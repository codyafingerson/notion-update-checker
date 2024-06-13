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

if [ -z "$newVersion" ]; then
    echo "No new version found"
    exit 0
fi

echo "A new notion version is available: $newVersion"

read -p "Would you like to package it? (y/n): " answer
if [ "$answer" = "y" ]; then
    echo $newVersion > $versionFile
    echo "Packaging process has started."
    autopkg run -v Notion.pkg
    echo "Packaging process has completed."
else
    echo "Notion version $newVersion has not been downloaded."
fi
