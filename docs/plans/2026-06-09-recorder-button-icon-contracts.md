---
title: Recorder Button Icon Contracts
type: reliability
status: completed
date: 2026-06-09
---

# Recorder Button Icon Contracts

## Problem Frame

The recorder layout initializes the visible record button with the play icon and
the hidden play button with the record icon. Runtime click handlers later swap
icons, but the first-render state is misleading and not covered by the
SDK-free baseline check.

## Scope Boundaries

- Preserve the existing two-button layout and click handlers.
- Do not change recording, playback, file storage, or permission behavior.
- Keep verification available without an Android SDK.

## Implementation Units

### U1: Correct Initial Button Icons

Files:

- Modify `app/src/main/res/layout/activity_main.xml`

Approach:

- Initialize the record button with `@drawable/record`.
- Initialize the play button with `@drawable/play`.
- Preserve existing visibility, accessibility labels, sizing, and positioning.

### U2: Extend SDK-Free Baseline Checks

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Assert the record button starts with the record icon.
- Assert the play button starts with the play icon and remains initially hidden.

### U3: Document The UI Contract

Files:

- Modify `README.md`
- Modify `CHANGES.md`
- Modify `VISION.md`

Approach:

- Record that the baseline check covers the recorder's first-render button
  state.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`

Gradle verification remains dependent on a compatible Android SDK.
