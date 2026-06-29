#!/usr/bin/env bash

set -e

function random() {
    picture="$(find ~/Pictures -type f -name '*.jpg' -o -name '*.png' -o -name '*.heic' | shuf -n 1)"
    #picture="$(find ~/Pictures -type f -name '2025*.png' -o -name '2025*.jpg' -o -name '2024*.png' -o -name '2024*.jpg' | shuf -n 1)"

    filename="$(basename "${picture}")"
    extension="${filename##*.}"

    output="/tmp/bg.jpg" # ${extension}"
    basename "${picture}" > /tmp/bg.info
    echo "${picture}" >> /tmp/bg.history

    if [ "${extension}" = "heic" ]
    then
        heif-convert "${picture}" "${output}"
        picture="${output}"
    fi

    # magick "${picture}" -gravity North -pointsize 30 -annotate +0+100 "${picture}" "${output}"
    # convert -pointsize 40 -fill blue -font arial -draw "text 600,600 \"${picture}\"" "${picture}" "${output}"

    # Account for the size of the i3 status bar on top of the window.
    ffmpeg -y -i "${picture}" -vf "drawtext=textfile=/tmp/bg.info:fontcolor=white:fontsize=75:x=10:y=200:bordercolor=black:borderw=5:" "${output}"

    gsettings set org.gnome.desktop.background picture-options scaled
    gsettings set org.gnome.desktop.background picture-uri file://${output}
    # feh --scale-down --bg-max "${output}"
}

while true
do
    random
    sleep 60
done

