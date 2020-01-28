FROM postgres:latest

COPY assets/ /

RUN set -ex && \
    \
    chmod 0600 /etc/postgresql/certificate.* && \
    chown -R postgres:postgres /etc/postgresql
