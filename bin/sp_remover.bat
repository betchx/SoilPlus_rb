@echo off

rem set TARGET_EXT=err f21 f22 f26 f27 f33 f34 f42 f43 f50 f51 f52 f53 f54 f55 f56 f57 f58 f59 f62 f63 f70 f81 f82 f89

rem �㏈���ŗL�p�ȃt�@�C���͍폜���Ȃ��l�ɕύX  (2013/12/11)
rem f21 �O���t�c�[���Ŏ擾����g�`�̌��f�[�^�D ruby����̕ϊ����\�Ȃ��߁C�c���Ă����D
rem f81 f82 : ���X�g�ҏW�v���O�����ŎQ�Ƃ���ꍇ�ɕK�v�D
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