/*

    Special Order processing

      Last change:  TG    5 Jan 2011    9:39 pm
*/

field id,desc,number,notfound,qty,deposit,supp_code,delivered

#include "bpos.ch"


#define TAKEORDERONLY  1
#define DELIVERYDOCKET 2
#define SPECIALORDER   3

#define PDTARR    1
#define ORDINAL   2
#define APPENDING 3
#define AUTOAPPE  4
#define PDTORDER  5

static specvars

Procedure s_specials

local mgo:=FALSE, choice, oldscr:=Box_Save(), aArray

specvars := array( 5 )

Center( 24, 'Opening files for Special Orders' )
if Netuse( "hold" )
 if Netuse( "supplier" )
  if Netuse( "customer" )
   if Netuse( "draft_po" )
    if Netuse( "sales" )
     if Master_use()
      if Netuse( "special" )
       set relation to special->id into master,;
                    to special->key into customer
       mgo := TRUE
      endif
     endif
    endif
   endif
  endif
 endif
endif
line_clear(24)
while mgo
 Box_Restore( oldscr )
 Heading("Special Orders")
 aArray := {}
 aadd( aArray, { 'Sales', 'Return to Sales Menu', nil, nil } )
 aadd( aArray, { 'Create', 'Create Special order', { || Specadd() }, nil } )
 aadd( aArray, { 'Delete', 'Remove Special order from file', { || Specdel() }, nil } )
 aadd( aArray, { 'Replace', "Replace 'found' ids in file", { || Specrepl() }, nil } )
 aadd( aArray, { 'Enquire', 'Make Enquiries on Order Status', { || SpecEnq() }, nil } )
 aadd( aArray, { 'Print', 'Reports Menu', { || SpecPrint() }, nil } )
 aadd( aArray, { 'Purge', 'Remove old filled orders from file', { || Specpurge() }, nil } )
 aadd( aArray, { 'Finalise', 'Finalise a special without selling', { || Specfinal() }, nil } )
 choice := MenuGen( aArray, 04, 35, 'Special' )
 if choice < 2
  exit
 else
  if Secure( aArray[ choice, 4 ] )
   Eval( aArray[ choice, 3 ] )
  endif
 endif 
enddo
close databases
return

*

procedure Specadd
local mscr,okf5,okf8,x,macq,linesave,mspecmode
local sID,firstpass,row,mtotdep,mordno,mappe,mspecno,custkey,sp_line,mpos
local custname, msupp, s_finished, s_ok, s_print, mdep, mstand, mdesc
local getlist:={}, mavail, mcomm, morder, mreceived, mqty, sAltDesc, mslipflag

while TRUE

 if !CustFind(FALSE)
  return
 endif

 firstpass:=TRUE
 row:=5
 mstand:=FALSE
 mtotdep:=0
 mSlipFlag := FALSE
 mordno:=space(10)
 mappe:=FALSE
 custkey:=customer->key
 custname:=customer->name
 specvars[ APPENDING ] := FALSE
 specvars[ AUTOAPPE ] := FALSE
 specvars[ PDTORDER ] := ''

 select special
 copy stru to ( Oddvars( TEMPFILE ) )
 if !Netuse( Oddvars( TEMPFILE ), TRUE, 10, "spectemp", TRUE )
  loop

 endif
 set relation to spectemp->id into master,;
                 spectemp->supp_code into supplier

 cls
 @ 01,67 say 'Docket is ' + if( lvars( L_DOCKET ), 'On', 'Off' )
 Heading('Create Special Order')
 @ 03,00 say ' Supp  Desc                          Author        Qty  Order No     Av Spec'
 @ 04,00 say replicate( chr( 196 ), 79 )
 mcomm := space(40)
 while TRUE
  msupp := space( SUPP_CODE_LEN )
  Highlight( 1, 1, 'Customer NameÍÍÍ> ', custname )
  Highlight( 1, 40, 'CommentsÍÍÍ>', customer->comments )
  Highlight( 02, 60, 'Deposit(s) $', Ns( mtotdep ) )
  @ 02,25 say 'Enter id/Code' get sID pict '@!'

  if !specvars[ APPENDING ]
   okf5 := setkey( K_F5, { || SpecPDTAppe() } )

  else
   okf5 := setkey( K_F5, nil )

  endif

  okf8 := setkey( K_F8, { || add_item() } )
  sID := space( ID_ENQ_LEN )

  if specvars[ APPENDING ]
   specvars[ ORDINAL ]++
   if specvars[ ORDINAL ] > len( specvars[ PDTARR ] )
    Error( 'PDT Append Run finished', 12, , 'Remember to Clear the PDT Memory with FUNCTION 19' )
    specvars[ APPENDING ] := FALSE

   else
    mpos := at( ',', specvars[ PDTARR ][ specvars[ ORDINAL ] ] )
    if mpos > 0
     sID := left( specvars[ PDTARR ][ specvars[ ORDINAL ] ], mpos-1 )

    else
     sID := specvars[ PDTARR ][ specvars[ ORDINAL ] ]

    endif
    keyboard sID + chr( K_ENTER ) 

   endif

  endif

  read
  setkey( K_F5, okf5 )
  setkey( K_F8, okf8 )
  select spectemp
  if !updated() .or. lastkey() = K_ESC
   if firstpass
    exit

   else
    mscr := Box_Save( 06, 18, 10, 62 )
    s_finished:=FALSE
    s_print:=TRUE
    @ 07,20 say 'Finished entering Special Orders' get s_finished pict 'y'
    read
    if s_finished
     s_ok:=FALSE
     @ 08,20 say 'Ok to Process this Special Order' get s_ok pict 'y'
     read
     if !s_ok .and. !mappe
      firstpass:=TRUE
      exit

     else
      if Bvars( B_SPDOCK ) > 0
       @ 09,20 say 'Print Special Docket' get s_print pict 'y'
       read

      endif

     endif
     Box_Restore( mscr )
     exit

    endif
    Box_Restore( mscr )

   endif

  else
   msupp := space( SUPP_CODE_LEN )
   mqty := 1
   mdep := 0
   mspecmode := 1
   if sID = '*'    // Not found descs
    mdesc := space( 24 )
    sAltDesc := space(20)
    macq := space(10)
    sp_line := Box_Save( 6, 00, 6, 79 )
    @ 05,00 get msupp pict '@!' valid( dup_chk(msupp,"supplier") )
    @ 05,06 get mdesc pict '@S25!'
    @ 05,32 get sAltDesc pict '@!'
    @ 05,54 get mqty pict '9999'
    @ 05,58 get mordno pict '@S10!'
    line_clear(6)
    @ 06,01 say 'Sp Comment' get mcomm
#ifndef DELIVERY_NOTE
    @ 06,45 say 'Deposit' get mdep pict '999.99'
    @ 06,60 say 'Acq #' get macq
#endif
    read
    Box_Restore( sp_line )
    if lastkey() = K_ESC .or. mqty = 0
     loop
    else
     firstpass := FALSE
     Add_rec( 'spectemp' )
     spectemp->key := custkey
     spectemp->date := Bvars( B_DATE )
     spectemp->desc := mdesc
     spectemp->alt_desc := sAltDesc
     spectemp->qty := mqty
     spectemp->notfound := 'X'
     spectemp->ordno := mordno
     spectemp->supp_code := msupp
     spectemp->comments := mcomm
     spectemp->deposit := mdep
     spectemp->acqno := macq
#ifdef DELIVERY_NOTE
     spectemp->specmode := mspecmode 
#endif
     spectemp->( dbrunlock() )
     mtotdep += mdep
     @ 05,06 say desc
     @ 05,31 say sAltDesc

    endif
   else
    if !Codefind(sID)
     clear typeahead
     Error( 'id/Code not on File', 12 )

    else
     line_clear(row)
     if specvars[ APPENDING ]
      mpos := at( ',', specvars[ PDTARR ][ specvars[ ORDINAL ] ] )
      if mpos > 0
       mqty := val( substr( specvars[ PDTARR ][ specvars[ ORDINAL ] ], mpos+1, 10 ) )

      endif
      mordno := specvars[ PDTORDER ]
      if specvars[ AUTOAPPE ]
       keyboard chr( K_PGDN )

      endif

     endif
     msupp := master->supp_code
     macq := space(10)
     mavail := MASTAVAIL
     @ 05,00 get msupp pict '@!' valid( dup_chk( msupp,"supplier" ) .and. !empty(msupp) )
     @ 05,06 say substr( master->desc, 1, 25 ) + ' ' + master->status
     @ 05,37 say substr( master->alt_desc, 1, 14 )
     @ 05,52 get mqty pict QTY_PICT
     @ 05,58 get mordno pict '@S10!'
     @ 05,70 say mavail pict '999'
     @ 05,75 say master->special pict '999'
     linesave := Box_Save(6,0,7,79)
     Line_clear( 6 )
     @ 06,01 say 'Sp Ord Comment' get mcomm pict '@KS19'
     @ 06,37 say 'Deposit' get mdep pict '9999.99'
     @ 06,53 say 'StandOr' get mstand pict 'Y'
     @ 06,63 say 'Acq #' get macq
     read
     mreceived := 0
     morder := mqty - mreceived
     if master->onorder > 0 .and. mqty - mreceived > 0
      line_clear( 7 )
      @ 07,01 say 'You have '+Ns(master->onorder)+' on order already.';
            +' How many extra to place onto draft order' get morder pict '99'
      read
     endif
     Box_Restore( linesave )
     if mqty > 0 .or. mreceived > 0
      firstpass := FALSE
      Add_rec( 'spectemp' )
      spectemp->key := custkey
      spectemp->date := Bvars( B_DATE )
      spectemp->supp_code := msupp
      spectemp->id := master->id
      spectemp->desc := master->desc
      spectemp->alt_desc := master->alt_desc
      spectemp->qty := mqty
      spectemp->received := mreceived  // this field for allocated exstock
      spectemp->alloc := morder        // this field is storage for Dpo qty
      spectemp->ordno := mordno
      spectemp->comments := mcomm
      spectemp->deposit := mdep
      spectemp->standing := mstand
      spectemp->acqno := macq
      spectemp->( dbrunlock() )
      mtotdep += mdep
     else
      line_clear(05)
     endif
    endif
   endif
   scroll( 05, 00, 24-1, 79, -1 )
  endif
 enddo

 if !firstpass
  select spectemp
  go top
  mspecno := Sysinc( "specno", 'I', 1, 'special' )
  Highlight( 2, 1, 'Special Order #' , Ns( mspecno ) )

  if mtotdep > 0
   Tender( mtotdep, mtotdep, 0, 0, 1, "sales", 'SDT', row, customer->name )

  endif

  while !spectemp->( eof() )
   if spectemp->alloc > 0              // Create Draft_po
    select draft_po
    dbseek( spectemp->id )
    locate for draft_po->source = 'Sp' .and. supp_code = spectemp->supp_code ;
           while id = spectemp->id
    if found()
     Rec_lock( 'draft_po' )
     draft_po->qty += spectemp->alloc

     draft_po->comment := trim(draft_po->comment) + ;
             if( !empty(spectemp->comments), '/'+spectemp->comments, '' )
     draft_po->( dbrunlock() )

    else
     Add_rec( 'draft_po' )
     draft_po->id := spectemp->id
     draft_po->supp_code := spectemp->supp_code
     draft_po->qty := spectemp->alloc
     draft_po->date_ord := Bvars( B_DATE )
     draft_po->special := TRUE
     draft_po->hold := TRUE
     draft_po->source := 'Sp'
     draft_po->skey := master->alt_desc
     draft_po->department := master->department
     draft_po->comment := trim( spectemp->comments )
#ifdef DPO_BY_DESC
     draft_po->skey := master->desc
#endif
     draft_po->( dbrunlock() )

    endif

   endif    // spectemp->alloc > 0
   if empty( spectemp->notfound )
    if master->( dbseek( spectemp->id ) )
     Rec_lock( 'master' )
     master->special += spectemp->qty
     if Bvars( B_SPMIN )
      master->minstock := 0

     endif
     master->( dbrunlock() )

    endif

   endif
   Add_rec( 'special' )
   special->number := mspecno
   special->key := custkey
   special->date := Bvars( B_DATE )
   special->desc := spectemp->desc
   special->alt_desc := spectemp->alt_desc
   special->qty := spectemp->qty
   special->received := spectemp->received
   special->notfound := spectemp->notfound
   special->ordno := spectemp->ordno
   special->supp_code := spectemp->supp_code
   special->comments := spectemp->comments
   special->deposit := spectemp->deposit
   special->acqno := spectemp->acqno
   special->id := spectemp->id
   special->standing := spectemp->standing
   special->alloc :=spectemp->alloc
   special->( dbrunlock() )

   spectemp->( dbskip() )

  enddo

  if s_print
   spectemp->( dbgotop() )
   Dock_head()
   Dock_line(  chr(17) + chr(14) + 'Special No: ' + Ns(mspecno,6) )
   Dock_line(  'Please order the following books for :' )
   Dock_line(  customer->name )
   Dock_line(  '(Hm) ' + customer->phone1 + '   (Wk)' + customer->phone2 )
   Dock_line(  'Desc               '+ ALT_DESC + '          Qty' )
   Dock_line(  replicate('-',40) )
   while !spectemp->( eof() )
    if spectemp->qty > 0
     if spectemp->notfound == 'X'
      Dock_line(  substr( spectemp->desc, 1, 19 ) + ' ' + substr( spectemp->alt_desc, 1, 14 ) + ;
                        ' ' + str( spectemp->qty, 4 ) )

     else
      Dock_line(  substr( spectemp->desc, 1, 19 ) + ' ' + substr( spectemp->alt_desc, 1, 14 ) + ;
         ' ' + str( spectemp->qty, 4 ) )

     endif

    endif
    spectemp->( dbskip() )

   enddo
   Dock_line( replicate( '-', 40 ) )
   Dock_line( 'Deposit Paid = $' + Ns( mtotdep, 7, 2 ) )
   Dock_Foot( )
   for x := 1 to Bvars( B_SPDOCK )
    Dock_print()

   next

  endif
  lvars( L_CUST_NO , Custnum() )

 endif
 select special
 spectemp->( dbclosearea() )

enddo
return

*

procedure Specdel
local tscr, pscr, aHelpLines, mordno
local mtotdep, mspecno, oldscr := Box_Save(), lAnswer := FALSE 
local specbrow,mscr,keypress,getlist:={},mdep, mdel
while TRUE
 Box_Restore( oldscr )
 Heading('Delete Special Order')
 draft_po->( ordsetfocus( BY_ID ) )
 select special
 ordsetfocus( BY_NUMBER )
 mspecno := 0
 @ 7,46 say 'ÍÍÍ> Order No to Delete' get mspecno pict '999999'
 read
 if !updated()
  draft_po->( ordsetfocus( BY_SUPPLIER ) )
  return

 else
  if !special->( dbseek( mspecno ) )
   Error('Order not on file',12)

  else
   cls
   mtotdep:=0
   Heading('')
   Highlight( 02, 10, 'Customer Name =>', customer->name )
   Highlight( 03, 10, 'Date of Order   ', dtoc( special->date ) )
   specbrow := TBrowseDB( 04, 0, 24, 79 )
   specbrow:HeadSep := HEADSEP
   specbrow:ColSep := COLSEP
   specbrow:goTopBlock := { || dbseek( mspecno ) }
   specbrow:goBottomBlock := { || jumptobott( mspecno ) }
   specbrow:skipBlock:=Keyskipblock( {|| special->number }, mspecno ) 
   specbrow:AddColumn(TBColumnNew('Desc', { || substr(if(empty(notfound),master->desc,desc),1,25) } ) )
   specbrow:AddColumn(TBColumnNew(ALT_DESC, { || substr(if(empty(notfound),master->alt_desc,special->alt_desc),1,15) } ) )
   specbrow:AddColumn(TBColumnNew('Last Rec',{ || master->dlastrecv } ) )
   specbrow:AddColumn(TBColumnNew('Date L Po', { || master->date_po } ) )
   specbrow:AddColumn(TBColumnNew('Qty', { || special->qty } ))
   specbrow:AddColumn(TBColumnNew('Received', { || special->received } ))
   specbrow:AddColumn(TBColumnNew('Delivered', { || special->delivered } ))
   specbrow:AddColumn(TBColumnNew('On Draft', { || if(draft_po->(eof()),'N','Y') } ) )
   specbrow:AddColumn(TBColumnNew('Supplier',{ || if(empty(notfound),supp_code,'?') } ) )
   specbrow:AddColumn(TBColumnNew('Comments', { || special->comments } ))
   specbrow:AddColumn(TBColumnNew('Deposit', { || special->deposit } ))
   specbrow:AddColumn(TBColumnNew('C. Order', { || special->ordno } ))
   specbrow:AddColumn(TBColumnNew('Master File Comments',{ || master->comments } ) )
   specbrow:AddColumn(TBColumnNew('id',{ || idcheck(id) } ) )
   specbrow:freeze := 1
   keypress := 0
   while keypress != K_ESC .and. keypress != K_END
    if special->number != mspecno
     select special
     ordsetfocus( BY_NUMBER )
     dbseek( mspecno )     // Reposition dbf if all records deleted by user

    endif
    specbrow:forcestable()
    keypress := inkey(0)
    if !navigate(specbrow,keypress)
     do case
     case keypress == K_F1
      aHelpLines := { { 'Del', 'Delete line from Order' },;
                   { 'Enter', 'Modify line Details' },;
                   { 'F4', 'Add a deposit to this Order' },;
                   { 'F9', 'Delete all of Special Order' },;
                   { 'F10', 'Examine Desc Details' },;
                   { 'F12', 'Finalise all of this Special Order' }, ;
                   { 'Ctrl-Enter', 'Change Customer order number' } }
      Build_help( aHelpLines )

     case keypress == K_CTRL_RET
      Heading( 'Adjust Special #' + Ns( mspecno ) )
      mscr:=Box_Save(08,02,14,77)
      Center( 09,'About to adjust the Customer Order Number on all items on S/O #' + Ns( mspecno ) )
      mordno := space( 20 )
      @ 11,10 say 'Order Number' get mordno
      read
      if updated()
       if Isready(14)
        select special
        dbseek( mspecno )
        while !special->( eof() ) .and. special->number = mspecno
         @ 13,10 say substr( master->desc, 1, 30 )
         Rec_lock( 'special' )
         special->ordno := mordno 
         special->( dbrunlock() )
         special->( dbskip() )

        enddo
        special->( dbseek( mspecno ) )
        SysAudit( 'AdjSpOrdno' + Ns( mspecno ) )

       endif

      endif
      Box_Restore( mscr )
      specbrow:refreshall()

     case keypress == K_F10
      itemdisp( FALSE )
      specbrow:refreshcurrent()

     case keypress == K_F4
      mtotdep := 0
      pscr := Box_Save( 12, 02, 15, 76 )
      Highlight( 13, 04, 'Deposit on ' + trim(substr( master->desc, 1, 20 )), Ns( special->deposit ) )
      @ 14, 04 say 'Amount to Add to Deposit' get mtotdep pict '9999.99'
      read
      if mtotdep > 0 
       dock_head( )  // Dock_head inits the docket Array!
       Dock_line( 'Deposit received from :' )
       Dock_line( customer->name )
       Dock_line( '(Hm) ' + customer->phone1 + '   (Wk)' + customer->phone2 )
       Dock_line( replicate( '-', 40 ) )
       Dock_line( 'Deposit already received = $' + Ns( special->deposit ) )
       Dock_line( '        New Deposit Paid = $' + Ns( mtotdep, 7, 2 ) )
       Dock_line( '      Total Deposit Paid = $' + Ns( mtotdep+special->deposit, 7, 2 ) )
       Tender( mtotdep, mtotdep, 0, 0, 1, "sales", 'SDT', 14, customer->name )
       dock_foot( )
       dock_Print()

       select special
       Rec_lock( 'special' )
       special->deposit += mtotdep
       special->( dbrunlock() )
       specbrow:refreshcurrent()

      endif
      Box_Restore( pscr )

     case keypress == K_ENTER
      tscr:=Box_Save( 12, 02, 15, 76 )
      rec_lock()
      @ 13,04 say ' Order Comments' get comments
      @ 14,04 say 'Customer Acq No' get acqno
      @ 14,32 say 'Customer Ord No' get ordno
      @ 14,60 say 'Qty Received' get received pict '999'
      read
      dbrunlock()
      Box_Restore( tscr )
      specbrow:refreshcurrent()

     case keypress == K_F12
      if Isready( 03, 21, 'About to finalise all of this Special' )
       special->( dbseek( mspecno ) )
       while special->number = mspecno .and. !special->( eof() )

        Rec_lock('master')
        master->special -= special->qty
        Rec_lock('master')
        master->special -= special->qty
        master->( dbrunlock() )
/*     
   Will need to look at this  
        if special->deposit > 0
         Tender( special->deposit, special->deposit, 0, 0, -1, "sales", 'SDR', 10, customer->name )
         dbrunlock()
        endif
*/
        select special
        Rec_lock('special')
        special->delivered := special->qty
        special->( dbrunlock() )
        special->( dbskip() )

       enddo
      endif

     case keypress == K_F10
      if Secure( X_SALEVOID )
       mtotdep := 0
       if Isready( 03, 21, 'Ok to delete all of Special Order' )
        SysAudit( "SpDelAll" + Ns( special->number ) )
        special->( dbseek( mspecno ) )
        while special->number = mspecno .and. !special->( eof() )
         if empty( special->notfound )
          Rec_lock( 'master' )
          master->special -= special->qty - special->delivered
          master->( dbrunlock() )

         endif
         if special->delivered < special->qty
          mtotdep += special->deposit

         endif
         Del_rec( 'special', UNLOCK )
         special->( dbskip() )

        enddo
        select special
        if mtotdep > 0
         mscr:=Box_Save(2,08,4,72)
         @ 3, 10 say 'Deposit Refund Due' get mtotdep pict '9999.99'
         read
         Box_Restore( mscr )
         if mtotdep > 0
          Tender( mtotdep, mtotdep, 0, 0, -1, "sales", 'SDR', 10, customer->name )

         endif

        endif
        specbrow:refreshall()

       endif

      endif

     case keypress == K_DEL
      mscr:=Box_Save(20,2,24,77)
      mdel:=FALSE
      @ 21,05 say 'Delete ÍÍÍ¯ '+trim( if(empty(notfound), left( master->desc,25 ), desc ) ) get mdel pict 'y'
      mdep:=special->deposit
      if !empty(mdep)
       @ 23,05 say 'Deposit Refund Due' get mdep

      endif
      read
      Box_Restore( mscr )
      if mdel
       if Secure( X_DELFILES )
        SysAudit( "SpLineDel" + idcheck( special->id ) + '|' + Ns( special->number ) )
        if empty( special->notfound )
         rec_lock( 'master' )
         master->special -= special->qty - special->delivered
         master->( dbrunlock() )

        endif
        if mdep > 0
         Tender( mdep, mdep, 0, 0, -1, "sales", 'SDR', 10, customer->name )
         dbrunlock()

        endif
        select special
        Del_rec( 'special', UNLOCK )
        eval( specbrow:skipblock , -1 )
        specbrow:refreshall()

       endif

      endif

     endcase

    endif
   enddo
  endif
 endif
enddo
return

*

procedure Specrepl
local keypress,specbrow,mscr,getlist:={},sID
local mavail, malloc, mcomm

select special
ordsetfocus( BY_NOTFOUND )

if !dbseek( 'X' )
 Error('No records found for replacement',12)
 ordsetfocus( BY_NUMBER )
 return

else
 cls
 Heading("Select Desc for " + ID_DESC + " replacement")
 specbrow := TBrowseDB( 01, 0, 24, 79 )
 specbrow:HeadSep := HEADSEP
 specbrow:ColSep := COLSEP
 specbrow:goTopBlock := { || dbseek( 'X' ) }
 specbrow:goBottomBlock  := { || jumptobott( FALSE ) }
 specbrow:skipBlock:=KeySkipBlock( {|| special->notfound }, 'X' ) 
 specbrow:Addcolumn( tbcolumnnew( 'Number',{ || transform( special->number, '999999' ) } ) )
 specbrow:AddColumn( tbColumnNew( 'Desc', { || substr( special->desc, 1, 20 ) } ) )
 specbrow:AddColumn( tbColumnNew( ALT_DESC, { || substr( special->alt_desc, 1, 12 ) } ) )
 specbrow:AddColumn( tbColumnNew( 'Qty', { || transform( special->qty, '9999' ) } ))
 specbrow:AddColumn( tbColumnNew( 'Supplier',{ || special->supp_code } ) )
 specbrow:addcolumn( tbcolumnnew( 'Customer Name', { || substr( customer->name,1,20) } ) )
 specbrow:AddColumn( tbColumnNew( 'Comments', { || special->comments } ))
 specbrow:AddColumn( tbColumnNew( 'Deposit', { || transform( special->deposit,'9999.99') } ))
 specbrow:AddColumn( tbColumnNew( 'C. Order', { || special->ordno } ))
 specbrow:freeze := 2
 keypress := 0
 while keypress != K_ESC .and. keypress != K_END
  specbrow:forcestable()
  keypress := inkey(0)
  if !navigate(specbrow,keypress)
   if keypress == K_ENTER
    mscr:=Box_Save(02,08,15,72)
    Heading( 'Replace id' )
    Highlight( 03, 10, 'Suspected Desc  =>', special->desc )
    Highlight( 05, 10, 'Suspected Author =>', special->alt_desc )
    sID := space( ID_ENQ_LEN )
    @ 07,10 say 'Enter '+ID_DESC+' for replacement' get sID pict '@!'
    read
    if updated()
     if !Codefind( sID )
      Error( ID_DESC +' not on file',12)
      select special
     else
      Highlight(09,10,'Replacement Desc  ',master->desc)
      Highlight(11,10,'Replacement Author ',master->alt_desc)
      if Isready(12)
       Rec_lock( 'master' )
       master->special += special->qty
       master->( dbrunlock() )
       mavail := MASTAVAIL
       malloc := 0
       mcomm := special->comments
       if mavail > 0
        malloc := min( mavail, special->qty )
        mscr := Box_Save( 06, 00, 08, 79, C_GREY )
        @ 07,01 say 'You have ' + Ns( mavail ) + ' available ex stock.';
                +' How many to allocate to this order' get malloc pict '999';
                valid( malloc <= special->qty .and. malloc <= mavail )
        read
        Box_Restore( mscr )
        if malloc > 0
         mcomm += ' : Part Alloc ' + Ns( malloc )
        endif
       endif
       if special->qty - malloc > 0
        Add_rec( 'draft_po' )
        draft_po->id := master->id
        draft_po->supp_code := master->supp_code
        draft_po->qty := special->qty
        draft_po->date_ord := Bvars( B_DATE )
        draft_po->special :=TRUE
        draft_po->source := 'Sp'
        draft_po->skey := master->alt_desc
        draft_po->( dbrunlock() )
       endif
       select special
       Rec_lock()
       special->supp_code := master->supp_code
       special->id := master->id
       special->desc := master->desc
       special->alt_desc := master->alt_desc
       special->notfound := ''
       dbrunlock()

       if malloc > 0
        DockForm( malloc, special->qty, special->number, special->comments, ;
                  special->deposit, special->date, master->sell_price, special->ordno )
       endif
      endif
     endif
    endif
    Box_Restore( mscr )
    select special
    specbrow:RefreshAll()
   endif
  endif
 enddo
endif
select special
ordsetfocus( BY_NUMBER )
return

*

procedure SpecEnq
local mchoice:=1,mkey,oldscr:=Box_Save(),getlist:={},aArray
local specbrow,hitkey,mnumber,mscr,oldrec,c,sID,mordno,mdesc,mname,saverec
while TRUE
 Box_Restore( oldscr )
 Heading('Special Order File Inquiry By')
 aArray := {}
 aadd( aArray, { 'Special', 'Return to Special Menu' } )
 aadd( aArray, { 'Key', 'Inquiry by Customer Key' } )
 aadd( aArray, { 'Number', 'Inquiry by Special Order Number' } )
 aadd( aArray, { ID_DESC, 'Inquiry by ' + ID_DESC } )
 aadd( aArray, { 'Order No', 'Find Special Orders by Customer Order' } )
 mchoice := MenuGen( aArray, 09, 36, 'Enquire' )
 do case
 case mchoice < 2
  ordsetfocus( BY_NUMBER )
  return
 case mchoice = 2
  select special
  ordsetfocus( BY_KEY )
  while CustFind( FALSE )
   mname := trim(customer->name)
   mkey := customer->key
   select special
   seek mkey
   Box_Save( 02, 00, 24, 79 )
   specbrow := TBrowseDB( 03, 01, 23, 78 )
   specbrow:HeadSep := HEADSEP
   specbrow:ColSep := COLSEP
   specbrow:goTopBlock := { || dbseek( mkey ) }
   specbrow:goBottomBlock  := { || jumptobott( mkey ) }
   specbrow:skipBlock:=KeyskipBlock( { || special->key }, mkey  )
   specbrow:AddColumn( TBColumnNew('Order #', { || transform( special->number , '999999') } ) )
   specbrow:AddColumn( TBColumnNew('Date', { || special->date } ) )
   specbrow:AddColumn( TBColumnNew('Desc',{ || substr(master->desc,1,25) }))
   specbrow:AddColumn( TBColumnNew('Customer Order', { || special->ordno } ) )
   hitkey := 0
   while hitkey != K_ESC .and. hitkey != K_END
    specbrow:forcestable()
    hitkey := inkey(0)
    if !navigate(specbrow,hitkey)
     do case
     case hitkey == K_ENTER
      saverec := special->(recno())
      mnumber := special->number
      special->( ordsetfocus( BY_NUMBER ) )
      special->( dbseek( mnumber ) ) 
      Specdisp( mnumber )
      select special
      ordsetfocus( BY_KEY )
      goto saverec
     endcase
    endif
   enddo
  enddo
  select special
  ordsetfocus( BY_NUMBER )

 case mChoice = 3
  mscr:=Box_Save()
  while TRUE
   Box_Restore( mscr )
   Heading('Special order File Inquiry')
   mnumber := 0
   @ 12,46 say 'ÍÍÍ¯Enter Order Number' get mnumber pict '999999'
   read
   if !updated()
    exit
   else
    select special
    ordsetfocus( BY_NUMBER )
    if !special->( dbseek( mnumber ) ) 
     Error('Special Order No NOT on file',15)
    else
     Specdisp(mnumber)
    endif
   endif
  enddo

 case mChoice = 4 .or. mchoice = 5
  mscr:=Box_Save()
  while TRUE
   Box_Restore( mscr )
   if mchoice = 4
    Heading('Inquiry by id/code')
    sID := space( ID_ENQ_LEN )
    @ 13,46 say 'ÍÍÍ¯Enter id' get sID pict '@!'
   else
    Heading('Inquiry by Customer Order No')

    mordno := space(10)

    @ 14,46 say 'ÍÍÍ>Customer Order No' get mordno pict '@S10!'
   endif
   read
   if !updated()
    exit
   else
    if mchoice = 4
     sID := trim( sID )
     Codefind( sID )
     mdesc := substr(master->desc,1,40)
     sID := master->id
     select special
     ordsetfocus( BY_ID )
     dbseek( sID )
    else
     select special
     ordsetfocus( BY_ORDNO )
     mordno := trim( mordno )
     dbseek( mordno )
    endif
    if !found()
     Error( if( mchoice=4, 'id ', 'Customer Order ' ) + 'not on the Special Order file', 12 )
     exit
    else
     Box_Save( 2, 00, 24, 79 )
     if mchoice = 4
      Highlight( 3, 10 , ' ' + ID_DESC + ' Í> ', idcheck( sID ) )
      Highlight( 4, 10 , 'Desc Í> ', mdesc )
      specbrow := tbrowsedb( 05, 02, 23, 78 )
     else
      specbrow := TBrowsedb( 03, 01, 23, 78 )
     endif
     specbrow:HeadSep := HEADSEP
     specbrow:ColSep := COLSEP
     specbrow:goTopBlock := { || dbseek( if(mchoice=4,sID,mordno) ) }
     specbrow:goBottomBlock := { || jumptobott( if( mchoice=4, sID, mordno) ) }
     specbrow:skipBlock := Keyskipblock( { || if( mchoice=4, special->id, special->ordno ) },;
             if( mchoice=4, sID, mordno ) ) 
     specbrow:AddColumn( tbcolumnNew( 'Order #', { || transform( special->number, '999999' ) } ) )
     specbrow:AddColumn( tbcolumnNew( 'Date', { || special->date } ) )
     specbrow:AddColumn( tbcolumnNew( 'Customer Name',{ || substr( customer->name, 1, 25 ) } ) )
     specbrow:AddColumn( tbcolumnNew( 'Customer Order', { || special->ordno } ) )
     specbrow:addcolumn( tbcolumnnew( 'Qty', { || special->qty } ) )
     c:=TBColumnNew( 'Recv', { || special->received } )
     c:colorblock:={ || if( special->qty-special->received <= 0 , { 5, 6 } , { 1, 2 } ) }
     specbrow:addcolumn( c )
     c:=tbcolumnnew( 'Del', { || special->delivered } )
     c:colorblock:={ || if( special->qty-special->delivered <= 0 , { 5, 6 } , { 1, 2 } ) }
     specbrow:addcolumn( c )
     hitkey := 0
     while hitkey != K_ESC .and. hitkey != K_END
      specbrow:forcestable()
      hitkey := inkey(0)
      if !navigate(specbrow,hitkey)
       do case
       case hitkey == K_ENTER
        mnumber := special->number
        oldrec := special->( recno() )
        special->( ordsetfocus( BY_NUMBER ) )
        special->( dbseek( mnumber ) ) 
        Specdisp( mnumber )
        ordsetfocus( if( mchoice = 4, BY_NOTFOUND, BY_ORDNO ) )
        special->( dbgoto( oldrec ) )
        specbrow:refreshall()
       endcase
      endif
     enddo
    endif
   endif
  enddo
 endcase
enddo

*

procedure specdisp ( mnumber )
local mscr:=Box_Save(0,0,24,79),specbrow,hitkey,tscr
local getlist:={},c,pscr, mtotdep, aHelpLines

cls
Heading('Inquiry On Order No ' + Ns(mnumber))
Custdisp()
select special
specbrow:=TBrowseDB(09, 01, 24, 79 )
specbrow:colorspec := TB_COLOR
specbrow:HeadSep:= HEADSEP
specbrow:ColSep:= COLSEP
specbrow:goTopBlock:={ || special->( dbseek( mnumber ) ) }
specbrow:goBottomBlock:={ || jumptobott( mnumber ) }
specbrow:skipBlock:=KeySkipBlock( {|| special->number }, mnumber )
specbrow:addcolumn(tbcolumnnew('Desc',{|| if(empty(special->notfound),substr(master->desc,1,18),special->desc) } ) )
specbrow:addcolumn(tbcolumnnew( ALT_DESC,{|| if(empty(special->notfound),substr(master->alt_desc,1,10),special->alt_desc) } ) )
specbrow:addcolumn(tbcolumnnew('Supp Code',{|| if(empty(special->notfound),master->supp_code,special->supp_code) }))
specbrow:addcolumn(tbcolumnnew('Qty',{||special->qty }))
c:=TBColumnNew( 'Recv',{ || special->received } )
c:colorblock:={ || if( special->qty-special->received <= 0 , { 5, 6 } , { 1, 2 } ) }
specbrow:addcolumn( c )
c:=tbcolumnnew( 'Del',{ || special->delivered } )
c:colorblock:={ || if( special->qty - special->delivered <= 0 , { 5, 6 } , { 1, 2 } ) }
specbrow:addcolumn( c)
specbrow:addcolumn(tbcolumnnew('Fnd',{|| if(empty(special->notfound),'Y','N') } ) )
specbrow:addcolumn(tbcolumnnew('Deposit',{||transform(special->deposit,'9999.99')}))
specbrow:addcolumn(tbcolumnnew('Date',{||special->date}))
specbrow:addcolumn(tbcolumnnew('Comments',{||special->comments}))
specbrow:addcolumn(tbcolumnnew('Master Comments',{||master->comments}))
specbrow:addcolumn(tbcolumnnew('Customer Order', {||special->ordno}))
specbrow:addcolumn(tbcolumnnew('Customer Acq #', {||special->acqno}))
hitkey:=0
specbrow:freeze := 1
while hitkey != K_ESC .and. hitkey != K_END
 specbrow:forcestable()
 hitkey := inkey(0)
 if !Navigate(specbrow,hitkey)
  do case
  case hitkey == K_F1
   aHelpLines:={ { 'Enter', 'Modify Item' }, { 'F10', 'Desc Display' } }
   aadd( aHelpLines, { 'F4','Add Deposit' } )
   Build_help( aHelpLines )


  case hitkey == K_F4
   mtotdep := 0
   pscr := Box_Save( 12, 02, 15, 76 )
   Highlight( 13, 04, 'Deposit on ' + trim(substr( master->desc, 1, 20 )), Ns( special->deposit ) )
   @ 14, 04 say 'Amount to Add to Deposit' get mtotdep pict '9999.99'
   read
   if mtotdep > 0 
    Dock_head()
    Dock_line(  'Deposit received from :' )
    Dock_line(  customer->name )
    Dock_line(  '(Hm) ' + customer->phone1 + '   (Wk)' + customer->phone2 )
    Dock_line(  replicate( '-', 40 ) )
    Dock_line(  'Deposit already received = $' + Ns( special->deposit ) )
    Dock_line(  '        New Deposit Paid = $' + Ns( mtotdep, 7, 2 ) )
    Dock_line(  '      Total Deposit Paid = $' + Ns( mtotdep+special->deposit, 7, 2 ) )
    Tender( mtotdep, mtotdep, 0, 0, 1, "sales", 'SDT', 14, customer->name )
    Dock_Foot( )
    Dock_print()

    select special
    Rec_lock('special')
    special->deposit += mtotdep
    special->( dbrunlock() )
    specbrow:refreshcurrent()
   endif
   Box_Restore( pscr )
   specbrow:refreshall()


  case hitkey == K_ENTER
   tscr:=Box_Save( 12, 02, 16, 76 )
   Rec_lock( 'Special' )
   @ 13,04 say ' Order Comments' get comments
   @ 14,04 say 'Customer Ord No' get ordno
   @ 14,60 say 'Qty Received' get received pict '999'
   @ 15,04 say 'Customer Acq No' get acqno
   read
   special->( dbrunlock() )
   Box_Restore( tscr )
   specbrow:refreshcurrent()

  case hitkey == K_F10
   itemdisp( FALSE )
   specbrow:refreshcurrent()

  endcase
 endif
enddo
Box_Restore( mscr )
return

*

procedure Specpurge
local mdate := Bvars( B_DATE ) - 60, getlist:={}, mnotdel := FALSE
if Secure( X_SYSUTILS )
 Heading('Purge Old Special Orders')
 Box_Save( 2, 03, 10, 77 )
 Center( 3, 'You are about to delete all filled Special Orders older than')
 Center( 4, dtoc( mdate ) )
 @ 05,05 say 'Date for Purge' get mdate
 @ 05,40 say 'Delete received but not delivered' get mnotdel pict 'y'
 read
 if Isready(7)
  special->( dbgotop() )
  while !special->( eof() )
   if special->date <= mdate .and. !special->standing .and. ;
      ( special->delivered = special->qty .or. ;
      ( mnotdel .and. special->received = special->qty ) )
    Highlight( 7, 10, 'Order No ', Ns( special->number ) )
    Highlight( 8, 10, 'Customer ', customer->name )
    if special->delivered < special->received
     Rec_lock('master')
     master->special -= special->qty
     master->( dbrunlock() )

    endif
    Del_rec( 'special', UNLOCK )

   endif
   special->( dbskip())

  enddo
  SysAudit( "SpePurge" + dtoc( mdate ) )

 endif

endif
return

*

Proc SpecFinal
local mspecno:=0, msbn, mscr, getlist:={}
@ 12,47 say 'ÍÍÍÍÍ> Special Order #' get mspecno pict '999999'
read
if updated()
 select special
 ordsetfocus( BY_NUMBER )
 if !special->( dbseek( mspecno ) )
  Error( 'Special order #' + Ns( mspecno ) + ' not on file' , 12 )
 else
  mscr := Box_Save( 2, 10, 5, 70 )
  msbn := space( ID_ENQ_LEN )
  Highlight( 3,12,'Customer Name ', customer->name )
  @ 4,12 say 'Scan Code / ' + ID_DESC + ' to finalise' get msbn pict '@!'
  read
  Box_Restore( mscr ) 
  if updated()
   if !Codefind( msbn ) 
    Error( 'Code not on file' , 12)
   else
    msbn := master->id
    select special
    locate for special->id = msbn .and. special->delivered < special->qty ;
           while special->number = mspecno
    if !found()
     Error( 'id not found on Special order or finalised', 12)
    else
     mscr:=Box_Save( 2,08,7,72 )
     Highlight( 3, 10, '   Desc', substr( master->desc, 1, 40 ) )
     Highlight( 4, 10, 'Date Ord', dtoc( special->date ) )
     Highlight( 4, 30, ' Ordered', Ns( special->qty ) )
     Highlight( 4, 50, 'Received', Ns( special->received ) )
     Highlight( 5, 10, 'About to finalise', Ns( special->qty - special->delivered ) + ' items' )
     if special->deposit > 0
      Highlight( 6, 10, 'Deposit Amount', Ns( special->deposit, 8, 2 ) )
     endif
     if Isready(12)
      Rec_lock('master')
      master->special -= special->qty
      master->( dbrunlock() )
      if special->deposit > 0
       Tender( special->deposit, special->deposit, 0, 0, -1, "sales", 'SDR', 10, customer->name )
       dbrunlock()

      endif
      select special
      Rec_lock('special')
      special->delivered := special->qty
      special->( dbrunlock() )

     endif
     Box_Restore( mscr )

    endif

   endif

  endif

 endif

endif
return

*

procedure SpecPrint
local newchoice:=1, choice, mspecno
local getlist:={}, msupp, mcat, mscr, aArray, farr
memvar muns, mnumber, msupptmp, lowerdate, upperdate
private muns, mnumber, msupptmp, lowerdate, upperdate
select special
ordsetfocus( BY_NUMBER )
Heading('Special File Print Menu')
Box_Save(10,36,17,48)
Print_find("report")
aArray := {}
aadd( aArray, { 'Return', 'Return to Special Menu' } )
aadd( aArray, { 'Customer', 'Customer Special Status Reports' } )
aadd( aArray, { 'All', 'Print entire Special File' } )
aadd( aArray, { 'Not Found', 'Descs not found' } )
aadd( aArray, { 'Overdue', 'Special orders not yet filled' } )
newchoice := MenuGen( aArray, 10, 36, 'Print' )
do case
case newchoice = 2
 aArray := {}
 aadd( aArray, { 'Print', 'Return to Special Report Menu' } )
 aadd( aArray, { 'All', 'All Special Order Reports for Customer' } )
 aadd( aArray, { 'Single', 'Print Single Special Order Report' } )
 aadd( aArray, { 'Category', 'All Special Order Reports by customer Category' } )
 choice := MenuGen( aArray, 12, 37, 'Customer' )
 do case
 case choice = 2
  Heading( 'Print All Special Order Details for Customer' )
  if CustFind( FALSE )
   select special
   ordsetfocus( BY_KEY )
   if !dbseek( customer->key )
    Error( "No Special Orders found for " + trim( customer->name ), 12 )

   else
    muns := TRUE
    Box_Save( 2, 10, 5, 70 )
    Center( 3, 'Print Orders for ' + trim( customer->name ) )
    @ 4, 12 say 'Print unsupplied items only' get muns pict 'y'
    read
    if Isready(12)
     Specstat( TRUE, customer->key, muns )

    endif

   endif
   ordsetfocus( BY_NUMBER )

  endif
 case choice = 3
  Heading('Customer Special Order Status Report')
  mspecno := 0
  @ 15,48 say 'ÍÍ>Special Order No' get mspecno pict '999999'
  read
  if !dbseek( mspecno )
   Error( 'Special Order No not on file', 14 )

  else
   Box_Save( 14, 08, 18, 72 )
   muns := TRUE
   Highlight( 15, 12, 'Customer Name ', trim( customer->name ) )
   Highlight( 16, 12, 'First desc   ', trim( master->desc ) )
   @ 17,12 say 'Print unsupplied items only' get muns pict 'y'
   read
   if Isready(18)
    Specstat( FALSE, mspecno, muns )

   endif

  endif
 case choice = 4
  Heading('Customer Order Status Reports for all Customers')
  if Netuse( 'custcate' )
   ordsetfocus( 'code' )
   mcat := space( 6 )
   muns := TRUE
   mscr := Box_Save( 2, 10, 5, 45 )
   @ 3, 12 say 'Customer category' get mcat pict '@!' valid( dup_chk( mcat, 'category' ) )
   @ 4, 12 say 'Print unsupplied items only' get muns pict 'y'
   read
   if Isready( 12, ,'Print special reports for customers of category ' + trim( Lookitup( 'category', mcat ) ) )
    custcate->( dbseek( mcat ) )
    while custcate->code = mcat .and. !custcate->( eof() ) .and. Pinwheel()
     select special
     ordsetfocus( BY_KEY )
     if dbseek( custcate->key )
      Box_Save( 14, 08, 18, 72 )
      Highlight( 15, 12, 'Customer Name ', trim( customer->name ) )
      Highlight( 16, 12, 'First desc   ', trim( master->desc ) )
      Specstat( TRUE, customer->key, muns )

     endif
     custcate->( dbskip() )

    enddo

   endif
   Box_Restore( mscr )

  endif
  select special
  ordsetfocus( BY_NUMBER )

 endcase

case newchoice = 3
 aArray := {}
 aadd( aArray, { 'Print', 'Return to Special Report Menu' } )
 aadd( aArray, { 'Customer', 'All Orders sorted by Customer' } )
 aadd( aArray, { 'Number', 'All Orders sorted by Number' } )
 choice := MenuGen( aArray, 13, 37, 'All' )

 farr := {}
 aadd(farr,{"if(NOTFOUND='',substr(master->desc,1,25),desc)",'Desc',25,0,FALSE})
 if choice = 3
  aadd(farr,{"if(NOTFOUND='',substr(master->alt_desc,1,20),alt_desc)",'alt_desc',20,0,FALSE})

 endif
 aadd(farr,{'comments','Special Order Comment',30,0,FALSE})
 aadd(farr,{'date','Date;Ordered',8,0,FALSE})
 if choice = 3
  aadd(farr,{'customer->name','Ordered For',25,0,FALSE})

 endif
 aadd(farr,{'qty','Qty;Ord',3,0,FALSE})
 aadd(farr,{'received','Qty;Rec',4,0,FALSE})
 aadd(farr,{'delivered','Qty;Del',4,0,FALSE})
 if choice = 2
  aadd(farr,{'master->status','Stat',4,0,FALSE})
  aadd(farr,{'special->number','Number',7,0,FALSE})
  aadd(farr,{'master->comments','Master File Comments',30,0,FALSE})

 endif
 
 if choice > 1
  Box_Save(14,08,17,72)
  muns := TRUE
  mnumber := 0
  @ 15,12 say '     Print unsupplied items only' get muns pict 'y'
  @ 16,12 say 'Print Order numbers greater than' get mnumber pict '999999'
  read

 endif
 do case
 case choice = 2
  Heading('Print All Specials by Customer')
  if Isready(12)
   
   ordsetfocus( BY_KEY )
   go top
   
   Reporter(farr,"'All Special Orders on File'",'key+customer->add3','"Customer -> "+key+customer->add3',;
   '','',FALSE,'if (muns, special->delivered < special->qty, .t.) .and. special->number >= mnumber')
   
   Endprint()
  endif
 case choice = 3
  Heading('Print All Specials by Number')
  if Isready(12)
   
   ordsetfocus( BY_NUMBER )
   go top
   
   Reporter(farr,"'All Special Orders on File'",'number','"Special Order # "+Ns(number)',;
   '','',FALSE,'if (muns, special->delivered < special->qty, .t.) .and. special->number >= mnumber')
   
   Endprint()

  endif

 endcase
case newchoice = 4
 Heading('Print All not found Descs')
 if Isready(12)
  // Pitch17()
  farr := {}
  aadd(farr,{'number','Special;Number',7,0,FALSE})
  aadd(farr,{'desc','Desc;Sought',25,0,FALSE})
  aadd(farr,{'alt_desc','Author;Sought',20,0,FALSE})
  aadd(farr,{'supp_code','Supp',4,0,FALSE})
  aadd(farr,{'comments','Special Order Comment',30,0,FALSE})
  aadd(farr,{'date','Date;Ordered',8,0,FALSE})
  aadd(farr,{'customer->name','Ordered For',25,0,FALSE})
  
  Reporter(farr,"'All Not Found Special Orders'",'','','','',FALSE,"special->notfound = 'X'")

  // Pitch10()
  Endprint()

 endif

case newchoice= 5
 Heading('Print Special orders overdue')
 upperdate := Bvars( B_DATE )
 lowerdate := Bvars( B_DATE ) - 30
 msupp := '*   '
 Box_Save( 15, 15, 19, 58 )
 @ 16,20 say 'Upper date for Report' get upperdate
 @ 17,20 say 'Lower date for Report' get lowerdate
 @ 18,20 say 'Supplier to Print (*=All)' get msupp pict '@!'
 read
 if Isready(18)
  select special
  indx( "special->supp_code", 'supp' )
  set relation additive to special->supp_code into supplier
  msupptmp := msupp
  if msupp != '*'
   dbseek( msupp )

  else
   special->( dbgotop() )

  endif
  // Pitch17()
  
  farr := {}
  aadd(farr,{'substr( master->desc,1,20 )','Desc',20,0,FALSE})
  aadd(farr,{'idcheck(id)','id',10,0,FALSE})
  aadd(farr,{'qty','Qty;Ord',4,0,FALSE})
  aadd(farr,{'date','Date;Ordered',8,0,FALSE})
  aadd(farr,{'substr( special->comments, 1, 17 )','Special;Order Comments',17,0,FALSE})
  aadd(farr,{'substr( master->comments, 1, 17 )','Master;Comments',17,0,FALSE})
  aadd(farr,{'substr( customer->name,1 ,25 )','Ordered for',25,0,FALSE})
  aadd(farr,{'substr( customer->add3,1,25)','Suburb',25,0,FALSE})
  aadd(farr,{'master->status','St',3,0,FALSE})
  
  Reporter(farr,"if( msupptmp='*','All','Supplier '+ msupptmp )+' Special Orders between '+dtoc(upperdate)+' and '+dtoc(lowerdate)",;
  'supp_code','"Supplier Code : "+supp_code','','',FALSE,;
  '( special->date >= lowerdate .and. special->date <= upperdate ) .and. special->qty - special->received > 0',;
  'if(msupptmp="*",.t.,special->supp_code=msupptmp)')

  // Pitch10()
  Endprint()
  special->( orddestroy( 'supp' ) )
 endif

endcase
return

*

procedure specstat ( by_key, mkeyval, muns )
local mordno := ')(-=}{'

set device to print
Specstathed()
while !special->( eof() ) ;
    .and. if( by_key, special->key = mkeyval ,special->number = mkeyval )
 if special->delivered < special->qty .or. !muns
  if special->ordno != mordno .and. !empty( special->ordno )
   @ prow()+2,15 say 'The following descs have your ref no ' + special->ordno
   mordno := special->ordno
  endif
  if empty( special->notfound )
   @ prow()+1,00 say special->number
   @ prow(),08 say substr(dtoc(special->date),1,5)
   @ prow(),14 say substr(master->desc,1,20)
   @ prow(),35 say substr(master->alt_desc,1,14)
   @ prow(),50 say special->qty - special->delivered pict '999'
   @ prow(),55 say Lookitup( "status",master->status )

  else
   @ prow()+1,00 say 'Unknown'
   @ prow(),14 say substr( special->desc, 1, 14 )
   @ prow(),35 say substr( special->alt_desc, 1, 14 )
   @ prow(),50 say special->qty - special->delivered
   @ prow(),55 say 'Desc unknown at present'

  endif
  if prow() > 56
   eject   
   Specstathed()

  endif

 endif
 skip

enddo
@ prow()+1, 0 say replicate( chr(196) ,80 )
@ prow()+3, 0 say 'For and on Behalf of ' + BPOSCUST + ' _____________________'
eject
set device to screen
return

*

procedure specstathed
setprc(0,0)

@ 0,0 say BIGCHARS + 'Special Order Status Report'
@ prow()+1,60 say BIGCHARS + dtoc(Bvars( B_DATE ) ) + NOBIGCHARS
@ prow()+1,0 say chr(27)+chr(31)+chr(1)+chr(14)+BPOSCUST;
            +chr(27)+chr(31)+chr(0)
@ prow()+1,0 say Bvars( B_ADDRESS1 )
if !empty( Bvars( B_ADDRESS2 ) )
 @ prow()+1,0 say Bvars( B_ADDRESS2 )
 @ prow()+1,0 say trim( Bvars( B_SUBURB ) )
 @ prow()+1,0 say Bvars( B_PHONE )
else
 @ prow()+1,0 say trim( Bvars( B_SUBURB ) )
 @ prow()+1,0 say Bvars( B_PHONE )
endif
@ prow()+2,15 say customer->name
@ prow(), 58 say '(Ph)  ' + customer->phone1
@ prow()+1,15 say customer->add1
if !empty(customer->fax)
 @ prow(),58 say '(FAX) ' + customer->fax
endif                                                           // if !empty(customer->fax)
if !empty(customer->add2)
 @ prow()+1,15 say trim(customer->add2)+if(empty(customer->add3),' '+customer->pcode,'')
endif
if !empty(customer->add3)
 @ prow()+1,15 say trim(customer->add3)+' '+customer->pcode
endif
@ prow()+3,0 say '--                                                                       --'
@ prow()+2,00 say 'Dear Customer,'
@ prow()+2,00 say 'Following is a status report on special orders placed with our suppliers'
@ prow()+1,00 say 'on your behalf.'
@ prow()+2,00 say 'Our Ref  Date  Desc                Author        Qty  Comments'
@ prow()+1,00 say replicate(chr(196),80)
return

*

Function SpecPDTAppe

local mstr, mpos, mscr, getlist :={}, sID

mscr := Box_Save( 06, 08, 15, 72 )
@ 07,10 say 'Ready to Append Data from Portable'
@ 08,10 say 'Hit "Function" followed by "11"'
@ 12,10 say 'Esc to halt downloading '

specvars[ PDTARR ] := {}
specvars[ ORDINAL ] := 1

while TRUE
 mstr := space( 25 )
 @ 10,10 say 'Data' get mstr
 read
 if lastkey() = K_ESC .or. mstr = 'EOF'
  exit

 else
  aadd( specvars[ PDTARR ], mstr )

 endif

enddo

if len( specvars[ PDTARR ] ) > 0

 specvars[ PDTORDER ] := space( 15 )
 @ 13,10 say 'Customer Order #' get specvars[ PDTORDER ] pict '@!'
 @ 14,10 say 'Automatic Append' get specvars[ AUTOAPPE ] pict 'y'
 read

 if Isready( 12 )

  mpos := at( ',', specvars[ PDTARR ][ specvars[ ORDINAL ] ] )
  if mpos > 0
   sID := left( specvars[ PDTARR ][ specvars[ ORDINAL ] ], mpos-1 )

  else
   sID := specvars[ PDTARR ][ specvars[ ORDINAL ] ]

  endif

  keyboard sID + chr( K_ENTER )
  specvars[ APPENDING ] := TRUE

 endif
endif

Box_Restore( mscr )

return nil

