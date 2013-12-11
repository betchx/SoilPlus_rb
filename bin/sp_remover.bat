@echo off

rem set TARGET_EXT=err f21 f22 f26 f27 f33 f34 f42 f43 f50 f51 f52 f53 f54 f55 f56 f57 f58 f59 f62 f63 f70 f81 f82 f89

rem 後処理で有用なファイルは削除しない様に変更  (2013/12/11)
rem f21 グラフツールで取得する波形の元データ． rubyからの変換が可能なため，残しておく．
rem f81 f82 : リスト編集プログラムで参照する場合に必要．
set     TARGET_EXT=err     f22 f26 f27 f33 f34 f42 f43 f50 f51 f52 f53 f54 f55 f56 f57 f58 f59 f62 f63 f70         f89

set BASE=%~dpn1


IF "%~x1"==".err" (if NOT "%~z1"=="0" goto :edit_err )

rem IF NOT "%~x1"==".err" goto :error_exit

FOR %%I IN ( %TARGET_EXT% ) DO (
 SET TGT="%BASE%.%%I"
 call :remove
)
goto :eof

SET TGT="%BASE%_log.csv"
call :remove

goto :eof

:edit_err
start notepad %1
goto :eof

:remove
echo %TGT%
rem pause
IF EXIST %TGT%  del %TGT%
goto :eof