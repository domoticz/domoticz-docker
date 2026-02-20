# Building the Domoticz Docker Image

This document explains how to build and publish the Domoticz Docker images.

## Prerequisites

- Docker Engine with [buildx](https://docs.docker.com/buildx/working-with-buildx/) support
- For multi-arch production builds: Docker Hub credentials (`docker login`)
- Internet access to download Domoticz binaries from `releases.domoticz.com`

## Quick Reference

| Command | What it does |
|---------|-------------|
| `./build.sh` | Build and push beta images for all platforms |
| `./build.sh --stable` | Build and push stable images for all platforms |
| `./buildstable.sh` | Same as `./build.sh --stable` |
| `docker compose build` | Build a local single-arch image for development |

## Production Builds

Production builds use `docker buildx` to cross-compile for three platforms simultaneously and push directly to Docker Hub (`domoticz/domoticz`).

### Supported Platforms

| Platform | Architecture |
|----------|-------------|
| `linux/amd64` | x86 64-bit |
| `linux/arm64` | ARM 64-bit (e.g. Raspberry Pi 4/5) |
| `linux/arm/v7` | ARM 32-bit (e.g. Raspberry Pi 2/3) |

### Beta Build

```bash
./build.sh
```

Downloads the latest beta binary from `releases.domoticz.com/beta/` and pushes with the following tags:
- `domoticz/domoticz:latest`
- `domoticz/domoticz:beta`
- `domoticz/domoticz:<year>-beta.<build_number>` (e.g. `2025-beta.16812`)

### Stable Build

```bash
./build.sh --stable
```

Downloads the latest stable binary from `releases.domoticz.com/release/` and pushes with:
- `domoticz/domoticz:stable`
- `domoticz/domoticz:<year>.<build_number>` (e.g. `2025.16800`)

The year and build number are auto-detected from the release metadata - no manual version bumping is needed.

## Local Development Build

For testing changes to the Dockerfile, entrypoint, or customstart script without pushing to Docker Hub:

```bash
docker compose build
```

This builds a single-arch (your host's architecture) image using the `docker-compose.yml` and runs the container as `domo_dev` on port 8080.

To start the container after building:

```bash
docker compose up -d
```

Alternatively, build directly with Docker:

```bash
docker build -t domoticz/domoticz .
```

To test a stable build locally, pass the `STABLE` build arg:

```bash
docker build --build-arg STABLE=true -t domoticz/domoticz:stable .
```

## How the Build Works

### Dockerfile Stages

The Dockerfile uses a multi-stage build:

**Stage 1 - `compiler`** (Python 3.11-slim)
- Creates a Python virtual environment at `/opt/venv`
- Installs pip packages: `setuptools`, `requests`, `pyserial`, `charset-normalizer`
- This stage is discarded after the venv is copied out

**Stage 2 - `application`** (Debian bookworm-slim)
- Copies the Python venv from stage 1
- Installs system runtime dependencies (split into its own cached layer)
- Downloads and extracts the Domoticz binary tarball for the target architecture
- Copies in the entrypoint and customstart scripts

### Layer Caching

The Dockerfile is structured so that the system dependencies layer (apt-get) is cached between builds. Only the Domoticz download layer changes on each build. This significantly speeds up repeated builds.

The build script reuses the `domoticz_build` buildx builder instance across runs, preserving its cross-compilation cache.

### Build Arguments

| Argument | Set by | Purpose |
|----------|--------|---------|
| `APP_VERSION` | `build.sh` | Build number from `version.h` |
| `APP_HASH` | `build.sh` | Git commit hash from `version.h` |
| `BUILD_DATE` | `build.sh` | ISO 8601 date from `version.h` timestamp |
| `STABLE` | `build.sh --stable` | When set, downloads from the release channel instead of beta |

### Version Detection

`build.sh` downloads `version_linux_x86_64.h` from the appropriate channel (beta or release). This file contains `#define` directives for `APPVERSION`, `APPHASH`, and `APPDATE`. The script parses these to determine the version number, commit hash, and build date. The year is extracted from the release timestamp automatically.

## Container Entrypoint

When the container starts, `docker-entrypoint.sh` performs the following:

1. **Assembles command-line arguments** from environment variables (`WWW_PORT`, `SSL_PORT`, `LOG_PATH`, `DATABASE_PATH`, `EXTRA_CMD_ARG`)
2. **Self-repair** - syncs default plugins, templates, dzVents examples, and `customstart.sh` into the userdata volume (only copies missing files, never overwrites)
3. **First-run customization** - if no `FIRSTRUN` marker exists, sources `userdata/customstart.sh` for user-defined setup (apt packages, pip installs, etc.)
4. **Starts Domoticz** with the assembled arguments

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WWW_PORT` | `8080` | HTTP port |
| `SSL_PORT` | `443` | HTTPS port |
| `TZ` | `Europe/Amsterdam` | Timezone ([list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)) |
| `LOG_PATH` | *(empty)* | Path to log file (logging disabled when empty) |
| `DATABASE_PATH` | *(empty)* | Path to database file |
| `EXTRA_CMD_ARG` | *(empty)* | Additional CLI arguments passed to the domoticz binary |

## .dockerignore

The `.dockerignore` file excludes build scripts, documentation, `.git/`, and backup files from the Docker build context. This keeps the context small (only `docker-entrypoint.sh` and `customstart.sh` need to be sent to the daemon). If you add new files that need to be `COPY`ed in the Dockerfile, make sure they are not listed in `.dockerignore`.

## Troubleshooting

### "Error downloading version file!"
The build script could not reach `releases.domoticz.com`. Check your internet connection and that the site is accessible.

### Build is slow
Ensure you are not passing `--no-cache` to `docker buildx build`. The Dockerfile is structured to cache the apt layer; only the Domoticz download should run on each build.

### Builder errors
If the buildx builder gets into a bad state, remove and recreate it:
```bash
docker buildx rm domoticz_build
./build.sh
```
The script will automatically create a new builder.
