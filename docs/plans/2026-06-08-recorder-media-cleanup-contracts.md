---
title: Recorder Media Cleanup Contracts
status: completed
date: 2026-06-08
origin: user-requested continuous engineering quality loop
execution: code
---

# Recorder Media Cleanup Contracts

## Problem Frame

The recorder sample releases media objects in a few places, but failed
prepare/start/stop paths can leave `MediaRecorder` or `MediaPlayer` instances
allocated. The refreshed README also dropped the exact baseline commands that
`scripts/check-baseline.sh` expects.

## Scope Boundaries

- Preserve the existing external-storage recording path and UI flow.
- Do not migrate runtime permissions, scoped storage, Gradle, or media APIs.
- Keep verification SDK-free unless Android tooling is explicitly available.

## Implementation Units

### U1: Static Cleanup Contracts

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Require centralized recorder/player release helpers.
- Require guarded runtime failure paths.

### U2: Media Cleanup Refactor

Files:

- Modify `app/src/main/java/gpj/android_recorder/MainActivity.java`
- Modify `README.md`
- Modify `CHANGES.md`

Approach:

- Release recorder/player instances through helpers.
- Guard recorder/player runtime stop/start failures.
- Restore README baseline and nested Gradle command documentation.

## Verification

- `scripts/check-baseline.sh`
- `git diff --check`
