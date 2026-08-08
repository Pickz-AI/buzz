# syntax=docker/dockerfile:1
# Buzz Agent (Hermes native gateway) — hermes + buzz CLI.
# Hermes' built-in Buzz adapter (gateway.platforms.buzz) talks to the relay:
#   inbound  = native NIP-42 WebSocket subscription (CLI polling fallback)
#   outbound = buzz CLI ("JSON in, JSON out")
# Build from the repo root:  docker build -f deploy/compose/agent/Dockerfile .
FROM rust:1.95.0-bookworm AS builder
WORKDIR /build
# Precise COPY: only workspace member dirs (crates/, examples/) + manifests.
# Entrypoint/deploy/docs changes no longer bust the cargo cache.
COPY Cargo.toml Cargo.lock ./
COPY crates/ crates/
COPY examples/ examples/
# Persistent BuildKit caches → incremental cargo builds on the VPS (no full
# rebuild when only crates/ changes; seconds instead of minutes).
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=/build/target \
    cargo build --release -p buzz-cli

FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git openssh-client gh \
       curl python3 python3-venv python3-dev build-essential \
    && curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash \
    && apt-get purge -y --auto-remove build-essential python3-dev gcc g++ cpp libc6-dev \
    && rm -rf /var/lib/apt/lists/* /root/.cache/uv /root/.cache/pip /tmp/*
COPY --from=builder /build/target/release/buzz /usr/local/bin/buzz
COPY deploy/compose/agent/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Hermes + Buzz adapter, all configured from env at container start (entrypoint):
#   BUZZ_RELAY_URL, BUZZ_PRIVATE_KEY, BUZZ_CHANNELS, BUZZ_ALLOWED_USERS,
#   BUZZ_ALLOW_ALL_USERS, OPENROUTER_API_KEY, HERMES_MODEL, GIT_USER_*, GITHUB_TOKEN
ENTRYPOINT ["/entrypoint.sh"]
# "run" (foreground) not "start" (service) — the gateway is the container's
# main process. Envs: BUZZ_RELAY_URL, BUZZ_PRIVATE_KEY, BUZZ_CHANNELS, …
CMD ["hermes", "gateway", "run"]
