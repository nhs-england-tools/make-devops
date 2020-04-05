FROM nginx:latest

COPY assets/ /

WORKDIR /application
EXPOSE 8443
ENTRYPOINT [ "/sbin/entrypoint.sh" ]
