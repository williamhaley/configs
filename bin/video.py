#!/usr/bin/env python3

import argparse
import subprocess

if __name__ == "__main__":
	parser = argparse.ArgumentParser(
		prog="video",
		description="ffmpeg wrapper for video processing",
		epilog="Loosely maintained",
	)

	parser.add_argument(
		"-i", "--input", help="Path to input file", type=str, required=True
	)
	parser.add_argument(
		"--remove-metadata", help="Remove metadata", action="store_true"
	)
	parser.add_argument(
		"--remux", help="Remux to another format by only copying a stream and not re-encoding", action="store_true"
	)
	parser.add_argument(
		"--output", help="Path to output file", type=str, required=True
	)

	args = parser.parse_args()
	command = ["ffmpeg", "-i", args.input]

	if args.remove_metadata:
		command += ["-map_metadata", "-1", "-fflags", "+bitexact", "-flags:v", "+bitexact", "-flags:a", "+bitexact"]

	# https://trac.ffmpeg.org/wiki/Map#Chooseallstreams
	if args.remux:
		command += ["-map", "0"]

	# For now the only options do a copy and we're forcing an overwrite
	command += ["-c", "copy"]
	command += ["-y"]
	command += [args.output]

	# print(" ".join(command))
	result = subprocess.run(command, stderr=subprocess.PIPE)
	print(result.stderr.decode("utf-8"))

