#!/bin/sh
# Buzz agent entrypoint — configure git/gh + hermes from env, then start the
# Hermes gateway (Buzz adapter). Secrets are consumed, persisted to their
# config stores, and removed from the environment before the gateway starts.
set -e

export PATH="$HOME/.local/bin:$PATH"

if [ -n "$GIT_USER_NAME" ]; then
  git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
  git config --global user.email "$GIT_USER_EMAIL"
fi
if [ -n "${GITHUB_TOKEN:-}${GH_TOKEN:-}" ]; then
  # gh REFUSES --with-token while GITHUB_TOKEN/GH_TOKEN is in the env (non-zero
  # exit) — so credentials were never stored, then the unset below left gh
  # completely logged out. Fix: strip the vars for the login invocation so gh
  # reads the token from stdin and persists it to ~/.config/gh/hosts.yml.
  _gh_token="${GH_TOKEN:-$GITHUB_TOKEN}"
  if printf '%s' "$_gh_token" | env -u GITHUB_TOKEN -u GH_TOKEN gh auth login --with-token; then
    env -u GITHUB_TOKEN -u GH_TOKEN gh auth setup-git 2>/dev/null || true
    echo "gh: authenticated and git credential helper configured"
  else
    echo "WARN: gh auth login failed — agent will be logged out" >&2
  fi
  unset GITHUB_TOKEN GH_TOKEN _gh_token
fi

# Hermes: OpenRouter key + model from env (persisted to ~/.hermes, then unset).
# The Buzz adapter itself reads BUZZ_* env vars directly (Option B).
if [ -n "$OPENROUTER_API_KEY" ]; then
  # Non-fatal: a hermes config hiccup must never kill the entrypoint (restart loop).
  hermes config set OPENROUTER_API_KEY "$OPENROUTER_API_KEY" >/dev/null 2>&1 || true
  hermes config set model.provider openrouter >/dev/null 2>&1 || true
  unset OPENROUTER_API_KEY
fi
if [ -n "$HERMES_MODEL" ]; then
  hermes config set model "$HERMES_MODEL" >/dev/null 2>&1 || true
  unset HERMES_MODEL
fi

# Auxiliary tasks use the OpenRouter fallback model (paid lane OK — user has credits).
# Clean channel view: only the final response reaches Buzz, no progress noise.
hermes config set display.platforms.buzz.interim_assistant_messages false >/dev/null 2>&1 || true
hermes config set display.platforms.buzz.tool_progress off >/dev/null 2>&1 || true

exec "$@"
