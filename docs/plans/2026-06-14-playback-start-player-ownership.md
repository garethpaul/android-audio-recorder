# Reconcile Playback Start With Active Player Ownership

Status: Completed

## Context

`startPlaying()` returns success immediately after `MediaPlayer.start()`. An
immediate error callback can release the active player and reset the controls
before `start()` returns, after which the click handler treats the stale return
value as success and restores the playing state.

## Scope

- Keep a local reference to the player being started.
- Return playback-start success only while that exact player remains active.
- Preserve preparation failures, runtime failures, stale callback rejection,
  completion cleanup, manual stop, and pause cleanup.
- Add mutation-sensitive portable contracts and maintenance documentation.

## Verification

- Run the SDK-free checker and full Android `make check` when the pinned SDK and
  JDK are available.
- Run the portable gate from an external working directory with Android SDK
  variables unset.
- Reject mutations that remove or weaken exact-player ownership, ordering,
  documentation, or completed-plan evidence.
- Audit the exact diff, generated artifacts, changed-line secret patterns, and
  whitespace before committing.

## Risks

- This remains source- and build-level validation; no emulator, physical
  device, speaker, or corrupt-media callback timing is claimed.
- PRs in the existing stack remain open and must not be merged or closed without
  explicit owner authorization.

## Verification Results

Completed on 2026-06-14:

- SDK-backed `make check` passed the source gate, debug and release Java
  compilation, Android lint, Gradle test tasks, and debug APK assembly under
  Amazon Corretto 8 and Android API 22. Lint retained one existing
  `OldTargetApi` warning and no errors.
- External-working-directory `make check` passed the portable source gate with
  Android SDK variables intentionally unset.
- Nine hostile mutations were rejected when they detached or inverted player
  ownership, started through the mutable field, restored unconditional success,
  removed maintained documentation, or reopened this plan.
- Exact diff, generated-artifact, changed-line secret-pattern, and whitespace
  audits passed before commit.
- No emulator, physical device, speaker, or corrupt-media runtime was used.
