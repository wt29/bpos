/*
   SaleCash.prg - Cash Sales
   Last change:  APG  14 Sep 2004   10:03 pm


      Last change:  TG   29 Apr 2011    4:13 pm
*/
Global aDocket

#include "bpos.ch"

static numtt, tt_types, tt_names, tt_cdflag, fkeys, lastfkeyhit:=0, price_conf, round_amt := 0

function S_cashSales ( hdpos )

local mgo:=FALSE, lMain, mgross, mcost, mSubTotal, mtotcost, firstpass, spec_done
local mspec_no, mspec_dep, sID, mdisval, mtax, mtran_qty, disc_val, mtot
local sFunKey3, sFunKey4, okf5, okf6, okf7, okf8, okf9, okf10, okaF1, okcf1, okcf2, msave, oksf10, oksf12, mscr
local repl_rec, mitemtax, mCustName, x
local mtrantype, mCustHistFlag, tax_exempt, retflag, specflag, qtyflag, discdone
local mqty, mmasterprice, hasdisc, mrow, mFinalTot, msellprice, msale_type, mCustKey
local mstype, mNoDiscTot
local getlist := {}


default hdpos to FALSE

if Master_use()
 mgo := Netuse( 'sales' ) 
 repl_rec := lastrec()

endif

if mgo
 if select( "cashtemp" ) != 0
  cashtemp->( dbclosearea() )
 endif
 select sales
 copy stru to ( Oddvars( TEMPFILE ) )
 if !Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "cashtemp" ) 
  Error( "Cannot open " + Oddvars( TEMPFILE ), 12 )
  mgo := FALSE

 endif

endif

price_conf := TRUE

while mgo

 lMain := TRUE
 firstpass := TRUE

 while lMain

  LastFKeyHit := 0
  retflag := FALSE
  qtyflag := FALSE
  specflag := FALSE
  discdone := FALSE
  mspec_no := 0
  mspec_dep := 0
  mqty := 1
  mitemtax := 0
  mdisval := 0
  round_amt := 0
  
  if firstpass

   cls
//   Print_find( "Docket" )
   Dock_Head()   // Set up the header and clear docket array
   mtax := 0
   mgross := 0
   mtotcost := 0
   mSubTotal := 0
   mNoDiscTot := 0         // The total sales proportion that is not discountable
   mCustKey := ''
   mCustName := ''         // Cust name for Misc Receipts
   spec_done := FALSE
   tax_exempt := FALSE
   mCustHistFlag := FALSE
   mRow := 5
   mTranType := 'C/S'
   mSType := '20'

   oksf10 := setkey( K_SH_F10, { || RePrintDock() } )
   oksf12 := setkey( K_SH_F12, { || ConToggle() } )

   Heading( 'Cash Sales' )
   Highlight( 01, 01, 'Last Tran #', Ns( Lvars( L_CUST_NO ), 4 ) )
//   DocketStatus()
//   Highlight( 01, 60, 'Docket is ' , if( Lvars( L_DOCKET ), 'On', 'Off' ) )

   @ 02,67 say if( price_conf,'','No Confirm' )
   Highlight( 4, 6, '', '  Desc                                  Price' )

   okcf2 := setkey( K_CTRL_F2, { || SetSalesTax( @tax_exempt ) } )
   msale_type := ''
   okcf1 := setkey( K_CTRL_F1, { || Custhist( @mCustName, @mCustHistFlag, @mCustKey ) } )

  endif

  sID := space( ID_ENQ_LEN )
  okaf1 := setkey( K_ALT_F1, { || Is_Special( @mspec_no, retflag, @specflag, mrow ) } )
  @ 02,23 say 'Scan Barcode' get sID pict '@!'
  Fkon( mrow )
  read
  Fkoff( mrow )

  setkey( K_ALT_F1, { || okaf1 } )
  setkey( K_CTRL_F2, { || okcf2 } )
  setkey( K_CTRL_F1, { || okcf1 } )

  if !updated()
   if lastkey() = K_ESC
    if firstpass
     mgo := FALSE
     exit
    else
     if Salevoid()
      firstpass := TRUE
      exit
     endif
    endif
   else
    Line_clear( 2 )
    lMain := FALSE
   endif
  else

   if sID = '-' .and. firstpass
    Heading( 'Cash Advance' )
    mtot := 0
    mtrantype := 'EPP'
    mCustName := space( 20 )
    mscr := Box_Save( 01, 38, 04, 77 )
    @ 02,40 say 'Payout Amount' get mtot pict '9999.99' valid( if( mtot < 0, Secure( X_SALEVOID ), mtot < 9000 ) )
    @ 03,40 say 'Customer' get mCustName
    read
    Box_Restore( mscr )
    if mtot != 0
     Dock_line( padr( if( mtot > 0, 'EFTPOS Payout', 'EFTPOS Decline' ), 31 );
                + ' ' + str( mtot, 8, 2 ) )
     firstpass = FALSE
     lMain := FALSE
     msubtotal := mgross := -mtot
     loop

    endif

   endif

   if !Codefind( sID )
    Error( 'Scan Incorrect !!', 5, 1 )

   else
    Line_clear( mrow )
    Line_clear( mrow+1 )
    if specflag
     specflag := FALSE
     select special
     locate for special->id = master->id while special->number = mspec_no
     if !found()
      Error( "ID not found or number incorrect", 12 )

     else
      if special->qty - special->delivered <= 0
       Error( "Special Order Filled - Finalisation Invalid", 12 )

      else
       spec_done := TRUE
       specflag := TRUE
       mspec_dep := special->deposit
       if mspec_dep > 0
        mscr := Box_Save( 04, 25, 06, 66 )
        @ 5,26 say 'Deposit Amt to Refund' get mspec_dep pict '9999.99';
               valid mspec_dep <= special->deposit
        read
        Box_Restore( mscr )
       endif
      endif
     endif
     select master
    endif
    mSellPrice := master->sell_price
    mitemtax := 0
    if tax_exempt
     if master->sales_tax != 0
      mSellprice -= master->cost_price * (Stret()/100)

     endif

    else
     mItemTax := 0

    endif

    if mspec_dep > 0
     mSellPrice := mSellPrice-mspec_dep
     Highlight( mrow, 55, "Less Deposit of", Ns( mspec_dep, 6, 2 ) )

    endif
    Poz( trim( master->desc ) + "$" + Ns( mSellPrice ) )
    @ mrow,06 say substr( master->desc, 1, 40 )
    if !hdpos
     @ mrow,76 say master->onhand pict '9999'

    endif

    if !hdpos
     if master->held > 0 .and. !specflag
      Hold_em( FALSE )
      if MASTAVAIL <= 0
       Error( 'Insufficient stock - You will need to release holds - Sale cancelled',12 )
       loop

      endif

     endif

    endif
    
    mMasterPrice := mSellPrice

    if price_conf
     mscr := Box_Save( mrow+1, 3, mrow+10, 30, 5 )
     @ mrow+2,05 say '<F3> = Hold System'
     @ mrow+3,05 say '<F4> = '+str( Bvars( B_DISC1 ),5,2 )+'% Discount'
     @ mrow+4,05 say '<F5> = '+str( Bvars( B_DISC2 ),5,2 )+'% Discount'
     @ mrow+5,05 say '<F6> = '+str( Bvars( B_DISC3 ),5,2 )+'% Discount'
     @ mrow+6,05 say '<F7> = '+str( Bvars( B_DISC4 ),5,2 )+'% Discount'
     @ mrow+7,05 say '<F8> = Add your own Disc.'
     @ mrow+8,05 say "<F9> =  Apply Qty's"
     @ mrow+9,05 say "<F10>=  Cust Returns"
     sFunKey3 := setkey( K_F3, { || Hold_em( FALSE ) } )
     sFunKey4 := setkey( K_F4, { || CashLineDisc( @msellprice, Bvars( B_DISC1 ), K_F4, @mMasterPrice, @discdone, mrow, mspec_dep ) } )
     okf5 := setkey( K_F5, { || CashLineDisc( @msellprice, Bvars( B_DISC2 ), K_F5, @mMasterPrice, @discdone, mrow, mspec_dep ) } )
     okf6 := setkey( K_F6, { || CashLineDisc( @msellprice, Bvars( B_DISC3 ), K_F6, @mMasterPrice, @discdone, mrow, mspec_dep ) } )
     okf7 := setkey( K_F7, { || CashLineDisc( @msellprice, Bvars( B_DISC4 ), K_F7, @mMasterPrice, @discdone, mrow, mspec_dep ) } )
     okf8 := setkey( K_F8, { || CashLineDisc( @msellprice, 0, K_F8, @mMasterPrice, @discdone, mrow ) } )
     okf9 := setkey( K_F9, { || F_qty( @qtyflag, specflag, @mqty, mrow ) } )
     okf10 := setkey( K_F10, { || F_ret( @retflag, mrow ) } )
     syscolor( C_NORMAL )
     @ mrow,46 get mSellPrice pict PRICE_PICT ;
       valid( mSellPrice < 9000 .and. if( msellprice=0, mspec_dep > 0 .or. Secure( X_SALEVOID ),TRUE ) )
     read

     setkey( K_F3, sFunKey3 )
     setkey( K_F4, sFunKey4 )
     setkey( K_F5, okf5 )
     setkey( K_F6, okf6 )
     setkey( K_F7, okf7 )
     setkey( K_F8, okf8 )
     setkey( K_F9, okf9 )
     setkey( K_F10, okf10 )
     Box_Restore( mscr )

    else
     @ mrow,46 say mSellPrice pict PRICE_PICT 

    endif

    if lastkey() = K_ESC
     SysAudit( 'LineVoid' + Ns( mSellPrice ) + substr( master->desc, 1, 10 ) )
     Line_clear( mrow )

    else
     if master->sell_price = 0 .and. mMasterPrice = 0
      mMasterPrice := mSellPrice

     endif
     mdisval := mMasterPrice-mSellPrice
     mcost := master->cost_price
     if master->cost_price = 0 .and. LastFkeyHit != 0
      mcost := zero( mSellPrice,100 ) * ( 100 - ( Fkeys[ abs( LastFkeyHit -1 ), 2 ] ) )

     endif
     if qtyflag
      @ mrow,62 say mSellPrice * mqty pict '99999.99'

     endif
     if !hdpos .and. master->onhand - mqty < -100
      Error( "Lower Limit for Negative Stock exceeded", 12 )
      SysAudit( "LowLim" + master->id )

     endif
     if retflag
      mqty := -mqty

     endif

     if firstpass
      Lvars( L_CUST_NO, Custnum() )    // Increment the customer number
      Highlight( 01, 01, 'This Tran #', Ns( Lvars( L_CUST_NO ), 4 ) )

//      @ 01,01 say 'This Tran #' + Ns( Lvars( L_CUST_NO ),4 )

     endif

     firstpass := FALSE
     select cashtemp

     if mspec_dep > 0
      Add_rec( 'cashtemp' )
      cashtemp->tran_type := 'SDP'
      cashtemp->sale_date := Bvars( B_DATE )
      cashtemp->time := time()
      cashtemp->register := Lvars( L_REGISTER )
      cashtemp->unit_price := mspec_dep
      cashtemp->qty := 1
      cashtemp->cust_no := Lvars( L_CUST_NO )
      cashtemp->name := Lookitup( 'customer', special->key, 'name' )
      cashtemp->spec_no := mspec_no

     endif

     Add_rec( 'cashtemp' )
     cashtemp->sale_date := Bvars( B_DATE )
     cashtemp->time := time()
     cashtemp->tran_num := Lvars( L_CUST_NO )
     cashtemp->register := Lvars( L_REGISTER )
     cashtemp->id := master->id
     cashtemp->qty := mqty
     cashtemp->cost_price := mcost
     cashtemp->unit_price := mMasterPrice+mspec_dep
     cashtemp->discount := mdisval
     cashtemp->tran_type := mtrantype
     cashtemp->sales_tax := mitemtax
     cashtemp->spec_no := mspec_no
     cashtemp->key := if( mCustHistFlag, mCustKey, '' )
     cashtemp->name := if( mCustHistFlag, mCustName, '' )
     cashtemp->operator := Oddvars( OPERCODE )

     cashtemp->sale_type := msale_type

     cashtemp->( dbrunlock() )

     if mCustHistFlag .and. firstpass
      Dock_line(  '~Customer : ' + left( customer->name, 26 ) )

     endif

     if qtyflag
      Dock_line(   substr( master->desc, 1, 18 )+' '+str( mqty, 3 ) +;
       ' @'+str( mSellPrice, 7, 2 )+' '+str( mSellPrice * mqty, 8, 2 ) )
      Dock_line(  master->id )
     else
      Dock_line(  substr( master->desc, 1, 30 -len(trim(master->id)) ) + ' ' + trim( master->id )+' '+str( mSellPrice * mqty, 8, 2 ) )

     endif

     if mspec_dep != 0
      Dock_line(  space( 12 )+' After Deposit Paid '+str( mspec_dep, 8, 2 ) )

     endif
     if mdisval > 0
      Dock_line(  space( 7 ) +'Inc Discount of '+str( mdisval / ( mMasterPrice / 100 ), 4, 1 );
       +'%  $-'+str( mdisval*mqty, 8, 2 ) )

     endif
     mNoDiscTot += if( master->NoDisc, mSellPrice * mQty, 0 )
     mgross    += mMasterPrice * mqty
     mtotcost  += mcost * mqty
     mSubTotal += mSellPrice * mqty
     mtax      += mitemtax * mqty

     if( mrow > 24 - 10, mrow := 5, mrow++ )
      @ mrow,0 clear
      @ mrow+1,37 say 'Sub Total        ' + str( mSubTotal, 7, 2 )
      Poz( 'Sub Total$' + Ns( mSubTotal, 8, 2 ) )

    endif
   endif
  endif  // Updated()
 enddo
 if !firstpass
  hasdisc := NO
  mSubTotal := Nocents( mSubTotal )
  mFinalTot := mSubTotal
  msave := Box_Save( mrow+1,3,mrow+7,30,4 )
  @ mrow+2,05 say '<F4> = '+str( Bvars( B_DISC1 ), 5, 2 ) + '% Discount'
  @ mrow+3,05 say '<F5> = '+str( Bvars( B_DISC2 ), 5, 2 ) + '% Discount'
  @ mrow+4,05 say '<F6> = '+str( Bvars( B_DISC3 ), 5, 2 ) + '% Discount'
  @ mrow+5,05 say '<F7> = '+str( Bvars( B_DISC4 ), 5, 2 ) + '% Discount'
  @ mrow+6,05 say '<F8> = Add Your Own Disc'
  syscolor( C_NORMAL )
  sFunKey4 := setkey( K_F4, { || CashTotDisc( mrow, Bvars( B_DISC1 ), K_F4, @hasdisc, @mFinalTot ) } )
  okf5 := setkey( K_F5, { || CashTotDisc( mrow, Bvars( B_DISC2 ), K_F5, @hasdisc, @mFinalTot ) } )
  okf6 := setkey( K_F6, { || CashTotDisc( mrow, Bvars( B_DISC3 ), K_F6, @hasdisc, @mFinalTot ) } )
  okf7 := setkey( K_F7, { || CashTotDisc( mrow, Bvars( B_DISC4 ), K_F7, @hasdisc, @mFinalTot ) } )
  okf8 := setkey( K_F8, { || CashTotDisc( mrow, 0 , K_F8, @hasdisc, @mFinalTot ) } )
  @ mrow+2,37 say 'Total Sale      ' get mFinalTot pict '9999.99';
      valid( if( hasdisc, YES, mFinalTot = mSubTotal ) )
  read
  Box_Restore( msave )
  setkey( K_F4, sFunKey4 )
  setkey( K_F5, okf5 )
  setkey( K_F6, okf6 )
  setkey( K_F7, okf7 )
  setkey( K_F8, okf8 )
  if lastkey() = K_ESC
   if Salevoid()
    loop

   endif

  endif

  Poz('Total Sale$' + Ns( mFinalTot, 8, 2 ) )

  select cashtemp
  if mSubTotal != mFinalTot  // Approportion Discounts
   disc_val := 100 - Zero( mFinalTot, zero( mSubTotal, 100 ) )
   cashtemp->( dbgotop() )
   while !cashtemp->( eof() )
    if !empty( cashtemp->id )
     Rec_lock( 'cashtemp' )
     cashtemp->discount += ( ( cashtemp->unit_price-cashtemp->discount )/100 ) * disc_val
     cashtemp->( dbrunlock() )

    endif
    cashtemp->( dbskip() )

   enddo

  endif

  mtran_qty := if( mFinalTot >= 0, 1, -1 )

  Dock_line(  space( 16 ) + 'Total sale    ' + str( mSubTotal, 10, 2 ) )

  if mFinalTot != mSubTotal
   mdisval := mSubTotal - mFinalTot
   if mdisval > 0
    Dock_line(  space( 5 ) + 'Total Discount of ' +Ns( ( mdisval / ( mSubTotal / 100 ) ), 4, 1 ) + ;
       '%  $-' + str( mdisval, 8, 2 ) )

   endif
  endif

  Tender( mFinalTot, mGross, mtax, mtotcost, mtran_qty, "cashtemp", mtrantype, mrow, mCustName, mNoDiscTot, mSType )

  if cashtemp->( reccount() ) > 5
   Box_Save( 10, 10, 12, 70 )
   Center( 11, 'Processing Sale - Please wait' )

  endif


  if CashTemp->( reccount() ) > 0

   Dock_foot( )
   Dock_print( )

   cashtemp->( dbgotop() )
   while !cashtemp->( eof() )
    if !hdpos .and. !empty( cashtemp->id )
     if cashtemp->spec_no != 0 .and. !empty( cashtemp->id ) // Update Special Order Files
      select special
      dbseek( cashtemp->spec_no )
      locate for special->id = cashtemp->id ;
      while special->number = cashtemp->spec_no
      if found()
       Rec_lock()
       special->delivered += cashtemp->qty
       special->deposit := 0
       dbrunlock()

      endif

     endif

     if master->( dbseek( cashtemp->id ) )   // Update master file
      Oddvars( IS_CONSIGNED, cashtemp->consign )  // Need to init these flags each time for routine to work
      Rec_lock( 'master' )
      Update_oh( -cashtemp->qty )

      master->dsale := Bvars( B_DATE )

      if cashtemp->spec_no != 0 .and. !empty( cashtemp->id ) // Update Special qtys
       master->special -= cashtemp->qty

      endif
      master->( dbrunlock() )

     endif

    endif

    Add_rec( 'sales' )
    for x := 1 to sales->( fcount() )
     sales->( fieldput( x, cashtemp->( fieldget( x ) ) ) )

    next

    sales->( dbrunlock() )
    cashtemp->( dbskip() )

   enddo

  endif

  select cashtemp
  zap

  sales->( dbcommit() )  
  
  Error('')
  Poz()

 endif
enddo

setkey( K_SH_F10, { || oksf10 } )
setkey( K_SH_F12, { || oksf12 } )
dbcloseall()

return nil

*

proc tender ( mFinalTot, mSubTotal, mtax, mcost, mtran_qty, mfile, mtran, mrow, mname, mStype, mcustkey, aPreLines )
local mbnkbranch, mbank, mdrawer, mremain:=abs(mFinalTot), mamt_ten, mchange, mcdflag
local mtran_amt, tscr, mscr, mvoucher
local mopscr
local mtend := 'CAS'
local x, getlist:={}
local firstpass := TRUE
local mDiscTotal := 0

local mDiscTemp := 0

default aPreLines to {}

if tt_types = nil
 Setup_tt_types()
endif

default mSType to ''
default mcustkey to ''
mamt_ten := mremain

while mremain > 0

 mvoucher := space( 6 )
 mopscr := Box_Save( 3, 3, numtt + 4, 31, 7 )

 @ 04, 05 say 'Tender Types'
 @ 05, 04 say replicate( chr( 196 ), 25 )

 for x := 3 to numtt
  if x < 11
   set function x to tt_types[x]

  endif
  @ 3+x, 05 say '<F' + Ns( x ) + '> ' + tt_names[x]
  if x = 11
   setkey( K_F11, { || keystuff( tt_types[11] ) } )

  endif
  if x = 12
   setkey( K_F12, { || keystuff( tt_types[12] ) } )

  endif

 next

 Syscolor( C_NORMAL )
 mscr:=Box_Save( mrow+3, 35, mrow+7, 70 )
 set confirm off
 mtend := 'CAS'
 @ mrow+4, 42 say 'Tender Type' get mtend pict '!!!' valid( ascan( tt_types, mtend ) != 0 )
 @ mrow+5, 37 say 'Amount Remaining ' + str( mremain * mtran_qty, 7, 2 )
 read
 Syscolor( 3 )
 mcdflag := !tt_cdflag[ ascan( tt_types, mtend ) ]
 @ mrow+4, 37 say space(30)
 @ mrow+4, 37 say tend_desc( mtend ) + " "
 syscolor( C_NORMAL )
 set confirm on
 Box_Restore( mopscr )

 @ mrow+5, 37 say if( mamt_ten > 0, 'Amount Tendered ', 'Amount Refunded ' ) get mamt_ten pict '9999.99'
 read

 if lastkey() = K_ESC
  if Salevoid()
   exit

  endif

 endif

 mbank := space( 3 )
 mbnkbranch := space( 15 )
 mdrawer := if( mname != nil, padr( mname, 20 ), space( 20 ) )

 if mtend = 'CHQ'
  tscr := Box_Save( mrow+5, 37, mrow+9, 70 )
  @ mrow+6, 38 say '   Bank' get mbank pict '@!'
  @ mrow+7, 38 say ' Branch' get mbnkbranch pict '@!'
  @ mrow+8, 38 say ' Drawer' get mdrawer
  read
  Box_Restore( tscr )

 endif

 if '/' $ mtend 
  tscr := Box_Save( mrow+5, 37, mrow+7, 70 )
  @ mrow+6, 38 say 'Surname' get mdrawer
  read
  Box_Restore( tscr )

 endif

 Dock_line( left( tend_desc( mtend ), 15 ) + ;
      if( mamt_ten * mtran_qty > 0, ' Amount Tendered ', ' Amount Refunded ' ) ;
      + str( mamt_ten * mtran_qty, 8, 2 ) )

//  mpozDisc += mDisctemp

 if mamt_ten >= mremain
  if mcdflag
   Open_de_draw()

  endif
  mchange := ( mamt_ten - mremain ) * mtran_qty
  @ mrow + 6, 37 say 'Change           ' + str( mchange, 7, 2 )
  Dock_line( padr( 'Change', 32 ) + str( mchange, 8, 2 ) )
  Poz( 'Change$' + Ns( mchange, 8, 2 ) )
  mtran_amt := mremain

 else
  mtran_amt := mamt_ten

 endif        // Amount Tendered >= Amount Remaining

 mremain -= mtran_amt

 Add_rec( mfile )
   
 ( mfile )->tran_type := mtran
 ( mfile )->tend_type := mtend
 ( mfile )->sale_date := Bvars( B_DATE )
 ( mfile )->time := time()
 ( mfile )->register := Lvars( L_REGISTER )
 ( mfile )->cost_price := if( firstpass, mcost, 0 ) 
 ( mfile )->sales_tax := if( firstpass, mtax, 0 )
 ( mfile )->qty := mtran_qty
 ( mfile )->tran_num := Lvars( L_CUST_NO )
 ( mfile )->bank := mbank
 ( mfile )->bnkbranch := mbnkbranch
 ( mfile )->drawer := mdrawer
 ( mfile )->name := if( !empty( mname ), mname, mdrawer )
 ( mfile )->operator := Oddvars( OPERCODE )
 ( mfile )->voucher := mvoucher
 ( mfile )->key := mcustkey
 if -Vs( mremain ) <= 0
  ( mfile )->discount := mSubtotal-mfinaltot
  ( mfile )->unit_price := mtran_amt
    
 endif
 ( mfile )->( dbrunlock() )

 mDiscTotal := 0
 mamt_ten := mremain
 @ mrow+5, 37 say 'Amount Remaining ' + str( mremain * mtran_qty, 7, 2 )

enddo
return

*

procedure f_qty ( qtyflag, specflag, mqty, mrow )
local getlist := {}
@ 4,6 say 'Desc                                     Price     Qty   Extend'
mqty := 0
@ mrow,54 say space( 23 )
@ mrow,60 - len( QTY_PICT ) get mqty pict QTY_PICT valid( if( specflag, mqty <= special->received - special->delivered, TRUE ) )
if specflag
 @ mrow,63 say 'Avail=' + Ns( special->received - special->delivered )

endif
read
keyboard chr( K_ENTER )
qtyflag := TRUE
return

*

procedure f_ret ( retflag, mrow )
if Secure( X_SALEVOID )
 @ mrow,1 say '<Ret>'
 retflag := TRUE

endif
return

*

procedure custhist ( mCustName, mCustHistFlag, mCustKey )
local mscr := Box_Save()
if CustFind( FALSE )
 Highlight( 1, 1, 'Customer ', trim( customer->name ) )
 mCustHistFlag := TRUE
 Rec_lock( 'customer' )
 customer->date_lp := Bvars( B_DATE )
 customer->( dbrunlock() )
 mCustName := customer->name
 mCustKey := customer->key
endif
Box_Restore( mscr )
return

*

Function Is_special ( temp_spec, retflag, specflag, mrow )
local mscr,dbsel:=select(),getlist:={}
if select( "special" ) = 0
 if !Netuse( "special" )
  return FALSE

 endif

endif
special->( ordsetfocus( 'number' ) )
if !retflag
 mscr := Box_Save( 3, 25, 6, 55 )
 temp_spec := 0
 @ 4,26 say 'Special Order No.' get temp_spec pict '999999'
 read
 if !special->( dbseek( temp_spec ) )
  Error( "Special order Number not Found", 12 )

 else
  specflag := TRUE
  Highlight( mrow, 75, '', 'S' )

 endif
 Box_Restore( mscr )

endif
select ( dbsel )
return TRUE

*

function Nocents ( p_val )
local pb, new_bit, amt, new_amt
amt := p_val
while TRUE
 pb := right( Ns( amt, 10, 2 ), 1 )         // for Parameter Bit
 if Bvars( B_CENTROUND )                      // For People who only want to round down
  new_bit := if( pb $ "01234" , "0" , "5" )
 else
  new_bit := if( pb $ "120", "0", if( pb $ "34567", "5", pb ) )
 endif
 if pb $ '01234567' .or. Bvars( B_CENTROUND )
  exit
 else
  amt += 0.01   // Must add 2 cents to get close to next round point and go again
 endif
enddo
new_amt := val( substr( Ns( amt, 10, 2 ), 1, len( Ns( amt, 10, 2 ) ) -1 ) + new_bit )
round_amt += ( new_amt - p_val )  // This is a static from top of file
return new_amt

*

function RePrintDock
local getlist:={},tran_no:=0,msave:=Box_Save(02,10,04,70)
local odbf:=select(),mgo:=TRUE,currec,tcount:=0,mtot:=0


@ 03,12 say 'Transaction Number to reprint' get tran_no pict '99999'
read

if updated()
 select sales
 currec := recno()
 locate for sales->tran_num = tran_no .and. sales->register = Lvars( L_REGISTER )
 if !found()
  Error( "Transaction Number not Found", 12 )

 else
  if !Lvars( L_DOCKET )
   DocketStatus()

  endif
  while !sales->( eof() ) .and. tcount < 40
   master->( dbseek( sales->id ) )
   select sales
   Dock_head()
   if tran_no = sales->tran_num .and. sales->register = Lvars( L_REGISTER )
    if !empty(sales->id)
     if sales->qty > 1
      Dock_line( substr(master->desc,1,19)+' '+str(sales->qty,2)+;
      ' @'+str( sales->unit_price,7,2)+' '+str(sales->unit_price*sales->qty,8,2))

     else
      Dock_line( substr(master->desc,1,31)+' '+str(sales->unit_price*sales->qty,8,2))

     endif
     if sales->discount > 0
      Dock_line(  space(7) +'Inc Discount of '+str((sales->discount/(sales->unit_price/100)),4,1)+;
      '%  $-'+str( sales->discount*sales->qty,8,2))

     endif
     mtot += ( sales->unit_price-sales->discount) * sales->qty
    else
     if mtot > 0
      Dock_line( space(16)+'Total sale    '+str(mtot,10,2))
      mtot := 0
      if sales->discount > 0
       Dock_line( space(5)+'Total Discount of '+Ns((sales->discount/(mtot/100)),4,1)+;
       '%  $-'+str(sales->discount,8,2))
      endif
     endif
     if !empty( sales->tend_type )
      Dock_line( substr(tend_desc(sales->tend_type),1,15)+' Amount Tendered '+;
      str(sales->unit_price*sales->qty,8,2))

     endif

    endif
    tcount++

   endif
   sales->( dbskip() )

  enddo
  if tcount > 0
   dock_foot()
   dock_print()

  endif

 endif
 sales->( dbgoto( currec ) )

endif
select ( odbf )
Box_Restore( msave )
return nil

*

func SaleVoid
local voi_tot := 0, voidret := FALSE, mscr
if Secure( X_SALEVOID )
 if select("cashtemp") = 0
  if select( 'buyback' ) != 0
   Box_Save( 8, 8, 10, 72, C_BRIGHT )
   Center(9,'-=< Voiding Sale - Please Wait >=-')
   select buyback
   zap
   Error( 'Sale Voided', 12 )
   voidret := TRUE

  else
   Error("No sales void function available here",12)

  endif

 else
  mscr := Box_Save( 8, 8, 10, 72, C_MAUVE )
  Center( 9, '-=< Voiding Sale - Please Wait >=-')

  select cashtemp
  sum cashtemp->unit_price * cashtemp->qty to voi_tot
  SysAudit( "SalVoi"+Ns( voi_tot,7,2 ) )
  zap         //  And Clear it !!

  Add_rec( 'sales' )
  sales->tran_type := 'VOI'
  sales->name := Ns( voi_tot, 10, 2 )
  sales->tran_num := Lvars( L_CUST_NO )
  sales->time := time()
  sales->sale_date := Bvars( B_DATE )
  sales->register := Lvars( L_REGISTER )
  sales->( dbrunlock() )
  Lvars( L_CUST_NO, Custnum() )
  SysAudit( "SalVoi" + Ns( voi_tot,7,2 ) )
  Error( 'Sale Voided', 12 )

  voidret := TRUE
  Box_Restore( mscr )

 endif
endif
return voidret

*

procedure CashTotDisc ( mrow, mdisc, mkey, hasdisc, mFinalTot )
local getlist := {}, mdisctot:=0
if mkey == K_F8
 @ mrow+3,37 say '  Enter Discount %' get mdisc pict '99.9'
 read
 line_clear( mrow + 3 )
endif
#ifdef NO_NETT_DISCOUNTS
cashtemp->( dbgotop() )
while !cashtemp->( eof() )
 if master->( dbseek( cashtemp->id ) ) 
  if !master->nodisc
   mdisctot += cashtemp->qty * ( ( cashtemp->unit_price-cashtemp->discount)/100 * mdisc )
  endif
 endif
 cashtemp->( dbskip() )
enddo 
mFinaltot := Nocents( mFinalTot - round( mdisctot,2 ) )
#else
mFinalTot := Nocents( mFinalTot - round( ( mFinalTot / 100 * mdisc ), 2 ) )
#endif
@ mrow+2,37 say 'Total Sale       ' + str( mFinalTot, 7, 2 )
@ mrow+2,62 say '(Less '+str( mdisc, 4, 1 ) + '% Disc)'
mdisctot := mdisc   // was mtotdisc DAC
hasdisc := TRUE
return

*

Func CashLineDisc ( msellprice, mdisc, mkey, mMasterPrice, discdone, mrow, spec_dep )
local getlist:={}
default spec_dep to 0
#ifdef NO_NETT_DISCOUNTS
if master->nodisc
 Error( 'Item is Nett Priced! - No Discount allowed', 12 )
 return nil
endif
#endif
if !discdone
 if master->sell_price = 0
  mMasterPrice := mSellPrice
 endif
 if mkey == K_F8
  @ mrow+1,35 say 'Enter Discount %' get mdisc pict '99.9'
  read
 endif
 discdone := TRUE
 mSellPrice -= round( ( ( mSellPrice+spec_dep )/ 100 * mdisc ), 2 ) 
endif
return nil


*

function setup_tt_types
local x, olddbf := select()

if Netuse( "sysrec" )
 tt_types := array( 3 )
 tt_names := array( 3 )
 tt_cdflag := array( 3 )
 tt_types[2] := 'DEP'
 tt_names[2] := 'Deposit Refund'
 tt_cdflag[2] := FALSE
 tt_types[3] := 'CAS'                // Default Tender Types
 tt_names[3] := 'Cash'               // and a description to suit
 tt_cdflag[3] := FALSE
 numtt := 3
 for x := 4 to 12                                      // Maximum Number Supported
  if empty( fieldget( fieldpos( 'pos' + Ns( x ) ) ) )  // Is field "POS?" empty
   exit                                                // Kill the loop ttypes must be contiguous
  else
   aadd( tt_types, fieldget( fieldpos( 'pos' + Ns( x ) ) ) )            // Function key assignments
   aadd( tt_names, fieldget( fieldpos( 'posn' + Ns( x ) ) ) )           // and Descriptions for Same
   aadd( tt_cdflag, fieldget( fieldpos( 'pos' + Ns( x ) + 'cash' ) ) )  // and whether not to open Cash Drawer
  endif
  numtt := x
 next
 dbclosearea()        // Close sysrec file
endif
select( olddbf )

return { tt_types, tt_names, tt_cdflag, numtt }

*

Procedure dock_head()

aDocket := {} // Clear the global array
// if !Lvars( L_DOCKET )
// Dock_line(  chr( 27 ) + chr( 33 ) +chr( 1 ) )
// Dock_line(  chr( 27 ) + chr( 99 ) + chr( 48 ) + chr( 1 ) )
// Dock_line(  chr( 27 ) + chr( 122 ) + chr( 1 ) )
// Error( 'Docket is set to off - Cannot reprint header', 12 )

//else
 Dock_line(  BIGCHARS + Bvars( B_DOCKLN1 ) + NOBIGCHARS )
 if !empty( Bvars( B_DOCKLN2 ) )
  if len( trim( Bvars( B_DOCKLN2 ) ) ) < 21
   Dock_line(  BIGCHARS + trim( Bvars( B_DOCKLN2 ) ) + NOBIGCHARS )

  else
   Dock_line(  Bvars( B_DOCKLN2 ) )

  endif

 endif
 Dock_line( "   Tax Invoice - ABN#" + Bvars( B_ACN ) )

// endif
return
*

Procedure Dock_line ( p_line, lSuppSpace )

/* used to print the docket line by line - now just builds the array aDocket */

Default lSuppSpace to TRUE



//if Lvars( L_DOCKET )      // Docket Suppress
// Print_find( "docket" )
 
// set console off
// set print on
 if '~' $ p_line         // The tilde(~) will cause this line in red
  p_line = chr(19)+substr(p_line,1,at('~',p_line)-1)+substr(p_line,at('~',p_line)+1,40)

 else
  if lSuppSpace
   p_line = space(1) + p_line

  else
   p_line = p_line

  endif

 endif
 aadd( aDocket, p_line )

return

*

procedure dock_foot()
local sFootText := trim( BVars( B_GREET ) )

Dock_Line( Bvars( B_PHONE ) + space( 3 ) + dtoc( Bvars( B_DATE ) ) + ' ' +;
        substr( time(), 1, 5 ) + str( Lvars( L_CUST_NO ), 6 ) )

if !empty( Bvars( B_GREET ) )
 if len( trim( Bvars( B_GREET ) ) ) < 21
  Dock_line( BIGCHARS + trim( Bvars( B_GREET ) ) + NOBIGCHARS )

 else
  do while len( sFootText ) > 0
   Dock_line( substr( sFootText, 1, 40 ) )
   sFootText := substr( sFootText, 41 )

  enddo

 endif

endif

#ifdef THELOOK
Dock_line( "Thank you for shopping at The Look" )
#endif

if Lvars( L_CUTTER )      // for those sites with a cutting docket printer
 Dock_line( replicate( CRLF, 2 ) )
 Dock_line( PAPERCUT, FALSE )

endif

// Dock_print()

return

*


Procedure Dock_print
local x

Print_find( "docket" )

set console off
set print on

for x := 1 to len( aDocket )
 ? aDocket[x]

next
set print off
set console on

set printer to  // Should Flush the printer

RETURN


function fkon 
default fkeys to array( 10, 2 )
Line_clear( 24-1 )
Line_clear( 24 )
@ 24-1,05 say 'F3        F4        F5        F6        F7       F8        F9        F10'
syscolor( C_INVERSE )
@ 24,01 say Lvars( L_F3N )
@ 24,11 say Lvars( L_F4N )
@ 24,21 say Lvars( L_F5N )
@ 24,31 say Lvars( L_F6N )
@ 24,41 say Lvars( L_F7N )
@ 24,51 say Lvars( L_F8N )
@ 24,61 say Lvars( L_F9N )
@ 24,71 say Lvars( L_F10N )
syscolor( C_NORMAL )
fkeys[ 3, 1 ] := setkey( K_F3, { || keyret( Lvars( L_F3 ) ) } )
fkeys[ 3, 2 ] := Lvars( L_F3MARGIN )
fkeys[ 4, 1 ] := setkey( K_F4, { || keyret( Lvars( L_F4 ) ) } )
fkeys[ 4, 2 ] := Lvars( L_F4MARGIN )
fkeys[ 5, 1 ] := setkey( K_F5, { || keyret( Lvars( L_F5 ) ) } )
fkeys[ 5, 2 ] := Lvars( L_F5MARGIN )
fkeys[ 6, 1 ] := setkey( K_F6, { || keyret( Lvars( L_F6 ) ) } )
fkeys[ 6, 2 ] := Lvars( L_F6MARGIN )
fkeys[ 7, 1 ] := setkey( K_F7, { || keyret( Lvars( L_F7 ) ) } )
fkeys[ 7, 2 ] := Lvars( L_F7MARGIN )
fkeys[ 8, 1 ] := setkey( K_F8, { || keyret( Lvars( L_F8 ) ) } )
fkeys[ 8, 2 ] := Lvars( L_F8MARGIN )
fkeys[ 9, 1 ] := setkey( K_F9, { || keyret( Lvars( L_F9 ) ) } )
fkeys[ 9, 2 ] := Lvars( L_F9MARGIN )
fkeys[ 10, 1 ] := setkey( K_F10, { || keyret( Lvars( L_F10 ) ) } )
fkeys[ 10, 2 ] := Lvars( L_F10MARGIN )
return nil

*

function keyret ( l_bit )
keyboard l_bit + chr(13)
LastFkeyHit := lastkey()
return nil

*

function keystuff ( l_bit )
keyboard l_bit
return nil

*

Procedure Fkoff
Line_clear( 24-1 )
Line_clear( 24 )
setkey( K_F3, { || fkeys[ 3, 1 ] } )
setkey( K_F4, { || fkeys[ 4, 1 ] } )
setkey( K_F5, { || fkeys[ 5, 1 ] } )
setkey( K_F6, { || fkeys[ 6, 1 ] } )
setkey( K_F7, { || fkeys[ 7, 1 ] } )
setkey( K_F8, { || fkeys[ 8, 1 ] } )
setkey( K_F9, { || fkeys[ 9, 1 ] } )
setkey( K_F10, { || fkeys[ 10, 1 ] } )
return

*

func tend_desc ( p_tran )
local x, mret
if tt_types = nil
 Setup_tt_types()
endif 
x:=ascan( tt_types, p_tran )
mret := if( x = 0, 'Unknown', trim( tt_names[x] ) ) 
return mret + replicate(' ',15 - len( trim( mret ) ) ) 

*

function SetSalesTax ( tax_exempt )
@ 1,30 say 'Sales Tax Exempt Sale'
tax_exempt := TRUE
return nil

*

function custnum ( astartnum )
#define NUMBER 1

local olddbf:=select(),retval:=0, mstru
static custnofile
default custnofile to 'Z' + substr( trim( Lvars( L_NODE ) ), -7 )

if !file( Oddvars( SYSPATH ) + custnofile + '.dbf' )
 mstru := {}
 aadd( mstru, { 'NUMBER', 'N', 6, 0 } )
 dbcreate( Oddvars( SYSPATH ) + custnofile, mstru )
endif
if Netuse( custnofile, TRUE, 0, 'custnums' )
 if lastrec() = 0
  Add_rec()
 endif
 if astartnum != nil
  fieldput( NUMBER, astartnum )
 else
  if fieldget( NUMBER ) + 1 >= 1000000
   fieldput( NUMBER, 1 )
  else
   fieldput( NUMBER, fieldget( NUMBER ) + 1 )
  endif
 endif
 retval:=fieldget( NUMBER )
 custnums->( dbclosearea() )
endif
select ( olddbf )
return ( retval )

*
/*
func mktg_type
local mstype, mscr,x // := Box_Save( 2, 10, 10, 40 ), x
static mktg_types, mktg_names
if mktg_types = nil
 if Netuse( "sysrec", SHARED, 0 )  // Must wait - About to set up Marketing Types
  mktg_types := {}
  mktg_names := {}
  for x := 1 to 10                               // Maximum Number Supported
   if empty( fieldget( fieldpos( 'stype' + Ns( x ) ) ) )       // Is field st empty
    exit                                         // Kill the loop stypes must be contiguous
   else
    aadd( mktg_types, nil )
    aadd( mktg_names, nil )
    mktg_types[x] := fieldget( fieldpos( 'stype' + Ns( x ) ) )  // Set up Pos Variables
    mktg_names[x] := fieldget( fieldpos( 'stypen' + Ns( x ) ) ) // and Descriptions for Same
   endif
  next
  dbclosearea()                                 // Close sysrec file
 endif
endif
mscr := Box_Save( 2, 10, 2+len(mktg_names)+1, 40 )
Heading( 'Select Sales Type' )
for x := 1 to len( mktg_names )
 @ x+2,12 prompt mktg_names[ x ]
next
menu to mstype
Box_Restore( mscr )
return if( mstype != 0, mktg_types[ mstype ], '' )

*/

function contoggle
price_conf := !price_conf
@ 02,67 say if( price_conf, space(10), 'No Confirm' )
return nil

*

function poz ( disp_text )
static portopen:=FALSE
#define POZ_PORT 2   // Only temporary
/*
   Epson DM-D202 Customer displays are two lines. This function looks for the
   $ sign and attempt to place it ( and following data ) on the second line 
*/   
if Lvars( L_POZ )
#ifndef __HARBOUR__
 if !portopen
  tp_open( POZ_PORT, 32, 128, 9600, 8, 'N', 1 )
  portopen := TRUE
 endif
 if disp_text = nil
  if !empty( Bvars( B_GREET ) )
 #ifdef EPSON_POZ
   tp_send( POZ_PORT, FF + BPOSCUST )
 #else
   tp_send( POZ_PORT, chr( 22 ) + chr( 17 ) + trim( Bvars( B_GREET ) ) + chr( 16 ) )
 #endif
  endif
 else
 #ifndef EPSON_POZ
  if '$' $ disp_text
   tp_send( POZ_PORT, chr( 3 ) + padr( left( disp_text, at( '$', disp_text ) - 1 ), 10 ) + ;
            padl( trim( substr( disp_text, at( '$', disp_text ), 10 ) ), 10 ) )
  else
   tp_send( POZ_PORT, chr( 3 ) + substr( disp_text, 1, 22 ) )
  endif
 #else
  if '$' $ disp_text
   tp_send( POZ_PORT, FF + left( disp_text, min( at( '$', disp_text ) - 1, 19 ) ) + ;
            CRLF + padl( trim( substr( disp_text, at( '$', disp_text ), 20 ) ), 20 ) )
  else
//   tp_send( POZ_PORT, FF + substr( disp_text, 1, 20 ) )
   tp_send( POZ_PORT, FF + disp_text )
  endif          
 #endif
 endif
#endif
disp_text := nil
endif
return nil

