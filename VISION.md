## Android Audio Recorder Vision

This document explains the current state and direction of the project.
Project overview and developer docs: [`README.md`](README.md)

Android Audio Recorder is a legacy Android sample that records audio to
external storage and plays it back.

The repository is useful as a compact example of pre-runtime-permission Android
media capture and playback. Project setup and verification notes live in
[`README.md`](README.md).

The goal is to keep the sample buildable and understandable while making future
storage, permission, and media API modernization deliberate.

The current focus is:

Priority:

- Preserve the documented Gradle 2.2.1 and Android Gradle Plugin 1.2.3 stack
- Keep audio record/playback behavior easy to inspect
- Maintain the SDK-free baseline check for quick source verification
- Keep recorder controls visually aligned with the action they trigger
- Keep recorder startup safe when optional UI chrome or controls are missing
- Keep recorder controls from entering active states when media startup fails
- Keep recorder construction and configuration failures inside guarded cleanup
- Output ownership begins immediately after setOutputFile succeeds so every
  later configuration failure removes incomplete output
- Reset playback controls automatically when media playback completes
- Reset playback controls automatically when media playback errors
- Ignore stale MediaPlayer callbacks before they affect current playback state
- Ignore stale callbacks and clean up incomplete output on active MediaRecorder errors
- Reset recorder controls when lifecycle cleanup releases recording resources
- Expose playback only after recording finalization succeeds
- Finalize active recording and playback through guarded stop paths on pause
- Delete pause-interrupted microphone captures after guarded finalization
- Explicit stop failures delete incomplete audio only after recorder release
  and only when an active recorder existed
- Keep local recorder app state out of Android backups by default
- Keep recordings in app-specific storage unless a documented user-facing export
  flow is added
- Keep the SDK-free `make check` baseline running in GitHub Actions
- Keep the legacy Gradle runtime behind a checksum-verified generated wrapper
- Keep exact-commit recorder device evidence separate from portable contracts,
  with unexecuted microphone and media scenarios recorded explicitly

Next priorities:

- Add runtime permission handling for microphone and storage access
- Move storage behavior to modern scoped-storage-compatible APIs
- Add Android tests around recording, playback dispatch, and lifecycle handling
- Evaluate Gradle runtime, SDK, plugin, and dependency modernization together
  in a dedicated compatibility pass; wrapper bootstrap hardening is separate
- Execute the recorder device verification matrix across representative Android
  versions with privacy-safe evidence

Contribution rules:

- One PR = one focused change.
- Run `scripts/check-baseline.sh` before pushing.
- Run `./gradlew tasks --no-daemon` and `./gradlew assembleDebug --no-daemon`
  when a compatible Android SDK is configured.
- Keep behavior changes small enough to verify on a device or emulator.

## Security And Privacy

Canonical security policy and reporting:

- [`SECURITY.md`](SECURITY.md)

Recorded audio is sensitive. Changes must avoid logging recording contents,
leaking file paths unnecessarily, or broadening storage access beyond what the
sample requires.

Do not commit local SDK paths, generated audio files, or device-specific data.

## What We Will Not Merge (For Now)

- Broad rewrites that mix media behavior with build-system migration
- Permission work that requests more access than the sample needs
- Storage changes without notes about Android version behavior
- Test or verification removals without a replacement gate

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
