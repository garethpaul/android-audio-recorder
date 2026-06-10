# Recorder Stop Result

Status: Completed

## Context

`MediaRecorder.stop()` can throw when a capture is too short or otherwise
cannot be finalized. The recorder caught that failure but still returned
success through `onRecord(false)`, causing the play button to appear for an
incomplete or corrupt recording.

## Changes

- Return a success flag from `stopRecording()` only after `MediaRecorder.stop()`
  completes.
- Propagate that result through `onRecord(false)`.
- Expose playback only when recording finalization succeeds.
- Reset recording and playback controls to idle after a finalization failure.
- Extend the SDK-free baseline with stop-result and documentation contracts.

## Verification

- `make check`
- Static mutations for unconditional stop success and unguarded playback UI
- `git diff --check`

The Android SDK is unavailable on this host, so device-level short-recording
failure behavior still requires verification with a compatible Android
toolchain.
