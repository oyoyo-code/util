@echo off
setlocal enabledelayedexpansion

rem ========================================
rem �^�X�N�X�P�W���[���̃^�X�N�����s����o�b�`
rem ========================================
rem ����1: �^�X�N��
rem ����2: �^�C���A�E�g�l�i�b�j
rem �߂�l: �^�X�N�����s����bat�̖߂�l
rem ========================================

rem �����`�F�b�N
if "%~1"=="" (
    echo �G���[: �^�X�N�����w�肳��Ă��܂���B
    echo �g�p���@: %~nx0 ^<�^�X�N��^> ^<�^�C���A�E�g�l�i�b�j^>
    exit /b 1
)

if "%~2"=="" (
    echo �G���[: �^�C���A�E�g�l���w�肳��Ă��܂���B
    echo �g�p���@: %~nx0 ^<�^�X�N��^> ^<�^�C���A�E�g�l�i�b�j^>
    exit /b 1
)

set TASK_NAME=%~1
set TIMEOUT_SECONDS=%~2

rem ���l�`�F�b�N
echo %TIMEOUT_SECONDS%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo �G���[: �^�C���A�E�g�l�͐��l�Ŏw�肵�Ă��������B
    exit /b 1
)

echo �^�X�N��: %TASK_NAME%
echo �^�C���A�E�g: %TIMEOUT_SECONDS%�b

rem �^�X�N�����s
echo.
echo �^�X�N�����s���Ă��܂�...
schtasks /Run /TN "%TASK_NAME%" >nul 2>&1
set SCHTASKS_RESULT=!errorlevel!

if !SCHTASKS_RESULT! neq 0 (
    echo �G���[: �^�X�N�̋N���Ɏ��s���܂����B�G���[�R�[�h: !SCHTASKS_RESULT!
    if !SCHTASKS_RESULT! equ 1 (
        echo ����: �w�肳�ꂽ�^�X�N��������Ȃ��\��������܂��B
    )
    exit /b !SCHTASKS_RESULT!
)

echo �^�X�N���N�����܂����B���s������ҋ@��...

rem �^�C���A�E�g�l��b����J�E���^�ɕϊ��i1�b�Ԋu�Ń`�F�b�N�j
set /a TIMEOUT_COUNT=%TIMEOUT_SECONDS%
set /a WAIT_COUNT=0

:WAIT_LOOP
rem 1�b�ҋ@
timeout /t 1 /nobreak >nul

rem �^�X�N�̏�Ԃ��`�F�b�N�i�ڍו\���Ŏ擾�j
set TASK_STATUS=
set TARGET_LINE=

rem �w�肳�ꂽ�^�X�N���Ɉ�v����s���擾
for /f "tokens=*" %%i in ('schtasks /Query /TN "%TASK_NAME%" /V /FO CSV /NH 2^>nul') do (
    set CURRENT_LINE=%%i
    
    rem 2��ڂ̃^�X�N�����m�F
    for /f "tokens=2 delims=," %%j in ("!CURRENT_LINE!") do (
        set CHECK_TASKNAME=%%j
        rem �_�u���N�H�[�g����
        for /f "delims=" %%k in ("!CHECK_TASKNAME!") do (
            set "CHECK_TASKNAME=%%~k"
        )
        
        rem �^�X�N������v����ꍇ
        if "!CHECK_TASKNAME!"=="%TASK_NAME%" (
            set TARGET_LINE=!CURRENT_LINE!
        )
    )
)

if "!TARGET_LINE!"=="" (
    echo �G���[: �w�肳�ꂽ�^�X�N�̎��s������������܂���ł����B
    exit /b 2
)

rem �ŐV�̃^�X�N�s�����Ԃ��擾
for /f "tokens=4 delims=," %%b in ("!TARGET_LINE!") do (
    set TASK_STATUS=%%b
)

rem �_�u���N�H�[�g����
for /f "delims=" %%a in ("!TASK_STATUS!") do (
    set "TASK_STATUS=%%~a"
)

rem ���s���܂��̓L���[�ɓo�^�ς݂��ǂ����𔻒�
if "!TASK_STATUS!"=="���s��" (
    set /a WAIT_COUNT+=1
    rem �^�C���A�E�g�l��0�̏ꍇ�͖������ҋ@
    if !TIMEOUT_COUNT! gtr 0 (
        if !WAIT_COUNT! geq !TIMEOUT_COUNT! (
            echo �^�C���A�E�g: �^�X�N���^�C���A�E�g���ԓ��Ɋ������܂���ł����B
            exit /b 124
        )
        echo �ҋ@��... ^(!WAIT_COUNT!/!TIMEOUT_COUNT!^) ���: !TASK_STATUS!
    ) else (
        echo �ҋ@��... ^(!WAIT_COUNT!�b�o��^) ���: !TASK_STATUS!
    )
    goto :WAIT_LOOP
) else if "!TASK_STATUS!"=="�L���[�ɓo�^�ς�" (
    set /a WAIT_COUNT+=1
    rem �^�C���A�E�g�l��0�̏ꍇ�͖������ҋ@
    if !TIMEOUT_COUNT! gtr 0 (
        if !WAIT_COUNT! geq !TIMEOUT_COUNT! (
            echo �^�C���A�E�g: �^�X�N���^�C���A�E�g���ԓ��Ɋ������܂���ł����B
            exit /b 124
        )
        echo �ҋ@��... ^(!WAIT_COUNT!/!TIMEOUT_COUNT!^) ���: !TASK_STATUS! ^(���s�J�n�҂�^)
    ) else (
        echo �ҋ@��... ^(!WAIT_COUNT!�b�o��^) ���: !TASK_STATUS! ^(���s�J�n�҂�^)
    )
    goto :WAIT_LOOP
) else (
    rem ���������A�����A���s�Ȃǂ̏ꍇ
    echo �^�X�N���s���������o���܂����B�i���: !TASK_STATUS!�j
    goto :GET_RESULT
)

:GET_RESULT
rem �ŐV�̃^�X�N���s���ʂ��Ď擾
for /f "tokens=*" %%i in ('schtasks /Query /TN "%TASK_NAME%" /V /FO CSV /NH 2^>nul') do (
    set CURRENT_LINE=%%i
    
    rem 2��ڂ̃^�X�N�����m�F
    for /f "tokens=2 delims=," %%j in ("!CURRENT_LINE!") do (
        set CHECK_TASKNAME=%%j
        for /f "delims=" %%k in ("!CHECK_TASKNAME!") do (
            set "CHECK_TASKNAME=%%~k"
        )
        
        if "!CHECK_TASKNAME!"=="%TASK_NAME%" (
            set TARGET_LINE=!CURRENT_LINE!
        )
    )
)

if "!TARGET_LINE!"=="" (
    echo �G���[: �^�X�N�����擾�ł��܂���ł����B
    exit /b 2
)

rem 7��ڂ���O��̎��s���ʂ��擾
for /f "tokens=7 delims=," %%a in ("!TARGET_LINE!") do (
    set LAST_RESULT=%%a
)

rem �_�u���N�H�[�g������
for /f "delims=" %%a in ("!LAST_RESULT!") do (
    set "LAST_RESULT=%%~a"
)

rem ���l���ǂ����𔻒�
set "NUMERIC_CHECK="
set /a TEST_NUM=!LAST_RESULT! 2>nul
if !errorlevel! equ 0 (
    if !TEST_NUM! equ !LAST_RESULT! (
        set NUMERIC_CHECK=1
    )
)

if "!NUMERIC_CHECK!"=="1" (
    rem ���l�̏ꍇ
    echo.
    echo �^�X�N���s����
    echo �ŏI���s����: !LAST_RESULT!
    
    rem �o�b�`�t�@�C���̖߂�l�����i0-255�j��K�p
    if !LAST_RESULT! gtr 255 (
        echo ����: �߂�l!LAST_RESULT!��255�𒴂��邽�߁A255�ɐ�������܂��B
        set LAST_RESULT=255
    )
) else (
    rem ���l�łȂ��ꍇ�i�G���[���b�Z�[�W�Ȃǁj��1�Ƃ���
    echo.
    echo �^�X�N���s����
    echo �ŏI���s����: !LAST_RESULT! ^(���l�ȊO�̂��߃G���[�Ƃ��Ĉ����܂�^)
    set LAST_RESULT=1
)

rem �߂�l��ݒ�
if "!LAST_RESULT!"=="0" (
    echo ����I��
    exit /b 0
) else (
    echo �ُ�I�� ^(�I���R�[�h: !LAST_RESULT!^)
    exit /b !LAST_RESULT!
)