#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MAIN_ACTIVITY="$ROOT_DIR/app/src/main/java/gpj/android_recorder/MainActivity.java"

if grep -Fq "onPlay(mStartPlaying[0]);" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Play button must not dispatch onPlay before branch-specific UI updates." >&2
  exit 1
fi

if ! grep -Fq "onPlay(true);" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Play-start branch must call onPlay(true)." >&2
  exit 1
fi

if ! grep -Fq "onPlay(false);" "$MAIN_ACTIVITY"; then
  printf '%s\n' "Play-stop branch must call onPlay(false)." >&2
  exit 1
fi

printf '%s\n' "Audio recorder baseline checks passed."
