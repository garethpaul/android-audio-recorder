# Interrupted Recording Cleanup

Status: Completed

## Context

The activity finalizes an active recording when `onPause()` runs, then resets
the controls to their idle state. The finalized file remains in app-specific
storage even though the resumed UI no longer offers that interrupted capture
for playback. Backgrounding the app can therefore retain microphone audio that
the user did not explicitly finish and cannot access through the visible flow.

## Prioritized Engineering Backlog

1. Delete pause-interrupted captures after guarded recorder finalization.
2. Enforce the lifecycle deletion contract in the SDK-free baseline.
3. Add device-level lifecycle coverage when a compatible Android toolchain and
   emulator are available.

## Objectives

- Route only active pause-time recording cleanup through a dedicated discard
  helper.
- Reuse `stopRecording()` so recorder stop failures remain caught and media
  resources are always released before deletion is attempted.
- Delete the app-specific recording file after finalization and log a generic
  error when deletion fails.
- Preserve recordings completed by the user through the record button.
- Document and statically verify the interrupted-capture privacy boundary.

## Implementation Units

### U1: Lifecycle discard behavior

Files:

- `app/src/main/java/gpj/android_recorder/MainActivity.java`

Add a focused helper that invokes the existing guarded stop path before
deleting the configured recording file. Call it only from the active-recorder
branch in `onPause()`.

### U2: Durable contract and verification

Files:

- `scripts/check-baseline.sh`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`
- `docs/plans/2026-06-12-interrupted-recording-cleanup.md`

Extend the canonical checker and documentation so future changes cannot retain
pause-interrupted audio or bypass guarded finalization. Record completed status
and actual verification only after all gates pass.

## Verification

- Focused source inspection confirmed guarded stop precedes deletion and
  `onPause()` routes active recording through the discard helper.
- `sh -n scripts/check-baseline.sh` passed.
- `make test` and `make build` completed with their documented Android SDK
  skip because no SDK is configured on this host.
- `make lint`, `make verify`, and `make check` passed through the SDK-free
  baseline.
- Focused source mutations removing the discard call, guarded stop, or file
  deletion were rejected.
- `git diff --check` passed.

## Boundaries

- Do not execute microphone capture or require Android SDK/device access.
- Do not delete recordings completed explicitly through the record button.
- Do not change storage paths, media formats, button behavior, or Gradle
  dependencies.
