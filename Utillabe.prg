
/*

 BPOS - Bluegum Software

 Last change: APG 1/08/2008 9:28:40 AM

 Last change:  TG   15 May 2010   10:32 am

*/

#include "bpos.ch"

Procedure U_Labels

local mqty,sID,getlist:={},oldscr:=Box_Save(), choice
local aMenuItems

if Master_use()
 while TRUE
  Box_Restore( oldscr )
  Heading('Label Production')
  aMenuItems := {}
  aadd( aMenuItems, { 'Utility', 'Return to Utility' } )
  aadd( aMenuItems, { 'Barcodes', 'Print extra Barcode Labels' } )
  aadd( aMenuItems, { 'Stk Cards', 'Print Stock Card Labels' } )
  choice := MenuGen( aMenuItems, 05, 50, 'Labels' )
  if choice < 2
   dbcloseall()
   return

  else
   Print_find("barcode")

   while TRUE

    Box_Save( 2, 08, 15, 72 )
    Heading('Print Extra Barcodes')
    sID := space( ID_ENQ_LEN )
    @ 3,10 say 'Scan Code or Enter ' + ID_DESC get sID pict '@!'
    read
    if !updated()
     exit

    else
     if !Codefind( sID )
      Error( 'Code Not on file', 12 )

     else
      mqty := 0
      Highlight( 5, 10, ID_DESC, idcheck( master->id ) )
      Highlight( 7, 10, 'Desc ', trim( master->desc ) )
      Rec_lock('master')
      @ 09,10 say '       Sell Price' get sell_price
      @ 11,10 say 'Quantity to print' get mqty pict '99'
      read
      master->( dbrunlock() )

      if mqty > 0 .and. lastkey() != K_ESC

       Print_find( 'barcode' )
       

       if choice = 2
        Code_print( master->id, mqty )

       else
        StkCard( master->id, mqty )

       endif
      endif
     endif
    endif
   enddo
  endif
 enddo
endif
close databases
return

*

Function Stuffkey ( mval )  // Useful little function
keyboard mval
return TRUE

*

procedure code_print ( sBarcode, mqty )

local x, sString := ''
sBarcode := trim( sBarcode )

set console off
set print on

for x = 1 to mqty

 sString += '^XA' + CRLF
 sString += '^PW250' + CRLF
 sString += '^FO10, 18' + CRLF
 sString += '^ABN,30,15' + CRLF
#ifdef LYTTLETON
 sString += '^FDLyttleton' + CRLF
#else 
 sString += '^FD' + trim( BVars( B_NAME ) ) + CRLF
#endif
 sString += '^FS' + CRLF
 sString += '^FO10,55' + CRLF
 if len( trim( sBarcode ) ) >= 12
  sString += '^BEN,50,Y,N' + CRLF
  sString += '^FD' + left( sBarcode, 12 ) + CRLF

 else
#ifdef THE_LOOK
  sString += '^B2N,40,Y,N,N' + CRLF
#else
  sString += '^B3N,N,60,Y,N' + CRLF
#endif
  sString += '^FD' + trim( sBarcode ) + CRLF

 endif
 // Print Price
 sString += '^FS' + CRLF
 sString += '^FO10,145' + CRLF
 sString += '^ADN,30,25' + CRLF
 sString += '^FD$' + ltrim( ns( master->sell_price, 10, 2 ) ) + CRLF
 // Print Description
 sString += '^FS' + CRLF
 sString += '^FO10,190' + CRLF
 sString += '^ADN,12,12' + CRLF
 sString += '^FD' + trim( master->desc ) + CRLF
 
 sString += '^XZ' + CRLF

next x

? sString

set console on
set print off

EndPrint( NO_EJECT )

return

*

Function StkCard ( mqty )
local x
// Pitch10()
set console off
set print on
for x := 1 to mqty
 ?
 ? master->alt_desc
 ? master->desc
 ? lookitup( 'supplier', master->supp_code )
 ? master->catalog
 ?
next
set console on
set print off
return nil

