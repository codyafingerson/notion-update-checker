import https from 'https';
import fs from 'fs';
import readline from 'readline';
import { spawn } from 'child_process';
import notifier from 'native-notifier';

const input = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

// After '-' is the version number (Major.Minor.Patch)
let notionBaseUrl = 'https://desktop-release.notion-static.com/Notion-';

/**
 * Reads the latest version number from a file named 'version.txt'.
 *
 * @returns {Promise<string>} A promise that resolves with the latest version number as a string,
 *                            or rejects if an error occurs during the read operation.
 */
async function latestVersionFromTextFile() {
    // Open the file and read the latest version number
    return new Promise((resolve, reject) => {
        fs.readFile('version.txt', 'utf8', (err, data) => {
            if (err) {
                reject(err);
            }

            resolve(data);
        });
    });
}

/**
 * Writes the latest version number to a file named 'version.txt'.
 *
 * @param {string} version - The version number to be written to the file.
 * @returns {Promise<void>} A promise that resolves when the file has been written successfully,
 *                          or rejects if an error occurs during the write operation.
 */
async function writeLatestVersionToFile(version) {
    return new Promise((resolve, reject) => {
        fs.writeFile('version.txt', version, (err) => {
            if (err) {
                reject(err);
            }

            resolve();
        });
    });
}

const currentVersion = await latestVersionFromTextFile();

/**
 * Checks for the latest version of Notion by incrementing the current version number.
 * It tries to increment the patch, minor, and major versions sequentially and checks if the new version exists.
 *
 * @returns {Promise<string>} A promise that resolves with the latest version number as a string,
 *                            or rejects if no new version is found.
 * @throws {Error} Throws an error if no new version is found.
 */
async function latestVersionFromNotion() {
    let version = currentVersion.split('.').map(Number);

    // Check if the new version exists on Notion website
    const checkVersion = (version) => {
        return new Promise((resolve, reject) => {
            https.get(notionBaseUrl + version.join('.') + '-universal.dmg', (res) => {
                if (res.statusCode === 200) {
                    resolve(version.join('.'));
                } else {
                    reject(res.statusCode);
                }
            }).on('error', (err) => {
                reject(err);
            });
        });
    };

    // Try incrementing patch version
    version[2]++;
    try {
        return await checkVersion(version);
    } catch (err) {
        version[2]--; // Revert patch increment
    }

    // Try incrementing minor version
    version[1]++;
    try {
        return await checkVersion(version);
    } catch (err) {
        version[1]--; // Revert minor increment
    }

    // Try incrementing major version
    version[0]++;
    try {
        return await checkVersion(version);
    } catch (err) {
        version[0]--; // Revert major increment
    }

    throw new Error('No new version found');
}

/**
 * Handles the process of packaging a new Notion version if available.
 *
 * @param {string} version - The new version number of Notion that is available.
 */
await latestVersionFromNotion().then((version) => {
    console.log("A new notion version is available: " + version);

    // notifier({
    //     title: 'Notion',
    //     message: `Notion version ${version} is available. Would you like to download it?`,
    // });

    input.question("Would you like to package it? (y/n): ", (answer) => {
        if (answer.toLowerCase() === 'y') {
            writeLatestVersionToFile(version);

            const proc = spawn('autopkg', ['run', '-v', 'Notion.pkg']);

            console.log(`Packaging process has started with PID ${proc.pid}.`);

            proc.stdout.on('data', (data) => {
                console.log(`${data}`);
            });

            proc.stderr.on('data', (data) => {
                console.error(`${data}`);
            });

            proc.on('close', (code) => {
                console.log(`Packaging process has completed with code ${code}.`);
                process.exit(code);
            });

        } else {
            console.log("Notion version " + version + " has not been downloaded.");
            process.exit(0);
        }
    });
}).catch(() => {
    console.log("No new notion version is available.");
    process.exit(0);
});