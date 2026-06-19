# Recorder Failed-Start File Cleanup

Status: Completed

## Context

`MediaRecorder.prepare()` or `start()` may create or truncate the configured
output before throwing. The recorder catch paths release the media object and
leave controls idle, but they do not remove that partial app-local audio file.
The hidden artifact can persist even though the UI never exposes a playable
recording.

## Requirements

- **R1:** Route both checked startup failure paths through one cleanup helper.
- **R2:** Release `MediaRecorder` before attempting to delete the output file.
- **R3:** Delete an existing failed-start recording only after `setOutputFile`
  succeeded, and log only a generic message if deletion fails.
- **R4:** Preserve successful recording, stop, pause-interruption deletion,
  playback, app-specific storage, permissions, and idle-control behavior.
- **R5:** Extend SDK-free contracts and privacy documentation.
- **R6:** Record focused, mutation, SDK-backed, and hosted verification
  truthfully.

## Implementation Units

### U1: Centralize Failed-Start Cleanup

**File:** `app/src/main/java/gpj/android_recorder/MainActivity.java`

Add a helper that releases the recorder and then removes the configured output
when present. Invoke it from both `IOException` and `RuntimeException` startup
catch paths.

### U2: Enforce Ordering And Privacy

**File:** `scripts/check-baseline.sh`

Require both helper calls, release-before-delete ordering, an existence guard,
generic logging, and completed plan evidence.

### U3: Document And Verify

**Files:** `README.md`, `SECURITY.md`, `CHANGES.md`, this plan

Document that failed recorder startup does not retain a hidden partial capture.

## Test Scenarios

- Removing either catch-path cleanup call fails the checker.
- Deleting before recorder release fails the checker.
- Removing the existence guard or deletion call fails the checker.
- Logging the recording path or exception details fails the checker.
- Existing interrupted-recording cleanup and complete Android gates stay green.

## Scope Boundaries

- Do not change file location, file name, audio format, encoder, permissions,
  dependencies, SDK, Gradle, wrapper, or successful recording/playback flow.
- Do not claim emulator, device, or microphone behavior without those
  environments.

## Verification

- The SDK-free checker failed before implementation because neither startup
  catch path used the failed-output cleanup helper.
- Nine hostile mutations were rejected: removing either cleanup call, moving
  release after deletion, removing the output-configured guard, removing the
  existence guard, removing deletion, logging the recording path, removing
  security guidance, and removing this canonical plan.
- SDK-backed `make check` passed with Amazon Corretto 8 and
  `/home/gjones/android-sdk`, including lint, debug/release unit-test tasks,
  Java compilation, and debug APK assembly. Lint retained the single documented
  `OldTargetApi` compatibility warning.
- External-directory `make check`, workflow YAML parsing, shell syntax, secret
  scanning, and `git diff --check` passed.
- Emulator, physical-device, microphone, and filesystem-failure behavior remain
  platform validation boundaries.
