package gpj.android_recorder;

import android.app.Activity;
import android.app.ActionBar;
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
    private String mFileName = null;

    private ImageButton mRecordButton = null;
    private MediaRecorder mRecorder = null;
    private boolean mStartRecording = true;

    private ImageButton mPlayButton = null;
    private MediaPlayer mPlayer = null;
    private boolean mStartPlaying = true;

    private boolean onRecord(boolean start) {
        if (start) {
            return startRecording();
        }

        boolean recorderPresent = mRecorder != null;
        boolean stopped = stopRecording();
        if (recorderPresent && !stopped) {
            discardStopFailedRecording();
        }
        return stopped;
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
        mPlayer = new MediaPlayer();
        MediaPlayer player = mPlayer;
        try {
            mPlayer.setDataSource(mFileName);
            mPlayer.prepare();
            mPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
                public void onCompletion(MediaPlayer mp) {
                    if (mPlayer != mp) {
                        return;
                    }
                    releasePlayer();
                    resetPlaybackControls();
                }
            });
            mPlayer.setOnErrorListener(new MediaPlayer.OnErrorListener() {
                public boolean onError(MediaPlayer mp, int what, int extra) {
                    if (mPlayer != mp) {
                        return true;
                    }
                    Log.e(LOG_TAG, "playback error");
                    releasePlayer();
                    resetPlaybackControls();
                    return true;
                }
            });
            player.start();
            return mPlayer == player;
        } catch (IOException e) {
            Log.e(LOG_TAG, "prepare() failed");
            releasePlayer();
        } catch (RuntimeException e) {
            Log.e(LOG_TAG, "startPlaying() failed");
            releasePlayer();
        }

        return false;
    }

    private void stopPlaying() {
        if (mPlayer != null) {
            try {
                mPlayer.stop();
            } catch (RuntimeException e) {
                Log.e(LOG_TAG, "stopPlaying() failed");
            }
        }

        releasePlayer();
    }

    private void releasePlayer() {
        if (mPlayer != null) {
            mPlayer.release();
        }
        mPlayer = null;
    }

    private void resetPlaybackControls() {
        if (mPlayButton != null) {
            mPlayButton.setVisibility(View.INVISIBLE);
            mPlayButton.setImageResource(R.drawable.play);
        }

        if (mRecordButton != null) {
            mRecordButton.setVisibility(View.VISIBLE);
            mRecordButton.setImageResource(R.drawable.record);
        }

        mStartPlaying = true;
    }

    private void resetRecordingControls() {
        if (mRecordButton != null) {
            mRecordButton.setVisibility(View.VISIBLE);
            mRecordButton.setImageResource(R.drawable.record);
        }

        mStartRecording = true;
    }

    private boolean startRecording() {
        releaseRecorder();
        boolean outputConfigured = false;
        try {
            mRecorder = new MediaRecorder();
            final MediaRecorder recorder = mRecorder;
            recorder.setAudioSource(MediaRecorder.AudioSource.MIC);
            recorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
            recorder.setOutputFile(mFileName);
            outputConfigured = true;
            recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
            recorder.setOnErrorListener(new MediaRecorder.OnErrorListener() {
                public void onError(MediaRecorder mr, int what, int extra) {
                    if (mRecorder != mr) {
                        return;
                    }
                    Log.e(LOG_TAG, "recording error");
                    discardFailedRecording(true);
                    resetRecordingControls();
                    resetPlaybackControls();
                }
            });
            recorder.prepare();
            recorder.start();
            return mRecorder == recorder;
        } catch (IOException e) {
            Log.e(LOG_TAG, "prepare() failed");
            discardFailedRecording(outputConfigured);
        } catch (RuntimeException e) {
            Log.e(LOG_TAG, "startRecording() failed");
            discardFailedRecording(outputConfigured);
        }

        return false;
    }

    private boolean stopRecording() {
        boolean stopped = false;
        if (mRecorder != null) {
            try {
                mRecorder.stop();
                stopped = true;
            } catch (RuntimeException e) {
                Log.e(LOG_TAG, "stopRecording() failed");
            }
        }

        releaseRecorder();
        return stopped;
    }

    private void releaseRecorder() {
        if (mRecorder != null) {
            mRecorder.release();
        }
        mRecorder = null;
    }

    private void discardFailedRecording(boolean outputConfigured) {
        releaseRecorder();
        if (!outputConfigured) {
            return;
        }
        if (mFileName != null) {
            File recording = new File(mFileName);
            if (recording.exists() && !recording.delete()) {
                Log.e(LOG_TAG, "failed recording cleanup failed");
            }
        }
    }

    private void discardStopFailedRecording() {
        if (mFileName != null) {
            File recording = new File(mFileName);
            if (recording.exists() && !recording.delete()) {
                Log.e(LOG_TAG, "failed finalization cleanup failed");
            }
        }
    }

    private void discardInterruptedRecording() {
        stopRecording();
        if (mFileName != null) {
            File recording = new File(mFileName);
            if (recording.exists() && !recording.delete()) {
                Log.e(LOG_TAG, "interrupted recording cleanup failed");
            }
        }
    }

    private File recordingDirectory() {
        File directory = getExternalFilesDir(null);
        if (directory == null) {
            directory = getFilesDir();
        }
        return directory;
    }

    private void configureRecordingFile() {
        mFileName = new File(
                recordingDirectory(),
                RECORDING_FILE_NAME).getAbsolutePath();
    }

    @Override
    public void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        configureRecordingFile();

        ActionBar actionBar = getActionBar();
        if (actionBar != null) {
            actionBar.setDisplayShowTitleEnabled(false);
            actionBar.setIcon(R.drawable.logo);
        }

        setContentView(R.layout.activity_main);

        mRecordButton = (ImageButton) findViewById(R.id.record);
        mPlayButton = (ImageButton) findViewById(R.id.play);
        if (mRecordButton == null || mPlayButton == null) {
            Log.e(LOG_TAG, "Recorder controls are not available");
            return;
        }

        mRecordButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                // Do something in response to button click

                if (mStartRecording) {
                    if (onRecord(true)) {
                        mRecordButton.setVisibility(View.VISIBLE);
                        mRecordButton.setImageResource(R.drawable.stop);
                        mStartRecording = false;
                    }
                } else {
                    if (onRecord(false)) {
                        mRecordButton.setVisibility(View.INVISIBLE);
                        mPlayButton.setVisibility(View.VISIBLE);
                        mPlayButton.setImageResource(R.drawable.play);
                        mStartRecording = true;
                    } else {
                        resetRecordingControls();
                        resetPlaybackControls();
                    }
                }
            }
        });

        mPlayButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                if (mStartPlaying) {
                    if (onPlay(true)) {
                        mPlayButton.setVisibility(View.VISIBLE);
                        mPlayButton.setImageResource(R.drawable.stop);
                        mStartPlaying = false;
                    } else {
                        resetPlaybackControls();
                    }
                } else {
                    onPlay(false);
                    resetPlaybackControls();
                }
            }
        });




    }

    @Override
    public void onPause() {
        super.onPause();
        if (mRecorder != null) {
            discardInterruptedRecording();
        }

        if (mPlayer != null) {
            stopPlaying();
        }

        resetRecordingControls();
        resetPlaybackControls();
    }
}
