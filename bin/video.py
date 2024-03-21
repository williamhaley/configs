#!/usr/bin/env python3

import argparse
import subprocess
import sys
from os import mkfifo
from tempfile import mktemp
from pathlib import Path
from selectors import DefaultSelector, EVENT_READ

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="video",
        description="ffmpeg wrapper for video processing",
        epilog="Loosely maintained",
    )

    parser.add_argument(
        "-i", "--input", help="Path to input file", nargs="+", default=[], required=True
    )
    parser.add_argument(
        "--remove-metadata", help="Remove metadata", action="store_true"
    )
    parser.add_argument(
        "--remux",
        help="Remux to another format by only copying a stream and not re-encoding",
        action="store_true",
    )
    parser.add_argument("--output", help="Path to output file", type=str, required=True)
    parser.add_argument("--verbose", help="Verbose output", action="store_true")

    args = parser.parse_args()
    command = ["ffmpeg"]

    # Concat demuxer https://trac.ffmpeg.org/wiki/Concatenate#demuxer
    # The protocol input https://trac.ffmpeg.org/wiki/Concatenate#protocol is a bit simpler.
    # It seems like we may want to always concat _before_ trimming any video.
    is_concat = False
    if len(args.input) > 1:
        # Seems to address an issue when concatenating some GoPro videos. The first video is fine, but the second video is mostly gray with some artifacts and static. Weird though. Both videos were recorded at the same time. Two separate files, same fps, same resolution, and both were clipped via the GoPro app. Not sure what the issue was that this addresses.
        # https://video.stackexchange.com/a/32430
        # https://superuser.com/a/981931/770509
        # https://trac.ffmpeg.org/ticket/4498
        fifos = [f"{mktemp()}.ts" for _ in range(len(args.input))]
        for i, input in enumerate(args.input):
            mkfifo(fifos[i])
            subprocess.Popen([
                "ffmpeg",
                "-y",
                "-i",
                f"{input}",
                "-c",
                "copy",
                "-bsf:v",
                # This is specifically for hevc/h265 https://www.jeffgeerling.com/blog/2021/how-join-multiple-mp4-files-gopro-ffmpeg
                "hevc_mp4toannexb",
                "-f",
                "mpegts",
                fifos[i],
            ], shell=False)

        fifo_names = "|".join(fifos)

        command += ["-i", f"concat:{fifo_names}"]
        command += ["-bsf:a", "aac_adtstoasc"]
    else:
        command += ["-i", args.input[0]]

    if args.remove_metadata:
        command += [
            "-map_metadata",
            "-1",
            "-fflags",
            "+bitexact",
            "-flags:v",
            "+bitexact",
            "-flags:a",
            "+bitexact",
        ]

    # https://trac.ffmpeg.org/wiki/Map#Chooseallstreams
    if args.remux:
        command += ["-map", "0"]

    if not args.verbose:
        # https://superuser.com/questions/326629/how-can-i-make-ffmpeg-be-quieter-less-verbose
        command += ["-hide_banner", "-loglevel", "error"]

    command += ["-c", "copy"]
    command += ["-y"]
    command += [args.output]

    if args.verbose:
        print(" ".join(command))

    proc = subprocess.Popen(
        command, shell=False, stderr=subprocess.PIPE, stdout=subprocess.PIPE
    )

    sel = DefaultSelector()
    sel.register(proc.stdout, EVENT_READ)
    sel.register(proc.stderr, EVENT_READ)

    while True:
        for key, _ in sel.select():
            data = key.fileobj.read1().decode()
            if not data:
                exit()
            if key.fileobj is proc.stdout:
                print(data, end="")
            else:
                print(data, end="", file=sys.stderr)
