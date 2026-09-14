#!/bin/sh
# Build a standard 1.44 MiB FAT12 floppy image containing this project.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
OUTPUT=${1:-"$PROJECT_ROOT/vibe-2.img"}

case $OUTPUT in
    /*) :
        ;;
    *) OUTPUT=$(pwd)/$OUTPUT
        ;;
esac

OUTPUT_DIR=$(dirname -- "$OUTPUT")
mkdir -p "$OUTPUT_DIR"

if ! command -v mkfs.fat >/dev/null 2>&1; then
    echo "error: mkfs.fat is required (usually provided by dosfstools)" >&2
    exit 1
fi

if ! command -v mcopy >/dev/null 2>&1; then
    echo "error: mcopy is required (usually provided by mtools)" >&2
    exit 1
fi

TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/vibe-2-floppy.XXXXXX")
IMAGE=$TEMP_ROOT/vibe-2.img
STAGE=$TEMP_ROOT/project

cleanup()
{
    rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT HUP INT TERM

mkdir "$STAGE"

# Copy through tar so that dotfiles and directory structure are retained.
# Git metadata and the requested output image are not project payload. Keep the
# tarballs separate so an error from either archive operation is observable.
TAR_FILE=$TEMP_ROOT/project.tar
OUTPUT_REL=
case $OUTPUT in
    "$PROJECT_ROOT"/*) OUTPUT_REL=${OUTPUT#"$PROJECT_ROOT"/} ;;
esac

if [ -n "$OUTPUT_REL" ]; then
    tar -C "$PROJECT_ROOT" \
        --exclude='./.git' \
        --exclude="./$OUTPUT_REL" \
        -cf "$TAR_FILE" .
else
    tar -C "$PROJECT_ROOT" \
        --exclude='./.git' \
        -cf "$TAR_FILE" .
fi
tar -C "$STAGE" -xf "$TAR_FILE"

# 1,440 1-KiB blocks = 1,474,560 bytes, the usual 3.5-inch floppy size.
mkfs.fat -F 12 -n VIBE2 -C "$IMAGE" 1440 >/dev/null

# Walk the staging root instead of using a shell glob: this includes hidden
# files such as core/.gitignore and does not accidentally copy . or ... . Exit
# 255 makes find stop and return failure if mcopy reports a full/corrupt image.
find "$STAGE" -mindepth 1 -maxdepth 1 \
    -exec sh -c 'mcopy -i "$1" -s "$2" :: || exit 255' sh "$IMAGE" {} \;

# Publish only after the image has been formatted and populated successfully.
mv -f "$IMAGE" "$OUTPUT"
echo "Created $OUTPUT"
