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
set HB_GT_LIB=gtwin
rem gtwvg

rem hbmk2 -obpos -xhb -arch=win *.prg vm.lib gtwvw.lib ct.lib rdd.lib macro.lib pp.lib dbfntx.lib ^ 
rem	dbfcdx.lib common.lib telepath.lib tip.lib
	

rem	hbmk2 -obpos -inc *.prg gtwin.lib hbtip.hbc xhb.hbc hbct.hbc hbtpathy.lib

rem hbmk2 -inc -obpos *.prg lang.lib vm.lib rtl.lib rdd.lib macro.lib pp.lib dbfntx.lib dbfcdx.lib dbffpt.lib common.lib ^
rem           gtwvw.lib codepage.lib ct.lib tip.lib pcrepos.lib hsx.lib hbsix.lib zlib.lib telepath.lib

rem vm.lib gtwvw.lib %HB%\obj\b32\mainwin.obj dbffpt.lib^
rem     ct.lib lang.lib rtl.lib rdd.lib macro.lib pp.lib dbfntx.lib dbfcdx.lib ^
rem  	common.lib codepage.lib tip.lib pcrepos.lib hsx.lib sixcdx.lib zlib.lib telepath.lib

rem	%HB%\obj\b32\mainwin.obj dbffpt.lib

copy makefile.bcc makefile
hbmake makefile

set path=%oldpath%



