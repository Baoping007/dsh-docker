# syntax=docker/dockerfile:1

FROM node:24-bookworm-slim

ARG DSH_VERSION=0.2.0-rc.2

ENV DEBIAN_FRONTEND=noninteractive \
    DSH_HOME=/root/.dsh

# Keep common development, troubleshooting, Python, and native-module build tools
# in the image. node-pty may need to build from source on Linux during install.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        bash \
        bash-completion \
        build-essential \
        ca-certificates \
        curl \
        file \
        git \
        htop \
        iproute2 \
        iputils-ping \
        jq \
        less \
        lsof \
        nano \
        netcat-openbsd \
        openssh-client \
        procps \
        python3 \
        python3-pip \
        python3-venv \
        rsync \
        tini \
        tmux \
        tree \
        unzip \
        vim-tiny \
        wget \
        zip \
    && rm -rf /var/lib/apt/lists/*

# Node.js provides npm and npx. Install pnpm plus the pinned DSH release.
RUN npm install --global --no-audit --no-fund \
        pnpm \
        "@deepseek-ai/dsh@${DSH_VERSION}"

WORKDIR /app

COPY proxy/package.json /app/proxy/package.json
RUN npm install --prefix /app/proxy --omit=dev --no-audit --no-fund

COPY proxy/ /app/proxy/
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod 0755 /app/entrypoint.sh \
    && mkdir --parents /workspace "${DSH_HOME}"

WORKDIR /workspace

VOLUME ["/workspace", "/root/.dsh"]

# The Node proxy listens on 3080 and forwards to DSH on 127.0.0.1:3079.
EXPOSE 3080

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]
