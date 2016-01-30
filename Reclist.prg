/*
 
          Last change: APG 11/08/2008 9:10:32 PM

      Last change:  TG   27 Mar 2011   12:41 pm
*/

Procedure Reclist

#include "bpos.ch"

local mgo:=FALSE,mscr,recbrow,okafs,mkey,x,mpo,mcolumn

local oldscr:=Box_Save( 0, 0, 24, 79 ),tfile:=Oddvars( TEMPFILE )+'.dbf'
local getlist:={},sdbf,msupp:=Oddvars( MSUPP )

local mreq, specEject:=FALSE,report_name,mseq

local inv_tot, item_tot, aHelpLines, aPo


local oldinvno

#ifndef THELOOK
local ntemp, qtyavail, sid, qty_reqd, mComments
local mNum, spec_dep, Spec_Date, page_number, page_width, page_len
local top_mar, bot_mar, arr_ptr, mCustOrdNo, col_head1, col_head2
local mseek, mSpecs, gt_inv, gt_qty
local oPrinter, nColFixed
local gt_cost, gt_sell, gt_retail, gt_tax
local lt_inv, lt_qty, lt_cost, lt_sell, lt_retail, lt_tax
local qty_issued

#endif

memvar msupptmp   // for the reporter

Center( 24,'Opening files for Edit Incoming')
if Netuse( "pohead" )
 if Netuse( "poline" )
  dbsetrelation( "pohead", { || poline->number } )
  if Master_use()
   if Netuse( "customer" )
    if Netuse( "supplier" )
     if Netuse( "special" )
      ordsetfocus( 'id' )
      set relation to special->key into customer
      if Netuse( "recvline" )
       set relation to recvline->id into special,;
                    to recvline->id into master
       if Netuse( "recvhead" )
        set relation to recvhead->supp_code into supplier   
 
        mgo := TRUE
       endif
      endif
     endif
    endif
   endif
  endif
 endif
endif
line_clear( 24 )
while mgo

 Box_Restore( oldscr )

 // okf10 := setkey( K_F10, { || AppendRecv() } )

 msupp := GetSuppCode( 8, 32, ALLOW_WILD )   // this is in proclib ( where else )

 // setkey( K_F10, okf10 )
 
 if lastkey() = K_ESC
  exit

 else
  okafs := setkey( K_ALT_S, { || StockDisp() } )
  if msupp != '*'
   if !recvhead->( dbseek( trim( msupp ) ) )
    Error( 'No Items received for ' + trim( LookItUp( "supplier", msupp ) ), 12 )
    loop

   endif

  else
   recvhead->( dbgotop() )

  endif

  cls
  Heading( 'Edit Items Received' + if( msupp = '!', '', ' from ' + trim( LookItUp( "supplier", msupp ) ) ) )

  select recvhead
  recbrow := tbrowsedb( 01, 03, 24, 79 )
  for x = 1 to 24-2
   @ x+2, 00 say row()-2 pict '99'

  next
  recbrow:headsep := HEADSEP
  recbrow:colsep := COLSEP
  if msupp != '*'
   recbrow:gotopblock := { || dbseek( msupp ) }
   recbrow:gobottomblock := { || jumptobott( msupp ) }
   recbrow:skipblock := KeySkipBlock( { || recvhead->supp_code }, msupp )

  else
   recbrow:addcolumn( tbcolumnnew( 'Supp', { || recvhead->supp_code } ) )

  endif
  recbrow:addcolumn( tbcolumnnew( 'Invoice #', { || recvhead->invoice } ) )
  recbrow:addcolumn( tbcolumnnew( 'Inv Date', { || recvhead->dreceived } ) )
  recbrow:addcolumn( tbcolumnnew( 'Inv Value', { || transform( recvhead->inv_total, '99999.99' ) } ) )
  mcolumn:=tbcolumnnew( 'Inv Calc ', { || transform( recvhead->inv_calc, '99999.99' ) } )   
  mcolumn:colorblock := { || if( recvhead->inv_calc != recvhead->inv_total, {5, 6}, {1, 2} ) }
  recbrow:addcolumn( mcolumn )
  recbrow:addcolumn( tbcolumnnew( 'Item Tot ', { || transform( recvhead->tot_items, '99999' ) } ) )
  mcolumn := tbcolumnnew( 'Item Calc ', { || transform( recvhead->items_calc, '99999' ) } ) 
  mcolumn:colorblock := { || if( recvhead->tot_items != recvhead->items_calc, {5, 6}, {1, 2} ) }
  recbrow:addcolumn( mcolumn )
  recbrow:addcolumn( tbcolumnnew( 'Res', { || if( recvhead->reserved, 'Y', 'N' ) } ) )
  recbrow:freeze := if( msupp="*", 2, 1 )
  recbrow:goTop()
  mkey := 0
  while mkey != K_ESC .and. mkey != K_END
   recbrow:forcestable()
   mkey := inkey(0)

   if !Navigate(recbrow,mkey)
    do case
    case mkey >= 48 .and. mkey <= 57
     keyboard chr( mkey )
     mseq := 0
     mscr := Box_Save( 2,08,4,40 )
     @ 3,10 say 'Selecting No' get mseq pict '999' range 1,24-2
     read
     Box_Restore( mscr )
     if !updated()
      loop

     else
      mreq := recno()
      skip mseq - recbrow:rowpos
      GrnLnDisp( msupp )
      RecBrow:refreshcurrent()
      goto mreq

     endif

    case mkey == K_F1
     aHelpLines := { ;
      { 'Enter', 'Display Invoice lines' },;
      { 'Del', 'Delete Entire Invoice' },;
      { 'F8', 'Recalc Invoice Values' },;
      { 'F10', 'Edit Header Details' } }
      Build_help( aHelpLines )

    case mkey == K_F10   // Edit the Header Details Here
     mscr :=Box_Save( 05, 05, 11, 75, C_MAUVE )
     oldinvno := recvhead->invoice   // This is a key value in recvline
     @ 06, 07 say '        Invoice No' get recvhead->invoice pict '@!' valid( !empty( recvhead->invoice ) )
     @ 06, 40 say ' Invoice Date' get recvhead->dreceived
     @ 07, 07 say 'Inv Value(Inc GST)' get recvhead->inv_total pict '99999.99'
     @ 07, 40 say '  Invoice Qty' get recvhead->tot_items pict '99999'
     @ 08, 07 say '      Misc Charges' get recvhead->x_charges pict '99999.99'
     @ 08, 40 say '      Freight' get recvhead->freight pict '99999.99'
     @ 09, 07 say '         Gst Total' get recvhead->GST pict '99999.99'
     Rec_lock( 'recvhead' )
     read
     recvhead->( dbrunlock() )
     recbrow:refreshcurrent()
     if recvhead->invoice != oldinvno
      while recvline->( dbseek( recvhead->supp_code + oldinvno ) ) .and. Pinwheel( NOINTERUPT )
       Rec_lock( 'recvline' )
       recvline->IndxKey := recvhead->supp_code + recvhead->invoice 
       recvline->( dbrunlock() )

      enddo 

     endif
     Box_Restore( mscr )

    case mkey == K_ENTER
     GrnLnDisp()
     recbrow:refreshcurrent()
     
    case mkey == K_F8
     if( msupp = '*', recvhead->( dbgotop() ), recvhead->( dbseek( msupp ) ) )
     while ( recvhead->supp_code = msupp .or. msupp = '*' ) .and. !recvhead->( eof() ) .and. Pinwheel( NOINTERUPT )
      recvline->( dbseek( recvhead->supp_code + recvhead->invoice ) )
      inv_tot := 0
      item_tot := 0

      while recvline->IndxKey = ( recvhead->supp_code + recvhead->invoice ) .and. !recvline->( eof() ) .and. Pinwheel( NOINTERUPT )
       inv_tot += ( recvline->cost_price * recvline->qty_inv )
       item_tot += recvline->qty_inv
       recvline->( dbskip() )

      enddo

      Rec_lock( 'recvhead' )
      recvhead->inv_calc := inv_tot + recvhead->freight + recvhead->x_charges + recvhead->GST
      recvhead->items_calc := item_tot

      recvhead->( dbrunlock() )
      recvhead->( dbskip() )

     enddo
     recbrow:gotop()
     recbrow:refreshall()

    case mkey == K_DEL
     if Isready( 12, 12, 'Ok to delete Invoice ' + trim( recvhead->invoice ) + ' from supplier ' + Lookitup( 'supplier', recvhead->supp_code ) )
      if Isready( 14, 14, 'Again are you sure' )
       recvhead->( dbseek( recvhead->supp_code + recvhead->invoice ) )
       while recvline->IndxKey = ( recvhead->supp_code + recvhead->invoice ) .and. !recvline->( eof() )
        Del_rec( 'recvline', UNLOCK )
        recvline->( dbskip() )

       enddo 
       Del_rec( 'recvhead', UNLOCK )
       recbrow:gotop()
       recbrow:refreshall()

      endif 

     endif

    endcase

   endif

  enddo
#ifdef THELOOK
  Heading( 'Finish review' )
  if isReady(12, , "Finish Reviewing?")

#else
  Heading( 'Print Goods Received Note' )
  Print_Find( "report" )
  if Isready( 12, , "OK to print the GRN?" )
   Box_Save( 2, 08, 6, 72 )
   Center( 3, 'Printing Goods Received Note' )

   oPrinter:= Win32Prn():New(Lvars( L_PRINTER) )
   oPrinter:Landscape:= .F.
   oPrinter:FormType := FORM_A4
   oPrinter:Copies   := 1
   if !oPrinter:Create()
       Alert( "Cannot create Printer " + LVars( L_PRINTER ) )

   endif
   oPrinter:StartDoc( 'Goods Received Note' )
   oPrinter:SetPen(PS_SOLID, 1, RGB_RED)
   oPrinter:SetFont('Lucida Console',8,{3,-50})
   nColFixed:= 40 * oPrinter:CharWidth
   page_number:=1
   page_width:=132
   page_len:=66
   top_mar:=0
   bot_mar:=10
   gt_qty := gt_inv := gt_cost := gt_sell := gt_retail := gt_tax := 0
   col_head1 := '  ID             Desc             Qty  Qty  Po#    Inv Cost   Inv Cost   Sell Sell Price  Disc   Retail    Retail'
   col_head2 := '                                 Recv  Inv                    Extended  Price   Extended                 Extended'
   col_head1 += '              GST'
   col_head2 += '            Total'
   report_name := 'Goods Received Note'
   PageHead( oPrinter, report_name, page_width, page_number, Col_head1, Col_head2 )

   if msupp = '*'
    recvhead->( dbgotop() )

   else
    recvhead->( dbseek( msupp ) )

   endif 

   while ( recvhead->supp_code = msupp .or. msupp = '*' ) .and. !recvhead->( eof() ) .and. Pinwheel()          // Start print Routine
    if PageEject2( oPrinter )
     page_number++
     PageHead( oPrinter, report_name, page_width, page_number, Col_head1, Col_head2 )

    endif
    oPrinter:SetColor( RGB_GREEN )
    oPrinter:NewLine()
    oPrinter:TextOut(  'Supplier: ' + substr( LookItUp( "supplier", recvhead->supp_code ), 1, 14 );
       + ' Code: ' + recvhead->supp_code + ' Invoice #' + recvhead->invoice )
    oPrinter:SetColor( RGB_BLACK )

    lt_qty := lt_inv := lt_cost := lt_sell := lt_retail := lt_tax := 0

    recvline->( dbseek( recvhead->supp_code + recvhead->invoice ) )
    while recvline->IndxKey = ( recvhead->supp_code + recvhead->invoice ) .and. !recvline->( eof() ) .and. Pinwheel()
     if recvline->qty > 0
      if PageEject2( oPrinter )       // Check for eject required
       page_number++
       PageHead( oPrinter, report_name, page_width, page_number, Col_head1, Col_head2 )

      endif
      oPrinter:NewLine()
      oPrinter:textout( idcheck( recvline->id ) )
      oprinter:setpos( 16 * oPrinter:CharWidth )
      oPrinter:textout( left( master->desc, 18 ) )
      oprinter:setpos( 35 * oPrinter:CharWidth )
      oPrinter:textout( transform( recvline->qty, QTY_PICT ) )
      oPrinter:setpos( 40 * oPrinter:CharWidth )
      oPrinter:textout( transform( recvline->qty_inv, QTY_PICT ) )
      oPrinter:setpos( 41 * oPrinter:CharWidth )
      oPrinter:textout( transform( recvline->ponum, PO_NUM_PICT ) )
      oPrinter:setpos( 54 * oPrinter:CharWidth )
      oPrinter:textout( transform( recvline->cost_price, PRICE_PICT ) )
      oPrinter:setpos( 64 * oPrinter:CharWidth )
      oPrinter:textout( transform( recvline->cost_price * recvline->qty, TOTAL_PICT ) )
      oPrinter:setpos( 72 * oPrinter:CharWidth )
      oPrinter:textout( transform( recvline->sell_price , PRICE_PICT ) )
      oPrinter:setpos( 82 * oPrinter:CharWidth )
      oPrinter:textout( transform( recvline->sell_price* recvline->qty, TOTAL_PICT ) )
      oPrinter:setpos( 90 * oPrinter:CharWidth )
      oPrinter:textout( transform( 100-( recvline->cost_price/(recvline->cost_price/100 * Bvars( B_GSTRATE ) ) ) * recvline->qty, PRICE_PICT  ) )
      oPrinter:setpos( 98 * oPrinter:CharWidth )
      oPrinter:textout( transform( recvline->retail , PRICE_PICT ) )
      oPrinter:setpos( 109 * oPrinter:CharWidth )
      oPrinter:textout( transform( recvline->retail * recvline->qty, PRICE_PICT ) )
      oPrinter:setpos( 114 * oPrinter:CharWidth )
      oPrinter:textout( transform( (recvline->cost_price/100 * BVARS( B_GSTRATE )) * recvline->qty, TOTAL_PICT ) )
      oPrinter:setpos( 124 * oPrinter:CharWidth )
      oPrinter:textout( transform( recvline->cost_price + ( recvline->cost_price/100 * Bvars( B_GSTRATE ) ) * recvline->qty , TOTAL_PICT ) )

//      lt_tax += ( recvline->cost_price + ( recvline->cost_price/100 * Bvars( B_GSTRATE ) ) ) * recvline->qty
      lt_qty += recvline->qty
      lt_inv += recvline->qty_inv
      lt_cost += recvline->cost_price * recvline->qty_inv
      lt_sell += recvline->sell_price * recvline->qty_inv
      lt_retail += recvline->retail * recvline->qty_inv

     endif
     recvline->( dbskip() )

    enddo
    if PageEject2( oPrinter )
     page_number++
     PageHead( oPrinter, report_name, page_width, page_number, Col_head1, Col_head2 )

    endif
    oPrinter:NewLine()
    oPrinter:textout( replicate( "=", oPrinter:maxcol() ) )
    oPrinter:NewLine()
    oPrinter:SetColor( RGB_GREEN )
    oPrinter:TextOut( 'Invoice totals' )
    oPrinter:SetPos( 35 * oPrinter:CharWidth )
    oPrinter:TextOut( transform( lt_qty, QTY_PICT ) )
    oPrinter:SetPos( 64 * oPrinter:CharWidth )
    oPrinter:TextOut( transform( lt_cost, TOTAL_PICT ) )
    oPrinter:SetPos( 82 * oPrinter:CharWidth )
    oPrinter:TextOut( transform( lt_sell, TOTAL_PICT ) )
    oPrinter:SetPos( 109 * oPrinter:CharWidth )
    oPrinter:TextOut( transform( lt_retail, TOTAL_PICT ) )
    oPrinter:SetPos( 124 * oPrinter:CharWidth )
    oPrinter:TextOut( transform( recvhead->gst, TOTAL_PICT ) )
    oPrinter:SetColor( RGB_BLACK )

    gt_inv += lt_inv
    gt_qty += lt_qty
    gt_cost += lt_cost
    gt_sell += lt_sell
    gt_retail += lt_retail
    gt_tax += lt_tax

    recvhead->( dbskip() )

   enddo

   if PageEject2( oPrinter )
    page_number++
    PageHead( oPrinter, report_name, page_width, page_number, Col_head1, Col_head2 )

   endif
   oPrinter:NewLine()
   oPrinter:textout( replicate( "=", oPrinter:maxcol() ) )
   oPrinter:NewLine()
   oPrinter:SetColor( RGB_RED )
   oPrinter:TextOut( 'Grand totals' )
   oPrinter:SetPos( 35 * oPrinter:CharWidth )
   oPrinter:TextOut( transform( gt_qty, QTY_PICT ) )
   oPrinter:SetPos( 64 * oPrinter:CharWidth )
   oPrinter:TextOut( transform( gt_cost, TOTAL_PICT ) )
   oPrinter:SetPos( 82 * oPrinter:CharWidth )
   oPrinter:TextOut( transform( gt_sell, TOTAL_PICT ) )
   oPrinter:SetPos( 109 * oPrinter:CharWidth )
   oPrinter:TextOut( transform( gt_sell, TOTAL_PICT ) )
   oPrinter:SetPos( 124 * oPrinter:CharWidth )
   oPrinter:TextOut( transform( gt_tax, TOTAL_PICT ) )

   oPrinter:endDoc()
   oPrinter:Destroy()

   recvline->( dbgotop() )
   while !recvline->( eof() )
    if recvhead->( dbseek( recvline->IndxKey ) )
     if recvhead->reserved
      Reserve_slip()

     endif

    endif
    recvline->( dbskip() )

   enddo

   Center( 4, 'Checking For Special Orders' )

   select recvline
   recvline->( ordsetFocus( 'id' ) )
   recvline->( dbsetrelat( 'recvhead', { || trim( recvline->IndxKey ) } ) )

   total on recvline->id fields qty to ( Oddvars( TEMPFILE ) ) ;
         for if( msupp = '*', TRUE, recvhead->supp_code = msupp ) .and. !recvhead->reserved

   sdbf:={}    // Sdbf for group special orders by customer
   aadd( sdbf, { "key", "C", 10, 0 } )
   aadd( sdbf, { "id", "c", 13, 0 } )
   aadd( sdbf, { "qty", "n", 10, 0 } )
   aadd( sdbf, { "reqd", "n", 10, 0 } )
   aadd( sdbf, { "number", "n", 6, 0 } )
   aadd( sdbf, { "comments", "c", 40, 0 } )
   aadd( sdbf, { "deposit", "n", 8, 2 } )
   aadd( sdbf, { "date", "d", 8, 0 } )
   aadd( sdbf, { "sell_price", "n", 8, 2 } )
   aadd( sdbf, { "custordno", 'c', 10, 0 } )
   ntemp := Oddvars( TEMPFILE2 )

   if select( "spectemp" ) != 0
    spectemp->( dbclosearea() )

   endif

   dbcreate( ntemp, sdbf )
   if Netuse( ntemp, EXCLUSIVE, 10, 'spectemp', NEW )
    if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, 'rectemp', NEW )
     set relation to rectemp->id into master
     while !rectemp->( eof() )           // Step thru rectemp

      qtyavail := rectemp->qty
      sID := rectemp->id

      if special->( dbseek( rectemp->id ) )  // got id ?

       while special->id = sID .and. qtyavail > 0 .and. !special->( eof() )

        mnum := special->number
        mcomments := special->comments
        spec_dep :=  special->deposit
        spec_date := special->date
        mcustordno := special->ordno
        if special->received < special->qty 

         Center(5,'Processing for ' + trim( customer->name ) )
         if !customer->stop .or. ( customer->stop .and. Isready( 10, 10, 'Customer is on stop - Allocate special order' ) )         
          qty_reqd := special->qty - special->received
          if qty_reqd <= qtyavail
           qtyavail -= qty_reqd
           qty_issued := qty_reqd

          else
           qty_issued := qtyavail
           qtyavail := 0

          endif
          @ 5,09 say space(60)

          Add_rec( 'spectemp' )
          spectemp->key := customer->key
          spectemp->id := rectemp->id
          spectemp->qty := qty_issued
          spectemp->reqd := qty_reqd
          spectemp->number := mnum
          spectemp->comments := mcomments
          spectemp->date := spec_date
          spectemp->deposit := spec_dep
          spectemp->sell_price := rectemp->sell_price
          spectemp->custordno := mcustordno
          spectemp->( dbrunlock() )
 
          if !Bvars( B_SPLETGROUP )
 
           for x := 1 to Bvars( B_SPADNO )
            Dockform( qty_reqd, qty_issued, mnum, mcomments, spec_dep, ;
                      spec_date, rectemp->sell_price, mcustordno )
            specEject := TRUE

           next

          endif

         endif

        endif
        special->( dbskip() )

       enddo

      endif
      rectemp->( dbskip() )

     enddo
     rectemp->( dbclosearea() )
     if Bvars( B_SPLETGROUP )
      select spectemp
      indx( "spectemp->key",'key' )
      set relation to spectemp->key into customer,;
                      spectemp->id into master
      spectemp->( dbgotop() )
      while !spectemp->( eof() )
       Dockform( spectemp->reqd, spectemp->qty, spectemp->number,;
                 spectemp->comments, spectemp->deposit, spectemp->date,;
                 spectemp->sell_price, spectemp->custordno )
       spectemp->( dbskip() )
       speceject := TRUE

      enddo
      spectemp->( dbclosearea() )   

     endif

    endif
    if prow() != 0
     eject

    endif
#endif

    select recvhead
    ordsetfocus( 'supplier' )
    if( msupp != '*', dbseek( msupp ), dbgotop() )
    while ( recvhead->supp_code = msupp .or. msupp = '*' ) .and. !recvhead->( eof() )
     Rec_lock('recvhead')
     recvhead->listed := TRUE
     recvline->( dbrunlock() )
     recvhead->( dbskip() )

    enddo
#ifndef THELOOK
    aPo := {}  // An array to hold po's
    recvline->( ordsetfocus( 'key' ) )
    if( msupp != '*', recvline->( dbseek( msupp ) ), recvline->( dbgotop() ) )
    while ( recvline->IndxKey = msupp .or. msupp = '*' ) .and. !recvline->( eof() )

     if recvline->ponum != 0              // No add to array for ponum = 0
      if ascan( aPo, recvline->ponum ) = 0
       aadd( aPo, recvline->ponum  )       // Add Po Number to array

      endif

     endif
     recvline->( dbskip() )

    enddo
     
    if len( aPo ) > 0                     // Have ponums in aPo array?
     if Isready( 14, , 'Print items not supplied/unfilled Special Orders listing' )
      mspecs := Isready( 16, , 'Print Only Specials Overdue' )
      select poline
      set relation to poline->id into master,;
                   to poline->id into recvline,;
                   to poline->id into special
      page_number:=1
      page_width:=80
      page_len:=66
      top_mar:=0
      bot_mar:=10
      col_head1 := 'Desc                    Author         Sta OrdQ BacQ SpeQ Ord Dat'
      col_head2 := '컴컴컴컴컴컴컴컴컴컴컴?컴컴컴컴컴컴컴 컴?컴컴 컴컴 컴컴 컴컴컴'
      report_name := 'Items not Supplied on Orders / Unfilled Special Orders'
      Print_find( "report" )
      set device to printer
      setprc(0,0)              // Could be superfluous
      PageHead( report_name, page_width, page_number, col_head1, col_head2 )
      for arr_ptr := 1 to len(aPo)                 // Start print Routine
       if PageEject( page_len, top_mar, bot_mar )
        page_number++
        PageHead( report_name, page_width, page_number, col_head1, col_head2 )
       endif
       select poline
       ordsetfocus( 'number' )
       mseek := aPo[ arr_ptr ]   // po number
       seek mseek
       if found()              // Found this po number
        mpo := poline->number
        @ prow()+2, 0 say 'Supplier: ' + BIGCHARS + substr( LookItUp( "supplier", pohead->supp_code ), 1, 14 );
                + chr(20) + ' Code: ' + pohead->supp_code + ' Order #' + Ns( mseek )
        @ prow()+1, 0 say ''
        while poline->number = mseek .and. !poline->(eof())  // Scan po items
         select recvline
         seek poline->id
         locate for recvhead->ponum = mseek while recvline->id = poline->id // Is id received here ?
         if !found()                                      // if !
          if PageEject( page_len, top_mar, bot_mar)       // Check for eject required
           page_number++
           PageHead( report_name, page_width, page_number, col_head1, col_head2 )
          endif
          if ( mspecs .and. !special->( eof() ) ) .or. !mspecs
           @ prow()+1, 0 say left( master->desc, 22 )
          endif
          if !mspecs
           @ prow(), 23 say left( master->author, 15 )
           @ prow(), 39 say master->status
           @ prow(), 43 say poline->qty_ord pict '9999'
           @ prow(), 48 say poline->qty pict '9999'
           @ prow(), 53 say master->special pict '9999'
           @ prow(), 58 say dtoc( pohead->date_ord )

          endif
          if !special->(eof())                         // Is it on special order ?
           select special
           while special->id = poline->id .and. !special->( eof() )
            if special->qty - special->received > 0                      // Been Received before
             if PageEject( page_len, top_mar, bot_mar)
              page_number++
              PageHead( report_name, page_width, page_number, col_head1, col_head2 )

             endif
             @ prow()+1,10 say 'Special #' + Ns(special->number)
             @ prow(), 28 say 'Qty Outstanding ' + Ns(special->qty-special->received)
             @ prow(), 50 say special->date
             @ prow(), 60 say left( customer->name, 25 ) + ' ' + customer->phone1
             @ prow(), 86 say left( special->comments, 25 )

            endif
            special->( dbskip() )

           enddo                      // id = sp->id .and. !special->eof()
           @ prow()+1,0 say ''        // say replicate(ULINE,80)

          endif

         endif
         poline->( dbskip() )

        enddo

       endif

      next                            //  po in aPo  array
      Endprint()
      set device to screen

     endif

    endif

   endif
#endif
  endif
  setkey( K_ALT_S, okafs )
 endif
 dbunlockall()
enddo
Oddvars( MSUPP, msupp )
close databases
return

*

Function GrnLnDisp ( msupp )
local tscr, reclbrow, mlkey, mscr, c, x, getlist:={}, mseq, mreq
select recvline
tscr := Box_Save( 2, 0 , 24, 79, C_BLACK )
reclbrow := tbrowsedb( 03, 4, 24-1, 79-1 )
for x = 1 to 24-5
 @ x + 4, 1 say row()-4 pict '99'

next
reclbrow:headsep := HEADSEP
reclbrow:colsep := COLSEP
reclbrow:gotopblock := { || dbseek( recvhead->supp_code + recvhead->invoice ) }
reclbrow:gobottomblock := { || jumptobott( recvhead->supp_code + recvhead->invoice ) }
reclbrow:skipblock := KeyskipBlock( { || recvline->IndxKey }, recvhead->supp_code + recvhead->invoice ) 
c:=tbcolumnnew( 'Desc', { || left( master->desc, 22 ) } )
reclbrow:addcolumn( c )
reclbrow:addcolumn( tbcolumnnew( 'Qty', { || transform( recvline->qty, '99999' ) } ) )
reclbrow:addcolumn( tbcolumnnew( 'Barcode', { || if( recvline->barprint, 'Y', 'N' ) } ) )
reclbrow:addcolumn( tbcolumnnew( 'PO', { || recvline->ponum } ) )
reclbrow:addcolumn( tbcolumnnew( 'Inv Qty', { || transform( recvline->qty_inv, '99999' ) } ) )
reclbrow:addcolumn( tbcolumnnew( 'Inv Cost', { || transform( recvline->cost_price ,'999.99' ) } ) )
reclbrow:addcolumn( tbcolumnnew( 'Sell', { || transform( recvline->sell_price,'999.99' ) } ) )
reclbrow:addcolumn( tbcolumnnew( '% Disc', { || transform( 100 - ;
  ( recvline->cost_price/( recvline->sell_price / 100 ) ), '999.99' ) } ) )
reclbrow:addcolumn( tbcolumnnew( 'Retail', { || transform( recvline->retail ,'999.99' ) } ) )
reclbrow:addcolumn( tbcolumnnew( 'Special', { || if( master->special = 0, 'No ','Yes' ) } ) )
reclbrow:addcolumn( tbcolumnnew( 'ID', { || idcheck( master->id ) } ) )
reclbrow:freeze := if( msupp='*', 2, 1 )
reclbrow:goTop()
mlkey := 0
while mlkey != K_ESC .and. mlkey != K_END
 reclbrow:forcestable()
 mlkey := inkey(0)
 if !navigate( reclbrow, mlkey )

  do case
  case mlkey >= 48 .and. mlkey <= 57
   keyboard chr( mlkey )
   mseq := 0
   mscr := Box_Save( 2, 08, 4, 40 )
   @ 3,10 say 'Selecting No' get mseq pict '999' range 1,24-2
   read
   Box_Restore( mscr )
   if !updated()
    loop

   else
    mreq := recno()
    skip mseq - reclbrow:rowpos
    GrnDisp()
    goto mreq
    reclbrow:refreshcurrent()

   endif

  case mlkey == K_DEL
   if recvline->( eof() )
    Error( 'Nothing to Delete!', 12 )

   else
    if Isready( 5, , 'About to delete => ' + trim( master->desc ) )
     Rec_lock( 'recvline' )
     recvline->qty := 0

    endif

   endif

  case mlkey == K_ENTER
   GrnDisp()

  case mlkey == K_F1
   mscr := Box_Save( 13, 50, 18, 75 )
   @ 14,51 say 'Enter Edit Item'
   @ 15,51 say 'F6 Reverse Barcode Flag'
   @ 16,51 say 'F10 Display Desc'
   @ 17,51 say 'Del Delete Item'
   inkey(0)
   Box_Restore( mscr )

  case mlkey == K_F6
   Rec_lock()
   recvline->barprint := !recvline->barprint
   dbrunlock()
   reclbrow:refreshcurrent()

  case mlkey == K_F10
   itemdisp( FALSE )

  endcase

 endif

 if recvline->qty = 0
  Del_rec( 'recvline', UNLOCK )
  reclbrow:refreshall()

 endif

enddo
select recvhead 
Box_Restore( tscr )
return nil

*

procedure Dockform ( p_req, p_issued, specordno, mcomments, spec_dep, spec_date, price, custordno )

Print_find( "report" )

// Pitch10()
set device to print

if !customer->spec_let
 if Bvars( B_SPECSLIP ) = 2    // An alternate type of Special Order Slip here
  if prow() > 58
   eject
  endif
  @ prow()+1, 0 say replicate( ULINE, 80 )
  @ prow()+1, 0 say 'Ord ' + Ns( p_req ) + ' Supplied ' +Ns( p_issued )+ ' x ' + left( master->desc, 40 )
  @ prow()+1, 0 say trim( customer->name )+'  '+customer->key+'  Ph.'+;
                   trim( customer->phone1 )+ ' #'+Ns( specordno )+' '+custordno
  @ prow()+1, 0 say trim( mcomments ) + '   ' + trim( master->comments )
  @ prow()+1, 0 say trim( master->alt_desc )
  @ prow()+1, 0 say replicate( ULINE, 80 )
 else
  if prow() > 55
   eject
  endif
  @ prow()+1, 0 say chr(14) + 'Special Order No: ' + ' ' + Ns( specordno )
  @ prow()+1, 0 say 'Received on ' + dtoc( Bvars( B_DATE ) ) + '   ' + 'Ordered on ' + dtoc( spec_date )
  @ prow()+1, 0 say 'Name     ' + customer->name
  @ prow()+1, 0 say 'Address  ' + customer->add1
  @ prow()+1, 0 say '         ' + customer->add2
  @ prow()+1, 0 say '         ' + customer->add3+'  '+customer->pcode
  @ prow()+1, 0 say 'Phone 1 ' + customer->phone1+'  Phone 2 ' + customer->phone2
  @ prow()+1, 0 say 'Comments ' + customer->comments
  @ prow()+1, 0 say 'Special Comments ' + mcomments
  @ prow()+1, 0 say 'Deposit  ' + Ns( spec_dep )
  @ prow()+1, 0 say 'id     ' + idcheck( master->id ) + '   '+'Cust Order No '+custordno
  @ prow()+1, 0 say 'Desc    ' + master->desc
  @ prow()+1, 0 say 'Author   ' + master->alt_desc
  @ prow()+1, 0 say 'Qty Ord  ' + Ns(p_req) + '    ' + 'Qty Rec  ' + Ns(p_issued)
  @ prow()+1, 0 say replicate( ULINE, 50 )
 endif
else
 SpecLetter ( p_req, p_issued, specordno, mcomments, spec_dep, spec_date, price )
endif
set device to screen
return

*

Proc Reserve_slip
set device to print
if prow() > 62
 eject
endif
@ prow()+1,0 say replicate( ULINE, 50 )
@ prow()+1,0 say 'Reserved Stock Slip'
@ prow()+1,0 say master->desc
@ prow()+1,0 say recvline->comment
@ prow()+1,0 say replicate( ULINE, 50 )
set device to screen
return

*

Function GrnDisp 
local mscr:=Box_Save( 02, 08, 22, 72 ), getlist:={}, mtax
Highlight( 03, 12, padl( ID_DESC, 13 ), idcheck( master->id ) )
Highlight( 05, 12, '         Desc', alltrim( master->desc ) )
Highlight( 07, 12, '     Alt Desc', master->alt_desc )
Highlight( 09, 12, '     Supplier', supplier->name )
@ 11,12 say ' Qty Received' get recvline->qty pict '99999'
@ 12,12 say ' Qty Invoiced' get recvline->qty_inv pict '99999'
@ 12,45 say 'Returns Reason' get recvline->retreason when ( recvline->qty != recvline->qty_inv ) pict '@!'
Center( 10, 'G.S.T.' + if( !supplier->gst_inc, ' not', '' ) + ' included in invoice line cost' )
mtax := recvline->cost_price * ( Bvars( B_GSTRATE )/100 )
@ 13,12 say '   Cost Price' get recvline->cost_price pict '9999.99'
Highlight( 13, 35, 'Invoice G.S.T Component', Ns( mtax, 7, 2 ) )
@ 14,12 say '   Sell Price' get recvline->sell_price pict '9999.99'
@ 15,12 say '        R.R.P' get recvline->retail pict '9999.99'
@ 17,12 say '      Barcode' get recvline->barprint pict 'y'
@ 21,12 say '     Comments' get recvline->comment pict '@S40'
Rec_lock('recvline')
Rec_lock('recvhead')
read
recvline->( dbrunlock() )
recvhead->( dbrunlock() )
Box_Restore( mscr )
return nil

