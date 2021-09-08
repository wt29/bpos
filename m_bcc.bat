@echo off

path=%path%;c:\borland\Bcc55\bin;C:\xharbour.bcc\bin
set include=C:\Borland\BCC55\include;C:\xharbour.bcc\include
set lib=C:\Borland\BCC55\lib;C:\xharbour.bcc\lib;C:\xharbour.bcc\lib\psdk
set mybcdir=C:\Borland\BCC55\bin
set hdir=C:\xharbour.bcc
set bcdir=C:\Borland\BCC55
set bcc_dir=%bcdir%

set HB_ARCHITECTURE=w32
set HB_COMPILER=bcc32
set HB_GT_LIB=gtwin

rem for Multi thread support, un-remark next line
rem set HB_MT=MT

set CFLAGS=-DHB_FM_STATISTICS_OFF -d -OS -O2 -5

copy makefile.bcc makefile /y

del bpos.exe
make
if not exist bpos.exe goto noexe
rem bpos c:\bpos\
goto end
:noexe 
echo No executable generated
:end


