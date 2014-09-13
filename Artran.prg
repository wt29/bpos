/*
        Artran.prg
        
      Last change:  TG   18 Oct 2010   10:22 pm
*/
Procedure Artran

#include "bpos.ch"


#define INV 1
#define CRE 2
#define PAY 3
#define DJN 4
#define CJN 5

#define CURRENT 1
#define DAYS30 2
#define DAYS60 3
#define DAYS90 4

local again:=NO,mscr,oldscr:=Box_Save()
local havefiles := Ar_file_open(NO),oksf10
local calc1,calc2,calc3,calc4,mtran_age,getlist:={}
local m90,m60,m30,mcu,mt,mttype,mbnkbranch:='',mbank:='',mfreight,mamtpaid
local msalestax, mtnum, mdate, mamt, mdrawer:='', mcheque, mcash, mtran, mpay
local mamt1, mamt2, mamt3, mamt4, mamt5, mamt6

while havefiles
 Box_Restore( oldscr )
 select customer
 if !again
  if !CustFind( TRUE )
   close databases
   return

  endif

 endif
 if !rec_lock()
  close databases
  return

 endif
 mttype:=0
 mtnum:=space(10)
 mamt1:=0                 // amount ex tax
 mamt2:=0                 // amount v.s.
 mamt3:=0
 mamt4:=0
 mamt5:=0
 mamt6:=0                 // amount freight
 mamt:=0                  // transaction total before salestax
 mamtpaid:=0              // amount credited to transaction
 msalestax:=0             // total salestax
 mfreight:=0              // freight component
 mt:=0                    // transaction total
 mtran_age:=0             // transaction age
 mcash:=0                 // cash component of payment
 mcheque:=0               //  cheque component of payment
 mttype := 3
 while mttype > 0
  mttype := 3
  Debtdisp()
  Heading('Select transaction type')
  Box_Save(9,05,17,17)
  @ 10,06 prompt '1. Invoice '
  @ 11,06 prompt '2. Credit  '
  @ 12,06 prompt '3. Payment '
  @ 13,06 prompt '4. Debt Jnl'
  @ 14,06 prompt '5. Cred Jnl'
  @ 15,06 prompt 'Show Trans.'
  @ 16,06 prompt 'History    '
  oksf10 := setkey( K_SH_F10 , { || Ar_Balchange() } )
  menu to mttype
  setkey( K_SH_F10 , oksf10 )
  do case
  case mttype = 6
   Trandisp( YES )
  case mttype = 7
   Trandisp( NO )
  otherwise
   if mttype < 1 .or. secure( X_DEBTRANS )
    exit

   endif
  endcase
 enddo
 again := NO
 if mttype > 0 .and. mttype < 6
  Box_Save( 08, 02, 18, 40 )
  Highlight(09,04,'Transaction type->',Tname(mttype))
  mdate := Bvars( B_DATE )
  @ 10,04 say "Date ................." get mdate
  @ 11,4 say "Reference number ....." get mtnum pict '@!'
  if mttype != PAY
   @ 13,04 say 'Transaction Amount ..$' get mamt pict '#######.##'
   @ 14,04 say 'Salestax Amount .....$' get msalestax pict '#######.##'
   @ 15,04 say 'Freight Amount ......$' get mfreight pict '#######.##'
   read
   mt:=mamt+msalestax+mfreight
   if lastkey() = K_ESC .or. mt = 0
    loop
   endif
   @ 16,27 say '컴컴컴컴컴'
   @ 17,04 say 'Transaction Total....$ ' + str( mt, 10, 2 )
   if msalestax > 0
    mscr := Box_Save( 8, 41, 17, 76 )
    @ 09,43 say 'S/tax Analysis - (Pg Dn) to Skip '
    @ 09,61 say 'Pg Dn'
    @ 10,43 to 10,74
    @ 11,43 say 'Amount Exempt........$'
    @ 12,43 say 'Amount V.S. .........$'
    @ 13,43 say 'Amount Taxable '+Ns( Bvars( B_ST1 ), 4, 1 )+'% ..$'
    @ 14,43 say 'Amount Taxable '+Ns( Bvars( B_ST2 ), 4, 1 )+'% ..$'
    @ 15,43 say 'Amount Taxable '+Ns( Bvars( B_ST3 ), 4, 1 )+'% ..$'
    @ 16,43 say 'Amount Freight.......$'
    @ 11,65 get mamt1 pict '#######.##'
    @ 12,65 get mamt2 pict '#######.##'
    @ 13,65 get mamt3 pict '#######.##'
    @ 14,65 get mamt4 pict '#######.##'
    @ 15,65 get mamt5 pict '#######.##'
    @ 16,65 get mamt6 pict '#######.##'
    read
    if lastkey() = K_ESC
     loop
    endif
    calc1 := mamt3*(Bvars( B_ST1 ) / 100 )
    calc2 := mamt4*(Bvars( B_ST2 ) / 100 )
    calc3 := mamt5*(Bvars( B_ST3 ) / 100 )
    calc4 := calc1+calc2+calc3
    if calc4 < msalestax - .02 .or. calc4 > msalestax + .02
     Error( Ns( calc4 ) + " Sales tax calculations do not agree with Sales Tax amount",12)
    endif
    Box_Restore( mscr )
   endif
  else
   @ 12,4 say 'Amount Cash ?........$' get mcash when mcheque = 0 pict '#######.##'
   @ 13,4 say 'Amount Cheque ?......$' get mcheque when mcash = 0 pict '#######.##'
   read
   mamt := mcash+mcheque
   mt := mamt
   @ 14,27 say '컴컴컴컴컴'
   @ 15,4 say 'Transaction Total....$' + str( mt, 10, 2 )
   if mcheque != 0
    Box_Save( 8, 41, 17, 76 )
    @ 9,50 say 'Cheque Details'
    @ 10,50 to 10,63
    mbank   := customer->bank      // cust bank details
    mbnkbranch := customer->bnkbranch    //    "       "
    mdrawer := customer->name      //    "       "
    @ 11,43 say 'Drawer' get mdrawer pict '@!'
    @ 13,43 say '  Bank' get mbank pict '@!'
    @ 14,43 say 'Branch' get mbnkbranch pict '@!'
    read
   else
    mbank := ''
    mbnkbranch := ''
    mdrawer := ''
   endif
#ifdef AR_RECEIPTS
   if mdrawer = ''
    mdrawer:=customer->name
   endif
#endif
  endif
  if !customer->op_it .and. mttype != INV
   mtran_age := 5
   mscr := Box_Save( 20, 01, 23, 77, C_GREY )
   @ 22,2 say "1..Current 2..30 days 3..60 days 4..90+ days"
   if mttype = PAY
    @ row(), col() say " 5..Credit oldest amount first"
   endif
   @ 21,2 say "Transaction age?..............." get mtran_age pict '9' ;
          valid( mtran_age > 0 .and. mtran_age < 6 )
   read
   Box_Restore( mscr )
   if lastkey() = K_ESC
    loop

   endif
  else
   mtran_age := 1
  endif
  if customer->amtcur+customer->amt30+customer->amt60+customer->amt90+mt ;
     >= customer->c_limit .and. mttype = INV
   Error('Credit Limit Exceeded',14)

  endif
#ifdef AR_RECEIPTS
  mrecpt := FALSE
  mrecptno := 0
  if mttype = PAY
   mrecpt := Isready( 19, 12, 'Print Receipt' )
   if mrecpt
    mrecptno := Sysinc( 'receipt', 'I', 1 )
   endif
  endif
#endif
  if Isready(19)
   if mttype != INV .and. customer->op_it
    mamtpaid := Open_proc( customer->key, mt, mamt, mttype )
   endif
   mscr := Box_Save( 18, 25, 20, 55, C_GREY )
   @ 19,27 say "Updating files..."
   if mttype = PAY
    mpay := mcheque
    mtran := 'CHQ'
    if empty(mcheque)
     mpay := mcash
     mtran := 'CAS'
    endif
    Add_rec( 'sales ')
    sales->unit_price := mpay
    sales->tend_type := mtran
    sales->tran_type := 'PAY'
    sales->qty := 1
    sales->register := lvars( L_REGISTER )
    sales->sale_date := Bvars( B_DATE )  
    sales->time := time()
    sales->tran_num := lvars( L_CUST_NO )
    sales->key := customer->key
    sales->drawer := mdrawer
    sales->bank := mbank
    sales->bnkbranch := mbnkbranch
    sales->name := mdrawer
    sales->( dbrunlock() )

    lvars( L_CUST_NO, Custnum() )

    Add_rec( 'debbank' )
    debbank->key := customer->key
    debbank->date := mdate
    debbank->tnum := mtnum
    debbank->cash := mcash
    debbank->cheque := mcheque
    debbank->drawer := mdrawer
    debbank->bank := mbank
    debbank->bnkbranch := mbnkbranch
#ifdef AR_RECEIPTS
    if mrecpt
     debbank->tnum := Ns( mrecptno )

    endif
#endif
    debbank->( dbrunlock() )

    Rec_lock( 'customer' )
    customer->bank := mbank
    customer->bnkbranch := mbnkbranch
    customer->( dbrunlock() )

   endif   // mttype = PAY

   if mttype = CRE .or. mttype = PAY .or. mttype = CJN
    mamt  := -mamt
    msalestax := -msalestax
    mt := -mt
    mamtpaid := -mamtpaid
    mfreight := -mfreight
   endif
   Add_rec('debtrans')
   debtrans->key := customer->key
   debtrans->bill_key := if(!empty(customer->bill_key),customer->bill_key,customer->key)
   debtrans->ttype := mttype
   debtrans->date := mdate
   debtrans->tnum := mtnum
   debtrans->amt := mt     // Possible problem hear with S/T totals
   debtrans->salestax := msalestax
   debtrans->tage := if( mttype < PAY, mtran_age, 1 )
   debtrans->amtpaid := mamtpaid
   debtrans->freight := mfreight
#ifdef AR_RECEIPTS
   if mrecpt
    debtrans->tnum := Ns( mrecptno )
   endif
#endif
   debtrans->( dbrunlock() )
   Rec_lock( 'customer' )
   if mttype < PAY
    customer->ytdamt += mt
   else
    if empty( customer->bank )
     customer->bank := mbank
     customer->bnkbranch := mbnkbranch
    endif
   endif
   if !customer->op_it .or. mttype = INV
    do case
    case mtran_age = CURRENT
     customer->amtcur += mt
    case mtran_age = DAYS30
     customer->amt30 += mt
    case mtran_age = DAYS60
     customer->amt60 += mt
    case mtran_age = DAYS90
     customer->amt90 += mt
    case mtran_age = 5
     m90 := customer->amt90
     m60 := customer->amt60
     m30 := customer->amt30
     mcu := customer->amtcur
     if m90 >= -mt
      customer->amt90 += mt
      mt := 0
     else
      mt += customer->amt90
      customer->amt90 := 0
     endif
     if m60 >= -mt
      customer->amt60 += mt
      mt := 0
     else
      mt += customer->amt60
      customer->amt60 := 0
     endif
     if m30 >= -mt
      customer->amt30 += mt
      mt := 0
     else
      mt += customer->amt30
      customer->amt30 := 0
     endif
     customer->amtcur += mt
    endcase
   endif
   if debtrans->ttype = 1
    customer->lastbuy := 1
   endif
   customer->( dbrunlock() )
   Box_Restore( mscr )
  else
  endif
#ifdef AR_RECEIPTS
  if mrecpt
   Dock_head()
   Dock_line(  'Receipt #' + Ns( mrecptno ) )
   Dock_line(  '' )
   Dock_line(  'Recieved from ' + trim( customer->name ) )
   if mcash > 0
    Dock_line(  'Cash   $' + Ns( mcash ) )

   endif
   if mcheque > 0
    Dock_line(  'Cheque $' + Ns( mcheque ) )

   endif
   Dock_line(  '' )
   Dock_line(  'Thank You' )
   Dock_foot( )

   Dock_print( )

  endif
#endif
  Debtdisp()
  again := Isready( 21,,'Another transaction for this customer?' )
 endif
enddo
close databases
return

*

function open_proc ( mkey, mt, mamt, mttype )
local payCur := NO, pay30 := NO, pay60 := NO, pay90 := NO, mtran_age, mpaymess:='Payment is equal to '
local sel, mscr, sscr, mword, getlist:={}
local munalloc, has_tran, tpaid, mpaid, mamtpaid, mb, b, tt
if mttype = PAY
 do case
 case mt = customer->amt90
  mpaymess += 'Outstanding 90+ days Amount'
  pay90 := YES
 case mt = customer->amt60
  mpaymess += 'Outstanding 60 day Amount'
  pay60 := YES
 case mt = customer->amt30
  mpaymess += 'Outstanding 30 day Amount'
  pay30 := YES
 case mt = customer->amtcur
  mpaymess += 'Outstanding Current Amount'
  paycur := YES
 case mt = customer->amt60 + customer->amt90
  mpaymess += 'Outstanding 60 + 90 day Amounts'
  pay60 := YES
  pay90 := YES
 case mt = customer->amt30 + customer->amt60
  mpaymess += 'Outstanding 30 + 60 day Amounts'
  pay30 := YES
  pay60 := YES
 case mt = customer->amt30 + customer->amt60 + customer->amt90
  mpaymess += 'Outstanding 30 + 60 + 90 day Amounts'
  pay30 := YES
  pay60 := YES
  pay90 := YES
 case mt = customer->amtcur + customer->amt30 + customer->amt60 + customer->amt90
  mpaymess += 'Outstanding Cur + 30 + 60 + 90 day Amounts'
  paycur := YES
  pay30 := YES
  pay60 := YES
  pay90 := YES
 endcase
 if paycur .or. pay30 .or. pay60 .or. pay90
  mscr := Box_Save( 18, 02, 20, 4 + len( trim( mpaymess ) ) )
  @ 19, 03 say mpaymess
  if Isready( 21, 02, 'Mark these Invoices Paid' )
   if debtrans->( dbseek( mkey ) )
    while debtrans->key = mkey .and. !debtrans->( eof() )
     Rec_lock( 'debtrans' )
     do case
     case debtrans->tage = CURRENT .and. paycur
      debtrans->amtpaid := debtrans->amt
     case debtrans->tage = DAYS30 .and. pay30
      debtrans->amtpaid := debtrans->amt
     case debtrans->tage = DAYS60 .and. pay60
      debtrans->amtpaid := debtrans->amt
     case debtrans->tage = DAYS90 .and. pay90
      debtrans->amtpaid := debtrans->amt
     endcase
     debtrans->( dbrunlock() )
     skip alias debtrans
    enddo
    Rec_lock( 'customer' )
    if paycur
     customer->amtcur := 0
    endif
    if pay30
     customer->amt30 := 0
    endif
    if pay60
     customer->amt60 := 0
    endif
    if pay90
     customer->amt90 := 0
    endif
    customer->( dbrunlock() )
   endif
   return mamt
  endif
  Box_Restore( mscr )
 endif
endif
mword := if( mttype != DJN , 'Credit' , 'Debit' )
munalloc := Vs( mt )  // Unallocated Balance
mpaid := 0
sscr := Box_Save(16,1,21,77)
@ 17,2 say "Trans.    Date   Trans.     Amount      Sales      Total    Balance  Age"
@ 18,2 say " type              #          $         Tax          $        $"
@ 19,2 say " 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�"
while TRUE
 Box_Save( 21, 01, 23, 30 )
 @ 22,2 say 'First Transaction'
 inkey(1)

 debtrans->( dbseek( mkey ) )

 has_tran := NO
 while debtrans->key = mkey .and. !debtrans->( eof() )

  tt := debtrans->amt
  b := Vs( tt - debtrans->amtpaid )
  if Vs( b ) != 0    // check transaction has'nt a zero bal
   do case
   case (debtrans->ttype = INV .or. debtrans->ttype = DJN ) .and. mttype = DJN
    skip alias debtrans
    loop
   case (debtrans->ttype = CRE .or. debtrans->ttype = PAY .or. debtrans->ttype = CJN) .and. mttype != DJN
    skip alias debtrans
    loop
   endcase
   @ 20,2 say tname(debtrans->ttype)+' '+dtoc(debtrans->date)+' '+substr(debtrans->tnum,1,6)+;
              ' '+str(debtrans->amt,10,2)+' '+str(debtrans->salestax,10,2)+' ';
              +str(tt,10,2)+' '+str(b,10,2)+' '+agename(debtrans->tage)
   has_tran := YES
  else
   skip alias debtrans
   loop
  endif
  Box_Save( 21, 46, 23, 77 )
  Highlight( 22, 47, 'Unallocated ' + mword + ' $', Ns( munalloc, 10, 2 ) )
  sel := NO
  Box_Save( 21, 01, 23, 30 )
  @ 22,02 say mword+' this transaction ?' get sel pict 'Y'
  read

  if lastkey() = K_ESC                       // if (Esc) pressed

   Rec_lock( 'customer' )
   if mttype != DJN
    customer->amtcur -= munalloc
   else
    customer->amtcur += munalloc
   endif
   customer->( dbrunlock() )
   return mt - munalloc
  endif
  if sel

   while TRUE
    mpaid := 0
    mscr := Box_Save( 21, 01, 23, 40 )
    @ 22,2 say 'Enter amount to '+mword+'..$' get mpaid pict '@Z 9999999.99';
           valid( mpaid >= 0 )
    
    read
    Box_Restore( mscr )
    mpaid := Vs( mpaid )
    mb := b
    if debtrans->ttype != INV .and. debtrans->ttype != DJN  // will convert a (-) figure to a (+)
     mb:= -mb                           // figure for comparison
    endif
    if mpaid > Vs( munalloc, 10, 2 ) .or. mpaid > Vs( mb, 10, 2 )
     if mpaid > Vs( munalloc, 10, 2 )
      Error( 'Amount exceeds unallocated Balance', 12 )
     else
      Error( 'Amount exceeds transaction Balance', 12 )
     endif
    else
     exit
    endif
   enddo

   Rec_lock( 'debtrans' )
   if mttype != DJN
    debtrans->amtpaid += mpaid
   else
    debtrans->amtpaid -= mpaid
   endif
   debtrans->( dbrunlock() )

   munalloc := Vs( munalloc-mpaid )    // Unallocated Balance
   mamtpaid := Vs( mt-munalloc )       // Allocated to transaction

   mtran_age := debtrans->tage

   tpaid := if( mttype != DJN , -mpaid , mpaid )

   Rec_lock( 'customer' )
   do case                                // update balance forward figures
   case mtran_age = CURRENT
    customer->amtcur += tpaid
   case mtran_age = DAYS30
    customer->amt30 += tpaid
   case mtran_age = DAYS60
    customer->amt60 += tpaid
   case mtran_age = DAYS90
    customer->amt90 += tpaid
   endcase
   customer->( dbrunlock() )

   if Vs( munalloc, 10, 2 ) = 0
    Box_Restore( sscr )
    return mt - munalloc
   endif

  endif
  debtrans->( dbskip() )

 enddo

 if !has_tran

  Error( 'No outstanding transactions to ' + mword + '!', 08 )

  Rec_lock( 'customer' )
  if mttype != DJN                         // credit or debit unallocated amounts
   customer->amtcur -= munalloc
  else
   customer->amtcur += munalloc
  endif
  customer->( dbrunlock() )
  return mt - munalloc
 endif

 mscr := Box_Save( 21, 01, 23, 30 )
 @ 22,2 say 'Last Transaction'
 inkey( 2 )
 Box_Restore( mscr )

enddo
return 0
*
Function Debtor_type_change
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
    if Netuse( 'arhist', EXCLUSIVE )
     if Netuse( 'debtrans', EXCLUSIVE )
      if Netuse( 'customer', EXCLUSIVE )
       ordsetfocus( 'key' )
       customer->( dbgotop() )
       while !customer->( eof() )
        Center( 8, customer->name )
        do case
        case mchoice = 1 .and. customer->op_it

// Move all 30, 60, 90 day transactions to the history file

         debtrans->( dbseek( customer->key ) )

         while debtrans->key = customer->key .and. !debtrans->( eof() )
          if debtrans->tage >= 2   // 30 day line
           Add_rec( 'arhist' )
           arhist->key := debtrans->key
           arhist->ttype := debtrans->ttype
           arhist->date := debtrans->date
           arhist->tnum := debtrans->tnum
           arhist->amt := debtrans->amt
           arhist->salestax := debtrans->salestax
           arhist->amtpaid := debtrans->amtpaid
           arhist->tage := debtrans->tage
           arhist->salesman := debtrans->salesman
           arhist->comment := debtrans->comment

           Del_rec( 'debtrans' )
          endif
          debtrans->( dbskip() )
         enddo

         customer->laststat := customer->amt30 + customer->amt60 + customer->amt90
         customer->op_it := FALSE

        case mchoice = 2 .and. !customer->op_it

         for x := 2 to 4
          do case
          case x = 2 .and. customer->amt30 != 0 
           Debtrans_rec( customer->amt30, x )
          case x = 3 .and. customer->amt60 != 0 
           Debtrans_rec( customer->amt60, x )
          case x = 4 .and. customer->amt90 != 0
           Debtrans_rec( customer->amt90, x )
          endcase
         next

         customer->op_it := TRUE

        endcase

        customer->( dbskip() )

       enddo
       SysAudit( 'ChangeCust' + if ( mchoice=1, 'OI->BBF','BBF->OI' ) )

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
Function Debtrans_rec( mamt, mtage )
Add_rec( 'debtrans' )
debtrans->key := customer->key
debtrans->tage := mtage
debtrans->ttype := if( mamt>0, 4, 5 ) //Db / Cr Journal
debtrans->date := Bvars( B_DATE )
debtrans->tnum := 'ADJUST'
debtrans->amt := mamt
debtrans->comment := 'Created by Type Change'
return nil
