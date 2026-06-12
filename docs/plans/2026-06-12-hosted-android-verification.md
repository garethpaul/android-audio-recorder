# Hosted Android Verification

## Status: Planned

## Context

The canonical workflow deliberately clears Android SDK variables because the
legacy Gradle toolchain was assumed unsupported. The authoritative PR head now
passes Android lint, both unit-test variants, and debug assembly locally with
Android API 22, build-tools 24.0.3, and Java 8.

## Goal

Run the proven complete Android gate for pull requests and default-branch
pushes instead of skipping every Gradle task in hosted CI.

## Changes

- Install platform-tools, Android API 22, and build-tools 24.0.3 before
  selecting Java 8.
- Run the canonical `make check` target with the hosted SDK configured.
- Increase the bounded job timeout for SDK installation and the complete gate.
- Keep actions immutable, permissions read-only, checkout credentials disabled,
  and the workflow byte-exact in the repository checker.
- Update the README and CI plan with the hosted lint, test, and build contract.

## Verification

- Run SDK-backed `make check` from the isolated repository root and an
  external working directory.
- Confirm lint reports exactly the documented `OldTargetApi` warning.
- Run hostile workflow, documentation, and plan-evidence mutations.
- Run `git diff --check`.
- Require the exact-head pull-request workflow to pass.

## Boundaries

- Do not change or suppress `targetSdkVersion 22` in this unit.
- Do not modernize Gradle, the Android plugin, JCenter, or recorder behavior.
- Do not add credentials, signing material, permissions, or dependencies.
