#!/bin/bash

shopt -s globstar
for f in **/*.m4a; do
 echo "Now converting $f ..."
 ffmpeg -i "$f" -acodec libmp3lame -aq 2 -ab 320k "${f%.m4a}.mp3"
 echo "Removing $f ..."
 rm "$f"
 echo "Done converting $f into ${f%.m4a}.mp3 !"
done
