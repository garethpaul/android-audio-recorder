---
title: Gradle Wrapper Verification
date: 2026-06-12
status: completed
execution: code
---

# Gradle Wrapper Verification

## Summary

Replace the obsolete trusted-wrapper baseline with an official checksum-capable
bootstrap while preserving the recorder's Gradle 2.2.1, Java 8, Android API 22,
build-tools 24.0.3, and Android Gradle Plugin 1.2.3 runtime contract.

## Requirements

- **R1:** Continue executing `gradle-2.2.1-all.zip` under Java 8 without
  changing the Android plugin, SDK, dependencies, or recorder behavior.
- **R2:** Pin Gradle's official distribution SHA-256,
  `1d7c28b3731906fd1b2955946c1d052303881585fc14baedd675e4cf2bc1ecab`.
- **R3:** Regenerate `gradlew`, `gradlew.bat`, and `gradle-wrapper.jar` with
  official Gradle 8.14.5 tooling and verify the published wrapper JAR SHA-256,
  `7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172`.
- **R4:** Preserve the repository's exact static wrapper contract and extend it
  to reject URL, checksum, generated launcher, JAR, documentation, and plan
  evidence drift.
- **R5:** Pass the full SDK-backed gate locally and on the final pull-request
  head before tracker reconciliation.

## Scope Boundaries

In scope: the four wrapper files, static baseline, repository guidance, and
verification evidence. Deferred: Gradle runtime, Android plugin, SDK,
dependencies, JCenter, application code, permissions, storage, and media
behavior.

## Implementation Units

### U1. Verified Wrapper Bootstrap

Generate the wrapper with Gradle 8.14.5, retain the Gradle 2.2.1 all
distribution, add its official checksum, and prove a fresh Java 8 bootstrap
accepts the real archive and rejects an incorrect checksum.

### U2. Static Contract And Documentation

Replace the recorded legacy wrapper hashes with exact reviewed generated
artifacts, preserve the byte-exact properties contract, and document that
checksum verification authenticates expected bytes without providing offline
reproducibility.

### U3. Compatibility And Hosted Evidence

Run `make check` from the repository and an external working directory,
exercise hostile mutations, and record exact hosted results only after they
complete on the pushed head.

## Risks And Mitigations

- Keep the Gradle runtime and Android plugin unchanged to isolate bootstrap
  risk from build modernization.
- Use a fresh temporary Gradle user home so cached downloads cannot hide
  checksum behavior.
- Enforce the official wrapper JAR and generated scripts with exact hashes.

## Sources

- [Gradle Wrapper documentation](https://docs.gradle.org/current/userguide/gradle_wrapper.html)
- [Gradle 2.2.1 checksum](https://services.gradle.org/distributions/gradle-2.2.1-all.zip.sha256)
- [Gradle 8.14.5 wrapper JAR checksum](https://services.gradle.org/distributions/gradle-8.14.5-wrapper.jar.sha256)

## Work Completed

- Regenerated all four wrapper files with official Gradle 8.14.5 tooling while
  retaining the Gradle 2.2.1 all distribution and Android build runtime.
- Replaced the obsolete recorded wrapper hashes with the official wrapper JAR,
  generated launcher, and exact checksum-protected properties contracts.
- Documented the authenticated-download boundary without changing recorder or
  Android build behavior.

## Verification Completed

- A fresh temporary Gradle user home downloaded the official distribution and
  reported Gradle 2.2.1 on Corretto Java 8 (`1.8.0_482`).
- A disposable wrapper with an incorrect distribution checksum was rejected
  before Gradle execution and reported the official archive checksum.
- SDK-backed `make check` passed with API 22, build-tools 24.0.3, and Java 8
  from the repository and an external working directory; lint retained only
  the documented `OldTargetApi` warning.
- Focused hostile mutations rejected properties, wrapper JAR, and incomplete
  plan evidence.
- `sh -n scripts/check-baseline.sh` and `git diff --check` passed.

## Hosted Verification

- On implementation head `63eca0b1c8f5a921c9810324a9474269e5f83268`,
  pull-request `Check` run `27439366513` passed the full Java 8/API 22 gate.
- CodeQL run `27439364674` passed both the actions and java-kotlin analyzers on
  the same implementation head.
- PR #3 was open, clean, and mergeable at that head. The final evidence-only
  commit must rerun the same pull-request and CodeQL gates before tracker
  reconciliation.
