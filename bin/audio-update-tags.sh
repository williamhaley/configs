#!/usr/bin/env bash

set -e

if [ -z "${MUSIC_DIRECTORY}" ] || [ ! -d "${MUSIC_DIRECTORY}" ]
then
	echo "specify a valid MUSIC_DIRECTORY variable structured like 'Artist/Album/01 - Track.extension'"
	exit 1
fi
echo "using directory '${MUSIC_DIRECTORY}'"

if [ -z "${ARTIST}" ] || [ ! -d "${MUSIC_DIRECTORY}/${ARTIST}" ]
then
	echo "specify a valid ARTIST directory under '${MUSIC_DIRECTORY}/"
	exit 1
fi
echo "using artist '${ARTIST}'"

if [ -z "${ALBUM}" ] || [ ! -d "${MUSIC_DIRECTORY}/${ARTIST}/${ALBUM}" ]
then
	echo "specify a valid ALBUM directory under '${MUSIC_DIRECTORY}/${ARTIST}/"
	exit 1
fi
echo "using album '${ALBUM}'"

album="${ALBUM}"
year=""

album_with_year_regex="^(.*) \(([0-9]{4})\)$"
if [[ ${ALBUM} =~ ${album_with_year_regex} ]]
then
	album="${BASH_REMATCH[1]}"
	year="${BASH_REMATCH[2]}"
fi

track_with_number_regex="^([0-9]+) - (.*).(mp3|m4a|ogg)$"

# https://superuser.com/questions/912096/list-multiple-file-types-in-bash-for-loop
shopt -s nullglob
for file in "${MUSIC_DIRECTORY}/${ARTIST}/${ALBUM}"/*.{mp3,m4a,ogg}
do
	track="$(basename "${file}")"
	track_number=""
	title=""

	if [[ ${track} =~ ${track_with_number_regex} ]]
	then
		# Seems like %i should work for base 10 int, but seemed problematic at time
		# of writing
		printf -v track_number '%.0f' "${BASH_REMATCH[1]}"
		title="${BASH_REMATCH[2]}"
	else
		echo "invalid title: '${track}'"
		exit 1
	fi

	echo "'${ARTIST}' - '${album}' - '${year}' - '${track_number}' - '${title}'"

	extension="${file##*.}"

	echo "${extension}"

	if [ "${extension}" = "mp3" ]
	then
		id3tool \
			--set-artist="${ARTIST}" \
			--set-album="${album}" \
			--set-year="${year}" \
			--set-track="${track_number}" \
			--set-title="${title}" \
			"${file}"
	else
		exiftool \
			-overwrite_original \
			-artist="${ARTIST}" \
			-album="${album}" \
			-year="${year}" \
			-TrackNumber="${track_number}" \
			-Title="${title}" \
			"${file}"
	fi
done
shopt -u nullglob
