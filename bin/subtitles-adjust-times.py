#!/usr/bin/env python3

import os
import sys
from datetime import datetime, timedelta

def adjust(file_path, adjustment):
    with open(file_path, 'r') as f:
        for line in f:
            if ' --> ' in line:
                pieces = line.strip().split(' --> ')
                adjusted = [datetime.strptime(x, "%H:%M:%S,%f") + timedelta(seconds=adjustment) for x in pieces]
                formatted = [x.strftime("%H:%M:%S,%f")[:-3] for x in adjusted]
                print(' --> '.join(formatted))
            else:
                print(line, end='')

if __name__ == '__main__':
    file = sys.argv[1]
    adjustment = sys.argv[2]

    if not os.path.isfile(sys.argv[1]):
        print(f'"{sys.argv[1]}" is not a valid file')
        sys.exit(1)

    try:
        float(sys.argv[2])
    except:
        print(f'"{sys.argv[2]}" is not a valid number')
        sys.exit(1)

    adjust(sys.argv[1], float(sys.argv[2]))

