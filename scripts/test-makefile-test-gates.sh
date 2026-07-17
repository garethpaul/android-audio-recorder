#!/bin/sh
# Asserts that `make check` actually DISPATCHES every host verification runner,
# and that the hostile-mutation gate is a live oracle rather than an echo.
#
# Text pins on the Makefile (grep -Fc / grep -Fxq) cannot do this: the pinned
# text stays byte-identical when a recipe line is `@echo`-prefixed or moved
# verbatim to a target `check` never builds. Both mutations leave every existing
# Makefile pin satisfied while the runner never executes. So instead of
# inspecting text, this harness runs `make check` under a fake SHELL that logs
# each dispatched command, then requires each runner's dispatched command line
# to appear in that log EXACTLY (whole-line), which no prefix or relocation can
# forge.
set -eu

SCRIPT_DIR=$(dirname -- "$0")
case $SCRIPT_DIR in
  /*) ROOT=$(CDPATH='' cd "$SCRIPT_DIR/.." && pwd) ;;
  *) ROOT=$(CDPATH='' cd "./$SCRIPT_DIR/.." && pwd) ;;
esac
MAKEFILE=$ROOT/Makefile
MAKE_BIN=${MAKE_BIN:-make}

TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/android-audio-test-gates.XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM
CONTROL_DIR="$TEMP_ROOT/control dir"
mkdir -p "$CONTROL_DIR"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Leg 1: observe execution. Run `make check` under a fake SHELL and require
# each runner's dispatched command line verbatim.
# ---------------------------------------------------------------------------

# Ask Make itself for $(ROOT) so the expected lines match the Makefile's own
# $(abspath ...) semantics rather than this script's path resolution.
ROOT_PROBE="$TEMP_ROOT/root-probe.mk"
printf 'aar-print-root:\n\t@printf %%s\\\\n "$(ROOT)"\n' > "$ROOT_PROBE"
MAKE_ROOT=$("$MAKE_BIN" --no-print-directory -f "$MAKEFILE" -f "$ROOT_PROBE" aar-print-root)
if [ -z "$MAKE_ROOT" ]; then
  fail 'Makefile $(ROOT) could not be resolved; the test-gate harness cannot verify dispatch.'
fi

FAKE_SHELL="$TEMP_ROOT/fake-shell"
FAKE_SHELL_LOG="$TEMP_ROOT/fake-shell.log"
cat > "$FAKE_SHELL" <<'SCRIPT'
#!/bin/sh
printf '%s\n' "$*" >> "$ANDROID_AUDIO_FAKE_SHELL_LOG"
exit 0
SCRIPT
chmod +x "$FAKE_SHELL"

LATER="$TEMP_ROOT/fake-shell.mk"
{
  printf 'build check lint test verify: override SHELL := %s\n' "$FAKE_SHELL"
  printf 'build check lint test verify: override .SHELLFLAGS := -c\n'
} > "$LATER"

: > "$FAKE_SHELL_LOG"
set +e
(cd "$CONTROL_DIR" && env ANDROID_AUDIO_FAKE_SHELL_LOG="$FAKE_SHELL_LOG" \
  "$MAKE_BIN" --no-print-directory -f "$MAKEFILE" -f "$LATER" check) \
  > "$TEMP_ROOT/check.out" 2>&1
status=$?
set -e
if [ "$status" -ne 0 ]; then
  printf 'make check did not complete under the fake shell, exited %s\n' "$status" >&2
  cat "$TEMP_ROOT/check.out" >&2
  exit 1
fi

# Every host runner `make check` must dispatch. `-Fxq -e` is required, not
# `-Fq`: a substring match on the log is satisfied by `@echo <runner>`, whose
# dispatched line is `-c echo <runner>`. `-e` is required because the expected
# line begins with `-c` and would otherwise be parsed as a grep option.
for dispatched_runner in \
  'scripts/check-baseline.sh' \
  'scripts/test-recording-file-store.sh' \
  'scripts/test-main-activity-contracts.py' \
  'scripts/test-review-mutations.sh' \
  'scripts/test-makefile-test-gates.sh'; do
  if ! grep -Fxq -e "-c $MAKE_ROOT$dispatched_runner" "$FAKE_SHELL_LOG"; then
    fail "make check must execute the host verification runner: $dispatched_runner"
  fi
done

# ---------------------------------------------------------------------------
# Leg 2: the hostile-mutation gate must be a live oracle.
#
# Leg 1 proves test-review-mutations.sh is dispatched, but a runner stubbed to
# `exit 0` -- or one whose mutation table is commented out -- is dispatched just
# the same and still prints its own success line. The mutation gate is the ONLY
# check that the contract runners reject hostile source edits, so its liveness
# has to be observed, not assumed. Plant a defect the gate is required to
# report -- a contract runner that accepts everything -- and require the gate to
# fail. An emptied table or a stubbed gate cannot report the planted defect.
# ---------------------------------------------------------------------------

CONTROL_COPY="$TEMP_ROOT/mutation-control"
mkdir -p "$CONTROL_COPY"
cp -R "$ROOT/app" "$ROOT/scripts" "$CONTROL_COPY/"
printf '#!/usr/bin/env python3\nimport sys\nsys.exit(0)\n' \
  > "$CONTROL_COPY/scripts/test-main-activity-contracts.py"
chmod +x "$CONTROL_COPY/scripts/test-main-activity-contracts.py"

set +e
"$CONTROL_COPY/scripts/test-review-mutations.sh" > "$TEMP_ROOT/mutation-control.out" 2>&1
mutation_status=$?
set -e
if [ "$mutation_status" -eq 0 ]; then
  printf '%s\n' 'The hostile-mutation gate passed against a contract runner that accepts every mutation; the gate is not a live oracle.' >&2
  cat "$TEMP_ROOT/mutation-control.out" >&2
  exit 1
fi
if ! grep -Fq 'Mutation survived:' "$TEMP_ROOT/mutation-control.out"; then
  printf '%s\n' 'The hostile-mutation gate must report a surviving mutation when a contract runner accepts every mutation.' >&2
  cat "$TEMP_ROOT/mutation-control.out" >&2
  exit 1
fi

printf '%s\n' "Makefile host test-gate dispatch checks passed."
