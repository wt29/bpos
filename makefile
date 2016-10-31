#BCC
VERSION=BCB.01
!ifndef CC_DIR
CC_DIR = $(MAKE_DIR)
!endif

!ifndef HB_DIR
HB_DIR = $(HARBOUR_DIR)
!endif
 
RECURSE= NO 
 
SHELL = 
COMPRESS = NO
EXTERNALLIB = NO
XFWH = NO
FILESTOADD =  5
WARNINGLEVEL =  0
USERDEFINE = 
USERINCLUDE = 
USERLIBS = 
EDITOR = notepad
GTWVW = 
CGI = NO
GUI = YES
MT = NO
SRC04 = obj 
PROJECT = bpos.exe $(PR) 
OBJFILES = $(SRC04)\BPOS.obj $(SRC04)\ACME.obj $(SRC04)\APCHEQUE.obj $(SRC04)\APEOM.obj $(SRC04)\APREMIT.obj //
 $(SRC04)\APREP.obj $(SRC04)\APTRAN.obj $(SRC04)\AREOM.obj $(SRC04)\ARREP.obj $(SRC04)\ARSTAT.obj //
 $(SRC04)\ARTRAN.obj $(SRC04)\DPURORD.obj $(SRC04)\ERRORSYS.obj $(SRC04)\FPURORD.obj $(SRC04)\INVFORMS.obj //
 $(SRC04)\MAINCATE.obj $(SRC04)\MAINCUST.obj $(SRC04)\MAINDEPT.obj $(SRC04)\MAINITEM.obj $(SRC04)\MAINSUPP.obj //
 $(SRC04)\PRINTFUNC.obj $(SRC04)\PROCLIB.obj $(SRC04)\PURCKIT.obj $(SRC04)\RECEIVE.obj $(SRC04)\RECLIST.obj //
 $(SRC04)\RECPOST.obj $(SRC04)\RETURNS.obj $(SRC04)\SETUPDBF.obj $(SRC04)\S_APPR.obj $(SRC04)\S_ARCH.obj //
 $(SRC04)\S_CASH.obj $(SRC04)\S_DAILY.obj $(SRC04)\S_INQ1.obj $(SRC04)\S_INQ2.obj $(SRC04)\S_INV1.obj //
 $(SRC04)\S_INV2.obj $(SRC04)\S_LAYB.obj $(SRC04)\S_QUOTE.obj $(SRC04)\S_REPO.obj $(SRC04)\S_SPEC.obj //
 $(SRC04)\UTILARCH.obj $(SRC04)\UTILBACK.obj $(SRC04)\UTILCOND.obj $(SRC04)\UTILLABE.obj $(SRC04)\UTILPACK.obj //
 $(SRC04)\UTILREPR.obj $(SRC04)\UTILSPPA.obj $(SRC04)\UTILSTOC.obj $(OB) 
PRGFILES = BPOS.PRG ACME.PRG APCHEQUE.PRG APEOM.PRG APREMIT.PRG //
 APREP.PRG APTRAN.PRG AREOM.PRG ARREP.PRG ARSTAT.PRG //
 ARTRAN.PRG DPURORD.PRG ERRORSYS.PRG FPURORD.PRG INVFORMS.PRG //
 MAINCATE.PRG MAINCUST.PRG MAINDEPT.PRG MAINITEM.PRG MAINSUPP.PRG //
 PRINTFUNC.PRG PROCLIB.PRG PURCKIT.PRG RECEIVE.PRG RECLIST.PRG //
 RECPOST.PRG RETURNS.PRG SETUPDBF.PRG S_APPR.PRG S_ARCH.PRG //
 S_CASH.PRG S_DAILY.PRG S_INQ1.PRG S_INQ2.PRG S_INV1.PRG //
 S_INV2.PRG S_LAYB.PRG S_QUOTE.PRG S_REPO.PRG S_SPEC.PRG //
 UTILARCH.PRG UTILBACK.PRG UTILCOND.PRG UTILLABE.PRG UTILPACK.PRG //
 UTILREPR.PRG UTILSPPA.PRG UTILSTOC.PRG $(PS) 
OBJCFILES = $(OBC) 
CFILES = $(CF)
RESFILES = BPOS.RES
RESDEPEN = BPOS.RES
TOPMODULE = BPOS.PRG
LIBFILES = lang.lib vm.lib rtl.lib rdd.lib macro.lib pp.lib dbfntx.lib dbfcdx.lib dbffpt.lib common.lib //
           gtwvw.lib codepage.lib ct.lib tip.lib pcrepos.lib hsx.lib hbsix.lib zlib.lib telepath.lib
#LIBFILES = lang.lib vm.lib rtl.lib rdd.lib macro.lib pp.lib dbfcdx.lib common.lib gtwvw.lib codepage.lib ct.lib tip.lib pcrepos.lib hsx.lib zlib.lib
EXTLIBFILES =
DEFFILE = 
HARBOURFLAGS = -w1
CFLAG1 =  -OS $(SHELL)  $(CFLAGS) -d -c -L$(HB_DIR)\lib 
CFLAG2 =  -I$(HB_DIR)\include;$(CC_DIR)\include
RFLAGS = 
LFLAGS = -L$(CC_DIR)\lib\obj;$(CC_DIR)\lib;$(HB_DIR)\lib -Gn -M -m -s -Tpe -x -aa
IFLAGS = 
LINKER = ilink32
 
ALLOBJ = c0w32.obj $(OBJFILES) $(OBJCFILES)
ALLRES = $(RESDEPEN)
ALLLIB = $(USERLIBS) $(LIBFILES) import32.lib cw32.lib
.autodepend
 
#DEPENDS
 
#COMMANDS
.cpp.obj:
$(CC_DIR)\BIN\bcc32 $(CFLAG1) $(CFLAG2) -o$* $**
 
.c.obj:
$(CC_DIR)\BIN\bcc32 -I$(HB_DIR)\include $(CFLAG1) $(CFLAG2) -o$* $**
 
.prg.obj:
$(HB_DIR)\bin\harbour -D__EXPORT__ -n -go -I$(HB_DIR)\include $(HARBOURFLAGS) -o$* $**
 
#.rc.res:
# $(CC_DIR)\BIN\brcc32 $(RFLAGS) $<
 
#BUILD
 
$(PROJECT): $(CFILES) $(OBJFILES) $(RESDEPEN) $(DEFFILE)
    $(CC_DIR)\BIN\$(LINKER) @&&!  
    $(LFLAGS) +
    $(ALLOBJ), +
    $(PROJECT),, +
    $(ALLLIB), +
    $(DEFFILE), +
    $(ALLRES) 
!
