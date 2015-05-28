package gpj.android_recorder;

import android.app.Activity;
import android.content.Context;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.LinearLayout;

import java.io.IOException;


public class MainActivity extends Activity {



    private static final String LOG_TAG = "AudioRecordTest";
    private static String mFileName = null;

    private ImageButton mRecordButton = null;
    private MediaRecorder mRecorder = null;

    private ImageButton mPlayButton = null;
    private MediaPlayer mPlayer = null;


    private void onRecord(boolean start) {
        if (start) {
            startRecording();
        } else {
            stopRecording();
        }
    }

    private void onPlay(boolean start) {
        if (start) {
            startPlaying();
        } else {
            stopPlaying();
        }
    }

    private void startPlaying() {
        mPlayer = new MediaPlayer();
        try {
            mPlayer.setDataSource(mFileName);
            mPlayer.prepare();
            mPlayer.start();
        } catch (IOException e) {
            Log.e(LOG_TAG, "prepare() failed");
        }
    }

    private void stopPlaying() {
        if(mPlayer != null) {
            mPlayer.stop();
            mPlayer.reset();
            mPlayer.release();
        }

        mPlayer = null;
    }

    private void startRecording() {
        mRecorder = new MediaRecorder();
        mRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
        mRecorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
        mRecorder.setOutputFile(mFileName);
        mRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);

        try {
            mRecorder.prepare();
        } catch (IOException e) {
            Log.e(LOG_TAG, "prepare() failed");
        }

        mRecorder.start();
    }

    private void stopRecording() {
        mRecorder.stop();
        mRecorder.release();
        mRecorder = null;
    }

    public MainActivity() {
        mFileName = Environment.getExternalStorageDirectory().getAbsolutePath();
        mFileName += "/audiorecordtest.3gp";
    }

    @Override
    public void onCreate(Bundle icicle) {
        super.onCreate(icicle);

        getActionBar().setDisplayShowTitleEnabled(false);
        getActionBar().setIcon(R.drawable.logo);

        setContentView(R.layout.activity_main);

        final boolean[] mStartRecording = {true};
        mRecordButton = (ImageButton) findViewById(R.id.record);
        mRecordButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                // Do something in response to button click

                if (mStartRecording[0]) {
                    startRecording();
                    mRecordButton.setVisibility(View.VISIBLE);
                    mRecordButton.setImageResource(R.drawable.stop);
                } else {
                    stopRecording();
                    mRecordButton.setVisibility(View.INVISIBLE);
                    mPlayButton.setVisibility(View.VISIBLE);
                    mPlayButton.setImageResource(R.drawable.play);
                }
                mStartRecording[0] = !mStartRecording[0];
            }
        });


        final boolean[] mStartPlaying = {true};
        mPlayButton = (ImageButton) findViewById(R.id.play);
        mPlayButton.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                onPlay(mStartPlaying[0]);
                if (mStartPlaying[0]) {
                    startPlaying();
                    mPlayButton.setVisibility(View.VISIBLE);
                    mPlayButton.setImageResource(R.drawable.stop);
                } else {
                    stopPlaying();
                    mPlayButton.setVisibility(View.INVISIBLE);
                    mRecordButton.setVisibility(View.VISIBLE);
                    mRecordButton.setImageResource(R.drawable.record);
                }
                mStartPlaying[0] = !mStartPlaying[0];
            }
        });




    }

    @Override
    public void onPause() {
        super.onPause();
        if (mRecorder != null) {
            mRecorder.release();
            mRecorder = null;
        }

        if (mPlayer != null) {
            mPlayer.release();
            mPlayer = null;
        }
    }
}
