# Versioning Strategy

This repository follows semantic versioning:

- `MAJOR`: breaking behavior changes
- `MINOR`: backward-compatible features
- `PATCH`: backward-compatible fixes

Git tags follow this exact format:

- `vMAJOR.MINOR.PATCH`

Examples:

- `v0.1.0`
- `v0.2.1`
- `v1.0.0`

## Release checklist

1. Ensure `main` is green in CI.
2. Update `CHANGELOG.md`.
3. Create and push annotated tag.
4. Verify GitHub release artifact is generated.
5. Announce release notes.
