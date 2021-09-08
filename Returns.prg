/*

 Program Returns. All returns processing functions

      Last change:  TG   26 Jan 2011   11:16 am
*/
static mcount := 0

Procedure P_Returns

#include "bpos.ch"

local mgo := NO, choice, oldscr:=Box_Save(), msupp:=Oddvars( MSUPP ), aArray

Center(24,'Opening files for Returns List Maintenance')
if Netuse( "stkhist" )
 if Netuse( "cretrans" )
  if Netuse( "deptmove" )
   if Netuse( "purhist" )
    if Netuse( "ytdsales" )
     if Master_use()
      if Netuse( "supplier" )
       if Netuse( "RetHead" )
        if Netuse( "RetLine" )
         if Netuse( "DraftRet" )
          set relation to DraftRet->id into master, ;
                       to DraftRet->supp_code into supplier
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
line_clear(24)

*

while mgo

 Box_Restore( oldscr )
 Heading( 'Returns Lists Menu' )
 aArray := {}
 aadd( aArray, { 'Exit', 'Return to Purchasing Menu',  , nil } )
 aadd( aArray, { 'Generate', 'Create Suggested Returns Listing', { || Retgen( @msupp ) }, nil } )
 aadd( aArray, { 'Add/Change', 'Edit/Add/Delete Returns Lists', { || Retedit( @msupp ) }, nil } )
 aadd( aArray, { 'Reports', 'Print Returns Lists', { || Retprint( @msupp ) }, nil } )
 aadd( aArray, { 'Post', 'Commit Returns / Produce credit claim', { || Retpost( @msupp ) }, nil } )
 aadd( aArray, { 'Inquire', 'Check details of Existing Credit Claims', { || RetEnq( @msupp ) }, nil } )
 choice := MenuGen( aArray, 06, 18, 'Returns' )

 if choice < 2
  exit
 else
  if Secure( aArray[ choice, 4 ] )
   Eval( aArray[ choice, 3 ] )
  endif
 endif

enddo
Oddvars( MSUPP, msupp )
dbcloseall() 

return

*

procedure retgen ( msupp )

local msupp1, allsupps, mmindays := 90, mmaxdays := 9999, msaledays := 9999, getlist:={}, mscr, mtype := '* '
local mflag:=FALSE, mhold:=FALSE, mmindate, mmaxdate, msale, supparr:={}, x, impr_supp := 'S', mdesc

Heading('Returns Selection Criteria')

Mscr := Box_Save( 7, 30, 9, 73 )
@ 8, 32 say 'Generate By Brand or Supplier (I/S)' get impr_supp pict '!' valid impr_supp $ 'IS'
read
Box_Restore( mscr )
if lastkey() = K_ESC
 return
endif
mdesc := if( impr_supp = 'I', 'Brand', 'Supplier' )
while TRUE
 mscr := Box_Save( 15, 05, 17, 35 )
 msupp1 := space( if( impr_supp = 'I', len( master->brand ), SUPP_CODE_LEN ) )
 @ 16, 07 say mdesc + ' Code' get msupp1 pict '@!' ;
          valid msupp1 = '*' .or. empty( msupp1 ) .or. dup_chk( msupp1, mdesc ) 
 read
 Box_Restore( mscr )
 allsupps := ( msupp1 = '*' )
 if empty( msupp1 ) .or. allsupps
  exit

 else
  if ascan( supparr, { | aval | aval[ 1 ] = msupp1 } ) != 0
   Error( mdesc + ' Code already on list', 12 )

  else
   aadd( supparr, { msupp1, if( msupp!='*', Lookitup( mdesc, msupp1 ), 'All ' + mdesc + 's' ) } )
   keyboard K_ESC
   Box_Save( 5, 50, 6 + min( len( supparr ), 18 ), 76 )
   for x := 1 to len( supparr )
    if x > 18
     scroll( 6, 51, 23, 75, 1 )

    endif
    @ 5 + min( x, 18 ), 51 say left( supparr[ x, 2 ], 25 ) 

   next

  endif

 endif

enddo

if len( supparr ) = 0 .and. !allsupps
 return

else

 Box_Save( 2, 07, 13, 72 )
 @ 03,10 say '           Number of Days since Last Sale' get msaledays pict '9999'
 @ 05,10 say 'Minimum Number of Days since last Invoice' get mmindays pict '999'
 @ 06,10 say 'Maximum Number of Days since last Invoice' get mmaxdays pict '9999'
 @ 08,10 say '         Ignore Sale or Return Flag (Y/N)' get mflag pict 'Y'
 @ 10,10 say '            Delete existing "Hold" ' + ITEM_DESC + '' get mhold pict 'Y'

 read
 if Isready(12)
  Box_Save( 15, 08, 18, 72 )
  Center( 16, '-=< Returns List Generation in progress >=-' )
  select DraftRet
  if Netuse( "DraftRet", EXCLUSIVE, 10, NOALIAS, OLD ) 
   if allsupps
    delete for ( !DraftRet->hold .or. mhold )
   else
    delete for if( impr_supp = 'I' ,ascan( supparr, { | aval | aval[ 1 ] = DraftRet->brand } ) != 0, ;
                                    ascan( supparr, { | aval | aval[ 1 ] = DraftRet->supp_code } ) != 0  );
                                    .and. ( !DraftRet->hold .or. mhold )
   endif
   pack
   Netuse( "DraftRet", SHARED, 10, NOALIAS, OLD )
   select master
   ordsetfocus( NATURAL )
   set relation to master->id into stkhist,;
                to master->supp_code into supplier
   master->( dbgotop() )
   mmindate := Bvars( B_DATE ) - mmindays
   mmaxdate := Bvars( B_DATE ) - mmaxdays
   msale := Bvars( B_DATE ) - msaledays
   Highlight( 17, 10, 'Total Records to Process ', Ns( lastrec() ) )
   @ 17,50 say 'Record #'

   while !master->( eof() ) .and. Pinwheel()
    @ 17,60 say master->( recno() )
    if ( ( !empty( master->dlastrecv ) .and. master->dlastrecv < mmindate .and. master->dlastrecv > mmaxdate );
          .or. ( msaledays != 0 .and. ( master->dsale < msale .and. master->dlastrecv < msale ) ) ;
       );
        .and. ( mtype = '*' .or. master->sales_code = mtype ) ;
        .and. ( !master->sale_ret .or. mflag ) .and. master->onhand > 0 ;
        .and. ( allsupps .or. ;
                if( impr_supp = 'I', ;
                   ascan( supparr, { | aval | aval[ 1 ] = master->brand } ) != 0, ;
                   ascan( supparr, { | aval | aval[ 1 ] = master->supp_code } ) != 0  ;
                  );
               )

     Add_rec( 'DraftRet' )
     DraftRet->id := master->id
     DraftRet->qty := master->onhand
     DraftRet->supp_code := master->supp_code 
     DraftRet->brand := master->brand
     DraftRet->department := master->department 
     DraftRet->date := Bvars( B_DATE ) 
     DraftRet->rrp := master->retail 
     DraftRet->cost := master->cost_price 
     DraftRet->desc := master->desc 
     DraftRet->alt_desc := master->alt_desc
     DraftRet->hold := TRUE 
     DraftRet->invmacro := '1' 
     DraftRet->stkhistoff := StkHistFind( master->id ) 
     DraftRet->skey := master->desc


     DraftRet->reference := stkhist->reference
     DraftRet->invdate := stkhist->date

     if ( master->dlastrecv < mmindate .and. master->dlastrecv > mmaxdate ;
         .and. !empty(master->dlastrecv) )
      DraftRet->type := 'I'
     else
      DraftRet->type := 'S'
     endif

     DraftRet->( dbrunlock() )

    endif
    master->( dbskip() )

   enddo

   if lastkey() = K_ESC
    Error( 'Escape was Struck - Regeneration may not be Complete', 12 )

   endif

   select master
   ordsetfocus( BY_ID )
   set relation to

   select DraftRet
   set relation to DraftRet->id into master,;
                to DraftRet->supp_code into supplier

  endif

 endif

endif
return

*

procedure retedit ( msupp )
local mscr,c,mkey,dpbrow,getlist:={},mmonth,mreq,x
local sID,mret:=0,mmonret:=0,mlen:=0,suppname,mseq
local oldscr := Box_Save()
local suppcom1
local suppcom2
local aHelpLines
local okf10  // Function Key hold
local aArray
local mfilter
local mfiltchoice
local mfiltertext

while TRUE
 Box_Restore( oldscr )
 Heading('Edit Returns Lists')

 okf10 := setkey( K_F10 , {|| All_returns( msupp ) } )
 msupp := GetSuppCode( 9, 30, ALLOW_WILD, 'F10 for Returns List' )
 setkey( K_F10, okf10 )

 if lastkey() = K_ESC
  exit

 else

  if msupp != '*'
   select supplier
   seek msupp
   suppname := trim( supplier->name )
   suppcom1 := supplier->comm1
   suppcom2 := supplier->comm2

  endif

  if !found() .and. msupp != '*'
   Error( 'Supplier Code not on file', 12 )

  else
   mmonth := left( upper( cmonth( Bvars( B_DATE ) ) ), 3 )
   if msupp != '*'
    select purhist
    if dbseek( trim(msupp) + '_RET' )
     mret := abs( purhist->jan+purhist->feb+purhist->mar+purhist->apr+purhist->may;
             +purhist->jun+purhist->jul+purhist->aug+purhist->sep+purhist->oct;
             +purhist->nov+purhist->dec )
     mmonret := abs( fieldget( fieldpos ( mmonth ) ) )

    endif
    select DraftRet
    seek msupp

   endif

   if msupp = '*'
    if lastrec() = 0
     Error('No Records to Process',12)
     loop

    endif

   endif

   cls
   Heading('Edit Returns List')

   if msupp != '*'
    Highlight( 01, 01, 'Supplier', suppname )
    Highlight( 02, 01, 'Comments', suppcom1 )
    Highlight( 03, 01, '        ', suppcom2 )
    Highlight( 02, 46, 'Returns this month $', Ns( mmonret ) )
    Highlight( 03, 46, 'Returns this year  $', Ns( mret ) )
    for x = 1 to 24-5
     @ x+5,0 say row()-5 pict '99'

    next
    dpbrow := TBrowseDB( 04, 3, 24, 79 )

   else
    dpbrow := TBrowseDB( 01, 1, 24, 79 )

   endif

   dpbrow:HeadSep := HEADSEP
   dpbrow:ColSep := COLSEP
   if msupp != '*'
    dpbrow:goTopBlock := { || dbseek( msupp ) }
    dpbrow:goBottomBlock  := { || jumptobott( msupp ) }
    dpbrow:skipblock := Keyskipblock( { || DraftRet->supp_code }, msupp )

   else
    dpbrow:addColumn( tbcolumnnew('Supp', { || DraftRet->supp_code } ) )

   endif
   dpbrow:addColumn( tbcolumnnew('Desc', { || left( master->desc, 30 ) } ) )
   c:=tbcolumnnew('H', { || if( DraftRet->hold,'*',' ' ) } )
   c:colorblock:= { || if( DraftRet->hold, {5, 6}, {1, 2} ) }
   dpbrow:addcolumn( c )
   dpbrow:addColumn( tbcolumnnew( 'Ori', { || DraftRet->type } ) )

   dpbrow:addColumn( tbcolumnnew( 'Qty', { || transform( DraftRet->qty, '9999' ) } ) )
   dpbrow:addColumn( tbcolumnnew( 'R.R.P', { || transform( master->retail ,'999.99') } ) )
   dpbrow:addColumn( tbcolumnnew( 'Onhand', { || transform( master->onhand, '9999')} ) )
   dpbrow:addColumn( tbcolumnnew( 'S/R', { || transform( master->sale_ret, 'Y' ) } ) )
   dpbrow:addColumn( tbcolumnnew( 'Dept', { || master->department } ) )
   dpbrow:addColumn( tbcolumnnew( 'Master File Comments', { || master->comments } ) )
   dpbrow:freeze := if( msupp = "*", 4, 3 )
   dpbrow:goTop()
   mkey := 0

   while mkey != K_ESC .and. mkey != K_END
    dpbrow:forcestable()
    mkey := inkey( 0 )

    if !navigate( dpbrow, mkey )
     do case
     case mkey >= 48 .and. mkey <= 57
      keyboard chr( mkey )
      mseq := 0
      mscr := Box_Save( 2, 08, 4, 40 )
      @ 3,10 say 'Selecting No' get mseq pict '999' range 1, 24-2
      read
      Box_Restore( mscr )
      if !updated()
       loop

      else
       mreq := recno()
       skip mseq - dpbrow:rowpos
       Retadd()
       if DraftRet->qty = 0
        Del_rec( 'DraftRet', UNLOCK )
        eval( dpbrow:skipblock, -1 )
        dpbrow:refreshall()

       else
        dpbrow:refreshcurrent()

       endif
       goto mreq

      endif

     case mkey == K_F1
      aHelpLines := {}
      aadd( aHelpLines, { 'Ins', 'Add new Item' } )
      aadd( aHelpLines, { 'Del', 'Delete Item' } )
      aadd( aHelpLines, { 'F3', 'Apply Filter' } )
      aadd( aHelpLines, { 'F4', 'Release Item' } )
      if msupp != '*'
       aadd( aHelpLines, { 'F5', 'Delete all' } )
       aadd( aHelpLines, { 'F7', 'Skip to Dept' } )
       aadd( aHelpLines, { 'F8', 'Value' } )
       aadd( aHelpLines, { 'F9', 'Hold all' } )
       aadd( aHelpLines, { 'F10', 'Unhold all' } )

      endif
      Build_help( aHelpLines )

     case mkey == K_F3
      aArray := {}
      aadd( aArray, { ' Operator Items only', nil } )
      aadd( aArray, { 'Invoice Generated Items Only', nil } )
      aadd( aArray, { 'Sales Generated Items Only', nil } )
      mfiltchoice := MenuGen( aArray, 6, 10 )
      mfiltertext := ''
      do case
      case mfiltchoice < 1
       draftret->( dbclearfilter() )
       mfilter := FALSE

      case mfiltchoice = 1
       draftret->( dbsetfilter( { || draftret->type = 'O' } ) )
       mfiltertext := 'Only Operator ' + ITEM_DESC + ' Displayed'

      case mfiltchoice = 2
       draftret->( dbsetfilter( { || draftret->type = 'I' } ) )
       mfiltertext := 'Only Invoice ' + ITEM_DESC + ' Displayed'

      case mfiltchoice = 3
       draftret->( dbsetfilter( { || draftret->type = 'S' } ) )
       mfiltertext := 'Only Sales ' + ITEM_DESC + ' Displayed'

      endcase
      mfilter := ( mfiltchoice > 0 )
      Highlight( 1, 46, '', padr( mfiltertext, 33 ) )
      dpbrow:gotop()
      dpbrow:refreshall()

     case mkey == K_F4
      Rev_hold( FALSE )
      dpbrow:refreshcurrent()

     case mkey == K_F5 .and. msupp != '*'
      if Isready( 5, 10, 'Ok to delete all Draft Return for ' + left( supplier->name, 30 ) )
       mscr:=Box_Save( 3, 10, 5, 70 )
       while DraftRet->supp_code = msupp .and. !DraftRet->( eof() )
        Highlight( 04, 12, 'Deleting Desc', padr( left( master->desc, 35 ), 35 ) )
        Del_rec( 'DraftRet', UNLOCK )
        skip alias DraftRet
       enddo
       Box_Restore( mscr )
       keyboard chr( K_ESC )  // Stuff keyboard to exit
      endif

     case mkey == K_F7
      Skip_to( msupp,dpbrow )

     case mkey == K_F8
      Draft_val( msupp )

     case mkey == K_F9
      Hold_all( TRUE, msupp, dpbrow )

     case mkey == K_F10
      Hold_all( FALSE, msupp, dpbrow )

     case mkey == K_ENTER
      Retadd()
      if DraftRet->qty = 0
       Del_rec( 'DraftRet', UNLOCK )
       eval( dpbrow:skipblock, -1 )
      endif
      dpbrow:refreshcurrent()

     case mkey == K_INS .and. msupp != "*"
      while TRUE
       sID := space( ID_ENQ_LEN )
       mscr := Box_Save( 5, 08, 7, 72 )
       @ 6,10 say 'Enter Code/id to add to Order' get sID pict '@!'
       read
       Box_Restore( mscr )
       if !updated()
        exit

       else
        if !Codefind( sID )
         Error( "Code not found", 12 )

        else
         select DraftRet
         Add_rec( 'DraftRet' )
         DraftRet->date := Bvars( B_DATE ) 
         DraftRet->qty := master->onhand 
         DraftRet->id := master->id 
         DraftRet->supp_code := msupp 
         DraftRet->brand := master->brand
         DraftRet->department := master->department 
         DraftRet->type := 'O' 
         DraftRet->desc := master->desc 
         DraftRet->alt_desc := master->alt_desc
         DraftRet->rrp := master->retail 
         DraftRet->cost := master->cost_price 
         DraftRet->invmacro := '1' 
         DraftRet->stkhistoff := StkHistFind( master->id )
         DraftRet->hold := NO 
         DraftRet->skey := master->desc
         DraftRet->reference := stkhist->reference
         DraftRet->invdate := stkhist->date

         Retadd()

         if DraftRet->qty = 0
          Del_rec( 'DraftRet', UNLOCK )
          eval( dpbrow:skipblock, -1 )

         endif

        endif

       endif

      enddo
      select DraftRet
      dpbrow:refreshall()

     case mkey == K_DEL
      mscr := Box_Save( 15, 2, 17, 77 )
      @ 16,05 say 'About to delete อออฏ ' + left( master->desc, 40 )
      if Isready(18)
       Del_rec( 'DraftRet' )
       eval( dpbrow:skipblock , -1 )
       dpbrow:refreshall()
      endif
      Box_Restore( mscr )

     endcase

    endif

   enddo

  endif

 endif

enddo
select DraftRet
dbunlockall()
return

*

procedure retprint
local getlist:={}, mscr, mhold := FALSE, mLinePrinted := FALSE
local authreq := FALSE
local aArray
local choice
local moldscr := Box_Save()
local mnumber

while TRUE

 Box_Restore( moldscr )
 Heading( 'Returns Reports Menu' )
 aArray := {}
 aadd( aArray, { 'Exit', 'Back to Returns Menu' } )
 aadd( aArray, { 'Draft', 'Print Draft Returns Listings' } )
 aadd( aArray, { 'Credit Claim', 'Reprint a Credit Claim' } )
 choice := MenuGen( aArray, 10, 19, 'Reports' )
 if choice < 2
  exit

 else
  do case
  case choice = 2
   DraftRetform()

  case choice = 3
   Heading( 'Reprint Credit Claim' )
   Print_find("report")
   
   mnumber := 0
   mscr := Box_Save( 3, 40, 5, 74 )
   @ 4, 42 say 'Number for Reprint' get mnumber pict '999999'
   read
   if updated()
    if !rethead->( dbseek( mnumber ) )
     Error( 'Number ' + Ns( mnumber ) + ' not found on file', 12 )

    else
     if Isready( 12 )
      Retform( mnumber )

     endif

    endif

   endif

  endcase

 endif

enddo
return

*

procedure retpost ( msupp )
local mauth:=space(20),mcon:=space(30),mcarrier:=space(30)
local mline:=space(60),mretnum,mtot:=0,x,mpost:=NO,mzero:=NO
local mmonth := upper( left( cmonth( Bvars( B_DATE ) ), 3 ) ), fieldord, mcode, getlist:={}
local mtype := 'R'  // 'R' is a return - 'C' is a credit claim ( no fault )

Heading('Post Returns')
@ 11,31 say 'ออฏ Supplier Code' get msupp pict '@K!'
read

if lastkey() != K_ESC
 Print_find("report")
 
 select DraftRet
 ordsetfocus( 'skey' )
 if !dbseek( msupp )
  Error( 'No Returns found for supplier', 13 )

 else
  locate for !draftret->hold while draftret->supp_code = msupp
  if !found()

   Error( 'No Returns released for this supplier', 12 )

  else

   Box_Save( 02, 08, 20, 78 )
   Highlight( 03, 10, 'Suppliers Name - ', supplier->name )

   if !supplier->returns

    Highlight(5,10,'','This Supplier Does not allow Returns')
    if !Isready(7)
     ordsetfocus( 'supplier' )
     return
    endif

   endif

   @ 05, 10 say mline
   @ 05, 10 say 'Return Authorisation No' get mauth
   @ 07, 10 say 'Consignment Note Number' get mcon
   @ 09, 10 say '        Carrier Details' get mcarrier
   @ 11, 10 say 'Zero minimum Stock' get mzero pict 'y'
   read

   if lastkey() != K_ESC

    if Isready( 12, 10, 'Ok to Post this return' )

     mretnum := Sysinc( 'retnum', 'I', 1 )

     mtot := 0
     mcode := trim(msupp) + '_RET'
     if !purhist->( dbseek( mcode ) )
      Add_rec( 'purhist' )
      purhist->code := mcode
      purhist->( dbrunlock() )
     endif

     select DraftRet
     DraftRet->( dbseek( msupp ) )
     copy to ( Oddvars( TEMPFILE ) ) while DraftRet->supp_code = msupp
     DraftRet->( dbseek( msupp ) )

     @ 11,10 say mline
     Center( 13, '-=< Now Posting Returns List for ' + trim( supplier->name ) + ' >=-')
     SysAudit( 'ReturnsPost' + trim( msupp ) )

     while DraftRet->supp_code = msupp .and. !DraftRet->( eof() ) 

      if !DraftRet->hold
       @ 15, 10 say mline
       Center( 15, '-=< Posting ' + trim( left( master->desc, 35 ) ) + ' >=-' )
       Rec_lock( 'master' )
 
       if mzero
        if master->onhand - DraftRet->qty <= 0
         master->minstock := 0
        endif
       endif

       Update_oh( -DraftRet->qty )
       master->retdate := Bvars( B_DATE )
       master->retqty := DraftRet->qty
       master->( dbrunlock() )
       
       Add_rec('stkhist')   // Update Stock History file //
       stkhist->id := master->id
       stkhist->reference := Ns( mretnum ) + ':' + DraftRet->supp_code
       stkhist->date := Bvars( B_DATE )
       stkhist->qty := -DraftRet->qty
       stkhist->type := 'R'
       stkhist->supp_code := DraftRet->supp_code
       stkhist->( dbrunlock() )

       select purhist
       Rec_lock( 'purhist' )
       fieldord := purhist->( fieldpos( mmonth ) )
       purhist->( fieldput( fieldord , purhist->( fieldget( fieldord ) ) - ( master->cost_price * DraftRet->qty ) ) )
       purhist->( dbrunlock() )

       select deptmove
       mcode := trim(master->department)
       seek mcode
       locate for deptmove->type = 'RET' while deptmove->code = mcode .and. !eof()
       if !found()
        Add_rec()
        deptmove->code := mcode
        deptmove->type := 'RET'
       endif
       Rec_lock()
       fieldord := fieldpos( mmonth )
       fieldput( fieldord , fieldget( fieldord ) - ( master->sell_price * DraftRet->qty ) )
       deptmove->( dbrunlock() )

       mtot+=if( TRUE, master->cost_price*(Bvars( B_GSTRATE )/100), master->cost_price*DraftRet->qty )

       Add_rec( 'retline' )
       retline->number := mretnum
       retline->id := draftret->id
       retline->qty := draftret->qty
       retline->cost_price := master->cost_price
       retline->retail := master->retail
       retline->ret_code := draftret->ret_code

       retline->reference := draftret->reference
       retline->invdate := draftret->invdate
       retline->( dbrunlock() )

       Del_rec( 'DraftRet' )

      endif

      DraftRet->( dbskip() )

     enddo

     Add_rec( 'rethead' )
     rethead->number       := mretnum
     rethead->supp_code    := msupp    
     rethead->date         := Bvars( B_DATE )         
     rethead->authnumber   := mauth   
     rethead->con_note     := mcon     
     rethead->carrier      := mcarrier      

     rethead->( dbrunlock() )

     if Bvars( B_AUTOCRED )
      
      Center( 17, '-=< Creditor processing in Progress >=-' )

      if supplier->( dbseek( msupp ) )
       Rec_lock( 'supplier' )
       supplier->amtcur -= mtot
       supplier->( dbrunlock() )

      endif
     
      Add_rec('cretrans')
      cretrans->code := msupp
      cretrans->ttype := 2
      cretrans->tage := 1
      cretrans->tnum := Ns(mretnum)
      cretrans->date := Bvars( B_DATE )
      cretrans->desc := mauth
      cretrans->amt := -mtot
      cretrans->( dbrunlock() )

     endif


     Center( 19, '-=< Printing Credit Claim #' + Ns( mretnum ) + '>=-' )
     for x := 1 to Bvars( B_CREDCL )
      Retform( mretnum )
     next

    endif
   endif
  endif
 endif
endif

DraftRet->( ordsetfocus( 1 ) )

return

*

procedure retenq ( msupp )   // Pass the last supplier used
/* Enquire / Modify / Delete PO Details */
local mretnum:=0, mscr, okf10, retbrow
local oldscr:=Box_Save(), x, mkey, menqrow
local mrec, mcost, mprice, mqty, getlist:={}, mseq
local aHelpLines
while TRUE
 Box_Restore( oldscr )
 Heading('Credit Claim Enquire')
 mscr := Box_Save( 6, 32, 9, 67 )
 @ 07,35 say 'Credit Claim Number' get mretnum pict PO_NUM_PICT
 @ 08,35 say '<F10> for Supplier Enquire'
 okf10 := setkey( K_F10, { || Retsuppenq( @mretnum, msupp ) } )  // Pass parameter by reference
 read
 setkey( K_F10, okf10 )
 Box_Restore( mscr )
 if lastkey() = K_ESC
  exit
 else
  rethead->( ordsetfocus( BY_NUMBER ) )
  if !rethead->( dbseek( mretnum ) )
   Error( 'Credit Claim Number not on file', 12 )

  else
   cls
   select retline
   set relation to retline->id into master
   Heading( 'Enquire on Credit Claim #' + Ns( mretnum ) )
   Ret_enq_header()
   retbrow:=TBrowseDB( 05, 3, 24, 79 )
   for x := 1 to retbrow:rowcount
    @ x+6,0 say x pict '99'

   next
   retbrow:HeadSep := HEADSEP
   retbrow:colSep := COLSEP
   retbrow:goTopBlock := { || retline->( dbseek( mretnum ) ) }
   retbrow:goBottomBlock  := { || jumptobott( mretnum, 'retline' ) }
   retbrow:skipBlock:=Keyskipblock( { || retline->number }, mretnum ) 
   retbrow:Addcolumn(TBColumnnew( 'Desc', { || left( master->desc, 20 ) } ) )
   retbrow:AddColumn(TBColumnNew( 'Qty',{ || transform( retline->qty,'9999') } ) )
   retbrow:AddColumn(TBColumnNew( 'Onhand',{ || transform( master->onhand , '9999')} ) )
   retbrow:AddColumn(TBColumnNew( 'Reference',{ || left( retline->reference, 20 ) } ) )
   retbrow:AddColumn(TBColumnNew( 'Inv Date', { || retline->invdate } ) )
   retbrow:freeze := 1
   retbrow:goTop()
   mkey := 0
   while mkey != K_ESC .and. mkey != K_END
    retbrow:forcestable()
    mkey := inkey( 0 )
    if !Navigate( retbrow, mkey )

     do case
     case mkey >= 48 .and. mkey <= 57
      keyboard chr( mkey )
      mseq := 0
      menqrow := min( retbrow:ntop+val( chr( mkey ) ), 24- 4 )
      mscr := Box_Save( menqrow, 18, menqrow + 2, 37 )
      @ menqrow+1, 20 say 'Selecting No' get mseq pict '999' range 1, retbrow:rowcount
      read
      Box_Restore( mscr )
      if !updated()
       loop

      else
       Eval( retbrow:skipblock, mseq - retbrow:rowpos )  // This is pretty tricky shit it prevents selection past last data row

      endif

     case mkey == K_F1
      aHelpLines := { ;
      { 'F6','Supplier Details' }, ;
      { 'F8','Value Order' },;
      { 'F10','Disp Desc Screen' } }
      Build_help( aHelpLines )

     
     case mkey == K_F6
      supplier->( dbseek( rethead->supp_code ) )
      select supplier
      Supplier()
      select retline
      Ret_enq_header()
      

     case mkey == K_F8
      mscr := Box_Save( 5, 10, 7, 70 )
      @ 6,12 say 'Valuing Order - Please Wait'
      mrec := recno()
      select retline
      retline->( dbseek( mretnum ) )
      sum retline->qty*master->cost_price,retline->qty*master->sell_price,retline->qty ;
          to mcost,mprice,mqty while retline->number = mretnum .and. !retline->( eof() )
      Box_Restore( mscr )
      goto mrec
      mscr := Box_Save( 5, 10, 11,70 )
      Highlight( 6, 12, ' Value at cost', Ns( mcost,9,2 ) )
      Highlight( 8, 12, ' Value at sell', Ns( mprice,9,2 ) )
      Highlight( 10, 12, 'Items on Order', Ns( mqty,9 ) )
      Error('',12)
      Box_Restore( mscr )

     case mkey == K_F10
      select master
      itemdisp( FALSE )
      select retline

     endcase
    endif
   enddo
  endif
 endif
enddo
return

*

function retadd
local mscr := Box_Save( 05, 01, 24, 79 ), getlist := {}
local mminstock, msale_ret, aArray := { 'Undefined', 'Invoice', 'Sales', 'Operator', 'Receiving' }
local okf6 := Setkey( K_F6, { || UsrRetDate() } )
local okf5 := setkey( K_F5, { || HistRetDate() } )
local okf10 := setkey( K_F10, { || itemdisp( FALSE ) } )

Oddvars( RETURNS_OFFSET, DraftRet->stkhistoff )

stkhist->( dbseek( DraftRet->id ) )
stkhist->( dbskip( DraftRet->stkhistoff ) )
mminstock := master->minstock
msale_ret := master->sale_ret

Rec_lock()
Heading('Return Lists Edit Screen')
Highlight( 06, 03, ID_DESC, idcheck( master->id ) )
Highlight( 07, 03, DESC_DESC, left( master->desc, 30 ) )
Highlight( 08, 03, ALT_DESC, master->alt_desc)
Highlight( 09, 03, ' Selection Reason', aArray[ at( DraftRet->type, 'ISOR' ) + 1 ] )  // will return 'undef' if not found
Highlight( 10, 03, '   Usual Supplier', DraftRet->supp_code)

if DraftRet->supp_code != master->supp_code
 Highlight( 11, 03, '', 'Supplier is Different!' )
 ? BELL

endif

Highlight( 12, 03, 'Last Return Date', dtoc( master->retdate ) )
Highlight( 14, 03, 'Recommended Retail', Ns( DraftRet->rrp, 8, 2 ) )
Highlight( 15, 03, '   Last Cost Price', Ns( DraftRet->cost, 8, 2 ) )

@ 16,03 say 'Quantity to Return' get DraftRet->qty pict '9999'
@ 17,03 say '     Minimum Stock' get mminstock
@ 18,03 say '         Firm Sale' get msale_ret pict 'Y'
@ 18,36 say 'Hold' get hold pict 'Y'
@ 18,50 say 'Return Reason' get DraftRet->ret_code pict '@!' valid( Dup_chk( DraftRet->ret_code, 'retcodes' ) )

@ 15,45 say 'Invoice #       Date    <F5><F6>'
Syscolor( C_BRIGHT )
@ 16,45 say left( draftret->reference, 15 ) + ' ' + dtoc( draftret->invdate )
Syscolor( C_NORMAL )

Salesdisp( master->id )
Stkhistdisp()

read

Rec_lock('master')
master->sale_ret := msale_ret
master->minstock := mminstock
master->( dbrunlock() )

select DraftRet
DraftRet->( dbrunlock() )

setkey( K_F5, okf5 )
setkey( K_F6, okf6 )
setkey( K_F10, okF10 )

Box_Restore( mscr )
return nil

*

static function HistRetDate
local mrec := Enq_hist()
if mrec != 0
 stkhist->( dbgoto( mrec ) )
 DraftRet->stkhistoff := Oddvars( RETURNS_OFFSET )
 DraftRet->reference := stkhist->reference
 DraftRet->invdate := stkhist->date

endif
return nil

*

static function UsrRetDate
local mscr := Box_Save( 3, 10, 6, 70 ), getlist := {}
@ 4, 12 say 'Invoice #' get DraftRet->reference
@ 5, 12 say 'Date ' get draftret->date
read
Box_Restore( mscr )
return nil

*

static function hold_all ( hold_em, msupp, dpbrow )
local mscr, oldrec := DraftRet->( recno() )
if msupp = '*'
 Error( 'No ' + if( hold_em, '', 'Un' ) + 'hold all for supplier = "*"',12 )

else
 if Isready( 10, 12 , 'Ok to ' + if( !hold_em, 'Unh', 'H' ) + 'old all for ' + left( supplier->name, 25 ) )
  mscr:=Box_Save( 2, 10, 4, 70 )
  Center( 3, if( !hold_em, 'Unh', 'H') + 'olding all ' + trim( supplier->name ) + ' - Please Wait' )
  DraftRet->( dbseek( msupp ) )
  while !DraftRet->( eof() ) .and. DraftRet->supp_code = msupp
   Rec_lock( 'DraftRet' )
   DraftRet->hold := if( hold_em, YES, FALSE )
   DraftRet->( dbrunlock() )
   DraftRet->( dbskip() )

  enddo
  Box_Restore( mscr )
  DraftRet->( dbgoto( oldrec ) )
  dpbrow:refreshall()

 endif

endif
return nil

*

static function skip_to ( msupp, dpbrow )
local mlet:=' ',getlist:={},mscr,mrec:=recno()
if msupp != '*'
 mscr := Box_Save( 16, 20, 18, 60 )
 @ 17,22 say 'First Letter of Dept' get mlet pict '!'
 read
 if updated()
  DraftRet->( dbseek( msupp+mlet, TRUE ) )
  if DraftRet->supp_code != msupp
   DraftRet->( dbgoto(  mrec ) )

  endif

 endif
 Box_Restore( mscr )
 dpbrow:refreshall()

endif
return nil

*

Function StkHistFind ( sID )
local mret := 0
select stkhist
if dbseek( sID )
 mcount := -1
 locate for stkhist->type = 'I' while stkhist->id = sID .and. count_em( @mcount )
 mret := mcount

endif
select DraftRet
return mret

*

Function count_em ( mcount )
mcount++
return TRUE

*

Function StkHistPos ( moffset, sID )
stkhist->( dbseek( sID ) )
if stkhist->( found() )
 stkhist->( dbskip( moffset ) )

endif
return TRUE

*

static procedure all_returns ( msupp )
local mrow := 7, mcol:=1, item_count
local mrec := recno(), getlist:={}
local mscr := Box_Save( 06, 00, 24, 79 )

Heading( "Suppliers with Outstanding Returns" )
DraftRet->( dbgotop() )
while !DraftRet->( eof() ) .and. inkey() = 0
 @ mrow,mcol say DraftRet->supp_code
 msupp := DraftRet->supp_code
 item_count := 1
 while !DraftRet->( eof() ) .and. DraftRet->supp_code = msupp
  DraftRet->( dbskip() )
  item_count++

 enddo
 @ mrow,mcol+04 say item_count-1 pict '999'
 mrow++
 if mrow = 24
  mrow := 07
  mcol += SUPP_CODE_LEN + 1
  if mcol > ( 24 - SUPP_CODE_LEN - 2 )
   Error( "End of Page Reached" )
   mcol := 01

  endif

 endif

enddo
Error("")
DraftRet->( dbgoto( mrec ) )

Box_Restore( mscr )
retu

*

static procedure Retsuppenq ( mret, msupp )
/* Browse a list of PO's attached to a supplier */
local mscr := Box_Save( 04, 25, 06, 55 ), getlist:={}, oldord
local retbrow, mkey
@ 05,27 say 'Enter Supplier Code' get msupp pict '@!K'
read
Box_Restore( mscr )
if empty( msupp ) //!updated()
 return

else
 select rethead
 oldord := rethead->( ordsetfocus( BY_SUPPLIER ) )
 rethead->( dbseek( msupp ) )
 mscr := Box_Save( 01, 59, 24-1, 79-1 )
 retbrow:=TBrowseDB( 02, 60, 24-2, 79-2 )
 retbrow:HeadSep := HEADSEP
 retbrow:colSep := COLSEP
 retbrow:goTopBlock := { || rethead->( dbseek( msupp ) ) }
 retbrow:goBottomBlock := { || jumptobott( msupp, 'rethead' ) }
 retbrow:skipBlock := Keyskipblock( { || rethead->supp_code }, msupp )
 retbrow:AddColumn( TBColumnNew('CC #',{ ||  rethead->number } ) )
 retbrow:AddColumn( TBColumnNew('CC Date', { || rethead->date } ) )
 retbrow:goTop()
 mkey := 0
 while mkey != K_ESC .and. mkey != K_END
  retbrow:forcestable()
  mkey := inkey(0)
  if !navigate( retbrow, mkey )
   if mkey == K_ENTER
    mret := rethead->number
    exit

   endif

  endif

 enddo
 Box_Restore( mscr )
 rethead->( ordsetfocus( oldord ) )

endif
return

*

static Function Ret_Enq_header()
/* Display the Supplier details on Enquiry screen */
@ 01, 00 clear to 04, 79
Highlight( 1, 01, 'Supplier', LookItup( "supplier", rethead->supp_code ) )
Highlight( 2, 01, 'Comments', LookItup( "supplier", rethead->supp_code, 'comm1' ) )
Highlight( 3, 01, '        ', LookItup( "supplier", rethead->supp_code, 'comm2' ) )
Highlight( 1, 46, 'Date of Order', dtoc( rethead->date ) )
Highlight( 2, 46, 'Phone #', LookItup( 'supplier', rethead->supp_code, 'phone' ) )
Highlight( 3, 46, 'Acc #', LookItup( 'supplier', rethead->supp_code, 'account' ) )
return nil

*

procedure DraftRetform()
  // draft return form similar to the credit claim form.

  local tot_cost := 0, tot_value := 0, tot_items := 0, page:=1
  local mdate, mSupp := space(5), mhold := .f., authreq := .f.
  local GetList := {}, oPrinter

//  Print_find("report")
  
  select DraftRet
  ordsetfocus( 1 )
  @ 10,30 say 'อออ> Supplier Code' get msupp pict '@K!'
  read

  if lastkey() != K_ESC
    if msupp != '*'
      if !dbseek( msupp )
        Error('No Draft Returns for this supplier!',12)
        return

      endif

    else
      go top

    endif
    Box_Save( 11, 32, 14, 64 )
    @ 12, 44 say 'Print Hold ' + DESC_DESC get mhold pict 'y'
    @ 13, 34 say 'Print Authorisation Request' get authreq pict 'y' when( msupp != '*' )
    read
    if Isready( 10 )
     oPrinter := Printcheck( 'Returns Request', 'Report' )
      mdate := date()
      LP( oPrinter, BIGCHARS )
      LP( oPrinter, 'Returns Request' )
      LP( oPrinter, NOBIGCHARS )
      LP( oPrinter, left( dtoc( mdate ), 2 ) + ' ' + cmonth( mdate ) + ' ' + str( year( mdate ), 4 ), 0, NONEWLINE )
      LP( oPrinter, if( !TRUE, 'A.C.N. ' + Bvars( B_ACN ), '' ), 60 )

      LP( oPrinter, BIGCHARS )
      LP( oPrinter, 'Returns Request from: ' + trim( BVars( B_NAME ) ), 0 )
      LP( oPrinter, NOBIGCHARS )

      LP( oPrinter, Bvars( B_ADDRESS1 ), 22 )
      if !empty( Bvars( B_ADDRESS2 ) )
        LP( oPrinter, Bvars( B_ADDRESS2 ), 22 )
        LP( oPrinter, trim( Bvars( B_SUBURB ) ), 22 )
        LP( oPrinter, '(Ph) ' + Bvars( B_PHONE ) + '   ' + if( empty( Bvars( B_FAX ) ),'','(Fax)' + Bvars( B_FAX ) ), 22 )

      else
        LP( oPrinter, trim( Bvars( B_SUBURB ) ), 22 )
        LP( oPrinter, '(Ph) ' + Bvars( B_PHONE ) + '   ' + if( empty( Bvars( B_FAX ) ),'','(Fax)' + Bvars( B_FAX ) ), 22 )

      endif
      supplier->( dbseek( mSupp ) )
      LP( oPrinter, 'Account No:' + supplier->Account, 15 )

      LP( oPrinter, supplier->name, 15 )
      LP( oPrinter, supplier->raddress1, 15 )
      if !empty( supplier->raddress2 )
        LP( oPrinter, supplier->raddress2, 15 )
      endif
      LP( oPrinter, trim( supplier->rcity ), 15 )
      if !empty( supplier->fax )
        LP( oPrinter, 'Fax No. ' + supplier->fax )
      endif
      LP( oPrinter )

      Retheader( page )

      while Pinwheel() .and. !DraftRet->( eof() ) .and. ;
           if( msupp = '*', TRUE, DraftRet->supp_code = msupp )
        if !DraftRet->hold .or. mhold

            master->( dbseek( DraftRet->id ) )

            LP( oPrinter, idcheck( master->id ), 0, NONEWLINE )
            LP( oPrinter, left( master->desc, 25 ), 14, NONEWLINE )
            LP( oPrinter, transform( draftRet->qty, QTY_PICT ), 40, NONEWLINE )
            LP( oPrinter, transform( draftRet->retail, PRICE_PICT ), 45, NONEWLINE )
            LP( oPrinter, transform( draftRet->cost_price, PRICE_PICT ), 53, NONEWLINE )
            LP( oPrinter, left( draftRet->reference, 20 ), 60, NONEWLINE )
            LP( oPrinter, dtoc( draftRet->invdate ), 72 )
            if len( trim( master->desc ) ) > 25
             LP( oPrinter, substr( master->desc, 26 ), 14 )

            endif

            tot_cost  += DraftRet->cost * DraftRet->qty
            tot_value += DraftRet->rrp * DraftRet->qty
            tot_items += DraftRet->qty

            if prow() > 60
              page++
              LP( oPrinter, DRAWLINE )
              oPrinter:newpage()

              Retheader( page, oPrinter )

            endif

        endif
        DraftRet->( dbskip() )
      enddo

      if prow() > 60
         page++
         LP( oPrinter, DRAWLINE )
         oPrinter:newpage()

         Retheader( page, oPRinter )

      endif

      LP( oPrinter, DRAWLINE )
      LP( oPrinter, BIGCHARS )
      LP( oPrinter, 'Total number of items Returned ' + Ns( tot_items,7 ) )
      LP( oPrinter, 'Please send Authorisation to return these overstocks' )
      oPrinter:endDoc()
      oPrinter:Destroy()

    endif
  endif
return


*

procedure retform ( nRetNum )
local tot_cost := 0, tot_value := 0, tot_items := 0, gst, page:=1
local mdate
local oPrinter := Printcheck( 'Credit Claim No: ' + Ns( nRetnum ), 'Report' )

select RetHead
dbseek( nRetNum )

mdate := rethead->date
LP( oPrinter, BIGCHARS )
LP( oPrinter, BOLD )
LP( oPrinter, 'Credit Claim' )
LP( oPrinter, NOBOLD )
LP( oPrinter, NOBIGCHARS )
LP( oPrinter, left( dtoc( mdate ), 2 ) + ' ' + cmonth( mdate ) + ' ' + str( year( mdate ), 4 ), 0, NONEWLINE )
LP( oPrinter, if( !TRUE, 'A.C.N. ' + Bvars( B_ACN ), '' ), 60 )
LP( oPrinter, BIGCHARS )
LP( oPrinter, 'Credit claim from: ', 0, NONEWLINE )
LP( oPrinter, BOLD )
LP( oPrinter, PRN_GREEN )
LP( oPrinter, trim( BVars( B_NAME ) ), 19 )
LP( oPrinter, PRN_BLACK )
LP( oPrinter, NOBOLD )
LP( oPrinter, NOBIGCHARS )
LP( oPrinter, Bvars( B_ADDRESS1 ), 19 )
if !empty( Bvars( B_ADDRESS2 ) )
 LP( oPrinter, Bvars( B_ADDRESS2 ), 19 )
 LP( oPrinter, trim( Bvars( B_SUBURB ) ), 19 )
 LP( oPrinter, '(Ph) ' + Bvars( B_PHONE ) + '   ' + if( empty( Bvars( B_FAX ) ),'','(Fax)' + Bvars( B_FAX ) ), 19 )

else
 LP( oPrinter, trim( Bvars( B_SUBURB ) ), 19 )
 LP( oPrinter, '(Ph) ' + Bvars( B_PHONE ) + '   ' + if( empty( Bvars( B_FAX ) ),'','(Fax)' + Bvars( B_FAX ) ), 19 )

endif
supplier->( dbseek( rethead->supp_code ) )
LP( oPrinter )
LP( oPrinter, 'Supplier', 0 , NONEWLINE )
LP( oPrinter, supplier->name, 19 )
LP( oPrinter, supplier->raddress1, 19 )
if !empty( supplier->raddress2 )
 LP( oPrinter, supplier->raddress2, 19 )

endif
LP( oPrinter, trim( supplier->rcity ), 19 )

if !empty( supplier->fax )
 LP( oPrinter, 'Fax No. ' + supplier->fax )

endif
LP( oPrinter, 'Account No.  :' + supplier->Account )
LP( oPrinter, BIGCHARS )
LP( oPrinter, 'Authorisation No : ' + rethead->authnumber )
LP( oPrinter, NOBIGCHARS )
LP( oPrinter, BIGCHARS )
LP( oPrinter, 'Credit Claim  No : ' + Ns( rethead->number ) )
LP( oPrinter, NOBIGCHARS )

if !empty( rethead->con_note ) .or. !empty( rethead->carrier )
 LP( oPrinter, 'Carrier: ' + rethead->carrier )
 LP( oPrinter, 'Consignment Note #' + rethead->con_note )

endif

LP( oPrinter )

Retheader( page, oPrinter )

retline->( dbseek( rethead->number ) )
while retline->number = rethead->number .and. !retline->( eof() ) 

 master->( dbseek( retline->id ) )

 LP( oPrinter, idcheck( master->id ), 0, NONEWLINE )
 LP( oPrinter, left( master->desc, 25 ), 14, NONEWLINE )
 LP( oPrinter, transform( retline->qty, QTY_PICT ), 40, NONEWLINE )
 LP( oPrinter, transform( retline->retail, PRICE_PICT ), 45, NONEWLINE )
 LP( oPrinter, transform( retline->cost_price, PRICE_PICT ), 52, NONEWLINE )
 LP( oPrinter, left( retline->reference, 20 ), 60, NONEWLINE )
 LP( oPrinter, dtoc( retline->invdate ), 72 )
 if len( trim( master->desc ) ) > 25
  LP( oPrinter, substr( master->desc, 26 ), 14 )

 endif

 tot_cost  += retline->cost_price * retline->qty
 tot_value += retline->retail * retline->qty
 tot_items += retline->qty

 if prow() > 58
   page++
   LP( oPrinter, DRAWLINE )
   oPrinter:newpage()
   Retheader( page, oPrinter )

 endif

 retline->( dbskip() )

enddo

if prow() > 58
 page++
 LP( oPrinter, DRAWLINE )
 oPrinter:newpage()
 Retheader( page, oPrinter )

endif

LP( oPrinter, DRAWLINE )

LP( oPrinter, BIGCHARS )
LP( oPrinter, ' Total Retail Value of Credit $', 0, NONEWLINE )
LP( oPrinter, BOLD )
LP( oPRinter, transform( tot_value, PRICE_PICT ), 32 )
LP( oPrinter, NOBOLD )
LP( oPrinter, NOBIGCHARS )

LP( oPrinter, BIGCHARS )
LP( oPrinter, ' Total Invoice Cost of Credit $', 0, NONEWLINE )
LP( oPrinter, BOLD )
LP( oPrinter, transform( tot_cost, PRICE_PICT ), 32 )
LP( oPrinter, NOBOLD )
LP( oPrinter, NOBIGCHARS )

gst := CalcGST(  tot_cost, BVars( B_GSTRATE)  )

LP( oPrinter, BIGCHARS )
LP( oPrinter, ' Total GST claimed in Credit  $', 0, NONEWLINE)
LP( oPrinter, BOLD )
LP( oPrinter, transform( gst, PRICE_PICT ), 32 )
LP( oPrinter, NOBOLD )
LP( oPrinter, NOBIGCHARS )

//LP( oPrinter, BIGCHARS )
//LP( oPrinter, '         Total Credit claimed $' + Ns( gst+tot_cost,8,2 ) )
//LP( oPrinter, NOBIGCHARS )

LP( oPrinter, BIGCHARS )
LP( oPrinter, 'Total number of items Returned ' ,0, NONEWLINE )
LP( oPrinter, BOLD )
LP( oPrinter, transform( tot_items, QTY_PICT ), 32 )
LP( oPrinter, NOBOLD )
LP( oPrinter, NOBIGCHARS )

oPrinter:endDoc()
oPrinter:Destroy()

return

*

function retheader ( page, oPrinter )
if page > 1
 LP( oPrinter,  'Page No. ' + Ns( page ) )

endif
LP( oPrinter, 'ID            Desc', 0, NONEWLINE )
LP( oPrinter, 'Qty  Retail   Cost    Last Inv  Date', 41 )
LP( oPrinter, DRAWLINE )
return nil

