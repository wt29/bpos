@echo off

set HB_ARCHITECTURE=w32
set HB_COMPILER=bcc
:: set HB_GT_LIB=gtwvw
set HB_GT_LIB=gtwvg

set CC=C:\borland\bcc55
set HB=C:\develop\harbour\core
rem set HB=C:\develop\harbour\HB30
rem set HB=C:\develop\xharbour\1.2.3

set oldpath=%path%
path=%path%;%cc%\bin;%hb%\bin\win\bcc
set include=%cc%\include
set lib=%cc%\lib;%HB%\lib\win\%HB_COMPILER%

:: hbmk2 -obpos *.prg bpos.rc gtwvg.hbc hbtip.hbc xhb.hbc hbct.hbc hbtpathy.hbc 
hbmk2 -obpos *.prg bpos.rc gtwvg.hbc hbtip.hbc xhb.hbc hbct.hbc hbtpathy.hbc 

rem set path=%oldpath%



