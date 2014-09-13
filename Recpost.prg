/*

        Post into Stock Items received from any source

        Last change:  APG   7 Jun 2004    4:19 pm

      Last change:  TG   19 Mar 2011    6:29 pm
*/

Procedure Recpost
 
#include "bpos.ch"
 
local po_list:={}, inv_list:={}, msupp:=Oddvars( MSUPP )
local mgo:=FALSE, clrspace:=space(60), getlist:={}, old_price
local spec_received, qty_avail, sID, needed, mcode, fieldord, minvtot:=0
local monhand, mavr, X, mmonth := upper( left( cmonth( Bvars( B_DATE ) ), 3 ) )
local moperator
local mbatch

Heading( 'Post Items Received' )
Center( 24, line_clear( 24 ) + "Opening Files for Posting" )

if Netuse( "hold" )
 if Netuse( "stkhist" )
  if Netuse( "customer" )
   if Netuse( "cretrans" )
    if Netuse( "supplier" )
     if Netuse( "special" )
      special->( ordsetfocus( BY_ID ) )
      set relation to special->key into customer
      if Netuse( "DraftRet" )
       if Netuse( "deptmove" )
        if Netuse( "purhist" )
         if Netuse( "pohead" )
          if Netuse( "poline" )
           if master_use()
            if Netuse( "recvline" )
             if Netuse( "recvhead" )
              set relation to recvhead->supp_code+recvhead->invoice into recvline
              mgo := TRUE
             endif
            endif
           endif
          endif
         endif
        endif
       endif
      endif
     endif
    endif
   endif
  endif
 endif
endif

Line_clear( 24 )

if mgo

 msupp := GetSuppCode( 10, 32, ALLOW_WILD )

 moperator := Oddvars( OPERCODE )

 if lastkey() != K_ESC

  Box_Save( 2, 08, 14, 72 )

  Center( 4, '-=< Posting in Progress - Please Wait >=-' )

  if( msupp = '*', recvhead->( dbgotop() ), recvhead->( dbseek( msupp ) ) )

  mbatch := Sysinc( "recvbatch", 'I', 1 )

  while !recvhead->( eof() ) .and. ( recvhead->supp_code = msupp .or. msupp = '*')

   if recvhead->listed

    while !recvline->( eof() ) .and. ( recvline->IndxKey = recvhead->supp_code + recvhead->invoice )

     if recvline->qty_inv > 0 .and. recvline->id != 'STKADJ'
      // Update master file
      select master
      @ 8,9 say clrspace
      @ 8,10 say 'Master'
      
      if !Codefind( recvline->id )
       Error( "id " + idcheck( recvline->id ) + " error on Master file", 12 )
       SysAudit( 'Recvid!Fnd' + recvline->id )
      else

       @ 6,9 say clrspace
       Center( 6, 'Posting desc ออ> ' + trim( left( master->desc, 40 ) ) )
       old_price := master->sell_price
       Rec_lock( 'master' )
       monhand := recvline->qty_inv + master->onhand
       mavr := master->avr_cost
       if recvhead->supp_code != '!' .and. monhand > 0
        mavr := (( master->avr_cost*master->onhand )+( recvline->cost_price*recvline->qty_inv ) )/;
        ( recvline->qty+master->onhand )
       endif
       // This '!' bit stops "funny suppliers" from overwriting master prices
       master->avr_cost := mavr

       if recvhead->supp_code != 'BUYB'    // Buyback Supplier
        master->cost_price := if( recvhead->supp_code!='!',recvline->cost_price,master->cost_price)
        master->sell_price := if( recvhead->supp_code!='!',recvline->sell_price,master->sell_price)
        master->retail := if( recvhead->supp_code!='!',recvline->retail,master->retail)

       endif

       if recvline->over_write
        master->supp_code := recvhead->supp_code

       endif

       if !recvhead->consign
        Update_oh( recvline->qty_inv )

       else
        master->consign += recvline->qty
         
       endif
       master->dlastrecv := Bvars( B_DATE )
       master->status := 'ACT'
       if recvline->ponum != 0
        master->onorder := max( 0, master->onorder - recvline->qty )

       endif
       master->( dbrunlock() )

       if !recvhead->reserved                 // Special Order file
        qty_avail := recvline->qty
        sID := recvline->id
        @ 8,20 say 'Special'
        if special->( dbseek( recvline->id ) )
         while special->id = recvline->id .and. qty_avail > 0 .and. !special->(eof())
          spec_received := 0
          if special->received < special->qty
           needed := special->qty - special->received
           Rec_lock( 'special' )
           if qty_avail <= needed
            if Bvars( B_SPECLABE )
             Print_find( "barcode" )
             Spec_label( qty_avail )

            endif
            if !special->standing          // Is order a standing special order - may need deleting
             special->received := special->received + qty_avail
             special->daterecv := Bvars( B_DATE )

            endif
            spec_received := qty_avail
            qty_avail := 0

           else
            if Bvars( B_SPECLABE )         // Print spine label for descs on special
             Print_find( "barcode" )
             Spec_label( needed )

            endif
            spec_received := special->qty - special->received
            if !special->standing
             special->received := special->qty

            endif
            qty_avail -= needed
           endif
           special->( dbrunlock() )

          endif
          special->( dbskip() )
         enddo
        endif
       endif
       
       if recvline->ponum != 0            // Purchase orders are deleted/reduced here
        select poline
        ordsetfocus( 'id' )
        @ 8,30 say 'Purchase'
        if dbseek( recvline->id )
         if ascan( po_list, recvline->ponum ) = 0
          aadd( po_list, recvline->ponum )
         endif
         locate for poline->number = recvline->ponum while poline->id = recvline->id
         if found()
          Rec_lock( 'poline' )
          do case
          case poline->qty - recvline->qty <= 0
           poline->( dbdelete() )
           Abs_delete( 'poline' )
          case poline->qty - recvline->qty > 0
           poline->back_ord := TRUE 
           poline->date_bord := Bvars( B_DATE ) 
           poline->qty -= recvline->qty
          endcase
          poline->( dbrunlock() )
         endif
        endif
       endif
      
       select purhist                         // Supplier history file updated
       @ 8,40 say 'History'
       mcode := trim( recvhead->supp_code ) + '_REC'
       if !dbseek( mcode )
        Add_rec()
        purhist->code := mcode
        dbrunlock()
       endif
       Rec_lock()
       fieldord := fieldpos( mmonth )
       fieldput( fieldord, fieldget( fieldord ) + ( recvline->cost_price * recvline->qty ) )
       dbrunlock()
      
       if !recvhead->consign

        select deptmove                        // Department movement
        @ 8,50 say 'Dept'
        mcode := trim( master->department )
        seek mcode
        locate for deptmove->type = 'REC' while deptmove->code = mcode .and. !eof()
        if !found()
         Add_rec()
         deptmove->code := mcode
         deptmove->type := 'REC'
         dbrunlock()
        endif
        Rec_lock( 'deptmove' )
        fieldord := fieldpos( mmonth )
        fieldput( fieldord, fieldget( fieldord ) + ( recvline->sell_price * recvline->qty ) )
        deptmove->( dbrunlock() )

       endif

       if recvhead->reserved                  // Booklist Stock Allocations
        select bklsid
        seek recvline->id
        locate for trim( bklsid->bkls_code ) $ trim( recvline->comment ) ; 
               while bklsid->id = recvline->id .and. !bklsid->( eof() )

        if found()
         Rec_lock( 'bklsid' )
         bklsid->pickingqty += recvline->qty
         bklsid->( dbrunlock() )

        endif

       endif
      
       Add_rec( 'stkhist' )               // Stock History file updates
       stkhist->id := master->id
       stkhist->reference := trim( recvhead->invoice ) + ':' + Ns( recvline->ponum )
       stkhist->date := recvhead->dreceived
       stkhist->qty := recvline->qty_inv
       stkhist->supp_code := recvhead->supp_code 
       stkhist->type := if( left( recvhead->supp_code, 1 ) = '!', substr( recvhead->supp_code, 2, 1 ), ;
                            if( recvhead->supp_code = 'BUYB', 'B', 'I' )  )
       stkhist->cost_price := recvline->cost_price
       stkhist->sell_price := recvline->sell_price

       if recvline->qty != recvline->qty_inv
        Add_rec( 'DraftRet' )
        DraftRet->date := Bvars( B_DATE ) 
        DraftRet->qty := recvline->qty_inv - recvline->qty
        DraftRet->id := recvline->id 
        DraftRet->supp_code := recvhead->supp_code 
        DraftRet->brand := master->brand
        DraftRet->department := master->department 
        DraftRet->type := 'R' 
        DraftRet->desc := master->desc 
        DraftRet->alt_desc := master->alt_desc 
        DraftRet->rrp := recvline->retail 
        DraftRet->cost := recvline->cost_price 
        DraftRet->invmacro := '1' 
        DraftRet->stkhistoff := 0 
        DraftRet->hold := NO 
        DraftRet->skey := master->desc
        DraftRet->ret_code := recvline->retreason

        DraftRet->( dbrunlock() )

       endif
       
       if recvline->barprint

        @ 8,60 say 'Barcode'
        Print_find( "barcode" )
        
        Code_print( if( !recvhead->consign, ;
                         master->id,          ;
                         '979' + substr( master->id, 4, ID_CODE_LEN - 3 ) ), ;
                         recvline->qty )
       endif

      endif               // Found on Master File Record
 
     endif                // Qty > 0 this must be here as STKADJ may be negative !
       
     minvtot += ( recvline->qty_inv * recvline->cost_price )
        
     Rec_lock( 'recvline' )
     recvline->posted := TRUE
     recvline->( dbrunlock() )

// Processing Complete - Delete recvline Record

     Del_rec( 'recvline', UNLOCK )
        
     recvline->( dbskip() )

    enddo      // While recvline

// Compile a list of Supplier Invoice #'s to process for creditors posting

    aadd( inv_list, { recvhead->invoice, recvhead->supp_code, recvhead->dreceived, ;
                      recvhead->inv_total, minvtot, recvhead->gst } )

    minvtot := 0
   
    if !recvline->( dbseek( recvhead->supp_code + recvhead->invoice ) )

     Del_rec( 'recvhead', UNLOCK )

    endif
 
   endif       // Listed

   recvhead->( dbskip() )

  enddo    // while recvhead

  if len( po_list ) != 0
   Center( 10, '-=< Backorder processing in Progress >=-' )
   poline->( ordsetfocus( 'number' ) )
   for x := 1 to len( po_list )
    if poline->( dbseek( po_list[ x ] ) )     // Find po and flag rest of descs as on backorder
     while poline->number = po_list[ x ] .and. !poline->( eof() )
      Rec_lock( 'poline' )
      poline->back_ord := TRUE 
      poline->date_bord := Bvars( B_DATE )
      poline->( dbrunlock() )
      poline->( dbskip() )
     enddo
    else
     if pohead->( dbseek( po_list[ x ] ) )  // Delete the header record! - Exterminate - Exterminate - Exterminate
      Del_rec( 'pohead', UNLOCK )
     endif
    endif   
   next
  endif
     
// Check for invoices to post and creditors enabled and auto posting
     
  if Bvars( B_AUTOCRED )

   Center(12,'-=< Creditor processing in Progress >=-')
   for x := 1 to len( inv_list )

    supplier->( dbseek( inv_list[ x, 2 ] ) )
    Rec_lock( 'supplier' )
    supplier->amtcur += inv_list[ x, 4 ]
    supplier->ytdamt += inv_list[ x, 4 ]
    supplier->( dbrunlock() )

    Add_rec( 'cretrans' )
    cretrans->code := inv_list[ x, 2 ]
    cretrans->ttype := 1
    cretrans->tage := 1
    cretrans->tnum := inv_list[ x, 1 ]
    cretrans->date := inv_list[ x, 3 ]
    cretrans->desc := inv_list[ x, 1 ]
    cretrans->amt := inv_list[ x, 4 ]
    cretrans->variance := inv_list[ x, 4 ] - inv_list[ x, 5 ]   // This is new!
    cretrans->( dbrunlock() )

   next

  endif

 endif    // Lastkey() != K_ESC
 
endif     // Mgo

dbcloseall()
Oddvars( MSUPP, msupp )     

return

*

procedure spec_label ( label_qty )
if customer->spec_let
 
// // Pitch17()
 set console off
 set print on
 while label_qty > 0
  ? trim( master->desc )
  ? trim( customer->name )
  ? 'Date Received ' + dtoc( Bvars( B_DATE ) )
  ? 'Phone Number  ' + customer->phone1
  ? 'Deposit ' + Ns( special->deposit, 7, 2 ) + '  Ord #'+Ns( special->number, 6 )
  ?
  label_qty--
 enddo
 set print off
 set console on
 Endprint( NO_EJECT )
endif
return
