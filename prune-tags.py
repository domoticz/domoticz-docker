#!/usr/bin/env python3
"""Delete old beta tags from the Docker Hub repository.

Docker Hub refuses anonymous tag pagination past offset 1000. Clients that
enumerate the full tag list (Synology Package Center, for one) then fail to
build their tag dropdown, see domoticz/domoticz#6957. Every beta build pushes
a permanent 20XX-beta.NNNNN tag, so the list has to be trimmed after a push or
it grows without bound.

Only tags matching 20XX-beta.NNNNN are considered. latest, beta, stable and
the stable version tags (2026.2 and friends) are never touched.

Two rules decide what stays, and a tag survives if either one keeps it: the
newest KEEP_BETA_TAGS builds, and every beta pushed since the last stable
release. The second rule is a floor, so the running development cycle is
always kept whole no matter how many builds it took.

Deleting a tag is not something the push credential can do: buildx pushes
through the registry API, which has its manifest delete endpoint disabled on
Docker Hub, so removal has to go through the Hub web API with a normal account
login. It is the same secret though, so by default the credentials `docker
login` already stored on this machine are reused. DOCKERHUB_USERNAME and
DOCKERHUB_TOKEN override that when set.
"""

import argparse
import base64
import datetime
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

API = "https://hub.docker.com/v2"
PAGE_SIZE = 100
BETA_TAG = re.compile(r"^(\d{4})-beta\.(\d+)$")
STABLE_TAG = re.compile(r"^\d{4}\.\d+$")
REGISTRIES = ("https://index.docker.io/v1/", "index.docker.io",
              "registry-1.docker.io", "docker.io")


def request(url, method="GET", data=None, token=None):
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(url, data=body, method=method)
    if body is not None:
        req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", "JWT " + token)
    with urllib.request.urlopen(req, timeout=60) as response:
        raw = response.read()
    return json.loads(raw) if raw else {}


def pushed_at(tag):
    value = tag.get("last_updated") or ""
    try:
        return datetime.datetime.strptime(value[:19], "%Y-%m-%dT%H:%M:%S")
    except ValueError:
        return None


def last_stable_release(tags):
    """When the most recent stable release was pushed, if it can be told."""
    times = [pushed_at(tag) for tag in tags
             if tag["name"] == "stable" or STABLE_TAG.match(tag["name"])]
    times = [t for t in times if t]
    return max(times) if times else None


def credentials_from_docker_config():
    """Reuse whatever `docker login` stored for Docker Hub on this machine."""
    config_dir = os.environ.get("DOCKER_CONFIG") or os.path.expanduser("~/.docker")
    try:
        with open(os.path.join(config_dir, "config.json"), encoding="utf-8") as handle:
            config = json.load(handle)
    except (OSError, ValueError):
        return None, None

    auths = config.get("auths", {})
    for registry in REGISTRIES:
        encoded = auths.get(registry, {}).get("auth")
        if encoded:
            decoded = base64.b64decode(encoded).decode("utf-8")
            username, _, secret = decoded.partition(":")
            if username and secret:
                return username, secret

    # Credentials live in a helper (credsStore / credHelpers) instead
    for registry in REGISTRIES:
        helper = config.get("credHelpers", {}).get(registry) or config.get("credsStore")
        if not helper:
            continue
        try:
            result = subprocess.run(["docker-credential-" + helper, "get"],
                                    input=registry, capture_output=True,
                                    text=True, timeout=30)
        except (OSError, subprocess.SubprocessError):
            continue
        if result.returncode == 0:
            try:
                entry = json.loads(result.stdout)
            except ValueError:
                continue
            if entry.get("Username") and entry.get("Secret"):
                return entry["Username"], entry["Secret"]

    return None, None


class Hub:
    """Hub web API session that logs back in when its token expires.

    The login token is only valid for a limited time, which a run deleting
    hundreds of tags one by one will outlive.
    """

    def __init__(self, username, password):
        self.username = username
        self.password = password
        self.token = None
        self.login()

    def login(self):
        self.token = request(f"{API}/users/login/", "POST",
                             {"username": self.username,
                              "password": self.password})["token"]

    def call(self, url, method="GET"):
        try:
            return request(url, method, token=self.token)
        except urllib.error.HTTPError as err:
            if err.code != 401:
                raise
            self.login()
            return request(url, method, token=self.token)


def list_tags(hub, repo):
    """Read every tag, page by page.

    The repository tag count Docker Hub reports is cached and lags behind
    deletions, so the 'next' link it hands out can point past the real last
    page. Walking off the end that way answers 404, which just means done.
    """
    tags = []
    page = 1
    while True:
        url = (f"{API}/repositories/{repo}/tags/"
               f"?page_size={PAGE_SIZE}&page={page}&ordering=last_updated")
        try:
            data = hub.call(url)
        except urllib.error.HTTPError as err:
            if err.code == 404 and tags:
                break
            raise
        results = data.get("results", [])
        tags.extend(results)
        if len(results) < PAGE_SIZE or not data.get("next"):
            break
        page += 1
    return tags


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=os.environ.get("HUB_REPO", "domoticz/domoticz"))
    parser.add_argument("--keep", type=int,
                        default=int(os.environ.get("KEEP_BETA_TAGS", "200")),
                        help="number of newest beta tags to keep")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    username = os.environ.get("DOCKERHUB_USERNAME")
    password = os.environ.get("DOCKERHUB_TOKEN") or os.environ.get("DOCKERHUB_PASSWORD")
    if not username or not password:
        username, password = credentials_from_docker_config()
    if not username or not password:
        print("prune-tags: no Docker Hub login found, skipping tag cleanup. "
              "Run 'docker login' or set DOCKERHUB_USERNAME/DOCKERHUB_TOKEN.")
        return 0

    try:
        hub = Hub(username, password)
        tags = list_tags(hub, args.repo)
    except (urllib.error.URLError, KeyError) as err:
        print(f"prune-tags: could not read tag list: {err}", file=sys.stderr)
        return 1

    betas = []
    for tag in tags:
        match = BETA_TAG.match(tag["name"])
        if match:
            betas.append({"name": tag["name"],
                          "order": (int(match.group(1)), int(match.group(2))),
                          "pushed": pushed_at(tag)})
    betas.sort(key=lambda beta: beta["order"], reverse=True)

    keep = {beta["name"] for beta in betas[:args.keep]}
    released = last_stable_release(tags)
    if released:
        since = {beta["name"] for beta in betas
                 if beta["pushed"] and beta["pushed"] >= released}
        print(f"prune-tags: last stable release {released:%Y-%m-%d}, "
              f"{len(since)} beta tags pushed since")
        keep |= since
    else:
        print("prune-tags: no stable release tag found, keeping newest builds only")

    stale = [beta["name"] for beta in betas if beta["name"] not in keep]

    print(f"prune-tags: {len(tags)} tags on {args.repo}, {len(betas)} beta tags, "
          f"keeping {len(keep)}, removing {len(stale)}")

    failed = 0
    for name in stale:
        if args.dry_run:
            print(f"  would delete {name}")
            continue
        try:
            hub.call(f"{API}/repositories/{args.repo}/tags/{name}/", "DELETE")
            print(f"  deleted {name}")
        except urllib.error.HTTPError as err:
            if err.code == 404:
                print(f"  {name} was already gone")
                continue
            failed += 1
            print(f"  failed to delete {name}: {err.code} {err.reason}", file=sys.stderr)

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
