@echo off
setlocal

REM =============================================================================
REM バッチコマンドのみでのファイルクリーンアップ
REM 制限: 日付比較が複雑、サブフォルダ処理が困難
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
echo クリーンアップ開始: %date% %time% >> "%LOG_FILE%"
echo =============================================== >> "%LOG_FILE%"

REM 基準日付の計算（WMIC使用）
for /f "tokens=1-3 delims=/" %%a in ('wmic os get localdatetime /value ^| find "=" ^| for /f "tokens=2 delims==" %%x in ("%%i") do echo %%x') do (
    set TODAY=%%i
)
set TODAY=%TODAY:~0,8%

REM 簡易的な日付計算（30日前固定 - 正確な計算は複雑）
set /a YEAR=%TODAY:~0,4%
set /a MONTH=%TODAY:~4,2%
set /a DAY=%TODAY:~6,2%

REM 日数を引く（月をまたぐ計算は省略）
set /a DAY=%DAY%-%DAYS_TO_KEEP%
if %DAY% LEQ 0 (
    set /a MONTH=%MONTH%-1
    set /a DAY=30
    if %MONTH% LEQ 0 (
        set /a YEAR=%YEAR%-1
        set MONTH=12
    )
)

REM ゼロパディング
if %MONTH% LSS 10 set MONTH=0%MONTH%
if %DAY% LSS 10 set DAY=0%DAY%

set CUTOFF_DATE=%YEAR%%MONTH%%DAY%

echo カットオフ日: %CUTOFF_DATE% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM ファイル削除（サブフォルダなしの場合のみ）
set DELETE_COUNT=0

if /i "%INCLUDE_SUBDIRS%"=="Y" (
    echo サブフォルダ処理はPowerShell版を使用してください >> "%LOG_FILE%"
    goto :EOF
)

for %%f in ("%TARGET_PATH%\*.%FILE_EXTENSION%") do (
    call :CheckAndDelete "%%f"
)

echo 削除完了: %DELETE_COUNT% ファイル >> "%LOG_FILE%"
goto :EOF

:CheckAndDelete
set FILE_PATH=%~1
if not exist %FILE_PATH% goto :EOF

REM ファイル日付取得（WMIC使用）
for /f "tokens=1-3" %%a in ('wmic datafile where "name='%FILE_PATH:\=\\%'" get LastModified /value 2^>nul ^| find "="') do (
    for /f "tokens=2 delims==" %%x in ("%%a") do set FILE_DATE=%%x
)

if not defined FILE_DATE goto :EOF
set FILE_DATE=%FILE_DATE:~0,8%

REM 日付比較（文字列比較 - 制限あり）
if "%FILE_DATE%" LSS "%CUTOFF_DATE%" (
    echo 削除中: %FILE_PATH% >> "%LOG_FILE%"
    del "%FILE_PATH%" 2>nul
    if not exist "%FILE_PATH%" (
        set /a DELETE_COUNT+=1
    ) else (
        echo エラー: %FILE_PATH% >> "%LOG_FILE%"
    )
)
goto :EOF