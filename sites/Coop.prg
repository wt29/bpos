/*

  Special Program for Uni Coop - Contains the Invoice Formats as well.

  Last change:  APG   7 Jun 2004    4:19 pm


  01/12/95 - TG - Fix to invoices to force them to 10 Pitch first and then to 12 Pitch.

  05/12/95 - SWW - Print store phone and fax numbers on invoice (Fax 5/12/95)

  12/01/96 - SWW - Additional details on docket printer.

  16/01/96 - SWW - Bug EB/960116/1 Fixed invoice reprint crash.

  23/01/96 - SWW - Completed EB/960105/2 - change end of invoice for contract completion.
      Last change: APG 1/08/2008 11:12:08 AM
*/
static branarr

Procedure Invforms

#include "bpos.ch"

#define ULINE_CHAR chr( 196 )
#define SIDES chr( 179 )
#define B_TLEFT chr( 218 )
#define B_TRIGHT chr( 191 )
#define B_BLEFT chr( 192 )
#define B_BRIGHT chr( 217 )

#define PICK_DATE ctod( '31/12/1967' )

function DB_load
local mFilePath := 'd:\prime\fromunix' + space( 10 ), mscr, getlist := {}
local marr                      // General purpose array variable
local oldcur := setcursor( 1 )  // save cursor state
local mFarr                     // File Array
local x, y                      // Some counters
local statline := 4             // Line to display status on
local mfpos                     // field position
local mfcount                   // Number of Fields
local mbegin := seconds()       // Start Time
local isPos := FALSE            // Are we building a POS Store
local midmonth                  // Middle of the month to set up history files
local mdept                     // Setup unique dept codes
local ctlwait := FALSE          //
local minkey 
local titlcount                 // Number of titles added

do case
case empty( Bvars( B_BRANCH ) )
 Error( 'No branch code defined! - Bye Bye!', 12 )

case !secure( X_SUPERVISOR )
 Error( 'You must have supervisor security privilege here', 12 )

case !file( Oddvars( SYSDRIVE )+"bsdbfbak.zip" ) 
 Error( 'No Backup squash file exists - exit and Squash Data first', 12 )

case date() - directory( Oddvars( SYSDRIVE )+"bsdbfbak.zip" )[ 1, 3 ] > 2
 Error( 'Sorry your Backup squash file is too old - Squash first', 12 )

otherwise

 if Netuse( Oddvars( SYSDRIVE ) + 'archive\archive', EXCLUSIVE ) .and. ;
    Netuse( Oddvars( SYSDRIVE ) + 'members\members', EXCLUSIVE ) .and. ;
    Netuse( 'master', EXCLUSIVE ) .and. ;
    Netuse( 'mail', EXCLUSIVE ) .and. ;
    Netuse( 'supplier', EXCLUSIVE ) .and. ;
    Netuse( 'imprint', EXCLUSIVE ) .and. ;
    Netuse( 'dept', EXCLUSIVE ) .and. ;
    Netuse( 'stock', EXCLUSIVE )  .and. ;
    Netuse( 'branch', EXCLUSIVE ) .and. ;
    Netuse( 'macatego', EXCLUSIVE ) .and. ;
    Netuse( 'category', EXCLUSIVE ) .and. ;
    Netuse( 'customer', EXCLUSIVE ) .and. ;
    Netuse( 'poline', EXCLUSIVE ) .and. ;
    Netuse( 'pohead', EXCLUSIVE ) .and. ;
    Netuse( 'special', EXCLUSIVE ) .and. ;
    Netuse( 'trrqst', EXCLUSIVE ) .and. ;
    Netuse( 'transfer', EXCLUSIVE ) .and. ;
    Netuse( 'ytdsales', EXCLUSIVE ) .and. ;
    Netuse( 'stkhist', EXCLUSIVE )
    
    
  Heading( 'Load Store #' + Bvars( B_BRANCH ) + ' from Reality' )
  Bsave( 2, 2, 24, 78 )
  @ 3, 4 say 'Path to Reality/Unix files' get mFilePath pict '@K'
  @ 4, 4 say 'Existing POS Store' get isPos pict 'y'
  @ 5, 4 say 'Wait for CTL file' get ctlwait pict 'y'
  read

  if !ctlwait .and. ( !Isready( 12 ) .or. !file( mFilePath + '\ctl?????.txt' ) )
   Error( 'No Control file found in directory ' + trim( mFilePath ), 12 )

  else 

   if ctlwait

    minkey := 0
    while !file( mFilePath + '\ctl?????.txt' ) .and. minkey = 0

     minkey := inkey( 1 )

     @ 6, 4 say 'Waiting for ctl file from the host - Time is ' + time()

    enddo

   endif  

   Audit( "DBLoadStart" )

   Kill( 'primeaud.txt' )  // Delete old log file
    
   mbegin := seconds()
    
// Mail --- Coop Mail box
   marr := {} 
   aadd( marr, { 'flag', 'c', 1, 0 } ) 
   aadd( marr, { 'id', 'c', 20, 0 } ) 
   aadd( marr, { 'to', 'c', 30, 0 } ) 
   aadd( marr, { 'isbn', 'c', ISBN_CODE_LEN, 0 } ) 
   aadd( marr, { 'message1', 'c', 250, 0 } ) 
   aadd( marr, { 'message2', 'c', 250, 0 } ) 
   aadd( marr, { 'response1', 'c', 250, 0 } ) 
   aadd( marr, { 'response2', 'c', 250, 0 } ) 
   aadd( marr, { 'response3', 'c', 250, 0 } ) 
   aadd( marr, { 'respbranch', 'c',250, 0 } ) 
   dbcreate( 'mailunix', marr )
   
   if Netuse( 'mailunix', EXCLUSIVE )
   
    mFArr := directory( mFilePath + '\mai?????.txt' )
    if len( mFArr ) > 0
     Highlight( statline, 4, 'Appending from Unix Mail', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

    endif

    Highlight( statline, 4, 'Adding to Bookscan Mail files', mailunix->( reccount() ) )
    statline++

    mailunix->( dbclosearea() )
    select mail
    
    appe from mailunix while Pinwheel( NOINTERUPT )

    kill( 'mailunix.dbf' )

   endif

// Build Supplier files 
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'extra_key', 'c', 10, 0 } )
   aadd( marr, { 'code', 'c', SUPP_CODE_LEN, 0 } )
   aadd( marr, { 'name', 'c', 40, 0 } )
   aadd( marr, { 'address1', 'c', 40, 0 } )
   aadd( marr, { 'address2', 'c', 40, 0 } )
   aadd( marr, { 'city', 'c', 40, 0 } )
   aadd( marr, { 'country', 'c', 30, 0 } )
   aadd( marr, { 'raddress1', 'c', 40, 0 } )
   aadd( marr, { 'raddress2', 'c', 40, 0 } )
   aadd( marr, { 'rcity', 'c', 40, 0 } )
   aadd( marr, { 'account', 'c', 15, 0 } )
   aadd( marr, { 'min_ord', 'n', 4, 0 } )
   aadd( marr, { 'returns_x', 'c', 1, 0 } )
   aadd( marr, { 'phone', 'c', 17, 0 } )
   aadd( marr, { 'fax', 'c', 17, 0 } )
   aadd( marr, { 'comm1', 'c', 40, 0 } )
   aadd( marr, { 'comm2', 'c', 40, 0 } )
   aadd( marr, { 'san', 'c', 12, 0 } )
   aadd( marr, { 'std_disc', 'n', 6, 2 } )
   aadd( marr, { 'price_meth', 'c', 1, 0 } )
   aadd( marr, { 'po_sort', 'c', 1, 0 } )
   aadd( marr, { 'returns', 'l', 1, 0 } )

   dbcreate( 'suppunix', marr )
   
   if Netuse( 'suppunix', EXCLUSIVE )
    mFArr := directory( mFilePath + '\fsp?????.txt' )
    if len( mFArr ) > 0
     Highlight( statline, 4, 'Appending from Unix Suppliers', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

    endif

    Highlight( statline, 4, 'Adding to Bookscan Supplier files', suppunix->( reccount() ) )
    statline++

    replace all name with low_case( suppunix->name ) ,;
                price_meth with 'R',;
                po_sort with 'T',;
                returns with if( suppunix->returns_x = 'Y', TRUE, FALSE )

    suppunix->( dbclosearea() )
    select supplier
    
    appe from suppunix while Pinwheel( NOINTERUPT )

    Add_rec( 'supplier' )
    supplier->code := 'STOCK'
    supplier->name := 'Stock Adjustment Supplier'

    Add_rec( 'supplier' )
    supplier->code := 'MISCE'
    supplier->name := 'Miscellaneous Stock Supplier'

    Add_rec( 'supplier' )
    supplier->code := '!TRA'
    supplier->name := 'Transfer Supplier'

    Add_rec( 'supplier' )
    supplier->code := '!C/N'
    supplier->name := 'Credit Note Dummy Supplier'

    kill( 'suppunix.dbf' )

   endif

   supplier->( dbclosearea() )

// Imprint files Next
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'extra_key', 'c', 10, 0 } )
   aadd( marr, { 'code', 'c', 6, 0 } )
   aadd( marr, { 'name', 'c', 25, 0 } )
   aadd( marr, { 'supp_code', 'c', SUPP_CODE_LEN, 0 } )
   aadd( marr, { 'supp_code2', 'c', SUPP_CODE_LEN, 0 } )
   dbcreate( 'imprunix', marr )
   
   if Netuse( 'imprunix', EXCLUSIVE )
    mFArr := directory( mFilePath + '\fpb?????.txt' )
    if len( mFArr ) > 0
     Highlight( statline, 4, 'Appending from Unix Publishers', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

    endif


    Highlight( statline, 4, 'Adding to Bookscan Imprint files', imprunix->( reccount() ) )
    statline++

    replace all name with low_case( imprunix->name ) 

    imprunix->( dbclosearea() )
    select imprint
    
    appe from imprunix while Pinwheel( NOINTERUPT ) 

    kill( 'imprunix.dbf' )

   endif

   imprint->( dbclosearea() )
    
// How about some Branches
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'code', 'c', BRANCH_CODE_LEN, 0 } )
   aadd( marr, { 'name', 'c', 40, 0 } )
   aadd( marr, { 'add1', 'c', 40, 0 } )
   aadd( marr, { 'add2', 'c', 40, 0 } )
   aadd( marr, { 'add3', 'c', 40, 0 } )
   aadd( marr, { 'phone','c', 20, 0 } )
   aadd( marr, { 'contact','c', 40, 0 } )
   dbcreate( 'branunix', marr )
   
   if Netuse( 'branunix', EXCLUSIVE )
    mFArr := directory( mFilePath + '\fbr?????.txt' )
    if len( mFArr ) > 0
     Highlight( statline, 4, 'Appending from Unix Branches', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

    endif

    Highlight( statline, 4, 'Adding to Bookscan Branches file', branunix->( reccount() ) )
    statline++

    replace all name with low_case( branunix->name )

    branunix->( dbclosearea() )
    select branch
    
    appe from branunix while Pinwheel( NOINTERUPT ) 

    kill( 'branunix.dbf' )

   endif

   branch->( dbclosearea() )
    
// Departments ( COOP Locations )
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'code', 'c', DEPT_CODE_LEN, 0 } )
   aadd( marr, { 'branch', 'c', BRANCH_CODE_LEN, 0 } )
   aadd( marr, { 'name', 'c', 30, 0 } )
   aadd( marr, { 'extra_key','c', 3, 0 } )
   dbcreate( 'deptunix', marr )
   
   if Netuse( 'deptunix', EXCLUSIVE )
    mFArr := directory( mFilePath + '\flo?????.txt' )
    if len( mFArr ) > 0
     Highlight( statline, 4, 'Appending from Unix Locations', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

    endif
    Highlight( statline, 4, 'Adding to Bookscan Dept file', deptunix->( reccount() ) )
    statline++

    replace all name with low_case( deptunix->name )
    delete for deptunix->branch != Bvars( B_BRANCH )
    
    deptunix->( dbclosearea() )
    select dept
    
    appe from deptunix while Pinwheel( NOINTERUPT ) 

    dept->( dbgotop() )
    mdept := dept->code
    dept->( dbskip() )
    while !dept->( eof() )
     if dept->code = mdept
      dept->( dbdelete() )
     else
      mdept := dept->code
     endif  
     dept->( dbskip() )
    enddo 


    kill( 'deptunix.dbf' )

   endif

   dept->( dbclosearea() )
    
// Categories ( COOP Subjects )
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'code', 'c', 6, 0 } )
   aadd( marr, { 'extra_key','c', 3, 0 } )
   aadd( marr, { 'name', 'c', 30, 0 } )
   dbcreate( 'cateunix', marr )
   
   if Netuse( 'cateunix', EXCLUSIVE )
    mFArr := directory( mFilePath + '\fsj?????.txt' )
    if len( mFArr ) > 0
     Highlight( statline, 4, 'Appending from Unix Subjects', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

    endif

    Highlight( statline, 4, 'Adding to Bookscan Category file', cateunix->( reccount() ) )
    statline++

    replace all name with low_case( cateunix->name )
    
    cateunix->( dbclosearea() )
    select category
    
    appe from cateunix while Pinwheel( NOINTERUPT ) 


    kill( 'cateunix.dbf' )

   endif

   category->( dbclosearea() )
    
// Customer Files ( Debtors First! )
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'key', 'c', CUST_KEY_LEN, 0 } )
   aadd( marr, { 'name', 'c', 40, 0 } )
   aadd( marr, { 'name2', 'c', 40, 0 } )
   aadd( marr, { 'contact', 'c', 40, 0 } )
   aadd( marr, { 'add1', 'c', 40, 0 } )
   aadd( marr, { 'add2', 'c', 40, 0 } )
   aadd( marr, { 'add3', 'c', 40, 0 } )
   aadd( marr, { 'xentered','c', 8, 0 } )
   aadd( marr, { 'comments','c', 20, 0 } )
   aadd( marr, { 'type','c', 2, 0 } )
   aadd( marr, { 'phone1','c', PHONE_NUM_LEN, 0 } )
   aadd( marr, { 'credit_car','c', 26, 0 } )
   aadd( marr, { 'pcode','c', 4, 0 } )
   aadd( marr, { 'xstop','c', 1, 0 } )

   aadd( marr, { 'entered','d', 8, 0 } )
   aadd( marr, { 'stop','l', 1, 0 } )

   dbcreate( 'custunix', marr )
   
   if Netuse( 'custunix', EXCLUSIVE )
    mFArr := directory( mFilePath + '\fcs?????.txt' )
    if len( mFArr ) > 0
     Highlight( statline, 4, 'Appending from Unix Customers', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

    endif


    Highlight( statline, 4, 'Adding to Bookscan Debtor ( Customer ) file', custunix->( reccount() ) )
    statline++

    custunix->( dbgotop() )
    mfcount := custunix->( fcount() )

    while !custunix->( eof() ) .and. Pinwheel( NOINTERUPT )

     Add_rec( 'customer' )

     for y := 1 to mfcount

      mfpos := customer->( fieldpos( custunix->( fieldname( y ) ) ) )
      if mfpos != 0

       customer->( fieldput( mfpos, custunix->( fieldget( y ) ) ) )

      endif

     next y
  
     customer->name := low_case( custunix->name )
     customer->entered := ctod( custunix->xentered )
     customer->debtor := TRUE
     customer->stop := if( custunix->xstop = 'Y', TRUE, FALSE )
      
     custunix->( dbskip() )

    enddo

    custunix->( dbclosearea() )
 

    kill( 'custunix.dbf' )

   endif

// Other Customers ( from COOP Special Order File )
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'extra_key', 'c', CUST_KEY_LEN, 0 } )
   aadd( marr, { 'name', 'c', 40, 0 } )
   aadd( marr, { 'foo1', 'c', 1, 0 } )
   aadd( marr, { 'foo2', 'c', 1, 0 } )
   aadd( marr, { 'add1', 'c', 40, 0 } )
   aadd( marr, { 'add2', 'c', 40, 0 } )
   aadd( marr, { 'add3', 'c', 40, 0 } )
   aadd( marr, { 'xentered','c', 8, 0 } )
   aadd( marr, { 'comments','c', 20, 0 } )
   aadd( marr, { 'type','c', 2, 0 } )
   aadd( marr, { 'amtcur','n', 10, 2 } )
   aadd( marr, { 'phone1','c', PHONE_NUM_LEN, 0 } )
   aadd( marr, { 'credit_car','c', 26, 0 } )
   aadd( marr, { 'pcode','c', 4, 0 } )
   aadd( marr, { 'entered','d', 8, 0 } )
   aadd( marr, { 'key','c', CUST_KEY_LEN, 0 } )

   dbcreate( 'custunix', marr )
   
   if Netuse( 'custunix', EXCLUSIVE )
    mFArr := directory( mFilePath + '\frc?????.txt' )
    if len( mFArr ) > 0
     Highlight( statline, 4, 'Appending from Unix Customers', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

    endif


    Highlight( statline, 4, 'Adding to Bookscan Customer file', custunix->( reccount() ) )
    statline++

    custunix->( dbgotop() )
    while !custunix->( eof() ) .and. Pinwheel( NOINTERUPT )

     if !customer->( dbseek( custunix->key ) )
       
      Add_rec( 'customer' )

      for y := 1 to custunix->( fcount() )
       
       mfpos := customer->( fieldpos( custunix->( fieldname( y ) ) ) )
       if mfpos != 0
        customer->( fieldput( mfpos, custunix->( fieldget( y ) ) ) )
       endif
      next y
  
      customer->name := low_case( custunix->name )
      customer->entered := ctod( custunix->xentered )
      customer->key := custunix->extra_key 
      customer->amtcur := customer->amtcur * -1
       
     endif

     custunix->( dbskip() )

    enddo


    custunix->( dbclosearea() )

    kill( 'custunix.dbf' )

   endif

   customer->( dbclosearea() )

// Special Orders files
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'number', 'n', 6, 0 } )
   aadd( marr, { 'text_num', 'c', 12, 0 } )
   aadd( marr, { 'key', 'c', CUST_KEY_LEN, 0 } )
   aadd( marr, { 'xdate', 'c', 8, 0 } )
   aadd( marr, { 'deposit', 'n', 10, 2 } )
   aadd( marr, { 'comments','c', 50, 0 } )
   aadd( marr, { 'isbn','c', ISBN_CODE_LEN, 0 } )
   aadd( marr, { 'qty','n', 5, 0 } )
   aadd( marr, { 'invoiced','n', 5, 0 } )
   aadd( marr, { 'supp_code','c', SUPP_CODE_LEN, 0 } )
   aadd( marr, { 'xcomments','c', 25, 0 } )
   aadd( marr, { 'branch','c', BRANCH_CODE_LEN, 0 } )
   aadd( marr, { 'date','d', 8, 0 } )

   dbcreate( 'specunix', marr )
   
   if Netuse( 'specunix', EXCLUSIVE )

    mFArr := directory( mFilePath + '\spe?????.txt' )
    if len( mFArr ) > 0
     Highlight( statline, 4, 'Appending from Unix Specials', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

    endif


    Highlight( statline, 4, 'Adding to Bookscan Special file', specunix->( reccount() ) )
    statline++

    specunix->( dbgotop() )
    mfcount := specunix->( fcount() )

    while !specunix->( eof() ) .and. Pinwheel( NOINTERUPT )
       
     Add_rec( 'special' )

     for y := 1 to mfcount

      mfpos := special->( fieldpos( specunix->( fieldname( y ) ) ) )
      if mfpos != 0
       special->( fieldput( mfpos, specunix->( fieldget( y ) ) ) )
      endif

     next y
  
     special->branch := Bvars( B_BRANCH )
     special->comments := trim( specunix->comments ) + ' ' + specunix->xcomments
     special->date := ctod( specunix->xdate )

     specunix->( dbskip() )

    enddo

    specunix->( dbclosearea() )
 

    kill( 'specunix.dbf' )

   endif

//  Do not Close Special Order file later due to resysnc required
    
//  Purchase Orders files
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'xnumber', 'c', PO_NUM_LEN, 0 } )
   aadd( marr, { 'coop_num', 'c', PO_NUM_LEN, 0 } )
   aadd( marr, { 'supp_code', 'c', SUPP_CODE_LEN, 0 } )
   aadd( marr, { 'xdate', 'c', 8, 0 } )
   aadd( marr, { 'branch', 'c', BRANCH_CODE_LEN, 0 } )
   aadd( marr, { 'xapproved','c', 1, 0 } )
   aadd( marr, { 'isbn','c', ISBN_CODE_LEN, 0 } )
   aadd( marr, { 'sales_code','c', 2, 0 } )
   aadd( marr, { 'qty_ord','n', 6, 0 } )
   aadd( marr, { 'comment','c', 30, 0 } )
   aadd( marr, { 'semester','c', 3, 0 } )
   aadd( marr, { 'cost_price','n', 10, 2 } )
   aadd( marr, { 'discount','n', 10, 2 } )
   aadd( marr, { 'sell_price','n', 10, 2 } )
   aadd( marr, { 'approved_x','c', 1, 0 } )
   aadd( marr, { 'date_ord','d', 8, 0 } )
   aadd( marr, { 'number', 'n', 6, 0 } )

   dbcreate( 'pounix', marr )
   
   if Netuse( 'pounix', EXCLUSIVE )
    mFArr := directory( mFilePath + '\por?????.txt' )
    if len( mFArr ) > 0
     Highlight( statline, 4, 'Appending from Unix Purchase Orders', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

    endif


    Highlight( statline, 4, 'Adding to Bookscan Purchase Order file', pounix->( reccount() ) )
    statline++

    pounix->( dbgotop() )
    mfcount := pounix->( fcount() )

    while !pounix->( eof() ) .and. Pinwheel( NOINTERUPT )
       
     if !pohead->( dbseek( val( pounix->coop_num ) ) )

      Add_rec( 'pohead' )

      for y := 1 to mfcount

       mfpos := pohead->( fieldpos( pounix->( fieldname( y ) ) ) )
       if mfpos != 0
        pohead->( fieldput( mfpos, pounix->( fieldget( y ) ) ) )
       endif

      next y

      pohead->number := val( pounix->coop_num )
      pohead->approved := if( pounix->xapproved = 'T', TRUE, FALSE )
      pohead->date_ord := ctod( pounix->xdate )

     endif
      
     Add_rec( 'poline' )

     for y := 1 to mfcount

      mfpos := poline->( fieldpos( pounix->( fieldname( y ) ) ) )
      if mfpos != 0
       poline->( fieldput( mfpos, pounix->( fieldget( y ) ) ) )
      endif

     next y
  
     poline->number := val( pounix->coop_num )
     poline->comment := trim( pounix->comment )
     poline->qty := poline->qty_ord
      
     pounix->( dbskip() )

    enddo

    pounix->( dbclosearea() )
 
    kill( 'pounix.dbf' )

   endif

   pohead->( dbclosearea() )
    
// Transfer files
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'xnumber', 'c', 6, 0 } )
   aadd( marr, { 'xcoop_num', 'c', 6, 0 } )
   aadd( marr, { 'to', 'c', BRANCH_CODE_LEN, 0 } )
   aadd( marr, { 'from', 'c', BRANCH_CODE_LEN, 0 } )
   aadd( marr, { 'xdate','c', 8, 0 } )
   aadd( marr, { 'coop_type','c', 1, 0 } )
   aadd( marr, { 'isbn','c', ISBN_CODE_LEN, 0 } )
   aadd( marr, { 'ponum','n', 6, 0 } )
   aadd( marr, { 'qty_rqst','n', 5, 0 } )
   aadd( marr, { 'qty_trf','n', 5, 0 } )
   aadd( marr, { 'ntrf_reas','c', 20, 0 } )
   aadd( marr, { 'xspec_flag','c', 1, 0 } )
   aadd( marr, { 'date','d', 8, 0 } )
   aadd( marr, { 'spec_flag','c', 1, 0 } )
   aadd( marr, { 'number', 'n', 6, 0 } )
   aadd( marr, { 'coop_num', 'c', 10, 0 } )

   dbcreate( 'trfunix', marr )
   
   if Netuse( 'trfunix', EXCLUSIVE )
    mFArr := directory( mFilePath + '\trf?????.txt' )
    if len( mFArr ) > 0
     Highlight( statline, 4, 'Appending from Unix Transfer File', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

    endif

    Highlight( statline, 4, 'Adding to Bookscan Transfer File', trfunix->( reccount() ) )
    statline++

    trfunix->( dbgotop() )
    mfcount := trfunix->( fcount() )

    while !trfunix->( eof() ) .and. Pinwheel( NOINTERUPT )
       
     if trfunix->coop_type = 'A' .and. trfunix->to != Bvars( B_BRANCH )

      Add_rec( 'trrqst' )

      for y := 1 to mfcount

       mfpos := trrqst->( fieldpos( trfunix->( fieldname( y ) ) ) )
       if mfpos != 0
        trrqst->( fieldput( mfpos, trfunix->( fieldget( y ) ) ) )
       endif

      next y
  
      trrqst->number := val( trfunix->xcoop_num )
      trrqst->branch := Bvars( B_BRANCH )
      trrqst->date := ctod( trfunix->xdate )
      trrqst->qty := trfunix->qty_rqst
      trrqst->qty_trf := trfunix->qty_trf
      trrqst->coop_num := trfunix->xcoop_num

     else

      Add_rec( 'transfer' )

      for y := 1 to mfcount

       mfpos := transfer->( fieldpos( trfunix->( fieldname( y ) ) ) )
       if mfpos != 0
        transfer->( fieldput( mfpos, trfunix->( fieldget( y ) ) ) )
       endif

      next y

      transfer->number := val( trfunix->xcoop_num )
      transfer->branch := Bvars( B_BRANCH )
      transfer->date := ctod( trfunix->xdate )
      transfer->qty := trfunix->qty_rqst
      trrqst->qty_trf := trfunix->qty_trf

     endif

     trfunix->( dbskip() )

    enddo

    trfunix->( dbclosearea() )
 
    kill( 'trfunix.dbf' )

   endif

   transfer->( dbclosearea() )
   trrqst->( dbclosearea() )
    
// Invoice History ( Stock History )
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'branch', 'c', BRANCH_CODE_LEN, 0 } )
   aadd( marr, { 'isbn', 'c', ISBN_CODE_LEN, 0 } )
   aadd( marr, { 'supp_code', 'c', SUPP_CODE_LEN, 0 } )

   aadd( marr, { 'xpo_num', 'c', 10, 0 } )
   aadd( marr, { 'reference','c', 20, 0 } )
   aadd( marr, { 'xinv_date','c', 8, 0 } )
   aadd( marr, { 'qty','n', 6, 0 } )
   aadd( marr, { 'xrcvdate','c', 8, 0 } )
   aadd( marr, { 'rcvqty','n', 6, 0 } )
   aadd( marr, { 'retqty','n', 5, 0 } )
   aadd( marr, { 'cost_price','n', 10, 2 } )
   aadd( marr, { 'sell_price','n', 10, 2 } )

   aadd( marr, { 'date_po','d', 8, 0 } )
   aadd( marr, { 'date','d', 8, 0 } )

   dbcreate( 'invhunix', marr )
   
   if Netuse( 'invhunix', EXCLUSIVE )

    mFArr := directory( mFilePath + '\inv?????.txt' )
    if len( mFArr ) > 0
     Highlight( statline, 4, 'Appending from Unix Inv Histories', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

    endif


    Highlight( statline, 4, 'Adding to Bookscan Stkhist file', invhunix->( reccount() ) )
    statline++

    invhunix->( dbgotop() )
    mfcount := invhunix->( fcount() )

    while !invhunix->( eof() ) .and. Pinwheel( NOINTERUPT )
       
     Add_rec( 'stkhist' )

     for y := 1 to mfcount

      mfpos := stkhist->( fieldpos( invhunix->( fieldname( y ) ) ) )
      if mfpos != 0
       stkhist->( fieldput( mfpos, invhunix->( fieldget( y ) ) ) )
      endif
     next y
  
     stkhist->reference := trim( stkhist->reference ) + ':' + trim( invhunix->xpo_num )
     stkhist->date := ctod( invhunix->xrcvdate )
     stkhist->type := 'I'   // Invoices 06/11/95 - TG

     invhunix->( dbskip() )

    enddo

    invhunix->( dbclosearea() )

    kill( 'invhunix.dbf' )

   endif


// Time for the stock files 
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'branch','c', BRANCH_CODE_LEN, 0 } )
//   aadd( marr, { 'date','c', 8, 0 } )
//   aadd( marr, { 'time','c', 8, 0 } )
   aadd( marr, { 'isbn','c', ISBN_CODE_LEN, 0 } )
   aadd( marr, { 'department','c', 3, 0 } )
   aadd( marr, { 'sales_code','c', 2, 0 } )
   aadd( marr, { 'onhand','n', 10, 0 } )
   aadd( marr, { 'onorder','n', 10, 0 } )
   aadd( marr, { 'excess','n', 10, 0 } )
   aadd( marr, { 'retqty','n', 10, 0 } )
   aadd( marr, { 'lastrecv','c', 8, 0 } )
   aadd( marr, { 'sale_date','c', 8, 0 } )
   aadd( marr, { 'last_disc','n', 10, 2 } )
   aadd( marr, { 'lastqty','n', 10, 0 } )
   aadd( marr, { 'sh_qty','n', 10, 0 } )
   aadd( marr, { 'sh_price','n', 10, 2 } )
   aadd( marr, { 'consign','n', 10, 0 } )
   aadd( marr, { 'con_price','n', 10, 2 } )

   midmonth := ctod( '15/01/95' )
   for x := 1 to 12
    aadd( marr, { lower( left( cmonth( midmonth ), 3 ) ), 'n', 5, 0 } ) 
    midmonth += 30   // Forward 30 days ( should work )
   next

   dbcreate( 'stocunix', marr )
   
   marr := {}
   aadd( marr, { 'flag', 'c', 1, 0 } )
   aadd( marr, { 'isbn','c', ISBN_CODE_LEN, 0 } )
   aadd( marr, { 'book_no','c', 7, 0 } )
   aadd( marr, { 'title','c', 80, 0 } )
   aadd( marr, { 'author','c', 30, 0 } )
   aadd( marr, { 'imprint','c', 6, 0 } )
   aadd( marr, { 'supp_code','c', 5, 0 } )
   aadd( marr, { 'supp_code2','c', 5, 0 } )
   aadd( marr, { 'sell_price','n', 10, 2 } )
   aadd( marr, { 'binding','c', 2, 0 } )
   aadd( marr, { 'edition','c', 2, 0 } )
   aadd( marr, { 'department','c', 3, 0 } )
   aadd( marr, { 'entered_x','c', 8, 0 } )
   aadd( marr, { 'nodisc_x','c', 1, 0 } )
   aadd( marr, { 'category','c', 6, 0 } )
   aadd( marr, { 'cost_price','n', 10, 2 } )
   aadd( marr, { 'entered','d', 8, 0 } )
   aadd( marr, { 'nodisc','l', 1, 0 } )
   aadd( marr, { 'darchive','d', 1, 0 } )

   dbcreate( 'titlunix', marr )
   
   if Netuse( 'stocunix', EXCLUSIVE )
    
    if Netuse( 'titlunix' , EXCLUSIVE )

     mFArr := directory( mFilePath + '\tit?????.txt' )

     if len( mFArr ) > 0

      Highlight( statline, 4, 'Appending from Unix title file', '' )

      for x := 1 to len( mFArr )

       append from ( mFilePath + '\' + mFarr[ x, 1 ] ) delimited
 
       frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

      next 

     endif

     replace titlunix->title with low_case( titlunix->title ), ;
             titlunix->darchive with ctod( titlunix->entered_x ), ;
             titlunix->entered with ctod( titlunix->entered_x ), ;
             titlunix->nodisc with if( titlunix->nodisc_x = 'Y', TRUE, FALSE ), ;
             titlunix->isbn with if( empty( titlunix->isbn ), titlunix->book_no, titlunix->isbn ) ;
             all

     Highlight( statline, 4, 'Adding to Bookscan Title Archive file', titlunix->( reccount() ) )
     statline++

     titlunix->( dbclosearea() )

     select archive
     set index to

     append from titlunix

// Ok now need to build the stock file
     select stocunix

     mFArr := directory( mFilePath + '\stk?????.txt' )
     if len( mFArr ) > 0
      Highlight( statline, 4, 'Appending from Unix Stock file', '' )

      for x := 1 to len( mFArr )

       append from ( mFilePath + '\' + mFarr[ x, 1 ] ) delimited
 
       frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

      next 

     endif

     Highlight( statline, 4, 'Adding to Bookscan Stock file', stocunix->( reccount() ) )
     statline++

     stocunix->( dbclosearea() )

     select stock

     set index to
      
     appe from stocunix  // while Pinwheel( NOINTERUPT )

     set index to stock
     @ statline, maxrow()-12 say "Reindexing Stock"

     reindex

     archive->( dbclosearea() )

     Netuse( Oddvars( SYSDRIVE ) + 'archive\archive', EXCLUSIVE )
     @ statline, maxrow()-12 say "Reindexing archive"

     reindex 

     if isPos

      if Netuse( 'stocunix', EXCLUSIVE )

       indx( 'branch + isbn', 'branch' )

       select stock

       set relation to stock->isbn into archive,;
                       stock->branch + stock->isbn into stocunix

       stock->( ordsetfocus( 'store' ) )
       stock->( dbseek( Bvars( B_BRANCH ) ) )

       Highlight( statline, 4, 'Building Bookscan Master file', stocunix->( reccount() ) )
       statline++

       titlcount := 0
        
       while stock->branch = Bvars( B_BRANCH )

        if !archive->( eof() ) 

         Add_rec( 'master' )

         for y := 1 to archive->( fcount() )
          mfpos := master->( fieldpos( archive->( fieldname( y ) ) ) )
          if mfpos != 0
           master->( fieldput( mfpos, archive->( fieldget( y ) ) ) )
          endif
         next y

         for y := 1 to stock->( fcount() )
          mfpos := master->( fieldpos( stock->( fieldname( y ) ) ) )
          if mfpos != 0
           master->( fieldput( mfpos, stock->( fieldget( y ) ) ) )
          endif
         next y
        
         for y := 1 to stocunix->( fcount() )
          mfpos := master->( fieldpos( stocunix->( fieldname( y ) ) ) )
          if mfpos != 0
           master->( fieldput( mfpos, stocunix->( fieldget( y ) ) ) )
          endif
         next y

         Add_rec( 'ytdsales' )
         for y := 1 to stocunix->( fcount() )
          mfpos := ytdsales->( fieldpos( stocunix->( fieldname( y ) ) ) )
          if mfpos != 0
           ytdsales->( fieldput( mfpos, stocunix->( fieldget( y ) ) ) )
          endif
         next y

        endif

        stock->( dbdelete() )  // Dont need this record now - details in master file
        stock->( dbskip() )
 
        @ statline, maxrow()-12 say titlcount
        titlcount++

       enddo 

       stocunix->( dbclosearea() )

      endif

     endif

     Add_rec( 'master' )
     master->isbn := '%02GIFT&CARD'
     master->title := 'Gifts & Cards'
     master->supp_code := 'MISCE'
     master->status := 'ACT'
     master->sales_code := '02'

     Add_rec( 'master' )
     master->isbn := '%03STATIONERY'
     master->title := 'Stationery'
     master->supp_code := 'MISCE'
     master->status := 'ACT'
     master->sales_code := '02'

     Add_rec( 'master' )
     master->isbn := '%02MISCELLANE'
     master->title := 'Miscellaneous Item'
     master->supp_code := 'MISCE'
     master->status := 'ACT'
     master->sales_code := '02'

     Add_rec( 'master' )
     master->isbn := '%14SALEBOOK'
     master->title := 'Sale Book'
     master->supp_code := 'MISCE'
     master->status := 'ACT'
     master->sales_code := '02'

     Add_rec( 'master' )
     master->isbn := '%39POST'
     master->title := 'Postage & Handling'
     master->supp_code := 'MISCE'
     master->status := 'ACT'
     master->sales_code := '39'

     Add_rec( 'master' )
     master->isbn := 'GIFTVOUCHER'
     master->title := 'Gift Vouchers'
     master->supp_code := 'MISCE'
     master->status := 'ACT'
     master->sales_code := '39'

     if Netuse( 'titlunix', EXCLUSIVE )

      Highlight( statline, 4, 'Building Master Categories file', master->( reccount() ) )
      statline++

      indx( 'isbn', 'isbn' )
      master->( dbgotop() )
      master->( dbsetrelation( 'titlunix', { || master->isbn } ) )
      while !master->( eof() ) .and. Pinwheel( NOINTERUPT )

       if !empty( titlunix->category )

        Add_rec( 'macatego' )
        macatego->isbn := master->isbn
        macatego->code := titlunix->category
        macatego->( dbrunlock() )
        
       endif
       master->( dbskip() )

      enddo 

      titlunix->( dbclosearea() )

     endif
      
     kill( 'titlunix' + ordbagext() )
     kill( 'titlunix.dbf' )

    endif

    kill( 'stocunix' + ordbagext() )
    kill( 'stocunix.dbf' )

   endif

   Highlight( statline, 4, 'Updating Special Orders', Ns( special->( lastrec() ) ) )
   statline++
    
   special->( dbgotop() )
   while !special->( eof() ) .and. Pinwheel( NOINTERUPT )
    if !master->( dbseek( padr( special->isbn, ISBN_ENQ_LEN ) ) )

     if archive->( dbseek( special->isbn ) )
      Add_rec( 'master' )

      for y := 1 to archive->( fcount() )
       mfpos := master->( fieldpos( archive->( fieldname( y ) ) ) )
       if mfpos != 0
        master->( fieldput( mfpos, archive->( fieldget( y ) ) ) )
       endif
      next y
 
      master->special += ( special->qty - special->delivered )

     endif

    else
     master->special += ( special->qty - special->delivered )

    endif
    special->( dbskip() )
   enddo

   Highlight( statline, 4, 'Updating Purchase Orders', Ns( poline->( lastrec() ) ) )
   statline++

   poline->( dbgotop() )
   while !poline->( eof() ) .and. Pinwheel( NOINTERUPT )

    if !master->( dbseek( padr( poline->isbn, ISBN_ENQ_LEN ) ) )

     if archive->( dbseek( poline->isbn ) )

      Add_rec( 'master' )

      for y := 1 to archive->( fcount() )
       mfpos := master->( fieldpos( archive->( fieldname( y ) ) ) )
       if mfpos != 0
        master->( fieldput( mfpos, archive->( fieldget( y ) ) ) )
       endif
      next y

      master->onorder += poline->qty

     endif

    else
     master->onorder += poline->qty

    endif
    poline->( dbskip() )
   enddo

   special->( dbclosearea() )
   poline->( dbclosearea() )
   master->( dbclosearea() )
   stock->( dbclosearea() )
   macatego->( dbclosearea() )
   archive->( dbclosearea() )

// Now for the Members files
   mFArr := directory( mFilePath + '\fme?????.txt' )
   
   if len( mFArr ) > 0

    marr := {}
    aadd( marr, { 'flag','c', 1, 0 } )
    aadd( marr, { 'number','c', 6, 0 } )
    aadd( marr, { 'title', 'c', 10, 0 } )
    aadd( marr, { 'initials','c', 10, 0 } )
    aadd( marr, { 'given', 'c', 30, 0 } )
    aadd( marr, { 'surname','c', 30, 0 } )
    aadd( marr, { 'address','c', 70, 0 } )

    dbcreate( 'membunix', marr )
   
    if Netuse( 'membunix', EXCLUSIVE )
     
     Highlight( statline, 4, 'Appending from Unix members file', '' )

     for x := 1 to len( mFArr )

      append from ( mFilePath + '\' + mFarr[ x, 1 ] ) while Pinwheel( NOINTERUPT ) delimited

      frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 

     next 

     Highlight( statline, 4, 'Adding to Bookscan members file', membunix->( reccount() ) )
     statline++

     membunix->( dbclosearea() )

     select members
     set index to
     
     append from membunix while Pinwheel( NOINTERUPT )

     kill( 'membunix.dbf' )

    endif

   endif 

   mFArr := directory( mFilePath + '\ctl?????.txt' )
   for x := 1 to len( mfarr )
    frename( mFilePath + '\' + mFarr[ x, 1 ], mFilePath + '\' + left( mfarr[ x, 1], at( '.', mFarr[ x, 1 ] ) ) + 'foo' ) 
   next

  endif
   
  dbcloseall()

 endif   

 Error( "DB Load finished ", statline, , "Time to perform routine " ;
       + Ns( ( seconds()-mbegin)/60, 4 ) + " minutes "+ ;
         Ns( ( seconds()-mbegin)%60, 2 ) + "  seconds " ) 
 
 Audit( "DBLoadFin" )

endcase
setcursor( oldcur )
return nil

*  

procedure Invform ( minvno, mprinter )

#define SETUP_OFFSET 30
#define ST_ROW 6

local row,p_tot:=0,mtotdisc:=0,pass:=1,arebo:=FALSE,mdisctot, x
local mordno:='+@#@#=',tax_tot:=0,page:=1,qty_tot:=0, p_ext, mtemp, mtax
local pwidth := lvars( val( substr( lvars( L_PRINTER ), 4, 1 ) ) + 7 )

invhead->( dbseek( minvno ) )
customer->( dbseek( invhead->key ) )

default mprinter to upper( invhead->printer )

if mprinter = "DOCKET"

 Error( 'Please Insert Invoice Slip for printing.', 12 )

 Setprc( 0, 0 )
 Print_find( 'docket' )
 

 Dock_line( chr( K_ESC ) + 'f' + chr( 1 ) + chr( 10 ) )  // Setup Epson Slip Printer

 set device to print
 set console off
 for x := 1 to ST_ROW
  @ prow() + 1, 0 say SLIP + ' '
 next 
 @ prow() + 1, SETUP_OFFSET say if( invhead->inv, 'Invoice ', 'Credit Note' ) ;
          + left( Bvars( B_BRANCH ),2) + ':' + padl( invhead->number, 6, '0')
 @ prow(), SETUP_OFFSET + 35 say dtoc( invhead->date )
 @ prow() + 1, SETUP_OFFSET say Lookitup( 'branch', Bvars( B_BRANCH ) )
 @ prow() + 5, SETUP_OFFSET say customer->name
 @ prow() + 1, SETUP_OFFSET + 35 say customer->key 
 @ prow() + 1, SETUP_OFFSET say customer->add1
 @ prow() + 1, SETUP_OFFSET say customer->add2 
 @ prow() + 1, SETUP_OFFSET say customer->add3 
 @ prow() + 1, SETUP_OFFSET + 35 say invhead->order_no
 @ prow() + 3, SETUP_OFFSET say ' '

 p_tot := 0
 while !invline->( eof() ) .and. invline->number = minvno .and. Pinwheel( NOINTERUPT )
  @ prow()+1, SETUP_OFFSET say left( master->title, 30 )
  @ prow(), SETUP_OFFSET + 40 say transform( invline->price, '99999.99' )
  p_tot += round( invline->price * invline->qty, 2 )
  invline->( dbskip() )
 enddo
// @ 35, SETUP_OFFSET+ 40 say transform( p_tot, '99999.99' )
// @ 35, SETUP_OFFSET+ 20 say padr('Sub total  ',20) + transform( p_tot, '99999.99' )
 @ 35, SETUP_OFFSET+ 19 say padr('Total  ',20) + transform( p_tot, '$99999.99' )     // SWW 23/01/96
 //--- Start of additions to docket format! SWW 12/01/96
 p_tot := round( p_tot, 2 )

 mdisctot := 0              // moved outside the if test. it crashes otherwise.

 if invhead->tot_disc > 0 .and. invhead->tot_disc <= 100 // David

  invline->( dbseek( invhead->number ) )

  while invline->number = invhead->number .and. !invline->( eof() )

   if !master->nodisc
    mdisctot += invline->qty * ( invline->price/100 * invhead->tot_disc )
   endif

   invline->( dbskip() )

  enddo 

  tax_tot := Zero( tax_tot, round( Zero( mdisctot, p_tot ), 2 ) )     // Rationalise tax ??

  p_tot -= mdisctot

 endif

 if mdisctot > 0
//   @ prow()+1, SETUP_OFFSET+ 20 say padr('Discount  ',20) + transform( mdiscTot, '99999.99' )
   @ prow()+1, SETUP_OFFSET+ 19 say padr('Discount  ',20) + transform( mdiscTot, '$99999.99' )      // SWW 23/01/96
//   @ prow()+1, SETUP_OFFSET+ 20 say padr('Total  ',20) + transform( p_tot, '99999.99' )
 endif

//--- SWW 23/01/96
// if invhead->deposit != 0
//   @ prow()+1, SETUP_OFFSET+ 20 say padr('Deposit value  ',20) + transform( invhead->deposit, '99999.99' )
// endif
//
// if invhead->payment != 0
//   @ prow()+1, SETUP_OFFSET+ 19 say padr('Less Payment Received  ',21) + transform( invhead->payment, '99999.99' )
// endif
 
 if invHead->Payment - p_tot != 0
  if invHead->Payment - p_tot > 0                           // SWW 05/01/96
    @ prow()+1, SETUP_OFFSET+ 19 say padr('Deposit Remaining  ',20) + transform( abs( invHead->Payment - p_tot), '$99999.99' )
  else
    @ prow()+1, SETUP_OFFSET+ 19 say padr('Balance Owing  ',20) + transform( abs( invHead->Payment - p_tot), '$99999.99' )
  endif
 endif
 //--- End of additions to docket format! SWW 12/01/96

 Dock_line( chr( K_ESC ) + 'c0' + chr( 1 ) )  //'Unsetup' Slip printer

 set device to screen
 set console on

else 

 setprc( 0, 0 )
 
 Pitch10()
 Pitch12()
 set device to print
 set console off
 Invformhead( minvno, FALSE, TRUE )

 invline->( dbseek( invhead->number ) )

 if pass = 2 .and. arebo
  @ prow()+2,10 say 'Backordered'
 endif

 while !invline->( eof() ) .and. invline->number = minvno .and. Pinwheel( NOINTERUPT )

  arebo := if( invline->ord - invline->qty > 0, TRUE, arebo  ) // David

  if invline->isbn = '*' .and. pass = 1
   @ prow()+1,0 say invline->comments
  else
   if invline->isbn != '*'

    @ prow()+1, 0 say Isbncheck( master->isbn )
    @ prow(),  16 say invline->req_no
    @ prow(),  34 say invline->qty pict QTY_PICT
    @ prow(),  39 say invline->ord-invline->qty pict QTY_PICT
    @ prow(),  44 say left( master->title, Backspace( 25, master->title ) )

    @ prow(),  74 say invline->sell pict PRICE_PICT
    @ prow(),  83 say Percent( invline->price, invline->sell ) pict '99.9'

    @ prow(),  88 say invline->price * invline->qty pict TOTAL_PICT

    p_tot += round( invline->price * invline->qty, 2 )
    p_ext = invline->price * invline->qty
    tax_tot += if(customer->exempt,0,p_ext-((p_ext)*(1/(1+(Stret()/100)))))
    qty_tot += invline->qty

    if len( trim( master->title ) ) > 25
     @ prow()+1, 45 say substr( master->title, backspace( 25, master->title ), 24 )
    endif
    if !empty( master->author )
     @ prow() +1, 45 say left( master->author, 35 )
    endif  

   endif

   if !empty( invline->comments ) .and. invline->isbn != '*'
    @ prow()+1,06 say ':' + alltrim( invline->comments )
   endif
   if prow() > 48
    @ prow()+1,10 say 'continued....'
    Invformhead( minvno, FALSE, FALSE )
   endif
  endif

  invline->( dbskip() )

 enddo

 if !empty( invhead->message1 )
  if prow() > 48
   Invformhead( minvno, FALSE, FALSE )
  endif
  @ prow()+1,05 say B_TLEFT+replicate( ULINE_CHAR, 42 )+B_TRIGHT
  @ prow()+1,05 say SIDES+' '+invhead->message1+' '+SIDES
  @ prow()+1,05 say SIDES+' '+invhead->message2+' '+SIDES
  @ prow()+1,05 say SIDES+' '+invhead->message3+' '+SIDES
  @ prow()+1,05 say B_BLEFT+replicate( ULINE_CHAR,42 )+B_BRIGHT
 endif

 @ prow()+1,0 say replicate( ULINE_CHAR, 96 )
 @ prow()+1,10 say 'Total Qty of Books'
 @ prow(), 34 say qty_tot pict QTY_PICT
// @ prow(), 74 say 'Sub-total'
 @ prow(), 74 say 'Total'               // SWW 23/01/96
 @ prow(), 87 say p_tot pict '$'+TOTAL_PICT

 if !empty( invhead->freight )
  @ prow()+1, 60 say 'Plus Postage & Handling'
  @ prow(),87 say invhead->freight pict '$'+TOTAL_PICT
  p_tot += invhead->freight
 endif

 p_tot := round( p_tot, 2 )

 mdisctot := 0                      // SWW 16/01/96 - Bug EB/960116/1

 if invhead->tot_disc > 0 .and. invhead->tot_disc <= 100 // David

  invline->( dbseek( invhead->number ) )

  while invline->number = invhead->number .and. !invline->( eof() )

   if !master->nodisc
    mdisctot += invline->qty * ( invline->price/100 * invhead->tot_disc )
   endif

   invline->( dbskip() )

  enddo 

  tax_tot := Zero( tax_tot, round( Zero( mdisctot, p_tot ), 2 ) )     // Rationalise tax ??

  p_tot -= mdisctot

 endif

 if mdisctot > 0
  @ prow()+1, 75 say 'Discount'
  @ prow(),87 say mdisctot pict '$'+TOTAL_PICT
 endif

// @ prow()+1,0 say replicate( ULINE_CHAR, 96 )
//
// @ prow()+1, 78 say 'Total'
// @ prow(), 87 say p_tot pict '$'+TOTAL_PICT
 
 if invhead->deposit != 0 
  @ prow()+1, 67 say 'Deposit'
  @ prow(), 87 say invhead->deposit pict '$'+TOTAL_PICT
 endif 

//--- SWW 23/01/96
// if invhead->payment != 0
//  @ prow()+1, 62 say 'Less Payment Received'
//  @ prow(), 87 say invhead->payment pict '$'+TOTAL_PICT
///*  @ prow()+1, 60 say 'Method of Payment'
//  @ prow(), 87 say invhead->   */
// endif
 
 if invhead->custbal != 0 
  if invhead->custbal > 0                           // SWW 05/01/96
     @ prow()+1, 66 say 'Deposit Remaining'
  else
     @ prow()+1, 70 say 'Balance Owing'
//     @ prow()+1, 70 say 'Amount Owing'
  endif
  @ prow(), 87 say invhead->custbal pict '$'+TOTAL_PICT
 endif
  
 @ prow()+3, 0 say 'All Payments to:                      All Queries to:'
 @ prow()+1, 0 say ' UNI CO-OP BOOKSHOP                   ' + CoopName()
 @ prow()+1, 0 say ' P.O. BOX 54                          ' + trim( Bvars( B_ADDRESS1 ) )
 @ prow()+1, 0 say ' BROADWAY  N.S.W. 2007                ' + padr( Bvars( B_ADDRESS2 ), 20 ) + ' Phone : ' + BVars( B_PHONE)
 @ prow()+1, 0 say '                                      ' + padr( Bvars( B_SUBURB ), 20 ) + ' Fax   : ' + BVars( B_FAX)

 Pitch10()
 Endprint()
 set console on
 set device to screen

endif
return

*

Procedure invformhead ( p_invno, mpickslip, newinv )
static page
local lUsePostForDelivery
if newinv
 page := 1
else
 eject
endif
#define VERT_BAR chr( 179 )
setprc( 0, 0 )
@ prow(),5 say 'Date  ' + dtoc(invhead->date)
if !mpickslip
 if invhead->inv
  @ prow(),60 say if( invhead->proforma,'Pro-Forma ','') ;
              +'Invoice No: ' + left( Bvars( B_BRANCH ),2) + ':' + Ns( p_invno )
 else
  @ prow(),60 say 'Credit No: ' + left( Bvars( B_BRANCH ),2) + ':' + Ns( p_invno )
 endif
else
 @ prow(),60 say 'Picking Slip No: ' + left( Bvars( B_BRANCH ),2) + ':' + Ns( p_invno )
endif
@ prow()+1,5 say 'Account No : ' + customer->key
@ prow(),60 say 'Page No :' + Ns(page,3)
page++
@ prow()+2, 57 say 'If not claimed please return to :'
@ prow()+1, 57 say 'UNVERSITY CO-OPERATIVE BOOKSHOP'
// @ prow()+1, 57 say 'P.O. BOX 54, BROADWAY NSW 2007'
@ prow()+1, 57 say trim( Bvars( B_ADDRESS1))+' '+ trim(Bvars( B_ADDRESS2) ) + '  ' + trim( Bvars( B_SUBURB  ) )

if !mpickslip
 if invhead->inv
  @ prow()+2,0 say 'Invoice to :'
  @ prow(),55 say 'Deliver to :'
 else
  @ prow()+2,0 say 'Credit  to :'
 endif
endif

lUsePostForDelivery  := empty( customer->dadd1 + customer->dadd2 + customer->dadd3 +customer->dpcode)
@ prow()+1,24 say customer->name
@ prow(),65   say customer->name
@ prow()+1,24 say customer->add1
@ prow(),65 say iif( lUsePostForDelivery, customer->add1, customer->dadd1)
@ prow()+1,24 say customer->add2
@ prow(),65 say iif( lUsePostForDelivery, customer->add2, customer->dadd2) 
@ prow()+1,24 say trim(customer->add3)+' '+customer->pcode
@ prow(),65 say iif( lUsePostForDelivery, trim(customer->add3)+' '+customer->pcode ,trim(customer->dadd3)+' '+customer->dpcode)

@ prow()+1,0 say replicate( ULINE_CHAR, 96 )
if !mpickslip
 @ prow()+1,4 say 'ISBN'
 @ prow(),14 say VERT_BAR
 @ prow(),16 say 'Order Number'
 @ prow(),32 say VERT_BAR
 @ prow(),34 say 'Qty'
 @ prow(),38 say VERT_BAR
 @ prow(),39 say 'B/O'
 @ prow(),42 say VERT_BAR
 @ prow(),44 say 'Title / Author'
 @ prow(),72 say VERT_BAR
 @ prow(),76 say 'Price'
 @ prow(),83 say VERT_BAR
 @ prow(),84 say 'Dsc'
 @ prow(),87 say VERT_BAR
 @ prow(),92 say 'Nett'
 @ prow()+1,0 say replicate( ULINE_CHAR, 96 )
else
 @ prow()+1,0 say 'Picked'
 @ prow(),6 say ' Qty '
 @ prow(),13 say 'Title'
 @ prow(),46 say 'ISBN'
 @ prow(),59 say IMPRINT_DESC
 @ prow(),76 say AUTHOR_DESC
 @ prow(),92 say 'Sta'
 @ prow(),96 say 'Bi'
 @ prow()+1,0 say replicate( ULINE_CHAR, 80 )
endif
return
*
proc PickSlip ( minvno )
local pwidth := lvars( val( substr( lvars( L_PRINTER ), 4, 1 ) ) + 7 )
setprc(0,0)

set device to print
set console off
select pickslip
set relation to pickslip->isbn into master,;
             to pickslip->key into customer
Invformhead( minvno, TRUE, TRUE )
Pitch17()

pickslip->( dbseek( minvno ) )

while !pickslip->( eof() ) .and. pickslip->number = minvno .and. Pinwheel()
 @ prow()+1,00 say '[     ]'
 @ prow(),07 say pickslip->qty pict '9999'
 @ prow(),13 say substr(master->title,1,30)
 @ prow(),45 say Isbncheck( master->isbn )
 @ prow(),58 say substr( Lookitup( "imprint" , master->imprint ) , 1, 15 )
 @ prow(),75 say substr(master->author,1,15)
 @ prow(),92 say master->status
 @ prow(),96 say master->binding
 if prow() > 55
  @ prow()+1,10 say 'continued....'
  Pitch10()
  Invformhead( minvno, TRUE, FALSE )
 endif
 pickslip->( dbskip() )
enddo

select pickslip
set relation to

Pitch10()
EndPrint()
set console on
set device to screen
return
*
procedure Poform ( ponum )
local row := 23, page_no:=1, mimprint, potot:=0, mcom, maxwidth := 76, x, mlines
setprc(0,0)

Pitch10()
set device to printer
set console off
pohead->( ordsetfocus( BY_NUMBER ) )
pohead->( dbseek( ponum ) )
supplier->( dbseek( pohead->supp_code ) )
Quality()
@ 00,25 say BIGCHARS + 'Purchase Order'
@ 01,00 say (substr(dtoc(pohead->date_ord),1,2)+'-'+substr(cmonth(pohead->date_ord),1,3);
            +'-'+substr(dtoc(pohead->date_ord),7,2))
@ 01,62 say if( !Oddvars( NZ ), if( empty(Bvars( B_ACN ) ) , '', "A.C.N. "+Bvars( B_ACN ) ) , ""  )
@ 02,00 say 'Supply to the order of :' +BIGCHARS + trim(LICENSEE)
@ 03,25 say Bvars( B_ADDRESS1 )
if !empty( Bvars( B_ADDRESS2 ) )
 @ 04,25 say Bvars( B_ADDRESS2 )
 @ 05,25 say trim( Bvars( B_SUBURB ) )
 @ 06,25 say Bvars( B_COUNTRY )
 @ 07,25 say 'Tel  ' + Bvars( B_PHONE )
 @ 08,25 say 'Fax  ' + Bvars( B_FAX )
else
 @ 04,25 say trim( Bvars( B_SUBURB ) )
 @ 05,25 say Bvars( B_COUNTRY )
 @ 06,25 say 'Tel  ' + Bvars( B_PHONE )
 @ 07,25 say 'Fax  ' + Bvars( B_FAX )
endif
@ 10,00 say 'Account No.  :' + supplier->Account
@ 12,00 say BIGCHARS + 'Our Order No : '+ Ns(ponum)
@ 15,15 say supplier->name
@ 16,15 say supplier->Address1
@ 17,15 say supplier->Address2
@ 18,15 say trim(supplier->City)
@ 19,15 say trim(supplier->country)
@ 21,00 say 'Fax No. ' + supplier->fax
@ 22,00 say '---'
@ 22,76 say '---'
Poheader( row, ponum, page_no )
poline->( dbseek( ponum ) )
while poline->number = ponum .and. !poline->( eof() ) .and. Pinwheel( NOINTERUPT )
 @ prow()+1,0 say if( !empty( master->catalog ), master->catalog, Isbncheck( master->isbn ) ) 
 @ prow(),13 say poline->qty pict '9999'
 @ prow(),20 say left(master->title, Backspace() )
 @ prow(),61 say left(master->author, 14)
 @ prow(),76 say master->binding
 if len( trim( master->title ) ) > 40
  @ prow()+1,20 say substr( master->title, Backspace()+1, 40 )
 endif
 if !empty( poline->comment )
  @ prow()+1,5 say '** ' + trim( poline->comment )
 endif
 potot += master->cost_price * poline->qty
 poline->( dbskip() )
 if prow() > 52
  if poline->number = ponum .and. !poline->( eof() )
   Page_no++
   @ prow()+1,0 say replicate( ULINE_CHAR, 80 )
   Poheader( 1, ponum, page_no )
  endif
 endif
enddo
@ prow()+1,00 say replicate( ULINE_CHAR, 80 )
Pitch10()
mcom := Lookitup( 'poinstru', pohead->instruct )
if !empty( mcom )
 mcom := strtran( mcom, '%NUMBER%', Ns( ponum ) )
 if '%BIG%' $ mcom
  mcom := strtran( mcom, '%BIG%' )
  maxwidth := 38
 endif 
 mlines := mlcount( mcom, maxwidth ) 
 @ prow() + 2, 02 say 'Ú' + '< Purchase Order Instructions >' + replicate( ULINE_CHAR, 45 ) + chr( 191 ) 
 for x := 1 to mlines
   @ prow()+1, 02 say chr( 179 ) + if( maxwidth = 38, BIGCHARS, '' ) + memoline( mcom, maxwidth, x ) + ;
                      if( maxwidth = 38, NOBIGCHARS, '' ) + chr( 179 ) 
 next
 @ prow() + 1, 02 say chr( 192 ) + replicate( ULINE_CHAR, 76 ) + chr( 217 )
endif
set relation to
set console on
set device to screen
Draft()
Endprint()
return
*
procedure Poheader ( head_row, ponum, page_no )
if page_no > 1
 @ head_row,00 say LICENSEE
 @ head_row,40 say 'Page No.' + Ns( page_no )
 @ head_row,60 say 'Our Order No.' + Ns( ponum, 6 )
endif
@ head_row+1,00 say '   ' + ISBN_DESC + '        Qty  Title'
@ head_row+1,62 say AUTHOR_DESC
@ head_row+1,76 say 'Bi'
@ head_row+2,00 say replicate( ULINE_CHAR, 80 )
return
*
proc Specletter ( p_req, p_issued, specordno, mcomments, spec_dep, spec_date, price )
set device to print
set console off
Pitch10()
@ 0,0 say BIGCHARS + 'Special Order No ' + Ns( specordno )
@ prow()+1, 60 say BIGCHARS + dtoc( Bvars( B_DATE ) )
@ prow()+1, 0 say chr(27)+chr(31)+chr(1)+BIGCHARS+LICENSEE;
            +chr(27)+chr(31)+chr(0)
@ prow()+1, 0 say Bvars( B_ADDRESS1 )
if !empty( Bvars( B_ADDRESS2 ) )
 @ prow()+1, 0 say Bvars( B_ADDRESS2 )
 @ prow()+1, 0 say trim( Bvars( B_SUBURB ) )
 @ prow()+1, 0 say Bvars( B_PHONE )
else
 @ prow()+1, 0 say trim( Bvars( B_SUBURB ) )
 @ prow()+1, 0 say Bvars( B_PHONE )
endif
@ prow()+2, 15 say customer->name
@ prow()+1, 15 say customer->add1
@ prow(),55 say '(Ph) ' + customer->phone1
if !empty( customer->add2)
 @ prow()+1, 15 say trim(customer->add2)+if(empty(customer->add3),' '+customer->pcode,'')
endif
if !empty( customer->add3)
 @ prow()+1, 15 say trim(customer->add3)+' '+customer->pcode
endif
@ prow()+3, 0 say '--                                                                       --'
@ prow()+1, 0 say 'Dear Customer,'
@ prow()+2, 0 say 'We have received the following title as per your Special Order'
@ prow()+2, 0 say 'ISBN     ' + Isbncheck( master->isbn )
@ prow()+1, 0 say 'Title    ' + master->title
@ prow()+1, 0 say 'Author   ' + master->author
@ prow()+1, 0 say 'Qty Ord  ' + Ns( p_req )
@ prow()+1, 0 say 'Price   $' + Ns( price, 7, 2 )
if p_req != p_issued
 @ prow()+1, 0 say 'Qty Rec  ' + Ns(p_issued)
endif
if !empty( mcomments )
 @ prow()+1, 0 say 'Order Comments ' + mcomments
endif
if spec_dep > 0
 @ prow()+2, 0 say 'Deposit Paid ' + Ns( spec_dep )
endif
@ prow()+2, 0 say 'This Order is now ready for collection. If you would like us to send'
@ prow()+1, 0 say 'this book to you, please telephone and have your Credit Card Number'
@ prow()+1, 0 say 'ready (Master, Visa, Amex,Diners or Bankcard) and we will be happy to'
@ prow()+1, 0 say 'forward your order.'
@ prow()+2, 0 say 'Yours Faithfully'
@ prow()+5, 0 say 'For ' + LICENSEE
@ prow()+4, 0 say 'Please Note.'
@ prow()+1, 0 say chr( K_ESC )+'E'+'We would appreciate if the books could be collected within two weeks'
@ prow()+1, 0 say 'or telephone us if there will be a delay.'+chr( K_ESC )+'F'
Endprint()  
set device to screen
return
*

Function MemberLook ( mnumber )

local tscr := Bsave() // Save the whole screen
local marr            // Menu Array
local mchoice         // Choice selected
local membrow         // Members Browse Object 
local mscr            // Screen saved
local hitkey          // Key struck during browsing
local mmacro          // type of enquiry made
local mkey            // Key to lookup
local getlist := {}
local x
local mret := ''

if !file( Oddvars( SYSDRIVE ) + 'members\members.dbf' )
 Error( 'No Members file installed', 12 )

else

 if Netuse( Oddvars( SYSDRIVE ) + 'members\members' )
  Heading('Member File Enquiry')
  marr := {}
  aadd( marr, { 'Exit', 'Return to previous option' } )
  aadd( marr, { 'Number', 'Search members file by number' } )
  aadd( marr, { '4x4', '4 x 4 Search on Surname + Given Name' } )
  mchoice := MenuGen( marr, 17, 36, 'Members' )
  while mchoice > 1

   do case
   case mchoice = 2
    mmacro := 'Number'
    members->( ordsetfocus( 'number' ) )
   case mchoice = 3
    mmacro := 'Surname'
    members->( ordsetfocus( '4x4' ) )
   endcase

   Heading( 'Inquire by ' + mmacro )
   mkey := space( if( mchoice = 2, 6, 8 ) ) 
   @ 17 + mchoice,46 say 'ÍÍÍÍ¯' get mkey pict '@K!'
   read
   if lastkey() = K_ESC
    exit
   else

    if mchoice = 2
     mkey := padl( mkey, 6, '0' )
    endif 

    if members->( dbseek( trim( mkey ) ) )

     mscr:=Bsave( 01, 00, maxrow(), maxcol() )
     for x = 1 to maxrow()-4
      @ x+3,1 say row()-3 pict '99'
     next
 
     membrow:=tbrowsedb( 02, 04, maxrow()-1, maxcol()-1 )
     membrow:colorspec := if( lvars( L_COLOR ), TB_COLOR, setcolor() )
     membrow:HeadSep:=HEADSEP
     membrow:ColSep:=COLSEP
     membrow:goTopBlock:={ || dbseek( mkey ) }
     membrow:goBottomBlock := { || jumptobott( mkey ) }
     membrow:skipBlock := KeySkipBlock( { || if( mchoice=2,members->number, upper( left( members->surname, 4 ) )+upper( left( members->given, 4 ) ) ) }, trim( mkey ) )
     membrow:addcolumn( tbcolumnnew( 'Number', { || members->number } ) )
     membrow:addcolumn( tbcolumnnew( 'Surname', { || members->surname } ) )
     membrow:addcolumn( tbcolumnnew( 'Address', { || left( members->address, 30 ) } ) )
     membrow:addcolumn( tbcolumnnew( 'Given Name', { || members->given } ) )
     membrow:addcolumn( tbcolumnnew( 'Title', { || members->title } ) )
     hitkey := 0
     while hitkey != K_ESC .and. hitkey != K_END
      membrow:forcestable()
      hitkey := inkey(0)
      if !Navigate( membrow, hitkey )
       if hitkey == K_ENTER
        Oddvars( MEMBER_NAME, trim( members->given ) + ' ' + trim( members->surname ) )
        mret := members->number
        exit
       endif
      endif 
     enddo 
     Brest( mscr )
    endif
   endif
  enddo
  members->( dbclosearea() )
 endif    
endif
Brest( tscr )
return mret

*

Function MemCheck ( checknum )
local oldsel := select(), mret := ''
if !Netuse( Oddvars( SYSDRIVE ) + 'members\members' )
 Error( 'Cannot open members file - Contact Head Office', 12 )
else
 members->( ordsetfocus( 'number' ) )
 if !members->( dbseek( padl( checknum, 6, '0' ) ) )
  Error( 'Member number not found against member file', 12 )
  members->( dbclosearea() )
  checknum := MemberLook( checknum )
 else
  Oddvars( MEMBER_NAME, trim( members->given ) + ' ' + trim( members->surname ) )
  checknum := members->number
  members->( dbclosearea() )
 endif
endif
select( oldsel )
return TRUE

*
 
function Mail
local mailbrow, hitkey, getlist := {}, x, mscr, tscr
local mess, mtarget, y, mfpos, mto, marr, oldcur := setcursor( 1 )
local olddbf := select(), mhlparr, c, msecs, mresponse, master_open:=FALSE, master_rec
local okf10
local masterord
local misbn

if select( 'master' ) = 0
 if !Master_use()
  return nil
 endif
else
 master_open := TRUE
 master_rec := master->( recno() )
 masterord := master->( ordsetfocus( BY_ISBN ) )
endif

if Netuse( 'archive\archive' )
 if Netuse( 'ftmail' )
  if Netuse( 'branch' )
   if Netuse( 'mail' )
    mscr:=Bsave( 00, 00, maxrow(), maxcol() )
    Heading( 'Mail System' )
    Bsave( 01, 00, maxrow(), maxcol() )
    for x = 1 to maxrow()-4
     @ x+3,1 say row()-3 pict '99'
    next

    mailbrow:=tbrowsedb( 02, 04, maxrow()-1, maxcol()-1 )
    mailbrow:colorspec := if( lvars( L_COLOR ), TB_COLOR, setcolor() )
    mailbrow:HeadSep:=HEADSEP
    mailbrow:ColSep:=COLSEP

    c := tbcolumnnew( 'Read', { || if( mail->read, 'Read', 'Wait' ) } ) 
    c:colorblock := { || if( mail->read,  {5, 6}, {1, 2} ) }
    mailbrow:addcolumn( c )
    c := tbcolumnnew( 'From', { || left( mail->id, 3 ) } ) 
    c:colorblock := { || if( mail->to != Bvars( B_BRANCH ),  {3, 4}, {1, 2} ) }
    mailbrow:addcolumn( c )
    mailbrow:addcolumn( tbcolumnnew( 'To', { || left( mail->to, 3 ) } ) )
    mailbrow:addcolumn( tbcolumnnew( 'Date', { || PickDate( substr( mail->id, 5, 5 ) ) } ) )
    mailbrow:addcolumn( tbcolumnnew( 'Time', { || PickTime( substr( mail->id, 11, 5 ) ) } ) )
    mailbrow:addcolumn( tbcolumnnew( 'ISBN', { || Isbncheck( mail->isbn ) } ) )
    mailbrow:addcolumn( tbcolumnnew( 'Text', { || left( mail->message1, 25 ) } ) )
    hitkey := 0
    while hitkey != K_ESC .and. hitkey != K_END
     mailbrow:forcestable()
     hitkey := inkey(0)
     do case
     case hitkey == K_F1
      Build_help( { { 'Ins', 'Create new mail message' }, ;
                    { 'Del', 'Delete mail Message' }, ;
                    { 'F10', 'Look at Title Info' }, ;
                    { 'Enter', 'Read Message' } } )
                  
     case hitkey == K_F10
      if empty( mail->isbn )
       Error( 'No ISBN referenced here', 12 )
      else
       if !CodeFind( mail->isbn )
        if !archive->( dbseek( mail->isbn ) )
         Error( 'This title not on found on Master or Archive Files', 12 )
        else
         mscr:=Bsave(2,08,8,72)
         Highlight(3,10,' Title ',archive->title)
         Highlight(5,10,'Author ',archive->author)
         Error( 'Title is in Archive - You will need to retreive later', 12 )
        endif 
       else 
        TitleDisp( FALSE )
       endif
      endif                 
      select mail

     case hitkey == K_INS
      marr := {}
      while TRUE
       mtarget := space( BRANCH_CODE_LEN )
       Bsave( 3, 10, 5, 30 )
       @ 4, 12 say 'Target Store' get mtarget pict '@!' ;
               valid( mtarget != Bvars( B_BRANCH ) .and. ;
               ( mtarget $ '   |ALL|POS|RES' .or. dup_chk( mtarget, 'branch' ) ) )
       read
       if !updated() 
        exit 

       else

        if mtarget $ 'ALL|POS|RES'
         marr := {}
         aadd( marr, mtarget )
         exit

        else 
         aadd( marr, mtarget )

        endif

        bsave( 2, 50, len( marr ) + 3, 55 )
        for x := 1 to len( marr )
         @ 2 + x, 51 say marr[ x ]
        next 

       endif 

      enddo

      if lastkey() != K_ESC .and. !empty( marr )
       tscr := Bsave( 14, 02, 23, 76 )
       Highlight( 14, 06, '', '[ Ctrl-W to Save Message. Esc to Exit ]' )
       mess := space( 500 )
       misbn := space( ISBN_CODE_LEN )

       okf10 := setkey( K_F10, { || MailISBN( @misbn ) } )
       mess := memoedit( mess, 15, 03, 22, 75, TRUE )
       setkey( K_F10, okf10 )

       if lastkey() != K_ESC

        msecs := Ns( int( seconds() ) )

        for x := 1 to len( marr )

         mto := marr[ x ]

         Add_rec( 'mail' )
         mail->id := Bvars( B_BRANCH ) + '*' + PickDate( Bvars( B_DATE ) ) + '*' + msecs
         mail->to := mto
         mail->message1 := left( memotran( mess ), 250 )
         mail->message2 := substr( memotran( mess ), 251, 250 )
         mail->date := Bvars( B_DATE )
         mail->time := time()
         mail->isbn := misbn
         mail->( dbrunlock() )
 
         Add_rec( 'ftmail' )
 
         for y := 1 to mail->( fcount() )
          mfpos := ftmail->( fieldpos( mail->( fieldname( y ) ) ) )
          if mfpos != 0
           ftmail->( fieldput( mfpos, mail->( fieldget( y ) ) ) )
          endif
         next y

         ftmail->flag := 'A'
         ftmail->( dbrunlock() )

        next

       endif 
       Brest( tscr )
      endif
      mail->( dbgotop() )
      mailbrow:refreshall()
     
     case hitkey == K_ENTER

      tscr := Bsave( 02, 02, 23, 76 )
      Highlight( 02, 06, '', '[ Ctrl-W to Save Message. Esc to Exit' )
      mess := trim( mail->message1 ) + ' ' + trim( mail->message2 )
      Bsave( 03, 03, 12, 75 )
      keyboard chr( K_ESC )
      memoedit( mess, 04, 04, 11, 74, FALSE )  

      mresponse := mail->response
      Bsave( 13, 03, 22, 75 )
      mresponse := memoedit( mresponse, 14, 04, 21, 74, TRUE )

      if trim( mresponse ) != trim( mail->response )

       Add_rec( 'ftmail' )
 
       for y := 1 to mail->( fcount() )
        mfpos := ftmail->( fieldpos( mail->( fieldname( y ) ) ) )
        if mfpos != 0
         ftmail->( fieldput( mfpos, mail->( fieldget( y ) ) ) )
        endif
       next y
       ftmail->response := memotran( trim( mresponse ) )
       ftmail->flag := 'C'
       ftmail->( dbrunlock() )

      endif

      Rec_lock( 'mail' )
      mail->read := TRUE
      mail->response := mresponse
      mail->( dbrunlock() )
      brest( tscr )
      mailbrow:refreshcurrent()
     
     case hitkey == K_DEL
      if left( mail->id, 3 ) != Bvars( B_BRANCH )
       Error( 'You cannot delete mail from other branches', 12 )

      else

       if Isready( 12, 10, 'Ok to delete this message' )

        Add_rec( 'ftmail' )

        for y := 1 to mail->( fcount() )
         mfpos := ftmail->( fieldpos( mail->( fieldname( y ) ) ) )
         if mfpos != 0
          ftmail->( fieldput( mfpos, mail->( fieldget( y ) ) ) )
         endif
        next y
        ftmail->flag := 'D'
        ftmail->( dbrunlock() )

        Del_rec( 'mail', UNLOCK )
        mail->( dbgotop() )
        mailbrow:refreshall()

       endif 

      endif  

     otherwise 
      Navigate( mailbrow, hitkey )

     endcase

    enddo 
    Brest( mscr )
    mail->( dbclosearea() )
   endif 
   branch->( dbclosearea() )
  endif
  ftmail->( dbclosearea() )
 endif
 archive->( dbclosearea() )
endif

if !master_open
 master->( dbclosearea() )
else
 master->( ordsetfocus( masterord ) )
 master->( dbgoto( master_rec ) )
endif  

select ( olddbf )
setcursor( oldcur )
return nil

*

function Mailisbn ( misbn )
local mscr := Bsave( 3, 10, 5, 25 + ISBN_CODE_LEN )
local getlist := {}, mrow := row(), mcol := col()
misbn := space( ISBN_CODE_LEN )
@ 4, 12 say 'ISBN / Code' get misbn pict '@!'
read
@ mrow, mcol say ''
if updated()
 if Codefind( misbn )
  misbn := master->isbn
 endif
endif
return nil

*

function PickDate ( mdate )
if valtype( mdate ) = 'D'
 mdate := Ns( mdate - PICK_DATE )
else
 mdate := PICK_DATE + val( mdate )
endif 
return mdate 

*

function PickTime ( mstr )
return padl( int( val( mstr ) / 3600 ), 2, '0' ) + ':' + padl( val( mstr ) % 60, 2, '0' ) 

*

function Postage ( minvamt )
local postbrow, hitkey, getlist := {}, x, mscr, tscr
local oldcur := setcursor( 1 ), mval := 0

if Netuse( 'postage' )
 locate for postage->value > minvamt
 postage->( dbskip( -1 ) )
 Heading( 'Postage Listing' )
 mscr := Bsave( 04, 39, maxrow(), maxcol() )
 postbrow:=tbrowsedb( 05, 40, maxrow()-1, maxcol()-1 )
 postbrow:colorspec := if( lvars( L_COLOR ), TB_COLOR, setcolor() )
 postbrow:HeadSep:=HEADSEP
 postbrow:ColSep:=COLSEP
 postbrow:addcolumn( tbcolumnnew( 'Value', { || transform( postage->value, '9999.99' ) } ) )
 postbrow:addcolumn( tbcolumnnew( 'Description', { || postage->desc } ) )
 postbrow:addcolumn( tbcolumnnew( 'Local', { || Transform( postage->local, '9999.99' ) } ) )
 postbrow:addcolumn( tbcolumnnew( 'InterState', { || Transform( postage->interstate, '9999.99' ) } ) )
 hitkey := 0
 while hitkey != K_ESC .and. hitkey != K_END
  postbrow:forcestable()
  hitkey := inkey(0)
  do case
  case hitkey == K_ENTER
   mval := postage->local
   exit

  case hitkey == K_DEL
   if Isready( 3, 10, 'Ok to delete rate ' + trim( postage->desc ) + ' from table' )
    Del_rec( 'postage', UNLOCK )
    postage->( dbgotop() )
    postbrow:refreshall()
   endif

  case hitkey == K_INS
   tscr := Bsave( 2, 2, 7, 50 )
   Add_rec( 'postage' )
   @ 3, 4 say 'Invoice Value' get postage->value pict '9999.99'
   @ 4, 4 say '  Description' get postage->desc 
   @ 5, 4 say 'Local Postage' get postage->local pict '9999.99'
   @ 6, 4 say 'Inter Postage' get postage->interstate pict '9999.99'
   read
   if !updated()
    Del_rec( 'postage' )
   endif
   dbrunlock()
   Brest( tscr ) 
   postage->( dbgotop() )
   postbrow:refreshall()

  case hitkey == K_F10
   tscr := Bsave( 2, 2, 7, 50 )
   Rec_lock( 'postage' )
   @ 3, 4 say 'Invoice Value' get postage->value pict '9999.99'
   @ 4, 4 say '  Description' get postage->desc 
   @ 5, 4 say 'Local Postage' get postage->local pict '9999.99'
   @ 6, 4 say 'Inter Postage' get postage->interstate pict '9999.99'
   read
   postage->( dbrunlock() )
   Brest( tscr ) 
   postbrow:refreshcurrent()

  otherwise 
   Navigate( postbrow, hitkey )
  endcase
 enddo
 postage->( dbclosearea() )
 Brest( mscr )
endif 
setcursor( oldcur ) 
return mval

*

Function FloatChange
local amount := 0, getlist:={}, mscr, marr := {}, choice
if Netuse( 'sales' )
 aadd( marr, { ' Float Increase', 'Create extra float' } )
 aadd( marr, { 'Float Decrease', 'Replacement of float' } )
 choice := MenuGen( marr, 02, 02, 'Float' )
 if choice != 0
  Bsave( 6, 10, 8, 45 )
  @ 7, 12 say 'Amount of ' + if( choice = 1, 'Increase', 'Decrease' ) get amount pict '9999.99'
  read
  if amount != 0

   Dock_line( padr( 'Float ' + if( choice =1, 'Increase', 'Decrease' ), 32 ) + str( amount, 8, 2 ) )
   Dock_foot()
   Dock_head()
   
   Add_rec( 'sales' )
   sales->sale_date := Bvars( B_DATE )
   sales->time := time()
   sales->tran_num := Lvars( L_CUST_NO )
   sales->register := Lvars( L_REGISTER )
   sales->tran_type := 'FLO'
   sales->operator := Oddvars( OPERCODE )
   sales->voucher := padl( amount * if( choice = 1, -1, 1 ), 10 )
   sales->( dbrunlock() )

  endif 
 endif
 sales->( dbclosearea() )
endif
return nil  

*

function Coop_exit
local mscr := Bsave()
Swap2dos( 'coop' )
brest( mscr )
return nil

*

Function Coopvalidate ( mbranch )
/* Need to add at least one extra terminal to each count as a RAS from Ho is a terminal */
if branarr = nil
 branarr := {}
 aadd( branarr, { '450', 'Coop Bookshop UTS Kuringai', 4 } )
 aadd( branarr, { '250', 'Coop Bookshop Macquarie University', 15 } )
 aadd( branarr, { '160', 'Coop Bookshop University of Canberra', 5 } )
 aadd( branarr, { '999', 'Training', -1 } )
endif
return ( ascan( branarr, { |fred| fred[1] = Bvars( B_BRANCH ) } ) != 0 )

*

Function CoopTerms
// Returns the local Terminal Count from the Validation Array
local mterms := 1
if !empty( Bvars( B_BRANCH ) ) .and. Oddvars( VALIDATE )
 mterms := branarr[ ascan( branarr, { |fred| fred[1] = Bvars( B_BRANCH ) } ), 3 ]
endif
return mterms

*

Function CoopName
// Returns the local Bookshop Name from the Validation Array
local mname := ''
if !empty( Bvars( B_BRANCH ) ) .and. Oddvars( VALIDATE )
 mname := branarr[ ascan( branarr, { |fred| fred[1] = Bvars( B_BRANCH ) } ), 2 ]
endif
return mname

*

Function BatchPrint
local page_number, page_width, page_len, top_mar, bot_mar
local gtrcvqty, gtinvqty, gtamt, gtretail, gtamtA
local rcvqty, invqty, retail, amt, amtA, minv
local brcvqty, binvqty, bretail, bamt, bamtA, bminv
local col_head1, col_head2, mbatch, report_name
local msupp, mdate, moperator

if Netuse( 'ftrecpt', EXCLUSIVE )

 if Isready( 12, 10, 'Print the Batch Listing' )

  page_number:=1
  page_width:=132
  page_len:=66
  top_mar:=0
  bot_mar:=10
  gtrcvqty := gtinvqty := gtamt := gtretail := gtamtA := 0

  col_head1 := '  Supp   Supplier Name          Invoice#          Date       Amt     Amt A$   Retail$    Margin%   Inv Qty   Recv Qty   Op'
  col_head2 := '  Code'                          
  report_name := 'Batch Listing'

  Print_find( "report" )
  

  Pitch17()
  set device to printer
  setprc( 0, 0 )             

  PageHead( report_name, page_width, page_number, col_head1, col_head2 )

  gtrcvqty := gtinvqty := gtretail := gtamt := gtamtA := 0

  ftrecpt->( dbgotop() )

  while !ftrecpt->( eof() ) .and. Pinwheel() 

   if PageEject( page_len, top_mar, bot_mar )

    page_number++
    PageHead( report_name, page_width, page_number, col_head1, col_head2 )

   endif

   mbatch := ftrecpt->batch

   @ prow()+2, 0 say 'Batch #' + BIGCHARS + Ns( mbatch )

   brcvqty := binvqty := bretail := bamt := bamtA := 0

   while ftrecpt->batch = mbatch .and. !ftrecpt->( eof() ) 

    minv := ftrecpt->invoice

    moperator := ftrecpt->operator
    rcvqty := invqty := retail := amt := amtA := 0

    while ftrecpt->invoice = minv .and. !ftrecpt->( eof() ) 

     rcvqty += ftrecpt->qty
     invqty += ftrecpt->qty_inv
     retail += ( ftrecpt->sell_price * ftrecpt->qty )
     amt    += ( ftrecpt->cost_price * ftrecpt->qty )
     amtA  += ftrecpt->forexamt
     msupp := ftrecpt->supp_code
     mdate := ftrecpt->dreceived

     ftrecpt->( dbskip() )

    enddo

    @ prow()+1, 1 say msupp
    @ prow(), 10 say left( lookitup( 'supplier', msupp ), 20 )
    @ prow(), 32 say minv
    @ prow(), 48 say mdate
    @ prow(), 57 say amt pict TOTAL_PICT
    @ prow(), 66 say amta pict TOTAL_PICT
    @ prow(), 75 say retail pict TOTAL_PICT
    @ prow(), 89 say Percent( amt, retail ) pict '999.99'

    @ prow(), 101 say rcvqty pict QTY_PICT
    @ prow(), 110 say invqty pict QTY_PICT
    @ prow(), 120 say moperator
    
    brcvqty += rcvqty
    binvqty += invqty
    bretail += retail
    bamt += amt
    bamtA += amta

   enddo 

   @ prow()+2, 0 say replicate( chr( 196 ), page_width )
   @ prow()+1, 10 say 'Batch Totals ********'
   @ prow()+1, 57 say bamt pict TOTAL_PICT
   @ prow(), 66 say bamta pict TOTAL_PICT
   @ prow(), 75 say bretail pict TOTAL_PICT
   @ prow(), 89 say Percent( bamt, bretail ) pict '999.99'

   @ prow(), 101 say brcvqty pict QTY_PICT
   @ prow(), 110 say binvqty pict QTY_PICT

   gtrcvqty += brcvqty
   gtinvqty += binvqty
   gtretail += bretail
   gtamt += bamt
   gtamtA += bamta

   eject // Re EJB 03/11/95

  enddo

  if PageEject( page_len, top_mar, bot_mar)
   page_number++
   PageHead( report_name, page_width, page_number, col_head1, col_head2 )
  endif

  @ prow()+2, 0 say replicate( chr( 205 ), page_width )
  @ prow()+1, 10 say 'Grand Totals ********'

  @ prow(), 57 say gtamt pict TOTAL_PICT
  @ prow(), 66 say gtamta  pict TOTAL_PICT
  @ prow(), 75 say gtretail pict TOTAL_PICT
  @ prow(), 89 say Percent( gtamt, gtretail ) pict '999.99'
  @ prow(), 101 say gtrcvqty pict QTY_PICT
  @ prow(), 110 say gtinvqty pict QTY_PICT
  Pitch10()
  Endprint()
  set device to screen
   
 endif 
 ftrecpt->( dbclosearea() )

endif 
return nil

*

Function SuppSync
/* 
   Function to syncronise coop Supplier Codes with all booktrac Files

   - Sort of a Big Global Change
   - See CVO #9

*/
local marr:={}   // Append array for download file
local farr := { 'archive\archive', 'draft_po', 'returns' , 'master', 'stkhist', 'recvhead', 'imprint', 'pohead', 'special', 'reqhead' }
local narr := { FALSE             , TRUE     , TRUE      , TRUE    , FALSE    , TRUE      , FALSE    , TRUE    , FALSE    , TRUE      }
local x
local mscr := Bsave( 2, 10, 15, 70 )
local newsupp    // New Supplier Code 
local oldsupp    // Old supplier code

field supp_code

begin sequence

if !file( 'transfer\fromho\suppfix.txt' )
 Error( 'Cannot find the suppfix.txt file in the transfer\fromho directory', 12 )

else

// Create supplier indexes as needed
 if Isready( 12 )

  for x := 1 to len( farr )
   if !Netuse( farr[ x ], EXCLUSIVE )
    Error( 'Cannot open file ' + farr[ x ] + ' Try again later', 12 )

    break

   else

    if !narr[ x ]  // Already has a supplier index

     @ 3, 12 say space( 40 )
     @ 3, 12 say 'Indexing file ' + farr[ x ] 
     indx( 'supp_code', 'supplier' )

    endif

   endif

  next

  aadd( marr, { 'extra_key', 'c', 10, 0 } )   // The Coop's key
  aadd( marr, { 'supp_code', 'c', SUPP_CODE_LEN, 0 } )  // Key to be
  dbcreate( 'suppfix', marr )

  if Netuse( 'suppfix', EXCLUSIVE )

   append from transfer\fromho\suppfix.txt delimited

   if Netuse( 'supplier', EXCLUSIVE )

    indx( 'extra_key', 'extra_key' )
    ordsetfocus( 'extra_key' )

    for x := 1 to len( farr )  // Cycle through the files

     @ 4, 12 say space( 40 )
     @ 4, 12 say 'Updating File ' + farr[ x ]

     if x = 1
      select archive  // Archive is special
     else
      select ( farr[x] )
     endif

     ordsetfocus( BY_SUPPLIER )

     suppfix->( dbgotop() )
     while !suppfix->( eof() ) .and. Pinwheel( NOINTERUPT ) // Cycle through the required fixes

      if supplier->( dbseek( suppfix->extra_key ) )

       oldsupp := supplier->code
       newsupp := suppfix->supp_code

       if oldsupp != newsupp  // This will lead to a never ending loop!!!

        while dbseek( oldsupp ) .and. Pinwheel( NOINTERUPT )

         supp_code := newsupp

        enddo

       endif

      endif

      suppfix->( dbskip() )

     enddo

    next

    suppfix->( dbgotop() )
    while !suppfix->( eof() )  // Patch the supplier file
     if supplier->( dbseek( suppfix->extra_key ) )
      supplier->code := suppfix->supp_code
     endif
     suppfix->( dbskip() )
    enddo

    supplier->( orddestroy( 'extra_key' ) )
    supplier->( dbclosearea() )

   endif

   suppfix->( dbclosearea() )
   kill( 'suppfix.dbf' )

  endif 

 // Get rid of all the unneeded supplier indexes
  archive->( orddestroy( 'supplier' ) )
  for x := 2 to len( marr )
   if !narr[ x ] 
    ( marr[ x ] )->( orddestroy( 'supplier' ) )
   endif
  next

 endif

endif

end sequence

dbcloseall()
return nil
