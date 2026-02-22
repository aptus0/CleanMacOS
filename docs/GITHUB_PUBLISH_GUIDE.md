# GitHub Publish Guide

This guide explains how to publish the project and keep a badge-friendly workflow with frequent, meaningful commits.

## 1. Create a GitHub repository

Create an empty repository in GitHub UI, then run:

```bash
git remote add origin git@github.com:<your-username>/<your-repo>.git
git push -u origin main
```

If you prefer HTTPS:

```bash
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

## 2. Badge links

This repository already points badges to `aptus0/CleanMacOS`.  
If you fork it, update badge paths in `README.md` to your fork path.

## 3. Enable branch protection (recommended)

In GitHub repository settings:

- Protect `main`
- Require PR before merge
- Require status checks (CI)

## 4. Bootstrap labels and milestones

Preferred: run GitHub Action `Bootstrap Project Metadata` from the Actions tab.

Alternative with GitHub CLI (`gh`):

```bash
gh auth login
./scripts/bootstrap_github_labels.sh
```

This creates:

- issue labels (`bug`, `enhancement`, `priority:*`, `version:*`)
- milestones (`v0.1.0`, `v0.2.0`, `v1.0.0`)

## 5. Recommended commit strategy

Use small commits with clear scopes:

- `feat: ...`
- `fix: ...`
- `docs: ...`
- `ci: ...`
- `chore: ...`

Each issue should map to one or more focused commits.

## 6. Create semantic version tags

Create a local tag:

```bash
./scripts/create_release_tag.sh v0.1.0 "Initial public release"
```

Create and push:

```bash
./scripts/create_release_tag.sh v0.1.0 "Initial public release" --push
```

On push, `.github/workflows/release.yml` builds and publishes a zipped `.app`.

## 7. Build release app locally

```bash
./scripts/build_release_app.sh v0.1.0
```

Output:

- `dist/CleanMacOS-v0.1.0.zip`
