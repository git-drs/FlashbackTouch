#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================================="
echo "      Building Flashback Touch Android ARM64 Addon        "
echo "=========================================================="

# 1. Ensure companion repositories are cloned and present
if [ -f "scripts/clone_all.sh" ]; then
    bash scripts/clone_all.sh
fi

# Locate companion repos (sibling or local or external)
IMGUI_DIR=""
if [ -d "$SCRIPT_DIR/imgui-android" ]; then
    IMGUI_DIR="$SCRIPT_DIR/imgui-android"
elif [ -d "$SCRIPT_DIR/../imgui-android" ]; then
    IMGUI_DIR="$SCRIPT_DIR/../imgui-android"
elif [ -d "$SCRIPT_DIR/../imgui-moulberry90-android" ]; then
    IMGUI_DIR="$SCRIPT_DIR/../imgui-moulberry90-android"
elif [ -d "$SCRIPT_DIR/external/imgui-android" ]; then
    IMGUI_DIR="$SCRIPT_DIR/external/imgui-android"
elif [ -d "$SCRIPT_DIR/external/imgui-moulberry90-android" ]; then
    IMGUI_DIR="$SCRIPT_DIR/external/imgui-moulberry90-android"
fi

FFMPEG_DIR=""
if [ -d "$SCRIPT_DIR/../flashtoch-ffmpeg-android" ]; then
    FFMPEG_DIR="$SCRIPT_DIR/../flashtoch-ffmpeg-android"
elif [ -d "$SCRIPT_DIR/external/flashtoch-ffmpeg-android" ]; then
    FFMPEG_DIR="$SCRIPT_DIR/external/flashtoch-ffmpeg-android"
fi

mkdir -p dist flashtoch-addon/src/main/resources/natives

# 2. Build or copy ImGui C++ native binaries
if [ "$1" == "--rebuild" ] || [ ! -f "dist/libimgui-moulberry90-java64.so" ] || [ ! -f "dist/libc++_flashtoch.so" ]; then
    if [ -n "$IMGUI_DIR" ] && [ -f "$IMGUI_DIR/build.sh" ]; then
        echo ">>> Building ImGui native binaries in $IMGUI_DIR..."
        (cd "$IMGUI_DIR" && bash build.sh)
        cp "$IMGUI_DIR"/dist/*.so dist/
    elif [ -f "build_so.sh" ]; then
        echo ">>> Building C++ native libraries using local build_so.sh..."
        bash build_so.sh
    fi
else
    echo ">>> ImGui native binaries already present in dist/."
fi
cp dist/libimgui-moulberry90-java64.so dist/libc++_flashtoch.so flashtoch-addon/src/main/resources/natives/

# 3. Build or package Bionic FFmpeg JAR
if [ ! -f "dist/flashtoch-ffmpeg-1.0.0.jar" ]; then
    if [ -f "scripts/package_ffmpeg.sh" ]; then
        echo ">>> Packaging Bionic FFmpeg using scripts/package_ffmpeg.sh..."
        bash scripts/package_ffmpeg.sh
    elif [ -n "$FFMPEG_DIR" ] && [ -f "$FFMPEG_DIR/build.sh" ]; then
        echo ">>> Packaging Bionic FFmpeg in $FFMPEG_DIR..."
        (cd "$FFMPEG_DIR" && bash build.sh)
        cp "$FFMPEG_DIR/dist/flashtoch-ffmpeg-1.0.0.jar" dist/
    fi
else
    echo ">>> Bionic FFmpeg jar already present in dist/."
fi

# 4. Compile Java sources (PreLaunch entrypoint + Android compatibility mixins)
echo ">>> Compiling Java sources (FlashToch PreLaunch & Mixins)..."
FABRIC_LOADER_JAR=$(find /data/data/com.termux/files/home/.gradle/caches/modules-2/files-2.1/net.fabricmc/fabric-loader/ -name "fabric-loader-*.jar" | head -n 1)
MIXIN_JAR=$(find /data/data/com.termux/files/home/.gradle/caches/modules-2/files-2.1/net.fabricmc/sponge-mixin/ -name "sponge-mixin-*.jar" | head -n 1)
OPENAL_JAR=$(find /data/data/com.termux/files/home/.gradle/caches/modules-2/files-2.1/org.lwjgl/lwjgl-openal/ -name "lwjgl-openal-*.jar" | grep -v "natives" | head -n 1)

rm -rf flashtoch-addon/build/classes flashtoch-addon/build/jar
mkdir -p flashtoch-addon/build/classes flashtoch-addon/build/jar

javac --release 17 \
    -cp "$FABRIC_LOADER_JAR:$MIXIN_JAR:$OPENAL_JAR:flashtoch-addon/lib/*" \
    -d flashtoch-addon/build/classes \
    $(find flashtoch-addon/src/main/java -name "*.java")

# 5. Assemble All-in-One JAR
echo ">>> Packaging All-in-One flashbacktouch-1.0.0.jar (Dear ImGui + FFmpeg)..."
rm -rf flashtoch-addon/build/jar/*
cp -r flashtoch-addon/build/classes/* flashtoch-addon/build/jar/
cp -r flashtoch-addon/src/main/resources/* flashtoch-addon/build/jar/

# Extract FFmpeg & JavaCPP bionic binaries into the package if present in dist
if [ -f "dist/flashtoch-ffmpeg-1.0.0.jar" ]; then
    unzip -q -o dist/flashtoch-ffmpeg-1.0.0.jar "org/*" -d flashtoch-addon/build/jar/
fi

mkdir -p dist
jar cf dist/flashbacktouch-1.0.0.jar -C flashtoch-addon/build/jar .
cp dist/flashbacktouch-1.0.0.jar dist/flashtoch-1.0.0.jar
rm -rf flashtoch-addon/build

echo "=========================================================="
echo ">>> BUILD COMPLETE!"
echo "Deliverable: dist/flashbacktouch-1.0.0.jar ($(du -h dist/flashbacktouch-1.0.0.jar | cut -f1))"
echo "Location:    $SCRIPT_DIR/dist/flashbacktouch-1.0.0.jar"
echo "=========================================================="
