#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <vMAJOR.MINOR.PATCH> <message> [--push]"
  exit 1
fi

TAG="$1"
MESSAGE="$2"
PUSH_FLAG="${3:-}"

if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid tag format: $TAG (expected vMAJOR.MINOR.PATCH)"
  exit 1
fi

if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Tag already exists: $TAG"
  exit 1
fi

git tag -a "$TAG" -m "$MESSAGE"
echo "Created tag: $TAG"

if [[ "$PUSH_FLAG" == "--push" ]]; then
  git push origin "$TAG"
  echo "Pushed tag: $TAG"
fi
