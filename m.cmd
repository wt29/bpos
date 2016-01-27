@echo off

rem set HB_ARCHITECTURE=W32
rem set HB_COMPILER=MSVC
rem set HB_GT_LIB=gtwvg

rem for Multi thread support, un-remark next line
rem set HB_MT=MT

rem nmake
call xm_msvc.cmd
if not exist bpos.exe goto noexe
goto end
:noexe 
echo No executable generated
:end



