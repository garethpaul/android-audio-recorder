---
title: Audio Recorder Playback Baseline
type: fix
status: completed
date: 2026-06-08
---

# Audio Recorder Playback Baseline

## Summary

Fix the recorder app's duplicate playback start/stop calls and add a small SDK-free source check so the behavior cannot regress before a full Android SDK verification pass is available.

---

## Problem Frame

The play button currently calls `onPlay(mStartPlaying[0])` and then calls `startPlaying()` or `stopPlaying()` again inside the same branch. That can create or stop media players twice from one tap. Local Gradle verification reaches Android plugin configuration but fails because no Android SDK path is configured in this environment.

---

## Requirements

- R1. A play-button tap must start playback once when entering play mode.
- R2. A play-button tap must stop playback once when leaving play mode.
- R3. The UI visibility and icon transitions must remain unchanged.
- R4. The repository must provide a source check that runs without Android SDK configuration.
- R5. README documentation must explain the legacy Android toolchain and verification commands.
- R6. Verification results must distinguish source-check success from missing Android SDK configuration.

---

## Key Technical Decisions

- **Reuse the existing `onPlay` helper:** Keep the current `startPlaying` and `stopPlaying` implementations, but call them through `onPlay(true/false)` exactly once per branch.
- **Avoid broad Android modernization:** The project is on Android Gradle Plugin 1.2.3 and compile SDK 22; dependency/toolchain updates need a separate SDK-capable pass.
- **Use an SDK-free shell check:** A simple script can guard against reintroducing the duplicate `onPlay(mStartPlaying[0])` call without needing Gradle.

---

## Scope Boundaries

- This pass does not change recording format, file location, permissions, or UI assets.
- This pass does not migrate Gradle, Android Gradle Plugin, or SDK levels.
- This pass does not add emulator or instrumentation tests.
- This pass does not alter runtime permission handling.

---

## Implementation Units

### U1. Fix Duplicate Playback Dispatch

- **Goal:** Ensure each play-button tap maps to one media-player action.
- **Files:** `app/src/main/java/gpj/android_recorder/MainActivity.java`
- **Patterns:** Keep the existing branch structure and UI updates; replace duplicate direct calls with one `onPlay(true)` or `onPlay(false)`.
- **Test Scenarios:**
  - The play-start branch calls `onPlay(true)` and does not call `startPlaying()` separately.
  - The play-stop branch calls `onPlay(false)` and does not call `stopPlaying()` separately.
  - Existing play/record button visibility and icon updates remain in place.
- **Verification:** `scripts/check-baseline.sh`

### U2. Add SDK-Free Source Check

- **Goal:** Provide a local quality gate that works before Android SDK setup.
- **Files:** `scripts/check-baseline.sh`
- **Patterns:** POSIX shell, repo-root detection, fail-fast messages.
- **Test Scenarios:**
  - The script fails if `onPlay(mStartPlaying[0]);` returns.
  - The script verifies `onPlay(true);` and `onPlay(false);` are present.
- **Verification:** `scripts/check-baseline.sh`

### U3. Document Restore and Verification

- **Goal:** Make the repo usable for future Android maintainers.
- **Files:** `README.md`
- **Patterns:** Short setup and verification sections with Android SDK prerequisites.
- **Test Scenarios:**
  - README lists `scripts/check-baseline.sh`.
  - README lists `./gradlew tasks --no-daemon` and `./gradlew assembleDebug --no-daemon`.
  - README documents that Android SDK configuration is required for Gradle verification.
- **Verification:** Manual README review

---

## Risks & Dependencies

- Gradle verification still requires `ANDROID_HOME` or `local.properties` pointing to a compatible Android SDK.
- The app targets SDK 22 and writes to external storage; runtime-permission and scoped-storage modernization are follow-up work.
- MediaRecorder and MediaPlayer lifecycle coverage should eventually move into tested presenter/controller logic or instrumentation tests.

---

## Sources / Research

- `app/src/main/java/gpj/android_recorder/MainActivity.java` contains the duplicate playback dispatch in the play button listener.
- `build.gradle`, `app/build.gradle`, and `gradle/wrapper/gradle-wrapper.properties` show Android Gradle Plugin 1.2.3, compile SDK 22, and Gradle 2.2.1.
- `./gradlew tasks --no-daemon` starts but fails with `SDK location not found` in this environment.
