/*

  Setupdbf creates new databases
  
      Last change:  TG   27 Feb 2011    6:22 pm
*/

#include "bpos.ch"

function setupdbfs
local lAnswer := FALSE, getlist :={}
local mfilepath := Oddvars( SYSPATH )

cls

@ 2, 2 to  12, 78
@ 3, 04 say SYSNAME + ' has detected no Database files on this system.'
@ 5, 04 say 'This section will set up the Database files required to run ' + SYSNAME
@ 6, 04 say SYSNAME + ' will exit after creation - you will need to restart!'
@ 7, 04 say 'Ok to create Database files' get lAnswer pict 'Y'
read

if lAnswer
 lAnswer := FALSE
 @ 8, 04 say 'Again - Ok to create Database Files' get lAnswer pict 'Y'
 read

 if lAnswer
  SetupDirs()
  CreateDbfs()
  @ 10, 04 say 'You will need to rename the *' + NEW_DBF_EXT + ' files to *.dbf to run '+ SYSNAME + ' - Bye for now!'

 endif

endif
@ 13, 00 say ''
quit   

return nil

*

function SetupDirs
local getlist:={}, mbranch:=space( BRANCH_CODE_LEN ), aArray

if len( directory( Oddvars( SYSPATH ) + 'archive', 'D' ) ) = 0
 DirMake( Oddvars( SYSPATH ) + 'archive' )

endif

// Master File Comments
if len( directory( Oddvars( SYSPATH ) + 'mcomments', 'D' ) ) = 0
 DirMake( Oddvars( SYSPATH ) + 'mcomments' )

endif
//Customer Comments
if len( directory( Oddvars( SYSPATH ) + 'ccomments', 'D' ) ) = 0
 DirMake( Oddvars( SYSPATH ) + 'ccomments' )

endif
// Supplier Comments
if len( directory( Oddvars( SYSPATH ) + 'scomments', 'D' ) ) = 0
 DirMake( Oddvars( SYSPATH ) + 'scomments' )

endif

#ifdef BRANCHES
mscr := Box_Save( 2, 46, 4, 70 )
@ 03,49 say 'Branch Code' get mbranch pict '@!'
read

Bvars( B_BRANCH, mbranch )
SysAudit( 'SetBranchCode' )

Bvarsave()
#endif

if !file( Oddvars( SYSPATH ) + 'archive\archive.dbf' )
 aArray := {}
 aadd( aArray, { 'id', 'c', ID_CODE_LEN, 0 } )
 aadd( aArray, { 'desc', 'c', 80, 0 } )
 aadd( aArray, { 'alt_desc', 'c', 30, 0 } )
 aadd( aArray, { 'sell_price', 'n', 10, 2 } )
 aadd( aArray, { 'supp_code', 'c', SUPP_CODE_LEN, 0 } )
 aadd( aArray, { 'supp_code2', 'c', SUPP_CODE_LEN, 0 } )
 aadd( aArray, { 'department', 'c', DEPT_CODE_LEN, 0 } )
 aadd( aArray, { 'binding', 'c', 2, 0 } )
 aadd( aArray, { 'brand', 'c', BRAND_CODE_LEN, 0 } )
 aadd( aArray, { 'edition', 'c', 2, 0 } )
 aadd( aArray, { 'book_no', 'c', 10, 0 } )
 aadd( aArray, { 'dsale', 'd', 8, 0 } )
 aadd( aArray, { 'darchive', 'd', 8, 0 } )

 dbcreate( Oddvars( SYSPATH ) + 'archive\archive', aArray )

endif

return nil

*

Function ChkField ( cField, cDbfName )
local cFileName, nNumOfRecs := 0, lUpdated := FALSE

dbcloseall()   // Clean slate

if NetUse( cDbfName )

 if (cDbfName)->( fieldpos( cfield ) ) != 0
   (cDbfname)->( dbclosearea() )

 else
  nNumOfRecs := (cDbfName)->( reccount() )

  (cDbfname)->( dbclosearea() )
  if len( directory( Oddvars( SYSPATH ) + 'dbfstru', 'D' ) ) = 0
   DirMake( Oddvars( SYSPATH ) + 'dbfstru' )

  endif

  CreateDbfs( OddVars( SYSPATH ) + 'dbfStru\' )   // create all the template dbf's using the temp extension
  cFileName := Oddvars( SYSPATH ) + 'dbfstru\' + cDbfName + NEW_DBF_EXT

  if NetUse( cFilename, EXCLUSIVE, , "tempdbf" )

   @ 3,10 say 'Performing upgrade to ' + cDbfName + ' database file on field ' + cfield

   cFileName := Oddvars( SYSPATH ) + ( cDbfName )

   append from ( cFileName )

   tempdbf->( dbclosearea() )

   FileDelete( cFileName + '.old' )  // Kill any old backup files first

   lUpdated := TRUE

   if RenameFile( Oddvars( SYSPATH ) + cDbfName + '.dbf',  Oddvars(SYSPATH) + cDbfName + '.old' ) != 0
    Error( 'Error renaming old ' + cDbfName + ' file' , 12, , 'Contact ' + DEVELOPER +  '  ' + SUPPORT_PHONE + ' Error no ' + Ns( Ferror() ) )

   endif

   copy file ( OddVars( SYSPATH ) + "dbfstru\" + cDbfName + NEW_DBF_EXT ) to ( Oddvars( SYSPATH ) + cdbfname + '.dbf' )

   @ 3, 10 say space(70)

  endif

 endif

endif

return lUpdated

*
*

function Check_new_dbf
// A Utility to check one set of DBFs against another
// First of all get an array of our existing Dbf's

local aCurrentDbf:= asort( directory( Oddvars( SYSPATH ) + '*.dbf' ), , ,{ |p1,p2| p1[1] < p2[1] } )

local x, y, ddstruct, mstruct, fname
local aNewStructure, sFname
local sScreen := Box_Save( 3, 10, 5, 30 )
local fhandle := fcreate( 'dbdifs.txt' )  // Differences written out here
local cOldSysPath := Oddvars( SYSPATH )

@ 04, 12 say 'File - dbdifs.txt'

if len( directory( Oddvars( SYSPATH ) + 'dbfstru', 'D' ) ) = 0   // Create a directory to hold system errors for review
 DirMake( Oddvars( SYSPATH ) + 'dbfstru' )

endif

aNewStructure := directory( OddVars( SYSPATH ) + 'dbfstru\*.' + NEW_DBF_EXT )   // Kill old structures in Dir if exist

for x := 1 to len( aNewStructure )
 Kill( Oddvars( SYSPATH ) + 'dbfstru\' + aNewStructure[ x, 1 ] )

next
 
Oddvars( SYSPATH, Oddvars( SYSPATH ) + 'dbfstru\' )       // Fool system in thinking default dir is dbcheck

Createdbfs()                         // Create dbf's ( with NEW_DBF_EXT ) extensions

Oddvars( SYSPATH, cOldSysPath )       // Set system path back on rails

Kill( Oddvars( SYSPATH ) + 'datadict.std' )

aNewStructure := asort( directory( OddVars( SYSPATH) + 'dbfstru\*' + NEW_DBF_EXT ), , ,{ |p1,p2| p1[1] < p2[1] } )  // Sorted Array of DD files

// Our new Data Dict ( DD ) is to be built from files in dbfstru
ddstruct := {}                       
aadd( ddstruct, { "file_name", "C", 10 , 0 } )
aadd( ddstruct, { "field_name", "C", 10 , 0 } )
aadd( ddstruct, { "field_type", "C", 1 , 0 } )
aadd( ddstruct, { "field_len", "N", 3, 0 } )
aadd( ddstruct, { "field_dec", "N", 2, 0 } )
dbcreate( Oddvars( SYSPATH) + 'datadict.std', ddstruct )

Netuse( 'datadict.std', EXCLUSIVE, , 'std' )

for x := 1 to len( aNewStructure )

 sFname  := OddVars( SYSPATH ) + 'dbfstru\' + aNewStructure[ x, 1 ]
 Netuse( sFname, EXCLUSIVE, ,'dbcheck' )
 mstruct := dbcheck->( dbstruct() )
 dbcheck->( dbclosearea() )

 for y := 1 to len( mstruct )

  fname := aNewStructure[ x, 1 ]

  if !( left( fname, 1 ) $ 'Z~_' )

   Add_rec( 'std' )
   std->file_name := substr( aNewStructure[ x,1 ], 1, at( '.', aNewStructure[ x,1] ) -1 )
   std->field_name := mstruct[ y, 1 ]
   std->field_type := mstruct[ y, 2 ]
   std->field_len := mstruct[ y, 3 ]
   std->field_dec := mstruct[ y, 4 ]
   std->( dbrunlock() )

  endif

 next

next

// altD()

Box_Save( 7, 10, 12, 70 )

@ 8, 12 say 'Data Dictionary built ' + Ns( std->( reccount() ) )+ ' records created'

Kill( OddVars( SYSPATH ) + "datadict.old" )

ddstruct := {}
aadd( ddstruct, { "file_name", "C", 10 , 0 } )
aadd( ddstruct, { "field_name", "C", 10 , 0 } )
aadd( ddstruct, { "field_type", "C", 1 , 0 } )
aadd( ddstruct, { "field_len", "N", 3, 0 } )
aadd( ddstruct, { "field_dec", "N", 2, 0 } )
dbcreate( OddVars( SYSPATH ) + "datadict.old", ddstruct )

Netuse( 'datadict.old', EXCLUSIVE, ,'ddold' )

for x := 1 to len( aCurrentDbf )
  // fwrite( fhandle,'File in use ' + aCurrentDbf[ x, 1 ] + CRLF )
  if !file( Oddvars( SYSPATH ) + aCurrentDbf[x, 1] )
   Error( 'File ' + aCurrentDbf[ x, 1 ] + ' not found' )

  else
   Netuse( aCurrentDbf[ x, 1 ], EXCLUSIVE )
   mstruct := dbstruct()
   dbclosearea()

   for y := 1 to len( mstruct )
    fname := aCurrentDbf[ x, 1 ]

    if !( left( fname, 1 ) $ 'Z~_' )  // Don't check temp etc files
     Add_rec( 'ddold' )
     ddold->file_name := substr( aCurrentDbf[ x, 1 ], 1, at( '.', aCurrentDbf[ x, 1 ] ) -1 )
     ddold->field_name := mstruct[ y, 1 ]
     ddold->field_type := mstruct[ y, 2 ]
     ddold->field_len := mstruct[ y, 3 ]
     ddold->field_dec := mstruct[ y, 4 ]
     ddold->( dbrunlock() )

    endif
    Pinwheel( NOINTERUPT )

   next
   Pinwheel( NOINTERUPT )

  endif

next

select ddold

@ 09, 12 say 'New Data Dictionary built ' + Ns( ddold->( reccount() ) ) + ' records created'
@ 10, 12 say 'Forward Searching - Wait about'

select std
indx( 'file_name+field_name', 'filename' )

select ddold
set relation to ddold->file_name+ddold->field_name into std

dbgotop()
while !eof() .and. Pinwheel( NOINTERUPT )
 do case
 case std->( eof() )  // Field not found in std
  fdisp( fhandle,  'Field not found in standard ' )
 case std->field_type != ddold->field_type
  fdisp( fhandle,  'Field type mismatch  - Standard = ' + std->field_type )
 case std->field_len != ddold->field_len
  fdisp( fhandle,  'Field length mismatch  - Standard = ' + Ns( std->field_len ) )
 case std->field_dec != ddold->field_dec
  fdisp( fhandle,  'Field Decimals mismatch  - Standard = ' + Ns( std->field_dec ) )
 otherwise
  fdisp( fhandle,  '' )
 endcase
 dbskip()
enddo
select std
orddestroy( 'filename' )

@ 11, 12 say 'Backward Searching - Wait about'

select ddold
set relation to
indx( 'file_name+field_name', 'ddold' )
select std
set relation to std->file_name + std->field_name into ddold
std->( dbgotop() )
while !std->( eof() ) .and. Pinwheel( NOINTERUPT )
 if ddold->( eof() )
  fwrite( fhandle,'File ' + std->file_name + '  Standard field ' + std->field_name + ' not on local dbfs' + CRLF )
 endif
 std->( dbskip() )
enddo
ddold->( orddestroy( 'ddold' ) )
dbcloseall()
fclose( fhandle )

Kill( Oddvars( SYSPATH ) + 'datadict.old' )
Kill( Oddvars( SYSPATH ) + 'datadict.new' )

Box_Restore( sScreen )
sScreen := Box_Save( 01, 02, 23, 78 )
memoedit( memoread( 'dbdifs.txt' ), 02, 3, 22, 77 )
Box_Restore( sScreen )
return nil

*

function fdisp ( mhandle, mstr )
local sScreen:=Box_Save( 2,40,8,75 )
@ 3,42 say 'File Name ' + ddold->file_name
@ 4,42 say 'Field Name ' + ddold->field_name
@ 5,42 say 'Field Type ' + ddold->field_type
@ 6,42 say 'Field Len  ' + Ns( ddold->field_len ) 
@ 7,42 say 'Field Dec  ' + Ns( ddold->field_dec )
if !empty( mstr )
 fwrite( mhandle,'File Name ' + ddold->file_name + CRLF )
 fwrite( mhandle,'Field Name ' + ddold->field_name + CRLF )
 fwrite( mhandle,'Field Type ' + ddold->field_type + CRLF )
 fwrite( mhandle,'Field Len  ' + Ns( ddold->field_len ) + CRLF ) 
 fwrite( mhandle,'Field Dec  ' + Ns( ddold->field_dec ) + CRLF )
 fwrite( mhandle, mstr  + CRLF + replicate( chr( 196 ), 40 ) + CRLF )
endif
return nil

*

function Createdbfs ( sSysPath )
local aArray

if sSysPath = nil
 sSysPath = Oddvars( SYSPATH )

endif

// bisac
aArray := {} 
aadd( aArray, { "brec", "c", 80, 0 } )
dbcreate( sSysPath + "bisac" + NEW_DBF_EXT, aArray )

// branch
aArray := {} 
aadd( aArray, { "code", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "name", "c", 25, 0 } )
aadd( aArray, { "add1", "c", 25, 0 } )
aadd( aArray, { "add2", "c", 25, 0 } )
aadd( aArray, { "add3", "c", 25, 0 } )
aadd( aArray, { "phone", "c", PHONE_NUM_LEN, 0 } )
aadd( aArray, { "contact", "c", 25, 0 } )
aadd( aArray, { "modem", "c", 25, 0 } )
aadd( aArray, { "baud", "n", 6, 0 } )
aadd( aArray, { "start", "c", 8, 0 } )
aadd( aArray, { "username", "c", 20, 0 } )
aadd( aArray, { "password", "c", 20, 0 } )
dbcreate( sSysPath + "branch" + NEW_DBF_EXT, aArray )

// dept
aArray := {} 
aadd( aArray, { "code", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "name", "c", 20, 0 } )
aadd( aArray, { "extra_key", "c", 3, 0 } )
aadd( aArray, { "shelf_len", "n", 10, 2 } )
aadd( aArray, { "week_sell", "n", 10, 2 } )
aadd( aArray, { "week_cost", "n", 10, 2 } )
aadd( aArray, { "week_disc", "n", 10, 2 } )
dbcreate( sSysPath + "dept" + NEW_DBF_EXT, aArray )

// draft_po
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "supp_code", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "department", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "date_ord", "d", 8, 0 } )
aadd( aArray, { "special", "l", 1, 0 } )
aadd( aArray, { "skey", "c", 10, 0 } )
aadd( aArray, { "hold", "l", 1, 0 } )
aadd( aArray, { "source", "c", 2, 0 } )
aadd( aArray, { "comment", "c", 80, 0 } )
aadd( aArray, { "drawexcess", "l", 1, 0 } )
aadd( aArray, { "drawtransf", "l", 1, 0 } )
dbcreate( sSysPath + "draft_po" + NEW_DBF_EXT, aArray )

// DraftRet
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "supp_code", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "brand", "c", BRAND_CODE_LEN, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "type", "c", 1, 0 } )
aadd( aArray, { "docket", "l", 1, 0 } )
aadd( aArray, { "skey", "c", 5, 0 } )
aadd( aArray, { "desc", "c", 20, 0 } )
aadd( aArray, { "alt_desc", "c", 20, 0 } )
aadd( aArray, { "cost", "n", 10, 2 } )
aadd( aArray, { "rrp", "n", 10, 2 } )
aadd( aArray, { "sell", "n", 10, 2 } )
aadd( aArray, { "invmacro", "c", 2, 0 } )
aadd( aArray, { "stkhistoff", "n", 4, 0 } )
aadd( aArray, { "department", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "hold", "l", 1, 0 } )
aadd( aArray, { "number", "n", 6, 0 } )
aadd( aArray, { "ret_code", "c", 2, 0 } )
aadd( aArray, { "reference", "c", 30, 0 } )
aadd( aArray, { "invdate", "d", 8, 0 } )
dbcreate( sSysPath + "DraftRet" + NEW_DBF_EXT, aArray )

// psales
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "tran_type", "c", 3, 0 } )
aadd( aArray, { "tend_type", "c", 3, 0 } )
aadd( aArray, { "mktg_type", "c", 3, 0 } )
aadd( aArray, { "sale_type", "c", 3, 0 } )
aadd( aArray, { "tran_num", "n", 6, 0 } )
aadd( aArray, { "unit_price", "n", 10, 2 } )
aadd( aArray, { "discount", "n", 10, 2 } )
aadd( aArray, { "cost_price", "n", 10, 2 } )
aadd( aArray, { "sales_tax", "n", 10, 2 } )
aadd( aArray, { "freight", "n", 10, 2 } )
aadd( aArray, { "rounding", "n", 10, 2 } )
aadd( aArray, { "register", "c", 10, 0 } )
aadd( aArray, { "sale_date", "d", 8, 0 } )
aadd( aArray, { "time", "c", 8, 0 } )
aadd( aArray, { "bank", "c", 3, 0 } )
aadd( aArray, { "bnkbranch", "c", 20, 0 } )
aadd( aArray, { "drawer", "c", 20, 0 } )
aadd( aArray, { "name", "c", 20, 0 } )
aadd( aArray, { "invno", "n", 6, 0 } )
aadd( aArray, { "spec_no", "n", 6, 0 } )
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "mop", "c", 3, 0 } )
aadd( aArray, { "operator", "c", OPERATOR_CODE_LEN, 0 } )
aadd( aArray, { "voucher", "c", 10, 0 } )
aadd( aArray, { "locflag", "c", 1, 0 } )
aadd( aArray, { "consign", "l", 1, 0 } )
dbcreate( sSysPath + "psales" + NEW_DBF_EXT, aArray )

// master
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "catalog", "c", 12, 0 } )
aadd( aArray, { "desc", "c", DESC_LEN, 0 } )
aadd( aArray, { "alt_desc", "c", ALT_DESC_LEN, 0 } )
aadd( aArray, { "brand", "c", BRAND_CODE_LEN, 0 } )
aadd( aArray, { "supp_code", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "supp_code2", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "supp_code3", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "department", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "cost_price", "n", 10, 2 } )
aadd( aArray, { "avr_cost", "n", 10, 2 } )
aadd( aArray, { "nett_price", "n", 10, 2 } )
aadd( aArray, { "sell_price", "n", 10, 2 } )
aadd( aArray, { "retail", "n", 10, 2 } )
aadd( aArray, { "st_amt", "n", 10, 2 } )
aadd( aArray, { "onhand", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "special", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "minstock", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "approval", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "stocktake", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "onorder", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "held", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "pp_onhand", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "excess", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "consign", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "sales_tax", "n", 1, 0 } )
aadd( aArray, { "sale_ret", "l", 1, 0 } )
aadd( aArray, { "lastpo", "n", PO_NUM_LEN, 0 } )
aadd( aArray, { "date_po", "d", 8, 0 } )
aadd( aArray, { "lastqty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "dlastrecv", "d", 8, 0 } )
aadd( aArray, { "status", "c", 3, 0 } )
aadd( aArray, { "binding", "c", 2, 0 } )
aadd( aArray, { "edition", "c", 2, 0 } )
aadd( aArray, { "location", "c", 11, 0 } )
aadd( aArray, { "dsale", "d", 8, 0 } )
aadd( aArray, { "comments", "c", 40, 0 } )
aadd( aArray, { "year", "c", 4, 0 } )
aadd( aArray, { "update", "l", 1, 0 } )
aadd( aArray, { "retdate", "d", 8, 0 } )
aadd( aArray, { "retqty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "entered", "d", 8, 0 } )
aadd( aArray, { "nodisc", "l", 1, 0 } )
aadd( aArray, { "taxexempt", "l", 1, 0 } )
#ifdef IS_BOOKSHOP
aadd( aArray, { "book_no", "c", 10, 0 } )
aadd( aArray, { "illustrat", "c", 30, 0 } )
#endif
dbcreate( sSysPath + "master" + NEW_DBF_EXT, aArray )

// operator
aArray := {} 
aadd( aArray, { "code", "c", OPERATOR_CODE_LEN, 0 } )
aadd( aArray, { "name", "c", 25, 0 } )
aadd( aArray, { "password", "c", 10, 0 } )
aadd( aArray, { "mask", "c", 50, 0 } )
dbcreate( sSysPath + "operator" + NEW_DBF_EXT, aArray )

// retcodes
aArray := {} 
aadd( aArray, { "code", "c", 2, 0 } )
aadd( aArray, { "name", "c", 50, 0 } )
dbcreate( sSysPath + "retcodes" + NEW_DBF_EXT, aArray )

// teleorde
aArray := {} 
aadd( aArray, { "code", "c", 10, 0 } )
aadd( aArray, { "name", "c", 20, 0 } )
aadd( aArray, { "data_no", "c", 20, 0 } )
aadd( aArray, { "username", "c", 20, 0 } )
aadd( aArray, { "password", "c", 20, 0 } )
dbcreate( sSysPath + "teleorde" + NEW_DBF_EXT, aArray )

// ftsales
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "cost_price", "n", 10, 2 } )
dbcreate( sSysPath + "ftsales" + NEW_DBF_EXT, aArray )

// accvars
aArray := {} 
aadd( aArray, { "l_deb_age", "d", 8, 0 } )
aadd( aArray, { "l_cre_age", "d", 8, 0 } )
aadd( aArray, { "op_bal", "n", 10, 2 } )
aadd( aArray, { "cop_bal", "n", 10, 2 } )
aadd( aArray, { "st1", "n", 5, 2 } )
aadd( aArray, { "st2", "n", 5, 2 } )
aadd( aArray, { "st3", "n", 5, 2 } )
aadd( aArray, { "st4", "n", 5, 2 } )
aadd( aArray, { "st5", "n", 5, 2 } )
aadd( aArray, { "int_rate", "n", 6, 2 } )
dbcreate( sSysPath + "accvars" + NEW_DBF_EXT, aArray )

// supplier
aArray := {} 
aadd( aArray, { "code", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "name", "c", 30, 0 } )
aadd( aArray, { "address1", "c", 30, 0 } )
aadd( aArray, { "address2", "c", 30, 0 } )
aadd( aArray, { "city", "c", 30, 0 } )
aadd( aArray, { "country", "c", 30, 0 } )
aadd( aArray, { "raddress1", "c", 30, 0 } )
aadd( aArray, { "raddress2", "c", 30, 0 } )
aadd( aArray, { "rcity", "c", 30, 0 } )
aadd( aArray, { "account", "c", 15, 0 } )
aadd( aArray, { "contact", "c", 30, 0 } )
aadd( aArray, { "min_ord", "n", 4, 0 } )
aadd( aArray, { "std_disc", "n", 6, 2 } )
aadd( aArray, { "lead_time", "n", 2, 0 } )
aadd( aArray, { "returns", "l", 1, 0 } )
aadd( aArray, { "phone", "c", PHONE_NUM_LEN, 0 } )
aadd( aArray, { "data_no", "c",PHONE_NUM_LEN , 0 } )
aadd( aArray, { "fax", "c", PHONE_NUM_LEN, 0 } )
aadd( aArray, { "homepage", "c", 30, 0 } )
aadd( aArray, { "email", "c", 30, 0 } )
aadd( aArray, { "comm1", "c", 30, 0 } )
aadd( aArray, { "comm2", "c", 30, 0 } )
aadd( aArray, { "posort", "c", 1, 0 } )
aadd( aArray, { "price_meth", "c", 1, 0 } )
aadd( aArray, { "gst_inc", "l", 1, 0 } )
aadd( aArray, { "san", "c", 12, 0 } )
aadd( aArray, { "amtcur", "n", 10, 2 } )
aadd( aArray, { "amt30", "n", 10, 2 } )
aadd( aArray, { "amt60", "n", 10, 2 } )
aadd( aArray, { "amt90", "n", 10, 2 } )
aadd( aArray, { "op_it", "l", 1, 0 } )
aadd( aArray, { "laststat", "n", 10, 2 } )
aadd( aArray, { "lastbuy", "n", 1, 0 } )
aadd( aArray, { "ytdamt", "n", 10, 2 } )
aadd( aArray, { "pytdamt", "n", 10, 2 } )
aadd( aArray, { "pay_amt", "n", 10, 2 } )
aadd( aArray, { "pay_date", "d", 8, 0 } )
aadd( aArray, { "teleorder", "c", 10, 0 } )
aadd( aArray, { "username", "c", 20, 0 } )
aadd( aArray, { "password", "c", 10, 0 } )
aadd( aArray, { "extra_key", "c", 10, 0 } )
aadd( aArray, { "supplytype", "c", 1, 0 } )
aadd( aArray, { "forexcode", "c", 4, 0 } )
dbcreate( sSysPath + "supplier" + NEW_DBF_EXT, aArray )

// salescde
aArray := {} 
aadd( aArray, { "code", "c", 2, 0 } )
aadd( aArray, { "name", "c", 20, 0 } )
dbcreate( sSysPath + "salescde" + NEW_DBF_EXT, aArray )

// macatego
aArray := {} 
aadd( aArray, { "code", "c", 6, 0 } )
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "skey", "c", 5, 0 } )
dbcreate( sSysPath + "macatego" + NEW_DBF_EXT, aArray )

// stock
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "onhand", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "available", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "onorder", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "excess", "n", QTY_LEN, QTY_DEC } )
dbcreate( sSysPath + "stock" + NEW_DBF_EXT, aArray )

// suppweek
aArray := {} 
aadd( aArray, { "code", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "year", "c", 4, 0 } )
aadd( aArray, { "c1", "n", 10, 2 } )
aadd( aArray, { "c2", "n", 10, 2 } )
aadd( aArray, { "c3", "n", 10, 2 } )
aadd( aArray, { "c4", "n", 10, 2 } )
aadd( aArray, { "c5", "n", 10, 2 } )
aadd( aArray, { "c6", "n", 10, 2 } )
aadd( aArray, { "c7", "n", 10, 2 } )
aadd( aArray, { "c8", "n", 10, 2 } )
aadd( aArray, { "c9", "n", 10, 2 } )
aadd( aArray, { "c10", "n", 10, 2 } )
aadd( aArray, { "c11", "n", 10, 2 } )
aadd( aArray, { "c12", "n", 10, 2 } )
aadd( aArray, { "c13", "n", 10, 2 } )
aadd( aArray, { "c14", "n", 10, 2 } )
aadd( aArray, { "c15", "n", 10, 2 } )
aadd( aArray, { "c16", "n", 10, 2 } )
aadd( aArray, { "c17", "n", 10, 2 } )
aadd( aArray, { "c18", "n", 10, 2 } )
aadd( aArray, { "c19", "n", 10, 2 } )
aadd( aArray, { "c20", "n", 10, 2 } )
aadd( aArray, { "c21", "n", 10, 2 } )
aadd( aArray, { "c22", "n", 10, 2 } )
aadd( aArray, { "c23", "n", 10, 2 } )
aadd( aArray, { "c24", "n", 10, 2 } )
aadd( aArray, { "c25", "n", 10, 2 } )
aadd( aArray, { "c26", "n", 10, 2 } )
aadd( aArray, { "c27", "n", 10, 2 } )
aadd( aArray, { "c28", "n", 10, 2 } )
aadd( aArray, { "c29", "n", 10, 2 } )
aadd( aArray, { "c30", "n", 10, 2 } )
aadd( aArray, { "c31", "n", 10, 2 } )
aadd( aArray, { "c32", "n", 10, 2 } )
aadd( aArray, { "c33", "n", 10, 2 } )
aadd( aArray, { "c34", "n", 10, 2 } )
aadd( aArray, { "c35", "n", 10, 2 } )
aadd( aArray, { "c36", "n", 10, 2 } )
aadd( aArray, { "c37", "n", 10, 2 } )
aadd( aArray, { "c38", "n", 10, 2 } )
aadd( aArray, { "c39", "n", 10, 2 } )
aadd( aArray, { "c40", "n", 10, 2 } )
aadd( aArray, { "c41", "n", 10, 2 } )
aadd( aArray, { "c42", "n", 10, 2 } )
aadd( aArray, { "c43", "n", 10, 2 } )
aadd( aArray, { "c44", "n", 10, 2 } )
aadd( aArray, { "c45", "n", 10, 2 } )
aadd( aArray, { "c46", "n", 10, 2 } )
aadd( aArray, { "c47", "n", 10, 2 } )
aadd( aArray, { "c48", "n", 10, 2 } )
aadd( aArray, { "c49", "n", 10, 2 } )
aadd( aArray, { "c50", "n", 10, 2 } )
aadd( aArray, { "c51", "n", 10, 2 } )
aadd( aArray, { "c52", "n", 10, 2 } )
aadd( aArray, { "c53", "n", 10, 2 } )
aadd( aArray, { "s1", "n", 10, 2 } )
aadd( aArray, { "s2", "n", 10, 2 } )
aadd( aArray, { "s3", "n", 10, 2 } )
aadd( aArray, { "s4", "n", 10, 2 } )
aadd( aArray, { "s5", "n", 10, 2 } )
aadd( aArray, { "s6", "n", 10, 2 } )
aadd( aArray, { "s7", "n", 10, 2 } )
aadd( aArray, { "s8", "n", 10, 2 } )
aadd( aArray, { "s9", "n", 10, 2 } )
aadd( aArray, { "s10", "n", 10, 2 } )
aadd( aArray, { "s11", "n", 10, 2 } )
aadd( aArray, { "s12", "n", 10, 2 } )
aadd( aArray, { "s13", "n", 10, 2 } )
aadd( aArray, { "s14", "n", 10, 2 } )
aadd( aArray, { "s15", "n", 10, 2 } )
aadd( aArray, { "s16", "n", 10, 2 } )
aadd( aArray, { "s17", "n", 10, 2 } )
aadd( aArray, { "s18", "n", 10, 2 } )
aadd( aArray, { "s19", "n", 10, 2 } )
aadd( aArray, { "s20", "n", 10, 2 } )
aadd( aArray, { "s21", "n", 10, 2 } )
aadd( aArray, { "s22", "n", 10, 2 } )
aadd( aArray, { "s23", "n", 10, 2 } )
aadd( aArray, { "s24", "n", 10, 2 } )
aadd( aArray, { "s25", "n", 10, 2 } )
aadd( aArray, { "s26", "n", 10, 2 } )
aadd( aArray, { "s27", "n", 10, 2 } )
aadd( aArray, { "s28", "n", 10, 2 } )
aadd( aArray, { "s29", "n", 10, 2 } )
aadd( aArray, { "s30", "n", 10, 2 } )
aadd( aArray, { "s31", "n", 10, 2 } )
aadd( aArray, { "s32", "n", 10, 2 } )
aadd( aArray, { "s33", "n", 10, 2 } )
aadd( aArray, { "s34", "n", 10, 2 } )
aadd( aArray, { "s35", "n", 10, 2 } )
aadd( aArray, { "s36", "n", 10, 2 } )
aadd( aArray, { "s37", "n", 10, 2 } )
aadd( aArray, { "s38", "n", 10, 2 } )
aadd( aArray, { "s39", "n", 10, 2 } )
aadd( aArray, { "s40", "n", 10, 2 } )
aadd( aArray, { "s41", "n", 10, 2 } )
aadd( aArray, { "s42", "n", 10, 2 } )
aadd( aArray, { "s43", "n", 10, 2 } )
aadd( aArray, { "s44", "n", 10, 2 } )
aadd( aArray, { "s45", "n", 10, 2 } )
aadd( aArray, { "s46", "n", 10, 2 } )
aadd( aArray, { "s47", "n", 10, 2 } )
aadd( aArray, { "s48", "n", 10, 2 } )
aadd( aArray, { "s49", "n", 10, 2 } )
aadd( aArray, { "s50", "n", 10, 2 } )
aadd( aArray, { "s51", "n", 10, 2 } )
aadd( aArray, { "s52", "n", 10, 2 } )
aadd( aArray, { "s53", "n", 10, 2 } )
dbcreate( sSysPath + "suppweek" + NEW_DBF_EXT, aArray )

// deptweek
aArray := {} 
aadd( aArray, { "code", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "year", "c", 4, 0 } )
aadd( aArray, { "c1", "n", 10, 2 } )
aadd( aArray, { "c2", "n", 10, 2 } )
aadd( aArray, { "c3", "n", 10, 2 } )
aadd( aArray, { "c4", "n", 10, 2 } )
aadd( aArray, { "c5", "n", 10, 2 } )
aadd( aArray, { "c6", "n", 10, 2 } )
aadd( aArray, { "c7", "n", 10, 2 } )
aadd( aArray, { "c8", "n", 10, 2 } )
aadd( aArray, { "c9", "n", 10, 2 } )
aadd( aArray, { "c10", "n", 10, 2 } )
aadd( aArray, { "c11", "n", 10, 2 } )
aadd( aArray, { "c12", "n", 10, 2 } )
aadd( aArray, { "c13", "n", 10, 2 } )
aadd( aArray, { "c14", "n", 10, 2 } )
aadd( aArray, { "c15", "n", 10, 2 } )
aadd( aArray, { "c16", "n", 10, 2 } )
aadd( aArray, { "c17", "n", 10, 2 } )
aadd( aArray, { "c18", "n", 10, 2 } )
aadd( aArray, { "c19", "n", 10, 2 } )
aadd( aArray, { "c20", "n", 10, 2 } )
aadd( aArray, { "c21", "n", 10, 2 } )
aadd( aArray, { "c22", "n", 10, 2 } )
aadd( aArray, { "c23", "n", 10, 2 } )
aadd( aArray, { "c24", "n", 10, 2 } )
aadd( aArray, { "c25", "n", 10, 2 } )
aadd( aArray, { "c26", "n", 10, 2 } )
aadd( aArray, { "c27", "n", 10, 2 } )
aadd( aArray, { "c28", "n", 10, 2 } )
aadd( aArray, { "c29", "n", 10, 2 } )
aadd( aArray, { "c30", "n", 10, 2 } )
aadd( aArray, { "c31", "n", 10, 2 } )
aadd( aArray, { "c32", "n", 10, 2 } )
aadd( aArray, { "c33", "n", 10, 2 } )
aadd( aArray, { "c34", "n", 10, 2 } )
aadd( aArray, { "c35", "n", 10, 2 } )
aadd( aArray, { "c36", "n", 10, 2 } )
aadd( aArray, { "c37", "n", 10, 2 } )
aadd( aArray, { "c38", "n", 10, 2 } )
aadd( aArray, { "c39", "n", 10, 2 } )
aadd( aArray, { "c40", "n", 10, 2 } )
aadd( aArray, { "c41", "n", 10, 2 } )
aadd( aArray, { "c42", "n", 10, 2 } )
aadd( aArray, { "c43", "n", 10, 2 } )
aadd( aArray, { "c44", "n", 10, 2 } )
aadd( aArray, { "c45", "n", 10, 2 } )
aadd( aArray, { "c46", "n", 10, 2 } )
aadd( aArray, { "c47", "n", 10, 2 } )
aadd( aArray, { "c48", "n", 10, 2 } )
aadd( aArray, { "c49", "n", 10, 2 } )
aadd( aArray, { "c50", "n", 10, 2 } )
aadd( aArray, { "c51", "n", 10, 2 } )
aadd( aArray, { "c52", "n", 10, 2 } )
aadd( aArray, { "c53", "n", 10, 2 } )
aadd( aArray, { "s1", "n", 10, 2 } )
aadd( aArray, { "s2", "n", 10, 2 } )
aadd( aArray, { "s3", "n", 10, 2 } )
aadd( aArray, { "s4", "n", 10, 2 } )
aadd( aArray, { "s5", "n", 10, 2 } )
aadd( aArray, { "s6", "n", 10, 2 } )
aadd( aArray, { "s7", "n", 10, 2 } )
aadd( aArray, { "s8", "n", 10, 2 } )
aadd( aArray, { "s9", "n", 10, 2 } )
aadd( aArray, { "s10", "n", 10, 2 } )
aadd( aArray, { "s11", "n", 10, 2 } )
aadd( aArray, { "s12", "n", 10, 2 } )
aadd( aArray, { "s13", "n", 10, 2 } )
aadd( aArray, { "s14", "n", 10, 2 } )
aadd( aArray, { "s15", "n", 10, 2 } )
aadd( aArray, { "s16", "n", 10, 2 } )
aadd( aArray, { "s17", "n", 10, 2 } )
aadd( aArray, { "s18", "n", 10, 2 } )
aadd( aArray, { "s19", "n", 10, 2 } )
aadd( aArray, { "s20", "n", 10, 2 } )
aadd( aArray, { "s21", "n", 10, 2 } )
aadd( aArray, { "s22", "n", 10, 2 } )
aadd( aArray, { "s23", "n", 10, 2 } )
aadd( aArray, { "s24", "n", 10, 2 } )
aadd( aArray, { "s25", "n", 10, 2 } )
aadd( aArray, { "s26", "n", 10, 2 } )
aadd( aArray, { "s27", "n", 10, 2 } )
aadd( aArray, { "s28", "n", 10, 2 } )
aadd( aArray, { "s29", "n", 10, 2 } )
aadd( aArray, { "s30", "n", 10, 2 } )
aadd( aArray, { "s31", "n", 10, 2 } )
aadd( aArray, { "s32", "n", 10, 2 } )
aadd( aArray, { "s33", "n", 10, 2 } )
aadd( aArray, { "s34", "n", 10, 2 } )
aadd( aArray, { "s35", "n", 10, 2 } )
aadd( aArray, { "s36", "n", 10, 2 } )
aadd( aArray, { "s37", "n", 10, 2 } )
aadd( aArray, { "s38", "n", 10, 2 } )
aadd( aArray, { "s39", "n", 10, 2 } )
aadd( aArray, { "s40", "n", 10, 2 } )
aadd( aArray, { "s41", "n", 10, 2 } )
aadd( aArray, { "s42", "n", 10, 2 } )
aadd( aArray, { "s43", "n", 10, 2 } )
aadd( aArray, { "s44", "n", 10, 2 } )
aadd( aArray, { "s45", "n", 10, 2 } )
aadd( aArray, { "s46", "n", 10, 2 } )
aadd( aArray, { "s47", "n", 10, 2 } )
aadd( aArray, { "s48", "n", 10, 2 } )
aadd( aArray, { "s49", "n", 10, 2 } )
aadd( aArray, { "s50", "n", 10, 2 } )
aadd( aArray, { "s51", "n", 10, 2 } )
aadd( aArray, { "s52", "n", 10, 2 } )
aadd( aArray, { "s53", "n", 10, 2 } )
dbcreate( sSysPath + "deptweek" + NEW_DBF_EXT, aArray )

// stkhist
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "reference", "c", 20, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "type", "c", 1, 0 } )
aadd( aArray, { "supp_code", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "cost_price", "n", 10, 2 } )
aadd( aArray, { "sell_price", "n", 10, 2 } )
aadd( aArray, { "forexamt", "n", 7, 2 } )
aadd( aArray, { "forexrate", "n", 7, 2 } )
aadd( aArray, { "forexcode", "c", 3, 0 } )
aadd( aArray, { "period", "n", 2, 0 } )
dbcreate( sSysPath + "stkhist" + NEW_DBF_EXT, aArray )

// aphist
aArray := {} 
aadd( aArray, { "code", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "ttype", "n", 1, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "duedate", "d", 8, 0 } )
aadd( aArray, { "tnum", "c", 10, 0 } )
aadd( aArray, { "amt", "n", 10, 2 } )
aadd( aArray, { "amtpaid", "n", 10, 2 } )
aadd( aArray, { "tage", "n", 1, 0 } )
aadd( aArray, { "pay", "l", 1, 0 } )
aadd( aArray, { "pay_amt", "n", 10, 2 } )
aadd( aArray, { "discount", "n", 2, 0 } )
aadd( aArray, { "dis_amt", "n", 7, 2 } )
aadd( aArray, { "desc", "c", 20, 0 } )
aadd( aArray, { "printed", "l", 1, 0 } )
dbcreate( sSysPath + "aphist" + NEW_DBF_EXT, aArray )

// sysrec
aArray := {} 
aadd( aArray, { "ponum1", "n", PO_NUM_LEN, 0 } )
aadd( aArray, { "ponum2", "n", PO_NUM_LEN, 0 } )
aadd( aArray, { "ponum3", "n", PO_NUM_LEN, 0 } )
aadd( aArray, { "ponum4", "n", PO_NUM_LEN, 0 } )
aadd( aArray, { "ponum5", "n", PO_NUM_LEN, 0 } )
aadd( aArray, { "specno", "n", PO_NUM_LEN, 0 } )
aadd( aArray, { "laybyno", "n", 6, 0 } )
aadd( aArray, { "invno", "n", 6, 0 } )
aadd( aArray, { "creditnote", "n", 6, 0 } )
aadd( aArray, { "custno", "n", 6, 0 } )
aadd( aArray, { "retnum", "n", 6, 0 } )
aadd( aArray, { "appno", "n", 6, 0 } )
aadd( aArray, { "tr_request", "n", 6, 0 } )
aadd( aArray, { "transfer", "n", 6, 0 } )
aadd( aArray, { "secondhand", "n", 6, 0 } )
aadd( aArray, { "pickslip", "n", 6, 0 } )
aadd( aArray, { "sale_close", "n", 6, 0 } )
aadd( aArray, { "fax", "n", 6, 0 } )
aadd( aArray, { "file", "n", 6, 0 } )
aadd( aArray, { "receipt", "n", 6, 0 } )
aadd( aArray, { "booklist", "n", 6, 0 } )
aadd( aArray, { "proforma", "n", 6, 0 } )
aadd( aArray, { "recvbatch", "n", 6, 0 } )
aadd( aArray, { "flagstk", "l", 1, 0 } )
aadd( aArray, { "stkdept", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "stktype", "c", 1, 0 } )
aadd( aArray, { "sysword", "c", 10, 0 } )
aadd( aArray, { "sysword1", "c", 10, 0 } )
aadd( aArray, { "last_up_re", "c", 13, 0 } )
aadd( aArray, { "pos4", "c", 3, 0 } )
aadd( aArray, { "posn4", "c", 20, 0 } )
aadd( aArray, { "pos4cash", "l", 1, 0 } )
aadd( aArray, { "pos5", "c", 3, 0 } )
aadd( aArray, { "posn5", "c", 20, 0 } )
aadd( aArray, { "pos5cash", "l", 1, 0 } )
aadd( aArray, { "pos6", "c", 3, 0 } )
aadd( aArray, { "posn6", "c", 20, 0 } )
aadd( aArray, { "pos6cash", "l", 1, 0 } )
aadd( aArray, { "pos7", "c", 3, 0 } )
aadd( aArray, { "posn7", "c", 20, 0 } )
aadd( aArray, { "pos7cash", "l", 1, 0 } )
aadd( aArray, { "pos8", "c", 3, 0 } )
aadd( aArray, { "posn8", "c", 20, 0 } )
aadd( aArray, { "pos8cash", "l", 1, 0 } )
aadd( aArray, { "pos9", "c", 3, 0 } )
aadd( aArray, { "posn9", "c", 20, 0 } )
aadd( aArray, { "pos9cash", "l", 1, 0 } )
aadd( aArray, { "pos10", "c", 3, 0 } )
aadd( aArray, { "posn10", "c", 20, 0 } )
aadd( aArray, { "pos10cash", "l", 1, 0 } )
aadd( aArray, { "pos11", "c", 3, 0 } )
aadd( aArray, { "posn11", "c", 20, 0 } )
aadd( aArray, { "pos11cash", "l", 1, 0 } )
aadd( aArray, { "pos12", "c", 3, 0 } )
aadd( aArray, { "posn12", "c", 20, 0 } )
aadd( aArray, { "pos12cash", "l", 1, 0 } )
aadd( aArray, { "aud", "n", 8, 4 } )
aadd( aArray, { "nzd", "n", 8, 4 } )
aadd( aArray, { "ukp", "n", 8, 4 } )
aadd( aArray, { "usd", "n", 8, 4 } )
aadd( aArray, { "stype1", "c", 3, 0 } )
aadd( aArray, { "stype2", "c", 3, 0 } )
aadd( aArray, { "stype3", "c", 3, 0 } )
aadd( aArray, { "stype4", "c", 3, 0 } )
aadd( aArray, { "stype5", "c", 3, 0 } )
aadd( aArray, { "stype6", "c", 3, 0 } )
aadd( aArray, { "stype7", "c", 3, 0 } )
aadd( aArray, { "stype8", "c", 3, 0 } )
aadd( aArray, { "stype9", "c", 3, 0 } )
aadd( aArray, { "stype10", "c", 3, 0 } )
aadd( aArray, { "stypen1", "c", 20, 0 } )
aadd( aArray, { "stypen2", "c", 20, 0 } )
aadd( aArray, { "stypen3", "c", 20, 0 } )
aadd( aArray, { "stypen4", "c", 20, 0 } )
aadd( aArray, { "stypen5", "c", 20, 0 } )
aadd( aArray, { "stypen6", "c", 20, 0 } )
aadd( aArray, { "stypen7", "c", 20, 0 } )
aadd( aArray, { "stypen8", "c", 20, 0 } )
aadd( aArray, { "stypen9", "c", 20, 0 } )
aadd( aArray, { "stypen10", "c", 20, 0 } )
aadd( aArray, { "quote", "n", 6, 0 } )
dbcreate( sSysPath + "sysrec" + NEW_DBF_EXT, aArray )

// turnover
aArray := {} 
aadd( aArray, { "tran_type", "c", 3, 0 } )
aadd( aArray, { "day", "c", 2, 0 } )
aadd( aArray, { "jantot", "n", 10, 2 } )
aadd( aArray, { "jancost", "n", 10, 2 } )
aadd( aArray, { "jandis", "n", 10, 2 } )
aadd( aArray, { "janqty", "n", 10, 2 } )
aadd( aArray, { "jantax", "n", 10, 2 } )
aadd( aArray, { "febtot", "n", 10, 2 } )
aadd( aArray, { "febcost", "n", 10, 2 } )
aadd( aArray, { "febdis", "n", 10, 2 } )
aadd( aArray, { "febqty", "n", 10, 2 } )
aadd( aArray, { "febtax", "n", 10, 2 } )
aadd( aArray, { "martot", "n", 10, 2 } )
aadd( aArray, { "marcost", "n", 10, 2 } )
aadd( aArray, { "marqty", "n", 10, 2 } )
aadd( aArray, { "mardis", "n", 10, 2 } )
aadd( aArray, { "martax", "n", 10, 2 } )
aadd( aArray, { "aprtot", "n", 10, 2 } )
aadd( aArray, { "aprcost", "n", 10, 2 } )
aadd( aArray, { "aprdis", "n", 10, 2 } )
aadd( aArray, { "aprqty", "n", 10, 2 } )
aadd( aArray, { "aprtax", "n", 10, 2 } )
aadd( aArray, { "maytot", "n", 10, 2 } )
aadd( aArray, { "maycost", "n", 10, 2 } )
aadd( aArray, { "mayqty", "n", 10, 2 } )
aadd( aArray, { "maydis", "n", 10, 2 } )
aadd( aArray, { "maytax", "n", 10, 2 } )
aadd( aArray, { "juntot", "n", 10, 2 } )
aadd( aArray, { "juncost", "n", 10, 2 } )
aadd( aArray, { "junqty", "n", 10, 2 } )
aadd( aArray, { "jundis", "n", 10, 2 } )
aadd( aArray, { "juntax", "n", 10, 2 } )
aadd( aArray, { "jultot", "n", 10, 2 } )
aadd( aArray, { "julcost", "n", 10, 2 } )
aadd( aArray, { "julqty", "n", 10, 2 } )
aadd( aArray, { "juldis", "n", 10, 2 } )
aadd( aArray, { "jultax", "n", 10, 2 } )
aadd( aArray, { "augtot", "n", 10, 2 } )
aadd( aArray, { "augcost", "n", 10, 2 } )
aadd( aArray, { "augqty", "n", 10, 2 } )
aadd( aArray, { "augdis", "n", 10, 2 } )
aadd( aArray, { "augtax", "n", 10, 2 } )
aadd( aArray, { "septot", "n", 10, 2 } )
aadd( aArray, { "sepcost", "n", 10, 2 } )
aadd( aArray, { "sepqty", "n", 10, 2 } )
aadd( aArray, { "sepdis", "n", 10, 2 } )
aadd( aArray, { "septax", "n", 10, 2 } )
aadd( aArray, { "octtot", "n", 10, 2 } )
aadd( aArray, { "octcost", "n", 10, 2 } )
aadd( aArray, { "octqty", "n", 10, 2 } )
aadd( aArray, { "octdis", "n", 10, 2 } )
aadd( aArray, { "octtax", "n", 10, 2 } )
aadd( aArray, { "novtot", "n", 10, 2 } )
aadd( aArray, { "novcost", "n", 10, 2 } )
aadd( aArray, { "novdis", "n", 10, 2 } )
aadd( aArray, { "novqty", "n", 10, 2 } )
aadd( aArray, { "novtax", "n", 10, 2 } )
aadd( aArray, { "dectot", "n", 10, 2 } )
aadd( aArray, { "deccost", "n", 10, 2 } )
aadd( aArray, { "decqty", "n", 10, 2 } )
aadd( aArray, { "decdis", "n", 10, 2 } )
aadd( aArray, { "dectax", "n", 10, 2 } )
aadd( aArray, { "null", "c", 1, 0 } )
dbcreate( sSysPath + "turnover" + NEW_DBF_EXT, aArray )

// exchrate
aArray := {} 
aadd( aArray, { "code", "c", 4, 0 } )
aadd( aArray, { "name", "c", 30, 0 } )
aadd( aArray, { "rate", "n", 12, 4 } )
dbcreate( sSysPath + "exchrate" + NEW_DBF_EXT, aArray )

// bvars
aArray := {} 
aadd( aArray, { "name", "c", 30, 0 } )
aadd( aArray, { "serial", "c", 6, 0 } )
aadd( aArray, { "address1", "c", 30, 0 } )
aadd( aArray, { "address2", "c", 30, 0 } )
aadd( aArray, { "suburb", "c", 30, 0 } )
aadd( aArray, { "phone", "c", PHONE_NUM_LEN, 0 } )
aadd( aArray, { "fax", "c", PHONE_NUM_LEN, 0 } )
aadd( aArray, { "san", "c", 12, 0 } )
aadd( aArray, { "acn", "c", 14, 0 } )
aadd( aArray, { "poinst", "c", 19, 0 } )
aadd( aArray, { "greet", "c", 40, 0 } )
aadd( aArray, { "country", "c", 30, 0 } )
aadd( aArray, { "wp", "c", 20, 0 } )
aadd( aArray, { "wptype", "c", 2, 0 } )
aadd( aArray, { "std_disc", "n", 4, 1 } )
aadd( aArray, { "disc1", "n", 4, 1 } )
aadd( aArray, { "disc2", "n", 4, 1 } )
aadd( aArray, { "disc3", "n", 4, 1 } )
aadd( aArray, { "disc4", "n", 4, 1 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "st1", "n", 4, 1 } )
aadd( aArray, { "st2", "n", 4, 1 } )
aadd( aArray, { "st3", "n", 4, 1 } )
aadd( aArray, { "st4", "n", 4, 1 } )
aadd( aArray, { "gst_rate", "n", 4, 1 } )
aadd( aArray, { "bcptr", "c", 1, 0 } )
aadd( aArray, { "dockln1", "c", 20, 0 } )
aadd( aArray, { "dockln2", "c", 40, 0 } )
aadd( aArray, { "barline1", "c", 20, 0 } )
aadd( aArray, { "barline2", "c", 20, 0 } )
aadd( aArray, { "gst", "c", 10, 0 } )
aadd( aArray, { "gstrate", "n", 4, 1 } )
aadd( aArray, { "numstore", "n", 1, 0 } )
aadd( aArray, { "mthclear", "n", 2, 0 } )
aadd( aArray, { "stmess1", "c", 42, 0 } )
aadd( aArray, { "stmess2", "c", 42, 0 } )
aadd( aArray, { "stmess3", "c", 42, 0 } )
aadd( aArray, { "speccomm", "c", 25, 0 } )
aadd( aArray, { "lastper", "d", 8, 0 } )
aadd( aArray, { "perlen", "n", 3, 0 } )
aadd( aArray, { "bells", "l", 1, 0 } )
aadd( aArray, { "spdock", "n", 1, 0 } )
aadd( aArray, { "specslip", "n", 1, 0 } )
aadd( aArray, { "spdele", "n", 1, 0 } )
aadd( aArray, { "spadno", "n", 1, 0 } )
aadd( aArray, { "specstand", "l", 1, 0 } )
aadd( aArray, { "splet", "n", 1, 0 } )
aadd( aArray, { "spletgroup", "l", 1, 0 } )
aadd( aArray, { "spmin", "l", 1, 0 } )
aadd( aArray, { "ladock", "n", 1, 0 } )
aadd( aArray, { "lapay", "n", 1, 0 } )
aadd( aArray, { "ladele", "n", 1, 0 } )
aadd( aArray, { "lacomp", "n", 3, 0 } )
aadd( aArray, { "lacash", "l", 1, 0 } )
aadd( aArray, { "inin", "n", 1, 0 } )
aadd( aArray, { "incr", "n", 1, 0 } )
aadd( aArray, { "inqty", "n", 1, 0 } )
aadd( aArray, { "autoback", "l", 1, 0 } )
aadd( aArray, { "apnote", "n", 1, 0 } )
aadd( aArray, { "apqty", "n", 1, 0 } )
aadd( aArray, { "poqty", "n", 1, 0 } )
aadd( aArray, { "credcl", "n", 1, 0 } )
aadd( aArray, { "speclabe", "l", 1, 0 } )
aadd( aArray, { "booklist", "l", 1, 0 } )
aadd( aArray, { "reordqty", "n", 1, 0 } )
aadd( aArray, { "saleret", "l", 1, 0 } )
aadd( aArray, { "openitem", "l", 1, 0 } )
aadd( aArray, { "opencred", "l", 1, 0 } )
aadd( aArray, { "autocred", "l", 1, 0 } )
aadd( aArray, { "newsort", "c", 1, 0 } )
aadd( aArray, { "procomm", "c", 20, 0 } )
aadd( aArray, { "stkrpt", "c", 1, 0 } )
aadd( aArray, { "salecons", "l", 1, 0 } )
aadd( aArray, { "centround", "l", 1, 0 } )
aadd( aArray, { "diary", "n", 3, 0 } )
aadd( aArray, { "po1name", "c", 12, 0 } )
aadd( aArray, { "po2name", "c", 12, 0 } )
aadd( aArray, { "po3name", "c", 12, 0 } )
aadd( aArray, { "po4name", "c", 12, 0 } )
aadd( aArray, { "po5name", "c", 12, 0 } )
aadd( aArray, { "matrix", "l", 1, 0 } )
aadd( aArray, { "pickslip", "l", 1, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "superindex", "l", 1, 0 } )
aadd( aArray, { "deptordr", "l", 1, 0 } )
aadd( aArray, { "chkimpr", "l", 1, 0 } )
aadd( aArray, { "chkstat", "l", 1, 0 } )
aadd( aArray, { "chkbind", "l", 1, 0 } )
aadd( aArray, { "chkcate", "l", 1, 0 } )
aadd( aArray, { "prepinv", "n", 1, 0 } )
aadd( aArray, { "san1", "c", 10, 0 } )
aadd( aArray, { "san2", "c", 10, 0 } )
aadd( aArray, { "mdisccash", "n", 6, 2 } )
aadd( aArray, { "mdisccard", "n", 6, 2 } )
dbcreate( sSysPath + "bvars" + NEW_DBF_EXT, aArray )

// superces
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "old_id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "new_id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "old_date", "d", 8, 0 } )
aadd( aArray, { "new_date", "d", 8, 0 } )
dbcreate( sSysPath + "superces" + NEW_DBF_EXT, aArray )

// invline
aArray := {} 
aadd( aArray, { "number", "n", 6, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "ord", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "sell", "n", 10, 2 } )
aadd( aArray, { "price", "n", 12, 4 } )
aadd( aArray, { "tax", "n", 12, 4 } )
aadd( aArray, { "req_no", "c", 25, 0 } )
aadd( aArray, { "skey", "c", 5, 0 } )
aadd( aArray, { "comments", "c", 80, 0 } )
aadd( aArray, { "spec_no", "n", 6, 0 } )
aadd( aArray, { "special", "l", 1, 0 } )
aadd( aArray, { "invoice", "l", 1, 0 } )
aadd( aArray, { "bkls_seq", "n", 3, 0 } )
aadd( aArray, { "serial", "c", 15, 0 } )
dbcreate( sSysPath + "invline" + NEW_DBF_EXT, aArray )

// laybypay
aArray := {} 
aadd( aArray, { "number", "n", 6, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "unit_price", "n", 10, 2 } )
dbcreate( sSysPath + "laybypay" + NEW_DBF_EXT, aArray )

// kit
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
dbcreate( sSysPath + "kit" + NEW_DBF_EXT, aArray )

// serial
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "serial", "c", 15, 0 } )
aadd( aArray, { "date_recv", "d", 8, 0 } )
aadd( aArray, { "date_sold", "d", 8, 0 } )
aadd( aArray, { "invno", "n", 6, 0 } )
aadd( aArray, { "supp_inv", "c", 15, 0 } )
aadd( aArray, { "supp_code", "c", SUPP_CODE_LEN, 0 } )
dbcreate( sSysPath + "serial" + NEW_DBF_EXT, aArray )

// purhist
aArray := {} 
aadd( aArray, { "code", "c", 8, 0 } )
aadd( aArray, { "jan", "n", 10, 2 } )
aadd( aArray, { "feb", "n", 10, 2 } )
aadd( aArray, { "mar", "n", 10, 2 } )
aadd( aArray, { "apr", "n", 10, 2 } )
aadd( aArray, { "may", "n", 10, 2 } )
aadd( aArray, { "jun", "n", 10, 2 } )
aadd( aArray, { "jul", "n", 10, 2 } )
aadd( aArray, { "aug", "n", 10, 2 } )
aadd( aArray, { "sep", "n", 10, 2 } )
aadd( aArray, { "oct", "n", 10, 2 } )
aadd( aArray, { "nov", "n", 10, 2 } )
aadd( aArray, { "dec", "n", 10, 2 } )
dbcreate( sSysPath + "purhist" + NEW_DBF_EXT, aArray )

// recvline
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "indxkey", "c", 20, 0 } )
aadd( aArray, { "ponum", "n", PO_NUM_LEN, 0 } )
aadd( aArray, { "over_write", "l", 1, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "qty_ord", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "qty_inv", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "cost_price", "n", 10, 2 } )
aadd( aArray, { "sell_price", "n", 10, 2 } )
aadd( aArray, { "nett_price", "n", 10, 2 } )
aadd( aArray, { "retail", "n", 10, 2 } )
aadd( aArray, { "st_amt", "n", 10, 2 } )
aadd( aArray, { "barprint", "l", 1, 0 } )
aadd( aArray, { "desc", "c", 5, 0 } )
aadd( aArray, { "comment", "c", 80, 0 } )
aadd( aArray, { "serial", "c", 15, 0 } )
aadd( aArray, { "posted", "l", 1, 0 } )
aadd( aArray, { "operator", "c", OPERATOR_CODE_LEN, 0 } )
aadd( aArray, { "retreason", "c", 2, 0 } )
aadd( aArray, { "tranbranch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "tranqty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "alt_loc", "c", DEPT_CODE_LEN, 0 } )
dbcreate( sSysPath + "recvline" + NEW_DBF_EXT, aArray )

// category
aArray := {} 
aadd( aArray, { "code", "c", 6, 0 } )
aadd( aArray, { "name", "c", 20, 0 } )
dbcreate( sSysPath + "category" + NEW_DBF_EXT, aArray )

// rethead.dbf
aArray:={}
aadd( aArray, { "number", "n", 6, 0} ) 
aadd( aArray, { "supp_code", "c", 5, 0} )
aadd( aArray, { "date", "d", 8, 0} )
aadd( aArray, { "authnumber", "c", 20, 0} )
aadd( aArray, { "con_note", "c", 20, 0} )
aadd( aArray, { "carrier", "c", 20, 0} )
aadd( aArray, { "rettype", "c", 1, 0} )
dbcreate( sSysPath + "rethead" + NEW_DBF_EXT, aArray )

// retline.dbf
aArray:={}
aadd( aArray, { "number", "n", 6, 0} ) 
aadd( aArray, { "id", "c", 12, 0} )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC} )
aadd( aArray, { "cost_price", "n", 10, 2} )
aadd( aArray, { "retail", "n", 10, 2} )
aadd( aArray, { "comment", "c", 80, 0} )
aadd( aArray, { "reference", "c", 20, 0} )
aadd( aArray, { "invdate", "d", 8, 0} )
aadd( aArray, { "ret_code", "c", 2, 0})                       //  Added SWW 15/01/96
dbcreate( sSysPath + "retline" + NEW_DBF_EXT, aArray )

// sales
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "tran_type", "c", 3, 0 } )
aadd( aArray, { "tend_type", "c", 3, 0 } )
aadd( aArray, { "mktg_type", "c", 3, 0 } )
aadd( aArray, { "sale_type", "c", 3, 0 } )
aadd( aArray, { "tran_num", "n", 6, 0 } )
aadd( aArray, { "unit_price", "n", 10, 2 } )
aadd( aArray, { "discount", "n", 10, 2 } )
aadd( aArray, { "cost_price", "n", 10, 2 } )
aadd( aArray, { "sales_tax", "n", 10, 2 } )
aadd( aArray, { "freight", "n", 10, 2 } )
aadd( aArray, { "rounding", "n", 10, 2 } )
aadd( aArray, { "register", "c", 10, 0 } )
aadd( aArray, { "sale_date", "d", 8, 0 } )
aadd( aArray, { "time", "c", 8, 0 } )
aadd( aArray, { "bank", "c", 3, 0 } )
aadd( aArray, { "bnkbranch", "c", 20, 0 } )
aadd( aArray, { "drawer", "c", 20, 0 } )
aadd( aArray, { "name", "c", 20, 0 } )
aadd( aArray, { "invno", "n", 6, 0 } )
aadd( aArray, { "spec_no", "n", 6, 0 } )
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "mop", "c", 3, 0 } )
aadd( aArray, { "operator", "c", OPERATOR_CODE_LEN, 0 } )
aadd( aArray, { "voucher", "c", 10, 0 } )
aadd( aArray, { "locflag", "c", 1, 0 } )
aadd( aArray, { "consign", "l", 1, 0 } )
dbcreate( sSysPath + "sales" + NEW_DBF_EXT, aArray )

// salesrep
aArray := {} 
aadd( aArray, { "code", "c", 2, 0 } )
aadd( aArray, { "name", "c", 30, 0 } )
dbcreate( sSysPath + "salesrep" + NEW_DBF_EXT, aArray )

// poline
aArray := {} 
aadd( aArray, { "number", "n", PO_NUM_LEN, 0 } )
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "cost_price", "n", 10, 2 } )
aadd( aArray, { "back_ord", "l", 1, 0 } )
aadd( aArray, { "date_bord", "d", 8, 0 } )
aadd( aArray, { "skey", "c", 5, 0 } )
aadd( aArray, { "qty_ord", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "ship_date", "d", 8, 0 } )
aadd( aArray, { "ship_qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "ship_stat", "c", 2, 0 } )
aadd( aArray, { "comment", "c", 80, 0 } )
aadd( aArray, { "confirm", "c", 20, 0 } )
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
dbcreate( sSysPath + "poline" + NEW_DBF_EXT, aArray )

// recvhead
aArray := {} 
aadd( aArray, { "supp_code", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "invoice", "c", 15, 0 } )
aadd( aArray, { "inv_total", "n", 10, 2 } )
aadd( aArray, { "inv_calc", "n", 10, 2 } )
aadd( aArray, { "tot_items", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "items_calc", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "dreceived", "d", 8, 0 } )
aadd( aArray, { "listed", "l", 1, 0 } )
aadd( aArray, { "reserved", "l", 1, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "forexamt", "n", 10, 2 } )
aadd( aArray, { "forexrate", "n", 12, 4 } )
aadd( aArray, { "forexcode", "c", 4, 0 } )
aadd( aArray, { "x_charges", "n", 10, 2 } )
aadd( aArray, { "freight", "n", 10, 2 } )
aadd( aArray, { "consign", "l", 1, 0 } )
aadd( aArray, { "operator", "c", OPERATOR_CODE_LEN, 0 } )
dbcreate( sSysPath + "recvhead" + NEW_DBF_EXT, aArray )

// companys
aArray := {} 
aadd( aArray, { "code", "c", 2, 0 } )
aadd( aArray, { "name", "c", 30, 0 } )
dbcreate( sSysPath + "companys" + NEW_DBF_EXT, aArray )

// binding
aArray := {} 
aadd( aArray, { "code", "c", 2, 0 } )
aadd( aArray, { "name", "c", 25, 0 } )
dbcreate( sSysPath + "binding" + NEW_DBF_EXT, aArray )

// system
aArray := {} 
aadd( aArray, { "details", "c", 80, 0 } )
dbcreate( sSysPath + "system" + NEW_DBF_EXT, aArray )

// brand
aArray := {} 
aadd( aArray, { "code", "c", BRAND_CODE_LEN, 0 } )
aadd( aArray, { "name", "c", 25, 0 } )
aadd( aArray, { "supp_code", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "supp_code2", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "disc_a", "n", 5, 1 } )
aadd( aArray, { "disc_b", "n", 5, 1 } )
aadd( aArray, { "disc_c", "n", 5, 1 } )
aadd( aArray, { "disc_d", "n", 5, 1 } )
aadd( aArray, { "disc_e", "n", 5, 1 } )
aadd( aArray, { "disc_f", "n", 5, 1 } )
aadd( aArray, { "disc_g", "n", 5, 1 } )
aadd( aArray, { "disc_h", "n", 5, 1 } )
aadd( aArray, { "disc_i", "n", 5, 1 } )
aadd( aArray, { "disc_j", "n", 5, 1 } )
aadd( aArray, { "disc_k", "n", 5, 1 } )
aadd( aArray, { "disc_l", "n", 5, 1 } )
aadd( aArray, { "disc_m", "n", 5, 1 } )
aadd( aArray, { "disc_n", "n", 5, 1 } )
aadd( aArray, { "disc_o", "n", 5, 1 } )
aadd( aArray, { "disc_p", "n", 5, 1 } )
aadd( aArray, { "disc_q", "n", 5, 1 } )
aadd( aArray, { "disc_r", "n", 5, 1 } )
aadd( aArray, { "disc_s", "n", 5, 1 } )
aadd( aArray, { "disc_t", "n", 5, 1 } )
aadd( aArray, { "disc_u", "n", 5, 1 } )
aadd( aArray, { "disc_v", "n", 5, 1 } )
aadd( aArray, { "disc_w", "n", 5, 1 } )
aadd( aArray, { "disc_x", "n", 5, 1 } )
aadd( aArray, { "disc_y", "n", 5, 1 } )
aadd( aArray, { "disc_z", "n", 5, 1 } )
aadd( aArray, { "extra_key", "c", 10, 0 } )
dbcreate( sSysPath + "brand" + NEW_DBF_EXT, aArray )

// titlchg
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "oldid", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "oldprice", "n", 10, 2 } )
aadd( aArray, { "newprice", "n", 10, 2 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "flag", "c", 1, 0 } )
aadd( aArray, { "processed", "l", 1, 0 } )
dbcreate( sSysPath + "titlchg" + NEW_DBF_EXT, aArray )

// deptmove
aArray := {} 
aadd( aArray, { "code", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "type", "c", 3, 0 } )
aadd( aArray, { "jan", "n", 10, 2 } )
aadd( aArray, { "feb", "n", 10, 2 } )
aadd( aArray, { "mar", "n", 10, 2 } )
aadd( aArray, { "apr", "n", 10, 2 } )
aadd( aArray, { "may", "n", 10, 2 } )
aadd( aArray, { "jun", "n", 10, 2 } )
aadd( aArray, { "jul", "n", 10, 2 } )
aadd( aArray, { "aug", "n", 10, 2 } )
aadd( aArray, { "sep", "n", 10, 2 } )
aadd( aArray, { "oct", "n", 10, 2 } )
aadd( aArray, { "nov", "n", 10, 2 } )
aadd( aArray, { "dec", "n", 10, 2 } )
dbcreate( sSysPath + "deptmove" + NEW_DBF_EXT, aArray )

// backlog
aArray := {} 
aadd( aArray, { "disk_set", "c", 2, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "initials", "c", 2, 0 } )
aadd( aArray, { "time", "c", 8, 0 } )
aadd( aArray, { "cumulative", "n", 2, 0 } )
dbcreate( sSysPath + "backlog" + NEW_DBF_EXT, aArray )

// open2buy
aArray := {} 
aadd( aArray, { "open_janb", "n", 10, 2 } )
aadd( aArray, { "open_febb", "n", 10, 2 } )
aadd( aArray, { "open_marb", "n", 10, 2 } )
aadd( aArray, { "open_aprb", "n", 10, 2 } )
aadd( aArray, { "open_mayb", "n", 10, 2 } )
aadd( aArray, { "open_junb", "n", 10, 2 } )
aadd( aArray, { "open_julb", "n", 10, 2 } )
aadd( aArray, { "open_augb", "n", 10, 2 } )
aadd( aArray, { "open_sepb", "n", 10, 2 } )
aadd( aArray, { "open_octb", "n", 10, 2 } )
aadd( aArray, { "open_novb", "n", 10, 2 } )
aadd( aArray, { "open_decb", "n", 10, 2 } )
aadd( aArray, { "open_jan1", "n", 10, 2 } )
aadd( aArray, { "open_jan2", "n", 10, 2 } )
aadd( aArray, { "open_jan3", "n", 10, 2 } )
aadd( aArray, { "open_jan4", "n", 10, 2 } )
aadd( aArray, { "open_jan5", "n", 10, 2 } )
aadd( aArray, { "open_feb1", "n", 10, 2 } )
aadd( aArray, { "open_feb2", "n", 10, 2 } )
aadd( aArray, { "open_feb3", "n", 10, 2 } )
aadd( aArray, { "open_feb4", "n", 10, 2 } )
aadd( aArray, { "open_feb5", "n", 10, 2 } )
aadd( aArray, { "open_mar1", "n", 10, 2 } )
aadd( aArray, { "open_mar2", "n", 10, 2 } )
aadd( aArray, { "open_mar3", "n", 10, 2 } )
aadd( aArray, { "open_mar4", "n", 10, 2 } )
aadd( aArray, { "open_mar5", "n", 10, 2 } )
aadd( aArray, { "open_apr1", "n", 10, 2 } )
aadd( aArray, { "open_apr2", "n", 10, 2 } )
aadd( aArray, { "open_apr3", "n", 10, 2 } )
aadd( aArray, { "open_apr4", "n", 10, 2 } )
aadd( aArray, { "open_apr5", "n", 10, 2 } )
aadd( aArray, { "open_may1", "n", 10, 2 } )
aadd( aArray, { "open_may2", "n", 10, 2 } )
aadd( aArray, { "open_may3", "n", 10, 2 } )
aadd( aArray, { "open_may4", "n", 10, 2 } )
aadd( aArray, { "open_may5", "n", 10, 2 } )
aadd( aArray, { "open_jun1", "n", 10, 2 } )
aadd( aArray, { "open_jun2", "n", 10, 2 } )
aadd( aArray, { "open_jun3", "n", 10, 2 } )
aadd( aArray, { "open_jun4", "n", 10, 2 } )
aadd( aArray, { "open_jun5", "n", 10, 2 } )
aadd( aArray, { "open_jul1", "n", 10, 2 } )
aadd( aArray, { "open_jul2", "n", 10, 2 } )
aadd( aArray, { "open_jul3", "n", 10, 2 } )
aadd( aArray, { "open_jul4", "n", 10, 2 } )
aadd( aArray, { "open_jul5", "n", 10, 2 } )
aadd( aArray, { "open_aug1", "n", 10, 2 } )
aadd( aArray, { "open_aug2", "n", 10, 2 } )
aadd( aArray, { "open_aug3", "n", 10, 2 } )
aadd( aArray, { "open_aug4", "n", 10, 2 } )
aadd( aArray, { "open_aug5", "n", 10, 2 } )
aadd( aArray, { "open_sep1", "n", 10, 2 } )
aadd( aArray, { "open_sep2", "n", 10, 2 } )
aadd( aArray, { "open_sep3", "n", 10, 2 } )
aadd( aArray, { "open_sep4", "n", 10, 2 } )
aadd( aArray, { "open_sep5", "n", 10, 2 } )
aadd( aArray, { "open_oct1", "n", 10, 2 } )
aadd( aArray, { "open_oct2", "n", 10, 2 } )
aadd( aArray, { "open_oct3", "n", 10, 2 } )
aadd( aArray, { "open_oct4", "n", 10, 2 } )
aadd( aArray, { "open_oct5", "n", 10, 2 } )
aadd( aArray, { "open_nov1", "n", 10, 2 } )
aadd( aArray, { "open_nov2", "n", 10, 2 } )
aadd( aArray, { "open_nov3", "n", 10, 2 } )
aadd( aArray, { "open_nov4", "n", 10, 2 } )
aadd( aArray, { "open_nov5", "n", 10, 2 } )
aadd( aArray, { "open_dec1", "n", 10, 2 } )
aadd( aArray, { "open_dec2", "n", 10, 2 } )
aadd( aArray, { "open_dec3", "n", 10, 2 } )
aadd( aArray, { "open_dec4", "n", 10, 2 } )
aadd( aArray, { "open_dec5", "n", 10, 2 } )
dbcreate( sSysPath + "open2buy" + NEW_DBF_EXT, aArray )

// status
aArray := {} 
aadd( aArray, { "code", "c", 3, 0 } )
aadd( aArray, { "name", "c", 25, 0 } )
dbcreate( sSysPath + "status" + NEW_DBF_EXT, aArray )

// poinstru
aArray := {} 
aadd( aArray, { "code", "c", 6, 0 } )
aadd( aArray, { "name", "c", 240, 0 } )
dbcreate( sSysPath + "poinstru" + NEW_DBF_EXT, aArray )

// abs_save
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
// aadd( aArray, { "memo", "m", 10, 0 } )
dbcreate( sSysPath + "abs_save" + NEW_DBF_EXT, aArray )

// nodes
aArray := {} 
aadd( aArray, { "node", "c", 20, 0 } )
aadd( aArray, { "reg", "c", 10, 0 } )
aadd( aArray, { "printer", "c", 4, 0 } )
aadd( aArray, { "report", "c", 30, 0 } )
aadd( aArray, { "barcode", "c", 30, 0 } )
aadd( aArray, { "invoice", "c", 30, 0 } )
aadd( aArray, { "docket", "c", 30, 0 } )
aadd( aArray, { "f1", "c", 13, 0 } )
aadd( aArray, { "f1n", "c", 9, 0 } )
aadd( aArray, { "f1margin", "n", 5, 1 } )
aadd( aArray, { "f2", "c", 13, 0 } )
aadd( aArray, { "f2n", "c", 9, 0 } )
aadd( aArray, { "f2margin", "n", 5, 1 } )
aadd( aArray, { "f3", "c", 13, 0 } )
aadd( aArray, { "f3n", "c", 9, 0 } )
aadd( aArray, { "f3margin", "n", 5, 1 } )
aadd( aArray, { "f4", "c", 13, 0 } )
aadd( aArray, { "f4n", "c", 9, 0 } )
aadd( aArray, { "f4margin", "n", 5, 1 } )
aadd( aArray, { "f5", "c", 13, 0 } )
aadd( aArray, { "f5n", "c", 9, 0 } )
aadd( aArray, { "f5margin", "n", 5, 1 } )
aadd( aArray, { "f6", "c", 13, 0 } )
aadd( aArray, { "f6n", "c", 9, 0 } )
aadd( aArray, { "f6margin", "n", 5, 1 } )
aadd( aArray, { "f7", "c", 13, 0 } )
aadd( aArray, { "f7n", "c", 9, 0 } )
aadd( aArray, { "f7margin", "n", 5, 1 } )
aadd( aArray, { "f8", "c", 13, 0 } )
aadd( aArray, { "f8n", "c", 9, 0 } )
aadd( aArray, { "f8margin", "n", 5, 1 } )
aadd( aArray, { "f9", "c", 13, 0 } )
aadd( aArray, { "f9n", "c", 9, 0 } )
aadd( aArray, { "f9margin", "n", 5, 1 } )
aadd( aArray, { "f10", "c", 13, 0 } )
aadd( aArray, { "f10n", "c", 9, 0 } )
aadd( aArray, { "f10margin", "n", 5, 1 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "cust_no", "n", 5, 0 } )
aadd( aArray, { "cdtype", "c", 1, 0 } )
aadd( aArray, { "auto_open", "l", 1, 0 } )
aadd( aArray, { "cdport", "n", 1, 0 } )
aadd( aArray, { "docket", "l", 1, 0 } )
aadd( aArray, { "colattr", "n", 2, 0 } )
aadd( aArray, { "backgr", "l", 1, 0 } )
aadd( aArray, { "shadow", "l", 1, 0 } )
aadd( aArray, { "good", "n", 3, 0 } )
aadd( aArray, { "bad", "n", 3, 0 } )
aadd( aArray, { "memory", "n", 3, 0 } )
aadd( aArray, { "speak", "l", 1, 0 } )
aadd( aArray, { "speed", "n", 3, 0 } )
aadd( aArray, { "space", "n", 3, 0 } )
aadd( aArray, { "res", "n", 3, 0 } )
aadd( aArray, { "maxrows", "n", 2, 0 } )
aadd( aArray, { "c1", "c", 20, 0 } )
aadd( aArray, { "c2", "c", 20, 0 } )
aadd( aArray, { "c3", "c", 20, 0 } )
aadd( aArray, { "c4", "c", 20, 0 } )
aadd( aArray, { "c5", "c", 20, 0 } )
aadd( aArray, { "c6", "c", 20, 0 } )
aadd( aArray, { "c7", "c", 20, 0 } )
aadd( aArray, { "c8", "c", 20, 0 } )
aadd( aArray, { "c9", "c", 20, 0 } )
aadd( aArray, { "color", "l", 1, 0 } )
aadd( aArray, { "poz", "l", 1, 0 } )
aadd( aArray, { "onp", "l", 1, 0 } )
aadd( aArray, { "modem", "l", 1, 0 } )
aadd( aArray, { "mport", "n", 1, 0 } )
aadd( aArray, { "mbaud", "n", 6, 0 } )
aadd( aArray, { "minit", "c", 20, 0 } )
dbcreate( sSysPath + "nodes" + NEW_DBF_EXT, aArray )

// cretrans
aArray := {} 
aadd( aArray, { "code", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "ttype", "n", 1, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "duedate", "d", 8, 0 } )
aadd( aArray, { "tnum", "c", 10, 0 } )
aadd( aArray, { "amt", "n", 10, 2 } )
aadd( aArray, { "amtpaid", "n", 10, 2 } )
aadd( aArray, { "variance", "n", 10, 2 } )
aadd( aArray, { "tage", "n", 1, 0 } )
aadd( aArray, { "pay", "l", 1, 0 } )
aadd( aArray, { "pay_amt", "n", 10, 2 } )
aadd( aArray, { "discount", "n", 2, 0 } )
aadd( aArray, { "dis_amt", "n", 7, 2 } )
aadd( aArray, { "desc", "c", 20, 0 } )
aadd( aArray, { "printed", "l", 1, 0 } )
dbcreate( sSysPath + "cretrans" + NEW_DBF_EXT, aArray )

// transfer
aArray := {} 
aadd( aArray, { "number", "n", 6, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "ponum", "n", PO_NUM_LEN, 0 } )
aadd( aArray, { "retail", "n", 10, 2 } )
aadd( aArray, { "cost_price", "n", 10, 2 } )
aadd( aArray, { "sell_price", "n", 10, 2 } )
aadd( aArray, { "from", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "to", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "processed", "l", 1, 0 } )
dbcreate( sSysPath + "transfer" + NEW_DBF_EXT, aArray )

// pohead
aArray := {} 
aadd( aArray, { "number", "n", PO_NUM_LEN, 0 } )
aadd( aArray, { "supp_code", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "date_ord", "d", 8, 0 } )
aadd( aArray, { "authreturn", "l", 1, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "prefix", "c", 1, 0 } )
aadd( aArray, { "teleorder", "l", 1, 0 } )
aadd( aArray, { "confirmed", "l", 1, 0 } )
aadd( aArray, { "approved", "l", 1, 0 } )
aadd( aArray, { "reserved", "l", 1, 0 } )
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "instruct", "c", 6, 0 } )
dbcreate( sSysPath + "pohead" + NEW_DBF_EXT, aArray )

// approval
aArray := {} 
aadd( aArray, { "number", "n", 6, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", 3, 0 } )
aadd( aArray, { "received", "n", 3, 0 } )
aadd( aArray, { "delivered", "n", 3, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "price", "n", 10, 2 } )
aadd( aArray, { "to_date", "n", 10, 2 } )
aadd( aArray, { "comments", "c", 20, 0 } )
aadd( aArray, { "desc", "c", 10, 0 } )
dbcreate( sSysPath + "approval" + NEW_DBF_EXT, aArray )

// arhist
aArray := {} 
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "bill_key", "c", 10, 0 } )
aadd( aArray, { "ttype", "n", 1, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "tnum", "c", 6, 0 } )
aadd( aArray, { "amt", "n", 10, 2 } )
aadd( aArray, { "freight", "n", 10, 2 } )
aadd( aArray, { "salestax", "n", 10, 2 } )
aadd( aArray, { "sundries", "n", 10, 2 } )
aadd( aArray, { "amtpaid", "n", 10, 2 } )
aadd( aArray, { "tage", "n", 1, 0 } )
aadd( aArray, { "salesman", "c", 2, 0 } )
aadd( aArray, { "comment", "c", 20, 0 } )
dbcreate( sSysPath + "arhist" + NEW_DBF_EXT, aArray )

// custcate
aArray := {} 
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "code", "c", 6, 0 } )
aadd( aArray, { "qty", "n", 3, 0 } )
dbcreate( sSysPath + "custcate" + NEW_DBF_EXT, aArray )

// customer
aArray := {} 
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "bill_key", "c", 10, 0 } )
aadd( aArray, { "extra_key", "c", 10, 0 } )
aadd( aArray, { "debtor", "l", 1, 0 } )
aadd( aArray, { "name", "c", 35, 0 } )
aadd( aArray, { "contact", "c", 35, 0 } )
aadd( aArray, { "add1", "c", 35, 0 } )
aadd( aArray, { "add2", "c", 35, 0 } )
aadd( aArray, { "add3", "c", 35, 0 } )
aadd( aArray, { "pcode", "c", 4, 0 } )
aadd( aArray, { "dadd1", "c", 35, 0 } )
aadd( aArray, { "dadd2", "c", 35, 0 } )
aadd( aArray, { "dadd3", "c", 35, 0 } )
aadd( aArray, { "dpcode", "c", 4, 0 } )
aadd( aArray, { "phone1", "c", PHONE_NUM_LEN, 0 } )
aadd( aArray, { "phone2", "c", PHONE_NUM_LEN, 0 } )
aadd( aArray, { "fax", "c", PHONE_NUM_LEN, 0 } )
aadd( aArray, { "email", "c", 40, 0 } )
aadd( aArray, { "c_limit", "n", 9, 2 } )
aadd( aArray, { "stop", "l", 1, 0 } )
aadd( aArray, { "san", "c", 12, 0 } )
aadd( aArray, { "credit_car", "c", 26, 0 } )
aadd( aArray, { "salestaxno", "c", 10, 0 } )
aadd( aArray, { "salesman", "c", 2, 0 } )
aadd( aArray, { "comments", "c", 35, 0 } )
aadd( aArray, { "amtcur", "n", 10, 2 } )
aadd( aArray, { "amt30", "n", 10, 2 } )
aadd( aArray, { "amt60", "n", 10, 2 } )
aadd( aArray, { "amt90", "n", 10, 2 } )
aadd( aArray, { "laststat", "n", 10, 2 } )
aadd( aArray, { "amt_lp", "n", 10, 2 } )
aadd( aArray, { "date_lp", "d", 8, 0 } )
aadd( aArray, { "lastbuy", "n", 1, 0 } )
aadd( aArray, { "ytdamt", "n", 10, 2 } )
aadd( aArray, { "pytdamt", "n", 10, 2 } )
aadd( aArray, { "op_it", "l", 1, 0 } )
aadd( aArray, { "spec_let", "l", 1, 0 } )
aadd( aArray, { "bank", "c", 15, 0 } )
aadd( aArray, { "branch", "c", 15, 0 } )
aadd( aArray, { "sort_ord", "c", 1, 0 } )
aadd( aArray, { "area", "c", 4, 0 } )
aadd( aArray, { "type", "c", 1, 0 } )
aadd( aArray, { "disc_type", "c", 1, 0 } )
aadd( aArray, { "exempt", "l", 1, 0 } )
aadd( aArray, { "entered", "d", 8, 0 } )
aadd( aArray, { "company", "c", 2, 0 } )
aadd( aArray, { "oldkey", "c", CUST_KEY_LEN, 0 } )
// aadd( aArray, { "memo", "m", 10, 0 } )
dbcreate( sSysPath + "customer" + NEW_DBF_EXT, aArray )

// debbank
aArray := {} 
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "cash", "n", 10, 2 } )
aadd( aArray, { "cheque", "n", 10, 2 } )
aadd( aArray, { "drawer", "c", 30, 0 } )
aadd( aArray, { "bank", "c", 20, 0 } )
aadd( aArray, { "bnkbranch", "c", 20, 0 } )
aadd( aArray, { "tnum", "c", 6, 0 } )
dbcreate( sSysPath + "debbank" + NEW_DBF_EXT, aArray )

// debtrans
aArray := {} 
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "bill_key", "c", 10, 0 } )
aadd( aArray, { "ttype", "n", 1, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "tnum", "c", 6, 0 } )
aadd( aArray, { "amt", "n", 10, 2 } )
aadd( aArray, { "freight", "n", 10, 2 } )
aadd( aArray, { "salestax", "n", 10, 2 } )
aadd( aArray, { "sundries", "n", 10, 2 } )
aadd( aArray, { "amtpaid", "n", 10, 2 } )
aadd( aArray, { "tage", "n", 1, 0 } )
aadd( aArray, { "salesman", "c", 2, 0 } )
aadd( aArray, { "comment", "c", 20, 0 } )
aadd( aArray, { "operator", "c", OPERATOR_CODE_LEN, 0 } )
dbcreate( sSysPath + "debtrans" + NEW_DBF_EXT, aArray )

// hold
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "type", "c", 1, 0 } )
aadd( aArray, { "number", "n", 6, 0 } )
dbcreate( sSysPath + "hold" + NEW_DBF_EXT, aArray )

// invhead
aArray := {} 
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "number", "n", 6, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "order_no", "c", 15, 0 } )
aadd( aArray, { "tot_disc", "n", 10, 2 } )
aadd( aArray, { "printed", "l", 1, 0 } )
aadd( aArray, { "posted", "l", 1, 0 } )
aadd( aArray, { "inv", "l", 1, 0 } )
aadd( aArray, { "inst1", "c", 30, 0 } )
aadd( aArray, { "inst2", "c", 30, 0 } )
aadd( aArray, { "freight", "n", 10, 2 } )
aadd( aArray, { "message1", "c", 40, 0 } )
aadd( aArray, { "message2", "c", 40, 0 } )
aadd( aArray, { "message3", "c", 40, 0 } )
aadd( aArray, { "stud_tag", "n", 3, 0 } )
aadd( aArray, { "bkls_code", "c", 10, 0 } )
aadd( aArray, { "operator", "c", OPERATOR_CODE_LEN, 0 } )
aadd( aArray, { "carrier", "c", 1, 0 } )
aadd( aArray, { "source", "c", 1, 0 } )
aadd( aArray, { "taxcert", "c", 1, 0 } )
aadd( aArray, { "reporder", "c", 10, 0 } )
aadd( aArray, { "proforma", "l", 1, 0 } )
dbcreate( sSysPath + "invhead" + NEW_DBF_EXT, aArray )

// layby
aArray := {} 
aadd( aArray, { "number", "n", 6, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", 3, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "price", "n", 10, 2 } )
aadd( aArray, { "to_date", "n", 8, 2 } )
aadd( aArray, { "pay_date", "d", 8, 0 } )
dbcreate( sSysPath + "layby" + NEW_DBF_EXT, aArray )

// pickslip
aArray := {} 
aadd( aArray, { "number", "n", 6, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "ord", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "sell", "n", 10, 2 } )
aadd( aArray, { "price", "n", 12, 4 } )
aadd( aArray, { "tax", "n", 12, 4 } )
aadd( aArray, { "req_no", "c", 25, 0 } )
aadd( aArray, { "skey", "c", 5, 0 } )
aadd( aArray, { "comments", "c", 80, 0 } )
aadd( aArray, { "spec_no", "n", 6, 0 } )
aadd( aArray, { "invoiced", "l", 1, 0 } )
aadd( aArray, { "special", "l", 1, 0 } )
aadd( aArray, { "invoice", "l", 1, 0 } )
aadd( aArray, { "freight", "n", 10, 2 } )
aadd( aArray, { "tot_disc", "n", 6, 2 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "operator", "c", OPERATOR_CODE_LEN, 0 } )
aadd( aArray, { "message1", "c", 40, 0 } )
aadd( aArray, { "message2", "c", 40, 0 } )
aadd( aArray, { "message3", "c", 40, 0 } )
aadd( aArray, { "salesman", "c", 2, 0 } )
dbcreate( sSysPath + "pickslip" + NEW_DBF_EXT, aArray )

// salehist
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "unit_price", "n", 10, 2 } )
aadd( aArray, { "cost_price", "n", 10, 2 } )
aadd( aArray, { "discount", "n", 12, 4 } )
aadd( aArray, { "sales_tax", "n", 10, 2 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "area", "c", 5, 0 } )
aadd( aArray, { "type", "c", 3, 0 } )
aadd( aArray, { "period", "n", 2, 0 } )
aadd( aArray, { "invno", "n", 6, 0 } )
aadd( aArray, { "mktg_type", "c", 3, 0 } )
aadd( aArray, { "sale_type", "c", 3, 0 } )
aadd( aArray, { "locflag", "c", 1, 0 } )
aadd( aArray, { "consign", "l", 1, 0 } )
dbcreate( sSysPath + "salehist" + NEW_DBF_EXT, aArray )

// special
aArray := {} 
aadd( aArray, { "number", "n", 6, 0 } )
aadd( aArray, { "branch", "c", BRANCH_CODE_LEN, 0 } )
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "date", "d", 8, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "received", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "delivered", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "alloc", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "deposit", "n", 8, 2 } )
aadd( aArray, { "supp_code", "c", SUPP_CODE_LEN, 0 } )
aadd( aArray, { "comments", "c", 40, 0 } )
aadd( aArray, { "notfound", "c", 1, 0 } )
aadd( aArray, { "desc", "c", 25, 0 } )
aadd( aArray, { "alt_desc", "c", 20, 0 } )
aadd( aArray, { "ordno", "c", 25, 0 } )
aadd( aArray, { "standing", "l", 1, 0 } )
aadd( aArray, { "new_id", "l", 1, 0 } )
aadd( aArray, { "acqno", "c", 10, 0 } )
aadd( aArray, { "date_del", "d", 8, 0 } )
aadd( aArray, { "specmode", "n", 1, 0 } )
dbcreate( sSysPath + "special" + NEW_DBF_EXT, aArray )


//stocklocs
aArray := {}
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "l0", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l0dept", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "l1", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l1dept", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "l2", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l2dept", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "l3", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l3dept", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "l4", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l4dept", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "l5", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l5dept", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "l6", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l6dept", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "l7", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l7dept", "c", DEPT_CODE_LEN, 0 } )
aadd( aArray, { "l0s", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l1s", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l2s", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l3s", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l4s", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l5s", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l6s", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "l7s", "n", QTY_LEN, QTY_DEC } )
dbcreate( sSysPath + "stoclocs" + NEW_DBF_EXT, aArray )

// Quote - Started off as a Header / Line items file but was easier to rehash the approval system
// and this is not going to be such a big file that normalisation is beneficial
aArray := {}
aadd( aArray, { "number", "n", INV_NUM_LEN, 0 } )
aadd( aArray, { "key", "c", CUST_KEY_LEN, 0 } )
aadd( aArray, { "Date", "d", 8, 0 } )
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "qty", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "price", "n", 10, 2 } )
aadd( aArray, { "comment", "c", 40, 0 } )
aadd( aArray, { "valid", "d", 8, 0 } )      // Date of validity
aadd( aArray, { "salesrep", "c", 2, 0 } )
dbcreate( sSysPath + "quote" + NEW_DBF_EXT, aArray )

// ytdsales
aArray := {} 
aadd( aArray, { "id", "c", ID_CODE_LEN, 0 } )
aadd( aArray, { "jan", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "feb", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "mar", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "apr", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "may", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "jun", "n", 4, 0 } )
aadd( aArray, { "jul", "n", 4, 0 } )
aadd( aArray, { "aug", "n", 4, 0 } )
aadd( aArray, { "sep", "n", 4, 0 } )
aadd( aArray, { "oct", "n", 4, 0 } )
aadd( aArray, { "nov", "n", 4, 0 } )
aadd( aArray, { "dec", "n", 4, 0 } )
aadd( aArray, { "per1", "n", 4, 0 } )
aadd( aArray, { "per2", "n", 4, 0 } )
aadd( aArray, { "per3", "n", 4, 0 } )
aadd( aArray, { "per4", "n", 4, 0 } )
aadd( aArray, { "per5", "n", 4, 0 } )
aadd( aArray, { "per6", "n", 4, 0 } )
aadd( aArray, { "per7", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "per8", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "per9", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "per10", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "per11", "n", QTY_LEN, QTY_DEC } )
aadd( aArray, { "per12", "n", QTY_LEN, QTY_DEC } )
dbcreate( sSysPath + "ytdsales" + NEW_DBF_EXT, aArray )

return nil
