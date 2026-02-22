#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required."
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Please authenticate first: gh auth login"
  exit 1
fi

create_or_update_label() {
  local name="$1"
  local color="$2"
  local description="$3"

  if gh label list --limit 200 --json name --jq '.[].name' | grep -Fxq "$name"; then
    gh label edit "$name" --color "$color" --description "$description" >/dev/null
    echo "Updated label: $name"
  else
    gh label create "$name" --color "$color" --description "$description" >/dev/null
    echo "Created label: $name"
  fi
}

echo "==> Syncing labels"
create_or_update_label "bug" "d73a4a" "Something is not working"
create_or_update_label "enhancement" "a2eeef" "New feature or request"
create_or_update_label "task" "cfd3d7" "Implementation or maintenance task"
create_or_update_label "documentation" "0075ca" "Documentation improvements"
create_or_update_label "ci" "5319e7" "CI/CD related work"
create_or_update_label "good first issue" "7057ff" "Good for new contributors"
create_or_update_label "help wanted" "008672" "Extra attention is needed"
create_or_update_label "priority:high" "b60205" "High priority"
create_or_update_label "priority:medium" "d93f0b" "Medium priority"
create_or_update_label "priority:low" "fbca04" "Low priority"
create_or_update_label "version:v0.1.0" "1d76db" "Planned for v0.1.0"
create_or_update_label "version:v0.2.0" "1d76db" "Planned for v0.2.0"
create_or_update_label "version:v1.0.0" "1d76db" "Planned for v1.0.0"

echo "==> Ensuring milestones"
ensure_milestone() {
  local title="$1"
  local desc="$2"
  local due="$3"

  if gh api "repos/:owner/:repo/milestones?state=all&per_page=100" --jq '.[].title' | grep -Fxq "$title"; then
    echo "Milestone exists: $title"
  else
    gh api "repos/:owner/:repo/milestones" \
      --method POST \
      --field title="$title" \
      --field description="$desc" \
      --field due_on="${due}T00:00:00Z" >/dev/null
    echo "Created milestone: $title"
  fi
}

ensure_milestone "v0.1.0" "Initial public cleaner release" "2026-03-15"
ensure_milestone "v0.2.0" "GitHub automation and quality iteration" "2026-04-15"
ensure_milestone "v1.0.0" "Stable release" "2026-06-01"

echo "Done."
