#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

echo "=========================================================="
echo "    Packaging Bionic FFmpeg ARM64 for Android Flashback   "
echo "=========================================================="

BUILD_TMP="build/tmp"
PKG_DIR="build/ffmpeg-pkg"
mkdir -p "$BUILD_TMP" "$PKG_DIR" dist

FFMPEG_VER="8.1.2-1.5.14"
JAVACPP_VER="1.5.14"

FFMPEG_JAR="ffmpeg-${FFMPEG_VER}-android-arm64.jar"
JAVACPP_JAR="javacpp-${JAVACPP_VER}-android-arm64.jar"

# Download official Bytedeco Android-ARM64 artifacts from Maven Central if not cached
if [ ! -f "$BUILD_TMP/$FFMPEG_JAR" ]; then
    echo ">>> Downloading $FFMPEG_JAR from Maven Central..."
    curl -L -o "$BUILD_TMP/$FFMPEG_JAR" \
        "https://repo1.maven.org/maven2/org/bytedeco/ffmpeg/${FFMPEG_VER}/${FFMPEG_JAR}"
fi

if [ ! -f "$BUILD_TMP/$JAVACPP_JAR" ]; then
    echo ">>> Downloading $JAVACPP_JAR from Maven Central..."
    curl -L -o "$BUILD_TMP/$JAVACPP_JAR" \
        "https://repo1.maven.org/maven2/org/bytedeco/javacpp/${JAVACPP_VER}/${JAVACPP_JAR}"
fi

# Extract and map native binaries to desktop linux-arm64 namespace
echo ">>> Unpacking and mapping Bionic shared libraries..."
rm -rf "$PKG_DIR"/*
unzip -q -o "$BUILD_TMP/$FFMPEG_JAR" -d "$PKG_DIR"
unzip -q -o "$BUILD_TMP/$JAVACPP_JAR" -d "$PKG_DIR"

mkdir -p "$PKG_DIR/org/bytedeco/ffmpeg/linux-arm64"
mkdir -p "$PKG_DIR/org/bytedeco/javacpp/linux-arm64"
mkdir -p "$PKG_DIR/org/bytedeco/ffmpeg/android-arm64"
mkdir -p "$PKG_DIR/org/bytedeco/javacpp/android-arm64"

if [ -d "$PKG_DIR/lib/arm64-v8a" ]; then
    for f in "$PKG_DIR/lib/arm64-v8a"/*; do
        b=$(basename "$f")
        if [ "$b" = "libjnijavacpp.so" ]; then
            cp "$f" "$PKG_DIR/org/bytedeco/javacpp/linux-arm64/"
            cp "$f" "$PKG_DIR/org/bytedeco/javacpp/android-arm64/"
        else
            cp "$f" "$PKG_DIR/org/bytedeco/ffmpeg/linux-arm64/"
            cp "$f" "$PKG_DIR/org/bytedeco/ffmpeg/android-arm64/"
        fi
    done
    # Remove redundant Android APK folder (JavaCPP uses org/bytedeco/ classpath)
    rm -rf "$PKG_DIR/lib"
fi

echo ">>> Packaging dist/flashtoch-ffmpeg-1.0.0.jar..."
jar cf dist/flashtoch-ffmpeg-1.0.0.jar -C "$PKG_DIR" .
rm -rf "$PKG_DIR"
echo ">>> Bionic FFmpeg packaging complete: dist/flashtoch-ffmpeg-1.0.0.jar"
