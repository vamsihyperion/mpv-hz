@echo off
setlocal enabledelayedexpansion

:: Set download URL and temp folder
set "URL=https://sourceforge.net/projects/mpv-player-windows/files/64bit/"
set "TEMP_DIR=%TEMP%\mpv_update"

:: Create temp dir
mkdir "%TEMP_DIR%" >nul 2>&1
cd /d "%TEMP_DIR%"

echo [INFO] Checking for latest mpv version...

:: Get the actual download link for the latest .7z file using curl and findstr
curl -s -L "%URL%" > mpv_page.html
for /f "tokens=1* delims=>=" %%a in ('findstr /i "mpv-x86_64.*7z" mpv_page.html') do (
    echo %%a%%b | findstr /i ".7z" >nul
    if !errorlevel! == 0 (
        for /f "tokens=2 delims=\"" %%x in ("%%b") do (
            set "FILENAME=%%x"
            goto :found
        )
    )
)

:found
if not defined FILENAME (
    echo [ERROR] Could not find latest mpv build.
    exit /b 1
)

echo [INFO] Latest version found: %FILENAME%
set "DOWNLOAD_URL=https://downloads.sourceforge.net/project/mpv-player-windows/64bit/%FILENAME%"

echo [INFO] Downloading %FILENAME%...
curl -L -o mpv-latest.7z "%DOWNLOAD_URL%"

echo [INFO] Extracting and updating...
mkdir mpv_temp
"%ProgramFiles%\7-Zip\7z.exe" x -y mpv-latest.7z -ompv_temp >nul

echo [INFO] Replacing old files...
xcopy /Y /E /Q /H mpv_temp\* "C:\mpv\" >nul

echo [DONE] mpv is updated.
timeout /t 3
