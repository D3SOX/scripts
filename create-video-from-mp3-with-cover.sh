#!/usr/bin/env bash
# create_video.sh: Extract cover art from an MP3 and turn it into a 1920x1080 video with the audio

set -euo pipefail

# Default values
RESOLUTION="1920:1080"

usage() {
  cat << EOF
Usage: $(basename "$0") -i INPUT_MP3 -o OUTPUT_MP4 [OPTIONS]

Required:
  -i INPUT_MP3    Path to the input MP3 file containing cover art
  -o OUTPUT_MP4   Path for the generated MP4 video

Options:
  -c COVER       Use existing COVER image instead of extracting from MP3
  -r RES         Video resolution in WIDTH:HEIGHT (default: ${RESOLUTION})
  -h             Show this help message and exit

Examples:
  # Extract cover and create 1920x1080 video
  $(basename "$0") -i song.mp3 -o video.mp4

  # Use custom cover image and custom resolution
  $(basename "$0") -i song.mp3 -o video.mp4 -c cover.jpg -r 1280:720
EOF
  exit 1
}

# Parse arguments
while getopts ":i:o:c:r:h" opt; do
  case ${opt} in
    i ) INPUT_MP3="$OPTARG" ;;
    o ) OUTPUT_MP4="$OPTARG" ;;
    c ) COVER_FILE="$OPTARG" ;;
    r ) RESOLUTION="$OPTARG" ;;
    h ) usage ;;
    \? ) echo "Invalid option: -$OPTARG" >&2; usage ;;
    : ) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done
shift $((OPTIND -1))

# Validate required parameters
if [[ -z "${INPUT_MP3-}" || -z "${OUTPUT_MP4-}" ]]; then
  echo "Error: Input MP3 and output video must be specified." >&2
  usage
fi

# Create a temporary cover file if not provided
if [[ -z "${COVER_FILE-}" ]]; then
  TMP_COVER=$(mktemp --suffix=".jpg")
  echo "Extracting cover art from '$INPUT_MP3' to '$TMP_COVER'..."
  ffmpeg -y -i "$INPUT_MP3" -an -c:v copy "$TMP_COVER"
  COVER_FILE="$TMP_COVER"
fi

# Determine exact audio duration using ffprobe
AUDIO_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT_MP3")
# Round duration to second-precision or keep as float
# You can also format with printf if needed:
# DURATION=$(printf "%.3f" "$AUDIO_DURATION")

echo "Audio duration detected: ${AUDIO_DURATION}s"

echo "Creating video '$OUTPUT_MP4' at resolution ${RESOLUTION}..."
ffmpeg -y \
  -loop 1 -i "$COVER_FILE" \
  -i "$INPUT_MP3" \
  -c:v libx264 -tune stillimage \
  -vf "scale=${RESOLUTION}:force_original_aspect_ratio=decrease,pad=${RESOLUTION}:(ow-iw)/2:(oh-ih)/2" \
  -c:a libmp3lame -b:a 128k \
  -t "$AUDIO_DURATION" \
  -shortest \
  -vsync vfr \
  "$OUTPUT_MP4"

# Clean up temporary cover
if [[ -n "${TMP_COVER-}" && -f "$TMP_COVER" ]]; then
  rm "$TMP_COVER"
fi

echo "Done. Video saved to '$OUTPUT_MP4'."

