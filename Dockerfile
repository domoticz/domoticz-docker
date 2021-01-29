FROM debian:buster-slim

ARG APP_HASH
ARG BUILD_DATE

LABEL org.label-schema.vcs-ref=$APP_HASH \
      org.label-schema.version=$APP_HASH \
      org.label-schema.vcs-url="https://github.com/domoticz/domoticz" \
      org.label-schema.url="https://domoticz.com/" \
      org.label-schema.name="Domoticz" \
      org.label-schema.description="Domoticz open source Home Automation system" \
      org.label-schema.license="GPLv3" \
      org.label-schema.build-date=$BUILD_DATE \
      maintainer="Domoticz Docker Maintainers <docker@domoticz.com>"

WORKDIR /opt/domoticz

RUN set -ex \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y unzip \
        git \
        libudev-dev \
        libusb-0.1-4 \
        curl libcurl4 libcurl4-gnutls-dev \
        libpython3.7-dev \
    && OS="$(uname -s | sed 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/')" \
    && MACH=$(uname -m) \
    && if [ ${MACH} = "armv6l" ]; then MACH = "armv7l"; fi \
    && archive_file="domoticz_${OS}_${MACH}.tgz" \
    && version_file="version_${OS}_${MACH}.h" \
    && history_file="history_${OS}_${MACH}.txt" \
    && curl -k -L https://releases.domoticz.com/releases/beta/${version_file} --output version.h \
    && curl -k -L https://releases.domoticz.com/releases/beta/${archive_file} --output domoticz.tgz \
    && tar xfz domoticz.tgz \
    && rm domoticz.tgz \
    && apt-get remove --purge --auto-remove -y curl \
    && rm -rf /var/lib/apt/lists/*

VOLUME /config
VOLUME /opt/domoticz/plugins
VOLUME /log

EXPOSE 8080
EXPOSE 443

ENV LOG_PATH=
ENV DATABASE_PATH=
ENV WWW_PORT=8080
ENV SSL_PORT=443

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/opt/domoticz/domoticz"]
