# Changes

## 2026-06-10

- Added a lightweight GitHub Actions workflow that runs `make check` for the
  recorder source baseline with immutable checkout, read-only permissions, and
  a bounded timeout.
- Extended the SDK-free baseline to require the CI workflow and completed CI
  plan.
- Removed the maintainer-specific Android SDK path from the Makefile.
- Cleared hosted Android SDK variables so the SDK-free CI job cannot
  accidentally enter the legacy Gradle path.

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
