#!/usr/bin/env -S npx zx

const ROOT = '';

const files = await glob([`${ROOT}*.*`]);

const ALLOWED_EXTENSIONS = ['heic', 'jpg', 'jpeg', 'mov', 'mp4'];

for (const file of files) {
    const extension = path.extname(file).slice(1).toLowerCase();

    if (!ALLOWED_EXTENSIONS.includes(extension)) {
        continue;
    }

    console.log(file);

    const newBasenameCommandResult = await $({ nothrow: true })`exif-get-timestamp.mjs -f ${file}`;
    // Maybe no EXIF dates, or some other issue exists. Skip it.
    if (newBasenameCommandResult.exitCode !== 0) {
        continue;
    }

    const sum = String(await $`md5sum ${file}`).slice(0, 8);
    const destination = `${String(newBasenameCommandResult).trim()} (${sum}).${extension}`;

    if (path.basename(file) !== path.basename(destination)) {
        if (fs.existsSync(destination)) {
            console.error(`oh no! ${destination} exists. A duplicate!`);
            process.exit(1);
        }

        // Google-Photos Takeout JSON files.
        if (!fs.existsSync(destination)/* && fs.existsSync(`${file}.json`)*/) {
            console.log('\t-> ' + destination);

            fs.renameSync(file, destination);
            // fs.renameSync(`${file}.json`, `${destination}.json`);
        }
    }
}
