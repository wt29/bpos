@echo off
set CC=C:\borland\bcc55
set HB=C:\develop\harbour\core
rem set HB=C:\develop\harbour\HB30
rem set HB=C:\develop\xharbour\1.2.3


set oldpath=%path%
path=%path%;%cc%\bin;%hb%\bin;%hb%\bin\win\bcc
rem path=%path%;%cc%\bin;%hb%\bin;%hb%\bin\win\bcc
set include=%cc%\include
set lib=%cc%\lib;%HB%\lib\win\bcc

set HB_ARCHITECTURE=w32
set HB_COMPILER=bcc
set HB_GT_LIB=gtwvg

hbmk2 -obpos *.prg bpos.rc gtwvg.hbc hbtip.hbc xhb.hbc hbct.hbc 
rem hbmk2 -inc -obpos *.prg bpos.rc gtwvg.hbc hbtip.hbc xhb.hbc hbct.hbc 
rem hbmk2 -obpos *.prg bpos.rc hbtip.hbc xhb.hbc hbct.hbc 

::copy makefile.bcc makefile
::hbmake makefile.bcc


set path=%oldpath%



