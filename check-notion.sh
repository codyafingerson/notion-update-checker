#!/bin/bash

notionBaseUrl="https://desktop-release.notion-static.com/Notion-"
versionFile="version.txt"

# Read the current version from the file
currentVersion=$(cat $versionFile)

# Function to check if a version exists on the Notion website
checkVersion() {
    version=$1
    statusCode=$(curl -o /dev/null -s -w "%{http_code}" $notionBaseUrl$version-universal.dmg)
    if [ $statusCode -eq 200 ]; then
        echo $version
    else
        echo ""
    fi
}

# Try incrementing the patch version
IFS='.' read -ra version <<< "$currentVersion"
version[2]=$((version[2]+1))
newVersion=$(checkVersion "${version[0]}.${version[1]}.${version[2]}")

if [ -z "$newVersion" ]; then
    # Revert patch increment and try incrementing minor version
    version[2]=$((version[2]-1))
    version[1]=$((version[1]+1))
    newVersion=$(checkVersion "${version[0]}.${version[1]}.${version[2]}")
fi

if [ -z "$newVersion" ]; then
    # Revert minor increment and try incrementing major version
    version[1]=$((version[1]-1))
    version[0]=$((version[0]+1))
    newVersion=$(checkVersion "${version[0]}.${version[1]}.${version[2]}")
fi

# Check if newVersion is empty
if [ -z "$newVersion" ]; then
    echo "No new version found"
    # osascript -e 'display alert "No new version" message "No new version of Notion was found."'
    exit 0
fi

# Ask the user if they want to package it
userResponse=$(osascript -e 'display dialog "A new Notion version is available: '"$newVersion"'. Would you like to download it and package it?" buttons {"Yes", "No"} default button "No"')

# Check the user's response
if [[ "$userResponse" == *"button returned:Yes"* ]]; then
    echo "$newVersion" > "$versionFile"
    echo "Packaging process has started."
    
    autopkg run -v Notion.pkg

    cacheDir=$(autopkg info | grep "'CACHE_DIR'" | awk -F"'" '{print $4}')

    osascript -e 'display alert "Packaging status" message "Packaging process has completed. You can find the packaged file here: '"$cacheDir"'"'
else
    osascript -e 'display alert "Notion" message "The new version of Notion was NOT downloaded or packaged."'
fi
