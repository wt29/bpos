/*

 SaleCash.prg - Cash Sales

 Last change:  TG   29 Apr 2011    4:13 pm

 */

#include "bpos.ch"

static numtt, tt_types, tt_names, tt_cdflag, fkeys, lastfkeyhit:=0, price_conf, round_amt := 0
static aDocket := {}, lPrintDocket

memvar nTotalCost, nTotalSale, nTotalSalesTax, nTotalFullPrice

function S_CashSales ( hdpos )

local lMainLoop:=FALSE, lMain, nFullPrice, nCostPrice, nSubTotal, firstpass, spec_done
local mspec_no, nSpecialDeposit, sID, nDiscountValue, nTaxValue, mtran_qty, disc_val, mtot
local sFunKey3, sFunKey4, bKeyF1, bKeyF5, bKeyF6, bKeyF7, bKeyF8, bKeyF9, bKeyF10, bKeyF12
local bKeyAltF1, bKeyCtrlf1, bKeyCtrlf2, msave, bKeyShiftF10, bKeyShiftF12, cScreen
local nReplRec, nItemTax, mCustName, x
local mtrantype, mCustHistFlag, tax_exempt, retflag, specflag, qtyflag, discdone
local nQuantity, mmasterprice, hasdisc, nRowNum, nFinalTot, nSellPrice, msale_type, mCustKey
local mstype, mNoDiscTot
local getlist := {}
local sPrompt

private nTotalCost, nTotalSale, nTotalSalesTax, nTotalFullPrice

default hdpos to FALSE

if Master_use()
 lMainLoop := Netuse( 'sales' ) 
 nReplRec := lastrec()

endif

if lMainLoop
 if select( "cashtemp" ) != 0
  cashtemp->( dbclosearea() )
 endif
 select sales
 copy stru to ( Oddvars( TEMPFILE ) )
 if !Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "cashtemp" ) 
  Error( "Cannot open " + Oddvars( TEMPFILE ), 12 )
  lMainLoop := FALSE

 else
  set relation to cashtemp->id into master
  
 endif

endif

price_conf := TRUE

while lMainLoop

 lMain := TRUE
 firstpass := TRUE

 while lMain
  LastFKeyHit := 0
  retflag := FALSE
  qtyflag := FALSE
  specflag := FALSE
  discdone := FALSE
  mspec_no := 0
  nSpecialDeposit := 0
  nQuantity := 1
  nItemTax := 0
  nDiscountValue := 0
  round_amt := 0
  
  if firstpass
   cls
//   Print_find( "Docket" )
   Dock_Head()   // Set up the header and clear docket array
   nTaxValue := 0
   nFullPrice := 0
   nTotalCost := 0
   nSubTotal := 0
   mNoDiscTot := 0         // The total sales proportion that is not discountable
   mCustKey := ''
   mCustName := ''         // Cust name for Misc Receipts
   spec_done := FALSE
   tax_exempt := FALSE
   mCustHistFlag := FALSE
   nRowNum := 5
   mTranType := 'C/S'
   mSType := '20'

   bKeyF1 := setkey( K_F1, { || CSalesHelp(1) } )
   bKeyShiftF10 := setkey( K_SH_F10, { || RePrintDock() } )
   bKeyShiftF12 := setkey( K_SH_F12, { || ConToggle() } )
   bKeyCtrlF1 := setkey( K_CTRL_F1, { || Custhist( @mCustName, @mCustHistFlag, @mCustKey ) } )

   Heading( HDG_CASHSALES )
   Highlight( 01, 01, 'Last Tran #', Ns( Lvars( L_CUST_NO ), 4 ) )
   // DocketStatus()
   // Highlight( 01, 60, 'Docket is ' , if( Lvars( L_DOCKET ), 'On', 'Off' ) )

   @ 02,67 say if( price_conf,'','No Confirm' )
#ifdef MUST_USE_QTY   
   HighLight( 4, 6, "", LBL_CS_SCR_HEAD_Q  )
   nQuantity := 0
#else
   Highlight( 4, 6, '', LBL_CS_SCR_HEAD )

#endif
   // bKeyCtrlf2 := setkey( K_CTRL_F2, { || SetSalesTax( @tax_exempt ) } )
   msale_type := ''

  endif   //  FirstPass

  bKeyF10 := setkey( K_F12, { || EditCashSale() } )
  bKeyAltF1 := setkey( K_ALT_F1, { || Is_Special( @mspec_no, retflag, @specflag, nRowNum ) } )

  sID := space( ID_ENQ_LEN )
  sPrompt := LBL_PLU_LOOKUP
  @ 02, 10 say sPrompt get sID pict '@!'
//  @ 02, ( maxcol() / 2 ) - ( len( sPrompt ) + ID_CODE_LEN ) / 2 say sPrompt get sID pict '@!'
  Fkon( nRowNum )
  read
  Fkoff( nRowNum )

  setkey( K_ALT_F1, { || bKeyAltF1 } )
  setkey( K_F12, { || bKeyF12 } )
  
   if firstpass
    setkey( K_SH_F10, { || bKeyShiftF10 } )
    setkey( K_SH_F12, { || bKeyShiftF12 } )
    setkey( K_CTRL_F1, { || bKeyCtrlf1 } )
    setkey( K_F1, { || bKeyF1 } )
//  setkey( K_CTRL_F2, { || bKeyCtrlf2 } )
 
   endif

  if !updated()
   if lastkey() = K_ESC
    if firstpass
     lMainLoop := FALSE
     exit
    else
     if Salevoid()
      firstpass := TRUE
      exit
     endif
    endif
   else
    Line_clear( 2 )
	CalcTotalSale()
    lMain := FALSE
   endif
  else

   if sID = '-' .and. firstpass
    Heading( 'Cash Advance' )
    mtot := 0
    mtrantype := 'EPP'
    mCustName := space( 20 )
    cScreen := Box_Save( 01, 38, 04, 77 )
    @ 02,40 say 'Payout Amount' get mtot pict '9999.99' valid( if( mtot < 0, Secure( X_SALEVOID ), mtot < 9000 ) )
    @ 03,40 say 'Customer' get mCustName
    read
    Box_Restore( cScreen )
    if mtot != 0
     Dock_line( padr( if( mtot > 0, 'EFTPOS Payout', 'EFTPOS Decline' ), 31 ) + ' ' + str( mtot, 8, 2 ) )
     firstpass = FALSE
     lMain := FALSE
     nSubTotal := nFullPrice := -mtot
     loop

    endif

   endif

   if !Codefind( sID )
    Error( 'Item not found', 5, 1 )

   else
    Line_clear( nRowNum )
//    Line_clear( nRowNum+1 )
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
       nSpecialDeposit := special->deposit
       if nSpecialDeposit > 0
        cScreen := Box_Save( 04, 25, 06, 66 )
        @ 5,26 say 'Deposit Amt to Refund' get nSpecialDeposit pict '9999.99';
               valid nSpecialDeposit <= special->deposit
        read
        Box_Restore( cScreen )
       endif
      endif
     endif
     select master
    endif
    nSellPrice := master->sell_price
 
    if nSpecialDeposit > 0
     nSellPrice := nSellPrice-nSpecialDeposit
     Highlight( nRowNum, 55, "Less Deposit of", Ns( nSpecialDeposit, 6, 2 ) )

    endif
    PoleDisplay( trim( master->desc ) + "$" + Ns( nSellPrice ) )
    @ nRowNum,06 say substr( master->desc, 1, 40 )
    if !hdpos
     @ nRowNum,76 say master->onhand pict '9999'

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
    
    mMasterPrice := nSellPrice

    if price_conf
     cScreen := Box_Save( nRowNum+1, 3, nRowNum+10, 30, 5 )
     @ nRowNum+2,05 say '<F3> = Hold System'
     @ nRowNum+3,05 say '<F4> = '+str( Bvars( B_DISC1 ),5,2 )+'% Discount'
     @ nRowNum+4,05 say '<F5> = '+str( Bvars( B_DISC2 ),5,2 )+'% Discount'
     @ nRowNum+5,05 say '<F6> = '+str( Bvars( B_DISC3 ),5,2 )+'% Discount'
     @ nRowNum+6,05 say '<F7> = '+str( Bvars( B_DISC4 ),5,2 )+'% Discount'
     @ nRowNum+7,05 say '<F8> = Add your own Disc.'
#ifndef MUST_USE_QTY 
     @ nRowNum+8,05 say "<F9> =  Apply Qty's"
#endif	 
     @ nRowNum+9,05 say "<F10>=  Cust Returns"
     sFunKey3 := setkey( K_F3, { || Hold_em( FALSE ) } )
     sFunKey4 := setkey( K_F4, { || CashLineDisc( @nSellPrice, Bvars( B_DISC1 ), K_F4, @mMasterPrice, @discdone, nRowNum, nSpecialDeposit ) } )
     bKeyF5 := setkey( K_F5, { || CashLineDisc( @nSellPrice, Bvars( B_DISC2 ), K_F5, @mMasterPrice, @discdone, nRowNum, nSpecialDeposit ) } )
     bKeyF6 := setkey( K_F6, { || CashLineDisc( @nSellPrice, Bvars( B_DISC3 ), K_F6, @mMasterPrice, @discdone, nRowNum, nSpecialDeposit ) } )
     bKeyF7 := setkey( K_F7, { || CashLineDisc( @nSellPrice, Bvars( B_DISC4 ), K_F7, @mMasterPrice, @discdone, nRowNum, nSpecialDeposit ) } )
     bKeyF8 := setkey( K_F8, { || CashLineDisc( @nSellPrice, 0, K_F8, @mMasterPrice, @discdone, nRowNum ) } )
#ifndef MUST_USE_QTY 
     bKeyF9 := setkey( K_F9, { || F_qty( @qtyflag, specflag, @nQuantity, nRowNum ) } )
#else
     nQuantity := 1
#endif	 
     bKeyF10 := setkey( K_F10, { || F_ret( @retflag, nRowNum ) } )
     syscolor( C_NORMAL )
     @ nRowNum,46 get nSellPrice pict PRICE_PICT ;
       valid( nSellPrice < 9000 .and. if( nSellPrice=0, nSpecialDeposit > 0 .or. Secure( X_SALEVOID ),TRUE ) )
#ifdef MUST_USE_QTY
	 @ nRowNum,61 - len( QTY_PICT ) get nQuantity pict QTY_PICT valid( if( specflag, nQuantity <= special->received - special->delivered, TRUE ) )
     qtyFlag := TRUE
#endif
	 read

     setkey( K_F3, sFunKey3 )
     setkey( K_F4, sFunKey4 )
     setkey( K_F5, bKeyF5 )
     setkey( K_F6, bKeyF6 )
     setkey( K_F7, bKeyF7 )
     setkey( K_F8, bKeyF8 )
#ifndef MUST_USE_QTY 
     setkey( K_F9, bKeyF9 )
#endif
     setkey( K_F10, bKeyF10 )
     Box_Restore( cScreen )

    else
     @ nRowNum,46 say nSellPrice pict PRICE_PICT 

    endif

    if lastkey() = K_ESC
     SysAudit( 'LineVoid' + Ns( nSellPrice ) + substr( master->desc, 1, 10 ) )
     Line_clear( nRowNum )

    else
     if master->sell_price = 0 .and. mMasterPrice = 0
      mMasterPrice := nSellPrice

     endif
     nDiscountValue := mMasterPrice-nSellPrice
     nCostPrice := master->cost_price
     if master->cost_price = 0 .and. LastFkeyHit != 0
      nCostPrice := zero( nSellPrice,100 ) * ( 100 - ( Fkeys[ abs( LastFkeyHit -1 ), 2 ] ) )

     endif
     if qtyflag
      @ nRowNum,62 say nSellPrice * nQuantity pict '99999.99'

     endif
     if !hdpos .and. master->onhand - nQuantity <= MAXNEGSTOCK
      Error( "Lower Limit for Negative Stock exceeded", 12 )
      SysAudit( "LowLim" + master->id )

     endif
     if retflag
      nQuantity := -nQuantity

     endif

     if firstpass
      Lvars( L_CUST_NO, Custnum() )    // Increment the customer number
      Highlight( 01, 01, 'This Tran #', Ns( Lvars( L_CUST_NO ), 4 ) )
	//  cScreen = Box_save( 05, 02, 23, 77 )

	 endif

     firstpass := FALSE
     select cashtemp

     if nSpecialDeposit > 0   // Write a record for the Special deposit use to tender the sale.
      Add_rec( 'cashtemp' )
      cashtemp->tran_type := 'SDP'
      cashtemp->sale_date := Bvars( B_DATE )
      cashtemp->time := time()
      cashtemp->register := Lvars( L_REGISTER )
      cashtemp->unit_price := nSpecialDeposit
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
     cashtemp->qty := nQuantity
     cashtemp->cost_price := nCostPrice
     cashtemp->unit_price := mMasterPrice+nSpecialDeposit
     cashtemp->discount := nDiscountValue
     cashtemp->tran_type := mtrantype
     cashtemp->sales_tax := if( master->taxexempt, 0, GetGSTComponent((mMasterPrice + nSpecialDeposit)) )  // this fudges it for AU GST
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
      Dock_line( substr( master->desc, 1, 18 )+' '+str( nQuantity, 3 ) + ' @'+str( nSellPrice, 7, 2 )+' '+str( nSellPrice * nQuantity, 8, 2 ) )
#ifdef THE_LOOK
	  Dock_line(  master->id )
#endif	  
     else
      Dock_line(  substr( master->desc, 1, 30 -len(trim(master->id)) ) + ' ' + trim( master->id )+' '+str( nSellPrice * nQuantity, 8, 2 ) )

     endif

     if nSpecialDeposit != 0
      Dock_line(  space( 12 )+' After Deposit Paid '+str( nSpecialDeposit, 8, 2 ) )

     endif

	 if nDiscountValue > 0
      Dock_line(  space( 7 ) +'Inc Discount of '+str( nDiscountValue / ( mMasterPrice / 100 ), 4, 1 );
       + '%  $-' + str( nDiscountValue*nQuantity, 8, 2 ) )

     endif

     mNoDiscTot += if( master->NoDisc, nSellPrice * nQuantity, 0 )
     nFullPrice += mMasterPrice * nQuantity
     // nTotalCost += nCostPrice * nQuantity
     // nSubTotal += nSellPrice * nQuantity
     // nTaxValue += nItemTax * nQuantity

  	 DisplaySales()
	 CalcTotalSale()

	 // Highlight( 2, 60, 'Sub Total',  str( CalcTotalSale(), 7, 2 ) )

	
//     if nRowNum > 14
//	  nRowNum := 5
	
//     else
//	  nRowNum++ 
	 
//     endif	 
//	 @ nRowNum,0 clear
//	 @ nRowNum+1,37 say 'Sub Total        ' + str( nSubTotal, 7, 2 )
//	 PoleDisplay( 'Sub Total$' + Ns( nSubTotal, 8, 2 ) )
 
    endif
   endif
  endif  // Updated()
 enddo
 if !firstpass
  hasdisc := NO
  nSubTotal := Nocents( nTotalSale )
  nFinalTot := nSubTotal
  msave := Box_Save( nRowNum+1,3,nRowNum+7,70,4 )
  @ nRowNum+2,05 say '<F4> = '+str( Bvars( B_DISC1 ), 5, 2 ) + '% Discount'
  @ nRowNum+3,05 say '<F5> = '+str( Bvars( B_DISC2 ), 5, 2 ) + '% Discount'
  @ nRowNum+4,05 say '<F6> = '+str( Bvars( B_DISC3 ), 5, 2 ) + '% Discount'
  @ nRowNum+5,05 say '<F7> = '+str( Bvars( B_DISC4 ), 5, 2 ) + '% Discount'
  @ nRowNum+6,05 say '<F8> = Add Your Own Disc'
//  syscolor( C_NORMAL )
  sFunKey4 := setkey( K_F4, { || CashTotDisc( nRowNum, Bvars( B_DISC1 ), K_F4, @hasdisc, @nFinalTot ) } )
  bKeyF5 := setkey( K_F5, { || CashTotDisc( nRowNum, Bvars( B_DISC2 ), K_F5, @hasdisc, @nFinalTot ) } )
  bKeyF6 := setkey( K_F6, { || CashTotDisc( nRowNum, Bvars( B_DISC3 ), K_F6, @hasdisc, @nFinalTot ) } )
  bKeyF7 := setkey( K_F7, { || CashTotDisc( nRowNum, Bvars( B_DISC4 ), K_F7, @hasdisc, @nFinalTot ) } )
  bKeyF8 := setkey( K_F8, { || CashTotDisc( nRowNum, 0 , K_F8, @hasdisc, @nFinalTot ) } )
  @ nRowNum+2, 46 say 'Total Sale' 
  @ nRowNum+2, 57 get nFinalTot pict '9999.99' valid( if( hasdisc, YES, nFinalTot = nSubTotal ) )
  read
  Box_Restore( msave )
  setkey( K_F4, sFunKey4 )
  setkey( K_F5, bKeyF5 )
  setkey( K_F6, bKeyF6 )
  setkey( K_F7, bKeyF7 )
  setkey( K_F8, bKeyF8 )
  syscolor( C_NORMAL )

  if lastkey() = K_ESC
   if Salevoid()
    loop

   endif

  endif

  PoleDisplay('Total Sale$' + Ns( nFinalTot, 8, 2 ) )

  select cashtemp
  if nSubTotal != nFinalTot  // Approportion Final Discounts to each item 
   disc_val := 100 - Zero( nFinalTot, zero( nSubTotal, 100 ) )
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

  mtran_qty := if( nFinalTot >= 0, 1, -1 )

  Dock_line(  space( 16 ) + 'Total sale    ' + str( nSubTotal, 10, 2 ) )

  if nFinalTot != nSubTotal
   nDiscountValue := nSubTotal - nFinalTot
   if nDiscountValue > 0
    Dock_line(  space( 5 ) + 'Total Discount of ' +Ns( ( nDiscountValue / ( nSubTotal / 100 ) ), 4, 1 ) + ;
       '%  $-' + str( nDiscountValue, 8, 2 ) )

   endif
  endif

  lPrintDocket := FALSE
  Tender( nFinalTot, nFullPrice, nTotalSalesTax, nTotalCost, mtran_qty, "cashtemp", mtrantype, nRowNum, mCustName, mNoDiscTot, mSType, @lPrintDocket )

  if cashtemp->( reccount() ) > 15
   Box_Save( 10, 10, 12, 70 )
   Center( 11, 'Processing Sale - Please wait' )

  endif


  if CashTemp->( reccount() ) > 0

   // if lPrintDocket
    Dock_foot( )
    Dock_print( )
   
   // endif
   
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
  PoleDisplay()

 endif
enddo

setkey( K_SH_F10, { || bKeyShiftF10 } )
setkey( K_SH_F12, { || bKeyShiftF12 } )
dbcloseall()

return nil

*

proc tender ( nFinalTot, nSubTotal, nTaxValue, nCostPrice, mtran_qty, mfile, mtran, nRowNum, mname, mStype, mcustkey, aPreLines, lPrintDocket )
local mbnkbranch, mbank, mdrawer, mremain:=abs(nFinalTot), mamt_ten, mchange, mcdflag
local mtran_amt, tscr, cScreen, mvoucher
local mopscr
local mtend := 'CAS'
local x, getlist:={}
local firstpass := TRUE
local mDiscTotal := 0


local mDiscTemp := 0

default aPreLines to {}
default lPrintDocket to FALSE

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
 cScreen:=Box_Save( nRowNum+3, 35, nRowNum+8, 70 )
 set confirm off
 mtend := 'CAS'
 @ nRowNum+4, 42 say 'Tender Type' get mtend pict '!!!' valid( ascan( tt_types, mtend ) != 0 )
 @ nRowNum+5, 37 say 'Amount Remaining ' + str( mremain * mtran_qty, 7, 2 )
 read
 Syscolor( 3 )
 mcdflag := !tt_cdflag[ ascan( tt_types, mtend ) ]
 @ nRowNum+4, 37 say space(30)
 @ nRowNum+4, 37 say tend_desc( mtend ) + " "
 syscolor( C_NORMAL )
 set confirm on
 Box_Restore( mopscr )

 @ nRowNum+5, 37 say if( mamt_ten > 0, 'Amount Tendered ', 'Amount Refunded ' ) get mamt_ten pict '9999.99'
 // @ nRowNum+6, 37 say "Print Docket" get lPrintDocket pict 'Y'
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
  tscr := Box_Save( nRowNum+5, 37, nRowNum+9, 70 )
  @ nRowNum+6, 38 say '   Bank' get mbank pict '@!'
  @ nRowNum+7, 38 say ' Branch' get mbnkbranch pict '@!'
  @ nRowNum+8, 38 say ' Drawer' get mdrawer
  read
  Box_Restore( tscr )

 endif

 if '/' $ mtend 
  tscr := Box_Save( nRowNum+5, 37, nRowNum+7, 70 )
  @ nRowNum+6, 38 say 'Surname' get mdrawer
  read
  Box_Restore( tscr )

 endif

 Dock_line( left( tend_desc( mtend ), 15 ) + ;
      if( mamt_ten * mtran_qty > 0, ' Amount Tendered ', ' Amount Refunded ' ) ;
      + str( mamt_ten * mtran_qty, 8, 2 ) )

//  mPoleDisplayDisc += mDisctemp

 if mamt_ten >= mremain
  if mcdflag
   Dock_line( chr( K_ESC ) + 'p' + chr( 0 ) + chr( 25 ) + chr( 250 ) )
   Open_de_draw()

  endif
  mchange := ( mamt_ten - mremain ) * mtran_qty
  @ nRowNum + 6, 37 say 'Change           ' + str( mchange, 7, 2 )
  Dock_line( padr( 'Change', 32 ) + str( mchange, 8, 2 ) )
  PoleDisplay( 'Change$' + Ns( mchange, 8, 2 ) )
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
 ( mfile )->cost_price := if( firstpass, nCostPrice, 0 ) 
 ( mfile )->sales_tax := if( firstpass, nTaxValue, 0 )
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
  ( mfile )->discount := nSubTotal-nFinalTot
  ( mfile )->unit_price := mtran_amt
    
 endif
 ( mfile )->( dbrunlock() )

 mDiscTotal := 0
 mamt_ten := mremain
 @ nRowNum+5, 37 say 'Amount Remaining ' + str( mremain * mtran_qty, 7, 2 )

enddo
return

*

procedure f_qty ( qtyflag, specflag, nQuantity, nRowNum )
local getlist := {}
@ 4,6 say 'Desc                                     Price     Qty   Extend'
nQuantity := 0
@ nRowNum,54 say space( 23 )
@ nRowNum,60 - len( QTY_PICT ) get nQuantity pict QTY_PICT valid( if( specflag, nQuantity <= special->received - special->delivered, TRUE ) )
if specflag
 @ nRowNum,63 say 'Avail=' + Ns( special->received - special->delivered )

endif
read
keyboard chr( K_ENTER )
qtyflag := TRUE
return

*

procedure f_ret ( retflag, nRowNum )
if Secure( X_SALEVOID )
 @ nRowNum,1 say '<Ret>'
 retflag := TRUE

endif
return

*

procedure custhist ( mCustName, mCustHistFlag, mCustKey )
local cScreen := Box_Save()
if CustFind( FALSE )
 Highlight( 1, 1, 'Customer ', trim( customer->name ) )
 mCustHistFlag := TRUE
 Rec_lock( 'customer' )
 customer->date_lp := Bvars( B_DATE )
 customer->( dbrunlock() )
 mCustName := customer->name
 mCustKey := customer->key
endif
Box_Restore( cScreen )
return

*

Function Is_special ( temp_spec, retflag, specflag, nRowNum )
local cScreen,dbsel:=select(),getlist:={}
if select( "special" ) = 0
 if !Netuse( "special" )
  return FALSE

 endif

endif
special->( ordsetfocus( 'number' ) )
if !retflag
 cScreen := Box_Save( 3, 25, 6, 55 )
 temp_spec := 0
 @ 4,26 say 'Special Order No.' get temp_spec pict '999999'
 read
 if !special->( dbseek( temp_spec ) )
  Error( "Special order Number not Found", 12 )

 else
  specflag := TRUE
  Highlight( nRowNum, 75, '', 'S' )

 endif
 Box_Restore( cScreen )

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
//  if !Lvars( L_DOCKET )
//   DocketStatus()

//  endif
  while !sales->( eof() ) .and. tcount < 40
   master->( dbseek( sales->id ) )
   select sales
   Dock_head()   // This also clears the aDocket array
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
local voi_tot := 0, voidret := FALSE, cScreen
#ifdef LYTTLETON
if isReady( 19, ,"Are you sure you want to void this sale?" )
#endif
if Secure( X_SALEVOID )
  select cashtemp
  sum cashtemp->unit_price * cashtemp->qty to voi_tot
  SysAudit( "SalVoi" + Ns( voi_tot, 7, 2 ) )
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

endif
#ifdef LYTTLETON
endif
#endif
return voidret

*

procedure CashTotDisc ( nRowNum, mdisc, mkey, hasdisc, nFinalTot )
local getlist := {}, mdisctot:=0
if mkey == K_F8
 @ nRowNum+3,37 say '  Enter Discount %' get mdisc pict '99.9'
 read
 line_clear( nRowNum + 3 )
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
nFinalTot := Nocents( nFinalTot - round( mdisctot,2 ) )
#else
nFinalTot := Nocents( nFinalTot - round( ( nFinalTot / 100 * mdisc ), 2 ) )
#endif
@ nRowNum+2,37 say 'Total Sale       ' + str( nFinalTot, 7, 2 )
@ nRowNum+2,62 say '(Less '+str( mdisc, 4, 1 ) + '% Disc)'
mdisctot := mdisc   
hasdisc := TRUE
return

*

Func CashLineDisc ( nSellPrice, mdisc, mkey, mMasterPrice, discdone, nRowNum, spec_dep )
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
  mMasterPrice := nSellPrice
 endif
 if mkey == K_F8
  @ nRowNum+1,35 say 'Enter Discount %' get mdisc pict '99.9'
  read
 endif
 discdone := TRUE
 nSellPrice -= round( ( ( nSellPrice+spec_dep )/ 100 * mdisc ), 2 ) 
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
Dock_line( "" )
// Dock_line(  PITCH_17 + Bvars( B_DOCKLN1 ) + PITCH_10 )

Dock_line( BIGCHARS + Bvars( B_DOCKLN1 ) + NOBIGCHARS )
if !empty( Bvars( B_DOCKLN2 ) )
 if len( trim( Bvars( B_DOCKLN2 ) ) ) < 21
   Dock_line(  BIGCHARS + trim( Bvars( B_DOCKLN2 ) ) + NOBIGCHARS )
//    Dock_line(  trim( Bvars( B_DOCKLN2 ) ) )

 else
  Dock_line(  Bvars( B_DOCKLN2 ) )

 endif

endif
Dock_line( "  Tax Invoice - ABN " + Bvars( B_ACN ) )
return

*

Procedure Dock_line ( p_line, lSuppSpace )

Default lSuppSpace to TRUE
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
local x, oPrinter

Print_find( "docket" )

set console off
set print on

for x := 1 to len( aDocket )
 ? aDocket[x]

next
set print off
set console on

set printer to  // Should Flush the printer

/*
Printcheck ('Docket', 'docket' )

oPrinter := Win32Prn():New(Lvars( L_PRINTER ) )
oPrinter:Landscape:= .F.
oPrinter:FormType := FORM_A4
oPrinter:Copies   := 1
if !oPrinter:Create()
 Alert( "Cannot create Printer " + LVars( L_PRINTER ) )
 return

endif
oPrinter:StartDoc( "docket" )
// oPrinter:SetPen( PS_SOLID, 1, RGB_RED )
oPrinter:SetFont( 'Lucida Console', 8, {3,-50} )


for x := 1 to len( aDocket )
 LP( oPrinter, aDocket[x], ,TRUE )

next
oPrinter:endDoc()
oPrinter:Destroy()
*/

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
local mstype, cScreen,x // := Box_Save( 2, 10, 10, 40 ), x
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
cScreen := Box_Save( 2, 10, 2+len(mktg_names)+1, 40 )
Heading( 'Select Sales Type' )
for x := 1 to len( mktg_names )
 @ x+2,12 prompt mktg_names[ x ]
next
menu to mstype
Box_Restore( cScreen )
return if( mstype != 0, mktg_types[ mstype ], '' )

*/

function contoggle
price_conf := !price_conf
@ 02,67 say if( price_conf, space(10), 'No Confirm' )
return nil

*

function PoleDisplay ( disp_text )
static portopen:=FALSE
#define PoleDisplayPort 2   // Only temporary
/*
   Epson DM-D202 Customer displays are two lines. This function looks for the
   $ sign and attempt to place it ( and following data ) on the second line 
*/   
if Lvars( L_POSDISPLAY )
// #ifndef __HARBOUR__
 if !portopen
  tp_open( PoleDisplayPort, 32, 128, 9600, 8, 'N', 1 )
  portopen := TRUE
 endif
 if disp_text = nil
  if !empty( Bvars( B_GREET ) )
 #ifdef EPSON_POLEDISPLAY
   tp_send( PoleDisplayPort, FF + trim( BVars( B_NAME ) ) )
 #else
   tp_send( PoleDisplayPort, chr( 22 ) + chr( 17 ) + trim( Bvars( B_GREET ) ) + chr( 16 ) )
 #endif
  endif

  else

 #ifdef EPSON_POLEDISPLAY
  if '$' $ disp_text
   tp_send( PoleDisplayPort, FF + left( disp_text, min( at( '$', disp_text ) - 1, 19 ) ) + ;
            CRLF + padl( trim( substr( disp_text, at( '$', disp_text ), 20 ) ), 20 ) )
  else
   tp_send( PoleDisplayPort, FF + disp_text )

  endif          
 
 #else  
  if '$' $ disp_text
   tp_send( PoleDisplayPort, chr( 3 ) + padr( left( disp_text, at( '$', disp_text ) - 1 ), 10 ) + ;
            padl( trim( substr( disp_text, at( '$', disp_text ), 10 ) ), 10 ) )
  else
   tp_send( PoleDisplayPort, chr( 3 ) + substr( disp_text, 1, 22 ) )
  endif
 
 #endif
 endif
// #endif
disp_text := nil
endif
return nil

*

function CSalesHelp( nWhich )
local aArray := {}

do case
Case nWhich = 1
	aadd( aArray, { '<Shift-F10>', 'Reprint Docket' } )
	aadd( aArray, { '<Ctrl-F1>', 'Add Customer to sale' } )
EndCase
Build_help( aArray ) 

return nil

*

Function EditCashSale
/* Allows an inline update of a sale - basically edits the saletemp file */
local oSaleTemp, nKeyPressed, cScreen, cScreen1, aHelpLines
local getlist:={}

if cashtemp->( reccount() ) > 0
 cScreen = Box_save( 03, 02, 23, 77 )
 oSaleTemp:= TBrowseDB( 04, 3, 22, 76 )
 oSaleTemp:colorspec := TB_COLOR
 oSaleTemp:HeadSep := HEADSEP
 oSaleTemp:ColSep := COLSEP
 oSaleTemp:goTopBlock := { || cashtemp->( dbgotop() ) }
 oSaleTemp:goBottomBlock := { || cashtemp->( dbgobottom() ) }
 // oSaleTemp:addcolumn( TBColumnNew( PLU_DESC, { || cashtemp->id } ) )
 oSaleTemp:addcolumn( TBColumnNew( DESC_DESC ,{ || left( master->desc, 20) } ) )
 oSaleTemp:addcolumn( TBColumnNew( 'Sale Price', { || ns( cashtemp->unit_price - cashtemp->discount, 7, 2 ) } ) )
 oSaleTemp:addcolumn( TBColumnNew( 'Qty',  { || cashtemp->qty } ) )
 oSaleTemp:addcolumn( TBColumnNew( 'Extend',  { || ns( ( cashTemp->unit_price - cashtemp->discount ) * cashtemp->qty, 7, 2) } ) )
 oSaleTemp:addcolumn( TBColumnNew( 'Onhand',  { || master->onhand } ) )
 oSaleTemp:goTop()
 nKeyPressed := 0
 while nKeyPressed != K_ESC .and. nKeyPressed != K_END
  oSaleTemp:forcestable()
  nKeyPressed := inkey(0)
  if !navigate( oSaleTemp, nKeyPressed )
   do case
   case nKeyPressed == K_F1
    aHelpLines := { ;
                  { 'Esc', 'Escape from function' }, ;
                  { 'Del', 'Delete Item' }, ;
                  }
    Build_help( aHelpLines )
/*
   case nKeyPressed == K_ENTER
    select cashtemp
	Rec_lock()
    cScreen1 := Box_Save( 10, 2, 13, 77 )
    @ 11,05 say 'Price' get cashtemp->unit_price pict PRICE_PICT
	@ 12,05 say 'Qty' get cashtemp->qty pict QTY_PICT
	read
    cashtemp->( dbrunlock() )
    CalcTotalSale()
	Box_Restore( cScreen1 )
    oSaleTemp:refreshcurrent()
 */ 
   case nKeyPressed == K_DEL
 //   cScreen1 := Box_Save( 15, 2, 17, 77 )
 //   @ 16,05 say 'OK to delete ==> ' + left( master->desc, 45 )
    if Isready( 18, nil, 'OK to delete ==> ' + left( master->desc, 45 ) )
     del_rec( 'cashtemp' )
     CalcTotalSale()
    
	endif
    // Box_Restore( cScreen1 )
	cashtemp->( dbgotop() )
    oSaleTemp:refreshAll()

   endcase

  endif
 enddo
 Box_Restore( cScreen )
 DisplaySales()
endif 
return nil

*

Function CalcTotalSale
local nCurrentRec:=cashtemp->( recno() )

nTotalSale:=0
nTotalCost:=0
nTotalSalesTax:=0
nTotalFullPrice:=0

cashtemp->(dbgotop())
while !cashtemp->(eof())
 if !cashtemp->( deleted() )
  nTotalSale += ( cashtemp->unit_price - cashtemp->discount ) * cashtemp->qty
  nTotalCost += cashtemp->cost_price * cashtemp->qty 
  nTotalSalesTax += cashtemp->sales_tax * cashtemp->qty
  nTotalFullPrice += master->sell_price * cashtemp->qty
  
 endif
 cashtemp->( dbskip() )
enddo

Highlight( 2, 60, 'Sub Total',  str( nTotalSale, 7, 2 ) )
cashtemp->( dbgoto( nCurrentRec ) )
// Displaysales()
return nTotalSale

*

Procedure DisplaySales()
local nRow := 6
@ 5,0 clear to 22,79
@ nRow, 0 say "<F12>"
cashtemp->( dbgobottom() )
while !cashtemp->( bof() ) .and. nRow < 22
  if !cashtemp->( deleted() )
   @ nRow, 06 say substr( master->desc, 1, 40 )
   @ nRow, 46 say cashtemp->unit_price - cashtemp->discount pict PRICE_PICT
   @ nRow, 54 say cashtemp->qty pict QTY_PICT
   @ nRow, 63 say ( cashtemp->unit_price - cashtemp->discount ) * cashtemp->qty pict PRICE_PICT
   @ nRow, 73 say master->onhand pict QTY_PICT
   nRow++
  endif
  cashtemp->( dbskip(-1) )

enddo
return
