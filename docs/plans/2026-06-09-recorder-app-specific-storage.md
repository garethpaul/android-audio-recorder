# Recorder App-Specific Storage

## Status: Completed

## Context

The recorder built its output path in the activity constructor from
`Environment.getExternalStorageDirectory()`, placing `audiorecordtest.3gp` at
the external storage root and requiring broad `WRITE_EXTERNAL_STORAGE`
permission even though the app targets API 21.

## Objectives

- Keep the existing single-file record/playback behavior.
- Store recordings under app-specific storage instead of the shared external
  storage root.
- Fall back to app-internal storage if app-specific external files are
  unavailable.
- Remove the broad write permission while preserving microphone access.
- Protect the behavior with SDK-free baseline checks.

## Work Completed

- Moved recording path configuration into `onCreate()`, after activity context
  APIs are available.
- Added app-specific external files storage with `getExternalFilesDir(null)` and
  an internal `getFilesDir()` fallback.
- Removed `WRITE_EXTERNAL_STORAGE` from the manifest.
- Extended `scripts/check-baseline.sh` to enforce app-specific storage,
  microphone permission, and absence of root external-storage writes.
- Updated README, VISION, and CHANGES notes for the storage contract.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`

Gradle lint, tests, and debug assembly still require `ANDROID_HOME` to point to
a compatible Android SDK.
