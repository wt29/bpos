/*  
        
        Utilpack.prg 

      Last change:  TG   26 Jan 2012    7:29 pm
*/

#include "bpos.ch"

external descend

Procedure U_Pack

local dbfile, mgo:=TRUE, mscr, x, mallfiles:=FALSE,oksf9,mval,mfile,mchoice
local oldscr:=Box_Save(0,0,24,79),mdbp,dbxfile,getlist:={}, aArray :={}
local mrecs                       // Number of Records in selected file
local must_index := FALSE

Heading('Rebuild Indexes & Pack Files')

dbfile := Directory( Oddvars( SYSPATH ) + '*.dbf' )
aadd( dbfile, { 'ARCHIVE.DBF' } )            // Add an Extra for ARCHIVE.DBF

aadd( aArray, { 'Utility', 'Return to Utility Menu' } )
aadd( aArray, { 'Pack', 'Perform Pack On System Files' } )
aadd( aArray, { 'Reindex', 'Reindex System Files' } )
mchoice := menugen( aArray, 06, 50, 'Pack' )

do case
case mchoice < 2 
 return

case mchoice = 3
 must_index := TRUE

endcase

mscr:=Box_Save( 14, 16, 16, 40 )

@ 15,18 say if( must_index, 'Reindex', 'Pack' ) + ' all files?' get mallfiles pict 'Y'

read
if lastkey() != K_ESC
 Box_Restore( mscr )
 if mallfiles
  if Isready( 12, 10, "Ok to " + if( must_index, 'Reindex', 'Pack' ) )
   Go_pack( YES , '', must_index )
   SysAudit( 'PackAll' )

  endif
  setkey( K_SH_F9 , oksf9 )

 else
  while !mallfiles
   Box_Save( 04, 66, 23, 75 )
   @ 4,68 say 'Files'
   dbxfile := {}
   for x := 1 to len( dbfile )
    aadd( dbxfile, substr( dbfile[ x,1 ], 1, at( '.', dbfile[x,1] ) -1 ) )

   next
   asort( dbxfile )
   mval := 1
   while mval != 0
    mval := ascan( dbxfile , '$' )
    if mval != 0
     adel( dbxfile , mval )

    endif
   enddo
   mdbp := achoice( 05, 67, 22, 74, dbxfile )      // Database Pointer
   if mdbp = 0                                     // Escape was Pressed
    mallfiles := TRUE
    exit

   else                                            // file was Selected
    mfile := dbxfile[ mdbp ]

   endif

   if mfile = "ARCHIVE"
    mfile := Oddvars( SYSPATH ) + "ARCHIVE\ARCHIVE"

   endif

   if Netuse( mfile, EXCLUSIVE, 10, NOALIAS, NEW )
    mrecs := Ns( reccount() )
    dbcloseall()
    if Isready( 11, 02 , "Ready to " + if( must_index,'index','pack') + " the " + mrecs + " records in the " ;
      + lower(trim(mfile)) + " file ?" )
     Go_pack( NO, mfile )
     SysAudit( "Pack" + trim( mfile ) )

    endif

   endif
   Box_Restore( oldscr )

  enddo

 endif

endif
return

*

function go_pack ( mallfiles, mfile, must_index )

local start_time:=seconds(), totrecs, mcount

local elapsed, ts, mindxext:=ordbagext(), hours

local msuccess := FALSE   // Did a successful pack occur?

default must_index to FALSE

cls
Heading( if( must_index, 'Reindex', 'File Pack' ) + ' in Progress - Stand by' )

@ 1,0 say ''

if mallfiles .or. mfile = "MASTER"
 if must_index
  Kill( Oddvars( SYSPATH ) + 'master' + mindxext )
 endif
 if Netuse( 'master', EXCLUSIVE, 1, NOALIAS, FALSE )
  mcount := Filedisp( 'Master', must_index )
  if !file( Oddvars( SYSPATH ) + 'master' + mindxext )
   indx( "padr( id, 12 )", 'id' )
   indx( "upper( left( desc, " + Ns( SEARCH_KEY_LEN ) + ") )", 'desc' )
   indx( "upper( left( alt_desc, " + Ns( SEARCH_KEY_LEN ) + ") ) + left( desc ," + Ns( SEARCH_KEY_LEN ) + " )", 'alt_desc' )
   indx( "department+upper( left( desc, " + Ns( SEARCH_KEY_LEN ) + " ) )", 'department' )
   indx( "supp_code+upper( left( desc, "+ Ns( SEARCH_KEY_LEN )+" ) )", 'supplier' )
   indx( "upper( left( catalog, " + Ns( SEARCH_KEY_LEN ) + ") )", 'catalog' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif
  
if mallfiles .or. mfile = "SUPPLIER"
 if must_index
  Kill( Oddvars( SYSPATH ) + 'supplier' + mindxext )
 endif
 if Netuse( "supplier",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := Filedisp('Supplier', must_index )
  if !file( Oddvars( SYSPATH ) + 'supplier' + mindxext ) 
   indx( "code",  'code' )
   indx( 'teleorder', 'teleorder' )
   indx( 'extra_key', 'extra_key' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "DRAFT_PO"
 if must_index
  Kill( Oddvars( SYSPATH ) + 'draft_po' + mindxext )
 endif
 if Netuse( "draft_po",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp('Draft Purchase Orders', must_index )
  if !file( Oddvars( SYSPATH ) + 'draft_po' + mindxext )
   indx( "supp_code + upper( skey )", "supplier" )
   indx( "id", "id" )
   indx( "supp_code + id", "suppid" )
   indx( "department + upper( skey )", "department" )
   indx( "source + supp_code", "source" )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "YTDSALES"
 if must_index
  Kill( Oddvars( SYSPATH ) + "ytdsales" + mindxext )
 endif
 if Netuse( "ytdsales", EXCLUSIVE, 1, NOALIAS, FALSE )
  mcount := FileDisp( 'Year to Date Sales', must_index )
  if !file( Oddvars( SYSPATH ) + "ytdsales" + mindxext ) 
   indx( "id", 'id' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "STKHIST"
 if must_index
  Kill( Oddvars( SYSPATH ) + "stkhist" + mindxext )
 endif
 if Netuse( "stkhist",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp('Stock History', must_index )
  if !file( Oddvars( SYSPATH ) + "stkhist" + mindxext )
   indx( "id + descend( dtos( date ) )", 'id' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "SALEHIST"
 if must_index
  Kill( Oddvars( SYSPATH ) + "salehist" + mindxext )
 endif
 if Netuse( "salehist",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Sales History', must_index )
  if !file( Oddvars( SYSPATH ) + "salehist" + mindxext )
   indx( "id + descend( dtos(date) )", 'id' )
   indx( "key", 'key' )  
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile == "SALES"
 if must_index
  Kill( Oddvars( SYSPATH ) + 'sales' + mindxext )
 endif
 if Netuse( "sales",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Sales', must_index )
  pack
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "POHEAD"
 if must_index
  Kill( Oddvars( SYSPATH ) + "pohead" + mindxext )
 endif
 if Netuse( "pohead",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp('Purchase Order Header', must_index )
  if !file( Oddvars( SYSPATH ) + "pohead" + mindxext ) 
   indx( "number", 'number' )
   indx( "supp_code", 'supplier' )

  else
   pack

  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "POLINE"
 if must_index
  Kill( Oddvars( SYSPATH ) + "poline" + mindxext )
 endif
 if Netuse( "poline",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp('Purchase Order Line Items', must_index )
  if !file( Oddvars( SYSPATH ) + "poline" + mindxext ) 
   indx( "number", 'number' )
   indx( "id", 'id' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif


if mallfiles .or. mfile = "RECVHEAD"
 if must_index
  Kill( Oddvars( SYSPATH ) + 'recvhead' + mindxext )
 endif
 if Netuse( "RECVHEAD", EXCLUSIVE, 1, NOALIAS, FALSE )
  mcount := FileDisp('Receiving Header', must_index )
  if !file( Oddvars( SYSPATH ) + 'recvhead' + mindxext )
   indx( 'supp_code + invoice', 'supplier' )
  endif
  pack
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "RECVLINE"
 if must_index
  Kill( Oddvars( SYSPATH ) + 'recvline' + mindxext )
 endif
 if Netuse( "RECVLINE", EXCLUSIVE, 1, NOALIAS, FALSE )
  mcount := FileDisp('Receiving Line Items', must_index )
  if !file( Oddvars( SYSPATH ) + 'recvline' + mindxext )
   if Bvars( B_NEWSORT ) = "T"
    indx( "IndxKey + desc", 'key' )
   else
    indx( "IndxKey", 'key' )
   endif
   indx( "id", 'id' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "DRAFTRET"
 if must_index
  Kill( Oddvars( SYSPATH ) + "DraftRet" + mindxext )
 endif
 if Netuse( "DraftRet", EXCLUSIVE, 1, NOALIAS, FALSE )
  mcount := Filedisp( 'Draft Returns', must_index )
  if !file( Oddvars( SYSPATH ) + "DraftRet" + mindxext )
   indx( "supp_code + department + upper( desc )", 'supplier' )
   indx( "supp_code + upper( skey )", 'skey' )

  else
   pack

  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "RETHEAD"
 if must_index
  Kill( Oddvars( SYSPATH ) + "rethead" + mindxext )
 endif
 if Netuse( "rethead", EXCLUSIVE, 1, NOALIAS, FALSE )
  mcount := FileDisp('Returns Header', must_index )
  if !file( Oddvars( SYSPATH ) + "rethead" + mindxext ) 
   indx( "number", 'number' )
   indx( "supp_code", 'supplier' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "RETLINE"
 if must_index
  Kill( Oddvars( SYSPATH ) + "retline" + mindxext )
 endif
 if Netuse( "retline", EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Returns Line Items', must_index )
  if !file( Oddvars( SYSPATH ) + "retline" + mindxext ) 
   indx( "number", 'number' )
   indx( "id", 'id' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "PURHIST"
 if must_index
  Kill( Oddvars( SYSPATH ) + "purhist" + mindxext )
 endif
 if Netuse( "purhist",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Supplier History', must_index )
  if !file( Oddvars( SYSPATH ) + "purhist" + mindxext ) 
   indx( "code", 'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "SPECIAL"
 if must_index
  Kill( Oddvars( SYSPATH ) + "special" + mindxext )
 endif
 if Netuse( "special",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Special Order', must_index )
  if !file( Oddvars( SYSPATH ) + "special" + mindxext ) 
   indx( "number", 'number' )
   indx( "id", 'id' )
   indx( "key", 'key' )
   indx( "notfound", 'notfound' )
   indx( "upper(ordno)", 'ordno' )
   indx( 'received-delivered', 'invoiced' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "LAYBY"
 if must_index
  Kill( Oddvars( SYSPATH ) + "layby" + mindxext )
 endif
 if Netuse( "layby",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Layby', must_index )
  if !file( Oddvars( SYSPATH ) + "layby" + mindxext )
   indx( "number", 'number' )
   indx( "key", 'key' ) 
  else
   pack
  endif
 endif
 Fileend( mcount, must_index )
endif

if mallfiles .or. mfile = "LAYBYPAY"
 if must_index
  Kill( Oddvars( SYSPATH ) + "lapaypay" + mindxext )
 endif
 if Netuse( "laybypay",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Layby Payments', must_index )
  if !file( Oddvars( SYSPATH ) + "laybypay" + mindxext )
   indx( "number", 'number' )
  else
   pack
  endif
 endif
 Fileend( mcount, must_index )
endif

if mallfiles .or. mfile = "INVHEAD"
 if must_index
  Kill( Oddvars( SYSPATH ) + "invhead" + mindxext )
 endif
 if Netuse( "invhead",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Invoice Header', must_index )
  if !file( Oddvars( SYSPATH ) + "invhead" + mindxext ) 
   indx( "number", 'number' )
   indx( "key", 'key' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "INVLINE"
 if must_index
  Kill( Oddvars( SYSPATH ) + "invline" + mindxext )
 endif
 if Netuse( "invline",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Invoice Line Items', must_index )
  if !file( Oddvars( SYSPATH ) + "invline" + mindxext ) 
   indx( "number",  'number' )
   indx( "id", 'id'  )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "PICKSLIP"
 if must_index
  Kill( Oddvars( SYSPATH ) + "pickslip" + mindxext )
 endif
 if Netuse( "pickslip",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Picking Slips', must_index )
  if !file( Oddvars( SYSPATH ) + "pickslip" + mindxext ) 
   indx( "number", 'number' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "CUSTOMER"
 if must_index
  Kill( Oddvars( SYSPATH ) + "customer" + mindxext  )
 endif
 if Netuse( "customer",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Customer Master', must_index )
  if !file( Oddvars( SYSPATH ) + "customer" + mindxext ) 
   indx( "key", 'key' )
   indx( "upper(name)", 'name' )

  else
   pack

  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "DEBTRANS"
 if must_index
  Kill( Oddvars( SYSPATH ) + "debtrans" + mindxext )
 endif
 if Netuse( "debtrans",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Debtors Transaction', must_index )
  if !file( Oddvars( SYSPATH ) + "debtrans" + mindxext ) 
   indx( "key + dtos( date )", 'key' )
   indx( "date", 'date' ) 
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "ARHIST"
 if must_index
  Kill( Oddvars( SYSPATH ) + "arhist" + mindxext )
 endif
 if Netuse( "arhist",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Debtors Transaction History', must_index )
  if !file( Oddvars( SYSPATH ) + "arhist" + mindxext ) 
   indx( "key + descend( dtos( date ) )", 'key' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "SALESREP"
 if must_index
  Kill( Oddvars( SYSPATH ) + "salesrep" + mindxext )
 endif
 if Netuse( "salesrep",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Sales Representives', must_index )
  if !file( Oddvars( SYSPATH ) + "salesrep" + mindxext ) 
   indx( "code", 'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "CRETRANS"
 if must_index
  Kill( Oddvars( SYSPATH ) + "cretrans" + mindxext )
 endif
 if file( Oddvars( SYSPATH ) + "cretrans.dbf")
  if Netuse( "cretrans",EXCLUSIVE,1, NOALIAS, FALSE )
   mcount := FileDisp( 'Creditor Transaction', must_index )
   if !file( Oddvars( SYSPATH ) + "cretrans" + mindxext ) 
    indx( "code",  'code' )
   else
    pack
   endif
   Fileend( mcount, must_index )
  endif
 endif
endif

if mallfiles .or. mfile = "APHIST"
 if must_index
  Kill( Oddvars( SYSPATH ) + "aphist" + mindxext )
 endif
 if Netuse( "aphist",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Creditor Transaction Hist.', must_index )
  if !file( Oddvars( SYSPATH ) + "aphist" + mindxext ) 
   indx( "code",  'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "CATEGORY"
 if must_index
  Kill( Oddvars( SYSPATH ) + "category" + mindxext )
 endif
 if Netuse( "category",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Category', must_index )
  if !file( Oddvars( SYSPATH ) + "category" + mindxext )
   indx( "code", 'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "MACATEGO"
 if must_index
  Kill( Oddvars( SYSPATH ) + "macatego" + mindxext )
 endif
 if Netuse( "macatego",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Master Categories', must_index )
  if !file( Oddvars( SYSPATH ) + "macatego" + mindxext )
   indx( "code + skey", 'code' )
   indx( "id", 'id' ) 
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile == "CUSTCATE"
 if must_index
  Kill( Oddvars( SYSPATH ) + "custcate" + mindxext )

 endif 
 if file( Oddvars( SYSPATH ) + "custcate.dbf")
  if Netuse( "custcate",EXCLUSIVE,1, NOALIAS, FALSE )
   mcount := FileDisp( 'Customer Categories', must_index )
   if !file( Oddvars( SYSPATH ) + "custcate" + mindxext )
    indx( "padr( key, 10 )", 'key' )
    indx( "code", 'code' )

   else
    pack

   endif
   Fileend( mcount, must_index )
  endif
 endif
endif

if mallfiles .or. mfile == "DEPT"
 if must_index
  Kill( Oddvars( SYSPATH ) + 'dept' + mindxext )
 endif
 if Netuse( "dept",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Department', must_index )
  if !file( Oddvars( SYSPATH ) + 'dept' + mindxext )
   indx( "code",  'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile == "DEPTMOVE"
 if must_index
  Kill( Oddvars( SYSPATH ) + "deptmove" + mindxext )
 endif
 if Netuse( "deptmove",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Department Stock Movement', must_index )
  if !file( Oddvars( SYSPATH ) + "deptmove" + mindxext ) 
   indx( "code + type", 'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile == "DEPTWEEK"
 if must_index
  Kill( Oddvars( SYSPATH ) + "deptweek" + mindxext )
 endif
 if Netuse( "deptweek",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Department Weekly Sales', must_index )
  if !file( Oddvars( SYSPATH ) + "deptweek" + mindxext )
   indx( "year + code", 'year' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile == "SUPPWEEK"
 if must_index
  Kill( Oddvars( SYSPATH ) + "suppweek" + mindxext )
 endif
 if Netuse( "suppweek",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Supplier Weekly Sales', must_index )
  if !file( Oddvars( SYSPATH ) + "suppweek" + mindxext )
   indx( "year + code", 'year' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "STATUS"
 if must_index
  Kill( Oddvars( SYSPATH ) + 'status' + mindxext )
 endif
 if Netuse( "status",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Status Codes', must_index )
  if !file( Oddvars( SYSPATH ) + 'status' + mindxext )
   indx( "code",  'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "BRANCH"
 if must_index
  Kill( Oddvars( SYSPATH ) + "branch" +mindxext )
 endif
 if Netuse( "branch",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Branch Codes', must_index )
  if !file( Oddvars( SYSPATH ) + "branch" + mindxext ) 
   indx( "code", 'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "STOCK"
 if must_index
  Kill( Oddvars( SYSPATH ) + "stock" + mindxext )
 endif
 if Netuse( "stock",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Stock Quantities', must_index )
  if !file( Oddvars( SYSPATH ) + "stock" + mindxext ) 
   indx( "id+branch", 'id' )
   indx( "branch", 'store' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "BRAND"
 if must_index
  Kill( Oddvars( SYSPATH ) + 'brand' + mindxext )
 endif
 if Netuse( "brand",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Imprint', must_index )
  if !file( Oddvars( SYSPATH ) + 'brand' + mindxext )
   indx( "code", 'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "BINDING"
 if must_index
  Kill( Oddvars( SYSPATH ) + "binding" + mindxext )
 endif
 if Netuse( "binding",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Binding Codes', must_index )
  if !file( Oddvars( SYSPATH ) + "binding" + mindxext ) 
   indx( "code", 'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "QUOTE"
 if must_index
  Kill( Oddvars( SYSPATH ) + "quote" + mindxext )
 endif
 if Netuse( "quote", EXCLUSIVE, 1, NOALIAS, FALSE )
  mcount := FileDisp( 'Quote', must_index )
  if !file( Oddvars( SYSPATH ) + "quote" + mindxext )
   indx( "number", 'number' )
   indx( "key", 'key' )
   indx( "id", 'id' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "APPROVAL"
 if must_index
  Kill( Oddvars( SYSPATH ) + "approval" + mindxext )
 endif
 if Netuse( "approval",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Approval', must_index )
  if !file( Oddvars( SYSPATH ) + "approval" + mindxext )
   indx( "number", 'number' )
   indx( "key", 'key' )
   indx( "id", 'id' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "TRANSFER"
 if must_index
  Kill( Oddvars( SYSPATH ) + "transfer" + mindxext )
 endif
 if Netuse( "transfer",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Transfer', must_index )
  if !file( Oddvars( SYSPATH ) + "transfer" + mindxext ) 
   indx( "number", 'number' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "KIT"
 if must_index
  Kill( Oddvars( SYSPATH ) + "kit" + mindxext )
 endif
 if file( Oddvars( SYSPATH ) + "kit.dbf")
  if Netuse( "kit",EXCLUSIVE,1, NOALIAS, FALSE )
   mcount := FileDisp( 'Kit', must_index )
   if !file( Oddvars( SYSPATH ) + "kit" + mindxext ) 
    indx( "id", 'id' )
    indx( "id", 'id' )
   else
    pack
   endif
   Fileend( mcount, must_index )
  endif
 endif
endif

if mallfiles .or. mfile = "HOLD"
 if must_index
  Kill( Oddvars( SYSPATH ) + "hold" + mindxext  )
 endif
 if Netuse( "hold",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Held ' + ITEM_DESC + '', must_index )
  if !file( Oddvars( SYSPATH ) + "hold" + mindxext ) 
   indx( "id", 'id' )
   indx( 'key', 'key' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "OPERATOR"
 if must_index
  Kill( Oddvars( SYSPATH ) + "operator" + mindxext )
 endif
 if Netuse( "operator", EXCLUSIVE, 1 )
  mcount := FileDisp( 'System Operator', must_index )
  if !file( Oddvars( SYSPATH ) + "operator" + mindxext ) 
   indx( "code", 'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "TELEORDE"
 if must_index
  Kill( Oddvars( SYSPATH ) + "teleorde" + mindxext )
 endif
 if Netuse( "teleorde",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Teleorder Suppliers', must_index )
  if !file( Oddvars( SYSPATH ) + "teleorde" + mindxext ) 
   indx( "code", 'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "TURNOVER"
 if must_index
  Kill( Oddvars( SYSPATH ) + "turnover" + mindxext )
 endif
 if Netuse( "turnover",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp('Turnover', must_index )
  if !file( Oddvars( SYSPATH ) + "turnover" + mindxext ) 
   indx( "tran_type + day", 'tran_type' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or.  mfile = "SUPERCES"
 if must_index
  Kill( Oddvars( SYSPATH ) + "superces" + mindxext )
 endif
 if file( Oddvars( SYSPATH ) + "superces.dbf" )
  if Netuse( "superces", EXCLUSIVE, 10, NOALIAS, FALSE  )
   mcount := FileDisp( "Supercession", must_index )
   if !file( Oddvars( SYSPATH ) + "superces" + mindxext ) 
    indx( "id", 'id' )
   else
    pack
   endif
   Fileend( mcount, must_index )
  endif
 endif
endif

if mallfiles .or. mfile = "POINSTRU"
 if must_index
  Kill( Oddvars( SYSPATH ) + "poinstru" + mindxext )
 endif
 if Netuse( "poinstru",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'PO Instructions', must_index )
  if !file( Oddvars( SYSPATH ) + "poinstru" + mindxext ) 
   indx( "code", 'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "RETCODES"
 if must_index
  Kill( Oddvars( SYSPATH ) + "retcodes" + mindxext )
 endif
 if Netuse( "retcodes", EXCLUSIVE, 1, NOALIAS, FALSE )
  mcount := FileDisp( 'Returns Codes', must_index )
  if !file( Oddvars( SYSPATH ) + "retcodes" + mindxext ) 
   indx( "code", 'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "SERIAL"
 if must_index
  Kill( Oddvars( SYSPATH ) + "serial" + mindxext )
 endif
 if Netuse( "serial", EXCLUSIVE, 1, NOALIAS, FALSE )
  mcount := FileDisp( 'Serial Numbers', must_index )
  if !file( Oddvars( SYSPATH ) + "serial" + mindxext )
   indx( "id", 'id' )
   indx( "key", 'key' )
   indx( "serial", 'serial' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if mallfiles .or. mfile = "EXCHRATE"
 if must_index
  Kill( Oddvars( SYSPATH ) + "exchrate" + mindxext )
 endif
 if Netuse( "exchrate",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Exchange Rates', must_index )
  if !file( Oddvars( SYSPATH ) + "exchrate" + mindxext ) 
   indx( "code", 'code' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

if file( Oddvars( SYSPATH ) + Oddvars( SYSPATH ) + "system.dbf" )
 if Netuse( "system" ,EXCLUSIVE, 10, NOALIAS, FALSE  )
  totrecs := lastrec()
  if totrecs - SYSTEM_MAX_RECS > 0
   delete next totrecs - SYSTEM_MAX_RECS
  endif
  pack
 endif
endif

#ifdef HEAD_OFFICE
if file( Oddvars( SYSPATH ) + Oddvars( SYSPATH ) + "titlchg.dbf" )
 if Netuse( "titlchg" ,EXCLUSIVE, 10, NOALIAS, FALSE  )
  totrecs := lastrec()
  delete for titlchg->processed
  pack
 endif
endif
#endif

if mallfiles .or. mfile = Oddvars( SYSPATH ) + "ARCHIVE\ARCHIVE"
 if must_index
  Kill( Oddvars( SYSPATH ) + "archive\archive" + mindxext )
 endif
 if file( Oddvars( SYSPATH ) + "archive\archive.dbf" )
  if Netuse( Oddvars( SYSPATH ) + "archive\archive", EXCLUSIVE, 1, 'archive', FALSE )
   mcount := FileDisp('Archive', must_index )
   if !file( Oddvars( SYSPATH ) + "archive\archive" + mindxext ) 
    indx( 'id', 'id', 'archive\archive' )
    indx( "upper( left( desc, " + Ns( SEARCH_KEY_LEN ) + " ) )", 'desc', 'archive\archive' )
    indx( "upper( left( alt_desc, " + Ns( SEARCH_KEY_LEN ) + " ) )", 'alt_desc', 'archive\archive' )

   else
    pack

   endif
   Fileend( mcount, must_index )
  endif
 endif
endif

if mallfiles .or. mfile = "STOCLOCS"
 if must_index
  Kill( Oddvars( SYSPATH ) + "stoclocs" + mindxext )
 endif
 if Netuse( "stoclocs",EXCLUSIVE,1, NOALIAS, FALSE )
  mcount := FileDisp( 'Stock Locations', must_index )
  if !file( Oddvars( SYSPATH ) + "stoclocs" + mindxext ) 
   indx( "id", 'id' )
  else
   pack
  endif
  Fileend( mcount, must_index )
 endif
endif

set escape on
close databases

elapsed := Seconds() - start_time
if elapsed < 0
 elapsed += 86400
endif 

if elapsed > 60
 if elapsed > 3600
  hours := int( elapsed / 3600 )
  ts := "Time for " + if( must_index, 'Reindex ', "Pack " ) + Ns( hours , 3 ) + " hour " + ;
     Ns( ( elapsed - ( 3600 * hours) ) / 60 , 2 ) + ' minutes'
 else
  ts := "Time for " + if( must_index, 'Reindex ', "Pack " ) + Ns( elapsed / 60, 3 ) + " minutes " + ;
     Ns( elapsed % 60 , 3 ) + "  seconds"
 endif
else
 ts := "Time for " + if( must_index, 'Reindex ', "Pack " ) + Ns((elapsed % 60),3) + "  seconds"
endif

Error(ts,12)
close databases
return msuccess

*

Function Filedisp ( mfile, must_index )
local mstr := if( must_index, 'Indexing ','Packing ' ) + mfile + ' file'
? mstr + space( 40-len( mstr ) ) + str( lastrec(), 6 ) + " recs"
return lastrec()

*

procedure fileend ( mcount, must_index )
if !must_index
 ?? '  ' + transform( mcount - lastrec(), "99,999" ) + ' records deleted'
endif
close databases
return

*

function indx ( mindexkey, mtag, cAlias, lIsUnique )

default lIsUnique to FALSE
default cAlias to alias()
//index on (mindexkey) tag (mtag) to (calias)
 Ordcreate( oddvars( SYSPATH ) + cAlias, mtag, mindexkey, { || &mindexkey }, lIsUnique )

return nil
