#!/bin/bash

set -e

BUILDX_PLATFORMS="linux/arm/v7,linux/arm64,linux/amd64"

# Parse arguments
CHANNEL=""
for arg in "$@"; do
  case "$arg" in
    --beta) CHANNEL="beta" ;;
    --stable) CHANNEL="stable" ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

if [ -z "$CHANNEL" ]; then
  CHANNEL="beta"
fi

# Map channel to download path
if [ "$CHANNEL" = "stable" ]; then
  VERSION_CHANNEL="release"
else
  VERSION_CHANNEL="beta"
fi

curl -ksL "https://releases.domoticz.com/${VERSION_CHANNEL}/version_linux_x86_64.h" --output version.h
if [ $? -ne 0 ]; then
  echo "Error downloading version file!"
  exit 1
fi

declare $(cat version.h | awk '{print $2"="$3}')
RELEASE_DATE="$(date -d @$APPDATE -u +"%Y-%m-%dT%H:%M:%SZ")"

# Remove double quotes in APPHASH
APPHASH="${APPHASH%\"}"
APPHASH="${APPHASH#\"}"

# Auto-detect year from the release timestamp
BUILD_YEAR="$(date -d @$APPDATE -u +"%Y")"

# Build tags
BUILDX_ARGS="--build-arg APP_VERSION=$APPVERSION --build-arg APP_HASH=$APPHASH --build-arg BUILD_DATE=$RELEASE_DATE"

if [ "$CHANNEL" = "beta" ]; then
  echo "Building beta release ${BUILD_YEAR}-beta.${APPVERSION} from commit $APPHASH ($RELEASE_DATE)"
  TAGS="--tag domoticz/domoticz:latest --tag domoticz/domoticz:beta --tag domoticz/domoticz:${BUILD_YEAR}-beta.${APPVERSION}"
else
  # For stable releases, use year as major version component
  STABLE_VERSION="${BUILD_YEAR}.${APPVERSION}"
  echo "Building stable release ${STABLE_VERSION} from commit $APPHASH ($RELEASE_DATE)"
  BUILDX_ARGS="$BUILDX_ARGS --build-arg STABLE=true"
  TAGS="--tag domoticz/domoticz:stable --tag domoticz/domoticz:${STABLE_VERSION}"
fi

# Reuse existing builder if available, otherwise create one
docker buildx inspect domoticz_build >/dev/null 2>&1 || docker buildx create --name domoticz_build
docker buildx use domoticz_build
docker buildx inspect --bootstrap > /dev/null 2>&1
docker buildx build --push --progress=plain --platform ${BUILDX_PLATFORMS} ${BUILDX_ARGS} ${TAGS} .
