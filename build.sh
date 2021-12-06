#!/bin/bash

Usage() {
	echo "Usage: $0 beta | stable"
	exit 1
}

if [ $# != 1 ]; then
  Usage
fi

case $1 in
  stable)
    RELEASE=release
    VERSION=2021.1
    ;;
  beta)
    RELEASE=beta
    VERSION=2021
    ;;
  *)
    Usage
    ;;
esac

# Supported platforms
BUILDX_PLATFORMS="linux/arm/v7,linux/arm64,linux/amd64"

# Abort script on error
set -e

# Download Domoticz installers
curl -sS https://releases.domoticz.com/releases/$RELEASE/version_linux_x86_64.h --output $RELEASE/linux/version.h
curl -sS https://releases.domoticz.com/releases/$RELEASE/domoticz_linux_armv7l.tgz --output $RELEASE/linux/arm/v7/domoticz.tgz
curl -sS https://releases.domoticz.com/releases/$RELEASE/domoticz_linux_aarch64.tgz --output $RELEASE/linux/arm64/domoticz.tgz
curl -sS https://releases.domoticz.com/releases/$RELEASE/domoticz_linux_x86_64.tgz --output $RELEASE/linux/amd64/domoticz.tgz

# Set APPVERSION, APPHASH, APPDATE and RELEASE_DATE
declare $(awk '{print $2"="$3}' $RELEASE/linux/version.h | tr -d '"')
if [ "`uname -s`" == "Darwin" ]; then
  RELEASE_DATE="$(date -r $APPDATE -u +"%Y-%m-%dT%H:%M:%SZ")"
else
  RELEASE_DATE="$(date -d @$APPDATE -u +"%Y-%m-%dT%H:%M:%SZ")"
fi

# Setup build toolchain
#docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx rm domoticz_build >/dev/null 2>&1 || true
docker buildx create --name domoticz_build
docker buildx use domoticz_build
docker buildx inspect --bootstrap

# Show who to build the Domoticz Docker images
if [ $1 = stable ]; then
  TAGS="--tag domoticz/domoticz:stable --tag domoticz/domoticz:$VERSION"
else
  TAGS="--tag domoticz/domoticz:latest --tag domoticz/domoticz:beta --tag domoticz/domoticz:$VERSION-beta.$APPVERSION"
fi

echo
echo "To build and push Domoticz release $VERSION.$APPVERSION image from commit $APPHASH ($RELEASE_DATE), run:";
echo
echo "docker buildx build --push --no-cache --platform $BUILDX_PLATFORMS --build-arg RELEASE=$RELEASE --build-arg APP_VERSION=$APPVERSION --build-arg APP_HASH=$APPHASH --build-arg BUILD_DATE=$RELEASE_DATE $TAGS ."
