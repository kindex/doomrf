#!/bin/bash
cd "$(dirname "$0")"

# Create symlinks for libraries if needed
[ -f libs/libSDL2-2.0.so.0 ] && [ ! -f libs/libSDL2.so ] && \
    ln -sf libSDL2-2.0.so.0 libs/libSDL2.so
[ -f libs/libSDL2_image-2.0.so.0 ] && [ ! -f libs/libSDL2_image.so ] && \
    ln -sf libSDL2_image-2.0.so.0 libs/libSDL2_image.so

LD_LIBRARY_PATH=libs:. ./rf "$@"