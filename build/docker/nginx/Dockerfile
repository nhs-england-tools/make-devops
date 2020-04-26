FROM nginx:latest

ENV \
    DEBIAN_FRONTEND="noninteractive" \
    TZ="Europe/London" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"

COPY assets/ /

RUN set -ex && \
    \
    # Install base packages
    apt-get update --yes && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
        ca-certificates && \
    \
    # Trust certificate
    chmod 400 /certificate/* && \
    cp /certificate/*.crt /usr/local/share/ca-certificates && \
    update-ca-certificates && \
    \
    # Clean up
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

WORKDIR /application
EXPOSE 8080 8443
ENTRYPOINT [ "/sbin/entrypoint.sh" ]
