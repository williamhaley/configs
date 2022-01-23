#!/usr/bin/env python3

from os import listdir, rename, path
from re import compile
import sys

"""
rename.py "My File X([0-9]+) - (.*).txt" "My File - x{} - {}.txt"
"""

match = sys.argv[1]
out = sys.argv[2]

prog = compile(match)

for f in listdir('.'):
  match = prog.match(f)
  if not match:
    continue

  source = path.join('.', match[0])

  print(f"change: '{source}' => '{out.format(*match.groups())}'")
  # Comment this line for a dry-run
  rename(f"{source}", out.format(*match.groups()))
