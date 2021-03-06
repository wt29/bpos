/*

      Last change:  TG   29 Apr 2011    3:32 pm
*/

Procedure Saleinq2

#include "bpos.ch"

procedure ItemDelete
local mans:=NO,o_id,getlist:={},okf9,okf10,mscr,okaf1
local oldcur:=setcursor(1), olddbf:=select(), oldrec:=recno(), farr, x

if Secure( 1, X_DELFILES )
 okf10:=setkey( K_F10, nil )
 okf9 :=setkey( K_F9, nil )
 okaf1 := setkey( K_ALT_F1, nil )
 if master->onhand != 0 .or. master->onorder != 0 .or. master->minstock != 0
  Error( 'All Quantities must be zero to delete', 12 )
 else
  mscr := Box_Save( 02, 08, 08, 72 )
  Highlight( 3, 10, 'Desc  ', trim( master->desc ) )
  Highlight( 5, 10, ALT_DESC, trim( master->alt_desc ) )
  if Isready( 7, 10, 'Ok to delete this desc' )
   o_id := master->id
   SysAudit( "TiDel" + o_id )
   Del_rec( 'master' )
//   if !empty( master->abs_ptr )      // Delete o Abstract
//    Abs_delete( 'master' )
//   endif
   master->( dbrunlock() )

   if ytdsales->( dbseek( o_id ) )
    Del_rec( 'ytdsales', UNLOCK )
   endif

   farr := { "stkhist", "macatego", "poline", "salehist" }
   for x := 1 to len( farr )
    if Netuse( farr[ x ], SHARED, 10, "temp" ) 
     ordsetfocus( 'id' )
     temp->( dbseek( o_id ) )
     while temp->id = o_id .and. !temp->( eof() )
      Del_rec( 'temp', UNLOCK )
      temp->( dbskip() )
     enddo
     temp->( dbclosearea() )
    endif
   next
  endif
  DispItem()
 endif
 setkey( K_F10, okf10 )
 setkey( K_F9, okf9 )
 setkey( K_ALT_F1, okaf1 )
endif
select ( olddbf )
goto oldrec
setcursor(oldcur)
return

*
Function abs_edit ( mfile, sAlias, lIsLocked )
local mscr
local msel := select()
local okalta := setkey( K_ALT_A, nil )
local okalts := setkey( K_ALT_S, nil )
local oktab := setkey( K_TAB, nil )
local okf10 := setkey( K_F10, nil )
local okf6 := setkey( K_F6, nil )
local okshf6 := setkey( K_SH_F6, nil )
local okcp := setkey( K_CTRL_P, nil )

local cFileName
default lIsLocked to FALSE

sAlias := lower( if( sAlias == nil, mfile, sAlias ) )

do case
case sAlias = 'master'
 cFileName = Oddvars( SYSPATH) + "mcomments\" + trim( master->id ) + ".txt"

case sAlias = 'customer'
 cFileName = Oddvars( SYSPATH) + "ccomments\" + trim( customer->key ) + ".txt"

case sAlias = 'supplier'
 cFileName = Oddvars( SYSPATH) + "scomments\" + trim( supplier->code ) + ".txt"

otherwise
 error( "Problem with comments 'alias' - Contact " + DEVELOPER, 12)
 return nil

endcase

if !lIsLocked
 rec_lock( sAlias )

endif 
mscr := Box_Save( 09, 04, 24, 76, RGB_RED )
@ 9, 10 say '< Hit Esc to abandon Changes - Ctrl-W to save Changes>'
MemoWrit( cFileName, MemoEdit( MemoRead( cFilename ), 10, 5, 23, 75 ) )

Box_Restore( mscr )

if !lIsLocked
 (sAlias)->( dbunlock() )

endif
 
setkey( K_SH_F6, okshf6 )
setkey( K_F6, okf6 )
setkey( K_F10, okf10 )
setkey( K_ALT_A, okalta )
setkey( K_ALT_S, okalts )
setkey( K_TAB, oktab )
setkey( K_CTRL_P, okcp )
select ( msel )

return nil

/*

Function abs_edit ( cfile, malias )
local mscr, cstr, msel := select()
local okalta := setkey( K_ALT_A, nil )
local okalts := setkey( K_ALT_S, nil )
local oktab := setkey( K_TAB, nil )
local okf10 := setkey( K_F10, nil )
local okf6 := setkey( K_F6, nil )
local okshf6 := setkey( K_SH_F6, nil )
local okcp := setkey( K_CTRL_P, nil )

mscr := Box_Save( 07, 02, 23, 76 )
Highlight( 7, 06, '', '[ Ctrl-W to save changes . Esc to Exit ' + cfile + ' entry ]' )
cstr := memoedit( cstr, 08, 03, 22, 75, TRUE )

// ( mal )->( dbrunlock() )
Box_Restore( mscr )

setkey( K_SH_F6, okshf6 )
setkey( K_F6, okf6 )
setkey( K_F10, okf10 )
setkey( K_ALT_A, okalta )
setkey( K_ALT_S, okalts )
setkey( K_TAB, oktab )
setkey( K_CTRL_P, okcp )
select ( msel )
return nil

*/

function Abs_delete ( mfile )
local mabs := mfile, osel := select()
return nil

*

procedure secondhand ( sh_flag )
keyboard Ns(Sysinc("secondhand",'I',1)) + chr(13)
sh_flag := TRUE
add_item()
return

*

function enq_cate
local sKey, mcode, mscr, msel:=select(), openmastcat:=FALSE
local getlist:={}, mrec, oldcur:=setcursor(1)
local sID := master->id, catebrow, nQty, oldntxord
local okf6 := setkey( K_F6, nil ), okf5, cPrompt
static lastcat
if Netuse( "category", SHARED, 10, 'ecat' )
 if Netuse( "macatego", SHARED, 10, 'emcat' )
  select emcat
  mrec := emcat->( recno() )     // Just in case store the record #
  oldntxord := emcat->( ordsetfocus( BY_ID ) )
  set relation to emcat->code into ecat
  dbseek( sID )
  Heading('Category on ' + ID_DESC + ' Maintenance')
  Box_Save(1,39,24-2,79-3)
  catebrow:=tbrowsedb(2,42,24-3,79-4)
  catebrow:HeadSep := HEADSEP
  catebrow:ColSep := COLSEP
  catebrow:goTopBlock:={||dbseek( sID )}
  catebrow:goBottomBlock:={||jumptobott( sID )}
  catebrow:skipblock := KeyskipBlock( {||emcat->id}, sID )
  catebrow:addcolumn(tbcolumnnew("Code",{||emcat->code}))
  catebrow:addcolumn(tbcolumnnew("Category Name",{||ecat->name}))
  sKey:=0
 // Something to do with automatic category maint from Add Item !!
  while sKey != K_ESC .and. sKey != K_END
   catebrow:forcestable()
   sKey:=inkey( 0 )
   if !Navigate( catebrow, sKey )
    do case
    case sKey == K_INS
	 cPrompt = 'Category to add to this ' + ITEM_DESC
     mscr := Box_Save( 02, 02, 05, 3 + len( cPrompt ) + 2 + CATEGORY_CODE_LEN )
     mcode := space(6)
     okf5 := setkey( K_F5, { || Stuffcat( lastcat ) } )
     @ 03,03 say cPrompt get mcode pict '@!' valid( dup_chk( mcode, "category" ) )
     read
     setkey( K_F5, okf5 )
     if !empty( mcode )
      nQty := 1
      Add_rec( 'emcat ')
      emcat->code := mcode
      emcat->id := master->id
      emcat->qty := nQty
      emcat->skey := upper( master->desc )
      emcat->( dbrunlock() )
      lastcat := emcat->code
     endif
     Box_Restore( mscr )
     emcat->( dbseek( sID ) )
     catebrow:refreshall()
    case sKey == K_DEL
     if Isready( 3, 5, 'Ok to delete category ' + trim( emcat->code ) + ' from this item?' )
      Del_rec( 'emcat', UNLOCK )
      seek sID
      catebrow:refreshall()
     endif
    endcase
   endif
  enddo
  emcat->( dbclosearea() )
  DispItem()
 endif
 ecat->( dbclosearea() )
endif
setkey( K_F6, okf6 )
select (msel)      // Who knows what file selected
setcursor(oldcur)
return TRUE

*

function Stuffcat ( mval )
keyboard mval + CRLF
return nil

*

func enq_hist ( lReturnVal )
local key,mscr,o_dbf:=select(),enqbrow,getlist:={},refrec
local oldcur:=setcursor(1), tscr, sID:=left( master->id, 12 )
local okf5:=setkey( K_F5, nil )
local nRecNo, nRecPos

default lReturnVal to 0
if Netuse( "stkhist", SHARED, 10, 'estk' )
 ordsetfocus( 'id' )
 if !dbseek( sID )
  Error("No History on File",12)
 else
  refrec := estk->( recno() )
  mscr:=Box_Save( 1, 39, 24-2, 79-3, C_CYAN )
  enqbrow:=tbrowsedb(2,40,24-3,79-4)
  enqbrow:HeadSep:=HEADSEP
  enqbrow:ColSep:=COLSEP
  enqbrow:goTopBlock:={||dbseek( sID )}
  enqbrow:goBottomBlock:={||jumptobott( sID )}
  enqbrow:skipBlock:=KeySkipBlock( {||estk->id},sID )
  enqbrow:addcolumn(tbcolumnnew("Date",{||estk->date}))
  enqbrow:addcolumn(tbcolumnnew("Reference",{||estk->reference}))
  enqbrow:addcolumn(tbcolumnnew("Qty",{||estk->qty}))
  enqbrow:addcolumn(tbcolumnnew("Type",{||histtype(estk->type)}))
  enqbrow:addcolumn(tbcolumnnew("Sell",{||transform( estk->sell_price, '9999.99') }))
  enqbrow:addcolumn(tbcolumnnew("Cost",{||transform( estk->cost_price, '9999.99') }))
  enqbrow:freeze:=1
  key := 0
  while key != K_ESC .and. key != K_END
   enqbrow:forcestable()
   key := inkey( 0 )
   if !navigate( enqbrow, key )
    do case
    case key == K_F10   // Edit a line item in history

     if Secure( X_EDITFILES )
      tscr := Box_Save( 2,10,4,70 )
      Rec_lock()
      @ 3,12 say 'Date' get date valid( !empty( estk->date ) )
      @ 3,30 say 'Reference' get reference valid( !empty( estk->reference ) )
      @ 3,50 say 'Qty' get qty valid ( !empty( estk->qty ) )
      @ 3,60 say 'Type' get estk->type
      read
      dbrunlock()
      Box_Restore( tscr )
     endif
    case key == K_ENTER

/*  This bit tries to calculate the offset of a selected record from the first record
    in a stock history listing. It is used to select the invoice # etc to perform
    a supplier return to */

     nRecNo := recno()
     go refrec
     nRecPos := 0

     while estk->id = sID .and. !estk->( eof() ) .and. estk->( recno() ) != nRecNo
      nRecPos++
      estk->( dbskip() )
     enddo

     Oddvars( RETURNS_OFFSET, nRecPos )
     lReturnVal := nRecPos 
     lReturnVal := estk->( recno() )
     exit
    endcase
   endif
  enddo
  Box_Restore( mscr )
  Syscolor( 1 )
 endif
 estk->( dbclosearea() )
endif
select ( o_dbf )
setcursor( oldcur )
setkey( K_F5, okf5 )
return lReturnVal     //  lReturnVal

*

function histtype ( inval )
local mret
do case
case inval = "I"
 mret := "Received"
case inval = "T"
 mret := "Transfered"
case inval = "R"
 mret := "Returned"
case inval = "K"
 mret := "Kitted"
case inval = "S"
 mret := "Sold"
case inval = "L"
 mret := "Laybyed"
case inval = 'C'
 mret := "Credit Ret"
case inval = 'B'
 mret := 'Buy Back'
otherwise
 mret := "Unknown"+'('+inval+')'
endcase
return mret

*

func enq_sales
local mscr, o_dbf:=select(), enqbrow, lReturnVal:=0,getlist:={},oldrec:=recno()
local oldcur:=setcursor(1), tscr, sID:=substr(master->id,1,12), sKey
local totsold, totinv, totsoldv, totret, totretv, mrec
if Netuse("salehist",SHARED,10,'ehist' ) 
 ordsetfocus( 'id' )
 if !dbseek( sID )
  Error( "No sales History on File", 12 )
 else
  dbseek( sID+chr(256), TRUE )
  mscr:=Box_Save( 1, 39, 24-2, 79-3, C_CYAN )
  enqbrow:=tbrowsedb(2,40,24-3,79-4)
  enqbrow:HeadSep:=HEADSEP
  enqbrow:ColSep:=COLSEP
  enqbrow:goTopBlock:={||dbseek( sID )}
  enqbrow:goBottomBlock:={||jumptobott( sID )}
  enqbrow:skipBlock:=KeySkipBlock( { || ehist->id}, sID )
  enqbrow:addcolumn(tbcolumnnew("Date",{ || ehist->date }))
  enqbrow:addcolumn(tbcolumnnew("Qty",{ || ehist->qty }))
  enqbrow:addcolumn(tbcolumnnew("Cust Key",{ || if(empty(ehist->key),'Cash      ',ehist->key) }))
  enqbrow:addcolumn(tbcolumnnew("Sell",{ || transform( ;
          ehist->unit_price-ehist->discount, '9999.99' ) }))
  enqbrow:freeze := 1
  sKey := 0
  while sKey != K_ESC .and. sKey != K_END
   enqbrow:forcestable()
   sKey:=inkey(0)
   if !navigate(enqbrow,sKey)
    do case
    case sKey == K_F10   // Edit a line item in history
     if Secure( X_EDITFILES )
      tscr := Box_Save( 2, 10, 4, 70 )
      Rec_lock()
      @ 3,12 say 'Date' get date valid( !empty( ehist->date ) )
      @ 3,50 say 'Qty' get qty valid ( !empty( ehist->qty ) )
      read
      dbrunlock()
      Box_Restore( tscr )
     endif

    case sKey == K_F8
     mrec := ehist->( recno() )
     dbseek( sID + chr( 256 ), TRUE )
     totsold := 0
     totinv := 0
     totsoldv := 0
     totret := 0
     totretv := 0
     while ehist->id = sID .and. Pinwheel()
      if ehist->qty > 0
       totsold += ehist->qty
       totsoldv += ehist->qty * ( ehist->unit_price - ehist->discount )
      else
       totret += ehist->qty
       totretv += ehist->qty * ( ehist->unit_price - ehist->discount )
      endif 
      if !empty( ehist->key )
       totinv += ehist->qty
      endif
      ehist->( dbskip() )
     enddo
     ehist->( dbgoto( mrec ) )
     tscr := Box_Save( 2, 1, 8, 35 )
     Highlight( 3, 3, ' Total Qty Sold', Ns( totsold ) )
     Highlight( 4, 3, '   Inc Invoiced', Ns( totinv ) )
     Highlight( 5, 3, '   Sold $ Value', Ns( totsoldv, 9, 2 ) )
     Highlight( 6, 3, '    Returns Qty', Ns( totret ) )
     Highlight( 7, 3, 'Returns $ Value', Ns( totretv, 9, 2 ) )
     Error( '', 12 )
     Box_Restore( tscr )

    endcase
   endif
  enddo
  Box_Restore( mscr )
  Syscolor( 1 )
 endif
 ehist->( dbclosearea() )
endif
select ( o_dbf )
goto oldrec
setcursor(oldcur)
return lReturnVal

*

function enq_po
local cur_dbf:=select(),sID:=master->id,oBrowse,nKeyPressed,c,okf9:=setkey( K_F9, nil )
local oldscr:=Box_Save(),lReturnVal:=0,oldcur:=setcursor(1)
if select( "ep" ) != 0
 return lReturnVal
endif
if Netuse( "pohead", SHARED, 10, "eh" )
 if Netuse( "poline", SHARED, 10, "ep" ) 
  ordsetfocus( 'id' )
  dbsetrelation( "eh", {|| ep->number}, "NUMBER" )
  if !dbseek( sID )
   Error( 'No Purchase Orders found on this ' + ID_DESC, 12 )

  else
   eh->( dbseek( ep->number ) )
   cls
   Heading('Purchase Orders on Item')
   oBrowse := TBrowseDB(01, 0, 24, 79)
   oBrowse:HeadSep := HEADSEP
   oBrowse:ColSep := COLSEP
   oBrowse:goTopBlock := { || dbseek( sID ) }
   oBrowse:goBottomBlock  := { || jumptobott( sID ) }
   oBrowse:skipBlock := Keyskipblock( { || ep->id }, sID ) 
   c := tbcolumnnew( 'Number', { || ep->number } )
   c:colorblock := { || if( ep->qty != ep->qty_ord , {5, 6}, {1, 2} ) }
   oBrowse:addcolumn( c )
//   oBrowse:addcolumn( tbcolumnNew( 'R', { || if( empty( ep->abs_ptr ), ' ', '*' ) } ) )
   oBrowse:addcolumn( tbcolumnNew( 'Ship Date', { || ep->ship_date } ) )
   oBrowse:addcolumn( tbcolumnNew( 'Supp', { || eh->supp_code } ) )
   oBrowse:addcolumn( tbcolumnNew( 'Date Ord', { || eh->date_ord } ) )
   oBrowse:addcolumn( tbcolumnNew( 'Qty Ord', { || ep->qty_ord } ) )
   oBrowse:addcolumn( tbcolumnNew( 'Qty Rec', { || ep->qty_ord-ep->qty } ) )
   oBrowse:addcolumn( tbcolumnNew( 'Comments', { || substr( ep->comment, 1, 20 ) } ) )
   oBrowse:addcolumn( tbcolumnNew( 'B/O Date', { || ep->date_bord } ))
   oBrowse:freeze := 1
   nKeyPressed := 0
   while nKeyPressed != K_ESC .and. nKeyPressed != K_END
    oBrowse:forcestable()
    nKeyPressed := inkey(0)
    if !navigate(oBrowse,nKeyPressed)
     do case
     case nKeyPressed = K_ENTER
      lReturnVal := ep->number
      nKeyPressed := K_ESC
     case nKeyPressed = K_F10 .and. Secure( X_EDITFILES )
      Fpoadj( 'ep', 'eh' )
//     case nKeyPressed == K_ALT_A
//      Abs_edit( 'Poline', 'ep' )
     endcase
    endif
   enddo
  endif
  ep->( dbclosearea() )
 endif
 eh->( dbclosearea() )
endif
select (cur_dbf)
Box_Restore( oldscr )
setcursor(oldcur)
setkey( K_F9, okf9 )
return lReturnVal

*

function enq_serial
local cur_dbf:=select(),sID:=master->id,oBrowse,nKeyPressed,c,okf9:=setkey( K_F9, nil )
local oldscr:=Box_Save(),lReturnVal:=0,oldcur:=setcursor(1)
if select( "ep" ) != 0
 return lReturnVal
endif
if Netuse( "serial", SHARED, 10, "ep" )
 ordsetfocus( 'id' )
 if !dbseek( sID )
  Error('No record of serial numbers for this id found',12)
 else
  cls
  Heading('Serial Numbers Orders on id')
  oBrowse := TBrowseDB(01, 0, 24, 79)
  oBrowse:HeadSep := HEADSEP
  oBrowse:ColSep := COLSEP
  oBrowse:goTopBlock := { || dbseek( sID ) }
  oBrowse:goBottomBlock  := { || jumptobott( sID ) }
  oBrowse:skipBlock:=KeySkipBlock( {|| ep->id }, sID )
  c:=tbcolumnnew('Serial', { || ep->serial } )
  oBrowse:addcolumn( c )
  oBrowse:addcolumn(tbcolumnNew('Cust Key', { ||  ep->key } ) )
  oBrowse:addcolumn(tbcolumnNew('Invno', { || ep->invno } ) )
  oBrowse:addcolumn(tbcolumnNew('Date sold',{ || ep->date_sold } ) )
  oBrowse:freeze := 1
  nKeyPressed := 0
  while nKeyPressed != K_ESC .and. nKeyPressed != K_END
   oBrowse:forcestable()
   nKeyPressed := inkey(0)
   Navigate(oBrowse,nKeyPressed)
  enddo
 endif
 ep->( dbclosearea() )
endif
select (cur_dbf)
Box_Restore( oldscr )
setcursor(oldcur)
setkey( K_F9, okf9 )
return lReturnVal

*

procedure enq_spec
local cur_dbf:=select(), sID:=master->id, oBrowse, nKeyPressed, okf8:=setkey( K_F8, nil )
local oldscr:=Box_Save(), oldcur:=setcursor(1)
if Netuse( "customer", SHARED, 10, "ecust" )
 if Netuse( "special", SHARED, 10, "espec" )
  ordsetfocus( 'id' )
  set relation to espec->key into ecust
  if !dbseek( sID )
   Error( 'No Special Orders found', 12 )
  else
   cls
   Heading( 'Special Orders on ' + ID_DESC )
   oBrowse := TBrowseDB( 01, 0, 24, 79 )
   oBrowse:HeadSep := HEADSEP
   oBrowse:ColSep := COLSEP
   oBrowse:goTopBlock := { || dbseek( sID ) }
   oBrowse:goBottomBlock := { || jumptobott( sID ) }
   oBrowse:skipBlock:=KeySkipBlock( { || espec->id }, sID )
   oBrowse:addcolumn(tbcolumnNew('Number', { || espec->number } ) )
   oBrowse:addcolumn(tbcolumnNew('Name', { || ecust->name } ) )
   oBrowse:addcolumn(tbcolumnNew('Date Ord',{ || espec->date } ) )
   oBrowse:addcolumn(tbcolumnNew('Qty Ord', { || espec->qty } ) )
   oBrowse:addcolumn(tbcolumnNew('Qty Recv', { || espec->received } ) )
   oBrowse:addcolumn(tbcolumnNew('Qty Supp', { || espec->delivered } ))
   oBrowse:addcolumn(tbcolumnNew('Cust Ord',{ || espec->ordno } ) )
   oBrowse:addcolumn(tbcolumnNew('Deposit', { || espec->deposit } ) )
   oBrowse:addcolumn(tbcolumnNew('Comments',{ || espec->comments } ) )
   oBrowse:freeze := 1
   nKeyPressed := 0
   while nKeyPressed != K_ESC .and. nKeyPressed != K_END
    oBrowse:forcestable()
    nKeyPressed := inkey(0)
    navigate( oBrowse, nKeyPressed )
   enddo
  endif
  espec->( dbclosearea() )
 endif
 ecust->( dbclosearea() )
endif
select (cur_dbf)
Box_Restore( oldscr )
setcursor(oldcur)
setkey( K_F8, okf8 )
return

*

procedure enq_appr
local cur_dbf:=select(),sID:=master->id,oBrowse,nKeyPressed,okf7:=setkey( K_F7, nil )
local oldscr:=Box_Save(),oldcur:=setcursor(1)
if Netuse( "customer", SHARED, 10, "ecust" )
 if Netuse( "approval", SHARED, 10, "eappr" )
  ordsetfocus( 'id' )
  set relation to eappr->key into ecust
  if !dbseek( sID )
   Error('No Approval Orders found',12)
  else
   cls
   Heading( 'Approval Details on ' + ID_DESC )
   oBrowse := Tbrowsedb( 01, 0, 24, 79 )
   oBrowse:HeadSep := HEADSEP
   oBrowse:ColSep := COLSEP
   oBrowse:goTopBlock := { || dbseek( sID ) }
   oBrowse:goBottomBlock  := { || jumptobott( sID ) }
   oBrowse:skipBlock := Keyskipblock( { || eappr->id }, sID ) 
   oBrowse:addcolumn( tbcolumnnew( 'Number', { || eappr->number } ) )
   oBrowse:addcolumn( tbcolumnnew( 'Customer Name', { || substr( ecust->name, 1, 20 ) } ) )
   oBrowse:addcolumn( tbcolumnnew( 'Date Appr',{ || eappr->date } ) )
   oBrowse:addcolumn( tbcolumnnew( 'Appr Q', { || eappr->qty } ) )
   oBrowse:addcolumn( tbcolumnnew( 'Retn Q', { || eappr->received } ) )
   oBrowse:addcolumn( tbcolumnnew( 'Invo Q', { || eappr->delivered } ))
   oBrowse:addcolumn( tbcolumnnew( 'Comments',{ || eappr->comments } ) )
   oBrowse:freeze := 1
   nKeyPressed := 0
   while nKeyPressed != K_ESC .and. nKeyPressed != K_END
    oBrowse:forcestable()
    nKeyPressed := inkey(0)
    Navigate(oBrowse,nKeyPressed)
   enddo
  endif
  eappr->( dbclosearea() )
 endif
 ecust->( dbclosearea() )
endif
select (cur_dbf)
Box_Restore( oldscr )
setcursor(oldcur)
setkey( K_F7, okf7 )
return

*

procedure enq_course
local cur_dbf:=select(),sID:=master->id,oBrowse,nKeyPressed,c
local oldscr:=Box_Save(), oldcur:=setcursor(1)
if Netuse( "customer", SHARED, 10, "ecust" )
 if Netuse( "courlect", SHARED, 10 ,"elect" )
  set relation to elect->lectcode into ecust
  if Netuse( "course", SHARED, 10, "ecour" )
   if Netuse("courid", SHARED, 10, "eid" )
    ordsetfocus( 'id' )
    set relation to eid->code into ecour,;
                 to eid->code into elect
    if !dbseek( sID )
     Error('No courses attached',12)
    else
     cls
     Heading('Courses Attached to id')
     oBrowse := tbrowsedb(01, 0, 24, 79)
     oBrowse:headsep := HEADSEP
     oBrowse:colsep := COLSEP
     oBrowse:gotopblock := { || dbseek( sID ) }
     oBrowse:gobottomblock  := { || jumptobott( sID ) }
     oBrowse:skipblock:=KeySkipBlock( {|| eid->id }, sID )
     oBrowse:addcolumn(tbcolumnnew('Course', { || eid->code } ) )
     c:=tbcolumnnew('Name', { || ecour->name } ) 
     c:colorBlock := { || if( eid->dropped, ;
                     if( eid->core, { 8, 8 }, { 13, 10 } ), ;
                     if( eid->core, { 5, 6 }, { 1, 2 } ) ) }
     oBrowse:AddColumn( c )
     oBrowse:addcolumn(TBcolumnNew('Text',{ || if( eid->core ,'Text','Recm' ) } ) )
     oBrowse:addcolumn(TBcolumnNew('Dropped',{ || if( eid->dropped ,'Dropped','Current' ) } ) )
     oBrowse:addcolumn(TBcolumnNew('Lecturer', { || substr( ecust->name,1,15) } ) )
     oBrowse:addcolumn(TBcolumnNew('Ord Prev', { || transform( eid->order_prev, '9999' ) } ) )
     oBrowse:addcolumn(TBcolumnNew('Ord This', { || transform( eid->order_this, '9999' ) } ) )
     oBrowse:AddColumn(TBColumnNew('Term Used', { || eid->term_used  } ) )
     oBrowse:freeze := 1
     nKeyPressed := 0
     while nKeyPressed != K_ESC .and. nKeyPressed != K_END
      oBrowse:forcestable()
      nKeyPressed := inkey( 0 )
      Navigate( oBrowse, nKeyPressed )
     enddo
    endif
    eid->( dbclosearea() )
   endif
   ecour->( dbclosearea() )
  endif
  elect->( dbclosearea() )
 endif
 ecust->( dbclosearea() )
endif
select (cur_dbf)
Box_Restore( oldscr )
setcursor(oldcur)
return

*

procedure enq_kit
local cur_dbf:=select(),cur_rec:=recno(),oBrowse,nKeyPressed,mastprice:=master->sell_price
local sID:=master->id,oldscr:=Box_Save(), ksell, kcost
local oldcur:=setcursor(1),mastindord:=master->( indexord() ),mscr, mrec
local kit_master:=( master->binding = 'KI' )
master->( ordsetfocus( BY_ID ) )
if Netuse( "kit", SHARED, 10, 'ekit' )
 ordsetfocus( 'id' )
 set relation to ekit->id into master
 if kit_master
  ordsetfocus( BY_ID )
  set relation to ekit->id into master
 else
  ordsetfocus( BY_ID )
  set relation to ekit->id into master
 endif
 if !dbseek( sID )
  Error( 'No ' + if( kit_master, 'Kit Record', 'Kitted items' ) + ' found',12)
 else
  cls
  Heading( if( kit_master, '' + ITEM_DESC + ' on Kit # '+ sID, 'Kits id ' ;
          + trim( sID ) + ' is attached to' ) )
  oBrowse := TBrowseDB( 02, 0, 24, 79)
  oBrowse:HeadSep := HEADSEP
  oBrowse:ColSep := COLSEP
  oBrowse:goTopBlock := { || dbseek( sID ) }
  oBrowse:goBottomBlock  := { || jumptobott( sID ) }
  if kit_master
   oBrowse:skipBlock:=KeySkipBlock( { || ekit->id }, sID )
  else
   oBrowse:skipBlock:=KeySkipBlock( { || ekit->id }, sID )
  endif
  oBrowse:addcolumn(tbcolumnNew('id', { || idcheck( master->id ) } ) )
  oBrowse:addcolumn(tbcolumnNew('Desc', { || substr(master->desc,1,40) } ) )
  oBrowse:addcolumn(tbcolumnNew('Onhand', { || master->onhand } ) )
  oBrowse:addcolumn(tbcolumnNew('Price', { || transform( master->sell_price, '9999.99' ) } ) )
  oBrowse:addcolumn(tbcolumnNew('On order', { || master->onorder } ) )
  oBrowse:freeze := 1
  nKeyPressed := 0
  while nKeyPressed != K_ESC .and. nKeyPressed != K_END
   oBrowse:forcestable()
   nKeyPressed := inkey(0)
   if !navigate(oBrowse,nKeyPressed)
    if nKeyPressed == K_F8
     mrec := recno()
     seek sID
     sum master->sell_price*ekit->qty, master->cost_price*ekit->qty ;
         to ksell, kcost while ekit->id = sID .and. !ekit->( eof() )
     mscr:=Box_Save( 3, 10, 7, 50 )
     Highlight( 4, 12, 'Kit Price on file', Ns( mastprice, 9, 2 ) )
     Highlight( 5, 12, 'Calculated Kit Price', Ns( ksell, 9, 2 ) )
     Highlight( 6, 12, 'Calculated Kit Cost', Ns( kcost, 9, 2 ) )
     inkey(0)
     Box_Restore( mscr )
     goto mrec
    endif
   endif
  enddo
 endif
 ekit->( dbclosearea() )
endif
select ( cur_dbf )
goto cur_rec
master->( dbseek( sID ) )
master->( ordsetfocus( mastindord ) )
Box_Restore( oldscr )
setcursor(oldcur)
return

*

proc hold_em ( refresh, by_key )
local mscr, nQty:=1, mans:=FALSE, mdate:=Bvars( B_DATE ) - 180, getlist:={}
local oldord, currec, sKey, enqbrow, sscr, ckey, oldcur:=setcursor(1)
local sID:=master->id, saverec:=1, oldsel := select()

default by_key to FALSE

if select( "customer" ) = 0
 if !Netuse( "customer" )
  return
 endif
else
 saverec := recno()
endif

if select( 'master' ) = 0
 if !master_use()
  return
 endif
endif

if select( "hold" ) = 0
 if !Netuse( "hold" )
  return
 endif
endif

if select( 'master' ) = 0
 if !master_use()
  return
 endif
endif

if by_key
 ordsetfocus( 'key' )
 sID := customer->key  // I know that this is not strictly Kosher but who cares!
 hold->( dbsetrelation( 'master', { || hold->id } ) )
 hold->( dbseek( sID ) )
else
 ordsetfocus( 'id' )
 hold->( dbseek( sID ) )
endif

select hold
hold->( dbsetrelation( 'customer', { || hold->key } ) )

mscr := Box_Save( 1, 29, 22, 77, C_CYAN )
enqbrow:=tbrowsedb( 2, 30, 21, 76 )
enqbrow:HeadSep := HEADSEP
enqbrow:ColSep := COLSEP
enqbrow:goTopBlock := { || dbseek( sID ) }
enqbrow:goBottomBlock := { || jumptobott( sID ) }
if by_key
 enqbrow:skipBlock := KeySkipBlock( { || hold->key }, sID )
else
 enqbrow:skipBlock := KeySkipBlock( { || hold->id }, sID )
endif
if by_key
 enqbrow:addcolumn( tbcolumnnew( "Desc", { || left( master->desc, 15 ) } ) )
else
 enqbrow:addcolumn( tbcolumnnew( "Customer", { || left( customer->name, 15 ) } ) )
endif
enqbrow:addcolumn( tbcolumnnew( "Qty", { || hold->qty } ) )
enqbrow:addcolumn( tbcolumnnew( "Date", { || hold->date } ) )
while sKey != K_ESC .and. sKey != K_END
 enqbrow:forcestable()
 sKey := inkey( 0 )
 if !navigate( enqbrow, sKey )
  do case
  case sKey == K_DEL 
   if Isready( 3, 05, 'About to release '+Ns( hold->qty )+' item(s) held for ' + trim( left( Customer->name, 25 ) ) )
    Rec_lock( 'master' )
    master->held -= hold->qty
    master->( dbrunlock() )
    Del_rec( 'hold', UNLOCK )
    hold->( dbseek( sID ) )    // Be Careful here - Double meaning!
    enqbrow:refreshall()
   endif

  case sKey == K_INS
   if by_key .or. ( !by_key .and. CustFind( FALSE ) )
    ckey := customer->key
    sscr := Box_Save( 3, 30, 5, 50 )
    @ 4,32 say 'Qty to Hold' get nQty pict '999'
    read
    Box_Restore( sscr )
    if nQty > 0
     Rec_lock('master')
     master->held += nQty
     master->( dbrunlock() )
     Add_rec('hold')
     hold->id := master->id
     hold->key := ckey
     hold->qty := nQty
     hold->date := Bvars( B_DATE )
     hold->( dbrunlock() )
     hold->( dbseek( sID ) )
     enqbrow:refreshall()
    endif
    Box_Restore( sscr )
   endif
   select hold

  case sKey == K_SH_F10 .and. !by_key
   if Secure( X_EDITFILES )
    sscr := Box_Save( 2, 06, 5, 74 )
    @ 03,10 say 'Enter date for Purge' get mdate
    read
    if lastkey() != K_ESC
     Center(4,'You are about to release all Items on hold older than ' + dtoc(mdate))
     if Isready(6)
      SysAudit('HoldPurge')
      currec := master->( recno() )
      oldord := master->( ordsetfocus( 'id' ) )
      select hold
      hold->( dbsetrelat( 'master', { || hold->id } ) )
      hold->( dbgotop() )
      while !hold->( eof() )
       if hold->date <= mdate .and. !master->(eof())

        Rec_lock( 'master' )
        master->held -= hold->qty
        master->( dbrunlock() )

        Del_rec( 'hold', UNLOCK )

       endif
       hold->( dbskip() )
      enddo
      master->( ordsetfocus( oldord ) )
      master->( dbgoto( currec ) )
     endif
     enqbrow:refreshall()
    endif
    Box_Restore( sscr )
   endif
  endcase
 endif
enddo
Box_Restore( mscr )
syscolor( C_NORMAL )
hold->( dbclearrel() )
customer->( dbgoto( saverec ) )   // Added by David.
select ( oldsel )
setcursor( oldcur )
if refresh
 DispItem()
endif
return
*
func launcher
local mchoice, aArray, mscr := Box_Save()
while TRUE
 Heading( 'Function Launcher' )
 aArray := {}
 aadd( aArray, { 'Exit', '', , } )
 aadd( aArray, { 'Hold System', '', { || Hold_em( TRUE ) } } )
 aadd( aArray, { 'Sales History', '', { || Enq_sales() } } )
 aadd( aArray, { 'Movement History', '', { || Enq_hist() } } )
 aadd( aArray, { 'Category Maint', '', { || Enq_cate() } } )
 aadd( aArray, { 'Approvals on id', '', { || Enq_appr() } } )
 aadd( aArray, { 'Purchase Orders', '', { || Enq_po() } } )
 aadd( aArray, { 'Special Orders', '', { || Enq_spec() } } )
#ifdef ACADEMIC
 aadd( aArray, { 'id/Course Enquiry', '', { || Enq_course() } } )
 aadd( aArray, { 'Supercession', '', { || Supercession() } } )
#endif
 aadd( aArray, { 'Kit Enquiry', '', { || Enq_kit() } } )
#ifdef PREPACK
 aadd( aArray, { 'Booklists on id', '', { || Enq_bkls() } } )
#endif
 aadd( aArray, { 'Abstract Edit', '', { || Abs_edit( 'master' ) } } )
#ifdef HEAD_OFFICE
 aadd( aArray, { 'Stock at Other Branches', '', { || StockDisp( master->id ) } } )
#endif
#ifdef MULTI_LOCATIONS
 aadd( aArray, { 'Stock Locations', '', { || StockLocs( master->id ) } } )
#endif
#ifdef SERIAL
 aadd( aArray, { 'Serial Numbers', '', { || Enq_serial() } } )
#endif
 mchoice := MenuGen( aArray, 2, 10, , , C_GREY, TRUE )
 if mchoice < 2
  exit
 else
  eval( aArray[ mchoice, 3 ] )
 endif
enddo
Box_Restore( mscr )
return nil

*

procedure StockDisp ( sID )
local cur_dbf:=select(), cur_rec:=recno(), stkbrow, sKey
local oldcur:=setcursor( 1 ), mscr

if Netuse( "branch", SHARED, 10, 'eloc' )
 if Netuse( "stock", SHARED, 10, 'estk' )
  set relation to estk->branch into eloc
  if !estk->( dbseek( sID ) )
   Error( 'No other stores have stock of this desc', 12 )
  else
   mscr := Box_Save( 1, 01, 22, 50, C_CYAN )
   stkbrow:=tbrowsedb( 2, 02, 21, 49 )
   stkbrow:HeadSep := HEADSEP
   stkbrow:ColSep := COLSEP
   stkbrow:goTopBlock := { || dbseek( sID ) }
   stkbrow:goBottomBlock := { || jumptobott( sID ) }
   stkbrow:skipBlock := KeySkipBlock( { || estk->id }, sID )
   stkbrow:addcolumn( tbcolumnnew( "Branch", { || left( eloc->name, 25 ) } ) )
   stkbrow:addcolumn( tbcolumnnew( "OnHand", { || estk->onhand } ) )
   stkbrow:addcolumn( tbcolumnnew( "On Ord", { || estk->onorder } ) )
   while sKey != K_ESC .and. sKey != K_END
    stkbrow:forcestable()
    sKey := inkey( 0 )
    Navigate( stkbrow, sKey )
   enddo
   Box_Restore( mscr )
  endif
  estk->( dbclosearea() )
 endif
 eloc->( dbclosearea() )
endif
select ( cur_dbf )
goto cur_rec
setcursor( oldcur )
return

*

procedure StockLocs ( sID )
local cur_dbf:=select(), cur_rec:=recno(), oldcur:=setcursor( 1 )
local mscr, x, nQty, mchoice, oldloc, newloc
local aArray, tscr, getlist := {}, stkqty, oldpos, newpos, mtemp
if Netuse( "stoclocs", SHARED, 10, 'estk' )
 if !estk->( dbseek( sID ) )
  Add_rec( 'estk' )
  estk->id := sID
  estk->( dbrunlock() )
 endif
 while TRUE
  Heading( 'Stock in other Locations' )
  mscr := Box_Save( 2, 06, 17, 52 )
  @ 3, 11 say 'Loc  OH     StkT   Department'
  @ 4, 11 say replicate( chr( 196 ), 40 )
  nQty := 0 
  for x := 0 to 7
   @ 7+x, 11 say Ns( x + 1 ) pict '9'
   @ 7+x, 14 say estk->( fieldget( fieldpos( 'l' + Ns( x ) ) ) ) pict QTY_PICT
   @ 7+x, 20 say estk->( fieldget( fieldpos( 'l' + Ns( x ) + 's' ) ) ) pict QTY_PICT
   @ 7+x, 30 say left( lookitup( 'dept', estk->( fieldget( fieldpos( 'l' + Ns( x ) + 'dept' ) ) ) ), 20 )
   nQty += estk->( fieldget( fieldpos( 'l' + Ns( x ) ) ) )
  next

  @ 06, 11 say replicate( chr( 196 ), 40 )
  @ 05, 11 say '0'  // Stock loc 0 ( default location )
  @ 05, 14 say master->onhand - nQty pict QTY_PICT
  @ 05, 20 say master->stocktake pict QTY_PICT
  @ 05, 30 say Lookitup( 'dept', master->department )
  @ 15, 11 say replicate( chr( 196 ), 40 )
  @ 16, 14 say master->onhand pict QTY_PICT
  @ 16, 20 say '<-Total Qty on Hand'
  aArray := {}
  aadd( aArray, { 'Exit', 'Return to TAB Menu' } )
  aadd( aArray, { 'Location', 'Maintain Location Names' } )
  aadd( aArray, { 'Qtys', 'Move Stock Between Locations' } )
  mchoice := MenuGen( aArray, 18, 10, , , C_GREY, TRUE )
  if mchoice < 2
   exit
  else
   do case
   case mchoice = 2
    Heading( 'Stock Location Maintainance' )
    tscr := Box_Save( 06, 19, 15, 42 )
    Rec_lock( 'estk' )
    @ 07, 22 get estk->l0dept pict '@!' valid( empty( estk->l0dept ) .or. Dup_Chk( estk->l0dept, 'dept' ) )
    @ 08, 22 get estk->l1dept pict '@!' valid( empty( estk->l1dept ) .or. Dup_Chk( estk->l1dept, 'dept' ) )
    @ 09, 22 get estk->l2dept pict '@!' valid( empty( estk->l2dept ) .or. Dup_Chk( estk->l2dept, 'dept' ) )
    @ 10, 22 get estk->l3dept pict '@!' valid( empty( estk->l3dept ) .or. Dup_Chk( estk->l3dept, 'dept' ) )
    @ 11, 22 get estk->l4dept pict '@!' valid( empty( estk->l4dept ) .or. Dup_Chk( estk->l4dept, 'dept' ) )
    @ 12, 22 get estk->l5dept pict '@!' valid( empty( estk->l5dept ) .or. Dup_Chk( estk->l5dept, 'dept' ) )
    @ 13, 22 get estk->l6dept pict '@!' valid( empty( estk->l6dept ) .or. Dup_Chk( estk->l6dept, 'dept' ) )
    @ 14, 22 get estk->l7dept pict '@!' valid( empty( estk->l7dept ) .or. Dup_Chk( estk->l7dept, 'dept' ) )
    read
    estk->( dbrunlock() )
    Box_Restore( tscr )
   case mchoice = 3
    Heading( 'Move Stock Between Locations' )
    tscr := Box_Save( 18, 30, 22, 65 )
    oldloc := 0
    newloc := 0
    @ 19, 32 say 'Old location number' get oldloc pict '9' range 0, 8
    read
    if lastkey() != K_ESC
     if ( oldloc != 0 .and. estk->( fieldget( fieldpos( 'l' + Ns( oldloc - 1 ) ) ) ) = 0 )
      Error( 'No stock quantities at location ' + Ns( oldloc ), 12 )
     else
      stkqty := if( oldloc = 0, MASTAVAIL, estk->( fieldget( fieldpos( 'l' + Ns( oldloc - 1 ) ) ) ) )
      @ 20, 32 say 'New Location number' get newloc pict '9' range 0, 8
      @ 21, 32 say 'Qty to move' get stkqty pict QTY_PICT
      read
      if lastkey() != K_ESC
       Rec_lock( 'estk' )
       oldpos := fieldpos( 'l' + Ns( oldloc - 1 ) )
       newpos := fieldpos( 'l' + Ns( newloc - 1 ) )

       if oldpos != 0
        mtemp := estk->( fieldget( oldpos ) ) 
        estk->( fieldput( oldpos, mtemp - stkqty ) ) 
       endif

       if newpos != 0
        mtemp := estk->( fieldget( newpos ) )
        estk->( fieldput( newpos, mtemp + stkqty ) ) 
       endif

       estk->( dbrunlock() )

       Print_find( 'barcode' )
       

       if Isready( 12, 10, 'Print new Barcode Labels' )

        Code_print( '97' + Ns( newloc - 1 ) + substr( estk->id, 4, ID_CODE_LEN - 3 ), stkqty )
        EndPrint( NO_EJECT )

       endif

      endif
     endif
    endif  
    Box_Restore( tscr )
   endcase
  endif
 enddo
 Box_Restore( mscr )
 estk->( dbclosearea() )
endif
select ( cur_dbf )
goto cur_rec
setcursor( oldcur )
return

*

function F12OrderIt
local nQty:=0, msel:=select(), aSave, getlist:={}
if Netuse( "Draft_PO", SHARED, 10 )
 Heading('Add Item to Order')
 aSave := Box_Save( 1, 20, 3, 60 )
 @ 2, 22 say 'Quantity to Order' get nQty pict QTY_PICT
 read
 Box_restore( aSave )
 if nQty > 0
  select draft_po
  dbseek( master->id )
  locate for draft_po->source = 'Op' while draft_po->id = master->id
  if found()
   if Isready( 'Item is already on Draft Po, Add this qty' )
    Rec_lock()
    draft_po->qty += nqty

   endif

  else
   Add_rec()
   draft_po->id := master->id
   draft_po->supp_code := master->supp_code
   draft_po->qty := nqty
   draft_po->date_ord := Bvars( B_DATE )
   draft_po->special := NO
   draft_po->source := 'Op'
   draft_po->skey := substr( master->alt_desc, 1, 5 ) + master->desc
   draft_po->department := master->department
   draft_po->hold := Bvars( B_DEPTORDR )

  endif
  draft_po->( dbrunlock() )

 endif
 DispItem()
 draft_po->( dbclosearea() )
endif
select (msel)      // Who knows what file selected
return TRUE
