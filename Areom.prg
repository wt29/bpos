/** @package 

        Areom.prg
        
        Copyright(c) DEPT OF FOREIGN AFFAIRS TRADE 2000
        
        Author: DEPT OF FOREIGN AFFAIRS TRADE
        Created: DOF 9/03/2009 9:48:31 AM
      Last change:  TG   18 Oct 2010   10:22 pm
*/
Procedure Areom

#include "bpos.ch"


local mtot,mkey,mclear_line := space(60),mint:=0,mint_rate:=0
local getlist:={}
field amtcur, amt30, amt60, amt90, tage, amt, amtpaid

Heading("Age Debtor Accounts")
Box_Save(4,08,12,72)

Center( 05, "This option will age the amounts outstanding for each account")
Center( 07, " and entries in the transaction file.")
Center( 08, DEVELOPER + " strongly recommends that you use the Accounts Backup before Ageing")
Center( 09,"The Debtors were last aged on " + dtoc( Oddvars( DEB_AGE ) ) )

if Isready(14)

 if Ar_file_open( EXCLUSIVE )

  if Netuse( "salehist", EXCLUSIVE, 10, NOALIAS, NEW )

   SysAudit("DebAge")

   select customer
   sum amtcur+amt30+amt60+amt90 to mtot while Pinwheel( NOINTERUPT )
//    set index to cust_key, custname
   Accvars("op_bal","R",mtot)
   Oddvars( DEB_OP_BAL, mtot )
   customer->( dbgotop() )
   while !customer->( eof() )
    @ 11,10 say mclear_line
    Highlight( 11, 10, 'Customer Being Aged ->', trim( customer->name ) )

    mkey := customer->key

    customer->amt90 += amt60           // age balances
    customer->amt60 := amt30
    customer->amt30 := amtcur
    customer->amtcur := 0
    customer->laststat := amt30+amt60+amt90

    if !customer->op_it

     if debtrans->( dbseek( mkey ) )

      while debtrans->key = mkey .and. !debtrans->( eof() )

       add_rec('arhist')
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

       skip alias debtrans

      enddo
     endif
    else

     if debtrans->( dbseek( mkey ) )

      while debtrans->key = mkey .and. !debtrans->( eof() )

       if Vs( debtrans->amtpaid, 10, 2 ) = Vs( debtrans->amt, 10, 2 )

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

       else

        debtrans->tage := min( 4, debtrans->tage + 1 )

       endif
       skip alias debtrans
      enddo
     endif
    endif
    skip alias customer
   enddo

   sele debtrans
//    set index to dbtkey,dbtdate
   pack

   select salehist
   @ 11,10 say mclear_line
   Center( 11, 'Ageing Sales History Records' )
   replace all salehist->period with min( 99, salehist->period+1 ) while Pinwheel( NOINTERUPT )

   select arhist
   @ 11,10 say mclear_line
   Center( 11, 'Ageing Transaction History Records' )
   replace all tage with min( 4, tage+1 ) while Pinwheel( NOINTERUPT )

   Accvars( "l_deb_age", "R", Bvars( B_DATE ) )
   Oddvars( DEB_AGE, Bvars( B_DATE ) )
  endif
 endif
endif
close databases
return
*
Proc ArInterest

local mcust,mkey,mclear_line := space(60),mint:=0,mint_rate:=0
local getlist:={}, mbillkey, totint:=0
field amtcur, amt30, amt60, amt90, tage, amt, amtpaid

Heading("Charge Interest on Debtor Accounts")
Box_Save(4,02,10,78)
Center(05,"This option will charge interest on amounts outstanding for each account")
Center(06, DEVELOPER + "vrecommends that you Backup up the Accounts System First")
@ 08, 10 say 'Annual Interest Rate to be Charged' get mint_rate pict '999.99'
read
if Isready(14)
 if Ar_file_open( EXCLUSIVE )
  SysAudit( "DebInt->" + Ns( mint_rate ) + '%' )
  customer->( dbgotop() )
  while !customer->( eof() )
   mcust := customer->name
   mint := 0
   @ 09,10 say mclear_line
   Highlight(09,10,'Customer Being Processed ->',trim(mcust))
   mkey := customer->key
   mint := customer->amt90 + customer->amt60 + customer->amt30
   if mint > 0
    mint := ( mint/100 ) * ( mint_rate/12 )
    mbillkey := if( !empty( customer->bill_key ), customer->bill_key, customer->key )
    Rec_lock( 'customer' )
    customer->amtcur += mint
    customer->lastbuy := 1
    customer->ytdamt += mint
    Add_rec( 'debtrans' )
    debtrans->key := mbillkey
    debtrans->bill_key := mbillkey
    debtrans->amt := mint
    debtrans->date := Bvars( B_DATE )
    debtrans->ttype := 4
    debtrans->tnum := 'Interest'
    debtrans->tage := 1
    totint += mint
    dbunlockall()
   endif
   skip alias customer
  enddo
  if totint > 0
   Error( 'Total Interest Added ' + Ns( totint, 7, 2 ), 12 )
  endif
 endif
endif
close databases
return
*
procedure areoy
Heading("Zero Year to Date Sales")
Box_Save(4,08,08,72)
Center(05,"This option will zero the customers year to date sales amount. ")
Center(06,"Print your customer listing before this step is performed.")
if Isready(10)
 if Ar_file_open( EXCLUSIVE )
  SysAudit( "DebEOY" )
  select customer
  replace all customer->pytdamt with customer->ytdamt,;
              customer->ytdamt with 0
  close databases
 endif
endif
return
*
procedure arpurge
local mdate := Bvars( B_DATE )-365, getlist:={}
Heading( "Purge old Transaction Histories" )
@ 14,10 say 'ออออ> Date to purge to' get mdate
read
if lastkey() != K_ESC
 Box_Save( 4,05,08,75 )
 Center( 05,"You are about to delete all Debtor Transaction Histories")
 Center( 06," Older than " + dtoc( mdate ) )
 if Isready( 10 )
  if Ar_file_open( EXCLUSIVE )
   SysAudit( "DebHistPur" )
   select arhist
   delete for arhist->date <= mdate
   close databases
  endif
 endif
endif
return
