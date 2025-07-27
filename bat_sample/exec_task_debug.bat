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
echo 実行コマンド: schtasks /Run /TN "%TASK_NAME%"
schtasks /Run /TN "%TASK_NAME%" >nul 2>&1
set SCHTASKS_RESULT=!errorlevel!

echo デバッグ: schtasks実行結果 = !SCHTASKS_RESULT!

if !SCHTASKS_RESULT! neq 0 (
    echo エラー: タスクの起動に失敗しました。エラーコード: !SCHTASKS_RESULT!
    rem タスクが存在しない場合などのエラー
    if !SCHTASKS_RESULT! equ 1 (
        echo 原因: 指定されたタスクが見つからない可能性があります。
    )
    exit /b !SCHTASKS_RESULT!
) else (
    echo タスクの実行コマンドが正常に完了しました。
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
set LAST_EXEC_TIME=
set LAST_RESULT_RAW=

rem ヘッダー付きでCSV構造を確認
rem echo デバッグ: 詳細CSV構造確認
rem schtasks /Query /TN "%TASK_NAME%" /V /FO CSV | findstr /n "."

rem echo.
echo 対象タスクの詳細情報を取得中...

rem 詳細情報でタスク情報を取得し、最新の実行を特定
set LATEST_TIME=
set TARGET_LINE=

rem 指定されたタスク名に一致する行を全て取得
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
            rem echo デバッグ: 一致するタスク行 = !CURRENT_LINE!
            
            rem 6列目の前回実行時刻を取得
            for /f "tokens=6 delims=," %%m in ("!CURRENT_LINE!") do (
                set EXEC_TIME=%%m
                rem ダブルクォート除去
                for /f "delims=" %%n in ("!EXEC_TIME!") do (
                    set "EXEC_TIME=%%~n"
                )
                
                rem echo デバッグ: 実行時刻 = !EXEC_TIME!
                
                rem 最新の実行時刻かチェック（簡易的に文字列比較）
                if "!LATEST_TIME!"=="" (
                    set LATEST_TIME=!EXEC_TIME!
                    set TARGET_LINE=!CURRENT_LINE!
                ) else (
                    rem より新しい時刻の場合は更新（詳細な時刻比較は省略）
                    set TARGET_LINE=!CURRENT_LINE!
                    set LATEST_TIME=!EXEC_TIME!
                )
            )
        )
    )
)

if "!TARGET_LINE!"=="" (
    echo エラー: 指定されたタスクの実行履歴が見つかりませんでした。
    exit /b 2
)

echo デバッグ: 最新のタスク行 = !TARGET_LINE!

rem 最新のタスク行から各情報を取得
for /f "tokens=2,4,6,7 delims=," %%a in ("!TARGET_LINE!") do (
    set TASK_NAME_CHECK=%%a
    set TASK_STATUS=%%b
    set LAST_EXEC_TIME=%%c
    set LAST_RESULT_RAW=%%d
)

rem ダブルクォート除去
for /f "delims=" %%a in ("!TASK_STATUS!") do (
    set "TASK_STATUS=%%~a"
)
for /f "delims=" %%a in ("!LAST_RESULT_RAW!") do (
    set "LAST_RESULT_RAW=%%~a"
)

echo デバッグ: 取得した状態 = !TASK_STATUS!
rem echo デバッグ: 取得した前回の結果（生データ） = !LAST_RESULT_RAW!

rem ダブルクォートを除去
for /f "delims=" %%a in ("!TASK_STATUS!") do (
    set "TASK_STATUS=%%~a"
)

echo デバッグ: 取得した状態（クォート除去後） = !TASK_STATUS!

rem 実行中またはキューに挿入済みかどうかを判定
if "!TASK_STATUS!"=="実行中" (
    rem 実行中の場合
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
) else if "!TASK_STATUS!"=="キューに挿入済み" (
    rem キューに挿入済みの場合も待機
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
echo.
echo 最終実行結果を取得中...

rem 再度最新のタスク情報を取得
set TARGET_LINE=
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

echo デバッグ: 最終実行結果（生データ） = [!LAST_RESULT!]

rem 数値かどうかを判定（より確実な方法）
set "NUMERIC_CHECK="

rem 方法1: 算術演算で数値判定
set /a TEST_NUM=!LAST_RESULT! 2>nul
if !errorlevel! equ 0 (
    if !TEST_NUM! equ !LAST_RESULT! (
        set NUMERIC_CHECK=1
        echo デバッグ: 算術演算で数値と判定されました
    ) else (
        echo デバッグ: 算術演算で数値ではないと判定されました（値が変化）
    )
) else (
    echo デバッグ: 算術演算でエラーが発生しました
)

echo デバッグ: NUMERIC_CHECK = [!NUMERIC_CHECK!]

if "!NUMERIC_CHECK!"=="1" (
    rem 数値の場合
    echo タスク実行完了
    echo 最終実行結果: !LAST_RESULT!
    
    rem バッチファイルの戻り値制限（0-255）を適用
    if !LAST_RESULT! gtr 255 (
        echo 注意: 戻り値!LAST_RESULT!は255を超えるため、255に制限されます。
        set LAST_RESULT=255
    )
) else (
    rem 数値でない場合（エラーメッセージなど）は1とする
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