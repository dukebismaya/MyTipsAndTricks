@echo off
setlocal enabledelayedexpansion

:: Set colors
color 0A

echo.
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                          VS Code Context Menu Setup                          ║
echo ║                              By Bismaya                                      ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝
echo.

:: loading
echo [■□□□□□□□□□] Initializing setup...
timeout /t 1 /nobreak >nul
echo [■■■□□□□□□□] Detecting system configuration...
timeout /t 1 /nobreak >nul

:: Get system info
set "currentUser=%USERNAME%"
set "userProfile=%USERPROFILE%"
for /f "tokens=2 delims==" %%i in ('wmic os get caption /value ^| find "="') do set "osName=%%i"

echo [■■■■■□□□□□] Scanning for VS Code installations...
timeout /t 1 /nobreak >nul

:: Auto-detect VS Code with multiple fallbacks
set "vscodePath="
set "searchPaths[0]=%userProfile%\AppData\Local\Programs\Microsoft VS Code\Code.exe"
set "searchPaths[1]=C:\Program Files\Microsoft VS Code\Code.exe"
set "searchPaths[2]=C:\Program Files (x86)\Microsoft VS Code\Code.exe"

:: Smart search across all user profiles
for /d %%u in (C:\Users\*) do (
    if exist "%%u\AppData\Local\Programs\Microsoft VS Code\Code.exe" (
        set "vscodePath=%%u\AppData\Local\Programs\Microsoft VS Code\Code.exe"
        goto :detected
    )
)

:: Check standard installation paths
for /L %%i in (0,1,2) do (
    if defined searchPaths[%%i] (
        if exist "!searchPaths[%%i]!" (
            set "vscodePath=!searchPaths[%%i]!"
            goto :detected
        )
    )
)

:: Registry search as fallback
for /f "skip=1 tokens=1,2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Visual Studio Code" 2^>nul ^| findstr "DisplayIcon InstallLocation"') do (
    if "%%a"=="InstallLocation" (
        if exist "%%c\Code.exe" (
            set "vscodePath=%%c\Code.exe"
            goto :detected
        )
    )
    if "%%a"=="DisplayIcon" (
        if exist "%%c" (
            set "vscodePath=%%c"
            goto :detected
        )
    )
)

:detected
echo [■■■■■■■□□□] Validating installation...
timeout /t 1 /nobreak >nul

if "%vscodePath%"=="" (
    color 0C
    echo.
    echo ╔══════════════════════════════════════════════════════════════════════════════╗
    echo ║                                  ERROR                                       ║
    echo ║                      VS Code installation not found!                         ║
    echo ║                   Please install VS Code and try again.                      ║
    echo ╚══════════════════════════════════════════════════════════════════════════════╝
    echo.
    pause
    exit /b 1
)

echo [■■■■■■■■■□] Preparing registry entries...
timeout /t 1 /nobreak >nul

:: Display system info
color 0B
echo.
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                            SYSTEM INFORMATION                                ║
echo ╠══════════════════════════════════════════════════════════════════════════════╣
echo ║ User:        %currentUser%                                                   ║
echo ║ OS:          %osName%                                                        ║
echo ║ VS Code:     %vscodePath%                                                    ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝
echo.

:: Create enhanced registry file
set "regFile=%temp%\vscode_context_pro.reg"

echo [■■■■■■■■■■] Generating context menu entries...
timeout /t 1 /nobreak >nul

(
echo Windows Registry Editor Version 5.00
echo.
echo ; === VS Code Context Menu Setup by Bismaya ===
echo ; Folder context menu
echo [HKEY_CLASSES_ROOT\Directory\shell\VSCode]
echo @="Open with Code"
echo "Icon"="%vscodePath:\=\\%,0"
echo "Extended"=-
echo.
echo [HKEY_CLASSES_ROOT\Directory\shell\VSCode\command]
echo @="\"%vscodePath:\=\\%\" \"%%1\""
echo.
echo ; Background context menu
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode]
echo @="Open with Code"
echo "Icon"="%vscodePath:\=\\%,0"
echo "Extended"=-
echo.
echo [HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode\command]
echo @="\"%vscodePath:\=\\%\" \"%%V\""
echo.
echo ; File context menu
echo [HKEY_CLASSES_ROOT\*\shell\VSCode]
echo @="Edit with Code"
echo "Icon"="%vscodePath:\=\\%,0"
echo.
echo [HKEY_CLASSES_ROOT\*\shell\VSCode\command]
echo @="\"%vscodePath:\=\\%\" \"%%1\""
) > "%regFile%"

color 0E
echo.
echo ╔══════════════════════════════════════════════════════════════════════════════╗
echo ║                        READY TO INSTALL CONTEXT MENU                         ║
echo ╠══════════════════════════════════════════════════════════════════════════════╣
echo ║ This will add the following context menu options:                            ║
echo ║                                                                              ║
echo ║ • Right-click on folders  → "Open with Code"                                 ║
echo ║ • Right-click on files    → "Edit with Code"                                 ║
echo ║ • Right-click on empty    → "Open with Code"                                 ║
echo ║   space in folders                                                           ║
echo ╚══════════════════════════════════════════════════════════════════════════════╝
echo.

:: Auto-proceed with countdown
color 0A
echo Installing in:
for /L %%i in (3,-1,1) do (
    echo %%i seconds... Press any key to cancel
    timeout /t 1 /nobreak >nul
)

echo.
echo ► Applying registry changes...
regedit /s "%regFile%" 2>nul

if %errorlevel%==0 (
    color 0A
    echo.
    echo ╔══════════════════════════════════════════════════════════════════════════════╗
    echo ║                              SUCCESS!                                        ║
    echo ╠══════════════════════════════════════════════════════════════════════════════╣
    echo ║ VS Code context menu has been successfully installed!                        ║
    echo ║                                                                              ║
    echo ║ You can now:                                                                 ║
    echo ║ • Right-click any folder to open it in VS Code                               ║
    echo ║ • Right-click any file to edit it in VS Code                                 ║
    echo ║ • Right-click empty space in Explorer to open current folder                 ║
    echo ╚══════════════════════════════════════════════════════════════════════════════╝
    echo.
    echo ► Setup completed successfully by Bismaya's VS Code Context Menu Tool
) else (
    color 0C
    echo.
    echo ╔══════════════════════════════════════════════════════════════════════════════╗
    echo ║                                ERROR                                         ║
    echo ╠══════════════════════════════════════════════════════════════════════════════╣
    echo ║ Failed to apply registry changes.                                            ║
    echo ║ Please run this script as Administrator.                                     ║
    echo ║                                                                              ║
    echo ║ Right-click the script and select "Run as administrator"                     ║
    echo ╚══════════════════════════════════════════════════════════════════════════════╝
)

:: Cleanup
del "%regFile%" 2>nul

echo.
echo Press any key to exit...
pause >nul