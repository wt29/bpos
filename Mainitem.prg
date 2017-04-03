/*

  MainItem - Master File Item maintenance & Reports

      Last change:  TG   16 Jan 2011    6:40 pm
*/

Procedure f_Desc

#include "bpos.ch"

local mgo:=FALSE
local oldscr:=Box_Save()
local choice
local aArray

Center( 24, 'Opening files for Master File (Item) Maintenance' )

mgo := Master_use()

Line_clear(24)

while mgo
 Box_Restore( oldscr )
 Heading( 'Master File Maintenance Menu')
 aArray := {}
 aadd( aArray, { 'File', 'Return to file maintenance menu', nil, nil } )
 aadd( aArray, { 'Add', 'Add New Items', { || add_item() }, nil } )
 aadd( aArray, { 'Print', 'Print Item Details', { || ItemPrint() }, nil } )
 aadd( aArray, { 'Value', 'Stock Valuation', { || ItemValue() }, nil } )
 aadd( aArray, { 'Markdown', 'Markdown Stock', { || ItemMarkDown() }, nil } )
 aadd( aArray, { 'Catalogue', 'Catalogue Production System', { || Catalog() }, nil } )
 choice := MenuGen( aArray, 03, 02, 'Desc' )
 if choice < 2
  exit

 else
  eval( aArray[ choice, 3 ] )

 endif

enddo
close databases
return

*

procedure ItemPrint
local mprntype,choice,mscr,sAltDesc1,sAltDesc2,mchoice
local mcat, mcust, mimpr
local oldscr:=Box_Save(), sID, deptloop
local getlist:={}, supploop, sHeading
local firstpass, aArray, aCustomer, aDetail, sHead, sFor, sWhile

memvar mDept, mOh, mlen1, mlen2, msupp, mtitl, mtitl1, mtitl2, cutoff
public mDept, mOh, mlen1, mlen2, msupp, mtitl, mtitl1, mtitl2, cutoff

while TRUE
 Box_Restore( oldscr )

 Heading( ITEM_DESC + ' File Print Menu' )
 Print_find( 'report' )

 aArray := {}
 aadd( aArray, { 'Return', 'Return to Item file Maintainance' } )
 aadd( aArray, { 'Supplier', 'Items for nominated Supplier' } )
 aadd( aArray, { ALT_DESC, 'Item file by ' + ALT_DESC + ' order' } )
 aadd( aArray, { 'Description', 'Item file by Description order' } )
 aadd( aArray, { 'Category', 'Item file by Category and id' } )
 aadd( aArray, { 'Department', 'Print all Items in Nominated Dept' } )
 aadd( aArray, { BRAND_DESC, 'Print all Items on ' + BRAND_DESC } )
 aadd( aArray, { 'Zed Report', 'Prepare Adhoc Item listing' } )
 aadd( aArray, { 'Status', 'Print Item File by Status' } )

 choice := Menugen( aArray, 06, 03, 'Print')

 if choice > 1 .and. choice < 8
  mprntype := 'C'
  mcust := space(45)

  mscr := Box_Save( 02, 10, 05, 70 )
  @ 03,12 say '<C>ustomer or <D>etail Report' get mprntype pict '!' valid( mprntype $ 'CD' )
  read
  Box_Restore( mscr )

  if lastkey() = K_ESC
   exit

  else
   if mprntype = 'C'
    if CustFind( FALSE )
     mcust := customer->name

    endif

    mcust := trim(mcust)

    aCustomer := {}
    aadd( aCustomer, { 'idcheck(ID)', 'ID', 13, 0, FALSE } )
    aadd( aCustomer, { 'desc', 'Description', 35, 0, FALSE } )
    aadd( aCustomer, { 'alt_desc', 'Alternate;Description', 20, 0, FALSE } )
    aadd( aCustomer, { 'department', 'Dept', 4, 0, FALSE } )
    aadd( aCustomer, { 'Lookitup("brand", "brand")', 'Brand', 20, 0, FALSE } )
    aadd( aCustomer, { 'binding', 'Binding', 7, 0, FALSE } )
    aadd( aCustomer, { 'sell_price', 'Price', 7, 2, FALSE } )
    aadd( aCustomer, { 'onhand', 'In;Stock', 5, 0, FALSE } )

   else
    aDetail := {}
    aadd( aDetail, { 'idcheck(ID)', 'ID', ID_CODE_LEN + 1, 0, FALSE } )
    aadd( aDetail, { 'desc', 'Description', 35, 0, FALSE } )
    aadd( aDetail, { 'alt_desc', 'Alternate;Description', 20, 0, FALSE } )
    aadd( aDetail, { 'department', 'Dept;Code', DEPT_CODE_LEN + 2, 0, FALSE } )
    aadd( aDetail, { 'supp_code', 'Supp;Code', SUPP_CODE_LEN + 1, 0, FALSE } )
    aadd( aDetail, { 'cost_price', 'Cost;Price', 8, 2, FALSE } )
    aadd( aDetail, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aDetail, { 'sell_price', 'Price', 7, 2, FALSE } )
    aadd( aDetail, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aDetail, { 'onhand', 'In;Stock', 5, 0, TRUE } )
    aadd( aDetail, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aDetail, { 'onorder', 'On;Order', 5, 0, FALSE } )
    aadd( aDetail, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aDetail, { 'minstock', 'Min;Stock', 5, 0, FALSE } )
    aadd( aDetail, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aDetail, { '100-(cost_price/(sell_price/100))', 'Disc;Last', 5, 2, FALSE } )
   endif
  endif

 endif

 do case
 case choice = 2
  master->( ordsetfocus( BY_SUPPLIER ) )
  supploop:=TRUE
  while supploop
   msupp := space( SUPP_CODE_LEN )
   @ 08,13 say 'อออ> Supplier code' get msupp pict '@!' valid( dup_chk( msupp ,"supplier" ) )
   read
   moh := TRUE
   Box_Save( 11, 40, 13, 63 )
   @ 12,42 say 'Onhand ' + ITEM_DESC + ' only' get moh pict 'y'
   read

   if lastkey() == K_ESC
    supploop := FALSE

   else
    mscr:= Box_Save( 07, 10, 09, 70 )
    Center(08,'-=< About to print stock items for ' + trim( LookItUp( "supplier" , msupp ) ) + ' >=-')
    if Isready(10)
     if select('ytdsales') != 0     // DAC
      ytdsales -> ( dbclosearea() )

     endif
     if Netuse( 'Ytdsales', SHARED, 10, NOALIAS, NEW )
      select master
      set relation to master->id into ytdsales
      ordsetfocus( BY_SUPPLIER )
      seek msupp
      
      if mprntype = 'C'
       sHeading = 'Report for Customer - ' + mcust + ' Items with Primary Supplier ' + ;
            LookItup( 'supplier' , msupp ) + if( moh, ' Onhand Items Only','' )

       Reporter( aCustomer,;                                                    // Field Array
            sHeading ,;                                                         // Report Heading
            ,;                                                                  // Group By
            ,;                                                                  // Group Heading
            ,;                                                                  // Sub Group by
            ,;                                                                  // Sub Group Heading
            FALSE,;                                                             // Summary Report
            "if( moh, master->onhand > 0, .t. )",;                              // For Condition
            "master->supp_code = msupp",;                                       // While Condition
            132 )                                                               // approx Page width

      else
       sHeading = 'Detail report for Internal Use Items with Primary Supplier ' ;
              + LookItUp( 'supplier', msupp ) + if( moh, 'Onhand ' + ITEM_DESC + ' Only', ''  )
       Reporter( aDetail,;                                                      // Field Array
            sHeading,;                                                          // Report Heading
            ,;                                                                  // Group By
            ,;                                                                  // Group Heading
            ,;                                                                  // Sub Group by
            ,;                                                                  // Sub Group Heading
            FALSE,;                                                             // Summary Report
            ,;                                                                  // For Condition
            "if( moh, master->onhand > 0, .t. )",;                              // While Condition
            132 )                                                               // approx Page width

      endif
      select master
      set relation to
      ytdsales->( dbclosearea() )
      select master

     endif

    endif
    Box_Restore( mscr )

   endif

  enddo
  ordsetfocus( BY_ID )

 case choice = 3
  Box_Save( 03, 08, 12, 72 )
  Heading('Print Items on File by Alt Desc')
  sAltDesc1 := space( 10 )
  sAltDesc2 := space( 10 )
  mchoice := 'R'
  @ 05,10 say '<A>ll Alt' + ITEM_DESC + ' or <R>ange' get mchoice pict '!' valid( mchoice $ 'AR' )
  read
  if mchoice = 'R'
   @ 07,10 say 'Enter Alternate Description part to start ' get sAltDesc1 pict '@!'
   @ 09,10 say 'Enter Alternate Description part to end   ' get sAltDesc2 pict '@!'
   read

  endif
  if Isready(11)
   select Master
   ordsetfocus( BY_ALTDESC )
   if mchoice = 'R'
    sAltDesc1 := trim(sAltDesc1)
    sAltDesc2 := trim(sAltDesc2)
    dbseek( sAltDesc1, TRUE )
    if mprntype = 'C'
     sHeading =  'Report for Customer - ' + mCust + ';Alternate ' + ITEM_DESC + ' from ' + sAltDesc1 + ' to ' + sAltDesc2
     Reporter( aCustomer,;                                                      //Field Array
            sHeading,;                                                                  // Report Heading
            ,;                                                                  // Group By
            ,;                                                                  // Group Heading
            ,;                                                                  // Sub Group by
            ,;                                                                  // Sub Group Heading
            FALSE,;                                                             // Summary Report
            ,;                                                                       // For Condition
            "upper( substr( master->author, 1, len( sAltDesc1 ) ) ) <= sAltDesc2",; // While Condition                                // While Condition
            132 )                                                               // approx Page width

    else
     sHeading = 'Detail Report for Internal Use Alternate Descriptions from ' + sAltDesc1 + ' to ' + sAltDesc2
     Reporter( aDetail,;                                                        //Field Array
            sHeading ,;                                                         // Report Heading
            ,;                                                                  // Group By
            ,;                                                                  // Group Heading
            ,;                                                                  // Sub Group by
            ,;                                                                  // Sub Group Heading
            FALSE,;                                                             // Summary Report
            ,;                                                                       // For Condition
            "upper( substr( master->author,1,len( sAltDesc1 ) ) ) <= sAltDesc2",; // While Condition                                // While Condition
            132 )                                                               // approx Page width

    endif

   else
    master->( dbgotop() )
    if mprntype = 'C'
     sHeading = 'Report for Customer ' + mcust + ' Complete Item File by Alternate Description'
     Reporter( aCustomer,;                                                      //Field Array
            sHeading ,;                                                         // Report Heading
            ,;                                                                  // Group By
            ,;                                                                  // Group Heading
            ,;                                                                  // Sub Group by
            ,;                                                                  // Sub Group Heading
            FALSE,;                                                             // Summary Report
            ,;                                                                  // For Condition
            ,;                                                                  // While Condition
            132 )                                                               // approx Page width


    else
     Reporter( aDetail,;                                                          //Field Array
            "Detail Report for Internal Use Complete Item File by Alternate Description",;   // Report Heading
            ,;                                                                  // Group By
            ,;                                                                  // Group Heading
            ,;                                                                  // Sub Group by
            ,;                                                                  // Sub Group Heading
            FALSE,;                                                             // Summary Report
            ,;                                                                  // For Condition
            ,;                                                                  // While Condition
            132 )                                                               // approx Page width

    endif

   endif

   master->( ordsetfocus( BY_ID ) )

  endif

 case choice = 4
  Box_Save( 03, 08, 12, 72 )
  Heading( 'Print all Items by Description on Master File' )
  mtitl1 := space(10)
  mtitl2 := space(10)
  mchoice := 'R'
  @ 05,10 say '<A>ll Descriptions or <R>ange' get mchoice pict '!' valid( mchoice $ 'AR' )
  read
  if mchoice = 'R'
   @ 07,10 say 'Enter item description part to start ' get mtitl1 pict '@!'
   @ 09,10 say 'Enter item description part to end   ' get mtitl2 pict '@!'
   read

  endif

  if Isready(11)
   select Master
   ordsetfocus( BY_DESC )
   if mchoice = 'R'
    mtitl1 := trim( mtitl1 )
    mlen1 := len( mtitl1 )
    mtitl2 := trim( mtitl2 )
    mlen2 := len( mtitl2 )
    dbseek( mtitl1, TRUE )
    if mprntype = 'C'
     sHeading = 'Report for ' + mcust + ' List of ' + ITEM_DESC + ' ' + mtitl1 + ' to ' + mtitl2
     Reporter( aCustomer,;                                                          //Field Array
            sHeading ,;   // Report Heading
            ,;                                                                  // Group By
            ,;                                                                  // Group Heading
            ,;                                                                  // Sub Group by
            ,;                                                                  // Sub Group Heading
            FALSE,;                                                             // Summary Report
            ,;                                                                  // For Condition
            "upper(substr(master->desc,1,mlen2))<= mtitl2",;                     // While Condition
            132 )                                                               // approx Page width

    else
      sHeading = "Report for " + mcust + ' List of ' + ITEM_DESC + ' ' + mtitl1 + " to " + mtitl2
      Reporter( aCustomer,;                                                     //Field Array
            sHeading,;                                                          // Report Heading
            ,;                                                                  // Group By
            ,;                                                                  // Group Heading
            ,;                                                                  // Sub Group by
            ,;                                                                  // Sub Group Heading
            FALSE,;                                                             // Summary Report
            ,;                                                                  // For Condition
            "upper(substr(master->desc,1,mlen2))<= mtitl2",;                    // While Condition
            132 )                                                               // approx Page width

  
    endif

   else
    master->( dbgotop() )
    if mprntype = 'C'
     sHeading = 'Report for ' + mcust + ' Complete List of Stock Items'
     Reporter( aCustomer,;                                                      //Field Array
            sHeading,;                                                          // Report Heading
            ,;                                                                  // Group By
            ,;                                                                  // Group Heading
            ,;                                                                  // Sub Group by
            ,;                                                                  // Sub Group Heading
            FALSE,;                                                             // Summary Report
            ,;                                                                  // For Condition
            ,;                                                                  // While Condition
            132 )        
    else
     sHeading = 'Detail Report for Internal Use Complete List of Stock Items'
     Reporter( aDetail,;                                                        //Field Array
            sHeading ,;                                                         // Report Heading
            ,;                                                                  // Group By
            ,;                                                                  // Group Heading
            ,;                                                                  // Sub Group by
            ,;                                                                  // Sub Group Heading
            FALSE,;                                                             // Summary Report
            ,;                                                                  // For Condition
            ,;                                                                  // While Condition
            132 )        
    endif

   endif

  endif
  master->( ordsetfocus( BY_ID ) )

 case choice = 5
  Box_Save(3,08,15,72)
  Heading('Print Items on Master File by Category')
  if Netuse( "category", FALSE, 10, NOALIAS, NEW )
   if Netuse( "macatego", FALSE, 10, NOALIAS, NEW )
    set relation to macatego->id into master,;
                 to macatego->code into category
    mcat := space(6)
    moh := FALSE
    @ 07,10 say 'Enter Category code for print' get mcat pict '@!'
    Box_Save( 11,40,13,63 )
    @ 12,42 say 'Onhand ' + ITEM_DESC + ' only' get moh pict 'y'
    read
    if updated()
     mcat := trim(mcat)
     if !dbseek( mcat )
      Error( 'No match found for ' + mcat, 09 )

     else
      Highlight( 09, 10, 'First Item Found=>', left( master->desc, 42 ) )
      if Isready(11)
       seek mcat
       if mprntype = 'C'
        sHeading := "Report for " + mcust + " List of Items matching Category " + trim(Category->name)
        Reporter( aCustomer,;                                                   //Field Array
                  sHeading,;                                                    // Report Heading
                  ,;                                                            // Group By
                  ,;                                                            // Group Heading
                  ,;                                                            // Sub Group by
                  ,;                                                            // Sub Group Heading
                  FALSE,;                                                       // Summary Report
                  "if( moh, master->onhand > 0 , TRUE )",;                      // For Condition
                  "macatego->code = " + mcat ,;                                 // While Condition
                  132 )

       else
         sHeading = 'Detail Report for Internal Use List of Items matching Category ' + mCAT
         Reporter( aDetail,;                                                    //Field Array
                   sHeading,;                                              // Report Heading
                   ,;                                                      // Group By
                   ,;                                                      // Group Heading
                   ,;                                                      // Sub Group by
                   ,;                                                      // Sub Group Heading
                   FALSE,;                                                 // Summary Report
                   "if( moh, master->onhand > 0 , TRUE )",;                // For Condition
                   '"macatego->code = " +mcat' ,;                          // While Condition
                   132 )

       endif
      endif
     endif
    endif
   endif
   macatego->( dbclosearea() )
   category->( dbclosearea() )
  endif
  select master

 case choice = 6
  Heading('Print Master File by Department')

   ordsetfocus( BY_DEPARTMENT )
   deptloop := TRUE
   while deptloop
    mdept := space(3)
    moh := FALSE
    @ 12,17 say 'ออ> Department Code' get mdept pict '@!' valid( Dup_chk( mdept ,"dept" ) )
    Box_Save( 11,45,13,68 )
    @ 12,47 say 'Onhand Items only?' get moh pict 'y'
    read
    if moh
     cutoff := 1

    else
     cutoff := 0

    endif

    if lastkey() = K_ESC
     deptloop := FALSE

    else
     select master
     ordsetfocus( BY_DEPARTMENT )
     seek mdept
     shead = "List of Stock Items in Department " + trim( Lookitup( "dept" , mdept ) ) + ;
             if( moh, if(cutoff > 1,' Items with Onhand >= ' + alltrim(str(cutoff)),' Onhand ' + ITEM_DESC + ' only'), '' )

     sfor = if( moh, "master->onhand >= cutoff" , ".t." )
     sWhile = 'master->department = mdept'

     if mprntype = 'C'
      Reporter( aCustomer,;               // Field Array
                sHead ,;                      // Report Heading
                ,;                            // Group By
                ,;                            // Group Heading
                ,;                            // Sub Group by
                ,;                            // Sub Group Heading
                FALSE,;                       // Summary Report
                sFor,;                        // For Condition
                sWhile,;                      // While Condition
                132 )

     else
       Reporter( aDetail,;                      // Field Array
                sHead ,;                      // Report Heading
                ,;                            // Group By
                ,;                            // Group Heading
                ,;                            // Sub Group by
                ,;                            // Sub Group Heading
                FALSE,;                       // Summary Report
                sFor,;                        // For Condition
                sWhile,;                      // While Condition
                132 )

     endif

    endif

   enddo
   Box_Restore( mscr )
   master->( ordsetfocus( 'id' ) )

 case choice = 7
  Heading( "Print all Stock Items on " + BRAND_DESC )
  mscr := Box_Save( 2,10,08,70 )
  Center( 3, 'This procedure will require an index of the master file' )
  if Isready(12)
   select master
   Center( 5,'-=< Reindexing Master file - Please Wait > ' )
   indx( "brand + desc", 'brand' )

   while TRUE
    mimpr := space(6)
    @ 13, 13 say 'ออ> '+BRAND_DESC+' Code' get mimpr pict '@!' ;
             valid( Dup_chk( mimpr, "brand" ) )
    read
    if !updated()
     exit

    else
     seek mimpr
     Center( 7 , 'Printing Items for ' + Lookitup( "brand" , mimpr ) )
     sFor := "master->brand=" + mimpr
     shead := "List of Stock Items matching " + BRAND_DESC + " Lookitup( 'brand' ," + mimpr + " )"

     if mprntype == 'C'
      Reporter( aCustomer,;                      // Field Array
                "Report for " + mcust + sHead ,;                      // Report Heading
                ,;                            // Group By
                ,;                            // Group Heading
                ,;                            // Sub Group by
                ,;                            // Sub Group Heading
                FALSE,;                       // Summary Report
                sFor,;                        // For Condition
                ,;    // While Condition
                132 )


     else
      Reporter( aDetail,;                                             // Field Array
                "Detail Report for Internal Use " + sHead ,;         // Report Heading
                ,;                                                   // Group By
                ,;                                                   // Group Heading
                ,;                                                    // Sub Group by
                ,;                                                  // Sub Group Heading
                FALSE,;                                             // Summary Report
                sFor,;                                              // For Condition
                ,;    // While Condition
                132 )

     endif

    endif

   enddo
   master->( orddestroy( 'brand' ) )
   master->( ordsetfocus( 'id' ) )

  endif

 case choice = 8
  Heading("Print Special Items Listing")
  Print_find( 'Report' )
  
  firstpass := TRUE
  while TRUE
   sID := space(13)
   @ 15,14 say 'อออ>Enter Code/id' get sID pict '@!'
   read
   if !updated()
    exit
   else
    if !Codefind( sID )
     Error( "Code not on File",12 )
    else
     if firstpass
      Sphead()
     endif
     set device to print
     @ prow()+2,01 say substr( master->desc, 1, 40 )
     @ prow(),  42 say substr( master->alt_desc, 1, 30 )
     @ prow(),  72 say master->sell_price pict '9999.99'
     set device to screen
     firstpass := FALSE
     if prow() > 60
      eject
      Sphead()
     endif
    endif
   endif
  enddo

  if !firstpass .and. prow() > 7
   endprint()

  endif

 case choice = 09
  Status_Print()

 case choice < 2
  ordsetfocus( BY_ID )
  exit

 endcase

enddo
return

*

procedure Status_Print()
local getlist:={}, farr
memvar stat
private stat := space(3)

Box_Save(05,08,9,33)
Heading('Print Items on File by Status')
@ 07,10 say 'Enter Status Code ' get stat pict '@!' ;
        valid ( empty( stat ) .or. dup_chk( stat, 'status') )
read
if Isready(11)
 select Master
 master->( dbgotop() )
 
 farr := {}
 aadd( farr,{'idcheck(master->id)','id',13,0,FALSE})
 aadd( farr,{'substr(master->desc,1,30)','Desc',30,0,FALSE})
 aadd( farr,{'substr(master->alt_desc,1,15)','Author',15,0,FALSE})
 aadd( farr,{'master->status','Status',6,0,FALSE})
 aadd( farr,{'substr(lookitup("brand", master->brand),1,12)','Brand',12,0,FALSE})
 aadd( farr,{'master->supp_code','Prim;Supp',SUPP_CODE_LEN,0,FALSE})
 aadd( farr,{'master->department','Dept',4,0,FALSE})
 aadd( farr,{'master->binding','Bind',4,0,FALSE})
 aadd( farr,{'master->cost_price','Invoice;Cost',7,2,FALSE})
 aadd( farr,{'master->sell_price','Sell;Price',7,2,FALSE})
 aadd( farr,{'master->onhand','On;Hand',5,0,FALSE})
 
 Reporter(farr,'"Report Of Items With Status ("+stat+")"','','','','',FALSE,;
           "(master->status == stat) .and. master->onhand > 0")
 
 ordsetfocus( BY_ID )

endif
return

*

procedure Illust_Print()
local getlist:={}, farr:={}
memvar illus
private illus := space(20)
Box_Save(05,08,9,50)
Heading('Print ' + ITEM_DESC + ' on File by Illustrator')
@ 07,10 say 'Enter Illustrator ' get illus pict '@!'
read
if Isready(11)
 select Master
 ordsetfocus( BY_DESC )
 master -> ( dbgotop() )
 
 aadd(farr,{'master->desc','Desc',40,0,FALSE})
 aadd(farr,{'master->alt_desc','Author',20,0,FALSE})
 aadd(farr,{'master->sell_price','Price',7,2,FALSE})
 
 Reporter(farr,'"List Of ' + ITEM_DESC + ' For Illustrator "+"( "+alltrim(illus)+" )"',;
 '','','','',FALSE,"master->illustrat = alltrim(illus)",,96)
 
 ordsetfocus( BY_ID )

endif
return 

*

procedure ItemValue
local mdep,msupp,msell,mcost,msum,mavg,monhand,mrrp,choice,mscr, getlist:={}
local deptchoice,oldscr:=Box_Save(), mapp, mdbf, mappcost, aArray, aReport
memvar totcost    // used in reports
field onhand, sell_price, cost_price, retail, avr_cost, approval, supp_code, department
while TRUE
 Box_Restore( oldscr )
 Heading('Stock Valuation')

 aArray := {}
 aadd( aArray, { 'Return', 'Return to Desc file Menu' } )
 aadd( aArray, { 'All', 'Value all Stock on Hand' } )
 aadd( aArray, { 'Department', 'Value Stock in a Department' } )
 aadd( aArray, { 'Supplier', 'Value Stock for a Supplier' } )
 choice := menugen( aArray, 07, 03, 'Value' )

 if choice < 2
  return

 else
  mdep := space(3)
  msupp := space( SUPP_CODE_LEN )
  do case
  case choice = 3

   aArray := {}
   aadd( aArray, { 'Department', 'Return to Valuation Menu' } )
   aadd( aArray, { 'All', 'Value all Stock by Dept to printer' } )
   aadd( aArray, { 'Single', 'Value Stock in a Department to screen' } )
   deptchoice := MenuGen( aArray, 10, 04, 'Department')

   if deptchoice < 2
    loop

   elseif deptchoice = 3
    @ 13,15 say 'อออฏ' get mdep pict '@!'
    read

   elseif deptchoice = 2
    if Netuse("dept",FALSE,10, NOALIAS, NEW )
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
      Netuse( Oddvars( TEMPFILE ), EXCLUSIVE , 10 , "total", NEW )
      select master
      ordsetfocus( BY_DEPARTMENT )
      go top
      mdep := department
      totcost := 0
      while !master->( eof() )
       mscr := Box_Save( 2, 20, 4, 60 )
       Center( 3,'Processing Dept ' + mdep )
       sum sell_price*onhand,cost_price*onhand,if(onhand > 0,1,0),;
           avr_cost*onhand,onhand,retail*onhand,approval*onhand;
           to msell,mcost,msum,mavg,monhand,mrrp,mapp;
           while department = mdep .and. Pinwheel( NOINTERUPT )
       select total
       Add_rec()
       replace department with mdep,;
               onhand with monhand,;
               sum with msum,;
               cost with mcost,;
               average with mavg,;
               sell with msell,;
               retail with mrrp,;
               approval with mapp

       select master
       mdep := department
       totcost += mcost

      enddo
      Box_Restore( mscr )
      select total
      go top
      set relation to department into dept
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

    endif
    set relation to
    dept->( dbclosearea() )
    select master
    loop
   endif

  case choice = 4
   @ 11,15 say 'อออฏ' get msupp pict '@!'
   read

  endcase

  if Isready(14)
   select master
   if choice = 3
    Center(16,'-=< Calculating - Please Wait >=-')
    ordsetfocus( BY_DEPARTMENT )
    seek mdep
    sum sell_price*onhand,cost_price*onhand,if(onhand > 0,1,0),;
        avr_cost*onhand,onhand,retail*onhand,sell_price*approval,cost_price*approval;
        to msell,mcost,msum,mavg,monhand,mrrp,mapp,mappcost;
        while department = mdep .and. rectach()

   else
    Center(16,'-=< Scanning '+Ns(lastrec())+ ' Records - Please Wait >=-')
    ordsetfocus()
    master->( dbgotop() )
    if choice = 4
     sum sell_price*onhand,cost_price*onhand,if(onhand > 0,1,0),;
         avr_cost*onhand,onhand,retail*onhand,sell_price*approval,cost_price*approval;
         to msell,mcost,msum,mavg,monhand,mrrp,mapp,mappcost;
         for supp_code = msupp while Rectach()

    else
     sum sell_price*onhand,cost_price*onhand,if(onhand > 0,1,0),;
         avr_cost*onhand,onhand,retail*onhand,sell_price*approval,cost_price*approval;
         to msell,mcost,msum,mavg,monhand,mrrp,mapp,mappcost while Rectach()

    endif

   endif

   Box_Save(2,08,20,72)
   if choice = 3
    Heading('Stock Valuation for Department ' + mdep)

   else
    Heading('Stock Valuation')

   endif
   Highlight( 03, 10, '  Number of Stock Lines Onhand ', Ns( msum, 9 ) )
   Highlight( 05, 10, '       Number of Items Counted ', Ns( monhand, 9 ) )
   Highlight( 07, 10, '     Stock Value at Last Cost $', Ns( mcost, 10, 2 ) )
   Highlight( 09, 10, '     Stock Value at Avr. Cost $', Ns( mavg, 10, 2 ) )
   Highlight( 11, 10, '    Stock Value at Sell Price $', Ns( msell, 10, 2 ) )
   Highlight( 13, 10, '        Stock Value at R.R.P. $', Ns( mrrp, 10, 2 ) )
   Highlight( 15, 10, '       Approval Value at Sell $', Ns( mapp, 10, 2 ) )
   Highlight( 17, 10, '       Approval Value at Cost $', Ns( mappcost, 10, 2 ) )
   Highlight( 19, 10, 'Average price of Items onhand $', Ns( Zero( msell, monhand ), 10, 2 ) )
   Isready(21)

  endif
  ordsetfocus( BY_ID )

 endif

enddo
return

*

procedure ItemMarkDown
local mtotdep:=0,mdept:=space(3), mretail, mprice, sID, getlist:={}
local page_no:=1, aArray := {}, farr
Heading('Stock Markdown')
if Isready(10)
 aadd( aArray, { 'id', 'c', ID_CODE_LEN, 0 } )
 aadd( aArray, { 'qty', 'n', 5, 0 } )
 aadd( aArray, { 'new_price', 'n', 10, 2 } )
 aadd( aArray, { 'old_price', 'n', 10, 2 } )
 dbcreate( Oddvars( TEMPFILE ), aArray )

 if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, 'markdown' )
  set relation to markdown->id into master

  Box_Save( 2, 08, 4, 72 )
  @ 3,10 say 'Enter new department for items marked down';
         get mdept pict '@!' valid( dup_chk( mdept , "dept" ) )
  read
  while TRUE

   Box_Save( 02, 03, 22, 78 )
   sID := space( ID_ENQ_LEN )
   @ 3,10 say 'Scan Code or Enter ' + ID_DESC get sID pict '@!'
   read

   if !updated()

    if markdown->( lastrec() ) > 0 .and. Isready( 12, 10, 'Completed?' )

     if Isready( 14, 12, 'Post Markdowns entered' )
      markdown->( dbgotop() )
      while !markdown->( eof() )

       if !master->( eof() )

        Rec_lock( 'master' )
        master->sell_price := markdown->new_price

        if !empty(mdept)
         master->department := mdept

        endif

        master->( dbrunlock() )
       endif

       markdown->( dbskip() )

      enddo

      select markdown
      dbgotop()

      Print_find( 'report' )
      
      farr := {}
      aadd( farr, { 'master->desc', 'Desc', 40, 0, FALSE } )
      aadd( farr, { 'master->alt_desc', 'Author', 20, 0, FALSE } )
      aadd( farr, { 'markdown->qty', 'Qty', 4, 0, FALSE } )
      aadd( farr, { 'markdown->old_price', 'Old;Price', 7, 2, FALSE } )
      aadd( farr, { 'markdown->new_price', 'New;Price', 7, 2, FALSE } )
      aadd( farr, { '(markdown->old_price - markdown->new_price) * markdown->qty','Markdown;Value', 9, 2, TRUE } )
 
      Reporter( farr, "Markdown SysAudit Report", '', '', '', '', FALSE, , , 96 )

     endif

    endif

   else

    if !Codefind( sID )
     Error( 'Code (id) not on file', 12 )

    else
     Highlight( 05, 05, '        Desc', master->desc )
     Highlight( 07, 05, '      Author', master->alt_desc )
     Highlight( 09, 05, ' Qty On-hand', Ns( master->onhand ) )
     Highlight( 11, 05, 'Last Invoice', dtoc( master->dlastrecv ) )
     Highlight( 13, 05, '  Sell Price', Ns( master->sell_price, 8, 2 ) )
     Highlight( 15, 05, '  Cost Price', Ns( master->cost_price, 8, 2 ) )
     mprice := if( master->retail = 0, master->sell_price, master->retail ) / 2
     mretail := if( master->retail = 0, master->sell_price, master->retail ) / 2
     @ 17,05 say 'New Sell Price' get mprice pict '9999.99'
     read

     if lastkey() != K_ESC

      Add_rec( 'markdown' )
      markdown->id := master->id
      markdown->qty := master->onhand
      markdown->old_price := master->sell_price
      markdown->new_price := mprice
      markdown->( dbrunlock() )

     endif
    endif
   endif
  enddo
  markdown->( dbclosearea() )
 endif
endif
return

*

Function Catalog
local marr:={}, choice, aArray:={}

Heading('Catalog Production Menu')
aadd( aArray, { 'Item', 'Return to Item Maintenance Menu', nil, nil } )
aadd( aArray, { 'Bestseller',  'Bestsellers listing based on monthly or yearly sales', { || Bestlist() }, nil } )
aadd( aArray, { 'Catalog', 'Produce Catalog listing using specific category or every desc',{ || Catalog_it( FALSE ) }, nil } )
choice := MenuGen( aArray, 09, 03, 'Catalog' )

if choice >= 2
 eval( aArray[ choice, 3 ] )

endif
return nil

*

procedure bestlist
local mastlen := istrunc()
local monthname := space( 3 ), break_here, break_code, line_to_print
local cutoff := 5, getlist := {}, with_it, mfile, idtemp, adbf:={}

Heading('Best Sellers Listing by Department')
Box_Save( 7,21,10,58)
@ 08,23 say 'Enter month for analysis(*)' get monthname pict '@!' ;
        valid( ( monthname $ 'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC*  ' )  )
@ 09,23 say '   Enter cutoff quantity' get cutoff pict '999'
@ 24,13 say '    Enter Month name or * for all months combined    '
read
if !updated()
 return

endif

with_it := TRUE
Box_Save( 12, 31, 14, 50 )
@ 13,33 say 'Include ' + ID_DESC+'?' get with_it pict 'Y'
read

if len(trim(monthname)) > 0 .and. cutoff >=1
 @ 24,14 say padc('Creating Temporary files',50)
 aadd( adbf, {"id","c",10,0})
 aadd( adbf, {"desc","c",mastlen,0})
 aadd( adbf, {"alt_desc","c",20,0})
 aadd( adbf, {"sell_price","n",7,2})
 aadd( adbf, {"department","c",20,0})
 aadd( adbf, {"binding","c",3,0})
 dbcreate ( Oddvars( TEMPFILE2 ), adbf )
 if select( 'ytdsales' ) != 0
  ytdsales->( dbclosearea() )
 endif 
 if Netuse( 'ytdsales', SHARED, 10, NOALIAS, NEW )
  if monthname = '*'
   copy all to ( Oddvars( TEMPFILE ) ) for ytdsales->JAN+ytdsales->FEB+ytdsales->MAR;
      +ytdsales->APR+ytdsales->MAY+ytdsales->JUN+ytdsales->JUL+ytdsales->AUG+;
       ytdsales->SEP+ytdsales->OCT+ytdsales->NOV+ytdsales->DEC >= cutoff

  else
   copy all to ( Oddvars( TEMPFILE ) ) for fieldget( fieldpos( monthname) ) >= cutoff

  endif
  ytdsales->( dbclosearea() )

 endif

else
 return

endif

if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, 'tempfile', NEW )
 if Netuse( Oddvars( TEMPFILE2 ), EXCLUSIVE, 10, 'tempfile2', NEW )
  Box_Save(12,10,14,70)
  @ 13,11 say 'Desc Selected : '
  tempfile->( dbgotop())
  while !tempfile->( eof() )
   idtemp := trim( tempfile->id )
   select master
   seek idtemp
   if master->( dbseek( idtemp ) )
    Add_rec( 'tempfile2' )
    tempfile2->id := idcheck( idtemp )
    tempfile2->desc := lower_it( master->desc )
    tempfile2->alt_desc := master->alt_desc
    tempfile2->sell_price := master->sell_price
    tempfile2->binding := padl(master->binding,3)
    tempfile2->department := Lookitup( 'dept', master->department )
    @ 13,28 say left( tempfile2->desc, 39 )
    tempfile->( dbdelete() )

   endif
   skip alias tempfile

  enddo
  select tempfile2
  Box_Save( 18, 55, 20, 70 )
  @ 19, 57 say 'Indexing'
  indx( "upper( department + alt_desc + desc)", 'dept' )
  @ 19, 57 say str( lastrec(), 5, 0 ) + ' listed'
  Box_Save(18,10,20,40)
  @ 19,11 say Oddvars( SYSPATH ) + 'BESTLIST.TXT Created'
  mfile := Oddvars( SYSPATH ) + 'bestlist.txt'
  set printer to ( mfile )
  set printer on
  set console off
  break_here := TRUE
  tempfile2->( dbgotop() )
  while !tempfile2->( eof() )
   break_code := tempfile2->department
   line_to_print :=''
   if break_here
    line_to_print := 'Department : ' + tempfile2->department
    ? line_to_print
    line_to_print := ''

   endif
   break_here := FALSE
   if with_it
    line_to_print += tempfile2->id + '.....' + tempfile2->desc

   else
    line_to_print += tempfile2->desc

   endif
   line_to_print += ' ' + tempfile2->alt_desc + ' ' + tempfile2->binding
   line_to_print += ' ' + ( if( is_value( tempfile2->sell_price ), ;
                    str( tempfile2->sell_price, 7, 2 ), '') )
   ? line_to_print
   skip alias tempfile2
   if break_code != tempfile2->department
    break_here := TRUE
    ?
   endif

  enddo
  set printer off
  set console on
  @ 19,11 say Oddvars( SYSPATH )+'Bestlist.txt Written'
  Error( 'Procedure Completed', 21 )

 endif

endif
tempfile->( dbclosearea() )
tempfile2->( dbclosearea() )
return

*

procedure catalog_it ( schoolfile )
#define TAB chr(9)
local codetemp := space( 6 ), adbf := {}, mastlen := istrunc(), getlist := {}
local tempfile2 := '__' + padl( sysinc( 'file' ,'I', 1 ), 7 ,'0' ) 
local authortemp, line_to_print, with_it, mfile, abstract, break_here
local with_dept, idtemp, break_code, mscr2, mscr, authorref
Heading('Catalog Generator')
@ 12, 16 say 'อออ> Category to catalogue on (*)' get codetemp pict '@K!!!!!!';
        valid( codetemp = '*' .or. Dup_Chk( codetemp, 'category' ) )
read

if updated()
 with_it := TRUE
 with_dept := FALSE
 authorref := FALSE
 mscr := Box_Save( 14, 25, 18, 65 )
 @ 15,26 say 'Include ' + ID_DESC + '?' get with_it pict 'y'
 @ 16,26 say 'Sorted by Department ?' get with_dept pict 'y'
 @ 17,26 say 'Produce Author Cross Reference ?' get authorref pict 'y'
 read
 Box_Restore( mscr )

 if lastkey() != K_ESC
  aadd( adbf, {"id","C",12,0})
  aadd( adbf, {"desc","C",mastlen,0})
  aadd( adbf, {"alt_desc","C",20,0})
  aadd( adbf, {"department","C",20,0})
  aadd( adbf, {"sell_price","N",10,2})
  aadd( adbf, {"binding","C",3,0})
  aadd( adbf, {'brand','C',20,0})
  aadd( adbf, {'category','C',20,0})
  dbcreate( Oddvars( TEMPFILE ), adbf )
  if codetemp != '*'
   if Netuse( 'macatego', SHARED, 10, NOALIAS, NEW )
    if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, 'tempfile', NEW )
     master->( ordsetfocus( BY_ID ) )
     if macatego->( dbseek( codetemp ) )
      Box_Save (14,10,16,70)
      @ 15,12 say 'Desc Selected : '
      while macatego->code = codetemp .and. Pinwheel( NOINTERUPT )
       if master->( dbseek( macatego->id ) )
        Add_rec( 'tempfile' )
        tempfile->id := idcheck( master->id ) 
        tempfile->desc := lower_it( master->desc )
        tempfile->alt_desc := master->alt_desc
        tempfile->sell_price := master->sell_price
        tempfile->binding := padr(master->binding,3)
        tempfile->department := LookItup( 'dept', master->department )
        tempfile->brand := LookItup( 'brand', master->brand )
        @ 15,30 say left( tempfile->desc,39 )

       endif

       macatego->( dbskip() )

      enddo
     endif
     tempfile->( dbclosearea() )

    endif
    macatego->( dbclosearea() )

   endif

  else
   mscr2 := Box_Save(0,0,24,79)
   Box_Save(12,20,14,61)
   @ 13,22 say 'This procedure will take quite a while'
   Tone( 500, 5 )
   if Isready(16)
    if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, 'tempfile', NEW )
     master->( ordsetfocus( BY_DESC ) )
     Box_Save( 14, 10, 16, 70 )
     @ 15,12 say 'Desc Selected : '
     master->( ordsetfocus( BY_DESC ) )
     master->( dbgotop() )
     while !master->( eof() ) .and. Pinwheel( NOINTERUPT )
      Add_rec( 'tempfile' )
      tempfile->id := idcheck( master->id )
      tempfile->desc := master->desc
      tempfile->desc := lower_it( master->desc )
      tempfile->alt_desc := master->alt_desc
      tempfile->sell_price := master->sell_price
      tempfile->binding := padr(master->binding,3)
      tempfile->department := LookItUp( 'dept', master->department )
      
      @ 15,30 say left( master->desc, 39 )
      skip alias master

     enddo

    else
     return

    endif
    tempfile->( dbclosearea() )

   endif

  endif
  if file( Oddvars( TEMPFILE ) + '.dbf' )
   if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, 'tempfile', NEW )
    select master
    ordsetfocus( BY_ID )
#ifndef __HARBOUR__
    V_select(1)
    V_use(Oddvars( SYSPATH )+'master')
#endif
    select tempfile
    Box_Save(18,55,20,70)
    @ 19, 57 say str( lastrec(),5,0 ) + ' listed'
    if with_dept
     indx( "upper( department + desc )", 'brand' )
    else
     indx ( "upper( desc )", 'desc' )
    endif
    indx( "upper( alt_desc + desc )", 'alt_desc' )
    mfile := Oddvars( SYSPATH ) + 'catalog.txt'
    set printer to ( mfile )
    set printer on
    set console off
    Box_Save(18,10,20,42)
    @ 19,12 say mfile + ' Created'
    set index to ( Oddvars( TEMPFILE ) )
    break_here := TRUE
    tempfile->( dbgotop() )
    if schoolfile
     while !tempfile->( eof() ) .and. Pinwheel( NOINTERUPT )
      ? tempfile->desc+TAB+'$'+Ns( tempfile->sell_price, 8, 2 )+TAB+;
        tempfile->binding+TAB+tempfile->id
      skip alias tempfile
     enddo
    else
     while !tempfile->( eof() ) .and. pinwheel( NOINTERUPT )
      if( !with_dept, break_here := FALSE, nil )
      break_code := tempfile->department
      line_to_print := ''
      if break_here
       ?
       ? 'Department : '
       ?? tempfile->department
      endif
      break_here := FALSE
      if with_it
       line_to_print := tempfile->id + ' ' + tempfile->desc + ' '
      else
       line_to_print := tempfile->desc + ' '
      endif
      idtemp := '978' + trim( tempfile->id)
      line_to_print += tempfile->alt_desc + ' ' + tempfile->binding
      line_to_print += ' ' + ( if( is_value( tempfile->sell_price ),;
                   str( tempfile->sell_price, 7, 2 ), space( 10 ) ) )
      ? line_to_print
      if master->( dbseek( idtemp ) )
#ifndef __HARBOUR__
       abstract := v_retrieve(master->abs_ptr)
#endif
       if len(trim(abstract)) > 0
        abstract := change_ret(abstract)
        ? trim(abstract)
        ?
       endif
      endif
      skip alias tempfile
      if( break_code != tempfile->department .and. with_dept , break_here := TRUE, nil)

     enddo
     if authorref
      ? chr(12)
      ? '                               Cross reference by Author'
      ?
      ?
      set index to ( tempfile2 )
      tempfile->( dbgotop() )
      authortemp := tempfile->alt_desc
      ? tempfile->alt_desc
      while !tempfile->( eof() ) .and. Pinwheel( NOINTERUPT )
       line_to_print := tempfile->desc + ' '
       if with_it
        line_to_print += tempfile->id + ' '
       endif
       line_to_print += tempfile->binding + ' ' + ;
            ( if( is_value(tempfile->sell_price),str(tempfile->sell_price,7,2),''))
       ? line_to_print
       skip alias tempfile
       if tempfile->alt_desc != authortemp
        authortemp := tempfile->alt_desc
        ?
        ? tempfile->alt_desc
       endif
      enddo
     endif
    endif
    set printer off
    set device to screen
    set console on
#ifndef __HARBOUR__
    V_close()
#endif
    Print_find( 'report' )
    @ 19,12 say mfile + ' Written'
    Error( 'Procedure Complete', 20 )
    tempfile->( dbclosearea() )
   endif
  endif
 endif
endif
return

*

function centre_left( this_line )
return ( 40-len(trim(this_line))/2 )

*

function change_ret(abs_line)
local search := chr(13)+chr(10)
local temp := strtran(abs_line, search, " ", )
return ( strtran(temp, '', "", ) )

*

function lower_it(this_line)
local isitup := TRUE, new_line :=''
local search := " .,-/\( )&:'" , i, thislet
for i = 1 to len(trim(this_line))
 if isitup
  thislet := upper(substr(this_line,i,1))
 else
  thislet := lower(substr(this_line,i,1))
 endif
 new_line += thislet
 if at(thislet,search)>=1
  isitup := TRUE
 else
  isitup := FALSE
 endif
next
return new_line

*

function istrunc()
local trunclen := FALSE, mscr, getlist:={}
local mast_len := if( len( master->desc ) < 40, 40, len( master->desc ) )
if mast_len > 40
 mscr := Box_Save( 7, 17, 11, 62 )
 @ 08,19 say 'Your master file description length is ' + Ns( mast_len, 2 )
 @ 09,19 say 'The default length for this list is 40.'
 @ 10,19 say 'Do you wish to truncate the length to 40' get trunclen pict 'Y'
 read
 mast_len := if( trunclen , 40, mast_len )
 Box_Restore( mscr )
endif
return mast_len

*

function is_value(price)
return ( price > 0 )

*

proc sphead
set device to print
@ prow(),00 say padc( trim( trim( BVars( B_NAME ) ) ) + ' Special Desc List', 80 )
@ prow()+2,02 say 'Desc'
@ prow(),  43 say 'Author'
@ prow(),  74 say 'Price'
@ prow()+1,0  say replicate(chr(196),80)
set device to screen
return
