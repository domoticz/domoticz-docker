FROM python:3.11-slim AS compiler
ENV PYTHONUNBUFFERED=1

WORKDIR /opt/domoticz

RUN python -m venv /opt/venv
# Enable venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install -U setuptools requests pyserial

# done with python packages

FROM debian:bookworm-slim AS application
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

ARG APP_VERSION
ARG APP_HASH
ARG BUILD_DATE
# If stable argument is passed it will download stable instead of beta
#ARG STABLE

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

WORKDIR /opt/domoticz

ARG DEBIAN_FRONTEND=noninteractive

COPY --from=compiler /opt/venv /opt/venv
#fix symlink
COPY --from=compiler /usr/local/bin/python /opt/venv/bin

RUN set -ex \
    && rm /var/lib/dpkg/info/libc-bin.* \
    && apt-get clean \
    && apt-get update -qq \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        libc-bin \
        tzdata \
        rsync \
        unzip \
        less \
        vim \
        git \
        jq \
        libudev-dev \
        libusb-0.1-4 \
        libsqlite3-0 \
        curl libcurl4-gnutls-dev \
        libpython3-dev \
    && OS="$(uname -s | sed 'y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/')" \
    && MACH=$(uname -m) \
    && if [ ${MACH} = "armv6l" ]; then MACH = "armv7l"; fi \
    && archive_file="domoticz_${OS}_${MACH}.tgz" \
    && version_file="version_${OS}_${MACH}.h" \
    && history_file="history_${OS}_${MACH}.txt" \
    && if [ -z "$STABLE"]; then curl -k -L https://releases.domoticz.com/beta/${archive_file} --output domoticz.tgz; else curl -k -L https://releases.domoticz.com/release/${archive_file} --output domoticz.tgz; fi \
    && tar xfz domoticz.tgz \
    && rm domoticz.tgz \
    && mkdir -p /opt/domoticz/userdata \
    && rm -rf /var/lib/apt/lists/*

VOLUME /opt/domoticz/userdata
VOLUME /opt/domoticz/www/templates

EXPOSE 8080
EXPOSE 443

ENV LOG_PATH=
ENV DATABASE_PATH=
ENV WWW_PORT=8080
ENV SSL_PORT=443
ENV EXTRA_CMD_ARG=

# Enable venv
ENV PATH="/opt/venv/bin:$PATH"

# timezone env with default
ENV TZ=Europe/Amsterdam

COPY docker-entrypoint.sh /usr/local/bin/
COPY customstart.sh /opt/domoticz/customstart.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat

# squirrel the web templates (used during self-repair by docker-entrypoint.sh)
RUN cp -a /opt/domoticz/www/templates /opt/domoticz/www-templates

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/opt/domoticz/domoticz"]
