/*

   Purchase Order Operations 
   
      Last change:  TG   27 Mar 2011    1:28 pm
*/
Procedure p_final

#include 'bpos.ch'

local mgo := FALSE, choice, getlist := {}, msupp := Oddvars( MSUPP )
local oldscr:=Box_Save(), aArray

Center(24,'Opening files for Purchase Order Finalisation')

if Netuse( "supplier" )
 if Netuse( "customer" )
  if Netuse( "draft_po" )
   if Netuse( "purhist" )
    if Master_use()
     if Netuse( "poline" )
      set relation to poline->id into master
      if Netuse( "pohead" )
       set relation to pohead->number into poline
       mgo := TRUE
      endif
     endif
    endif
   endif
  endif
 endif
endif

Line_clear(24)

while mgo
 Box_Restore( oldscr )
 Heading( 'Purchase Order Menu' )
 aArray := {}
 aadd( aArray, { 'Purchasing', 'Exit to Purchasing Menu', nil, nil } )
 aadd( aArray, { 'Final', 'Finalise Purchase Orders from Drafts', { || pofinal( @msupp ) }, nil } )
 aadd( aArray, { 'Enquire', 'Enquire/Cancel/Amend Po Details', { || Poenq( @msupp ) }, nil } )
 aadd( aArray, { 'Reports', 'Print Purchase Orders', { || PoPrint( @msupp ) }, nil } )
 choice := MenuGen( aArray, 04, 18, 'Final' )
 if choice < 2
  exit

 else
  Eval( aArray[ choice, 3 ] )

 endif

enddo
Oddvars( MSUPP, msupp )
close databases
return

*

procedure pofinal ( msupp )       /* Finalise Purchase Order Details */
local mfmonth, mtotal, mseq, temp_po, mponum, fo, mreserved, mposort
local oldscr := Box_Save(), getlist:={}, aArray, minstruct, sID
local mmonth, mscr, mkey, x, gallcode:=0, mteleorder
local mstruct  // DBF Structure File

Print_find("report")

while TRUE
 Box_Restore( oldscr )
 Heading('Post Purchase Orders')

 msupp := GetSuppCode( 8, 35 )

 if lastkey() = K_ESC
  exit
 else
  select draft_po
  draft_po->( ordsetfocus( BY_SUPP_BY_ID ))
  if !dbseek( msupp )
   Error( 'No Draft Po for this Supplier', 8 )
  else
   mkey := ''
   if msupp = '!RET'     // Authorised Returns Supplier
    if !CustFind( TRUE ) // only debtors allowed
     select draft_po
     ordsetfocus( BY_SUPPLIER )
     exit

    else
     mkey := customer->key

    endif

   endif

   Print_find( "report" )

   Box_Save( 2, 02, 12, 78 )
   Center( 3, 'You are about to prepare a Purchase Order for' )
   Syscolor( 3 )
   Center( 4, trim( LookItUp( "supplier", msupp ) ) )
   minstruct := space( 6 )
   mposort := LookItup( "supplier", msupp, "posort" )
   @ 4,77 say mposort
   syscolor( C_NORMAL )
   mfmonth := upper( left( cmonth( Bvars( B_DATE ) ), 3 ) )

   Heading( 'Select Po Number Sequence' )
   aArray := { Bvars( B_PO1NAME ), Bvars( B_PO2NAME ), Bvars( B_PO3NAME ), Bvars( B_PO4NAME ), Bvars( B_PO5NAME ) } 
   mscr := Box_Save( 07, 10, 13, 23 )
   mseq := Achoice( 08, 11, 12, 22, aArray )
   Box_Restore( mscr )

   if mseq = 0
    loop
   endif

   mponum := Sysinc( 'ponum' + Ns( mseq ), 'I', 1, 'pohead' )

   temp_po := mponum
   mreserved := FALSE
   mteleorder := !empty( Lookitup( 'supplier', msupp, 'teleorder' ) )

   @ 05,04 say 'Next Purchase Order No is' get temp_po pict PO_NUM_PICT valid( temp_po > 0 )
   @ 05,45 say 'Month to Commit Order' get mfmonth pict '!!!';
           valid( mfmonth $ 'JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC' )
   @ 06, 04 say 'PO Instructions' get minstruct pict '@!' valid( Dup_chk( minstruct, 'poinstru' ) )

#ifdef RESERVED_ORDERS
   @ 06,25 say 'Reserved Order' get mreserved pict 'y'
#endif

   if !empty( Lookitup( 'supplier', msupp, 'teleorder' ) )
    @ 06, 45 say 'Teleorder' get mteleorder pict 'y'
   endif

   read
   if Isready(11)
    mponum := temp_po
    Center(07,'-=< Totalling Draft Purchase Order >=-')
    mmonth := upper( substr( cmonth( Bvars( B_DATE ) ), 1, 3) )

    mstruct := {}
    aadd( mstruct, { 'id', 'c', ID_CODE_LEN, 0 } )
    aadd( mstruct, { 'qty', 'n', QTY_LEN, 0 } )
    aadd( mstruct, { 'comment', 'c', 30, 0 } )
    aadd( mstruct, { 'source', 'c', 2, 0 } )
    dbcreate( Oddvars( TEMPFILE ), mstruct )

    if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "final", NEW )
     set relation to final->id into master

     sID := ')(*)(*)('
     while draft_po->supp_code = msupp .and. !draft_po->( eof() )
      if !draft_po->hold
       if draft_po->id != sID
        locate for final->id = draft_po->id
        if !found()
         Add_rec( 'final' )
         final->id := draft_po->id
         final->qty := draft_po->qty
         final->comment := draft_po->comment
        else
         final->qty += draft_po->qty

        endif 
       endif
      endif
      draft_po->( dbskip() )
     enddo 

     if final->( lastrec() ) = 0
      Error( 'No Items to post - Have you released Holds?', 12 )

     else 
      do case
      case mposort = 'I'
       indx( "id", 'final' )
      case mposort = 'T'
       indx( "master->desc", 'final' )
      case mposort = 'A'
       indx( "master->alt_desc", 'final' )
      endcase

      mtotal := 0
// messagebox( "waiting" )
      final->( dbgotop() )
      while !final->( eof() ) .and. Pinwheel( NOINTERUPT )
       if final->qty > 0
         
        Rec_lock( 'master' )

        master->onorder += final->qty
        master->lastpo := mponum
        master->date_po := Bvars( B_DATE )
        master->lastqty := final->qty
        master->( dbrunlock() )  // FLUSH!!!!!!!!!!!

        Highlight( 08, 12, 'Posting Desc ', trim( substr( master->desc, 1, 20 ) ) )
        Add_rec( 'poline' )
        poline->number := mponum
        poline->id := final->id
        poline->qty := final->qty
        poline->qty_ord := final->qty
        poline->cost_price := master->cost_price
        poline->back_ord := FALSE
        poline->comment := final->comment
        poline->( dbrunlock() )

        mtotal += if( master->cost_price > 0,master->cost_price,master->sell_price*;
                    ( Lookitup( 'supplier', msupp, 'std_disc' ) * .01 ) ) *final->qty

       endif
       final->( dbskip() )

      enddo

      Add_rec( 'pohead' )
      pohead->number := mponum
      pohead->reserved := mreserved
      pohead->date_ord := Bvars( B_DATE )
      pohead->supp_code := msupp
      pohead->key := mkey
      pohead->teleorder := !mteleorder  // Important to have sense reversed here
      pohead->instruct := minstruct
//      pohead->branch := Bvars( B_BRANCH )
      pohead->( dbrunlock() )

      select purhist
      dbseek( msupp )
      locate for at('_',purhist->code) = 0 while purhist->code = msupp
      if !found()
       Add_rec()
       purhist->code := msupp

      endif
      Rec_lock()
      fo := fieldpos( mfmonth )
      fieldput( fo, fieldget( fo ) + mtotal )
      dbrunlock()
      Center(09,'-=< Clearing Draft Purchase Order >=-')

      draft_po->( dbseek( msupp ) )
      while draft_po->supp_code = msupp .and. !draft_po->( eof() )
       if !draft_po->hold
        Del_rec( 'draft_po', UNLOCK )
       endif
       draft_po->( dbskip() )
      enddo

      if Netuse( 'open2buy' )
       if lastrec() = 0
        Add_rec()

       endif
       Rec_lock()
       mtotal += eval( fieldblock( 'open_' + mfmonth + Ns( mseq ) ) )
       eval( fieldblock( 'open_' + mfmonth + Ns( mseq ) ) , mtotal ) 
       open2buy->( dbrunlock() )
       open2buy->( dbclosearea() )

      endif

      Center( 10,'-=< Printing Purchase Order >=-' )
      for x := 1 to Bvars( B_POQTY )
       Poform( mponum )

      next

     endif
     final->( orddestroy( 'final' ) )
     final->( dbclosearea() )

    endif
   endif
  endif
 endif
enddo
return

*

procedure poenq ( msupp )
/* Enquire / Modify / Delete PO Details */
local mpo:=0, mscr, okf10, pobrow, mship, mstat, mcomm, madd
local oldscr:=Box_Save(), x, mkey, mastcomm, c, menqrow
local mrec, mcost, mprice, mqty, getlist:={}, mreason, mdpo, mseq, mpokey
local mres, mcomment, mdate, mnum, sID, mtele, mconf, aHelpLines, minstruct
while TRUE
 Box_Restore( oldscr )
 Heading('Purchase Order Enquire')
 mscr := Box_Save( 6, 32, 9, 67 )
 @ 07,35 say 'Purchase Order Number' get mpo pict PO_NUM_PICT
 @ 08,35 say '<F10> for Supplier Enquire'
 okf10:=setkey( K_F10, { || Posuppenq( @mpo, @msupp ) } )  // Pass parameter by reference
 read
 setkey( K_F10, okf10 )
 Box_Restore( mscr )
 if lastkey() = K_ESC
  exit
 else
  pohead->( ordsetfocus( BY_NUMBER ) )
  if !pohead->( dbseek( mpo ) )
   Error( 'PO Number not on file', 12 )
  else
   cls
   select poline
   Heading( 'Enquire on PO #' + Ns( mpo ) )
   Po_enq_header()
   pobrow:=TBrowseDB( 05, 3, 24, 79 )
   for x := 1 to pobrow:rowcount
    @ x+6,0 say x pict '99'
   next
   pobrow:HeadSep := HEADSEP
   pobrow:colSep := COLSEP
   pobrow:goTopBlock := { || poline->( dbseek( mpo ) ) }
   pobrow:goBottomBlock  := { || jumptobott( mpo, 'poline' ) }
   pobrow:skipBlock:=Keyskipblock( { || poline->number }, mpo ) 
   c:=tbcolumnnew('Desc', { || substr( master->desc,1,20) } )
   c:colorblock:= { || if( poline->qty != poline->qty_ord, {5, 6}, {1, 2} ) }
   pobrow:Addcolumn( c )
 //  pobrow:Addcolumn(TBColumnnew( 'R',{ || if( empty( poline->abs_ptr ),' ', '*') } ) )
   pobrow:AddColumn(TBColumnNew( 'Qty Ord',{ || transform( poline->qty_ord,'9999') } ) )
   pobrow:AddColumn(TBColumnNew( 'B/O Qty',{ || transform( poline->qty , '9999')} ) )
   pobrow:AddColumn(TBColumnNew( 'Onhand',{ || transform( master->onhand , '9999')} ) )
   pobrow:AddColumn(TBColumnNew( 'Spec',{ || transform( master->special , '9999')} ) )
   pobrow:AddColumn(TbColumnNew( 'Status',{|| substr( LookItUp( "Status", master->status ), 1, 10 ) } ) )
   pobrow:AddColumn(TBColumnNew( 'Shipping Date',{ ||  poline->ship_date } ) )
   pobrow:AddColumn(TBColumnNew( 'PO Comments', { || poline->comment } ) )
   pobrow:freeze := 1
   pobrow:goTop()
   mkey := 0
   while mkey != K_ESC .and. mkey != K_END
    pobrow:forcestable()
    mkey := inkey(0)
    if !navigate(pobrow,mkey)
     do case
     case mkey >= 48 .and. mkey <= 57
      keyboard chr( mkey )
      mseq := 0
      menqrow := min( pobrow:ntop+val( chr( mkey ) ), 24- 4 )
      mscr := Box_Save( menqrow, 18, menqrow + 2, 37 )
      @ menqrow+1, 20 say 'Selecting No' get mseq pict '999' range 1, pobrow:rowcount
      read
      Box_Restore( mscr )
      if !updated()
       loop

      else
       Eval( pobrow:skipblock, mseq - pobrow:rowpos )  // This is pretty tricky shit it prevents selection past last data row
       Fpoadj( 'poline', 'pohead' )
       pobrow:refreshall()

      endif

     case mkey == K_F1
      aHelpLines := { ;
      { 'Ins','Add Line' } ,;
      { 'Del','Delete Line'} ,;
      { 'Ctrl-Enter','Adjust all Lines' },;
      { 'Enter','Adjust single Line' }, ;
      { 'F6','Supplier Details' }, ;
      { 'F7','Header Details' },;
      { 'F8','Value Order' },;
      { 'F9','Delete all Lines' },;
      { 'F10','Disp Desc Screen' },;
      { 'Alt-A','Line Report(*)' } }
      Build_help( aHelpLines )

     case mkey == K_ALT_A
      Abs_edit( 'poline' )
      pobrow:refreshcurrent()
      
     case mkey == K_F6
      supplier->( dbseek( pohead->supp_code ) )
      select supplier
      Supplier()
      select poline
      Po_enq_header()
      
     case mkey == K_F7
      mscr := Box_Save( 10, 10, 14, 60 )
      mtele := mconf := FALSE
      minstruct := pohead->instruct
//      @ 11, 12 say 'Teleordered flag is set to ' + if( pohead->teleorder, 'Yes', 'No' ) + ' change?' get mtele pict 'y'
      @ 12, 12 say '  Confirmed flag is set to ' + if( pohead->confirmed, 'Yes', 'No' ) + ' change?' get mconf pict 'y'
      @ 13, 12 say 'PO Instructions' get minstruct pict '@!' valid( dup_chk( minstruct, 'poinstru' ) )
      read
      if updated()
       Rec_lock( 'pohead' )
       if mtele
        pohead->teleorder := !pohead->teleorder
       endif
       if mconf
        pohead->confirmed := !pohead->confirmed
       endif    
       pohead->instruct := minstruct
       pohead->( dbrunlock() )
       Po_enq_header()
      endif
      Box_Restore( mscr )

     case mkey == K_F8
      mscr := Box_Save( 5, 10, 7, 70 )
      @ 6,12 say 'Valuing Order - Please Wait'
      mrec := recno()
      select poline
      poline->( dbseek( mpo ) )
      sum poline->qty*master->cost_price,poline->qty*master->sell_price,poline->qty ;
          to mcost,mprice,mqty while poline->number = mpo .and. !poline->( eof() )
      Box_Restore( mscr )
      goto mrec
      mscr := Box_Save( 5, 10, 11,70 )
      Highlight( 6, 12, ' Value at cost', Ns( mcost,9,2 ) )
      Highlight( 8, 12, ' Value at sell', Ns( mprice,9,2 ) )
      Highlight( 10, 12, 'Items on Order', Ns( mqty,9 ) )
      Error('',12)
      Box_Restore( mscr )

     case mkey == K_CTRL_RET
      Heading( 'Adjust Po #' + Ns( mpo ) )
      mscr:=Box_Save(08,02,14,77)
      Center( 09,'About to adjust shipping dates etc on all po items' )
      Center( 10,'Leave the fields empty for no change to files' )
      Center( 13,'Warning - Adjusting Master File comments will overwrite existing Comments')
      mship := ctod('  /  /  ')
      mstat := '   '
      mcomm := space( 20 )
      mastcomm := space( 30 )
      @ 11,10 say 'Shipping date' get mship
      @ 11,35 say 'Po Comments' get mcomm
      @ 12,10 say 'Status' get mstat pict '@!' valid( mstat = '   ' .or. Dup_chk( mstat , 'Status' ) )
      @ 12,22 say 'Master Comments' get mastcomm
      read
      if updated()
       if Isready(14)
        
        poline->( dbseek( mpo ) )
        while !poline->( eof() ) .and. poline->number = mpo

         @ 13,10 say substr(master->desc,1,30)

         Rec_lock( 'poline' )
         poline->ship_date := if( empty(mship),poline->ship_date,mship )
         poline->comment := if( empty(mcomm),poline->comment,mcomm )
         poline->( dbrunlock() )

         Rec_lock( 'master' )
         master->status := if( !empty( mstat ), mstat, master->status )
         master->comments := if( !empty( mastcomm ), mastcomm, master->comments )
         master->( dbrunlock() )

         poline->( dbskip() )
         
        enddo

        pohead->( dbseek( mpo ) )
        SysAudit( 'AdjPOAll' + Ns( mpo ) )
       endif
      endif
      Box_Restore( mscr )
      pobrow:refreshall()

     case mkey == K_ENTER
      Fpoadj( 'poline', 'pohead' )

      pobrow:refreshcurrent()
      pobrow:down()
      
     case mkey == K_INS
      mres := pohead->reserved
      mpokey := pohead->key
      mdate := pohead->date_ord
      mnum := pohead->number
      msupp := pohead->supp_code
      sID := space( ID_ENQ_LEN )
      mscr := Box_Save( 5, 10, 7, 70 )
      @ 6, 12 say 'Item to add to Po' get sID pict '@!'
      read
      Box_Restore( mscr )
      if updated()

       if !CodeFind( sID )
        Error( 'Item not on file' , 12 )

       else
        mqty := 0
        mcomment := space( 80 )
        mscr := Box_Save( 5, 10, 9, 70 )
        Highlight( 6, 12, 'Desc', substr( master->desc, 1, 30 ) )
        @ 7, 12 say 'Qty to Order' get mqty pict '9999'
        @ 8, 12 say 'Comment on Po' get mcomment pict '@S40'
        read
        if mqty > 0

         Add_rec( 'poline' )
         poline->number := mnum
         poline->id := master->id
         poline->qty := mqty
         poline->qty_ord := mqty
         poline->cost_price := master->cost_price
         poline->back_ord := FALSE
         poline->comment := mcomment
         poline->( dbrunlock() )

         Rec_lock('master')
         master->onorder += mqty
         master->lastpo := mpo
         master->date_po := Bvars( B_DATE )
         master->( dbrunlock() )

         select poline
         pobrow:refreshall()

        endif
        Box_Restore( mscr )

       endif
      endif

     case mkey == K_DEL
      mscr := Box_Save( 19, 2, 23, 77 )
      mdpo := FALSE
      if Isready( 20, 05, 'Delete ÍÍÍ¯ ' + trim( master->desc )  )
       Rec_lock( 'master' )
       mcomm := trim(master->comments)+space(30-len(trim(master->comments)))
       @ 21,05 say 'Reason' get mcomm
       @ 21,50 say 'Status' get master->status pict '@!' valid( Dup_chk( master->status , "status" ) )
       @ 22,05 say 'Add desc to draft purchase order' get mdpo pict 'y'
       read

       if mdpo
        madd := TRUE
        select draft_po
        ordsetfocus( BY_ID )
        seek poline->id
        locate for draft_po->supp_code = pohead->supp_code ;
               .and. draft_po->source = 'Bo' ;
               while draft_po->id = poline->id

        if found()
         Rec_lock()
         draft_po->qty += poline->qty

        else
         Add_rec()
         draft_po->id := poline->id 
         draft_po->supp_code := pohead->supp_code 
         draft_po->qty := poline->qty 
         draft_po->date_ord := Bvars( B_DATE ) 
         draft_po->special := FALSE 
         draft_po->source := 'Bo' 
         draft_po->skey := master->alt_desc
         draft_po->department := master->department
         draft_po->hold := Bvars( B_DEPTORDR )

        endif

        Supp_swap( nil, msupp )
        dbrunlock()

       endif

       master->onorder -= poline->qty
       master->comments := mcomm

       master->( dbrunlock() )

       Abs_delete( 'poline' )

       select poline
       Del_rec( ,UNLOCK )

       eval( pobrow:skipblock , -1 )
       pobrow:refreshall()

      endif
      Box_Restore( mscr )
     case mkey == K_F10
      select master
      itemdisp( FALSE )
      select poline

     case mkey == K_F9
      mscr := Box_Save( 3, 3, 12, 77, C_YELLOW )
      pohead->( dbseek( mpo ) )
      Center( 4, 'Purchase Order to =>' + LookItUp( "supplier" , pohead->supp_code ) )

      if Isready(  5, 10, 'Ok to delete all of PO No ' + Ns( mpo ) )
       madd := FALSE
       @ 6,10 say 'Add descs back into Draft Purchase Orders' get madd pict 'y'
       read

       mreason := space( len( master->comments ) )
       @ 7,10 say 'Reason for Deletion of Order' get mreason
       read

       draft_po->( ordsetfocus( BY_ID ) ) 
       poline->( dbseek( mpo ) )
       while poline->number = mpo .and. !poline->( eof() )
        @ 9,10 say padr( 'Deleting Desc < ' + trim( master->desc ) + ' >', 65 )
        if madd
         select draft_po
         dbseek( poline->id )
         locate for ( draft_po->supp_code = pohead->supp_code .and. draft_po->source = 'Bo' );
                while draft_po->id = poline->id
         if found()
          Rec_lock( 'draft_po' )
          draft_po->qty += poline->qty

         else
          Add_rec( 'draft_po' )
          draft_po->id := poline->id 
          draft_po->supp_code := pohead->supp_code 
          draft_po->qty := poline->qty 
          draft_po->date_ord := Bvars( B_DATE ) 
          draft_po->special := FALSE 
          draft_po->source := 'Bo' 
          draft_po->skey := master->alt_desc
          draft_po->department := master->department
          draft_po->hold := Bvars( B_DEPTORDR )

         endif
         draft_po->( dbrunlock() )

        endif

        Rec_lock('master')
        master->onorder -= poline->qty
        master->comments := if( empty(mreason), master->comments, trim( master->comments + ' ' + mreason ) )
        master->( dbrunlock() )

        Del_rec( 'poline', UNLOCK )
        Abs_delete( 'poline' )

        poline->( dbskip() )

       enddo

       Del_rec( 'pohead', UNLOCK )
       SysAudit( 'PODelAll' + Ns( mpo ) )
       keyboard chr( K_ESC )
       pobrow:refreshall()
      endif
      Box_Restore( mscr )
     endcase
    endif
   enddo
  endif
 endif
enddo
return

*

Function Po_Enq_header()
/* Display the Supplier details on Enquiry screen */
@ 01, 00 clear to 04, 79
Highlight( 1, 01, 'Supplier', LookItup( "supplier", pohead->supp_code ) )
Highlight( 2, 01, 'Comments', LookItup( "supplier", pohead->supp_code, 'comm1' ) )
Highlight( 3, 01, '        ', LookItup( "supplier", pohead->supp_code, 'comm2' ) )
Highlight( 1, 46, 'Date of Order', dtoc( pohead->date_ord ) )
Highlight( 2, 46, 'Phone #', LookItup( 'supplier', pohead->supp_code, 'phone' ) )
Highlight( 3, 46, 'Acc #', LookItup( 'supplier', pohead->supp_code, 'account' ) )
Highlight( 2, 69, '', if( pohead->teleorder, 'TeOrdered', '' ) )
Highlight( 3, 69, '', if( pohead->confirmed, 'Confirmed', '' ) )
Highlight( 4, 01, 'PO Instr', left( lookitup( 'poinstru', pohead->instruct ), 30 ) ) 
return nil

*


procedure fpoadj ( lalias, halias ) 

/* 

   Update a line Item in a Po
   this proc may be called from poinq in saleinq
   lalias is the poline alias, halias is the pohead alias 

*/

local mscr:=Box_Save( 08, 02, 13, 77 , C_GREY ), getlist:={}
local mcomments := master->comments, mstatus := master->status
local mdate := ( lalias )->ship_date, mpocomm := ( lalias )->comment
local mqty := ( lalias)->qty, oldqty
local mres := ( halias )->reserved, oldsel := select(), okf10
oldqty := mqty
Highlight( 09, 04, 'Desc', master->desc )

@ 10,04 say 'Master Comments' get mcomments
@ 10,55 say 'Status' get mstatus pict '@!' valid( Dup_Chk( mstatus , "Status" ) )
@ 11,04 say 'Po Comments' get mpocomm pict '@S40'
@ 12,06 say ' Qty on order' get mqty when Secure( X_EDITFILES ) pict '99999'
@ 12,35 say 'Reserved' get mres pict 'y'
@ 12,50 say 'Shipping Date' get mdate
okf10 := setkey( K_F10, { || itemdisp( FALSE ) } )
read
setkey( K_F10, okf10 )

if updated()

 Rec_lock( 'master' )
 master->comments := mcomments
 master->status := mstatus
 if mqty != oldqty
  master->onorder -= ( oldqty - mqty )
 endif
 master->( dbrunlock() )

 Rec_lock( lalias )
 ( lalias )->ship_date := mdate
 ( lalias )->comment := mpocomm
 if mqty != oldqty
  ( lalias )->qty := mqty
 endif
 ( lalias )->( dbrunlock() )

 Rec_lock( halias )
 ( halias )->reserved := mres
 ( halias )->( dbrunlock() )

endif
select ( oldsel )
Box_Restore( mscr )
return

*

procedure poprint ( msupp )

local mpo, choice, getlist:={}, msummary, mnum, tscr
local mcost, msell, mqty, mtcost, mtsell, mtqty, apo, indisp, mscr, aHelpLines
local element, mkey, mtname, aArray, oldscr:=Box_Save(), farr

memvar mdate, mrpthead, mbackord, msuppx

while TRUE

 Box_Restore( oldscr )

 Heading( 'Purchase Order Print Menu' )
 Print_find( 'report' )
 aArray := {}
 aadd( aArray, { 'Return', 'Return to Purchase Menu' } )
 aadd( aArray, { 'PO Number', 'Print One Po Number' } )
 aadd( aArray, { 'All', 'Print Orders' } )
 aadd( aArray, { 'BackOrder', 'Print Backorders' } )
 aadd( aArray, { 'Value', 'Value Orders Outstanding' } )
 choice := MenuGen( aArray, 08, 19, 'Reports' )

 farr := {}
 if choice = 3 .or. choice = 4
  aadd( farr,{'pohead->supp_code','Supp;Code',SUPP_CODE_LEN,0,FALSE})
 endif 
 aadd( farr,{'idcheck(poline->id)','id',13,0,FALSE})
 aadd( farr,{'left(master->desc,20)','Desc',20,0,FALSE})
 aadd( farr,{'left(master->alt_desc,15)','Alt Desc',15,0,FALSE})
 aadd( farr,{'pohead->date_ord','Date of;Order',8,0,FALSE})
 if choice = 5 .or. choice = 6
  aadd( farr,{'poline->date_bord','Date of;Back Ord',8,0,FALSE})
  aadd( farr,{'poline->qty_ord','Qty;Order',5,0,TRUE})
 endif
 if choice = 3 .or. choice = 4
  aadd( farr,{'poline->qty','Qty;Ord.',5,0,FALSE})
 endif
 if choice = 5 .or. choice = 6
  aadd( farr,{'poline->qty',"Qty on ;B'Order",7,0,TRUE})
 endif
 aadd( farr,{'master->cost_price','Last;Inv Cost',8,2,FALSE})
 if choice = 5 .or. choice = 6
  aadd( farr,{'master->cost_price*(poline->qty_ord-poline->qty)','Inv Cost;Extended',10,2,TRUE})
 else 
  aadd( farr,{'poline->qty*master->cost_price','Inv Cost;Extended',8,2,TRUE})
 endif 
 aadd( farr,{'master->retail','Current; R.R.P.',7,2,FALSE})
 if choice = 5 .or. choice = 6
  aadd( farr,{'master->retail*(poline->qty_ord-poline->qty)','Current;RRP Ext',10,2,TRUE})
 else 
  aadd( farr,{'master->sell_price','Sell;Price',7,2,TRUE})
  aadd( farr,{'poline->comment','Purchase Order;Comments',15,0,FALSE})
 endif

 do case
 case choice < 2
  exit
  
 case choice = 2
  Heading('Print a Single Purchase Order')
  mpo := 0
  Box_Save( 09, 30, 11, 70 )
  @ 10,31 say 'Purchase Order Number' get mpo pict PO_NUM_PICT
  read
  if updated()
   select pohead
   ordsetfocus( BY_NUMBER )
   if !pohead->( dbseek( mpo ) )
    Error( 'PO Number not on file' )
   else
    Box_Save( 17, 10, 19, 70 )
    HighLight( 18, 12, 'Supplier Name ', LookItUp( "supplier", pohead->supp_code) )
    select pohead
    if Isready( 12, 46 )
     Poform( mpo )
    endif
   endif
  endif

 case choice = 3 .or. choice < 4
  mbackord := ( choice = 5 .or. choice = 6 )
  Heading( 'Purchase Orders Print' )
  msupp := GetSuppCode( 08, 45, ALLOW_WILD )
  mdate := Bvars( B_DATE )
  Box_Save( 10, 45, 12, 68 )
  @ 11,47 say 'Cutoff Date' get mdate
  read
  msummary := Isready( 13, 48, 'Summary Format' )
  if Isready( 15, 48 )

   select pohead
   ordsetfocus( BY_NUMBER )
   set relation to pohead->supp_code into supplier
   select poline
   ordsetfocus( BY_NUMBER )
   set relation to poline->id into master,;
                   poline->number into pohead

   indx( 'pohead->supp_code', 'posupp' )

   if msupp = '*'
    dbgotop()

   else
    dbseek( msupp )

   endif 

   msuppx := msupp
   mrpthead := 'All Purchase' + if( mbackord, 'Back', '' ) + ' Orders Older than ' + dtoc( mdate ) + ' for ' ;
    + if( msupp = '*', 'All Suppliers', Lookitup( "supplier", msupp ) )
    

   Reporter(farr,mrpthead, 'pohead->supp_code','"Supplier -> "+pohead->supp_code',;
                 'number','"Purchase Order No -> "+str(number)',msummary,;
                 '( pohead->date_ord < mdate + 1 ) .and. if( !mbackord, .t., back_ord )', ;
                 'if( msuppx = "*", .t., pohead->supp_code = msuppx)' )

   Endprint()
   if msupp != '*'
    orddestroy( 'posupp' )
   endif 

   poline->( ordsetfocus( BY_NUMBER ) )
   poline->( orddestroy( 'posupp' ) )
   poline->( dbclearrelation() )
   poline->( dbsetrelation( 'master', { || poline->id } ) )
   pohead->( dbsetrelation( 'poline', { || pohead->number } ) )

  endif

 case choice = 5
  select pohead
  ordsetfocus( BY_NUMBER )
  set relation to pohead->supp_code into supplier
  select poline
  ordsetfocus( BY_NUMBER )
  set relation to poline->id into master,;
                  poline->number into pohead

  poline->( dbgotop() )

  apo := {}
  mnum := poline->number
  mtcost := mtsell := mtqty := 0

  while !poline->( eof() )

   select poline
   sum master->cost_price*poline->qty, master->sell_price*poline->qty, poline->qty ;
       to mcost, msell, mqty ;
       while poline->number = mnum .and. Pinwheel()

   pohead->( dbseek( mnum ) )
   mtname := trim( lookitup( 'supplier', pohead->supp_code ) ) + ' ' + pohead->supp_code

   aadd( apo, { mtname, mcost, msell, mqty, mnum, pohead->supp_code } )

   mnum := poline->number

   mtcost += mcost
   mtsell += msell
   mtqty += mqty

  enddo 

  poline->( dbclearrelation() )
  poline->( dbsetrelation( 'master', { || poline->id } ) )
  pohead->( dbsetrelation( 'poline', { || pohead->number } ) )

  Heading("Display Order Totals")
  mscr:=Box_Save( 04, 02, 22, 75 )
  indisp:=TBrowseNew( 05, 03, 21, 74 )
  indisp:HeadSep:=HEADSEP
  indisp:ColSep:=COLSEP
  element := 1
  indisp:goTopBlock:={ || element:=1 }
  indisp:goBottomBlock:={ || element:= len( apo ) }
  indisp:skipBlock:={ |n| ArraySkip( len( apo ), @element, n ) }
  indisp:AddColumn(TBColumnNew( 'Number', { || transform( apo[ element,5 ],"999999") } ) )
  indisp:AddColumn(TBColumnNew( 'Supplier', { || padr( apo[ element, 1 ], 20 ) } ) )
  indisp:AddColumn(TBColumnNew( 'Value@Cost', { || transform( apo[ element,2 ],"999,999") } ) )
  indisp:AddColumn(TBColumnNew( 'Value@Sell', { || transform( apo[ element,3 ],"999,999") } ) )
  indisp:AddColumn(TBColumnNew( 'Qty', { || transform( apo[ element,4 ],"999,999") } ) )
  mkey:=0
  while mkey != K_ESC
   indisp:forcestable()
   mkey:=inkey(0)
   if !Navigate( indisp, mkey )
    do case
    case mkey == K_F1
     aHelpLines := { { 'F8', 'Total all Orders' },;
                  { 'Enter', 'Examine Order' },;
                  { 'Esc', 'Exit from Function' } }
     Build_help( aHelpLines )             
    case mkey == K_F8
     mscr := Box_Save( 3, 10, 10, 70 )
     Highlight( 4, 12, 'Totals at cost', Ns( mtcost, 10, 2 ) )
     Highlight( 6, 12, 'Totals at sell', Ns( mtsell, 10, 2 ) )
     Highlight( 8, 12, '  Totals items', Ns(  mtqty, 10, 2 ) )
     Error( '', 12 )
     Box_Restore( mscr )
    case mkey == K_ENTER
     tscr := Box_Save()
     keyboard Ns( apo[ element, 5 ] ) + CR
     Poenq( apo[ element, 6 ] )
     Box_Restore( tscr )
    endcase
   endif
  enddo 
 endcase
enddo
return

procedure Posuppenq ( mpo, msupp )
/* Browse a list of PO's attached to a supplier */
local mscr := Box_Save( 04, 25, 06, 55 ), getlist:={}, oldord
local pobrow, mkey
@ 05,27 say 'Enter Supplier Code' get msupp pict '@!K'
read
Box_Restore( mscr )
if empty( msupp ) //!updated()
 return
else
 select pohead
 oldord := pohead->( ordsetfocus( BY_SUPPLIER ) )
 pohead->( dbseek( msupp ) )
 mscr := Box_Save( 01, 59, 24-1, 79-1 )
 pobrow:=TBrowseDB( 02, 60, 24-2, 79-2 )
 pobrow:HeadSep := HEADSEP
 pobrow:colSep := COLSEP
 pobrow:goTopBlock := { || pohead->( dbseek( msupp ) ) }
 pobrow:goBottomBlock := { || jumptobott( msupp, 'pohead' ) }
 pobrow:skipBlock := Keyskipblock( { || pohead->supp_code }, msupp )
 pobrow:AddColumn( TBColumnNew('Ord #',{ ||  pohead->number } ) )
 pobrow:AddColumn( TBColumnNew('Ord Date', { || pohead->date_ord } ) )
 pobrow:goTop()
 mkey := 0
 while mkey != K_ESC .and. mkey != K_END
  pobrow:forcestable()
  mkey := inkey(0)
  if !navigate( pobrow, mkey )
   if mkey == K_ENTER
    mpo := pohead->number
    exit
   endif
  endif   
 enddo
 Box_Restore( mscr )
 pohead->( ordsetfocus( oldord ) )
endif
return

