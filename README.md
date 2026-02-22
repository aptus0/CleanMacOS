# CleanMacOS

[![CI](https://img.shields.io/github/actions/workflow/status/USERNAME/REPO/ci.yml?branch=main&label=CI)](https://github.com/USERNAME/REPO/actions)
[![Release](https://img.shields.io/github/v/tag/USERNAME/REPO?sort=semver)](https://github.com/USERNAME/REPO/releases)
[![Issues](https://img.shields.io/github/issues/USERNAME/REPO)](https://github.com/USERNAME/REPO/issues)
[![License](https://img.shields.io/github/license/USERNAME/REPO)](./LICENSE)

Native macOS cleaner app built with SwiftUI.

`CleanMacOS` scans selected cleanup categories, shows a detailed preview, and permanently removes selected files with a terminal-style execution log.

## Features

- Safe-by-default category selection with optional advanced categories.
- Scan + preview workflow with estimated size and item counts.
- One-click cleanup flow for common safe locations.
- Permanent deletion mode with per-item log output.
- Exclusion list support (`~/...` paths supported).
- Persistent preferences (settings, exclusions, last cleanup time).

## Included Cleanup Categories

- User Caches (`~/Library/Caches`)
- User Logs (`~/Library/Logs`)
- Trash (`~/.Trash`)
- Xcode DerivedData
- iOS Simulators
- Homebrew Cache
- Browser Caches (optional)
- Large Files Report (preview-only)

## Safety Model

- Path traversal is blocked by normalized path checks.
- Protected roots are hard-blocked (system and critical user-data roots).
- Exclusion list is enforced before deletion.
- Large Files category never deletes; it is report-only.

## Build and Run

### Xcode

1. Open `CleanMacOS.xcodeproj`.
2. Select the `CleanMacOS` scheme.
3. Run on macOS.

### Command line

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -scheme CleanMacOS \
  -configuration Debug \
  -sdk macosx \
  -destination 'platform=macOS,arch=arm64' \
  clean build
```

## Versioning

This project uses semantic versioning tags:

- `vMAJOR.MINOR.PATCH`

Examples:

- `v0.1.0` initial public cleaner app
- `v0.2.0` GitHub automation and templates
- `v1.0.0` stable release

## GitHub Setup

See `docs/GITHUB_PUBLISH_GUIDE.md` for:

- repository creation and remote setup
- commit strategy
- labels/milestones bootstrapping
- release/tag workflow

## Disclaimer

This app can permanently remove files. Use only on paths you understand.  
It does not directly "reset" RAM/CPU at OS kernel level; cleanup impact is indirect through reduced disk and I/O pressure.
