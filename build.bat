@echo off
setlocal

set FPC=fpc
set PROJECT_DIR=%~dp0
set BUILD_DIR=%PROJECT_DIR%build

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

if "%1"=="" goto build
if "%1"=="build" goto build
if "%1"=="debug" goto build
if "%1"=="release" goto release
if "%1"=="wadedit" goto wadedit
if "%1"=="clean" goto clean
if "%1"=="rebuild" goto rebuild
goto usage

:build
echo Building debug...
%FPC% @fpc.cfg rf.pas -o rf.exe
echo Done: rf.exe
goto end

:release
echo Building release...
%FPC% @fpc.cfg -O3 -Xs rf.pas -o rf.exe
echo Done: rf.exe (optimized)
goto end

:wadedit
echo Building wadedit...
%FPC% @fpc.cfg utils\wadedit.pas -o wadedit.exe
echo Done: wadedit.exe
goto end

:clean
echo Cleaning...
del /q "%BUILD_DIR%\*.o" 2>nul
del /q "%BUILD_DIR%\*.ppu" 2>nul
del /q rf.exe wadedit.exe link*.res 2>nul
echo Done
goto end

:rebuild
call %0 clean
call %0 build
goto end

:usage
echo Usage: %0 {build^|debug^|release^|clean^|rebuild^|wadedit}
exit /b 1

:end
endlocal
