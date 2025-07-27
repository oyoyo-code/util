@echo off
setlocal

REM =============================================================================
REM SQL Server �����e�i���X�v���� ���|�[�g�N���[���A�b�v �o�b�`�t�@�C��
REM =============================================================================

REM �p�����[�^�̐ݒ�
set TARGET_PATH=%1
set FILE_EXTENSION=%2
set DAYS_TO_KEEP=%3
set INCLUDE_SUBDIRS=%4

REM �f�t�H���g�l�̐ݒ�
if "%TARGET_PATH%"=="" set TARGET_PATH=C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Log
if "%FILE_EXTENSION%"=="" set FILE_EXTENSION=txt
if "%DAYS_TO_KEEP%"=="" set DAYS_TO_KEEP=7
if "%INCLUDE_SUBDIRS%"=="" set INCLUDE_SUBDIRS=Y

REM ���O�t�@�C���̐ݒ�
set LOG_FILE=%~dp0cleanup_log_%date:~0,4%%date:~5,2%%date:~8,2%.txt

echo =============================================== >> "%LOG_FILE%"
echo �N���[���A�b�v�J�n: %date% %time% >> "%LOG_FILE%"
echo =============================================== >> "%LOG_FILE%"
echo �Ώۃp�X: %TARGET_PATH% >> "%LOG_FILE%"
echo �g���q: %FILE_EXTENSION% >> "%LOG_FILE%"
echo �ۑ�����: %DAYS_TO_KEEP% >> "%LOG_FILE%"
echo �T�u�f�B���N�g���܂�: %INCLUDE_SUBDIRS% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM ���t�v�Z�i�w������O�̓��t���v�Z�j
powershell -Command "(Get-Date).AddDays(-%DAYS_TO_KEEP%).ToString('yyyy-MM-dd')" > temp_date.txt
set /p CUTOFF_DATE=<temp_date.txt
del temp_date.txt

echo �J�b�g�I�t��: %CUTOFF_DATE% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM �t�@�C���폜�̎��s
set DELETE_COUNT=0
set ERROR_COUNT=0

if /i "%INCLUDE_SUBDIRS%"=="Y" (
    set SEARCH_OPTION=/S
) else (
    set SEARCH_OPTION=
)

REM PowerShell���g�p���ăt�@�C���̓��t�`�F�b�N�ƍ폜�����s
powershell -Command "& { ^
    $cutoffDate = [DateTime]'%CUTOFF_DATE%'; ^
    if ('%INCLUDE_SUBDIRS%' -eq 'Y') { $recurse = '-Recurse' } else { $recurse = '' }; ^
    $files = Get-ChildItem -Path '%TARGET_PATH%' -Filter '*.%FILE_EXTENSION%' $recurse ^
        | Where-Object {$_.LastWriteTime -lt $cutoffDate}; ^
    $deleteCount = 0; $errorCount = 0; ^
    foreach ($file in $files) { ^
        try { ^
            Write-Host \"�폜��: $($file.FullName)\"; ^
            Remove-Item $file.FullName -Force; ^
            $deleteCount++; ^
        } catch { ^
            Write-Host \"�G���[: $($file.FullName) - $($_.Exception.Message)\"; ^
            $errorCount++; ^
        } ^
    }; ^
    Write-Host \"�폜����: $deleteCount �t�@�C��\"; ^
    Write-Host \"�G���[: $errorCount �t�@�C��\"; ^
}" >> "%LOG_FILE%" 2>&1

echo. >> "%LOG_FILE%"
echo =============================================== >> "%LOG_FILE%"
echo �N���[���A�b�v�I��: %date% %time% >> "%LOG_FILE%"
echo =============================================== >> "%LOG_FILE%"

REM ���ʂ̕\��
echo �N���[���A�b�v���������܂����B
echo ���O�t�@�C��: %LOG_FILE%
type "%LOG_FILE%"

endlocal
pause