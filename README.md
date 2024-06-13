# Notion Update Checking Script

A simple script that checks for Notion updates based on the current version stored in a text file. If a new version is available, it prompts the user to package the new version. This is a workaround for deploying software more easily with an MDM. 

**Note:** This has not been tested on Windows.

## Features

- Reads the current version of Notion from a `version.txt` file.
- Checks for the latest version of Notion by incrementing the current version number.
- Notifies the user if a new version is available.
- Prompts the user to package the new version using `autopkg`.

## Getting Started

### Prerequisites
- [`autopkg`](https://github.com/autopkg/autopkg) installed for packaging the new version of Notion.
- An `autopkg` recipe for packaging Notion. (Recommended recipe repo is https://github.com/autopkg/swy-recipes)

### Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/codyafingerson/notion-update-checker
    cd notion-update-checker
    ```

2. Ensure you give the bash script permission to execute by running `chmod +x ./check-notion.sh`

### Scheduling as a Process (on a Mac)
1. Update the `ProgramArguments` key in the [plist file](./com.codyfingerson.notionupdates.plist) to point to the correct location where you have cloned this repository.

2. Move the plist file to the appropriate directory: The plist file should be placed in the `~/Library/LaunchAgents` directory for per-user agents.
    - You can execute `mv com.codyfingerson.notionupdates.plist ~/Library/LaunchAgents/` while in the directory where you cloned this repository. 

3. Load the plist file into `launchd` using the `launchctl` command:
    - `launchctl load ~/Library/LaunchAgents/com.codyfingerson.notionupdates.plist`

4. The task should now be scheduled to run at the interval you specified. You can verify that everything worked by running:
    - `launchctl list | grep com.codyfingerson.notionupdates`

**PLIST Quick Tips**
- You can change the time and date that the script executes by modifying the `StartCalendarInterval` key. The hour is first, followed by the minute, and then the day of the week. The default is set to run at 9 AM, Monday through Friday.
    - *0 and 7* represent Sunday
    - *1* represents Monday
    - *2* represents Tuesday
    - and so on...

- If you would like to change the default location for error logs, you can change the `StandardOutPath` key to your desired location. 

## How It Works

1. The script reads the current version from `version.txt`.
2. It checks for the latest version of Notion by incrementing the patch, minor, and major versions sequentially.
3. If a new version is found, it prompts the user to package the new version using `autopkg`.
4. If the user agrees, it writes the new version to `version.txt` and starts the packaging process.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author
Cody Fingerson