#!/usr/bin/env -S npx zx

// Look for the date in one of these fields, in this order.
const DATE_FIELD_PRIORITIES = ['DateTimeOriginal', 'QuickTime:CreationDate', 'CreationDate', 'CreateDate', 'MediaCreateDate', 'TrackCreateDate'];

async function getTimestamp(path) {
    const dateTime = String(await $`exiftool -j -ignoreMinorErrors -dateFormat '%Y-%m-%d %T' -DateTimeOriginal -QuickTime:CreationDate -CreationDate -CreateDate -MediaCreateDate -TrackCreateDate ${path}`).trim();

    const jsonResults = JSON.parse(dateTime);
    if (jsonResults.length !== 1) {
        process.exit(1);
    }
    const result = jsonResults[0];

    const dates = DATE_FIELD_PRIORITIES.reduce((memo, dateField) => {
        if (result[dateField]) {
            return [...memo, result[dateField]];
        }

        return memo;
    }, []);

    // No date found in a field we wanted.
    if (dates.length === 0) {
        console.error(`"${path}" no dates found`);
        process.exit(1);
    }

    // The dates don't all match.
    if (dates.every(date => date !== dates[0])) {
        console.error(`"${path}" inconsistent dates`);
        process.exit(1);
    }

    if (isNaN(new Date(dates[0]))) {
        console.error(`"${path}" invalid date`);
        process.exit(1);
    }

    return dates[0];
}

async function getTimezone(path) {
    const offset = JSON.parse(await $`exiftool -json -m -OffsetTimeOriginal ${path}`)[0]?.['OffsetTimeOriginal'];
    let offsetFromDateTime = null;

    const dateTime = JSON.parse(await $`exiftool -json -m -CreationDate ${path}`)[0]?.['CreationDate'];
    if (dateTime) {
        offsetFromDateTime = dateTime.slice(-6);
    }

    if (offset && offsetFromDateTime && offset !== offsetFromDateTime) {
        console.error(`"${path}" inconsistent timezone data`);
        process.exit(1);
    }

    if (offset || offsetFromDateTime) {
        return offset || offsetFromDateTime;
    }

    // console.error(`"${path}" no timezone offset`);
    // process.exit(1);
}

const timestamp = await getTimestamp(argv.f);
const offset = await getTimezone(argv.f);

if (offset) {
    console.log(`${timestamp} ${offset}`);
} else {
    console.log(timestamp);
}

