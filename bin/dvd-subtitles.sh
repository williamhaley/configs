#!/usr/bin/env bash
#
# INPUT_PATH=~/file.iso OUTPUT_NAME="my dvd" TITLE_NUMBER=1 SUBTITLE_TRACK_NUMBER=7 dvd-subtitles.sh

set -e

if [ ! -f "${INPUT_PATH}" ]
then
    echo "INPUT_PATH should be the path to a DVD"
    exit 1
fi

if [ -z "${OUTPUT_NAME}" ]
then
    echo "OUTPUT_NAME should be the name of the output (no extension)"
    exit 1
fi

if [ -z "${TITLE_NUMBER}" ]
then
    echo "TITLE_NUMBER should be the DVD source title number"
    exit 1
fi

if [ -z "${SUBTITLE_TRACK_NUMBER}" ]
then
    echo "SUBTITLE_TRACK_NUMBER should be the DVD source subtitle track"
    exit 1
fi

work_dir=/tmp/subs
rm -rf "${tmp_dir}"
mkdir -p "${work_dir}"

pushd "${work_dir}"
    # This should extract the CC or other text subtitles? Not really sure how it decides on what to pull.
    docker run -u $(id -u):$(id -g) --rm -it -v "${INPUT_PATH}":/dvd.iso:ro -v "$(pwd)":/out subtitles ccextractor /dvd.iso -o "/out/${OUTPUT_NAME}.cc.en.srt"

    # mencoder \
    #     -dvd-device "${INPUT_PATH}" \
    #     "dvd://${TITLE_NUMBER}" \
    #     -nosound \
    #     -ovc copy \
    #     -o /dev/null \
    #     -sid "${SUBTITLE_TRACK_NUMBER}" \
    #     -vobsubout "${work_dir}/subtitles"

    #     vobsub2srt --tesseract-lang eng subtitles
    #     cp subtitles.srt "${OUTPUT_NAME}.en.srt"
popd
