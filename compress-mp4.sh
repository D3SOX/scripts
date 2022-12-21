#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    exit 1
fi
input=$1
output=$2

# validate input file
if [ -f "$input" ]; then
    tempout="temp-$input"
    tempoutsecond="temp2-$input"

    # cleanup from last run
    rm -f "$tempout"
    rm -f "$tempsecond"
    rm -f "x264_2pass.log"
    rm -f "x264_2pass.log.mbtree"
    
    # double-pass encode
    ffmpeg -hide_banner -y -i "$input" -c:v libx264 -x264-params pass=1 -b:v 318k -c:a libmp3lame -b:a 128k -f mp4 /dev/null && ffmpeg -hide_banner -i "$input" -c:v libx264 -x264-params pass=2 -b:v 318k -c:a libmp3lame -b:a 128k "$tempout"
    # compress further
    ffmpeg -hide_banner -y -i "$tempout" -c:v libx264 -crf 18 -preset veryslow -c:a copy "$tempoutsecond"
    # resize
    #w=1280
    #h=720
    w=640
    h=360
    ffmpeg -hide_banner -y -i "$tempoutsecond" -vf scale=$w:$h "$output"
    
    # cleanup
    rm -f "$tempout"
    rm -f "$tempsecond"
    rm -f "x264_2pass.log"
    rm -f "x264_2pass.log.mbtree"

    echo "Generated $output"
else
    echo "File $input not found"
fi

