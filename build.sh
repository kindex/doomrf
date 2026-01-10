#!/bin/bash
set -e

FPC="/home/kindex/bin/fpc/bin/fpc"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"

mkdir -p "$BUILD_DIR"

case "${1:-build}" in
  build|debug)
    echo "Building debug (Linux)..."
    $FPC @fpc.cfg rf.pas
    echo "Done: rf"
    ;;
  release)
    echo "Building release (Linux)..."
    $FPC @fpc.cfg -O3 -Xs rf.pas
    echo "Done: rf (optimized)"
    ;;
  win64)
    echo "Building release (Windows x64)..."
    $FPC @fpc.cfg -Px86_64 -Twin64 -O3 -Xs rf.pas -o rf.exe
    echo "Done: rf.exe"
    ;;
  win32)
    echo "Building release (Windows x86)..."
    $FPC @fpc.cfg -Pi386 -Twin32 -O3 -Xs rf.pas -o rf.exe
    echo "Done: rf.exe"
    ;;
  wadedit)
    echo "Building wadedit..."
    $FPC @fpc.cfg utils/wadedit.pas -o wadedit
    echo "Done: wadedit"
    ;;
  clean)
    echo "Cleaning..."
    rm -rf "$BUILD_DIR"/*.o "$BUILD_DIR"/*.ppu
    rm -f rf rf.exe wadedit wadedit.exe link*.res
    echo "Done"
    ;;
  rebuild)
    $0 clean && $0 build
    ;;
  *)
    echo "Usage: $0 {build|debug|release|win64|win32|clean|rebuild|wadedit}"
    exit 1
    ;;
esac
