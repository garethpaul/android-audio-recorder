# Recorder Pause Finalization

Status: Completed

## Goal

Finalize active audio recording before lifecycle cleanup releases media
resources when the activity pauses.

## Requirements

- `onPause()` routes active recording through the guarded stop path.
- `onPause()` routes active playback through the guarded stop path.
- Lifecycle cleanup does not call release helpers directly.
- Existing stop methods continue to catch runtime failures and release media.
- The SDK-free baseline enforces pause-time finalization.
- Root Make targets work outside the checkout and accept either Android SDK
  environment variable.
- Hosted verification uses a fixed runner and cancels superseded runs.

## Implementation

- Replace direct `releaseRecorder()` and `releasePlayer()` calls in `onPause()`
  with `stopRecording()` and `stopPlaying()`.
- Extract and inspect the pause method in `scripts/check-baseline.sh`.
- Resolve Make paths from the Makefile location and normalize
  `ANDROID_HOME`/`ANDROID_SDK_ROOT` for the legacy Gradle wrapper.
- Pin GitHub Actions to Ubuntu 24.04 and add workflow concurrency.

## Verification

- `make check`
- `make -f /absolute/path/to/Makefile check` from outside the repository
- pause-finalization and automation mutation checks
- shell syntax checks
- `git diff --check`

The Android SDK is not available on this host, so device-level recording
finalization still requires verification with the legacy-compatible toolchain.
