#!/usr/bin/env python3

import argparse


# http://trac.ffmpeg.org/wiki/Scaling
def scale():
    return ["-vf", "scale=${2}"]


def rotate():
    return ["-vf", "transpose=${2}"]


# https://ffmpeg.org/ffmpeg.html#Audio-Options
# https://superuser.com/questions/268985/remove-audio-from-video-file-with-ffmpeg
def remove_audio():
    remove = [" -c copy -an"]


def remove_metadata():
    #   	-map_metadata -1 \
    # -c:v copy \
    # -c:a copy \
    # -y \
    # -fflags +bitexact \
    # -flags:v +bitexact \
    # -flags:a +bitexact \
    pass


# https://www.youtube.com/watch?v=Q1SE5i7YzCg
def youtube_upres():
    # scale=2560:1440 -b:v 30M -b:a 192k -preset slow -crf 18
    pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="video",
        description="ffmpeg wrapper for video processing",
        epilog="Loosely maintained",
    )

    parser.add_argument(
        "-i", "--input", help="Path to input file", type=str, required=True
    )
    parser.add_argument("-v", "--verbose", action="store_true")

    args = parser.parse_args()
