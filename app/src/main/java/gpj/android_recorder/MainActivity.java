package gpj.android_recorder;

import android.app.Activity;
import android.app.ActionBar;
import android.content.Context;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageButton;

import java.io.File;
import java.io.IOException;

public class MainActivity extends Activity {

    private static final String LOG_TAG = "AudioRecordTest";
    private static final String RECORDING_FILE_NAME = "audiorecordtest.3gp";
    private RecordingFileStore mRecordingFiles = null;

    private ImageButton mRecordButton = null;
    private MediaRecorder mRecorder = null;
    private boolean mStartRecording = true;

    private ImageButton mPlayButton = null;
    private MediaPlayer mPlayer = null;
    private boolean mStartPlaying = true;
    private AudioManager mAudioManager = null;
    private boolean mHasAudioFocus = false;
    private AudioManager.OnAudioFocusChangeListener mAudioFocusListener = null;

    private boolean onRecord(boolean start) {
        if (start) {
            return startRecording();
        }

        return stopRecording();
    }

    private boolean onPlay(boolean start) {
        if (start) {
            return startPlaying();
        }

        stopPlaying();
        return true;
    }

    private boolean startPlaying() {
        releasePlayer();
        File recording = mRecordingFiles == null ? null : mRecordingFiles.getPlayableFile();
        if (recording == null || !requestPlaybackAudioFocus()) {
            return false;
        }

        MediaPlayer player = null;
        try {
            player = new MediaPlayer();
            mPlayer = player;
            player.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
                public void onCompletion(MediaPlayer mp) {
                    if (mPlayer != mp) {
                        return;
                    }
                    releasePlayerIfOwned(mp);
                    showIdleControls();
                }
            });
            player.setOnErrorListener(new MediaPlayer.OnErrorListener() {
                public boolean onError(MediaPlayer mp, int what, int extra) {
                    if (mPlayer != mp) {
                        return true;
                    }
                    Log.e(LOG_TAG, "playback error");
                    releasePlayerIfOwned(mp);
                    showIdleControls();
                    return true;
                }
            });
            player.setDataSource(recording.getAbsolutePath());
            player.prepare();
            player.start();
            return mPlayer == player;
        } catch (IOException e) {
            Log.e(LOG_TAG, "prepare() failed");
        } catch (RuntimeException e) {
            Log.e(LOG_TAG, "startPlaying() failed");
        }

        if (player != null) {
            releasePlayerIfOwned(player);
        } else {
            abandonPlaybackAudioFocus();
        }

        return false;
    }

    private void stopPlaying() {
        MediaPlayer player = mPlayer;
        mPlayer = null;
        if (player != null) {
            try {
                player.stop();
            } catch (RuntimeException e) {
                Log.e(LOG_TAG, "stopPlaying() failed");
            } finally {
                safeReleasePlayer(player);
            }
        }
        abandonPlaybackAudioFocus();
    }

    private void releasePlayer() {
        MediaPlayer player = mPlayer;
        mPlayer = null;
        if (player != null) {
            safeReleasePlayer(player);
        }
        abandonPlaybackAudioFocus();
    }

    private void releasePlayerIfOwned(MediaPlayer player) {
        if (mPlayer != player) {
            return;
        }
        mPlayer = null;
        safeReleasePlayer(player);
        abandonPlaybackAudioFocus();
    }

    private void safeReleasePlayer(MediaPlayer player) {
        try {
            player.release();
        } catch (RuntimeException e) {
            Log.e(LOG_TAG, "releasePlayer() failed");
        }
    }

    private boolean requestPlaybackAudioFocus() {
        if (mAudioManager == null) {
            return false;
        }
        final AudioManager.OnAudioFocusChangeListener focusListener =
                new AudioManager.OnAudioFocusChangeListener() {
                    public void onAudioFocusChange(int focusChange) {
                        if (mAudioFocusListener != this) {
                            return;
                        }
                        if (focusChange == AudioManager.AUDIOFOCUS_LOSS ||
                                focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
                            stopPlaying();
                            showIdleControls();
                        }
                    }
                };
        int result = mAudioManager.requestAudioFocus(
                focusListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT);
        mHasAudioFocus = result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
        if (mHasAudioFocus) {
            mAudioFocusListener = focusListener;
        }
        return mHasAudioFocus;
    }

    private void abandonPlaybackAudioFocus() {
        AudioManager.OnAudioFocusChangeListener focusListener = mAudioFocusListener;
        boolean hadAudioFocus = mHasAudioFocus;
        mAudioFocusListener = null;
        mHasAudioFocus = false;
        if (mAudioManager != null && hadAudioFocus && focusListener != null) {
            mAudioManager.abandonAudioFocus(focusListener);
        }
    }

    private void showIdleControls() {
        if (mRecordButton != null) {
            mRecordButton.setVisibility(View.VISIBLE);
            mRecordButton.setImageResource(R.drawable.record);
        }

        if (mPlayButton != null) {
            boolean hasRecording = mRecordingFiles != null &&
                    mRecordingFiles.hasPlayableRecording();
            mPlayButton.setVisibility(
                    hasRecording ? View.VISIBLE : View.INVISIBLE);
            mPlayButton.setImageResource(R.drawable.play);
        }

        mStartRecording = true;
        mStartPlaying = true;
    }

    private void showRecordingControls() {
        if (mRecordButton != null) {
            mRecordButton.setVisibility(View.VISIBLE);
            mRecordButton.setImageResource(R.drawable.stop);
        }
        if (mPlayButton != null) {
            mPlayButton.setVisibility(View.INVISIBLE);
        }
        mStartRecording = false;
        mStartPlaying = true;
    }

    private void showPlaybackControls() {
        if (mPlayButton != null) {
            mPlayButton.setVisibility(View.VISIBLE);
            mPlayButton.setImageResource(R.drawable.stop);
        }
        if (mRecordButton != null) {
            mRecordButton.setVisibility(View.INVISIBLE);
        }
        mStartPlaying = false;
        mStartRecording = true;
    }

    private boolean startRecording() {
        discardInterruptedRecording();
        try {
            File pendingRecording = mRecordingFiles.beginRecording();
            mRecorder = new MediaRecorder();
            final MediaRecorder recorder = mRecorder;
            recorder.setAudioSource(MediaRecorder.AudioSource.MIC);
            recorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
            recorder.setOutputFile(pendingRecording.getAbsolutePath());
            recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
            recorder.setOnErrorListener(new MediaRecorder.OnErrorListener() {
                public void onError(MediaRecorder mr, int what, int extra) {
                    if (mRecorder != mr) {
                        return;
                    }
                    Log.e(LOG_TAG, "recording error");
                    releaseRecorderIfOwned(mr);
                    mRecordingFiles.discardRecording();
                    showIdleControls();
                }
            });
            recorder.prepare();
            recorder.start();
            if (mRecorder != recorder) {
                return false;
            }
            return true;
        } catch (IOException e) {
            Log.e(LOG_TAG, "prepare() failed");
        } catch (RuntimeException e) {
            Log.e(LOG_TAG, "startRecording() failed");
        }

        releaseRecorder();
        if (mRecordingFiles != null) {
            mRecordingFiles.discardRecording();
        }
        return false;
    }

    private boolean stopRecording() {
        MediaRecorder recorder = mRecorder;
        mRecorder = null;
        if (recorder == null) {
            return false;
        }

        boolean stopped = false;
        try {
            recorder.stop();
            stopped = true;
        } catch (RuntimeException e) {
            Log.e(LOG_TAG, "stopRecording() failed");
        } finally {
            safeReleaseRecorder(recorder);
        }

        if (stopped && mRecordingFiles.commitRecording()) {
            return true;
        }
        mRecordingFiles.discardRecording();
        return false;
    }

    private void releaseRecorder() {
        MediaRecorder recorder = mRecorder;
        mRecorder = null;
        if (recorder != null) {
            safeReleaseRecorder(recorder);
        }
    }

    private void releaseRecorderIfOwned(MediaRecorder recorder) {
        if (mRecorder != recorder) {
            return;
        }
        mRecorder = null;
        safeReleaseRecorder(recorder);
    }

    private void safeReleaseRecorder(MediaRecorder recorder) {
        try {
            recorder.release();
        } catch (RuntimeException e) {
            Log.e(LOG_TAG, "releaseRecorder() failed");
        }
    }

    private void discardInterruptedRecording() {
        MediaRecorder recorder = mRecorder;
        mRecorder = null;
        if (recorder != null) {
            try {
                recorder.stop();
            } catch (RuntimeException e) {
                Log.e(LOG_TAG, "interrupted recording stop failed");
            } finally {
                safeReleaseRecorder(recorder);
            }
        }
        if (mRecordingFiles != null && !mRecordingFiles.discardRecording()) {
            Log.e(LOG_TAG, "interrupted recording cleanup failed");
        }
    }

    private void configureRecordingFiles() {
        try {
            mRecordingFiles = new RecordingFileStore(
                    getFilesDir(),
                    RECORDING_FILE_NAME);
        } catch (IOException e) {
            Log.e(LOG_TAG, "recording storage unavailable");
            mRecordingFiles = null;
        }
    }

    @Override
    public void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        configureRecordingFiles();
        mAudioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);

        ActionBar actionBar = getActionBar();
        if (actionBar != null) {
            actionBar.setDisplayShowTitleEnabled(false);
            actionBar.setIcon(R.drawable.logo);
        }

        setContentView(R.layout.activity_main);

        mRecordButton = (ImageButton) findViewById(R.id.record);
        mPlayButton = (ImageButton) findViewById(R.id.play);
        showIdleControls();
        if (mRecordButton == null || mPlayButton == null) {
            Log.e(LOG_TAG, "Recorder controls are not available");
            return;
        }

        mRecordButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                // Do something in response to button click

                if (mStartRecording) {
                    if (onRecord(true)) {
                        showRecordingControls();
                    } else {
                        showIdleControls();
                    }
                } else {
                    onRecord(false);
                    showIdleControls();
                }
            }
        });

        mPlayButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                if (mStartPlaying) {
                    if (onPlay(true)) {
                        showPlaybackControls();
                    } else {
                        showIdleControls();
                    }
                } else {
                    onPlay(false);
                    showIdleControls();
                }
            }
        });
    }

    @Override
    public void onPause() {
        if (mRecorder != null) {
            discardInterruptedRecording();
        }

        if (mPlayer != null) {
            stopPlaying();
        }

        showIdleControls();
        super.onPause();
    }
}
