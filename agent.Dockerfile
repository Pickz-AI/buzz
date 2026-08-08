# syntax=docker/dockerfile:1
# Buzz Agent — buzz-acp harness + buzz-agent runtime + buzz-cli + buzz-dev-mcp.
# Build context MUST be the repo root (Coolify: Dockerfile Location =
# "agent.Dockerfile", Base Directory = "/").
# Canonical files live in deploy/compose/agent/.
FROM rust:1.95.0-bookworm AS builder
WORKDIR /build
COPY Cargo.toml Cargo.lock ./
COPY crates/ crates/
RUN cargo build --release -p buzz-acp -p buzz-agent -p buzz-cli -p buzz-dev-mcp

FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git openssh-client gh \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /build/target/release/buzz-acp     /usr/local/bin/buzz-acp
COPY --from=builder /build/target/release/buzz-agent   /usr/local/bin/buzz-agent
COPY --from=builder /build/target/release/buzz         /usr/local/bin/buzz
COPY --from=builder /build/target/release/buzz-dev-mcp /usr/local/bin/buzz-dev-mcp
COPY deploy/compose/agent/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Git/gh config comes from env at container start (see entrypoint.sh):
#   GIT_USER_NAME, GIT_USER_EMAIL, GITHUB_TOKEN (fine-grained PAT)
ENTRYPOINT ["/entrypoint.sh"]
CMD ["buzz-acp"]
