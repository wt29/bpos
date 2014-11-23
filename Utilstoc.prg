/**

        Utilstoc.prg
        
      Last change:  TG   27 Feb 2011    4:57 pm
*/
Procedure U_stocktake

#include "bpos.ch"

#include 'fileio.ch'

local lGo:=FALSE, oldscr:=Box_Save(), nMenuSelect, aArray

if Master_use()
 lGo := TRUE

endif

Line_clear( 24 )

select master

while lGo
 Box_Restore( oldscr )
 Heading('Stocktake System')
 aArray := {}
 aadd( aArray, { 'Utility', 'Return to Utility Menu', , nil } )
 aadd( aArray, { 'Prepare', 'Prepare the stockfile for Stocktaking', { || StPrep() }, X_SUPERVISOR } )
 aadd( aArray, { 'Stocktake', 'Perform the Stocktake', { || StDo() }, nil } )
 aadd( aArray, { 'Reports', 'Shrinkage etc reports', { || StPrint() }, nil  } )
 aadd( aArray, { 'Finalise', 'Accept Stocktake and update onhand quantities', { || StFinal() }, X_SUPERVISOR } )
 nMenuSelect := Menugen( aArray, 04, 50, 'Stocktake' )
 if nMenuSelect < 2
  exit

 else
  if Secure( aArray[ nMenuSelect, 4 ] )
   Eval( aArray[ nMenuSelect, 3 ] )

  endif

 endif

enddo
dbcloseall()
return

*

procedure s_qty ( qtyflag )
@ 3,50 clear to 3,78
Highlight( 3,70,'','Multiples')
qtyflag := TRUE
return

*

procedure stkadj
local mscr,mmin:=FALSE,mcost:=FALSE,oldcur:=setcursor(1), mper, getlist:={}
if Secure( X_SUPERVISOR )
 mscr := Box_Save( 02, 02, 07, 77 )
 Heading("Post Stocktake Adjustments")
 Box_Save( 2, 02, 7, 77 )
 Center( 3, 'This routine will allow you to reset the minimum stock and' )
 Center( 4, ' change all zero cost prices to a defined percentage of sell price' )
 @ 5, 12 say 'Set Minimum Stock to On Hand' get mmin pict 'y'
 @ 5, 45 say 'Change zero Cost Prices' get mcost pict 'y'
 read
 if mcost
  mper := 35.0
  @ 6, 45 say 'Default percentage' get mper pict '99.9'
  read
 endif
 if Isready(12)
  if !Netuse( "master", EXCLUSIVE )
   Error( "Exclusive use of master file required", 12 )
  else
   @ 6, 24 say Ns( master->( lastrec() ) )
   if mmin
    @ 6,12 say 'Min'
    replace all minstock with master->onhand while Pinwheel( NOINTERUPT )
    SysAudit("MinStkAdj")
   endif
   if mcost
    @ 6,16 say 'Cost'
    replace all cost_price with master->sell_price-((master->sell_price/100)*mper);
            for master->cost_price = 0 while Pinwheel( NOINTERUPT )
    SysAudit("CostPriceAdj")
   endif
   master->( dbclosearea() )
  endif
 endif
 setcursor(oldcur)
 Box_Restore( mscr )
endif
return

*

procedure stprep

local mdept, mtype, getlist:={}, lAnswer
Box_Save( 2, 02, 12, 77 )

if Sysinc("FlagStk","G")    // SYSREC->FLAGSTK
 Heading('Stocktake already in progress')
 Center( 3, "The system has detected a stocktake already in progress.")
 Center( 5, "If you do not wish to proceed answer 'N' to the question!")
 Center( 7, "If you really do have a stocktake in progress then continuing from")
 Center( 8, "here will clear current stocktake details and you will have to")
 Center( 9, "re-enter all your stocktake up to this point.")
 Error('Stocktake Already in progress',14)

else
 Heading('Stocktake Preparation')
 Center( 3, "This procedure will prepare the master file for the stocktake.")
 Center( 5, "It 'zeros' the current Stocktake quantities in the master file.")
 Center( 7, "It is a mandatory step in the stocktaking process.")

endif
if Isready(14)

 Heading('Determine Stocktake Type')
 mtype := 'D'
 Box_Save(2,08,15,72)
 @ 3,10 say '<D>epartmental Stocktake or <A>ll the Store <D/A> ';
        get mtype pict '!' valid( mtype $ 'DA' )
 read
 lAnswer := FALSE
 mdept := space(3)
 if mtype = 'D'
  @ 5,10 say 'You are about to perform a "Departmental" stocktake'
  mdept := space(3)
  @ 7,10 say 'Enter Department Code for Stocktake' get mdept pict '!!!';
         valid( Dup_chk( mdept , "dept" ) )
  read
  if lastkey() != K_ESC
   @ 7,10 say space(50)
   Center(7,'Department Name อออ> ' + Lookitup( "dept" , mdept ) )

  else
   return

  endif

 else
  syscolor( C_BRIGHT )
  @ 5,10 say 'You are about to stocktake everything in the store'
  syscolor( C_NORMAL )

 endif
 if Isready(9)
  Center(13, 'Processing in progress - Please wait')
  SysAudit("StkTakePre")
  select master
  if Netuse( "master", EXCLUSIVE, 10, NOALIAS, OLD )
   if mtype = 'A'
    replace all stocktake with 0

   else
    master->( ordsetfocus( BY_DEPARTMENT ) )
    master->( dbseek( mdept ) )
    replace all stocktake with 0 while master->department = mdept

   endif

   Sysinc( "FlagStk","R",TRUE )
   Sysinc( "StkType","R",mtype )
   Sysinc( "Stkdept","R",mdept )

   master->( dbclosearea() )
   Master_use()
  else
   Error('You need exclusive use of the Master file to perform this',12)
   Master_use()
  endif
 endif
endif
select master
ordsetfocus( BY_ID )
return

*

procedure stdo
local okf10,mdep,mtype,mnew,mtot:=1,mtot2:=0,mtot3:=0,mdepname, sID,mrate,cucount
local mspace:=space( ID_ENQ_LEN ),start:=seconds(),max_rate:=0,oldscan:=space( ID_ENQ_LEN ),mqty
local getlist:={}, qtyflag
cls
Heading( 'Stocktake Entry' )
if !Sysinc( "FlagStk", "G" )       // SYSREC->FLAGSTK
 Error( 'You MUST Prepare the stock file first!!', 12 )

else
 mdep := Sysinc( "stkdept", 'g' )
 mtype := Sysinc( "Stktype", "G" )   // SYSREC->STKTYPE
 if mtype = 'A'
  mdep := space(3)
  Box_Save(2,18,4,62)
  @ 03,20 say 'Default Department' get mdep pict '@!' ;
          valid( Dup_chk( mdep , "dept" ) )
  read
  if lastkey() = K_ESC
   select master

   return
  else
   mdepname := lookitup( 'dept', mdep ) //dept->name
  endif
 else
  Heading( 'Departmental Stocktake' )
  mdepname:= LookItUp( "dept", Sysinc( "StkDept", "G" ) )  // SYSREC->STKDEPT
 endif
 select master
 @ 2,08 clear to 6,72
 @ 5,10 say 'Previous ' + ITEM_DESC + '                  Stocktake     Onhand         Qty'
 while TRUE
  mqty := 1
  qtyflag := FALSE
  sID := mspace
  okf10 := setkey( K_F10 , { || s_qty( @qtyflag ) } )
  @ 03,10 say 'Scan barcode' get sID pict '@!'
  @ 03,52 say "<F10>  Apply Qty's"
  read
  setkey( K_F10 , okf10 )
  if !updated() .and. mqty = 1
   exit

  else
   if !Codefind( sID )     
    Error( 'Scan Incorrect', 12, .5 )
    tone( lvars( L_BAD ), 5 )

   else
    tone( lvars( L_GOOD ), 5 )
    if qtyflag
     mqty := 0
     @ 3,57 get mqty pict QTY_PICT valid( mqty < 9000 )
     read
     if !updated()
      loop

     endif

    endif
    mnew := FALSE
    if mtype = 'D' .and. mdep != master->department

     if Isready( 4, 10,'Department does not match Stocktake Department - Overwrite (Y/N)' )

      Rec_lock( 'master' )
      master->department := mdep
      master->stocktake := 0
      master->( dbrunlock() )

     else
      loop
     endif
    endif
    Rec_lock( 'master' )
    master->stocktake += mqty

    qtyflag := FALSE

    if empty( master->department )
     master->department := mdep
    endif
    master->( dbrunlock() )

    scroll( 6, 9, 15, 70, -1 )
    line_clear( 6 )
    @ 6,09 say left( master->desc, 30 )
    @ 6,45 say master->stocktake
    @ 6,57 say master->onhand
    @ 6,69 say padl( alltrim( str( mqty ) ), 6 )
    mtot3 += mqty
    if trim( sID ) = oldscan
     Line_clear( 19 )
     cucount += mqty
     Highlight( 19, 10, 'Cumulative copy count = ', Ns( cucount, 4 ) )
    else
     cucount := mqty
     mtot2++
     Line_clear( 19 )
    endif
    Highlight( 20, 10, '' + ITEM_DESC + ' scanned this session = ', Ns( mtot2, 5 ) )
    Highlight( 21, 10, 'Volumes added this session  = ', Ns( mtot3, 5 ) )
    if mtot2 > 20
     mrate := ( ( seconds() - start ) ) / mtot2
     max_rate := max( max_rate, mrate )
     Highlight( 22, 10, 'Current Average Scan Rate   = ', Ns( mrate, 6, 2 ) )
     Highlight( 23, 10, 'Best Rate Achieved          = ', Ns( max_rate, 6, 2 ) )
    endif
    oldscan := trim( sID )
   endif
  endif
 enddo
endif
return

*

procedure stprint
local nMenuSelect,mstktype:=Sysinc("StkType","G"),mapp,mavg,mstocktake,aArray
local getlist:={}, mscr, mdbf, aReport,sForCond
local mcount,msum,mavr,msell,mrrp,moh,mcost,mappr,mapprval

memvar totcost, mdep, lIncludeApps, lanswer, monhand, mmargin, mupmargin
public totcost, mdep, lIncludeApps, lanswer, monhand, mmargin, mupmargin

mdep:=Sysinc("Stkdept","G")
while TRUE
 Heading('Stocktake Report Menu')
 Print_Find( "Report" )
 aArray := {}
 aadd( aArray, { 'Quit', 'Return to Stocktake Menu' } )
 aadd( aArray, { 'Overs', 'Print all items where Onhand is greater than the Stocktake Numbers' } )
 aadd( aArray, { 'Unders', 'Print all itens where Onhand is less that the Stocktake (Shrinkage)' } )
 aadd( aArray, { 'Negative', 'Print all items where Onhand is Negative' } )
 aadd( aArray, { 'Department', 'Stocktake Values by Department' } )
 aadd( aArray, { 'Totals', 'Display stock values using Stocktake totals' } )
 aadd( aArray, { 'Stock List', 'Print a list of all items in stock - uses the Onhand value' } )
 aadd( aArray, { 'StkTake Ls', 'Print a list of all items counted in the Stocktake' } )
 aadd( aArray, { 'Data Error', 'Print a list of Stock with potential Data Entry Errors' } )

 nMenuSelect := MenuGen( aArray, 09, 51, 'Reports')

 do case
 case nMenuSelect < 2
  exit
 case nMenuSelect = 2
  Heading('Print Stocktake Overs Report')
  if Isready(12)
   
   select master
   ordsetfocus( BY_DEPARTMENT )       // By Department !!

   aReport := {}
   aadd(aReport,{'master->id',ID_DESC, 15, 0, FALSE } )
   aadd(aReport,{'master->desc',DESC_DESC, 20, 0, FALSE} )
   aadd(aReport,{'master->alt_desc','Alt Desc', 10, 0, FALSE} )
   aadd(aReport,{'master->onhand','Onhand', 7, 0, TRUE } )
   aadd(aReport,{'master->approval','Appr', 7, 0, TRUE } )
   aadd(aReport,{'master->stocktake','Stktake', 9, 0, TRUE } )
   aadd(aReport,{'master->stocktake-master->onhand','Variation', 10, 0, TRUE } )
   aadd(aReport,{'cost_price*(onhand-stocktake)','Ext Value;Last Cost', 10, 2, TRUE } )
   aadd(aReport,{'avr_cost*(onhand-stocktake)','Ext Value;Avr Cost', 10, 2, TRUE } )
   aadd(aReport,{'sell_price*(onhand-stocktake)','Ext Value;At Sell', 10, 2, TRUE } )
   aadd(aReport,{'retail*(onhand-stocktake)','Ext Value;Retail', 10, 2, TRUE } )

//   // Pitch17()
   if mstktype == "A"   // sysrec->stktype = 'A'
    go top
    Reporter( aReport,;
            "Stocktake Overs Report",;
            ,;                              // group by
            ,;                              // group header
            ,;                              // sub grp by
            ,;                              // sub grp header
            FALSE,;                                   // Summary report
            'master->stocktake > master->onhand',;    // For cond
            ,;                                        // While cond
            132 )                                     // Page width

   else
    seek mdep
    Reporter( aReport,;
            "Stocktake Overs Report",;
            ,;                              // group by
            ,;                              // group header
            ,;                              // sub grp by
            ,;                              // sub grp header
            FALSE,;                                   // Summary report
            'master->stocktake > master->onhand',;    // For cond
            'master->department = mdep',;                                        // While cond
            132 )                                     // Page width

   endif
   ordsetfocus( BY_ID )
  endif
 case nMenuSelect = 3
  Heading('Print Stocktake Unders Report')
  lIncludeApps := TRUE
  mscr := Box_Save( 2, 10, 4, 40 )
  @ 3,12 say 'Add Approvals to Count' get lIncludeApps pict 'y'
  read
  Box_Restore( mscr )
  if Isready(12)
   
   ordsetfocus( BY_DEPARTMENT )
   aReport := {}
   aadd(aReport,{'master->id',ID_DESC, 15, 0, FALSE } )
   aadd(aReport,{'master->desc',DESC_DESC, 20, 0, FALSE} )
   aadd(aReport,{'master->alt_desc','Alt Desc', 10, 0, FALSE} )
   aadd(aReport,{'master->onhand','Onhand', 7, 0, TRUE } )
   aadd(aReport,{'master->approval','Appr', 7, 0, TRUE } )
   aadd(aReport,{'master->stocktake','Stktake', 9, 0, TRUE } )
   aadd(aReport,{'master->stocktake-master->onhand','Variation', 9, 0, TRUE } )
   aadd(aReport,{'cost_price*(onhand-stocktake)','Ext Value;Last Cost', 10, 2, TRUE } )
   aadd(aReport,{'avr_cost*(onhand-stocktake)','Ext Value;Avr Cost', 10, 2, TRUE } )
   aadd(aReport,{'sell_price*(onhand-stocktake)','Ext Value;At Sell', 10, 2, TRUE } )
   aadd(aReport,{'retail*(onhand-stocktake)','Ext Value;Retail', 10, 2, TRUE } )

   if mstktype == "A"   // sysrec->stktype = 'A'
    go top
    Reporter( aReport,;
            "Stocktake Overs Report",;
            ,;                              // group by
            ,;                              // group header
            ,;                              // sub grp by
            ,;                              // sub grp header
            FALSE,;                                   // Summary report
            'master->stocktake + if( lIncludeApps, master->approval, 0 ) < master->onhand',;    // For cond
            ,;                                        // While cond
            132 )                                     // Page width
   else
    seek mdep

    Reporter( aReport,;
            "Stocktake Overs Report",;
            ,;                              // group by
            ,;                              // group header
            ,;                              // sub grp by
            ,;                              // sub grp header
            FALSE,;                                   // Summary report
            'master->stocktake + if( lIncludeApps, master->approval, 0 ) < master->onhand',;    // For cond
            'master->department = mdep',;                                        // While cond
            132 )                                     // Page width
   endif
   ordsetfocus( BY_ID )
  endif

 case nMenuSelect = 4
  Box_Save(3,08,12,72)
  Heading('Print Negative Stock Report')
  lAnswer := 'A'
  @ 05,10 say '<A>ll Stock or a <D>epartment' get lAnswer pict '!';
          valid(lAnswer $ 'AD')
  read
  if lAnswer = 'D'
   mdep := space(3)
   @ 07,10 say 'Enter Department Code for Report' get mdep pict '!!!' ;
           valid( Dup_chk( mdep , "dept" ) )
   read
  endif
  if Isready(9)
   select master
   ordsetfocus( BY_DEPARTMENT )
   go top

   aReport := {}
   aadd(aReport, {'master->id', ID_DESC, 15, 0, FALSE } )
   aadd(aReport, {'master->desc', 'Item Description', 50, 0, FALSE} )
   aadd(aReport, {'master->alt_desc', 'Alt Desc', 10, 0, FALSE} )
   aadd(aReport, {'master->onhand', 'Onhand', 7, 0, TRUE } )
   Reporter( aReport,;
            "Negative Stock Report",;
            ,;                              // group by
            ,;                              // group header
            ,;                              // sub grp by
            ,;                              // sub grp header
            FALSE,;                                   // Summary report
            "master->onhand < 0",;    // For cond
            "if( lAnswer = 'A', .t., master->department=mdep)",;                                        // While cond
            132 )                                     // Page width

   ordsetfocus( BY_ID )
  endif
 case nMenuSelect = 5
  if select('dept') = 0
   if !netuse('dept',FALSE,10, NOALIAS, NEW )
    Error( 'Dept file not available', 12 )
    loop
   endif
  endif
  Print_find("report")
  
  if Isready(12)
   mdbf := {}
   aadd( mdbf, { "department", 'C', 3, 0 } )
   aadd( mdbf, { "onhand", 'N', 12, 0 } )
   aadd( mdbf, { "sum", 'N', 12, 0 } )
   aadd( mdbf, { "average", 'N', 12, 2 } )
   aadd( mdbf, { "cost", 'N', 12, 2 } )
   aadd( mdbf, { "sell", 'N', 12, 2 } )
   aadd( mdbf, { "retail", 'N', 12, 2 } )
   aadd( mdbf, { "approval", 'N', 12, 2 } )
   dbcreate( Oddvars( TEMPFILE ) , mdbf )
   Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "total", NEW )
   select master
   ordsetfocus( BY_DEPARTMENT )
   master->( dbgotop() )
   mdep := master->department
   totcost := 0
   while !master->( eof() )
    mscr:=Box_Save(2,20,4,60)
    Center( 3,'Processing Dept ' + mdep )
    sum master->sell_price*master->stocktake, master->cost_price*master->stocktake, ;
        if( master->stocktake > 0, 1, 0 ), ;
        master->avr_cost*master->stocktake, master->stocktake, ;
        master->retail*master->stocktake, 0 ;
        to msell,mcost,msum,mavg,mstocktake,mrrp,mapp ;
        while master->department = mdep
    Add_rec( 'total' )
    total->department := mdep
    total->onhand := mstocktake
    total->sum := msum
    total->cost := mcost
    total->average := mavg
    total->sell := msell
    total->retail := mrrp
    total->approval := mapp
    total->( dbrunlock() )
    select master
    mdep := master->department
    totcost += mcost
   enddo
   Box_Restore( mscr )
   select total
   dbgotop()
   set relation to field->department into dept
   aReport := {}
   aadd(aReport,{'dept->name','Department', 11, 0, FALSE } )
   aadd(aReport,{'sum','# of;Items', 8, 0, TRUE } )
   aadd(aReport,{'master->onhand','Onhand', 7, 0, TRUE } )
   aadd(aReport,{'cost','Stock at;Last Cost', 10, 2, TRUE } )
   aadd(aReport,{'average','Stock at;Avr Cost', 10, 2, TRUE } )
   aadd(aReport,{'sell','Stock at;Sell Price', 10, 2, TRUE } )
   aadd(aReport,{'retail','Stock at;Retail', 10, 2, TRUE } )
   aadd(aReport,{'cost/(totcost/100)','% of;Stock', 5, 2, FALSE } )
   aadd(aReport,{'master->stocktake-master->onhand','Variation', 9, 0, TRUE } )
   aadd(aReport,{'master->cost_price*(master->onhand-master->stocktake)','Ext Value;Last Cost', 10, 2, TRUE } )
   aadd(aReport,{'master->avr_cost*(master->onhand-master->stocktake)','Ext Value;Avr Cost', 10, 2, TRUE } )
   aadd(aReport,{'master->sell_price*(master->onhand-master->stocktake)','Ext Value;At Sell', 10, 2, TRUE } )
   aadd(aReport,{'master->retail*(master->onhand-master->stocktake)','Ext Value;Retail', 10, 2, TRUE } )


   Reporter( aReport,;
            "Stocktake Valuation by Department",;
            ,;                              // group by
            ,;                              // group header
            ,;                              // sub grp by
            ,;                              // sub grp header
            FALSE,;                         // Summary report
            ,;                              // For cond
            ,;                              // While cond
            132 )                           // Page width

   total->( dbclosearea() )
   select master
   ordsetfocus( BY_ID )
  endif
  set relation to
  dept->( dbclosearea() )
  select master
  loop
 case nMenuSelect = 6
  Box_Save(2,08,21,72)
  Center(3,'-=< Stock Take Totals >=-')
  Heading('Stocktake Totals')
  if Isready(12)
   Center(3,'                         ')
   Center(3,'-=< Processing in progress - Please Wait >=-')
   select master
   if mstktype == 'A'
    ordsetfocus(  )
    dbgotop()
   else
    ordsetfocus( BY_DEPARTMENT )
    dbseek( mdep )
   endif
   mcount := 0
   msum := 0
   mappr:= 0
   mcost := 0
   mavr := 0
   msell := 0
   mrrp := 0
   moh := 0
   mapprval := 0
   while ( ( mstktype == 'A' .and. !master->( eof() ) ) .or.;
    ( mstktype == 'D' .and. master->department = mdep ) ) .and. Pinwheel()
    if master->stocktake > 0
     mcount++
    endif
    msum += master->stocktake
    mcost += master->stocktake * master->cost_price
    mavr += master->stocktake * master->avr_cost
    msell += master->stocktake * master->sell_price
    mrrp += master->stocktake * master->retail
    moh += master->onhand
    mappr += master->approval
    mapprval += master->approval * master->cost_price
    skip alias master
   enddo
   if mstktype = 'A'
    Heading("Stocktake totals for all Stock")
   else
    Heading("Stocktake totals for Dept. " + Lookitup( "dept" , mdep ) )
   endif
   Highlight( 05, 10, 'Number of ' + ITEM_DESC + ' Counted       ', Ns( mcount ) )
   Highlight( 06, 10, 'Number of Items Counted        ', Ns( msum ) )
   Highlight( 08, 10, 'Items Onhand Pre Stocktake     ', Ns( moh ) )
   Highlight( 10, 10, 'Number of Items on Approval    ', Ns( mappr ) )
   Highlight( 11, 10, 'Approval Value at Last Cost   $', Ns( mapprval, 10, 2 ) )
   Highlight( 12, 10, 'Stocktake Value at Last Cost  $', Ns( mcost, 10, 2 ) )
   Highlight( 13, 10, 'Stocktake Value at Avr. Cost  $', Ns( mavr, 10, 2 ) )
   Highlight( 15, 10, 'Stocktake Value at Sell Price $', Ns( msell, 10, 2 ) )
   Highlight( 17, 10, 'Stocktake Value at R.R.P.     $', Ns( mrrp, 10, 2 ) )
   if !eof() .and. mstktype = 'A'
    @ 19,10 say 'Processing Aborted - Values Incorrect!!'
   endif
   Isready(20)
   ordsetfocus( BY_ID )
  endif
 case nMenuSelect = 7
  Heading('Print Stock Listing')
  if select('dept') = 0
   if !netuse( 'dept', SHARED, 10, NOALIAS, NEW )
    Error( 'Dept file not available', 12 )
    loop
   endif
  endif
  select master
  set relation to master->department into dept
  Box_Save(3,08,12,72)
  lAnswer := 'A'
  mdep := space(3)
  @ 05,10 say '<A>ll Stock or a <D>epartment' get lAnswer pict '!';
          valid(lAnswer $ 'AD')
  read
  if lAnswer = 'D'
   @ 07,10 say 'Enter Department Code for Report' get mdep pict '!!!' ;
           when( lAnswer = 'D' ) valid( Dup_chk( mdep , "dept" ) )
   read

  endif

  if Isready(12)
   
   ordsetfocus( BY_DEPARTMENT )      // Index by Dept
   if lAnswer = 'A'
    master->( dbgotop() )

   else
    master->( dbseek( mdep ) )

   endif
   aReport := {}
   aadd( aReport, {'substr(desc, 1, 35)', DESC_DESC, 30, 0, FALSE } )
   aadd( aReport, {'space(1)', ' ', 1, 0, FALSE } )
   aadd( aReport, {'substr(alt_desc, 1, 25)', ALT_DESC, 25, 0, FALSE } )
   aadd( aReport, {'master->onhand','Onhand', 7, 0, TRUE } )
   aadd( aReport, {'master->sell_price','Sell;Price', 10, 2, FALSE } )
   aadd( aReport, {'master->sell_price*master->onhand','Valuation;Sell Price', 12,2, TRUE } )
   aadd( aReport, {'master->cost_price','Cost;Price', 10, 2, FALSE } )
   aadd( aReport, {'master->cost_price*master->onhand','Valuation;Cost Price', 12,2, TRUE } )
 //  aadd( aReport, {'100-Zero(master->cost_price,Zero(master->onhand->sell_price, 100))','Discount', 10,2, FALSE } )

   if lAnswer = 'D'
    Reporter( aReport,;
            "Stock listing by Department",;
            ,;                              // group by
            ,;                              // group header
            ,;                              // sub grp by
            ,;                              // sub grp header
            FALSE,;                         // Summary report
            "master->onhand > 0",;          // For cond
            "master->department = mdep",;   // While cond
            132 )                           // Page width
   else
    Reporter( aReport,;
            "Stock listing by Department",;
            ,;                              // group by
            ,;                              // group header
            ,;                              // sub grp by
            ,;                              // sub grp header
            FALSE,;                         // Summary report
            "master->onhand >0",;           // For cond
            ,;                              // While cond
            132 )                           // Page width

    endif

   ordsetfocus( BY_ID )
  endif
  dept->( dbclosearea() )
  select master
 
 case nMenuSelect = 8
  Heading('Print Stocktake Listing')
  if !netuse( 'dept', SHARED, 10, NOALIAS, NEW )
   Error( 'Dept file not available', 12 )
   loop
  endif
  select master
  set relation to master->department into dept
  if Isready(12)
   
   ordsetfocus( BY_DEPARTMENT )     // Index by Dept
   go top
   aReport := {}
   aadd(aReport,{'substr(desc, 1, 35)', DESC_DESC, 30, 0, FALSE } )
   aadd(aReport,{'substr(alt_desc, 1, 25)', ALT_DESC, 25, 0, FALSE } )
   aadd(aReport,{'master->stocktake', 'Stocktake', 8, 0, TRUE } )
   aadd(aReport,{'master->onhand', 'Onhand', 7, 0, TRUE } )
   aadd(aReport,{'master->sell_price', 'Sell;Price', 10, 2, FALSE } )
   aadd(aReport,{'master->sell_price*master->stocktake', 'ST Valuation; @Sell Price', 12,2, TRUE } )
   aadd(aReport,{'master->cost_price', 'Cost;Price', 10, 2, FALSE } )
   aadd(aReport,{'master->cost_price*master->stocktake','St Valuation; @Cost Price', 12,2, TRUE } )
//   aadd(aReport,{'100-Zero(master->cost_price,Zero(master->onhand->sell_price, 100))','Discount', 10,2, FALSE } )
   Reporter( aReport,;
            "Stocktake listing by Department",;
            ,;                              // group by
            ,;                              // group header
            ,;                              // sub grp by
            ,;                              // sub grp header
            FALSE,;                         // Summary report
            "master->stocktake >0",;           // For cond
            ,; // While cond
            132 )                           // Page width
   ordsetfocus( BY_ID )
  endif
  dept->( dbclosearea() )
  select master

 case nMenuSelect = 9
  Heading('Print Data Entry Error Listing')
  mcost := 0.01
  msell := 200
  monhand := 10
  mmargin := 35
  mupmargin := 50
  Box_Save( 2,08,11,72 )
  Center( 3, 'Items which have a -' )
  @ 04,10 say 'Cost price less than        ' get mcost pict '9999.99'
  @ 05,10 say 'or a Sell Price greater than' get msell pict '9999.99'
  @ 06,10 say 'or Onhand greater than      ' get monhand pict '9999'
  @ 07,10 say 'or Margin is less than      ' get mmargin pict '99.9'
  @ 08,10 say 'or Margin is greater than   ' get mupmargin pict '99.9'
  @ 09,10 say 'and are onhand at the moment'
  read
  
  if Isready( 12 )
   Center( 10,'Processing - Please Wait' )
   select master
   ordsetfocus( BY_DEPARTMENT )
   go top
   // Pitch17()

   aReport := {}
   aadd(aReport,{'substr(desc, 1, 35)','Item Description', 30, 0, FALSE } )
   aadd(aReport,{'substr(alt_desc, 1, 25)','Alternate Desc', 25, 0, TRUE } )
   aadd(aReport,{'master->stocktake','Stocktake', 8, 0, TRUE } )
   aadd(aReport,{'master->onhand','Onhand', 7, 0, TRUE } )
   aadd(aReport,{'master->sell_price','Sell;Price', 10, 2, FALSE } )
   aadd(aReport,{'master->sell_price*master->onhand','Valuation;Sell Price', 12, 2, TRUE } )
   aadd(aReport,{'master->cost_price','Cost;Price', 10, 2, FALSE } )
   aadd(aReport,{'master->cost_price*master->onhand','Valuation;Cost Price', 12, 2, TRUE } )
//   aadd(aReport,{'100-Zero(master->cost_price,Zero(master->onhand->sell_price, 100))','Discount', 10, 2, FALSE } )

   sForCond = "master->onhand > 0 .and." + ;
              "( master->onhand>monhand.or.master->cost_price<mcost.or.master->sell_price>msell .or." + ;
              "100-Zero(master->cost_price,(master->sell_price/100))<mmargin .or." + ;
              "( Lookitup( 'supplier', 'supp_code', 'price_meth' ) = 'R'" + ;
              ".and. 100 - Zero( master->cost_price, ( master->sell_price/100 ) ) > mupmargin ) )"

   Reporter( aReport,;
            "Data Error Entry Listing",;
            ,;                              // group by
            ,;                              // group header
            ,;                              // sub grp by
            ,;                              // sub grp header
            FALSE,;                         // Summary report
            sForCond,;                      // For cond
            ,;                              // While cond
            132 )                           // Page width

   ordsetfocus( BY_ID )
   set relation to

  endif

 endcase
 return

enddo
return

*

procedure stfinal
local lAnswer, mdept, getlist:={}, mleg := FALSE


Heading('Stocktake Finalisation')
select master

if !Netuse( "master" , EXCLUSIVE , 1, NOALIAS, OLD ) // NEW
 Error('You MUST have exclusive use of the master file!!!',12)
else
 if !Sysinc( "FlagStk" , "G" )
  Error('You MUST do a stocktake first!!',12)
 else
  syscolor( C_BRIGHT )
  cls
  text

         BE ABSOLUTELY SURE YOU KNOW WHAT YOU ARE DOING HERE!!!!!

      This module will Finalise the stocktake. It will post all the
       stocktake quantities to the onhand quantities. Be sure that
      you have printed all your reports and have made any corrections
      to the stock that are required. If in any doubt do not procede.

   If you are performing a departmental stocktake then only the department
                   onhand quantities will be updated.

           Perform a system backup before you undertake this step.

  endtext
  syscolor( C_NORMAL )
  Heading('Stocktake Finalisation')
  if Isready(16)
   lAnswer := FALSE
   @ 18,10 say 'Again - Do you wish to continue (Y/N) ' get lAnswer pict 'y'
   read
   if lAnswer
    SysAudit("StkTakeFin")
    Center(20,'-=< Processing in Progress - Please wait >=-')
    if Sysinc("Stktype","G") == 'A'   // SYSREC->STKTYPE = 'A'
     replace all onhand with master->stocktake + master->approval

    else
     mdept := Sysinc("stkdept","G")
     replace all onhand with master->stocktake + master->approval ;
             for master->department = mdept

    endif
    Sysinc("flagstk","R",FALSE)        // Replace flag - End of Stocktake

   endif
  endif
 endif
endif
return

*

procedure chk_po
local mscr
if Secure( X_SYSUTILS )

Heading("Resync Master File Quantities")
 mscr := Box_Save( 2, 02, 12, 76 )
 Center( 03, "This Procedure will scan the Master, Special, Approval, Hold and Purchase Order files" )
 Center( 05, "It will resynchronise the master file quantities from this information" )
 if Isready( 06 )
  if Netuse( "hold", EXCLUSIVE )
   if Netuse( "approval", EXCLUSIVE )
    if Netuse( "special", EXCLUSIVE )
     if Netuse( "poline", EXCLUSIVE )
      if Netuse( "master", EXCLUSIVE )
       @ 07,10 say 'Reseting the Master File'
       replace all onorder with 0,;
                   special with 0,;
                   approval with 0,;
                   held with 0

       ordsetfocus( BY_ID )

       select special
       Highlight( 08, 10, 'Updating Special Orders', Ns( lastrec() ) )
       @ 08,45 say 'Record #'
       while !special->( eof() )
        @ 08,55 say recno()
        if master->( dbseek( padr( special->id, ID_ENQ_LEN ) ) )
         master->special += ( special->qty - special->delivered )
        endif
        special->( dbskip() )
       enddo

       select poline
       Highlight( 09,10,'Updating Po            ',Ns(lastrec()) )
       @ 09,45 say 'Record #'
       while !poline->( eof() )
        if master->( dbseek( padr( poline->id, ID_ENQ_LEN ) ) )
         master->onorder += poline->qty
        endif
        @ 09,55 say poline->( recno() )
        poline->( dbskip() )
       enddo
       select approval
       Highlight(10,10,'Updating Approval      ',Ns(lastrec()))
       @ 10,45 say 'Record #'
       while !approval->( eof() )
        if master->( dbseek( padr( approval->id, ID_ENQ_LEN ) ) )
         master->approval += ;
                 approval->qty-approval->received-approval->delivered
        endif
        @ 10,55 say approval->( recno() )
        approval->( dbskip() )
       enddo

       select hold
       Highlight(11,10,'Updating Hold ' + ITEM_DESC + '   ',Ns(lastrec()))
       @ 11,45 say 'Record #'
       while !hold->( eof() )
        @ 11,55 say hold->( recno() )
        if master->( dbseek( padr( hold->id, ID_ENQ_LEN )  ) )
         master->held += hold->qty
        endif
        hold->( dbskip() )
       enddo

      endif
     endif
    endif
   endif
  endif
  close databases
  Error("Procedure Finished",12)
 endif
 keyboard chr( K_ESC )
 Box_Restore( mscr )

endif
return

*

Func BrowSystem
local mscr, keypress:=0, mbrow, tscr, getlist:={}, mfilter
if Netuse( 'System' ) 
 if secure( X_SYSUTILS )
  mscr:=Box_Save( 2, 10, 21, 70 )
  mbrow:=TbrowseDb( 3, 11, 20, 69 )
  mbrow:headsep := HEADSEP
  mbrow:addcolumn(tbcolumnnew('Entry',{ || system->details } ) )
  while keypress != K_ESC .and. keypress != K_END
   mbrow:forcestable()
   keypress := inkey(0)
   if !Navigate( mbrow,keypress)
    if keypress == K_F3
     tscr := Box_Save( 3,0,5,40 )
     mfilter := space( 20 )
     @ 4, 1 say 'String to filter' get mfilter
     read
     if !updated()
      dbclearfilter()
     else
      mfilter := trim( mfilter )
      dbsetfilter( { || upper( system->details ) = upper( mfilter ) } )
      mbrow:refreshall()
     endif
     Box_Restore( tscr )
    endif
   endif
  enddo
  Box_Restore( mscr )
 endif
 use
endif
return nil

*

function SetupHold
local mscr := Box_Save( 2, 5, 7, 74 )
Center( 3, 'This Procedure will update Special Order / Hold values' )
Center( 4, 'Do not use it without advice from ' + DEVELOPER )
if Isready( 12 )
 if Secure( X_SYSUTILS )
  if Master_use()
   if NetUse( 'hold' )
    if NetUse( 'special' )
     Highlight( 5, 15, 'Records to Process', Ns( lastrec() ) )
     set relation to hold->id into hold,;
                  to padr( hold->id, ID_ENQ_LEN ) into master
     while !special->( eof() )
      if special->received - special->delivered > 0
       select hold
       locate for hold->number = special->number .and. hold->type = 'S' ;
              while hold->id = special->id
       if !found()
        Add_rec( 'hold' )
        hold->key := special->key
        hold->qty := special->received-special->delivered
        hold->date := Bvars( B_DATE )
        hold->id := special->id
        hold->type := 'S'
        hold->number := special->number
        Rec_lock( 'master' )
        master->held += special->received-special->delivered
        master->( dbrunlock() )
        hold->( dbrunlock() )
       endif
      endif
      skip alias special
      Highlight( 6, 15, 'Records Processed', Ns( special->(recno()) ) )
     enddo
    endif
   endif
  endif
 endif
endif
Box_Restore( mscr )
close databases
return nil
