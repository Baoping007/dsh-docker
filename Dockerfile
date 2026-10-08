# syntax=docker/dockerfile:1

FROM node:22-bookworm-slim

ARG DSH_VERSION=0.2.0-rc.2

ENV DEBIAN_FRONTEND=noninteractive \
    DSH_HOME=/root/.dsh \
    PNPM_HOME=/pnpm \
    PATH=/pnpm/bin:/pnpm:${PATH}

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        git \
        less \
        procps \
        python3 \
        python3-pip \
        python3-venv \
        tini \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Node.js includes npm and npx. Corepack supplies the pnpm version used by DSH.
RUN corepack enable \
    && corepack prepare pnpm@latest --activate \
    && mkdir --parents "${PNPM_HOME}" \
    && pnpm add --global "@deepseek-ai/dsh@${DSH_VERSION}"

RUN mkdir --parents /workspace "${DSH_HOME}"

WORKDIR /workspace

VOLUME ["/workspace", "/root/.dsh"]

ENTRYPOINT ["tini", "--"]
CMD ["dsh", "web", "--no-open"]
