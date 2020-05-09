FROM python:latest

ENV \
    DEBIAN_FRONTEND="noninteractive" \
    GOSU_VERSION="1.12" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    SYSTEM_USER_GID="999" \
    SYSTEM_USER_UID="999" \
    SYSTEM_USER="tools" \
    TZ="Europe/London"

RUN set -eux && \
    \
    # Install base packages
    apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        dnsutils \
        git \
        gnupg \
        iputils-ping \
        make \
        net-tools \
        netcat \
        traceroute \
        wget \
    && \
    \
    # Install Python packages
    pip install \
        awscli==1.18.55 \
        awscli-local==0.6 \
        boto3==1.13.5 \
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
    # Install gosu
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" && \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
    gpgconf --kill all && \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
    \
    # Configure system user
    userdel --remove --force $SYSTEM_USER ||: && \
    groupadd --system --gid $SYSTEM_USER_GID $SYSTEM_USER && \
    useradd --system --create-home --home-dir /tmp --shell=/bin/false --uid $SYSTEM_USER_UID --gid $SYSTEM_USER_GID $SYSTEM_USER && \
    \
    # Clean up
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

COPY assets/ /

ENTRYPOINT [ "/sbin/entrypoint.sh" ]
CMD [ "/bin/bash" ]
