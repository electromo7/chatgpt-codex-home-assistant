ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.21
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    nodejs \
    npm \
    ttyd \
  && npm install --global @openai/codex \
  && npm cache clean --force

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
