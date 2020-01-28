FROM postgres:latest

COPY assets/ /

RUN set -ex && \
    \
    find /sql -type d -exec chmod 777 {} \; && \
    find /sql -type f -exec chmod 666 {} \;

WORKDIR /sql
ENTRYPOINT [ "/sbin/entrypoint.sh" ]
