/** @package

        Apeom.prg

        Last change:  TG    5 Jan 2011    9:16 pm

*/
Procedure Apeom

#include "bpos.ch"


local mtot,mclear_line:=space(60),mcust,mcode,getlist:={}
field amtcur, amt30, amt60, amt90, tage


Heading( "Age Creditor Accounts" )
Box_Save( 4,02,12,78 )
Center( 05," This option will age the amounts outstanding for each account")
Center( 06," and entries in the transaction file.")
Center( 08, DEVELOPER + " recommends you Backup the Accounts before this Step")
Center( 09,"The Creditors were last aged on " + dtoc( Oddvars( CRE_AGE ) ) )
if Isready(14)
 if Ap_file_open( EXCLUSIVE )
  if Netuse( 'stkhist', EXCLUSIVE )
   SysAudit("CreAge")
   select supplier
   sum amtcur+amt30+amt60+amt90 to mtot
   Accvars( "cop_bal","R",mtot )
   Oddvars( CRE_OP_BAL, mtot )
   supplier->( dbgotop() )
   mclear_line := space(60)
   while !supplier->( eof() )
    mcust := supplier->name
    @ 11,10 say mclear_line
    Highlight( 11,10,'Creditor Being Aged ->',trim( mcust ) )
    mcode := supplier->code
    supplier->amt90 += supplier->amt60        // age balances
    supplier->amt60 := amt30
    supplier->amt30 := amtcur
    supplier->amtcur := 0
    supplier->laststat := supplier->amt30 + supplier->amt60 + supplier->amt90
    if cretrans->( dbseek( mcode ) )
     if !supplier->op_it
      while cretrans->code = mcode .and. !cretrans->( eof() )
       Aphist_add()
       cretrans->( dbdelete() )
       skip alias cretrans
      enddo
     else
      while cretrans->code = mcode .and. !cretrans->( eof() )
       if Vs(cretrans->amtpaid,10,2) = Vs(cretrans->amt,10,2)
        Aphist_add()
        cretrans->( dbdelete() )             // erase invoices if paid
       else
        if cretrans->tage < 4
         cretrans->tage += 1
        endif
       endif
       skip alias cretrans
      enddo
     endif
    endif
    skip alias supplier
   enddo
   sele cretrans
   pack
   select stkhist
   @ 11,10 say mclear_line
   Center( 11, 'Ageing Stock History Records' )
   replace all stkhist->period with min( 99, stkhist->period+1 )
   select aphist
   @ 11,10 say mclear_line
   Center( 11, 'Ageing Transaction History Records' )
   replace all tage with min( 4, tage+1 )
   Accvars( "l_cre_age", "R", Bvars( B_DATE ) )
   Oddvars( CRE_AGE, Bvars( B_DATE ) )
  endif
 endif
endif
dbcloseall()
return

*

procedure apeoy
if Secure( X_CREDEOM )
 Heading( "Zero Year to Date Purchases" )
 Box_Save( 4,05,08,75 )
 Center( 05,"This option will zero the Suppliers year to date purchases amount.")
 Center( 06," Print your supplier listing before this step is performed")
 if Isready( 10 )
  if Ap_file_open( EXCLUSIVE )
   SysAudit( "CreEOY" )
   select supplier
   replace all supplier->pytdamt with supplier->ytdamt,;
               supplier->ytdamt with 0
   close databases
  endif
 endif
endif
return
*
procedure appurge
local mdate := Bvars( B_DATE )-365, getlist:={}
if Secure( X_SYSUTILS )
 Heading( "Purge old Transaction Histories" )
 @ 14,26 say 'ออออ> Date to purge to' get mdate
 read
 if lastkey() != K_ESC
  Box_Save( 4,05,08,75 )
  Center( 05,"You are about to delete all Supplier Transaction Histories")
  Center( 06," Older than " + dtoc( mdate ) )
  if Isready( 10 )
   if Ap_file_open( EXCLUSIVE )
    SysAudit( "CreHistPur" )
    select aphist
    delete for aphist->date <= mdate
    close databases
   endif
  endif
 endif
endif
return
*
function Aphist_add
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
return nil
