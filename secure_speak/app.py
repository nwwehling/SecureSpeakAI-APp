import os
import yt_dlp
from flask import Flask, request, jsonify
from keras.models import load_model
import librosa
import numpy as np

app = Flask(__name__)

# Load the trained model
def load_trained_model():
    model_path = 'securespeak_model.h5'
    model = load_model(model_path)
    return model

# Preprocess the audio file
def preprocess_audio(audio_path, max_sequence_length):
    audio_data, sr = librosa.load(audio_path, sr=None, duration=5.0, dtype=np.float32)
    mfccs = librosa.feature.mfcc(y=audio_data, sr=sr, n_mfcc=13, n_fft=1024, hop_length=256)
    mfccs = mfccs.T
    mfccs = mfccs[:, :, np.newaxis]

    if mfccs.shape[0] < max_sequence_length:
        pad_width = max_sequence_length - mfccs.shape[0]
        mfccs = np.pad(mfccs, ((0, pad_width), (0, 0), (0, 0)), mode='constant')
    elif mfccs.shape[0] > max_sequence_length:
        mfccs = mfccs[:max_sequence_length, :]

    return mfccs[np.newaxis, :, :, :]

# Predict whether the audio is human or not
def predict_human_or_not(model, audio_path, max_sequence_length):
    preprocessed_audio = preprocess_audio(audio_path, max_sequence_length)
    prediction = model.predict(preprocessed_audio)
    label = "Human" if prediction > 0.4 else "AI"
    confidence_percentage = prediction[0][0] * 100 if label == "Human" else (1 - prediction[0][0]) * 100
    return label, confidence_percentage

# Download video and extract audio
def download_video(url, output_path):
    ydl_opts = {
        'format': 'bestaudio/best',
        'outtmpl': output_path,
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'wav',
            'preferredquality': '192',
        }],
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([url])

@app.route('/process_video', methods=['POST'])
def process_video():
    data = request.get_json()
    video_url = data.get('video_link')

    if video_url:
        try:
            audio_path = "/tmp/extracted_audio.wav"
            download_video(video_url, audio_path)

            model = load_trained_model()
            max_sequence_length = 1071
            prediction, confidence = predict_human_or_not(model, audio_path, max_sequence_length)

            os.remove(audio_path)

            return jsonify({'prediction': prediction, 'confidence': confidence})
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    return jsonify({'error': 'No video link provided'}), 400

if __name__ == "__main__":
    app.run()
