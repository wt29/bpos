/*
      Apremit.prg

      Last change:  TG   15 May 2010   10:32 am
*/
Procedure Apremit

#include "bpos.ch"


local oldscr:=Box_Save(), choice, getlist:={}, msupp
local printzero, aArray

if Ap_file_open( Bvars( B_AUTOCRED ) )   // Will require Exclusive Access if Auto Post is Enabled
 while TRUE
  Box_Restore( oldscr )
  printzero := FALSE
  Heading('Print Remittance Advices')
  aArray := {}
  aadd( aArray, { 'EOM', 'Return to Creditors End of Month Menu' } )
  aadd( aArray, { 'One', 'Remittance Advice for Single Creditor' } )
  aadd( aArray, { 'All', 'Remittance Advice for All Creditors' } )
  aadd( aArray, { 'Starting', 'Restart Remittance Advice Run for all Creditors' } )
  choice := MenuGen( aArray, 11, 20, 'Remittance' )
  do case
  case choice = 2 .or. choice = 4
   msupp := space(4)
   Box_Save(2,25,4,55)
   @ 3,28 say 'Enter Supplier Code' get msupp pict '@!' valid( Dup_chk( msupp , 'Supplier' ) )
   read
   if updated()
    if !supplier->( dbseek( msupp ) )
     Error( "Supplier not on File", 12 )
    else
     Creddisp()
     if Isready(14)
      if choice = 4
       Box_Save(12,01,14,78)
       @ 13,05 say 'Print s/ments for creditors with current t/actions but zero balances';
               get printzero pict 'Y'
       read
      endif
      Remitgo( choice, printzero )
     endif
    endif
   endif
  case choice = 3
   select supplier
   go top
   Box_Save(12,01,14,78)
   @ 13,05 say 'Print s/ments for creditors with current t/actions but zero balances' get printzero pict 'Y'
   read
   if Isready(14)
    Remitgo( choice, printzero )
   endif
  case choice < 2
   close databases
   return
  endcase
 enddo
else
 dbcloseall()
 return
endif
*
procedure remitgo ( choice, printzero )
local hasbal
sele supplier
while !eof()
 if inkey() = K_ESC
  set device to screen
  set console on
  Error( "Remittance Advice Print Terminated !", 16 )
  return
 endif
 hasbal := FALSE
 if supplier->amtcur != 0 .or. supplier->amt30 != 0 .or. ;
    supplier->amt60 != 0 .or. supplier->amt90 != 0
  hasbal := TRUE
 endif
 if printzero .or. hasbal
  if cretrans->( dbseek( supplier->code ) ) .or. hasbal
   Remitprint()
  endif
 endif
 select supplier
 if choice = 2
  go bott
 endif
 skip
enddo
return
*
procedure remitprint
local repage:=1,rerow,p_bal:=0, bf_flag
setprc(0,0)
// Pitch10()
set device to print
set console off
rerow := Rehead(repage)
bf_flag := TRUE
cretrans->( dbseek( supplier->code ) )
while !cretrans->( eof() ) .and. cretrans->code = supplier->code
 if bf_flag
  if !supplier->op_it
   @ rerow,11 say 'Balance Brought Forward'
   @ rerow,40 say supplier->laststat pict '9999999.99'
   p_bal := supplier->laststat
   rerow++
  endif
  bf_flag := FALSE
 else
  @ rerow,01 say cretrans->date
  @ rerow,11 say tsname( cretrans->ttype ) + cretrans->tnum
  p_bal += cretrans->amt - cretrans->amtpaid
  @ rerow,25 say cretrans->desc
  if cretrans->amt > 0
   @ rerow,44 say cretrans->amt pict '9999999.99'
   @ rerow,55 say cretrans->amtpaid pict '9999999.99'
  else
   @ rerow,44 say cretrans->amtpaid pict '9999999.99'
   @ rerow,55 say cretrans->amt pict '9999999.99'
  endif
  @ rerow,69 say cretrans->amt - cretrans->amtpaid pict '9999999.99'
  rerow++
  if rerow > 55
   skip alias cretrans
   if eof() .or. cretrans->code != supplier->code
    Remitfoot( p_bal, TRUE )
   else
    repage++
    rerow := Rehead( repage )
   endif
  else
   skip alias cretrans
  endif
 endif
enddo
Remitfoot( p_bal, FALSE )
eject
select supplier
set device to screen
set console on
return

*

function rehead ( page_no )
local mdate := dtoc( Bvars( B_DATE ) )
if page_no > 1
 @ 1,0 say 'Page No ' + Ns( page_no, 3 )
endif
@ 03,05 say trim( BPOSCUST ) + chr( 20 ) + chr( 13 )
setprc(3,0)
@ prow(),54 say substr( BPOSCUST,1,24)
@ 04,10 say Bvars( B_ADDRESS1 )
@ 04,54 say substr(Bvars( B_ADDRESS1 ), 1, 24 )
if !empty( Bvars( B_ADDRESS2 ) )
 @ 05,10 say Bvars( B_ADDRESS2 )
 @ 05,54 say substr( Bvars( B_ADDRESS2 ), 1, 24 )
 @ 06,10 say Bvars( B_SUBURB )
 @ 06,54 say substr(Bvars( B_SUBURB ), 1, 24 )
 @ 07,10 say 'Telephone ' + Bvars( B_PHONE )
 @ 07,54 say Bvars( B_PHONE )
else
 @ 05,10 say Bvars( B_SUBURB )
 @ 05,54 say substr(Bvars( B_SUBURB ),1,24)
 @ 06,10 say 'Telephone ' + Bvars( B_PHONE )
 @ 06,54 say Bvars( B_PHONE )
endif
@ 09,12 say 'Account No. ' + supplier->account
@ 13,12 say chr(27) + chr(77) + supplier->name
@ 14,12 say supplier->address1
@ 15,12 say supplier->address2
@ 16,12 say supplier->city
@ 20,04 say 'Statement for the period ending ' + (substr(mdate,1,2)+'-'+ ;
	substr(cmonth(Bvars( B_DATE )),1,3)+'-'+substr(mdate,7,2))
@ 20,54 say "S'ment Date " + (substr(mdate,1,2)+'-'+ ;
	substr(cmonth(Bvars( B_DATE )),1,3)+'-'+substr(mdate,7,2))
@ 22,04 say 'Date'
@ 22,11 say 'Reference'
@ 22,25 say 'Particulars'
@ 22,49 say 'Debit'
@ 22,60 say 'Credit'
@ 22,74 say 'Balance'
return 24
*
procedure remitfoot ( p_bal, more )
@ 57,03 say 'Herewith our cheque for Balance owing as shown above'
@ 58,03 say '90+ Days'
@ 58,16 say '60 Days'
@ 58,29 say '30 Days'
@ 58,42 say 'Current'
@ 60,01 say supplier->amt90 pict '9999999.99'
@ 60,13 say supplier->amt60 pict '9999999.99'
@ 60,25 say supplier->amt30 pict '9999999.99'
@ 60,39 say supplier->amtcur pict '9999999.99'
if !more
 @ 60,67 say p_bal pict '9999999.99'
else
 @ 60,56 say 'Continued ...... '
endif
return
