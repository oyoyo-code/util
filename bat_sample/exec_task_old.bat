@echo off
setlocal enabledelayedexpansion

rem ========================================
rem タスクスケジューラのタスクを実行するバッチ
rem ========================================
rem 引数1: タスク名
rem 引数2: タイムアウト値（秒）
rem 戻り値: タスクが実行したbatの戻り値
rem ========================================

rem 引数チェック
if "%~1"=="" (
    echo エラー: タスク名が指定されていません。
    echo 使用方法: %~nx0 ^<タスク名^> ^<タイムアウト値（秒）^>
    exit /b 1
)

if "%~2"=="" (
    echo エラー: タイムアウト値が指定されていません。
    echo 使用方法: %~nx0 ^<タスク名^> ^<タイムアウト値（秒）^>
    exit /b 1
)

set TASK_NAME=%~1
set TIMEOUT_SECONDS=%~2

rem 数値チェック
echo %TIMEOUT_SECONDS%| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo エラー: タイムアウト値は数値で指定してください。
    exit /b 1
)

echo タスク名: %TASK_NAME%
echo タイムアウト: %TIMEOUT_SECONDS%秒

rem タスクを同期実行
echo.
echo タスクを実行しています...
schtasks /Run /TN "%TASK_NAME%" /Wait >nul 2>&1
set SCHTASKS_RESULT=!errorlevel!

if !SCHTASKS_RESULT! neq 0 (
    echo エラー: タスクの実行に失敗しました。エラーコード: !SCHTASKS_RESULT!
    rem タスクが存在しない場合などのエラー
    if !SCHTASKS_RESULT! equ 1 (
        echo 原因: 指定されたタスクが見つからない可能性があります。
    )
    exit /b !SCHTASKS_RESULT!
)

rem タスクの最後の実行結果を取得
for /f "tokens=*" %%i in ('schtasks /Query /TN "%TASK_NAME%" /FO CSV /NH 2^>nul ^| findstr /c:"%TASK_NAME%"') do (
    set TASK_INFO=%%i
)

if "!TASK_INFO!"=="" (
    echo エラー: タスク情報を取得できませんでした。
    exit /b 2
)

rem CSVの最後のフィールド（Last Result）を取得
for /f "tokens=9 delims=," %%a in ("!TASK_INFO!") do (
    set LAST_RESULT=%%~a
)

rem ダブルクォートを除去
set LAST_RESULT=!LAST_RESULT:"=!

echo.
echo タスク実行完了
echo 最終実行結果: !LAST_RESULT!

rem 戻り値を設定
if "!LAST_RESULT!"=="0" (
    echo 正常終了
    exit /b 0
) else (
    echo 異常終了 ^(終了コード: !LAST_RESULT!^)
    rem 16進数の場合の変換（0x80041315など）
    if "!LAST_RESULT:~0,2!"=="0x" (
        rem 16進数の場合は1を返す（簡略化）
        exit /b 1
    ) else (
        rem 10進数の場合はそのまま返す（ただし、batの制限により0-255の範囲）
        if !LAST_RESULT! gtr 255 set LAST_RESULT=1
        exit /b !LAST_RESULT!
    )
)
