# Recorder Output Ownership Boundary

Status: Planned

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

- Run `sh scripts/check-baseline.sh` first.
- Run bounded SDK-backed `make check` with the configured Java 8 and Android
  SDK toolchain when available.
- Reject mutations that place the marker before output configuration, restore
  the stale post-encoder ordering, remove either catch cleanup, or reopen this
  plan.

## Scope Boundaries

- Do not change codecs, formats, filenames, storage roots, permissions,
  dependencies, Gradle, workflows, UI controls, or successful runtime flow.
- Do not claim emulator, device, microphone, or forced platform-failure
  behavior without those environments.
- Do not merge or close any pull request without explicit owner authorization.
