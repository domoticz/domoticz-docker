#!/bin/bash

set -e

RELEASE=beta
VERSION=2021
BUILDX_PLATFORMS="linux/arm/v7,linux/arm64,linux/amd64"

curl -sS https://releases.domoticz.com/releases/$RELEASE/version_linux_x86_64.h --output $RELEASE/linux/version.h
curl -sS https://releases.domoticz.com/releases/$RELEASE/domoticz_linux_armv7l.tgz --output $RELEASE/linux/arm/v7/domoticz.tgz
curl -sS https://releases.domoticz.com/releases/$RELEASE/domoticz_linux_aarch64.tgz --output $RELEASE/linux/arm64/domoticz.tgz
curl -sS https://releases.domoticz.com/releases/$RELEASE/domoticz_linux_x86_64.tgz --output $RELEASE/linux/amd64/domoticz.tgz

declare $(awk '{print $2"="$3}' $RELEASE/linux/version.h | tr -d '"')
if [ "`uname -s`" == "Darwin" ]; then
  RELEASE_DATE="$(date -r $APPDATE -u +"%Y-%m-%dT%H:%M:%SZ")"
else
  RELEASE_DATE="$(date -d @$APPDATE -u +"%Y-%m-%dT%H:%M:%SZ")"
fi

echo "Building release $VERSION.$APPVERSION from commit $APPHASH ($RELEASE_DATE)";

#docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx rm domoticz_build >/dev/null 2>&1 || true
docker buildx create --name domoticz_build
docker buildx use domoticz_build
docker buildx inspect --bootstrap

echo "docker buildx build --push --no-cache --platform $BUILDX_PLATFORMS --build-arg RELEASE=$RELEASE --build-arg APP_VERSION=$APPVERSION --build-arg APP_HASH=$APPHASH --build-arg BUILD_DATE=$RELEASE_DATE --tag domoticz/domoticz:latest --tag domoticz/domoticz:beta --tag domoticz/domoticz:$VERSION-beta.$APPVERSION ."
