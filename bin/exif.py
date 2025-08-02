#!/usr/bin/env python

import subprocess
import argparse
import hashlib
import pathlib
import datetime
import json
import re
import os


def get_coordinates(image_path):
    def format(coordinate_and_ref):
        (coordinate, ref) = coordinate_and_ref.split(" ")

        direction = {"N": 1, "E": 1, "S": -1, "W": -1}
        if ref.upper() not in direction:
            raise RuntimeError(f"invalid ref {ref}")
        return str(round(float(coordinate) * direction[ref.upper()], 5))

    # three -short on purpose to get just the value without a label
    out = subprocess.check_output(
        [
            "exiftool",
            "-short",
            "-short",
            "-short",
            "-c",
            "%.6f",
            "-gpslatitude",
            "-gpslongitude",
            image_path,
        ]
    ).decode("utf-8")
    print(", ".join([format(x) for x in out.strip().split("\n")]))


def get_image_metadata(image_path):
    parsed_dates = []
    parsed_offsets = []

    def add_offset(tzinfo):
        if tzinfo == None:
            return
        parsed_offsets.append(tzinfo)
        if tzinfo != parsed_offsets[0]:
            raise Exception(
                f"inconsistent timezone data for '{parsed}' and '{parsed_offsets[0]}"
            )

    id = hashlib.md5(open(image_path, "rb").read()).hexdigest()[0:8]
    extension = pathlib.Path(image_path).suffix

    out = subprocess.check_output(
        [
            "exiftool",
            "-json",
            "-groupNames",
            "-ignoreMinorErrors",
            "-DateTimeOriginal",
            "-CreationDate",
            "-CreateDate",
            "-MediaCreateDate",
            "-TrackCreateDate",
            "-OffsetTimeOriginal",
            image_path,
        ]
    ).decode("utf-8")
    exif_from_image = json.loads(out)
    if len(exif_from_image) > 1:
        raise "multiple EXIF responses returned"
    exif_from_image = exif_from_image[0]

    for key in [
        "EXIF:DateTimeOriginal",
        "QuickTime:CreateDate",
        "QuickTime:CreationDate",
        "QuickTime:MediaCreateDate",
        "QuickTime:TrackCreateDate",
    ]:
        if key in exif_from_image:
            for format in [
                "%Y:%m:%d %H:%M:%S",
                "%Y:%m:%d %H:%M:%S%z",
            ]:
                try:
                    parsed = datetime.datetime.strptime(exif_from_image[key], format)
                except ValueError:
                    continue
                add_offset(parsed.tzinfo)
                parsed_dates.append(
                    {
                        "isMaybeLocalized": parsed.tzinfo != None,
                        "parsed": parsed,
                        "original": exif_from_image[key],
                    }
                )

                date1 = (
                    parsed.replace(tzinfo=datetime.timezone.utc)
                    if parsed.tzinfo == None
                    else parsed.astimezone(datetime.timezone.utc)
                )
                date2 = (
                    parsed_dates[0]["parsed"].replace(tzinfo=datetime.timezone.utc)
                    if parsed_dates[0]["parsed"].tzinfo == None
                    else parsed_dates[0]["parsed"].astimezone(datetime.timezone.utc)
                )

                # abs() seems to work fine on the computed time delta.
                date_difference = abs(date1 - date2)
                # Make sure the dates are close enough. Any major outliers should give us pause.
                if date_difference.total_seconds() > 5:
                    raise Exception(
                        f"inconsistent timestamps for '{image_path}' when comparing '{parsed}' against {parsed_dates[0]["parsed"]}"
                    )

    for key in ["EXIF:OffsetTimeOriginal"]:
        if key in exif_from_image:
            for format in ["%z"]:
                parsed = datetime.datetime.strptime(exif_from_image[key], format).tzinfo
                add_offset(parsed)

    best_date = None
    for date in parsed_dates:
        if (
            date["isMaybeLocalized"]
            or not best_date
            or len(date["original"]) > len(best_date["original"])
        ):
            best_date = date

    if not best_date:
        return (None, None, None)

    best_date = best_date["parsed"]

    if best_date.tzinfo == None and len(parsed_offsets) > 0:
        best_date = best_date.replace(tzinfo=parsed_offsets[0])

    return best_date, id, extension


def format_date(date):
    format = "%Y.%m.%d %H.%M.%S" if date.tzinfo == None else "%Y.%m.%d %H.%M.%S %z"

    return date.strftime(format)


def format_filename(date, id, extension):
    formatted_date = format_date(date)
    return f"{formatted_date} ({id}.h1){extension}"


def validate_filename(image_path, allow_manual_timezone):
    original_filename = pathlib.Path(image_path).name
    (best_date, id, extension) = get_image_metadata(image_path)

    # If there's no EXIF date assume this was some context-less screenshot or similarly captured image and we can't validate it.
    # Could be an image downloaded from a text message or something else where EXIF was stripped out.
    if best_date == None:
        print(f"cannot validate '{image_path}'. no meaningful EXIF data")
        return

    if allow_manual_timezone:
        image_path_date_string = re.match(r"(.*) \(.*\)\..*", original_filename)[1]

        for format in ["%Y.%m.%d %H.%M.%S %z", "%Y.%m.%d %H.%M.%S"]:
            try:
                image_path_date = datetime.datetime.strptime(
                    image_path_date_string, format
                )
            except ValueError:
                continue

            # TODO Maybe put this behind an arg flag like --allow-weird-gopro-screenshot-capture-exif
            # TODO I don't understand this. I have at least one file that's a GoPro screenshot captured from a video. There's no TZ info in the screenshot, just a datetime. Despite there being no TZ info, the date seems to (coincidentally?) be the exact offset increment behind UTC for my home TZ. It's as if it took the TZ into account, but acted as if the datetime was UTC (even though it was my TZ) and applied the offset.
            if True:
                with_utc_fix = best_date.astimezone(datetime.timezone.utc)
                with_utc_fix = with_utc_fix.replace(tzinfo=image_path_date.tzinfo)
                if format_filename(with_utc_fix, id, extension) == original_filename:
                    print(
                        f"'{image_path}' has weird EXIF data. GoPro mangling TZ info?"
                    )
                    return

    formatted_filename = format_filename(best_date, id, extension)

    if formatted_filename != original_filename:
        raise Exception(
            f"current filename '{original_filename}' does not match desired filename '{formatted_filename}'"
        )


def rename(image_path):
    (best_date, id, extension) = get_image_metadata(image_path)

    # If there's no EXIF date assume this was some context-less screenshot or similarly captured image and we can't validate it.
    # Could be an image downloaded from a text message or something else where EXIF was stripped out.
    if best_date == None:
        print(f"cannot rename '{image_path}'. no meaningful EXIF data")
        return

    formatted_filename = format_filename(best_date, id, extension)

    new_filename = pathlib.Path(image_path).parent.joinpath(formatted_filename)

    os.rename(image_path, new_filename)


def gnome_maps(image_path):
    out = subprocess.check_output(
        [
            "exiftool",
            "-j",
            "-c",
            "%.6f",
            "-GPSPosition",
            "-GPSLatitude",
            "-GPSLongitude",
            image_path,
        ]
    ).decode("utf-8")

    (lat, lat_direction) = json.loads(out)[0]["GPSLatitude"].split(" ")
    (lng, lng_direction) = json.loads(out)[0]["GPSLongitude"].split(" ")

    lat = lat if lat_direction == "N" else f"-{lat}"
    lng = lng if lng_direction == "E" else f"-{lng}"

    subprocess.Popen(["gnome-maps", f"geo:{lat},{lng};crs=wgs84;u=0"])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="exif.py",
        description="EXIF tasks",
    )
    subparsers = parser.add_subparsers(
        title="commands",
        description="valid commands",
        required=True,
        dest="command_name",
    )

    get_coordinates_parser = subparsers.add_parser("get-coordinates")
    get_coordinates_parser.add_argument("--filename", required=True)

    validate_filename_parser = subparsers.add_parser("validate")
    validate_filename_parser.add_argument("--filename", required=True)
    validate_filename_parser.add_argument(
        "--allow-manual-timezone",
        action="store_true",
        help="Sometimes a screenshot or other image has no TZ info and a TZ may have been added manually to the filename. If the EXIF lacks any TZ info, but the filename has some, allow it",
    )

    gnome_maps_parser = subparsers.add_parser("gnome-maps")
    gnome_maps_parser.add_argument("--filename", required=True)

    rename_parser = subparsers.add_parser("rename")
    rename_parser.add_argument("--filename", required=True)

    args = parser.parse_args()

    if args.command_name == "get-coordinates":
        get_coordinates(args.filename)
    if args.command_name == "validate":
        validate_filename(args.filename, args.allow_manual_timezone)
    elif args.command_name == "rename":
        rename(args.filename)
    elif args.command_name == "gnome-maps":
        gnome_maps(args.filename)
