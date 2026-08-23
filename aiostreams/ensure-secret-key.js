#!/usr/bin/env node
// Makes sure AIOStreams has a SECRET_KEY, generating one on first start.
//
// Writing to /data/options.json directly would achieve nothing: the Supervisor
// rewrites that file from the stored add-on configuration every time the
// add-on starts. So a generated key is pushed back into the real add-on
// options through the Supervisor API, which is what makes it show up in the
// Configuration tab.
//
// The key is also kept in /data/secret_key. That is the durable copy: it is
// what gets reused if the Supervisor call fails, and it is what lets the
// add-on notice later that the key has changed.
//
// Prints the key on stdout. All logging goes to stderr so it does not end up
// in the captured value.
'use strict';

const fs = require('fs');
const crypto = require('crypto');

const OPTIONS_FILE = '/data/options.json';
const KEY_FILE = '/data/secret_key';
const SUPERVISOR_URL = 'http://supervisor/addons/self/options';
const HEX64 = /^[0-9a-f]{64}$/i;

function log(message) {
    process.stderr.write(`[aiostreams] ${message}\n`);
}

function readOptions() {
    try {
        return JSON.parse(fs.readFileSync(OPTIONS_FILE, 'utf8'));
    } catch {
        return {};
    }
}

function readStoredKey() {
    try {
        const key = fs.readFileSync(KEY_FILE, 'utf8').trim();
        return HEX64.test(key) ? key : null;
    } catch {
        return null;
    }
}

async function saveToOptions(options, key) {
    const token = process.env.SUPERVISOR_TOKEN || process.env.HASSIO_TOKEN;
    if (!token) {
        log('No Supervisor token, cannot save the key to the add-on options.');
        return false;
    }

    // The Supervisor replaces the whole options object, so send the current
    // options back with SECRET_KEY filled in rather than SECRET_KEY alone.
    const response = await fetch(SUPERVISOR_URL, {
        method: 'POST',
        headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ options: { ...options, SECRET_KEY: key } }),
        signal: AbortSignal.timeout(10000),
    });

    if (!response.ok) {
        log(`Supervisor refused the options update (HTTP ${response.status}).`);
        return false;
    }
    return true;
}

async function main() {
    const options = readOptions();
    const configured =
        typeof options.SECRET_KEY === 'string' ? options.SECRET_KEY.trim() : '';
    const stored = readStoredKey();

    if (configured) {
        if (
            stored &&
            HEX64.test(configured) &&
            stored.toLowerCase() !== configured.toLowerCase()
        ) {
            log('WARNING: SECRET_KEY differs from the key generated earlier.');
            log('WARNING: Configurations saved under the old key will not decrypt.');
        }
        process.stdout.write(configured);
        return;
    }

    const key = stored || crypto.randomBytes(32).toString('hex');

    if (stored) {
        log('SECRET_KEY is blank, reusing the key from a previous start.');
    } else {
        log('SECRET_KEY is blank, generating one.');
        fs.writeFileSync(KEY_FILE, `${key}\n`, { mode: 0o600 });
    }

    let saved = false;
    try {
        saved = await saveToOptions(options, key);
    } catch (error) {
        log(`Could not reach the Supervisor: ${error.message}`);
    }

    if (saved) {
        log('Generated key saved to the add-on options, see the Configuration tab.');
    } else {
        log(`Generated key kept in ${KEY_FILE} and reused on every start.`);
        log('Set SECRET_KEY yourself in the Configuration tab to manage it by hand.');
    }

    process.stdout.write(key);
}

main().catch((error) => {
    log(`FATAL: could not establish a SECRET_KEY: ${error.message}`);
    process.exit(1);
});
