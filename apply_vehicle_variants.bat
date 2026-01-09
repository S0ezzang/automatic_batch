@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ==================================================
REM 0. 경로 정의
REM ==================================================
set LAUNCH_SRC=E:\shared\soyoung.jung\my_batch\launch_cfg.bat
set LAUNCH_DST=E:\shared\_git_auto\fcm55\fcm55_hkmc\util\launch_cfg.bat
set PROJECT_FILE=E:\shared\_git_auto\fcm55\fcm55_hkmc\.project
set BSW_BAT=E:\shared\_git_auto\fcm55\fcm55_hkmc\references\BswDevStart\BswDevStart_r2.bat
set FCM55_ROOT=E:\shared\_git_auto\fcm55\fcm55_hkmc


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
set PROJECT_NAME=FCM55_%TODAY%
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
REM 4. BswDevStart_r2.bat PROJECT_NAME 수정
REM ==================================================
echo [STEP 4] Update PROJECT_NAME in BswDevStart_r2.bat

if not exist "%BSW_BAT%" (
    echo [ERROR] BswDevStart_r2.bat file not found
    pause
    exit /b 1
)

REM 환경변수로 경로 전달
set "PS_BSW_BAT=%BSW_BAT%"

echo Updating BswDevStart_r2.bat file...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update_bswdevstart.ps1"

if errorlevel 1 (
    echo [ERROR] Failed to update BswDevStart_r2.bat file
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
REM 6. 차종 리스트
REM ==================================================
set CAR_LIST=JG RS4_FL

REM ==================================================
REM 7. 차종별 (Import → BswDevStart → Generate) 반복
REM ==================================================
for %%C in (%CAR_LIST%) do (

    echo.
    echo ==============================================
    echo START CAR : %%C
    echo ==============================================

    REM ---------- 6. EB Import ----------
    echo [%%C] Import project
    cmd /c ""%TRESOS_CMD_BASE%" importProject -c %FCM55_ROOT%"
    if errorlevel 1 goto :fail

    REM ---------- 7. BswDevStart 실행 (자동 차종 입력) ----------
    echo [%%C] Run BswDevStart
    pushd "E:\shared\_git_auto\fcm55\fcm55_hkmc\references\BswDevStart"
    echo %%C | call BswDevStart_r2.bat
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

exit /b 0

REM ==================================================
REM FAIL 처리
REM ==================================================
:fail
echo.
echo [ERROR] Batch execution failed.
pause
exit /b 1
