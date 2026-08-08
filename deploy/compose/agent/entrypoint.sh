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
if [ -n "$GITHUB_TOKEN" ]; then
  printf '%s' "$GITHUB_TOKEN" | gh auth login --with-token
  gh auth setup-git 2>/dev/null || true
  unset GITHUB_TOKEN
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

exec "$@"
