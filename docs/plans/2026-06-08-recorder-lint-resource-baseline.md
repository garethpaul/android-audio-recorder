---
title: Recorder Lint Resource Baseline
type: chore
status: completed
date: 2026-06-08
---

# Recorder Lint Resource Baseline

## Summary

Clean the remaining legacy Android resource lint findings while preserving the
recorder UI and adding a guard for the resource conventions.

## Problem Frame

The recorder app still carried starter resources, layout-local styling, missing
button accessibility labels, and raw PNG controls in `res/drawable/`. Those
issues make lint less useful and leave future maintainers without a clear
resource baseline.

## Requirements

- R1. Remove unused starter resources that are no longer referenced.
- R2. Move the recorder background color into themed resources.
- R3. Add content descriptions for the record and play image buttons.
- R4. Keep the single-source control PNGs in `drawable-nodpi`.
- R5. Document the narrow lint suppressions used by the obsolete Android
  toolchain.
- R6. Extend the SDK-free check so resource regressions fail before Gradle runs.

## Key Technical Decisions

- **Keep behavior unchanged:** The button artwork and resource names stay the
  same, so existing Java and layout references continue to resolve.
- **Use theme background:** Moving the fixed background color to
  `android:windowBackground` avoids root-layout overdraw without changing the
  visible color.
- **Keep lint suppressions narrow:** `LintError` documents the obsolete lint API
  database limitation; `IconMissingDensityFolder` documents intentional nodpi
  bitmap assets.

## Scope Boundaries

- This pass does not redesign the recorder screen.
- This pass does not replace the bitmap artwork.
- This pass does not modernize Gradle, SDK levels, or runtime permissions.

## Verification

- `scripts/check-baseline.sh`
- `ANDROID_HOME=/home/gjones/android-sdk ./gradlew lint --no-daemon`
- `ANDROID_HOME=/home/gjones/android-sdk ./gradlew test --no-daemon`
- `ANDROID_HOME=/home/gjones/android-sdk ./gradlew assembleDebug --no-daemon`

## Sources / Research

- `activity_main.xml` uses `@drawable/play` and `@drawable/record` for the two
  visible image buttons.
- `MainActivity.java` updates the same controls with `R.drawable.stop`,
  `R.drawable.play`, and `R.drawable.record`.
- `app/lint.xml` is limited to the obsolete lint database failure and the
  intentional nodpi bitmap baseline.
