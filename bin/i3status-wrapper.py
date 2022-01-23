#!/usr/bin/env python3

import json
import subprocess
import sys

def print_line(message):
	""" Non-buffered printing to stdout. """
	sys.stdout.write(message + '\n')
	sys.stdout.flush()

def read_line():
	""" Interrupted respecting reader for stdin. """
	# try reading a line, removing any extra whitespace
	try:
		line = sys.stdin.readline().strip()
		# i3status sends EOF, or an empty line
		if not line:
			sys.exit(3)
		return line
	# exit on ctrl-c
	except KeyboardInterrupt:
		sys.exit()

def forecast():
	return subprocess.run("weather.sh", check=True, capture_output=True).stdout.decode('utf-8').rstrip('\n')

if __name__ == '__main__':
	# Skip the first line which contains the version header.
	print_line(read_line())

	# The second line contains the start of the infinite array.
	print_line(read_line())

	while True:
		line, prefix = read_line(), ''

		# ignore comma at start of lines
		if line.startswith(','):
			line, prefix = line[1:], ','

		list_of_data = json.loads(line)

		try:
			list_of_data.insert(0, {'full_text' : forecast(), 'name' : 'weather'})
		except:
			pass

		# and echo back new encoded json
		print_line(prefix + json.dumps(list_of_data))
