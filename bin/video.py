#!/usr/bin/env python3

import argparse
import subprocess
import sys
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
        "--remove-audio", help="Remove audio", action="store_true"
    )
    parser.add_argument(
        "--dry-run", help="Print command without executing", action="store_true"
    )
    parser.add_argument(
        "--speed", help="Speed up video by given factor", type=int, default=1
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

    if args.remove_audio:
        command += ["-an"]

    if args.speed > 1:
        command += ["-filter:v", f"setpts=PTS/{args.speed}"]

    if not args.verbose:
        # https://superuser.com/questions/326629/how-can-i-make-ffmpeg-be-quieter-less-verbose
        command += ["-hide_banner", "-loglevel", "error"]

    # Can't do a simple copy if we're applying a filter
    if not args.speed >1:
        command += ["-c", "copy"]
    command += ["-y"]
    command += [args.output]

    if args.verbose or args.dry_run:
        print(" ".join(command))

    if args.dry_run:
        exit(0)

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
