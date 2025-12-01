#!/usr/bin/env bash
set -e # Exit immediately if any command fails.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)" # Absolute path to the directory containing this script.
MAIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)" # Main project directory (assumes is one level from the script).
CALL_DIR="$(pwd)" # Current directory where the script is being used.

BUILD_SCRIPT="$MAIN_DIR/build.py" # Path to the build script.
HEX_FILE="$MAIN_DIR/MICROBIT.hex" # Expected output HEX file.

SOURCE_DIR="$MAIN_DIR/source" # Source directory.

# Ensure the build script exists
if [[ ! -f "$BUILD_SCRIPT" ]]; then
    echo "Error: build.py not found at $BUILD_SCRIPT"
    exit 1
fi

echo "Cleaning source directory: $SOURCE_DIR"

shopt -s nullglob # Make globs return empty list instead of literal pattern.
# Remove everything in source/ except the 'samples' directory.
for ITEM in "$SOURCE_DIR"/*; do
    BASENAME="$(basename "$ITEM")"
    if [[ "$BASENAME" != "samples" ]]; then
        rm -rf "$ITEM" # Delete file or directory.
    fi
done
shopt -u nullglob # Restore default glob behaviour.

FILES_TO_COPY=() # Array of files that will be copied into source.

# If the user passed arguments, treat them as files to copy.
if [[ $# -gt 0 ]]; then
    for f in "$@"; do
        FILES_TO_COPY+=("$CALL_DIR/$f") # Convert to absolute path.
    done
else
# Otherwise, copy all files in the caller directory.
    for f in "$CALL_DIR"/*; do
        [[ -f "$f" ]] && FILES_TO_COPY+=("$f") # Only include regular files.
    done
fi

echo "Copying files into source/ ..."

# Copy each selected file into the source directory.
for f in "${FILES_TO_COPY[@]}"; do
    BASENAME="$(basename "$f")"
    cp "$f" "$SOURCE_DIR/$BASENAME"
done

echo "Source folder updated."

# Determine output name based on first provided file, or use the directory name.
if [[ $# -gt 0 ]]; then
    FIRST_ARG="$1"
    if [[ -f "$FIRST_ARG" ]]; then
        OUTPUT_NAME="${FIRST_ARG##*/}" # Remove path name.
        OUTPUT_NAME="${OUTPUT_NAME%.*}" # Remove file extension.
    else
        OUTPUT_NAME="$(basename "$CALL_DIR")" # Use folder name as output.
    fi
else
    OUTPUT_NAME="$(basename "$CALL_DIR")" # No args so use current directory name.
fi

echo "Output name: $OUTPUT_NAME.hex"

cd "$MAIN_DIR"
echo "Running build..."
python3 "$BUILD_SCRIPT" # Execute the build process.

# Ensure the hex file was produced.
if [[ ! -f "$HEX_FILE" ]]; then
    echo "Error: MICROBIT.hex not found after build."
    exit 1
fi

DEST_FILE="$CALL_DIR/$OUTPUT_NAME.hex" # Renames the hex file and set its destination to where the script was called.
echo "Copying HEX to $DEST_FILE"
cp "$HEX_FILE" "$DEST_FILE" # Copy the built HEX to the called directory.

echo "Done."
