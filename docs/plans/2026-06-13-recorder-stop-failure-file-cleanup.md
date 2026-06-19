# Recorder Stop-Failure File Cleanup

Status: Completed

## Priority

Failed startup and pause-interrupted recordings already delete partial audio,
but an explicit `MediaRecorder.stop()` failure only hides playback and leaves
the improperly constructed app-local file on disk. Android documents this
runtime failure as the signal for applications to clean up the output file.
Closing that privacy and storage gap is the next bounded recorder priority.

## Requirements

- **R1:** Delete the current recording file after explicit stop fails for an
  active recorder.
- **R2:** Release the recorder before deleting its output and keep the cleanup
  failure log generic without exposing the recording path.
- **R3:** Preserve a prior valid recording when `stopRecording()` is called
  without an active recorder.
- **R4:** Preserve successful finalization, playback exposure, failed-start
  cleanup, pause-interruption cleanup, app-specific storage, and UI behavior.
- **R5:** Add fail-closed SDK-free contracts, documentation, and hostile
  mutation coverage for the active-recorder guard and release/delete order.
- **R6:** Record truthful local, external-directory, hosted Android, mutation,
  emulator/device, microphone, and forced-deletion-failure evidence.

## Implementation Units

### U1: Delete Failed Finalization Output

**File:** `app/src/main/java/gpj/android_recorder/MainActivity.java`

Track whether a recorder existed when stopping. After the guarded stop and
release, delete the output only when that recorder existed and stop did not
succeed. Use a stable path-free cleanup warning.

### U2: Enforce The Failure Boundary

**File:** `scripts/check-baseline.sh`

Require the active-recorder guard, successful-stop result, release-before-
delete order, existence/deletion checks, generic warning, and regression plan.

### U3: Document And Verify

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
`docs/plans/2026-06-13-recorder-stop-failure-file-cleanup.md`

Document that incomplete explicit-stop output is removed while prior valid
recordings are preserved when no recorder is active. Record actual verification.

## Test Scenarios

- An active recorder whose `stop()` throws is released and its output is
  deleted before playback can be exposed.
- Successful stop retains the finalized file for playback.
- Calling stop without an active recorder does not delete an older valid file.
- Deletion failure logs a generic category without the path.
- Removing the active-recorder guard, failure condition, release ordering,
  existence/deletion check, guidance, or completed-plan status fails checks.

## Scope Boundaries

- Do not change recorder formats, codecs, sources, filenames, storage roots,
  permissions, UI icons, playback behavior, dependencies, or legacy SDK levels.
- Do not claim emulator, device, microphone, or forced filesystem-deletion
  behavior without the corresponding runtime environment.

## Verification

- Isolated, canonical, and external-directory SDK-backed `make check` passed
  the source contracts, debug/release Java compilation, Android lint with the
  one documented `OldTargetApi` compatibility warning, debug/release Gradle
  test tasks, and debug APK assembly.
- Eight hostile mutations were rejected: active-recorder guard removal,
  failed-stop condition removal, result-propagation removal, release reordering,
  deletion removal, path logging, security-guidance removal, and plan rollback.
- Shell syntax and `git diff --check` passed.
- Emulator, physical-device, microphone, and forced filesystem-deletion failure
  behavior were not exercised because those runtime facilities are unavailable.

## Source

- Android `MediaRecorder.stop()` API reference:
  https://developer.android.com/reference/android/media/MediaRecorder#stop()
