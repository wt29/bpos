@echo off
set CC=C:\borland\bcc55
rem set HB=C:\develop\harbour-core
rem set HB=C:\develop\harbour\HB30
set HB=C:\develop\xharbour\1.2.3


set oldpath=%path%
path=%path%;%cc%\bin;%hb%\bin;%hb%\bin\win\bcc
set include=%cc%\include;%HB%\include;%HB%\obj\b32
set lib=%cc%\lib;%HB%\lib\win\bcc


set HB_ARCHITECTURE=win
set HB_COMPILER=bcc
set HB_GT_LIB=gtwvw

rem hbmk2 -inc -obpos -xhb -arch=win *.prg %HB%\obj\b32\mainwin.obj vm.lib gtwvg.lib tip.lib ct.lib lang.lib vm.lib rtl.lib rdd.lib macro.lib pp.lib dbfntx.lib dbfcdx.lib dbffpt.lib common.lib gtwvw.lib codepage.lib ct.lib tip.lib pcrepos.lib hsx.lib sixcdx.lib zlib.lib

copy makefile.bcc makefile
rem copy mfbcc makefile
hbmake makefile

set path=%oldpath%



