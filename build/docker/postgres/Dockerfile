FROM postgres:latest

COPY assets/ /

RUN set -ex && \
    \
    chmod 0600 /etc/postgresql/certificate.* && \
    chown -R postgres:postgres /etc/postgresql && \
    \
    find /sql -type d -exec chmod 777 {} \; && \
    find /sql -type f -exec chmod 666 {} \;

WORKDIR /sql
ENTRYPOINT [ "/sbin/entrypoint.sh" ]
