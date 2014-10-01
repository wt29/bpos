/*

        BPOS Supplier Maintenance Module


      Last change:  TG   18 Mar 2011    5:34 pm
*/

Procedure f_Supplier

#include "bpos.ch"

local lLoop:=FALSE
local nMenuChoice
local cSuppCode := Oddvars( MSUPP )
local aArray
local sScreen
local oldscr:=Box_Save()
local getlist:={}

Center(24,'Opening files for Supplier Maintenance')
if Netuse( "purhist" )
 if Netuse( "supplier" )
  lLoop := TRUE
 endif
endif

line_clear( 24 )

while lLoop
 Box_Restore( oldscr )
 Heading('Supplier File Maintenance Menu')

 aArray := {}
 aadd( aArray, { 'File', 'Exit to File Menu' } )
 aadd( aArray, { 'Add', 'Add New Suppliers' } )
 aadd( aArray, { 'Change', 'Change/Enquire Supplier Details' } )
 aadd( aArray, { 'Global', 'Replace old Supplier with New' } )
 aadd( aArray, { 'Print', 'Supplier Details' } )
 nMenuChoice := Menugen( aArray, 04, 02, 'Supplier' )

 do case
 case nMenuChoice = 2
  while TRUE

   cSuppCode := space( SUPP_CODE_LEN )
   Heading( 'Supplier File Add' )
   sScreen := Box_Save( 05, 12, 07, 40 )
   @ 6,14 say 'New Supplier Code';
          get cSuppCode pict '@!' valid( left( cSuppCode, 1 ) != '*' .and. non_stock( cSuppCode ) )
   read
   Box_Restore( sScreen )
   if ! updated()
    exit
   else
    if dbseek( cSuppCode )
     sScreen := Box_Save( 7, 10, 9, 70 )
     Center( 8,'Supplier Name ' + trim( supplier->name ) )
     Error('Supplier Code already on file',12)
     Box_Restore( sScreen )

    else
     SysAudit("SupAdd"+cSuppCode)
     select supplier
     Add_rec('supplier')
     supplier->code := cSuppCode
     supplier->country := Bvars( B_COUNTRY )
     supplier->posort := 'T'
     supplier->op_it := !Bvars( B_OPENCRED )
     if SYSNAME = 'BPOS'
      supplier->price_meth := 'C'
      supplier->gst_inc := NO

     else
      supplier->price_meth := 'R'
      supplier->gst_inc := NO

     endif 

     supplier->forexcode := '$AUS'
      
     Supplier( GO_TO_EDIT )

     if empty( supplier->name )
      Error('No Name for Supplier Record',12)
      Del_rec( 'supplier' )
     endif

     supplier->( dbrunlock() )
    endif
   endif
  enddo

 case nMenuChoice = 3
  while TRUE
   Heading('Change Supplier Details')
   cSuppCode := GetSuppCode( 06, 14 ) 
   if lastkey() = K_ESC
    exit
   else
    supplier->( dbseek( cSuppCode ) )
    Supplier()
   endif
  enddo
 case nMenuChoice = 4
  Suppglobal()

 case nMenuChoice = 5
  Supp_print()

 case nMenuChoice < 2
  exit
 endcase

enddo
Oddvars( MSUPP, cSuppCode )
dbcloseall()
return
*

procedure suppglobal
local nMenuChoice, mpub1, mpub2, mpub3, mlen1, mlen2, mlen3, cSuppCode, mimpr
local val_arr, y, f_ord, f_arr, keyval, suppname, lAnswer, cSuppCode2
local x, aArray, creddel, getlist:={}, sbrand

if Secure( X_GLOBALS )

 Heading('Global Supplier Change')

 aArray := {}
 aadd( aArray, { 'File', 'Exit to File Menu' } )
 aadd( aArray, { 'Absorb', 'Absorb one Supplier into Another' } )
 aadd( aArray, { 'Create', 'Create a new Supplier from ' + BRAND_DESC } )
 aadd( aArray, { BRAND_DESC, 'Absorb one ' + BRAND_DESC + ' into another' } )
 aadd( aArray, { ID_DESC, 'Absorb ' + ITEM_DESC + ' using ' +ID_DESC+' info' } )
 aadd( aArray, { 'Name', 'Change the Name/Code of a supplier' } )

 nMenuChoice := MenuGen( aArray, 08, 03, 'Global' )

 do case
 case nMenuChoice = 2 .or. nMenuChoice = 6
  Box_Save( 02, 08, 11, 71 )
  Heading( if( nMenuChoice=2, 'One Supplier Absorbs another', 'Change the code of a supplier' ) )
  cSuppCode := space( SUPP_CODE_LEN )
  @ 3, 10 say 'Old Supplier Code' get cSuppCode pict '@!'
  read

  if updated()
   if !supplier->( dbseek( cSuppCode ) )
    suppname:='Supplier Code ('+ cSuppCode + ') which is not on file'
   else
    suppname:=trim( supplier->name )
    creddel := TRUE
    if nMenuChoice = 2 .and. ;
      (supplier->amtcur+supplier->amt30+supplier->amt60+supplier->amt90 != 0)
     Error("Supplier has Creditors Balance - " + SYSNAME + " will not delete old Creditor",12)
     creddel := FALSE
    endif
   endif
   lAnswer := FALSE
   Highlight(05,10,'Supplier Name',suppname)
   @ 07,10 say 'Is this the Supplier to '+if( nMenuChoice = 2,'absorb','change' ) ;
           get lAnswer pict 'Y'
   read

   if lAnswer
    cSuppCode2:=space( SUPP_CODE_LEN )
    if nMenuChoice = 2
     @ 09,10 say 'Supplier to absorb into' get cSuppCode2 pict '@!' ;
             valid( Dup_chk( cSuppCode2, 'Supplier' ) )

    else
     @ 09,10 say 'New code to change to' get cSuppCode2 pict '@!'

    endif
    read
    if !updated()
     return

    else
     supplier->( dbseek( cSuppCode2 ) )
     if nMenuChoice = 6 .and. found()
      Error( 'Code ' + cSuppCode2 + ' is already on file - you cannot change', 12 )
      return
     endif

     Heading('Global Supplier Change')
     Box_Save( 01, 08, 12, 70, 6 )
     Center( 3, 'You are about to change all file records for -' )
     Center( 4, suppname + if( nMenuChoice = 6, ' ('+cSuppCode+')', '' ) )
     Center( 5, '- to -' )
     Center( 6, if( nMenuChoice=2, supplier->name, suppname + ' (' +cSuppCode2+')' ) )
     Syscolor( 1 )
     if Isready( 10 )
      if Isready( 10, 10, 'AGAIN - ARE YOU SURE THIS IS CORRECT? (Y/N)' )
       SysAudit("SupGloA"+cSuppCode+"to"+cSuppCode2)
       if Netuse( 'aphist', EXCLUSIVE )
        if Netuse( "cretrans", EXCLUSIVE )
         if Netuse( "master", EXCLUSIVE )
          if Netuse( 'brand' )
           if Netuse( 'pohead' )
            ordsetfocus( BY_SUPPLIER )
            if Netuse( 'draft_po' )
             @ 10, 15 say 'Draft PO file'

             while dbseek( cSuppCode )
              rec_lock('draft_po')
              draft_po->supp_code := cSuppCode2
              draft_po->( dbrunlock() )

             enddo

             draft_po->( dbclosearea() )
             @ 10, 15 say 'Purchase Order files'
             while pohead->( dbseek( cSuppCode ) )
              Rec_lock( 'pohead' )
              pohead->supp_code := cSuppCode2
              pohead->( dbrunlock() )

             enddo
             @ 10, 15 say BRAND_DESC + ' file        '

             select brand
             locate for brand->supp_code = cSuppCode
             while found()
              Rec_lock( 'brand' )
              brand->supp_code := cSuppCode2
              brand->( dbskip() )
              continue

             enddo

             if fieldpos( 'supp_code2' ) != 0     // Second Supplier Code on brand file
              select brand
              locate for brand->supp_code2 = cSuppCode
              while found()
               Rec_lock( 'brand' )
               brand->supp_code2 := cSuppCode2
               brand->( dbskip() )
               continue

              enddo

             endif

             if nMenuChoice = 6
              @ 10, 15 say 'Creditors file     '
              while cretrans->( dbseek( cSuppCode ) )
               Rec_lock('cretrans')
               cretrans->code := cSuppCode2
               cretrans->( dbrunlock() )
              enddo  
              select aphist
              while aphist->( dbseek( cSuppCode ) )
               Rec_lock( 'aphist' )
               aphist->code := cSuppCode2
               aphist->( dbrunlock() )
              enddo
             endif

             @ 10, 15 say 'Master file          '
             select master
             replace all supp_code with cSuppCode2 for master->supp_code = cSuppCode

            endif
            pohead->( dbclosearea() )

           endif
           brand->( dbclosearea() )

          endif
          master->( dbclosearea() )

         endif
         @ 10, 15 say 'Purchase History file   '
         val_arr := { '','_RET','_SAL','_REC' }
         for y := 1 to 4
          select purhist
          if dbseek( trim( cSuppCode ) + val_arr[ y ] )
           if nMenuChoice = 6                           // Just rename Record here!
            Rec_lock()
            purhist->code := trim( cSuppCode2 ) + val_arr[ y ]

           else
            f_ord := 1                             // Our position ordinal
            f_arr := {}                            // An array to save field values in

            while fieldget( f_ord ) != nil
             aadd( f_arr, fieldget( f_ord ) )      // Save field vals in array
             f_ord++

            enddo
            keyval := trim( cSuppCode2 ) + val_arr[y]  // Calculate new code value

            if !dbseek( keyval )                   // Well that one wasn't on file
             Add_rec()                             // New purhist record created
             purhist->code := keyval               // With new key ( code )

            endif
            Rec_lock()
            for f_ord := 1 to len( f_arr )
             if valtype( fieldget( f_ord ) ) == 'N'
              fieldput( f_ord, fieldget( f_ord ) + f_arr[ f_ord ] )   // Append field data
             endif
            next

           endif
           dbrunlock()

          endif

         next
         select supplier
         if dbseek( cSuppCode )
          Rec_lock()
          if nMenuChoice = 2
           if creddel
            delete
         //   if !empty( supplier->abs_ptr )
         //    Abs_delete( 'supplier' )

         //   endif

           endif

          else
           supplier->code := cSuppCode2

          endif
          dbrunlock()
         endif
         cretrans->( dbclosearea() )
        endif
        aphist->( dbclosearea() )
       endif
      endif
     endif
    endif
   endif
  endif

 case nMenuChoice > 2
  Heading('Change a ' + BRAND_DESC + ' into a Supplier')
  Box_Save(02,08,10,72)
  if nMenuChoice = 3 .or. nMenuChoice = 4
   @ 3,10 say 'Enter your three matches for the ' + BRAND_DESC + ' code'
   @ 4,10 say 'Warning - Blank ' + BRAND_DESC + ' will also be replaced!'
   mpub1 := space( 6 )
   mpub2 := space( 6 )
   mpub3 := space( 6 )

  else
   @ 3,10 say 'Enter your three ' + ID_DESC + ' fragments'
   mpub1 := space( 7 )
   mpub2 := space( 7 )
   mpub3 := space( 7 )

  endif
  @ 5,10 say '1.' get mpub1 pict '@!' valid( if( nMenuChoice!=3.or.empty(mpub1), TRUE, Dup_chk( mpub1, "brand" ) ) )
  @ 5,25 say '2.' get mpub2 pict '@!' valid( if( nMenuChoice!=3.or.empty(mpub2), TRUE, Dup_chk( mpub2, "brand" ) ) )
  @ 5,40 say '3.' get mpub3 pict '@!' valid( if( nMenuChoice!=3.or.empty(mpub3), TRUE, Dup_chk( mpub3, "brand" ) ) )
  read
  if updated()
   if nMenuChoice = 4
    sBrand := space(6)
    @ 7,10 say 'New ' + BRAND_DESC + ' code' get sBrand pict '@!' valid( Dup_chk( sBrand , "brand" ) )

   else
    cSuppCode := space( SUPP_CODE_LEN )
    @ 7,10 say 'New Supplier Code' get cSuppCode pict '@!'

   endif
   read
   if updated()
    if nMenuChoice != 4
     select supplier
     seek cSuppCode

    endif
    if nMenuChoice != 4 .and. !found()
     Error('This supplier code NOT on file - Enter it',12 )

    else
     Box_Save( 02, 08, 14, 70 )
     Heading('Change new Supplier records')
     lAnswer := FALSE
     @ 3,10 say 'You are about to change all master file records that match'
     @ 5,10 say ' Either ' + if( empty(mpub1),'<Blank',mpub1 ) + ;
             ' or ' + if( empty( mpub2 ), '<Blank>', mpub2 )  + ;
             ' or ' + if( empty( mpub3 ), '<Blank>', mpub3 )
     if nMenuChoice != 4
      Highlight( 6, 10,' to ', trim( supplier->name ) )

     else
      Highlight( 6, 10, 'to ', Lookitup( "brand" , mimpr ) )

     endif
     if Isready( 08, 10, 'Are you sure this is correct' )
      if Isready( 10, 10, 'Again - Are you sure this is correct' )
       if Netuse( "master", EXCLUSIVE, 5, NOALIAS, NEW )
        if nMenuChoice != 4
         ordsetfocus( NATURAL )

        endif
        Center(12,'-=< Now Processing - Please Wait >=-')
        do case
        case nMenuChoice = 3
         SysAudit("SupGloC"+cSuppCode)
         replace all supp_code with cSuppCode for master->brand == mpub1 ;
                 .or. master->brand == mpub2 .or. master->brand == mpub3

        case nMenuChoice = 4
         SysAudit("SupGloImp"+mimpr)
         replace all master->brand with sBrand for master->brand == mpub1 ;
                 .or. master->brand == mpub2 .or. master->brand == mpub3
         if select('brand') <> 0
          brand -> ( dbclosearea() ) // Added by DAC

         endif
         if NetUse( 'brand', SHARED, 10, 'brandtemp', NEW )
          aArray := { mpub1, mpub2, mpub3 }
          for x := 1 to 3
           if aArray[ x ] != mimpr
            if dbseek( aArray[ x ] )
             Del_Rec()

            endif

           endif

          next
          brandtemp->( dbclosearea() )

         endif
        case nMenuChoice = 5
         SysAudit("SupGloid"+cSuppCode)
         mpub1 := '978' + trim( mpub1 )
         mpub2 := '978' + trim( mpub2 )
         mpub3 := '978' + trim( mpub3 )
         mlen1 := len( mpub1 )
         mlen2 := len( mpub2 )
         mlen3 := len( mpub3 )
         replace all supp_code with cSuppCode for;
                 ( substr( master->id, 1, mlen1 ) = mpub1 .and. mlen1 > 3 ) .or. ;
                 ( substr( master->id, 1, mlen2 ) = mpub2 .and. mlen2 > 3 ) .or. ;
                 ( substr( master->id, 1, mlen3 ) = mpub3 .and. mlen3 > 3 )

        endcase
        master->( dbclosearea() )

       endif
       select supplier
//       supplier->( dbclosearea() )
      endif
     endif
    endif
   endif
  endif
 endcase
endif
return

*

procedure supp_print
local nMenuChoice, first_day, weeknum, this_year, last_year, start_week
local page_number, page_width, page_len, top_mar, bot_mar, ly, ty
local col_head1, col_head2, tlycost, tlysell, ttycost, report_name, sScreen
local tot_lysell, tot_tysell, this_arr, last_arr, x, y, s, tycost, tysell
local lycost, lysell, ttysell, getlist:={}, cSuppCode, mtot, aArray, farr:={}
memvar impr
private impr

Heading('Suppliers Print Menu')

aArray := {}
aadd( aArray, { 'Back', 'Return to Suppliers Menu' } )
aadd( aArray, { 'Code', 'Print Suppliers by Code' } )
aadd( aArray, { 'Receipts', 'Print Receipts by Supplier by month' } )
aadd( aArray, { 'Sales', 'Print Sales by Supplier by month' } )
aadd( aArray, { 'Movement', 'Print Movement by Supplier' } )
aadd( aArray, { 'Orders', 'Print Order totals by Month by Supplier' } )
aadd( aArray, { 'Envelopes', 'Address Envelopes' } )
aadd( aArray, { BRAND_DESC +'s', 'List of '+BRAND_DESC+' in system' } )
aadd( aArray, { 'Weekly', 'Comparitive Weekly Sales' } )
aadd( aArray, { 'YTD sales', 'Year to date Comparision' } )
aadd( aArray, { 'Labels', 'Print Labels for All Suppliers' } )
nMenuChoice := MenuGen( aArray, 09, 03, 'Print' )

Print_find( 'report' )

farr := {}
if nMenuChoice = 3 .or. nMenuChoice = 4
 aadd(farr,{'substr(supplier->name,1,30)','SUPPLIER NAME',30,0,FALSE})
 aadd(farr,{'abs(jan)','JAN',7,0,TRUE})
 aadd(farr,{'abs(feb)','FEB',7,0,TRUE})
 aadd(farr,{'abs(mar)','MAR',7,0,TRUE})
 aadd(farr,{'abs(apr)','APR',7,0,TRUE})
 aadd(farr,{'abs(may)','MAY',7,0,TRUE})
 aadd(farr,{'abs(jun)','JUN',7,0,TRUE})
 aadd(farr,{'abs(jul)','JUL',7,0,TRUE})
 aadd(farr,{'abs(aug)','AUG',7,0,TRUE})
 aadd(farr,{'abs(sep)','SEP',7,0,TRUE})
 aadd(farr,{'abs(oct)','OCT',7,0,TRUE})
 aadd(farr,{'abs(nov)','NOV',7,0,TRUE})
 aadd(farr,{'abs(dec)','DEC',7,0,TRUE})
 aadd(farr,{'abs(jan)+abs(feb)+abs(mar)+abs(apr)+abs(may)+abs(jun)+abs(jul)+abs(aug)+abs(sep)+abs(oct)+abs(nov)+abs(dec)','TOTALS',9,0,TRUE})

endif
if nMenuChoice = 5
 aadd(farr,{'if(substr(code,at("_",code)+1,3)="SAL","SALES",if(substr(code,at("_",code)+1,3)="REC","RECEIVED","RETURNED"))','Movement',8,0,FALSE})

endif
if nMenuChoice = 6
 aadd(farr,{'substr(supplier->name,1,30)','SUPPLIER NAME',30,0,FALSE})

endif

if nMenuChoice = 5 .or. nMenuChoice = 6
 aadd(farr,{'JAN','Jan',7,0,TRUE})
 aadd(farr,{'FEB','Feb',7,0,TRUE})
 aadd(farr,{'MAR','Mar',7,0,TRUE})
 aadd(farr,{'APR','Apr',7,0,TRUE})
 aadd(farr,{'MAY','May',7,0,TRUE})
 aadd(farr,{'JUN','Jun',7,0,TRUE})
 aadd(farr,{'JUL','Jul',7,0,TRUE})
 aadd(farr,{'AUG','Aug',7,0,TRUE})
 aadd(farr,{'SEP','Sep',7,0,TRUE})
 aadd(farr,{'OCT','Oct',7,0,TRUE})
 aadd(farr,{'NOV','Nov',7,0,TRUE})
 aadd(farr,{'DEC','Dec',7,0,TRUE})
 aadd(farr,{'JAN+FEB+MAR+APR+MAY+JUN+JUL+AUG+SEP+OCT+NOV+DEC','Totals',10,0,TRUE})

endif

do case
case nMenuChoice = 2
 Heading('Print Suppliers by Code')
 if Isready(14)
  supplier -> (dbgotop())
 
  farr := {}
  aadd(farr,{'code','Code',SUPP_CODE_LEN +1 ,0,FALSE})
  aadd(farr,{'name','Supplier Name',30,0,FALSE})
  aadd(farr,{'trim(address1)+" "+trim(address2)+" "+trim(city)','Address',43,0,FALSE})
  aadd(farr,{'phone','Telephone',17,0,FALSE})
  aadd(farr,{'fax','Facsimile',17,0,FALSE})
  aadd(farr,{'account','Account #',10,0,FALSE})
  aadd(farr,{'std_disc','Disc',4,1,FALSE})
  Reporter(farr,'"Listing of Suppliers sorted by Code"')

 endif

case nMenuChoice = 3
 Heading('Print Receipts per Supplier')
 if Isready(16)
  select purhist
  set relation to substr(purhist->code,1,at('_',purhist->code)-1) into supplier
  go top

  Reporter(farr,'"Receipts by Supplier by Month"','','','','',FALSE,"'_REC' $ purhist->code")

  select supplier

 endif

case nMenuChoice = 4
 Heading('Print Sales by Supplier by Month')
 if Isready(16)
  select purhist
  set relation to substr(purhist->code,1,at('_',purhist->code)-1) into supplier
  go top
  Reporter(farr,'"Sales by Supplier by Month"','','','','',FALSE,"'_SAL' $ purhist->code")

  select supplier

 endif

case nMenuChoice = 5
 Heading('Print Stock Movement by Supplier')
 if Isready(17)
  select purhist
  set relation to substr(purhist->code,1,at("_",purhist->code)-1) into supplier
  go top

  Reporter(farr,'"Stock Movement by Supplier by Month"','supplier->name',;
  '"Totals for Supplier -=> "+supplier->name','','',FALSE,"'_' $ purhist->code")
  s := array( 3,12 )
  sum purhist->jan, purhist->feb, purhist->mar, purhist->apr, purhist->may, purhist->jun, ;
      purhist->jul, purhist->aug, purhist->sep, purhist->oct, purhist->nov, purhist->dec ; 
      to s[1,1],s[1,2],s[1,3],s[1,4],s[1,5],s[1,6],s[1,7],s[1,8],s[1,9],s[1,10],s[1,11],s[1,12] ;
      for '_SAL' $ purhist->code
  sum purhist->jan, purhist->feb, purhist->mar, purhist->apr, purhist->may, purhist->jun, ;
      purhist->jul, purhist->aug, purhist->sep, purhist->oct, purhist->nov, purhist->dec ; 
      to s[2,1],s[2,2],s[2,3],s[2,4],s[2,5],s[2,6],s[2,7],s[2,8],s[2,9],s[2,10],s[2,11],s[2,12] ;
      for '_RET' $ purhist->code 
  sum purhist->jan, purhist->feb, purhist->mar, purhist->apr, purhist->may, purhist->jun, ;
      purhist->jul, purhist->aug, purhist->sep, purhist->oct, purhist->nov, purhist->dec ; 
      to s[3,1],s[3,2],s[3,3],s[3,4],s[3,5],s[3,6],s[3,7],s[3,8],s[3,9],s[3,10],s[3,11],s[3,12] ;
      for '_REC' $ purhist->code 
  set device to printer
  @ prow() + 2, 0 say 'Totals for Movement Types'
  for x := 1 to 3
   @ prow()+1, 0 say if( x=1, 'Sales    ',if( x = 2, 'Returns  ', 'Received ' ) )
   mtot := 0
   for y := 1 to 12
    @ prow(), pcol() + 2 say s[ x, y ] pict '999999' 
    mtot += s[ x, y ]
   next 
   @ prow(), pcol() + 2 say mtot pict '99999999'
  next
  set device to screen
  // Pitch10()
  Endprint()
  set relation to
  select supplier
 endif

case nMenuChoice = 6
 Heading('Print Orders by Supplier by Month')
 If Isready(17)
  
  select purhist
  set relation to purhist->code into supplier
  dbgotop()
  Reporter(farr,'"Order Totals by Supplier by Month"','','','','',FALSE,"at('_',purhist->code) = 0")

  select supplier

 endif

case nMenuChoice = 7
 while TRUE
  cSuppCode := space( SUPP_CODE_LEN )
  Heading('Address Envelopes')
  @ 14,15 say 'ÍÍÍ¯Enter Supplier Code' get cSuppCode pict '@!' ;
          valid( Dup_chk( cSuppCode, 'supplier' ) )
  read
  if !updated()
   exit
  else
   if !supplier->( dbseek( cSuppCode ) )
    Error( 'Supplier Code not on File', 17 )

   else
    Print_find( "label", "report" )
    
    Box_Save( 17, 10, 19, 70 )
    Highlight( 18, 12, 'Supplier Name -> ', trim( supplier->name ) )
    if Isready( 19 )
     // Pitch10()
     set printer on
     set console off
     ?
     ?
     ?
     ?
     ? space( 24 ) + supplier->name
     ? space( 24 ) + supplier->address1
     ? space( 24 ) + supplier->address2
     ? space( 24 ) + supplier->city
     if upper( substr( supplier->country, 1, 3 ) ) != 'AUS'
      ? space( 24 ) + supplier->country
     endif
     Endprint()
     set console on
     set printer off
    endif
   endif
  endif
 enddo

case nMenuChoice = 8
 Heading( 'Print List of ' + BRAND_DESC + 's in System' )
 if Isready( 12 )
  if Netuse( "brand" , SHARED, 10, NOALIAS, NEW )
   
   impr := BRAND_DESC
   farr := {}
   aadd(farr,{'code','Code',11,0,FALSE})
   aadd(farr,{'name','Name',50,0,FALSE})
   aadd(farr,{'supp_code','Supplier',8,0,FALSE})
   Reporter(farr,'"Listing of " + impr + "s Sorted by Code"','','','','',FALSE,,,80)
   brand->( dbclosearea() )

  endif

 endif

case nMenuChoice = 9
 if Secure( X_SALESREPORTS )
  SysAudit("SupWkComRe")
  Heading( 'Supplier Comparitive Weekly Sales Report' )
  first_day := ctod("01/01/"+substr(ltrim(str(year( Bvars( B_DATE ) ))),3,2))
  weeknum := int((Bvars( B_DATE )-first_day)/7)+if( dow( first_day ) < 5,1,0)
  this_year := ns( year( Bvars( B_DATE ) ) )
  last_year := ns( year( Bvars( B_DATE ) ) - 1 )
  start_week := 1
  sScreen := Box_Save( 2,20,6,60 )
  @ 3,22 say 'Starting Week number' get start_week pict '99' range 1,53
  @ 5,22 say this_year + space(10) + last_year
  Highlight( 4, 22, 'Current Week is' , Ns( weeknum ) )
  read
  if Isready(12)
   
   if Netuse( "suppweek" )
    indx( "code", 'code' )
    select supplier
    set relation to supplier->code into suppweek
    go top
    page_number := 1
    page_width := 132
    page_len := 66
    top_mar := 0
    bot_mar := 10
    col_head1 := 'Supplier      Yr'
    col_head2 := 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
    for x := start_week to min( start_week+18, 53 )
     col_head1 += padl( 'W' + ns( x ) , 6 )
     col_head2 += ' ' + "==="
 next
    report_name := 'Sales by Supplier by Week Variance '
    set device to print
    PageHead( report_name, page_width, page_number, col_head1, col_head2 )
    tot_lysell := {}
    tot_tysell := {}
    while !supplier->(eof()) .and. Pinwheel()
     select suppweek
     locate for suppweek->year = last_year while suppweek->code = supplier->code
     last_arr := {}
     if found()
      for x := start_week to min( start_week+18 , 53 )
       aadd(last_arr,{fieldget(fieldpos('C'+ Ns(x))),fieldget(fieldpos('S'+Ns(x)))})
       aadd(tot_lysell,0)
      next
     endif
     seek supplier->code
     locate for suppweek->year = this_year while suppweek->code = supplier->code
     this_arr := {}
     if found()
      for x := start_week to min( start_week+18 , 53 )
       aadd(this_arr,{fieldget(fieldpos('C'+ Ns(x))),fieldget(fieldpos('S'+Ns(x)))})
       aadd(tot_tysell,0)
      next
     endif
     if len( last_arr ) != 0
      @ prow()+1,0 say substr( supplier->name,1,13 ) + ' '+substr(last_year,3,2)
      for x := 1 to len( this_arr )
       @ prow(),x*6+12 say last_arr[x,2] pict '9999'
       tot_lysell[x] += last_arr[x,2]
      next
     endif
     @ prow()+1,0 say substr( supplier->name,1,13 ) + ' '+substr(this_year,3,2)
     for x := 1 to len( this_arr )
      @ prow(),x*6+12 say this_arr[x,2] pict '9999'
      tot_tysell[x] += this_arr[x,2]
     next
     if len( last_arr ) != 0
      @ prow()+1,0 say substr( supplier->name,1,13 ) + ' Va%'
      for x := 1 to len( this_arr )
       ly := last_arr[x,2]
       ty := this_arr[x,2]
       @ prow(),x*6+12 say (ty-ly)/(ly/100) pict '9999'
      next
     endif
     if PageEject( page_len, top_mar, bot_mar )
      page_number++
      PageHead( report_name, page_width, page_number, col_head1, col_head2 )
     endif
     @ prow()+1,0 say ''
     skip alias supplier
    enddo
    @ prow()+1,0 say replicate( chr( 205 ) , 130 )
    if len( tot_lysell ) != 0
     @ prow()+1,0 say replicate(chr(205),79)
     @ prow()+1,0 say 'Total   ' + substr( last_year,3,2 )
     for x := 1 to len( this_arr )
      @ prow(),x*6+11 say tot_lysell[x] pict '99999'
     next
    endif
    @ prow()+1,0 say 'Total   ' + substr( this_year,3,2 )
    for x := 1 to len( this_arr )
     @ prow(),x*6+11 say tot_tysell[x] pict '99999'
    next
    if len( tot_lysell ) != 0
     @ prow()+1,0 say 'Total Variance' 
     for x := 1 to len( this_arr )
      ly := tot_lysell[x]
      ty := tot_tysell[x]
      @ prow(),x*6+11 say (ty-ly)/(ly/100) pict '99999'
     next
    endif
    set device to screen
    // Pitch10()
    Endprint()
    select supplier
    set relation to
    suppweek->( orddestroy( 'code' ) )
    suppweek->( dbclosearea() )
   endif
  endif
 endif

case nMenuChoice = 10
 if Secure( X_SALESREPORTS )
  SysAudit("YtdSuppRpt")
  Heading( 'Year to date Comparision' )
  first_day := ctod("01/01/"+substr(ltrim(str(year( Bvars( B_DATE ) ))),3,2))
  weeknum := int((Bvars( B_DATE )-first_day)/7)+if( dow( first_day ) < 5,1,0)
  this_year := ns( year( Bvars( B_DATE ) ) )
  last_year := ns( year( Bvars( B_DATE ) ) - 1 )
  start_week := 0
  Box_Save( 02,20,04,60 )
  Highlight( 03, 22, 'Week to Print to is ' , Ns( weeknum - 1 ) )
  
  if Isready(12)
   if Netuse( "suppweek" )
    indx( "suppweek->code", 'code' )
    select supplier
    set relation to supplier->code into suppweek
    go top
    page_number := 1
    page_width := 80
    page_len := 66
    top_mar := 0
    bot_mar := 10
    ly := substr( last_year, 3, 2 )
    ty := substr( this_year, 3, 2 )
    col_head1 := 'Supplier           Cost ' + ly + '   Cost '+ ty + ;
                 '   Var %     Sell ' + ly + '   Sell ' + ty + '   Var %'
    col_head2 := replicate(chr(196),80)
    tlycost := 0
    tlysell := 0
    ttycost := 0
    ttysell := 0
    report_name := 'Ytd Sales Variance by Department to Week ' + Ns( weeknum - 1 )
    set device to print
    PageHead( report_name, page_width, page_number, col_head1, col_head2 )
    while !supplier->(eof()) .and. Pinwheel()
     select suppweek
     locate for suppweek->year = last_year while suppweek->code = supplier->code
     lycost := 0
     lysell := 0
     if found()
      for x := 1 to weeknum-1
       lycost += fieldget( fieldpos( 'C' + Ns(x) ) )
       lysell += fieldget( fieldpos( 'S' + Ns(x) ) )

      next
      tlycost += lycost
      tlysell += lysell

     endif
     seek supplier->code
     locate for suppweek->year = this_year while suppweek->code = supplier->code
     tycost := 0
     tysell := 0
     if found()
      for x := 1 to weeknum -1
       tycost += fieldget( fieldpos( 'C' + Ns(x) ) )
       tysell += fieldget( fieldpos( 'S' + Ns(x) ) )

      next
      ttycost += tycost
      ttysell += tysell

     endif
     @ prow()+1,0 say substr( supplier->name,1,13 )
     @ prow(), 20 say lycost pict '999999'
     @ prow(), 30 say tycost pict '999999'
     @ prow(), 40 say (tycost-lycost)/(lycost/100) pict '9999'
     @ prow(), 50 say lysell pict '999999'
     @ prow(), 60 say tysell pict '999999'
     @ prow(), 70 say (tysell-lysell)/(lysell/100) pict '9999'
     if PageEject( page_len, top_mar, bot_mar )
      page_number++
      PageHead( report_name, page_width, page_number, col_head1, col_head2 )

     endif
     supplier->( dbskip() )

    enddo
    @ prow()+1,0 say replicate(chr(205),79)
    @ prow()+1,0 say ' Totals '
    @ prow(), 20 say tlycost pict '999999'
    @ prow(), 30 say ttycost pict '999999'
    @ prow(), 40 say (ttycost-tlycost)/(tlycost/100) pict '9999'
    @ prow(), 50 say tlysell pict '999999'
    @ prow(), 60 say ttysell pict '999999'
    @ prow(), 70 say (ttysell-tlysell)/(tlysell/100) pict '9999'
    set device to screen
    // Pitch10()
    Endprint()
    select supplier
    set relation to

    suppweek->( orddestroy( 'code' ) )
    suppweek->( dbclosearea() )

   endif

  endif

 endif

case nMenuChoice = 11
 Heading( 'Print Labels for All Suppliers' )
 Print_find( 'label', 'barcode' )
 if Isready(12)
  Pitch12()
  supplier->( dbgotop() )
  label form supplabe.frm to print noconsole while Pinwheel() sample
  // Pitch10()

 endif

endcase

return

*

procedure supplier ( goto_edit )
local okalta:=setkey( K_ALT_A, { || abs_edit( "supplier" ) } )
local okf10 := setkey( K_F10, { || supp_get() } )
local okaf9 := setkey( K_F9, { || supphist() } )
local okf1 := setkey( K_F1, { || SuppGetHelp() } )
local getlist := {}, mwait := ' ', sScreen := Box_Save( 01, 0, 24, 79, C_NORMAL )
default goto_edit to FALSE
if select( "purhist" ) = 0
 if !Netuse( "purhist" )
  return
 endif
 select supplier
endif
Supp_say()
if goto_edit
 Supp_get()
else 
 @ 24,79 get mwait
 read
endif
setkey( K_F10, okf10 )
setkey( K_ALT_A, okalta )
setkey( K_F9, okaf9)
setkey( K_F1, okf1 )
Box_Restore( sScreen )

*

function supp_say
cls
Heading( 'Supplier Details Screen')
Highlight( 02, 01, '    Supplier Name', supplier->name )
Highlight( 02, 53, 'Code->', supplier->code )
Highlight( 03, 01, ' Postal Address 1', supplier->address1 )
Highlight( 04, 01, '                2', supplier->address2 )
Highlight( 05, 01, '                3', supplier->city )
Highlight( 06, 01, '          Country', supplier->country )
Highlight( 08, 01, '            Email', supplier->email )
Highlight( 09, 01, '        Home Page', supplier->homepage )
Highlight( 04, 54, 'Phone', supplier->phone )
Highlight( 05, 54, '  Fax', supplier->fax )
Highlight( 06, 54, 'Modem', supplier->data_no )
Highlight( 07, 54, '  San', supplier->san )
Highlight( 08, 52, 'T Order', supplier->teleorder )
Highlight( 09, 50, 'User Name', supplier->username )
Highlight( 10, 50, ' Password', supplier->password )
Highlight( 11, 01, 'Returns Address 1', supplier->raddress1 )
Highlight( 12, 01, '                2', supplier->raddress2 )
Highlight( 13, 01, '                3', supplier->rcity )
Highlight( 15, 01, '     Contact Name', supplier->contact )
Highlight( 16, 01, '   Our Account No', supplier->account )

if SYSNAME != 'BPOS'
 Highlight( 17, 01, '   Standard Disc.', supplier->std_disc )

else
 Highlight( 17, 03, 'Standard Markup', supplier->std_disc )

endif

Highlight( 15, 49, '         Returns (Y/N)', supplier->returns, 'y' )
Highlight( 16, 49, ' Minimum Order Value $', supplier->min_ord, '@b' )
Highlight( 17, 49, '       Lead Time (Wks)', supplier->lead_time, '@b' )
Highlight( 18, 49, '    Open Item Creditor', supplier->op_it, 'y' )
Highlight( 19, 49, ' Sell Price Method R/C', supplier->price_meth )
Highlight( 20, 55, '(R)etail- or (C)ost+', "" )
Highlight( 19, 01, '         Comments', supplier->comm1 )
Highlight( 20, 01, '                 ', supplier->comm2 )
Highlight( 21, 01, '  Doc. Sort Order', Suppdocsort( supplier->posort ) )
Highlight( 22, 01, 'Inv Line Item GST Incl', supplier->gst_inc, 'Y' )
// Highlight( 22, 01, '      Supply Type', supplier->supplytype )
Highlight( 23, 01, '    Currency Code', supplier->forexcode )

return nil

*

function suppdocsort ( mparm )
local aArray := { 'Undefined', 'id', 'Desc', 'alt_desc', 'Bin' }, mstr := 'ITAB'
return aArray[ at( mparm, mstr ) + 1 ]

*

function suppgethelp
Build_help( { {'Alt-A','Abstract'},{'F10', 'Edit'},{'F9','Supplier Movements'} } )
return nil

*

procedure supp_get
local getlist:={}, okalta:=setkey( K_ALT_A , nil ), okf10 := setkey( K_F10, nil )
if Secure( X_EDITFILES )
 Heading('Supplier Edit Screen')
 @ 02, 19 get supplier->name valid( non_stock( supplier->code ) )
 Highlight( 02, 53, 'Code->', supplier->code )
 @ 03, 19 get supplier->address1
 @ 04, 19 get supplier->address2
 @ 05, 19 get supplier->city
 @ 06, 19 get supplier->country
 @ 08, 19 get supplier->email
 @ 09, 19 get supplier->homepage
 @ 04, 60 get supplier->phone pict '@!'
 @ 05, 60 get supplier->fax pict '@!'
 @ 06, 60 get supplier->data_no pict '@!'
 @ 07, 60 get supplier->san pict '@!'
 @ 08, 60 get supplier->teleorder pict '@!' ;
          valid( empty( supplier->teleorder ) .or. dup_chk( supplier->teleorder, 'teleorde' ) )
 @ 09, 60 get supplier->username
 @ 10, 60 get supplier->password
 @ 11, 19 get supplier->raddress1
 @ 12, 19 get supplier->raddress2
 @ 13, 19 get supplier->rcity
 @ 15, 19 get supplier->contact
 @ 16, 19 get supplier->account pict 'XXXXXXXXXXXX'
 @ 17, 19 get supplier->std_disc pict '9999.99%'
 @ 15, 72 get supplier->returns pict 'y'
 @ 16, 72 get supplier->min_ord pict '999'
 @ 17, 72 get supplier->lead_time pict '999'
 @ 18, 72 get supplier->op_it pict 'y'
 @ 19, 72 get supplier->price_meth pict '!'  valid( supplier->price_meth $ 'RC' )
 @ 19, 19 get supplier->comm1
 @ 20, 19 get supplier->comm2
 @ 21, 01 say '  Doc. Sort Order'
 @ 21, 19 get supplier->posort pict '!' valid( supplier->posort $ 'ITAB' )
 @ 21, 20 say '<I>tem,<D>esc,<A>ltDesc,<N>atural'
 @ 22, 01 say 'Invoices GST Incl' get supplier->gst_inc pict 'Y'
 @ 23, 01 say '    Currency Code' get supplier->forexCode pict '@!' valid( Dup_Chk( supplier->forexCode, 'exchrate' ) )
 Rec_lock('supplier')
 read
 supplier->( dbrunlock() )

endif
setkey( K_ALT_A , okalta )
setkey( K_F10, okf10 )
Supp_say()
return

*

function non_stock ( cSuppCode)
if cSuppCode = 'MISC'
 Error('Supplier MISC is reserved by system for non stock items',12)

endif
return TRUE

*

function supphist
local sScreen:=Box_Save( 3, 2, 23, 77 ), mcode := trim(supplier->code) + '_SAL'
local totsal:=0, totrec:=0, totret:=0, totord := 0, totmov :=0, x, cField1
local asal[12], arec[12], aret[12], aord[12], mov:=0
afill( asal, 0 )
afill( arec, 0 )
afill( aret, 0 )
afill( aord, 0 )
@ 5, 3 say replicate( chr( 196 ), 73 )
@ 18, 3 say replicate( chr( 196 ), 73 )
@ 04,10 say 'Sales'
@ 04,20 say 'Received'
@ 04,34 say 'Returns'
@ 04,46 say 'Movement'
@ 04,68 say 'Orders'

select purhist
cField1 := fieldpos( 'jan' )

for x := 0 to 11
 @ x+6,3 say upper( substr( fieldname( cField1 + x ), 1, 1 ) ) + ;
             lower( substr( fieldname( cField1 + x ), 2, 2 ) )
next
Syscolor( 3 )
if dbseek( trim(supplier->code) + '_SAL' )
 for x := 0 to 11
  asal[x+1] := fieldget( cField1 + x )
  totsal += asal[ x+1 ]
  @ x+6, 09 say abs( asal[ x+1 ] ) pict '9999999'

 next
 @ 19,08 say totsal pict '99999999'

endif
if dbseek( trim(supplier->code) + '_REC' )
 for x := 0 to 11
  arec[x+1] := fieldget( cField1 + x )
  totrec += arec[ x+1 ]
  @ x+6, 22 say abs( arec[ x+1 ] ) pict '9999999'

 next
 @ 19,21 say totrec pict '99999999'

endif

if dbseek( trim(supplier->code) + '_RET' )
 for x := 0 to 11
  aret[x+1] := fieldget( cField1 + x )
  totret += aret[ x+1 ]
  @ x+6, 35 say abs( aret[ x+1 ] ) pict '9999999'

 next
 @ 19,34 say totret pict '99999999'
endif

for x := 0 to 11
 mov := asal[ x+1 ] + arec[ x+1 ] + aret[ x+1 ]
 totmov += mov
 @ x+6, 48 say mov pict '9999999'

next

@ 19,47 say totmov pict '99999999'

if dbseek( padr(supplier->code, 8 ) )
 for x := 0 to 11
  aord[x+1] := fieldget( cField1 + x )
  totord += aord[ x+1 ]
  @ x+6, 68 say abs( aord[ x+1 ] ) pict '9999999'

 next
 @ 19,67 say totord pict '99999999'

endif

syscolor( C_NORMAL )
select supplier
Highlight( 20, 04, 'Returns / Receiving Ratio = ', Ns( totret/(totrec/100) ) +'%' )
Highlight( 21, 04, '    Returns / Sales Ratio = ', Ns( totret/(totsal/100) ) +'%' )
Highlight( 22, 04, '  Receiving / Sales Ratio = ', Ns( totrec/(totsal/100) ) +'%' )
Error('')
Box_Restore( sScreen )
return nil
