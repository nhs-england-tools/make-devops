FROM postgres:latest

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
    \
    # Set file permissions
    chmod 0600 /etc/postgresql/certificate.* && \
    chown -R postgres:postgres /etc/postgresql && \
    find /sql -type d -exec chmod 777 {} \; && \
    find /sql -type f -exec chmod 666 {} \; && \
    \
    # Clean up
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

WORKDIR /sql
EXPOSE 5432
ENTRYPOINT [ "/sbin/entrypoint.sh" ]
