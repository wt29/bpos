/*

  Proc UtilSPPA - Utilities - ShoP PArameters

  Most of BPOS Configuration Files setup here

      Last change:  TG   29 Apr 2011    3:46 pm
*/

Procedure U_setup
 
#include "bpos.ch"

local sScreen, aArray
local aGlobalVars, aLocalVars
local nOldF1, nOldF2
local nOldAlt2, nOldAlt3, nOldAlt5, nOldAlt6, nOldAlt9, nOldAlt10
local getlist:={}

aGlobalVars := bvarget()    // this should return an array of all bvars
aLocalVars := lvarget()

sScreen := Box_Save( 01, 00, 24, 79 )
Heading( 'Edit Store Data' )

@ 02,01 say '    Store Name' get aGlobalVars[ B_NAME ] pict '!XXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
@ 04,01 say 'Address Line 1' get aGlobalVars[ B_ADDRESS1 ] pict '!XXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
@ 05,01 say '        Line 2' get aGlobalVars[ B_ADDRESS2 ] pict '!XXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
@ 06,01 say '        Line 3' get aGlobalVars[ B_SUBURB ] pict   '!XXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
@ 07,01 say '       Country' get aGlobalVars[ B_COUNTRY ] pict '!XXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
@ 08,01 say '     Telephone' get aGlobalVars[ B_PHONE ] pict '##############'
@ 09,01 say '       Fax No.' get aGlobalVars[ B_FAX ] pict '##############'
@ 10,01 say '    ABN Number' get aGlobalVars[ B_ACN ] pict '99999999999'
#ifdef IS_BOOKSHOP
@ 11,01 say '    SAN Number' get aGlobalVars[ B_SAN ] pict 'XXXXXXXXXXXX'
#endif
@ 03,50 say 'PO 1'
@ 04,50 say 'PO 2'
@ 05,50 say 'PO 3'
@ 06,50 say 'PO 4'
@ 07,50 say 'PO 5'

@ 09,47 say ' Special'
@ 10,47 say '   Layby'
@ 11,47 say ' Invoice'
@ 12,47 say '  Return'
@ 13,47 say 'Approval'
@ 14,47 say 'Transfer'
@ 15,47 say 'Credit N'

#ifdef AR_RECEIPTS
@ 15, 47 say "AR Recpt"
#endif

if Netuse( "sysrec", EXCLUSIVE, 1 )

 if sysrec->( lastrec() ) = 0  // System may start up with Blank record
  Add_rec('sysrec')

 endif 
 Syscolor( C_BRIGHT )
 @ 03,56 say sysrec->ponum1 pict PO_NUM_PICT
 @ 04,56 say sysrec->ponum2 pict PO_NUM_PICT
 @ 05,56 say sysrec->ponum3 pict PO_NUM_PICT
 @ 06,56 say sysrec->ponum4 pict PO_NUM_PICT
 @ 07,56 say sysrec->ponum5 pict PO_NUM_PICT

 @ 09,56 say sysrec->specno pict '999999'
 @ 10,56 say sysrec->laybyno pict '999999'
 @ 11,56 say sysrec->invno pict '999999'
 @ 12,56 say sysrec->retnum pict '999999'
 @ 13,56 say sysrec->appno pict '999999'
 @ 14,56 say sysrec->transfer pict '999999'
 @ 15,56 say sysrec->creditnote pict '999999'

#ifdef AR_RECEIPTS
 @ 16,56 say sysrec->receipt pict '999999'

#endif

 @ 02,66 say 'PO Names'
 @ 03,66 say aGlobalVars[ B_PO1NAME ]
 @ 04,66 say aGlobalVars[ B_PO2NAME ]
 @ 05,66 say aGlobalVars[ B_PO3NAME ]
 @ 06,66 say aGlobalVars[ B_PO4NAME ]
 @ 07,66 say aGlobalVars[ B_PO5NAME ]

 Syscolor( C_NORMAL )
 @ 02,66 say 'PO Names'
 sysrec->( dbclosearea() )

endif

@ 14,02 say 'Printer Names (use the Windows name)'
@ 15,02 say ' Report' get aLocalVars[ L_REPORT_NAME ] pict 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
@ 16,02 say ' Docket' get aLocalVars[ L_DOCKET_NAME ] pict 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
@ 17,02 say 'Barcode' get aLocalVars[ L_BARCODE_NAME ] pict 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
@ 18,02 say 'Invoice' get alocalVars[ L_INVOICE_NAME ] pict 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
@ 20,04 say 'Register Name' get aLocalVars[ L_REGISTER ] pict 'XXXXXXXXXX'
@ 20,29 say 'C/D Type' get aLocalVars[ L_CDTYPE ] pict '!' valid( aLocalVars[ L_CDTYPE ] $ 'PSCEN' ) // Parallel, Serial, Citizen, Epson, None
@ 20,40 say 'Port' get aLocalVars[ L_CDPORT ] range 1,2
@ 20,47 say 'Auto' get aLocalVars[ L_AUTO_OPEN ] pict 'Y'
@ 20,58 say 'Good' get aLocalVars[ L_GOOD ] pict '999' range 100,999
@ 20,68 say 'Bad' get aLocalVars[ L_BAD ] pict '999' range 100,999
@ 21,04 say 'Docket Cutter' get aLocalVars[ L_CUTTER ] pict 'y'
@ 21,29 say 'POS Display' get aLocalVars[ L_POSDISPLAY ] pict 'y'
// @ 21,47 say 'Barcode Printer Type' get aGlobalVars[ B_BCPTR ] pict '!'

aArray := {}

aadd( aArray, { '<Alt-F2>', 'Set System Numbers' } )
aadd( aArray, { '<Alt-F3>', 'Open to Buy Report' } )
// aadd( aArray, { '<Alt-F4>', 'Set the GST Rate' } )
aadd( aArray, { '<Alt-F5>', 'Point of Sale Function Keys' } )
aadd( aArray, { '<Alt-F6>', 'Reports/System Variables' } )
aadd( aArray, { '<Alt-F9>', 'Set Transaction Types' } )
aadd( aArray, { '<Alt-F10>', 'Set Exchange Rates' } )

nOldF1:= setkey( K_F1, { || Build_help( aArray ) } )
nOldF2:= setkey( K_F2, { || SysInfo( aLocalVars[ L_NODE ] ) } )
nOldAlt2:=setkey( K_ALT_F2, { || Set_nums( aGlobalVars ) } )
nOldAlt3:=setkey( K_ALT_F3, { || Open_to_buy() } )
nOldAlt5:=setkey( K_ALT_F5, { || Set_pos( aLocalVars, Getlist ) } )
nOldAlt6:=setkey( K_ALT_F6, { || Setnorpt( aGlobalVars, Getlist ) } )
nOldAlt9:=setkey( K_ALT_F9, { || Set_tt( aGlobalVars ) } )
nOldAlt10:=setkey( K_ALT_F10, { || Set_exchg() } )

read

setkey( K_F1, nOldF1 )
setkey( K_F2, nOldF2 )
setkey( K_ALT_F2, nOldAlt2 )
setkey( K_ALT_F3, nOldAlt3 )
setkey( K_ALT_F5, nOldAlt5 )
setkey( K_ALT_F6, nOldAlt6 )
setkey( K_ALT_F9, nOldAlt9 )
setkey( K_ALT_F10, nOldAlt10 )

Bvarsave()  // Force Flush to disk
Lvarsave()

if updated()
 if !empty( LVars( L_DOCKET_NAME ) ) .and. !PrinterExists( trim( LVars( L_DOCKET_NAME ) ) )
  Alert( "Docket Printer '" + trim( LVars( L_DOCKET_NAME ) ) + "' not found on this machine" )

 endif
 if !empty( LVars( L_REPORT_NAME ) ) .and. !PrinterExists( trim( LVars( L_REPORT_NAME ) ) )
  Alert( "Report Printer '" + trim( LVars( L_REPORT_NAME ) ) + "' not found on this machine" )

 endif
 if !empty( LVars( L_BARCODE_NAME ) ) .and. !PrinterExists( trim( LVars( L_BARCODE_NAME ) ) )
  Alert( "Barcode Printer '" + trim( LVars( L_BARCODE_NAME ) ) + "' not found on this machine" )

 endif
 if !empty( LVars( L_INVOICE_NAME ) ) .and. !PrinterExists( trim( LVars( L_INVOICE_NAME ) ) )
  Alert( "Invoice Printer '" + trim( LVars( L_INVOICE_NAME ) ) + "' not found on this machine" )

 endif

endif

SysAudit("SetLoc")
dbcloseall()
return

*

procedure SysInfo ( sNodeName )
local sScreen:=Box_Save( 04, 01, 13, 77 )
Highlight( 05, 03, '    Node Address', sNodeName )
Highlight( 06, 03, '        Compiler', version() )
Highlight( 07, 03, 'Operating System', os() )
Highlight( 08, 03, '   Build Version', BUILD_NO )
Highlight( 09, 03, '             RDD', rddsetdefault() )
Highlight( 10, 03, '       Index Ext', ordbagext() )
Highlight( 11, 03, '       Free Pool', Ns( memory(0) ) )
Highlight( 12, 03, '     System Path', Oddvars( SYSPATH ) )

Error('')
Box_Restore( sScreen )
return

*

procedure set_pos ( aLocalVars )
local sScreen:=Box_Save(04,01,21,77)
local nOldAlt5:=setkey( K_ALT_F5 , nil )
local getlist := {}

Heading('Set up POS Function Keys')
#define FUNC_PICT '@!'
@ 5,21 say 'Scan Value'
@ 5,42 say 'Label'
@ 5,55 say 'Margin'
@ 6,04 say 'Function Key  #3' get aLocalVars[ L_F3 ] pict FUNC_PICT
@ 6,42 get aLocalVars[ L_F3N ] // pict '!!!!!!!!!'
@ 6,55 get aLocalVars[ L_F3MARGIN ] pict '999.99'
@ 7,04 say 'Function Key  #4' get aLocalVars[ L_F4 ] pict FUNC_PICT
@ 7,42 get aLocalVars[ L_F4N ] // pict '!!!!!!!!!'
@ 7,55 get aLocalVars[ L_F4MARGIN ] pict '999.99'
@ 8,04 say 'Function Key  #5' get aLocalVars[ L_F5 ] pict FUNC_PICT
@ 8,42 get aLocalVars[ L_F5N ] // pict '!!!!!!!!!'
@ 8,55 get aLocalVars[ L_F5MARGIN ] pict '999.99'
@ 9,04 say 'Function Key  #6' get aLocalVars[ L_F6 ] pict FUNC_PICT
@ 9,42 get aLocalVars[ L_F6N ] // pict '!!!!!!!!!'
@ 9,55 get aLocalVars[ L_F6MARGIN ] pict '999.99'
@ 10,04 say 'Function Key  #7'get aLocalVars[ L_F7 ] pict FUNC_PICT
@ 10,42 get aLocalVars[ L_F7N ] // pict '!!!!!!!!!'
@ 10,55 get aLocalVars[ L_F7MARGIN ] pict '999.99'
@ 11,04 say 'Function Key  #8' get aLocalVars[ L_F8 ] pict FUNC_PICT
@ 11,42 get aLocalVars[ L_F8N ] // pict '!!!!!!!!!'
@ 11,55 get aLocalVars[ L_F8MARGIN ] pict '999.99'
@ 12,04 say 'Function Key  #9' get aLocalVars[ L_F9 ] pict FUNC_PICT
@ 12,42 get aLocalVars[ L_F9N ] // pict '!!!!!!!!!'
@ 12,55 get aLocalVars[ L_F9MARGIN ] pict '999.99'
@ 13,04 say 'Function Key #10'get aLocalVars[ L_F10 ] pict FUNC_PICT
@ 13,42 get aLocalVars[ L_F10N ] // pict '!!!!!!!!!'
@ 13,55 get aLocalVars[ L_F10MARGIN ] pict '999.99'
Read

// getlist := aGetList

Box_Restore( sScreen )
SysAudit("SetPos")
setkey( K_ALT_F5 , nOldAlt5 )
return

*

procedure set_nums ( aGlobalVars )
local nOldF2 := setkey( K_ALT_F2 , NIL )
// local aGetList := GetList
local getlist := {}
clear gets

if Secure( X_SUPERVISOR )
 if Netuse( "Sysrec", EXCLUSIVE )
  SysAudit("SetNums")
  @ 03,56 get ponum1 pict PO_NUM_PICT
  @ 04,56 get ponum2 pict PO_NUM_PICT
  @ 05,56 get ponum3 pict PO_NUM_PICT
  @ 06,56 get ponum4 pict PO_NUM_PICT
  @ 07,56 get ponum5 pict PO_NUM_PICT

  @ 03,66 get aGlobalVars[ B_PO1NAME ]
  @ 04,66 get aGlobalVars[ B_PO2NAME ]
  @ 05,66 get aGlobalVars[ B_PO3NAME ]
  @ 06,66 get aGlobalVars[ B_PO4NAME ]
  @ 07,66 get aGlobalVars[ B_PO5NAME ]

  @ 09,56 get specno pict '999999'
  @ 10,56 get laybyno pict '999999'
  @ 11,56 get invno pict '999999'
  @ 12,56 get retnum pict '999999'
  @ 13,56 get appno pict '999999'
  @ 14,56 get transfer pict '999999'
  @ 15,56 get creditnote pict '999999'
#ifdef AR_RECEIPTS
  @ 16,56 get receipt pict '999999'
#endif
  read
  use

 endif

endif
setkey( K_ALT_F2 , nOldF2 )
return

*

procedure open_to_buy
local sScreen,nOldAlt3:=setkey( K_ALT_F3 , nil )
local updt_flag := Secure( X_SUPERVISOR ),x , mdstr, mimth
local aValues:=array( 12, 6 ), y, line_tot
local getlist:={}

if Netuse( "open2buy", EXCLUSIVE )
 if lastrec() = 0
  Add_rec()

 endif 
 sScreen := Box_Save( 02, 02, 17, 77 )
 Heading( 'Open to Buy Budgets' )
 @ 03, 10 say 'Budget'
 @ 03, 19 say Bvars( B_PO1NAME )
 @ 03, 28 say Bvars( B_PO2NAME )
 @ 03, 37 say Bvars( B_PO3NAME )
 @ 03, 46 say Bvars( B_PO4NAME )
 @ 03, 55 say Bvars( B_PO5NAME )
 @ 4, 3 say replicate( chr( 196 ), 74 )
 for x := 1 to 12
  mdstr := '0' + Ns(x)
  mdstr := substr( mdstr, if( len( mdstr ) = 3, 2, 1 ), 2)
  mimth := left( cmonth( ctod( "01/" + mdstr + "/94" ) ), 3 )
  @ x + 4, 03 say mimth
  aValues[ x, 1 ] := eval( fieldblock( 'open_' + mimth + 'b' ) )
  line_tot := 0
  @ x + 4, 07 get aValues[ x, 1 ] pict '999999.99'

  for y := 1 to 5
   aValues[ x, y + 1 ] := eval( fieldblock( 'open_' + mimth + Ns( y ) ) )

   line_tot += aValues[ x, y + 1 ]

   if !updt_flag
    @ x + 4, 09 + ( y * 9 ) say aValues[ x, y+1 ] pict '99999.99'

   else
    @ x + 4, 09 + ( y * 9 ) get aValues[ x, y+1 ] pict '99999.99'

   endif

  next y
  @ x + 4, 67 say line_tot pict '999999.99'

 next x

 if !updt_flag
  inkey(0)

 else
  read
  if updated()
   for x := 1 to 12
    mdstr := '0'+Ns(x)
    mdstr := substr(mdstr,if(len(mdstr)=3,2,1),2)
    mimth := left( cmonth( ctod("01/"+mdstr+"/94") ), 3 )
    eval( fieldblock( 'open_' + mimth + 'b' ), aValues[ x, 1 ] )
    for y := 1 to 5
     eval( fieldblock( 'open_' + mimth + ns( y ) ), aValues[ x, y + 1 ] )

    next

   next

  endif 
  SysAudit("SetOpBud")

 endif

 Box_Restore( sScreen )
 open2buy->( dbclosearea() )
endif
setkey( K_ALT_F3 , nOldAlt3 )
return

*

procedure set_tax
local sScreen, getlist:={}, nGST
local nOldAlt4:=setkey( K_ALT_F4, nil )

if Secure( X_SUPERVISOR )
#ifdef SALESTAX
 sScreen:=Box_Save( 03,08,09,30 )
 Heading('Set up Sales Tax Codes')
 @ 04,10 say ' Code   Percent Rate'
 syscolor( C_BRIGHT )
 @ 05,10 say '  0        Exempt'
 @ 6,12 say '1'
 @ 6,21 get aGlobalVars[ B_ST1 ] pict '99.99'
 @ 7,12 say '2'
 @ 7,21 get aGlobalVars[ B_ST2 ] pict '99.99'
 @ 8,12 say '3'
 @ 8,21 get aGlobalVars[ B_ST3 ] pict '99.99'
 read

#else
 sScreen:=Box_Save( 03, 08, 7, 70 )
 nGST = Bvars( B_GSTRATE )
 @ 4, 10 say 'GST Rate' get nGST pict '99.99'
 @ 5, 10 say 'Be very, very careful about changing this !!'
 @ 6, 10 say 'If in doubt ring ' + DEVELOPER + ' before proceeding'
 read
 if updated()
  BVars( B_GSTRATE, nGST )

 endif

#endif

 syscolor( C_NORMAL )
 SysAudit("SetTax")
 Box_Restore( sScreen )

endif

setkey( K_ALT_F4 , nOldAlt4 )

return

*

procedure setnorpt ( aGlobalVars )
local sScreen
local nOldAlt6:=setkey( K_ALT_F6 , nil )
local oksf10
local getlist := {}

clear gets

if Secure( X_SUPERVISOR )
 sScreen:=Box_Save( 1, 1, 24, 79 )
 Heading( 'Setup System Defaults' )

 Highlight( 2, 07, '', 'Special Orders' )
 @ 03,03 say '          Dockets' get aGlobalVars[ B_SPDOCK ] pict '9'
 @ 04,03 say '    Delete Advice' get aGlobalVars[ B_SPDELE ] pict '9'
 @ 05,03 say '     Advice Notes' get aGlobalVars[ B_SPADNO ] pict '9'
 @ 06,03 say '             Type' get aGlobalVars[ B_SPECSLIP ] pict '9'
 @ 07,03 say '      Cust Letter' get aGlobalVars[ B_SPLET ] pict '9'
 @ 08,03 say '      Grp by Cust' get aGlobalVars[ B_SPLETGROUP ] pict 'Y'
 @ 09,03 say '   Special Labels' get aGlobalVars[ B_SPECLABE ] pict 'Y'

 Highlight( 10, 08, '', 'Layby' )
 @ 11,03 say '          Dockets' get aGlobalVars[ B_LADOCK ] pict '9'
 @ 12,03 say '  Payment Receipt' get aGlobalVars[ B_LAPAY ] pict '9'
//  @ 13,03 say '    Delete Advice' get aGlobalVars[ B_LADELE ] pict '9'
 @ 14,03 say ' Days to Complete' get aGlobalVars[ B_LACOMP ] pict '999'
 @ 15,03 say 'Layby Tot in Cash' get aGlobalVars[ B_LACASH ] pict 'Y'

 Highlight( 16, 07, '', 'Invoicing' )
 @ 17,03 say '         Invoices' get aGlobalVars[ B_ININ ] pict '9'
 @ 18,03 say '     Credit Notes' get aGlobalVars[ B_INCR ] pict '9'
 @ 19,03 say ' Quantity Default' get aGlobalVars[ B_INQTY ] pict '9'
 @ 20,03 say 'Automatic Backord' get aGlobalVars[ B_AUTOBACK ] pict 'y'

 Highlight( 21, 07, '', 'Approvals' )
 @ 22,03 say '   Approval Notes' get aGlobalVars[ B_APNOTE ] pict '9'
 @ 23,03 say ' Quantity Default' get aGlobalVars[ B_APQTY ] pict '9'

 Highlight( 2, 30, '', 'Item Entry' )
 @ 03,26 say '  Default Min Stock' get aGlobalVars[ B_REORDQTY ] pict '9'
 @ 04,26 say 'Items are Firm Sale' get aGlobalVars[ B_SALERET ] pict 'Y'
 @ 05,26 say '            Beep On' get aGlobalVars[ B_BELLS ] pict 'Y'
 Highlight( 6, 30, '', 'Misc' )
 @ 07,26 say 'Sales Period Length' get aGlobalVars[ B_PERLEN ] pict '999'
 @ 08,26 say '     GRN Sort Order' get aGlobalVars[ B_NEWSORT ] pict '!' valid aGlobalVars[ B_NEWSORT ] $ 'TN'
 @ 09,26 say ' Balance BF Debtors' get aGlobalVars[ B_OPENITEM ] pict 'Y'
 @ 10,26 say 'Balance BF Creditor' get aGlobalVars[ B_OPENCRED ] pict 'Y'
 @ 11,26 say 'Auto Post Creditors' get aGlobalVars[ B_AUTOCRED ] pict 'Y'

 Highlight( 12, 26, '',  'Purchasing' )
 @ 13,30 say 'Purchase Orders' get aGlobalVars[ B_POQTY ] pict '9'
 @ 14,30 say '  Credit Claims' get aGlobalVars[ B_CREDCL ] pict '9'

 Highlight( 15, 30, '', 'Compulsory Fields' )
 @ 16,37 say BRAND_DESC
 @ 16,46 get aGlobalVars[ B_CHKIMPR ] pict 'y'
 @ 17,37 say 'Status'
 @ 17,46 get aGlobalVars[ B_CHKSTAT ] pict 'y'
 @ 18,37 say PACKAGE_DESC
 @ 18,46 get aGlobalVars[ B_CHKBIND ] pict 'y'
 @ 19,37 say 'Category'
 @ 19,46 get aGlobalVars[ B_CHKCATE ] pict 'y'

 Highlight( 02, 52, '', 'Sales' )
 @ 03,54 say 'POS Discount 1' get aGlobalVars[ B_DISC1 ] pict '99.9%'
 @ 04,54 say 'POS Discount 2' get aGlobalVars[ B_DISC2 ] pict '99.9%'
 @ 05,54 say 'POS Discount 3' get aGlobalVars[ B_DISC3 ] pict '99.9%'
 @ 06,54 say 'POS Discount 4' get aGlobalVars[ B_DISC4 ] pict '99.9%'
 @ 08,56 say 'Round down Cents' get aGlobalVars[ B_CENTROUND ] pict 'Y'
 @ 09,49 say 'Consolidate Daily Sales' get aGlobalVars[ B_SALECONS ] pict 'Y'
 @ 10,56 say 'Matrix Discounts' get aGlobalVars[ B_MATRIX ] pict 'y'
 @ 11,56 say '   Picking Slips' get aGlobalVars[ B_PICKSLIP ] pict 'y'
 @ 12,56 say 'Allow Dept Order' get aGlobalVars[ B_DEPTORDR ] pict 'y'
 read
 Box_Save( 01, 01, 24, 79 )

 //@ 02,03 say '          Branch Code' get aGlobalVars[ B_BRANCH ] pict '@!' valid( len( trim( aGlobalVars[ B_BRANCH ] ) ) = BRANCH_CODE_LEN )
// @ 09,03 say '     Barcode Label L1' get aGlobalVars[ B_BARLINE1 ] pict 'XXXXXXXXXXXXXXXXXXXX'
// @ 10,03 say '     Barcode Label L2' get aGlobalVars[ B_BARLINE2 ] pict 'XXXXXXXXXXXXXXXXXXXX'
 @ 11,03 say 'Special Order Comments' get aGlobalVars[ B_SPECCOMM ] pict '!XXXXXXXXXXXXXXXXXXXXXXXXX'
 @ 12,03 say '    Default Po Comment' get aGlobalVars[ B_POINST ] pict '!XXXXXXXXXXXXXXXXX'
 @ 13,03 say '      Docket Head Ln 1' get aGlobalVars[ B_DOCKLN1 ] pict 'XXXXXXXXXXXXXXXXXXXX'
 @ 14,03 say '      Docket Head Ln 2' get aGlobalVars[ B_DOCKLN2 ] pict 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
 @ 15,03 say '         Docket Footer' get aGlobalVars[ B_GREET ] pict '@S40'
 @ 17,03 say '              GST Rate' get aGlobalVars[ B_GSTRATE ] pict '99.9'

 oksf10 := setkey( K_SH_F10, { || SetBranchCode( aGlobalVars ) } )

 read

 setkey( K_SH_F10, oksf10 )

 SysAudit( "SetSys" )

 Box_Restore( sScreen )

endif
setkey( K_ALT_F6, nOldAlt6 )
return

*

function SetBranchCode ( aGlobalVars )
local sScreen := Box_Save( 2, 46, 4, 70 )
Local getlist := {}

if secure( X_SUPERVISOR )
 if !empty( aGlobalVars[ B_BRANCH ] )
  Error( 'Warning - Changing an existing branch code can have serious repercussions', 12 )

 endif 
 @ 03,49 say 'Branch Code' get aGlobalVars[ B_BRANCH ] pict '@!' valid( len( trim( aGlobalVars[ B_BRANCH ] ) ) = BRANCH_CODE_LEN )
 read
 SysAudit( 'SetBranchCode' )
 Box_Restore( sScreen )

endif
return nil

/*

procedure set_st
local sScreen,x,nOldAlt7:=setkey( K_ALT_F7, nil )
local aValue := array( 10, 2 )
local getlist:={}

if Secure(X_SUPERVISOR)
 if Netuse( "sysrec", SHARED, .1 )
  Heading("Set up Marketing Sale Types")
  sScreen:=Box_Save(03,08,15,42)
  @ 04,10 say 'Key Code  Description'
  for x := 1 to 10
   aValue[ x, 1 ] := eval( fieldblock( 'stype'+Ns( x ) ) )
   aValue[ x, 2 ] := eval( fieldblock( 'stypen'+Ns( x ) ) )
   @ x+4,10 say Ns( x )
   @ x+4,15 get aValue[ x, 1 ] pict '@!'
   @ x+4,19 get aValue[ x, 2 ]

  next
  read

  if updated()
   Rec_lock()
   for x := 1 to 10
    eval( fieldblock( 'stype'+Ns( x ) ), aValue[ x, 1 ] ) 
    eval( fieldblock( 'stypen'+Ns( x ) ), aValue[ x, 2 ] )
   next
   dbrunlock()

  endif 
  SysAudit("SetSaleType")
  Box_Restore( sScreen )

 endif
 use

endif
setkey( K_ALT_F7, nOldAlt7 )
return

*/

procedure set_lpt ( aLocalVars )
local sScreen,nOldAlt8:=setkey( K_ALT_F8, nil )
local getlist:={}
if Secure(X_SUPERVISOR)
 sScreen:=Box_Save(01,00,22,57)
 Heading("Setup Printer Control Strings")
 Highlight(02,01,"",'Lpt1')
 @ 02,11 say '10 Pitch' get aLocalVars[ L_LPT1_10 ] pict '@!'
 @ 03,11 say '12 Pitch' get aLocalVars[ L_LPT1_12 ] pict '@!'
 @ 04,11 say '17 Pitch' get aLocalVars[ L_LPT1_17 ] pict '@!'
 @ 05,11 say 'Letter Q' get aLocalVars[ L_LPT1_LQ ] pict '@!'
 @ 06,11 say '   Draft' get aLocalVars[ L_LPT1_DR ] pict '@!'
 Highlight(07,01,"",'Lpt2')
 @ 07,11 say '10 Pitch' get aLocalVars[ L_LPT2_10 ] pict '@!'
 @ 08,11 say '12 Pitch' get aLocalVars[ L_LPT2_12 ] pict '@!'
 @ 09,11 say '17 Pitch' get aLocalVars[ L_LPT2_17 ] pict '@!'
 @ 10,11 say 'Letter Q' get aLocalVars[ L_LPT2_LQ ] pict '@!'
 @ 11,11 say '   Draft' get aLocalVars[ L_LPT2_DR ] pict '@!'
 Highlight(12,01,"",'Lpt3')
 @ 12,11 say '10 Pitch' get aLocalVars[ L_LPT3_10 ] pict '@!'
 @ 13,11 say '12 Pitch' get aLocalVars[ L_LPT3_12 ] pict '@!'
 @ 14,11 say '17 Pitch' get aLocalVars[ L_LPT3_17 ] pict '@!'
 @ 15,11 say 'Letter Q' get aLocalVars[ L_LPT3_LQ ] pict '@!'
 @ 16,11 say '   Draft' get aLocalVars[ L_LPT3_DR ] pict '@!'
 Highlight(17,01,"",'Lpt4')
 @ 17,11 say '10 Pitch' get aLocalVars[ L_LPT3_10 ] pict '@!'
 @ 18,11 say '12 Pitch' get aLocalVars[ L_LPT3_12 ] pict '@!'
 @ 19,11 say '17 Pitch' get aLocalVars[ L_LPT3_17 ] pict '@!'
 @ 20,11 say 'Letter Q' get aLocalVars[ L_LPT3_LQ ] pict '@!'
 @ 21,11 say '   Draft' get aLocalVars[ L_LPT3_DR ] pict '@!'
 read
 Box_Restore( sScreen )
 SysAudit("SetLPT")

endif
setkey( K_ALT_F8 , nOldAlt8 )
return

*/

procedure set_tt
local sScreen, x, nOldAlt9 := setkey( K_ALT_F9 , nil )
local aValue:=array( 12, 3 )
// local aGetList := GetList
local getlist := {}
//clear gets

if Secure( X_SUPERVISOR )
 if Netuse( "sysrec", SHARED, .1 )
  Heading( "Set up Transaction Types" )
  sScreen:=Box_Save(03,08,14,42)
  @ 04,10 say 'Key Code  Description        NCD'
  for x := 4 to 12
   aValue[ x, 1 ] := eval( fieldblock( 'pos' + Ns( x ) ) )
   aValue[ x, 2 ] := eval( fieldblock( 'posn' + Ns( x ) ) )
   aValue[ x, 3 ] := eval( fieldblock( 'pos' + Ns( x )+'cash' ) )
   @ x+1,10 say '<F'+Ns(x)+'>'
   @ x+1,15 get aValue[ x, 1 ] pict '@!'
   @ x+1,19 get aValue[ x, 2 ]
   @ x+1,40 get aValue[ x, 3 ] pict 'Y'
  next
  read

  if updated()
   Rec_lock()
   for x := 4 to 12
    eval( fieldblock( 'pos' + Ns( x ) ), aValue[ x, 1 ] )
    eval( fieldblock( 'posn' + Ns( x ) ), aValue[ x, 2 ] )
    eval( fieldblock( 'pos' + Ns( x ) + 'cash' ), aValue[ x, 3 ] )

   next
   dbrunlock()

  endif 
  SysAudit("SetTrTy")
  Box_Restore( sScreen )

 endif
 use

endif
setkey( K_ALT_F9 , nOldAlt9 )
return

*

function set_exchg
local sScreen, nOldAlt10:=setkey( K_ALT_F10 , nil )
local sscr, key:=0, lastarea:=select(), oTBrowse, aHelpLines
local getlist:={}

if Netuse( 'exchrate' )
 sscr := Box_Save( 1, 39, 22, 77  )
 oTBrowse:=tbrowsedb( 2, 40, 21, 76 )
 oTBrowse:HeadSep := HEADSEP
 oTBrowse:ColSep := COLSEP
 oTBrowse:addcolumn( tbcolumnnew( "Code", { || exchrate->code } ))
 oTBrowse:addcolumn( tbcolumnnew( "Name", { || substr( exchrate->name, 1, 20 ) } ))
 oTBrowse:addcolumn( tbcolumnnew( "Rate", { || exchrate->rate } ))
 dbgotop()
 while TRUE
  oTBrowse:forcestable()
  key := inkey(0)
  if !navigate( oTBrowse, key )
   do case
   case key == K_F1
    aHelpLines := {}
    aadd( aHelpLines, { '<Esc/End>', 'Exit' } )
    aadd( aHelpLines, { '<Enter>', 'Edit Item' } )
    aadd( aHelpLines, { '<Del>', 'Delete Item' } )
    aadd( aHelpLines, { '<Ins>', 'Add New Item' } )
    Build_help( aHelpLines )

   case key == K_ESC .or. key == K_END
    exit 

   case key == K_DEL
    if Isready( 12,,'Ok to delete '+trim( exchrate->name )+' from file')
     Del_Rec( 'exchrate', UNLOCK )
     eval( oTBrowse:skipblock , -1 )
     oTBrowse:refreshall()

    endif

   case key == K_ENTER
    sScreen := Box_Save( 08, 01, 14, 72, C_GREY )
    Highlight( 09, 03, 'Currency Code', exchrate->code )
    @ 10, 03 say 'Currency Name' get exchrate->name 
    @ 12, 03 say 'Exchange Rate' get exchrate->rate pict '99999999.9999'
    Rec_lock( 'exchrate' )
    read
    exchrate->( dbrunlock() )
    Box_Restore( sScreen )
    oTBrowse:refreshcurrent()

   case key == K_INS
    sScreen := Box_Save( 08, 01, 14, 72, C_GREY )
    exchrate->( dbappend() )
    @ 09, 03 say 'Currency Code' get exchrate->code pict '@!'
    @ 11, 03 say 'Currency Name' get exchrate->name 
    @ 13, 03 say 'Exchange Rate' get exchrate->rate pict '99999999.9999'
    read
    exchrate->( dbrunlock() )
    oTBrowse:refreshall()
    Box_Restore( sScreen )

   endcase

  endif

 enddo
 Box_Restore( sscr )
 exchrate->( dbclosearea() )

endif
select ( lastarea )
setkey( K_ALT_F10 , nOldAlt10 )
return nil
