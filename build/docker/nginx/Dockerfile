FROM nginx:latest

COPY assets/ /

RUN set -ex && \
    \
    chmod 400 /certificate/* && \
    \
    apt-get --yes update && \
    apt-get install --yes --force-yes --no-install-recommends \
        ca-certificates && \
    cp /certificate/*.crt /usr/local/share/ca-certificates && \
    update-ca-certificates && \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

WORKDIR /application
EXPOSE 8080 8443
ENTRYPOINT [ "/sbin/entrypoint.sh" ]
