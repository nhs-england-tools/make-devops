FROM python:latest

ENV \
    DEBIAN_FRONTEND="noninteractive" \
    TZ="Europe/London" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"

RUN set -ex && \
    \
    # Install base packages
    apt-get update --yes && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
        curl \
        make \
        netcat \
        wget \
    && \
    \
    # Install Python packages
    pip install \
        awscli==1.18.46 \
        awscli-local==0.6 \
        boto3==1.12.46 \
        requests==2.23.0 \
    && \
    \
    # Install aws-iam-authenticator
    curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.15.10/2020-02-22/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x ./aws-iam-authenticator && \
    mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator && \
    \
    # Install jq
    curl -LO https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x ./jq-linux64 && \
    mv ./jq-linux64 /usr/local/bin/jq && \
    \
    # Install kubectl
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.2/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    \
    # Clean up
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

CMD [ "sh" ]
