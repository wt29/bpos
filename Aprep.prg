/*

        Aprep.prg
        
        Copyright(c)  2000
        
        Author: Tony Glynn

      Last change:  TG    5 Jan 2011    9:20 pm
*/
Procedure Aprep

#include "bpos.ch"

#define INV 1
#define CRE 2
#define PAY 3
#define DJN 4
#define CJN 5

local choice, oldscr := Box_Save( 0, 0, 24, 79 )
local term:=0,tflag:=NO,totcur,tot30,tot60,tot90,e,totytd,row,mpage
local reptit,totinv,totcre,totpay,totdbj,totcrj,msummary,supptot,trantot
local discrepancy, getlist := {}, curr_per, bpos, apos, printzero, aArray

local aReport

field amtcur, amt30, amt60, amt90, amt, amtpaid, ytdamt, code, phone, name


while TRUE
 Box_Restore( oldscr )
 Heading( 'Accounts Payable Reports' )
 aArray := {}
 aadd( aArray, { 'Return', 'Return to Creditors Menu' } )
 aadd( aArray, { 'Trial Balance', 'Print Aged Trial Balance' } )
 aadd( aArray, { 'All', 'All Transactions' } )
 aadd( aArray, { 'Journals', 'Credit/Debit Journals' } )
 aadd( aArray, { 'Payments', 'Print All Payments' } )
 aadd( aArray, { 'Purchases', 'Print Purchases Register' } )
 choice := MenuGen( aArray, 08, 19, 'Reports' )
 do case
 case choice < 2
  return
 case choice = 2
  Box_Save(2,08,6,72)
  printzero := NO
  msummary := NO
  @ 3,10 say 'Summary Report' get msummary pict 'y'
  @ 5,10 say 'Print Creditors with Zero Balance' get printzero pict 'y'
  read
  if Isready( 9 )
   if Ap_file_open( NO )
    totinv:=totcre:=totpay:=totdbj:=totcrj:=0
    totcur:=tot30:=tot60:=tot90:=e:=totytd:=0 
    row:=1
    mpage:=1
    reptit := "Trial Balance" + if(msummary,' - Summary only','')+;
          if(printzero,'',' - Excludes Creditors with a zero balance')

    // Pitch17()
    set device to print
    set console off
    select supplier
    go top
    while !supplier->( eof() ) .and. pinwheel( NOINTERUPT )
     if term = K_ESC
      go bott
      skip
      tflag:=YES
      exit
     endif
     term := inkey()
     if row=1
      apos:=((136-len(trim( BVars( B_NAME ) )))/2)-8
      bpos:=((136-len(reptit))/2)-7
      @ 1,1 say  dtoc(Bvars( B_DATE ))+space(apos)+trim( BVars( B_NAME ) )
      @ 3,0 say 'PAGE '+ltrim(str(mpage,2))+space(bpos)+reptit
      @ 5,0 say "Credit Id   Creditor Name                     Phone" ;
          + "          Current $    30 Days $    60 Days $" ;
          + "   90+ Days $      Total $       Ytd  $"
      @ 6,0 say replicate( HEADSEP, 136 )
      row:=7
     endif
     if row<58
      totcur+=amtcur
      tot30+=amt30
      tot60+=amt60
      tot90+=amt90
      totytd+=ytdamt
      e:=Vs((amtcur+amt30+amt60+amt90),10,2)
      if !msummary .and. ( printzero .or. amtcur+amt30+amt60+amt90 # 0 )
       @ row,0 say code +'    ' + substr(name,1,35) + '  ' +phone
       @ row,60 say if(amtcur!=0,str(amtcur,10,2),space(10))+ '   ' +if(amt30!=0,str(amt30,10,2),space(10))
       @ row,86 say if(amt60!=0,str(amt60,10,2),space(10))+ '   ' +if(amt90!=0,str(amt90,10,2),space(10));
      + '   ' +if(e!=0,str(e,10,2),space(10))+ '   ' +str(ytdamt,10,2)
       row++
      endif
      skip
     else
      eject
      mpage++
      row:=1
     endif
     if term = K_ESC
      go bott
      skip
      tflag := YES
      exit
     endif
     enddo
     if tflag
      @ row+2,40 say "ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Report Terminated ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ"
      // Pitch10()
      set device to screen
      set printer off
      endprint()
      return
     else
      if row>52
       eject
       mpage++
       @ 1,0 say dtoc( Bvars( B_DATE ) ) + space( apos ) + trim( BVars( B_NAME ) )
       @ 3,0 say 'Page '+Ns(mpage,2)+space(bpos)+reptit
       @ 5,0 say "   Id          Creditor                   Phone " ;
          + "            Current $    30 Days $    60 Days $" ;
          + "   90+ Days $      Total $       YTD  $"
       @ 6,0 say replicate( HEADSEP, 136 )
       row:=7
      endif
      @ row,60 say "ÍÍÍÍÍÍÍÍÍÍ   ÍÍÍÍÍÍÍÍÍÍ   ÍÍÍÍÍÍÍÍÍÍ   ÍÍÍÍÍÍÍÍÍÍ   ÍÍÍÍÍÍÍÍÍÍ   ÍÍÍÍÍÍÍÍÍÍ"
      @ row+1,48 say "Total  $....."
      @ row+1,60 say str( totcur, 10, 2 )
      @ row+1,73 say str( tot30, 10, 2 )
      @ row+1,86 say str( tot60, 10, 2 )
      @ row+1,99 say str( tot90, 10, 2 )
      @ row+1,112 say str( totcur+tot30+tot60+tot90, 10, 2 )
      @ row+1,125 say str( totytd, 10, 2 )
      @ row+2,40 say "ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ End of Report ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ"
     endif
     select cretrans
     set index to
     go top
     while !eof()
      if cretrans->tage = 1
       do case
       case cretrans->ttype = INV
        totinv += amt
       case cretrans->ttype = CRE
        totcre -= amt
       case cretrans->ttype = PAY
        totpay -= amt
       case cretrans->ttype = DJN
        totdbj += amt
       case cretrans->ttype = CJN
        totcrj -= amt
       endcase
      endif
      skip
     enddo
     // Pitch10()
     @ 0,0 say dtoc( Bvars( B_DATE ) ) + padc( trim( BVars( B_NAME ) ), 60 ) + 'Page ' + Ns( mpage, 2 )
     @ 1,0 say padc( 'Creditors Trial Balance SysAudit Report', 80 )
     @ 06,10 say '     Opening Balance.... '+str( Oddvars( CRE_OP_BAL ),10,2)
     @ 07,10 say '     + Purchases........ '+str(totinv,10,2)
     @ 09,10 say '     + Debit Journals... '+str(totdbj,10,2)
     @ 10,10 say '     - Payments......... '+str(totpay,10,2)
     @ 11,10 say '     - Credits.......... '+str(totcre,10,2)
     @ 12,10 say '     - Credit Journals.. '+str(totcrj,10,2)
     @ 13,10 say '                         ÄÄÄÄÄÄÄÄÄ-'

     supptot := totcur+tot30+tot60+tot90
     trantot := Oddvars( CRE_OP_BAL )+totinv+totdbj-totcre-totpay-totcrj

     @ 14,10 say '     Total.............. '+str(supptot,10,2)
     @ 15,10 say '     Closing Balance.... '+str(trantot,10,2)
     if Vs(supptot,10,2) != Vs(trantot,10,2)
      if Vs(supptot,10,2) < Vs(trantot,10,2)
       discrepancy:=Vs(trantot,10,2) - Vs(supptot,10,2)
      else
       discrepancy:=Vs(supptot,10,2) - Vs(trantot,10,2)
      endif
      @ 17,10 say '     Discrepancy is..... '+str(discrepancy,10,2)
     endif
     set device to screen
     Endprint()
    close databases
   endif
  endif
 case choice > 2 .and. choice < 7
  if ap_file_open( NO )
   select cretrans
   set relation to cretrans->code into supplier
   curr_per := YES
   Box_Save( 2, 25, 4, 55 )
   @ 3,26 say 'Print Current Period Only?' get curr_per pict 'Y'
   read
   Print_find("report")
   
   if Isready(12)
    do case
    case choice = 3
     reptit:="Transaction List"
     If Curr_Per
      dbsetfilter( { || cretrans->tage = 1 } )
     Endif
    case choice = 4
     reptit:="Journal Register"
     if Curr_Per
      dbsetfilter( { || ( cretrans->ttype=DJN .or. cretrans->ttype=CJN ) .and. cretrans->tage = 1 } )
     else
      dbsetfilter( { || ( cretrans->ttype=DJN .or. cretrans->ttype=CJN ) } )
     endif
    case choice = 5
     reptit:="Payment Register"
     if Curr_Per
      dbsetfilter( { || cretrans->ttype = PAY .and. cretrans->tage = 1 } )
     else
      dbsetfilter( { || cretrans->ttype = PAY } )
     endif
    case choice = 6
     reptit:="Sales Journal"
     if Curr_per
      dbsetfilter( { || ( cretrans->ttype=INV .or. cretrans->ttype=CRE ) .and. cretrans->tage = 1 } )
     else
      dbsetfilter( { || cretrans->ttype=INV .or. cretrans->ttype=CRE } )
     endif
    endcase
    go top

    aReport := {}
    aadd(aReport,{'id','Tran;Code',4,0,FALSE})
    aadd(aReport,{'substr(supplier->name,1,20)','Creditor Name',30,0,FALSE})
    aadd(aReport,{'date','Date',8,0,FALSE})
    aadd(aReport,{'tname(ttype)','Trans;Type',7,0,FALSE})
    aadd(aReport,{'tnum','Ref No',6,0,FALSE})
    aadd(aReport,{'amt','Amount',10,2,FALSE})
    aadd(aReport,{'agename(tage)','Age',10,0,FALSE})
    aadd(aReport,{'tnum','Ref No',6,0,FALSE})

    Reporter( aReport,;
            reptit,;
            ,;
            ,;
            ,;
            ,;
            ,;
             )

    endif

   dbcloseall()

  endif

 endcase

enddo
