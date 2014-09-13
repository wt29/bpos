static cline := ''
static lrec := 0
static recno := 0
static hoffset := 0
static pan_step := 5   // "Smoothness" of panning: how many columns per press
static know_last := .f.
static ctrl_codes_ := {}

#include "bpos.ch"

#include "box.ch"
#define TAB_SPACES space(2)
/*
Procedure Utilrepr
local mscr, oarray := {}, Spool_loop := TRUE, the_sfile,mlen
local mbuff, mhandle, x, zapsfile, choice, mfile, sfile, dbfile
local msp := 's' + substr( trim( lvars( L_NODE ) ), -4 ), indisp, mkey, element

Heading( 'Reprint Spooled Print Files' )
Spool_loop := TRUE
set printer to
sfile := directory( Oddvars( SYSPATH ) + "spool\" + msp + "*.*" )
mlen := len( sfile )
if mlen = 0
 Error('No Spooled Files for this User',12)
 spool_loop := FALSE
else
 Heading( "Select File" )
 dbfile := sfile
 ASort( dbfile )
 element := 1
 mscr := Box_Save(04,10,22,70)
 indisp := TBrowseNew(05,11,21,69)
 indisp:HeadSep := HEADSEP
 indisp:ColSep := COLSEP
 indisp:goTopBlock := { || element:=1 }
 indisp:goBottomBlock := { || element:= len(dbfile) }
 indisp:skipBlock := {|n|ArraySkip(len(dbfile),@element,n)}
 indisp:AddColumn(TBColumnNew('File name', { || if( dbfile[element,1]!='*Deleted*',padr(substr( dbfile[element,1], 6, at( '.', dbfile[element,1] ) -6 ), 12 ),'*Deleted*') } ) )
 indisp:AddColumn(TBColumnNew('       Size', { || transform(dbfile[element,2],"999,999,999") } ) )
 indisp:AddColumn(TBColumnNew('  Date', { || dbfile[element,3] } ) )
 indisp:AddColumn(TBColumnNew(' Time', { || dbfile[element,4] } ) )
 mkey:=0
 while mkey != K_ESC
  while !indisp:stabilize() .and. ( mkey := inkey() ) == 0
  enddo
  if indisp:stable
   mkey:=inkey(0)
  endif
  if !Navigate(indisp,mkey)
   The_Sfile :=  dbfile[ element, 1 ]
   do case
   case mkey == K_ENTER
    browtext( Oddvars( SYSPATH )+"spool\"+the_sfile )
   case mkey == K_DEL
    Kill( Oddvars( SYSPATH ) + "spool\" + the_sfile )
    dbfile[ element, 1 ] := '*Deleted*'
    eval( indisp:skipblock, -1 )
    eval( indisp:gotopblock )
    indisp:refreshall()
   endcase
  endif
 enddo
 Box_Restore( mscr )
endif
return

function BrowText(cFilename,;                    // Name of file to browse
                  nTop, nLeft, nBottom, nRight,; // Browse window dimensions
                  nMaxWidth,;                    // Maximum width of line
                  cColorSpec,;                   // cColorSpec string
                  lShowName,;                    // Show file name?
                  aToRemove_;                    // Array of printer codes
                  )                              //   to not display
local key
local txt
local col
local width
local block_:= {0,0}
local nSkipPage     // how many lines to move for a PgUp/PgDn
local oldScreen := Box_Save()
local oldCursor := set(_SET_CURSOR, .F.)
   
if cFilename == nil
 return nil
endif
   
default nTop      to 0
default nLeft     to 0
default nBottom   to 24
default nRight    to 79
default nMaxWidth to 132
default lShowName to TRUE
default aToRemove_ to {}
default cColorSpec to "w/n,n/w,b/w,w/b"

ctrl_codes_:= aToRemove_ // Set the file-wide static of codes to remove
txt:= TBrowseNew(nTop+1, nLeft+1, nBottom-2, nRight-1)
nSkipPage := ((txt:nBottom-2) - (txt:nTop+1))
txt:ColorSpec:= cColorSpec
FT_FUse(cFilename)      // open text file
@ nTop,nLeft,nBottom,nRight BOX B_SINGLE_DOUBLE + " "
setpos(nBottom-1,nLeft)
dispout(padc(;
      "Alt-S=Search, Alt-B=Block, Alt-U=Unmark, Alt-F=File, Alt-P=Printer",;
       nRight-nLeft,chr(177) ) )
if lShowName
 setpos(nTop, nLeft)
 dispout(" File: " +trim(cFilename)+" ")
endif
setpos(nBottom, nLeft)
dispout(" Line: "+alltrim(str(recno))+" of "+alltrim(str(lrec))+" ")

// This line makes startup slow in big files
// lrec:=  FT_FLastRec()
// know_last:= .t.


width := txt:nright-txt:nleft+1
col := TBColumnNew(, {||substr(padr(TB_GetLine(),nMaxWidth),hoffset)} )
col:colorblock := {||if( ( recno>=block_[1] .and. recno<=block_[2] ) .or. ;
                        ( recno<=block_[1] .and. recno>=block_[2] ) ,;
                          {3,4},{1,2})}
txt:addColumn(col)
txt:goTopBlock := { || FT_FGoTop() }
txt:goBottomBlock := { || FT_FGoBot() }
txt:skipBlock := { |n| TextPosition(n) }
while key != K_ESC
 while !txt:stabilize() .and. nextkey() == 0
 enddo
 if block_[1] > 0
  block_[2] := recno
 endif
 setpos(nBottom, nLeft)
 dispout(padr("Line: "+alltrim(str(recno))+" of "+;
         alltrim(str(lrec))+iif(know_last,"","+"),;
         nRight-nLeft,chr(196)))
 key:= inkey(0)
 do case
 case key == K_UP                         //  Up one row
  if block_[1] > 0 .and. block_[2] > block_[1]
//컴컴 This reveals the current record in NON-marked color
   txt:refreshCurrent()
   txt:stabilize()
  endif
  txt:up()
  if block_[1] > 0
//컴컴 We are in BLOCK mode, so have to pay attention
//컴컴 to cleaning up the block markers.
   while !txt:stabilize()
   enddo
   block_[2] := recno
   txt:refreshCurrent()
  endif
 case key == K_DOWN                       //  Down one row
  if block_[1] > 0 .and. block_[2] < block_[1]
   ++block_[2]
   txt:refreshCurrent()
   txt:stabilize()
  endif
  txt:down()
//컴컴 more block dragging stuff
  if block_[1] <> 0
   txt:refreshCurrent()
   txt:stabilize()
   block_[2] := recno
  endif
 case key == K_LEFT
  hoffset:= max(hoffset -=pan_step,0)
  txt:refreshall()
 case key == K_RIGHT
  hoffset +=pan_step
  txt:refreshall()
 case key == K_PGUP
//컴컴 The following nonsense is to
//컴컴 accommodate the unfortunate tendency of TBrowse not
//컴컴 to move the highlighter to the top if it doesn't have
//컴컴 to (known as the MoveHiLite() phenomenon...
  if recno - nSkipPage <= 0
   while recno > 1
    txt:up()
    txt:stabilize()
   enddo
  else
   FT_FGoTo(recno - nSkipPage)
  endif
  if block_[1] > 0
   block_[2] := FT_FRecno()
  endif
  txt:refreshall()
 case key == K_PGDN
  if know_last
   FT_FGoTo( min(recno + nSkipPage, lrec) )
  else
   FT_FGoTo( recno + nSkipPage )
   if FT_FEOF()
    FT_FGoto(recno)
    while !FT_FEof()
     FT_FSkip(1)
    enddo
   endif
  endif
  if block_[1] > 0
   block_[2] := FT_FRecno()
  endif
  txt:refreshall()
 case key == K_CTRL_PGUP
  txt:goTop()
  if block_[1] > 0
   block_[2] := FT_FRecno()
  endif
 case key == K_CTRL_PGDN
  txt:goBottom()
  if block_[1] > 0
   block_[2] := FT_FRecno()
  endif
  know_last := TRUE
 case key == K_HOME
  hoffset := 0
  txt:refreshall()
 case key == K_END
  hoffset := len(cline)-(txt:nRight-txt:nLeft)
  txt:refreshall()
 case key == K_CTRL_HOME
  hoffset := 0
  txt:refreshall()
 case key == K_CTRL_END
  hoffset := len(cline)-(txt:nRight-txt:nLeft)
  txt:refreshall()
 case key == K_TAB
  hoffset += txt:nRight-txt:nLeft
  txt:refreshall()
 case key == K_SH_TAB
  hoffset := max(hoffset -= txt:nRight-txt:nLeft,0)
  txt:refreshall()
 otherwise 
  HandleException( key, txt,block_ )
 endcase
enddo
ft_fuse()                // close file
Box_Restore( oldScreen )
set(_SET_CURSOR, oldCursor)
return nil
*   
function TextPosition(howMany)
local actual := howmany
local record := ft_frecno()
local numskipped
if ( -howmany ) > record  // this solves a problem where ft_fskip()
 ft_fgotop()              // ignores the command to skip to -1.
else                      // I would have expected it to move as
 ft_fskip( howmany )      // far as possible, but it fooled me.
endif
recno := FT_FRecNo()
numskipped := recno - record
lrec  :=  max( lrec, recno )
cline := FT_FReadLn()
if FT_FEof()
 know_last := TRUE
endif
return (recno - record)
*   
static function HandleException(key,txt,block_)
local temp
do case
case key == K_ALT_S // Search
 SrchText(txt)
case key == K_ALT_B
 if (block_[1] == 0) .and. (block_[2] == 0)
  block_[1] := block_[2] := recno
 else
  block_[1]:= recno
 endif
 if block_[1] > block_[2]
  temp := block_[1]
  block_[1] := block_[2]
  block_[2] := temp
 endif
 txt:refreshall()
case key == K_ALT_F      //컴컴 Output to a file
 TxtOut(txt,block_,"F")
case key == K_ALT_P      //컴컴 Send to printer
 TxtOut(txt,block_,"P")
case key == K_ALT_U      //컴컴 unmark block
 block_[1] := block_[2] := 0
 txt:refreshAll()
endcase
return NIL
*
static function SrchText(browse)
static SrchFor := ""
static NoCase := TRUE
static StartLine
local LineIn
local LineLong
local oldPos := FT_FRecNo()        //컴컴 mark our starting place
local getlist := {}
local oldScreen := Box_Save(9,7,13,53)
local oldCursor := set(_SET_CURSOR,2)  //컴컴 turn the cursor on
local srchlength
   
StartLine := if( empty( SrchFor ), 1, oldPos+1 )
SrchFor := padr( SrchFor, 80 ) // 80 character max search string length
Scroll( 9, 7, 13, 53 )
@ 9, 7 to 13, 53
@ 10, 8 say "Search for: " get SrchFor picture "@S30K"
@ 11, 8 say "Case insensitive? " get NoCase
@ 12, 8 say "Start search on line number:" get StartLine picture "######"
read
set(_SET_CURSOR, oldCursor)            //컴컴 turn cursor off again
if !empty( SrchFor )
 SrchFor := if( NoCase, upper( trim( SrchFor ) ), trim( SrchFor ) )
 srchlength := len( SrchFor )-1
 FT_FGoTo( StartLine )
 LineLong := ''
 if NoCase
  while !(SrchFor $ (LineLong:= (right( linelong, SrchLength ) +   ;
                                " " + upper(FT_FReadLn())))) .and. !FT_FEof() ;
                               .and. inkey() == 0
   @ 12,42 say ft_frecno()
   FT_FSkip(1)
  enddo
 else
  while !(SrchFor $ (LineLong:= (right( linelong, SrchLength ) + ;
                                " " + FT_FReadLn()))) .and. !FT_FEof()      ;
                                .and. inkey() == 0
   @ 12,42 say ft_frecno()
   FT_FSkip(1)
  enddo
 endif
endif
Box_Restore( oldScreen )
if !ft_feof()
 browse:refreshAll()
else
 tone(100,2)
 lrec := ft_frecno()
 know_last:= TRUE
 FT_FGoTo(oldPos)
endif
return NIL
*   
static function TxtOut(txt,block_,F_or_P)
local getlist:= {}, oldScreen, cOutfile:= space(30), nThisrec
local nTemp
default F_or_P to "F"
//컴컴 "Drag Block around" stuff may leave the
//컴컴 block anchors upside down.
if block_[2] < block_[1]
 nTemp     := block_[1]
 block_[1] := block_[2]
 block_[2] := ntemp
endif
if (block_[1] <= block_[2]) .and. (block_[2] > 0)
 if F_or_P == "F"
  oldScreen:= Box_Save(txt:nBottom-4,txt:nLeft+15,;
                                  txt:nBottom-1,txt:nRight-15)
  @ txt:nBottom-4,txt:nLeft+15,;
             txt:nBottom-1,txt:nRight-15 box B_DOUBLE+" "
  set cursor on
  @ txt:nBottom-3,txt:nLeft +23 say "Copy marked text to where?"
  @ txt:nBottom-2,txt:nLeft +20 get cOutfile picture '@!'
  read
  Box_Restore( oldScreen )
  set cursor off
   
  if lastkey() != K_ESC
//컴컴 if the file exists, append to the end
   if file(cOutFile)
    set printer to (cOutFile) additive
   else
    set printer to (cOutFile)
   endif
  endif
 endif
   
 FT_FGoto(block_[1])
 nThisrec:= FT_Frecno()
 set console off
 set print on
 while nThisrec >= block_[1] .and. nThisrec <= block_[2]
  ? FT_Freadln()
  FT_FSkip(1)
  nThisrec := FT_Frecno()
 enddo
   
 set print off
 set console on
 set printer to
   
//컴컴 remove the highlights of the block
 block_[1] := block_[2] := 0
 txt:refreshAll()
else
 NoBlock(txt)
endif
return NIL
*   
static function NoBlock ( txt )
local oldScreen
tone(100,2)     //컴컴 THUD
oldScreen := Box_Save( txt:nBottom-4, txt:nLeft +15, txt:nBottom-1, txt:nRight -15 )
@ txt:nBottom-4,txt:nLeft+15,txt:nBottom-1,txt:nRight-15 box B_DOUBLE+" "
@ txt:nBottom-3,txt:nLeft +25 say "Use Alt-B to Block Text!"
@ txt:nBottom-2,txt:nLeft +25 say "      Press a key...    "
inkey(0)
Box_Restore( oldScreen )
return NIL
*   
function TB_GetLine()
local escpos, i
if chr(9) $ cline
 cline := strtran(cline,chr(9),TAB_SPACES)
endif
     // Strip printer codes
for i:= 1 to len(ctrl_codes_)
 if ctrl_codes_[i] $ cline
  cline := strtran(cline, ctrl_codes_[i],"")
 endif
next
return cline
	Last change:  TG   16 Jan 2011    6:40 pm
*/