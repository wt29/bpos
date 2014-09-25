/*

 Collected Sales Records


      Last change:  TG   18 Oct 2010    9:44 pm
*/

#include "bpos.ch"

field jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec

Procedure S_report

local aArray, choice

if Secure( X_SALESREPORTS )
 while TRUE
  Print_find( "report" )
  Heading( 'Sales Reports' )
  aArray := {}
  aadd( aArray, { 'Exit', 'Return to Sales Menu' } )
  aadd( aArray, { 'No Sales', 'Print Items not sold', { || NoSalesRpt() }, nil } )
  aadd( aArray, { 'Monthly', 'Print Sorted Monthly Sales Figures', { || MthSalesRpt() }, nil } )
  aadd( aArray, { 'Year to Date', 'Print Year to Date sales', { || YearSalesRpt() }, nil } )
  aadd( aArray, { 'Period', 'Print Period Sales', { || PerSalesRpt() }, nil } )
  aadd( aArray, { 'Department', 'Print Sales by department by period', { || DeptSalesRpt() }, nil } )
  aadd( aArray, { 'Supplier', 'Print Sales by Supplier by Period', { || SuppSalesRpt() }, nil } )
  aadd( aArray, { 'Brand', 'Print Sales by Brand by Period', { || ImprSalesRpt() }, nil } )
  aadd( aArray, { 'Best Sellers', 'Print 20 Best Sellers in Each Department', { || ListBest() }, nil } )
  choice := MenuGen( aArray, 09, 35, 'Reports')
  if choice < 2
   return
  else
   if Secure( aArray[ choice, 4 ] )
    Eval( aArray[ choice, 3 ] )
   endif
  endif
 enddo
endif
return

*

Function ytdtot
return ytdsales->jan+ytdsales->feb+ytdsales->mar+ytdsales->apr+;
       ytdsales->may+ytdsales->jun+ytdsales->jul+ytdsales->aug+;
       ytdsales->sep+ytdsales->oct+ytdsales->nov+ytdsales->dec

*

Function FinYtd
//local mstr := 'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC'
local mmonth := month( Bvars( B_DATE ) ), ytdqty := 0, x
local startfield := ytdsales->( fieldpos( 'jan' ) )
if mmonth > 6
 for x = 7 to mmonth
  ytdqty += ytdsales->( fieldget( x+startfield-1 ) )
 next
else
 for x = 7 to 12
  ytdqty += ytdsales->( fieldget( x+startfield-1 ) )
 next
 for x = 1 to mmonth
  ytdqty += ytdsales->( fieldget( x+startfield-1 ) )
 next
endif
return ytdqty

*

procedure Monthly_Sales()
local db, grp_by := "S", filen, getlist:={}
local nmth := month(Bvars( B_DATE ) )
local mthstr := 'JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC'
local mth := substr(mthstr,(nmth-1)*4+1,3)
local dpart, aReport
local scrn := Box_Save( 10, 22, 15, 61 )
local months := {"January","February","March","April","May","June","July",;
                  "August","September","October","November","December"}

memvar yr, this_month

private this_month
private yr := year( Bvars( B_DATE ) )

@ 11, 24 say "Supplier or Department Order (S/D)" get grp_by valid grp_by = "S" .or. grp_by = "D" pict "@!"
read

@ 12, 27 say "Enter Month For Analysis:" get mth picture '@!AAA' valid ( mth $ mthstr )
@ 13, 27 say "                     Year" get yr pict '9999'
if grp_by = "D"
 filen := "dept"
 dpart := '*  '
 @ 14,31 say "Department (* = All):" get dpart picture '@K!' ;
         valid ( dpart = '*  ' .or. dup_chk( dpart, 'dept' ) )
else        
 filen := "supplier"
 dpart := '*   '       
 @ 14,33 say "Supplier (* = All):" get dpart picture '@K!' ;
         valid ( dpart = '*   ' .or. dup_chk( dpart, 'supplier' ) )
endif
read

nmth := if(mth=='JAN',1,(at(mth,mthstr)-1)/4+1) // Figure out the number of the month
this_month := months[nmth]              // Into the array to return the correct month

if IsReady(14)
 if Master_use()
  if Netuse( "salehist" )
   set relation to salehist->id into master
   db := {}
   aadd( db, { "id", "C", 12, 0 } )
   aadd( db, { "qty", "N", 8, 0 } )
   aadd( db, { "department", "C", 3, 0 } )
   aadd( db, { "supp_code", "C", 4, 0 } )
   aadd( db, { "cost_price", "N", 12, 2 } )
   aadd( db, { "nett_price", "N", 12, 2 } )
   dbcreate( Oddvars( TEMPFILE ), db )
   if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "saletmp" )
    salehist->( dbgobottom() )
    do while !Salehist->( bof() ) .and. Pinwheel()

     if month( salehist->date ) = nmth .and. year( salehist->date ) = yr

      if trim(dpart) = '*' .or. if(grp_by = "S", master->supp_code = dpart, master->department = dpart )
       Add_rec()
       saletmp->id := salehist->id
       saletmp->qty := salehist->qty
       saletmp->department := master->department
       saletmp->supp_code := master->Supp_code
       saletmp->cost_price := salehist->qty * salehist->cost_price
       saletmp->nett_price := salehist->qty *( salehist->unit_price - salehist->discount )

      endif

     endif

     salehist->( dbskip(-1) )

    enddo
    salehist->( dbClearRelation() )

    indx( "id", 'id' )
    total on saletmp->id fields qty,cost_price,nett_price to ( Oddvars( TEMPFILE2 ) )

    saletmp->( orddestroy( 'id' ) ) 
    saletmp->( dbclosearea() )

   endif
   salehist -> ( dbclosearea() )

  endif

  if Netuse( filen )

   if Netuse( "ytdsales" )

    if Netuse( Oddvars( TEMPFILE2 ), EXCLUSIVE, 10, "stmp" )

     if grp_by == "S"
      indx( "supp_code + descend( padl( str( qty ), 8, '0' ) )", 'sort_key' )
      set relation to stmp->id into master ,stmp->supp_code into supplier,stmp->id into ytdsales

     else
      indx( "department + descend( padl( str( qty ), 8, '0' ) )", 'sort_key' )
      set relation to stmp->id into master ,stmp->department into dept,stmp->id into ytdsales

     endif

     stmp->( dbgotop() )

     aReport := {}
     aadd( aReport,{ 'master->id', 'id', ID_CODE_LEN + 1, 0, FALSE})
     aadd( aReport,{ 'master->desc', 'Desc', 40, 0, FALSE})
     aadd( aReport,{ 'qty', 'Quantity;Sold', 8, 0, TRUE})
     aadd( aReport,{ 'cost_price', 'Cost Of Sales', 12, 2, TRUE})
     aadd( aReport,{ 'nett_price', 'Nett Sales',12, 2, TRUE})
     aadd( aReport,{ 'qty*master->retail', 'Recomended;Retail', 12, 2, TRUE})
     aadd( aReport,{ 'master->onhand', 'Onhand', 7, 0, FALSE})
     aadd( aReport,{ 'ytdtot()', 'Ytd;Sales', 6, 0, FALSE})
    
     if grp_by = "S"
      Reporter(aReport,;
               "Monthly Total Sales by Supplier for " + this_month + " (" + ns(yr) + ")",;
               'supp_code',;
               "'Supplier : ' + supp_code + ', ' + supplier->name",;
               '',;
               '',;
               FALSE,;
               ,;
               ,;
               132 )

     else  // Group by Department
      Reporter(aReport,;
               "Monthly Total Sales by Department for " + this_month + " (" + ns(yr) + ")",;
               'department',;
               "'Department : ' + department + ', ' + dept->name",;
               '',;
               '',;
               FALSE,;
               ,;
               ,;
               132)

     endif
    
     stmp->( orddestroy( 'sort_key' ) )
     stmp->( dbclosearea() )

    endif
    ytdsales->( dbclosearea() )

   endif
   ( filen )->( dbclosearea() )

  endif
  master->( dbclosearea() )

 endif

endif
Box_Restore(scrn)

return

*

function MthSalesRpt

local oldscr:=Box_Save(0,0,24,79), aArray, aScreen
local bchoice
local sd:='S'
local aReport, sMonth
local getlist:={}

memvar nCutoff, nFieldPos  // , sCutoff, mper

Public nCutoff, nFieldPos  // , sCutoff, mper

Heading('Monthly Sales Report')
aArray :={}
aadd( aArray, { 'Return', 'Return to Sales Menu' } )
aadd( aArray, { 'All Items', 'Best Sellers' } )
aadd( aArray, { 'Supplier', 'Best Sellers by Supplier' } )
aadd( aArray, { 'Department', 'Best Sellers by Department' } )
aadd( aArray, { 'Nett Sales','Monthly Nett Sales Report' } )

bchoice := MenuGen( aArray, 11, 36, 'Monthly')
if bchoice < 2
 return nil

endif
if bchoice = 5
 Monthly_Sales()

else
 aScreen := Box_Save(2,20,8,60)
 nCutoff := 10
 sMonth:=upper( substr( cmonth( Bvars( B_DATE ) ), 1, 3 ) )
 @ 03,22 say 'Sales Cutoff Quantity' get nCutoff pict '999'
 @ 05,22 say 'Month for analysis   ' get sMonth pict '!!!';
         valid( sMonth $ '|JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC|')
 read
 if Isready( 06 )
  Center( 07, "-=< Processing - Please Wait >=-" )
  if Master_use()
   if Netuse( "ytdsales" )
    nfieldpos := fieldpos( sMonth )
    indx( "fieldget( nfieldpos ) * -1", 'totals' )
// Build an array of fields
    aReport := {}
    aadd( aReport, {'idCheck(master->id)','Item ID', 14, 0, FALSE } )
    aadd( aReport, {'substr( master->desc, 1, 18)','Desc',19, 0,FALSE } )
    aadd( aReport, {'substr( master->alt_desc, 1, 12)', 'Alt Desc', 13, 0, FALSE } )
    aadd( aReport, {'master->onhand', 'Onhand', 7, 0, TRUE } )
    aadd( aReport, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aReport, {'master->dsale','Last Sale', 10, 0, FALSE } )
    aadd( aReport, {'Jan', 'Jan', 4, 0, TRUE } )
    aadd( aReport, {'Feb', 'Feb', 4, 0, TRUE } )
    aadd( aReport, {'Mar', 'Mar', 4, 0, TRUE } )
    aadd( aReport, {'Apr', 'Apr', 4, 0, TRUE } )
    aadd( aReport, {'May', 'May', 4, 0, TRUE } )
    aadd( aReport, {'Jun', 'Jun', 4, 0, TRUE } )
    aadd( aReport, {'Jul', 'Jul', 4, 0, TRUE } )
    aadd( aReport, {'Aug', 'Aug', 4, 0, TRUE } )
    aadd( aReport, {'Sep', 'Sep', 4, 0, TRUE } )
    aadd( aReport, {'Oct', 'Oct', 4, 0, TRUE } )
    aadd( aReport, {'Nov', 'Nov', 4, 0, TRUE } )
    aadd( aReport, {'Dec', 'Dec', 4, 0, TRUE } )
    aadd( aReport, {'JAN+FEB+MAR+APR+MAY+JUN+JUL+AUG+SEP+OCT+NOV+DEC','Total',6,0,TRUE } )

    do case
    case bchoice = 2
     set relation to ytdsales->id into master

     go top

     Reporter( aReport,;
               "Monthly Sales Report for Month " + sMonth,;
               ,;                                       // group by
               ,;                                       // group header
               ,;                                       // sub grp by
               ,;                                       // sub grp header
               FALSE,;                                  // Summary report
               "master->supp_code != 'MISC'",;          // For cond
               "fieldget( nfieldpos ) >= nCutoff",;     // While cond
               132 )                                    // Page width

    case bchoice = 3
     ytdsales->( dbgotop() )
     copy to ( Oddvars( TEMPFILE ) ) for fieldget( nfieldpos ) >= nCutoff
     if Netuse( Oddvars( TEMPFILE ), SHARED, 10, "saletemp" )
      set relation to saletemp->id into master
      indx( "master->supp_code", 'supplier' )
      
      saletemp->( dbgotop() )

      Reporter( aReport,;
               "Monthly Sales Report for Month " + sMonth + " by Supplier",;
               "master->supp_code",;                                    // group by
               '"Supplier:" + master->supp_code',;                      // group header
               ,;                                                       // sub grp by
               ,;                                                       // sub grp header
               FALSE,;                                                  // Summary report
               "master->supp_code != 'MISC'",;                          // For cond
               "fieldget( nFieldpos ) >= nCutoff",;                     // While cond
               132 )                                                    // Page width

      orddestroy( 'supplier' )

     endif

    case bchoice = 4
     go top
     copy to ( Oddvars( TEMPFILE ) ) while fieldget( nfieldpos) >= nCutoff
     if Netuse( Oddvars( TEMPFILE ), SHARED, 10, "saletemp" )
      set relation to saletemp->id into master
      indx( "master->department", 'dept' )
      
      go top

      Reporter( aReport,;
               "Monthly Sales Report for Month " + sMonth,;
               'master->department',;                    //group by
               "'Department'",;                            // group header
               ,;                                        // sub grp by
               ,;                                        // sub grp header
               FALSE,;                                   // Summary report
               "master->supp_code != 'MISC'",;           // For cond
               "fieldget( nFieldPos ) >= nCutoff",;      // While cond
               132 )                                     // Page width
      orddestroy( 'dept' )
     endif

    endcase
    ytdsales->( orddestroy( 'totals' ) )

   endif

  endif
  Box_Restore( AScreen, 2, 20, 8, 60 )

  dbcloseall()

 endif

endif
return nil

*

function NoSalesRpt

local aReport, aScreen
local getlist:={}

memvar dLastSale
public dLastSale

Heading('No Sales Report with stock')
aScreen := Box_Save(2,20,8,60)
dLastSale = date() - 31
@ 03,22 say 'Date of Last Sale' get dLastSale pict '@D'
read

if Isready( 06 )
 Center( 07, "-=< Processing - Please Wait >=-" )
 if Netuse( "ytdsales" )
  if Master_use()
   master->( ordsetfocus( BY_DEPARTMENT ) )
   set relation to master->id into ytdsales
   master->( dbgotop() )
   aReport := {}
   aadd( aReport,{'idCheck(master->id)','Item ID',14,0,FALSE})
   aadd( aReport,{'substr( master->desc, 1, 18)','Desc',19,0,FALSE})
   aadd( aReport,{'substr( master->alt_desc, 1, 12)','Alt Desc',13,0,FALSE})
   aadd( aReport,{'master->onhand', 'Onhand', 7, 0, TRUE })
//    aadd( aReport,{'space(1)','', 1, 0, FALSE })
   aadd( aReport,{'master->dsale','Last Sale', 10, 0, FALSE })
   aadd( aReport,{'ytdsales->Jan','Jan',4,0,TRUE})
   aadd( aReport,{'ytdsales->Feb','Feb',4,0,TRUE})
   aadd( aReport,{'ytdsales->Mar','Mar',4,0,TRUE})
   aadd( aReport,{'ytdsales->Apr','Apr',4,0,TRUE})
   aadd( aReport,{'ytdsales->May','May',4,0,TRUE})
   aadd( aReport,{'ytdsales->Jun','Jun',4,0,TRUE})
   aadd( aReport,{'ytdsales->Jul','Jul',4,0,TRUE})
   aadd( aReport,{'ytdsales->Aug','Aug',4,0,TRUE})
   aadd( aReport,{'ytdsales->Sep','Sep',4,0,TRUE})
   aadd( aReport,{'ytdsales->Oct','Oct',4,0,TRUE})
   aadd( aReport,{'ytdsales->Nov','Nov',4,0,TRUE})
   aadd( aReport,{'ytdsales->Dec','Dec',4,0,TRUE})
   aadd( aReport,{'ytdTot()','Total',6,0,TRUE } )

   master->( dbgotop() )

   Reporter( aReport,;
           "Items without a sale since " + dtoc( dLastSale ),;
           "master->department",;                         // group by
           "'Department:' + master->department",;           // group header
           ,;                                       // sub grp by
           ,;                                       // sub grp header
           FALSE,;                                  // Summary report
           "master->dsale <= dLastSale .and. master->onhand > 0",;           // For cond
           ,;                                       // While cond
           132 )                                    // Page width

  endif
 endif
endif
Box_Restore( aScreen )
dbcloseall()
return nil

*

function YearSalesRpt
local oldscr:=Box_Save(0,0,24,79)
local getlist:={}, sd:='S'
local aReport, aScreen

memvar nCutoff, sSupp
public nCutoff, sSupp

Heading( 'Yearly Sales Report' )
aScreen := Box_Save( 2, 20, 6, 60 )
@ 03, 22 say 'Supplier or Department Order (S/D)' get sd pict '@!A' valid (sd $ 'SD' )
read
nCutoff := 10
sSupp := space( if( sd = 'S', SUPP_CODE_LEN, DEPT_CODE_LEN ) )
@ 04, 22 say 'Sales Cutoff Quantity' get nCutoff pict '999'
@ 05, 22 say if( sd = 'S' ,'Supplier', 'Department' ) + ' to print (*=All)' get sSupp pict '@!'
read
if Isready(6)
 if Master_use()
  if Netuse( "Ytdsales" )
   indx( "(jan+feb+mar+apr+may+jun+jul+aug+sep+oct+nov+dec) * -1", 'totals' )
   dbgotop()
   copy to ( Oddvars( TEMPFILE ) ) while ;
        (jan+feb+mar+apr+may+jun+jul+aug+sep+oct+nov+dec) >= nCutoff
   if Netuse( Oddvars( TEMPFILE ), SHARED, 10, "saletemp" )
    set relation to saletemp->id into master
    indx( if( sd = 'S', "master->supp_code", "master->department" ), "mthtemp" )
    if sSupp != '*'
     saletemp->( dbseek( sSupp ) )

    else
     go top

    endif
    aReport := {}
    aadd( aReport,{'idCheck(master->id)','Item ID',ID_CODE_LEN+1,0,FALSE})
    aadd( aReport,{'substr( master->desc, 1, 18)','Desc',18,0,FALSE})
    aadd( aReport,{'substr( master->alt_desc, 1, 12)','Alt Desc',12,0,FALSE})
    aadd( aReport,{'master->onhand', 'Onhand', 7, 0, TRUE })
    aadd( aReport,{'master->dsale','Last Sale', 9, 0, FALSE })
    aadd( aReport,{'Jan','Jan',4,0,TRUE})
    aadd( aReport,{'Feb','Feb',4,0,TRUE})
    aadd( aReport,{'Mar','Mar',4,0,TRUE})
    aadd( aReport,{'Apr','Apr',4,0,TRUE})
    aadd( aReport,{'May','May',4,0,TRUE})
    aadd( aReport,{'Jun','Jun',4,0,TRUE})
    aadd( aReport,{'Jul','Jul',4,0,TRUE})
    aadd( aReport,{'Aug','Aug',4,0,TRUE})
    aadd( aReport,{'Sep','Sep',4,0,TRUE})
    aadd( aReport,{'Oct','Oct',4,0,TRUE})
    aadd( aReport,{'Nov','Nov',4,0,TRUE})
    aadd( aReport,{'Dec','Dec',4,0,TRUE})
    aadd( aReport,{'JAN+FEB+MAR+APR+MAY+JUN+JUL+AUG+SEP+OCT+NOV+DEC','Total',6,0,TRUE } )

    if sd = 'D'
     Reporter( aReport,;
               "Year to date Sales Report By Department",;
               'master->department',;                    // group by
               "'Department: '+Lookitup( 'dept',master->department)+' '+master->department",;      // group header
               ,;                                        // sub grp by
               ,;                                        // sub grp header
               FALSE,;                                   // Summary report
               ,;                                        // For cond
               "if( sSupp = '*', .t., master->department = sSupp)",;      // While cond
               132 )                                     // Page width

    else
     Reporter( aReport,;
               "Year to date Sales Report By Supplier",;
               'master->supp_code',;                     // group by
               "'Supplier: '+Lookitup( 'supplier',master->supp_code)+' '+master->supp_code",;         // group header
               ,;                                        // sub grp by
               ,;                                        // sub grp header
               FALSE,;                                   // Summary report
               ,;                                        // For cond
               "if( sSupp = '*', .t., master->supp_code = sSupp)",;      // While cond
               132 )                                     // Page width
    endif
    SysAudit( 'YtdSalRe4Qty>'+Ns( nCutoff ) )
   endif
   ytdsales->( orddestroy( 'totals' ) )
  endif
 endif
endif
Box_Restore( aScreen )
dbcloseall()
return nil

*

function PerSalesRpt()
local aScreen
local getlist:={}
local aReport, sCutoff

memvar nCutoff, nPer, nFieldPos
public nCutoff, nPer, nFieldPos

Heading('Period Sales Report')
aScreen := Box_Save(2,20,8,60)
nCutOff:=1
nPer := "1"
@ 03,22 say 'Sales Cutoff Quantity' get nCutOff pict '999'
@ 05,22 say '  Period for analysis' get nPer pict '99';
        valid( trim( nper ) $ '|1|2|3|4|5|6|7|8|9|10|11|12|' )
read
if Isready(06)
 if Master_use()
  if Netuse( "ytdsales" )
   Center(07,"-=< Processing - Please Wait >=-")
   nfieldpos := fieldpos( 'per' + nPer )
   set relation to ytdsales->id into master
   indx( "fieldget( nfieldpos ) * -1", 'totals' )
   sCutoff := Ns( nCutOff )
   ytdsales->( dbgotop() )
   aReport := {}
   aadd( aReport,{'idCheck(master->id)','Item ID',ID_CODE_LEN+1,0,FALSE})
   aadd( aReport,{'substr( master->desc, 1, 18)','Desc',18,0,FALSE})
   aadd( aReport,{'substr( master->alt_desc, 1, 12)','Alt;Desc',12,0,FALSE})
   aadd( aReport,{'master->onhand', 'Onhand', 7, 0, TRUE })
   aadd( aReport,{'master->dsale','Last;Sale', 9, 0, FALSE })
   aadd( aReport,{'Per1','P1',4,0,TRUE})
   aadd( aReport,{'Per2','P2',4,0,TRUE})
   aadd( aReport,{'Per3','P3',4,0,TRUE})
   aadd( aReport,{'Per4','P4',4,0,TRUE})
   aadd( aReport,{'Per5','P5',4,0,TRUE})
   aadd( aReport,{'Per6','P6',4,0,TRUE})
   aadd( aReport,{'Per7','P7',4,0,TRUE})
   aadd( aReport,{'Per8','P8',4,0,TRUE})
   aadd( aReport,{'Per9','P9',4,0,TRUE})
   aadd( aReport,{'Per10','P10',4,0,TRUE})
   aadd( aReport,{'Per11','P11',4,0,TRUE})
   aadd( aReport,{'Per12','P12',4,0,TRUE})
   aadd( aReport,{'Per1+Per2+Per3+Per4+Per5+Per6+Per7+Per8+Per9+Per10+Per11+Per12','Total',6,0,TRUE } )
   Reporter( aReport,;
             "Period Sales Report for Items with Period sales > " + sCutoff,;
             'master->department',;                    // group by
             "'Department:'+lookitup('dept',master->department)",;                           // group header
             ,;                                        // sub grp by
             ,;                                        // sub grp header
             FALSE,;                                   // Summary report
             ,;                                        // For cond
             "fieldget( nFieldpos ) >= nCutoff",;      // While cond
             132 )                                     // Page width

   SysAudit( 'PerSalRe4Qty>' + sCutOff )
  endif
  ytdsales->( orddestroy( 'totals' ) )
 endif
 close databases
endif
Box_Restore( aScreen )
return nil

*

function DeptSalesRpt
local aReport

memvar tot_sales, tot_profit
public tot_sales, tot_profit

if Netuse( "dept" )
  sum dept->week_sell - dept->Week_disc, ;
      dept->week_sell - dept->week_disc - dept->week_cost to ;
      tot_sales, tot_profit

 Heading('Sales by Department by Period')
 if Isready(12)
  aReport := {}
  aadd( aReport,{'name', 'Department Name', 20, 0, FALSE } )
  aadd( aReport,{'(week_sell-week_disc)/(tot_sales/100)','% of Sales', 11, 2, TRUE } )
  aadd( aReport,{'(week_sell-week_disc-week_cost)/(tot_profit/100)','% of Profit',12,2,TRUE } )
  aadd( aReport,{'week_sell-Week_Disc', 'Nett Sales', 11, 2, TRUE })
  aadd( aReport,{'week_cost','Nett Cost', 10, 2, TRUE })
  aadd( aReport,{'week_sell-Week_Disc-week_cost', 'Gross Profit', 12, 2, TRUE })
  dept->( dbgotop() )
  Reporter( aReport,;
            "Sales by department for Period" ,;
            'dept->code',;                    // group by
            "'Department:'+ dept->name",;    // group header
            ,;                                        // sub grp by
            ,;                                        // sub grp header
            FALSE,;                                   // Summary report
            "at('_', dept->code)= 0",;                // For cond
            ,;                                        // While cond
            132 )                                     // Page width

  SysAudit('DeptPerRep')
  if Isready( 6, 22, 'Ok to clear department Sales totals for Period' )
   go top
   while !dept->( eof() ) .and. Pinwheel( NOINTERUPT )
    Rec_lock( 'dept' )
    dept->week_sell := 0
    dept->week_disc := 0
    dept->week_cost := 0
    dept->( dbrunlock() )
    dept->( dbskip() )
   enddo
   SysAudit('DeptPerRptClr')
  endif
 endif
endif
close databases
return nil

*

Function SuppSalesRpt
local sd:='S', getlist := {}, lNoSales, sSupp, nToPeriod, lSum
local aReport

memvar nPeriod
public nPeriod

Heading( 'Print Period  Totals by Supplier' )

if Netuse( 'brand' )
 if Netuse( 'supplier' )
  if Netuse( 'ytdsales' )
   if Master_use()
    set relation to master->brand into brand,;
                 to master->supp_code into supplier
    if Netuse( "salehist" )
     set relation to salehist->id into master

     Print_find( 'Report' )
     
     nPeriod := 1
     ntoPeriod := 0
     sSupp := '*   '
     lNoSales := FALSE
     lSum := FALSE
     Box_Save( 09, 10, 16, 70 )
     @ 10,12 say ' Report from period' get nPeriod pict '99'
     @ 10,35 say 'back to period' get ntoPeriod pict '99'
     @ 11,12 say '  Supplier to Print' get sSupp pict '@!' valid( sSupp = '*' .or. Dup_Chk( sSupp, 'supplier' ) )
     @ 12,12 say 'Summary Report only' get lSum pict 'y'
     @ 15,12 say 'Print No Sales Report' get lNoSales pict 'y'
     read
     if lastkey() != K_ESC
      Box_Save( 05,20,09,60 )
      Center( 06, "-=< Totalling >=-" )
      if nToPeriod != 0
       total on salehist->id to ( Oddvars( TEMPFILE ) ) ;
             for salehist->period >= nPeriod .and. salehist->period <= nToPeriod .and. ;
             if( sSupp = '*', TRUE, master->supp_code = sSupp ) fields qty

      else
       total on salehist->id to ( Oddvars( TEMPFILE ) ) for salehist->period = nToPeriod .and. ;
             if( sSupp = '*', TRUE, master->supp_code = sSupp ) fields qty

      endif
      if Netuse( Oddvars( TEMPFILE ), SHARED, 10, 'temp' )
       set relation to temp->id into master,;
                    to temp->id into ytdsales

       Center( 07, "-=< Indexing >=-" )
       indx( "master->supp_code + master->brand + master->desc", 'supplier' )
       Center( 08, "-=< Printing >=-" )

       aReport := {}
       aadd( aReport,{'substr(master->desc, 1,30)', 'Description', 30, 0, FALSE } )
       aadd( aReport,{'idcheck(id)','ID', 10, 0, FALSE } )
       aadd( aReport,{'master->cost_price','Cost', 8, 2, FALSE } )
       aadd( aReport,{'master->onhand', 'On Hand', 8, 0, TRUE })
       aadd( aReport,{'master->onorder','On Order', 8, 2, TRUE })
       aadd( aReport,{'master->onorder','On Order', 8, 2, TRUE })
       aadd( aReport,{'qty', 'M.T.D.;Sales', 12, 0, TRUE })
       aadd( aReport,{'qty*master->cost_price', 'M.T.D.;Value', 12, 0, TRUE })
       aadd( aReport,{'FinYtd()', 'Y.T.D.', 10, 0, TRUE })
       if nToPeriod != 0
        // Pitch17()
        go top
        Reporter( aReport,;
                  '"Sales by Supplier by Period"' ,;
                  'supplier->name',;                        // group by
                  "'Supplier:'+Lookitup( 'supplier',master->supp_code)",;                             // group header
                  'brand->name',;                         // sub grp by
                  "'Brand :'+Lookitup( 'brand',master->brand)",;                             // sub grp header
                  FALSE,;                                   // Summary report
                  ,;                                        // For cond
                  ,;                                        // While cond
                  132 )                                     // Page width

        go top
        Reporter( aReport,;
                  '"Sales by Supplier by Period"' ,;
                  'supplier->name',;                        // group by
                  "'Supplier:'+Lookitup( 'supplier',master->supp_code)",;     // group header
                  'brand->name',;                         // sub grp by
                  "'Brand :'+Lookitup( 'brand',master->brand)",;            // sub grp header
                  TRUE,;                                   // Summary report
                  ,;                                        // For cond
                  ,;                                        // While cond
                  132 )                                     // Page width

       else
        if !lSum
         go top
         Reporter( aReport,;
                  '"Sales by Supplier for Period " + Ns( nPeriod )',;
                  'supplier->name',;                        // group by
                  "'Supplier:'+Lookitup( 'supplier',master->supp_code)",;                             // group header
                  'brand->name',;                         // sub grp by
                  "'Brand :'+Lookitup( 'brand',master->brand) ",;                             // sub grp header
                  FALSE,;                                   // Summary report
                  'temp->period = nPeriod',;                // For cond
                  ,;                                        // While cond
                  132 )                                     // Page width

        else
         go top
         Reporter( aReport,;
                  '"Sales by Supplier for Period " + Ns( nPeriod )' ,;
                  'supplier->name',;                        // group by
                  "'Supplier:'+Lookitup( 'supplier',master->supp_code) ",;                             // group header
                  'imprint->name',;                         // sub grp by
                  "'Imprint :'+Lookitup( 'brand',master->brand) ",;                             // sub grp header
                  TRUE,;                                    // Summary report
                  'temp->period = nPeriod',;                // For cond
                  ,;                                        // While cond
                  132 )                                     // Page width

        endif
       endif

       SysAudit( 'MthTotSuppRep' )
       select temp
       set relation to

       if lNoSales
        Box_Save( 05,20,09,60 )
        Center( 06, "-=< Indexing Sales History >=-" )
        indx( "id", 'id' )
        select master
        Center( 07, "-=< Indexing Master File >=-" )
        indx( "supp_code + brand + desc", 'supplier' )
        set relation to master->id into temp,;
                        master->supp_code into supplier,;
                        master->id into ytdsales,;
                        master->brand into brand
        Center( 08, "-=< Printing Report >=-" )
        
       // // Pitch17()
        if sSupp != '*'
         dbseek( trim( sSupp ) )
        endif
        Reporter( aReport,;
                  '"Items not sold by Supplier for Period " + Ns( nPeriod )',;
                  'supplier->name',;                        // group by
                  "'Supplier:'+Lookitup( 'supplier',master->supp_code) ",;                             // group header
                  'imprint->name',;                         // sub grp by
                  "'Imprint:'+Lookitup( 'brand',master->brand) ",;                             // sub grp header
                  TRUE,;                                    // Summary report
                  'temp->period = nPeriod',;                // For cond
                  "if( sSupp = '*', TRUE, master->supp_code = sSupp )",;   // While cond
                  132 )                                     // Page width

        SysAudit( 'MthSuppNoSaRe' )
        master->( orddestroy( 'supplier' ) )
       endif
      endif
     endif
    endif
   endif
  endif
 endif
endif
dbcloseall()
return nil

*

Function ImprSalesRpt
local sScr, getlist:={}, aReport
memvar sBrandcode, sBrandName
public sBrandCode, sBrandName

if Netuse( 'ytdsales' )
 if Master_use()
  set relation to master->id into ytdsales
  sScr := Box_Save( 3, 10 , 11, 70 )
 // Center( 4, 'This Procedure will require a reindex of the master file' )
 // if Isready( 12 )
   Center( 5, 'Reindexing Master File ' + Ns( lastrec() ) + ' records' )
   indx( "brand + desc", 'brand' )
   while TRUE
    sBrandCode := space( BRAND_CODE_LEN )
    @ 7,12 say 'Brand Code' get sBrandCode pict '@!' valid( Dup_chk( sBrandCode, 'brand' ) )
    read
    if !updated()
     exit

    else
     Print_find( "report" )
     sBrandName := LookItup( 'Brand', sBrandCode )
     Center( 9,'Brand to print => ' +  sBrandName )
     if Isready( 12 )
      select master
      seek sBrandCode
      aReport := {}
      aadd(aReport,{'master->id','Item ID', 15, 0, FALSE } )
      aadd(aReport,{'master->desc','Item Description', 40, 0, FALSE} )
      aadd(aReport,{'master->cost_price','Cost Price', 12, 2, FALSE} )
      aadd(aReport,{'master->retail','Recomended;Retail', 12, 2, FALSE} )
      aadd(aReport,{'master->sell_price','Sell Price', 12, 2, FALSE} )
      aadd(aReport,{'master->onhand','Onhand', 7, 0, TRUE } )
      aadd(aReport,{'ytdtot()','Ytd;Sales', 7, 0, TRUE } )
    
      Reporter(aReport,;
               'Sales by Brand for ' + sBrandName ,;
               ,;
               ,;
               ,;
               ,;
               FALSE,;
               ,;
               "master->brand = sBrandCode",;
               132 )
      SysAudit( 'SaleImpr' )
     endif
    endif
   enddo
   master->( orddestroy( 'brand' ) )
 endif
endif
dbcloseall()
return nil

*

procedure listbest()
local db, numdays := 14, getlist:={}
local count, dept, aReport := {}
local bind := '* ', dpart := '*  '
local mscr := Box_Save(10,26,15,56)

memvar stdate,enddate
private stdate := Bvars( B_DATE ) - 13, enddate := Bvars( B_DATE )

@ 11,29 say "Enter start date:" get stdate picture 'D' valid stdate >= ctod('01/01/80')
@ 12,28 say "Enter finish date:" get enddate picture 'D' valid enddate >= ctod('01/01/80')
@ 13,37 say "Binding: " get bind picture '@!K' valid ( bind = '* ' .or. dup_chk( bind, 'binding') )
@ 14,34 say "Department: " get dpart picture '@K!' valid ( dpart = '*  ' .or. dup_chk( dpart, 'dept'))
read

if select( 'binding') != 0
 binding->( dbclosearea() )
endif

if select( 'dept') != 0
 dept->( dbclosearea() )
endif

if IsReady(16)
 if Master_use()
  if Netuse( "salehist" )
   set relation to salehist->id into master
   db := {}
   aadd( db, { "id", "C", 12, 0 } )
   aadd( db, { "qty", "N", 8, 0 } )
   aadd( db, { "department", "C", 3, 0 } )
   aadd( db, { "brand", "C", 6, 0 } )
   aadd( db, { "date", "D", 0, 0 } )
   aadd( db, { "binding", "C", 2, 0 } )
   dbcreate( Oddvars( TEMPFILE ), db )
   select 0
   if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "saletmp" )
    salehist->( dbgobottom() )
    while ((( salehist->date ) >= stdate) .and. salehist->(!bof())) .or. salehist->date = ctod("  /  /  ")
     Pinwheel()      
     if ( salehist->date) <= enddate .and. salehist->date <> ctod("  /  /  ") 
      if ( master->binding == bind .or. bind == '* ')
       if ( master->department == dpart .or. dpart == '*  ')
        add_rec( 'saletmp' )
        saletmp->id := salehist->id
        saletmp->qty := salehist->qty
        saletmp->department := master->department
        saletmp->brand := master->brand
        saletmp->date := salehist->date
        saletmp->binding := master->binding
       endif
      endif
     endif
     salehist->( dbskip(-1) )
    enddo
    set relation to
    indx( "saletmp->id", "id" )
    total on saletmp->id fields qty to ( Oddvars( TEMPFILE2 ) )
    saletmp->( orddestroy( 'id' ) )
    close saletmp
    Kill( "tmpindx" + ordbagext() )
   endif
   close salehist
  endif
// --- Keep only 20 descs in each department ----
  select 0
  if Netuse( Oddvars( TEMPFILE2 ), EXCLUSIVE, 10, "stmp" )
   indx("department+descend(padl(str(qty),8,'0'))","dept")
   stmp->( dbgotop() )
   while stmp->( !eof() )
    count := 0
    dept := stmp->department
    while ( dept == stmp->department )
     if stmp->qty <= 0
      stmp->( dbdelete() )
     else
      count ++
     endif
     if count > 20
      stmp->( dbdelete() )
     endif
     stmp->( dbskip() )
    enddo
   enddo

   stmp->( orddestroy( 'dept' ) )
   stmp->( dbclosearea() )

  endif

 // Top 20 in Each Brand ----------------------------------------------
  if Netuse( "brand" )
   if Netuse( Oddvars( TEMPFILE2 ), EXCLUSIVE, 10, "stmp" )
    indx("department+descend(padl(str(qty),8,'0'))", 'dept')
    set relation to stmp->id into master, stmp->brand into brand

    stmp->( dbgotop() )
   
    aadd(aReport,{'substr(master->desc,1,50)','Desc',50,0,FALSE})
    aadd(aReport,{'substr(master->alt_desc,1,20)','Author',20,0,FALSE})
    aadd(aReport,{'master->binding','Binding',7,0,FALSE})
    aadd(aReport,{'brand->name','Brand',20,0,FALSE})
    aadd(aReport,{'qty','Quantity',8,0,TRUE})

    Reporter(aReport,'"Best Sellers Listing ('+dtoc(stdate)+' to '+dtoc(enddate)+')',;
    'department',"'Department : '+department+' ('+lookitup('dept',department)+')'",'','',FALSE)

    stmp->( orddestroy( 'dept' ) )
    stmp->( dbclosearea() )

   endif

   brand->( dbclosearea() )

  endif
  master->( dbclosearea() )

 endif
 if select( 'dept') != 0
  dept->( dbclosearea() )

 endif
endif
Box_Restore( mscr )
return

