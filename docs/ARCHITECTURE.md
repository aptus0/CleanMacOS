# Architecture

## Overview

`CleanMacOS` follows a simple SwiftUI + view-model + engine split:

- `ContentView.swift`: UI and interaction surfaces.
- `CleanerViewModel.swift`: state orchestration, async flows, UI-facing operations.
- `CleanupEngine.swift`: scanning, filtering, and file deletion logic.
- `CleanupModels.swift`: category/settings/result models.
- `CleanerPreferencesStore.swift`: local persistence with `UserDefaults`.

## Execution Flow

1. User selects categories and optional exclusions.
2. View model builds a `CleanupPlan` using the engine.
3. Preview is shown with per-target size and file counts.
4. User runs cleanup.
5. Engine applies safety filters and executes deletion.
6. Terminal output and summary metrics are updated in UI.

## Concurrency Model

- `CleanupEngine` is an `actor` to serialize filesystem operations and reduce race risk.
- UI updates stay on `@MainActor` in the view model.

## Safety Gates

- Paths are normalized (`resolvingSymlinksInPath + standardizedFileURL`).
- Candidate target must be descendant of category roots.
- Candidate target must not be descendant of blocked roots.
- Candidate target must not be descendant of user-defined exclusions.

## Persistence

Stored with `UserDefaults`:

- cleaner settings
- excluded paths
- last cleanup date

## Extending Categories

To add a category:

1. Add enum case in `CleanupCategory`.
2. Define title/details/risk/warning/roots.
3. Ensure root semantics are safe.
4. Rebuild and test with both preview and execute flows.
