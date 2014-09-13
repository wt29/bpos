/*

      General Look up an Item Procedure

      Last change:  TG   29 Apr 2011    5:08 pm
*/

Procedure s_enquire

#include "bpos.ch"
#include "getexit.ch"


local lMainLoop:=FALSE, nMenuChoice
local mloop, cid, cKeyValue, nRow, nPos
local lIsLocked, lSecHandFlag, aArray
local lFlag, nSelected
local cStrPart, nKeyPressed
local cSaveOldScreen:=Box_Save()
local cScreenSave, nIntx, enqlevel, sobj, mmacro
local mlen, rec_list[ 51 ], bit, mfield
local mcode, mqty, keybuff, mrec, mseq
local okins, c, dstru, astru, abs_search := FALSE, mreq, okf12
local okf11
local getlist:={}

lMainLoop := Master_use()

while lMainLoop
 Box_Restore( cSaveOldScreen )
 Heading('Master File Enquiry')
 aArray := {}
 aadd( aArray, { 'Exit', 'Return to previous option' } )
 aadd( aArray, { 'ID', 'Display item using the Item ID' } )
 aadd( aArray, { DESC_DESC, 'Find item using part of the ' + DESC_DESC } )
 aadd( aArray, { ALT_DESC, 'Find item using part of the ' + ALT_DESC } )
 aadd( aArray, { 'Supplier', 'Locate item by supplier' } )
 aadd( aArray, { 'Category', 'Inquire using Category search' } )
 aadd( aArray, { 'Part', 'Find part of ' + ITEM_DESC + ' (Slow Search)' } )
 aadd( aArray, { 'Archive', 'Retrieve ' + ITEM_DESC + ' from Archive' } )
 aadd( aArray, { 'Boolean', 'Boolean Search on Master File' } )
 okf11 := setkey( K_F11, { || Archive() } )

 nMenuChoice := MenuGen( aArray, 07, 35, 'Enquire' )

 setkey( K_F11, okf11 )
 setkey( K_F12, okf12 )

 enqlevel := Box_Save( 0, 0, 24, 79 )
 do case
 case nMenuChoice = 2
  while TRUE
   lIsLocked := NO
   lSecHandFlag := NO
   Heading('Inquire by ' + ID_DESC )
   cid := space( ID_ENQ_LEN )
   @ 09, 42 say 'ÍÍÍÍ¯' get cid pict '@!'
   Box_Save( 08, 47, 11, 75 )
   @ 10, 48 say 'New Item = <Ins>'
   okins := setkey( K_INS ,{ || add_item() } )
   read
   setkey( K_INS, okins )
   if !updated()
    exit
   else
    if !Codefind( cid )
     Error( ID_DESC + ' not on File',18 )
    else
     itemdisp( FALSE )
    endif
    Box_Restore( enqlevel )
   endif
  enddo

 case nMenuChoice >= 3 .and. nMenuChoice <= 5
  select master
  do case
  case nMenuChoice = 3
   mmacro := 'Desc'
   cKeyValue := space( SEARCH_KEY_LEN )
   master->( ordsetfocus( BY_DESC ) )
  case nMenuChoice = 4
   mmacro := 'alt_desc'
   cKeyValue := space( SEARCH_KEY_LEN )
   master->( ordsetfocus( BY_ALTDESC ) )
  case nMenuChoice = 5
   mmacro := 'supp_code'
   cKeyValue := space( SUPP_CODE_LEN )
   master->( ordsetfocus( BY_SUPPLIER ) )
  endcase
  while TRUE
   Box_Restore( enqlevel )
   Heading( 'Inquire by ' + mmacro )
   cKeyValue += if( nMenuChoice != 5, space( SEARCH_KEY_LEN - len( cKeyValue ) ), ;
           if( nMenuChoice != 11, space( SUPP_CODE_LEN - len( cKeyValue ) ), ;
              space( 8 - len( cKeyValue ) ) ) )
   @ 7+nMenuChoice, 38 + len( aArray[ nMenuchoice, 1 ] ) say 'ÍÍÍÍ¯' get cKeyValue pict '@K!'
   read
   if lastkey() = K_ESC
    exit
   else
    cKeyValue := trim( cKeyValue )
    mlen := len( cKeyValue )
    select master
    if !dbseek( cKeyValue )
     Error( 'No ' + mmacro + ' match on File', 12 )

    else
     master->( dbskip() )
     if upper( substr( fieldget( fieldpos( mmacro ) ), 1, mlen ) ) != cKeyValue
      master->( dbskip( -1 ) )
      itemdisp( FALSE )

     else
      master->( dbskip( -1 ) )
      cls
      Heading('')
      for nIntX = 1 to 24-2
       @ nIntX+2,0 say row()-2 pict '99'
      next
      sobj := tbrowsedb( 01, 3, 24, 79 )
      sobj:colorspec := TB_COLOR
      sobj:HeadSep := HEADSEP
      sobj:ColSep := COLSEP
      sobj:goTopBlock := { || dbseek( cKeyValue ) }
      sobj:goBottomBlock := { || jumptobott( cKeyValue ) }
      c:=tbcolumnnew( DESC_DESC, { || if( !deleted(),left( master->desc, 30 ),'*****DELETED*****') } )
      c:colorblock := { || if( MASTAVAIL > 0, {5, 6}, {1, 2} ) }
      sobj:addcolumn( c )
      sobj:addcolumn( tbcolumnnew( 'Avail',{ || transform( MASTAVAIL, QTY_PICT ) } ) )
      sobj:addcolumn( tbcolumnnew( 'Onhand',{ || transform( master->onhand , QTY_PICT ) } ) )
      sobj:addcolumn( tbcolumnnew( 'Price', { || transform( master->sell_price , PRICE_PICT ) } ) )
      sobj:addcolumn( tbcolumnnew( 'Supp', { || master->supp_code } ) )
      sobj:addcolumn( tbcolumnnew( BRAND_DESC, { || master->brand } ) )
      sobj:addcolumn( tbcolumnnew( ID_DESC, { || master->id } ) )
      sobj:addcolumn( tbcolumnnew( 'Catalog', { || master->catalog } ) )
      sobj:addcolumn( tbcolumnnew( 'Dept', { || master->department } ) )
      sobj:freeze := 1
      nKeyPressed := 0
      keybuff := ''
      while nKeyPressed != K_ESC .and. nKeyPressed != K_END
       sobj:forcestable()
       nKeyPressed := inkey(0)
       if !navigate(sobj,nKeyPressed)
        do case
        case nKeyPressed == K_F1
         Build_help( browhelp() )

        case nKeyPressed >= 48 .and. nKeyPressed <= 57
         keyboard chr( nKeyPressed )
         mseq := 0
         cScreenSave := Box_Save( 2,08,4,40 )
         @ 3,10 say 'Selecting No' get mseq pict '999'
         read
         Box_Restore( cScreenSave )
         if !updated()
          loop
         else
          mreq := recno()
          dbskip( mseq - sobj:rowpos )
          itemdisp( FALSE )
          dbgoto( mreq )
         endif

        case nKeyPressed == K_ALT_S
         StockDisp( master->id )

        case nKeyPressed == K_ENTER
         itemdisp( FALSE )

        case nKeyPressed == K_INS
         add_item()

        otherwise
         if nKeyPressed = K_BS .or. nKeyPressed > 31
          if nKeyPressed = K_BS
           keybuff:=substr(keybuff,1,max(len(keybuff)-1,0))
          else
           keybuff+=upper(chr(nKeyPressed))
          endif
          mrec := recno()
          if !dbseek( keybuff )
           go mrec
           keybuff:=substr(keybuff,1,max(len(keybuff)-1,0))
          else
           Syscolor( 2 )
           if !empty( keybuff )
            @ 0,55 say '< ' + keybuff + ' > '
           else
            @ 0,55 say replicate(' ',20)
           endif
           Syscolor( 1 )
           sobj:refreshall()
           sobj:forcestable()
          endif
         endif
        endcase
       endif
       if master->( deleted() )
        eval( sobj:skipblock, -1 )
       endif
      enddo
     endif
    endif
   endif
  enddo
  master->( ordsetfocus( BY_ID ) )

 case nMenuChoice = 6
  if Netuse( "macatego", SHARED, 10, "xcat" )
   set relation to xcat->id into master
   mloop := TRUE
   cKeyValue := space(6)
   while mloop
    Box_Restore( enqlevel )
    Heading('Inquire by Category')
    cKeyValue += space(6-len(cKeyValue))
    @ 13,45 say 'ÍÍÍÍ¯' get cKeyValue pict '@K!' valid dup_chk( cKeyValue, "category" )
    read
    if lastkey() = K_ESC
     mloop := FALSE
    else
     cKeyValue := trim( cKeyValue )
     mlen := len( cKeyValue )
     seek cKeyValue
     cls
     Heading('Inquire by Category')
     for nIntX = 1 to 24-2
      @ nIntX+2,0 say row()-2 pict '99'
     next
     sobj:=tbrowsedb( 01, 03, 24, 79 )
     sobj:colorspec := TB_COLOR
     sobj:HeadSep := HEADSEP
     sobj:ColSep := COLSEP
     sobj:goTopBlock := { || dbseek( cKeyValue ) }
     sobj:goBottomBlock  := { || jumptobott( cKeyValue ) }
     sobj:skipBlock:= Keyskipblock( { || left( xcat->code, mlen ) }, cKeyValue )
     c:=tbcolumnNew( DESC_DESC, { || left( master->desc, 30 ) } )
     c:colorBlock := { || if( master->onhand > 0, {5, 6}, {1, 2} ) }
     sobj:addColumn( c )
     sobj:addcolumn( tbcolumnNew( ALT_DESC, { || master->alt_desc } ) )
     sobj:addcolumn( tbcolumnNew( 'Avail',{ || transform( MASTAVAIL, QTY_PICT)} ) )
     sobj:addcolumn( tbcolumnNew( 'Price', { || transform( master->sell_price, PRICE_PICT) } ) )
     sobj:addcolumn( tbcolumnNew( 'Supp', { || master->supp_code } ) )
     sobj:addcolumn( tbcolumnNew( 'Bi', { || master->Binding } ) )
     sobj:addcolumn( tbcolumnNew( 'Code', { || xcat->code } ))
     sobj:addcolumn( tbcolumnNew( 'Master File Comments',{ || master->comments } ) )
     sobj:addcolumn( tbcolumnNew( ID_DESC, { || idcheck( master->id ) } ) )
     sobj:freeze := 1
     nKeyPressed := 0
     while nKeyPressed != K_ESC .and. nKeyPressed != K_END
      sobj:forcestable()
      nKeyPressed := inkey(0)
      mcode := xcat->code
      if !navigate(sobj,nKeyPressed)
       do case
       case nKeyPressed >= 48 .and. nKeyPressed <= 57
        keyboard chr( nKeyPressed )
        mseq := 0
        cScreenSave:=Box_Save( 2,08,4,40 )
        @ 3,10 say 'Selecting No' get mseq pict '999'
        read
        Box_Restore( cScreenSave )
        if !updated()
         loop
        else
         skip mseq - sobj:rowpos
         itemdisp( FALSE )
         select xcat
        endif
       case nKeyPressed == K_ENTER
        select master
        itemdisp( FALSE )
        select xcat
        sobj:refreshall()
       case nKeyPressed == K_INS
        cid:=space( ID_ENQ_LEN )
        mqty:=1
        cScreenSave:=Box_Save( 2, 10, 4, 70 )
        @ 3,12 say 'id/Code to add to category list' get cid pict '@!'
        read
        Box_Restore( cScreenSave )
        if Codefind( cid )
         Add_rec('xcat')
         xcat->code := mcode
         xcat->id := master->id
         xcat->qty := mqty
         xcat->skey := upper( master->desc )
         xcat->( dbrunlock() )
         sobj:refreshall()
        endif
        select xcat
       case nKeyPressed == K_DEL
        if Isready( 3, 12, 'Ok to delete desc from list' )
         Del_rec( 'xcat', UNLOCK )
         eval( sobj:skipblock , -1 )
         sobj:refreshall()
        endif
       endcase
      endif
     enddo
    endif
   enddo
   xcat->( dbclosearea() )
  endif
  select master

 case nMenuChoice = 7
  while TRUE
   Box_Restore( enqlevel )
   Heading('Select Field to Search within')
   select master
   dstru:= dbstruct()
   astru:={}
   mlen := len(dstru)
   for nIntX:=1 to mlen
    if dstru[ nIntx, 2 ] = 'C'
     aadd(astru, dstru[ nIntx, 1 ] )
    endif
   next
   cScreenSave:=Box_Save( 2, 2, 24, 14 )
   nMenuChoice:=achoice( 3, 3, 23, 13, astru)
   if nMenuChoice = 0
    exit

   else
    mfield:=astru[nMenuChoice]
    mfield:=upper(substr(mfield,1,1))+lower(substr(mfield,2,len(mfield)-1))
    Heading("Enter Part to search for")
    Box_Save(2,8,5,72)
    @ 3,10 say 'This option will search for part of a '+mfield+' (10 Characters)'
    @ 4,10 say '      It may take a considerable period of time'
    cStrPart:=space(10)
    @ 14,44 say 'ÍÍ¯Enter Part of ' + mfield get cStrPart pict '@!'
    read
    if !updated()
     exit

    else
    // msearch := TRUE
     select master
     if upper(mfield)='ABS_PTR'
#ifndef __HARBOUR__
      v_select(0)
      v_use( Oddvars( SYSPATH )+'master' )
#endif
      abs_search := TRUE

     else
      abs_search := FALSE

     endif
     ordsetfocus(  )
     cls
     Heading("Part Search in " + mfield)
     go top
     nRow := 4
     nPos := 1
     @ 2,0 say ' No  Desc                    Author                 Supp Bi Dep St  OH   Price'
     @ 3,0 say 'ÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÅÄÄÅÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄÄÄÄÄ'
     lFlag := TRUE
     Highlight(1,02,'Records to search',Ns(lastrec()))
     bit := fieldpos(mfield)
     cStrPart := trim(cStrPart)
     while lFlag .and. !eof() .and. Pinwheel()
      if TRUE
       @ nRow,00 say nPos pict '999'
       @ nRow,04 say substr(master->desc,1,25)
       @ nRow,30 say master->alt_desc
       @ nRow,53 say master->supp_code
       @ nRow,58 say master->binding
       @ nRow,61 say master->department
       @ nRow,65 say master->status
       @ nRow,68 say master->onhand pict '999'
       @ nRow,72 say master->sell_price pict PRICE_PICT
       rec_list[nPos] := recno()
       nRow++
       nPos++

      endif
      Highlight(1,50,'Record Number',Ns(recno()))
      skip

      if nRow >= 24 - 1 .or. eof() .or. inkey() != 0
       while TRUE
        nSelected := 0
        @ 24,10 say 'Enter No to Examine '+if(eof(),'','or <Enter> for next page');
                get nSelected pict '99' valid(nSelected < nPos)
        read
        if lastkey() = K_ESC
         lFlag := FALSE
         exit
        endif
        if nSelected = 0
         @ 4,0 clear
         nPos := 1
         nRow := 4
         exit
        endif
        if updated()
         goto rec_list[ nSelected ]
         itemdisp( FALSE )
        endif
       enddo
      endif
     enddo
    endif
   endif

   select master
   ordsetfocus( BY_ID )

  enddo
 case nMenuChoice = 8
  Archive()

 case nMenuChoice = 9
  Boolean( 'master' )

 case nMenuChoice < 2
  lMainLoop := FALSE

 endcase
enddo

close databases

return

*

procedure itemdisp ( go_to_edit )
local getlist:={},okf1,sFunKey3,sFunKey4,okf5,okf6,okf7,okf8,okf9,okf10,okf12
local okafa,okafs,oktab
local oksf10, okaf1, okf11 , cScreenSave:=Box_Save(), odbf:=select()
local closeytd:=FALSE, oldvid:=24, oldcur, cKeyValue
local stuff_categories := FALSE, oldcolor:=syscolor( C_NORMAL )

okf1 := setkey( K_F1, { || Enq_help() } )
sFunKey3 := setkey( K_F3, { || Hold_em( TRUE ) } )
okafa := setkey( K_ALT_A, { || Abs_edit( "master" ) } )
okafs := setkey( K_ALT_S, { || StockDisp( master->id ) } )
sFunKey4 := setkey( K_F4, { || Enq_sales() } )
okf5 := setkey( K_F5, { || Enq_hist() } )
okf6 := setkey( K_F6, { || Enq_cate() } )
okf7 := setkey( K_F7, { || Enq_appr() } )
okf8 := setkey( K_F8, { || Enq_spec() } )
okf9 := setkey( K_F9, { || Enq_po() } )
oktab := setkey( K_SH_TAB, { || Launcher() } )
okf10 := setkey( K_F10, { || F10Edit() } )
okf11 := setkey( K_F11, { || F11Costs() } )
okf12 := setkey( K_F12, { || F12OrderIt() } )
if master->binding = "KI"
 oksf10 := setkey( K_SH_F10, { || Enq_kit() } )
endif
okaf1 := setkey( K_ALT_F1, { || Desc_dele() } )
DispItem()
if go_to_edit
// EditDesc( @dump_flag, @append_all, nil, FromAddDesc )
 EditDesc( nil )

else
 while TRUE
  oldcur:=setcursor(0)
  cKeyValue := inkey(0)
  setcursor( oldcur )
  if setkey(cKeyValue) != nil
   eval(setkey(cKeyValue))
  else
   exit
  endif
 enddo
endif
setkey( K_F1, okf1 )
setkey( K_F3, sFunKey3 )
setkey( K_F4, sFunKey4 )
setkey( K_F5, okf5 )
setkey( K_F6, okf6 )
setkey( K_F7, okf7 )
setkey( K_F8, okf8 )
setkey( K_F9, okf9 )
setkey( K_F10, okf10 )
setkey( K_F11, okf11 )
setkey( K_ALT_F1, okaf1 )
setkey( K_ALT_A, okafa )
setkey( K_ALT_S, okafs )
setkey( K_TAB, oktab )

Vidmode( oldvid+1, 80 )
Box_Restore( cScreenSave )
setcolor( oldcolor )
set function 2 to master->id + chr( K_ENTER )
clear typeahead
select ( odbf )

return

*

proc dispItem
cls
if select( "ytdsales" ) = 0
 if !Netuse( "ytdsales" )
  return
 endif
endif
ytdsales->( dbseek( master->id ) )
select master
Heading( 'Item Inquiry' )
@ 02, 14 - len( PLU_DESC ) say PLU_DESC
@ 02, 52 say 'Catalog'
@ 03, 14 - len( DESC_DESC ) say DESC_DESC
@ 05, 14 - len( ALT_DESC ) say ALT_DESC
@ 06, 14 - len( BRAND_DESC ) say BRAND_DESC
@ 07, 01 say 'Prim Supplier'
@ 08, 04 say 'Supplier 2'
@ 08, 22 say 'Supplier 3'
@ 09, 04 say 'Department'
#ifndef NO_SEE_UM
@ 10, 01 say 'Ls Cost Price'
@ 11, 01 say 'Av Cost Price'
@ 14, 11 say 'RRP'
@ 12, 56 say 'Disc/Mar'
#endif
// @ 12, 04 say 'Nett Price'
@ 13, 04 say 'Sell Price'
// @ 15, 10 say 'Nett'
@ 17, 05 say '   Status'
@ 19, 05 say ' Comments'
@ 09, 34 say 'Qty Avail.'
@ 10, 26 say '<F7>   On Approval'
@ 11, 26 say '<F8>Special Orders'
@ 12, 26 say '<F9>Total on Order'
@ 13, 31 say 'Minimum Stock'
@ 14, 30 say 'Last Stocktake'
@ 15, 33 say '<F3>On Hold'
@ 08, 52 say '<F6>Category'
@ 10, 57 say PACKAGE_DESC
@ 10, 68 say 'Edition'
@ 11, 55 say 'Firm Sale'
@ 11, 68 say 'Year'
@ 13, 59 say 'Last PO #'
@ 14, 56 say 'Date Last PO'
@ 15, 56 say 'Last Qty Ord'
@ 16, 51 say '<F5>Last Received'
@ 17, 55 say 'Last Ret. Qty'
@ 18, 54 say 'Last Ret. Date'
@ 19, 54 say '<F4> Last Sold'
@ 21, 03 say 'Jan   Feb   Mar   Apr   May   Jun   Jul   Aug   Sep   Oct   Nov'
@ 21, 69 say 'Dec   Tot'
Center( 23, 'Sales Period is '+Ns( Bvars( B_PERLEN ) ) + ' days - Last Period Close was ' + dtoc( Bvars( B_LASTPER ) ) )
syscolor( C_BRIGHT )
@ 02, 15 say master->id
@ 02, 60 say master->catalog
@ 03, 15 say left( master->desc, 60 )
// @ 04, 15 say substr( master->desc,39,38 )
@ 05, 15 say master->alt_desc
@ 06, 15 say LookItUp( 'brand', master->brand )  // Also known as the brand
@ 07, 15 say LookItUp( 'supplier' , master->supp_code )
@ 08, 15 say master->supp_code2
@ 08, 33 say master->supp_code3
@ 09, 15 say LookItUp( 'dept' , master->department )
@ 13, 15 say master->sell_price pict PRICE_PICT
@ 17, 15 say LookItUp( 'Status', master->status )
@ 19, 15 say left( master->comments, 35 )
@ 09, 46 say MASTAVAIL pict QTY_PICT
@ 09, 50 say ' (' + trim( ns( master->onhand ) ) + ')'
@ 10, 46 say master->approval pict QTY_PICT
@ 11, 46 say master->special pict QTY_PICT
@ 12, 46 say master->onorder pict QTY_PICT
@ 13, 46 say master->minstock pict QTY_PICT
@ 14, 46 say master->stocktake pict QTY_PICT
@ 15, 46 say master->held pict QTY_PICT
@ 08, 65 say Lookitup( 'category', Lookitup( 'macatego', master->id, 'code', 'id' ) )
@ 10, 65 say master->binding
@ 10, 76 say master->edition
@ 11, 65 say master->sale_ret pict 'Y'
@ 11, 73 say master->year
@ 13, 69 say master->lastpo
@ 14, 69 say master->date_po
@ 15, 69 say master->lastqty
@ 16, 69 say master->dlastrecv
if !empty( master->retdate )
 @ 17, 69 say master->retqty
 @ 18, 69 say master->retdate

endif
@ 19, 69 say master->dsale
@ 22, 02 say ytdsales->jan
@ 22, 08 say ytdsales->feb
@ 22, 14 say ytdsales->mar
@ 22, 20 say ytdsales->apr
@ 22, 26 say ytdsales->may
@ 22, 32 say ytdsales->jun
@ 22, 38 say ytdsales->jul
@ 22, 44 say ytdsales->aug
@ 22, 50 say ytdsales->sep
@ 22, 56 say ytdsales->oct
@ 22, 62 say ytdsales->nov
@ 22, 68 say ytdsales->dec
@ 22, 74 say ytdtot() pict '99999'
syscolor( C_INVERSE )
@ 24, 02 say ytdsales->per1
syscolor( C_BRIGHT )
@ 24, 08 say ytdsales->per2
@ 24, 14 say ytdsales->per3
@ 24, 20 say ytdsales->per4
@ 24, 26 say ytdsales->per5
@ 24, 32 say ytdsales->per6
@ 24, 38 say ytdsales->per7
@ 24, 44 say ytdsales->per8
@ 24, 50 say ytdsales->per9
@ 24, 56 say ytdsales->per10
@ 24, 62 say ytdsales->per11
@ 24, 68 say ytdsales->per12
@ 24, 74 say ytdsales->per1+ytdsales->per2+ytdsales->per3+ytdsales->per4+;
            ytdsales->per5+ytdsales->per6+ytdsales->per7+ytdsales->per8+;
            ytdsales->per9+ytdsales->per10+ytdsales->per11+ytdsales->per12 ;
            pict '99999'
syscolor( C_NORMAL )
if master->( deleted() )
 Highlight( 1, 10,'','* * * * DELETED * * * *' )
endif
return

*

function enq_help
local aArray := { {'F10','Edit Item'}, {'Alt-A','Abstract'}, { 'Alt-S','Stock' } } 
aadd( aArray, { 'F11', 'Display Costs' } )
aadd( aArray, { 'Tab', 'Second Menu' } )
aadd( aArray, { 'F12', 'Add to Draft PO' } )
Build_help( aArray )
return nil

*

proc f10edit
F11Costs()   // Will display hidden field Headings.
EditDesc()
DispItem()  // Force a redisplay
return

*

procedure EditDesc ( super, FromAddDesc )
local getlist:={},cScreenSave,temp_id:=master->id+' ',chkval,mreplace,mrec
local msub,o_id,lAnswer, oldcur:=setcursor(1),old_price:=master->sell_price
local okf1,sFunKey3,sFunKey4,okf5,okf6,okf7,okf8,okf9,okaf8,okf10:=setkey( K_F10, { || tedit()} )
local oktab,okafa,okaf1,tscr:=Box_Save(),bit:='',stuff_cat:=FALSE, mWasChanged := FALSE

default super to FALSE
default FromAddDesc to FALSE

select master
if empty( master->desc )
 stuff_cat := TRUE

endif
sFunKey3 := setkey( K_F3 , nil )
okf5 := setkey( K_F5 , { || Repeat() } )
okafa := setkey( K_ALT_A , nil )
oktab := setkey( K_TAB , nil )
okaf1 := setkey( K_ALT_F1 , nil )

@ 02,15 get temp_id pict '@K!' valid( !empty( temp_id ) )

@ 02,60 get master->catalog pict '@!'
@ 03,15 get master->desc pict '@S60'
@ 05,15 get master->alt_desc pict '@!'
@ 06,15 say space(30)
@ 06,15 get master->brand pict '@!' valid( lastkey() = K_UP .or. dup_chk( master->brand,'brand') )
@ 07,15 say space(30)
@ 07,15 get master->supp_code pict '@!K' valid( lastkey() = K_UP .or. dup_chk(master->supp_code,'supplier') ;
        .and. !empty(master->supp_code) )
@ 08,15 get master->supp_code2 pict '@!K' valid( lastkey() = K_UP .or. empty(master->supp_code2) ;
        .or. dup_chk(master->supp_code2,'supplier') )
@ 08,33 get master->supp_code3 pict '@!K' valid( lastkey() = K_UP .or. empty(master->supp_code3) ;
        .or. dup_chk(master->supp_code3,'supplier') )
@ 09,15 say space(18)
@ 09,15 get master->department pict '@!K';
        valid( lastkey() = K_UP .or. dup_chk(master->department,"dept") .and. !empty( master->department ) )
@ 10,15 get master->cost_price pict PRICE_PICT
if super
 @ 11,15 get master->avr_cost pict PRICE_PICT
endif
@ 13,15 get master->sell_price pict PRICE_PICT
@ 14,15 get master->retail pict PRICE_PICT
@ 17,15 say space( 15 )
@ 17,15 get master->status pict '@!' valid( lastkey() = K_UP .or. dup_chk( master->status, "status" ) )
@ 19,15 get master->comments pict '@S35'
if super
 @ 11,46 get master->approval pict QTY_PICT
 @ 12,46 get master->special pict QTY_PICT
 @ 13,46 get master->onorder pict QTY_PICT
 @ 15,46 get master->stocktake pict QTY_PICT
 @ 16,46 get master->held pict QTY_PICT
 @ 17,46 get master->pp_onhand pict QTY_PICT
endif
@ 13,46 get master->minstock pict QTY_PICT
if stuff_cat
 @ 09,65 get bit valid( enq_cate() )
endif
@ 10,65 get master->binding pict '@!' valid( lastkey() = K_UP .or. dup_chk( master->binding,"binding" ) )
@ 10,76 get master->edition pict '@!'
@ 11,65 get master->sale_ret pict 'Y'
@ 11,73 get master->year pict '9999'
if super
 @ 13,69 get master->lastpo
 @ 14,69 get master->date_po
 @ 15,69 get master->lastqty
 @ 16,69 get master->dlastrecv
 @ 17,69 get master->retqty
 @ 18,69 get master->retdate
 @ 19,69 get master->dsale
 if !ytdsales->( eof() )
  Rec_lock( 'ytdsales' )
  @ 22,02 get ytdsales->jan
  @ 22,08 get ytdsales->feb
  @ 22,14 get ytdsales->mar
  @ 22,20 get ytdsales->apr
  @ 22,26 get ytdsales->may
  @ 22,32 get ytdsales->jun
  @ 22,38 get ytdsales->jul
  @ 22,44 get ytdsales->aug
  @ 22,50 get ytdsales->sep
  @ 22,56 get ytdsales->oct
  @ 22,62 get ytdsales->nov
  @ 22,68 get ytdsales->dec
  @ 24,02 get ytdsales->per1
  @ 24,08 get ytdsales->per2
  @ 24,14 get ytdsales->per3
  @ 24,20 get ytdsales->per4
  @ 24,26 get ytdsales->per5
  @ 24,32 get ytdsales->per6
  @ 24,38 get ytdsales->per7
  @ 24,44 get ytdsales->per8
  @ 24,50 get ytdsales->per9
  @ 24,56 get ytdsales->per10
  @ 24,62 get ytdsales->per11
  @ 24,68 get ytdsales->per12
 endif
endif
okaf8 := setkey( K_ALT_F8, { || EditDesc( TRUE ) } )
Rec_lock( 'master' )
read
mWasChanged := updated()
ytdsales->( dbrunlock() )
setkey( K_ALT_F8 , okaf8 )
if super
 keyboard chr( K_PGDN )
endif 
if temp_id != master->id
 mreplace := TRUE
/*
 if len( trim( temp_id ) ) = 10 .and. SYSNAME = 'BPOS'
  chkval := trim( temp_id )
  if idcheck( chkval ) != chkval
   cScreenSave:=Box_Save( 2, 8, 4, 72 )
   @ 3,10 say 'Your new id does not verify - Accept new value' get mreplace pict 'y'
   read
   Box_Restore( cScreenSave )
   if mreplace
    temp_id := idcheck( chkval )
   endif
  endif
  temp_id := CalcAPN( '978' + temp_id )
 endif
 msub := substr( temp_id, 1, 2 )
 if len( temp_id ) = 12 .and. ( msub = '97' .or. msub = '93' .or. msub = '94' )
  temp_id := CalcAPN( temp_id )
 endif
*/
 mrec := recno()
 if Codefind( temp_id )
  cScreenSave := Box_Save( 08, 08, 11, 72 )
  Highlight( 09, 10, DESC_DESC, substr( master->desc, 1, 40 ) )
  Highlight( 10, 11, ALT_DESC, substr( master->alt_desc, 1, 40 ) )
  Error( 'ID/Code already on file - Code not changed', 12 )
  Box_Restore( cScreenSave )
  mreplace := FALSE

 endif
 goto mrec

 if mreplace
  o_id := master->id
  cScreenSave := Box_Save( 2, 8, 5, 72 )
  lAnswer := FALSE
  @ 3,10 say 'You Have changed the Code field do you wish to change'
  @ 4,10 say ' all occurences of ' + o_id + ' to ' + temp_id get lAnswer pict 'y'
  read
  if lAnswer
   id_exchg( o_id, temp_id )
  endif
  Box_Restore( cScreenSave )
 endif
endif

setkey( K_F10 , okf10 )

if procname(2) == "BISAC_IMPO"
 setkey( K_F1, okf1 )
 setkey( K_F4, sFunKey4 )
 setkey( K_F5, okf5 )
 setkey( K_F6, okf6 )
 setkey( K_F7, okf7 )
 setkey( K_F8, okf8 )
 setkey( K_F9, okf9 )
 setkey( K_F10, okf10 )
else
 setkey( K_F3, sFunKey3 )
 setkey( K_F5, okf5 )
 setkey( K_ALT_A, okafa )
 setkey( K_TAB, oktab )
 setkey( K_ALT_F1, okaf1 )
endif
master->( dbrunlock() )
setcursor( oldcur )
Box_Restore( tscr )
return

*

Function tedit
local mvar := trim( substr( readvar(), rat( '>', readvar() ) + 1, 10 ) )
do case
case mvar = 'SUPP_CODE'
 Dup_chk( '!@#$', 'supplier' )
case mvar = 'DEPARTMENT'
 Dup_chk( '!@#$', 'dept ' )
case mvar = 'BINDING'
 Dup_chk( '!@#$', 'binding' )
case mvar = 'BRAND'
 Dup_chk( '!@#$', 'brand' )
case mvar = 'STATUS'
 Dup_chk( '!@#$', 'status' )
case mvar = 'SALES_CODE'
 Dup_chk( '!@#$', 'salescde' )
case mvar = 'SEMESTER'
 Dup_chk( '!@#$', 'semester' )
endcase
return nil

*

Function F11costs
@ 10,01 say 'Ls Cost Price'
@ 11,01 say 'Av Cost Price'
@ 14,11 say 'RRP'
Syscolor( 3 )
@ 10,15 say master->cost_price pict '9999.99'
@ 11,15 say master->avr_cost pict '9999.99'
@ 14,15 say master->retail pict '9999.99'
Syscolor( 1 )
return nil

*

Function Supercession
local oldrec := master->( recno() ) 
local oldord := master->( ordsetfocus( 'id' ) )
local oldsel := select(), cScreenSave, mold, mnew, getlist := {}, cKeyValue
local molddate, mnewdate
if select( 'superces' ) = 0
 if !Netuse( 'superces' )
  Error( 'Cannot seem to open the Supercession file here', 12 )
  return nil
 endif
endif
select superces 
begin sequence
 if !superces->( dbseek( master->id ) )
  Error( 'No Supercession record on File', 12 )
  if Isready( 12, ,'Create Supercession Record' )
   Add_rec( 'superces' )
   superces->id := master->id
   superces->( dbrunlock() )
  else
   break
  endif
 endif
 while TRUE

  cScreenSave := Box_Save( 2, 1, 9, 79, C_MAUVE )
  @ 2, 5 say '< Hit F10 to change Supercession Records >'

  Syscolor( C_BRIGHT )
  @ 3, 03 say 'Current Edition'
  @ 5, 03 say 'Old Edition'
  @ 7, 03 say 'New Edition'
  @ 3, 66 say 'Edn'
  @ 3, 70 say 'Date'
  Syscolor( C_MAUVE )

  master->( dbseek( superces->id ) )
  @ 4, 03 say idcheck( master->id )
  @ 4, ID_ENQ_LEN+5 say left( master->desc, 25 ) + right( trim( master->desc ), 10 )
  @ 4, 66 say master->edition
  
  master->( dbseek( superces->old_id) ) 
  if master->( found() )
   @ 6, 03 say idcheck( master->id )
   @ 6, ID_ENQ_LEN+5 say left( master->desc, 25 ) + right( trim( master->desc ), 10 ) 
   @ 6, 66 say master->edition
   @ 6, 70 say superces->old_date

  else
   @ 6, 03 say 'No previous supercession'

  endif

  master->( dbseek( superces->new_id ) )
  if master->( found() )
   @ 8, 03 say idcheck( master->id )
   @ 8, ID_ENQ_LEN+5 say left( master->desc, 25 ) + right( trim( master->desc ), 10 )
   @ 8, 66 say master->edition
   @ 8, 70 say superces->new_date

  else
   @ 8, 03 say 'Not Superceded ! - Current Edition'

  endif
  cKeyValue :=inkey( 0 )
  if cKeyValue != K_F10

   Box_Restore( cScreenSave )
   break

  else

   mold := space( ID_ENQ_LEN )
   @ 6, 3 get mold pict '@!'

   read
   if !Codefind( mold )
    Error( 'ID/Code not found', 12 )

   else
    molddate := Bvars( B_DATE )
    @ 6, 70 get molddate
    read
    if lastkey() != K_ESC
     Rec_lock( 'superces' )
     superces->old_id := master->id
     superces->old_date := molddate
     superces->( dbrunlock() )

    endif

   endif

   mnew := space( ID_ENQ_LEN )
   @ 8, 3 get mnew pict '@!'

   read
   if !Codefind( mnew )
    Error( 'id/Code not found', 12 )
   else
    mnewdate := Bvars( B_DATE )
    @ 8, 70 get mnewdate
    read
    if lastkey() != K_ESC
     Rec_lock( 'superces' )
     superces->new_id := master->id
     superces->new_date := mnewdate
     superces->( dbrunlock() )
    endif
   endif
     
  endif 
 enddo 
end sequence
master->( ordsetfocus( oldord ) )
master->( dbgoto( oldrec ) )
select ( oldsel )
return nil  

*

function Boolean ( mfile )

#ifdef __HARBOUR__

mFile := nil

#else

#define FIND_THIS 1
#define FIRSTNEXT 2
#define CASESENSE 3
#define WILDCARDS 4

local cScr
local t, l, b, r
local aQry := {}
local nRecno
local cPtr
local cWhereFound
local lDBVEverLooked := FALSE
local lDBFEverLooked := FALSE
local lFirstNext, oldbuf
local nRow, nPos, nSelected
local getlist:={}
local rec_list[ Lvars( L_MAXROWS ) + 1 ]

select ( mfile )

cScr := Box_Save( 0, 0, 24, 79 )

while aQry != NIL

 aQry := Build_exp()

 if aQry != NIL

  lFirstNext     := if( lDBFEverLooked, aQry[FIRSTNEXT], QRY_FIRST )

  // vidmode( lvars( L_MAXROWS ), 80 )
  cls
  Heading( "Boolean Search Results" )
  nRow := 4
  nPos := 1
  if mfile = 'customer'
   @ 2,1 say ' No Name                      Address               Suburb'
   @ 3,1 say 'ÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'

  else
   @ 2,0 say ' No  Desc                    Author                 Supp Bi Dep St  OH   Price'
   @ 3,0 say 'ÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÅÄÄÅÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄÄÄÄÄ'

  endif
  
  Highlight( 1, 0, 'Query', strtran( strtran( strtran( aqry[ FIND_THIS ], '&', ' and ' ), '|', ' or ' ), '!', ' not ' ) )
  lDBFEverLooked := TRUE
  nrecno := 1
  oldbuf := v_buffers( 20 )
  while nrecno != 0
   nRecno := v_qry_dbf(aQry[FIND_THIS] ,;  // <cFindThis>
                       QRY_INTERPRET   ,;  // <lMode>
                       lFirstNext      ,;  // <lFirstNext>
                       aQry[CASESENSE] ,;  // <lCaseSensitive>
                       aQry[WILDCARDS] ,;  // <lWildCards>
                       { || Pinwheel() } ) // <bPacifier>
   if nrecno != 0
    goto nrecno
    @ nRow,00 say nPos pict '999'
    if mfile = 'customer'

     @ nRow,5 say substr( customer->name, 1, 25 )
     @ nRow,31 say customer->add1
     @ nRow,53 say customer->add2
    else

     @ nRow,04 say left( ( mfile )->desc, 25 )
     @ nRow,30 say ( mfile )->alt_desc
     @ nRow,53 say ( mfile )->supp_code
     @ nRow,58 say ( mfile )->binding
     @ nRow,61 say ( mfile )->department
     if mfile = 'master'
      @ nRow,65 say ( mfile )->status
      @ nRow,68 say ( mfile )->onhand pict QTY_PICT
     endif
     @ nRow,72 say ( mfile )->sell_price pict PRICE_PICT

    endif

    rec_list[nPos] := recno()
    nRow++
    nPos++
   endif

   lfirstNext := QRY_NEXT
   if nRow >= 24 - 1 .or. nrecno = 0 .or. inkey() != 0
    while TRUE

     nSelected := 0
     @ 24,10 say 'Enter No to Examine '+if(eof(),'','or <Enter> for next page');
             get nSelected pict '99' valid( nSelected < nPos .and. nSelected >= 0 )
     read

     if lastkey() = K_ESC
      aQry := nil
      nrecno := 0
      exit
     endif

     if nSelected = 0
      @ 4,0 clear
      nPos := 1
      nRow := 4
      exit
     endif
     if updated()

      goto rec_list[ nSelected ]

      do case
      case mfile = 'master'
       itemdisp( FALSE )

      case mfile = 'customer'
       CustScr( FALSE )

      case mfile = 'archive'
       StockDisp( archive->id )

      endcase
     endif
    enddo
   endif
  enddo
  v_buffers( oldbuf )
 endif
enddo

Box_Restore( cScr )
#endif

return nil

*

func build_exp

local t:=3, l:=05, b:=20, r:=75, boldF1, bOldF2, bOldF7, bOldF8, bOldF9, bOldF10
local cScr, cOldExp, nKey:=0, aExp, aStack := {}, getlist := {}

static lCaseSensitive := FALSE
static lWildCards     := TRUE
static lFirst         := TRUE
static cExp

Heading( 'Build Boolean Search Expression' )

cScr := Box_Save( t, l, b, r, C_MAUVE )

@ b - 2, l + 3 say "F2-Options    F7-AND    F8-OR    F9-NOT    F10-Begin Search"
@ t + 1, l + 2 say "Case Sensitive [ ]   Interpret Wild Cards [X]   Find First [X]"

default cExp to  ""

while nKey != K_ESC .and. nKey != K_F10

 nKey := 0
 show_stack( aStack, t + 2, l + 14, b - 4, r - 3 )
 cExp := padr( cExp, 128 )
 cOldExp := cExp

 bOldF1  := setkey( K_F1,  {|| Boolhelp() } )
 bOldF2  := setkey( K_F2,  {|| bang(@nKey) } )
 bOldF7  := setkey( K_F7,  {|| bang(@nKey) } )
 bOldF8  := setkey( K_F8,  {|| bang(@nKey) } )
 bOldF9  := setkey( K_F9,  {|| bang(@nKey) } )
 bOldF10 := setkey( K_F10, {|| bang(@nKey) } )

 @ b - 3, l + 2 say "Search For:" get cExp picture "@KS45"
 read

 setkey( K_F1,  bOldF1  )
 setkey( K_F2,  bOldF2  )
 setkey( K_F7,  bOldF7  )
 setkey( K_F8,  bOldF8  )
 setkey( K_F9,  bOldF9  )
 setkey( K_F10, bOldF10 )

 if nKey == 0
  nKey := lastkey()
 endif

 if nKey != K_ESC .and. nKey != K_F2
  cExp := alltrim( cExp )
  if substr( cExp, 1, 1 ) != '('
   if substr( cExp, 1, 1 ) != '"'
    cExp := '"' + cExp + '"'
   endif
  endif
#ifndef __HARBOUR__
  if !v_qry_chk( cExp ) 
   Error( "Invalid expression", 12 )
   loop
  endif
#endif

 endif

 do case
 case nKey == K_F2
  options( @lCaseSensitive, @lWildCards, @lFirst, t, l )
 case nKey == K_F7
  cExp := and( aStack, cExp )
 case nKey == K_F8
  cExp := or( aStack, cExp )
 case nKey == K_F9
  cExp := not( cExp )
 case nKey == K_ENTER
  aadd( aStack, cExp )
 endcase

enddo

Box_Restore( cScr )

aExp := if( nKey == K_ESC, NIL, {cExp, lFirst, lCaseSensitive, lWildCards} )

return aExp


/*
   Internal function to show the stack of the RPN expression builder
*/

func show_stack( a, t, l, b, r )

local nStart
local nLen
local nWid
local nIntX, y

@ t, l clear to b, r
nLen := min( len(a), b - t )
nWid := (r - l) + 1

nStart := b - nLen
y := if( nLen < len(a), len(a) - nLen, 0 ) + 1
for nIntX = nStart to nStart + nLen - 1
 @ nIntX, l say pad( a[y++], nWid )
next

return NIL

/*
   Internal routine to process hot keys in the case after the get/read. 
*/

func bang( nKey )

local o

nKey := lastkey()
o := getactive()
o:exitState := GE_ENTER

return NIL

/*
   Options box to modify the user settings.  Very crude.       
*/

func options( lCaseSensitive, lWildCards, lFirst, nTargetTop, nTargetLeft )

local t:=11, l:=25, b:=15, r:=55, cScr, getlist := {}

cScr := Box_Save( t, l, b, r )

@ t + 1, l + 1 say "Case sensitive search:" get lCaseSensitive picture "Y"
@ t + 2, l + 1 say "Interpret ? * as wild:" get lWildCards picture "Y"
@ t + 3, l + 1 say "Find First=Y next=N  :" get lFirst picture "Y"
read

Box_Restore( cScr )

if updated()
 @ nTargetTop + 1, nTargetLeft + 18 say if( lCaseSensitive, "X", " " )
 @ nTargetTop + 1, nTargetLeft + 45 say if( lWildCards,     "X", " " )
 @ nTargetTop + 1, nTargetLeft + 62 say if( lFirst,         "X", " " )
endif

return NIL

/*
   ANDs the current expression with the top of the RPN stack.
*/

func and(aStack, cExp)
local cNewExp

if len(aStack) > 0
 cNewExp := "(" + cExp + "&" + aStack[len(aStack)] + ")"
 asize( aStack, len(aStack) - 1 )
else
 cNewExp := cExp
endif
return cNewExp

/*
   ORs the current expression with the top of the RPN stack.    
*/

func or(aStack, cExp)
local cNewExp

if len(aStack) > 0
 cNewExp := "(" + cExp + " | " + aStack[len(aStack)] + ")"
 asize( aStack, len(aStack) - 1 )
else
 cNewExp := cExp
endif
return cNewExp

/*
   NOTs the current expression.  Unary.
*/

func not(cExp)
return "(!" + cExp + ")"

function Boolhelp
local cScreenSave := Box_Save()
cls
Heading( 'Boolean Search Help' )  
@ 1, 0 say ''
text
   This routine is based on Reverse Polish Notation (RPN)     
   expression building.                                           
                                                                  
   For example, if you wanted to search for a record that         
   contained both Brahms and Bach but not Beethoven, and you      
   did not know how to spell Beethoven, you would want to         
   end up with the following expression:                          
                                                                  
      ( ("Brahms" & "Bach") & !("B*oven") )                       
                                                                  
   To create this expression using an RPN expression builder      
   you would type the following (the items in square brackets     
   are single key presses):                                       
                                                                  
   Brahms  - Search expression one                                
   [ENTER] - Push the entry up                                    
   Bach    - Search expression two                                
   [F7]    - AND search expression one with search expression two 
   [ENTER] - Push the compound entry up                           
   B*oven  - Search expression three                              
   [F9]    - NOT (or logically negate) Search expression three    
   [F7]    - AND the compound expression with Search exp three    
   [F10]   - Begin the search                                     
endtext                                                                 
inkey( 0 )
Box_Restore( cScreenSave )
return nil

