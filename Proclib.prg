/*

 Proclib - Assorted programs of general use in BPOS

           Last change:  APG  19 Apr 2005    8:41 pm

      Last change:  TG   29 Apr 2011    5:12 pm
 */

#include "box.ch"
#include "error.ch"
#include "bpos.ch"
#include "set.ch"
#include "fileio.ch"

#define SEC_CHAR chr(255)

#define PITCH10 1
#define PITCH12 2
#define PITCH17 3
#define LETTERQ 4
#define DRAFTQ  5

static spfile_no := 0, secmask:='',musercode:=''
static ptrstr 
static nPrevRecord
static mbvars:={}, mlvars:={}, mpvars:={}

Function KeyskipBlock( mval, xkey )
return ( { |nmove| Awskipit( nmove, mval, xkey ) } )

*

Function Awskipit( nmove, mval, xkey )
local nmoved
nmoved := 0
if nmove == 0 .or. lastrec() == 0
 dbskip( 0 )
elseif nmove > 0 .and. recno() != lastrec() + 1
 while nmoved <= nmove .and. !eof() .and. eval( mval ) = xkey
  skip 1
  nmoved++
 enddo
 dbskip( -1 )
 nmoved--
elseif nmove < 0
 while nmoved >= nmove .and. !bof() .and. eval( mval ) = xkey
  dbskip( -1 )
  nmoved--
 enddo
 if !bof()
  dbskip( 1 )
 endif
 nmoved++
endif
return ( nmoved )

*

function del_rec( cFileName, munlock )
default cFileName to alias()
Rec_lock( cFileName )
( cFileName )->( dbdelete() )
if munlock != nil
 ( cFileName )->( dbrunlock() )
endif
return nil

*

function rec_lock ( cFileName, real_name )
default cFileName to alias()
default real_name to cFileName
if select(real_name) = 0
 real_name := cFileName
endif
if !( ( cFileName )->( eof() ) )  
 while !( cFileName )->( dbrlock() )
  Error( 'Waiting for record in ' + real_name + ' to be freed', 12, 5, ;
   transform( ( cFileName )->( fieldget(1) ), '@!' )+' '+procname( 1 )+' '+Ns( procline( 1 ) ) )
  inkey( 1 )
 enddo
endif
return TRUE

*

function add_rec ( cFileName ) // Bugger it add the record or else !!
default cFileName to alias()
(cFileName)->( dbappend() )
while neterr()             // Error from last attempt
 Error('Attempting to append new record to ' + cFileName , 12, 5 ) // Warn 'em
 (cFileName)->( dbappend() )   // Attempt to add again
enddo                      // Test and loop ?
return TRUE                // OK so back we go

*

function Netuse (  sDbfFile, ex_use, wait, sDBFAlias, lnewArea, aindex ,mtag )
local lForever, nCount := 1, ocur := setcursor( 0 )

default ex_use to SHARED
default wait to 10
default sDBFAlias to NOALIAS
default lnewArea to NEW
default mtag to 1

lForever := ( wait = 0 )
lnewArea := ( lnewArea != nil ) .and. lnewArea
if !file( sDbfFile + if(  '.' $ sDbfFile, '', '.dbf' ) )
 Error( 'File ' + sDbfFile + ' could not be found in default drive or in path "' + Oddvars( SYSPATH ) + '"', 12 )
 return FALSE

endif
while ( lForever .or. wait > 0 )
 dbusearea( lnewArea, "DBFCDX", sDbfFile, sDBFAlias, !ex_use )

 if !neterr()

  if aindex != nil
   dbsetindex( Oddvars( SYSPATH ) + aindex )

  endif

  ordsetfocus( mtag )

  setcursor( ocur )
  return TRUE
 endif
 inkey(1)
 --wait
 nCount++
 if int(nCount/5) = nCount/5
  Error( 'Waiting for file ' + sDbfFile + ' to become Available', 12, 4 )
 endif
enddo
Error( 'File ' + sDbfFile + ' unavailable', 12, 3 )
setcursor( ocur )
return FALSE

*

function Navigate( br, k )
local did := TRUE
do case
case k == K_UP
 br:up()
case k == K_DOWN
 br:down()
case k == K_LEFT
 br:left()
case k == K_RIGHT
 br:right()
case k == K_PGUP
 br:pageUp()
case k == K_PGDN
 br:pageDown()
case k == K_CTRL_PGUP
 br:goTop()
case k == K_CTRL_PGDN
 br:goBottom()
 br:refreshcurrent()
case k == K_HOME
 br:home()
case k == K_CTRL_HOME
 br:panHome()
case k == K_CTRL_END
 br:panEnd()
case k == K_CTRL_RIGHT
 br:panRight()
case k == K_CTRL_LEFT
 br:panLeft()
otherwise
 do case
 case k == K_SH_F1
  Open_de_draw()
 case k == K_SH_F2
  DocketStatus()
 case k == K_SH_F3 
  Print_swap()
 case k == K_CTRL_F1
  Mem_avail()
 case k == K_CTRL_P
  Printgraph()     // Ctrl Print Screen
 case k == K_ALT_L
#ifdef SECURITY
  Login( TRUE )
#endif  
 endcase
 did := FALSE
endcase
return did

*

function jumptobott( lowval, malias )
local cType:=valtype( lowval ), mlen
default malias to alias()
do case
case cType = 'C'
 mlen := len( trim( lowval ) )
 ( malias)->( dbseek( trim( lowval ) + chr( 254 ), TRUE ) )
 ( malias )->( dbskip( -1 ) )
case cType = 'N'
 ( malias )->( dbseek( lowval+1, TRUE ) )
 ( malias )->( dbskip( -1 ) )
case cType = 'L'
 if lowval = FALSE
  ( malias )->( dbseek( TRUE, TRUE ) )
  ( malias )->( dbskip( -1 ) )
 endif
endcase
return nil

*

function pinwheel ( nointerupt )
local olddev := set( _SET_DEVICE, 'screen' ), mret
static mchr := {'|','/','-','\'}, nCount := 0
nCount++
if nCount = 5
 nCount := 1
endif
@ 24, 79 say mchr[ nCount ]
set( _SET_DEVICE, olddev )
if nointerupt = nil
 mret := ( inkey() != K_ESC )
else
 mret := TRUE
endif  
return mret

*

function Update_oh ( mqty )
local nOrigSelect := select()

if mqty != nil
 if master->onhand + mqty < MAXNEGSTOCK
  Error( 'Negative Stock limit Exceeded on ' + DESC_DESC, 12, ,trim( left( master->desc, 40 ) ) )

 else
  master->onhand += mqty

 endif
endif

select( nOrigSelect )
return nil

*

function bvarget
local nPosition
if len( mbvars ) = 0
 if Netuse( "bvars" )             // All of our 'B_' Variables
  if reccount() = 0
   Add_rec()

  endif
  for nPosition := 1 to fcount()          // Loop for num fields
   aadd( mbvars, fieldget( nPosition ) )

  next                            // And Again for more fields
  use

 endif

endif 
return mbvars

*

function bvarsave
local x
if len( mbvars ) = 0
 Bvars()

endif
if Netuse( "bvars", EXCLUSIVE )
 for x := 1 to fcount()           // Loop for num fields 
  fieldput( x, mbvars[ x ] ) 

 next                             // And Again for more fields
 dbclosearea()

endif
return nil

* 

function bvars ( mindex, mval )

if mindex == B_DATE

 mbvars[ B_DATE ] := if( date() != mbvars[ B_DATE ], date(), mbvars[ B_DATE ] ) // Test for Midnight etc.

 if mbvars[ B_DATE ] != lvars( L_DATE )   // Reset Terminal Date ?
  if lvars( L_CUST_NO ) > 5
   Lvars( L_CUST_NO , CustNum( 1 ) )      // New customer no seq

  endif
  Lvars( L_DATE , mbvars[ B_DATE ] )

 endif

endif

if mval != nil 
 mbvars[ mindex ] := mval

endif
 
return mbvars[ mindex ] 

*

function lvarget
local x, mnode
if len( mlvars ) = 0
 if Netuse( "nodes" )

  mnode := upper( if( !empty( netname() ), netname(), 'NONET' ) )  // Connected to Lan ?

  if trim( mnode ) = 'NONET' .and. gete( 'NETNAME' ) != ''
   mnode := gete( 'NETNAME' )
  endif 
  locate for nodes->node = mnode                                   // Locate record for logged in node

  if !found()                                  
   Add_rec( 'nodes' )
   nodes->node := mnode
   nodes->good := 530
   nodes->bad := 250
   nodes->colattr := if(iscolor(),1,16)
   nodes->memory := 640
   nodes->color := TRUE
   nodes->backgr := TRUE
   nodes->shadow := TRUE
   nodes->cdtype := 'C'
   nodes->auto_open := TRUE

  endif                            
  for x := 1 to fcount()                    // Loop for num fields 
   aadd( mlvars, fieldget(x) )

  next                                      // And Again for more fields
  nodes->( dbclosearea() )                  // Close Node list file
  if empty( mlvars[ L_C1 ] )
   Factory( mlvars )                        // Set up default Colours

  endif

 endif
endif 
return mlvars

*

function lvarsave
local x, mnode

if len( mlvars ) = 0
 Lvars()
endif

if Netuse( "nodes", EXCLUSIVE )                         // All of our 'L_' Variables
 mnode:=upper(if(!empty(netname()),netname(),'NONET'))  // Connected to Lan ?
 locate for nodes->node = mnode                         // Locate record for logged in node
 if found()                                  
  for x := 1 to fcount()                                // Loop for num fields 
   fieldput( x, mlvars[ x ] ) 
  next                                                  // And Again for more fields
 else
  Error( 'Trouble locating Node Address in Nodes file - Notify ' + DEVELOPER , 12 )
 endif
 nodes->( dbclosearea() )
endif
return nil

* 

function lvars ( mindex, mval )
if len( mlvars ) = 0
 mlvars = array( 100 )
endif
if mval != nil
 mlvars[ mindex ] := mval

endif
return mlvars[ mindex ] 

*

function oddvars ( mindex, mval )
static marray
default marray to array( 25 )
if mval != nil 
 marray[ mindex ] := mval
endif
return marray[ mindex ] 

*

Function MenuGen ( marr, mrow, mcol, mdesc, mchoice, mcolor, mscr_rest, nSelRow )
local x, mwidth, mscr
default mchoice to 0 
default mdesc to ''
default mscr_rest to FALSE
default mcolor to C_NORMAL
mwidth := len( mdesc )
for x := 1 to len( marr )
 mwidth := max( mwidth, len( marr[ x, 1 ] ) + 1 )

next
mscr := Box_Save( mrow, mcol, mrow+len( marr )+1, mcol+mwidth+2, mcolor ) 
for x := 1 to len( marr )
 @ mrow + x, mcol+1 prompt if(x!=1.and.!empty(mdesc),' ','') + padr( marr[ x, 1 ], mwidth + if(x=1,1,0) ) message if( marr[ x, 2] = nil, '', line_clear( 24 ) + marr[ x, 2 ] ) 

next
Highlight( mrow, mcol, '', mdesc )
clear typeahead
menu to mchoice 
if mscr_rest
 Box_Restore( mscr )

endif
nSelRow := mrow + mchoice
return mchoice 

*

Function Build_help ( aArray, wait )
local mwidth := 0, x, mscr, oldcur := setcursor( SC_NONE )
default wait to len( aArray ) 
for x := 1 to len( aArray )
 mwidth := max( mwidth, len( aArray[ x, 1 ] ) + len( aArray[ x, 2 ] ) )
next
mscr := Box_Save( 24-2-len( aArray ) , 79-4-mwidth, 24-1, 79-2, C_YELLOW )
for x := 1 to len( aArray )
 @ 24-2-len( aArray )+x, 79-3-mwidth say aArray[ x, 1 ]
 @ 24-2-len( aArray )+x, 79-2-len( aArray[ x, 2 ] ) say aArray[ x, 2 ]
next
if inkey( wait ) = K_SPACE
 @ 24-2-len( aArray ), 79-3-mwidth say '< Help locked - Hit Space >'
 while inkey( 0 ) != K_SPACE
 enddo 
endif
Box_Restore( mscr )
setcursor( oldcur )
return nil

*

function BrowHelp
local aArray := {}
aadd( aArray, { 'Up Arrow', 'Move Up one Line' } )
aadd( aArray, { 'Down Arrow', 'Move Down one Line' } )
aadd( aArray, { 'Right Arrow', 'Move Right one field' } )
aadd( aArray, { 'Left Arrow', 'Move left one field' } )
aadd( aArray, { 'Page Up', 'Move up one Page' } )
aadd( aArray, { 'Page Down', 'Move Down one Page' } )
aadd( aArray, { 'Ctrl Page Up', 'Move to top of Browse' } )
aadd( aArray, { 'Ctrl Page Down', 'Move to Bottom of Browse' } )
aadd( aArray, { 'Ctrl Home', 'Move to furthest left Column' } )
aadd( aArray, { 'Ctrl End', 'Move to furthest right Column' } )
aadd( aArray, { 'Ctrl Left Arrow', 'Pan the browse left' } )
aadd( aArray, { 'Ctrl Right Arrow', 'Pan the display right' } )
aadd( aArray, { 'Shift F1', 'Trigger Cash Drawer' } )
aadd( aArray, { 'Shift F2', 'Print a Docket' } )
aadd( aArray, { 'Shift F3', 'Swap Printers' } )
aadd( aArray, { 'Shift F4', 'Print Docket Header' } )
aadd( aArray, { 'Shift F5', 'Calculator' } )
aadd( aArray, { 'Shift F6', 'Diary/Calendar Functions' } )
aadd( aArray, { 'Shift F7', 'Local Time' } )
aadd( aArray, { 'Ctrl P', 'Print Screen to "Report" printer' } )
#ifdef SECURITY
aadd( aArray, { 'Alt L', 'Change login' } )
#endif
return aArray

*

function NumGet ( mnum )
return Bvars( B_BRANCH ) + padl( mnum, 6 )

*

function SayGet ( mrow, mcol, msay, mget, mpict, mvalid )
local getlist := {}
default mvalid to TRUE
@ mrow, mcol say msay get mget pict ( mpict ) valid ( eval( mvalid ) )
read
return mget

*

procedure heading ( cHeading )

static cOldHeading

local olddev := set(_SET_DEVICE,"screen")
local dToday := dtoc( bvars( B_DATE ) )
local sOldColour := setcolor()

cHeading := if( empty( cHeading ), cOldHeading, cHeading )
syscolor( C_INVERSE )
line_clear(0)

@ 0,0 say padc( cHeading, 79 )
@ 0,1 say trim( lvars( L_REGISTER ) )

#ifndef SECURITY
@ 0,79-17 say ( dToday )
#else
@ 0,79-17 say ( dToday + ' User:' + Oddvars( OPERCODE ) )
#endif

Setcolor( sOldColour )

cOldHeading := cHeading

set( _SET_DEVICE, olddev )

return

*

function error ( ertext, errow, erwait, extrainfo )
local sScreen, ercol, er_bott, er_right, ocursor:=setcursor(0)
default erText to ""
default extraInfo to ""
default erWait to 0
if bvars( B_BELLS )
 tone( lvars( L_BAD ), 5 )
endif
ertext := trim( ertext )
ercol := min( 24, int( (79-( max( len(ertext), len( extrainfo ) ) ) ) / 2 ) -2 )
if errow = nil
 sScreen := Box_Save( 24, 0, 24, 79 )
 syscolor( C_INVERSE )
 Line_clear( 24 )
 Center( 24, ertext + ' - Hit any key to continue - ' )

else
 er_right := ercol + max( 27, max( len( ertext ), if( extrainfo != "", len( extrainfo ), 0 ) ) ) + 4
 er_bott := errow + if( erwait = 0, 2, 1 ) + if( empty( ertext ), 0, 1 )+ if( extrainfo = "", 0, 1 )
 sScreen:=Box_Save( errow, ercol, er_bott, er_right, C_YELLOW )
 Center( errow + 1, ertext )
 if extrainfo != ""
  Center( errow + 2, extrainfo )

 endif
 if erwait = 0
  Center( er_bott - 1, '- Hit any key to continue -' )

 endif  

endif

inkey( erwait )

Syscolor( 1 )           
Box_Restore( sScreen )
setcursor( ocursor )
return nil

*

function codefind ( outcode )               // Universal id/Code Seek prg
local lfoundkey:=FALSE,p_test,mcode,cur_ord,mxcode,x,sFieldName,sTest:="/.';="
local sScreen,nKey,mlen,oBrowse,tscr
local mreq,c,en_key,mseq,getlist:={}
local lastarea := select()
p_test := substr(outcode,1,1)               // What lookup mode passed
select master                               // Get Master File (just in case)
do case
case p_test $ sTest
 do case
 case p_test = '/'                          // Lookup by desc ?
  master->( ordsetfocus( BY_DESC ) )        // Desc index
  sFieldName:='desc'                        // Field for macro subst
 case p_test = '.'
  master->( ordsetfocus( BY_ALTDESC ) )
  sFieldName:='alt_desc'
 case p_test = ';'
  master->( ordsetfocus( BY_DEPARTMENT ) )
  sFieldName:='department'
 case p_test = "'"
  master->( ordsetfocus( BY_SUPPLIER ) )
  sFieldName:='supp_code'
 case p_test = "="
  master->( ordsetfocus( BY_CATALOG ) )  
  sFieldName:='catalog'
 endcase
 mcode := trim( substr( outcode, 2, 10 ) )  // Get the relevant bit

 if master->( dbseek( mcode ) )
  master->( dbskip() )                                      // test here for only one match
  if upper( substr( master->( fieldget( fieldpos( sFieldName ) ) ), 1, len(mcode) ) ) != mcode
   skip -1
   lfoundkey := TRUE

  else
   sScreen := Box_Save()
   @ 1,0 clear to 24,79
   skip -1
   for x = 1 to 24-2
    @ x+2,0 say row()-2 pict '99'
   next
   mlen:=len(mcode)
   oBrowse:=tbrowsedb( 01, 3, 24, 79 )
   oBrowse:colorspec := if( iscolor(), TB_COLOR, setcolor() )
   oBrowse:HeadSep := HEADSEP
   oBrowse:ColSep := COLSEP
   oBrowse:goTopBlock := { || dbseek( mcode ) }
   oBrowse:goBottomBlock := { || jumptobott( mcode ) }
   c:=tbcolumnnew( DESC_DESC, { || substr( master->desc, 1, 45 ) } )
   c:colorBlock := { || if( MASTAVAIL > 0, {5, 6}, {1, 2} ) }
   oBrowse:addcolumn( c )
   oBrowse:addcolumn(tbcolumnNew('Avail',{ || transform( MASTAVAIL, '9999') } ) )
   oBrowse:addcolumn(tbcolumnNew('Supp', { || master->supp_code } ) )
   oBrowse:addcolumn(tbcolumnNew('Price', { || transform( master->sell_price, PRICE_PICT ) } ) )
   do case
   case p_test = '.'
    oBrowse:addcolumn(tbcolumnNew('Dept', { || master->alt_desc } ) )

   case p_test = ';'
    oBrowse:addcolumn(tbcolumnNew('Dept', { || master->department } ) )

   case p_test = '='
    oBrowse:addcolumn(tbcolumnNew('Catalog', { || master->catalog } ) )

   endcase

   oBrowse:addcolumn(tbcolumnNew('Bi', { || master->Binding } ) )
   oBrowse:freeze := 1
   nKey := 0
   while nKey != K_ESC .and. !lfoundkey .and. nKey != K_END
    oBrowse:forcestable()
     nKey := inkey(0)
    if !Navigate( oBrowse, nKey )
     do case
     case nKey >= 48 .and. nKey <= 57
      keyboard chr( nKey )
      mseq := 0
      tscr := Box_Save( 2, 08, 4, 40 )
      @ 3,10 say 'Selecting No' get mseq pict '999'
      read
      Box_Restore( tscr )
      if !updated()
       loop
      else
       mreq := recno()
       skip mseq - oBrowse:rowpos
       lfoundkey := TRUE
      endif
     case nKey == K_ENTER
      lfoundkey := TRUE
     case nKey = K_F3
      oBrowse:refreshcurrent()
     case nKey == K_F10
      itemdisp( FALSE )
      oBrowse:refreshall()
     case nKey == K_INS
      lfoundkey := add_item()
     endcase
    endif
   enddo
   Box_Restore( sScreen)
  endif
 endif
 master->( ordsetfocus( BY_ID ) )

case p_test = ','
 if Netuse("macatego",FALSE,10,"ecat",NEW )
  set relation to ecat->id into master
  en_key := trim(substr(outcode,2,10))       // Get the relevant bit
  Heading('Inquire by Category')
  sScreen:=Box_Save( 0, 0, 24, 79 )
  if !dbseek( en_key )
   Error( 'No Category match on File', 12 )
  else
   skip
   if upper( substr( ecat->code, 1, len( en_key ) ) ) != en_key
    skip -1
    lfoundkey := TRUE

   else
    @ 1,0 clear to 24,79
    skip -1
    mlen := len(en_key)
    oBrowse:= TBrowseDB(01, 0, 24, 79)
    oBrowse:colorspec := if( iscolor(), TB_COLOR, setcolor() )
    oBrowse:HeadSep := HEADSEP
    oBrowse:ColSep := COLSEP
    oBrowse:goTopBlock:={ || dbseek( en_key ) }
    oBrowse:goBottomBlock:={ || jumptobott( en_key ) }
    oBrowse:skipBlock:=KeySkipBlock( {||substr( ecat->code,1,mlen)},en_key )
    c:=tbcolumnNew( DESC_DESC, { || substr( master->desc, 1, 40 ) } )
    c:colorBlock := { || if(master->onhand > 0, {5, 6}, {1, 2} ) }
    oBrowse:addcolumn( c )
    oBrowse:addcolumn(tbcolumnNew( ALT_DESC, { || master->alt_desc } ) )
    oBrowse:addcolumn(tbcolumnNew('Code', { || ecat->code } ) )
    oBrowse:addcolumn(tbcolumnNew('Avail',{ || transform( MASTAVAIL, '9999')} ) )
    oBrowse:addcolumn(tbcolumnNew('Supp', { || master->supp_code } ) )
    oBrowse:addcolumn(tbcolumnNew( PACKAGE_DESC, { || master->binding } ) )
    oBrowse:addcolumn(tbcolumnNew('Price', { || transform( master->sell_price ,'999.99') } ) )
    oBrowse:addcolumn(tbcolumnNew('Cost', { || transform( master->cost_price ,'999.99') } ) )
    oBrowse:addcolumn(tbcolumnNew('Disc', { || transform( 100-(master->cost_price/(master->sell_price/100)) ,'999.99') } ) )
    oBrowse:freeze := 1
    nKey := 0
    while nKey != K_ESC .and. !lfoundkey .and. nKey != K_END
     oBrowse:forcestable()
     nKey := inkey(0)
     if !Navigate( oBrowse, nKey )
      do case
      case nKey == K_ENTER
       lfoundkey := TRUE

      case nKey == K_F10
       itemdisp(FALSE)
       oBrowse:refreshall()

      case nKey == K_INS
       lfoundkey := add_item()

      endcase
     endif
    enddo
   endif
  endif
  Box_Restore( sScreen )
  ecat->( dbclosearea() )
  select master
 endif

otherwise
 cur_ord := master->( ordsetfocus( BY_ID ) )
// if left( outcode, 3 ) = '979' .and. len( outcode ) > 10
//  outcode := '978' + substr( outcode, 4, ID_CODE_LEN - 3 )
//  Oddvars( IS_CONSIGNED, TRUE )

// else
  Oddvars( IS_CONSIGNED, FALSE ) 

// endif
 mxcode := padr( outcode, ID_CODE_LEN )
 if SYSNAME = 'BPOS' .and. len( trim( mxcode ) ) = 10 .and. !isalpha( mxcode )
  mxcode := substr( CalcAPN( '978' + mxcode ), 1, ID_CODE_LEN )

 endif
// mxcode := substr( mxcode, 1, 12 )  // Now going for 13 character IDs
 lfoundkey := master->( dbseek( mxcode ) )     // ??? .and. mxcode = trim(substr(id,1,12)
// if !lfoundkey
//  master->( ordsetfocus( BY_CATALOG ) )
//  lfoundkey := master->( dbseek( trim( outcode ) ) )

// endif
 master->( ordsetfocus( cur_ord ) )

endcase
set function 2 to if( !lfoundkey, outcode, master->id ) + chr( 13 )
select ( lastarea )
return( lfoundkey )

*

function dup_chk ( dup_no, workarea )
local sscr,key:=0,auto_close:=FALSE,lastarea:=select(),supp_code:=space( SUPP_CODE_LEN )
local dup_rec,oTBrowse,validation:=FALSE,oc,aHelpLines
local getlist:={},msupp,mcat,sScreen,mwork:=upper(workarea),keybuff,waopen:=FALSE
#ifdef SECURITY
local cNewPassword, cNewPassword2
local x, page_number:=1, page_width, page_len, top_mar, bot_mar, col_head1, col_head2,report_name
#endif
if ( mwork='BRAND' .and. !Bvars( B_CHKIMPR ) ) .or. ;
   ( mwork='STATUS' .and. !Bvars( B_CHKSTAT ) ) .or. ;
   ( mwork='BINDING' .and. !Bvars( B_CHKBIND ) ) .or. ;
   ( mwork='CATEGORY' .and. !Bvars( B_CHKCATE ) )
 return TRUE
endif

if select( workarea ) = 0
 if !Netuse( workarea )
  select (lastarea)
  return FALSE                               // File not available pack up
 endif
else
 waopen := TRUE
endif
select (workarea)          // All cool use the file !!
dup_rec:=recno()           // Hold record no
seek dup_no                // Seek our test record
if !found()
 (workarea)->( dbseek( upper( substr( dup_no, 1, 1 ) ) , TRUE ) ) // Soft
 sscr := Box_Save( 1, 39, 22, 77, C_MAUVE )
 @ 1, 60 say '<' + workarea + '>'
 oTBrowse:=tbrowsedb( 2, 40, 21, 76 )
 oTBrowse:HeadSep := HEADSEP
 oTBrowse:ColSep := COLSEP
 oTBrowse:addcolumn( tbcolumnnew( "Code",{ || ( workarea )->code } ))
 oTBrowse:addcolumn( tbcolumnnew( "Name",{ || left( ( workarea )->name, 20 ) } ))
 if mwork = 'BRAND'
  oTBrowse:addcolumn( tbcolumnnew( "Supp",{ || ( workarea)->supp_code } ) )
 endif
 go top
 keybuff:=''
 while TRUE
  oTBrowse:forcestable()
  key := inkey(0)
  if !navigate( oTBrowse, key )
   do case
   case key == K_F1
    aHelpLines := {}
    aadd( aHelpLines, { '<Esc/End>', 'Exit' } )
    aadd( aHelpLines, { '<Enter>', 'Select Item' } )
    if mwork != 'SUPPLIER' .and. mwork != 'DEPT'
     aadd( aHelpLines, { '<Del>', 'Delete Item' } )
    endif
    aadd( aHelpLines, { '<F10>', 'Edit Details' } )
    aadd( aHelpLines, { '<Ins>', 'Add New Item' } )
    if mwork = 'OPERATOR'
     aadd( aHelpLines, { '<F9>', 'Setup Profile' } )
     aadd( aHelpLines, { '<F8>', 'Print Profile' } )
    endif
    Build_help( aHelpLines )

   case key == K_ESC .or. key == K_END
    exit

   case key == K_ENTER
    keyboard chr( K_HOME )+chr( K_CTRL_Y )+trim( (mwork)->code )+chr( K_ENTER )
    exit

   case key == K_DEL
    if Secure( X_DELFILES )
     if mwork != 'SUPPLIER' .and. mwork != 'DEPT'
      if Isready( 12,,'Ok to delete '+trim((mwork)->code)+' from file')
       SysAudit("CodeDel"+trim( (mwork)->code )+mwork)
       select ( mwork )
       Del_rec( mwork, UNLOCK )
       eval( oTBrowse:skipblock , -1 )
       oTBrowse:refreshall()
      endif
     endif
    endif

   case key == K_F10
    if Secure( X_EDITFILES )
     oc:=setcolor()
     do case
     case mwork = "SUPPLIER" 
      Supplier()
     otherwise
      Rec_lock()
      sScreen := Box_Save( 08, 01, 13, 72, C_GREY )
      Highlight( 09, 07, 'Code', (mwork)->code )
      @ 10, 03 say '    Name' get name pict '@s40' valid !empty( (mwork)->name ) 
      do case
      case mwork == 'BRAND'
       @ 11,34 say 'Supplier' get brand->supp_code pict '@!' valid( Dup_chk( brand->supp_code , "Supplier" ) )

       if bvars( B_MATRIX )
        Box_Restore( matrix_disp() )  // This will confuse em!
       endif
      endcase
      if mwork == 'OPERATOR'
#ifdef SECURITY   // Needed as the invoicing adds an operator code to determine who created the invoice
       if substr( secmask, X_SUPERVISOR, 1 ) != SEC_CHAR
          Error( 'You do not have supervisor equivalance You cannot setup users', 12 )
       else
          Box_Restore( SetupSec() )
       endif
#endif
      endif
      read
      dbrunlock()
      Box_Restore( sScreen )
     endcase
     Setcolor(oc)
     oTBrowse:refreshcurrent()
    endif

   case key == K_INS
    if Secure( X_ADDFILES )
     do case
     case mwork = "SUPPLIER"
      msupp := space( SUPP_CODE_LEN )
      sScreen:=Box_Save( 5, 08, 7, 29 + SUPP_CODE_LEN )
      @ 6,10 say 'New Supplier Code' get msupp pict '@!' ;
               valid( substr( msupp,1,1 ) != '*' .and. non_stock( msupp ) .and. !empty( msupp ) )
      read
      Box_Restore( sScreen )
      if updated()
       if dbseek( msupp )
        sScreen:=Box_Save( 7, 10, 9, 70 )
        Center( 8, 'Supplier Name ' + trim( supplier->name ) )
        Error( 'Supplier Code already on file', 12 )
        Box_Restore( sScreen )
       else
        SysAudit("SupAdd"+msupp)
        Add_rec()
        supplier->code := msupp
        supplier->country := bvars( B_COUNTRY )
        supplier->posort := 'T'
        supplier->op_it := Bvars( B_OPENCRED )
        supplier->price_meth := 'R'
        supplier->gst_inc := YES
        Supplier( GO_TO_EDIT )
        if empty( supplier->name ) .or. empty( supplier->code )
         Error('No Name or code for Supplier Record',12)
         Rec_lock()
         delete
        endif
        dbrunlock()
       endif
      endif

     otherwise
      mcat := space( len( ( mwork )->code ) )
      sScreen:=Box_Save( 06, 08, 09, 32+len( mcat ), C_GREEN )
      @ 7,10 say 'New ' + lower( mwork ) + ' Code' get mcat pict '@!' valid !empty( mcat )
      read
      Box_Restore( sScreen )
      if updated()
       if dbseek( mcat )
        sScreen:=Box_Save( 11, 08, 13, 72, C_GREY )
        Center( 12, 'Name ÍÍÍ¯ ' + (mwork)->name )
        Error( 'Code already on file',12 )
        Box_Restore( sScreen )
       else
        Add_rec( mwork )
        ( mwork )->code := mcat
         sScreen:=Box_Save( 08, 01, 15, 72, C_GREEN )
         Highlight( 09, 03, 'Code' , mcat )
         @ 11,03 say '    Name' get (mwork)->name pict '@s40'
         do case
         case mwork == "TELEORDE"
          @ 12, 03 say ' Data No' get teleorde->data_no
          @ 13, 03 say 'Username' get teleorde->username
          @ 14, 03 say 'Password' get teleorde->password
         case mwork == "DEPT"
          @ 13,03 say 'Lineal Metres' get dept->shelf_len pict '9999.99'
         case mwork == 'brand'
          @ 11,34 say 'Supplier' get brand->supp_code pict '@!' ;
                      valid( Dup_chk( brand->supp_code , "Supplier" ) )
         endcase
         read
         if mwork == 'BRAND' .and. Bvars( B_MATRIX )
          Box_Restore( matrix_disp() )
         endif
         if mwork == 'OPERATOR'
#ifdef SECURITY
          if substr( secmask, X_SUPERVISOR, 1 ) != SEC_CHAR
           Error( 'You do not have supervisor equivalance You cannot setup users', 12 )
           operator->name := ''  // Force system to delete login
          else
           Box_Restore( SetupSec() )

          endif
#endif
         endif
         Box_Restore( sScreen )
        if empty((mwork)->name) .or. empty((mwork)->code )
         Error( 'Code or Name Empty - record deleted' , 12 )
         Del_rec( mwork, UNLOCK )
        endif
        ( mwork )->( dbrunlock() )
       endif
      endif
     endcase
     oTBrowse:refreshall()
    endif
#ifdef SECURITY   // Don't need any of this if not using SECURITY etc
   case key = K_F8
    if mwork = 'OPERATOR'
     if substr( secmask, X_SUPERVISOR, 1 ) != SEC_CHAR
      Error( 'You must be a supervisor to perform this!', 12 )
     else 
      if Isready( 12, 10, 'Print Security Listing' )
       page_number:=1
       page_width:=132
       page_len:=66
       top_mar:=0
       bot_mar:=10
       col_head1 := '                      S F P S U D C G R S V C C I A E D D D D D C C C C C S S'
       col_head2 := '  Name                U I U A T E R E E T O D N N F F F T R E B D T R E B U G'                          
       report_name := 'Security Flags Listing'
       Print_find( "report" )

       set device to printer
       setprc( 0, 0 )             
       PageHead( report_name, page_width, page_number, col_head1, col_head2 )
       operator->( dbgotop() )
       while !operator->( eof() ) .and. Pinwheel()          // Start print Routine
          if PageEject( page_len, top_mar, bot_mar )
           page_number++
           PageHead( report_name, page_width, page_number, col_head1, col_head2 )
          endif
          @ prow()+1, 1 say operator->name
          for x := 1 to len( operator->mask )
           @ prow(), 20 + ( x * 2 ) say if( substr( operator->mask, x, 1 ) = SEC_CHAR, 'X', ' ' )
          next
          operator->( dbskip() )
       enddo
       Endprint()
      endif
     endif 
    endif

   case key = K_F9
    if mwork = 'OPERATOR'
     if substr( secmask, X_SUPERVISOR, 1 ) != SEC_CHAR .and. ;
          Oddvars( OPERCODE ) != operator->code
      Error( "You cannot set Somebody else's Password!", 12 )
     else
      sScreen := Box_Save( 3, 01, 5, 40 )
      @ 3, 2 say 'Setting Password for ' + trim( operator->name )
      set console off
      @ 4, 2 say 'Enter new password'
      accept to cNewPassword
      @ 4, 2 say 'Retype new password'
      accept to cNewPassword2
      set console on
      if cNewPassword != cNewPassword2
       Error( 'Passwords do not match - password not changed', 12 )
      else
       SysAudit( 'PWChangeBy'+Oddvars( OPERCODE )+'On'+operator->code+"!"+hb_decrypt( operator->password, CRYPTKEY )+'!'+cNewPassword )
       Rec_lock( 'operator' )
       operator->password := hb_encrypt( upper( padr( cNewPassword, 10 ) ), CRYPTKEY )
       operator->( dbrunlock() )

      endif
      Box_Restore( sScreen )
     endif
    endif

#endif

   otherwise
    if key = K_BS .or. key > 32
     if key = K_BS
      keybuff:=substr(keybuff,1,max(len(keybuff)-1,0))
     else
      keybuff+=upper(chr(key))
     endif
     dbseek( keybuff, TRUE )
     if !empty( keybuff )
      @ 1,42 say '< ' + keybuff + ' >-'
     else
      @ 1,42 say replicate('Ä',20) color if(iscolor(),'B+/','W/')+substr(syscolor(),at("/",syscolor())+1,2)
     endif
     oTBrowse:refreshall()
    endif
   endcase

  endif

 enddo
 Box_Restore( sscr )

else

 validation := TRUE
 if procname( 7 ) = 'ADD_TITL' .and. mwork == 'BRAND'
  if !empty( brand->supp_code ) .and. empty( master->supp_code )
   master->supp_code := brand->supp_code
  endif
 endif 
endif
goto dup_rec
select ( lastarea )
if !waopen
 ( workarea )->( dbclosearea() )
endif
return validation

*

function SetupSec
local tscr, getlist:={}, x,mstr
local sa := array( len( operator->mask ) )  // security array
Heading( 'Set Security Profile' )
for x := 1 to len( operator->mask )
 sa[ x ] := if( substr( operator->mask, x, 1 ) == SEC_CHAR, TRUE, FALSE )

next
tscr:=Box_Save( 02, 01, 22, 78, C_GREY ) 
@ 02, 02 say ' Security Profile for ' + trim( operator->name )
@ 03, 05 say 'Supervisor' get sa[ X_SUPERVISOR ] pict 'y'
@ 04, 06 say 'File Menu' get sa[ X_FILES ] pict 'y'
@ 05, 02 say 'Purchase Menu' get sa[ X_PURCHASE ] pict 'y'
@ 06, 05 say 'Sales Menu' get sa[ X_SALES ] pict 'y'
@ 07, 03 say 'Utility Menu' get sa[ X_UTILITY ] pict 'y'
@ 09, 13 say 'Debtors' get sa[ X_DEBTORS ] pict 'y'
@ 10, 02 say 'Transaction Access' get sa[ X_DEBTRANS ] pict 'y'
@ 11, 05 say 'Debtors Reports' get sa[ X_DEBREPS ] pict 'y'
@ 12, 09 say 'Debtors EOM' get sa[ X_DEBEOM ] pict 'y'
@ 13, 04 say 'Debtors Balances' get sa[ X_DEBBALMOD ] pict 'y'
@ 15, 11 say 'Creditors' get sa[ X_CREDITORS ] pict 'y'
@ 16, 02 say 'Transaction Access' get sa[ X_CREDTRANS ] pict 'y'
@ 17, 03 say 'Creditors Reports' get sa[ X_CREDREPS ] pict 'y'
@ 18, 07 say 'Creditors EOM' get sa[ X_CREDEOM ] pict 'y'
@ 19, 02 say 'Creditors Balances' get sa[ X_CREDBALMOD ] pict 'y'
@ 21, 06 say 'Gen Ledger' get sa[ X_GENERAL ] pict 'y'

@ 03, 30 say '   Invoicing' get sa[ X_INVOICES ] pict 'y'
@ 04, 30 say 'Credit Notes' get sa[ X_CREDITNOTES ] pict 'y'
@ 05, 30 say ' Cash Drawer' get sa[ X_CASHDRAWER ] pict 'y'
@ 06, 30 say ' Sales Voids' get sa[ X_SALEVOID ] pict 'y'
@ 03, 50 say 'Add to Files' get sa[ X_ADDFILES ] pict 'y'
@ 04, 50 say '  Edit Files' get sa[ X_EDITFILES ] pict 'y'
@ 05, 50 say 'Delete Files' get sa[ X_DELFILES ] pict 'y'
@ 06, 47 say 'Perform Globals' get sa[ X_GLOBALS ] pict 'y'

@ 10, 29 say '    Stocktake' get sa[ X_STOCKTAKE ] pict 'y'
@ 11, 29 say ' System Utils' get sa[ X_SYSUTILS ] pict 'y'
@ 12, 29 say 'Sales Reports' get sa[ X_SALESREPORTS ] pict 'y'
read
mstr := ''
for x := 1 to len( operator->mask )
 mstr += if( sa[ x ] , SEC_CHAR, ' ' )

next
operator->mask := mstr
return tscr

*

function login ( allow_add )
local mret := FALSE, mpass, ocode, sScreen, getlist := {}, x, mfound
local oc := setcursor(1), okf10, okf9, nOrigSelect := select(), backdoor := FALSE
local okaltl := setkey( K_ALT_L, nil )
static lFlag:=FALSE

default allow_add to FALSE

if !lFlag
 lFlag := TRUE
 if Netuse( 'operator' )
  if !file( Oddvars( SYSPATH ) + 'operator' + ordbagext() )
   indx( 'code','code' )

  endif
  if operator->( lastrec() ) = 0  // Operator file is Empty - Create Default Supervisor
   Add_rec( 'operator' )
   operator->code := 'XX'
   operator->name := 'Supervisor'
   operator->mask := replicate( SEC_CHAR, 10 ) // Will give supervisor security
   operator->( dbrunlock() )

  endif
  for x:=1 to 3
   sScreen := Box_Save( 12, 25, 15, 55 )
   ocode := space( OPERATOR_CODE_LEN )
   okf9 := setkey( K_ALT_F9, { || BackDoor( @backdoor ) } )
   okf10 := setkey( K_F10, { || if( !allow_add, nil, Dup_Chk( '^%&^', 'operator' ) ) } )
   @ 13,27 say 'Operator Code' get ocode pict '@!' ;
             valid( if( allow_add, dup_chk( ocode, 'operator' ), TRUE ) )
   read
   setkey( K_ALT_F9, okf9 )
   setkey( K_F10, okf10 )
   mfound := operator->( dbseek( ocode ) ) 
   if !empty( operator->password ) .and. !backdoor .or. !mfound
    @ 14,27 say 'Enter Your Password'
    set console off
    accept to mpass
    set console on

    if mfound .and. ( upper( padr( mpass, 10 ) ) = hb_decrypt( operator->password, CRYPTKEY ) )
     Oddvars( OPERCODE, operator->code )
     Oddvars( OPERNAME, operator->name )
     secmask := operator->mask
     x := 4
     mret := TRUE

    else
     if x = 3
      SysAudit( "PWordVio" + trim( ocode ) + '|' + trim( mpass ) + '|' )
      Error( SYSNAME + ' Security Violation - Bye Bye' , 12 )
      close databases
      cls
      quit

     else
      Error('Invalid Login Attempt - try again',12)

     endif

    endif
   else
    if backdoor
     Oddvars( OPERCODE, '!!!' )
     Oddvars( OPERNAME, 'Back Door!' )
     secmask := replicate( SEC_CHAR, 10 )

    else
     Oddvars( OPERCODE, operator->code )
     Oddvars( OPERNAME, operator->name )
     secmask := operator->mask

    endif
    x := 4
    mret := TRUE

   endif
   Box_Restore( sScreen )

  next
  operator->( dbclosearea() )

 endif
 lFlag := FALSE

endif            
select ( nOrigSelect )
setcursor( oc )
setkey( K_ALT_L, okaltl )
return mret

*

function backdoor ( backdoor )
local mpass, getlist := {}
set console off
accept to mpass
set console on
backdoor := ( upper( mpass ) == 'COWPER' )
keyboard chr( 13 )
return nil

*

#ifdef SECURITY
function secure ( area )
if area = nil .or. substr( secmask, area, 1 ) = SEC_CHAR .or. ;
   substr( secmask, X_SUPERVISOR, 1 ) = SEC_CHAR 
 return TRUE
else
 Error( 'No Security Rights for this Area' , 12 )
endif
return FALSE
#else
function secure ( area )
area = nil
return TRUE
#endif

*

function matrix_disp
local tscr:=Box_Save( 14, 01, 20, 78, C_GREY ), getlist:={}
Center( 15,'Discount Matrix')
@ 16,04 say 'A     B     C     D     E     F     G     H     I     J     K     L     M'
@ 17,02 get brand->disc_a
@ 17,08 get brand->disc_b
@ 17,14 get brand->disc_c
@ 17,20 get brand->disc_d
@ 17,26 get brand->disc_e
@ 17,32 get brand->disc_f
@ 17,38 get brand->disc_g
@ 17,44 get brand->disc_h
@ 17,50 get brand->disc_i
@ 17,56 get brand->disc_j
@ 17,62 get brand->disc_k
@ 17,68 get brand->disc_l
@ 17,74 get brand->disc_m
@ 18,04 say 'N     O     P     Q     R     S     T     U     V     W     X     Y     Z'
@ 19,02 get brand->disc_n
@ 19,08 get brand->disc_o
@ 19,14 get brand->disc_p
@ 19,20 get brand->disc_q
@ 19,26 get brand->disc_r
@ 19,32 get brand->disc_s
@ 19,38 get brand->disc_t
@ 19,44 get brand->disc_u
@ 19,50 get brand->disc_v
@ 19,56 get brand->disc_w
@ 19,62 get brand->disc_x
@ 19,68 get brand->disc_y
@ 19,74 get brand->disc_z
read
return tscr

*

function LookItUp ( sWorkArea, sReturn, sFieldName, sIndexOrder )
local slastarea := select()
local nDuplRec, waopen:=FALSE, sOldIndexOrder
default sfieldname to 'name'
default sIndexOrder to 'code'

if select( sWorkArea ) = 0
 if !Netuse(sWorkArea )
  return ''
 endif
else
 waopen := TRUE
endif

select ( sWorkArea )
nDuplRec := recno()
sOldIndexOrder := ordsetFocus( sIndexOrder )

if !dbseek( sReturn )
 sReturn := if( pcount() = 3, fieldget( fieldpos( sfieldname ) ), '' )

else
 sReturn := if( pcount() = 2, trim((select())->name), fieldget( fieldpos( sfieldname ) ) )

endif

ordsetfocus( soldIndexorder )
goto nDuplRec

select ( slastarea )
if !waopen
 ( sWorkArea )->( dbclosearea() )
endif

return sReturn

*

function idcheck ( sID )
/*
local ntot := 0, nInc, sChkDigit,sNewCheckDigit

do case
case left( sID ,3 ) = '978'
 sID := substr( sID, 4, 10 )
case len(sID) != 10
 return(sID)
endcase
sID := trim( left( sID, 9 ) )
for nInc := 1 to 9
 ntot += val( substr( sID, nInc, 1 ) ) * ( 11 - nInc )

next nInc

sChkDigit := ntot % 11

do case
case sChkDigit = 10
 sNewCheckDigit := '1'
case sChkDigit = 0
 sNewCheckDigit := '0'
case sChkDigit = 1
 sNewCheckDigit := 'X'
otherwise
 sNewCheckDigit := Ns( 11 - sChkDigit, 1 )
endcase
sID += sNewCheckDigit
*/
return sID

*

function CalcAPN ( cCodein )
local nEven := 0, nOdd := 0, nStep :=2, nResult
local cCode := left( cCodein, 12 )
while nStep < 13
 nEven += val( substr( cCode, nStep, 1 ) )
 nOdd +=  val( substr( cCode, nStep-1, 1 ) )
 nStep += 2

enddo
nResult := 10-(10*((( nEven*3 ) + nOdd )/ 10-int((( nEven*3 ) + nOdd ) / 10 ) ) )

if nResult = 10
 nResult := 0

endif
return (cCode + str( nResult, 1 ) )

*

function Vs ( sArg )   // Gets over rounding errors
return val( str( sArg, 10, 2 ) )

*

function zero ( n1, n2 )
if Vs( n2 ) != 0
 return ( n1 / n2 )

endif
return 0

*

function center ( row, text )
local oldcon := set( _SET_CONSOLE, TRUE )
local olddev := set( _SET_DEVICE, 'Screen' )
if row = 24
 line_clear(24)
endif
@ row,(79/2) - (len(trim(text))/2) say text
set( _SET_CONSOLE, oldcon )
set( _SET_DEVICE, olddev )
return nil

*

function Box_Save ( t, l, b, r, c )   // top,left,bottom,right,colour  // the Array version
local scbuff1,scbuff2,scmask1,scmask2,oldcolor:=setcolor(), ssave
default t to 0, l to 0, b to 24, r to 79
ssave:=savescreen( t, l, min( b+1, 24 ), min( r+2, 79 ) )
if pcount() = 5
 syscolor(c)
endif
if ( b < 24 .or. r < 79 .or. t >= 1 )
 @ t,l clear to b,r
 @ t,l to b,r color 'B+/' + substr( syscolor(), at("/",syscolor())+1, 2 )
 if b <= 24-1 .and. r <= 79-2
  scbuff1 := savescreen(b+1,l+2,min(24,b+1),min(79,r+2))
  scbuff2 := savescreen(t+1,r+1,min(24,b+1),min(79,r+2))
  scmask1 := replicate("X"+chr( lvars( L_COLATTR ) ),len(scbuff1)/2)
  scmask2 := replicate("X"+chr( lvars( L_COLATTR ) ),len(scbuff2)/2)
  restscreen(min(24,B+1),L+2,min(24,B+1),min(79,R+2),transform(scbuff1,scmask1))
  restscreen(min(24,t+1),min(79,R+1),min(24,B+1),min(79,R+2),transform(scbuff2,scmask2))
 endif
endif
return { t, l, min( 24, b+1 ), min( 79, r+2 ), ssave, oldcolor, setcursor(), row(), col() }

*

Function Box_Restore ( marray )    // restore a screen saved in array format
restscreen( marray[ 1 ], marray[ 2 ], marray[ 3 ], marray[ 4 ], marray[ 5 ] )
setcolor( marray[ 6 ] )
setcursor( marray[ 7 ] )
@ marray[ 8 ], marray[ 9 ] say ''
return nil 

*

function line_clear ( line_no )
@ line_no,0 say space(79+1)
return ""

*

function syscolor ( p_colour )

local c_colour := setcolor(), sOldColour

static sTColour := 1
sOldcolour := sTcolour

do case
case p_colour = C_NORMAL
 if substr( lvars( L_REGISTER ) , 1, 5 ) = "TRAIN"
  setcolor( 'Gr+/r, w+/r,,,w/r' )

 else
  setcolor( 'GR+/' + C_BACKGROUND + ', w+/r,,,w/r' )

 endif

case p_colour = C_INVERSE
 setcolor( 'n/w', 'i' )

case p_colour = C_BRIGHT
 setcolor( 'w+/' + C_BACKGROUND + ', w+' )

case p_colour = C_MAUVE    // 4
 setcolor( 'w/rb,w+/r,,,w/r', 'w+' )

case p_colour = C_GREY     // 5
 setcolor( 'w+/w', 'w+' )

case p_colour = C_YELLOW   // 6
 setcolor( 'gr+/r', 'w+' )

case p_colour = C_GREEN    // 7
 setcolor( 'w+/g', 'w+' )

case p_colour = C_CYAN     // 8
 setcolor( 'w/bg+,w+/gr,,,bg+/bg', 'w+' )

endcase

STColour := p_colour
return c_colour

*

function isready ( p_row, p_col, ptext, pcolor )  // Universal "OK to Proceed" Function
default ptext to  'Ok to Proceed ?'
p_row := nil
p_col := nil
pColor := nil
return ( if( messagebox( , ptext, "Input required", MB_YESNO ) = MB_RET_YES, TRUE, FALSE) )
/*
local sScreen,p_prompt,plen
default pcolor to C_NORMAL
plen := len( trim( ptext ) )/2
default p_col to ( 79/2 ) - plen            // Default Column
sScreen := Box_Save( p_row, p_col, p_row+3, p_col+( plen*2 )+3 , 3, pcolor )
@ p_row+1,p_col+2 say ptext
@ p_row+2,p_col+plen-2 prompt 'No'
@ p_row+2,p_col+plen+3 prompt 'Yes'
// messagebox( ptext, "where is this" )

menu to p_prompt
Box_Restore( sScreen )
return ( p_prompt = 2 )
*/
*

function highlight ( nRow, nCol, sStr1, sStr2, sPict )
@ nRow, nCol say sStr1
if pcount() = 5
 @ nRow, nCol + len( sStr1 ) + 1 say sStr2 pict ( sPict ) color ('W+/' + ;
                substr( syscolor(), at( "/", syscolor() ) + 1, 2 ) )

else
 SysColor( C_INVERSE )
 @ nRow, nCol + len( sStr1 ) + 1 say sStr2  color "W+/" + C_BACKGROUND   // color (sColours)
 SysColor( C_NORMAL )

endif
return nil

*

function master_use   
local ok := FALSE
if Netuse( 'master' )
 Repeat( master->( lastrec() ) ) 
 ok := TRUE

endif
return ok



function mem_avail
local sScreen:=Box_Save(10,20,14,60),oldcur:=setcursor(0)
Error('',16)
Box_Restore( sScreen )
setcursor( oldcur )
return NIL

*

function ns ( pnum,plen,pdec )
do case
case pcount() = 1
 return ltrim( str( pnum ) )
case pcount() = 2
 return ltrim( str( pnum,plen ) )
case pcount() = 3
 return ltrim( str( pnum, plen, pdec ) )
endcase
return nil

*

function kill ( file_name )
local mcol := col(), mrow := row()
if file( file_name )
 ferase( file_name )

endif
return nil

*

function Sysinc ( sysval, action, value, chkdbf )
local nOrigSelect:=select(), retval:=0, nFieldPosition, firstwarn:=FALSE, oldord
if Netuse( 'sysrec', SHARED, 0 )
 nFieldPosition := fieldpos( sysval )
 Rec_lock()
 do case
 case action = 'I'    // Increment system value
  if fieldget( nFieldPosition ) + value >= 1000000
   fieldput( nFieldPosition, 1 )
  else
   fieldput( nFieldPosition, fieldget( nFieldPosition ) + value )
  endif
 case action = 'R'    // Replace System value
  fieldput( nFieldPosition, value )
 case action = 'A'    // Add to system value
  fieldput( nFieldPosition, fieldget( nFieldPosition ) + value )
 endcase
 retval := fieldget( nFieldPosition )
 if chkdbf != nil .and. action = 'I'
  oldord := ( chkdbf )->( ordsetfocus( 'number' ) )
  while TRUE .and. Pinwheel( NOINTERUPT )
   if !( chkdbf )->( dbseek( retval ) )
    exit
   else
    if !firstwarn
     Error( 'System value detected on file already', 12, 2,'Looking for next free number' )
     firstwarn := TRUE
    endif 
    if fieldget( nFieldPosition ) + value >= 1000000
     fieldput( nFieldPosition, 1 )
    else
     fieldput( nFieldPosition, fieldget( nFieldPosition ) + value )
    endif
    retval := fieldget( nFieldPosition )
   endif
  enddo  
  ( chkdbf )->( ordsetfocus( oldord ) )
 endif
 dbcommit()
 dbclosearea()
endif
select ( nOrigSelect )
return ( retval )

*

function fil_lock ( wait, malias )
local forever,nCount
if malias = nil
 malias := alias()
endif
if (malias)->( flock() )
 return TRUE  // locked
endif
forever := (wait = 0)
nCount := 1
while (forever .or. wait > 0)
 inkey(.5)
 wait -= .5
 nCount++
 if int(nCount/5) = nCount/5
  Error('Waiting for file '+malias+' to be unlocked by other users',12,.5)
 endif
 if ( malias)->( flock() )
  return TRUE
 endif
enddo
return FALSE

*

procedure SysAudit( p_det )
local nOrigSelect := select()
if file( Oddvars( SYSPATH ) + "system.dbf" )
 if Netuse( "system" )
  Add_rec()
  system->details := p_det + left( dtoc( Bvars( B_DATE ) ), 5 ) + left( time(), 5 ) + lvars( L_REGISTER )
#ifdef SECURITY
  system->details := trim( system->details ) + '|' + Oddvars( OPERCODE )
#endif
  system->( dbclosearea() )
 endif
 select ( nOrigSelect )
endif
return

*

function printgraph ( oPrinter )  // Prints the screen
local char:=0
local x
local pgraph := savescreen( 0, 0, 24, 79 )
local mlen := len( pgraph )
local pstr:=''
local lKill := FALSE  // This allows the screen print to be embedded in another prn object

if oPrinter = nil  // the error system relies on this.
 oPrinter := PrintCheck( 'Screen Print' )  // Setup and returns a printer object
 lKill := TRUE

endif

for x := 1 to mlen step 2
 pstr += substr( pgraph, x, 1 )
 char++
 if char = 80
  char := 0
  oPrinter:TextOut( pstr )
  oPrinter:NewLine()
  pstr := ''

 endif

next

if lKill
 oPrinter:EndDoc()
 oPrinter:Destroy()

endif

return nil

*

procedure id_exchg ( old_id, new_id )
local nOrigSelect:=select(), sScreen:=Box_Save( 2, 10, 5, 70, C_GREY ), x, idfocus, otherlock 
local dbflist:={"ytdsales","poline","special","draft_po","invline","approval",;
                    "layby","kit","stkhist","macatego","hold",;
                    "salehist","recvline","pickslip","stock" }
/* If you update this proc please check its mate in BRTRANS.PRG */
Center( 3, 'Exchanging ' + ID_DESC + ' on all files - Please Wait',TRUE)
Rec_lock('master')
master->id := new_id
master->( dbrunlock() )
old_id := substr( old_id,1,12 )
for x := 1 to len( dbflist )
 idfocus := FALSE
 if Netuse( dbflist[x], SHARED, 10, 'idchg' )
  Center( 4, 'File ' + padr( dbflist[ x ], 20 ) )
  if ordnumber( 'id' ) != 0
   ordsetfocus( 'id' )
   dbseek( old_id )
   idfocus := TRUE
  else
   locate for idchg->id = old_id  // no index by id for dbf so seek by locate
  endif
  while found() .and. Pinwheel( NOINTERUPT )
   otherlock := TRUE
   if select( dbflist[ x ] ) != 0       // File is open elsewhere
    if ascan( ( dbflist[ x ] )->( dbrlocklist() ), recno() ) != 0
     ( dbflist[ x ] )->id := new_id
     otherlock := FALSE
     dbcommitall()
    endif 
   endif
   if otherlock
    Rec_lock( 'idchg', dbflist[ x ] )
    idchg->id := new_id
    idchg->( dbrunlock() )
   endif
   if idfocus
    dbseek( old_id )
   else
    dbskip( 1 )
    continue
   endif
  enddo
  idchg->( dbclosearea() )
 endif
next
select ( nOrigSelect )
Box_Restore( sScreen )
return

*

function stcheck
local sScreen:=Box_Save( 2, 10, 7, 20 ), stret
@ 3,12 prompt '1 '+Ns( Bvars( B_ST1 ), 4, 1 )+'%'
@ 4,12 prompt '2 '+Ns( Bvars( B_ST2 ), 4, 1 )+'%'
@ 5,12 prompt '3 '+Ns( Bvars( B_ST3 ), 4, 1 )+'%'
@ 6,12 prompt '0 Exempt'
menu to stret
if stret >= 4
 stret := 0
endif
Box_Restore( sScreen )
keyboard chr(5)+Ns(stret)+chr(13)  // Stuff Keyboard with home,ctrl-y etc
return TRUE


/*function get_search_str()
local getlist:={}, sString := space(14)
local nCursor := setcursor(1), cscr := Box_Save( 8, 53, 10, 76 )
@9,54 say 'String:' get sString picture "@!"
read
setcursor( nCursor )
Box_Restore( cscr )
return ( sString )

*/

*

function add_item ( sid, msupp )
local currec:=master->( recno() ), sScreen, lfoundkey := FALSE, sSubString, getlist:={}
local lAccept, okins := setkey( K_INS , nil ), okf8 := setkey( K_F8 , nil ), hasarchive

local idnum := space( ID_ENQ_LEN ), catnum:=space(15)
local there := FALSE, mfpos, y
local fromArchive := FALSE

default msupp to ''

if empty(sid)
 sScreen:=Box_Save( 3,23,5,57 )
 sid := space( ID_ENQ_LEN )
 #ifdef IS_BOOKSHOP
 @ 4,26 say 'New Code/id' get sid pict '@!'
 #else
 @ 4,26 say 'New PLU' get sid pict '@!'
 #endif
 read
 Box_Restore( sScreen )

endif

if !empty( sid )
 if Codefind( sid )
  itemdisp( FALSE )

 else
  if left( sid, 1 ) $ "/.,';="
   Error( "Illegal first character '"+substr( sid,1,1 )+"' in PLU/id",12 )

  else
   lAccept := TRUE
   sid := trim( sid )
#ifdef BOOKSHOP   
   sSubString := substr( sid, 1, 2 )
   do case
   case len( sid ) = 13 .and. ( sSubString = '97' .or. sSubString = '93' .or. sSubString = '94' )
    sid := CalcAPN( sid )   // Dud (no check digit) Keyboard/CalcAPN readers

   case SYSNAME = 'BPOS' .and. len( sid ) = 10 .and. !isalpha( sid )
    if sid != idcheck( sid )
     Error( PLU_DESC + ' Code not verified', 8 )
     sScreen := Box_Save( 08, 10, 11, 70 )
     Highlight( 09, 12, 'Old id', sid )
     Highlight( 09, 35, 'New Calculated Value', idcheck( sid ) )
     @ 10,25 say 'Accept Calculated Value' get lAccept pict 'Y'
     read
     Box_Restore( sScreen )
    endif
    sid := CalcAPN( '978' + sid )

   endcase

#endif

   if lAccept
    hasarchive := !( select( 'archive' ) = 0 )
    if !hasarchive
     if file( Oddvars( SYSPATH ) + "archive\archive.dbf" )
      if Netuse( Oddvars( SYSPATH ) + "archive\archive", SHARED, 10, 'archive', NEW, 'archive\archive','id' )
       hasarchive := TRUE

      endif     

     endif

    endif

    if hasarchive 
     if archive->( dbseek( left( sid, 12 ) ) )
      sScreen := Box_Save( 08, 10, 12, 72 )
      Highlight( 09, 12, '', 'Item Exists in Archive' )
      Highlight( 10, 12, 'Description ->', substr( archive->desc, 1, 40 ) )
      if Isready( 12, 10, 'Retrieve Item from archive?' )
       Add_rec( 'master' )
       for y := 1 to archive->( fcount() )
        mfpos := master->( fieldpos( archive->( fieldname( y ) ) ) )
        if mfpos != 0
         master->( fieldput( mfpos, archive->( fieldget( y ) ) ) )
        endif
       next y
       if archive->( fieldpos( 'brand' ) ) != 0
          master->supp_code := ;
          if( lookitup( 'supplier', archive->supp_code ) != '',archive->supp_code,;
           lookitup( 'brand', archive->brand, 'supp_code' ) )
       else
          master->supp_code := archive->supp_code
       endif
       fromArchive := TRUE
      endif 
      Box_Restore( sScreen )
     endif
     archive->( dbclosearea() )
     keyboard chr( K_ENTER )  
    endif 

    if !fromArchive

     Add_rec( 'master' )
     master->id := sid
     master->sale_ret := Bvars( B_SALERET )
     master->minstock := Bvars( B_REORDQTY )
     master->entered := Bvars( B_DATE )
     master->supp_code := msupp
	 master->sales_tax := TRUE  			// Death and taxes
     keyboard chr( K_ENTER )                // Stuff kbrd to get over id ?

    endif

    itemdisp( TRUE, , ,TRUE )    // This last True prevents

    if lastkey() = K_ESC .or. empty( master->desc ) .or. empty( master->supp_code )
     Rec_lock('master')
     master->( dbdelete() )
     master->( dbrunlock() )
     Error(if(lastkey()=K_ESC,'<Esc> pressed',if(empty(master->desc),'No desc';
             ,'No 1st Supplier - the Item record must have a supplier'))+' - Record Deleted',12)
    else
     lfoundkey := TRUE
     Repeat( master->( recno() ) )   // Save last record number for repeat func

    endif

   endif

  endif
  if !lfoundkey
   master->( dbgoto( currec ) )

  endif

 endif

endif
setkey( K_INS, okins )
setkey( K_F8, okf8 )
return lfoundkey

*

func vidmode ( lines )
if( lvars( L_MAXROWS ) > 25 , setmode( lines, 80 ) , nil )
return nil

*

procedure Repeat ( nPrevRecord )
local nCurrentRecord := master->( recno() ), cType, sToRepeat, sFieldName

if nPrevRecord = nil  // No record to repeat
 nPrevRecord := nPrevRecord

else
 default nPrevRecord to 0
 if upper( alias() ) = 'MASTER'
  master->( dbgoto( nPrevRecord ) )
  sFieldName := trim( substr( readvar(), rat( '>', readvar() ) + 1, 10 ) )
  sToRepeat := fieldget( fieldpos( sFieldName ) )
  master->( dbgoto( nCurrentRecord ) )
  cType := valtype( sToRepeat )

  do case
  case cType = 'N'
   sToRepeat := Ns( sToRepeat, 8, 2 )

  case cType = 'D'
   sToRepeat := dtoc( sToRepeat )

  case cType = 'L'
   sToRepeat := if( sToRepeat,'Y','N' )

  case cType = 'U'
   sToRepeat := ''
  endcase

  keyboard sToRepeat + chr( K_ENTER )

 endif
endif
return

*

function backspace ( mpos, mstr )
local x
default mstr to master->desc
default mpos to 40
for x := mpos to 1 step -1
 if substr( mstr, x, 1 ) = ' '
  return( x )
 endif
next
return( mpos )  // No spaces return string pos

*

function norm_cat ( catno )
return catno

*

function show_open_areas( )
 
local oBrowse,nKey,i, arr := {}
local sScreen:=Box_Save(1,15,24-2,79-40)
local element := 1, getlist:={}

for i := 1 to 250
 if !empty(alias(i))
  aadd(arr,alias(i))
 endif
next

if len(arr) = 0
 aadd(arr,"")
endif

oBrowse:= TBrowseNew(2, 16, 24-3, 79-41)
oBrowse:colorspec := if( iscolor(), TB_COLOR, setcolor() )
oBrowse:HeadSep := HEADSEP
oBrowse:ColSep := COLSEP
oBrowse:goTopBlock := { || element := 1 }
oBrowse:goBottomBlock := { || element := len(arr) }
oBrowse:skipBlock := { |n| ArraySkip(len(arr), @element, n) }
oBrowse:addcolumn(tbcolumnNew('Open Work Areas', { || padr(arr[element],20) } ) )
nKey := 0
while nKey != K_ESC
 oBrowse:forcestable()
 nKey := inkey(0)
 if !navigate( oBrowse, nKey )
  if nKey == K_F10
   oBrowse:refreshall()
  endif
 endif
enddo
Box_Restore( sScreen )

return nil

*
function GetGSTComponent( nValue )
return nValue / 11

*

function CalcGst ( nValue, nGST )
return nvalue / ( 100 / nGST )

*

function percentof ( n1, n2 )
return 100-zero( n1,( n2 / 100 ) )

*

function Check_fld_len
// A Utility to check the DBFs for required field lengths
local aArray := asort( directory( Oddvars( SYSPATH ) + '*.dbf' ), , ,{ |p1,p2| p1[1] < p2[1] } ), x, y, z, fhandle 
local sScreen := Box_Save( 20, 10, 23, 40 )
local type_arr := { { 'SUPP_CODE', SUPP_CODE_LEN },;
                    { 'id', ID_CODE_LEN }, ;
                    { 'DEPARTMENT', DEPT_CODE_LEN }, ;
                    { 'BRANCH', BRANCH_CODE_LEN }, ;
                    { 'KEY', CUST_KEY_LEN } }
fhandle := fcreate( 'dberrors.txt' )
@ 22, 12 say 'File - dberrors.txt'
for x := 1 to len( aArray )
 if Netuse( aArray[ x, 1 ] )
  @ 21, 12 say aArray[ x, 1 ]
  for y := 1 to fcount()
   for z := 1 to len( type_arr )
    if fieldname( y ) = type_arr[ z, 1 ] .and. valtype( fieldget( y ) ) = 'C' .and. ;
       len( fieldget( y ) ) !=  type_arr[ z, 2 ]
     fwrite( fhandle, padr( aArray[ x, 1 ], 15 ) + padr( fieldname( y ), 15 ) + ;
              padl( len( fieldget( y ) ), 10 ) + padl( type_arr[ z, 2 ], 10 ) + CRLF )
    endif
   next
  next
  dbclosearea()
 endif
next
fclose( fhandle )
Box_Restore( sScreen )
sScreen := Box_Save( 07, 02, 23, 76 )
memoedit( memoread( 'dberrors.txt' ), 08, 3, 22, 75 )
Box_Restore( sScreen )
return nil


*

function GetSuppCode ( top, left, wild, morehelp ) // this morehelp could be an array for help
// Will allow you to retreive a supplier code in a generic sense
local sScreen, getlist:={}
//local msupp := padr( Oddvars( MSUPP ), SUPP_CODE_LEN )
local msupp := space( SUPP_CODE_LEN )
default wild to FALSE
default morehelp to ''
sScreen := Box_Save( top, left, top+2+if( wild, 1, 0 ) + if( !empty( morehelp ), 1, 0 ), ;
           left +  max( 18 + SUPP_CODE_LEN, len( morehelp ) ), C_MAUVE )
if wild
 @ top+2, left+2 say '"*" = All Suppliers'

endif
if !empty( morehelp )
 @ top+3, left+2 say morehelp

endif

@ top+1, left+2 say 'Supplier Code' get msupp pict '@K!' ;
                valid( if( wild, msupp = '*', FALSE ) .or. Dup_chk( msupp , "Supplier" )  )
read
Box_Restore( sScreen )
Oddvars( MSUPP, msupp )
return msupp

*

Function Build_HDMast
local aArray, sScreen, kill_it := FALSE

if len( directory( 'c:\' ) ) = 0
 Error( 'Problem finding the c: Drive', 12 )
else 
 
 sScreen := Box_Save( 7, 10, 12, 70 )

 if len( directory( 'c:\standby', 'D' ) ) = 0
  Shell( 'md c:\standby' )
 endif

 if file( Oddvars( SYSPATH ) + 'hdpos.exe' )
  Center( 8, 'Copying latest hdpos.exe' )
  copy file ( Oddvars( SYSPATH ) + 'hdpos.exe' ) to ( 'C:\standby\hdpos.exe' )
 endif

 if Netuse( 'sales' )
  copy stru to c:\standby\sales.str
  sales->( dbclosearea() )
 endif
  
// This allows new structures to be uploaded at will
 if file( 'c:\standby\sales.dbf' )
  if Netuse( 'c:\standby\sales' )
   kill_it := ( sales->( reccount() ) = 0 )
   sales->( dbclosearea() )
  endif
 endif

 if kill_it
  Kill( 'c:\standby\sales.dbf' )
 endif    

 if !file( 'c:\standby\hdmast.dbf' )

  aArray := {}
  aadd( aArray, { 'id', 'c', ID_CODE_LEN, 0 } )
  aadd( aArray, { 'desc', 'c', 60, 0 } )
  aadd( aArray, { 'sell_price', 'n', 9, 2 } )
  aadd( aArray, { 'cost_price', 'n', 9, 2 } )
  aadd( aArray, { 'nodisc', 'l', 1, 0 } )
  dbcreate( 'c:\standby\hdmast', aArray )

 endif

 if Netuse( 'c:\standby\hdmast', EXCLUSIVE )

  if Isready( 12, 12, 'Start the update process' )

   Center( 10, 'Creating Standby Master File' )

   zap 
   appe from master while Pinwheel( NOINTERUPT )

   if !file( "c:\standby\hdsid" + ordbagext() )

    Center( 11, ' Indexing Standby Master File' )
    indx( 'id', 'id' )
    indx( 'upper( desc )', 'desc' )

   endif

   Error( 'Procedure Finished', 17 )

   Box_Restore( sScreen )

  endif

  hdmast->( dbclosearea() )

  copy file ( Oddvars( SYSPATH ) + 'nodes.dbf' ) to c:\standby\nodes.dbf
  copy file ( Oddvars( SYSPATH ) + 'bvars.dbf' ) to c:\standby\bvars.dbf

  endif

endif   

return nil

*

#ifdef TERMINALCOUNT
function TermCnt()
local mterms, TermName, FileName, ternCount

TermName := trim( lvars( L_NODE ) )
if sysinc( "FlagStk","G")              // If stocktake in progress, all unlimited terminals
 return TRUE
endif

if len( TermName ) > 8
 TermName := Oddvars( SYSPATH ) + "archive\" + right( TermName, 8 ) + ".bt"
else
 TermName := Oddvars( SYSPATH ) + "archive\" + TermName + ".bt"
endif

if ( FileName := Fcreate( TermName, FC_HIDDEN ) ) !=-1
 Fwrite( FileName, DEVELOPER + " Terminal Control File" )
 Fwrite( FileName, CRLF )
 TermName := "This site is licensed for " + Ns( TERMINALCOUNT ) + " terminals"
 Fwrite( FileName, TermName )
 Fclose( FileName )
endif
TermName := FileName := {}
TermName := directory( Oddvars( SYSPATH ) + "archive\*.bt","H" )

for ternCount := 1 to len( TermName )
 if at( "H", TermName[ ternCount, 5 ] ) != 0
  aadd( FileName, TermName[ ternCount ] )
 endif
next

if len(FileName) > TERMINALCOUNT               // defined in BPOS.ch
 return FALSE

endif

return TRUE
*

function DelTerm()
local mlvars := lvarget(), TermName

TermName := trim( mlvars[ L_NODE ] )
if len(TermName)>8
 TermName := Oddvars( SYSPATH ) + "archive\" + right(TermName,8) + ".bsa"
else
 TermName := Oddvars( SYSPATH ) + "archive\" + TermName + ".bsa"
endif
ferase( TermName )

return TRUE
#endif

*
function ShowCallStack()

   local aStack := {}
   local nCnt   := 0
   local cStr   := ''
   local lFirst := .t.

   for nCnt := 2 to 15
     if empty(procname( nCnt))
       nCnt := 16
     else
       cStr := ' ' + pad( procname( nCnt), 15) + 'L ' + str( procline( nCnt), 5) + ' '
       aadd( aStack, { iif( lFirst, ' ', '')+cStr, 'Function:' + cStr})
       lFirst := .f.
     endif
   next

   MenuGen( aStack, 3, 10 , 'Call Stack', , , TRUE )
  
return nil

*

function ArraySkip( alen, curpos, howmany )
local actual
if howmany >= 0
 if (curpos +howmany) > alen
  actual := alen-curpos
  curpos := alen
 else
  actual := howmany
  curpos += howmany
 endif
else
 if (curpos +howmany) < 1
  actual := 1-curpos
  curpos := 1
 else
  actual := howmany
  curpos += howmany
 endif
endif
return actual
