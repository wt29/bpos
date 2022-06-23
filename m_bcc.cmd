@echo off

set HB_ARCHITECTURE=w32
set HB_COMPILER=mingw
rem set HB_GT_LIB=gtwvg
set HB_GT_LIB=gtwin

set CC=C:\MinGw
rem set CC=C:\borland\bcc55
set HB=C:\develop\harbour\core
rem set HB=C:\develop\harbour\HB30
rem set HB=C:\develop\xharbour\1.2.3


set oldpath=%path%
path=%path%;%cc%\bin;%hb%\bin;%hb%\bin\win\mingw
rem path=%path%;%cc%\bin;%hb%\bin;%hb%\bin\win\bcc
rem path=%path%;%cc%\bin;%hb%\bin;%hb%\bin\win\bcc
set include=%cc%\include
set lib=%cc%\lib;%HB%\lib\win\%HB_COMPILER


rem hbmk2 -obpos *.prg bpos.rc hbtip.hbc xhb.hbc hbct.hbc hbtpathy.hbc gtwvw.hbc
hbmk2 -inc -obpos *.prg bpos.rc gtwvg.hbc hbtip.hbc xhb.hbc hbct.hbc hbtpathy.hbc
rem hbmk2 -obpos *.prg bpos.rc hbtip.hbc xhb.hbc hbct.hbc 

::copy makefile.bcc makefile
::hbmake makefile.bcc


rem set path=%oldpath%



