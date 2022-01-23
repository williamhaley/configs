#!/usr/bin/env bash

set -e

work_dir="$(mktemp -d)"

echo "work_dir: ${work_dir}"

interrupt()
{
	echo "cleaning up..."
	rm -rf "${work_dir}"
	exit 1
}

trap interrupt INT EXIT

file_names=()
desired_width=3840
desired_height=2160

concat_simple()
{
	manifest="${work_dir}/manifest.txt"

	for file in "${@}"
	do
		file_path="$(realpath "${file}")"
		file_name_with_extension=$(basename -- "${file_path}")
		file_names+=("${file_name_with_extension%.*}")

		if [ "$(ffprobe -v quiet -print_format json -show_format -show_streams GHCA0930.MP4 | jq '.streams[0].side_data_list[0].rotation')" = "-180" ]
		then
			original_file_path="${file_path}"
			file_path="${work_dir}/$(python3 -c 'import sys,uuid; sys.stdout.write(uuid.uuid4().hex)').mp4"

			ffmpeg -i "${original_file_path}" -vf "transpose=2,transpose=2" "${file_path}"
		fi

		echo "file '${file_path}'" >> "${manifest}"
	done

	cat "${manifest}"
    # Entirely possible this is too long
    # compound_file_name=$(IFS=- ; echo "${file_names[*]}")

	ffmpeg -f concat -safe 0 -i "${manifest}" -c copy "concat.mp4"
}

concat_simple "${@}"
exit 1

# The paths must be absolute for the videos we combine
for file in "$@"
do
	file_path="$(realpath "${file}")"
	file_name_with_extension=$(basename -- "${file_path}")

	file_path="${work_dir}/${file_name_with_extension}"

	ffmpeg \
		-i "${file}" \
        -vf "scale=${desired_width}:${desired_height}:force_original_aspect_ratio=1,pad=${desired_width}:${desired_height}:(ow-iw)/2:(oh-ih)/2,setsar=1" \
		"${file_path}"

	echo "file '${file_path}'" >> "${work_dir}/manifest.txt"

	file_names+=("${file_name_with_extension%.*}")
done

# Entirely possible this ends up being too long
# compound_file_name=$(IFS=- ; echo "${file_names[*]}")

cat "${work_dir}/manifest.txt"

ffmpeg \
	-y \
	-f concat \
	-safe 0 \
	-i "${work_dir}/manifest.txt" \
	-c:a copy \
	-c:v copy \
	"concat.mp4"

