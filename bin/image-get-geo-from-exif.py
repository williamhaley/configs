#!/usr/bin/env python3

import re
import subprocess
import sys

def format(coordinate_and_ref):
  (coordinate, ref) = coordinate_and_ref.split(' ')

  direction = {
    'N': 1,
    'E': 1,
    'S': -1,
    'W': -1
  }
  if ref.upper() not in direction:
    raise RuntimeError(f'invalid ref {ref}')
  return str(round(float(coordinate) * direction[ref.upper()], 5))

def main(image_path):
  # three -short on purpose to get just the value without a label
  out = subprocess.check_output(['exiftool', '-short', '-short', '-short', '-c', '%.6f', '-gpslatitude', '-gpslongitude', image_path]).decode('utf-8')
  print(', '.join([format(x) for x in out.strip().split('\n')]))

if __name__ == '__main__':
  main(sys.argv[1])
