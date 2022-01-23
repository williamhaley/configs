#!/usr/bin/env bash

file=""

while getopts "r:f:" opt;
do
  case ${opt} in
    r)
      rotation=$OPTARG
      ;;
    f)
      file=$OPTARG
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z "$file" ];
then
    echo "must specify file with -f"
    exit 1
fi

vf=""
if [ "${rotation}" = "90" ];
then
    vf="transpose=1"
elif [ "${rotation}" = "180" ];
then
    vf="transpose=2,transpose=2"
elif [ "${rotation}" = "270" ];
then
    vf="transpose=2"
fi

set -x
ffmpeg -i "${file}" -vf "${vf}" "${file}"

