/*

 Procedure RecItem - Incoming Stock

      Last change:  TG   18 Mar 2011    6:21 pm

 Note - all costs are stored GST ex as in AU any GST collected is paid by the gov on purchases

*/

static lbarcode, nCostPrice, msell, mretail, mtax, mqty, mserial, mstd_disc
static mpo, minv, minvdate, mtaxcomp, minvval, mreserved, mprice_meth, mcomment
static mdisc, lAlreadyRec, nRecQty, mpo_qty, mnett, lGST_Inc, nGST, msuppname
static mischarge, mfreight, mrounding, mforexrate, mForexamt, mForexCode
static mconsignment

static cReturnReason  // Reason for returns
static mTotInvQty  // Total Qty on Invoice
static mQtyInv     // Qty invoiced by supplier on line

Procedure P_Receive

#include "bpos.ch"

local supploop := FALSE, idloop, sID, cSupplierCode := Oddvars( MSUPP )
local okf8, okf9, okf10, oks, sscr, getlist:={}, invloop
local oldscr := Box_Save(), mover, firstpass, item_tot, inv_tot

Center( 24, line_clear( 24 ) + 'Opening files for Item Receive')

if Master_use()
 if Netuse( 'pohead' ) 
  if Netuse( 'poline' )
   if Netuse( 'recvline' )
    if Netuse( 'recvhead' )
     supploop := TRUE
    endif
   endif
  endif
 endif
endif

line_clear( 24 )

while supploop

 Box_Restore( oldscr )

 Heading('Receive Items')

 cSupplierCode := GetSuppCode( 07, 35 )

 if lastkey() = K_ESC
  exit

 endif

 Box_Save( 2, 01, 12, 78 )
 mstd_disc := Lookitup( 'supplier', cSupplierCode, 'std_disc' )
 mprice_meth := Lookitup( 'supplier', cSupplierCode, 'price_meth' )
 lGST_Inc := Lookitup( 'supplier', cSupplierCode, 'gst_inc' )
 msuppname := Lookitup( 'supplier', cSupplierCode )
 mreserved := FALSE

 Highlight( 3, 03, 'Supplier', msuppname )
 Highlight( 4, 03, 'Comments', Lookitup( 'supplier', cSupplierCode, 'comm1' ) )
 Highlight( 5, 03, '        ', Lookitup( 'supplier', cSupplierCode, 'comm2' ) )

 minv := space( len( recvhead->invoice ) )
 minvdate := Bvars( B_DATE )
 minvval := 0
 mTotInvQty := 0
 nGST := 0
 cReturnReason := space( 2 )

 invloop := TRUE

 while invloop

  if lastkey() == K_ESC
   recvhead->( dbseek( cSupplierCode ) )
   while recvhead->supp_code = cSupplierCode .and. !recvhead->( eof() ) .and. Pinwheel( NOINTERUPT )
    recvline->( dbseek( recvhead->supp_code + recvhead->invoice ) )
    inv_tot := 0
    item_tot := 0
    while recvline->IndxKey = ( recvhead->supp_code + recvhead->invoice ) .and. !recvline->( eof() ) .and. Pinwheel( NOINTERUPT )
     inv_tot += ( recvline->cost_price * recvline->qty )
     item_tot += recvline->qty
     recvline->( dbskip() )

    enddo
    Rec_lock( 'recvhead' )
    recvhead->inv_calc := inv_tot + recvhead->freight + recvhead->x_charges + recvhead->gst
    recvhead->items_calc := item_tot
    recvhead->( dbrunlock() )
    recvhead->( dbskip() )

   enddo
   exit

  else
   RecInvBlock( cSupplierCode )    // Show the block including GST totals

  endif

  idloop:=TRUE
  firstpass:=TRUE

  sscr:=Box_Save()
  while idloop
   Box_Restore( sscr )
   sID := space( ID_ENQ_LEN )
   Heading( 'Receive Items from ' + msuppname )
   Center( 10, '<F8> PO on ' + ID_DESC + ' - <F9> PO on Supp - <F10> Change PO' )
   if firstpass
    mpo := 0
    @ 9, 03 say 'Purchase Order No' get mpo pict PO_NUM_PICT
    firstpass := FALSE

   else
    Highlight( 9, 03, 'Purchase Order No', Ns( mpo ) )

   endif

   @ 11,02 say 'Scan Code/Stock Code/id to Receive' get sID pict '@!'
   okf8 := setkey( K_F8, { || PoOnid( @mpo ) } )
   okf9 := setkey( K_F9 , { || PoSuppEnq( @mpo,cSupplierCode ) } )
   okf10 := setkey( K_F10, { || Po_change( @mpo,cSupplierCode ) } )
   read
   setkey( K_F8, okf8 )
   setkey( K_F9, okf9 )
   setkey( K_F10, okf10 )
   oks := setkey( K_ALT_S, { || Stockdisp() } )
   if lastkey() = K_ESC
    idloop := FALSE

   else
    sID := trim( sID )
    if empty( sID )
     loop

    endif
#ifdef THELOOK
    lBarCode := FALSE
#else
    lbarcode := if( len( sID ) = 10 .or. len( sID ) < 9 , YES , NO )
#endif
    if !Codefind( sID ) .and. !( substr( sID, 1, 1 ) $ "/.,';" )
     keyboard chr( K_ENTER )
     if !add_item( sID,cSupplierCode )
      loop

     endif

    endif

    sID := master->id
    if mpo = 0
     mpo_qty := 0
     mreserved := FALSE
     mcomment := ''

    else
     select poline
     ordsetfocus( BY_ID )
     seek sID
     locate for poline->number = mpo while poline->id = sID
     mpo_qty := poline->qty
     ordsetfocus( BY_NUMBER )
     if !found()
      Error( 'Item NOT ordered on this PO', 12 )
      loop

     endif
     mcomment := poline->comment
     pohead->( dbseek( mpo ) )
     mreserved := pohead->reserved

    endif
    select recvline
    ordsetfocus( 'id' )
    lAlreadyRec := dbseek( sID )
    nRecQty = recvline->qty
    ordsetfocus( 'key' )
    mqty := 0
    mQtyInv := 0
    cReturnReason := space( 2 )

    ItemRecvScr( msuppname )     // Looking for this Hmmmm?

    if lastkey() != K_ESC

     if mpo > 0 .and. mqty > poline->qty
      ?? BELL
      if !Isready( 21, ,'About to receive (' + Ns( mqty ) + ') more than you ordered ('+ns( poline->qty ) + ') - Proceed? ' )
       loop

      endif

     endif
     if mqty > 0
      mover := FALSE
      if cSupplierCode != master->supp_code .and. cSupplierCode != '!RET' // Auth Rets
       Box_Save( 20, 08, 23, 72 )
       @ 21,10 say 'Supplier code does not match Desc File Supplier code.'
       @ 22,10 say 'Do you wish to Overwrite the Supplier Code' get mover pict 'Y'
       read

      endif
      recvhead->( dbseek(  cSupplierCode + minv  ) )
      if !recvhead->( found() )
       Add_rec( 'recvhead' )
       recvhead->supp_code := cSupplierCode
       recvhead->invoice := minv
       recvhead->inv_total := minvval
       recvhead->gst := nGST
       recvhead->listed := FALSE
       recvhead->dreceived := minvdate
       recvhead->reserved := mreserved
       recvhead->x_charges := mischarge
       recvhead->freight := mfreight
       recvhead->consign := mconsignment
       recvhead->( dbrunlock() )

      endif

      Add_rec( 'recvline' )
      recvline->id := master->id
      recvline->IndxKey := padr( cSupplierCode, SUPP_CODE_LEN ) + minv
      recvline->ponum := mpo
      recvline->qty := mqty
      recvline->qty_ord := poline->qty
      recvline->qty_inv := mqtyinv
      recvline->cost_price := nCostPrice
      recvline->retail := mretail
      recvline->sell_price := msell
      recvline->barprint := lbarcode
      recvline->over_write := mover
      recvline->desc := master->desc
      recvline->comment := if( mpo != 0, poline->comment, '' )
      recvline->operator := Oddvars( OPERCODE )
      recvline->retreason := cReturnReason
      recvline->( dbrunlock() )

     endif
    endif
   endif
   setkey( K_ALT_S, oks )
  enddo
 enddo
enddo
Oddvars( MSUPP, cSupplierCode )
close databases
return

*

procedure com_change
local getlist:={}
local okf5 := setkey( K_F5 , nil )
local okf6 := setkey( K_F6 , nil )
local okf7 := setkey( K_F7 , nil )
local okf8 := setkey( K_F8 , nil )
local okf9 := setkey( K_F9 , nil )
local okf10 := setkey( K_F10 , nil )
Rec_lock( 'master' )
@ 06,13 get comments pict '@k'
read
master->( dbrunlock() )
setkey( K_F5 , okf5 )
setkey( K_F6 , okf6 )
setkey( K_F7 , okf7 )
setkey( K_F8 , okf8 )
setkey( K_F9 , okf9 )
setkey( K_F10 , okf10 )
RecTitlDis()
return

*

procedure bc_change
lbarcode := !lbarcode
RecTitlDis()
Highlight( 06, 60, 'Barcode', lbarcode, 'Y' )
return

*

procedure MinStkChg
local getlist:={}
local okf5 := setkey( K_F5 , nil )
local okf6 := setkey( K_F6 , nil )
local okf7 := setkey( K_F7 , nil )
local okf8 := setkey( K_F8 , nil )
local okf9 := setkey( K_F9 , nil )
local okf10 := setkey( K_F10 , nil )
Rec_lock( 'master' )
@ 05,55 get master->minstock
read
master->( dbrunlock() )
setkey( K_F5 , okf5 )
setkey( K_F6 , okf6 )
setkey( K_F7 , okf7 )
setkey( K_F8 , okf8 )
setkey( K_F9 , okf9 )
setkey( K_F10 , okf10 )
@ 05,55 say space(5)
RecTitlDis()
return

*

procedure disc_reta 
local getlist:={},okf4:=setkey( K_F4 , nil )
line_clear(20)
@ 20,04 say 'Discount Percentage' get mdisc pict '99.99'
read
nCostPrice := mretail - ( mretail / 100 * mdisc )
if Bvars( B_STD_DISC ) > 0
 msell := mretail - ( mretail / 100 * Bvars( B_STD_DISC ) )
 @ 17,32 say '(Less Store Discount of ' + Ns( Bvars( B_STD_DISC ), 4, 1 ) + '%)'
endif
line_clear(20)
@ 19,32 say Ns( mdisc, 4, 1 ) + '% Discount on retail     '   // Leave these Spaces
setkey( K_F4 , okF4 )
return

*

procedure disc_sell 
local getlist:={},okf3:=setkey( K_F3 , nil )
line_clear(20)
@ 20,04 say 'Discount Percentage' get mdisc pict '99.99'
read
nCostPrice := msell - (msell/100*mdisc)
if Bvars( B_STD_DISC ) > 0
 msell := mretail - (mretail/100*Bvars( B_STD_DISC ) )
endif
line_clear(20)
@ 19,32 say Ns(mdisc,4,1)+'% Discount on sell price     '  // leave these spaces
setkey( K_F3 , okf3 )
return

*

procedure disc_cost 
local getlist:={}
line_clear(20)
@ 20,05 say 'Markup Percentage' get mdisc pict '999.99'
read
msell := ( nCostPrice + mtax ) + ( ( nCostPrice + mtax) /100 * mdisc )
if Bvars( B_STD_DISC ) > 0
 msell := msell - ( msell / 100 * Bvars( B_STD_DISC ) )
endif
line_clear( 20 )
@ 19,32 say Ns( mdisc, 5, 1 ) + '% Markup on cost price        '  // leave these spaces
return

*

procedure Po_change ( mpo,cSupplierCode )
local old_po:=mpo,getlist:={}
@ 5,10 say 'Purchase Order No' get mpo pict PO_NUM_PICT
read
if mpo > 0
 pohead->( dbseek( mpo ) )
 if !pohead->( found() ) .or. cSupplierCode != pohead->supp_code
  Error( 'Po #' + Ns( mpo ) + ' not found against Supplier', 12 )
  mpo := old_po
 endif
endif
@ 5,10 say space(50)
Highlight( 5, 10, 'Purchase Order No', Ns( mpo, 6 ) )
return

*

procedure Chg_id 
local new_id:=space( ID_ENQ_LEN ),old_id:=master->id,sscr:=Box_Save(02,10,04,41)
local mreplace:=YES,chkval,getlist:={},mans:=FALSE,mscr,mrec
local okf10:=setkey( K_F10 , nil ),okf9:=setkey( K_F9 , nil )
local lAnswer
@ 3,12 say 'Enter new ' + ID_DESC get new_id pict '@!'
read
if updated()
 if idcheck( new_id ) != idcheck( old_id )
  if len( trim( new_id ) ) = 10 .and. SYSNAME = 'BPOS'
   chkval := trim( new_id )
   if idcheck( chkval ) # chkval
    mscr:=Box_Save( 2, 8, 4, 72 )
    @ 3,10 say 'Your new id does not verify - Accept new value' get mreplace pict 'y'
    read
    Box_Restore( mscr )
    if mreplace
     new_id := idcheck(chkval)
    endif
   endif
   new_id := CalcAPN( '978' + new_id)
   lbarcode := YES
  endif
  select master
  mrec := recno()
  if Codefind( new_id ) .and. recno() != mrec
   Error( ID_DESC + '/Code already exists - Code not changed ' + master->id, 12 )
   mreplace := FALSE
  endif
  goto mrec
  if mreplace

   mscr := Box_Save( 2, 8, 5, 72 )
   @ 3,10 say 'You Have changed the ' + ID_DESC + ' field do you wish to change'
   @ 4,10 say ' all occurences of ' + old_id + ' to ' + new_id + ' ?' get lAnswer pict 'Y'
   read
   Box_Restore( mscr )

   if lAnswer
    id_exchg( old_id, new_id )
   endif

  endif
 endif
endif

Box_Restore( sscr )
Highlight(04,01,'      ' + ID_DESC, idcheck( master->id ) )
setkey( K_F10 , okf10 )
setkey( K_F9 , okf9 )
return

*

proc PoOnid ( mpo )
local mscr:=Box_Save(),tid:=space( ID_ENQ_LEN ),getlist:={}
@ 4,12 say 'id' get tid pict '@!'
read
Box_Restore( mscr )
if updated()
 if Codefind( tid )
  mpo := enq_po()
  Highlight( 5, 10, 'Purchase Order No', padr( Ns( mpo,6 ), 6 ) )
 endif
endif
return

*

proc RecTitlDis 
Highlight( 02, 01, '     Desc', substr( master->desc, 1, 50) )
Highlight( 03, 01, '    Author', master->alt_desc )
Highlight( 04, 01, '      id', idcheck( master->id ) )
Highlight( 04, 26, 'Special Orders', Ns( master->special ) )
Highlight( 04, 45, 'Total on Order', Ns( master->onorder ) )
Highlight( 05, 01, '   '+BRAND_DESC, master->brand )
Highlight( 05, 30, 'Department', master->department )
Highlight( 05, 45, 'Min Stock', Ns( master->minstock ) )
Highlight( 05, 60, 'Binding', master->binding )
Highlight( 06, 00, '<F8>Comments', master->comments )
Highlight( 06, 45, 'Supplier1', master->supp_code )
Highlight( 06, 60, 'Barcode', lbarcode,'Y' )
if mpo > 0
 @ 7,01 say replicate(chr(196),78)
 Highlight( 08, 01, 'Po Number', Ns( mpo ) )
 Highlight( 08, 20, 'Qty Ordered', Ns( mpo_qty ) )
 if mreserved
  Center( 7, '< RESERVED ORDER >' )
  Center( 9, mcomment )
 else
  Highlight( 08, 40, 'Po Comment', mcomment )
 endif
endif
@ 10,01 say replicate(chr(196),78)
return

*

proc RecItemEdit
select master
itemdisp( FALSE )
RecTitlDis()
return

*

proc RecInvChg 
local getlist:={}
@ 13,01 say 'Invoice No' get minv pict '@!';
        valid(if(Bvars( B_AUTOCRED ), !empty(minv), TRUE ) )
@ 13,42 say 'Invoice Date' get minvdate
@ 13,60 say 'Invoice value' get minvval pict '99999.99'
read
return

*

function ItemrecvScr ( msuppname )
local getlist := {}, sFunKey3, sFunKey4, okf5, okf6, okf7, okf8, okf9, okf10
local reploop := TRUE, oldscr:=Box_Save( 0, 0, 24, 79 )
local nSuppDisc
nCostPrice := master->cost_price
msell := master->sell_price
// mretail := if( master->retail=0, master->sell_price, master->retail )
mretail := master->retail
mserial := space( 15 )
while reploop
 cls
 Heading( 'Receive Items from ' + msuppname )
 RecTitldis()
 Highlight( 04, 75, '', '<F9>' )
 Highlight( 02, 74, '', '<F10>' )
 Highlight( 05, 75, '', '<F7>' )
 Highlight( 06, 75, '', '<F6>' )
 okf5:=setkey( K_F5, { || RecInvChg() } )
 okf6:=setkey( K_F6, { || Bc_change() } )
 okf7:=setkey( K_F7, { || Minstkchg() } )
 okf8:=setkey( K_F8, { || Com_change() } )
 okf9:=setkey( K_F9, { || Chg_id() } )
 okf10:=setkey( K_F10, { || RecItemEdit() } )
 @ 11,01 say 'Qty to Receive' get mqty pict QTY_PICT
 @ 11,35 say 'Qty Invoiced' get mQtyInv when ( Stuffkey( Ns( mqty ) ) );
         pict QTY_PICT valid ( if( !mconsignment, mQtyInv >= mqty, mQtyInv = 0 ) )

 if lAlreadyRec
  ? BELL
  Highlight( 12, 25, '', NS( nRecQty ) + ' Received this session' )

 endif

 @ 12, 01 say 'Returns Reason' get cReturnReason when ( mqty != mQtyInv .and. !mconsignment ) pict '@!';
          valid( Dup_chk( cReturnReason, 'retcodes' ) )
 Highlight( 11, 65, 'Qty on Hand', Ns( master->onhand ) )
 Highlight( 12, 75, '', '<F5>' )
 Highlight( 13, 01, 'Invoice No', minv )
 Highlight( 13, 27, 'Invoice Date', dtoc( minvdate ) )
 Highlight( 13, 60, 'Invoice Value', Ns( minvval ) )
 if master->special > 0 .and. !mreserved
  Highlight( 22, 10, '', 'Quantity required for special orders = ' + Ns( master->special ) )

 endif

 if mprice_meth != 'C' // Cost Plus or Retail less
  nSuppDisc := mStd_Disc
  @ 15,06 say '   Retail Price' get mretail pict PRICE_PICT
  @ 16,06 say '  Supplier Disc' get nSuppDisc pict DISC_PICT
  @ 15,00 say 'Last'
  Highlight( 15, 00, '', '(' + Ns( master->retail, 7, 2) + ')' )
  read
  if lastkey() != K_ESC
//   nCostPrice := mretail -( mretail / 100 * mstd_disc )
   nCostPrice := mretail -( mretail / 100 * nSuppDisc )
   mdisc := nSuppDisc
//   mdisc := mstd_disc
   msell := mretail
   @ 17,06 say '     Sell Price' get msell pict PRICE_PICT
   Highlight( 17, 00, '', '('+Ns(master->sell_price,7,2)+')' )
   @ 19,06 say '     Cost Price' get nCostPrice pict '9999.99'
   @ 19,32 say space( 47 )
   Highlight( 19, 67, '', '<F3>R <F4>S' )
   @ 19,32 say Ns( mdisc, 4, 1 ) + '% Discount on Retail'
   Highlight( 19, 00, '', '(' + Ns( master->cost_price, 7, 2 ) + ')' )
   Highlight( 10, 75, '', 'PgUp' )
   sFunKey3 := setkey( K_F3, { || disc_reta() } )
   sFunKey4 := setkey( K_F4, { || disc_sell() } )
   read
   setkey( K_F3, sFunKey3 )
   setkey( K_F4, sFunKey4 )
   @ 19,68 say space( 11 )
   if lGST_Inc  // Ok the cost price is GST inclusive so we need to deduct this to get the cost correct
    mtax := nCostPrice -( ( nCostPrice ) * ( 1/ ( 1+ ( Bvars( B_GSTRATE )/100 ) ) ) )
    @ 21,06 say 'G.S.T Component' get mtax pict '9999.99'
    nCostPrice -= mtax

   endif

   read

  endif

 else           // Cost Price is Cost Plus
  nSuppDisc = 0
//  if lGST_Inc
//   nCostPrice := master->cost_price + ( master->cost_price/100 * Bvars( B_GSTRATE ) )
  nCostPrice := master->cost_price
//  endif
  @ 15,09 say '   Cost Price' get nCostPrice pict PRICE_PICT
//  @ 15,00 say 'Last'
  Highlight( 15, 00, '', '(' + Ns(master->cost_price,7,2) + ')' )
  @ 16,09 say 'Supplier Disc' get nSuppDisc pict DISC_PICT

  read
  if lastkey() != K_ESC

   nCostPrice = nCostPrice - ( ( nCostPrice / 100 ) * nSuppDisc )

   if lGST_Inc
    mtaxcomp := nCostPrice -((nCostPrice)*(1/(1+(Bvars( B_GSTRATE )/100 ) ) ) )
    @ 16,06 say 'G.S.T Component' get mtaxcomp pict '9999.99'
    nCostPrice -= mtaxcomp
    mtax := mtaxcomp

   else // GST should be Ex. Stuff onhand is
//    mtax := nCostPrice * Bvars( B_GSTRATE ) / 100
//    @ 16,06 say 'G.S.T Component' get mtax pict '9999.99'

   endif

   @ 15, 09 say space(45)

   Highlight( 15, 09, '   Cost Price', transform( nCostPrice, PRICE_PICT ) )
//   mretail := ( nCostPrice + mtax ) + ( ( nCostPrice + mtax )/ 100 * mstd_disc )
//   mretail := nCostPrice + mtax
   mdisc := mstd_disc
   Highlight( 17, 00, '', '(' + Ns( master->retail, 7, 2 ) + ')' )
 //  if master->sell_price = 0
    msell = nCostPrice * (mstd_disc / 100)

 //  else
 //   msell := master

 //  endif

   //msell := mretail

   @ 17,09 say ' Retail Price' get mretail pict PRICE_PICT
   Highlight( 19, 00, '', '(' + Ns( master->sell_price, 7, 2 ) + ')' )
   @ 19,09 say '   Sell Price' get msell pict PRICE_PICT
   @ 19,32 say space(47)
   Highlight( 19, 74, '', '<F3>S' )
   @ 19,32 say '(Plus Markup of '+Ns( mdisc, 7, 1 ) + '%)'
   Highlight( 11, 75, '', 'PgUp' )
   sFunKey3 := setkey( K_F3 , { || disc_cost() } )
   read
   setkey( K_F3 , sFunKey3 )
   @ 19,68 say space(11)

  endif

 endif
 setkey( K_F5, okf5 )
 setkey( K_F6, okf6 )
 setkey( K_F7, okf7 )
 setkey( K_F8, okf8 )
 setkey( K_F9, okf9 )
 setkey( K_F10, okf10 )
 if lastkey() != K_PGUP
  exit

 endif

enddo
Box_Restore( oldscr )
return nil

*

Procedure Recpo
local newloop:=FALSE, mscr, cost_tot, sell_tot, cSupplierCode := Oddvars( MSUPP )
local oldscr:=Box_Save(0,0,24,79), getlist:={}, sobj, mrec, keypress
local okf10, inv_tot, item_tot, sID, gotchya, mindxkey, mappend
local y, aHelpLines

Center( 24, 'Opening files for Receive Items' )

if Master_use()
 if Netuse( "pohead" )
  if Netuse( "poline" )
   if Netuse( "recvline" )
    if Netuse( "recvhead" )
     newloop := TRUE
    endif
   endif
  endif
 endif
endif

line_clear( 24 )

while newloop

 Box_Restore( oldscr )

 Heading('Purchase Order Receive')

 cSupplierCode := GetSuppCode( 8, 35 )

 if lastkey() = K_ESC
  exit
 endif

 mpo := 0

 Box_Save( 2, 01, 10, 79 )
 Highlight( 03, 10, 'Supplier ', Lookitup( 'supplier', cSupplierCode ) )
 @ 05,10 say 'Purchase Order No' get mpo pict PO_NUM_PICT
 @ 05,50 say '<F10> PO/Supp'
 okf10 := setkey( K_F10, { || PoSuppEnq( @mpo, cSupplierCode ) } )
 read
 setkey( K_F10, okf10 )

 if lastkey() = K_ESC
  exit
 endif

 if mpo > 0
  if !pohead->( dbseek( mpo ) )
   Error( 'Po #' + Ns( mpo ) + ' not found', 12 )
   loop

  endif
  if pohead->supp_code != cSupplierCode
   Error( 'Po #' + Ns( mpo ) + ' not found against Supplier',12 )
   loop

  endif

 endif

 select recvline
 locate for recvline->ponum = mpo

 lAlreadyRec := FALSE
 mappend := TRUE

 if found()
  mindxkey := recvline->IndxKey
  Error( "This po is already on New Stock File", 12 )
  lAlreadyRec := TRUE
  if !Isready( 12, 12, 'Continue to process' )
   loop

  else
   mappend := Isready( 12, 12, 'Ok to reappend?' )

  endif

 endif

 Heading( 'Receive Items on Po#' + Ns( mpo ) )

 mstd_disc := Lookitup( 'supplier', cSupplierCode, 'std_disc' )
 mprice_meth := Lookitup( 'supplier', cSupplierCode, 'price_meth' )
 lGST_Inc := Lookitup( 'supplier', cSupplierCode, 'gst_inc' )
 msuppname := Lookitup( 'supplier', cSupplierCode )
 mreserved := pohead->reserved

 if !mappend
  minv := space( len( recvhead->invoice ) )
  minvdate := Bvars( B_DATE )
  minvval := 0
  mTotInvQty := 0

 else
  minv := space( len( recvhead->invoice ) )
  minvdate := Bvars( B_DATE )
  minvval := 0
  mTotInvQty := 0

 endif
  
 RecInvBlock( cSupplierCode ) 

 if Bvars( B_AUTOCRED ) .and. empty( minv )
  Error( "Auto Creditors Posting is engaged - You must enter Inv #", 12 )
  loop
 endif

 if select( "recvtemp" ) != 0
  recvtemp->( dbclosearea() )

 endif
 select recvline
 copy stru to ( Oddvars( TEMPFILE ) )

 if !Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "recvtemp" ) 
  Error( "Cannot open " + Oddvars( TEMPFILE ), 12 )
  loop
 endif

 if mappend

  Center( 09, 'Preparing to receive Purchase Order' )

  select poline
  dbseek( mpo )
  set relation to poline->id into master

  mindxkey := cSupplierCode + minv

  while poline->number = mpo .and. !eof() .and. Pinwheel( NOINTERUPT )
   Add_rec( 'recvtemp' )
   recvtemp->id := poline->id
   recvtemp->IndxKey := mindxkey
   recvtemp->ponum := mpo
   recvtemp->qty := poline->qty
   recvtemp->barprint := FALSE 
   recvtemp->qty_ord := poline->qty
   recvtemp->qty_inv := poline->qty
   recvtemp->cost_price := master->cost_price
   recvtemp->retail := master->retail
   recvtemp->sell_price := master->sell_price
   recvtemp->over_write := FALSE
   recvtemp->desc := master->desc
   recvtemp->comment := if( mpo != 0, poline->comment, '' )
   recvtemp->operator := Oddvars( OPERCODE )
   recvtemp->( dbrunlock() )

   poline->( dbskip() )

  enddo

  select poline
  set relation to

 endif

 select recvtemp
 set relation to recvtemp->id into master

 dbgotop()
 cls
 Heading( 'Receive Items on Po#' + Ns(mpo) )
 sobj := tbrowsedb( 02, 0, 24, 79 )
 sobj:HeadSep := HEADSEP
 sobj:ColSep := COLSEP
 sobj:addcolumn( tbcolumnnew( 'Desc', { || left( master->desc, 20 ) } ) )
 sobj:addcolumn( tbcolumnnew( 'Qty Ord', { || recvtemp->qty_ord } ) )
 sobj:addcolumn( tbcolumnnew( 'Qty Rec', { || recvtemp->qty } ) )
 sobj:addcolumn( tbcolumnnew( 'Sell Price', { || recvtemp->sell_price } ) )
 sobj:addcolumn( tbcolumnnew( 'Inv Price', { || recvtemp->cost_price } ) )
 sobj:addcolumn( tbcolumnnew( 'Barcode', { || if(recvtemp->barprint, 'Y', 'N' ) } ) )
 sobj:addcolumn( tbcolumnnew( 'Master File Comments', { || master->comments } ) )
 sobj:addcolumn( tbcolumnnew( 'id', { || idcheck( master->id ) } ) )
 sobj:freeze := 1
 sobj:gotop()
 keypress := 0
 while keypress != K_ESC .and. keypress != K_END
  sobj:forcestable()
  keypress := inkey(0)
  if !navigate( sobj, keypress )
   do case
   case keypress == K_F1
    aHelpLines := { ;
    { 'Enter', 'Edit Invoice lines' },;
    { 'Del', 'Delete Line from Invoice' },;
    { 'F8', 'Calculate Invoice Values' },;
    { 'F10', 'Desc Header Details' } }
    Build_help( aHelpLines )

   case keypress == K_F10
    select master
    DispItem( FALSE )
    select recvtemp
    sobj:refreshcurrent()

   case keypress == K_INS
    sID := space( ID_ENQ_LEN )
    mscr:=Box_Save( 5, 08, 7, 72 )
    @ 6,10 say 'Code/id No to add to receiving' get sID pict '@!'
    read
    Box_Restore( mscr )
    if !updated()
     exit
    else 
     gotchya := Codefind( sID )
     if !gotchya .and. !( substr( sID, 1, 1 ) $ "/.,';" )
      gotchya := add_item( sID, cSupplierCode )
     endif
     if gotchya

      Add_rec( 'recvtemp' )
      recvtemp->barprint := FALSE
      recvtemp->id := master->id
      recvtemp->IndxKey := mindxkey
      recvtemp->ponum := 0
      recvtemp->cost_price := master->cost_price
      recvtemp->sell_price := master->sell_price
      recvtemp->retail := master->retail
      recvtemp->over_write := FALSE 
      recvtemp->desc := master->desc
      recvtemp->operator := Oddvars( OPERCODE )

      mqty := recvtemp->qty
      lbarcode := recvtemp->barprint
      mpo_qty := recvtemp->qty_ord
      mcomment := recvtemp->comment
      mreserved := recvhead->reserved
      mQtyInv := 0

      ItemRecvScr( Lookitup( 'supplier', cSupplierCode ) )

      recvtemp->qty := mqty
      recvtemp->invqty := mQtyInv
      recvtemp->sell_price := msell
      recvtemp->retail := mretail
      recvtemp->barprint := lbarcode
      recvtemp->cost_price := nCostPrice
   //   recvtemp->st_amt := mst_amt
   //   recvtemp->retreason := mst_amt

      recvtemp->( dbrunlock() )

      sobj:refreshall()
      sobj:gotop()

     endif
    endif
      
   case keypress == K_DEL
    Del_rec( 'recvtemp', UNLOCK )
    sobj:refreshall()
    sobj:gotop()

   case keypress == K_ENTER 
    mqty := recvtemp->qty
    lbarcode := recvtemp->barprint
    mpo_qty := recvtemp->qty_ord
    mcomment := recvtemp->comment
    mreserved := recvhead->reserved
    mQtyInv := 0
    cReturnReason := space( 6 )

    ItemRecvScr( Lookitup( 'supplier', cSupplierCode ) )

    Rec_lock( 'recvline' )
    recvtemp->qty := mqty
    recvtemp->sell_price := msell
    recvtemp->retail := mretail
    recvtemp->barprint := lbarcode
    recvtemp->cost_price := nCostPrice
//    recvtemp->st_amt := mst_amt
    recvtemp->( dbrunlock() )

    sobj:refreshcurrent()
    sobj:down()

   case keypress == K_ESC .or. keypress == K_END

    if Isready( 3, 12, 'Finished data entry on this order' )

     if Isready( 4, 12, 'Ok to receive this order' ) 

      select recvtemp

      dbgotop()
      locate for recvtemp->qty > 0 

      if !found()
       Error( 'No items on PO have a qty > 0 - what do you want to receive!', 12 )
      else 

       Add_rec( 'recvhead' )
       recvhead->supp_code := cSupplierCode
       recvhead->invoice := minv
       recvhead->inv_total := minvval
       recvhead->tot_items := mTotInvQty
       recvhead->gst := nGST
       recvhead->listed := FALSE
       recvhead->dreceived := minvdate
       recvhead->reserved := recvhead->reserved
       recvhead->branch := recvhead->branch
       recvhead->forexAmt := mForExAmt
       recvhead->forexRate := mForExRate
       recvhead->ForexCode := mForexCode
       recvhead->( dbrunlock() )
       recvtemp->( dbgotop() )

       inv_tot := 0 
       item_tot := 0

       while !recvtemp->( eof() ) .and. Pinwheel( NOINTERUPT )

        Add_rec( 'recvline' )                                   
        for y := 1 to recvtemp->( fcount() )
         recvline->( fieldput( y, recvtemp->( fieldget( y ) ) ) )
        next y
        recvline->( dbrunlock() )

        inv_tot += recvtemp->cost_price * recvtemp->qty
        item_tot += recvtemp->qty
        recvtemp->( dbskip() )

       enddo 

       Rec_lock( 'recvhead' )
       recvhead->inv_calc := inv_tot + recvhead->freight + recvhead->x_charges + recvhead->gst
       recvhead->items_calc := item_tot
       recvhead->( dbrunlock() )
        
      endif

     endif
     exit

    endif

   case keypress == K_F8
    mrec := recvtemp->( recno() )
    Heading( 'Calculate Invoice Value')
    mscr:=Box_Save( 4, 20, 6, 60, C_GREY )
    Center( 5, 'Calculating - Please wait' )
    recvtemp->( dbgotop() )
    sum recvtemp->cost_price*recvtemp->qty,recvtemp->sell_price*recvtemp->qty,recvtemp->qty ;
        to cost_tot,sell_tot,mqty
    Box_Restore( mscr )
    Heading('Total Order Value')
    mscr:=Box_Save( 4, 08, 12, 72, 4 )
    Highlight( 05, 10, 'Invoice totals for  => ', Lookitup( 'supplier', cSupplierCode ) )
    Highlight( 07, 10, 'At Cost value is    =>$', Ns( cost_tot,8,2 ) )
    Highlight( 09, 10, 'Retail value  is    =>$', Ns( sell_tot,8,2 ) )
    Highlight( 11, 10, 'Items on Invoice    => ', Ns( mqty ) )
    Error('',15)
    recvtemp->( dbgoto( mrec ) )
    Box_Restore( mscr )

   endcase
  endif
 enddo
enddo

dbcloseall()

Oddvars( MSUPP, cSupplierCode )
return

*

function RecInvBlock ( cSupplierCode )
local mscr :=Box_Save( 05, 05, 11, 75 ), getlist:={}
default mconsignment to FALSE
default mischarge to 0
default mfreight to 0
default mForexRate to 0
default mForexAmt to 0
default nGST to 0
default mForexCode to padr( lookitup( 'supplier', cSupplierCode, 'forexcode' ), 4 )
@ 06, 07 say '         Invoice No' get minv pict '@!' valid( !empty( minv ) )
@ 06, 40 say '       Invoice Date' get minvdate
@ 07, 07 say 'Total Invoice Value' get minvval pict '99999.99'
@ 07, 40 say '        Invoice Qty' get mTotInvQty pict '99999'
@ 08, 07 say '       Misc Charges' get mischarge pict '99999.99'
@ 08, 40 say '            Freight' get mfreight pict '99999.99'
@ 09, 07 say '          Total GST' get nGST pict TOTAL_PICT
@ 09, 40 say 'Cost prices GST inc' get lGST_Inc pict 'Y'
read
Box_Restore( mscr )
return nil
