@echo off
set VS=C:\Program Files (x86)\Microsoft Visual Studio 9.0
set HB=C:\develop\xharbour\1.20

path=%vs%\vc\bin;%vs%\Common7\ide;C:\Program Files\Microsoft SDKs\Windows\v6.0A\bin;%HB%\bin
set include=%vs%\vc\include;C:\Program Files\Microsoft SDKs\Windows\v6.0A\include
set lib=%vs%\vc\lib;C:\Program Files\Microsoft SDKs\Windows\v6.0A\lib;%HB%\lib

set HB_ARCHITECTURE=w32
set HB_COMPILER=msvc
set HB_GT_LIB=gtwvw

copy makefile.vc makefile /y

nmake

