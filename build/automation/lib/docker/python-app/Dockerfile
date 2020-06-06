FROM nhsd/python-base:latest as base
ENV \
    APP="" \
    PYTHONPATH="/application"

FROM base as builder
RUN set -eux && \
    # Get Python packages
    mkdir /packages && cd /packages && \
    pip install --upgrade pip && \
    pip install --prefix=/packages --no-warn-script-location --verbose \
        gunicorn==20.0.4

FROM base
COPY --from=builder /packages /usr/local
COPY assets/ /
RUN set -eux && \
    chown $SYSTEM_USER:$SYSTEM_USER /certificate/*
WORKDIR /application
CMD [ "gunicorn" ]
EXPOSE 8443
