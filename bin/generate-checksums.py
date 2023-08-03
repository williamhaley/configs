#!/usr/bin/env python3

import hashlib
import os
import subprocess
import sys

if len(sys.argv) < 2:
    print("only argument should be a comma-separated string of extensions")
    sys.exit(1)

extensions = [f".{x.lower()}" for x in sys.argv[1].split(',')]

for root, dirs, files in os.walk("."):
    for file in files:
        _, file_extension = os.path.splitext(file)
        if file_extension.lower() in extensions:
            checksum_file_path = os.path.join(root, f"{file}.md5sum")
            file_path = os.path.join(root, file)
            if not os.path.isfile(checksum_file_path):
                with open(checksum_file_path, "wb") as checksum_file:
                    result = subprocess.run(["md5sum", file_path], stdout=checksum_file, stderr=subprocess.PIPE)
                    if result.returncode != 0:
                        print(file_path, result.stderr)
                        sys.exit(1)
                    else:
                        print(file_path)
