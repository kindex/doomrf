#!/bin/bash
set -e

# Extract version from rf.pas: version='X.X';
VERSION=$(grep -oP "version='\\K[^']+" rf.pas)
PLATFORM="${1:-linux64}"

case "$PLATFORM" in
  linux64)
    ARCHIVE="doomrf-v${VERSION}-linux64.tar.gz"
    EXECUTABLE="rf"
    BUILD_CMD="release"
    ;;
  win64)
    ARCHIVE="doomrf-v${VERSION}-win64.zip"
    EXECUTABLE="rf.exe"
    BUILD_CMD="win64"
    ;;
  win32)
    ARCHIVE="doomrf-v${VERSION}-win32.zip"
    EXECUTABLE="rf.exe"
    BUILD_CMD="win32"
    ;;
  *)
    echo "Usage: $0 {linux64|win64|win32}"
    exit 1
    ;;
esac

DIST_DIR="doomrf-${VERSION}"

echo "=== Building $PLATFORM release ==="
./build.sh "$BUILD_CMD"

echo "=== Creating distribution ==="
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Исполняемый файл
cp "$EXECUTABLE" "$DIST_DIR/"

# Конфиг
cp doom.ini "$DIST_DIR/"

# Ресурсы (без Saves)
cp -r RF "$DIST_DIR/"
rm -rf "$DIST_DIR/RF/Saves" "$DIST_DIR/Doom/Saves"

# Документация
cp README.txt CHANGELOG.txt "$DIST_DIR/" 2>/dev/null || true

# Платформо-зависимые файлы
case "$PLATFORM" in
  linux64)
    # Библиотеки из libs/
    mkdir -p "$DIST_DIR/libs"
    cp libs/*.so* "$DIST_DIR/libs/" 2>/dev/null || true
    # SDL2 из системы если нет локальной
    if [ ! -f "$DIST_DIR/libs/libSDL2"* ]; then
        [ -f /usr/lib/x86_64-linux-gnu/libSDL2-2.0.so.0 ] && \
            cp /usr/lib/x86_64-linux-gnu/libSDL2-2.0.so.0 "$DIST_DIR/libs/"
    fi
    # Скрипт запуска
    cp rf.sh "$DIST_DIR/"
    ;;
  win64|win32)
    # SDL2 DLLs для Windows
    DLL_COUNT=0
    for dll in SDL2.dll SDL2_image.dll SDL2_mixer.dll SDL2_ttf.dll \
               lib*.dll; do
        if [ -f "$dll" ]; then
            cp "$dll" "$DIST_DIR/"
            ((DLL_COUNT++)) || true
        fi
    done
    if [ $DLL_COUNT -eq 0 ]; then
        echo "WARNING: No DLLs found. Run ./build-win64.sh first to download them."
    else
        echo "Copied $DLL_COUNT DLL files"
    fi
    ;;
esac

echo "=== Creating archive ==="
case "$PLATFORM" in
  linux64)
    tar -czvf "$ARCHIVE" "$DIST_DIR"
    ;;
  win64|win32)
    zip -r "$ARCHIVE" "$DIST_DIR"
    ;;
esac

rm -rf "$DIST_DIR"

echo ""
echo "Created: $ARCHIVE"
ls -lh "$ARCHIVE"
