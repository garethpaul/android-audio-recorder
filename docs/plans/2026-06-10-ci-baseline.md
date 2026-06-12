# Android Audio Recorder CI Baseline

## Status: Completed

## Context

`android-audio-recorder` has an SDK-free recorder source baseline and guarded
Gradle gates behind `make check`. The repository needs the same wrapper to run
in GitHub Actions so media lifecycle, storage, and privacy contracts are
checked before review.

## Objectives

- Run the existing `make check` wrapper in GitHub Actions.
- Run the complete legacy Android gate with a matching hosted SDK.
- Make the workflow presence part of the SDK-free baseline contract.

## Work Completed

- Added `.github/workflows/check.yml` to run `make check` on pushes, pull
  requests, and manual dispatches.
- Pinned setup actions to immutable revisions, limited permissions to
  repository reads, and bounded the job to 15 minutes.
- Install Android API 22 and build-tools 24.0.3, select Java 8, and run the
  complete `make check` gate including lint, unit tests, and debug assembly.
- Removed the maintainer-specific default SDK path; Gradle checks now require
  an explicit `ANDROID_HOME`.
- Extended `scripts/check-baseline.sh` to require the CI workflow and this
  completed plan.
- Disabled persisted checkout credentials and enforce one byte-exact canonical
  workflow; additional workflow files under `.github/workflows` fail locally.
- Added owner coverage for CI, Gradle, and the complete app tree, and locked the
  fixed legacy Gradle/module configuration against source-set redirection.
- Enforced the exact microphone-only manifest, rejected symlinks and packaged
  binaries, and recorded hashes for every Gradle wrapper executable.
- Updated README, VISION, SECURITY, and CHANGES with the CI baseline.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`

## Follow-Up Candidates

- Modernize Gradle 2.2.1, Android Gradle Plugin 1.2.3, JCenter, and the API 22
  target in a separate compatibility-focused change.
