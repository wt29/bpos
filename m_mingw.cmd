@echo off

set HB_ARCHITECTURE=w32
set HB_COMPILER=mingw
set HB_GT_LIB=gtwvg
:: set HB_GT_LIB=gtwvw

set CC=C:\MinGw
set HB=C:\develop\harbour\34\bin\win\mingw
rem set HB=C:\develop\harbour\core
rem set HB=C:\develop\harbour\HB30
rem set HB=C:\develop\xharbour\1.2.3


set oldpath=%path%
path=%path%;%cc%\bin;%hb%;%hb%\bin\win\mingw
set include=%cc%\include
set lib=%cc%\lib;%HB%\lib\win\%HB_COMPILER

rem hbmk2 -obpos *.prg bpos.rc hbtip.hbc xhb.hbc hbct.hbc 
hbmk2 -inc -obpos *.prg bpos.rc hbtip.hbc xhb.hbc hbct.hbc hbtpathy.hbc gtwvg.hbc

::copy makefile.bcc makefile
::hbmake makefile.bcc

set path=%oldpath%



