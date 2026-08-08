# syntax=docker/dockerfile:1
# Buzz Agent — buzz-acp harness + buzz-agent runtime + buzz-cli + buzz-dev-mcp.
# Build from the repo root:  docker build -f deploy/compose/agent/Dockerfile .
FROM rust:1.95.0-bookworm AS builder
WORKDIR /build
COPY Cargo.toml Cargo.lock ./
COPY crates/ crates/
RUN cargo build --release -p buzz-acp -p buzz-agent -p buzz-cli -p buzz-dev-mcp

FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /build/target/release/buzz-acp     /usr/local/bin/buzz-acp
COPY --from=builder /build/target/release/buzz-agent   /usr/local/bin/buzz-agent
COPY --from=builder /build/target/release/buzz         /usr/local/bin/buzz
COPY --from=builder /build/target/release/buzz-dev-mcp /usr/local/bin/buzz-dev-mcp
ENTRYPOINT ["buzz-acp"]
