@echo off
set CC=C:\borland\bcc55
rem set HB=C:\develop\harbour-core
rem set HB=C:\develop\harbour\HB30
set HB=C:\develop\xharbour\1.2.3


set oldpath=%path%
path=%path%;%cc%\bin;%hb%\bin;%hb%\bin\win\bcc
set include=%cc%\include;%HB%\include
set lib=%cc%\lib;%HB%\lib\win\bcc

set HB_ARCHITECTURE=w32
set HB_COMPILER=bcc
set HB_GT_LIB=gtwvw

rem hbmk2 -inc -obpos *.prg gtwvg.hbc hbtip.hbc xhb.hbc hbct.hbc
rem copy makefile.bcc makefile
copy mfbcc makefile

hbmake makefile

set path=%oldpath%



