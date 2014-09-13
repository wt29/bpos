/*

  Daily Sales Reports and Posting

      Last change:  TG    3 Apr 2011   10:18 am

*/

procedure s_daily

#include "bpos.ch"
#include "set.ch"

local choice, oldscr := Box_Save(), aArray

while TRUE
 Box_Restore( oldscr )
 Heading('Daily Sales Analysis')

 aArray := {}
 aadd( aArray, { 'Exit', 'Return to Sales Menu', nil, nil } )
 aadd( aArray, { 'Graphic', 'Graphic of Days Sales', { || Salegraph() }, X_SALESREPORTS } )
 aadd( aArray, { 'X Report', 'Drawer Status Reports', { || Xreport() }, X_SALESREPORTS } )
 aadd( aArray, { 'Current', 'Current Sales', { || Daily_Sales( TRUE ) }, X_SALESREPORTS } )
 aadd( aArray, { 'Sales Close', 'Close Sales for the day', { || Saleclose() }, X_SUPERVISOR } )
 aadd( aArray, { 'All Sales', 'Print all ' + ITEM_DESC + ' sold today', { || Daily_sales( FALSE ) }, X_SALESREPORTS } )
 aadd( aArray, { 'Cash Book', 'Print Daily Cash Book', { || Cashbook() }, X_SALESREPORTS } )
 aadd( aArray, { 'Post', "Post today's sales", { || SalePost() }, X_SUPERVISOR } )
 choice := MenuGen( aArray, 08, 35, 'Daily' )
 if choice < 2
  return
 else 
  if Secure( aArray[ choice, 4 ] )
   Eval( aArray[ choice, 3 ] )
  endif
 endif 

enddo

*

procedure xreport
local sTendType
local nGrandQty := 0
local nGrandTot := 0
local nQty := 0
local nTotal := 0
local aRptFields :={}
local oPrinter

if Netuse( "sales" )
 Print_find("docket","report")
 Heading('X Report')
 if Isready(12)
  SysAudit("XReport")
  indx( "sales->tend_type",'tend_type' )
  sales->( dbgotop() )
  nGrandQty := 0
  nGrandTot := 0
  nQty := 0
  nTotal := 0
  oPrinter:= Win32Prn():New( Lvars( L_PRINTER) )
  oPrinter:Landscape:= .F.
  oPrinter:FormType := FORM_A4
  oPrinter:Copies   := 1
  if !oPrinter:Create()
    Alert( "Cannot create Printer " + LVars( L_PRINTER ) )

  else
   oPrinter:StartDoc( 'X Report' )
   locate for empty( sales->id) .and. !empty( sales->tend_type ) .and. sales->tran_type != 'PAY'
   if !found()
    Error( "No Sales Found to report", 12 )

   else
    sTendType := sales->Tend_Type
    oPrinter:Newline()
    oPrinter:TextOut( "X Report    " + dtoc( Bvars( B_DATE ) ) + "   " + time() )
    oPrinter:NewLine()
    oPrinter:TextOut( replicate("=", 31 ) )
    oPrinter:Newline()
    oPrinter:TextOut( "Tender Type       Qty     Total" )
    oPrinter:NewLine()
    oPrinter:TextOut( replicate( '-', 31 ) )
    do while !sales->( eof() )
     if empty( sales->id ) .and. !empty( sales->tend_type ) .and. sales->tran_type != 'PAY'
      if sales->tend_type != sTendType
       oPrinter:Newline()
       oPrinter:Textout( Padr( Tend_desc( sTendType ), 15 ) + padl( Ns( nQty, 5 ),6) + Padl( Ns( nTotal, 9, 2 ), 10 ) )
       nGrandQty += nQty
       nGrandTot += nTotal
       nQty := 0
       nTotal := 0
       sTendType := sales->Tend_Type

      endif
      nQty += sales->qty
      nTotal += sales->qty * sales->unit_price

     endif
     sales->( dbskip() )

    enddo
    oPrinter:Newline()
    oPrinter:Textout( Padr( Tend_desc( sTendType ), 15 ) + padl( Ns( nQty, 5 ),6) + Padl( Ns( nTotal, 9, 2 ), 10 ) )
    nGrandQty += nQty
    nGrandTot += nTotal
    oPrinter:Newline()
    oPrinter:TextOut( Replicate( "=", 31 ))
    oPrinter:Newline()
    oPrinter:Textout( 'Totals         ' + padl( Ns( nGrandQty, 5 ),6) + Padl( Ns( nGrandTot, 9, 2 ), 10 ) )
    oPrinter:Newline()
    oPrinter:Newline()

   endif
   sales->( dbgotop() )
   locate for sales->tran_type = 'PAY'
   if found()
    nQty := 0
    nTotal := 0
    oPrinter:Newline()
    oPrinter:TextOut( "Debtor Payments" + dtoc( Bvars( B_DATE ) ) + " " + time() )
    oPrinter:Newline()
    oPrinter:NewLine()
    oPrinter:TextOut( replicate("=", 31 ) )
    oPrinter:Newline()
    oPrinter:TextOut( "Tender Type       Qty     Total" )
    oPrinter:NewLine()
    oPrinter:TextOut( replicate( '-', 31 ) )
    do while !sales->( eof() )
     if empty( sales->id ) .and. sales->tran_type = 'PAY'
      nQty += sales->qty
      nTotal += sales->qty * sales->unit_price

     endif
     sales->( dbskip() )

    enddo
    oPrinter:Newline()
    oPrinter:TextOut( "Total Debtor Payments" )
    oPrinter:Newline()
    oPrinter:Textout( "Qty " + Ns( nQty, 5 ) + "  Total:$" + ns( nTotal, 9, 2 ) )

   endif

   oPrinter:endDoc()
   oPrinter:Destroy()

   if Lvars( L_CUTTER )      // Cheap and nasty paper cut until I figure out oPOS
    set print on
    set console off
    ? replicate( CRLF, 2 )
    ? PAPERCUT
    ? replicate( CRLF, 2 )
    ?? chr(26)
    set print off
    set console on
    set printer to

   endif


  endif
  ordDestroy( "tend_type" )

 endif
 sales->( dbclosearea() )

endif
return

*

procedure salegraph    // Nifty proc to produce on screen block graph of sales
local max_val:=0,max_time:=0,start_time:=24,xtics,ytics,m1,x_scale,y_scale,y
local x_pos,blok,plot,x,gval,bit:=' ',totval:=0,totqty:=0,mval,getlist:={},inc
if Netuse( "sales" )
 if sales->( reccount() ) = 0
  sales->( dbclosearea() )
  Error( "No Sales to process", 12 )
  return
 endif
 Box_Save( 2, 10, 4, 70 )
 Center( 3, 'Processing - Please Wait' )
 copy to ( Oddvars( TEMPFILE ) )              // We need a temporary file
 sales->( dbclosearea() )
 if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, 'graphic' )   // Exclusive use only one person at a time!
  replace all time with substr(graphic->time,1,2),;
              unit_price with graphic->unit_price*graphic->qty,;
              qty with 1
  indx( "graphic->time", 'time' )     // reduce the time and unit price fields

// No Invoices needed therefore no empty(tend_type) records and no Sales Records
// total em up on hour records to "Stime"

  total on graphic->time to stime fields unit_price,qty ;
        for !empty(graphic->tend_type) .and. empty(graphic->id) ;
        .and. graphic->tran_type != 'PAY' .and. graphic->tran_type != 'B/B'

  graphic->( dbclosearea() )

  Kill( Oddvars( TEMPFILE ) + OrdBagExt() )

  if Netuse("stime",EXCLUSIVE,10,'graphic')
   max_val:=0              // Maximum hourly sales value
   start_time:=24    // 12 am is our earliest time
   max_time:=0             //
   while !eof()         // Loop to figure out start and End trading times
    max_val:=max(max_val,graphic->unit_price)
    if !empty( graphic->time )
     start_time:=min(start_time,val(graphic->time))
     max_time:=max(max_time,val(graphic->time))
    endif
    skip
   enddo
   m1:=len(ltrim(str(max_val,10)))       // tricky bit to get '000's scale
   y_scale:=round(zero(max_val,(10^(m1-1))),0)+1  // How big is the y axis
   x_scale:=max_time-start_time                   // Number of hours traded
   cls
   Heading("Daily Sales Graph")
   for y:=1 to 22                                // Draw y axis
    @ y,10 say COLSEP
   next
   ytics:=round(zero(20,y_scale),0)      // Spacing of tics on y axis
   inc:=0
   for y:=24-2 to 1 step -ytics             // And Plot them
    @ y,10 say 'Ã'
    @ y,00 say inc * 10^(m1-1) pict '999999'
    inc++
   next
   for x:=10 to 79                             // X axis
    @ 22,X say 'Ä'
   next
   xtics:=max(round(zero(79*.75,x_scale+1),0),4)     // X Tics
   if xtics=0
    xtics := 69
   endif
   for x:=10 to 79 step xtics                  // Plot them
    @ 24-2,X say 'Á'
   next
   go top
   x_pos:=10
   while !eof()                                      // Step thru time dbf
    if !empty( graphic->time )
     gval:=zero(graphic->unit_price,(10^(m1-1)))     // How big is the bar graph?
     plot:=24-2-(gval*(ytics))
     blok:=replicate('±',xtics-1)                    // Width of bar variable
     for y:=21 to plot step -1
      @ y,x_pos+1 say blok                           // Draw Bar
     next
     Syscolor( C_BRIGHT )
     @ plot,x_pos+1 say Ns( graphic->unit_price, 5 ) // Total for bar
     Syscolor( C_INVERSE )
     @ plot-1,x_pos+1 say Ns( graphic->qty, 5 )
     Syscolor( C_NORMAL )
     @ plot-2,x_pos+1 say if(xtics-1<5,Ns((graphic->unit_price/graphic->qty)*10,4),;
                      Ns(graphic->unit_price/graphic->qty,7,2))
     mval:= val( graphic->time )
     @ 24-1,x_pos+1 say ;
     if(mval<12,if(mval=0,'12',Ns(mval))+'a',if(mval=12,'12',Ns(mval-12,2))+'p' )
     x_pos += xtics
    endif
    totval += graphic->unit_price
    totqty += graphic->qty
    skip
   enddo
   Highlight(24,1,'Average for Day $',Ns( totval/totqty , 10,2 ))
   Syscolor( C_BRIGHT )
   @ 24,25 say '$ ' + NS( totval )
   Syscolor( C_INVERSE )
   @ 24,35 say 'Number of Sales=' + Ns( totqty )
   Syscolor( C_NORMAL )
   @ 24,57 say 'Average for Hour'+if( xtics-1 < 5, '(x10)', '' )
   @ 24,79 get bit
   use
   read
   Kill("stime.dbf")
  endif
 endif
endif
return

*

procedure saleclose

local close_val, mgo := FALSE, mclose, x
local oPrinter

if Netuse( 'sales', EXCLUSIVE )
 if Netuse( 'psales', EXCLUSIVE )
  mgo := TRUE
 endif
endif

if mgo
 if psales->( reccount() ) != 0
  Box_Save( 2, 10, 5, 70 )
  Center( 3, 'Previous Days Sales have not been Posted!!!' )
  Syscolor( C_INVERSE )
  Center( 4, "Unable to Close Sales at this Time!!" )
  Syscolor( C_NORMAL )
  SysAudit( "SalClosFail" )
  Error( "", 12 )

 else
  Box_Save( 3, 08, 6, 72 )
  Center( 04, 'Ready to Close Sales for the day' )
  if Isready( 12 )
   sales->( dbgotop() )
   while !sales->( eof() )
    Add_rec( 'psales' )
    for x := 1 to psales->( fcount() )
     psales->( fieldput( x, sales->( fieldget( x ) ) ) )

    next
    sales->( dbskip() )

   enddo

   select sales
   zap

   select psales
   sum psales->unit_price * psales->qty to close_val;
       for empty( psales->id ) .and. !empty( psales->tend_type )

   mclose := Sysinc( "Sale_Close", 'I', 1 )
   SysAudit( "SalesClose" + Ns( mclose )+" $"+ ns( close_val )  )

   Print_find( "Docket" )
   oPrinter:= Win32Prn():New(Lvars( L_PRINTER) )
   oPrinter:Landscape:= .F.
   oPrinter:FormType := FORM_A4
   oPrinter:Copies   := 1
   if !oPrinter:Create()
       Alert( "Cannot create Printer " + LVars( L_PRINTER ) )

   else
    oPrinter:StartDoc( 'Sales Close' )
    oPrinter:Newline()
    oPrinter:TextOut( 'Sales Close Number ' + Ns( mclose ) )
    oPrinter:Newline()
    oPrinter:Textout( '          Z Totals ' + Ns( close_val, 8, 2 ) )
    oPrinter:endDoc()
    oPrinter:Destroy()

    if Lvars( L_CUTTER )      // Cheap and nasty paper cut until I figure out oPOS
     set print on
     set console off
     ? replicate( CRLF, 2 )
     ? PAPERCUT
     ?? chr(26)
     set print off
     set console on
     set printer to

    endif

   endif
   Error( 'Sales Closed! Number = ' + Ns( mclose) + '  Value $' + Ns( close_val ), 12, ,;
          'Ready for trading again' )

  endif

 endif

endif
dbcloseall()
return

*

procedure daily_sales ( lCurrent )
local gst:=TRUE,mtype:='D',msum := YES,getlist:={}
local mtot:=FALSE
local aRptFields:={}
local cSalesFile

Print_find("report")

Heading( if( lCurrent, 'Current', 'Daily') + ' Sales Report')
Box_Save( 2, 18, 8, 62 )
@ 03,22 say 'Department or Supplier Order (D/S)' get mtype pict '!' valid( mtype $ 'DS' )
@ 05,42 say 'Summary Format' get msum pict 'y'
@ 07,42 say ' Total on Item' get mtot pict 'y'
read
if Isready( 7 )
 if Netuse( "dept" )
  if Netuse( "supplier" )
   if Master_use()
    set relation to master->supp_code into supplier,;
                    master->department into dept
    if lCurrent
      cSalesFile = "sales"

    else
      cSalesFile = "psales"

	endif	  
    if Netuse( cSalesFile, , ,"SalesFile" )
     set relation to SalesFile->id into master
     Center(07,'-=< Now Processing - Please Wait >=-')
     SysAudit( "DSalesRpt" )

     if mtype = 'S'
      indx( "master->supp_code", 'temp' )

     else
      if mtot
       indx( "SalesFile->id", 'id' )
       total on salesfile->id to ( Oddvars( TEMPFILE ) ) field qty for !empty( SalesFile->id )
       Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, 'SalesFile', FALSE )

      endif
      indx( "master->department", 'dept' )

     endif

     aadd(aRptFields,{'idcheck(SalesFile->id)','ID',13,0,FALSE})    // 13
     aadd(aRptFields,{'substr(master->desc,1,25)','Desc',25,0,FALSE}) //25
     aadd(aRptFields,{'SalesFile->qty','Qty;Sold',4,0,TRUE})
     aadd(aRptFields,{'SalesFile->unit_price','Unit;Price',7,2,FALSE})
     aadd(aRptFields,{'SalesFile->discount*SalesFile->qty','Disc.',7,2,TRUE})
     if mtype != 'S'
      aadd(aRptFields,{'SalesFile->discount*SalesFile->qty/((SalesFile->unit_price*SalesFile->qty)/100)','Disc%',3,1,FALSE})//3,1

     endif
     aadd(aRptFields,{'SalesFile->qty*(SalesFile->unit_price-SalesFile->discount)','Nett;Sale',9,2,TRUE})
     aadd(aRptFields,{'SalesFile->qty*SalesFile->cost_price','Cost;Price',10,2,TRUE})
     if mtype != 'S'
      aadd(aRptFields,{'SalesFile->time','Time',8,0,FALSE})
      aadd(aRptFields,{'master->onhand','Onhand',6,0,FALSE})      // 6

     endif
     if mtype = 'S'
      if msum
       Reporter( aRptFields,;
                 "Daily Sales Report by Supplier (Summary)",;
                 "master->supp_code",;
                 "'Supplier : '+supplier->name",;
                 '',;
                 '',;
                 TRUE,;
                 '!empty( SalesFile->id )')

      else
        Reporter(aRptFields,;
                 "Daily Sales Report by Supplier (Full)",;
                 'master->supp_code',;
                 "'Supplier : '+supplier->name",;
                 '',;
                 '',;
                 FALSE,;
                 '!empty( SalesFile->id )')

      endif

     else
      if msum
        Reporter(aRptFields,;
                 "Daily Sales Report by Department (Summary)",;
                 'master->department',;
                 "'Department : '+dept->name",;
                 '',;
                 '',;
                 TRUE,;
                 '!empty( SalesFile->id )')


      else
       Reporter(aRptFields,;
                "Daily Sales Report by Department (Full)",;
                'master->department',;
                "'Department : '+dept->name",;
                '',;
                '',;
                FALSE,;
                '!empty( SalesFile->id )')


      endif

     endif

     if mtype ="S"
      SalesFile->( ordDestroy( "temp" ) )

     endif

    endif

   endif

  endif

 endif
 dbcloseall()
 Kill( Oddvars( SYSPATH ) + 'SalesFile' + ordBagExt() )
endif
return

*

procedure cashbook
local mbank:=NO, msum:=NO, getlist:={}
/* Local mcash, minvs, mpays */
local aCashBook, aInvDaily, aRptFields
local grp := 'TranTypeDesc(SalesFile->tran_type)'
local grpn := "'Totals for transaction type -> '+TranTypeDesc(psales->tran_type)"

Print_find("report")
Heading('Cash Book Report')
Box_Save( 2, 03, 09, 75 )
Center(3,'This Module will print the daily cash book and Invoice List')

@ 5,10 say 'Print Banking List' get mbank pict 'Y'
@ 5,50 say 'Summary Reports' get msum pict 'Y'
read

if Isready(06)
 if Netuse( "psales", SHARED, 10, , TRUE )
  SysAudit( "CashBookRpt" )
  Center(07,'-=< Processing - Please Wait >=-')
  
  aCashBook := {}
  aadd(aCashBook,{'sale_date','Date',8,0,FALSE})
  aadd(aCashBook,{'tran_num','Trans;No',8,0,FALSE})
  aadd(aCashBook,{'tend_type','Tender;Type',4,0,FALSE})
  aadd(aCashBook,{'unit_price*qty','Nett Sale',10,2,TRUE})
  aadd(aCashBook,{'discount*qty','Discount;%',10,2,TRUE})
  aadd(aCashBook,{'cost_price*qty','Nett;Cost',10,2,TRUE})
  aadd(aCashBook,{'time','Time',8,0,FALSE})
  aadd(aCashBook,{'Register','Register',10,0,FALSE})
  aadd(aCashBook,{'name','Customer Name',20,0,FALSE})
  aadd(aCashBook,{'sales_tax','Sales;Tax',8,2,TRUE})

  aInvDaily := {}
  aadd(aInvDaily,{'sale_date','Date',8,0,FALSE})
  aadd(aInvDaily,{'tran_num','Trans;No',8,0,FALSE})
  aadd(aInvDaily,{'tend_type','Tender;Type',4,0,FALSE})
  aadd(aInvDaily,{'discount*qty','Discount',10,2,TRUE})
  aadd(aInvDaily,{'(unit_price-discount)*qty','Nett Sale',10,2,TRUE})
  aadd(aInvDaily,{'cost_price*qty','Nett;Cost',10,2,TRUE})
  aadd(aInvDaily,{'time','Time',8,0,FALSE})
  aadd(aInvDaily,{'register','Register',10,0,FALSE})
  aadd(aInvDaily,{'name','Customer Name',20,0,FALSE})
  aadd(aInvDaily,{'invno','Inv #',6,0,FALSE})
  indx( "psales->tran_type + psales->tend_type", Oddvars( TEMPFILE ) )

  if msum
   Reporter( aCashBook,;
            "Daily Cash Book (Summary)",;
            grp,grpn,;
            'Tend_desc(tend_type)',;
            "'Tender type -> '+Tend_desc(tend_type)",;
            TRUE,;
            'empty( psales->id ) .and. !empty( psales->tend_type )' )

   go top

   Reporter( aInvDaily,;
            "Daily Invoice/Credit Note List (Summary)",;
            'TranTypeDesc(psales->tran_type)',;
            "'Totals for transaction type -> '+TranTypeDesc(psales->tran_type)",;
            '',;
            '',;
            TRUE,;
            'empty( psales->id ) .and. empty( psales->tend_type )' )
  else
   Reporter( aCashBook,;
            "Daily Cash Book",;
            grp,;
            grpn,;
            'Tend_desc(tend_type)',;
            "'Tender type -> '+Tend_desc(tend_type)",;
            FALSE,;
            'empty( psales->id ) .and. !empty( psales->tend_type )' )

   go top
   Reporter( aInvDaily,;
            "'Daily Invoice/Credit Note List'",;
            'TranTypeDesc(psales->tran_type)',;
            "'Totals for transaction type -> '+TranTypeDesc(psales->tran_type)",;
            '',;
            '',;
            FALSE,;
            'empty( psales->id ) .and. empty( psales->tend_type )' )

  endif
/*
  count to mpays for empty( psales->id ) .and. psales->tran_type = 'PAY'
  count to minvs for empty( psales->id ) .and. empty( psales->tend_type );
          .and. ( psales->tran_type = 'INV' .or. psales->tran_type = 'C/N')
  count to mcash for empty( psales->id ) .and. !empty( psales->tend_type )

  set console off
  set printer on
  ? 'Total Invoice Payments Processed ' + Ns( mpays )
  ? 'Total Invoices/C-Notes processed ' + Ns( minvs )
  ? '       Total Cash Sale Customers ' + Ns( mcash )
  ? '         Total Sale Transactions ' + Ns( mcash+minvs )
  set printer off
  set console on
  // Pitch10()
*/
  if mbank
   aRptFields := {}
   aadd(aRptFields,{'sale_date','Date',8,0,FALSE})
   aadd(aRptFields,{'tend_type','Tend',4,0,FALSE})
   aadd(aRptFields,{'unit_price*qty','Value',10,2,TRUE})
   aadd(aRptFields,{'space(1)',' ',1,0,FALSE})
   aadd(aRptFields,{'bank','Bank',7,0,FALSE})
   aadd(aRptFields,{'branch','Branch',20,0,FALSE})
   aadd(aRptFields,{'drawer','Drawer',20,0,FALSE})
      
   indx( "psales->bank + psales->drawer", Oddvars( TEMPFILE ) )
   go top
   Reporter(aRptFields,;
            "'Daily Banking List'",;
            '',;
            '',;
            '',;
            '',;
            FALSE,;
            'empty( psales->id ) .and. psales->tend_type = "CHQ"',;
            CONDENSE )

  endif

 endif
 close databases

endif
return
*
*

procedure salepost
local mgo:=NO,mper:=NO,mmthclr:=NO,kit_proc:=FALSE,mcode,ncode,mmonth
local first_day,weeknum,up,cp,uq,fo,mtax,kit_id,mqty
local f1,f2,f3,f4,f5
// local mtran, mval, fieldord

Center( 24, 'Opening files for Daily Posting' )
if Netuse( "deptmove" )
 if Netuse( "salehist" )
  if Netuse( "dept" )
   if Netuse( "turnover" )
    if Netuse( "deptweek" )
     if Netuse( "purhist" )
      if Netuse( "suppweek" )
       if Netuse( "draft_po" )
        draft_po->( ordsetfocus( "id") )
        if Netuse( "ytdsales" )
         if Netuse( "master" )
          if Netuse( "psales", EXCLUSIVE )
           set relation to psales->id into master,;
                        to psales->id into ytdsales,;
                        to psales->id into draft_po
           mgo:=TRUE
           line_clear(24)
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
if mgo
 if psales->( lastrec() ) = 0 
  Error( 'No Sales Records to Post!', 12)

 else
  Box_Save( 2, 9, 20, 72, 4 )
  Center( 03, 'Please ensure that you have printed the daily reports.')
  Center( 05, 'About to post the daily sales figures.')
  Center( 07, 'The Sales Period was last closed on '+dtoc( Bvars( B_LASTPER ) )+'.')
  Center( 09, 'Period rollover is set for '+Ns( Bvars( B_PERLEN ) )+ ;
              ' days. It has been ' + Ns( Bvars( B_DATE ) - Bvars( B_LASTPER ) ) + ' days')

  if Bvars( B_DATE ) - Bvars( B_LASTPER ) >= Bvars( B_PERLEN )
   Center( 11, 'Automatic Period Rollover will occur' )
   mper := YES

  endif

  if month( Bvars( B_DATE ) + 7 ) != month( Bvars( B_DATE ) ) .and. ;
     month( Bvars( B_DATE ) ) != Bvars( B_MTHCLEAR )
   Center(12,'End of Month Rollover will occur')
   mmthclr := YES

  endif

  if Isready(13)
   SysAudit("SalesPost")
   Center(13,'-=< Posting In Progress - Do Not Interrupt >=-')
   psales->( dbgotop() )
   @ 15,12 say 'Total Records to Process ' + Ns(reccount())
   @ 15,50 say 'Record #'

   while !psales->( eof() )

    mmonth := upper( substr( cmonth( psales->sale_date ), 1, 3 ) )  // Use Date of Sale NOT Date of Post
    @ 15,60 say psales->( recno() )
    @ 16,11 say space( 55 )
    if empty( psales->id )

     select turnover
     @ 16,11 say 'T'
     if !turnover->( dbseek( psales->tran_type + Ns( day( psales->sale_date ) ) ) )
      Add_rec( 'turnover' )
      turnover->tran_type := psales->tran_type
      turnover->day := Ns( day( psales->sale_date ) )
     endif

     Rec_lock( 'turnover' )

     up := psales->unit_price
     cp := psales->cost_price
     uq := psales->qty

     f1 := fieldpos( mmonth + 'tot' )  // Field Ordinal for total sales
     f2 := fieldpos( mmonth + 'cost' ) // for month costs
     f3 := fieldpos( mmonth + 'qty' )  // for cust qty
     f4 := fieldpos( mmonth + 'dis' )  // for discounts
     f5 := fieldpos( mmonth + 'tax' )  // for tax

     if( f1!=0, fieldput( f1, fieldget( f1 ) + ( up * uq ) ), nil )
     if( f2!=0, fieldput( f2, fieldget( f2 ) + ( cp * uq ) ), nil )
     if( f3!=0, fieldput( f3, fieldget( f3 ) + uq ), nil )
     if( f4!=0, fieldput( f4, fieldget( f4 ) + psales->discount ), nil )
     mtax := up-(( up )*(1/(1+( Bvars( B_GSTRATE )/100))))
     if( f5!=0, fieldput( f5 , fieldget( f5 ) + ( if( TRUE , mtax , psales->sales_tax )* uq ) ), nil )
     turnover->( dbrunlock() )

    else

     kit_proc := ( master->binding = 'KI' )
     if kit_proc                // Test for kit Sold?
      Netuse( "kit" )
      kit_id := master->id    // Position kit file on first record in kit
      seek kit_id
     endif

     while TRUE
      if !master->( dbseek( if( kit_proc, kit->id, psales->id ) ) )  // Position Master File on first id in kit
       SysAudit( "SeekErrSalPost" + psales->id, 12 )
      else

       mcode:=trim( master->supp_code ) + '_SAL'
       purhist->( dbseek( mcode ) )
       @ 16,14 say 'Purhist'
       if !purhist->( found() )
        Add_rec('purhist')
        purhist->code := mcode
       endif
       Rec_lock( 'purhist' )
       fo := purhist->( fieldpos( mmonth ) )
       if fo != 0
        purhist->( fieldput( fo , purhist->( fieldget( fo ) ) - ;
                 ( psales->cost_price * ( psales->qty * if( kit_proc, kit->qty, 1 ) ) ) ) )
       endif
       purhist->( dbrunlock() )

 // Routine to calculate ISO Week Number.
       first_day := ctod("01/01/"+substr(ltrim(str(year( psales->sale_date ))),3,2))
       weeknum:=int((psales->sale_date-first_day)/7)+if( dow( first_day ) < 5,1,0)
       mcode := 'S'+Ns(weeknum)
       ncode := 'C'+Ns(weeknum)
       @ 16,32 say 'Suppweek'
       if !suppweek->( dbseek( Ns( year( psales->sale_date ) ) + master->supp_code ) )
        Add_rec( 'suppweek' )
        suppweek->code := master->supp_code
        suppweek->year := Ns( year( psales->sale_date ) )
       endif
       Rec_lock( 'suppweek' )
       fo := suppweek->( fieldpos( mcode ) )
       f1 := suppweek->( fieldpos( ncode ) )
       if fo != 0 .and. f1 != 0
        suppweek->( fieldput( fo, suppweek->( fieldget( fo ) ) + ;
                ( psales->unit_price - psales->discount ) * ( psales->qty * if( kit_proc, kit->qty, 1 ) ) ) )
        suppweek->( fieldput( f1, suppweek->( fieldget( f1 ) ) + ;
                  psales->cost_price * ( psales->qty * if( kit_proc, kit->qty, 1 ) ) ) )
       endif
       suppweek->( dbrunlock() )

       select deptweek                 // Update Sales by Department by Week
       mcode := 'S' + Ns( weeknum )
       ncode := 'C' + Ns( weeknum )
       @ 16,32 say 'Deptweek'
       if !deptweek->( dbseek( Ns( year( psales->sale_date ) ) + master->department ) )
        Add_rec( 'deptweek' )
        deptweek->code := master->department
        deptweek->year := Ns( year( psales->sale_date ) )
       endif
       Rec_lock( 'deptweek' )
       fo := fieldpos( mcode )
       f1 := fieldpos( ncode )
       if fo != 0 .and. f1 != 0
        fieldput( fo, fieldget( fo ) + ;
                ( psales->unit_price-psales->discount ) * ( psales->qty * if( kit_proc, kit->qty, 1 ) ) )

        fieldput( f1, fieldget( f1 ) + psales->cost_price * ( psales->qty * if( kit_proc, kit->qty, 1 ) ) )
       endif
       deptweek->( dbrunlock() )

       select deptmove                // Update Department Movement here
       mcode:=trim( master->department )
       seek mcode
       @ 16,22 say 'Deptmove'
       locate for deptmove->type = 'SAL' while deptmove->code = mcode .and. !eof()
       if !found()
        Add_rec()
        deptmove->code := mcode
        deptmove->type := 'SAL'
       endif
       Rec_lock()
       fo := fieldpos( mmonth )
       if fo != 0
        fieldput( fo , fieldget( fo ) - ;
                ( ( psales->unit_price - psales->discount ) * ( psales->qty * if( kit_proc, kit->qty, 1 ) ) ) )

       endif
       deptmove->( dbrunlock() )

       @ 16,42 say 'Dept'
       if !empty( master->department )
        if !dept->( dbseek( master->department ) )
         Add_rec( 'dept' )
         dept->code := master->department
        endif
        Rec_lock('dept')
        dept->week_sell += ( psales->unit_price * ( psales->qty * if( kit_proc, kit->qty, 1 ) ) )
        dept->week_disc += ( psales->discount * ( psales->qty * if( kit_proc, kit->qty, 1 ) ) )
        dept->week_cost += ( psales->cost_price * ( psales->qty * if( kit_proc, kit->qty, 1 ) ) )
        dept->( dbrunlock() )

       endif

       @ 16, 48 say 'Sahist'

       Add_rec( 'salehist' )
       salehist->id := if( kit_proc, kit->id, psales->id )
       salehist->date := psales->sale_date
       salehist->unit_price := psales->unit_price
       salehist->discount := psales->discount
       salehist->cost_price := psales->cost_price
       salehist->qty := psales->qty * if( kit_proc, kit->qty, 1 )  
       salehist->key := psales->key
       salehist->mktg_type := psales->mktg_type
       salehist->sale_type := psales->sale_type
       salehist->invno := psales->invno
       salehist->sales_tax := psales->sales_tax
       salehist->locflag := psales->locflag
       salehist->consign := psales->consign
       salehist->( dbrunlock() )

       fo := ytdsales->( fieldpos( mmonth ) )                               // Update Ytdsales File
       @ 16,56 say 'YtdS'
       if !ytdsales->( dbseek( if( kit_proc, kit->id, psales->id ) ) )  // No Record Exists for id?
        Add_rec( 'ytdsales' )
        ytdsales->id := if( kit_proc, kit->id, psales->id ) 
        ytdsales->per1 += psales->qty * if( kit_proc, kit->qty, 1 ) 

       else
        Rec_lock( 'ytdsales' )
        ytdsales->per1 := min( 9999, ytdsales->per1 + ( psales->qty * if( kit_proc, kit->qty, 1 ) ) )

       endif

       if fo != 0
        mqty := ytdsales->( fieldget( fo ) ) + ( psales->qty * if( kit_proc, kit->qty, 1 ) ) 
        ytdsales->( fieldput( fo , mqty ) )

       endif
       ytdsales->( dbrunlock() )

       // Reorder Quantity Processing Here
       // No Order Processing for 'MISC' supplier or Secondhand Records

       if master->supp_code != 'MISC' .and. master->supp_code != '%SH%'
        if master->onhand < ( master->minstock - master->onorder ) .or. psales->consign
         mqty := if( psales->consign, psales->qty, master->minstock - master->onhand - master->onorder )
         select draft_po
         dbseek( if( kit_proc, kit->id, psales->id ) )
         locate for draft_po->source = if( psales->consign, 'Co', 'Sa' ) while draft_po->id = master->id
         if found()            // Record Exist Already? Must not be Special Order
          Rec_lock()
          draft_po->qty := mqty
         else
          Add_rec()
          draft_po->id := master->id
          draft_po->supp_code := master->supp_code
          draft_po->qty := mqty
          draft_po->date_ord := Bvars( B_DATE )
          draft_po->special := NO
          draft_po->source := if( psales->consign, 'Co', 'Sa' )
          draft_po->skey := substr( master->alt_desc, 1, 5 ) + master->desc
          draft_po->department := master->department
          draft_po->hold := Bvars( B_DEPTORDR )
#ifdef DPO_BY_DESC
          draft_po->skey := master->desc
#endif
         endif
         draft_po->( dbrunlock() )
        endif
       endif
      endif
      if !kit_proc              // This is not a Kit Record Therefore exit loop
       exit
      else
       kit->( dbskip() )
       if kit->id != kit_id     // Test for valid - Still part of Kit ?
        kit->( dbclosearea() )   
        exit                    // Get out of loop
       endif
      endif

     enddo                      // While kit processing
    endif

    psales->( dbdelete() )
    psales->( dbskip() )

   enddo
   if mmthclr
    m->month := substr( cmonth( Bvars( B_DATE ) + 7 ) ,1 ,3 )
    Center( 17, '-=< Monthly file Clearance in progress >=-' )
    if Fil_lock( 20, 'ytdsales' )  // Wait a while for file - Exclusive use is much faster
     if Fil_lock( 20, 'purhist' )
      if Fil_lock( 20, 'deptmove' )
       if Fil_lock( 20, 'turnover' )
        select ytdsales
        replace &month with 0 all
        delete for ytdsales->jan+ytdsales->feb+ytdsales->mar+ytdsales->apr+;
                   ytdsales->may+ytdsales->jun+ytdsales->jul+ytdsales->aug+;
                   ytdsales->sep+ytdsales->oct+ytdsales->nov+ytdsales->dec+;
                   ytdsales->per1+ytdsales->per2+ytdsales->per3+ytdsales->per4+;
                   ytdsales->per5+ytdsales->per6+ytdsales->per7+ytdsales->per8+;
                   ytdsales->per9+ytdsales->per10+ytdsales->per11+ytdsales->per12 = 0
        select purhist
        replace &month with 0 all
        delete for purhist->jan+purhist->feb+purhist->mar+purhist->apr+;
                   purhist->may+purhist->jun+purhist->jul+purhist->aug+;
                   purhist->sep+purhist->oct+purhist->nov+purhist->dec = 0
        select deptmove
        replace &month with 0 all
        delete for deptmove->jan+deptmove->feb+deptmove->mar+deptmove->apr;
                  +deptmove->may+deptmove->jun+deptmove->jul+deptmove->aug;
                  +deptmove->sep+deptmove->oct+deptmove->nov+deptmove->dec = 0;
                  .and. '_' $ deptmove->code
/*
        select turnover
        replace &month.tot  with 0,;
                &month.cost with 0,;
                &month.dis  with 0,;
                &month.qty  with 0,;
                &month.tax  with 0 ;
                all
*/
        Bvars( B_MTHCLEAR, month( Bvars( B_DATE ) ) ) // Note that month rollover may not-
        SysAudit( "MthFileClear" )                       // Take place if repeated exclusive -
        Bvarsave()                                    // Use cannot take place - May need more

       endif
      endif                                           // more reviews in future
     endif
    endif
   endif
   if mper
    Center(19,'-=< Period Rollover in progress >=-')
    select ytdsales
    if Fil_lock(10)                                   // Try for a file lock - Much Faster !
     replace all per12 with ytdsales->per11,;
                 per11 with ytdsales->per10,;
                 per10 with ytdsales->per9,;
                 per9 with ytdsales->per8,;
                 per8 with ytdsales->per7,;
                 per7 with ytdsales->per6,;
                 per6 with ytdsales->per5,;
                 per5 with ytdsales->per4,;
                 per4 with ytdsales->per3,;
                 per3 with ytdsales->per2,;
                 per2 with ytdsales->per1,;
                 per1 with 0

    else                                              // No exclusive use - Must close on time
     ytdsales->( dbgotop() )                          // Do it record by record
     while !ytdsales->( eof() )
      Rec_lock( 'ytdsales' )
      ytdsales->per12 := ytdsales->per11
      ytdsales->per11 := ytdsales->per10
      ytdsales->per10 := ytdsales->per9
      ytdsales->per9 := ytdsales->per8
      ytdsales->per8 := ytdsales->per7
      ytdsales->per7 := ytdsales->per6
      ytdsales->per6 := ytdsales->per5
      ytdsales->per5 := ytdsales->per4
      ytdsales->per4 := ytdsales->per3
      ytdsales->per3 := ytdsales->per2
      ytdsales->per2 := ytdsales->per1
      ytdsales->per1 := 0
      ytdsales->( dbrunlock() )
      ytdsales->( dbskip() )

     enddo
     SysAudit("PerRoll")

    endif
    Bvars( B_LASTPER, Bvars( B_DATE ) )     // This is the date of last period rollover - save it
    Bvarsave()                              // Save all Bvars to Bvars.dbf

   endif
   select psales
   pack                                     // All records should be deleted - Pack & Clear file

  endif
  Syscolor( C_NORMAL )

 endif 

endif
dbcloseall()
return

*

Function TranTypeDesc ( mtype )
local mret := 'Unknown ('+mtype+')'
if mtype = 'C/S'
 mret := 'Cash Sales'
elseif mtype = 'LBD'
 mret := 'Layby Deposit'
elseif mtype = 'LBT'
 mret := 'Layby total ( less initial Deposit )'
elseif mtype = 'LBP'
 mret := 'Layby Payment'
elseif mtype = 'SDT'
 mret := 'S/Order Deposit Taken'
elseif mtype = 'SDR'
 mret := 'S/Order Deposit Refund'
elseif mtype = 'SDP'
 mret := 'S/Order Deposit Presented'
elseif mtype = 'LDE'
 mret := 'Layby Cancelled Refund'
elseif mtype = 'PPC'
 mret := 'Prepack Cash Sale'
elseif mtype = 'PAY'
 mret := 'Accounts Payments'
elseif mtype = 'VOI'
 mret := 'Cash Sale Voids'
elseif mtype = 'INV'
 mret := 'Invoices'
elseif mtype = 'C/N'
 mret := 'Credit Notes'
elseif mtype = 'DRR'
 mret := 'Debtor Receipt'
elseif mtype = 'MIR'
 mret := 'Miscellaneous Debtor Receipt'
elseif mtype = 'SUB'
 mret := 'Subscription Payment'
elseif mtype = 'MOS'
 mret := 'Mail Order Sales Payment'
elseif mtype ='B/B'
 mret := 'Second Hand Buy Back'
elseif mtype = 'ZZZ'
 mret := 'Sales Close Z-Read'
elseif mtype = 'ACC'
 mret := 'Account Payments'
elseif mtype = 'SHA'
 mret := 'Share Sales'
elseif mtype = 'PCH'
 mret := 'Petty Cash'
endif
return mret

*

function PrintusInteruptus
local mdev := set( _SET_DEVICE, 'PRINTER' ), mcons := set( _SET_CONSOLE, FALSE )
if lastkey() = K_ESC
 @ prow()+1, 0 say BIGCHARS + 'Escape was Hit - Report not completed.' + NOBIGCHARS
endif
set( _SET_DEVICE, mdev )
set( _SET_CONSOLE, mcons )
return nil

*

/*function SaleBank
local bdstr, fbank, getlist:={}, mval := {}, atemp, astru, mclose
local x, olddbf:=select(), mvtype, mscr, aArray, mstr, ftbank

Heading( "Daily Banking Summary" )

aArray := Setup_tt_types()

for x := 3 to len( aArray[ 1 ] )                       // Get the POS tend Types

 aadd( mval, { aArray[ 1, x ], aArray[ 2, x ], 0 } )

next

aadd( mval, { 'TotBank', 'Total Banked', 0 } )
aadd( mval, { 'Date', 'Date Banked', Bvars( B_DATE ) } )
aadd( mval, { 'TotCust', 'Total Customers', 0 } )
mscr := Box_Save( 2, 10 , 4 + len( mval ), 50 )

for x := 1 to len( mval )

 @ x+2,11 say padl( mval[ x, 2 ], 20 ) get mval[ x, 3 ] pict '999999.99'

next

read
 
Box_Restore( mscr )

if updated()

 mclose := Sysinc( "sale_close", 'I', 0 )  // A fudge here I just want the last sales close number

 mstr := right( padl( Ns( mclose ), 6, '0' ), 5  )   // Only really need 5 chars here - Who is going to do 1e5 sales closes!

 ftbank := Oddvars( SYSPATH ) + 'transfer\toho\' + mstr + 'bnk.' + padl( Bvars( B_BRANCH ), 3, 0 )

 astru := {}
 aadd( astru, { 'branch', 'c', BRANCH_CODE_LEN, 0 } ) 

 for x := 1 to len( mval )
  mvtype := valtype( mval[ x, 3 ] )
  aadd( astru, { mval[ x, 1 ], mvtype, if( mvtype = 'D', 8, 10 ), if( mvtype = 'D', 0, 2 ) } )

 next

 dbcreate( ftbank, astru ) 

 if Netuse( ftbank, EXCLUSIVE, , 'trbank'  )

  Add_rec( 'trbank' )
  for x := 1 to len( mval )  // Branch is the first field
   fieldput( x+1, mval[ x, 3 ] )
  next 
  trbank->branch := Bvars( B_BRANCH )
  
 endif

 trbank->( dbclosearea() )

endif
 
select( olddbf )
return nil
*/
