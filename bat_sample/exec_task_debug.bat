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
echo ���s�R�}���h: schtasks /Run /TN "%TASK_NAME%"
schtasks /Run /TN "%TASK_NAME%" >nul 2>&1
set SCHTASKS_RESULT=!errorlevel!

echo �f�o�b�O: schtasks���s���� = !SCHTASKS_RESULT!

if !SCHTASKS_RESULT! neq 0 (
    echo �G���[: �^�X�N�̋N���Ɏ��s���܂����B�G���[�R�[�h: !SCHTASKS_RESULT!
    rem �^�X�N�����݂��Ȃ��ꍇ�Ȃǂ̃G���[
    if !SCHTASKS_RESULT! equ 1 (
        echo ����: �w�肳�ꂽ�^�X�N��������Ȃ��\��������܂��B
    )
    exit /b !SCHTASKS_RESULT!
) else (
    echo �^�X�N�̎��s�R�}���h������Ɋ������܂����B
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
set LAST_EXEC_TIME=
set LAST_RESULT_RAW=

rem �w�b�_�[�t����CSV�\�����m�F
rem echo �f�o�b�O: �ڍ�CSV�\���m�F
rem schtasks /Query /TN "%TASK_NAME%" /V /FO CSV | findstr /n "."

rem echo.
echo �Ώۃ^�X�N�̏ڍ׏����擾��...

rem �ڍ׏��Ń^�X�N�����擾���A�ŐV�̎��s�����
set LATEST_TIME=
set TARGET_LINE=

rem �w�肳�ꂽ�^�X�N���Ɉ�v����s��S�Ď擾
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
            rem echo �f�o�b�O: ��v����^�X�N�s = !CURRENT_LINE!
            
            rem 6��ڂ̑O����s�������擾
            for /f "tokens=6 delims=," %%m in ("!CURRENT_LINE!") do (
                set EXEC_TIME=%%m
                rem �_�u���N�H�[�g����
                for /f "delims=" %%n in ("!EXEC_TIME!") do (
                    set "EXEC_TIME=%%~n"
                )
                
                rem echo �f�o�b�O: ���s���� = !EXEC_TIME!
                
                rem �ŐV�̎��s�������`�F�b�N�i�ȈՓI�ɕ������r�j
                if "!LATEST_TIME!"=="" (
                    set LATEST_TIME=!EXEC_TIME!
                    set TARGET_LINE=!CURRENT_LINE!
                ) else (
                    rem ���V���������̏ꍇ�͍X�V�i�ڍׂȎ�����r�͏ȗ��j
                    set TARGET_LINE=!CURRENT_LINE!
                    set LATEST_TIME=!EXEC_TIME!
                )
            )
        )
    )
)

if "!TARGET_LINE!"=="" (
    echo �G���[: �w�肳�ꂽ�^�X�N�̎��s������������܂���ł����B
    exit /b 2
)

echo �f�o�b�O: �ŐV�̃^�X�N�s = !TARGET_LINE!

rem �ŐV�̃^�X�N�s����e�����擾
for /f "tokens=2,4,6,7 delims=," %%a in ("!TARGET_LINE!") do (
    set TASK_NAME_CHECK=%%a
    set TASK_STATUS=%%b
    set LAST_EXEC_TIME=%%c
    set LAST_RESULT_RAW=%%d
)

rem �_�u���N�H�[�g����
for /f "delims=" %%a in ("!TASK_STATUS!") do (
    set "TASK_STATUS=%%~a"
)
for /f "delims=" %%a in ("!LAST_RESULT_RAW!") do (
    set "LAST_RESULT_RAW=%%~a"
)

echo �f�o�b�O: �擾������� = !TASK_STATUS!
rem echo �f�o�b�O: �擾�����O��̌��ʁi���f�[�^�j = !LAST_RESULT_RAW!

rem �_�u���N�H�[�g������
for /f "delims=" %%a in ("!TASK_STATUS!") do (
    set "TASK_STATUS=%%~a"
)

echo �f�o�b�O: �擾������ԁi�N�H�[�g������j = !TASK_STATUS!

rem ���s���܂��̓L���[�ɑ}���ς݂��ǂ����𔻒�
if "!TASK_STATUS!"=="���s��" (
    rem ���s���̏ꍇ
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
) else if "!TASK_STATUS!"=="�L���[�ɑ}���ς�" (
    rem �L���[�ɑ}���ς݂̏ꍇ���ҋ@
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
echo.
echo �ŏI���s���ʂ��擾��...

rem �ēx�ŐV�̃^�X�N�����擾
set TARGET_LINE=
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

echo �f�o�b�O: �ŏI���s���ʁi���f�[�^�j = [!LAST_RESULT!]

rem ���l���ǂ����𔻒�i���m���ȕ��@�j
set "NUMERIC_CHECK="

rem ���@1: �Z�p���Z�Ő��l����
set /a TEST_NUM=!LAST_RESULT! 2>nul
if !errorlevel! equ 0 (
    if !TEST_NUM! equ !LAST_RESULT! (
        set NUMERIC_CHECK=1
        echo �f�o�b�O: �Z�p���Z�Ő��l�Ɣ��肳��܂���
    ) else (
        echo �f�o�b�O: �Z�p���Z�Ő��l�ł͂Ȃ��Ɣ��肳��܂����i�l���ω��j
    )
) else (
    echo �f�o�b�O: �Z�p���Z�ŃG���[���������܂���
)

echo �f�o�b�O: NUMERIC_CHECK = [!NUMERIC_CHECK!]

if "!NUMERIC_CHECK!"=="1" (
    rem ���l�̏ꍇ
    echo �^�X�N���s����
    echo �ŏI���s����: !LAST_RESULT!
    
    rem �o�b�`�t�@�C���̖߂�l�����i0-255�j��K�p
    if !LAST_RESULT! gtr 255 (
        echo ����: �߂�l!LAST_RESULT!��255�𒴂��邽�߁A255�ɐ�������܂��B
        set LAST_RESULT=255
    )
) else (
    rem ���l�łȂ��ꍇ�i�G���[���b�Z�[�W�Ȃǁj��1�Ƃ���
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
    rem 16�i���̏ꍇ�̕ϊ��i0x80041315�Ȃǁj
    if "!LAST_RESULT:~0,2!"=="0x" (
        rem 16�i���̏ꍇ��1��Ԃ��i�ȗ����j
        exit /b 1
    ) else (
        rem 10�i���̏ꍇ�͂��̂܂ܕԂ��i�������Abat�̐����ɂ��0-255�͈̔́j
        if !LAST_RESULT! gtr 255 set LAST_RESULT=1
        exit /b !LAST_RESULT!
    )
)