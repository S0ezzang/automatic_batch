@echo off

REM ==================================================
REM Check if already running with logging
REM ==================================================
if "%LOGGING_ENABLED%"=="1" goto :start

REM ==================================================
REM Setup logging and restart
REM ==================================================
setlocal EnableExtensions EnableDelayedExpansion
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set LOG_FILE=%~dp0logs\apply_vehicle_variants_%datetime:~0,8%_%datetime:~8,6%.log
if not exist "%~dp0logs" mkdir "%~dp0logs"

echo ========================================
echo Vehicle Variants Batch Process
echo Started: %datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%
echo Log file: %LOG_FILE%
echo ========================================
echo.

REM Restart this script with logging enabled
set LOGGING_ENABLED=1
cmd /c ""%~f0" 2>&1" | powershell -NoProfile -Command "$input | Tee-Object -FilePath '%LOG_FILE%'"
exit /b %ERRORLEVEL%

:start
setlocal EnableExtensions EnableDelayedExpansion

REM ==================================================
REM 0. 프로젝트 선택
REM ==================================================
echo ========================================
echo Select Project:
echo ========================================
echo 1. FCM55   (JG, RS4)
echo 2. FCM55S  (DL3_PE2, HE, QY2I, SX3I, SX3K, MX5_FL)
echo ========================================
echo.

set /p PROJECT_CHOICE="Enter your choice (1 or 2): "

if "%PROJECT_CHOICE%"=="1" goto :project_fcm55
if "%PROJECT_CHOICE%"=="2" goto :project_fcm55s

echo.
echo [ERROR] Invalid choice. Please select 1 or 2.
pause
exit /b 1

:project_fcm55
set PROJECT_ROOT=E:\shared\_git_auto\fcm55\fcm55_hkmc
set PROJECT_TYPE=FCM55
set CAR_LIST=JG RS4
echo.
echo Selected: FCM55 (JG, RS4)
goto :project_selected

:project_fcm55s
set PROJECT_ROOT=E:\shared\_git_auto\fcm55\fcm55s_hkmc
set PROJECT_TYPE=FCM55S
set CAR_LIST=DL3_PE2 HE QY2I SX3I SX3K MX5_FL
echo.
echo Selected: FCM55S (DL3_PE2, HE, QY2I, SX3I, SX3K, MX5_FL)
goto :project_selected

:project_selected
echo.

REM ==================================================
REM 1. 경로 정의
REM ==================================================
set LAUNCH_SRC=E:\shared\soyoung.jung\my_batch\launch_cfg.bat
set LAUNCH_DST=%PROJECT_ROOT%\util\launch_cfg.bat
set PROJECT_FILE=%PROJECT_ROOT%\.project
set BSW_BAT=%PROJECT_ROOT%\references\BswDevStart\BswDevStart_r3.bat
set FCM55_ROOT=%PROJECT_ROOT%


REM ==================================================
REM 1. launch_cfg.bat (B → A 복사)
REM ==================================================
echo [STEP 1] Copy launch_cfg.bat (B -> A)
copy /Y "%LAUNCH_SRC%" "%LAUNCH_DST%"
if errorlevel 1 goto :fail

REM ==================================================
REM 2. 오늘 날짜 기반 PROJECT_NAME 생성
REM ==================================================
for /f %%i in ('powershell -command "Get-Date -Format yyyyMMdd"') do set TODAY=%%i
set PROJECT_NAME=%PROJECT_TYPE%_%TODAY%
echo PROJECT_NAME=%PROJECT_NAME%

REM ==================================================
REM 3. .project 파일 name 수정 (절대경로 + 검증)
REM ==================================================
echo [STEP 3] Update .project name
echo Checking file:
echo %PROJECT_FILE%

if not exist "%PROJECT_FILE%" (
    echo [ERROR] .project file not found
    pause
    exit /b 1
)

REM 환경변수로 경로 전달
set "PS_PROJECT_FILE=%PROJECT_FILE%"
set "PS_PROJECT_NAME=%PROJECT_NAME%"

echo Updating .project file...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update_project.ps1"

if errorlevel 1 (
    echo [ERROR] Failed to update .project file
    pause
    exit /b 1
)

REM ==================================================
REM 4. BswDevStart_r3.bat PROJECT_NAME 수정
REM ==================================================
echo [STEP 4] Update PROJECT_NAME in BswDevStart_r3.bat

if not exist "%BSW_BAT%" (
    echo [ERROR] BswDevStart_r3.bat file not found
    pause
    exit /b 1
)

REM 환경변수로 경로 전달
set "PS_BSW_BAT=%BSW_BAT%"

echo Updating BswDevStart_r3.bat file...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update_bswdevstart.ps1"

if errorlevel 1 (
    echo [ERROR] Failed to update BswDevStart_r3.bat file
    pause
    exit /b 1
)

REM ==================================================
REM 5. TRESOS 환경 설정
REM ==================================================
echo [STEP 5] Load TRESOS environment
call "%LAUNCH_DST%"

IF "%TRESOS_CMD_BASE%"=="" (
    set "TRESOS_CMD_BASE=%TRESOS_BASE%\bin\tresos_cmd.bat"
)

REM ==================================================
REM 6. 차종별 (Import → BswDevStart → Generate) 반복
REM ==================================================
for %%C in (%CAR_LIST%) do (

    echo.
    echo ==============================================
    echo START CAR : %%C
    echo ==============================================

    REM ---------- 6. EB Import ----------
    echo [%%C] Import project
    cmd /c ""%TRESOS_CMD_BASE%" importProject -c %FCM55_ROOT%"
    if errorlevel 1 (
        echo [WARNING] Import failed - project may already exist, continuing...
    )

    REM ---------- 7. BswDevStart 실행 (자동 차종 입력) ----------
    echo [%%C] Run BswDevStart
    pushd "%PROJECT_ROOT%\references\BswDevStart"

    REM Set UTF-8 code page to support Unicode characters in Python scripts
    chcp 65001 >nul

    REM Create temporary input file with vehicle model (no trailing space)
    > temp_car_input.txt <nul set /p="%%C"
    echo.>> temp_car_input.txt

    call BswDevStart_r3.bat < temp_car_input.txt
    if exist temp_car_input.txt del temp_car_input.txt
    popd
    if errorlevel 1 goto :fail

    REM ---------- 8. Generate ----------
    echo [%%C] Generate
    "%TRESOS_CMD_BASE%" generate %PROJECT_NAME%
    if errorlevel 1 goto :fail

    echo ==============================================
    echo END CAR : %%C
    echo ==============================================
)

echo.
echo ===== ALL CARS COMPLETED SUCCESSFULLY =====
echo.
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set endtime=%%I
echo Completed: %endtime:~0,4%-%endtime:~4,2%-%endtime:~6,2% %endtime:~8,2%:%endtime:~10,2%:%endtime:~12,2%

exit /b 0

REM ==================================================
REM FAIL 처리
REM ==================================================
:fail
echo.
echo [ERROR] Batch execution failed.
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set endtime=%%I
echo Failed at: %endtime:~0,4%-%endtime:~4,2%-%endtime:~6,2% %endtime:~8,2%:%endtime:~10,2%:%endtime:~12,2%
pause
exit /b 1
