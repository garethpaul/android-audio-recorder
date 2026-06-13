# Recorder Runtime Error Callback

Status: Completed

## Context

Recorder startup exceptions and explicit `stop()` failures delete incomplete
output, but an active `MediaRecorder` has no `OnErrorListener`. A platform
recording error after `start()` can therefore leave the UI in recording mode
and retain a capture that did not finalize normally.

## Requirements

- Install a `MediaRecorder.OnErrorListener` before recording starts.
- Ignore callbacks whose recorder instance is no longer the active recorder.
- Log a generic recorder error without path, platform code, or exception data.
- Release the owned recorder before deleting its incomplete output.
- Reset recording and playback controls after active-error cleanup.
- Preserve startup cleanup, explicit stop cleanup, pause interruption cleanup,
  storage, permissions, formats, and successful recording behavior.
- Add mutation-sensitive static coverage, documentation, and truthful
  verification evidence.

## Implementation Units

### U1: Handle Active Recorder Errors

**File:** `app/src/main/java/gpj/android_recorder/MainActivity.java`

Register the listener after recorder configuration and before `prepare()`. Use
instance identity to reject stale callbacks, then perform generic logging,
release, deletion, and UI reset in that order.

### U2: Extend Portable Contracts

**File:** `scripts/check-baseline.sh`

Require listener registration, ownership guard, non-reflective logging,
cleanup/reset ordering, regression markers, and completed plan evidence.

### U3: Document And Verify

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`, this plan

Document active recorder-error cleanup. Run local and external `make check`,
hostile mutations, available Android verification, and final diff, artifact,
credential, and exact-head hosted checks.

## Scope Boundaries

- Do not add `OnInfoListener`, automatic retries, multiple recordings, or new
  user-facing strings in this unit.
- Do not change codecs, sources, output paths, storage roots, permissions,
  Gradle dependencies, or legacy SDK levels.
- Do not claim emulator, physical-device, microphone, or forced recorder-error
  behavior without those runtime facilities.

## Verification Plan

- Run `make check` locally and from an external working directory.
- Prove hostile mutations for listener removal, post-start registration,
  ownership-guard removal, release/deletion/reset ordering, path/code logging,
  documentation drift, and incomplete-plan status fail.
- Run Android lint, Gradle tests, Java compilation, and debug assembly when the
  compatible SDK is available; otherwise record the local skip.
- Run `git diff --check`, generated-artifact inspection, and
  credential-shaped added-line scans.
- Record hosted evidence only after querying the exact pushed head.

## Source

- Android `MediaRecorder.OnErrorListener` API reference:
  https://developer.android.com/reference/android/media/MediaRecorder.OnErrorListener

## Verification

- Local and external-working-directory `make check` passed all SDK-free source,
  callback ownership, cleanup ordering, documentation, and repository
  contracts.
- Nine focused hostile mutations were rejected across listener registration
  and timing, stale ownership, generic logging, discard/reset presence and
  ordering, guidance, and completed-plan status. A callback-bounded checker fix
  was added after a precise reset-removal mutation exposed parser state leakage.
- No Android SDK is configured locally, so Android lint, Gradle tests, Java
  compilation, and debug assembly were truthfully skipped and remain required
  in hosted CI.
- Final diff, artifact, conflict-marker, credential-pattern, and whitespace
  inspection passed. Emulator, physical-device, microphone, and forced
  recorder-error behavior were not exercised.
- Hosted exact-head evidence remains pending push.
