#!/usr/bin/env python3

from pathlib import Path
from selectors import DefaultSelector, EVENT_READ
import argparse
import subprocess
import sys

# await $`ffmpeg -y -safe 0 -f concat -i ${inputsTemporaryFile} -c copy output.mp4`
# await $`ffmpeg -y -safe 0 ${inputParameters} -filter_complex ${filter} -map "[v]" -map "[a]" output.mp4`

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog="video-concat",
        description="ffmpeg wrapper for video concatenation",
        epilog="Loosely maintained",
    )

    parser.add_argument(
        "-i", "--input", help="Path to input file", nargs="+", default=[], required=True
    )

    args = parser.parse_args()

    command = ['ffmpeg', '-y']
    paths = [str(Path(x).absolute()) for x in args.input]
    for path in paths:
        command += ['-i', path]

    filter_inputs = ''.join(map(lambda x: f"[{x}:v]", range(len(paths))))
    n = len(paths)

    command += ["-filter_complex", f"{filter_inputs}concat=n={n}:v=1[outv]"]
    command += ["-map", "[outv]"]
    command += ["output.mp4"]

    print(command)

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

