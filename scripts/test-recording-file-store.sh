#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ -n "${JAVA_HOME:-}" ]; then
  JAVAC=${JAVAC:-$JAVA_HOME/bin/javac}
  JAVA=${JAVA:-$JAVA_HOME/bin/java}
else
  JAVAC=${JAVAC:-$(command -v javac || true)}
  JAVA=${JAVA:-$(command -v java || true)}
fi

if [ -z "$JAVAC" ] || [ -z "$JAVA" ] || [ ! -x "$JAVAC" ] || [ ! -x "$JAVA" ]; then
  printf '%s\n' "Java 8 or newer is required for host recorder tests." >&2
  exit 1
fi

BUILD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/android-audio-tests.XXXXXX")
trap 'rm -rf "$BUILD_DIR"' EXIT HUP INT TERM

"$JAVAC" -d "$BUILD_DIR" \
  "$ROOT_DIR/app/src/main/java/gpj/android_recorder/RecordingFileStore.java" \
  "$ROOT_DIR/scripts/java/gpj/android_recorder/RecordingFileStoreTest.java"
"$JAVA" -cp "$BUILD_DIR" gpj.android_recorder.RecordingFileStoreTest
