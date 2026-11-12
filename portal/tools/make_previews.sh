#!/usr/bin/env bash
# usage: portal/tools/make_previews.sh <frames_landscape_dir> <frames_portrait_dir> <covers_dir> <sha> <out_dir>
# Cuts the two CrazyGames preview videos from Movie Maker frames (portal/tools/preview_demo.gd):
#   preview-landscape-1920x1080_<sha>.mp4 and preview-portrait-1080x1620_<sha>.mp4
# Spec (portal/PORTAL_ASSET_SPECS.md): 15-20 s, opens on the static cover (0.6 s hold, 0.3 s cross-fade into gameplay),
# no audio stream, H.264 yuv420p, faststart, <= 50 MB, no speed-up.
set -euo pipefail
L=$1; P=$2; C=$3; SHA=$4; OUT=$5; mkdir -p "$OUT"
cut() {  # frames_dir cover_png WxH out
  local W=${3%x*} H=${3#*x}
  ffmpeg -hide_banner -loglevel error -y -loop 1 -framerate 60 -t 0.9 -i "$2" -framerate 60 -i "$1/f%08d.png" \
    -filter_complex "[0:v]scale=$W:$H:flags=lanczos,setsar=1,format=yuv420p[c];[1:v]scale=$W:$H,setsar=1,format=yuv420p[g];[c][g]xfade=transition=fade:duration=0.3:offset=0.6[v]" \
    -map "[v]" -an -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -r 60 -t 20 -movflags +faststart "$4"
  ffprobe -v error -show_entries format=duration,size -show_entries stream=codec_name,width,height,r_frame_rate,codec_type -of compact "$4"
}
cut "$L" "$C/cover-landscape-1920x1080_$SHA.png" 1920x1080 "$OUT/preview-landscape-1920x1080_$SHA.mp4"
cut "$P" "$C/preview-open-portrait-1080x1620_$SHA.png" 1080x1620 "$OUT/preview-portrait-1080x1620_$SHA.mp4"
