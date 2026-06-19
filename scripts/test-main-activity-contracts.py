#!/usr/bin/env python3
from pathlib import Path
import sys


root = Path(__file__).resolve().parents[1]
source = (root / "app/src/main/java/gpj/android_recorder/MainActivity.java").read_text()
manifest = (root / "app/src/main/AndroidManifest.xml").read_text()


def require(fragment: str, message: str) -> None:
    if fragment not in source:
        raise AssertionError(message)


def reject(fragment: str, message: str) -> None:
    if fragment in source:
        raise AssertionError(message)


require("private RecordingFileStore mRecordingFiles", "activity must own recording storage")
require("mRecordingFiles.beginRecording()", "recording must start in a pending file")
require("recorder.setOutputFile(pendingRecording.getAbsolutePath())",
        "MediaRecorder must write only to the pending recording")
require("mRecordingFiles.commitRecording()", "successful stop must promote pending output")
require("mRecordingFiles.discardRecording()", "failed capture must discard only pending output")
reject("setOutputFile(mFileName)", "recorder must not overwrite the finalized capture")
reject("getExternalFilesDir", "microphone recordings must remain in internal app storage")

if source.count("MediaRecorder recorder = mRecorder;\n        mRecorder = null;") < 3:
    raise AssertionError("every recorder stop/release path must detach ownership first")
if source.count("MediaPlayer player = mPlayer;\n        mPlayer = null;") < 2:
    raise AssertionError("every player stop/release path must detach ownership first")
require("if (mRecorder != recorder)", "recorder startup must preserve exact ownership")
require("if (mPlayer != player)", "player startup must preserve exact ownership")

require("requestAudioFocus", "playback must request audio focus")
require("abandonAudioFocus", "playback cleanup must abandon audio focus")
require("AudioManager.AUDIOFOCUS_LOSS", "focus loss must stop active playback")

start_playing = source.index("private boolean startPlaying()")
start_playing_end = source.index("private void stopPlaying()", start_playing)
start_playing_source = source[start_playing:start_playing_end]
if start_playing_source.index("try {") > start_playing_source.index("new MediaPlayer()"):
    raise AssertionError("MediaPlayer construction must remain inside guarded focus cleanup")

on_pause = source.index("public void onPause()")
on_pause_end = source.index("\n    }", on_pause)
on_pause_source = source[on_pause:on_pause_end]
if on_pause_source.index("super.onPause();") < on_pause_source.index("discardInterruptedRecording();"):
    raise AssertionError("onPause must stop sensitive recording before delegating lifecycle")

require("showIdleControls();", "completion and failure paths must restore idle controls")
require("mRecordingFiles.hasPlayableRecording()", "idle controls must query finalized output")
require("hasRecording ? View.VISIBLE : View.INVISIBLE",
        "idle controls must preserve replay access to a finalized recording")

if "android.permission.RECORD_AUDIO" not in manifest:
    raise AssertionError("manifest must retain microphone permission")

sys.stdout.write("MainActivity contracts passed.\n")
