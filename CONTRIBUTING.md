# Contributing

Thanks for contributing to `CleanMacOS`.

## Development setup

1. Clone the repository.
2. Open `CleanMacOS.xcodeproj`.
3. Build and run the `CleanMacOS` scheme.

## Branch naming

Use short, explicit branch names:

- `feat/<topic>`
- `fix/<topic>`
- `docs/<topic>`
- `ci/<topic>`

## Commit style

Use conventional-style commit prefixes:

- `feat:`
- `fix:`
- `docs:`
- `ci:`
- `build:`
- `chore:`

## Pull requests

- Fill in the PR template completely.
- Link the issue (`Closes #123`) when relevant.
- Keep PR scope focused.
- Include screenshots when UI changes.

## Testing expectations

Before opening a PR:

```bash
xcodebuild -project CleanMacOS.xcodeproj -scheme CleanMacOS -destination 'platform=macOS' clean build
```

## Safety expectations

- Never relax protected-root checks without justification.
- Any deletion behavior change must include documentation update.
- Favor transparent logging and clear user-facing warnings.
