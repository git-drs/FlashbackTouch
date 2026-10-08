#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SRC_DIR="native-build"
OUT_DIR="native-build/obj"
mkdir -p "$OUT_DIR"

# Locate JDK JNI include paths
JDK_INC="/data/data/com.termux/files/usr/lib/jvm/java-21-openjdk/include"
JDK_INC_LINUX="/data/data/com.termux/files/usr/lib/jvm/java-21-openjdk/include/linux"
if [ ! -d "$JDK_INC" ]; then
    JDK_BASE=$(find /data/data/com.termux/files/usr/lib/jvm/ -maxdepth 1 -name "*openjdk*" | head -n 1)
    JDK_INC="$JDK_BASE/include"
    JDK_INC_LINUX="$JDK_BASE/include/linux"
fi

CXX="clang++"
CXXFLAGS="-std=c++14 -fPIC -O3 -DNDEBUG -DIMGUI_USER_CONFIG=\"imconfig.h\" \
    -I$SRC_DIR -I$JDK_INC -I$JDK_INC_LINUX \
    -Wno-everything"

echo "=== 1. Compiling C++ files in $SRC_DIR ==="
OBJECTS=()
for src in "$SRC_DIR"/*.cpp; do
    base=$(basename "$src" .cpp)
    obj="$OUT_DIR/$base.o"
    echo "Compiling $base.cpp..."
    $CXX $CXXFLAGS -c "$src" -o "$obj"
    OBJECTS+=("$obj")
done

mkdir -p dist flashtoch-addon/src/main/resources/natives

echo "=== 2. Linking dist/libimgui-moulberry90-java64.so ==="
$CXX -shared -fPIC -O3 -o dist/libimgui-moulberry90-java64.so "${OBJECTS[@]}" -lm

echo "=== 3. Configuring collision-free C++ runtime (dist/libc++_flashtoch.so) ==="
SYSTEM_LIBCXX="/data/data/com.termux/files/usr/lib/libc++_shared.so"
cp "$SYSTEM_LIBCXX" dist/libc++_flashtoch.so
patchelf --set-soname libc++_flashtoch.so dist/libc++_flashtoch.so
patchelf --replace-needed libc++_shared.so libc++_flashtoch.so dist/libimgui-moulberry90-java64.so
patchelf --set-rpath '$ORIGIN' dist/libimgui-moulberry90-java64.so

echo "=== 4. Updating addon natives resources ==="
cp dist/libimgui-moulberry90-java64.so dist/libc++_flashtoch.so flashtoch-addon/src/main/resources/natives/

echo "=== Success! Machine architecture & dependencies ==="
readelf -h dist/libimgui-moulberry90-java64.so | grep Machine
readelf -d dist/libimgui-moulberry90-java64.so | grep -E 'RUNPATH|NEEDED'
ls -lh dist/libimgui-moulberry90-java64.so dist/libc++_flashtoch.so
