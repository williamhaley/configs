#!/usr/bin/env python3

import argparse
import sys
from datetime import datetime, timedelta
import os
import subprocess
from tempfile import NamedTemporaryFile
from pathlib import Path
import shutil

def trim(from_start, from_end, src_file):
	total = float(subprocess.check_output(['ffprobe', '-v', '0', '-show_entries', 'format=duration', '-of', 'compact=p=0:nk=1', src_file]))
	print(f'Total duration of video clip: {total} seconds')
	with NamedTemporaryFile() as tmp_file:
		filename, file_extension = os.path.splitext(src_file)
		tmp_file_name = Path(tmp_file.name).with_suffix(file_extension)
		print(f'using tmp_file {tmp_file_name}')

		head = ['ffmpeg', '-y', '-i', src_file]
		body = []
		# Using -vcodec copy is fast, but depending on the encoding, could result in missing frames in our copy of the
		# video stream, and so blacked out video which is undesirable. This is slower, as we are re-encoding, but better.
		tail = ['-acodec', 'copy', tmp_file_name]

		if from_start:
			print(f'Trim {from_start} seconds from beginning')
			body.extend(['-ss', str(from_start)])
		if from_end:
			print(f'Trim {from_end} seconds from end')
			trim_end = total - from_end
			if from_start != None:
				# If we are also trimming from the start, offset what we cut from the end.
				trim_end -= from_start
			body.extend(['-t', str(trim_end)])

		command = []
		command.extend(head)
		command.extend(body)
		command.extend(tail)

		subprocess.call(command)
		shutil.move(tmp_file_name, src_file)

def time_to_seconds(time_str):
	try:
		date = datetime.strptime(time_str, '%H:%M:%S')
		delta = timedelta(hours=date.hour, minutes=date.minute, seconds=date.second).total_seconds()
		return delta
	except ValueError:
		pass

	try:
		date = datetime.strptime(time_str, '%M:%S')
		delta = timedelta(hours=0, minutes=date.minute, seconds=date.second).total_seconds()
		return delta
	except ValueError:
		pass

	if str.isdigit(time_str):
		return int(time_str)

	print('invalid format for time to trim')
	sys.exit(1)

def load_opts():
	parser = argparse.ArgumentParser(description='Trim video files')
	parser.add_argument('--start', dest='start', type=str, help='duration to trim from the start as HH:MM:SS')
	parser.add_argument('--end', dest='end', type=str, help='duration to trim from the end as HH:MM:SS')
	parser.add_argument('--file', dest='path', required=True, help='path to video file')

	args = parser.parse_args()

	start=None
	end=None

	if args.start:
		start = time_to_seconds(args.start)
	if args.end:
		end = time_to_seconds(args.end)
	if start == None and end == None:
		print('must pass either --start or --end')
		sys.exit(1)

	if not os.path.isfile(args.path):
		print('file does not exist')
		sys.exit(1)

	return start, end, args.path

if __name__ == '__main__':
	start, end, path = load_opts()
	trim(start, end, path)
