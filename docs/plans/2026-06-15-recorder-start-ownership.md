---
title: Recorder Start Ownership
type: reliability
status: planned
date: 2026-06-15
---

# Recorder Start Ownership

## Problem Frame

`startRecording()` installs a `MediaRecorder` error listener before prepare and
start, but returns success unconditionally after `start()`. If the active error
callback releases and clears the recorder during startup, the click handler can
still switch the controls into an active recording state after the callback has
reset them. The playback path already prevents the analogous race by retaining
the starting player and returning success only while that instance remains
owned.

## Requirements

- Retain the recorder instance created for the current start attempt.
- Configure, prepare, and start through that retained instance.
- Return recording-start success only when the activity still owns the same
  recorder after `start()` returns.
- Preserve error cleanup, failed-file deletion, recorder identity guards,
  control resets, output location, lifecycle cleanup, and public behavior.
- Add mutation-sensitive portable contracts for retained recorder ownership and
  post-start success selection.
- Synchronize contributor, security, vision, readme, and change guidance.

## Implementation Units

### 1. Bind startup to the retained recorder

**Files:** `app/src/main/java/gpj/android_recorder/MainActivity.java`

Capture the newly assigned recorder in a local final reference, use it through
configuration and startup, and return whether the field still owns that exact
instance.

### 2. Enforce the startup ownership invariant

**Files:** `scripts/check-baseline.sh`

Require local recorder capture after assignment, require configuration and
start through that local reference, require retained identity as the success
condition, and preserve the existing callback ownership and cleanup ordering.

### 3. Document recorder startup reconciliation

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`

Record that successful startup requires retained recorder ownership so callback
cleanup cannot be overwritten by the click-handler transition.

## Verification

- Run the focused portable baseline checker and POSIX shell syntax validation.
- Run `make check` from the repository root and through the absolute Makefile
  path from an external directory.
- Reject hostile mutations that remove local ownership, restore field-based
  startup, or return unconditional success.
- Audit the exact diff, generated Android artifacts, whitespace, and changed
  lines for credential material before committing.
- Record Android SDK, emulator, microphone, and media-runtime limitations
  without claiming unexecuted behavior.

## Risks And Mitigations

- **Legacy API behavior:** keep the existing `MediaRecorder` sequence and error
  handling; only bind it to the retained instance and reconcile success.
- **Callback cleanup:** preserve the field identity guard so stale callbacks
  cannot release a newer recorder.
- **Stacked delivery:** base the pull request on the instrumentation compilation
  branch and retain base-first merge ordering.

## Out Of Scope

- Changing audio format, encoder, storage, permissions, or file naming.
- Replacing the legacy Android media APIs.
- Running an emulator, physical device, microphone, or playback scenario.
