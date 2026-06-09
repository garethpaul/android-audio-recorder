---
title: Recorder Startup UI State
type: reliability
status: completed
date: 2026-06-09
---

# Recorder Startup UI State

## Problem Frame

Recorder and player startup can fail when microphone permission, the media
stack, or the recording file is unavailable. The click handlers still switched
the controls to stop-recording or stop-playback state after those failures,
which left the UI claiming an active media operation that had already been
released.

## Scope Boundaries

- Preserve the legacy Android activity and button layout.
- Keep existing media cleanup behavior and app-specific recording storage.
- Do not add runtime permission handling in this pass.
- Keep verification available without an Android SDK.

## Implementation Units

### U1: Return Startup Success

Files:

- Modify `app/src/main/java/gpj/android_recorder/MainActivity.java`

Approach:

- Make record and play dispatch return whether startup succeeded.
- Make `startRecording()` and `startPlaying()` return `true` only after media
  startup completes.
- Return `false` after guarded prepare/start failures and cleanup.

### U2: Gate UI Transitions

Files:

- Modify `app/src/main/java/gpj/android_recorder/MainActivity.java`

Approach:

- Switch the record button to stop state only when recording starts.
- Switch the play button to stop state only when playback starts.
- Keep stop branches resetting controls after cleanup.

### U3: Cover And Document The Guard

Files:

- Modify `scripts/check-baseline.sh`
- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Add SDK-free contracts for success-returning media dispatch.
- Document the startup-failure UI behavior with the existing recorder
  maintenance notes.

## Verification

- `scripts/check-baseline.sh`
- `make lint`
- `make test`
- `make build`
- `make check`
- `make verify`
- `git diff --check`
