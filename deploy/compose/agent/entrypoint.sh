#!/bin/sh
# Buzz agent entrypoint — configure git/gh from env, then start the harness.
# Secrets (GITHUB_TOKEN) are consumed by gh, persisted in gh's config, and
# removed from the environment before the harness spawns agent subprocesses.
set -e

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

exec buzz-acp "$@"
