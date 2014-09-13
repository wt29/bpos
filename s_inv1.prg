/*
      s_inv1.prg

      Last change:  TG   27 Feb 2011    1:43 pm
*/
#include "bpos.ch"

procedure s_invoice

local mgo:=FALSE,choice,mchoice,mcustkey,minvno
local mno,mdate,okf5,mscr,getlist:={},loopval,inbrow,mkey,mseq,mreq
local oldscr:=Box_Save(),deladd,mqty,x
local minv, mtrmac, mhdbf, mldbf, f_arr, aArray

Center( 24, 'Opening files for Invoice/Credit Notes' )
if Netuse( "approval" )
 if Netuse( "hold" )
  if Netuse( "special" )
   if Netuse( "draft_po" )
    if Netuse( "pickslip" )
     if Netuse( "debtrans" )
      if Netuse( "customer" )
       if Netuse( "sales" )
        if Master_use()
         if Netuse( "invline" )
          set relation to invline->id into master
          if Netuse( "invhead" )
           set relation to invhead->number into invline,;
                        to invhead->key into customer
           mgo := TRUE
          endif
         endif 
        endif
       endif
      endif
     endif
    endif
   endif
  endif
 endif
endif
line_clear(24)

while mgo
 Box_Restore( oldscr )
 minv := TRUE
 mtrmac := 'Invoice'
 Heading( "Invoice/Credit Note Menu" )
 aArray := {}
 aadd( aArray, { 'Sales', 'Return to Sales Menu' } )
 aadd( aArray, { 'Invoice', 'Create a Sales Invoice' } )
 aadd( aArray, { 'Credit Note', 'Create a Credit Note' } )
 aadd( aArray, { 'Proforma', 'Create a Proforma Invoice' } )
 aadd( aArray, { 'Enquire', 'Display Sales Invoice' } )
 aadd( aArray, { 'Reprint', 'Reprint Invoices' } )
 aadd( aArray, { 'Purge', 'Purge old Invoice Details' } )
 aadd( aArray, { 'Archive', 'Invoice Archive system' } )

 okf5 := setkey( K_F5 , { || total_freight() } )
 choice := MenuGen( aArray, 06, 35, 'Invoices' )
 setkey( K_F5 , okf5 )

 oldscr := Box_Save()
 do case
 case choice < 2
  exit
 case choice = 2
  Invcreate( FALSE, TRUE, 'Invoice' )
 case choice = 3
  Invcreate( FALSE, FALSE, 'Credit Note' )
 case choice = 4
  Invcreate( TRUE, minv, mtrmac )
 case choice = 5
  while TRUE
   Box_Restore( oldscr )
   Heading( 'Invoice File Enquiry' )
   aArray := {}
   aadd( aArray, { 'Return', 'Return to Invoice Menu' } )
   aadd( aArray, { 'Number', 'Inquiry by Reference Number' } )
   aadd( aArray, { 'Key', 'Inquiry by Customer Key ' } )
   mchoice := MenuGen( aArray, 10, 36, 'Enquire')
   do case
   case mchoice < 2
    exit
   case mchoice = 2
    while TRUE
     Heading( 'Invoice File Inquiry' )
     minvno := 0
     @ 12,44 say 'ÍÍÍ¯Invoice/Credit #' get minvno pict '999999'
     read
     if !updated()
      exit
     else
      if !invhead->( dbseek( minvno ) ) 
       Error('Invoice Number ' + Ns( minvno ) + ' not on file',12)
      else
       Invenq()
      endif
     endif
    enddo
   case mchoice = 3
    while TRUE
     if !CustFind( TRUE )
      exit

     else
      mcustkey := customer->key
      Heading('Inquire by Key')
      select invhead
      ordsetfocus( BY_KEY )
      if !dbseek( mcustkey )
       Error('No Invoices Found for Customer',12)
       exit

      else
       Box_Save(02,02,24,77)
       Highlight(03,12,'Customer->',customer->name)
       for x = 1 to 24-6
        @ x+5,3 say row()-5 pict '99'

       next
       inbrow:=TBrowseDB(04, 05, 24-1, 76)
       inbrow:HeadSep := HEADSEP
       inbrow:ColSep:=COLSEP
       inbrow:goTopBlock := { || dbseek( mcustkey ) }
       inbrow:goBottomBlock  := { || jumptobott( mcustkey ) }
       inbrow:skipBlock:=Keyskipblock( { || invhead->key}, mcustkey )
       inbrow:addcolumn( tbcolumnNew( 'Number', { || invhead->number } ) )
       inbrow:addcolumn( tbcolumnNew( 'Date', { || invhead->date } ) )
       inbrow:addcolumn( tbcolumnNew( 'Order No', { || invhead->order_no } ) )
       inbrow:addcolumn( tbcolumnNew( 'Type', { || if( invhead->inv, 'Invoice',' Credit' ) } ) )
       inbrow:addcolumn( tbcolumnNew( 'First Desc', { || substr( master->desc, 1, 25 ) } ) )
       inbrow:addcolumn( tbcolumnNew( 'Comments', { || invhead->message1 } ) )
       inbrow:freeze := 1
       inbrow:goTop()
       mkey := 0
       while mkey != K_ESC .and. mkey != K_END
        inbrow:forcestable()
        mkey:=inkey(0)
        if !Navigate(inbrow,mkey)
         do case
         case mkey >= 48 .and. mkey <= 57
          keyboard chr( mkey )
          mseq := 0
          mscr:=Box_Save( 2,08,4,40 )
          @ 3,10 say 'Selecting No' get mseq pict '999' range 1,24-2
          read
          Box_Restore( mscr )
          if !updated()
           loop
          else
           mreq := recno()
           skip mseq - inbrow:rowpos
           Invenq()
           goto mreq
          endif
         case mkey == K_ENTER
          Invenq()
         endcase
        endif
       enddo
      endif
     endif
     invhead->( ordsetfocus( BY_NUMBER ) )
    enddo
   endcase
  enddo
 case choice = 6
  while TRUE
   Box_Restore( oldscr )
   Heading('Invoice Print Options')
   aArray := {}
   aadd( aArray, { 'Exit', 'Return to Invoice Menu  ' } )
   aadd( aArray, { 'Invoice', 'Reprint an Invoice/Credit Note' } )
   aadd( aArray, { 'Label', 'Produce a Package Label' } )
   aadd( aArray, { 'PickSlip', 'Reprint a Picking Slip' } )
   mchoice := MenuGen( aArray, 12, 36, 'Reprint' )
   do case
   case mchoice < 2
    exit
   case mchoice = 2
    Heading('Invoice Reprint')
    Box_Save( 04, 08, 18, 72 )
    Print_find("invoice","report")
    @ 6, 10 say 'This option enables you to reprint invoices/credits.'
    @ 8, 10 say 'Please ensure that you have the right printer selected.'
    mno := 0
    @ 10, 10 say 'Reference No for reprint ' get mno pict '999999'
    read
    if !updated()
     loopval := FALSE
    else
     if !invhead->( dbseek( mno ) )
      Error( 'Reference No not on file', 13 )
     else
      Highlight( 12, 10, 'Customer Name ',Left( Lookitup( 'customer', invhead->key, ,'key' ), 30 ) )
      
      if Isready( 14 )
       Center( 16, '-=< Invoice/Credit Printing in Progress >=-' )
       Invform( mno )
      endif
     endif
    endif
   case mchoice = 3
    while TRUE
     Heading( "Print Package Label" )
     if !CustFind( TRUE )
      exit
     else
      mqty := 1
      Box_Save( 2, 10, 10, 70 )
      Highlight( 3, 12, "Name ", customer->name )
      Highlight( 4, 12, "Add1 ", customer->add1 )
      Highlight( 5, 12, "     ", trim(customer->add2)+' '+customer->pcode )
      @ 9, 12 say 'Qty to Print' get mqty pict '999'
      read
      Print_find( "label", "report" )
      
      if Isready(10)
       deladd := !empty( customer->dadd1 )
       for x:= 1 to mqty
        set print on
        set console off
        ?
        ?
        ?
        ? BIGCHARS + space(4) + trim(customer->name)
        ?
        ? BIGCHARS + space(4) + if( deladd, customer->dadd1, customer->add1 ) + NOBIGCHARS
        ? BIGCHARS + space(4) + if( deladd, customer->dadd2, customer->add2 ) + NOBIGCHARS
        ? BIGCHARS + space(4) + trim( if( deladd, customer->dadd3, customer->add3 ) )+;
           ' ' + if( deladd, customer->dpcode, customer->pcode ) + NOBIGCHARS
       next
       endprint()
       set print off
       set console on
      endif
     endif
    enddo

   case mchoice = 4
    Heading( 'Picking Slip Reprint' )
    Box_Save( 04, 08, 18, 72 )
    Print_find( "pickslip", "report" )
    @ 6,10 say 'This option enables you to reprint Picking Slips'
    @ 8,10 say 'Please ensure that you have the right printer selected.'
    mno := 0
    @ 10,10 say 'Reference No for reprint ' get mno pict '999999'
    read
    if !updated()
     loopval := FALSE
    else
     if !pickslip->( dbseek( mno ) ) 
      Error('Reference No not on file',13)
     else
      Highlight( 12, 10, 'Customer Name ', trim( Lookitup( 'customer', pickslip->key, ,'key' ) ) )
      
      if Isready( 14 )
       Center( 16, '-=< Picking Slip Printing in Progress >=-' )
       PickSlip( mno )
      endif
     endif
    endif
   endcase
  enddo
 case choice = 7
  if Secure( X_SYSUTILS )
   Heading('Invoice Purge Options')
   Box_Save( 12,36,16,46 )
   aArray := {}
   aadd( aArray, { 'Exit', 'Return to Invoice Menu  ' } )
   aadd( aArray, { 'Invoice', 'Delete old Invoices/Credit Notes' } )
   aadd( aArray, { 'PickSlip', 'Delete old Picking Slips' } )
   mchoice := MenuGen( aArray, 12, 36, 'Delete')
   do case
   case mchoice < 2
    exit
   case mchoice = 2
    mdate := Bvars( B_DATE ) - 365
    Box_Save( 2, 08, 9, 72 )
    Heading( 'Purge Old Invoice Details' )
    @ 3,10 say 'Clear invoices/credits older than' get mdate
    read
    Center( 5, 'You are about to clear all invoices older than ' + dtoc( mdate ) )
    if Isready( 7 )
     Center( 7, '-=< Processing - Please Wait >=-' )
     invhead->( dbclosearea() )
     if Netuse( 'invhead', EXCLUSIVE )
      invline->( dbclosearea() )
      if Netuse( 'invline', EXCLUSIVE )
       select invhead
       set relation to invhead->number into invline
       while invhead->date < mdate .and. !invhead->( eof() )
        while invline->number = invhead->number .and. !invline->( eof() )
         invline->( dbdelete() )
         invline->( dbskip() )
        enddo
        invhead->( dbdelete() )
        invhead->( dbskip() )
       enddo
      endif
      invline->( dbclosearea() )
      Netuse( 'invline' )
      set relation to invline->id into master
      invhead->( dbclosearea() )
      Netuse( 'invhead' )
      set relation to invhead->number into invline,;
                      to invhead->key into customer
      SysAudit( "InvPurge" + dtoc( mdate ) )
     endif
    endif
   case mchoice = 3
    mdate := Bvars( B_DATE ) - 365
    Box_Save( 2, 08, 9, 72 )
    Heading( 'Purge Old Picking Slip Details' )
    @ 3,10 say 'Clear Picking Slips older than' get mdate
    read
    Center( 5, 'You are about to clear all picking slips older than ' + dtoc( mdate ) )
    if Isready(7)
     Center(7,'-=< Processing - Please Wait >=-')
     pickslip->( dbclosearea() )
     if Netuse( 'pickslip', EXCLUSIVE )
      delete for pickslip->date < mdate
     endif
     pickslip->( dbclosearea() )
     Netuse( 'pickslip' )
     SysAudit( 'PickSlipPurge' )
    endif
   endcase
  endif
 case choice = 8
  if Secure( X_SYSUTILS )
   Heading( 'Invoice Archive Options' )
   Box_Save( 13, 36, 17, 46 )
   aArray := {}
   aadd( aArray, { 'Exit', 'Return to Invoice Menu' } )
   aadd( aArray, { 'Create', 'Create an Invoice Archive' } )
   aadd( aArray, { 'Retrieve', 'Retrieve Invoice from Archive' } )
   mchoice := MenuGen( aArray, 13, 36, 'Archive' )
   do case
   case mchoice < 2
    exit
   case mchoice = 2
    Heading( 'Create an Invoice Archive' )
    mdate := year( Bvars( B_DATE ) - 365 )
    Box_Save(2,08,9,72)
    @ 3,10 say 'Create an Invoice Archive for year' get mdate pict '9999'
    read
    Center( 5, 'You are about to archive all invoices in year ' + Ns( mdate ) )
    if Isready( 12 )
     invhead->( dbclosearea() )
     if Netuse('invhead', EXCLUSIVE )

      mhdbf := 'inharc' + right( Ns( mdate ), 2 )
      copy stru to ( mhdbf )

      invline->( dbclosearea() )
      if Netuse('invline', EXCLUSIVE )

       mldbf := 'inlarc' + right( Ns( mdate ), 2 )
       copy stru to ( mldbf )

       if Netuse( ( mldbf ), EXCLUSIVE, 10, 'inltemp', NEW )

        if Netuse( ( mhdbf ), EXCLUSIVE, 10, 'inhtemp', NEW )

         select invhead
         set relation to invhead->number into invline

         while !invhead->( eof() ) .and. Pinwheel( TRUE )

          if year( invhead->date ) = mdate 
           Center( 7, 'Processing Invoice #' + Ns( invhead->number ) + '   Invoice Date ' + dtoc( invhead->date ) )
           while invline->number = invhead->number .and. !invline->( eof() ) .and. Pinwheel( TRUE )
            f_arr := {}                                   // An array to save field values in
            for x := 1 to invline->( fcount() )
             aadd( f_arr, invline->( fieldget( x ) ) )    // Save field vals in array
            next
            Add_rec( 'inltemp' )
            for x := 1 to len( f_arr )
             inltemp->( fieldput( x , f_arr[ x ] ) )      // Append field data
            next
            invline->( dbdelete() )
            invline->( dbskip() )
           enddo
 
           f_arr := {}                                    // An array to save field values in
           for x := 1 to invhead->( fcount() )
            aadd( f_arr, invhead->( fieldget( x ) ) )     // Save field vals in array
           next
           Add_rec( 'inhtemp' )
           for x := 1 to len( f_arr )
            inhtemp->( fieldput( x , f_arr[ x ] ) )       // Append field data
           next
           invhead->( dbdelete() )
 
          endif
          invhead->( dbskip() )

         enddo

         inltemp->( dbclosearea() )
        endif 

        inhtemp->( dbclosearea() )

        Heading("Backup Invoice Archive")

        if Isready(12)
         @ 12,0 clear to 24,79
         if Shell( "pkzip -aes "+ right( Ns( mdate ), 2 ) + 'invarc ' +mldbf+'.dbf ' + mhdbf+'.dbf' )
          Box_Save( 2, 10, 4, 72 )
          Center( 3, 'Loading Backup to Floppy Program ...Please Wait' )

          @ 12,0 clear to 24,79
#ifndef __HARBOUR__
          if Shell( "backup " + chr( getdriv() ) + ':' + right( Ns( mdate ), 2 ) + "invarc.zip a:/f" )
           SysAudit( "InvArcBak" )
          endif
#endif
         endif
        endif
     
       endif
      endif
     endif

     invline->( dbclosearea() )
     Netuse( 'invline' )
     set relation to invline->id into master

     invhead->( dbclosearea() )
     Netuse( 'invhead' )
     set relation to invhead->number into invline,;
                  to invhead->key into customer

     SysAudit( "InvArc" + Ns( mdate ) )

    endif    
   case mchoice = 3
    Error( 'Function not Implemented yet' )
   endcase
  endif

 endcase
enddo
dbcloseall()
return

*

procedure trtype ( minv, mtrmac )
local sFunKey3 := setkey( K_F3, nil )

if minv

 if Secure( X_CREDITNOTES )
  Heading('Credit Note')
  mtrmac:='Credit Note'
  minv := FALSE
 endif

else

 Heading('Invoice')
 mtrmac:='Invoice'
 minv := TRUE

endif
setkey( K_F3, sFunKey3 )
return

*

function stret   // If a site uses GST then the B_ST1 value is used for sales tax calculations
local mst := master->sales_tax, mret := 0
#ifdef SALESTAX   // If you need to compile BPOS for a country that uses Sales Tax define this somewhere
if mst >= 0 .and. mst < 4
 do case
 case mst = 1
  mret := Bvars( B_ST1 )
 case mst = 2
  mret := Bvars( B_ST2 )
 case mst = 3
  mret := Bvars( B_ST3 )
endcase   
endif
#else
mret := if( !master->taxExempt, BVars( B_GSTRATE ), 0 )
#endif
return mret

*

procedure cred_check ( mnett )
if mnett+customer->amtcur+customer->amt30+customer->amt60+customer->amt90  > customer->c_limit
  syscolor( C_BRIGHT )
  @ 04,01 say '-=< Credit Limit Exceeded >=-'
  syscolor( C_NORMAL )
 endif
return

*

function invenq
local mtot:=0,minv:=invhead->inv,mloop := TRUE,mkey
local mtotdisc:=invhead->tot_disc,mscr:=Box_Save( 0,0,24,79 )
local minvno := invhead->number, indisp
Heading( 'Inquiry on '+if(minv,'Invoice','Credit')+' No ' + Ns(mInvno,6) )
Custdisp()
select invline
dbseek( minvno )
sum invline->price * invline->qty to mtot while invline->number = minvno
dbseek( minvno )
Highlight(7,34,if( minv,'Inv','Cdt' )+' Total ',Ns( mtot+invhead->freight,8,2 )+' Inc Freight '+Ns(invhead->freight,8,2) )
if mtotdisc > 0
 Highlight(8,67,'Dis ',Ns(mtot-(mtot/100*mtotdisc),8,2))
endif
if invhead->proforma
 Highlight( 8, 1, '', 'Pro-Forma Invoice' )
endif
Highlight( 8, 25, 'Inv Date', dtoc( invhead->date ) )
indisp:=tbrowsedb(09, 0, 24, 79)
indisp:HeadSep:=HEADSEP
indisp:ColSep:=COLSEP
indisp:goTopBlock:={ || dbseek( minvno ) }
indisp:goBottomBlock:={ || jumptobott( minvno ) }
indisp:skipBlock:=Keyskipblock( { || invline->number }, minvno ) 
indisp:addcolumn(tbcolumnnew('Desc', { || substr( master->desc,1,25) } ) )
indisp:addcolumn(tbcolumnnew('Ord', { || transform( invline->ord,'999') } ) )
indisp:addcolumn(tbcolumnnew('Qty', { || transform( invline->qty,'999') } ) )
indisp:addcolumn(tbcolumnnew('Sell',{ || transform( invline->sell,PRICE_PICT) } ) )
indisp:addcolumn(tbcolumnnew('Extend',{ || transform(invline->price*invline->qty, TOTAL_PICT )} ) )
indisp:addcolumn(tbcolumnnew('Disc', { || transform( 100-((invline->price*invline->qty)/;
       ((invline->sell*invline->qty)/100)),'99.9') } ) )
indisp:addcolumn(tbcolumnnew('Order No',{ || invline->req_no } ) )
indisp:addcolumn(tbcolumnnew('id',{ || idcheck( invline->id ) } ) )
indisp:addcolumn(tbcolumnnew('Comments', { || invline->comments } ) )
indisp:freeze := 1
indisp:goTop()
mkey := 0
while mkey != K_ESC .and. mkey != K_END
 indisp:forcestable()
 mkey := inkey(0)
 if !Navigate( indisp, mkey )
  do case
  case mkey == K_F10
   itemdisp( FALSE )
  endcase
 endif
enddo
Box_Restore( mscr )
select invhead
return nil

*

procedure InvTotDisc ( mnett, mdisc, mkey, mtrmac )
local getlist:={}, mdisctot:=0, mscr
if mkey == K_F8
 mscr := Box_Save( 5, 34, 7, 60)
 @ 6,35 say 'Enter Discount % ' get mdisc pict '99.9'
 read
 Box_Restore( mscr )
endif
#ifdef NO_NETT_DISCOUNTS
 invtemp->( dbgotop() )
 while !invtemp->( eof() )
  if !master->nodisc
   mdisctot += invtemp->qty * ( invtemp->price/100 * mdisc )
  endif
  invtemp->( dbskip() )
 enddo 
 mnett -= round( mdisctot, 2 )
#else
 mnett -= round( ( mnett / 100 * mdisc ), 2 )
#endif
@ 7, 45 say 'Total ' + mtrmac + '    ' get mnett pict TOTAL_PICT
@ 7, 72 say '(-'+str( mdisc, 4, 1 )+'%)'
return

*

procedure total_freight()
local tot := 0, yearget := year(Bvars( B_DATE )), getlist := {}
local i, tot_array := {0,0,0,0,0,0,0,0,0,0,0,0}, savescr := Box_Save(5,20,8,58)
local months := {"January","Febuary","March","April","May","June","July",;
                  "August","September","October","November","December"}

set cursor on
@6,30 say "Enter year:" get yearget pict "9999"
read
if lastkey() != K_ESC
 select invhead 
 ordsetfocus(  )
 invhead->( dbgobottom() )
 while ((year( invhead->date ) >= yearget) .and. !(invhead->(bof()))) .or.;
       ( invhead->date == ctod("  /  /  ") .and. !(invhead->(bof())) )
  Pinwheel()  
  if (year(invhead->date)) == yearget
   tot_array[month(invhead->date)] += invhead->freight
   tot += invhead->freight
   @7,25 say "Counting: "+str(tot,11,2)
  endif
  invhead->( dbskip(-1) )          
 enddo
 @7,21 say "Total Freight For "+alltrim(str(yearget))+" is $"+alltrim(str(tot,11,2))
 if IsReady(10)
  Print_find("Report")

  set printer on
  set console off
  ? "Amount Of Freight For ("+alltrim(str(yearget))+")"
  ? replicate(chr(196),30)
  for i := 1 to 12 
   ? padr(months[i],10),transform(tot_array[i],"99999999999.99")
  next
  ? replicate(chr(196),30)
  ? padr("Total",10),transform(tot,"99999999999.99")
    
  endprint()
  set console on
  set printer off
 endif
 select invhead 
 ordsetfocus( BY_NUMBER )

endif   
set cursor off  
Box_Restore( savescr )

return
