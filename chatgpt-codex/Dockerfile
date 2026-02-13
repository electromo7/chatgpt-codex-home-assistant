ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.21
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3018
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

COPY ha-query.sh /usr/local/bin/ha-query
RUN chmod +x /usr/local/bin/ha-query

# S6 overlay service setup
RUN mkdir -p /etc/s6-overlay/s6-rc.d/chatgpt-codex/dependencies.d
COPY run.sh /etc/s6-overlay/s6-rc.d/chatgpt-codex/run
RUN chmod a+x /etc/s6-overlay/s6-rc.d/chatgpt-codex/run \
  && echo "longrun" > /etc/s6-overlay/s6-rc.d/chatgpt-codex/type \
  && touch /etc/s6-overlay/s6-rc.d/user/contents.d/chatgpt-codex \
  && touch /etc/s6-overlay/s6-rc.d/chatgpt-codex/dependencies.d/base
