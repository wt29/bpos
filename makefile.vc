VERSION=BCB.01
CC_DIR = C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC
HB_DIR = c:\develop\xharbour\1.20
 
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
EDITOR = edit
GTWVW = YES
GUI = YES
MT = NO
SRC09 = 
CF = CFiles
PROJECT = bpos.exe $(PR)

PRGFILES = bpos.prg proclib.prg Setupdbf.prg \
 acme.prg Apcheque.prg Apeom.prg Apremit.prg Aprep.prg Aptran.prg Areom.prg Arrep.prg Arstat.prg Artran.prg \
 Dpurord.prg Errorsys.prg Fpurord.prg Invforms.prg \
 Maincate.prg Maincust.prg Maindept.prg Mainsupp.prg Mainitem.prg \
 Receive.prg Reclist.prg Recpost.prg Returns.prg \
 Utilarch.prg Utilback.prg Utilcond.prg Utillabe.prg Utilpack.prg Utilsppa.prg Utilstoc.prg \
 s_appr.prg s_arch.prg s_cash.prg s_daily.prg s_inq1.prg s_inq2.prg s_inv1.prg s_inv2.prg s_layb.prg s_repo.prg s_spec.prg \
 PrintFunc.prg s_quote.prg

CFILES = bpos.c proclib.c setupdbf.c\
 acme.c Apcheque.c Apeom.c Apremit.c Aprep.c Aptran.c Areom.c Arrep.c Arstat.c Artran.c \
 Dpurord.c Errorsys.c Invforms.c \
 Maincate.c Maincust.c Maindept.c Mainsupp.c Mainitem.c \
 Fpurord.c Purckit.c Receive.c Reclist.c Recpost.c Returns.c\
 Utilarch.c Utilback.c Utilcond.c Utillabe.c Utilpack.c Utilsppa.c Utilstoc.c \
 s_appr.c s_arch.c s_cash.c s_daily.c s_inq1.c s_inq2.c s_inv1.c s_inv2.c s_layb.c s_repo.c s_spec.c \
 PrintFunc.c s_quote.c

OBJFILES = bpos.obj proclib.obj Setupdbf.obj \
 acme.obj Apcheque.obj Apeom.obj Apremit.obj Aprep.obj Aptran.obj Areom.obj Arrep.obj Arstat.obj Artran.obj \
 Dpurord.obj Errorsys.obj Fpurord.obj Invforms.obj \
 Maincate.obj Maincust.obj Maindept.obj Mainsupp.obj Mainitem.obj \
 Receive.obj Reclist.obj Recpost.obj Returns.obj \
 Utilarch.obj Utilback.obj Utilcond.obj Utillabe.obj Utilpack.obj Utilsppa.obj Utilstoc.obj \
 s_appr.obj s_arch.obj s_cash.obj s_daily.obj s_inq1.obj s_inq2.obj s_inv1.obj s_inv2.obj s_layb.obj \
 s_repo.obj s_spec.obj PrintFunc.obj s_quote.obj


# HFILES = bpos.ch

RESFILES = bpos.res
RESDEPEN = 
TOPMODULE = BPOS.PRG
GTLIB = GTWVW.LIB
HBLIBS = 

HBLIBS = lang.lib vm.lib rtl.lib rdd.lib macro.lib pp.lib dbfntx.lib dbfcdx.lib dbffpt.lib \
         pcrepos.lib common.lib codepage.lib ct.lib tip.lib pcrepos.lib hsx.lib hbsix.lib hbzip.lib \
         tip.lib debug.lib zlib.lib $(GTLIB)

CLIBS = kernel32.lib user32.lib gdi32.lib winspool.lib comctl32.lib comdlg32.lib \
        advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib mpr.lib \
        uuid.lib vfw32.lib winmm.lib ws2_32.lib shell32.lib user32.lib winspool.lib \
        ole32.lib oleaut32.lib ws2_32.lib kernel32.lib gdi32.lib comctl32.lib comdlg32.lib \
        advapi32.lib

EXTLIBFILES =
DEFFILE = 
HARBOURFLAGS = -w2 /b

#CFLAGS = /c /MT /W3
CFLAGS = /c /W3 /MT

RFLAGS =
LFLAGS= /NODEFAULTLIB:LIBC /NODEFAULTLIB:LIBC
# LFLAGS = /Nodefaultlib:LIBCMT
LFLAGS = $(LFLAGS) /MERGE:.CRT=.data
IFLAGS = 

LINKER = link
.SUFFIXES: .c .obj .prg 

ALLOBJ = $(OBJFILES) $(OBJCFILES)
ALLRES = $(RESDEPEN)
ALLLIB = $(HBLIBS) $(CLIBS)

#DEPENDS
 
#COMMANDS
#{}.c{$(SRC09)}.obj:
#.c{$(SRC09)}.obj:

.c.obj:
 cl -I$(HB_DIR)\include $(CFLAGS) -Fo$* $**

.prg.c:
 $(HB_DIR)\bin\harbour /D__EXPORT__ /n /I$(HB_DIR)\include $(HARBOURFLAGS) /gc $** -O$*
 
.rc.res:
 $(CC_DIR)\rc $(RFLAGS) $<
 
#BUILD
#$(CFILES) $(RESDEPEN) $(DEFFILE)
bpos.exe: $(PRGFILES) $(CFILES) $(OBJFILES) $(RESFILES)
        link $(OBJFILES) $(HB_DIR)\obj\vc\mainwin.obj $(ALLLIB) $(RESFILES) /out:bpos.exe /map:bpos.map $(LFLAGS)

#link $(OBJFILES) $(ALLLIB) /out:bpos.exe /map:bpos.map $(LFLAGS)
     