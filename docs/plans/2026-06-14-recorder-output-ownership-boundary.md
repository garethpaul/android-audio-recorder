# Recorder Output Ownership Boundary

Status: Completed

## Problem

Recorder startup marks the output as configured only after
`setAudioEncoder()` succeeds. The failed-start cleanup contract instead begins
when `setOutputFile()` succeeds. If encoder configuration throws in that gap,
the catch path can release the recorder without deleting an incomplete output.
The dependency-free checker currently preserves the same incorrect ordering.

## Requirements

1. Mark output ownership immediately after `setOutputFile()` returns.
2. Keep both startup exception paths routed through the existing guarded
   failed-output cleanup helper.
3. Preserve recorder configuration order, successful capture and playback,
   explicit-stop cleanup, pause cleanup, callback ownership, storage, and UI
   behavior.
4. Make the portable baseline reject moving the ownership marker before
   `setOutputFile()` or after `setAudioEncoder()`.
5. Pass focused, full, mutation, whitespace, artifact, and credential audits;
   record Android SDK and runtime coverage truthfully.

## Implementation

- Move `outputConfigured = true` directly below `setOutputFile()`.
- Correct the startup-order assertion in `scripts/check-baseline.sh`.
- Document the strengthened partial-output cleanup boundary in project and
  security guidance.

## Verification

- `sh scripts/check-baseline.sh` passed the corrected source, ordering,
  documentation, and completed-plan contracts.
- Bounded SDK-backed `make check` passed with Amazon Corretto 8 and Android API
  22. It completed debug/release Java compilation, Android lint with the one
  documented legacy warning, debug/release unit-test tasks, and debug APK
  assembly.
- Six hostile mutations were rejected: moving the marker before output
  configuration, restoring the stale post-encoder ordering, removing either
  catch cleanup, removing security guidance, and reopening this plan.
- Shell syntax and `git diff --check` passed. Generated build output is removed
  before commit, and changed-line credential scanning is required in the final
  audit.
- Emulator, physical-device, microphone, and forced encoder-configuration
  failure behavior were not exercised.

## Scope Boundaries

- Do not change codecs, formats, filenames, storage roots, permissions,
  dependencies, Gradle, workflows, UI controls, or successful runtime flow.
- Do not claim emulator, device, microphone, or forced platform-failure
  behavior without those environments.
- Do not merge or close any pull request without explicit owner authorization.
