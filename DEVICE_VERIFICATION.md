# Android Audio Recorder Device Verification

Run this matrix on the exact reviewed commit with a compatible Android SDK,
Java 8, legacy Gradle runtime, and an authorized emulator or physical device.
Portable contracts do not substitute for microphone, storage, or media evidence.

## Evidence Header

Record these values without recordings, file paths, device identifiers, logs,
APKs, signing material, or account data:

- commit SHA and pull request
- tester and UTC timestamp
- Android Studio, SDK, build tools, Java, and Gradle versions
- emulator image or physical-device model and Android version
- clean install or upgrade path
- Gradle lint, test, and assemble result

Mark every row `pass`, `fail`, `blocked`, or `not run`. Explain blocked and
unexecuted rows. Do not convert `not run` into passing evidence.

## Permission And Startup Matrix

| Scenario | Expected result | Result | Evidence |
| --- | --- | --- | --- |
| Microphone available | Recording starts and controls enter recording state. | not run | |
| Microphone unavailable | Startup fails without leaving active controls or output. | not run | |
| Recorder construction failure | Partial resources release and no file remains. | not run | |
| Encoder/configuration failure | Owned output is deleted after release. | not run | |
| Prepare/start failure | UI returns idle, pending output is removed, and prior finalized audio remains playable. | not run | |
| Microphone permission denied/revoked | Startup fails closed without retaining pending audio. | not run | |

This legacy target predates modern runtime-permission behavior. Record the exact
Android version and observed permission path; do not claim current-platform
permission safety without a dedicated modernization change.

## Recording And Playback Matrix

| Scenario | Expected result | Result | Evidence |
| --- | --- | --- | --- |
| Record then stop | Finalized app-local file becomes playable. | not run | |
| Explicit stop failure | Incomplete pending output is deleted and prior finalized audio remains replayable. | not run | |
| Pause during recording | Interrupted capture is finalized defensively then deleted. | not run | |
| Playback completion | Player releases once, audio focus is abandoned, and replay remains available. | not run | |
| Playback error | Current player releases and controls reset generically. | not run | |
| Stale player callback | Old callback cannot alter the current player or controls. | not run | |
| Recorder runtime error | Current recorder releases, deletes output, and resets controls. | not run | |

## Lifecycle And Storage Matrix

| Scenario | Expected result | Result | Evidence |
| --- | --- | --- | --- |
| Rotate while idle | Controls remain consistent without leaked media objects. | not run | |
| Rotate while recording | Hidden interrupted audio is not retained. | not run | |
| Background during playback | Active playback stops through guarded cleanup. | not run | |
| Audio focus loss | Exact active player stops, releases, and restores replay-ready controls. | not run | |
| Process recreation | Missing in-memory ownership fails closed. | not run | |
| Internal storage inspection | Pending, backup, and finalized captures remain owner-only and backups stay disabled. | not run | |
| Interrupted promotion recovery | Prior finalized audio is restored and stale pending output is deleted. | not run | |

Sanitized logs must not contain recording paths, audio contents, device details,
encoder configuration values, or exception messages.

## Completion

Record unresolved failures and protected evidence links outside git. A runtime
claim requires all applicable rows to pass on the exact commit. This repository
currently records every recorder device and media row as unexecuted.
