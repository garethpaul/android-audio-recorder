---
title: Android Audio Explicit Launcher Export Boundary
type: security
status: planned
date: 2026-06-15
---

# Android Audio Explicit Launcher Export Boundary

## Problem Frame

The recorder's `MainActivity` owns a `MAIN`/`LAUNCHER` intent filter but omits
`android:exported`. Legacy Android infers that the activity is exported, which
leaves an externally reachable component boundary implicit and blocks a future
Android 12 target upgrade where filtered components require an explicit value.

## Priorities

1. P0: Preserve app launch behavior while explicitly declaring the activity's
   existing external reachability.
2. P1: Add a structural, mutation-sensitive portable contract for the named
   launcher block and exactly one exported attribute occurrence.
3. P1: Synchronize contributor, readme, security, vision, changelog, and plan
   evidence without changing recorder behavior or dependencies.

## Requirements

- Set `android:exported="true"` only on `.MainActivity`.
- Preserve the `MAIN` action, `LAUNCHER` category, application metadata,
  permissions, backup policy, and media lifecycle behavior.
- Reject missing, false, duplicate, same-line duplicate, unrelated, or
  filter-detached export declarations in the SDK-free checker.
- Keep repository and external-directory validation location-independent.
- Record SDK-backed validation separately from unexecuted emulator, device,
  microphone, speaker, and real media scenarios.

## Implementation Units

### 1. Declare the launcher boundary

**File:** `app/src/main/AndroidManifest.xml`

Add the explicit true value to the existing launcher activity only.

### 2. Enforce structural ownership

**File:** `scripts/check-baseline.sh`

Count exported attribute occurrences and require the sole declaration within
the `.MainActivity` block that also owns both launcher filter entries.

### 3. Synchronize durable guidance

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
and this plan.

Document the intentional boundary and completed verification evidence.

## Verification

- Run POSIX syntax and the focused baseline checker.
- Run repository and external-directory `make check` with Java 8 and the
  configured Android SDK.
- Reject isolated mutations for missing, false, unrelated, filter-detached,
  same-line duplicate, missing-guidance, and incomplete-plan variants.
- Audit exact paths, generated artifacts, file modes, whitespace, conflict
  markers, dependency/workflow drift, and credential-shaped additions.

## Risks And Mitigations

- **Launch regression:** require the activity name and both intent-filter
  entries in the same structural contract as the exported value.
- **Overexposure:** permit exactly one exported attribute and reject any
  application or unrelated component declaration.
- **Legacy build:** retain the current Gradle, Android plugin, SDK levels, and
  dependencies; the exported attribute is supported by the compile SDK.
- **Stacked delivery:** base this PR on recorder-start ownership and preserve
  base-first merge ordering.

## Out Of Scope

- Target/compile SDK, Gradle, Android plugin, or dependency upgrades.
- New activities, services, receivers, providers, deep links, or permissions.
- Recorder/player lifecycle, file handling, UI controls, or media behavior.
