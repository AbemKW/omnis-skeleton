import sys
import os

try:
    import imageio_ffmpeg
    ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
    ffmpeg_dir = os.path.dirname(ffmpeg_exe)
    os.environ["PATH"] = ffmpeg_dir + os.path.pathsep + os.environ.get("PATH", "")
except Exception as e:
    pass

import whisper

def transcribe(audio_path, output_path):
    model = whisper.load_model("turbo") # turbo model for 8x faster transcription with high accuracy
    result = model.transcribe(audio_path)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(result["text"])
    print(f"Transcription saved to {output_path}")

if __name__ == "__main__":
    audio = sys.argv[1]
    output = sys.argv[2]
    transcribe(audio, output)

