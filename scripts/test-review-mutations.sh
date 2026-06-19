#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MUTATION_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/android-audio-mutations.XXXXXX")
trap 'rm -rf "$MUTATION_ROOT"' EXIT HUP INT TERM

run_mutation() {
  name=$1
  file=$2
  expression=$3
  test_command=$4
  case_root="$MUTATION_ROOT/$name"

  mkdir -p "$case_root"
  cp -R "$ROOT_DIR/app" "$ROOT_DIR/scripts" "$case_root/"
  perl -0pi -e "$expression" "$case_root/$file"
  if (cd "$case_root" && sh -c "$test_command") >/dev/null 2>&1; then
    printf '%s\n' "Mutation survived: $name" >&2
    exit 1
  fi
}

run_mutation finalized-output-target \
  app/src/main/java/gpj/android_recorder/MainActivity.java \
  's/recorder\.setOutputFile\(pendingRecording\.getAbsolutePath\(\)\)/recorder.setOutputFile(mRecordingFiles.getPlayableFile().getAbsolutePath())/' \
  './scripts/test-main-activity-contracts.py'

run_mutation retained-player-ownership \
  app/src/main/java/gpj/android_recorder/MainActivity.java \
  's/MediaPlayer player = mPlayer;\n        mPlayer = null;/MediaPlayer player = mPlayer;/' \
  './scripts/test-main-activity-contracts.py'

run_mutation hidden-replay-control \
  app/src/main/java/gpj/android_recorder/MainActivity.java \
  's/hasRecording \? View\.VISIBLE : View\.INVISIBLE/View.INVISIBLE/' \
  './scripts/test-main-activity-contracts.py'

run_mutation removed-audio-focus \
  app/src/main/java/gpj/android_recorder/MainActivity.java \
  's/mAudioManager\.requestAudioFocus/mAudioManager.requestRemovedAudioFocus/' \
  './scripts/test-main-activity-contracts.py'

run_mutation unguarded-player-construction \
  app/src/main/java/gpj/android_recorder/MainActivity.java \
  's/MediaPlayer player = null;\n        try \{\n            player = new MediaPlayer\(\);/MediaPlayer player = new MediaPlayer();\n        try {/' \
  './scripts/test-main-activity-contracts.py'

run_mutation late-pause-cleanup \
  app/src/main/java/gpj/android_recorder/MainActivity.java \
  's/public void onPause\(\) \{\n/public void onPause() {\n        super.onPause();\n/; s/        showIdleControls\(\);\n        super\.onPause\(\);/        showIdleControls();/' \
  './scripts/test-main-activity-contracts.py'

run_mutation delete-finalized-on-failure \
  app/src/main/java/gpj/android_recorder/RecordingFileStore.java \
  's/return !pendingFile\.exists\(\) \|\| discardOwnedFile\(pendingFile\);/return !recordingFile.exists() || discardOwnedFile(recordingFile);/' \
  './scripts/test-recording-file-store.sh'

run_mutation group-readable-output \
  app/src/main/java/gpj/android_recorder/RecordingFileStore.java \
  's/file\.setReadable\(false, false\)/true/' \
  './scripts/test-recording-file-store.sh'

run_mutation symlinked-recorder-state \
  app/src/main/java/gpj/android_recorder/RecordingFileStore.java \
  's/if \(!file\.equals\(file\.getCanonicalFile\(\)\) \|\| !file\.isFile\(\)\)/if (!file.isFile())/; s/return file\.exists\(\) && file\.isFile\(\) &&\n                    directory\.equals\(file\.getCanonicalFile\(\)\.getParentFile\(\)\) &&\n                    file\.equals\(file\.getCanonicalFile\(\)\);/return file.exists() \&\& file.isFile();/' \
  './scripts/test-recording-file-store.sh'

printf '%s\n' "Android audio hostile mutations passed."
