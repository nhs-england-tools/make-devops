FROM python:latest

ENV DEBIAN_FRONTEND="noninteractive"

RUN set -ex && \
    \
    # Install base packages
    echo "APT::Install-Recommends 0;\nAPT::Install-Suggests 0;" > /etc/apt/apt.conf.d/99config && \
    apt-get --yes update && \
    apt-get --yes upgrade && \
    apt-get --yes install \
        curl \
        netcat \
    && \
    \
    # Install Python packages
    pip install \
        awscli==1.18.1 \
        awscli-local==0.5 \
        boto3==1.12.1 \
        requests==2.22.0 \
    && \
    \
    # Install aws-iam-authenticator
    curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x ./aws-iam-authenticator && \
    mv ./aws-iam-authenticator /usr/local/bin/aws-iam-authenticator && \
    \
    # Install jq
    curl -LO https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x ./jq-linux64 && \
    mv ./jq-linux64 /usr/local/bin/jq && \
    \
    # Install kubectl
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.17.3/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    \
    # Clean up
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

CMD [ "sh" ]
