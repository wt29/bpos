/*

  Module Bpos - Retail POS

      Last change:  TG   27 Feb 2011    6:13 pm
*/

#include "bpos.ch"

Function Main()

local nSelect
local nLength
local nMMChoice
local nFileMenu
local nPurchMenu
local nSaleMenu
local nUtilMenu
local cSaveScreen
local nOldF1,nOldFuncKey2
local getlist:={}
local cScreen, moff:=0
local aMenu
local aHelp, aDir
local cStoreName
local cSysPath

// local nMaxRow := maxrow(), nMaxCol := maxcol()

#ifdef __GTWVW__
 //  local lMainCoord
 //altd()
 local lMainCoord := WVW_SetMainCoord( .t. )
 // wvW_SetWindowTitle( "Hello World")
 WVW_SetCodePage(,255)

 WVW_SetFont(,"Lucida Console",28,-12)
 //WVT_GTGetFont("Lucida Console",28,-12)
 //  WVW_SBcreate( 0 )
 //  WVW_SBaddPart( 0, '20', 20, 0, .t. )
 //  WVW_SBSetText(,,'Hello' )
 //wvw_showwindow()
 //wait

#else
 setmode(25,80)

#endif

cSysPath := GetENV( "BPOSPATH" )
if !empty( cSysPath )
 if right( trim( cSysPath ), 1 ) != '\'
  cSysPath += '\'
 
 endif
else
 cSysPath = '\bpos\'
 
endif

Oddvars( SYSPATH, cSysPath )

Oddvars( START_SCR, { Savescreen(), row(), col() } )

cls
?? 'Initialising ' + SYSNAME + '....  Please Wait'

set scoreboard off   // No <Ins> etc
set confirm on       // Must Hit Enter
set deleted on       // Dont Show Deleted Records
set date british     // Rule Britannia !
set wrap on          // Wrap Menus - Right On!
set epoch to 1980    // From the PC Era only

rddsetdefault( "DBFCDX" )
request DBFFPT
request DBFCDX

set autopen on
set( _SET_MFILEEXT, ".FPT" )
// set( _SET_EVENTMASK, INKEY_ALL )
set( _SET_EVENTMASK, INKEY_KEYBOARD )
set( _SET_DEBUG, .t. )
set( _SET_AUTOPEN, TRUE )
set( _SET_AUTORDER, TRUE )

set path to ( Oddvars( SYSPATH ) )

if len( directory( Oddvars( SYSPATH ) + '*.dbf' ) ) = 0
 SetupDbfs()         // a completely new program instance ??

endif 

if len( directory( Oddvars( SYSPATH ) + 'errors', 'D' ) ) = 0   // Create a directory to hold system errors for review
 DirMake( Oddvars( SYSPATH ) + 'errors' )

endif


Lvarget()                   // Set up Local Arrays
Bvarget()                   // Set up the Bvars Array
// altD(1)                  // Turns on Debug

Oddvars( TEMPFILE, '_' + padl( sysinc( 'file', 'I', 1 ), 7 ,'0' ) )
Oddvars( TEMPFILE2, '__' + padl( sysinc( 'file', 'I', 1 ), 6 ,'0' ) )
Oddvars( MSUPP, space( SUPP_CODE_LEN ) )
Oddvars( OPERCODE, '' )
Oddvars( SPFILE_NO, 0 )
Oddvars( IS_CONSIGNED, FALSE )  // Default is not on consignment

if date() < Bvars( B_DATE ) .or. date() < ctod('01/01/03') // Test Date Integrity
 cScreen:=Box_Save( 21,0,24,79 )
 @ 21,0 clear to 24,79
 Shell( "date" )
 Box_Restore( cScreen )

endif

Bvars( B_DATE, date() )     // Store Date into Variable
if BVars( B_GSTRATE ) = 0   // Just in case this isn't set up
 BVars( B_GSTRATE, GST_RATE )

endif

Lvars( L_PRINTER, 'lpt1' )    // This is crap

Chkfield( "Quote", "SysRec" )
ChkField( "TaxExempt", "master" )


cStoreName := trim( Bvars( B_NAME ) ) // , if( empty( BPOSCUST ),'No Serial No',trim( BPOSCUST ) ) )
// nLength := max( ( 20 + len( BPOSCUST ) ) /2, 16 )         // Format Box for Licencee Length
nLength := max( ( 20 + len( cStoreName ) ) /2, 16 )         // Format Box for Licencee Length

Syscolor( 1 )
Heading('*** Welcome to ' + SYSNAME + ' ***')
Box_Save( 04, 79/2-1-nLength, 11, 79/2 + nLength, 8 )        // Clear Box
Center( 05, 'Copyright ' + DEVELOPER )                // Hello
Center( 06, cStoreName )                // Hello
Center( 08, DEVELOPER_PHONE )
Center( 09, SYSNAME + ' Build Number ' + BUILD_NO )

// Center( 10, "Licensed to -=< " + BPOSCUST + " >=-")
Syscolor( 1 )

if !empty( getenv( 'pack' )  )
 Go_Pack( TRUE, '', FALSE )
 quit

endif

if !empty( getenv( 'reindex' ) )
 Go_Pack( TRUE, '', TRUE )
 quit

endif

#ifdef SECURITY
 Login( FALSE )                                 // Not allowed to add an operator here

#else
 Oddvars( OPERCODE, '' ) 
 Error( '', 21 )

#endif

#ifndef NO_SH_F1_CD
setkey( K_SH_F1, { || CDOpen() } )              // Shift F1 = kick open CD

#endif

setkey( K_SH_F2, { || Build_HDMast() } )        // Shift F2 - Probably limited use too
setkey( K_SH_F3, { || Print_swap() } )          // Shift F3 - Don't need this either
setkey( K_SH_F9, { || DocketStatus() } )        // Shift F9 - can disable docket printing
setkey( K_CTRL_F5, { || Show_Open_Areas() } )   // Debugging use only
setkey( K_CTRL_F6, { || ShowCallStack() } )     // Call stack - Debugging use only
setkey( K_CTRL_F10, { || Colourset() } )        // Ctrl F10 - Crap - in windows especially
setkey( K_SH_F12, { || Printgraph() } )         // Ctrl Print Screen


#ifdef SECURITY
setkey( K_ALT_L, { || Login( TRUE ) } )         // Allow an Operator Add

#endif

Poz( BPOSCUST )                                 // Init the pole display if used

//BPOSSendmail()

while TRUE                                      // Main Menu Loop

// Syscolor( C_INVERSE )
// @ 0, 0, 24, 79 box replicate( chr( 176 ), 9 )
// Syscolor( C_NORMAL )
 cls
 
 Heading('Main Menu')                    // Call the heading routine

 set message to 24 center                // Line 24 for comments
 nSelect := 3                            // Sales Default Menu Option

 Box_Save( 02, 00, 4, 79 )

 nMMChoice := 1
 @ 03, 01 prompt '   File   ' message line_clear( 24 ) + 'File Maintenance Operations'
 @ 03, 18 prompt 'Purchasing' message line_clear( 24 ) + 'Purchase and Returns'
 @ 03, 34 prompt '  Sales   ' message line_clear( 24 ) + 'Sales Related Activities'
 @ 03, 50 prompt ' Utility  ' message line_clear( 24 ) + 'Utility Functions, Pack, Index'
 @ 03, 69 prompt ' Modules  ' message line_clear( 24 ) + 'Extra Modules / Accounting Operations'
 line_clear( 24 )

 Syscolor( C_NORMAL )

 aHelp := { { '<Shift-F1>','Open Cashdraw' } ,;
              { '<Shift-F2>','Build HD Master File' } ,;
              { '<Shift-F3>','Change Printers' } ,;
              { '<Shift-F4>','Reprint Header' } ,;
              { '<Shift-F5>','Calculator' } ,;
              { '<Shift-F6>','Calendar' } ,;
              { '<Shift-F9>','Dockets On/Off' } }

 nOldF1 := Setkey( K_F1, { || Build_help( aHelp ) } )

 menu to nSelect
 setkey( K_F1, nOldF1 )
 cSaveScreen := Box_Save()

 do case
 case nSelect = 1 .and. secure( X_FILES )
  while TRUE
   Box_Restore( cSaveScreen )
   Heading('File Maintenance Menu')
   aMenu := {}
   aadd( aMenu, { 'Exit', 'Return to top line options', , nil } )
   aadd( aMenu, { 'Item', 'Master (Item) File maintenance', { || f_desc() }, nil } )
   aadd( aMenu, { 'Supplier', 'Modify Supplier File', { || f_supplier() }, nil } )
   aadd( aMenu, { 'Category', 'Modify Category File' , { || f_category() }, nil} )
   aadd( aMenu, { 'Mailout',  'Maintain Customer File', { || f_customer() }, nil } )
   aadd( aMenu, { 'Department', 'Department Code Maintenance', { || f_department() }, nil } )
   nFileMenu := Menugen( aMenu, 01, 01, 'File' )
   if nFileMenu < 2
    exit

   else
    if Secure( aMenu[ nFileMenu, 4 ] )
     Eval( aMenu[ nFileMenu, 3 ] )

    endif

   endif

  enddo

 case nSelect = 2 .and. secure( X_PURCHASE )
  while TRUE
   Box_Restore( cSaveScreen )
   Heading('Purchasing Menu')
   aMenu := {}
   aadd( aMenu, { 'Main' ,'Return to top line options' } )
   aadd( aMenu, { 'Draft' ,'Prepare Draft Purchase Orders', { || p_Drafts() }, nil } )
   aadd( aMenu, { 'Final' ,'Finalise Purchase Orders' , { || p_Final() }, nil} )
   aadd( aMenu, { 'Incoming' ,'Items into stock', { || Incoming() }, nil } )
   aadd( aMenu, { 'Returns' ,'Return Items to Suppliers' , { || p_Returns() }, nil} )
   nPurchMenu := MenuGen( aMenu, 01, 17, 'Purchasing' )
   if nPurchMenu < 2
    exit

   else
    if Secure( aMenu[ nPurchMenu, 4 ] )
     Eval( aMenu[ nPurchMenu, 3 ] )

    endif

   endif

  enddo

 case nSelect = 3 .and. secure( X_SALES )
  while TRUE
   Box_Restore( cSaveScreen )
   Heading( 'Sales Menu' )
   aMenu:={}
   aadd( aMenu, { 'Main', 'Return to top line options', , nil } )
   aadd( aMenu, { 'Cash', 'Perform Cash Sales', { || s_CashSales() }, nil } )
   aadd( aMenu, { 'Special', 'Enter Special Order details', { || S_Specials() }, nil } )
   aadd( aMenu, { 'Lay-by', 'Lay-by operations', { || S_Layby() }, nil } )
   aadd( aMenu, { 'Invoices', 'Prepare Invoices', { || S_Invoice() }, nil } )
   aadd( aMenu, { 'Enquiry', 'Desc Inquiry', { || S_Enquire() }, nil } )
   aadd( aMenu, { 'Daily', 'Daily Sales/Register Balance', { || s_daily() }, nil } )
   aadd( aMenu, { 'Reports', 'Reports on Sales Activity', { || S_Report() }, nil } )
   aadd( aMenu, { 'Approval', 'Items on Approval System', { || S_Approval() }, nil } )
   aadd( aMenu, { 'Quote', 'Quotation System', { || S_Quote() }, nil } )

   nSaleMenu := MenuGen( aMenu, 1, 34, 'Sales' )
   if nSaleMenu < 2
    exit

   else
    if Secure( aMenu[ nSaleMenu, 4 ] )
     Eval( aMenu[ nSaleMenu, 3 ] )

    endif

   endif

  enddo

 case nSelect = 4 .and. Secure( X_UTILITY )
  while TRUE
   Box_Restore( cSaveScreen )
   Heading('Utility Menu')
   aMenu := {}
   aadd( aMenu, { 'Main', 'Return to Main Menu', nil, nil } )
   aadd( aMenu, { 'Details','Change Shop Details', { || u_setup() }, nil } )
   aadd( aMenu, { 'Stocktake','Stocktake System', { || u_stocktake() }, X_STOCKTAKE } )
   aadd( aMenu, { 'Labels','Replace damaged barcode labels', { || u_labels() }, nil } )
   aadd( aMenu, { 'Pack', 'Housekeeping Duties', { || u_Pack() }, nil } )
   aadd( aMenu, { 'Archive', 'Archive Utilities', { || u_Archive() }, nil } )
   aadd( aMenu, { 'Backup', 'Backup System', { || utilBack( 08, 50 ) }, nil } )
//   aadd( aMenu, { 'Import', 'Append ' + ITEM_DESC + ' & Standby POS files', { || u_import() }, nil } )
//   aadd( aMenu, { 'Update', 'Update Databases for remote system', { || u_update() }, nil } )
   aadd( aMenu, { 'Condense', 'Condense Sales/Stock Histories', { || u_condense() }, nil } )
//   aadd( aMenu, { 'Test Print', 'Execute the printer test', { || Testw32Prn() }, nil } )
//  aadd( aMenu, { 'HelpFiles', 'Check the OLEHelp file for MS Word', { || StartWord() }, nil } )
   nOldFuncKey2 := setkey( K_ALT_F1, { || MaintLaunch() } )
   nUtilMenu := MenuGen( aMenu, 1, 49, 'Utilities' )
   setkey( K_ALT_F1, nOldFuncKey2 )
   if nUtilMenu < 2
    exit
   else 
    if Secure( aMenu[ nUtilMenu, 4 ] )
     Eval( aMenu[ nUtilMenu, 3 ] )
    endif
   endif
  enddo

 case nSelect = 5
  Acme()

 case nSelect = 0

  if Isready( 19,,'Exit ' + SYSNAME + '?' )     // Clean up

   Dbcloseall()
   Poz( 'Register not in use' )
   Lvarsave()
   adir := directory( '_*.*' )
   aeval( aDir, { | del_element | ferase( del_element[ 1 ] ) } )
   cls
   quit

  endif
  syscolor( C_NORMAL )

 endcase
enddo
return nil

*

function MaintLaunch
local aMenu:={}, nMaintMenu, cScreen := Box_Save()
if Secure( X_SUPERVISOR )
 aadd( aMenu, { 'Resyncronise', 'Resync the Master Qtys', { || Chk_po() } } )  // In utilstoc
 aadd( aMenu, { 'SysAudit Browse', 'Browse to SysAudit trail', { || BrowSystem() } } )
 aadd( aMenu, { 'Stock Adjust', 'Allows resetting of Minimum Stock', { || StkAdj() } } ) // In utilstoc
 aadd( aMenu, { 'Hold Setup', 'Setup the hold system', { || SetupHold() } } )
 aadd( aMenu, { 'Field Lengths', 'Check all Dbfs for Correct Field lengths', { || Check_fld_len() } } ) // In proclib ( where else ! )
 aadd( aMenu, { 'Dbf Structures', 'Verify Database Structures', { || Check_new_dbf() } } ) // In proclib ( where else ! )
 aadd( aMenu, { 'Debtor Types', 'Change all Debtors from one type to Another', { || Debtor_type_change() } } ) // In Artran
 aadd( aMenu, { 'Creditor Types', 'Change all Creditors from one type to Another', { || Creditor_type_change() } } ) // In Aptran
 aadd( aMenu, { 'Test Percent', 'Test the Percentage calc vs. GST', { || Check_Percent() } } )
 aadd( aMenu, { 'Change GST Rate', 'Change the GST Rate', { || Set_tax() } } )

 nMaintMenu := MenuGen( aMenu, 1, 49, 'Maintenance' )
 if nMaintMenu # 0
  eval( aMenu[ nMaintMenu, 3 ] )

 endif

endif
Box_Restore( cScreen )
return nil

*

function Incoming
local sscr := Box_Save(), nSelect, aMenu
while TRUE
 Box_Restore( sscr )
 Heading('Receive Items into stock')
 aMenu := {}
 aadd( aMenu, { 'Return', 'Return to Purchasing Menu', , nil } )
 aadd( aMenu, { 'Po Receive', 'Receive Items into Stock From PO', { || Recpo() }, nil } )
 aadd( aMenu, { 'Item Receive', 'Receive Items into Stock using Items', { || p_receive() }, nil } )
 aadd( aMenu, { 'List', 'List Items Received/Print Goods Received Note', { || Reclist() }, nil } )
 aadd( aMenu, { 'Barcode/Post', 'Post Items to Stock & Print Barcode' , { || RecPost() }, nil} )
 nSelect := MenuGen( aMenu, 5, 18, 'Incoming' )
 if nSelect < 2
  exit

 else
  if Secure( aMenu[ nSelect, 4 ] )
   Eval( aMenu[ nSelect, 3 ] )

  endif
 endif 
enddo
return nil


* 

procedure Help ( call_prg ) // , line_num, input_var )

local nOldfk1 := setkey( K_F1, nil )

do case
case call_prg = 'S_Cash'
 Build_help( { { '<Shift-F1>', 'Open the cashdraw' },;
               { '<Shift-F2>', 'Create the Standby POS' },;
               { '<Shift-F3>', 'Swap Printers' },;
               { '<Shift-F4>', 'Reprint Header' },;
               { '<Shift-F5>', 'Calculator' },;
               { '<Shift-F6>', 'Diary/Calendar Functions' },;
               { '<Shift-F9>', 'Dockets On/Off' },;
               { '<Shift-F10>', 'Reprint Docket' },;
               { '<Alt-F1>', 'Finalise Special' },;
               { '<Ctrl-F1>', 'Frequent Shopper' },;
               { '<Ctrl-F2>', 'Tax Exempt Sale' } } )

case call_prg = 'SPECADD'
 Build_help( { { '<*>', 'Add No ' + ID_DESC + ' Desc' },;
               { '<F8>','Flag to Add new id' } } )

case call_prg = 'INVCREATE'
 Build_help( { { '<Alt-F1>', 'Append from Special by Customer' },;
               { '<Alt-F2>', 'Append from Special by Special Order #' },;
               { '<Alt-F3>', 'Append from Approval by Customer' },;
               { '<Alt-F4>', 'Append from Approval by Approval #' },;
               { '<Alt-F5>', 'Append from Approval for other Customer' },;
               { '<Alt-F6>', 'Append from a Category' },;
               { '<Alt-F7>', 'Append from a Proforma Invoice' },;
               { '<Alt-F8>', 'Append from an ASP PDT' } } )

endcase
setkey( K_F1 , nOldFk1 )
return
*

procedure colourset
local getlist:={}, ocur:=setcursor(1), mlvars := LvarGet()
local cScreen:=Box_Save( 2, 02, 13, 76 ), okcf10 := setkey( K_CTRL_F10 , { || factory( mlvars) } )

Heading( "Set Color Strings" )
@ 03,04 say '1' get mlvars[ L_C1 ] pict '@!'
@ 04,04 say '2' get mlvars[ L_C2 ] pict '@!'
@ 05,04 say '3' get mlvars[ L_C3 ] pict '@!'
@ 06,04 say '4' get mlvars[ L_C4 ] pict '@!'
@ 07,04 say '5' get mlvars[ L_C5 ] pict '@!'
@ 08,04 say '6' get mlvars[ L_C6 ] pict '@!'
@ 09,04 say '7' get mlvars[ L_C7 ] pict '@!'
@ 10,04 say '8' get mlvars[ L_C8 ] pict '@!'
@ 11,04 say '9' get mlvars[ L_C9 ] pict '@!'
@ 03,30 say 'Black   N  Black ³ Grey    N+  White'
@ 04,30 say 'Blue    B  Uline ³ B Blue  B+  B ULine'
@ 05,30 say 'Green   G  White ³ B Green G+  B White'
@ 06,30 say 'Cyan    BG White ³ B Cyan  BG+ B White'
@ 07,30 say 'Red     R  White ³ B Red   R+  B White'
@ 08,30 say 'Magenta RB White ³ B Magen RB+ B White'
@ 09,30 say 'Brown   GR White ³ Yellow  GR+ B White'
@ 10,30 say 'White  W   White ³ Black   U   Und Lne'
@ 12,05 say "{ Ctrl-F10 for Default Colours }"
read

setkey( K_CTRL_F10 , okcf10 )
Box_Restore( cScreen )
setcursor( ocur )
LvarSave()
return
*

function factory ( mlvars )
mlvars[ L_C1 ] := 'W/G,W+/R,,,W/R        '
mlvars[ L_C2 ] := 'N/W                   '
mlvars[ L_C3 ] := 'W+/B                  '
mlvars[ L_C4 ] := 'W+/Rb,W+/R,,,W/R      '
mlvars[ L_C5 ] := 'W+/W                  '
mlvars[ L_C6 ] := 'Gr+/R                 '
mlvars[ L_C7 ] := 'W+/G                  '
mlvars[ L_C8 ] := 'W/Bg,W+/Gr,,,Bg+/Bg  '
mlvars[ L_C9 ] := 'Gr+/N,W+/N,,,W/N      '
return nil

*

Function ChgSan()

local cScreen := Box_Save( 5, 23, 10, 53 )
local nSelect := 1, aMenu

setkey( K_SH_F8, nil )
@ 6, 25 say 'Current SAN is ' + alltrim( Bvars( B_SAN ) )
@ 7, 25 say 'Change to: '
aMenu := {}
aadd( aMenu, { '1. Main SAN', '' } )
aadd( aMenu, { '2. Childrens SAN' } )
nSelect := MenuGen( aMenu, 08, 30, 'SAN Change' )
if nSelect = 1
 Bvars( B_SAN, Bvars( B_SAN1 ) )
elseif nSelect = 2
 Bvars( B_SAN, Bvars( B_SAN2 ) )
endif
Box_Restore( cScreen )
setkey( K_SH_F8, { || ChgSan() } )

return TRUE

*

Function BoxIt ( nRow, ncol, ctext) // , cMessage )

//@ nline - 1, nrow -1, nline + 1, nrow + len( cText ) box replicate( chr( 176 ), 9 )
Box_Save( nrow - 1, nCol -1, nRow + 1, ncol + max( 12, len( cText ) ) )
// box replicate( chr( 176 ), 9 )

return nil

*

Function Check_Percent
local getlist := {}
local nAmt := 0
local aBox := Box_Save( 2, 10, 6, 60 )
@ 3, 12 say 'Amount' get nAmt pict '9999.99'
read
@ 4, 12 say PercentOf( BVars( B_GSTRATE ), nAmt )
@ 5, 12 say CalcGST( nAmt, BVars( B_GSTRATE ) )
Error("")
Box_Restore( aBox )
return nil

