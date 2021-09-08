@echo off
path=%path%;C:\Program Files\Microsoft Visual Studio 9.0\VC\bin;C:\Program Files\Microsoft Visual Studio 9.0\Common7\ide;C:\Program Files\Microsoft SDKs\Windows\v6.0A\bin;c:\xharbour\bin
set include=%include%;C:\Program Files\Microsoft Visual Studio 9.0\VC\include;C:\Program Files\Microsoft SDKs\Windows\v6.0A\include
set lib=%lib%;C:\Program Files\Microsoft Visual Studio 9.0\VC\lib;C:\Program Files\Microsoft SDKs\Windows\v6.0A\lib;c:\xharbour\lib

set HB_ARCHITECTURE=w32
set HB_COMPILER=msvc
set HB_GT_LIB=gtwvw
nmake
