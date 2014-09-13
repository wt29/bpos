/*

      Last change:  TG   16 Jan 2011    8:48 pm
*/

Procedure S_Quote

#include "bpos.ch"

local mgo:=FALSE, choice, oldscr:=Box_Save(), aArray

Center( 24,'Opening files for Quote System' )
if Netuse( "customer" )

 if Master_use()

  if Netuse( "quote" )

   set relation to quote->key into customer,;
                to quote->id into master

   mgo := TRUE

  endif

 endif

endif

line_clear(24)

while mgo
 Box_Restore( oldscr )
 Heading("Quotes")
 aArray := {}
 aadd( aArray, { 'Sales', 'Return to Invoices Menu' } )
 aadd( aArray, { 'Create', 'Create a Quote', { || QuoteAdd() } } )
 aadd( aArray, { 'Enquire', 'Enquire on Quotations', { || LaybyEnq( 'quote' ) } } )
 aadd( aArray, { 'Print', 'Reports Menu', { || QuotePrint() } } )
 aadd( aArray, { 'Purge', 'Remove old Quotes from file', { || QuotePurge() } } )

 choice := MenuGen( aArray, 11, 35, 'Quotes' )

 if choice < 2
  exit

 else
  Eval( aArray[ choice, 3 ] )

 endif

enddo

dbcloseall()

return

*

procedure QuoteAdd

local mtot, mkey, mcomm, sID, mqty, mrec, mscr, nQuoteNo, getlist:={}
local mprint, mitems,mdef,keypress,appbrow
local mprice, adding, goloop, mpost_it, mfinish
local dValid, cComment, cSalesRep

while CustFind( NO )

 cls
 Heading('Enter Quote Details')

 if select( "qttemp" ) != 0
  qttemp->( dbclosearea() )

 endif

 select quote
 copy stru to ( Oddvars( TEMPFILE ) )

 if !Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "qttemp" )
  exit

 else
  mdef := NO
  mtot := 0
  mitems := 0
  mkey := customer->key
  mcomm := space(30)
  dValid := BVars( B_DATE ) + 30
  cSalesRep := space( SALESREP_CODE_LEN )
  mscr := Box_Save( 3, 10, 6, 70 )
  @ 04,12 say 'Quote Valid to' get dValid
  @ 05,12 say 'Sales Rep' get cSalesRep pict '@!' valid( dup_chk( cSalesRep, 'salesrep' ) )
  read
  Box_Restore( mscr )

  Highlight( 02, 05, 'Cust. No      => ', mkey )
  Highlight( 02, 35, 'Customer Name => ', left( customer->name, 42 ) )
  Highlight( 03, 05, 'Quote Valid to => ', dtoc( dValid ) )
  Highlight( 03, 35, 'Sales Rep => ', left( lookitup( 'salesrep', cSalesRep ), 15 )  )

  adding := TRUE
  select qttemp
  set relation to qttemp->id into master
  appbrow:=TBrowseDB(04, 0, 23, 79)
  appbrow:HeadSep:=HEADSEP
  appbrow:ColSep:=COLSEP
  appbrow:addColumn( tbcolumnnew( DESC_DESC, { || substr( master->desc, 1, 25 ) } ) )
  appbrow:addColumn( tbcolumnnew( 'Qty', { || transform( qttemp->qty,'999') } ) )
  appbrow:addcolumn( tbcolumnnew( 'Price', { || transform( qttemp->price, '99999.99' ) } ) )
  appbrow:addColumn( tbcolumnnew( 'Extend', { || transform( qttemp->price*qttemp->qty,'99,999.99') } ) )
  appbrow:addcolumn( tbcolumnnew( 'Avail', { || transform( MASTAVAIL, '9999') } ) )
  appbrow:addColumn( tbcolumnnew( ID_DESC, { || idcheck( master->id ) } ) )
  appbrow:freeze:=1
  appbrow:goTop()
  keypress := 0
  goloop := TRUE
  while goloop
   appbrow:forcestable()
   if adding
    keyboard chr( K_INS )

   endif
   keypress := inkey(0)
   if !Navigate( appbrow, keypress )

    do case
    case keypress == K_F8
     mrec := qttemp->( recno() )
     sum qttemp->price * qttemp->qty, qttemp->qty to mtot, mitems
     @ 3,50 say 'Sub Total ' + Ns( mtot, 7, 2 ) + ' (' + Ns( mitems ) + ')'
     qttemp->( dbgoto( mrec ) )

    case keypress == K_DEL
     if Isready( 6, 12 , 'Ok to delete desc "'+trim( left( master->desc, 20 ) ) + '" from quote' )
      Del_rec( 'qttemp', UNLOCK )
      eval( appbrow:skipblock , -1 )
      appbrow:refreshall()
     endif

    case keypress == K_INS
     sID := space( ID_ENQ_LEN )
     mscr := Box_Save( 6, 18, 8, 62 )
     @ 7, 20 say 'Scan Code or Enter Stock ID' get sID pict '@!'
     read
     Box_Restore( mscr )
     if !updated()
      adding := FALSE
      appbrow:gotop()

     else
      if !Codefind( sID )
       select qttemp
       Error( DESC_DESC + ' not on File', 12 )

      else
       select qttemp
       mscr:=Box_Save( 6, 02, 10, 75 )
       @ 07, 04 say 'Desc                      Price     Qty'
       @ 08, 03 say left( master->desc, 24 )
       mqty := if( mdef, 1, 0 )
       mprice := master->sell_price
       cComment := Space( 40 )
       if !mdef
        @ 8,29 get mprice pict '9999.99' valid( mPrice < 9000 )
        @ 8,41 get mqty pict '999'
        @ 9,04 say 'Line Comments' get cComment
        read

       endif
       Box_Restore( mscr )
       if mqty > 0
        Add_Rec( 'qttemp' )
        qttemp->id := master->id
        qttemp->key := mkey
        qttemp->qty := mqty
        qttemp->price := mprice
        qttemp->date := Bvars( B_DATE )
        qttemp->valid := dValid
        qttemp->comment := cComment
        qttemp->salesrep := cSalesRep
        qttemp->( dbrunlock() )

        if adding
         appbrow:down()
         mtot += qttemp->price * qttemp->qty
         mitems += qttemp->qty
         Highlight( 3, 55, 'Sub Total ', Ns( mtot, 7, 2 ) + ' (' + Ns( mitems ) + ')' )

        endif

       endif

      endif

     endif
     appbrow:gobottom()

    case keypress == K_ENTER
     mscr := Box_Save( 04, 08, 08, 72 )
     @ 05,11 say 'Desc                                Price       Qty'
     @ 06,10 say left( master->desc, 30 )
     @ 06,46 get price pict '9999.99' valid( qttemp->price < 9000 )
     @ 06,59 get qty pict '999'
     @ 07, 10 say 'Comments' get comment
     Rec_lock()
     read
     if qttemp->qty = 0
      delete

     endif
     dbrunlock()
     Box_Restore( mscr )
     appbrow:Refreshcurrent()

    case keypress == K_ESC .or. keypress == K_END
     mpost_it := NO
     mprint := YES
     mfinish := FALSE
     mscr := Box_Save( 19, 20, 23, 54 )
     @ 20,22 say '   Finished Processing?' get mfinish pict 'y'
     @ 21,22 say ' Ok to Post this Quote?' get mpost_it pict 'y'
     @ 22,22 say 'Ok to Print this Quote?' get mprint pict 'y'
     read
     Box_Restore( mscr )
     goloop := !mfinish

    endcase

   endif

  enddo

  if mpost_it
   nQuoteNo := Sysinc( 'quote', 'I', 1, 'quote' )
   Box_Save( 21, 08, 24, 71 )
   Center( 22,'Now Posting Quote #' + Ns( nQuoteNo ) )

   select qttemp
   indx( "id", 'id' )
   total on qttemp->id to ( Oddvars( TEMPFILE2 ) ) fields qty

   qttemp->( orddestroy( 'id' ) )
   qttemp->( dbclosearea() )

   if Netuse( Oddvars( TEMPFILE2 ), EXCLUSIVE , 10 , 'qttemp' )
//    indx( "desc", 'desc' )
    qttemp->( dbgotop() )
    while !qttemp->( eof() ) .and. Pinwheel()
     Add_rec( 'quote' )
     quote->number := nQuoteNo
     quote->key := qttemp->key
     quote->id := qttemp->id
     quote->qty := qttemp->qty
     quote->price := qttemp->price
     quote->date := Bvars( B_DATE )
     quote->valid := dValid
     quote->comment := qttemp->comment
     quote->SalesRep := qttemp->SalesRep
     quote->( dbrunlock() )

     qttemp->( dbskip() )

    enddo

    qttemp->( orddestroy( 'desc' ) )
    qttemp->( dbclosearea() )

   endif
   select quote

   if mprint
    Center(23,'-=< Quote Printing in Progress >=-')

//    Print_find("report")
    QuoteForm( nQuoteNo )

   endif
  endif
 endif
enddo
return

*

procedure QuotePrint

local nQuoteNo,oldscr:=Box_Save(), choice, aArray, getlist:={}, mscr, farr

memvar mall, mkey, moutstand

private mall := NO, mkey, moutstand

farr := {}
aadd(farr,{'Idcheck(id)', ID_DESC, ID_CODE_LEN, 0, FALSE } )
aadd(farr,{'left(master->desc,40)', DESC_DESC, 40, 0, FALSE } )
aadd(farr,{'qty','Qty', 3, 0, TRUE } )
aadd(farr,{'price','Price', 6, 2, FALSE } )
aadd(farr,{'price*qty','Price;Extended',10, 2, TRUE } )
aadd(farr,{'space(1)', ' ', 1, 0, FALSE } )
aadd(farr,{'date','Date of;Quote', 8, 0, FALSE } )
aadd(farr,{'space(1)', ' ', 1, 0, FALSE } )
aadd(farr,{'valid','Valid;Until', 8, 0, FALSE } )
aadd(farr,{'space(1)', ' ', 1, 0, FALSE } )
aadd(farr,{'customer->name','Customer Name', 25, 0, FALSE } )
aadd(farr,{'customer->phone1','Telephone1', 14, 0, FALSE } )

while TRUE

 Box_Restore( oldscr )
 Heading('Quote Print Menu')
 Print_find( 'Report' )
 aArray := {}
 aadd( aArray, { 'Exit', 'Return to Quote Menu' } )
 aadd( aArray, { 'Reprint', 'Reprint Single Quote' } )
 aadd( aArray, { 'All', 'Print entire Quote File' } )
 aadd( aArray, { 'Customer', 'Print all quotes for customer' } )
 choice := Menugen( aArray, 15, 36, 'Print' )
 select quote

 do case
 case choice = 2
  nQuoteNo := 0
  Heading( 'Reprint Quote' )
  Box_Save( 2, 08, 4, 72 )

  @ 03, 10 say 'Quote Number to reprint' get nQuoteNo pict '999999'
  read
  if updated()
   if !dbseek( nQuoteNo )
    Error( "Quote Number not on File", 12 )

   else
    Box_Save( 2, 08, 6, 72 )
    Highlight( 03, 10, 'Customer Name', customer->name )
    Highlight( 04, 10, 'First ' + DESC_DESC + ' on file', alltrim( master->desc ) )
    if Isready(12)
     QuoteForm( nQuoteNo )

    endif

   endif

  endif

 case choice = 3
  Heading('Print All Quote Details')
  mscr := Box_Save( 03, 08, 05, 55 )
  mall := FALSE
  @ 04, 10 say 'Include expired Quotes' get mall pict 'y'
  read
  if Isready(17)
   Reporter( farr, 'All Outstanding Quotes on file','number','"Quote Number: "+Ns(number)+"  Sales Rep: "+salesrep','','', FALSE, ;
            'if( mall, .t., valid>=date)')

   Endprint()

  endif
  Box_Restore( mscr )

 case choice = 5
  Heading('Print all Quotes for Customer')
  if CustFind( FALSE )
   mkey := customer->key
   select quote
   ordsetfocus( BY_KEY )
   if !dbseek( mkey )
    Error( 'No Quotes found for Customer', 12 )

   else
    moutstand := TRUE
    Box_Save( 2, 10, 5, 70 )
    Highlight( 3, 12, 'Print all quote details for', trim( customer->name ) )
    read

    if Isready(07)
     Reporter(farr,'"All Quotes for "+customer->name','number','"Quote Number : "+Ns(number)','','',;
                     FALSE,'.t.','quote->key = mkey')

     Endprint()

    endif

   endif
   ordsetfocus( BY_NUMBER )

  endif

 case choice < 2
  return

 endcase

enddo

*

proc Quotepurge
local mdate := Bvars( B_DATE ) - 365, getlist:={}

if Secure( X_SYSUTILS )
 Heading('Purge Old Quotes')
 Box_Save( 2, 08, 4, 72 )

 @ 03, 10 say 'Delete all Quotes older than' get mdate
 read
 if lastkey() != K_ESC
  select quote
  Box_Save( 2, 08, 10, 72 )
  Center( 3, 'You are about to delete all Quotes older than' )
  Center( 5, dtoc( mdate ) )
  if Isready(7)
   ordsetfocus( BY_NUMBER )
   quote->( dbgotop() )
   while !quote->( eof() )
    if quote->date <= mdate
     Highlight( 6, 10, 'Quote No ', Ns( quote->number ) )
     Highlight( 7, 10, 'Customer ', customer->name)
     Rec_lock('quote')
     quote->( dbdelete() )

    endif
    quote->( dbskip() )

   enddo
   SysAudit("QuotePurge" + dtoc( mdate ) )

  endif

 endif

endif

return

