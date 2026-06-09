# Recorder Recording Lifecycle Reset

Date: 2026-06-09
Status: Completed

## Problem

Recording state lived in an `onCreate` listener-local boolean array. When
`onPause()` released the recorder, the UI and click handler could still think a
recording was active, leaving stale stop controls after media resources had
already been cleaned up.

## Scope

- Track recording state as an activity field.
- Add a centralized recording-control reset helper.
- Reset recording and playback controls during lifecycle cleanup after media
  resources are released.
- Preserve existing startup-failure and playback-completion behavior.

## Verification

- Red: `make lint` failed on the missing field-backed recording-state reset.
- Green: `make lint` passes after adding the lifecycle reset.
- Full gate: `make check`.
