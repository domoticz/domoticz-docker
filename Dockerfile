FROM debian:buster-slim

ARG APP_VERSION
ARG APP_HASH
ARG BUILD_DATE
ARG BUILDPLATFORM
ARG RELEASE
ARG DEBIAN_FRONTEND=noninteractive

LABEL org.label-schema.version=$APP_VERSION \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$APP_HASH \
      org.label-schema.vcs-url="https://github.com/domoticz/domoticz" \
      org.label-schema.url="https://domoticz.com/" \
      org.label-schema.vendor="Domoticz" \
      org.label-schema.name="Domoticz" \
      org.label-schema.description="Domoticz open source Home Automation system" \
      org.label-schema.license="GPLv3" \
      org.label-schema.docker.cmd="docker run -v ./config:/config -v ./plugins:/opt/domoticz/plugins -e DATABASE_PATH=/config/domoticz.db -p 8080:8080 -d domoticz/domoticz" \
      maintainer="Domoticz Docker Maintainers <info@domoticz.com>"

ENV LOG_PATH=
ENV DATABASE_PATH=
ENV WWW_PORT=8080
ENV SSL_PORT=443
ENV EXTRA_CMD_ARG=
ENV EXTRA_PACKAGES=

# timezone env with default
ENV TZ=Europe/Amsterdam

RUN set -ex \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
        tzdata \
        unzip \
        git \
        libudev-dev \
        libusb-0.1-4 \
        libsqlite3-0 \
        curl libcurl4 libcurl4-gnutls-dev \
        libpython3.7-dev \
        python3 python3-requests python3-setuptools \
        python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/pip3 /usr/bin/pip

ADD $RELEASE/$BUILDPLATFORM/domoticz.tgz /opt/domoticz/

COPY docker-entrypoint.sh /usr/local/bin/

RUN mkdir -p /opt/domoticz/userdata \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && ln -s /usr/local/bin/docker-entrypoint.sh / # backwards compat

VOLUME /opt/domoticz/userdata
EXPOSE 8080
EXPOSE 443
WORKDIR /opt/domoticz

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/opt/domoticz/domoticz"]
