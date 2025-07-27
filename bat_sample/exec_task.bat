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

rem タスクを実行
echo.
echo タスクを実行しています...
schtasks /Run /TN "%TASK_NAME%" >nul 2>&1
set SCHTASKS_RESULT=!errorlevel!

if !SCHTASKS_RESULT! neq 0 (
    echo エラー: タスクの起動に失敗しました。エラーコード: !SCHTASKS_RESULT!
    if !SCHTASKS_RESULT! equ 1 (
        echo 原因: 指定されたタスクが見つからない可能性があります。
    )
    exit /b !SCHTASKS_RESULT!
)

echo タスクを起動しました。実行完了を待機中...

rem タイムアウト値を秒からカウンタに変換（1秒間隔でチェック）
set /a TIMEOUT_COUNT=%TIMEOUT_SECONDS%
set /a WAIT_COUNT=0

:WAIT_LOOP
rem 1秒待機
timeout /t 1 /nobreak >nul

rem タスクの状態をチェック（詳細表示で取得）
set TASK_STATUS=
set TARGET_LINE=

rem 指定されたタスク名に一致する行を取得
for /f "tokens=*" %%i in ('schtasks /Query /TN "%TASK_NAME%" /V /FO CSV /NH 2^>nul') do (
    set CURRENT_LINE=%%i
    
    rem 2列目のタスク名を確認
    for /f "tokens=2 delims=," %%j in ("!CURRENT_LINE!") do (
        set CHECK_TASKNAME=%%j
        rem ダブルクォート除去
        for /f "delims=" %%k in ("!CHECK_TASKNAME!") do (
            set "CHECK_TASKNAME=%%~k"
        )
        
        rem タスク名が一致する場合
        if "!CHECK_TASKNAME!"=="%TASK_NAME%" (
            set TARGET_LINE=!CURRENT_LINE!
        )
    )
)

if "!TARGET_LINE!"=="" (
    echo エラー: 指定されたタスクの実行履歴が見つかりませんでした。
    exit /b 2
)

rem 最新のタスク行から状態を取得
for /f "tokens=4 delims=," %%b in ("!TARGET_LINE!") do (
    set TASK_STATUS=%%b
)

rem ダブルクォート除去
for /f "delims=" %%a in ("!TASK_STATUS!") do (
    set "TASK_STATUS=%%~a"
)

rem 実行中またはキューに登録済みかどうかを判定
if "!TASK_STATUS!"=="実行中" (
    set /a WAIT_COUNT+=1
    rem タイムアウト値が0の場合は無制限待機
    if !TIMEOUT_COUNT! gtr 0 (
        if !WAIT_COUNT! geq !TIMEOUT_COUNT! (
            echo タイムアウト: タスクがタイムアウト時間内に完了しませんでした。
            exit /b 124
        )
        echo 待機中... ^(!WAIT_COUNT!/!TIMEOUT_COUNT!^) 状態: !TASK_STATUS!
    ) else (
        echo 待機中... ^(!WAIT_COUNT!秒経過^) 状態: !TASK_STATUS!
    )
    goto :WAIT_LOOP
) else if "!TASK_STATUS!"=="キューに登録済み" (
    set /a WAIT_COUNT+=1
    rem タイムアウト値が0の場合は無制限待機
    if !TIMEOUT_COUNT! gtr 0 (
        if !WAIT_COUNT! geq !TIMEOUT_COUNT! (
            echo タイムアウト: タスクがタイムアウト時間内に完了しませんでした。
            exit /b 124
        )
        echo 待機中... ^(!WAIT_COUNT!/!TIMEOUT_COUNT!^) 状態: !TASK_STATUS! ^(実行開始待ち^)
    ) else (
        echo 待機中... ^(!WAIT_COUNT!秒経過^) 状態: !TASK_STATUS! ^(実行開始待ち^)
    )
    goto :WAIT_LOOP
) else (
    rem 準備完了、無効、失敗などの場合
    echo タスク実行完了を検出しました。（状態: !TASK_STATUS!）
    goto :GET_RESULT
)

:GET_RESULT
rem 最新のタスク実行結果を再取得
for /f "tokens=*" %%i in ('schtasks /Query /TN "%TASK_NAME%" /V /FO CSV /NH 2^>nul') do (
    set CURRENT_LINE=%%i
    
    rem 2列目のタスク名を確認
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
    echo エラー: タスク情報を取得できませんでした。
    exit /b 2
)

rem 7列目から前回の実行結果を取得
for /f "tokens=7 delims=," %%a in ("!TARGET_LINE!") do (
    set LAST_RESULT=%%a
)

rem ダブルクォートを除去
for /f "delims=" %%a in ("!LAST_RESULT!") do (
    set "LAST_RESULT=%%~a"
)

rem 数値かどうかを判定
set "NUMERIC_CHECK="
set /a TEST_NUM=!LAST_RESULT! 2>nul
if !errorlevel! equ 0 (
    if !TEST_NUM! equ !LAST_RESULT! (
        set NUMERIC_CHECK=1
    )
)

if "!NUMERIC_CHECK!"=="1" (
    rem 数値の場合
    echo.
    echo タスク実行完了
    echo 最終実行結果: !LAST_RESULT!
    
    rem バッチファイルの戻り値制限（0-255）を適用
    if !LAST_RESULT! gtr 255 (
        echo 注意: 戻り値!LAST_RESULT!は255を超えるため、255に制限されます。
        set LAST_RESULT=255
    )
) else (
    rem 数値でない場合（エラーメッセージなど）は1とする
    echo.
    echo タスク実行完了
    echo 最終実行結果: !LAST_RESULT! ^(数値以外のためエラーとして扱います^)
    set LAST_RESULT=1
)

rem 戻り値を設定
if "!LAST_RESULT!"=="0" (
    echo 正常終了
    exit /b 0
) else (
    echo 異常終了 ^(終了コード: !LAST_RESULT!^)
    exit /b !LAST_RESULT!
)