# Security and Scope

## What the App Does

- Scans selected user/system-adjacent cleanup paths.
- Calculates estimated removable size.
- Permanently removes matched targets after user action.
- Shows operation logs in a terminal-style panel.

## What the App Does Not Do

- Does not bypass SIP/root protections automatically.
- Does not modify protected system paths.
- Does not clear kernel-managed memory directly.
- Does not guarantee speed-ups for every machine/workload.

## Protected Roots

These roots are blocked by design:

- `/System`
- `/Library`
- `/Applications`
- `/private/var/db`
- `/private/var/vm`
- `~/Library/Application Support`
- `~/Library/Keychains`
- `~/Library/Mobile Documents`
- `~/Library/Containers/com.apple.CloudDocs`

## Permanent Deletion Notice

This app currently performs permanent deletion (`FileManager.removeItem`) for cleanup targets.  
There is no recovery step in-app for removed items.

## Recommended Usage

- Start with preview scan.
- Keep `Only safe areas` enabled unless needed.
- Use exclusions for app folders you want to keep.
- Read terminal output and failure list after each run.
