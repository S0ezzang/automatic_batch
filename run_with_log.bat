@echo off
REM ==================================================
REM Wrapper script to run apply_vehicle_variants.bat with logging
REM ==================================================

REM Generate log filename with timestamp
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set LOG_FILE=apply_vehicle_variants_%datetime:~0,8%_%datetime:~8,6%.log

echo ========================================
echo Starting vehicle variants batch process
echo Log file: %LOG_FILE%
echo ========================================
echo.

REM Run the main batch file and capture all output
powershell -NoProfile -Command ^
"& { ^
  & '%~dp0apply_vehicle_variants.bat' | Tee-Object -FilePath '%~dp0%LOG_FILE%' ^
}"

echo.
echo ========================================
echo Process completed
echo Log saved to: %~dp0%LOG_FILE%
echo ========================================
pause
