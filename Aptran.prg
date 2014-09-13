/** @package 

        Aptran.prg
        
        Copyright(c) DEPT OF FOREIGN AFFAIRS TRADE 2000
        
        Author: DEPT OF FOREIGN AFFAIRS TRADE
        Created: DOF 6/03/2009 11:27:24 PM
      Last change:  TG   15 Jan 2011    2:02 pm
*/

#include "bpos.ch"

Procedure ApTran



#define INV 1
#define CRE 2
#define PAY 3
#define DJN 4
#define CJN 5

#define CURRENT 1
#define DAYS30 2
#define DAYS60 3
#define DAYS90 4

local mscr, again := FALSE, gotfiles := ap_file_open( SHARED )
local oksf10, oldscr := Box_Save()
local mttloop, dummy, msupp, getlist:={}, aArray

local mttype

// field amtcur, amt30, amt60, amt90, ttype, tage, amt, amtpaid

while gotfiles
 select supplier
 dummy := space(10)
 while !again
  msupp:=space(4)
  mscr:=Box_Save( 2, 25, 4, 55 )
  @ 3,28 say 'Enter supplier Code' get msupp pict '@!';
         valid( Dup_chk( msupp , "supplier" ) )
  read
  Box_Restore( mscr )
  if !updated()
   close databases
   return
  endif
  select supplier
  seek msupp
  if !found()
   Error( "Supplier not on File",12 )
  else
   again := TRUE
  endif
 enddo
 mttloop := TRUE
 while mttloop
  Box_Restore( oldscr )
  mttype := 1
  Creddisp( FALSE )
  Heading( 'Select transaction type' )
  aArray := {}
  aadd( aArray, { ' 1. Invoice ', '' } )
  aadd( aArray, { '2. Credit  ', '' } )
  aadd( aArray, { '3. Payment ', '' } )
  aadd( aArray, { '4. Debt Jnl', '' } )
  aadd( aArray, { '5. Cred Jnl', '' } )
  aadd( aArray, { 'Show Trans.', '' } )
  aadd( aArray, { 'History', '' } )
  oksf10 := setkey( K_SH_F10 , { || Ap_balchange() } )
  mttype := MenuGen( aArray, 9, 5 )
  setkey( K_SH_F10 , oksf10 )
  do case
  case mttype > 0 .and. mttype < 6
   Aptrango( mttype )
  case mttype = 6
   A_tran_disp( TRUE )
  case mttype = 7
   A_tran_disp( FALSE )
  otherwise
   mttloop := FALSE
  endcase
 enddo
 again := NO
enddo
close databases
return
*

function aptrango ( mttype )
local mamt := 0, mtnum := space(16), mdesc := space(16), mduedate := Bvars( B_DATE )
local mamtpaid := 0, mtran_age := 0, mdate:= Bvars( B_DATE ), getlist:={}
local mscr := Box_Save( 08, 02, 17, 40 ), tscr, mt, mc, m3, m6, m9

// field amtcur, amt30, amt60, amt90, ttype, tage, amt, amtpaid, ytdamt

Highlight( 09, 04, 'Transaction type->', Tname( mttype ) )
@ 10,04 say "Date ............." get mdate
@ 11,04 say "Reference number ." get mtnum pict '@!'
@ 12,04 say 'Transaction Amt..$' get mamt pict '#######.##'
@ 13,04 say 'Description ......' get mdesc
@ 14,04 say 'Due Date .........' get mduedate
read
if lastkey() = K_ESC .or. mamt = 0
 return 0
else
 mt := mamt
 @ 15,23 say '컴컴컴컴컴'
 @ 16,4 say 'Transaction Total.$'
 @ 16,23 say mt pict '#######.##'
 if mttype != INV .and. !supplier->op_it
  tscr := Box_Save( 19, 1, 22, 75 )
  @ 21,2 say " 1..current  2..30 days  3..60 days  4..90+ days  5... Oldest First"
  @ 20,2 say "Transaction age?..............." get mtran_age pict "#" range 1,5
  read
  Box_Restore( tscr )
  if lastkey() = K_ESC
   Box_Restore( mscr )
   return 0
  endif
 else
  mtran_age := CURRENT
 endif
 if Isready( 19 )
  select supplier
  Rec_lock()
  if mttype != INV .and. supplier->op_it
   mamtpaid := Apopenpay( supplier->code, mamt, mttype )

  endif
  tscr := Box_Save( 18,25,20,55 )
  @ 19,27 say "Updating files..."
  select cretrans
  if mttype = CRE .or. mttype = PAY .or. mttype = CJN
   mamt := -mamt
   mt := -mt
   mamtpaid := -mamtpaid

  endif

  Add_rec()
  replace code with supplier->code ,;
          ttype with mttype ,;
          date with mdate ,;
          tnum with mtnum ,;
          amt with mamt ,;
          tage with if( mttype < PAY, mtran_age, 1 ) ,;
          amtpaid with mamtpaid ,;
          desc with mdesc,;
          duedate with mduedate

  select supplier

  if mttype != PAY
   replace supplier->ytdamt with supplier->ytdamt + mt

  endif
  if !supplier->op_it .or. mttype = INV
   do case
   case mtran_age = CURRENT
    supplier->amtcur += mt
   case mtran_age = DAYS30
    supplier->amt30 += mt
   case mtran_age = DAYS60
    supplier->amt60 += mt
   case mtran_age = DAYS90
    supplier->amt90 += mt
   case mtran_age = 5
    m9 := supplier->amt90
    m6 := supplier->amt60
    m3 := supplier->amt30
    mc := supplier->amtcur
    if m9 >= -mt
     supplier->amt90 += mt
     mt := 0
    else
     mt += supplier->amt90
     supplier->amt90 := 0
    endif
    if m6 >= -mt
     supplier->amt60 += mt
     mt := 0
    else
     mt += supplier->amt60
     supplier->amt60 :=0
    endif
    if m3 >= -mt
     supplier->amt30 += mt
     mt := 0
    else
     mt += supplier->amt30
     supplier->amt30 := 0
    endif
    supplier->amtcur += mt
   endcase
  endif
  if cretrans->ttype = INV
   supplier->lastbuy := 1
  endif
  Box_Restore( tscr )
  dbunlockall()
 endif
endif
Creddisp( FALSE )
Box_Restore( mscr )
return mamt

*

function apopenpay ( mcode, mamt, mttype )

local paycur := FALSE, pay30 := FALSE, pay60 := FALSE, pay90 := FALSE
local sel,mgo,mscr,sscr:=Box_Save(16,0,24,79),bal,tpaid
local mun_alloc, mamtpaid, mfound, mamt_to_pay, mtran_age, mb, getlist:={}

field amtcur, amt30, amt60, amt90, ttype, tage, amt, amtpaid, date, tnum

if mttype = PAY
 do case
 case mamt = amt90
  @ 20,2 say 'Payment Is Equal To Outstanding 90+ days Amount'
  pay90 := YES
 case mamt = amt60
  @ 20,2 say 'Payment Is Equal To Outstanding 60 day Amount'
  pay60 := YES
 case mamt = amt30
  @ 20,2 say 'Payment Is Equal To Outstanding 30 day Amount'
  pay30 := YES
 case mamt = amtcur
  @ 20,2 say 'Payment Is Equal To Outstanding Current Amount'
  paycur := YES
 case mamt = amt60+amt90
  @ 20,2 say 'Payment Is Equal To Outstanding 60 + 90 day Amounts'
  pay60 := YES
  pay90 := YES
 case mamt = amt30+amt60
  @ 20,2 say 'Payment Is Equal To Outstanding 30 + 60 day Amounts'
  pay30 := YES
  pay60 := YES
 case mamt = amt30+amt60+amt90
  @ 20,3 say 'Payment Is Equal To Outstanding 30 + 60 + 90 day Amounts'
  pay30 := YES
  pay60 := YES
  pay90 := YES
 case mamt = amtcur+amt30+amt60+amt90
  @ 20,3 say 'Payment Is Equal To Outstanding Cur + 30 + 60 + 90 day Amounts'
  paycur := YES
  pay30 := YES
  pay60 := YES
  pay90 := YES
 endcase
 if paycur .or. pay30 .or. pay60 .or. pay90
  mgo := NO
  @ 22,02 say 'Do you wish to mark these invoices paid' get mgo pict 'y'
  read
  if mgo
   if cretrans->( dbseek( mcode ) )
    while cretrans->code = mcode .and. !cretrans->( eof() )
     if ( cretrans->tage = CURRENT .and. paycur ) .or. ;
        ( cretrans->tage = DAYS30 .and. pay30 ) .or. ;
        ( cretrans->tage = DAYS60 .and. pay60 ) .or. ;
        ( cretrans->tage = DAYS90 .and. pay90 )
      Rec_lock( 'cretrans' )
      cretrans->amtpaid := cretrans->amt
      cretrans->( dbrunlock() )
     endif
     cretrans->( dbskip() )
    enddo
   endif
   select supplier
   if paycur
    supplier->amtcur := 0
   endif
   if pay30
    supplier->amt30 := 0
   endif
   if pay60
    supplier->amt60 := 0
   endif
   if pay90
    supplier->amt90 := 0
   endif
   Box_Restore( sscr )
   return mamt                // all paid up return full amt
  endif
 endif
endif
select cretrans
mun_alloc := Vs(mamt,10,2)    //  Unallocated Balance
mamt_to_pay := 0
Box_Save( 16, 1, 21, 78 )
@ 17,2 say "Trans.    Date   Trans.     Amount                 Total    Balance  Age"
@ 18,2 say " Type              #          $                      $        $"
@ 19,2 say "컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴"
while TRUE
 Box_Save( 21, 01, 23, 20 )
 @ 22,03 say 'First Transaction'
 inkey( 1 )
 select cretrans
 seek mcode
// mfound indicates if any transactions with a balance are found.
 mfound := FALSE
 while cretrans->code = mcode .and. !eof()
  bal := Vs( cretrans->amt - cretrans->amtpaid )
  if Vs( bal ) != 0
   do case
   case ( ttype = INV .or. ttype = DJN ) .and. mttype = DJN
    skip
    loop
   case ( ttype = CRE .or. ttype = PAY .or. ttype = CJN ) .and. mttype != DJN
    skip
    loop
   endcase
   @ 20,2 say Tname( ttype )+' '+dtoc( date )+' '+substr( tnum,1,6 )+' '+str( amt,10,2 )+' ';
              +space( 10 )+' '+str( cretrans->amtpaid,10,2 )+' '+str( bal,10,2 )+' ';
              +Agename( tage )
   mfound := TRUE
   Box_Save( 21, 50, 23, 78 )
   Highlight( 22, 52, 'Unallocated Cash $', Ns( mun_alloc,10,2 ) )
   sel := FALSE
   mscr := Box_Save( 21, 01, 23, 30 )
   @ 22,03 say 'Pay this transaction ?' get sel pict 'y'
   read
   Box_Restore( mscr )
   if lastkey() = K_ESC
    select supplier
    if mttype != DJN
     supplier->amtcur -= mun_alloc
    else
     supplier->amtcur += mun_alloc
    endif
    Box_Restore( sscr )
    return mamt - mun_alloc
   endif
   if sel
    while TRUE
     mscr := Box_Save( 21, 01, 23, 40 )
     mamt_to_pay := 0
     @ 22,02 say 'Enter amount to pay ..$' get mamt_to_pay pict '@Z 9999999.99'
     read
     Box_Restore( mscr )
     mamt_to_pay := Vs( mamt_to_pay )
     mb := bal
     if ttype != INV .and. ttype != DJN   // will convert a (-) figure to a (+)
      mb := -mb                           // figure for comparison
     endif
     if mamt_to_pay > Vs( mun_alloc ) .or. mamt_to_pay > Vs( mb )
      if mamt_to_pay > Vs( mun_alloc )
       Error( 'Amount exceeds unallocated Balance !', 12 )
      else
       Error( 'Amount exceeds transaction Balance !', 12 )
      endif
     else
      exit
     endif
    enddo
    select cretrans
    Rec_lock()
    if mttype != DJN
     cretrans->amtpaid += mamt_to_pay
    else
     cretrans->amtpaid -= mamt_to_pay
    endif
    mtran_age := cretrans->tage
    tpaid := if( mttype != DJN, -mamt_to_pay, mamt_to_pay )
    select supplier
    do case                                 // Update Aged Balances
    case mtran_age = CURRENT
     supplier->amtcur += tpaid
    case mtran_age = DAYS30
     supplier->amt30 += tpaid
    case mtran_age = DAYS60
     supplier->amt60 += tpaid
    case mtran_age = DAYS90
     supplier->amt90 += tpaid
    endcase
    select cretrans

    mun_alloc := Vs( mun_alloc - mamt_to_pay )    

    if mun_alloc = 0    // Nothing left to allocate
     Box_Restore( sscr )
     return mamt        // All allocated return full amt
    endif

   endif
  endif
  skip
 enddo
 if !mfound
  Error('No outstanding transactions to Pay !',08)
  select supplier
  if mttype != DJN                // credit or debit unallocated amounts
   supplier->amtcur -= mun_alloc  // to current balance
  else
   supplier->amtcur += mun_alloc
  endif
  Box_Restore( sscr )
  return mamt - mun_alloc
 endif
 @ 22,2 say 'Last Transaction'
 inkey(2)
enddo
Box_Restore( sscr )
return mamtpaid
*
Function creditor_type_change
local mscr, aArray, x, mchoice, sscr:=Box_Save()

if Secure( X_SUPERVISOR )
 mscr := Box_Save( 2, 2, 9, 78 )
 Center( 3, 'WARNING!!! - Be very sure you know what you are doing here!!!' )
 Center( 4, DEVELOPER + ' WILL NOT ACCEPT ANY responsibility for the incorrect' )
 Center( 5, 'use of this procedure!' )
 Center( 7, 'PERFORM AN ACCOUNTS BACKUP FIRST' )
 if Isready( 12 )
  if Isready( 14, , 'Again are you sure you wish to proceed?' )
   aArray := {}
   aadd( aArray, { 'Change ALL Open item to Balance Brought Forward', '' } )
   aadd( aArray, { 'Change ALL Balance Brought Forward to Open Item', '' } )
   mchoice := Menugen( aArray, 17, 10 )
   if mchoice > 0 .and. Isready( 12, , 'One last time - Are you sure about this?' )
    if Netuse( 'aphist', EXCLUSIVE )
     if Netuse( 'cretrans', EXCLUSIVE )
      if Netuse( 'supplier', EXCLUSIVE )
       ordsetfocus( 'code' )
       supplier->( dbgotop() )
       while !supplier->( eof() )
        Center( 8, supplier->name )
        do case
        case mchoice = 1 .and. supplier->op_it

// Move all 30, 60, 90 day transactions to the history file

         cretrans->( dbseek( supplier->code ) )

         while cretrans->code = supplier->code .and. !cretrans->( eof() )
          if cretrans->tage >= 2   // 30 day line

           Add_rec( 'aphist' )
           aphist->code := cretrans->code
           aphist->ttype := cretrans->ttype
           aphist->date := cretrans->date
           aphist->tnum := cretrans->tnum
           aphist->amt := cretrans->amt
           aphist->duedate := cretrans->duedate
           aphist->amtpaid := cretrans->amtpaid
           aphist->tage := cretrans->tage
           aphist->desc := cretrans->desc

           Del_rec( 'cretrans' )

          endif

          cretrans->( dbskip() )

         enddo

         supplier->laststat := supplier->amt30 + supplier->amt60 + supplier->amt90
         supplier->op_it := FALSE

        case mchoice = 2 .and. !supplier->op_it

         for x := 2 to 4
          do case
          case x = 2 .and. supplier->amt30 != 0 
           cretrans_rec( supplier->amt30, x )
          case x = 3 .and. supplier->amt60 != 0 
           cretrans_rec( supplier->amt60, x )
          case x = 4 .and. supplier->amt90 != 0
           cretrans_rec( supplier->amt90, x )
          endcase
         next

         supplier->op_it := TRUE

        endcase

        supplier->( dbskip() )

       enddo
       SysAudit( 'ChangeCred' + if ( mchoice=1, 'OI->BBF','BBF->OI' ) )

       Isready( 12, , 'Procedure finished!' )

      endif
     endif
    endif
   endif
  endif
 endif
endif
dbcloseall()
Box_Restore( sscr )
return nil

*

Function cretrans_rec( mamt, mtage )
Add_rec( 'cretrans' )
cretrans->code := supplier->code
cretrans->tage := mtage
cretrans->ttype := if( mamt>0, 4, 5 ) //Db / Cr Journal
cretrans->date := Bvars( B_DATE )
cretrans->tnum := 'ADJUST'
cretrans->amt := mamt
cretrans->comment := 'Created by Type Change'
return nil
