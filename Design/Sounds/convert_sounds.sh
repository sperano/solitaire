#!/bin/sh
# Converts the sound effects in this directory into the app's resources:
#     Design/Sounds/convert_sounds.sh
# The .ogg files are from Kenney's Casino Audio 1.1 (CC0, see License.txt), kept unchanged;
# iOS cannot play Ogg, so each becomes AAC in an .m4a named after its SoundEffect case.
# Needs ffmpeg. Commit the files it writes.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
out="$here/../../Solitaire/Resources/Sounds"
bitrate=96k

convert() {
    ffmpeg -loglevel error -y -i "$here/$1.ogg" -map_metadata -1 -c:a aac -b:a "$bitrate" "$out/$2.m4a"
}

mkdir -p "$out"
convert card-slide-1 draw
convert card-place-2 place
convert card-slide-4 flip
convert card-shove-1 undo
convert card-fan-2 win
