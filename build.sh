#!/bin/bash
set -e

# FPC paths
FPC="/home/kindex/bin/fpc/fpc/bin/x86_64-linux/fpc"
FPC_CROSS="/home/kindex/bin/fpc/fpc/bin/x86_64-linux/ppcrossx64"
WIN64_UNITS="-Fu/home/kindex/bin/fpc/fpc/units/x86_64-win64/rtl -Fu/home/kindex/bin/fpc/fpc/units/x86_64-win64/*"

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
    $FPC_CROSS -Twin64 $WIN64_UNITS -O3 -Xs rf.pas
    echo "Done: rf.exe"
    ;;
  wadedit)
    echo "Building wadedit..."
    $FPC @fpc.cfg utils/wadedit.pas
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
    echo "Usage: $0 {build|debug|release|win64|clean|rebuild|wadedit}"
    exit 1
    ;;
esac
