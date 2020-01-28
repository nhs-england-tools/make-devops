FROM python:latest

RUN set -ex && \
    \
    # Install base packages
    apk add --update --no-cache \
        curl \
        jq \
    && \
    pip install \
        awscli \
        awscli-local \
        boto3 \
    && \
    # Install aws-iam-authenticator
    curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x ./aws-iam-authenticator && \
    mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator && \
    # Install kubectl
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    \
    # Clean up
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

CMD [ "sh" ]
