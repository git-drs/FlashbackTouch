#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

GITHUB_USER="${1:-$FLASHTOCH_GITHUB_USER}"
if [ -z "$GITHUB_USER" ]; then
    GITHUB_USER="git-drs"
fi

echo "=========================================================="
echo "      Flashback Touch: Cloning Companion Repositories     "
echo "=========================================================="
echo "GitHub Organization / User: $GITHUB_USER"

mkdir -p external

# 1. ImGui Native Android Repo
IMGUI_DIR=""
if [ -d "$ROOT_DIR/imgui-android" ]; then
    IMGUI_DIR="$ROOT_DIR/imgui-android"
    echo ">>> Found existing local directory: $IMGUI_DIR"
elif [ -d "$ROOT_DIR/../imgui-android" ]; then
    IMGUI_DIR="$ROOT_DIR/../imgui-android"
    echo ">>> Found existing sibling directory: $IMGUI_DIR"
elif [ -d "$ROOT_DIR/../imgui-moulberry90-android" ]; then
    IMGUI_DIR="$ROOT_DIR/../imgui-moulberry90-android"
    echo ">>> Found existing sibling directory: $IMGUI_DIR"
elif [ -d "$ROOT_DIR/external/imgui-android" ]; then
    IMGUI_DIR="$ROOT_DIR/external/imgui-android"
    echo ">>> Found existing external directory: $IMGUI_DIR"
elif [ -d "$ROOT_DIR/external/imgui-moulberry90-android" ]; then
    IMGUI_DIR="$ROOT_DIR/external/imgui-moulberry90-android"
    echo ">>> Found existing external directory: $IMGUI_DIR"
else
    echo ">>> Cloning imgui-android from GitHub ($GITHUB_USER)..."
    git clone "https://github.com/$GITHUB_USER/imgui-android.git" "$ROOT_DIR/external/imgui-android" || {
        echo ">>> [Note] Remote clone failed (not pushed to GitHub yet?)."
    }
    IMGUI_DIR="$ROOT_DIR/external/imgui-android"
fi

# 2. FFmpeg Bionic Android Packaging
if [ ! -f "$ROOT_DIR/dist/flashtoch-ffmpeg-1.0.0.jar" ]; then
    if [ -f "$ROOT_DIR/scripts/package_ffmpeg.sh" ]; then
        echo ">>> Packaging official Bionic FFmpeg binaries via scripts/package_ffmpeg.sh..."
        bash "$ROOT_DIR/scripts/package_ffmpeg.sh"
    fi
else
    echo ">>> Found existing Bionic FFmpeg package in dist/."
fi

echo "=========================================================="
echo ">>> All components are ready for building!"
echo "    ImGui Repo: $IMGUI_DIR"
echo "=========================================================="
