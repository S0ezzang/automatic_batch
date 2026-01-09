@echo off
setlocal EnableExtensions EnableDelayedExpansion

set PROJECT_FILE=E:\shared\_git_auto\fcm55\fcm55_hkmc\.project
set PROJECT_NAME=FCM55_20260109

echo [TEST] Checking file existence
if not exist "%PROJECT_FILE%" (
    echo [ERROR] File not found in batch
    pause
    exit /b 1
) else (
    echo [OK] File exists in batch
)

echo.
echo [TEST] Setting environment variables
set "PS_PROJECT_FILE=%PROJECT_FILE%"
set "PS_PROJECT_NAME=%PROJECT_NAME%"

echo PS_PROJECT_FILE=%PS_PROJECT_FILE%
echo PS_PROJECT_NAME=%PS_PROJECT_NAME%

echo.
echo [TEST] Calling PowerShell
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $p=$env:PS_PROJECT_FILE; $n=$env:PS_PROJECT_NAME; Write-Host \"PowerShell received path: $p\"; if (-not (Test-Path -LiteralPath $p)) { throw \"File not found: $p\" }; $c = Get-Content -LiteralPath $p -ErrorAction Stop; $c = $c -replace '<name>FCM55.*?</name>', \"<name>$n</name>\"; Set-Content -LiteralPath $p -Value $c -ErrorAction Stop; Write-Host \"Successfully updated .project file\""

echo.
echo [TEST] PowerShell ERRORLEVEL: %ERRORLEVEL%

pause
