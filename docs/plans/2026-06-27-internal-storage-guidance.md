# Align maintained recording-storage guidance

Status: Completed

## Problem

The recorder has used `getFilesDir()` and owner-private pending, backup, and
finalized files since the recording ownership redesign. `README.md`,
`AGENTS.md`, and the opening of `VISION.md` still described external storage,
contradicting the privacy-sensitive implementation and later sections of the
same documentation.

## Fix

- Describe owner-private internal storage consistently in maintained guidance.
- Preserve historical plans that accurately describe earlier repository states.
- Make the SDK-free baseline require the current storage statement and reject
  the stale external-storage wording.

## Test First

The new baseline contract failed on `README.md` before the documentation was
corrected because the required internal-storage statement was absent.

## Verification

- Run `./scripts/check-baseline.sh` for the focused documentation contract.
- Run `make check` for host contracts, hostile mutations, and available Android
  SDK-backed verification.
- Run an isolated stale-wording mutation and require the baseline to reject it.
- Run shell syntax and whitespace checks.
