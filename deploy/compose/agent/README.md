# Buzz Agent (Coolify)

Runs the team's shared agent as its own resource — **separate from the relay
stack** (independent restarts, secrets, and update cadence).

```
Coolify resource "buzz-agent"
  └── buzz-acp (harness) ──WS──► wss://buzz.pickz-ai.com (relay)
        ├── buzz-agent (ACP runtime, LLM via env provider)
        └── buzz-dev-mcp (shell/file tools)
```

The image bundles `buzz-acp`, `buzz-agent`, `buzz` (CLI), and `buzz-dev-mcp` —
no external agent install needed.

## Coolify setup

1. **Git repo**: `git@github.com:Pickz-AI/buzz.git`, branch `pickz-deploy`
2. **Build pack**: **Dockerfile**, path `deploy/compose/agent/Dockerfile`
   (the compose.yml is only for local `docker compose up` testing — Coolify
   builds the Dockerfile directly; env_file: .env does not exist in the repo)
3. **Env vars**: copy `deploy/compose/agent/.env.example` into the resource's
   **Environment Variables** tab — `BUZZ_PRIVATE_KEY` (agent nsec), relay URL,
   `RESPOND_TO`/`AGENT_OWNER` for shared access, and the LLM provider keys.
4. Deploy. The agent registers on the relay within seconds.

## Before first start

```bash
# 1. Agent keypair (own identity — NOT the relay owner key)
buzz-admin generate-key

# 2. Register the agent's pubkey as a relay member (in the relay container)
docker exec -it <relay-container> buzz-admin add-member --pubkey <agent-hex>
```

## Verify

```bash
# From any member client: mention the agent in a channel, e.g.
#   "@<agent-name> hallo"   (allowlist mode requires the sender to be listed)
# Container logs show the harness connecting + spawning buzz-agent.
docker logs -f <agent-container>
```

## Local test

```bash
cd deploy/compose/agent
cp .env.example .env   # fill in values
docker compose up
```
