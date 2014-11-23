@echo off

set HB_ARCHITECTURE=w32
set HB_COMPILER=bcc
set HB_GT_LIB=gtwvt

hbmk2 -obpos *.prg gtwvt.hbc hbtip.hbc xhb.hbc hbct.hbc

