/*

Re Daemon - A process to run in the regional server to do file polling and updates

      Last change: APG 9/03/2009 6:47:02 PM
*/

#include "bpos.ch"

#xcommand DEFAULT <v1> TO <x1> [, <vn> TO <xn> ]                        ;
	  =>                                                            ;
	  IF <v1> == NIL ; <v1> := <x1> ; END                           ;
	  [; IF <vn> == NIL ; <vn> := <xn> ; END ]
	  

#define C1 'W/B,W+/R,,,W/R' 
#define C2 'N/W'  
#define C3 'W+/B' 
#define C4 'W+/RB,W+/R,,,W/R' 
#define C5 'W+/W' 
#define C6 'GR+/R' 
#define C7 'W+/G' 
#define C8 'W+/Bg,W+/GR,,,BG+/BG' 
#define C9 'Gr+/N,W+/N,,,W/N' 

#define BS_DIR 'booktrac'

#define BOX2 .t.

#define RAS

local stkfiles, z, y, x, interval := 60, it_took := 60, start, err_ret, mstruct, mkey
local mstr, mloc, downfiles, slsfiles, rcvfiles, trffiles, mtranarr
local mfiles, i, aArray, mpoll_int, mpoll_comp

set scoreboard off   // No <Ins> etc
set confirm on       // Must Hit Enter
set deleted on       // Dont Show Deleted Records
set date british     // Rule Britannia !
set wrap on          // Wrap Menus - Right On!
set epoch to 1980

cmxautoshare( 0 )
cmxAutoOrder( 1 )               // Automatically set production indexes to first tag
V_files( 2 )                    // Flexfiles Max use count for Abstract Files
V_exclusive( FALSE )            // Set non exclusive Flexfile use.

Syscolor( C_NORMAL )

cls
Heading( 'Regional File Processor' )
if Netuse( 'reparams' )
 mpoll_int := reparams->poll_int
 mpoll_comp := reparams->poll_comp
 reparams->( dbclosearea() )
endif 

if !Netuse( 'branches' )
 quit
endif 

StatusBox( 'Run commenced at ' + time() )

while TRUE

 mkey := inkey( interval )   // Wait until next run

 if mkey == K_F10
  Filemaint()
 elseif mkey = K_F9
  Params_maint()
 elseif mkey == K_ESC
  if Isready( 12, 10, 'Ok to halt ReDaemon' )
   quit
  endif
 endif  
     
 StatusBox( 'Processing commenced at ' + time() )
 start := seconds()


 branches->( dbgotop() )
 // read the list of available server directories to poll
 while !branches->( eof() ) 
  qout()
 #ifdef RAS
  Shell( 'rasdial ' + trim( branches->ras_entry ) )
  err_ret := swperrlev()
 #else
  err_ret := 0
 #endif
  if err_ret != 0
   StatusBox( 'Rasdial returned error no ' + Ns( err_ret ) )
  else
   Shell( 'net use i: /d' )
   Shell( 'net use i: \\' + trim( branches->server_name ) + '\booktrac' )
   err_ret := swperrlev()
   if err_ret != 0
    StatusBox( 'Unable to map transfer on ' + branches->server_name  )
    StatusBox( 'Error level was ' + Ns( err_ret ), BOX2 )
   else 

  // All Right! - Connected to the server 

  //************* Transaction Types
    mtranarr := { 'stk', 'sls', 'bnk', 'rcv', 'trf', 'por' }

    for i := 1 to len( mtranarr )

     mfiles := Directory( 'i:transfer\?????' + mtranarr[ i ] + '.*' )           

     if len( mfiles ) = 0
      StatusBox( 'No ' + mtranarr[ i ] +' files found to process in ' + branches->server_name )  
     endif 

     for x := 1 to len( mfiles )
      
      if Netuse( 'i:transfer\' + mfiles[ x, 1 ], EXCLUSIVE, , 'branch' )

       if !file( 'toho\' + mfiles[ x, 1 ] )
        mstruct := dbstruct()
        dbcreate( 'toho\' + mfiles[ x, 1 ],  mstruct )
       endif

       if Netuse( 'toho\' + mfiles[ x, 1 ], , , 'region' ) 

        while !branch->( eof() )                             // Process the records to update stock
	 add_rec( 'region' )          
	 for y := 1 to branch->( fcount() )                  // Move the stock record to the regional server dbf
	  region->( fieldput( y, branch->( fieldget( y ) ) ) )  
	 next
	 del_rec( 'branch' )                                 // delete the old record
	 branch->( dbskip() )
        enddo

        region->( dbclosearea() )

       endif
       branch->( dbclosearea() )

       Kill( 'i:transfer\' + mfiles[ x, 1 ] )
	
      endif // Netuse

     next   // Stkfile

    next    // Tranfer file type ( mtranarr )
    
  // Put data back to the branches here
    stkfiles := directory( 'to' + trim( branches->storecode ) + '\stk?????.dbf' )
    if !empty( stkfiles ) 
     if Netuse( 'i:stock' )
      ordsetfocus( BY_ID )
       for y := 1 to len( stkfiles )
        if Netuse( 'to' + trim( branches->storecode ) + '\' + stkfiles[ y, 1 ], EXCLUSIVE, , 'stkupdt' )
	 while !stkupdt->( eof() )
	  if !stock->( dbseek( stkupdt->id + stkupdt->storecode ) )
	   Add_rec('stock')
	   stock->id := stkupdt->id 
	   stock->storecode := stkupdt->storecode
	  endif

	  Rec_lock( 'stock' )
	  stock->onhand := stkupdt->onhand
	  stock->available := stkupdt->available
	  stock->onorder := stkupdt->onorder

	  stock->( dbrunlock() )
	  stkupdt->( dbskip() )

	  Highlight( 13, 12,'Records Checked',Ns( stkupdt->( recno() ) ) )
	 enddo
	 stkupdt->( dbclosearea() )
        endif
        kill( 'to' + trim( branches->storecode ) + '\' + stkfiles[ y, 1 ] )
       next
      stock->( dbclosearea() )
     endif
    endif
       
   endif   // Able to map drive on server

  // Send Other previously processed here

  // Disconnect

#ifdef RAS
   dbcommitall()
   inkey( 20 )
   qout()
   Shell( 'rasdial ' + trim( branches->ras_entry ) + ' /d' )
#endif

  endif

  branches->( dbskip() )

 enddo  

/* 

 Read the data that has come from the ho server now ( in 'fromho' )
 and process into another dir because the result set from HO will
 need to be sent ( and processed ) x times ( for the number of branches ).

*/

 downfiles := Directory( 'fromho\*.*' ) 
 branches->( dbgotop() )
 while !branches->( eof() )
  for x := 1 to len( downfiles )
   copy file ( 'fromho\' + downfiles[ x, 1 ] ) to ( 'to' + branches->storecode + '\' + downfiles[ x, 1 ] )
  next x
  branches->( dbskip() )
 enddo  

 for x := 1 to len( downfiles )   // Clean up the directory
  kill( 'fromho\' + downfiles[ x, 1 ] )
 next

 // Process all the good things here ( Hopefully not a lot of work here )

 // Write files to the head office if required

 StatusBox( 'Processing Ended at ' + time() )
 StatusBox( 'Elapsed = ' + Ns( seconds() - start ) + ' seconds.' )
  
enddo 
dbcloseall()
quit
*

function Netuse ( p_file, ex_use, wait, p_alias, lnewarea )
local forever, mcount := 1, x, aArray

default ex_use to TRUE
default wait to 10
default p_alias to nil
default lnewarea to .t.

forever := ( wait = 0 )
lnewarea := ( lnewarea != nil ) .and. lnewarea
if !file( p_file + '.dbf' )
 do case
 case p_file = 'reparams'
  aArray := {}
  aadd( aArray, { 'poll_int', 'n', 5, 0 } )
  aadd( aArray, { 'poll_comp', 'c', 8, 0 } )
  dbcreate( 'reparams', aArray )
 case p_file = 'branches'
  aArray := {}
  aadd( aArray, { 'ras_entry', 'c', 15, 0 } )
  aadd( aArray, { 'server_name', 'c', 15, 0 } )
  aadd( aArray, { 'inactive', 'l', 1, 0 } )
  aadd( aArray, { 'storecode', 'c', 3, 0 } )
  dbcreate( 'branches', aArray )
 otherwise
  Statusbox( 'File ' + p_file + ' cannot be located - exiting' )
  quit
 endcase 
endif
while ( forever .or. wait > 0 )
 dbusearea( lnewarea, 'COMIX', p_file, p_alias, !ex_use )
 if !neterr()
  return TRUE
 endif
 inkey(1)
 --wait
 mcount++
 if int(mcount/5) = mcount/5
  StatusBox( 'Waiting for file ' + p_file + ' to become Available' )
 endif
enddo
StatusBox( 'File ' + p_file + ' unavailable' )
return FALSE
*
function add_rec ( mfile ) // Bugger it add the record or else !!
default mfile to alias()
(mfile)->( dbappend() )
while neterr()             // Error from last attempt
 StatusBox( 'Attempting to append new record to ' + mfile ) // Warn 'em
 (mfile)->( dbappend() )   // Attempt to add again
enddo                      // Test and loop ?
return TRUE                // OK so back we go
*
function del_rec( mfile )
default mfile to alias()
Rec_lock( mfile )
( mfile )->( dbdelete() )
( mfile )->( dbrunlock() )
return nil
*
function rec_lock ( mfile, real_name )
default mfile to alias()
default real_name to mfile
if select(real_name) = 0
 real_name := mfile
endif
if !( ( mfile )->( eof() ) )  
 while !( mfile )->( dbrlock() ) 
  StatusBox( 'Waiting for record in ' + real_name + ' to be freed', 12, 5, ;
   transform( ( mfile )->( fieldget(1) ), '@!' )+' '+procname( 1 )+' '+str( procline( 1 ) ) )
  inkey( 1 )
 enddo
endif
return TRUE
*
func params_maint
local mscr := Bsave( 2, 10, 5, 50 ), getlist := {}
if Netuse( 'reparams')
 @ 3, 12 say 'Regular Poll interval (minutes)' get reparams->poll_int pict '99999'
 @ 4, 12 say '          Compulsory Poll start' get reparams->poll_comp pict '99:99:99'
 read
 reparams->( dbclosearea() )
endif
Brest( mscr )
return nil
* 
func filemaint
local sscr,key:=0,auto_close:=FALSE,lastarea:=select()
local bloop,dup_rec,oTBrowse,validation:=FALSE,mndex,oc,newpass,newpass2,aHelpLines
local getlist:={},mdept,msupp,mcat,mscr,tscr,keybuff

select branches            // All cool use the file !!
sscr := Bsave( 1, 39, 22, 77  )
oTBrowse:=tbrowsedb( 2, 40, 21, 76 )
oTBrowse:HeadSep := HEADSEP
oTBrowse:ColSep := COLSEP
oTBrowse:addcolumn( tbcolumnnew( "RAS Entry", { || branches->ras_entry } ))
oTBrowse:addcolumn( tbcolumnnew( "Name", { || branches->server_name } ))
oTBrowse:addcolumn( tbcolumnnew( "Active", { || if( branches->inactive, 'No ', 'Yes' ) } ) )
oTBrowse:addcolumn( tbcolumnnew( "Store Code", { || branches->storecode } ) )
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
   aadd( aHelpLines, { '<Enter>', 'Edit Item' } )
   aadd( aHelpLines, { '<Del>', 'Delete Item' } )
   aadd( aHelpLines, { '<Ins>', 'Add New Item' } )
   Build_help( aHelpLines )
  case key == K_ESC .or. key == K_END
   exit
  case key == K_DEL
   if Isready( 12,,'Ok to delete '+trim(branches->ras_entry)+' from file')
    Rec_lock()
    delete
    dbrunlock()
    eval( oTBrowse:skipblock , -1 )
    oTBrowse:refreshall()
    if flock()
     pack
     dbunlock()
    endif 
   endif
  case key == K_F10 .or. key == K_INS
   mscr := Bsave( 09, 01, 14, 72, C_GREY )
   if key == K_INS
    branches->( dbappend() )
   endif 
   @ 10, 03 say '  RAS Entry' get branches->ras_entry 
   @ 11, 03 say 'Server Name' get branches->server_name
   @ 12, 03 say '   Inactive' get branches->inactive pict 'y'
   @ 13, 03 say ' Store Code' get branches->storecode pict '!!!' ;
	    valid !empty( branches->storecode )
   read
   if empty( directory( 'to' + trim( branches->storecode) , 'D' ) )
    Shell( 'md ' + 'to' + trim( branches->storecode ) )
   endif
   Brest( mscr )
   oTBrowse:refreshall()
  endcase
 endif
enddo
Brest( sscr )
return nil
*
function ns ( pnum,plen,pdec )
do case
case pcount() = 1
 return ltrim(str(pnum))
case pcount() = 2
 return ltrim(str(pnum,plen))
case pcount() = 3
 return ltrim(str(pnum,plen,pdec))
endcase
return nil
*
function BSave ( t, l, b, r )   // top,left,bottom,right,colour  // the Array version
local scbuff1,scbuff2,scmask1,scmask2, ssave
default t to 0, l to 0, b to 24, r to 79
ssave:=savescreen( t, l, min( b+1, 24 ), min( r+2, 79 ) )
if ( b < 24 .or. r < 79 .or. t >= 1 )
 @ t,l clear to b,r
 @ t,l to b,r color if(iscolor(),'B+/','W/')+substr(setcolor(),at("/",setcolor())+1,2)
 if b <= 24-1 .and. r <= 79-2
  scbuff1 := savescreen(b+1,l+2,min(24,b+1),min(79,r+2))
  scbuff2 := savescreen(t+1,r+1,min(24,b+1),min(79,r+2))
  scmask1 := replicate("X"+chr( 1 ),len(scbuff1)/2)
  scmask2 := replicate("X"+chr( 1 ),len(scbuff2)/2)
  restscreen(min(24,B+1),L+2,min(24,B+1),min(79,R+2),transform(scbuff1,scmask1))
  restscreen(min(24,t+1),min(79,R+1),min(24,B+1),min(79,R+2),transform(scbuff2,scmask2))
 endif
endif
return { t, l, min( 24, b+1 ), min( 79, r+2 ), ssave, nil, setcursor(), row(), col() }
*
Function BRest ( marray )    // the array version of above
restscreen( marray[ 1 ], marray[ 2 ], marray[ 3 ], marray[ 4 ], marray[ 5 ] )
setcursor( marray[ 7 ] )
@ marray[ 8 ], marray[ 9 ] say ''
return nil 
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
 did := FALSE
endcase
return did
*
function isready ( p_row, p_col, ptext, pcolor )  // Universal "OK to Proceed" Function
local mscr,getlist:={},p_prompt,plen
default pcolor to C_NORMAL
default ptext to  'Ok to Proceed ?'
plen := len( trim( ptext ) )/2
default p_col to ( 79/2 ) - plen            // Default Column
mscr := Bsave( p_row, p_col, p_row+3, p_col+( plen*2 )+3 , 3, pcolor )
@ p_row+1,p_col+2 say ptext
@ p_row+2,p_col+plen-2 prompt 'No'
@ p_row+2,p_col+plen+3 prompt 'Yes'
menu to p_prompt
Brest( mscr )
return ( p_prompt = 2 )
*
function highlight ( r, c, t1, t2, p_pict )  
local cs := trim( strtran( setcolor(), '+' ) ) // remove any enhanced colors
local slashpos := at( "/", cs )
local commapos := at( ",", cs )
@ r,c say t1
if pcount() = 5
 @ r,c+len(t1)+1 say t2 pict (p_pict) color ( if( iscolor(),'W+/','W/')+substr( syscolor(),at("/",syscolor())+1,2) )
else
 @ r,c+len(t1)+1 say t2 color ( left( cs, slashpos-1 ) + '+/' + substr( cs, slashpos + 1, commapos-slashpos-1 ) + substr( cs, commapos, len( cs ) - commapos ) )
endif
return nil
*
function syscolor ( p_color )
local c_color := setcolor()
do case
case p_color = 1                                 // White on Blue
 setcolor( C1 )
case p_color = 2                                 // Grey on White
 setcolor( C2 )
case p_color = 3                                 // Highlight white on Blue
 setcolor( C3 )
case p_color = 4                                 // Mauve Background
 setcolor( C4 )
case p_color = 5                                 // Grey Background
 setcolor( C5 )
case p_color = 6                                 // Yellow on red
 setcolor( C6 )
case p_color = 7                                 // Green Background
 setcolor( C7 )
case p_color = 8                                 // Cyan Background
 setcolor( C8 )
case p_color = 9                                 // Black Background
 setcolor( C9 )
endcase
return c_color
*
Function Build_help ( aArray, wait )
local mwidth := 0, x, mscr, oldcur := setcursor( SC_NONE )
default wait to len( aArray ) 
for x := 1 to len( aArray )
 mwidth := max( mwidth, len( aArray[ x, 1 ] ) + len( aArray[ x, 2 ] ) )
next
mscr := Bsave( 24-3-len( aArray ) , 79-4-mwidth, 24-2, 79-2, C_YELLOW )
for x := 1 to len( aArray )
 @ 24-3-len( aArray )+x, 79-3-mwidth say aArray[ x, 1 ]
 @ 24-3-len( aArray )+x, 79-2-len( aArray[ x, 2 ] ) say aArray[ x, 2 ]
next
if inkey( wait ) = K_SPACE
 while inkey( 0 ) != K_SPACE
 enddo 
endif
brest( mscr )
setcursor( oldcur )
return nil
*
function kill ( file_name )
if file( file_name )
 ferase( file_name )
endif
return nil
*
Static function statusbox ( message, box2 )
static sbox1, handle, sbox2
if sbox1 = nil
 sbox1 := Bsave( 2, 1, 17, 78 )
 sbox2 := Bsave( 18, 2, 24, 78 )
 handle := fcreate( 'redaemon.log', 0 )
else
 if box2 = nil
  scroll( 3, 2, 16, 77, -1 )
  @ 3, 3 say message
 else
  scroll( 19, 3, 23, 77, -1 ) 
  @ 20, 3 say message
 endif
endif
fwrite( handle, message + CRLF )
return nil
*
procedure heading ( newtext )
static oldtext                                 // Last Heading Used
local olddev:=set(_SET_DEVICE,"screen"), oc:=setcolor()
newtext:= if( empty( newtext ), oldtext, newtext )   // if no text passed
syscolor( C_INVERSE )                          // Heading Colors
line_clear( 0 )                                  // Clear top of screen
@ 0,0 say padc( newtext, 79 )
@ 0,1 say 'HO Daemon'                          // Display Terminal Name
@ 0,79-10 say date()
if !isnum()                                    // Is number lock engaged?
 syscolor( C_BRIGHT )                          // No ! tell'em
 @ 0,60 say 'NumLock!'
endif
Setcolor( oc )                                 // Reset Colors
oldtext := newtext                             // Rename Oldtext Variable
set(_SET_DEVICE, olddev )
return
*
function line_clear ( line_no )
@ line_no,0 say space(79+1)
return ""
*
function Shell ( swpstring, rundir )
local mscr := Bsave(), mret := TRUE
default rundir to ''
if !swpruncmd( swpstring, 0, rundir, "" )
 StatusBox( 'Swap Error - Major Code = '+Ns(swperrmaj())+' Minor Code = '+Ns(swperrmin()) )
 mret := FALSE
endif
Brest( mscr )
return mret
