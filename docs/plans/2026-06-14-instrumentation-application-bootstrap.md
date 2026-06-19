---
title: Instrumentation Application Bootstrap
type: testing
status: completed
date: 2026-06-14
---

# Instrumentation Application Bootstrap

## Problem Frame

The checked-in `ApplicationTest` only declares a constructor. It can compile,
but it contains no test method and therefore proves no application bootstrap
behavior when instrumentation is executed.

## Requirements

- Create the application through the existing legacy `ApplicationTestCase`.
- Assert that instrumentation produces a non-null application instance with
  the recorder package identity.
- Keep the test compatible with the Android API 22 and Gradle 2.2.1 baseline.
- Add a fail-closed source contract so the assertion cannot silently disappear.
- Update maintained guidance without claiming microphone, UI, emulator, or
  physical-device coverage.

## Scope Boundaries

- Do not modernize the Android test framework, Gradle, target SDK, or support
  libraries in this change.
- Do not invoke recording, playback, permissions, or storage side effects.
- Do not merge or close stacked pull requests without explicit authorization.

## Verification

- Compile Android tests, run Gradle unit tasks, lint, and assemble when the
  configured SDK supports the legacy project.
- Run repository and external-directory `make check`.
- Reject hostile mutations for the test method, application creation, non-null
  assertion, package assertion, static contract, and completed-plan evidence.
- Record instrumentation execution as unexecuted unless an emulator or device
  is actually available.

## Risks

- This is a bootstrap assertion, not behavioral coverage for recorder or player
  lifecycle, UI controls, permissions, storage, or device media services.
- The legacy instrumentation test still requires a compatible emulator or
  physical device for execution.

## Verification Results

- `app:assembleDebugAndroidTest` compiled and packaged the legacy
  instrumentation APK against the configured Android SDK.
- Repository and external-directory `make check` passed the SDK-backed lint,
  unit-test, debug assembly, and portable-contract gates.
- Six hostile mutations covering the test method, application creation,
  non-null assertion, package assertion, documentation, and completed-plan
  evidence were rejected.
- No emulator or physical-device instrumentation was executed, so the runtime
  assertion remains unexecuted locally.
