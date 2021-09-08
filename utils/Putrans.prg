/*

 Transfer ' + ITEM_DESC + ' from One system to Another

 Last change: DOFAT 30/06/2008 8:41:25 PM

      Last change:  TG   16 Jan 2011    6:40 pm
*/

#include "bpos.ch"

Procedure p_transfer
 
local mgo := FALSE, manswer, firstpass, mtrannum, mupdt, mapp, farr
local mdbf, madrive, mnumfiles, x, oldscr := Bsave(), getlist := {}, mdate
local mlastnum, mqty, sID, mpo, mto_store, ftrans, mscr, mdrive, aArray
local mtot, mtemp, trobj, akey, i, mkey, scrn, adding, driveok:=FALSE
local endtry:=FALSE, mfrom_store, mfpos, y

local okf6       // Holds key state for F6
local prchoice
local mautonum   // Automatic transfer number
local trmode     // Transfer Mode
local mloop

memvar mnum
private mnum

Center( 24, 'Opening Files for Stock Transfer' )

if Netuse( 'branch' )
 if Netuse( 'draft_po' )
  if Netuse( 'recvhead' )
   if Netuse( 'recvline' )
    if Netuse( 'stkhist' )
     if Netuse( 'trrqst' )
      if Netuse( 'transfer' )
       mgo := Master_use()
      endif
     endif
    endif
   endif
  endif
 endif
endif
 
Line_clear( 24 )

while mgo
  
 Brest( oldscr )
 aArray := {}
 aadd( aArray, { 'Exit', 'Return to Purchase Menu' } )
 aadd( aArray, { 'Out', 'Transfer Items Out' } )
 aadd( aArray, { 'In', 'Receive Items on Transfer' } )
 aadd( aArray, { 'Purge', 'Delete old Transfer Details' } )
 aadd( aArray, { 'Report', 'Hardcopy of Transfers' } )
 manswer := MenuGen( aArray, 07, 18, 'Transfer')

 do case
 case manswer < 2
  dbcloseall()
  return

 case manswer = 2

  while TRUE

   cls
   Heading( 'Transfer Items Out to Other Store' )

   akey := {}
   aadd( akey, { "id", 'c', 12, 0 } )
   aadd( akey, { "qty", 'n', 5, 0 } )
   aadd( akey, { "qty_trf", 'n', 5, 0 } )
   aadd( akey, { "ponum", 'n', 6, 0 } )
   aadd( akey, { "from", 'c', BRANCH_CODE_LEN, 0 } )
   aadd( akey, { "to", 'c', BRANCH_CODE_LEN, 0 } )
   aadd( akey, { "coop_type", 'c', 1, 0 } )
   aadd( akey, { "coop_num", 'c', 10, 0 } )
   aadd( akey, { "ntrf_reas", 'c', 1, 0 } )

   dbcreate( Oddvars( TEMPFILE ), aKey )

   if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "keys" )

    trmode := 'M'  // Manual
    mautonum := 0
   
    set relation to keys->id into master,;
                 to keys->to into branch

    trobj := TBrowseDB( 2, 0, 24, 79 ) 
    trobj:colorspec := if( iscolor(), TB_COLOR, setcolor() )
    trobj:HeadSep := HEADSEP
    trobj:ColSep := COLSEP

    trobj:addcolumn( tbcolumnNew( 'id', { || padr( idcheck( keys->id ), 12 ) } ) )
    trobj:addcolumn( tbcolumnNew( 'Qty Rqst', { || padl( keys->qty, 5 ) } ) )
    trobj:addcolumn( tbcolumnNew( 'Qty Trfd', { || padl( keys->qty_trf, 5 ) } ) )
    trobj:addcolumn( tbcolumnNew( 'Desc', { || left( master->desc, 35 ) } ) )
    trobj:addcolumn( tbcolumnNew( 'PO', { || padl( keys->ponum, 6 ) } ) )
    trobj:addcolumn( tbcolumnNew( 'To', { || left( branch->name, 12 ) } ) )
    
    mpo := 0
    mto_store := space( BRANCH_CODE_LEN )

    adding := TRUE  
    mkey := 0

    while mkey != K_ESC .and. mkey != K_END

     trobj:forcestable()

     if adding
      keyboard chr( K_INS )

     endif

     mkey := inkey(0)

     if !Navigate( trobj, mkey )

      do case
      case mkey == K_F1
       Build_help( { ;
                    { 'Enter', 'Edit Item' },;
                    { 'Del', 'Delete Item' },;
                    { 'Ins', 'Add New Items' },;
                    { 'F9', 'Append from File' },;
                    { 'F10', 'Display Desc' },;
                    { 'End', 'Process Transfer' } } )

      case mkey == K_F9 .and. trmode = 'M'

       mautonum := 0
       mscr := Bsave( 3, 10, 5, 50 )
       @ 4, 12 say 'Automatic Transfer to Append' get mautonum pict '999999'
       read
       Brest( mscr )

       if mautonum > 0
        if !trrqst->( dbseek( mautonum ) )
         Error( 'Number not found on request file', 12 )

        else
         select trrqst
         locate for !trrqst->processed while trrqst->number = mautonum
         select keys

         if !trrqst->( found() )
          Error( 'This transfer request appears to be fully processed', 12 )

         else

          while trrqst->number = mautonum .and. !trrqst->( eof() )

           if !trrqst->processed

            Add_rec( 'keys' )

            for y := 1 to trrqst->( fcount() )

             mfpos := keys->( fieldpos( trrqst->( fieldname( y ) ) ) )

             if mfpos != 0

              keys->( fieldput( mfpos, trrqst->( fieldget( y ) ) ) )

             endif

            next y

            keys->ntrf_reas := '0'
           
            keys->( dbrunlock() )

           endif
          
           trrqst->( dbskip() )

          enddo
          trmode := 'A'  // Automatic
         
          trobj:gotop()
          trobj:refreshall()

         endif

        endif

       endif    
   
      case mkey == K_F10
       itemdisp( FALSE )
       select keys

      case mkey == K_INS .and. trmode = 'M'
       scrn := Bsave( 1, 08, 8, 72 )
       sID := space( ID_ENQ_LEN )
       adding := TRUE
       @ 2,10 say 'id to Transfer' get sID pict '@!'

       read

       if lastkey() = K_ESC   
        adding := FALSE 
        trobj:refreshall()

       else

        if !Codefind( sID ) 
         Error( 'Code not on file', 12 )
         trobj:refreshall()

        else
         mqty := 0
         Highlight( 3, 10, 'Desc ', left( master->desc, 53 ) )

         @ 4,10 say 'Purchase ( Transfer ) Order Number' get mpo pict '@k 999999'
         if empty( mto_store )

          @ 5,10 say 'Transfer to' get mto_store pict '@!' ;
                 valid( mto_store != Bvars( B_BRANCH ) .and. dup_chk( mto_store, 'branch' ) )
         else

          Highlight( 5, 10, 'Transfer to ', Lookitup( 'branch', mto_store ) )

         endif        

         @ 6,10 say 'Qty to Transfer' get mqty pict '9999'

         read

         if mqty > 0 .and. !empty( mto_store )

          Add_rec( 'keys' )
          keys->id := master->id
          keys->qty_trf := mqty
          keys->ponum := mpo
          keys->to := mto_store
          keys->from := Bvars( B_BRANCH )
          keys->( dbrunlock() )
          keys->( dbgotop() )
                
          trobj:gobottom()

         endif
         trobj:refreshall()

        endif 

       endif
      
       Brest( scrn )

      case mkey == K_DEL .and. trmode = 'M'
       keys->( dbdelete() )
       keys->( dbgotop() )
       trobj:refreshall()

      case mkey == K_ENTER
       scrn := Bsave( 1, 08, 7, 72 )
       sID := space( ID_ENQ_LEN )

       Highlight( 2, 10, 'id to Transfer ', keys->id )
       Highlight( 3, 10, 'Desc ', left( master->desc, 53 ) )
       @ 4,10 say 'Qty to transfer' get keys->qty_trf pict '9999' 
       @ 5,10 say 'Purchase ( Transfer ) Order Number' get keys->ponum pict '@k 999999'
       @ 6,10 say 'Transfer to' get keys->to pict '@!' ;
              valid( keys->to != Bvars( B_BRANCH ) .and. ;
                     dup_chk( keys->to, 'branch' ) )
       read

       if keys->qty_trf = 0 .and. trmode = 'M'

        Del_rec( 'keys', UNLOCK ) 

       endif

       trobj:refreshall()
       Brest( scrn )

      endcase
     endif
    enddo
    
    if !( ( keys->( lastrec() ) != 0 ) .and. IsReady( 12 ) )

     exit

    else

     if Isready( 12, 10, 'Process this Transfer' )
      select keys
      pack

      mtrannum := Sysinc( 'transfer', 'I', 1, 'transfer' )

      keys->( dbgotop() )
      while !keys->( eof() )

       Add_rec( 'transfer' )
       transfer->number := mtrannum              // mtrannum
       transfer->branch := Bvars( B_BRANCH )
       transfer->id :=  keys->id             // master->id
       transfer->qty := keys->qty_trf            // mqty
       transfer->date := Bvars( B_DATE )
       transfer->ponum := keys->ponum
       transfer->retail := master->retail
       transfer->cost_price := master->cost_price
       transfer->sell_price := master->sell_price
       transfer->from := keys->from              // Bvars( B_BRANCH )
       transfer->to := keys->to                  // mto_store

       transfer->( dbrunlock() )
       keys->( dbskip() )

      enddo

 #ifndef HEAD_OFFICE

      Heading("Select Drive to Write Transfer Files")
      mscr := Bsave( 09, 10, 13, 14 )
      @ 10,11 prompt 'A:'
      @ 11,11 prompt 'B:'
#ifndef __HARBOUR__
      @ 12,11 prompt chr( getdriv() ) + ':'
#endif
      menu to mdrive
      Brest( mscr )
      mdrive := if( mdrive=1, 'A:', if( mdrive=2, 'B:', '\transfer\' ) )

      if mdrive = 'A:' .or. mdrive = 'B:'
       Center( 8, 'Insert transfer diskette into Drive ' + mdrive )

      endif

      if Isready( 5 )

       Center( 9, 'Copying Details on Transfer #' + Ns( mtrannum ) + ' to disk' )

       scrn := Bsave( 8, 10, 11, 70 )
       mdbf := mdrive + "t_" + Ns( mtrannum ) + '.dbf'
       driveok := FALSE
       endtry := FALSE
       
       while !driveok .and. !endtry

        if !DriveTest( mdrive ) 
         if !Isready( 12, , 'Try Floppy Drive Again' )
          endtry := TRUE
         endif
        else
         driveok := TRUE
        endif

       enddo

       if driveok

        Kill( mdbf )
        select transfer
        seek mtrannum
        copy to ( mdbf ) while transfer->number = mtrannum

       endif 
      
       if !driveok .and. !file( mdbf )

        Error( "File not written to floppy - Transfer Cancelled", 12 )
        loop

       endif

 #endif

       mtot := 0
       select transfer
       dbseek( mtrannum )
       while transfer->number = mtrannum .and. !transfer->( eof() )

        if Codefind( transfer->id )
         
         Rec_lock( 'master' )
         Update_oh( -transfer->qty )
         master->( dbrunlock() )
         
 #ifdef TRANSFERTODPO

         if master->Supp_Code != '%SH%' .and. master->Supp_Code != 'MISC'
          if master->onhand < ( master->minstock - master->onorder)
           mqty := master->minstock - master->onhand - master->onorder
           select draft_po
           locate for draft_po->source = 'St' while draft_po->id = master->id
           if found()      // Record Exist Already? Must not be Special Order
            Rec_lock()
            draft_po->qty := mqty
           else
            Add_rec()
            draft_po->id := master->id
            draft_po->supp_code := master->Supp_Code
            draft_po->qty := mqty
            draft_po->date_ord := Bvars( B_DATE )
            draft_po->special := NO
            draft_po->source := 'St'
            draft_po->skey := substr( master->alt_desc, 1, 5 ) + master->desc
            draft_po->department := master->department
            draft_po->hold := Bvars( B_DEPTORDR )
   #ifdef DPO_BY_DESC
            draft_po->skey := master->desc
   #endif
           endif
           draft_po->( dbrunlock() )
          endif
         endif

 #endif
         
         Add_rec( 'stkhist' )
         stkhist->id := master->id
         stkhist->reference := 'TrO:' + Ns( mtrannum ) + transfer->to
         stkhist->date := Bvars( B_DATE )
         stkhist->qty := -( transfer->qty )
         stkhist->type := 'T'
         stkhist->( dbrunlock() )
          
         mtot += master->cost_price*(Bvars( B_GSTRATE )/100)*transfer->qty
 
        endif
       
        transfer->( dbskip() )

       enddo
 
 #ifdef RECV_TRANSFER

       if !Netuse( 'fttrans' )

        Error( 'Cannot post transfer Acknowledgement #' + Ns( mtrannum ), 12, ,'Unable to open transfer file for Head office upload' )
        Audit( 'TrAck#' + Ns( mtrannum ) + 'Failure' )

       else

        keys->( dbgotop() )
        while !keys->( eof() )
       
         Add_rec( 'fttrans' )
         fttrans->number := mtrannum
         fttrans->branch := Bvars( B_BRANCH )
         fttrans->id := keys->id
         fttrans->qty := keys->qty_trf
         fttrans->date := Bvars( B_DATE )
         fttrans->to := keys->to
         fttrans->from := keys->from
         fttrans->type := trmode
         fttrans->( dbrunlock() )

         keys->( dbskip() )

        enddo
        fttrans->( dbclosearea() )

       endif

       if valtype( Scrn) == 'A'           // SWW 1/12/95
         Brest( scrn )                    // Apparently scrn is not always an array?
       endif
      

 #endif

      
 #ifndef HEAD_OFFICE

       if driveok .and. Isready( 12, 10, 'Write out Update Records as well' )

        Heading('Create Update Diskette for Remote')
        select master
        ordsetfocus(  )
        if lastrec() > 501
         goto lastrec() - 500
        else
         go top
        endif
        copy rest to ( mdrive + "update" ) for !deleted()
        master->( ordsetfocus( BY_ID ) )

       endif
      endif

 #endif

      if trmode = 'A' 

       trrqst->( dbseek( mautonum ) )

       while trrqst->number = mautonum .and. !trrqst->( eof() )

        Rec_lock( 'trrqst' )
        trrqst->processed := TRUE
        trrqst->( dbrunlock() )
        trrqst->( dbskip() )

       enddo

      endif  

      Print_find( "report" )
      Printcheck()
      Pitch17()

      farr := {}

      select keys
      keys->( dbgotop() )
      locate for keys->qty_trf > 0
      if found() 

       keys->( dbgotop() )
       aadd( farr, { 'idcheck( id )','id', ID_CODE_LEN, 0, FALSE } )
       aadd( farr, { 'left( master->desc, 25 )', 'Desc', 25, 0, FALSE } )
       aadd( farr, { 'qty_trf', ' Qty;Trans', 5, 0, TRUE } )
       aadd( farr, { 'to', 'To', BRANCH_CODE_LEN, 0, FALSE } )
       aadd( farr, { 'from', 'From', BRANCH_CODE_LEN, 0, FALSE } )
       aadd( farr, { 'master->cost_price', 'Cost;Price', 7, 2, FALSE } )
       aadd( farr, { 'keys->qty_trf * master->cost_price', 'Extended;Cost Price', 10, 2, TRUE } )
       Reporter( farr, 'Transfer #'+Ns( mtrannum )+' Details Print', '', '', '', '',,,'keys->qty_trf>0',80 )
       EndPrint()

       Error( 'Transfer #' + Ns( mtrannum ) + ' created', 12 )

      endif

     endif  // Ok to process

    endif   // IsReady(12)

    keys->( dbclosearea() )

   endif    // Netuse keys
  
  enddo
/////////////////***************   Transfer In  *****************////////////////////////

/* 
   
   There are two versions operating here depending if you are in a Head Office 
   situation or not

*/

 case manswer = 3

  Heading( "Transfer Items in from other Store" )

#ifdef HEAD_OFFICE

  mtrannum := 0
  mscr := Bsave( 06, 10, 08, 40 )
  @ 7, 12 say 'Transfer # to receive' get mtrannum pict '999999'
  read
  Brest( mscr )
  if !updated()
   loop

  else

   if !transfer->( dbseek( mtrannum ) )
    Error( 'Transfer #' + Ns( mtrannum ) + ' not on file', 12 )

   else
    akey := {}
    aadd( akey, { "id", 'c', 12, 0 } )
    aadd( akey, { "qty", 'n', 5, 0 } )
    aadd( akey, { "ponum", 'n', 6, 0 } )
    aadd( akey, { "from", 'c', BRANCH_CODE_LEN, 0 } )
    aadd( akey, { "coop_type", 'c', 1, 0 } )
    aadd( akey, { "cost_price", 'n', 10, 2 } )
    aadd( akey, { "sell_price", 'n', 10, 2 } )

    dbcreate( Oddvars( TEMPFILE ), aKey )
    if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, , 'trappe' )
     transfer->( dbseek( mtrannum ) )
     while transfer->number = mtrannum .and. !transfer->( eof() )
      if !transfer->processed
       Add_rec( 'trappe' )
       trappe->id := transfer->id
       trappe->qty := transfer->qty
       trappe->ponum := transfer->ponum
       trappe->from := transfer->from
       trappe->coop_type := transfer->coop_type
       trappe->cost_price := transfer->cost_price
       trappe->sell_price := transfer->sell_price
       trappe->( dbrunlock() )
      endif
      transfer->( dbskip() )
     enddo

     if trappe->( lastrec() ) = 0
      Error( 'This transfer appear to have processed already!', 12 )

     else   
      Bsave( 7, 0, 24, 79 )
      select trappe
      dbgotop()
      set relation to trappe->id into master,;
                   to trappe->from into branch

      trobj := TBrowseDB( 8, 2, 24-1, 79-1 ) 
      trobj:colorspec := if( iscolor(), TB_COLOR, setcolor() )
      trobj:HeadSep := HEADSEP
      trobj:ColSep := COLSEP

      trobj:addcolumn( tbcolumnNew( 'id', { || padr( idcheck( trappe->id ), 12 ) } ) )
      trobj:addcolumn( tbcolumnNew( 'Qty', { || padl( trappe->qty, 5 ) } ) )
      trobj:addcolumn( tbcolumnNew( 'Desc', { || left( master->desc, 35 ) } ) )
      trobj:addcolumn( tbcolumnNew( 'PO', { || padl( trappe->ponum, 6 ) } ) )
      trobj:addcolumn( tbcolumnNew( 'From', { || left( branch->name, 12 ) } ) )
    
      mkey := 0

      while mkey != K_ESC .and. mkey != K_END

       trobj:forcestable()
       mkey := inkey(0)

       if !navigate( trobj, mkey )

        do case
        case mkey == K_F10
         itemdisp( FALSE )
         select trappe

        case mkey == K_F1
         Build_help( { ;
                      { 'Del', 'Delete Item' },;
                      { 'F10', 'Display Desc' },;
                      { 'End', 'Process Transfer' } } )


        case mkey == K_DEL
         trappe->( dbdelete() )
         trappe->( dbgotop() )
         trobj:refreshall()

        endcase
       endif
      enddo
    
      if ( trappe->( lastrec() ) != 0 ) .and. IsReady( 12, 10, 'Process Transfer' ) 

       select trappe
       pack

       trappe->( dbgotop() )

       Add_rec( 'recvhead' )
       recvhead->supp_code := '!TRA'
       recvhead->invoice := 'TrI:' + Ns( mtrannum ) + '-' + trappe->from 
       recvhead->dreceived := Bvars( B_DATE )

       while !trappe->( eof() )

        select transfer
        transfer->( dbseek( mtrannum ) )

        locate for !transfer->processed .and. transfer->id = trappe->id ;
               while transfer->number = mtrannum

        if found()
         Rec_lock( 'transfer' )
         transfer->processed := TRUE
         transfer->( dbrunlock() )
        endif 
       
        Add_rec( 'recvline' )
        recvline->Indxkey := recvhead->supp_code + recvhead->invoice
        recvline->id := master->id
         
        recvline->qty := trappe->qty
        recvline->qty_inv := trappe->qty
        recvline->tranbranch := Bvars( B_BRANCH )
        recvline->tranqty := trappe->qty
        recvline->ponum := trappe->ponum
        recvline->over_write := FALSE
        recvline->operator := Oddvars( OPERCODE )
        recvline->cost_price := trappe->cost_price
        recvline->sell_price := trappe->sell_price
        recvline->( dbrunlock() )

        trappe->( dbskip() )

       enddo 

      endif

     endif

     trappe->( dbclosearea() )

    endif

   endif

  endif

    
#else    //  !Head Office

  mscr := Bsave( 09, 10, 13, 14 )
  @ 10,11 prompt 'A:'
  @ 11,11 prompt 'B:'
#ifndef __HARBOUR__
  @ 12,11 prompt chr( getdriv() ) + ':'
#endif
  menu to mdrive
  Brest( mscr )
#ifndef __HARBOUR__
  mdrive := if( mdrive=1,'A:',if(mdrive=2,'B:',chr(getdriv())+':'+Oddvars( SYSPATH ) +'bisac\') )
#endif
  bsave( 2, 08, 6, 72 )
  if mdrive = 'A:' .or. mdrive = 'B:'
   Center( 3, 'Insert transfer diskette into Drive ' + mdrive )
  endif
  if Isready( 5 )
   if file( mdrive + "update.dbf" )
    if Netuse( mdrive + "update", EXCLUSIVE, 10, NOALIAS, NEW )
     @ 4,12 say 'Number of Records in Update ' + Ns( lastrec() )
     @ 4,52 say 'Appended '
     mapp := 0
     while !update->( eof() )
      if !Codefind( update->id )
       Add_rec( 'master' )
       master->id := update->id
       master->desc := update->desc
       master->alt_desc := update->alt_desc
       master->brand := if( valtype( update->brand ) != 'U', update->brand, '' )
       master->department := update->department
       master->retail := update->retail
       master->sell_price := update->sell_price
       master->year := update->year
       master->sale_ret := update->sale_ret
       master->supp_code := update->supp_code
       master->supp_code2 := update->supp_code2
       master->supp_code3 := update->supp_code3
       master->binding := update->binding
       master->comments := update->comments
       master->( dbrunlock() )
       mapp++
       @ 4, 62 say Ns( mapp )
       
      endif
      update->( dbskip() )
     enddo
     update->( dbclosearea() )
    endif
   endif
   madrive := Directory( mdrive + "t_*.dbf" )
   mnumfiles := len( madrive )
   if mnumfiles = 0
    Error("Transfer files not found",6)
   else
    mtrannum := 0
    for x := 1 to mnumfiles
     mdbf := mdrive + madrive[ x, 1 ]
     if Netuse( mdbf, EXCLUSIVE, 10, "tfile", NEW )
      if tfile->to != Bvars( B_BRANCH )
       Error( 'Nominated transfer is to Branch ' + tfile->to, 12 )
      else
       Add_rec( 'recvhead' )
       recvhead->supp_code := '!TRA'
       recvhead->invoice := 'Tr:' + Ns( tfile->number )
       recvhead->dreceived := Bvars( B_DATE )
       while !tfile->( eof() )
        if !Codefind( tfile->id )
         Error( "id " + tfile->id + " not on database - not transfered", 10 )
        else
         Highlight( 5, 10, 'Desc transfered ', master->desc )
         
         Add_rec( 'recvline' )
         recvline->key := recvhead->supp_code + recvhead->invoice
         recvline->id := master->id
         
         recvline->qty := tfile->qty
         recvline->branch := Bvars( B_BRANCH )
         recvline->ponum := tfile->ponum
         recvline->over_write := FALSE
         recvline->inv_cost := tfile->cost_price
         recvline->retail := tfile->retail
         recvline->sell_price := tfile->sell_price
         recvline->( dbrunlock() )
/* 
         There is no need to update the Stock History file as it will be done in the Receiving Section
         A report of the incoming stock will be produced by the GRN 
*/
        endif
        Rec_lock( 'tfile' )
        tfile->( dbdelete() )
        mlastnum := tfile->number

        tfile->( dbskip() )

       enddo

       tfile->( dbclosearea() )
       Kill( mdbf )
      endif
     endif
    next
   endif
  endif

#endif

 case manswer = 4
  Heading('Purge old Transfer Details')
  mdate := Bvars( B_DATE ) - 60
  @ 11,27 say 'อออ>Enter Date for Purge' get mdate
  read
  if lastkey() != K_ESC
   select transfer
   bsave( 2, 08, 8, 72 )
   Center( 3, 'You are about to delete all transfers older than' )
   Center( 5, dtoc( mdate ) )

   if Isready( 7 )
    transfer->( dbgotop() )
    while !transfer->( eof() )
     if transfer->date <= mdate
      Highlight( 7, 10, 'Transfer No ', Ns( transfer->number ) )
      Del_rec( 'transfer' ,UNLOCK )
     endif
     transfer->( dbskip() )
    enddo
    trrqst->( dbgotop() )
    while !trrqst->( eof() )
     if trrqst->date <= mdate .and. trrqst->processed
      Highlight( 7, 10, 'Transfer Request No ', Ns( trrqst->number ) )
      Del_rec( 'trrqst' ,UNLOCK )
     endif
     trrqst->( dbskip() )
    enddo
   endif
  endif

 case manswer = 5
  aArray := {}
  aadd( aArray, { 'Exit', 'Return to Purchase Menu' } )
  aadd( aArray, { 'Transfers', 'Reprint Transfers details' } )
  prchoice := MenuGen( aArray, 11, 19, 'Reports')

  do case
  case prchoice = 2 
   Heading( "Reprint Transfer Details" )
   mnum := 0
   mscr := Bsave( 11, 30, 14, 65 )
   @ 12,31 say 'Transfer Number to Print' get mnum pict '999999'
   @ 13,31 say '-1 for all transfers'
   read

   if updated()

    select transfer
    set relation to transfer->id into master
    if mnum != -1 .and. !dbseek( mnum )
     Error( "Transfer number not on file", 12 )

    else
     Print_find( "report" )
     if Isready( 12 )

      Printcheck()
      Pitch17()
      farr := {}

      if mnum = -1 
       transfer->( dbgotop() )
      endif 

      aadd( farr, { 'idcheck( id )', 'id', 13, 0, FALSE } )
      aadd( farr, { 'left( master->desc, 40 )', 'Desc', 20, 0, FALSE } )
      aadd( farr, { 'left( master->alt_desc, 15 )', 'Author', 15, 0, FALSE } )
      aadd( farr, { 'date','Date', 8, 0, FALSE } )
      aadd( farr, { 'qty',' Qty;Trans', 5, 0, TRUE } )
      aadd( farr, { 'left( lookitup( "branch", to ), 8', 'To;Branch', 8, 0, FALSE } )
      aadd( farr, { 'from', 'From;Branch', 6, 0, FALSE } )
      aadd( farr, { 'master->cost_price','Cost;Price', 7, 2, FALSE } )
      aadd( farr, { 'transfer->qty * master->cost_price', 'Extended;Cost Price', 9, 2, TRUE } )
      if mnum = -1
       Reporter( farr, "All Transfers on File",'number', "'Number :'+Ns(number)", '', '', FALSE, '', '', 132 )
      else
       Reporter( farr, "Transfer #"+Ns( mnum )+" Reprint", '', '', '', '', FALSE, '', 'transfer->number = mnum', 132)
      endif
      Pitch10()
      Endprint()

     endif
     transfer->( dbclearrelation() )
    endif
   endif

  case prchoice = 3
   Heading( "Reprint Transfer Requests" )
   mnum := 0
   mscr := Bsave( 11, 30, 14, 65 )
   @ 12,31 say 'Request Number to Print' get mnum pict '999999'
   @ 13,31 say '-1 for all transfers'
   read
   if updated()
    select trrqst
    set relation to trrqst->id into master

    if mnum != -1 .and. !dbseek( mnum )
     Error( "Request number not on file", 12 )

    else
     Print_find( "report" )
     if Isready( 12 )

      Printcheck()
      Pitch17()
      farr := {}

      if mnum = -1 
       trrqst->( dbgotop() )
      endif 

      aadd( farr, { 'idcheck( id )', 'id', 13, 0, FALSE } )
      aadd( farr, { 'left( master->desc, 40 )', 'Desc', 20, 0, FALSE } )
      aadd( farr, { 'left( master->alt_desc, 15 )', 'Author', 15, 0, FALSE } )
      aadd( farr, { 'date','Date', 8, 0, FALSE } )
      aadd( farr, { 'qty',' Qty;Trans', 5, 0, FALSE } )
      aadd( farr, { 'left( lookitup( "branch", to ), 8)', 'To;Branch', 8, 0, FALSE } )
      aadd( farr, { 'from', 'From;Branch', 6, 0, FALSE } )
      aadd( farr, { 'master->cost_price','Cost;Price', 7, 2, FALSE } )
      aadd( farr, { 'trrqst->qty * master->cost_price', 'Extended;Cost Price', 9, 2, TRUE } )
      aadd( farr, { 'master->sell_price','Sell;Price', 7, 2, FALSE } )
      aadd( farr, { 'master->onhand','Onhand', 7, 2, FALSE } )
      aadd( farr, { 'master->department','Dept', 5, 0, FALSE } )
      aadd( farr, { 'master->semester','Seme', 5, 0, FALSE } )
      aadd( farr, { 'master->sales_code','Sales;Code', 5, 0, FALSE } )

      if mnum = -1

       mnum := Bvars( B_BRANCH )
       Reporter( farr, "All Transfers Request on File",'number',"'Number :'+Ns(number)",'','',FALSE,'!trrqst->processed.and.trrqst->from=mnum','', 132 )

      else

       Reporter( farr, "Transfer Request #"+Ns( mnum )+" Reprint",'','','','',FALSE,'!trrqst->processed','trrqst->number = mnum', 132 )

      endif

      Pitch10()

      Endprint()

     endif
     trrqst->( dbclearrelation() )
    endif
   endif

  endcase

 endcase

enddo
return
