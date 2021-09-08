/*
        Arstat.prg
        

      Last change:  TG   15 May 2010   10:32 am
*/
Procedure ArStat

#include "bpos.ch"


local choice, oldscr := Box_Save(), getlist:={}, aArray
local printzero, stm1, stm2, stm3, mdate := Bvars( B_DATE )

if Ar_file_open( SHARED )
 while TRUE
  printzero := NO
  Box_Restore( oldscr )
  Heading('Print Statements')
  aArray := {}
  aadd( aArray, { 'EOM', 'Return to End of Month Menu' } )
  aadd( aArray, { 'One', 'Statement for a Single Debtor' } )
  aadd( aArray, { 'All', 'Statements for all Debtors' } )
  aadd( aArray, { 'Starting', 'Statements for all Starting With' } )
  aadd( aArray, { 'Message', 'Add a message to Statements' } )
  choice := MenuGen( aArray, 10, 03, ,'Statements')
  do case
  case choice = 2 .or. choice = 4
   if CustFind( TRUE )
    Debtdisp()

    Print_find("report")

    if Isready(14)
     if choice = 4
      Box_Save(12,01,15,78)
      @ 13,05 say 'Print s/ments for debtors with current t/actions but zero balances';
              get printzero pict 'y'
      read
     else
      printzero := TRUE
     endif
     if Statgo( choice, printzero )
      Endprint()
     endif
    endif
   endif
  case choice = 3
   select customer
   go top
   Box_Save(12,01,15,78)
   @ 13,05 say 'Print s/ments for debtors with current t/actions but zero balances';
           get printzero pict 'Y'
   read
   Print_find("report")

   // Pitch10()
   if Isready(14)
    if Statgo( choice, printzero )
     Endprint()
    endif
   endif
  case choice = 5
   Box_Save(6,09,10,70)
   stm1 := Bvars( B_STMESS1 )
   stm2 := Bvars( B_STMESS2 ) 
   stm3 := Bvars( B_STMESS3 )
   @ 7,12 say "Line 1:" get stm1 pict '@K!'
   @ 8,12 say "Line 2:" get stm2 pict '@K!'
   @ 9,12 say "Line 3:" get stm3 pict '@K!'
   read
   bvars( B_STMESS1, stm1 )
   bvars( B_STMESS2, stm2 )
   bvars( B_STMESS3, stm3 )
  case choice < 2
   close databases
   return
  endcase
 enddo
endif

*

function Statgo ( choice, printzero, mdate )
local hasbal, mscr := Box_Save(), statedone:=NO
Box_Restore( mscr )
sele customer
while !customer->(eof())
 if inkey() = K_ESC
  set device to screen
  Error("Statement Print Terminated !",16)
  return statedone
 endif
 hasbal := ( customer->amtcur != 0 .or. customer->amt30 != 0 .or. ;
           customer->amt60 != 0 .or. customer->amt90 != 0 )
 if hasbal .or. ( printzero .and. debtrans->( dbseek( customer->key ) ) )
  Box_Save( 3,10,5,70 )
  Highlight( 4, 12, 'Processing', customer->name )
  Stateprint( mdate )
  statedone := YES
 endif
 sele customer
 if choice = 2
  go bott
 endif
 skip alias customer
enddo
return statedone

*

procedure stateprint ( mdate )
local strow:=24,p_bal:=0,page:=1
field tnum, amt, amtpaid, ttype, date

set device to print
set console off
Sthead( page, mdate )
page++
if !customer->op_it
 @ strow,1 say 'Balance Brought Forward'
 @ strow,40 say customer->laststat pict '9999999.99'
 @ strow,61 say 'Bal bf'
 @ strow,68 say customer->laststat pict '9999999.99'
 strow++
 p_bal:=customer->laststat
endif
select debtrans
seek customer->key
while !debtrans->( eof() ) .and. debtrans->key = customer->key
 @ strow,0 say date
 @ strow,10 say trim( tsname(ttype) + tnum )
 p_bal+=amt-amtpaid
 if amt > 0
  @ strow,18 say amt pict '9999999.99'
  @ strow,28 say amtpaid pict '9999999.99'
 else
  @ strow,18 say amtpaid pict '9999999.99'
  @ strow,28 say amt pict '9999999.99'
 endif
 @ strow,40 say p_bal pict '9999999.99'
 @ strow,53 say substr(dtoc(date),1,5)
 @ strow,60 say substr(tname(ttype),1,2) + tnum
 @ strow,68 say amt-amtpaid pict '9999999.99'
 strow++
 #ifdef STATCOMMENTS
 if !empty(debtrans->comment)
  @ strow, 0 say 'Ref:'+debtrans->comment
  strow++
 endif
 #endif
 skip
 if strow > 55
  Stfoot( p_bal, ( !eof() .and. debtrans->key = customer->key ) )
  Sthead( page, mdate )
  page++
  strow:=24
 endif
enddo
if !empty(Bvars( B_STMESS1 ) )
 @ strow,05 say chr( 218 ) + Replicate( chr(196),42 ) + chr( 191 )
 @ strow+1,05 say chr( 179 ) + padr( Bvars( B_STMESS1 ), 42 ) + chr( 179 )
 @ strow+2,05 say chr( 179 ) + padr( Bvars( B_STMESS2 ), 42 ) + chr( 179 )
 @ strow+3,05 say chr( 179 ) + padr( Bvars( B_STMESS3 ), 42 ) + chr( 179 )
 @ strow+4,05 say chr( 192 ) + replicate( chr(196),42 ) + chr( 217 )

endif
Stfoot( p_bal, FALSE )
select customer
set device to screen
set console on
return

*

procedure sthead( stpage, mdate )
default mdate to Bvars( B_DATE )
mdate := dtoc( mdate )
if stpage > 1
 @ 1,0 say 'Page No ' + Ns(stpage,3)
endif
@ 03,0 say chr(14) + trim(trim( BVars( B_NAME ) )) + chr(20) + chr(13)
setprc( 3, 0 )
@ prow(),54 say trim( BVars( B_NAME ) )
@ 04,00 say Bvars( B_ADDRESS1 )
@ 04,54 say substr(Bvars( B_ADDRESS1 ), 1, 24 )
if !empty(Bvars( B_ADDRESS2 ) )
 @ 05,00 say Bvars( B_ADDRESS2 )
 @ 05,54 say substr(Bvars( B_ADDRESS2 ), 1, 24 )
 @ 06,00 say Bvars( B_SUBURB )
 @ 06,54 say substr( Bvars( B_SUBURB ), 1, 24 )
 @ 07,00 say alltrim(Bvars( B_COUNTRY ))
 @ 07,54 say alltrim(Bvars( B_COUNTRY ))
 @ 08,00 say 'Telephone ' + Bvars( B_PHONE )
 @ 08,54 say 'P' + Bvars( B_PHONE ) 
else
 @ 05,10 say Bvars( B_SUBURB )
 @ 05,54 say substr(Bvars( B_SUBURB ), 1, 24 )
 @ 06,10 say 'Telephone ' + Bvars( B_PHONE )
 @ 06,54 say Bvars( B_PHONE )
endif
@ 09,12 say 'Account No. ' + customer->key
@ 09,54 say 'Account No. ' + customer->key
if len(trim(customer->name)) > 28
 @ 13,10 say chr(27) + chr(77) + substr( customer->name, 1, 43 )
 @ 13,64 say substr( customer->name, 1, 25 )
 @ 14,12 say substr( customer->add1, 1, 43 )
 @ 14,64 say substr( customer->add1, 1, 25 )
 @ 15,12 say substr( customer->add2, 1, 43 )
 @ 15,64 say substr( customer->add2, 1, 24 )
 @ 16,12 say trim(substr(customer->add3,1,40)) + ' ' + customer->pcode
 @ 16,64 say trim(substr(customer->add3,1,20)) + ' ' + customer->pcode
 @ 17,00 say chr(27) + chr(80)
else
 @ 13,12 say customer->name
 @ 13,54 say substr(customer->name,1,24)
 @ 14,12 say customer->add1
 @ 14,54 say substr(customer->add1,1,24)
 @ 15,12 say customer->add2
 @ 15,54 say substr(customer->add2,1,24)
 @ 16,12 say trim(customer->add3) + ' ' + customer->pcode
 @ 16,54 say trim(substr(customer->add3,1,20)) + ' ' + customer->pcode
endif
@ 20,04 say 'Statement for the period ending '+( substr( mdate, 1, 2 ) + '-' + ;
        substr(cmonth( Bvars( B_DATE ) ), 1, 3 )+'-'+substr( mdate, 7, 2 ) )
@ 20,54 say "S'ment Date " + (substr( mdate, 1, 2 )+'-'+;
        substr(cmonth( Bvars( B_DATE ) ), 1, 3 )+'-'+substr( mdate, 7, 2 ) )
@ 22,04 say 'Date'
@ 22,11 say 'Reference'
@ 22,23 say 'Debit'
@ 22,33 say 'Credit'
@ 22,43 say 'Balance'
@ 22,53 say 'Date'
@ 22,60 say 'Ref No.'
@ 22,72 say 'Amount'
return
*
procedure stfoot ( p_bal, more )
@ 58,03 say '90+ Days'
@ 58,16 say '60 Days'
@ 58,29 say '30 Days'
@ 58,42 say 'Current'
@ 60,01 say customer->amt90 pict '9999999.99'
@ 60,13 say customer->amt60 pict '9999999.99'
@ 60,25 say customer->amt30 pict '9999999.99'
@ 60,39 say customer->amtcur pict '9999999.99'
if !more
 @ 60,56 say 'Amount Due'
 @ 60,67 say p_bal pict '9999999.99'
 @ 63,02 say 'Terms: Strictly Nett - Payment now due'
 @ 63,40 say p_bal pict '9999999.99'
 @ 63,56 say 'Enclosed    $'
else
 @ 60,56 say 'Continued ...... '
 @ 63,02 say 'Statement Continued Next Page.....'
endif
return


