@echo off
setlocal

REM =============================================================================
REM SQL Server メンテナンスプラン レポートクリーンアップ バッチファイル
REM =============================================================================

REM パラメータの設定
set TARGET_PATH=%1
set FILE_EXTENSION=%2
set DAYS_TO_KEEP=%3
set INCLUDE_SUBDIRS=%4

REM デフォルト値の設定
if "%TARGET_PATH%"=="" set TARGET_PATH=C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Log
if "%FILE_EXTENSION%"=="" set FILE_EXTENSION=txt
if "%DAYS_TO_KEEP%"=="" set DAYS_TO_KEEP=7
if "%INCLUDE_SUBDIRS%"=="" set INCLUDE_SUBDIRS=Y

REM ログファイルの設定
set LOG_FILE=%~dp0cleanup_log_%date:~0,4%%date:~5,2%%date:~8,2%.txt

echo =============================================== >> "%LOG_FILE%"
echo クリーンアップ開始: %date% %time% >> "%LOG_FILE%"
echo =============================================== >> "%LOG_FILE%"
echo 対象パス: %TARGET_PATH% >> "%LOG_FILE%"
echo 拡張子: %FILE_EXTENSION% >> "%LOG_FILE%"
echo 保存日数: %DAYS_TO_KEEP% >> "%LOG_FILE%"
echo サブディレクトリ含む: %INCLUDE_SUBDIRS% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM 日付計算（指定日数前の日付を計算）
powershell -Command "(Get-Date).AddDays(-%DAYS_TO_KEEP%).ToString('yyyy-MM-dd')" > temp_date.txt
set /p CUTOFF_DATE=<temp_date.txt
del temp_date.txt

echo カットオフ日: %CUTOFF_DATE% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM ファイル削除の実行
set DELETE_COUNT=0
set ERROR_COUNT=0

if /i "%INCLUDE_SUBDIRS%"=="Y" (
    set SEARCH_OPTION=/S
) else (
    set SEARCH_OPTION=
)

REM PowerShellを使用してファイルの日付チェックと削除を実行
powershell -Command "& { ^
    $cutoffDate = [DateTime]'%CUTOFF_DATE%'; ^
    if ('%INCLUDE_SUBDIRS%' -eq 'Y') { $recurse = '-Recurse' } else { $recurse = '' }; ^
    $files = Get-ChildItem -Path '%TARGET_PATH%' -Filter '*.%FILE_EXTENSION%' $recurse ^
        | Where-Object {$_.LastWriteTime -lt $cutoffDate}; ^
    $deleteCount = 0; $errorCount = 0; ^
    foreach ($file in $files) { ^
        try { ^
            Write-Host \"削除中: $($file.FullName)\"; ^
            Remove-Item $file.FullName -Force; ^
            $deleteCount++; ^
        } catch { ^
            Write-Host \"エラー: $($file.FullName) - $($_.Exception.Message)\"; ^
            $errorCount++; ^
        } ^
    }; ^
    Write-Host \"削除完了: $deleteCount ファイル\"; ^
    Write-Host \"エラー: $errorCount ファイル\"; ^
}" >> "%LOG_FILE%" 2>&1

echo. >> "%LOG_FILE%"
echo =============================================== >> "%LOG_FILE%"
echo クリーンアップ終了: %date% %time% >> "%LOG_FILE%"
echo =============================================== >> "%LOG_FILE%"

REM 結果の表示
echo クリーンアップが完了しました。
echo ログファイル: %LOG_FILE%
type "%LOG_FILE%"

endlocal
pause