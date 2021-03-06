/*

 Procedure Utilarch - Archive old unused ' + ITEM_DESC + '

 Last change:  TG   25 Feb 2011    1:47 pm

 */

Procedure U_Archive

#include "bpos.ch"

local lIgnoreMinStock := FALSE
local mrecsarch := 0
local x                                 // Array Ordinal
local mfpos                             // Field Position
local aMenu, nMenu, getlist:={}, aReport, sHeading, sForCOnd

memvar dLastSale, dLastReceived, dEntered, nMinStock
public dLastSale, dLastReceived, dEntered, nMinStock

dLastSale := Bvars( B_DATE )-365
dLastReceived := Bvars( B_DATE )-365
dEntered := Bvars( B_DATE )-365
nMinStock := 0

Heading( 'Archive Master file Items' )
Center( 24, 'Opening files for Archive Maintenance' )
if Netuse( Oddvars( SYSPATH ) + "archive\archive", EXCLUSIVE )
 ordsetfocus( 'id' )
 Line_clear( 24 )
 Box_Save( 2, 02, 10, 78 )
 @ 3,07 say 'This option will Archive items from the master file into the'
 @ 4,07 say ' "Archive" Database - ' + SYSNAME + ' will prompt for selection criteria'
 @ 5,07 say 'You will be prompted to print or execute the results'
 if Isready( 8 )
  Box_Save( 02, 02, 22, 78 )
  @ 3,10 say '   Date of last sale' get dLastSale
  @ 4,10 say 'Date of last invoice' get dLastReceived
  @ 5,10 say '  Date of item entry' get dEntered
  @ 6,10 say 'Ignore minimum stock' get lIgnoreMinStock pict 'Y'
  read
  @ 08,10 say 'You are about to archive all ' + ITEM_DESC + ' which have -'
  @ 09,10 say '- No Onhand Stock'
  @ 10,10 say '- None on Order'
  @ 11,10 say '- None marked for Special Order'
  if lIgnoreMinStock
   @ 12,10 say '- Not been Sold since ' + dtoc( dLastSale )
   @ 13,10 say '- Not been Received since ' + dtoc( dLastReceived )
   @ 14,10 say '- Been added to ' + SYSNAME + ' before ' + dtoc( dEntered )
   nMinStock := 1000000  // A stupidly large number

  else
   @ 12,10 say '- A Minimum Stock of 0'
   @ 13,10 say '- Not been Sold since ' + dtoc( dLastSale )
   @ 14,10 say '- Not been Received since ' + dtoc( dLastReceived )
   @ 15,10 say '- Been added to ' + SYSNAME + ' before ' + dtoc( dEntered )

  endif
  Heading( 'Select Operation' )
  aMenu := {}
  aadd( aMenu, { 'Print  ', '' } )
  aadd( aMenu, { 'Execute', '' } )
  aadd( aMenu, { 'Quit   ', '' } )
  nMenu := MenuGen( aMenu, 18, 5 )
  do case
  case nMenu = 1  // Print
   if Netuse( "master" )
    Print_find( 'report' )
    aReport := {}
    aadd( aReport, { 'idcheck(ID)', 'ID', ID_CODE_LEN + 1, 0, FALSE } )
//    aadd( aReport, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aReport, { 'desc', 'Description', 35, 0, FALSE } )
//    aadd( aReport, { 'alt_desc', 'Alternate;Description', 20, 0, FALSE } )
    aadd( aReport, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aReport, { 'department', 'Dept', 4, 0, FALSE } )
    aadd( aReport, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aReport, { 'Lookitup("brand", "brand")', 'Brand', 10, 0, FALSE } )
//    aadd( aReport, { 'binding', 'Binding', 7, 0, FALSE } )
    aadd( aReport, { 'sell_price', 'Price', 7, 2, FALSE } )
    aadd( aReport, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aReport, { 'onhand', 'In;Stock', 5, 0, FALSE } )
    aadd( aReport, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aReport, { 'dsale', 'Last;Sold', 8, 0, FALSE } )
    aadd( aReport, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aReport, { 'entered', 'Date;Entered', 9, 0, FALSE } )
    aadd( aReport, { 'space(1) ', ' ', 1, 0, FALSE } )
    aadd( aReport, { 'dLastRecv', 'Date Last;Received', 10, 0, FALSE } )

    select master
    master->( ordsetfocus( BY_DESC ) )
    master->( dbgotop() )

    sHeading = 'Report on Items selected for Archive'

    sforCond = "(master->onhand <= 0) .and. " + ;
	           "(master->onorder = 0) .and. " + ;
               "(master->special = 0) .and. " + ;
			   "(master->entered < dEntered) .and. " + ;
               "(master->dsale < dLastSale) .and. " + ;
			   "(master->dlastrecv < dLastReceived) .and. " + ;
               "(master->minstock <= nMinStock) .and. " + ;
			   "(master->consign = 0)"

	Reporter( aReport,;                                                      // Field Array
              sHeading ,;                                                    // Report Heading
              ,;                                                             // Group By
              ,;                                                             // Group Heading
              ,;                                                             // Sub Group by
              ,;                                                             // Sub Group Heading
              FALSE,;                                                        // Summary Report
              sForCond,;                                                     // For Condition
              ,;                                                             // While Condition
              132 )                                                          // approx Page width


    master->( dbclosearea() )
   endif

  case nMenu = 2  // Execute
   if Isready(16)
    Center(17,'-=< Archiving - Please Wait >=-')
    if Netuse( "salehist", EXCLUSIVE )
     if Netuse( "stkhist", EXCLUSIVE )
      if Netuse( "macatego", EXCLUSIVE )
       if Netuse( "master", EXCLUSIVE )
        ordsetfocus( NATURAL )
        master->( dbgotop() )
        Highlight(18,03,'Master file Records',Ns(lastrec()))
        SysAudit( "ArcStart" )
        while !master->( eof() )
         if master->onhand <= 0 .and. master->onorder = 0 .and. ;
          master->special = 0 .and. master->entered < dEntered .and. ;
          master->dsale < dLastSale .and. master->dlastrecv < dLastReceived .and. ;
          master->minstock <= nMinStock .and. master->consign = 0

          if !archive->( dbseek( master->id ) )
           Add_rec('archive')
           for x := 1 to master->( fcount() )
            mfpos := archive->( fieldpos( master->( fieldname( x ) ) ) )
            if mfpos != 0
             archive->( fieldput( mfpos, master->( fieldget( x ) ) ) )

            endif
           next x

          endif

          macatego->( dbseek( master->id ) ) // Purge old Category Records
          while macatego->id = master->id .and. !macatego->( eof() )
           macatego->( dbdelete() )
           macatego->( dbskip() )

          enddo

          stkhist->( dbseek( master->id ) )  // Purge old Stock Histories
          while stkhist->id = master->id .and. !stkhist->( eof() )
           stkhist->( dbdelete() )
           stkhist->( dbskip() )

          enddo

          salehist->( dbseek( master->id ) )  // Purge old Sales Histories
          while salehist->id = master->id .and. !salehist->( eof() )
           salehist->( dbdelete() )
           salehist->( dbskip() )

          enddo

          select master
          delete
          mrecsarch++

         endif
         master->( dbskip() )
         Highlight( 18, 30, 'Records Processed', Ns( recno() ) )
         Highlight( 18, 55, 'Records Archived', Ns( mrecsarch ) )

        enddo
        Center( 19, '-=< Packing Master file >=-' )
        if Netuse( "master", EXCLUSIVE, 10, NOALIAS, OLD )
         pack

        endif
        master->( dbclosearea() )

       endif
       macatego->( dbclosearea() )

      endif
      stkhist->( dbclosearea() )

     endif
     salehist->( dbclosearea() )

    endif
    select archive
    Center(21,"-=< Deleting non unique ids from Archive >=-")
    indx( "field->id", 'unique', nil, UNIQUE )   // unique
    copy to ( Oddvars( SYSPATH ) )+"archive\" + Oddvars( TEMPFILE )
    ordDestroy( 'unique' )
    archive->( dbclosearea() )
    Kill( ( Oddvars( SYSPATH ) ) + "archive\oldarc.dbf" )
    frename( ( Oddvars( SYSPATH ) )+"archive\archive.dbf", (Oddvars( SYSPATH )) + "archive\oldarc.dbf" )
    frename( ( Oddvars( SYSPATH ) )+"archive\"+Oddvars( TEMPFILE )+".dbf", (Oddvars( SYSPATH )) + "archive\archive.dbf" )
    if Netuse( Oddvars( SYSPATH ) + "archive\archive" , EXCLUSIVE )
     pack
     kill( ( Oddvars( SYSPATH ) ) + "archive\oldarc.dbf" )

    endif
    SysAudit( "ArcFinish" )
    Box_Save( 5, 03, 8, 76 )
    Center( 06, DEVELOPER + ' strongly recommend you Backup your new Archive' )
    Center( 07, ' on a separate disk set using the \Utility\Backup\Archive option' )
    Error( 'Archive Completed', 09 )

   endif

  endcase

 endif

endif
dbCloseAll()
return
