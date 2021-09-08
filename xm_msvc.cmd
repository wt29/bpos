@echo off

set CC=C:\Program Files\Microsoft Visual Studio 9.0\VC
set SDK=C:\Program Files\Microsoft SDKs\Windows\v6.0A
set HB=C:\develop\xharbour\1.20

call %CC%\vcvarsall.bat

set oldpath=%path%
set oldinc=%include%
set oldlib=%lib%

path=%path%;%cc%\bin;%cc%\Common7\ide;%SDK%\bin;%HB%
set include=%include%;%cc%\include;C:\Program Files\Microsoft SDKs\Windows\v6.0A\include
set lib=%HB%\lib;%cc%\lib;%SDK%\lib

set HB_ARCHITECTURE=w32
set HB_COMPILER=msvc
set HB_GT_LIB=gtwvw

copy makefile.vc makefile

nmake

set path=%oldpath%
set include=%oldinc%
set lib=%oldlib%


