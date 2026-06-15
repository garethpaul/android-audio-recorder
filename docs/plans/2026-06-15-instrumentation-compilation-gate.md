# Instrumentation Compilation Gate

Status: Planned

## Summary

Make the recorder's canonical `make test` and hosted `make check` paths compile
the instrumentation APK instead of leaving `ApplicationTest` outside CI.

## Problem Frame

The instrumentation bootstrap assertion is checked by source contracts and was
compiled once with an ad hoc Gradle command, but the maintained test target runs
only Gradle's local unit-test task. A future instrumentation compile failure can
therefore land while the canonical local and hosted gates remain green.

## Requirements

- **R1:** With a configured Android SDK, `make test` must run local unit-test
  tasks and compile the debug instrumentation APK.
- **R2:** `make check` and the existing hosted workflow must inherit the new
  instrumentation compile gate without duplicating Gradle commands.
- **R3:** SDK-free invocations must retain the existing explicit skip instead of
  failing or claiming instrumentation execution.
- **R4:** Portable contracts and maintained documentation must fail closed if
  instrumentation compilation is removed from the canonical test target.

## Key Technical Decisions

- Extend the existing Gradle invocation in `make test`; do not add a parallel
  workflow-only command that can drift from local verification.
- Compile `assembleDebugAndroidTest` without claiming emulator or physical-device
  execution.
- Keep SDK detection and Java/Android toolchain ownership unchanged.

## Implementation Units

### U1: Add instrumentation assembly to the canonical test target

**Goal:** Ensure every SDK-backed `make check` compiles instrumentation source.

**Requirements:** R1, R2, R3

**Dependencies:** None

**Files:**

- `Makefile`
- `scripts/check-baseline.sh`

**Approach:** Add the debug Android-test assembly task to the existing Gradle
test invocation and enforce its exact placement through the portable checker.

**Test scenarios:**

- SDK-backed `make test` runs both local tests and instrumentation assembly.
- SDK-backed `make check` inherits the same tasks through `verify`.
- SDK-free `make test` prints the existing skip and exits successfully.
- Removing, misspelling, or relocating the instrumentation task is rejected.

**Verification:** Repository and external-directory gates pass, the generated
instrumentation APK exists during SDK-backed validation, and hostile mutations
cannot weaken the target contract.

### U2: Record the compile-only instrumentation boundary

**Goal:** Distinguish compilation evidence from runtime instrumentation.

**Requirements:** R4

**Dependencies:** U1

**Files:**

- `README.md`
- `SECURITY.md`
- `CHANGES.md`
- `docs/plans/2026-06-15-instrumentation-compilation-gate.md`

**Approach:** Document that canonical checks compile the instrumentation APK but
do not run it without an emulator or device. Record only completed validation.

**Test scenarios:** Documentation and completed-plan evidence mutations are
rejected by the portable checker.

**Verification:** Guidance, changelog, and plan agree on the compile-only
boundary and retain the device-verification non-claims.

## Scope Boundaries

- Do not add an emulator, device farm, microphone test, or media side effect.
- Do not modernize Gradle, Android test APIs, dependencies, or target SDK.
- Do not merge or close stacked pull requests without owner authorization.

## Risks And Dependencies

- The legacy Gradle and Android plugin baseline requires Java 8 and the pinned
  Android API 22/build-tools 24.0.3 SDK packages.
- Instrumentation compilation catches source and packaging drift but cannot
  prove application bootstrap or media behavior at runtime.

## Acceptance Examples

- **AE1:** Hosted `make check` reaches `app:assembleDebugAndroidTest` and fails
  if `ApplicationTest` no longer compiles.
- **AE2:** A developer without an Android SDK receives the existing clear skip
  and can still run the portable source baseline.
