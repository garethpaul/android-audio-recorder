# AGENTS.md

## Repository purpose

`garethpaul/android-audio-recorder` is an Android application or sample. A simple audio recorder for Android.

## Project structure

- `Makefile` - repository verification targets
- `scripts` - baseline checks and helper scripts
- `docs` - plans, notes, and generated README assets
- `app` - application source or app module
- `build.gradle` - Gradle build configuration
- `gradlew` - checked-in Gradle wrapper

## Development commands

- Install dependencies: no repository-specific install command is documented.
- Full baseline: `make check`
- Combined verification: `make verify`
- Lint/static checks: `make lint`
- Tests: `make test`
- Build: `make build`
- Android unit tests when the SDK is configured: `./gradlew test`
- Android debug build when the SDK is configured: `./gradlew assembleDebug`
- If a command above skips because a platform toolchain is missing, verify on a machine with that SDK before claiming platform behavior is tested.

## Coding conventions

- Language mix noted in the README: Java (2), shell (1).
- Use the checked-in Gradle wrapper for Android builds when an SDK is configured.

## Testing guidance

- A legacy instrumentation smoke test exists, but there is no substantive behavioral test suite; treat `make check` as the minimum baseline.
- Start with the narrowest relevant test or Make target, then run `make check` before handing off if the change is not documentation-only.
- Keep README verification notes in sync when commands, fixtures, or supported toolchains change.

## PR / change guidance

- Keep diffs focused on the requested repository and avoid unrelated modernization or formatting churn.
- Preserve public APIs, sample behavior, file formats, and documented environment variables unless the task explicitly changes them.
- Update tests, README notes, or docs/plans when behavior, security posture, or validation commands change.
- Call out skipped platform validation, legacy toolchain assumptions, and any risky files touched in the final summary.

## Safety and gotchas

- No required secret or credential file was identified in the repository scan. If you add integrations later, keep secrets out of git.
- The recorder disables Android backup in the checked-in manifest so local app state associated with recordings is not backed up by default.
- Recordings are stored under app-specific external files with an internal storage fallback; the checked-in manifest keeps only microphone permission.
- Explicit stop failures delete incomplete audio only when an active recorder
  existed, preserving older valid output when no recorder is active.
- Active MediaRecorder errors must verify recorder ownership before generic
  logging, incomplete-output cleanup, or control reset.
- Stale audio-focus callbacks cannot stop a newer player.
- Recording startup succeeds only while the exact started recorder remains
  owned, so immediate error cleanup cannot be overwritten by stale controls.
- Keep the explicit launcher export boundary on `.MainActivity`, which owns the
  sole `MAIN`/`LAUNCHER` filter; do not export unrelated components.
- This looks like a legacy Android project or sample. Expect Android SDK, Gradle, and support-library versions to matter.
- See `SECURITY.md` for vulnerability reporting and safe research guidance.
- See `VISION.md` for project direction and contribution guardrails.

## Agent workflow

1. Inspect the README, Makefile, manifests, and the files directly related to the request.
2. Make the smallest source or docs change that satisfies the task; avoid generated, vendored, or local-environment files unless required.
3. Run the narrowest useful validation first, then `make check` or the documented package/platform gate when available.
4. If a required SDK, service credential, or external runtime is unavailable, record the skipped command and why.
5. Summarize changed files, commands run, and remaining risks or follow-up validation.
