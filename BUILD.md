# Building DOOM 513: RF

## Requirements

### Linux
- Free Pascal Compiler (FPC) 3.2.2+
- SDL2 (`apt install libsdl2-dev`)

### Windows
- Free Pascal Compiler (FPC) 3.2.2+
- SDL2.dll (download from https://libsdl.org/download-2.0.php)

### Cross-compilation Linux → Windows
- FPC with Windows target support (`fpcupdeluxe` or `apt install fpc-crosswin64`)
- SDL2.dll in project root

## Building

### Linux

```bash
# Debug build
./build.sh

# Release build (optimized)
./build.sh release

# Clean
./build.sh clean

# Rebuild
./build.sh rebuild

# Build wadedit utility
./build.sh wadedit
```

### Windows (native)

```cmd
REM Debug build
build.bat

REM Release build
build.bat release

REM Clean
build.bat clean

REM Rebuild
build.bat rebuild
```

### Cross-compilation for Windows

```bash
# Windows 64-bit
./build.sh win64

# Windows 32-bit
./build.sh win32
```

## Creating Distribution Package

```bash
# Linux 64-bit (tar.gz)
./package.sh linux64

# Windows 64-bit (zip)
./package.sh win64

# Windows 32-bit (zip)
./package.sh win32
```

Archives are created in project root:
- `doomrf-v2.0-linux64.tar.gz`
- `doomrf-v2.0-win64.zip`
- `doomrf-v2.0-win32.zip`

## WebStorm / IntelliJ IDEA

Run Configurations are included:
- **Build** - build the project
- **Run** - run the game
- **Build and Run** - build and run

## Project Structure

```
doomrf2/
├── rf.pas              # Main program
├── build.sh            # Build script (Linux)
├── build.bat           # Build script (Windows)
├── package.sh          # Create distribution
├── fpc.cfg             # FPC configuration
├── doom.ini            # Game configuration
├── build/              # Object files (.o, .ppu)
├── sdl2/               # SDL2 Pascal bindings
├── RF/                 # RF mod resources
├── Doom/               # Doom mod resources
└── bots/               # Bot configurations
```