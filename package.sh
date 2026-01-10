#!/bin/bash
set -e

VERSION="2.0"
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
cp -r Doom "$DIST_DIR/"
cp -r bots "$DIST_DIR/"
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
    cp run.sh "$DIST_DIR/"
    ;;
  win64|win32)
    # SDL2.dll для Windows (должен лежать в проекте)
    if [ -f SDL2.dll ]; then
        cp SDL2.dll "$DIST_DIR/"
    else
        echo "WARNING: SDL2.dll not found. Download from https://libsdl.org/download-2.0.php"
    fi
    # SDL2_image.dll для PNG
    if [ -f SDL2_image.dll ]; then
        cp SDL2_image.dll "$DIST_DIR/"
    else
        echo "WARNING: SDL2_image.dll not found"
    fi
    # Добавить build.bat
    cp build.bat "$DIST_DIR/"
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
