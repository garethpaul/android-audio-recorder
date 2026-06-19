# Changes

## 2026-06-19

- Prevented failed or interrupted recording attempts from overwriting the last
  finalized capture by adding owner-private pending, rollback, and recovery files.
- Moved sensitive microphone output to internal app storage, tightened file
  permissions, and rejected symlink, directory, and stale-state collisions.
- Detached recorder and player ownership before release, added release guards,
  and kept finalized audio replayable after completion or failed replacement.
- Added transient playback audio-focus ownership and focus-loss cleanup.
- Added host Java behavior tests, Android instrumentation storage coverage,
  lifecycle contracts, and nine hostile mutations to the canonical gate.

## 2026-06-15

- Added an explicit launcher export boundary for the sole `MAIN`/`LAUNCHER`
  activity and extended the byte-exact audited manifest contract.
- Reconciled recording startup success only while the exact started recorder
  remains owned, preventing immediate error cleanup from being overwritten by stale controls.

## 2026-06-14

- Added an instrumentation bootstrap assertion that creates the application and
  verifies the recorder package identity.
- Added instrumentation APK compilation to the canonical test gate so hosted
  checks reject stale or uncompilable Android-test source.
- Reconciled playback startup success only while the exact started player
  remains active, preventing immediate errors from restoring stale controls.
- Playback startup failures restore record-ready controls instead of leaving
  the user on a play-only failure state.
- Output ownership begins immediately after setOutputFile succeeds, closing
  the failed-cleanup gap before audio encoder configuration.
- Added mutation-sensitive ordering and completed-plan contracts for the
  recorder output ownership boundary.
- Added an exact-commit recorder device verification matrix for microphone
  startup, output cleanup, recording, playback, lifecycle, storage, and
  privacy-safe evidence, with every runtime row explicitly unexecuted.

## 2026-06-13

- Deleted partial app-local audio left by a failed recorder startup after first
  releasing the `MediaRecorder`.
- Added ordering, generic-log, documentation, and completed-plan contracts for
  both checked startup failure paths.
- Explicit stop failures delete improperly finalized app-local audio after
  recorder release while preserving prior output if no recorder was active.
- Guarded completion and error listeners against stale MediaPlayer callbacks
  before they can release or reset a newer playback session.
- Added mutation-sensitive callback identity and ordering contracts.
- Added owned runtime handling for active MediaRecorder errors with generic
  logging, release-before-delete cleanup, and idle control reset.

## 2026-06-12

- Regenerated the wrapper bootstrap with official Gradle 8.14.5 tooling while
  retaining the Gradle 2.2.1 Android runtime, and pinned the official
  distribution checksum.
- Extended the SDK-free exact wrapper contract and documented its online
  dependency boundary.
- Deleted pause-interrupted recordings after guarded recorder finalization so
  backgrounding cannot retain microphone audio hidden by the reset UI.
- Guarded recorder construction and all media configuration calls alongside
  prepare/start so permission, device-state, storage, and encoder failures
  release partial resources instead of escaping the click handler.
- Added SDK-free startup ordering contracts and a completed implementation
  plan.
## 2026-06-10

- Routed pause-time media cleanup through guarded recorder/player stop methods
  so active recording containers can finalize before release.
- Propagated recorder stop failures to the control state so incomplete captures
  are not exposed for playback.
- Made root checks location-independent, accepted `ANDROID_SDK_ROOT`, and
  pinned CI to Ubuntu 24.04 with superseded-run cancellation.
- Added a lightweight GitHub Actions workflow that runs `make check` for the
  recorder source baseline with immutable checkout, read-only permissions, and
  a bounded timeout.
- Extended the SDK-free baseline to require the CI workflow and completed CI
  plan.
- Removed the maintainer-specific Android SDK path from the Makefile.
- Cleared hosted Android SDK variables so the SDK-free CI job cannot
  accidentally enter the legacy Gradle path.
- Disabled persisted checkout credentials and replaced substring workflow
  checks with one canonical, single-workflow security contract.
- Made canonical workflow comparison byte-exact, added ownership for CI,
  Gradle, and the complete app tree, and locked the legacy Gradle/module layout.
- Rejected alternate manifests, local Android binary dependencies, and direct
  network clients in the SDK-free privacy baseline.
- Enforced the exact microphone-only manifest, rejected protected-path
  symlinks and packaged binaries, and recorded Gradle wrapper hashes.
- Removed an inaccurate generated device preview that did not represent the
  recorder's two-button interface.

## 2026-06-09

- Reset playback controls and release the player when media playback reports an
  error, with an SDK-free baseline contract.
- Moved recording-state tracking out of the record-button listener closure and
  reset recorder controls during lifecycle cleanup.
- Added an SDK-free baseline contract for recording-state reset behavior.
- Guarded recorder startup when the action bar or record/play controls are
  unavailable, with an SDK-free baseline contract.
- Reset playback controls automatically when media playback completes and added
  an SDK-free contract for the completion listener.
- Kept recorder controls in their idle state when media recording or playback
  startup fails, with an SDK-free contract for the success-gated UI transition.
- Disabled Android backup for the recorder app and added an SDK-free manifest
  contract for the audio privacy baseline.
- Moved recordings into app-specific storage with an internal fallback and
  removed the broad `WRITE_EXTERNAL_STORAGE` permission.

## 2026-06-08

- Added `make check` as the root wrapper for recorder source, lint, test, and
  debug build verification.
- Added a repository changelog and expanded the documented Android verification
  gate to include lint, tests, and debug assembly.
- Cleaned Android lint findings by removing unused starter resources, moving
  bitmap assets to `drawable-nodpi`, documenting the nodpi lint baseline, and
  adding button accessibility labels.
- Moved the recorder background color into the app theme to avoid root-layout
  overdraw.
- Added recorder/player cleanup contracts so failed media prepare/start/stop
  paths release resources predictably.
- Corrected the recorder's initial record/play button icons and added an
  SDK-free baseline guard for the first-render button state.
