#!/usr/bin/env -S npx zx

const { i: inputs } = argv;

const formattedInputs = inputs.map(input => `file '${fs.realpathSync(input)}'`).join('\n');

const inputsTemporaryFile = tmpfile('inputs.txt', formattedInputs)

// `-safe 0` is to handle unorthodox file names - https://stackoverflow.com/questions/38996925/ffmpeg-concat-unsafe-file-name
await $`ffmpeg -safe 0 -f concat -i ${inputsTemporaryFile} -c copy output.mp4`
