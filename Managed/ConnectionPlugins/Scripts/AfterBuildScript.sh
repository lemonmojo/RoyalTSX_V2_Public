#!/bin/bash

# Working Directory must be Project Directory
# var 1: Debug or Release
# var 2: Project Name

TARGET_FILE_NAME="${2}"
PROJECT_DIR=$(pwd)
INPUT_INFO_DIR="PluginInfo"
PLUGIN_ID=$(grep '<ID' ${INPUT_INFO_DIR}/PluginInfo.xml | cut -f2 -d">"|cut -f1 -d"<")
OUTPUT_DIR="bin/${1}/${2}.app"
OUTPUT_DIR_PLUGIN="bin/${1}/${PLUGIN_ID}.plugin"
INPUT_FRAMEWORK_DIR="Frameworks/"
OUTPUT_INFO_DIR="${OUTPUT_DIR}/PluginInfo"
OUTPUT_MACOS_DIR="${OUTPUT_DIR}/Contents/MacOS"
OUTPUT_RESOURCES_DIR="${OUTPUT_DIR}/Contents/Resources"
OUTPUT_FRAMEWORK_DIR="${OUTPUT_DIR}/Contents/Frameworks"
ROYALTSX_PLUGINS_DIR="$HOME/Library/Application Support/Royal TSX/Plugins/Installed"

# delete the PluginInfo directory
rm -rf "$OUTPUT_INFO_DIR"

#copy the PluginInfo directory to the output directory
#cp -R "$INPUT_INFO_DIR" "$OUTPUT_INFO_DIR"
rsync -r --exclude=.svn "$INPUT_INFO_DIR"/ "$OUTPUT_INFO_DIR"

# check if the frameworks directory exists in bundle
if [ -d "$OUTPUT_FRAMEWORK_DIR" ]
then
	# delete the plugins directory if it exists
	rm -rf "${OUTPUT_FRAMEWORK_DIR}"
fi

# create the frameworks directory
mkdir "$OUTPUT_FRAMEWORK_DIR"

# copy the frameworks dir contents
cp -fR "$INPUT_FRAMEWORK_DIR" "$OUTPUT_FRAMEWORK_DIR"

# delete the MacOS dir
rm -rf "${OUTPUT_MACOS_DIR}"

# move back to project dir
cd "${PROJECT_DIR}"

# clean up resources dir
cd "${OUTPUT_RESOURCES_DIR}"

# when not debugging remove debug info files
if [ "${1}" != "Debug" ]
then
	rm -f *.mdb
fi

cd "${PROJECT_DIR}"

# temporary rename target file
mv "${OUTPUT_RESOURCES_DIR}/${TARGET_FILE_NAME}.dll" "${OUTPUT_RESOURCES_DIR}/${TARGET_FILE_NAME}.dlltemp"

cd "${OUTPUT_RESOURCES_DIR}"

# remove all external dependencies
rm -f *.config
rm -f *.dll

# rename target file back to it original name
mv "${TARGET_FILE_NAME}.dlltemp" "${TARGET_FILE_NAME}.dll"

cd "${PROJECT_DIR}"

# remove the .plugin bundle
rm -rf "$OUTPUT_DIR_PLUGIN"

# rename the .app bundle to .plugin
mv "$OUTPUT_DIR" "$OUTPUT_DIR_PLUGIN"

rm -rf "${ROYALTSX_PLUGINS_DIR}/${PLUGIN_ID}.plugin"
cp -fR "$OUTPUT_DIR_PLUGIN" "${ROYALTSX_PLUGINS_DIR}/${PLUGIN_ID}.plugin"