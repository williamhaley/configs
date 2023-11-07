#!/usr/bin/env python3

import argparse
import subprocess
import sys

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
	parser.add_argument("--verbose", help="Verbose output", action="store_true")

	args = parser.parse_args()
	command = ["ffmpeg", "-i", args.input]

	if args.remove_metadata:
		command += ["-map_metadata", "-1", "-fflags", "+bitexact", "-flags:v", "+bitexact", "-flags:a", "+bitexact"]

	# https://trac.ffmpeg.org/wiki/Map#Chooseallstreams
	if args.remux:
		command += ["-map", "0"]

	# For now the only options do a copy and we're forcing an overwrite
	command += ["-c", "copy"]

	if not args.verbose:
		# https://superuser.com/questions/326629/how-can-i-make-ffmpeg-be-quieter-less-verbose
		command += ['-hide_banner', '-loglevel', 'error']

	command += ["-y"]
	command += [args.output]

	if args.verbose:
		print(' '.join(command))

	proc = subprocess.Popen(command, shell=False, stderr=subprocess.PIPE)
	for line in proc.stderr:
			print(line.decode('utf8'), end=''),
	proc.stderr.close()
	proc.wait()
