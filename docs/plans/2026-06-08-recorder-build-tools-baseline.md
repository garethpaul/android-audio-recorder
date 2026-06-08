---
title: Audio Recorder Build Tools Baseline
type: chore
status: completed
date: 2026-06-08
---

# Audio Recorder Build Tools Baseline

## Summary

Make the legacy Android audio recorder debug build runnable on the current Linux host by keeping the old Gradle and Android Gradle Plugin stack but moving the module from Android build-tools 22.0.1 to 24.0.3.

---

## Problem Frame

The repository's SDK-free playback check passes, and Gradle task configuration succeeds when `ANDROID_HOME=/home/gjones/android-sdk` is set. The debug build then hangs in the PNG cruncher because build-tools 22.0.1 invokes an obsolete 32-bit `aapt` binary that cannot load `libz.so.1` on this host. The AirQuality Android repo in this workspace already uses build-tools 24.0.3 successfully with the same legacy Gradle stack.

---

## Requirements

- R1. Keep Gradle wrapper 2.2.1, Android Gradle Plugin 1.2.3, compile SDK 22, and target SDK 22 unchanged.
- R2. Use Android build-tools 24.0.3 so the debug build avoids the build-tools 22.0.1 `aapt` loader failure.
- R3. Preserve the playback dispatch fix and SDK-free source check.
- R4. Documentation must name the build-tools version and the `ANDROID_HOME` requirement.
- R5. Local verification must run the source check, Gradle task listing, and debug APK assembly with the configured Android SDK.

---

## Key Technical Decisions

- **Change only build-tools:** This is the smallest build reproducibility fix and avoids a broader Gradle, plugin, or SDK migration.
- **Follow the adjacent repo pattern:** `airquality-android` verifies with build-tools 24.0.3 under Android Gradle Plugin 1.2.3 in this workspace.
- **Keep the SDK-free check:** `scripts/check-baseline.sh` remains the first local gate because it works without Android SDK setup.

---

## Scope Boundaries

- This pass does not update Gradle, Android Gradle Plugin, compile SDK, target SDK, or app dependencies.
- This pass does not change recording, playback, permissions, storage paths, or UI behavior.
- This pass does not add emulator or device tests.

---

## Implementation Units

### U1. Pin Compatible Legacy Build Tools

- **Goal:** Allow debug APK assembly on a current Linux host with the installed Android SDK.
- **Files:** `app/build.gradle`
- **Patterns:** Keep the existing `android` block and only change `buildToolsVersion`.
- **Test Scenarios:**
  - `app/build.gradle` declares `buildToolsVersion "24.0.3"`.
  - `ANDROID_HOME=/home/gjones/android-sdk ./gradlew assembleDebug --no-daemon` completes without the build-tools 22.0.1 `aapt` loader failure.
- **Verification:** `ANDROID_HOME=/home/gjones/android-sdk ./gradlew assembleDebug --no-daemon`

### U2. Document Build Prerequisites

- **Goal:** Make future local verification repeatable.
- **Files:** `README.md`
- **Patterns:** Keep the README short and command-oriented.
- **Test Scenarios:**
  - README names Android build-tools 24.0.3.
  - README lists `scripts/check-baseline.sh`, Gradle task listing, and debug assembly.
- **Verification:** Manual README review

---

## Risks & Dependencies

- Build-tools 24.0.3 is still legacy; a future migration should update Gradle, Android Gradle Plugin, SDK levels, and runtime permission handling together.
- Device behavior is not exercised by this pass; it only proves source checks and debug APK assembly.

---

## Sources / Research

- `app/build.gradle` currently pins build-tools 22.0.1.
- `scripts/check-baseline.sh` verifies the playback dispatch fix without the Android SDK.
- `ANDROID_HOME=/home/gjones/android-sdk ./gradlew tasks --no-daemon` succeeds.
- `ANDROID_HOME=/home/gjones/android-sdk ./gradlew assembleDebug --no-daemon` fails because `/home/gjones/android-sdk/build-tools/22.0.1/aapt` cannot load `libz.so.1`.
