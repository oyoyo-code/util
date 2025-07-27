@echo off
setlocal

REM =============================================================================
REM �o�b�`�R�}���h�݂̂ł̃t�@�C���N���[���A�b�v
REM ����: ���t��r�����G�A�T�u�t�H���_����������
REM =============================================================================

set TARGET_PATH=%1
set FILE_EXTENSION=%2
set DAYS_TO_KEEP=%3
set INCLUDE_SUBDIRS=%4

if "%TARGET_PATH%"=="" set TARGET_PATH=C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Log
if "%FILE_EXTENSION%"=="" set FILE_EXTENSION=txt
if "%DAYS_TO_KEEP%"=="" set DAYS_TO_KEEP=7
if "%INCLUDE_SUBDIRS%"=="" set INCLUDE_SUBDIRS=Y

set LOG_FILE=%~dp0cleanup_log_%date:~0,4%%date:~5,2%%date:~8,2%.txt

echo =============================================== >> "%LOG_FILE%"
echo �N���[���A�b�v�J�n: %date% %time% >> "%LOG_FILE%"
echo =============================================== >> "%LOG_FILE%"

REM ����t�̌v�Z�iWMIC�g�p�j
for /f "tokens=1-3 delims=/" %%a in ('wmic os get localdatetime /value ^| find "=" ^| for /f "tokens=2 delims==" %%x in ("%%i") do echo %%x') do (
    set TODAY=%%i
)
set TODAY=%TODAY:~0,8%

REM �ȈՓI�ȓ��t�v�Z�i30���O�Œ� - ���m�Ȍv�Z�͕��G�j
set /a YEAR=%TODAY:~0,4%
set /a MONTH=%TODAY:~4,2%
set /a DAY=%TODAY:~6,2%

REM �����������i�����܂����v�Z�͏ȗ��j
set /a DAY=%DAY%-%DAYS_TO_KEEP%
if %DAY% LEQ 0 (
    set /a MONTH=%MONTH%-1
    set /a DAY=30
    if %MONTH% LEQ 0 (
        set /a YEAR=%YEAR%-1
        set MONTH=12
    )
)

REM �[���p�f�B���O
if %MONTH% LSS 10 set MONTH=0%MONTH%
if %DAY% LSS 10 set DAY=0%DAY%

set CUTOFF_DATE=%YEAR%%MONTH%%DAY%

echo �J�b�g�I�t��: %CUTOFF_DATE% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM �t�@�C���폜�i�T�u�t�H���_�Ȃ��̏ꍇ�̂݁j
set DELETE_COUNT=0

if /i "%INCLUDE_SUBDIRS%"=="Y" (
    echo �T�u�t�H���_������PowerShell�ł��g�p���Ă������� >> "%LOG_FILE%"
    goto :EOF
)

for %%f in ("%TARGET_PATH%\*.%FILE_EXTENSION%") do (
    call :CheckAndDelete "%%f"
)

echo �폜����: %DELETE_COUNT% �t�@�C�� >> "%LOG_FILE%"
goto :EOF

:CheckAndDelete
set FILE_PATH=%~1
if not exist %FILE_PATH% goto :EOF

REM �t�@�C�����t�擾�iWMIC�g�p�j
for /f "tokens=1-3" %%a in ('wmic datafile where "name='%FILE_PATH:\=\\%'" get LastModified /value 2^>nul ^| find "="') do (
    for /f "tokens=2 delims==" %%x in ("%%a") do set FILE_DATE=%%x
)

if not defined FILE_DATE goto :EOF
set FILE_DATE=%FILE_DATE:~0,8%

REM ���t��r�i�������r - ��������j
if "%FILE_DATE%" LSS "%CUTOFF_DATE%" (
    echo �폜��: %FILE_PATH% >> "%LOG_FILE%"
    del "%FILE_PATH%" 2>nul
    if not exist "%FILE_PATH%" (
        set /a DELETE_COUNT+=1
    ) else (
        echo �G���[: %FILE_PATH% >> "%LOG_FILE%"
    )
)
goto :EOF