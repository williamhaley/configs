#!/usr/bin/env bash

help_and_exit() {
  cat <<-EOF
  Usage: screenshot.sh [-h|-s|-c]

  Take screenshot of a whole screen or a specified region,
  save it to a specified folder (current folder is default)
  and copy it to a clipboard.

    -h   - print help and exit
    -s   - take a screenshot of a screen region
    -c   - save only to clipboard
EOF
    exit 0
}

base_folder="$HOME/Downloads/"
mkdir -p "${base_folder}"
savefile=true
region=false
params="-window root"
while test $# -gt 0; do
  case "$1" in
    -h|--help*)
      help_and_exit
      ;;
    -r|--region*)
      params=""
      shift
      ;;
    -c|--clipboard-only*)
      savefile=false
      shift
      ;;
    *)
      help_and_exit
      shift
      ;;
  esac
done

file_path=${base_folder}$( date '+%Y-%m-%d_%H-%M-%S' )_screenshot.png
import ${params} ${file_path}
xclip -selection clipboard -target image/png -i < ${file_path}

if [ "$savefile" = false ] ; then
  rm ${file_path}
fi

