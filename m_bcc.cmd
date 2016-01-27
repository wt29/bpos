@echo off
set CC=C:\borland\bcc55
rem set HB=C:\develop\harbour-core
rem set HB=C:\develop\harbour\HB30
set HB=C:\develop\xharbour\1.2.3


set oldpath=%path%
path=%path%;%cc%\bin;%hb%\bin;%hb%\bin\win\bcc
set include=%cc%\include
set lib=%cc%\lib;%HB%\lib\win\bcc

set HB_ARCHITECTURE=w32
set HB_COMPILER=bcc
set HB_GT_LIB=gtwvg

rem hbmk2 -inc -obpos *.prg bpos.rc gtwvg.hbc hbtip.hbc xhb.hbc hbct.hbc 

rem copy makefile.bcc makefile
hbmake makefile.bcc


set path=%oldpath%



