#!/bin/bash

set -e

BUILDX_PLATFORMS="linux/arm/v7,linux/arm64,linux/amd64"

curl -ksL https://releases.domoticz.com/releases/release/version_linux_x86_64.h --output version.h
if [ $? -ne 0 ]
then
        echo "Error downloading version file!";
        exit 1
fi

declare $(cat version.h | awk '{print $2"="$3}')
RELEASE_DATE="$(date -d @$APPDATE -u +"%Y-%m-%dT%H:%M:%SZ")"
STABLE_VERSION=2022.2
echo "Building release $STABLE_VERSION.$APPVERSION from commit $APPHASH ($RELEASE_DATE)";

# Remove double quotes in APPHASH
APPHASH="${APPHASH%\"}"
APPHASH="${APPHASH#\"}"

#docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx rm domoticz_build >/dev/null 2>&1 || true
docker buildx create --name domoticz_build
docker buildx use domoticz_build
docker buildx inspect --bootstrap
echo "docker buildx build --push --no-cache --platform ${BUILDX_PLATFORMS} --build-arg APP_VERSION=$APPVERSION --build-arg APP_HASH=$APPHASH --build-arg BUILD_DATE=$RELEASE_DATE --build-arg STABLE=true --tag domoticz/domoticz:stable --tag domoticz/domoticz:$STABLE_VERSION ."
