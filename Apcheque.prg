/**

      Apcheque.prg
        

      Last change:  TG   15 May 2010   10:32 am
*/
Procedure Apcheque

#include "bpos.ch"

#define INV 1
#define CRE 2
#define PAY 3
#define DJN 4
#define CJN 5

#define CURRENT 1
#define DAYS30  2
#define DAYS60  3
#define DAYS90  4

#define CHQCRED  1
#define CHQAMT   2
#define CHQPRINT 3
#define CHQUPDT  4
#define CHQNUM   5

local HaveFiles := Ap_file_open( SHARED )
local mcalc :=NO,mamtcur,mamt30,mamt60,mamt90,mttype,mtnum,mamt,mdesc
local mamtpaid,mtage,mdate,mduedate,choice,mscr,sel,getlist:={}
local oldscr:=Box_Save(),aArray
local mc,m3,m6,m9,pamt,mlo_chq1,mlo_chq2,mhi_chq1,auto_chq, cscr,payarr,payamt
local paycur,pay30,pay60,pay90,process, mchqnum, indisp, element
local mchqcur,mchq30,mchq60,mchq90,mchq_tot,mchq_req,mhead,macc,tscr, mkey
local mtot_req,mhi_chq2,condition,mchqlist:={}, x, nchoice, cchoice, tempamt

while HaveFiles
 Box_Restore( oldscr )
 mttype := PAY
 mtnum := space(6)
 mamt := 0
 mdesc := space(16)
 mamtpaid := 0        // Amount credited to transaction
 mtage := 5           // Transaction age
 mdate:= Bvars( B_DATE )
 mduedate := Bvars( B_DATE )
 Heading('Cheque Processing')
 aArray := {}
 aadd( aArray, { 'Return', 'Return to Creditors Menu' } )
 aadd( aArray, { 'All', 'Pay All Creditors' } )
 aadd( aArray, { 'Individual', 'Pay Individual Creditors' } )
 choice := MenuGen( aArray, 07, 19, 'Cheque')
 if choice = 2
  select supplier
  Box_Save( 03,14,05,63 )
  Center( 04,"Calculating Cash Requirement... Please Wait!" )
  sum supplier->amtcur,1 to mamtcur, mchqcur for supplier->amtcur > 0
  sum supplier->amt30,1 to mamt30, mchq30 for supplier->amt30 > 0
  sum supplier->amt60,1 to mamt60, mchq60 for supplier->amt60 > 0
  sum supplier->amt90,1 to mamt90, mchq90 for supplier->amt90 > 0
  Box_Save(03,2,07,77)
  @ 04,04 say "  Current        30 Days        60 Days        90 Days          Total"
  syscolor( C_BRIGHT )
  @ 05,03 say str(mamtcur,10,2)+'     '+str(mamt30,10,2)+'     '+str(mamt60,10,2);
     +'     '+str(mamt90,10,2)+'     '+str(mamtcur+mamt30+mamt60+mamt90,10,2)
  @ 06,03 say str(mchqcur,10)+'     '+str(mchq30,10)+'     '+str(mchq60,10);
     +'     '+str(mchq90,10)+'     '+str(mchqcur+mchq30+mchq60+mchq90,10)
  syscolor( C_NORMAL )
 endif
 do case
 case choice < 2
  close databases
  return
 case choice = 2
  mlo_chq1 := 0
  mlo_chq2 := 0
  mhi_chq1 := 0
  mhi_chq2 := 0
  macc := space(6)
  mhead := ' '
  mtot_req := 0
  mchq_req := 0
  auto_chq := NO
  paycur := NO
  pay30 := NO
  pay60 := NO
  pay90 := NO
  cscr:=Box_Save(07,2,16,77)
  while TRUE
   Box_Save( 07,2,16,77 )   // I dont know why we need this but we do
   @ 08,4 say "Pay Current..      First Chq.        Description......"
   @ 09,4 say "Pay 30  Days.      Last Chq.."
   @ 10,4 say "Pay 60  Days.      First Chq."
   @ 11,4 say "Pay 90+ Days.      Last Chq..        T/action date...."
   @ 12,4 say "Assign Chqs..      Tot Chq's.        Due Date........."
   @ 13,4 say "                   Chq's req.        Total Amt Req...."
   @ 14,04 say '(E)dit Details    (P)roceed      (C)ancel'
   syscolor( C_BRIGHT )
   @ 08,18 say if( paycur, 'Yes', 'No ')
   @ 08,34 say if( mlo_chq1 > 0, str( mlo_chq1, 6 ), ' n/a  ' )
   @ 08,59 say mdesc
   @ 09,18 say if( pay30, 'Yes', 'No ')
   @ 09,34 say if( mhi_chq1 > 0, str( mhi_chq1, 6 ), ' n/a  ' )
   @ 09,59 say macc
   @ 10,18 say if( pay60, 'Yes', 'No ')
   @ 10,34 say if( mlo_chq2 > 0, str( mlo_chq2, 6 ), ' n/a  ' )
   @ 11,18 say if( pay90, 'Yes', 'No ')
   @ 11,34 say if( mhi_chq2 > 0, str( mhi_chq2, 6 ), ' n/a  ' )
   @ 12,18 say if( auto_chq, 'Yes', 'No ' )
   Highlight( 13, 59, "$ ", Ns( mtot_req, 10, 2 ) )
   Highlight( 13, 34, '', Ns( mchq_req, 4 ) )
   @ 14,05 say 'E'
   @ 14,23 say 'P'
   @ 14,38 say 'C'
   @ 08,59 say mdesc
   @ 09,59 say macc
   @ 10,59 say substr( mhead,1,17 )
   @ 11,59 say mdate
   @ 12,59 say mduedate
   @ 13,59 say mtot_req pict '$999,999.99'
   syscolor( C_NORMAL )
   sel := 'C'
   @ 15,04 say 'Your Choice ?' get sel PICT '!'
   read
   do case
   case sel='E'
    condition := '.f.'
    mtot_req := 0
    mchq_tot := 0
    mchq_req := 0
    @ 08,18 say '   '
    @ 09,18 say '   '
    @ 10,18 say '   '
    @ 11,18 say '   '
    @ 12,18 say '   '
    @ 08,18 get paycur pict 'Y'
    @ 09,18 get pay30  pict 'Y'
    @ 10,18 get pay60  pict 'Y'
    @ 11,18 get pay90  pict 'Y'
    @ 12,18 get auto_chq pict 'Y'
    read
    if paycur
     mtot_req += mamtcur
     mchq_req += mchqcur
    endif
    if pay30
     mtot_req += mamt30
     mchq_req += mchq30
    endif
    if pay60
     mtot_req += mamt60
     mchq_req += mchq60
    endif
    if pay90
     mtot_req += mamt90
     mchq_req += mchq90
    endif
    if auto_chq
     @ 08,34 get mlo_chq1 pict '@Z ######'
     @ 09,34 get mhi_chq1 pict '@Z ######'
     @ 10,34 get mlo_chq2 pict '@Z ######'
     @ 11,34 get mhi_chq2 pict '@Z ######'
     read
     // calculate cheques available
     if mlo_chq1 > 0 .and. mhi_chq1 > 0 .and. mhi_chq1 >= mlo_chq1
      mchq_tot := ( mhi_chq1 - mlo_chq1 ) + 1
      if mlo_chq2 > 0 .and. mhi_chq2 > 0 .and. mhi_chq2 >= mlo_chq2
       mchq_tot += ( mhi_chq2 - mlo_chq2 ) + 1
      endif
     endif
     if mchq_tot>0
      Highlight( 12, 33, '',Ns( mchq_tot,4 ) )
     endif
    endif
    @ 08,59 get mdesc pict '@!'
    select supplier
    @ 09,59 say macc
    @ 10,59 say substr( mhead,1,17 )
    @ 11,59 get mdate
    @ 12,59 get mduedate
    read
   case sel = 'C'
    exit
   case sel = 'P'
    do case
    case empty( mduedate )
     Error( 'You Must Enter A Due Date', 20 )
    case empty( mdate )
     Error( 'You Must Enter A Transaction Date', 20 )
    case mtot_req = 0
     Error( 'You Must Mark Which T/actions To Pay', 20 )
    case auto_chq .and. mchq_tot < mchq_req
     Error( 'Not Enough Cheques Have Been Allocated', 20 )
    otherwise
     Box_Restore( cscr )
     while TRUE
      Heading('Cheque Processing')
      aArray := {}
      aadd( aArray, { 'Return', 'Return to Cheque Menu' } )
      aadd( aArray, { 'List', 'Print list of Creditors to be paid' } )
      aadd( aArray, { 'Print', 'Print Cheques for Creditors' } )
      aadd( aArray, { 'Update', 'Update Creditor Files' } )
      nchoice := MenuGen( aArray, 09, 20, 'All')
      do case
      case nchoice < 2
       exit
      case nchoice = 2
       select supplier
       go top
       mchqlist := {}
       while !supplier->( eof() )
        mamt := 0
        mamtpaid := 0
        process := NO
// decide if creditor is to be paid
        PayAmt := CalcPay( paycur, pay30, pay60, pay90, mduedate )
        if PayAmt > 0
// Array format -> code, amt to pay, cheque printed?, creditor updated, chqnum
          aadd( mchqlist, { supplier->code, PayAmt, FALSE, FALSE, '' } )
        endif
        skip alias supplier
       enddo
       if len( mchqlist ) = 0
        Error( 'No Creditors Selected to be Paid', 12 )
       else
        Heading( 'List of Suppliers to be Paid' )
        element := 1
        mscr:=Box_Save( 08, 30, 23, 79 )
        indisp:=TBrowseNew( 09, 31, 22, 77 )
        indisp:HeadSep:=HEADSEP
        indisp:ColSep:=COLSEP
        indisp:goTopBlock:={ || element:=1 }
        indisp:goBottomBlock:={ || element:= len( mchqlist ) }
        indisp:skipBlock:={|n|ArraySkip(len(mchqlist),@element,n)}
        indisp:addcolumn(tbcolumnnew('Code',{ || padr( mchqlist[ element, CHQCRED ], 4 ) } ) )
        indisp:AddColumn(TBColumnNew('Supplier Name',;
         { || padr( Suppname( mchqlist[ element, CHQCRED ] ), 20)} ) )
        indisp:AddColumn(TBColumnNew('Chq Amount', {||transform(mchqlist[element,CHQAMT],"999,999.99") } ) )
        mkey:=0
        while mkey != K_ESC
         indisp:forcestable()
         mkey:=inkey(0)
         if !Navigate(indisp,mkey)
          do case
          case mkey == K_ENTER
           supplier->( dbseek( mchqlist[ element, CHQCRED ] ) )
           if !supplier->op_it
            tscr := Box_Save( 5, 10, 8, 70 )
            Highlight( 6,12, 'Creditor' , Suppname( mchqlist[ element, CHQCRED ] ) )
            @ 7, 12 say 'Cheque Amount' get mchqlist[ element, CHQAMT ] pict '999999.99'
            read
            Box_Restore( tscr )
           else
            A_tran_disp( TRUE )  // for current
            tempamt := CalcPay( paycur, pay30, pay60, pay90, mduedate )
            if tempamt > 0
             mchqlist[ element, CHQAMT ] := tempamt
            endif
           endif
           indisp:refreshcurrent()
          endcase
         endif
        enddo
       endif
      case nchoice = 3
       if len( mchqlist ) == 0
        Error( 'You must run the listing first', 12 )
       else
// Print Run!
        while TRUE
         Print_find( 'Report' )
         aArray := {}
         aadd( aArray, { 'Return', 'Return to Cheque Menu' } )
         aadd( aArray, { 'Lineup', 'Setup Cheques Printing' } )
         aadd( aArray, { 'All', 'Print all Cheques' } )
         aadd( aArray, { 'From', 'Print Cheques from Creditor' } )
         cchoice := MenuGen( aArray, 11, 21, 'Print')
         do case
         case cchoice  < 2
          exit
         case cchoice = 2
          Heading( 'Align Cheques in Printer' )
          if Isready( 12 )
           ChqPrint( TRUE, '', 0, 0 )
          endif
         case cchoice = 3
          if Isready(12)
           for x := 1 to len( mchqlist )
            if mchqlist[ x, CHQAMT ] > 0
             if auto_chq
              if mlo_chq1 <= mhi_chq1
               mtnum := mlo_chq1
               mlo_chq1++
              else
               mtnum := mlo_chq2
               mlo_chq2++
              endif
              mchqnum := mtnum
             else
              mchqnum := 0
             endif
             supplier->( dbseek( mchqlist[ x, CHQCRED ] ) )
             mscr := Box_Save(21,03,23,50)
             Highlight(22,04,'Processing ',supplier->name)
             mtnum := ChqPrint( FALSE, supplier->name, mchqlist[ x, CHQAMT ], mchqnum, ;
                       paycur, pay30, pay60, pay90, mduedate )
             mchqlist[ x, CHQNUM ] := mtnum
             mchqlist[ x, CHQPRINT ] := TRUE   // Cheque was printed
            endif
           next
          endif
         case cchoice = 4
         endcase
        enddo
       endif
      case nchoice = 4    // Update creditors who have been paid
       if Isready( 12 )
        for x = 1 to len( mchqlist )
         if mchqlist[ x, CHQPRINT ] .and. !mchqlist[ x, CHQUPDT ]
          if supplier->( dbseek( mchqlist[ x, CHQCRED ] ) )
           mscr := Box_Save(21,03,23,50)
           Highlight(22,04,'Processing ',supplier->name)
           if supplier->op_it
            payarr := { 0, 0, 0, 0 }   // For Cur,30,60,90
            if cretrans->( dbseek( supplier->code ) )
             while cretrans->code = supplier->code .and. !eof()
              if ( ( cretrans->tage = CURRENT .and. paycur ) .or. ;
                   ( cretrans->tage = DAYS30 .and. pay30 ) .or. ;
                   ( cretrans->tage = DAYS60 .and. pay60 ) .or. ;
                   ( cretrans->tage = DAYS90 .and. pay90 ) ;
                 ) .and. cretrans->duedate <= mduedate
               payarr[ cretrans->tage ] += cretrans->amt - cretrans->amtpaid
               Rec_lock( 'cretrans' )
               cretrans->amtpaid := cretrans->amt
               cretrans->( dbrunlock() )
              endif
              skip alias cretrans
             enddo
            endif
            Rec_lock('supplier')
            if paycur
             supplier->amtcur -= payarr[ CURRENT ]
            endif
            if pay30
             supplier->amt30 -= payarr[ DAYS30 ]
            endif
            if pay60
             supplier->amt60 -= payarr[ DAYS60 ]
            endif
            if pay90
             supplier->amt90 -= payarr[ DAYS90 ]
            endif
            supplier->( dbrunlock() )
            mamtpaid := payarr[ CURRENT ] + payarr[ DAYS30 ] ;
                      + payarr[ DAYS60 ] + payarr[ DAYS90 ]
           endif
           select cretrans
           mamt = -mchqlist[ x, CHQAMT ]
           mamtpaid = -mchqlist[ x, CHQAMT ]
           Add_rec()
           replace code with supplier->code,;
                   ttype with PAY,;
                   date with mdate,;
                   tnum with Ns( mchqlist[ x, CHQNUM ] ),;
                   amt with mamt,;
                   tage with CURRENT,;
                   amtpaid with mamtpaid,;
                   desc with 'Cheque'
           select supplier
           if !supplier->op_it
            Rec_lock('supplier')
            do case
            case cretrans->tage = CURRENT
             supplier->amtcur += mamt
            case cretrans->tage = DAYS30
             supplier->amt30 += mamt
            case cretrans->tage = DAYS60
             supplier->amt60 += mamt
            case cretrans->tage = DAYS90
             supplier->amt90 += mamt
            case cretrans->tage = 5
             m9 := supplier->amt90
             m6 := supplier->amt60
             m3 := supplier->amt30
             mc := supplier->amtcur
             if m9 >= -mamt
              supplier->amt90 += mamt
              pamt := 0
             else
              mamt += supplier->amt90
              supplier->amt90 := 0
             endif
             if m6 >= -mamt
              supplier->amt60 += mamt
              mamt := 0
             else
              mamt += supplier->amt60
              supplier->amt60 := 0
             endif
             if m3 >= -mamt
              supplier->amt30 += mamt
              mamt := 0
             else
              mamt += supplier->amt30
              supplier->amt30 := 0
             endif
             supplier->amtcur += mamt
            endcase
            supplier->( dbrunlock() )
           endif
           Box_Restore( mscr )
          endif
          mchqlist[ x, CHQUPDT ] := TRUE   // Creditor was updated
         endif                             // !found!
        next
       endif
      endcase
     enddo
    endcase
   endcase
  enddo
 case choice = 3
  select supplier
  dbsetfilter( { || supplier->amtcur+supplier->amt30+supplier->amt60+supplier->amt90 > 0 } )
  go top
  while !eof()
   Creddisp()
   sel := Isready( 17, 02, 'Pay this Creditor?' )
   if lastkey() == K_ESC
    exit
   else
    if sel
     if Aptrango( PAY ) > 0
//    Print_de_cheque( mamt )
     endif
    endif
   endif
   skip
  enddo
  Error( 'No Further Creditors found', 20 )
  supplier->( dbclearfilter() )
 endcase
enddo
*
Function ChqPrint ( testprint, custname, chqamt, chqnum, pc,p3,p6,p9, mduedate )
local moneywords := NumToWords( chqamt ), x, pass
setprc( 0, 0 )
set device to printer
set console off
// Pitch10()
if !testprint
 ChqHead()
 @ prow()+4, 0 say ''
 for pass := 1 to 3
  select cretrans
  seek supplier->code
  while cretrans->code = supplier->code .and. !eof()
   if ( ( cretrans->ttype = 1 .and. pass = 1 ) .or. ;
        ( cretrans->ttype = 2 .and. pass = 2 ) .or. ;
        ( ( cretrans->ttype = 4 .or. cretrans->ttype = 5 ) .and. pass = 3 );
      ) .and. abs( cretrans->amt - cretrans->amtpaid ) > 0
    if ( pc .and. cretrans->tage = 1 ) .or. ;
       ( p3 .and. cretrans->tage = 2 ) .or. ;
       ( p6 .and. cretrans->tage = 3 ) .or. ;
       ( p9 .and. cretrans->tage > 3 )
     if !supplier->op_it .or. cretrans->duedate <= mduedate
      @ prow()+1, 0 say padr( dtoc( cretrans->date ), 13 ) + ;
                        padr( cretrans->tnum, 09 ) + ;
                        padr( tname( cretrans->ttype ) , 12 ) + ;
                        padl( Ns( cretrans->amt-cretrans->amtpaid, 10, 2 ), 10 ) + ;
                        space( 18 ) + ;
                        padl( Ns( cretrans->amt-cretrans->amtpaid, 10, 2 ), 10 )
      if prow() > 40
       ChqBody( 'VOID', 0, 0 )
       eject
       setprc( 0, 0 )
       Chqhead()
      endif
     endif
    endif
   endif
   skip alias cretrans
   if prow() > 40 .and. cretrans->code = supplier->code .and. !cretrans->( eof() )
    ChqBody( 'VOID', 0, 0 )
    chqnum++
    eject
    setprc( 0, 0 )
    Chqhead()
   endif
  enddo
 next          // pass
else
 ChqHead()
 @ prow()+4, 0 say ''
 for x := 1 to 10
  @prow()+1, 0 say 'XXXXXXXXXXX XXXXXXXXX XXXXXXXXXXXX XXXXXXXXXX                  XXXXXXXXXX'
 next
endif
ChqBody( custname, chqnum, chqamt )
eject
set console on
set device to screen
return chqnum
*
function ChqBody ( custname, chqnum, chqamt )
local moneywords := NumtoWords( chqamt )
@ 52, 5 say substr( custname, 1, 30 )
@ prow(),   36 say Bvars( B_DATE )
@ prow(),   47 say if( chqamt != 0, chqnum, 'VOID' )
@ prow(),   64 say if( chqamt != 0, padl( '$'+Ns(chqamt,10,2), 12, '*' ), 'VOID' )
if chqamt != 0
 @ prow()+3, 10 say substr( moneywords, 1, chqspace( moneywords ) )
 @ prow()+1, 10 say substr( moneywords , chqspace( moneywords ) +1 , 50 )
else
 @ prow()+3, 10 say replicate( '*', 15 ) + ' VOID ' + replicate( '*', 15 )
 @ prow()+1, 10 say replicate( '*', 15 ) + ' VOID ' + replicate( '*', 15 )
endif
return nil
*
function ChqHead
@ prow()+8, 25 say supplier->name
@ prow()+1, 25 say supplier->address1
@ prow()+1, 25 say supplier->address2
@ prow()+1, 25 say supplier->city
@ prow()+1, 05 say supplier->code
@ prow(), 65 say Bvars( B_DATE )
return nil
*
function ChqSpace ( mstr )
local mpos := 40, mret := 40
if len( trim( mstr ) ) > 40
 for mpos := 40 to 1 step -1
  if substr(mstr, mpos,1) = ' '
   return( mpos )
  endif
 next
endif
return( mret )  // No spaces return string pos
*
function NumToWords ( mamt )
local camt:=""
local ones:="     One  Two  ThreeFour Five Six  SevenEightNine "
local teen:="Ten      Eleven   Twelve   Thirteen Fourteen Fifteen  Sixteen  "+;
      "SeventeenEighteen Nineteen "
local tens:="Twenty Thirty Forty  Fifty  Sixty  SeventyEighty Ninety"
local cnum:=left(str(mamt,9,2),6),cents

// Hundred thousands
if left( cnum, 1 ) > " "
 camt:=rtrim( substr( ones, val( left( cnum, 1 ) ) * 5+1, 5 ) ) + " Hundred "
endif

// Tens of thousands and thousands
do case
case substr(cnum,2,1)>"1"
 camt += rtrim(substr(tens,val(substr(cnum,2,1))*7-13,7))
 if substr(cnum,3,1)>"0"
  camt+="-"+rtrim(substr(ones,val(substr(cnum,3,1))*5+1,5))
 endif
 camt+=" Thousand " 
case substr(cnum,2,1)="1"
 camt+=rtrim(substr(teen,val(substr(cnum,3,1))*9+1,9))+" Thousand "
case substr(cnum,2,2)="00"
 camt+="Thousand "
case substr(cnum,3,1)>" "
 camt+=rtrim(substr(ones,val(substr(cnum,3,1))*5+1,5))+" Thousand "
endcase

// Hundreds
if substr(cnum,4,1)>"0"
 camt+=rtrim(substr(ones,val(substr(cnum,4,1))*5+1,5))+" Hundred"
endif

// Tens and ones
do case
case substr(cnum,5,1)>"1"
 camt+=if(mamt>99,' and ','') + rtrim(substr(tens,val(substr(cnum,5,1))*7-13,7))
 if right(cnum,1)>"0"
  camt+="-"+rtrim(substr(ones,val(right(cnum,1))*5+1,5))
 endif
case substr(cnum,5,1)="1"
 camt+=if(mamt>99,' and ','')+rtrim(substr(teen,val(right(cnum,1))*9+1,9))
case right(cnum,2)=" 0"
 camt+="Zero"
otherwise
 camt+=if(mamt>9,' and ','')+rtrim(substr(ones,val(right(cnum,1))*5+1,5))
endcase

// Cents
cents := right(str(mamt,9,2),2)
camt := rtrim(camt)+" Dollars " +if(cents='00','Even','and ' + cents +" cents" )

return camt
*
Function Suppname ( mexpr )
supplier->( dbseek( mexpr ) )
return supplier->name
*
function CalcPay( paycur, pay30, pay60, pay90, mduedate )
local mamt := 0
if paycur .and. supplier->amtcur != 0        // Was > 0
 if supplier->op_it
  mamt += OpTranTot( mduedate, supplier->code, CURRENT )
 else
  mamt += supplier->amtcur
 endif
endif
if pay30 .and. supplier->amt30 != 0          // Was > 0
 if supplier->op_it
  mamt += OpTranTot( mduedate, supplier->code, DAYS30 )
 else
  mamt += supplier->amt30
 endif
endif
if pay60 .and. supplier->amt60 != 0           // Was > 0
 if supplier->op_it
  mamt += OpTranTot( mduedate, supplier->code, DAYS60 )
 else
  mamt += supplier->amt60
 endif
endif
if pay90 .and. supplier->amt90 != 0           // Was > 0
 if supplier->op_it
  mamt += OpTranTot( mduedate, supplier->code, DAYS90 )
 else
  mamt += supplier->amt90
 endif
endif
return mamt
*
function OpTranTot( mduedate, mcode, mdays )
local mtot := 0
// Only Add up Credit ( type=2 ) .and. Invoice ( type=1 ) records
cretrans->( dbseek( mcode ) )
while cretrans->code = mcode .and. !cretrans->( eof() )
 if cretrans->tage = mdays .and. cretrans->duedate <= mduedate .and.;
    cretrans->ttype < 3
  mtot += cretrans->amt - cretrans->amtpaid
 endif
 skip alias cretrans
enddo
return mtot
