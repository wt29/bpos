/* 

        Utilcond.prg

      Last change:  TG   18 Oct 2010    9:44 pm
*/
Procedure U_Condense

#include "bpos.ch"


local mlast:=Bvars( B_DATE )-365,minv:=Bvars( B_DATE )-365,getlist:={},mrecsarch:=0
local mentered:=Bvars( B_DATE )-365,mcount,finitorec,monthsold,monthrec
local sID,this_month,ayearrec,ayearsold,ayear
local start_this_year, start_last_year

Heading( 'Condense Stock / Sales Histories' )
Center( 24, 'Opening files for History Condensation' )
if Netuse( "salehist", EXCLUSIVE )
 Line_clear( 24 )
 Box_Save( 2, 02, 11, 78 )
 start_this_year := Bvars( B_DATE ) - 365
 start_last_year := start_this_year - 365
 @ 3,07 say 'This option will condense to Sales History files.'
 @ 4,05 say 'Records before ' + dtoc( start_last_year ) + ' will be condensed to a year total.'
 @ 5,05 say 'Records between ' + dtoc( start_this_year ) + ' and ' + dtoc( start_last_year ) + ' will be condensed by month.'
 Center( 7, 'Bluegum Software STRONGLY recommends you backup BEFORE this step!!' )
 if Isready( 8 )
  if Isready( 8, 10, 'Again - Do you wish to proceed' )
   SysAudit( 'CondSaHist'+dtoc( start_last_year ) +'|'+dtoc( start_last_year ) )
   Center( 09,'-=< Condensing Sales History - Please Wait >=-')
   Highlight( 10, 12, 'Records to process', Ns( lastrec() ) )
   mcount := 0
   salehist->( dbgotop() )
   while !salehist->( eof() ) .and. Pinwheel( NOINTERUPT )
    sID := salehist->id
    if salehist->date < start_last_year 
     ayear := year( salehist->date )
     ayearsold := 0
     ayearrec := recno()
     while salehist->date < start_last_year .and. salehist->id = sID;
          .and. !salehist->( eof() ) .and. Pinwheel( NOINTERUPT )
      ayearsold += salehist->qty
      mcount++
      delete
      skip alias salehist
     enddo
     finitorec := recno()
     goto ayearrec
     recall
     salehist->qty := min( ayearsold, 9999 )  // update values
     goto finitorec
    else
     if salehist->date < start_this_year .and. salehist->date >= start_last_year
      this_month := month( salehist->date )
      monthsold := 0
      monthrec := recno()
      while month( salehist->date ) = this_month .and. ;
           salehist->date < start_this_year .and. salehist->date >= start_last_year .and. ;
           salehist->id = sID .and. !eof() .and. Pinwheel( NOINTERUPT )
       if empty( salehist->key )
        monthsold += salehist->qty
        delete
       endif
       mcount++
       skip alias salehist
      enddo
      finitorec := recno()
      goto monthrec
      recall
      salehist->qty := min( monthsold, 9999 )  // update month values
      goto finitorec
     else
      mcount++
      salehist->( dbskip() )
     endif
    endif
    @ 10, 50 say mcount
   enddo
  endif
 endif
endif
dbcloseall()
return
