---
title: Recorder Backup Policy
type: security
status: completed
date: 2026-06-09
---

# Recorder Backup Policy

## Problem Frame

Android Audio Recorder handles user-created audio. Its manifest allowed Android
backup, which is not a good privacy default for a sample that can create local
recording-related state.

## Scope Boundaries

- Keep the existing external-storage recording path unchanged.
- Do not add scoped storage, runtime permissions, or modern media-store behavior
  in this pass.
- Keep verification SDK-free when a compatible Android SDK is unavailable.

## Implementation Units

### U1: Disable Manifest Backup

Files:

- Modify `app/src/main/AndroidManifest.xml`

Approach:

- Set `android:allowBackup` to `false` on the application.
- Leave permissions, launcher activity, and media behavior unchanged.

### U2: Add Baseline Coverage

Files:

- Modify `scripts/check-baseline.sh`

Approach:

- Require `android:allowBackup="false"` in the recorder manifest.
- Reject `android:allowBackup="true"` so future edits cannot silently restore
  the old backup policy.

### U3: Document The Privacy Baseline

Files:

- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Record the backup policy beside the existing audio privacy and verification
  guardrails.
- Keep scoped-storage and runtime-permission modernization as separate work.

## Verification

- `make check`
- `scripts/check-baseline.sh`
- `git diff --check`
