/*

 General Forms definitions - Usually copied and recreated as a 'Site' file

      Last change:  TG   29 Apr 2011    4:46 pm
*/

#include "bpos.ch"

#define SIDES '|'
#define B_TLEFT '*'
#define B_TRIGHT '*'
#define B_BLEFT '*'
#define B_BRIGHT '*'

procedure Invform ( nInvoiceNo )
local p_tot:=0, mtotdisc:=0, pass:=1, arebo:=FALSE, mdisctot
local mordno:='+@#@#=', tax_tot:=0, page:=1, qty_tot:=0, p_ext

local oPrinter := Printcheck( 'Invoice: ' + Ns( nInvoiceNo ), 'Invoice' )    // Default Font

select invhead
seek nInvoiceNo
select customer
seek invhead->key

Invformhead( nInvoiceNo, FALSE, TRUE, oPrinter )

for pass := 1 to 2
 select invline
 seek invhead->number
 if pass = 2 .and. arebo
  LP( oPrinter, PRN_RED )
  LP( oPrinter, BOLD )
  LP( oPrinter, 'We have backordered for you', 10 )
  LP( oPrinter, NOBOLD )
  LP( oPrinter, PRN_BLACK )

 endif

 while invline->number = nInvoiceNo .and. !invline->( eof() )
  if invline->ord - invline->qty > 0
   arebo := TRUE

  endif
  if ( pass = 1 .and. invline->qty > 0 .or. invline->id = '*' ) .or. (pass = 2 .and. invline->ord - invline->qty > 0)
   if invline->id = '*' .and. pass = 1
    LP( oPrinter, invline->comments, 0 )   // a "*" indicates a comment only line

   else
    if invline->id != '*'
     if invline->req_no != mordno .and. customer->sort_ord == 'O'
      LP( oPrinter, 'Your Order No : ' + invline->req_no, 0 )
      mordno := invline->req_no

     endif
     LP( oPrinter, transform( if( pass=1, invline->qty, invline->ord - invline->qty ), '9999' ), 0, NONEWLINE ) // Backordered
     LP( oPrinter, substr( master->desc, 1, 35 ), 6, NONEWLINE )
     LP( oPrinter, transform( invline->sell, '9999.99' ), 42, NONEWLINE )
     if invline->price != invline->sell
      LP( oPrinter, transform( PercentOf( invline->price, invline->sell ), '99.9' ) + '%', 50, NONEWLINE )

     else
      LP( oPrinter, 'Nett', 50, NONEWLINE )

     endif
     LP( oPrinter, transform( invline->sell - invline->price, '999.99' ), 55, NONEWLINE )   // Amount of discount
     LP( oPrinter, transform( invline->price, '9999.99' ), 63, NONEWLINE )                  // Price is the selling price - OK for GST
     if pass = 1
      LP( oPrinter, transform( invline->price * invline->qty, '99999.99' ), 70 )    // Should do a newline
      p_tot += round( invline->price * invline->qty, 2 )
      p_ext = invline->price * invline->qty                // Extend the selling prive
      tax_tot += invline->tax * invline->qty               // Calculate the tax
      qty_tot += invline->qty

     else
      oPrinter:NewLine()                                   // Need this because we aren't printing backordered item extends

     endif

    endif
    if !empty( invline->comments ) .and. invline->id != '*'
     LP( oPrinter, ':' + alltrim( invline->comments ), 6 )

    endif
    if oPrinter:prow() > 65
     LP( oPrinter, 'continued....' )
     oPrinter:NewPage()
     Invformhead( nInvoiceNo, FALSE, FALSE, oPrinter )

    endif

   endif

  endif
  invline->( dbSkip() )

 enddo

next  // pass

if !empty( invhead->message1 ) .and. oPrinter:prow() > 54
  oPrinter:NewPage()
  Invformhead( nInvoiceNo, FALSE, FALSE, oPrinter )

endif

p_tot := round( p_tot, 2 )

LP( oPrinter, "---------", 70 )

if invhead->tot_disc > 0 .and. invhead->tot_disc <= 100

#ifdef NO_NETT_DISCOUNTS
 mdisctot := 0
 invline->( dbseek( invhead->number ) )
 while invline->number = invhead->number .and. !invline->( eof() )
  if !master->nodisc
   mdisctot += invline->qty * ( invline->price/100 * invhead->tot_disc )

  endif
  invline->( dbskip() )

 enddo 
#else
 mdisctot := round( ( p_tot / 100 * invhead->tot_disc ), 2 )

#endif

 tax_tot := Zero( tax_tot, round( Zero( mdisctot, p_tot ), 2 ) )     // Rationalise tax ??

 LP( oPrinter,  'Less overall discount of ' + Ns( invhead->tot_disc, 5,1) + '%', 12, NONEWLINE )
 LP( oPrinter, transform( mdisctot, '99999.99' ), 71 )

 p_tot -= mdisctot

endif

if !empty( invhead->freight )
 LP( oPrinter, 'Post & Packing', 49, NONEWLINE )
 LP( oPrinter, transform( invhead->freight, '99999.99' ), 70 )
 p_tot += invhead->freight
 tax_tot += GetGSTComponent( invhead->freight )  // Figure out the GST component

endif

LP( oPrinter, transform( qty_tot, '9999' ) + '   (Total Items Supplied)', 0, NONEWLINE )

if invhead->inv
 LP( oPrinter, 'Total Invoice Less GST', 42, NONEWLINE )

else
 LP( oPrinter, ' Total Credit Less GST', 42, NONEWLINE )

endif
LP( oPrinter, BOLD )
tax_tot := p_tot / 11
LP( oPrinter, transform( p_tot - tax_tot, '99999.99' ), 70 )
LP( oPrinter, NOBOLD )

LP( oPrinter,  '             Total GST', 42, NONEWLINE )
LP( oPrinter,  transform( tax_tot, '99999.99' ), 70  )
LP( oPrinter, '          Total Invoice', 42, NONEWLINE )
LP( oPrinter, transform( p_tot, '99999.99' ), 70 )

LP( oPrinter, DRAWLINE )
LP( oPrinter )
LP( oPrinter, SCRIPTCHARS )
LP( oPrinter, space( 45 ) + 'Thank you for your order' )
LP( oPrinter, NOBIGCHARS )

if !empty( invhead->message1 )
 oPrinter:NewLine()
 LP( oPrinter, B_TLEFT + replicate( '-', 42 )+B_TRIGHT, 05 )
 LP( oPrinter, SIDES + ' ' + invhead->message1 + ' ' + SIDES, 05 )
 LP( oPrinter, SIDES + ' ' + invhead->message2 + ' ' + SIDES, 05 )
 LP( oPrinter, SIDES + ' ' + invhead->message3 + ' ' + SIDES, 05 )
 LP( oPrinter, B_BLEFT+replicate( '-', 42 )+B_BRIGHT, 05 )

endif

oPrinter:endDoc()
oPrinter:Destroy()

return

*

Procedure invformhead ( nInvoiceNo, mpickslip, newinv, oPrinter )
local cType
static page

if newinv
 page := 1

endif

if !mpickslip
 if invhead->inv
  cType := 'Tax Invoice'

 else
  cType := 'Credit Note'

 endif
else
 cType := 'Picking Slip'

endif


oPrinter:NewLine()
LP( oPrinter, BIGCHARS )
LP( oPrinter, BOLD )
LP( oPrinter, cType + " No: " +  transform( nInvoiceNo, '999999' ), 0, NONEWLINE )
LP( oPrinter, 'Date: ' + dtoc( invhead->date), 60 ) //  Should give a new line
LP( oPrinter, NOBOLD )
LP( oPrinter, NOBIGCHARS )

if page > 1
 LP( oPrinter, 'Page No: ' + Ns( page, 3 )  )

endif
page++

oPrinter:NewLine()
LP( oPrinter, PRN_GREEN )
LP( oPrinter, BOLD )
LP( oPrinter, VERYBIGCHARS )
LP( oPrinter, upper( trim( BVars( B_NAME ) ) ), 20 )
LP( oPrinter, NOBIGCHARS )
LP( oPrinter, NOBOLD )
LP( oPrinter, PRN_BLACK )
LP( oPrinter, 'ACN ' + Bvars( B_ACN ), 20 )
LP( oPrinter, Bvars( B_ADDRESS1 ), 20 )
LP( oPrinter, Bvars( B_ADDRESS2 ), 20 )
LP( oPrinter, Bvars( B_SUBURB ), 20 )
LP( oPrinter, Bvars( B_PHONE ), 20 )
oPrinter:NewLine()

if !mpickslip
 LP( oPrinter, BOLD )
 if invhead->inv
  LP( oPrinter, 'Invoice to :', 10, NONEWLINE )
  LP( oPrinter, 'Deliver to :', 42  )

 else
  LP( oPrinter, 'Credit  to :', 10 )

 endif
 LP( oPrinter, NOBOLD )

endif
LP( oPrinter, customer->name, 10, NONEWLINE )
LP( oPrinter, customer->name, 42 )
if !empty(customer->contact)
 LP( oPrinter, 'Attn : ' + customer->contact, 10 )

endif

LP( oPrinter, customer->add1, 10, NONEWLINE )
LP( oPrinter, customer->dadd1, 42 )            // New Line
LP( oPrinter, customer->add2, 10, NONEWLINE  )
LP( oPrinter, customer->dadd2, 42 )
LP( oPrinter, trim(customer->add3) + if(!empty(customer->add3),' ', "") + customer->pcode, 10, NONEWLINE )
LP( oPrinter, trim(customer->dadd3) + if(!empty(customer->dadd3),' ', "") + customer->dpcode, 42 )  // New Line
if !mpickslip
 oPrinter:NewLine()
 oPrinter:NewLine()
 LP( oPrinter, 'Your Reference: ', 0, NONEWLINE )
 LP( oPrinter, BOLD )
 LP( oPrinter, invhead->order_no, 15, NONEWLINE )
 LP( oPrinter, NOBOLD )

endif
LP( oPrinter, 'Account No: ', 58, NONEWLINE )
LP( oPrinter, BOLD )
LP( oPrinter, customer->key, 70  )
LP( oPrinter, NOBOLD )

LP( oPrinter,  "--", 0, NONEWLINE )  // New Line
LP( oPrinter, "--", 76  )

if !mpickslip
 LP( oPrinter, ' Qty', 0, NONEWLINE )
 LP( oPrinter, 'Desc', 6, NONEWLINE )
 LP( oPrinter, 'Price', 44, NONEWLINE )
 LP( oPrinter, 'Disc', 50, NONEWLINE )
 LP( oPrinter, 'Value', 56, NONEWLINE )
 LP( oPrinter, ' Sell  Extend', 65 )
 LP( oPrinter, DRAWLINE )

else
 LP( oPrinter, 'Picked', 0, NONEWLINE )
 LP( oPrinter, ' Qty ', 6 )
 LP( oPrinter, ' Desc', 13, NONEWLINE )
 LP( oPrinter, 'ID', 46, NONEWLINE )
 LP( oPrinter, BRAND_DESC, 59, NONEWLINE )
 LP( oPrinter, ALT_DESC, 76, NONEWLINE )
 LP( oPrinter, 'Sta', 92, NONEWLINE )
 LP( oPrinter,  'Bi', 96 )
 LP( oPrinter, DRAWLINE )

endif
return

*

proc PickSlip ( nInvoiceNo )
local pwidth := lvars( val( substr( lvars( L_PRINTER ), 4, 1 ) ) + 7 )
setprc(0,0)

set device to print
set console off
select pickslip
set relation to pickslip->id into master,;
             to pickslip->key into customer
Invformhead( nInvoiceNo, TRUE, TRUE )
select pickslip
seek nInvoiceNo
while !pickslip->( eof() ) .and. pickslip->number = nInvoiceNo .and. Pinwheel()
 @ prow()+1,00 say '[     ]'
 @ prow(),07 say pickslip->qty pict '9999'
 @ prow(),13 say substr(master->desc,1,30)
 @ prow(),45 say idcheck( master->id )
 @ prow(),58 say substr( Lookitup( "brand" , master->brand ) , 1, 15 )
 @ prow(),75 say substr(master->alt_desc,1,15)
 @ prow(),92 say master->status
 @ prow(),96 say master->binding
 if prow() > 55
  @ prow()+1,10 say 'continued....'
  Invformhead( nInvoiceNo, TRUE, FALSE )

 endif
 skip

enddo
select pickslip
set relation to
EndPrint()
set console on
set device to screen
return

*

procedure Poform ( ponum )
local nRow := 35, page_no:=1, potot:=0, mcom, maxwidth := 76, x, mlines
local oPrinter

pohead->( ordsetfocus( BY_NUMBER ) )
pohead->( dbseek( ponum ) )
supplier->( dbseek( pohead->supp_code ) )

oPrinter := Printcheck( 'PO:' + Ns( ponum ) + '  on Supp Code:' + pohead->supp_code )  // Def to report printer

LP( oPrinter, VERYBIGCHARS )
LP( oPrinter, BOLD )
LP( oPrinter, '' )  // Blank line otherwise the PO looks strange
LP( oPrinter, 'Purchase Order', 25 )
LP( oPrinter, NOBOLD )
LP( oPrinter, NOBIGCHARS )
LP( oPrinter, substr(dtoc(pohead->date_ord),1,2)+'-'+substr(cmonth(pohead->date_ord),1,3);
            +'-'+substr(dtoc(pohead->date_ord),7,2), 0, NONEWLINE )
LP( oPrinter, if( empty(Bvars( B_ACN ) ) , '', "A.C.N. "+Bvars( B_ACN ) ), 62 )
LP( oPrinter )
LP( oPrinter )
LP( oPrinter,'Supply to the order of :', 0, NONEWLINE )
LP( oPrinter, BIGCHARS )
LP( oPrinter, BOLD )
LP( oPrinter, PRN_GREEN )
LP( oPrinter, trim( BVars( B_NAME ) ), 25 )
LP( oPrinter, PRN_BLACK )
LP( oPrinter, NOBOLD )
LP( oPrinter, NOBIGCHARS )
LP( oPrinter, Bvars( B_ADDRESS1 ), 25 )
if !empty( Bvars( B_ADDRESS2 ) )
 LP( oPrinter, Bvars( B_ADDRESS2 ), 25 )

endif
LP( oPrinter, trim( Bvars( B_SUBURB ) ), 25 )
LP( oPrinter, Bvars( B_COUNTRY ), 25 )
LP( oPrinter, 'Tel  ' + Bvars( B_PHONE ), 25 )
LP( oPrinter, 'Fax  ' + Bvars( B_FAX ), 25 )
LP( oPrinter )   // Should add a blank line
LP( oPrinter, 'Account No.  : ' + supplier->Account )
LP( oPrinter )
LP( oPrinter, BIGCHARS )
LP( oPrinter, BOLD )
LP( oPrinter, 'Our Order No : '+ Ns(ponum) )
LP( oPrinter, NOBOLD )
LP( oPrinter, NOBIGCHARS )
LP( oPrinter )
LP( oPrinter )
LP( oPrinter, supplier->name, 15 )
LP( oPrinter, supplier->Address1, 15 )
LP( oPrinter, supplier->Address2, 15 )
LP( oPrinter, supplier->city, 15 )
LP( oPrinter, supplier->country, 15 )
LP( oPrinter )
LP( oPrinter )
LP( oPrinter, 'Fax No. ' + supplier->fax )

LP( oPrinter,  '---', 0, NONEWLINE )
LP( oPrinter,  '---', 78  )

Poheader( oPrinter, ponum, page_no )

poline->( dbseek( ponum ) )

while poline->number = ponum .and. !poline->( eof() ) .and. Pinwheel( NOINTERUPT )

 LP( oPrinter, if( !empty( master->catalog), master->catalog, master->id ), 0, NONEWLINE )
// LP( oPrinter, if( !empty( master->catalog), master->catalog, idcheck( master->id ) ), 0, NONEWLINE )
 LP( oPrinter, transform( poline->qty, '9999' ), 14, NONEWLINE )
 LP( oPrinter, substr(master->desc,1,Backspace() ), 20, NONEWLINE )
 LP( oPrinter, substr(master->alt_desc,1,14), 62, NONEWLINE )
 LP( oPrinter, master->binding, 76  )
 if len( trim( master->desc ) ) > 40
  LP( oPrinter, substr( master->desc,Backspace()+1, 40 ), 20 )

 endif
 if !empty( poline->comment )
  LP( oPrinter, '** ' + trim( poline->comment ), 5 )

 endif
 potot += master->cost_price * poline->qty
 poline->( dbskip() )
 nRow++
 if nRow > 63
  if poline->number = ponum .and. !eof()
   Page_no++
   nRow := 5
   LP( oPrinter, DRAWLINE )
   LP( oPrinter, '....Continued Over' )
   oPrinter:NewPage()
   Poheader( oPrinter, ponum, page_no )

  endif

 endif

enddo
LP( oPrinter, DRAWLINE )
#ifdef DUCKWORTHS
 LP( oPrinter, BIGCHARS )
 LP( oPrinter, 'Please DO / DO NOT backorder these titles.' )
 LP( oPrinter, NOBIGCHARS )
 LP( oPrinter, BIGCHARS )
 LP( oPrinter, 'Quote our order number ' + Ns( ponum ) + ' all correspondence relating to this order.' )
 LP( oPrinter, NOBIGCHARS )
 LP( oPrinter )
 LP( oPrinter, 'For and on behalf of DUCKWORTHS ____________________________________' )

#else

mcom := Lookitup( 'poinstru', pohead->instruct )
if !empty( mcom )
 mcom := strtran( mcom, '%NUMBER%', Ns( ponum ) )
 if '%BIG%' $ mcom
  mcom := strtran( mcom, '%BIG%' )
  maxwidth := 38

 endif
 mlines := mlcount( mcom, maxwidth ) 
 LP( oPrinter )

 LP( oPrinter,  '< Purchase Order Instructions >', 2  )
 for x := 1 to mlines
   if maxwidth = 38
    LP( oPrinter, BIGCHARS )

   endif

   LP( oPrinter, mcom, 2 )

   if maxwidth = 38
    LP( oPrinter, NOBIGCHARS )

   endif

 next

 LP( oPrinter, DRAWLINE )
endif

#endif

set relation to
oPrinter:enddoc()
oPrinter:Destroy()

return

*

procedure poheader ( oPrinter, ponum, page_no )
if page_no > 1
 LP( oPrinter, DRAWLINE )
 LP( oPrinter, trim( BVars( B_NAME ) ), 0, NONEWLINE )
 LP( oPrinter, 'Order No: ' + Ns( ponum, 6 ), 32, NONEWLINE )
 LP( oPrinter, 'Page No: ' + Ns( page_no, 3 ), 66  )

endif
LP( oPrinter, '   ' + ID_DESC + '        Qty  Desc', 0, NONEWLINE )
LP( oPrinter, ALT_DESC, 62, NONEWLINE )
LP( oPrinter, 'Bi', 76 )
LP( oPrinter, DRAWLINE )

return

*

proc specletter ( p_req, p_issued, specordno, mcomments, spec_dep, spec_date, price )
set device to print
set console off
// Pitch10()
@ 0,0 say BIGCHARS + 'Special Order No ' + Ns( specordno ) + NOBIGCHARS
@ prow()+1,60 say BIGCHARS + dtoc(Bvars( B_DATE ) )
@ prow()+1,0 say chr(27)+chr(31)+chr(1)+BIGCHARS+trim( BVars( B_NAME ) ) + NOBIGCHARS;
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
@ prow()+1,15 say customer->add1
@ prow(),55 say '(Ph) ' + customer->phone1
@ prow()+1, 1 say 'Date Ordered ' + dtoc( spec_date )
if !empty(customer->add2)
 @ prow()+1,15 say trim(customer->add2)+if(empty(customer->add3),' '+customer->pcode,'')

endif

if !empty(customer->add3)
 @ prow()+1,15 say trim(customer->add3)+' '+customer->pcode

endif
@ prow()+3,0 say '--                                                                       --'
@ prow()+1,0 say 'Dear Customer,'
@ prow()+2,0 say 'We have received the following desc as per your Special Order'
@ prow()+2,0 say 'Item ID  ' + idcheck( master->id )
@ prow()+1,0 say 'Desc     ' + master->desc
@ prow()+1,0 say 'Alt Desc ' + master->alt_desc
@ prow()+1,0 say 'Qty Ord  ' + Ns( p_req )
@ prow()+1,0 say 'Price   $' + Ns( price, 7, 2 )
if p_req != p_issued
 @ prow()+1,0 say 'Qty Rec  ' + Ns(p_issued)

endif
if !empty( mcomments )
 @ prow()+1,0 say 'Order Comments ' + mcomments

endif
if spec_dep > 0
 @ prow()+2,0 say 'Deposit Paid ' + Ns( spec_dep )

endif
@ prow()+2,0 say 'This Order is now ready for collection. If you would like us to send'
@ prow()+1,0 say 'this book to you, please telephone and have your Credit Card Number'
@ prow()+1,0 say 'ready (MasterCard, Visa, Amex, Diners or Bankcard) and we will be happy to'
@ prow()+1,0 say 'forward your order.'
@ prow()+2,0 say 'Yours Faithfully'
@ prow()+5,0 say 'For ' + trim( BVars( B_NAME ) )
@ prow()+4,0 say 'Please Note.'
@ prow()+1,0 say chr( K_ESC )+'E'+'We would appreciate if the books could be collected within two weeks'
@ prow()+1,0 say 'or telephone us if there will be a delay.'+chr( K_ESC )+'F'
Endprint()
set device to screen
return

*

procedure QuoteForm ( nQuoteNo )

local nTotItems:=0, nQuoteTot:=0, dValid
local oPrinter := Printcheck( 'Quote No: ' + Ns( nQuoteNo ), 'Report' )

quote->( dbseek( nQuoteNo ) )

dValid := quote->valid

QuoteFormHead( nQuoteNo, oPrinter, TRUE )  // New quote

while quote->number = nQuoteNo .and. !quote->( eof() )
 LP( oPrinter, transform( quote->qty, QTY_PICT ), 0, NONEWLINE )
 LP( oPrinter, substr( master->desc, 1, 50 ), 6, NONEWLINE )
 LP( oPrinter, transform( quote->price, PRICE_PICT ), 64, NONEWLINE )
 LP( oPrinter, transform( quote->price*quote->qty, TOTAL_PICT ), 72 )

 nTotItems += quote->qty
 nQuoteTot += quote->qty * quote->price


 if !empty( quote->comment )
  LP( oPrinter, '*** ' + alltrim( quote->comment ) + ' ***', 10 )

 endif

 if oPrinter:prow() > 60
  LP( oPrinter, 'continued....', 6 )
  oPrinter:Newpage()
  QuoteFormhead( nQuoteNo, oPrinter, TRUE )  // New page

 endif

 Quote->( dbSkip() )

enddo

nQuoteTot := round( nQuoteTot, 2 )
oPrinter:SetPos( 70  * oPrinter:CharWidth)

oPrinter:line( oPrinter:posX, ;
               oPrinter:posY - ( oPrinter:charheight / 2 ), ;
               oPrinter:rightMargin, ;
               oPrinter:posY - ( oPrinter:charheight / 2 ) )


oPrinter:NewLine()

LP( oPrinter, transform( nTotItems, '9999' ) + '   (Total Qty)', 0, NONEWLINE )
LP( oPrinter, 'Quote Total', 50, NONEWLINE )
LP( oPrinter, BOLD )
LP( oPrinter, transform( nQuoteTot, TOTAL_PICT ), 72 )
LP( oPrinter, NOBOLD )
LP( oPrinter, DRAWLINE )

LP( oPrinter, BIGCHARS )
LP( oPrinter, BOLD )
LP( oPrinter, 'Quotation is valid until ' + dtoc( dValid ) + ' only' )

oPrinter:endDoc()
oPrinter:Destroy()

return

*

Procedure QuoteFormHead ( nQuoteNo,  oPrinter, lNewQuote )

static nPage

if lNewQuote
 nPage := 1

else
 nPage++

endif

if nPage > 1
 LP( oPrinter, DRAWLINE )
 LP( oPrinter, trim( BVars( B_NAME ) ), 0, NONEWLINE )
 LP( oPrinter, 'Quotation No: ' + Ns( nQuoteNo, 6 ), 32, NONEWLINE )
 LP( oPrinter, 'Page No: ' + Ns( nPage, 3 ), 66 )
 LP( oPrinter, DRAWLINE )

else

 LP( oPrinter, VERYBIGCHARS )
 LP( oPrinter, BOLD )
 LP( oPrinter, 'Quotation', 25 )
 LP( oPrinter, NOBOLD )
 LP( oPrinter, NOBIGCHARS )

 LP( oPrinter, 'Quote Number:', 0 , NONEWLINE )
 LP( oPrinter, BOLD )
 LP( oPrinter, Ns( nQuoteNo ), 16, NONEWLINE )
 LP( oPrinter, NOBOLD )
 LP( oPrinter, 'Date: ', 60, NONEWLINE ) //  + NOBIGCHARS
 LP( oPrinter, BOLD )
 LP( oPrinter, dtoc( quote->date ), 66 ) //  + NOBIGCHARS
 LP( oPrinter, NOBOLD )

 oPrinter:NewLine()
 LP( oPrinter, PRN_GREEN )
 LP( oPrinter, BOLD )
 LP( oPrinter, BIGCHARS )
 LP( oPrinter, trim( BVars( B_NAME ) ), 20 )
 LP( oPrinter, NOBIGCHARS )
 LP( oPrinter, NOBOLD )
 LP( oPrinter, PRN_BLACK )
 LP( oPrinter, 'ACN ' + Bvars( B_ACN ), 20 )
 LP( oPrinter, Bvars( B_ADDRESS1 ), 20 )
 LP( oPrinter, Bvars( B_ADDRESS2 ), 20 )
 LP( oPrinter, Bvars( B_SUBURB ), 20 )
 LP( oPrinter, Bvars( B_PHONE ), 20 )
 oPrinter:NewLine()
 oPrinter:NewLine()

 LP( oPrinter, BOLD )
 LP( oPrinter, 'Customer   :', 10 )   // New line
 LP( oPrinter, NOBOLD )

 LP( oPrinter, customer->name, 10 )
 if !empty( customer->contact )
  LP( oPrinter, 'Attn : ' + customer->contact, 10 )

 endif

 LP( oPrinter, customer->add1, 10 )
 LP( oPrinter, customer->add2, 10  )   // New line
 LP( oPrinter, trim( customer->add3 ) + if( !empty(customer->add3), ' ',  "" ) + customer->pcode, 10 )  // New Line
 LP( oPrinter, '  Account No:', 56, NONEWLINE )
 LP( oPrinter, BOLD )
 LP( oPrinter, customer->key, 70 )
 LP( oPrinter, NOBOLD )

 LP( oPrinter, 'Sales Person:', 56, NONEWLINE )
 LP( oPrinter, BOLD )
 LP( oPrinter, quote->salesRep, 70 )
 LP( oPrinter, NOBOLD )

 LP( oPrinter,  "--", 0, NONEWLINE )  // New Line
 LP( oPrinter, "--", 78 )

 LP( oPrinter, ' Qty', 0, NONEWLINE )
 LP( oPrinter, DESC_DESC, 6, NONEWLINE )
 LP( oPrinter, 'Price', 66, NONEWLINE )
 LP( oPrinter, 'Extend', 74 )
 LP( oPrinter, DRAWLINE )

endif // New Page

return

