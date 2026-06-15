# android-audio-recorder

<!-- README-OVERVIEW-IMAGE -->
![Project overview](docs/readme-overview.svg)

## Overview

`garethpaul/android-audio-recorder` is an Android application or sample. A simple audio recorder for Android.

This README is based on the checked-in source, manifests, scripts, and repository metadata on the `master` branch. The project language mix found during review was: Java (2), shell (1).

## Repository Contents

- `README.md` - project overview and local usage notes
- `.github/workflows/check.yml` - GitHub Actions baseline for `make check`
- `build.gradle` - Android or Gradle build configuration
- `app` - source or example code
- `docs` - source or example code
- `gradle` - source or example code
- `gradlew` - Android or Gradle build configuration
- `scripts` - source or example code
- `SECURITY.md` - security reporting and disclosure guidance
- `VISION.md` - project direction and maintenance guardrails

Additional scan context:

- Source directories: app, docs, gradle, scripts
- Dependency and build manifests: build.gradle, gradlew
- Entry points or build surfaces: Gradle build files
- Test-looking files: app/src/androidTest/java/gpj/android_recorder/ApplicationTest.java

## Getting Started

### Prerequisites

- Git
- Android Studio or a compatible Android SDK
- Java 8 and the checked-in Gradle wrapper

### Setup

```bash
git clone https://github.com/garethpaul/android-audio-recorder.git
cd android-audio-recorder
scripts/check-baseline.sh
./gradlew lint --no-daemon
./gradlew test assembleDebugAndroidTest --no-daemon
./gradlew assembleDebug --no-daemon
```

The setup commands above are derived from repository files. Legacy mobile, Python, or JavaScript samples may require older SDKs or package versions than a modern workstation uses by default.

The generated wrapper still executes Gradle 2.2.1 for compatibility. It uses
`distributionSha256Sum` to authenticate the downloaded distribution, while the
SDK-free baseline verifies the wrapper JAR and launchers. This does not make the first build offline-reproducible;
an uncached build still needs Gradle's HTTPS distribution service.

## Running or Using the Project

- Use Android Studio to open the project or run `./gradlew assembleDebug` when the Android SDK is configured.

## Testing and Verification

- `make check` - runs the source baseline and Android SDK-backed Gradle checks,
  including instrumentation APK compilation
  when `ANDROID_HOME` or `ANDROID_SDK_ROOT` is configured
- `scripts/check-baseline.sh` - runs SDK-free recorder baseline checks
- The canonical GitHub Actions workflow installs Android API 22 and build-tools
  24.0.3, selects Java 8, and runs full `make check` on pushes and pull
  requests. The workflow uses Ubuntu 24.04 and cancels superseded runs.
- Local Gradle checks accept an explicit `ANDROID_HOME` or `ANDROID_SDK_ROOT`;
  the repository does not assume a maintainer-specific SDK location.
- The baseline check protects media cleanup, play/record dispatch, and
  first-render button icon state.
- Recorder startup guards optional action-bar and record/play control lookups
  before wiring button listeners.
- Recorder controls remain in their idle state after record/play startup failures;
  playback startup failures restore record-ready controls instead of trapping
  the user on an unreadable recording.
- Recorder configuration failures during media construction, microphone
  source, format, output path, or encoder setup release partial resources and
  leave controls idle.
- A failed recorder startup also deletes any partial app-local capture after
  releasing the recorder, so hidden failed output is not retained.
- The explicit launcher export boundary is limited to `.MainActivity` and its
  existing `MAIN`/`LAUNCHER` intent filter.
- Output ownership begins immediately after setOutputFile succeeds, so later
  recorder configuration failures cannot bypass partial-output cleanup.
- Active MediaRecorder errors release the owned recorder, delete incomplete
  output, and reset controls while stale recorder callbacks are ignored.
- Recording startup enters the active state only while the exact started recorder
  remains owned, so immediate error cleanup cannot be overwritten by the click handler.
- Recorder lifecycle cleanup resets field-backed recording and playback control
  state so released media resources do not leave stale stop controls on screen.
- Recorder lifecycle cleanup routes active capture and playback through guarded
  stop methods before release, allowing recording containers to finalize.
- Pause-interrupted recordings are deleted after guarded finalization so
  backgrounding does not retain microphone audio that the reset UI cannot play.
- Recorder controls keep playback hidden after recording finalization failures
  instead of presenting an incomplete capture as playable.
- Explicit stop failures delete incomplete app-local audio after recorder
  release, but a stop call without an active recorder preserves prior output.
- Playback completion resets the play control to idle and releases the player
  without requiring an extra stop tap.
- Recorder playback errors release the player and reset controls to idle rather
  than leaving the stop icon visible for a failed playback session.
- Playback startup enters the playing state only while the exact started player
  remains active, so an immediate error callback cannot restore stale controls.
- Recorder completion and error listeners ignore stale MediaPlayer callbacks
  before releasing the retained player or resetting current playback controls.
- `./gradlew lint --no-daemon`, `./gradlew test assembleDebugAndroidTest --no-daemon`, and `./gradlew assembleDebug --no-daemon` when the Android SDK is configured
- [`docs/plans/2026-06-12-gradle-wrapper-verification.md`](docs/plans/2026-06-12-gradle-wrapper-verification.md)
  records wrapper provenance and compatibility evidence.

The legacy target SDK produces one documented `OldTargetApi` compatibility
warning. When the required SDK is unavailable locally, use static checks and
source review first, then rely on the hosted matching platform toolchain.

Use [`DEVICE_VERIFICATION.md`](DEVICE_VERIFICATION.md) for the exact-commit
emulator/device matrix. It covers microphone startup, owned-output cleanup,
recording, playback, lifecycle, app-specific storage, privacy-safe evidence,
and explicit unexecuted rows.

## Configuration and Secrets

- No required secret or credential file was identified in the repository scan. If you add integrations later, keep secrets out of git.
- The recorder disables Android backup in the checked-in manifest so local app
  state associated with recordings is not backed up by default.
- Recordings are stored under app-specific external files with an internal
  storage fallback; the checked-in manifest keeps only microphone permission.

## Security and Privacy Notes

- Review changes touching network requests, sockets, or service endpoints; examples from the scan include app/src/androidTest/java/gpj/android_recorder/ApplicationTest.java, app/src/main/AndroidManifest.xml, app/src/main/res/layout/activity_main.xml, gradle.properties.
- Review changes touching mobile permissions or privacy-sensitive device data; examples from the scan include app/src/main/AndroidManifest.xml, docs/plans/2026-06-08-recorder-build-tools-baseline.md, docs/plans/2026-06-08-recorder-lint-resource-baseline.md, docs/plans/2026-06-08-recorder-playback-baseline.md, and 1 more.
- Review changes touching file, media, JSON, XML, CSV, OCR, or data parsing; examples from the scan include app/lint.xml, app/src/main/AndroidManifest.xml, app/src/main/res/values-w820dp/dimens.xml, docs/plans/2026-06-08-recorder-lint-resource-baseline.md, and 1 more.
- Review changes touching database, model, or persistence code; examples from the scan include docs/plans/2026-06-08-recorder-build-tools-baseline.md.

## Maintenance Notes

- See `docs/plans/2026-06-14-recorder-device-verification-checklist.md` for the
  recorder/device evidence matrix and runtime non-claims.
- The legacy instrumentation bootstrap creates the application and verifies its
  package identity. The canonical test gate compiles the debug instrumentation APK,
  but does not execute it; recording, playback, UI, and device behavior remain
  outside that assertion.

- This looks like a legacy Android project or sample. Expect Android SDK, Gradle, and support-library versions to matter.
- See `SECURITY.md` for vulnerability reporting and safe research guidance.
- See `VISION.md` for project direction and contribution guardrails.
- See `docs/plans/2026-06-08-recorder-check-wrapper.md` for the root
  verification wrapper baseline.
- See `docs/plans/2026-06-12-hosted-android-verification.md` for the complete
  hosted Android lint, test, and build gate.
- See `docs/plans/2026-06-09-recorder-button-icon-contracts.md` for the
  first-render button icon contract.
- See `docs/plans/2026-06-09-recorder-startup-control-guards.md` for action-bar
  and record/play control lookup guards.
- See `docs/plans/2026-06-09-recorder-backup-policy.md` for the manifest
  backup policy contract.
- See `docs/plans/2026-06-09-recorder-app-specific-storage.md` for the
  recording storage contract.
- See `docs/plans/2026-06-09-recorder-startup-ui-state.md` for the media
  startup-failure UI state contract.
- See `docs/plans/2026-06-09-recorder-playback-completion-ui.md` for the
  playback completion UI reset contract.
- See `docs/plans/2026-06-09-recorder-recording-lifecycle-reset.md` for the
  recording-state lifecycle reset contract.
- See `docs/plans/2026-06-09-recorder-playback-error-ui.md` for the playback
  error UI reset contract.
- See `docs/plans/2026-06-13-recorder-stale-player-callback.md` for retained
  player identity guards on asynchronous callbacks.
- See `docs/plans/2026-06-10-ci-baseline.md` for the lightweight GitHub
  Actions baseline.
- See `docs/plans/2026-06-12-interrupted-recording-cleanup.md` for the
  pause-interrupted microphone capture deletion contract.
- See `docs/plans/2026-06-12-recorder-configuration-failures.md` for complete
  recorder startup guarding and partial-resource cleanup.
- See `docs/plans/2026-06-13-recorder-failed-start-file-cleanup.md` for partial
  file deletion after failed recorder startup.

## Contributing

Keep changes small and tied to the project that is already present in this repository. For code changes, document the toolchain used, avoid committing generated dependency directories or local configuration, and update this README when setup or verification steps change.
