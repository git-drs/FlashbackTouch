#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMGUI_DIR=""
if [ -d "$SCRIPT_DIR/imgui-android" ]; then
    IMGUI_DIR="$SCRIPT_DIR/imgui-android"
elif [ -d "$SCRIPT_DIR/../imgui-android" ]; then
    IMGUI_DIR="$SCRIPT_DIR/../imgui-android"
fi

if [ -z "$IMGUI_DIR" ] || [ ! -f "$IMGUI_DIR/build.sh" ]; then
    echo "Error: Cannot locate imgui-android repository with build.sh."
    exit 1
fi

echo "=== 1. Building Dear ImGui Android C++ binaries ($IMGUI_DIR) ==="
(cd "$IMGUI_DIR" && bash build.sh)

echo "=== 2. Staging native libraries to dist/ and flashtoch-addon/ ==="
mkdir -p dist flashtoch-addon/src/main/resources/natives
cp "$IMGUI_DIR"/dist/libimgui-moulberry90-java64.so dist/
cp "$IMGUI_DIR"/dist/libc++_flashtoch.so dist/
cp dist/libimgui-moulberry90-java64.so dist/libc++_flashtoch.so flashtoch-addon/src/main/resources/natives/

echo "=== Success! Native binaries staged ==="
ls -lh dist/libimgui-moulberry90-java64.so dist/libc++_flashtoch.so

