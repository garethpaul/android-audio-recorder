# Recording File Ownership Review

Status: Completed.

## Problem

The recorder wrote every attempt directly to `audiorecordtest.3gp`. A new
attempt could truncate the last valid recording before `prepare()` or `start()`
succeeded, and the existing failure cleanup then deleted that shared path.
Playback completion also hid the still-valid recording, while recorder/player
release left field ownership attached until after potentially failing platform
calls.

## Design

- Store microphone audio under internal app storage.
- Record into an owner-only fixed pending file.
- On successful stop, move the current finalized file to a rollback backup,
  promote pending output, then delete the backup.
- On startup, restore a lone backup and delete interrupted pending output.
- Reject symlink, directory, and escaped-path collisions before cleanup.
- Detach exact recorder/player ownership before stop or release.
- Keep finalized playback visible after completion and failed replacement.
- Request transient playback audio focus and abandon it on every terminal path.

## Evidence

- RED: the host storage test could not compile before the storage owner existed.
- GREEN: host Java behavior tests cover failed-attempt preservation, successful
  replacement, interrupted promotion recovery, owner-only permissions, and
  symlink collision rejection.
- Android instrumentation compiles a real app-files storage preservation test.
- Lifecycle source contracts cover pending output, exact ownership, replay
  controls, internal storage, launcher export, and audio focus.
- Nine hostile mutations must be rejected by the host gate.
- Aggregate PR #17 passed the hosted Android `check` and CodeQL Actions and
  Java/Kotlin jobs at reviewed head
  `1ba4fb8382abb5e5a31395920b7ab02397356e80`, then merged as
  `263c3c2232818d65f7094ae766397dabfff4f46d`.
- The official Gradle 8.14.5 wrapper JAR SHA-256 is
  `7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172`.
- Gradle publishes the 2.2.1 all-distribution SHA-256 as
  `1d7c28b3731906fd1b2955946c1d052303881585fc14baedd675e4cf2bc1ecab`.

## Unverified Runtime Boundaries

No microphone, physical device, emulator, runtime permission denial, audio
focus competition, process kill during promotion, or legacy Android SDK runtime
was available locally. Hosted checks compile the app and instrumentation APK;
they do not execute microphone/media device behavior.
