/*

      Last change:  TG   16 Jan 2011    6:40 pm
*/

field amtcur, amt30, amt60, amt90, amt, amtpaid, ytdamt
field name, address1, address2, city, date, duedate, code, op_it
field add1, add2, add3, pcode, salesman, tage, tnum, ttype, key, c_limit
field freight, salestax

Procedure Acme

#include "bpos.ch"

local warn_disp:=FALSE,choice,mscr,tscr,archoice,areom
local oldscr:=Box_Save(), apchoice, apeom, getlist:={}, aArray

// Don't even display Accounts if not enabled


if !getaccvars()
 Error( "Accounting Variables file not available cannot proceed",12)
 return

endif

while TRUE
 Box_Restore( oldscr )
 Heading('Accounts Main Menu')
 choice := 5
 Box_Save( 05, 00, 07, 77 )
 @ 06, 02 prompt ' Debtors  ' message line_clear( 24 ) + 'Accounts Receivable System'
 @ 06, 18 prompt 'Creditors ' message line_clear( 24 ) + 'Accounts Payable Menu'
 @ 06, 66 prompt ' ' + SYSNAME + ' ' message line_clear( 24 ) + 'Return to ' + SYSNAME + ' Main Menu'
 menu to choice
 tscr := Box_Save()
 do case
 case choice = 1 .and. Secure( X_DEBTORS )
  while TRUE
   Box_Restore( tscr )
   Heading('Accounts Receivable Menu')
   aArray := {}
   aadd( aArray, { 'Accounts', 'Return to Accounts Menu' }  )
   aadd( aArray, { 'Transactions', 'Transaction Menu' } )
   aadd( aArray, { 'Reports', 'Reports Menu' } )
   aadd( aArray, { 'End of Month', 'End of Month/Statements' } )
   archoice := Menugen( aArray, 04, 01, 'Debtors' )
   if Bvars( B_DATE ) - Oddvars( DEB_AGE ) > 30
    mscr := Box_Save( 11, 08, 13, 72, C_GREY )
    Center( 12, 'It has been ' + Ns( Bvars( B_DATE ) - Oddvars( DEB_AGE ) ) + ' days since Debtors Ageing' )
    Syscolor( C_NORMAL )
   endif
   if Bvars( B_DATE ) - Oddvars( DEB_AGE ) > 30
    Box_Restore( mscr )
   endif
   mscr:=Box_Save()
   do case
   case archoice = 2
    Artran()
   case archoice = 3 .and. secure( X_DEBREPS )
    Arrep()
   case archoice = 4 .and. secure( X_DEBEOM )
    while archoice = 4
     Box_Restore( mscr )
     Heading('End of Month Procedure')
     aArray := {}
     aadd( aArray, { 'Debtors', 'Return to Debtors Menu', nil } )
     aadd( aArray, { 'Interest', 'Charge Interest on Accounts', { || Arinterest() } } )
     aadd( aArray, { 'Statements', 'Print Debtors Statements', { || Arstat() } } )
     aadd( aArray, { 'Ageing', 'Age Accounts', { || Areom() } } )
     aadd( aArray, { 'Year End', 'Zero Year to date Sales', { || Areoy() } } )
     aadd( aArray, { 'Purge', 'Delete old History Transactions', { || Arpurge() } } )
     areom := Menugen( aArray, 08, 02, 'End of Month' )
     if areom < 2
      archoice := 1
     else
      Eval( aArray[ areom, 3 ] )
     endif
    enddo
   case archoice < 2
    exit
   endcase
  enddo

 case choice = 2 .and. Secure( X_CREDITORS )
  while TRUE
   Box_Restore( tscr )
   Heading('Accounts Payable Menu')
   aArray := {}
   aadd( aArray, { 'Accounts', 'Return to Accounts Menu' } )
   aadd( aArray, { 'Transactions', 'Transaction Menu' } )
   aadd( aArray, { 'Cheque', 'Cheque Processing' } )
   aadd( aArray, { 'Reports', 'Reports Menu' } )
   aadd( aArray, { 'End of Month', 'End of Month/Statements' } )
   apchoice := MenuGen( aArray, 04, 18, 'Creditors')
   if Bvars( B_DATE ) - Oddvars( CRE_AGE ) > 30
    mscr:=Box_Save( 11, 08, 13, 72, C_GREY )
    Center(12,'It has been '+Ns( Bvars( B_DATE ) - Oddvars( CRE_AGE ) )+' days since Creditors Ageing')
    Syscolor( C_NORMAL )
   endif
   if Bvars( B_DATE ) - Oddvars( CRE_AGE ) > 30
    Box_Restore( mscr )
   endif
   do case
   case Apchoice = 2
    Aptran()
   case Apchoice = 3
    Apcheque()
   case Apchoice = 4 .and. Secure( X_CREDREPS )
    Aprep()
   case Apchoice = 5 .and. Secure( X_CREDEOM )
    mscr:=Box_Save()
    while Apchoice = 5
     Box_Restore( mscr )
     Heading('End of Month Procedure')
     aArray := {}
     aadd( aArray, { 'Creditors', 'Return to Creditors Menu' } )
     aadd( aArray, { 'Remittance', 'Print Remittance Advices', { || Apremit() } } )
     aadd( aArray, { 'Ageing', 'Age Accounts', { || Apeom() } } )
     aadd( aArray, { 'Year End', 'Zero Year to Date Figures', { || Apeoy() } } )
     aadd( aArray, { 'Purge', 'Delete old History Transactions', { || Appurge() } } )
     apeom := MenuGen( aArray, 09, 19, 'End of Month' )
     if apeom < 2
      apchoice := 1
     else
      eval( aArray[ apeom, 3 ] )
     endif
    enddo
   case apchoice < 2
    exit
   endcase
  enddo

 case choice = 3 .and. Secure( X_GENERAL )
  if !file( Oddvars( SYSPATH )+'Exogen.bat' )
   Error("General Ledger Option not Installed",12)
  else
   Shell( Oddvars( SYSPATH )+'Exogen' )
  endif

 case choice = 4 .and. Secure( X_REPORTER )

 case choice < 2 .or. choice = 5
  return

 endcase

enddo

*

Function Accvars ( Sysval,Action,Value )
local nSelArea:=select(),retval:=0,mfieldpos
if Netuse( 'accvars', EXCLUSIVE, 0 )       // We need to wait forever here!
 mfieldpos:=fieldpos(sysval)
 do case
 case action = 'I'    // Increment system value
  if fieldget( mfieldpos ) + value >= 1000000
   fieldput(mfieldpos,1)
  else
   fieldput(mfieldpos,fieldget(mfieldpos)+1)
  endif
 case action = 'R'    // Replace System Value
  fieldput(mfieldpos,value)
 endcase
 retval:=fieldget(mfieldpos)
 accvars->( dbclosearea() )
endif
select ( nSelArea )
return ( retval )

*

function ar_file_open ( p_mode )
local ar_files := FALSE
Center(24,'Opening files for Debtors Processing')
if Netuse( "arhist", p_mode )
 if Netuse( "sales" )
  if Netuse( "debbank", p_mode )
   if Netuse( "debtrans", p_mode ) 
    if Netuse( "customer", p_mode )
     customer->( dbsetfilter( { || customer->debtor = TRUE } ) )
     ar_files := TRUE
    endif
   endif
  endif
 endif
endif
line_clear(24)
return( ar_files )

*

procedure trandisp ( current )
local mscr,mval,c,arbrow,getlist:={},mkey:=customer->key, tscr, keypress
dbselectarea( if( current, 'debtrans', 'arhist' ) )
if !dbseek( mkey )    //.and. customer->op_it
 Error('No Transactions on File',12)
else
 mscr:=Box_Save(08,00,24,79)
 if current
  Heading("Display Outstanding Transactions")
 else
  Heading("Display Transaction History")
 endif
 if !customer->op_it
  @ 08,10 say space( 36 )
  Highlight( 08, 10, '< Last Statement Balance $', Ns(customer->laststat) +'>' )
 endif
 arbrow:=tbrowsedb( 09, 01, 23, 78 )
 arbrow:HeadSep := HEADSEP
 arbrow:ColSep := COLSEP
 if current
  arbrow:goTopBlock := { || debtrans->( dbseek( mkey ) ) }
  arbrow:goBottomBlock := { || jumptobott( mkey, 'debtrans' ) }
  arbrow:skipBlock := KeyskipBlock( {|| debtrans->key }, mkey )
 else
  arbrow:goTopBlock := { || arhist->( dbseek( mkey ) ) }
  arbrow:goBottomBlock := { || jumptobott( mkey, 'arhist' ) }
  arbrow:skipBlock := KeyskipBlock( {|| arhist->key }, mkey )
 endif
 arbrow:addcolumn(tbcolumnnew('Type', { || tsname(ttype) } ) )
 arbrow:addcolumn(tbcolumnnew('Date', { || date } ) )
 arbrow:addcolumn(tbcolumnnew('Refer',{ || transform( tnum, 'xxxxxxxxxx' ) } ) )
 arbrow:addcolumn(tbcolumnnew('Inv Amount', { || transform( amt , '999999.99') } ) )
 arbrow:addcolumn(tbcolumnnew('   Paid',{ || transform( amtpaid , '999999.99') } ) )
 c:=tbcolumnnew(' BALANCE',{ || transform( amt-amtpaid , '999999.99') } )
 c:colorblock:= { || if( amt-amtpaid != 0 , {5, 6}, {1, 2} ) }
 arbrow:addcolumn( c )
 arbrow:addcolumn(tbcolumnnew('Freight', { || transform( freight , '999999.99') } ) )
 arbrow:addcolumn(tbcolumnnew('Sales Tax', { || transform( salestax , '999999.99') } ) )
 arbrow:addcolumn(tbcolumnnew('Age',{ || substr( agename( tage ),1,3) } ) )
 keypress := 0
 while keypress != K_ESC .and. keypress != K_END
  arbrow:forcestable()
  keypress := inkey(0)
  if !navigate( arbrow, keypress )
   do case
   case keypress = K_ENTER
    if Master_use()
     if Netuse( "invline" ) 
      set relation to invline->id into master
      if Netuse( "invhead" ) 
       set relation to invhead->number into invline
       mval := if( current , val( debtrans->tnum ) , val( arhist->tnum ) )
       if !dbseek( mval )
        Error('Invoice Number ' + Ns( mval ) + ' not on file',12)
       else
        Invenq()
       endif
       invhead->( dbclosearea() )
      endif
      invline->( dbclosearea() )
     endif
     master->( dbclosearea() )
    endif
    dbselectarea( if( current, 'debtrans', 'arhist' ) )
   case keypress == K_SH_F10 .and. current .and. Secure( X_DEBBALMOD )
    tscr := Box_Save( 10, 02, 20, 40 )
    @ 11,03 say 'Trans Amt' get amt
    @ 12,03 say ' Amt Paid' get amtpaid
    @ 14,03 say 'Sales Tax' get salestax
    @ 15,03 say '  Freight' get freight
    @ 16,03 say ' Sundries' get sundries
    @ 17,03 say 'Trans Age' get tage pict '9' range 1,4
    @ 18,03 say 'Reference' get tnum
    Rec_lock( 'debtrans' )
    read
    debtrans->( dbrunlock() )
    Box_Restore( tscr )
    arbrow:refreshcurrent()
    SysAudit( 'F10DbAcMd' + trim( customer->key ) )
   endcase
  endif
 enddo
 Box_Restore( mscr )
endif
select customer

return

*

procedure debtdisp
Heading('Debtor Display')
Box_Save( 1, 2, 8, 78 )
select customer
#ifndef DSPSYD
Highlight( 02, 03, 'ID', key )
Highlight( 02, 16, 'Name', name )
#else
Highlight( 02, 03, '   Name', customer->name )
#endif
Highlight( 03, 03, 'Address', add1 )
Highlight( 02, 60, 'Current', amtcur )
Highlight( 03, 60, '30 Days', amt30 )
Highlight( 04, 60, '60 Days', amt60 )
Highlight( 05, 60, '90 Days', amt90 )
Highlight( 06, 60, 'Total->', amtcur+amt30+amt60+amt90, '9999999.99' )
Highlight( 07, 58, 'Sales YTD', ytdamt, '9999999.99' )
Highlight( 06, 03, 'Credit Limit', Ns( c_limit ) )
@ 07,03 say 'Type'
#ifndef DSPSYD
Highlight( 07, 40, 'Salesman', salesman )
#else
Highlight( 07, 40, 'ID', customer->key )
#endif
syscolor( C_BRIGHT )
@ 04,11 say add2
@ 05,11 say trim(add3) + ' '+ pcode
if op_it
 @ 7,08 say 'Open Item'
else
 @ 7,08 say 'Balance Brought Forward'
endif
syscolor( C_NORMAL )
if amtcur+amt30+amt60+amt90 >= c_limit
 syscolor( C_BRIGHT )
 @ 06,03 say 'Credit Limit of ' + Ns( c_limit ) + ' Exceeded'
 syscolor( C_NORMAL )
endif
return

*

procedure ar_balchange
local oldcur := setcursor(1), getlist:={}, oldbal
if secure( X_DEBTRANS )
 oldbal := customer->amtcur+customer->amt30+customer->amt60+customer->amt90
 @ 2,69 get customer->amtcur pict '999999.99'
 @ 3,69 get customer->amt30  pict '999999.99'
 @ 4,69 get customer->amt60  pict '999999.99'
 @ 5,69 get customer->amt90  pict '999999.99'
 @ 7,69 get customer->ytdamt pict '999999.99'
 Rec_lock( 'customer' )
 read
 customer->( dbrunlock() )
 SysAudit("ArBalChg"+trim( customer->key )+Ns(oldbal)+'!'+Ns(amtcur+amt30+amt60+amt90))
 Debtdisp()
 keyboard '9'
 setcursor( oldcur )
endif
return

*

function tsname ( p_tt )
local sname
do case
case p_tt = 1
 sname := 'INV'
case p_tt = 2
 sname := 'CRE'
case p_tt = 3
 sname := 'PAY'
case p_tt = 4
 sname := 'DBJ'
case p_tt = 5
 sname := 'CRJ'
otherwise
 sname := '???'
endcase
return sname

*

function tname ( p_tt )
local sname
do case
case p_tt = 1
 sname := 'Invoice'
case p_tt = 2
 sname := 'Credit'
case p_tt = 3
 sname := 'Payment'
case p_tt = 4
 sname := 'Dbt Jnl'
case p_tt = 5
 sname := 'Crd Jnl'
otherwise
 sname := 'Unknown'
endcase
return sname

*

function agename ( p_age )
local sname
do case
case p_age = 1
 sname := 'Current'
case p_age = 2
 sname := '30 Days'
case p_age = 3
 sname := '60 Days'
case p_age = 4
 sname := '90 Days'
otherwise
 sname := '  ?    '
endcase
return sname

*

function ap_file_open ( p_mode )
local ap_files := FALSE
Center(24,'Opening files for Creditors Processing')
if Netuse( "aphist", p_mode )
 if Netuse( "cretrans", p_mode )
  ap_files := Netuse( "supplier", p_mode )
 endif
endif
line_clear( 24 )
return( ap_files )

*

procedure a_tran_disp ( current )
local mkey, mscr, getlist:={}, tscr, apbrow, mdate
if current
 select cretrans
else
 select aphist
endif
if !dbseek( supplier->code )
 Error('No Transactions on File',12)
else
 mscr := Box_Save( 08, 00, 24, 79 )
 if current
  Heading("Display Outstanding Transactions")
 else
  Heading("Display Transaction History")
 endif
 apbrow:=tbrowsedb(09,01,23,78)
 apbrow:HeadSep := HEADSEP
 apbrow:ColSep := COLSEP
 apbrow:goTopBlock := { || dbseek(supplier->code) }
 apbrow:goBottomBlock  := { || jumptobott(supplier->code) }
 apbrow:skipBlock:=KeyskipBlock( {||field->code}, supplier->code )
 apbrow:addcolumn(tbcolumnnew('Type', { || tsname(ttype) } ) )
 apbrow:addcolumn(tbcolumnnew('Date', { || date } ) )
 apbrow:addcolumn(tbcolumnnew('Due Date', { || duedate } ) )
 apbrow:addcolumn(tbcolumnnew('Refer',{ || tnum } ) )
 apbrow:addcolumn(tbcolumnnew('Amount', { || transform( amt , '999999.99') } ) )
 apbrow:addcolumn(tbcolumnnew('Paid',{ || transform( amtpaid , '999999.99') } ) )
 apbrow:addcolumn(tbcolumnnew('Balance',{ || transform( amt-amtpaid , '999999.99') } ) )
 apbrow:addcolumn(tbcolumnnew('Age',{ || substr(agename(tage),1,3) } ) )
 apbrow:addcolumn(tbcolumnnew('Description',{|| field->desc } ) )
 mkey := 0
 while mkey != K_ESC .and. mkey != K_END
  apbrow:forcestable()
  mkey := inkey(0)

  if !navigate( apbrow, mkey )
   do case
   case mkey == K_ENTER .and. current .and. amt-amtpaid != 0
    tscr := Box_Save( 10, 10, 12, 70 )
    Rec_lock( 'cretrans' )
    @ 11, 12 say 'Transaction Due Date' get cretrans->duedate
    read
    cretrans->( dbrunlock() )
    Box_Restore( tscr )

   case mkey == K_ALT_T .and. current
    mdate := Bvars( B_DATE )
    tscr := Box_Save( 10, 10, 12, 70 )
    @ 11, 12 say 'Replace all Transaction Due Dates with' get mdate
    read
    if updated()
     cretrans->( dbseek( supplier->code ) )
     while cretrans->code = supplier->code .and. !cretrans->( eof() )
      Rec_lock( 'cretrans' )
      cretrans->duedate := mdate
      cretrans->( dbrunlock() )
      cretrans->( dbskip() )
     enddo
     apbrow:refreshall()
    endif
    Box_Restore( tscr )

   case mkey == K_SH_F10 .and. current .and. Secure( X_CREDBALMOD )
    tscr:=Box_Save( 10, 02, 20, 40 )
    @ 11,03 say 'Trans Amt' get cretrans->amt
    @ 12,03 say ' Amt Paid' get cretrans->amtpaid
    @ 17,03 say 'Trans Age' get cretrans->tage pict '9' range 1,4
    @ 18,03 say 'Reference' get cretrans->tnum
    Rec_lock('cretrans')
    read
    cretrans->( dbrunlock() )
    Box_Restore( tscr )
    apbrow:refreshcurrent()
    SysAudit( 'F10CrAcMd'+trim( supplier->code ) )
   endcase

  endif
 enddo
 Box_Restore( mscr )
endif
select supplier
return

*

procedure creddisp
Heading('Creditor Display')
Box_Save( 1, 2, 8, 78)
Highlight( 02, 03, 'Code', supplier->code )
Highlight( 02, 16, 'Name', supplier->name )
Highlight( 03, 03, 'Address', supplier->address1 )
Highlight( 04, 03, '       ', supplier->address2 )
Highlight( 05, 03, '       ', supplier->city )
Highlight( 02, 60, 'Current', supplier->amtcur )
Highlight( 03, 60, '30 Days', supplier->amt30 )
Highlight( 04, 60, '60 Days', supplier->amt60 )
Highlight( 05, 60, '90 Days', supplier->amt90 )
Highlight( 06, 60, 'Total->', supplier->amtcur+supplier->amt30+supplier->amt60+supplier->amt90,'9999999.99' )
Highlight( 07, 58, 'Purch YTD', supplier->ytdamt, '9999999.99' )
@ 7,6 say 'Type'
Syscolor( C_BRIGHT )
@ 04,11 say supplier->address2
@ 05,11 say supplier->city
if supplier->op_it
 @ 7,11 say 'Open Item'
else
 @ 7,11 say 'Balance Brought Forward $' + Ns( supplier->laststat, 10, 2 )
endif
Syscolor( C_NORMAL )
return

*

procedure ap_balchange
local getlist:={}, oldcur := setcursor(1),oldbal
oldbal := supplier->amtcur+supplier->amt30+supplier->amt60+supplier->amt90
@ 2,68 get supplier->amtcur pict '999999.99'
@ 3,68 get supplier->amt30  pict '999999.99'
@ 4,68 get supplier->amt60  pict '999999.99'
@ 5,68 get supplier->amt90  pict '999999.99'
@ 7,68 get supplier->ytdamt pict '999999.99'
Rec_lock('supplier')
read
supplier->( dbrunlock() )
SysAudit("ApBalCh"+supplier->code+Ns(oldbal)+'!'+Ns(amtcur+amt30+amt60+amt90))
Creddisp()
keyboard '9'
setcursor( oldcur )
return
*
function getaccvars
if !Netuse( "accvars" )
 return FALSE
endif
if lastrec() = 0  // File usually empty on new system
 Add_rec()
endif
Oddvars( CRE_OP_BAL, accvars->cop_bal )
Oddvars( CRE_AGE, accvars->l_cre_age )
Oddvars( DEB_OP_BAL, accvars->op_bal )
Oddvars( DEB_AGE, accvars->l_deb_age )
use
return TRUE
