# Recorder Startup Control Guards

## Status: Completed

## Context

`MainActivity.onCreate` assumed the optional action bar and both record/play
`ImageButton` controls were always available. Legacy theme or layout changes
could crash startup before media controls are wired.

## Objectives

- Preserve existing recorder setup for valid layouts.
- Guard the optional action bar before setting title/icon state.
- Look up both record and play controls before wiring listeners.
- Skip listener setup with a non-sensitive log message when controls are
  unavailable.
- Keep the SDK-free baseline check covering the startup guards.

## Work Completed

- Added an `ActionBar` local and null guard before action-bar updates.
- Moved record/play button lookup before listener wiring.
- Added a record/play control null guard with a clear log message.
- Extended `scripts/check-baseline.sh`.
- Updated README, VISION, and CHANGES.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`

On this workspace, `make check` completed the legacy Gradle lint, test, and
debug assemble tasks with the configured Android SDK.

## Follow-Up Candidates

- Move recording-state tracking out of the local `mStartRecording` array.
- Add runtime microphone permission handling for modern Android versions.
