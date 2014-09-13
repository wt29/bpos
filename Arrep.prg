/*

        Arrep.prg
        

      Last change:  TG   18 Oct 2010    9:44 pm
*/
field amtcur, amt30, amt60, amt90, amt, amtpaid, date, ttype, tage
field name, phone1, ytdamt, key, salestax

Procedure Arrep

#include "bpos.ch"

local oldscr:=Box_Save(),choice, aArray
local getlist:={}, printzero, report_desc, curr_per, msum
local aReport

while TRUE
 Box_Restore( oldscr )
 Print_find("report")
 Heading('Accounts Receivable Reports')
 aArray := {}
 aadd( aArray, { 'Debtors', 'Return to Debtors Menu' } )
 aadd( aArray, { 'Trial Balance', 'Aged Trial Balance' } )
 aadd( aArray, { 'All', 'Transactions' } )
 aadd( aArray, { 'Journals', 'Credit/Debit Journals' } )
 aadd( aArray, { 'Payments', 'Print All Payments' } )
 aadd( aArray, { 'Sales', 'Print Sales Register' } )
 aadd( aArray, { 'Banking', 'Print Banking List' } )
 aadd( aArray, { 'Master', 'Print Debtor Master List' } )

 choice := MenuGen( aArray, 07, 02, 'Reports')

 do case
 case choice < 2
  return
 case choice = 2
  Box_Save(2,08,6,72)
  printzero:=FALSE
  msum:=FALSE
  @ 03,10 say 'Summary Report' get msum pict 'Y'
  @ 05,10 say 'Print Debtors with Zero Balance' get printzero pict 'Y'
  read
  if Isready(12)
   if ar_file_open( SHARED )
    Trialbal(msum,printzero)
    close databases

   endif

  endif
 case choice > 2 .and. choice < 7
  if Ar_file_open( SHARED )
   select debtrans
   ordsetfocus( 2 )
   set relation to key into customer
   curr_per := TRUE
   Box_Save(2,25,4,55)
   @ 3,26 say 'Print Current Period Only?' get curr_per pict 'y'
   read

   Print_find("report")

   if Isready(12)
    do case
    case choice = 3
     report_desc := "Debtor Transaction List" + ;
                  if( curr_per, ' - Current Period Only', ' - All Periods ' )
     if curr_per
      dbsetfilter( { || tage = 1 } )
     endif
    case choice = 4
     report_desc := "Debtor Journal Register" + ;
                  if( curr_per, ' - Current Period Only', ' - All Periods ' )
     if curr_per
      dbsetfilter( { || (ttype=4 .or. ttype=5) .and. tage=1 } )
     else
      dbsetfilter( { || ttype=4 .or. ttype=5 } )
     endif
    case choice = 5
     report_desc := "Debtor Payment Register" + ;
                  if( curr_per, ' - Current Period Only', ' - All Periods ' )
     if curr_per
      dbsetfilter( { || ttype=3 .and. tage=1 } )
     else
      dbsetfilter( { || ttype=3 } )
     endif
    case choice = 6
     report_desc := "Debtor Sales Journal" + ;
                  if( curr_per, ' - Current Period Only', ' - All Periods ' )
     if curr_per
      dbsetfilter( { || (ttype=1 .or. ttype=2) .and. tage=1 } )
     else
      dbsetfilter( { || ttype=1 .or. ttype=2 } )
     endif
    endcase
    dbgotop()
  //   // Pitch17()
    aReport := {}
    aadd(aReport,{'key','Key',10,0,FALSE})
    aadd(aReport,{'substr(supplier->name,1,20)','Customer Name',20,0,FALSE})
    aadd(aReport,{'date','Date',8,0,FALSE})
    aadd(aReport,{'tname(ttype)','Trans;Type',7,0,FALSE})
    aadd(aReport,{'tnum','Ref No',6,0,FALSE})
    aadd(aReport,{'sundries','Sundries',10,2,TRUE})
    aadd(aReport,{'freight','Freight',10,2,TRUE})
    aadd(aReport,{'amt','Amount',10,2,FALSE})
    aadd(aReport,{'agename(tage)','Age',10,0,FALSE})

    Reporter( aReport,;
            report_desc,;
            ,;
            ,;
            ,;
            ,;
            ,;
             )
    set filter to

   endif

   close databases

  endif
 case choice = 7
  Heading("Print Banking List")
  if Isready(12)
   if Ar_file_open( SHARED )
    select debbank
    indx( "key", 'key' )
    go top
//    // Pitch17()
     aReport := {}
     aadd( aReport,{'customer->key','Customer;Key',10,0,FALSE})
     aadd( aReport,{'date','Date',8,0,FALSE})
     aadd( aReport,{'tnum','Trans;Num',6,0,FALSE})
     aadd( aReport,{'cash','Amount;Cash',10,2,TRUE})
     aadd( aReport,{'cheque','Amount;Cheque',10,2,TRUE})
     aadd( aReport,{'drawer','drawer',20,0,FALSE})
     aadd( aReport,{'bank','Bank',20,0,FALSE})
     aadd( aReport,{'bnkbranch','Branch',20,0,FALSE})
     Reporter( aReport,;
               "Banking List",;
               ,;
               ,;
               ,;
               ,;
               ,;
               )

    orddestroy( 'key' )
    Box_Save(14,08,16,72)
    Center(15,"Erase banking file ?")
    if Isready(18)
     if Netuse( "debbank", EXCLUSIVE, 10, OLD )
      zap
     endif
    endif
   endif
   close databases
  endif
 case choice = 8
  if Ar_file_open( SHARED )
   if Isready(14)
//    // Pitch17()
     customer->( dbgotop() )
     aReport := {}
     aadd( aReport,{'customer->key','Key',10,0,FALSE})
     aadd( aReport,{'substr( customer->name)','Name',25,0,FALSE})
     aadd( aReport,{'customer->add1','Address 1',25,0,FALSE})
     aadd( aReport,{'customer->add2','Address 2',25,0,FALSE})
     aadd( aReport,{'customer->add3','Address 3',25,0,FALSE})
     aadd( aReport,{'customer->pcode','Post;Code',5,0,FALSE})
     aadd( aReport,{'customer->phone1','Telephone',14,0,FALSE})
     Reporter( aReport,;
               "Debtor Master List;Sorted by Key",;
               ,;
               ,;
               ,;
               ,;
               ,;
               )

   endif
   close databases
   Kill( Oddvars( TEMPFILE ) + ordbagext() )

  endif

 endcase

enddo

*

procedure trialbal ( msum, printzero )

local totcur,tot30,tot60,tot90,totytd:=0
local totinv:=0,totcre:=0,totpay:=0,totdbj:=0,totcrj:=0,mpage:=1
local e,trantotals,disc,custtotals,bpos,apos
local report_desc:="Trial Balance" + if( msum , ' Ä Summary Only','' )


// Pitch17()
setprc( 0, 0 )
set device to print
set console off
select customer
if !printzero
 report_desc += ' Ä Excludes Debtors with a zero balance'
endif
customer->( ordsetfocus( BY_KEY ) )
customer->( dbgotop() )
totcur:=tot30:=tot60:=tot90:=totytd:=0
while !customer->( eof() )
 if prow() = 0
  apos := ( ( 136-len( BPOSCUST ) )/2 ) - 8
  bpos := ( ( 136-len( report_desc ) )/2 ) - 7
  @ prow()+1,01 say dtoc( Bvars( B_DATE ) ) + space( apos ) + BPOSCUST
  @ prow()+2,00 say 'Page ' + Ns( mpage,2 ) + space( bpos ) + report_desc
  @ prow()+2,00 say "Debtor Id#   Name                             Phone" ;
     + "          Current $    30 Days $    60 Days $" ;
     + "   90+ Days $      Total $       Ytd  $"
  @ prow()+1,00 say replicate( HEADSEP,136 )
 endif
 if prow() < 58
  totcur += amtcur
  tot30 += amt30
  tot60 += amt60
  tot90 += amt90
  totytd += ytdamt
  e := Vs( amtcur + amt30 + amt60 + amt90, 10, 2 )
  if !msum
   if printzero .or. amtcur+amt30+amt60+amt90 != 0
    @ prow()+1,0 say key+ '    ' +substr(name,1,25)+ '  ' +phone1
    @ prow(),60 say if(amtcur!=0,str(amtcur,10,2),space(10))+ '   ' +if(amt30!=0,str(amt30,10,2),space(10))
    @ prow(),86 say if(amt60!=0,str(amt60,10,2),space(10))+ '   ' +if(amt90!=0,str(amt90,10,2),space(10));
        + '   ' +if(e!=0,str(e,10,2),space(10))+ '   ' +str(ytdamt,10,2)
   endif
  endif
  customer->( dbskip() )

 else
  eject
  mpage++

 endif

enddo
if prow() > 52
 eject
 mpage++
 @ 01,00 say dtoc( Bvars( B_DATE ) ) + space( apos ) + BPOSCUST
 @ 03,00 say 'Page '+Ns(mpage,2)+space(bpos)+report_desc
 @ 05,00 say " Debtor Id#    Debtor Name                Phone " ;
    + "            Current $    30 Days $    60 Days $" ;
    + "   90+ Days $      Total $       YTD  $"
 @ 06,00 say replicate( HEADSEP, 136 )

endif
@ prow()+1,60 say "ÍÍÍÍÍÍÍÍÍÍ   ÍÍÍÍÍÍÍÍÍÍ   ÍÍÍÍÍÍÍÍÍÍ   ÍÍÍÍÍÍÍÍÍÍ   ÍÍÍÍÍÍÍÍÍÍ   ÍÍÍÍÍÍÍÍÍÍ"
@ prow()+1,40 say "Total  $....."
@ prow(),60 say str( totcur, 10, 2 )
@ prow(),73 say str( tot30, 10, 2 )
@ prow(),86 say str( tot60, 10, 2 )
@ prow(),99 say str( tot90, 10, 2 )
@ prow(),112 say str( totcur + tot30 + tot60 + tot90, 10, 2 )
@ prow(),125 say str( totytd, 10, 2 )
custtotals := totcur+tot30+tot60+tot90

@ prow()+2,40 say "ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ End of Report ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ"

select debtrans
debtrans->( ordsetfocus( NATURAL ) )
debtrans->( dbgotop() )
while !debtrans->( eof() )
 if tage = 1
  do case
  case ttype=1
   totinv+=( amt )
  case ttype=2
   totcre-=( amt )
  case ttype=3
   totpay-=( amt )
  case ttype=4
   totdbj+=( amt )
  case ttype=5
   totcrj-=( amt )
  endcase

 endif
 debtrans->( dbskip() )

enddo

// Pitch10()

@ 00,00 say dtoc( Bvars( B_DATE ) ) + padc( BPOSCUST, 60 ) + 'Page ' + Ns( mpage, 3 )
@ 01,00 say padc( 'Debtors Trial Balance SysAudit Report', 80 )

@ 03,10 say 'Opening Balance.... '+str( Oddvars( DEB_OP_BAL ), 10, 2 )
@ 04,10 say '+ Sales............ '+str( totinv, 10, 2 )
@ 05,10 say '+ Debit Journals... '+str( totdbj, 10, 2 )
@ 06,10 say '- Payments......... '+str( totpay, 10, 2 )
@ 07,10 say '- Credits.......... '+str( totcre, 10, 2 )
@ 08,10 say '- Credit Journals.. '+str( totcrj, 10, 2 )
@ 09,10 say '                    ÄÄÄÄÄÄÄÄÄÄ'

trantotals := Oddvars( DEB_OP_BAL )+totinv+totdbj-totcre-totpay-totcrj
@ 10,10 say 'Total/............. '+str( trantotals, 10, 2 )
@ 11,10 say 'Closing Balance.... '+str( custtotals, 10, 2 )

if Vs( trantotals ) != Vs( custtotals )
 if Vs( trantotals ) < Vs( custtotals )
  disc := Vs( custtotals ) - Vs( trantotals )
 else
  disc := Vs( trantotals ) - Vs( custtotals )
 endif
 @ 15,10 say 'Discrepancy is..... '+str( disc,10,2 )
endif

eject
// Pitch10()
debtrans->( ordsetfocus( 'key' ) )
customer->( ordsetfocus( BY_KEY ) )
set console on
set device to screen
return
