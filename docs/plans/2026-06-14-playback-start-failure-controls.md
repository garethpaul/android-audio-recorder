# Restore Controls After Playback Start Failure

Status: Planned

## Context

`startPlaying()` safely catches media preparation and startup failures, releases
the player, and returns `false`. The play-button handler only updates controls
on success, so a missing, corrupt, or unreadable recording leaves the play
button visible and the record button hidden. The user can retry the same failed
playback but cannot return to recording without leaving the activity.

## Scope

- Restore record-ready controls whenever playback startup returns `false`.
- Preserve successful playback, manual stop, completion, error callback, and
  pause cleanup behavior.
- Keep media exceptions generic and free of file paths or dependency details.
- Add mutation-sensitive portable contracts and maintenance documentation.

## Implementation Units

### 1. Reconcile failed playback startup

Files:

- `app/src/main/java/gpj/android_recorder/MainActivity.java`

Add the missing failure branch beside the successful `onPlay(true)` path and
reuse `resetPlaybackControls()` so the play button is hidden, the record button
is visible, and `mStartPlaying` remains ready for a future valid recording.

### 2. Protect the control transition

Files:

- `scripts/check-baseline.sh`
- `docs/plans/2026-06-14-playback-start-failure-controls.md`

Require success and failure branches, failure-path control reset, ordering, and
completed verification evidence in the SDK-free checker.

### 3. Document the failure behavior

Files:

- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`

Record that playback startup failures return the UI to recording without
logging app-local file paths.

## Verification

To be recorded after implementation:

- SDK-free contract checker and Java 8/API 22 Gradle gates.
- Repository-root and external-directory `make check`.
- Isolated source, ordering, documentation, and plan mutations.

## Risks

- A failed playback attempt now hides the play control, requiring a new
  recording before another attempt; this avoids trapping users on known-bad
  media.
- No emulator, physical device, microphone, or speaker behavior is claimed by
  local static and build verification.
