/*

  Utilimpo - General Utilities for Import/Export of Data from BPOS including the CD Rom interfaces



   Last change:  APG  23 Aug 2004    9:03 pm

      Last change:  TG   16 Jan 2011    6:40 pm
*/

#include "bpos.ch"

#define FCI ' '               // Field Change Indicator

procedure U_Import

local mgo:=FALSE,choice,oldscr:=Bsave(), aArray
Center( 24, 'Opening files for File Import')
if Netuse( "ytdsales" )
 if Netuse( "dept" )
  if Netuse( "draft_po" )
   if Netuse( "supplier" ) 
    if master_use()
     set relation to field->id into ytdsales
     mgo := YES
    endif
   endif
  endif
 endif
endif
line_clear( 24 )
while mgo
 Brest( oldscr )
 Heading( 'Append System Menu' )
 aArray := {}
 aadd( aArray, { 'Utility', 'Return to Utility Menu' } )
 aadd( aArray, { 'Bisac', 'Add descs from a BISAC File' } )
 aadd( aArray, { 'CD ROM', 'CD ROM Descs from files' } )
 aadd( aArray, { 'Standby', 'Append from and clear Standby POS' } )
 choice := MenuGen( aArray, 09, 50, 'Import' )
 do case
 case choice < 2
  mgo := FALSE
 case choice = 2
  Bisac_impo()
 case choice = 3
  Impo_bt()
 case choice = 4
  Impo_stby()
 endcase
enddo
close databases
return
*

procedure bisac_impo
local oldscr := Bsave(),getlist:={},bisac_file,lAnswer
local m_handle,mkey,indisp,dbfile,merror,msupp,mscr,newrec,mdrive,trailer
local mfile, mcount, line, ord_date, mdept, msel, mbrand, mdate1, mdate2
local myear, mlast, mfirst, filehead, mprice, mdesc, mrec, mrecs, mstr
local dump_flag, append_all, mchoice, aArray, nport, i:=0, box, x, nwait, nuser

while TRUE
 Brest( oldscr )
 Heading( 'Bisac File Import' )
 aArray := {}
 aadd( aArray, { 'Import', 'Return to Import Menu' } )
 aadd( aArray, { 'Dial-Up', 'Use Procomm to obtain file' } )
 aadd( aArray, { 'Edit', 'Edit Update file' } )
 aadd( aArray, { 'Produce', 'Produce Bisac Format Floppy' } )
 mchoice := Menugen( aArray, 11, 51, 'Bisac' )
 if mchoice < 2
  exit
 endif
 do case
 case mchoice = 2
  Heading("Select Supplier for BISAC File")
  mscr := Bsave( 06,02,08,36 )
  select supplier
  msupp:=space( SUPP_CODE_LEN )
  @ 07,03 say 'Supplier Code for BISAC file' get msupp pict '@!'
  read
  Brest( mscr )
  if updated()
   if !dbseek( msupp )
    Error( "Supplier Code NOT on File",12 )
   else
    if empty(supplier->data_no)
     Error("No Data Number Exists For " + trim(supplier->name),12)
    else
     m_handle := fcreate(Oddvars( SYSPATH ) + "bisac\datafile.txt")
     if m_handle = -1
      Error("Cannot create Data record",12)
     else
      mrec := 'G' + padr( substr( supplier->name, 1, 30 ), 70 ) + CRLF +;
           padr( supplier->data_no, 70 ) + CRLF + ;
           padr( Oddvars( SYSPATH ) + "bisac\0.bsc", 70 ) + CRLF + ;
           padr( supplier->code, 70 ) + CRLF + ;
           padr( supplier->username, 70 ) + CRLF + ;
           trim( supplier->password ) + CRLF + ;
           padr( supplier->san, 70 ) + CRLF
      fwrite( m_handle,mrec )
      fclose( m_handle )
      Bsave( 04, 10, 06, 70 )
      Center( 05,'Loading Teleorder Program .... Please Wait' )
      Shell( "torder" )
     endif
    endif
   endif
  endif
 case mchoice = 3
  Heading("Select Supplier for BISAC File")
  mscr := Bsave( 06,02,08,36 )
  msupp := space( SUPP_CODE_LEN )
  @ 07,03 say 'Supplier Code for BISAC file' get msupp pict '@!';
          valid( Dup_chk( msupp , "supplier" ) )
  read
  Brest( mscr )
  if updated()
   Bsave( 02, 08, 14, 72 )
   Syscolor( 3 )
   Center( 03,'Append BISAC Records from ' + trim( Lookitup( 'supplier', msupp ) ) )
   Syscolor(1)
   if Netuse( "bis_titl", EXCLUSIVE )
    lAnswer := YES
    if lastrec() > 2
     lAnswer := NO
     @ 5,10 say 'Your current BISAC Edit File already contains records'
     @ 6,10 say 'Do you wish to delete them and reappend new ones' get lAnswer pict 'Y'
     read
    endif
    if lAnswer

     zap
     bisac_file := GetFile()

     if empty( bisac_file )
      bis_titl->( dbclosearea() )
      loop
     endif
     zap
     Center( 07,'-=< Creating BISAC edit from '+lower( bisac_file ) ;
            +' - Please Wait >=-' )
     append from ( bisac_file ) sdf

    endif
    ordsetfocus(  )
    dump_flag := YES
    append_all := FALSE
    mrecs := bis_titl->( lastrec() )
    bis_titl->( dbgotop() )
    while !bis_titl->( eof() )
     Center(08,'Checking Bisac file against Master File - Record #'+Ns(Recno()))
     if bis_titl->type = '1'
      mdesc := substr( bis_titl->desc,1,30 )
      if empty( bis_titl->brand )
       mbrand := upper( substr( strtran( bis_titl->publisher,' ' ),1,6 ) )
      else
       mbrand := upper( substr( strtran( bis_titl->brand,' ' ),1,6 ) )
      endif
      mrec := recno()
      bis_titl->( dbskip() )
      if bis_titl->type = '3'
       mdesc := bis_titl->media+bis_titl->desc_fci+bis_titl->desc+bis_titl->alt_desc
      endif
      goto mrec
      do case
      case upper( substr( mdesc, 1, 4 ) ) = 'THE '
       mdesc := trim( substr( mdesc, 5, len( mdesc ) -5 ) ) + ' ' + substr( mdesc, 1, 3 )
      case upper( substr( mdesc, 1, 2 ) ) = 'A '
       mdesc := trim( substr( mdesc, 3, len( mdesc ) -3 ) ) + ' ' + substr( mdesc, 1, 1 )
      endcase
      select master
      ordsetfocus( BY_ID )
      if !( !dump_flag .and. substr( bis_titl->id, 1, 6 ) = '000000' )
       if !Codefind( CalcAPN( '978' + bis_titl->id ) )
        Add_rec()
        mprice := val(bis_titl->price)/100
        master->id := CalcAPN('978' + bis_titl->id)
        master->desc := low_case( mdesc )
        master->supp_code := msupp
        master->alt_desc := upper( strtran( bis_titl->alt_desc, '/', ' ' ) )
        master->retail := mprice
        master->sell_price := mprice-( mprice/100*Bvars( B_STD_DISC ) )
        master->cost_price := mprice-( mprice/100*supplier->std_disc )
        master->brand := mbrand
        master->year := substr( bis_titl->pub_date,1,4 )
        master->binding := bis_titl->binding
        master->minstock := Bvars( B_REORDQTY )
        master->sale_ret := Bvars( B_SALERET )
        master->entered := Bvars( B_DATE )
        master->status := bis_titl->status
        master->department := bis_titl->audience
        master->edition := bis_titl->edition
        if append_all
         if inkey() != 0
          append_all := FALSE
         else
          Highlight( 08,50,'# Records',Ns( bis_titl->(lastrec()) ) )
         endif
        else
         itemdisp( TRUE, @dump_flag, @append_all )
        endif
        if lastkey() = K_ESC
         Del_rec( 'master' )
        endif
        master->( dbrunlock() )
       endif
      endif
     endif
     select bis_titl
     bis_titl->( dbskip() )
    enddo
    bis_titl->( dbclosearea() )
   endif
  endif
 case mchoice = 4
  Heading("Create BISAC new Release File")
  mfirst:=1
  mlast:=master->(lastrec())
  myear:=space(4)
  mdate1:=Bvars( B_DATE )
  mdate2:=mdate1+1
  mbrand:=space(6)
  msupp:=space( SUPP_CODE_LEN )
  mdept:=space(3)
  Heading( "Records to select" )
  aArray := {}
  aadd( aArray, { 'All', 'Retrieve all records in Database' } )
  aadd( aArray, { 'Selected Rec', 'Retrieve selected Records' } )
  aadd( aArray, { 'Date Entered', 'Retrieve using Date records Entered' } )
  aadd( aArray, { 'Year', 'Retrieve records matching year fields' } )
  aadd( aArray, { 'Imprint', 'Retrieve records using Imprint' } )
  aadd( aArray, { 'Supplier', 'Retrieve records using Supplier' } )
  aadd( aArray, { 'Department', 'Retrieve records using Department' } )
  aadd( aArray, { 'Customer', 'Retrieve records using Customer Purchases' } )
  msel := MenuGen( aArray, 09, 10, 'Bisac Select' )

  do case
  case msel = 0
   loop

  case msel = 2
   mscr:=Bsave( 08, 02, 13, 40 )
   Highlight( 09, 03, 'Records in Master File' , Ns( master->( reccount() ) ) )
   @ 10,03 say 'First record to retrieve' get mfirst pict '99999'
   @ 11,03 say ' Last Record to retrieve' get mlast pict '99999' ;
           valid( mlast <= master->( lastrec() ) )
   read
   Brest( mscr )
   if !updated()
    loop
   endif

  case msel = 3
   mscr := Bsave( 09, 03, 12, 35 )
   @ 10,04 say 'Start of record entry' get mdate1
   @ 11,04 say '   End date of record' get mdate2
   read
   Brest( mscr )
   if !updated()
    loop
   endif

  case msel = 4
   mscr:=Bsave( 09, 10, 11, 30 )
   @ 10,12 say 'Year code' get myear pict '!!!!'
   read
   Brest( mscr )
   if !updated()
    loop
   endif

  case msel = 5
   mscr := Bsave( 09, 10, 11, 30 )
   @ 10,12 say 'Imprint' get mbrand pict '@!' valid( Dup_chk( mbrand, "brand" ) )
   read
   Brest( mscr )
   if !updated()
    loop
   endif

  case msel = 6
   mscr := Bsave( 09, 10, 11, 30 )
   @ 10,12 say 'Supplier' get msupp pict '@!' valid( Dup_chk( msupp, "supplier" ) )
   read
   Brest( mscr )
   if !updated()
    loop
   endif

  case msel = 7
   mscr := Bsave( 09, 10, 11, 30 )
   @ 10,12 say 'Department' get mdept pict '@!' valid( Dup_chk( mdept, "dept" ) )
   read
   Brest( mscr )
   if !updated()
    loop
   endif

  case msel = 8
   if CustFind( FALSE )   // All customers
    if !salehist->( dbseek( customer->key ) )
     Error( 'No Sales History found for customer' + left( customer->name, 25 ), 12 )
     loop
    else

     aArray := {}
     aadd( aArray, { 'id', 'c', 12, 0 } )
     dbcreate( Oddvars( TEMPFILE ), aArray )

     if netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, 'btemp' )
      indx( 'id', Oddvars( TEMPFILE ), , 'id' )
      while salehist->key = customer->key .and. !salehist->( eof() )
       if !btemp->( dbseek( salehist->id ) )
        Add_rec( 'btemp' )
        btemp->id := salehist->id
       endif
       salehist->( dbskip() )
      enddo
     endif
    endif
   endif

  endcase
  mscr:=Bsave( 09, 10, 12, 35 )
  @ 11,11 say 'Records Selected'
  m_handle := fcreate( Oddvars( SYSPATH ) + 'bisac.new' )
  if m_handle = -1
   Error( "Cannot create " + bisac_file, 12 )
  else
   ord_date := substr(Ns(year(Bvars( B_DATE ))),3,2)+padl(month(Bvars( B_DATE )),2,'0');
            +padl(day(Bvars( B_DATE )),2,'0')
   filehead := '**HEADER**'+ord_date+substr(BPOSCUST,1,10)+Bvars( B_SAN )+'00000010**PUBSTAT**'
   filehead += CRLF
   fwrite( m_handle, filehead )
   if msel < 8
    select master
    ordsetfocus( NATURAL )
    if msel != 2
     dbgotop()
    else
     go mfirst
    endif
   else
    select btemp
    dbgotop()
    set relation to btemp->id into master
   endif
   mcount := 0

   Highlight( 10, 11, 'Total Records', Ns( lastrec() ) )

   while !eof() .and. if( msel = 8, TRUE, if( msel = 2 , recno() <= mlast, TRUE ) ) .and. Pinwheel()
    if ( msel = 1 ) .or. ( msel = 2 ) .or. ;
       ( msel = 3 .and. master->entered > mdate1 .and. master->entered < mdate2 ) .or.;
       ( msel = 4 .and. master->year = myear ) .or. ;
       ( msel = 5 .and. master->brand = mbrand ) .or. ;
       ( msel = 6 .and. master->supplier1 = msupp ) .or. ;
       ( msel = 7 .and. master->department = mdept ) .or. ;
       ( msel = 8 )
     line := padl( substr( idcheck( master->id ),1,10),10)
     line += '1N B '+substr( master->desc,1,30)+' '+padr(substr(upper(master->alt_desc),1,30),30,' ')
     line += ' A'+FCI+padl( int( master->retail*100) , 7 , '0' )+FCI+master->year+'00'
     line += FCI + padl( substr( LookItup( "brand" , master->brand ),1,10),10 )
     line += FCI + padl( substr( LookItup( "brand" , master->brand ),1,10),14 )
     line += FCI + '   '                           // number of volumes
     line += FCI + padl( master->edition, 2 )         // edition
     line += FCI + master->binding
     line += FCI + '   '                           // Volume Number
     line += FCI + padl( int( master->retail * 100 ), 7 ,'0' ) // New Price
     line += FCI + '      '                        // New Price Effective date
     line += FCI + '   '                           // Audience Type
     line += FCI + master->status                  // Status
     line += FCI + master->year + '00'             // Available Date
     line += FCI + space(8)     // Alternate id ( Library of Congress # )
     line += CRLF
     mcount++
     @ 11,27 say mcount pict '999999'
     fwrite( m_handle, line )
    endif
    skip  // This skip is devious as it might be skipping either the btemp or master so don't alias it
   enddo
   trailer := "**TRAILER**" + ord_date + '000000' + padl( mcount ,6, '0' ) + "**PUBSTAT*" +;
              space(2) + padr('Created by BPOS - 02 637-7366',220) + CRLF
   fwrite( m_handle, trailer )
   fclose( m_handle )
   
   if select( 'btemp' ) != 0
    btemp->( dbclosearea() )
   endif

   if mcount > 0 

    aArray := directory( Oddvars( SYSPATH ) + 'bisac.new' )
    if aArray[ 1, 2 ] > 1400000
     Error( 'This output file if bigger than one 1.44M floppy', 12, , 'Pkzip + DOS Backup will be used to create floppy disks' )
     if Isready( 12 )
      @ 12,0 clear to 24,79
      mstr := "pkzip -ues bisac " + Oddvars( SYSPATH )+ "bisac.new"
      if Shell( mstr )
       aArray := Directory( Oddvars( SYSPATH ) + 'bisac.zip' )
       if aArray[ 1, 2 ] > 1400000
        Bsave( 2, 10, 4, 72 )
        Center(3,'Loading Backup to Floppy Program ...Please Wait')
#ifndef __HARBOUR__
        mdrive := chr( getdriv() ) + ':'
        @ 12,0 clear to 24,79
        if Shell( "backup " + mdrive + Oddvars( SYSPATH )+"bisac.zip a:/f" )
         Audit("AccBakDsk")
        endif
#endif
       else
        Heading("Select Drive for Bisac Files")
        mscr := Bsave( 09, 10, 13, 14 )
        @ 10,11 prompt 'A:'
        @ 11,11 prompt 'B:'
#ifndef __HARBOUR__
        @ 12,11 prompt chr( getdriv() ) + ':'
#endif
        menu to mdrive
        Brest( mscr )
        if lastkey() != K_ESC
#ifndef __HARBOUR__
         mdrive := if( mdrive=1, 'A:', if( mdrive=2, 'B:', chr( getdriv() ) + ':\bisac\' ) )
#endif
         bisac_file := mdrive + '\bisac.zip'
         lAnswer := YES
         while lAnswer
          mscr := Bsave( 9, 02, 12, 50 )
          @ 10,03 say 'Write disk file to ' + bisac_file get lAnswer pict 'y'
          read
          if lAnswer
           @ 11,04 say 'Writing File !'
           m_handle := fopen( mdrive+'\null:')
           if ferror() = 3
            Error( "Drive " + mdrive + ' is not ready' , 12 )
           else
            copy file ( Oddvars( SYSPATH )+'bisac.zip' ) to ( bisac_file )
            if file( Oddvars( SYSPATH ) + 'pkunzip.exe' )
             copy file ( Oddvars( SYSPATH ) + 'pkunzip.exe' ) to ( mdrive )
            endif
           endif
          endif
         enddo
        endif
       endif
      endif
     endif
    else

     Heading( 'Write out BISAC records to production disks' )
     mfile := 'bisac   .new'
     mscr:=Bsave( 6, 02, 8, 45 )
     @ 7,3 say 'File name for Bisac File' get mfile pict '@K NNNNNNNN.NNN'
     read
     Brest( mscr )
     if lastkey() != K_ESC
      Heading("Select Drive for Bisac Files")
      mscr := Bsave( 09, 10, 13, 14 )
      @ 10,11 prompt 'A:'
      @ 11,11 prompt 'B:'
#ifndef __HARBOUR__
      @ 12,11 prompt chr( getdriv() ) + ':'
#endif
      menu to mdrive
      Brest( mscr )
      if lastkey() != K_ESC
#ifndef __HARBOUR__
       mdrive := if( mdrive=1, 'A:', if( mdrive=2, 'B:', chr( getdriv() ) + ':\bisac\' ) )
#endif
       bisac_file := mdrive + strtran( mfile, ' ' )
       lAnswer := YES
       while lAnswer
        mscr := Bsave( 9, 02, 12, 50 )
        @ 10,03 say 'Write disk file to '+bisac_file get lAnswer pict 'y'
        read
        if lAnswer
         @ 11,04 say 'Writing File !'
         m_handle := fopen( mdrive+'\null:')
         if ferror() = 3
          Error( "Drive " + mdrive + ' is not ready' , 12 )
         else
          copy file ( Oddvars( SYSPATH )+'bisac.new' ) to ( bisac_file )
         endif
        endif
       enddo
      endif
     endif
    endif
   endif
  endif
 endcase
enddo
return
*

procedure impo_bt 

local oldscr := Bsave(), mform, mcomment, mprice, mndate
local mauthor, mdesc, sID, mpos, mdate, mthstr, mpub, newrec, mabs, mdept, msupp, mrec
local mchoice, mexec, mscr, mret, mappe, getlist:={}, mbrand, mexchg_pr, mexchg, mrecs
local bt_file, lAnswer, mcat, mgo, dump_flag, mp1, mp2, aArray
local no_append := ( procname( 1 ) = 'CODEFIND' ), mfile

while TRUE

 Brest( oldscr )
 Heading( SYS_TYPE + ' CD-ROM Interfaces' )
 Bsave( 12, 51, 19, 63 )
 aArray := {}
 aadd( aArray, { 'Import', 'Return to Import Menu' } )
 aadd( aArray, { 'Bookfind', 'Run Bookfind Cd-Rom' } )
 aadd( aArray, { 'Whitaker', 'Whitakers British BIP CD' } )
 aadd( aArray, { 'Global', 'Global Items in Print' } )
 aadd( aArray, { 'Bowker', 'Bowkers American BIP CD' } )
 mchoice := MenuGen( aArray, 12, 51, 'CD ROM' )

 if mchoice < 2
  exit

 else
  do case
  case mchoice = 2
   mscr := Bsave( 4, 10, 8, 70 )
   mexec := NO
   @ 05, 12 say 'Run the Baker & Taylor CD-ROM Program?' get mexec pict 'y'
   Highlight( 06, 12, 'Download Format is', 'Full Delimited With V1.03' )
   read
   if lastkey() != K_ESC
    if mexec
     Center( 7, 'Loading Baker & Taylor CD-ROM Program' )
     Shell( "baker" )
    endif
    if no_append  // Sorry no Append from codefind
     loop       
    endif 
    Brest( mscr )
#ifndef UNINT     
    if !file( "\baker\baker.out" ) 
#else      
    if !file( "c:\baker.out" ) 
#endif
     Error( "No \baker\baker.out input file found",12 )
    else
     Heading( "Append descs from Baker & Taylor File" )

     aArray := {}
     aadd( aArray, { 'id', 'c', 12, 0 } )
     aadd( aArray, { 'desc', 'c', 35, 0 } )
     aadd( aArray, { 'alt_desc', 'c', 20, 0 } )
     aadd( aArray, { 'binding', 'c', 2, 0 } )
     aadd( aArray, { 'publisher', 'c', 20, 0 } )
     aadd( aArray, { 'sell_price', 'n', 10, 2 } )
     aadd( aArray, { 'year', 'c', 10, 0 } )
     aadd( aArray, { 'status', 'c', 3, 0 } )
     dbcreate( Oddvars( TEMPFILE ), aArray )

     if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, , 'bt' ) 
      Bsave( 02, 08, 15, 72 )
      select supplier
      locate for 'BAKER' $ supplier->name .and. 'TAYLOR' $ supplier->name
      if found()
       msupp := padr( supplier->code, 4 )
      else
       msupp := space( SUPP_CODE_LEN )
      endif
      @ 03,10 say 'Supplier Code for Baker & Taylor' get msupp pict '@!' ;
              valid( dup_chk( msupp, 'supplier' ) )
      read
      if lastkey() = K_ESC
       mgo := NO
       Bsave( 02,08,14,72 )
      else
       @ 3,09 say space( 58 )
       Syscolor( 3 )
       Center( 03, 'Append Baker & Taylor Records from ' + trim( supplier->name ) )
       Syscolor( 1 )
#ifdef UNINT         
       bt_file := "c:\baker.out                "
#else
       bt_file := "\baker\baker.out                  "
#endif         
       @ 05,10 say 'Baker & Taylor file name' get bt_file pict '@!K'
       read
       if lastkey() = K_ESC
        loop
       endif
       if !file( bt_file )
        Error( 'File ' + trim( bt_file ) + ' not Found',12)
       else
        select bt
        lAnswer := YES
        if lastrec() > 2
         lAnswer := Isready( 7, 10, 'File contains records - clear & reappend ?' )
        endif
        mexchg := Sysinc( "USD", "G" )
        mdept := space( 3 )
        mcat := space( 6 )
        @ 09,10 say 'Current Exch Rate $US1 =' get mexchg pict '999.9999'
        @ 09,44 say if( TRUE,'$NZ','$AUS')
        read
        if lAnswer
         zap
         Center(13,'-=< Creating Baker & Taylor Conversion File >=-')
         append from ( bt_file ) delimited
        endif
        mrecs := lastrec()
        dump_flag := YES
        bt->( dbgotop() )
        while !bt->( eof() )
         mrec := recno()
         if !master->( dbseek(  CalcAPN( '978' + bt->id ) ) )
          Add_rec('master')
          mexchg_pr := Zero( mexchg, bt->sell_price )
          master->id := CalcAPN('978' + bt->id)
          master->desc := low_case(bt->desc)
          master->supp_code := msupp
          master->alt_desc := bt->alt_desc
          master->brand := bt->publisher
          master->binding := bt->binding
          master->sell_price := if(mexchg!=0,mexchg_pr,0)
          master->cost_price := if(mexchg!=0,mexchg_pr-(mexchg_pr*(supplier->std_disc/100)),0)
          master->minstock := 1
          master->comments := '$US' + Ns( bt->sell_price )
          master->department := mdept
          master->status := bt->status
          master->entered := Bvars( B_DATE )
          master->year := substr( bt->year,1,2 ) + substr( bt->year,4,2 )
          itemdisp( TRUE )
          if lastkey() = K_ESC
           Del_rec( 'master', UNLOCK )
          endif
         endif
         select bt
         bt->( dbskip() )
        enddo
       endif
      endif
      bt->( dbclosearea() )
     endif
     Kill("\baker\baker.out")
    endif
   endif

  case mchoice = 3
   if !file( Oddvars( SYSPATH ) + "bookfind.bat" )
    Error( "File " + Oddvars( SYSPATH ) + "Bookfind.bat not found", 12 )
   else
    mexec := NO
    Heading( "Bookfind BIP System" )
    mscr := Bsave( 4, 10, 8, 70 )
    @ 5,12 say 'Run Bookfind CD-ROM Program' get mexec pict 'y'
    read
    if lastkey() != K_ESC
     if mexec
      Center( 6,'Loading Bookfind BIP CD-ROM Program' )
      Shell( "bookfind" )
     endif
     if !no_append .and. file( "\bookfind\bookfind.out" )
      if Isready( 7, 12, 'Append Download descs from Bookfind BIP' )

       aArray := {}
       aadd( aArray, { 'tag', 'c', 3, 0 } )
       aadd( aArray, { 'line', 'c', 3, 0 } )
       dbcreate( Oddvars( TEMPFILE ), aArray )

       if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, , 'bookfind' ) 

        zap
        append from ( "\bookfind\bookfind.out" ) sdf
        dbgotop()

        while !bookfind->( eof() )
         if empty(bookfind->tag)
          newrec := YES
          bookfind->( dbskip() )
         endif
         sID := ''
         mdesc := ''
         mauthor := ''
         mbrand := ''
         mpub := ''
         mdate := ''
         mcomment := ''
         mprice := ''
         mform := ''
         mabs := ''
         while !bookfind->( eof() ) .and. !empty(bookfind->tag)
          do case
          case bookfind->tag = 'ON'
           sID := bookfind->line
          case bookfind->tag = 'AK'
           mauthor := bookfind->line
          case bookfind->tag = 'TI'
           mdesc := bookfind->line
          case bookfind->tag = 'PU'
           mbrand := upper( bookfind->line )
          case bookfind->tag = 'PY'
           mdate := bookfind->line
          case bookfind->tag = 'CL'
           mcomment := bookfind->line
          case bookfind->tag = 'PR'
           mprice := bookfind->line
          case bookfind->tag = 'BC'
           mform := bookfind->line
          case bookfind->tag = 'DE'
           mabs += ' ' + trim( bookfind->line )
           bookfind->( dbskip() )
           while empty( bookfind->tag ) .and. !bookfind->( eof() )
            mabs += ' '+ trim( bookfind->line )
            bookfind->( dbskip() )
           enddo
           bookfind->( dbskip( -1 ) )
          case bookfind->tag = 'DL'
           mabs += ' ' + trim( bookfind->line )
           bookfind->( dbskip() )
           while empty( bookfind->tag ) .and. !bookfind->( eof() )
            mabs +=  ' ' + trim( bookfind->line )
            bookfind->( dbskip() )
           enddo
           bookfind->( dbskip( -1 ) )
          endcase
          bookfind->( dbskip() )
         enddo
         if !Codefind( sID )
          Add_rec( 'master' )
          mthstr := "JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"
          mpos := at( upper( substr( mdate,1,3 ) ),mthstr )
          master->id := CalcAPN( '978' + sID )
          master->desc := low_case( mdesc )
          master->alt_desc := mauthor
          master->brand := mbrand
          master->supp_code := Lookitup( "brand", mbrand, "supp_code" )
          master->year := mdate
          master->minstock := 1
          master->binding := mform
          master->comments := if(!empty( mprice ),trim(mprice)+' ','')+trim(mcomment)+' '+mform
          master->entered := Bvars( B_DATE )
          cls
          Heading( 'Bookfind Desc Editing screen' )
          Highlight( 02,03,'      Code',master->id )
          Highlight( 02,35,'id',if(substr(master->id,1,3)='978', idcheck( master->id ), 'No id' ) )
          @ 04,03 say '     Desc' get master->desc pict '@S35'
          @ 05,03 say '    Author' get master->alt_desc pict '@!'
          @ 07,03 say '   Imprint' get master->brand pict '@!' valid( Dup_chk( master->brand, "brand" ) )
          Highlight( 07,22,'Full Imprint name', mbrand )
          @ 08,03 say '  Supplier' get master->supp_code pict '@!' valid( dup_chk( master->supp_code, "supplier" ) )
          Highlight(08,20,'','<-- Must be filled in or Record will be Deleted')
          Highlight(09,10,'','This Supplier Code is Extracted from the Imprint file')
          Highlight(10,10,'','It may not be accurate !')
          @ 11,03 say '   Binding' get master->binding pict '@!' ;
                  valid( Dup_chk( master->binding,"Binding" ) )
          @ 11,25 say 'Department' get master->department pict '@!' ;
                  valid( dup_chk( master->department,"dept"))
          @ 13,03 say 'Cost Price' get master->cost_price pict '9999.99'
          @ 13,25 say 'Sell Price' get master->sell_price pict '9999.99'
          @ 13,50 say '       RRP' get master->retail pict '9999.99'
          @ 15,03 say ' Min Stock' get master->minstock pict '999'
          @ 15,25 say ' Firm Sale' get master->sale_ret pict 'Y'
          @ 17,25 say '      Year' get master->year
          @ 19,03 say '  Comments' get master->comments
          Highlight(21,03,'','Hit <PgUp> to abort Append')
          read
          if lastkey() = K_PGUP
           bookfind->( dbgobottom() )
          endif
          if lastkey() == K_ESC .or. empty( master->supp_code )
           Error("No Supplier Entered or Esc Pressed - Record Deleted",12)
           master->( dbdelete() )
          else
#ifndef __HARBOUR__
           if !empty( mabs )
            v_select( 0 )
            if V_use( Oddvars( SYSPATH ) + 'master' ) == -1
             Error("Cannot Open master Abstract File, Error " + Ns( V_error() ),12)
            else
             master->abs_ptr := V_replace( mabs, master->abs_ptr )
             v_close()
            endif
           endif
#endif
          endif
          master->( dbrunlock() )
         endif
         bookfind->( dbskip() )
        enddo
        bookfind->( dbclosearea() )
       endif
       Kill( "\bookfind\bookfind.out" )
      endif
     endif
     Brest( mscr )
    endif
   endif

  case mchoice = 4
   if !file( Oddvars( SYSPATH )+"whitaker.bat" )
    Error( "File "+Oddvars( SYSPATH )+"Whitaker.bat not found - cannot run Bookbank",12 )
   else
    mexec := NO
    Heading( "Whitakers BBIP System" )
    mscr := Bsave( 4, 10, 8, 70 )
    @ 5,12 say 'Run Whitakers British BIP CD-ROM Program' get mexec pict 'y'
    read
    if lastkey() != K_ESC
     if mexec
      Center( 6,'Loading Whitakers BBIP CD-ROM Program' )
      Shell( "whitaker" )
     endif
#ifdef UNINT     
     if file( "c:\whitaker.out" )
#else
     if file( Oddvars( SYSPATH ) + "whitaker.out" )
#endif
      if !no_append .and. Isready( 7, 12, 'Append Download descs from Whitaker BBIP' )

       aArray := {}
       aadd( aArray, { 'space', 'c', 6, 0 } )
       aadd( aArray, { 'tag', 'c', 3, 0 } )
       aadd( aArray, { 'space2', 'c', 2, 0 } )
       aadd( aArray, { 'line', 'c', 2, 0 } )
       dbcreate( Oddvars( TEMPFILE ), aArray )

       if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, , 'whit' ) 
        zap
#ifdef UNINT
        append from ( "c:\whitaker.out" ) sdf
#else
        append from ( Oddvars( SYSPATH ) + "whitaker.out" ) sdf
#endif
        whit->( dbgotop() )

        while !whit->( eof() )
         if empty( whit->tag )
          newrec := YES
          whit->( dbskip() )
         endif
         sID := ''
         mdesc := ''
         mauthor := ''
         mpub := ''
         mdate := ''
         mcomment := ''
         mprice := ''
         mform := ''
         mbrand := ''
         while !whit->( eof() ) .and. !empty( whit->tag )
          do case
          case whit->tag = '001'
           sID := whit->line
          case whit->tag = '100'
           mauthor := whit->line
          case whit->tag = '245'
           mdesc := whit->line
          case whit->tag = '260'
           mbrand := whit->line
          case whit->tag = '262'
           mdate := whit->line
          case whit->tag = '979'
           mcomment := whit->line
          case whit->tag = '350'
           mprice := whit->line
          case whit->tag = '300'
           mform := whit->line
          endcase
          whit->( dbskip() )
         enddo
         whit->( dbskip( -1 ) )
         select master
         if !Codefind(sID)
          Add_rec( 'master' )
          mthstr := "JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"
          mpos := at( upper( substr( mdate, 1, 3 ) ), mthstr )
          mndate := padr( int(( mpos+2 )/3 ), 2 ) + substr( mdate, 5, 2 )
          master->id := CalcAPN( '978' + sID )
          master->desc := low_case( mdesc )
          master->alt_desc := mauthor
          master->brand := mbrand
          master->year := mndate
          master->minstock := 1
          master->comments := if(!empty( mprice ),trim(mprice)+' ','')+trim(mcomment)+' '+mform
          master->entered := Bvars( B_DATE )
          cls
          Heading( 'Whitakers Desc Editing screen' )
          Highlight( 02,03,'      Code',master->id )
          Highlight( 02,35,'id',if(substr(master->id,1,3)='978',;
                     idcheck(master->id),'No id') )
          @ 04,03 say '     Desc' get desc pict '@S35'
          @ 05,03 say '    Author' get author pict '@!'
          @ 07,03 say '   Imprint' get brand pict '@!' ;
                  valid( Dup_chk( master->brand,"brand" ) )
          Highlight( 07,20,'Full Imprint name', mbrand )
          @ 08,03 say '  Supplier' get supp_code pict '@!';
                  valid( dup_chk(master->supp_code,"supplier"))
          Highlight(08,20,'','<-- Must be filled in or Record will be Deleted')
          @ 11,03 say '   Binding' get binding pict '@!' ;
                  valid( Dup_chk( master->binding,"Binding" ) )
          @ 11,25 say 'Department' get department pict '@!' ;
                  valid( dup_chk( master->department,"dept"))
          @ 13,03 say 'Cost Price' get cost_price pict '9999.99'
          @ 13,25 say 'Sell Price' get sell_price pict '9999.99'
          @ 13,50 say '       RRP' get retail pict '9999.99'
          @ 15,03 say ' Min Stock' get minstock pict '999'
          @ 15,25 say ' Firm Sale' get sale_ret pict 'Y'
          @ 17,25 say '      Year' get year
          @ 19,03 say '  Comments' get comments
          Highlight(21,03,'','Hit <PgUp> to abort Append')
          read
          if lastkey() = K_PGUP
           select whit
          go bott
           select master
          endif
          if lastkey() == K_ESC .or. empty( master->supp_code )
           Error("No Supplier Entered or Esc Pressed - Record Deleted",12)
           master->( dbdelete() )
          endif
         endif
         whit->( dbskip() )
        enddo
        whit->( dbclosearea() )
       endif
#ifdef UNINT       
       Kill( "c:\whitaker.out" )
#else
       Kill( Oddvars( SYSPATH )+"whitaker.out" )
#endif
      endif
     endif
     Brest( mscr )
    endif
   endif

  case mchoice = 5 .or. mchoice = 6
   mfile := if( mchoice = 5, 'Global', 'Bowker' )
   if !file( Oddvars( SYSPATH ) + mfile + '.bat' )
    Error( "File " + Oddvars( SYSPATH ) + mfile + '.bat not found - Cannot run BIP program.', 12 )
   else
    mscr := Bsave( 2, 10, 4, 70 )
    Center( 3, 'Loading ' + mfile + ' BIP CD-ROM Program' )
    Shell( mfile )

    mfile := Directory( "\bowker\*.out" ) 

    if len( mfile ) != 0 .and. !no_append ;
       .and. Isready( 7, 12,'Append Download descs from GBIP' )

     mfile := Getfile( "*.out", "\bowker\" )       

     aArray := {}
     aadd( aArray, { 'space', 'c', 1, 0 } )
     aadd( aArray, { 'marker', 'c', 1, 0 } )
     aadd( aArray, { 'mcount', 'n', 2, 0 } )
     aadd( aArray, { 'space3', 'n', 1, 0 } )
     aadd( aArray, { 'tag', 'c', 3 } )
     aadd( aArray, { 'space4', 'c', 1, 0 } )
     aadd( aArray, { 'garbage', 'c', 2, 0 } )
     aadd( aArray, { 'space5', 'c', 2, 0 } )
     aadd( aArray, { 'detail', 'c', 2, 0 } )
     dbcreate( Oddvars( TEMPFILE ), aArray )

     if Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, , 'marc' ) 

      zap
      append from ( mfile ) sdf

      dbgotop()

      locate for marc->mcount = 1
      while !marc->( eof() )
       newrec := YES
       sID := mdesc := mauthor := mbrand := mpub := mdate :=  mcomment := mprice := ''
       mform := mabs := msupp := ''
       marc->( dbskip() )
       while !marc->( eof() ) .and. marc->mcount != 1
        if newrec
         marc->( dbskip( -1 ) )
         newrec := FALSE
        endif 
        do case
        case marc->tag = '020'
         sID := trim( strtran( substr( marc->detail, 1, at( '^c' ,marc->detail ) ),'-',"" ) )
         mprice := substr( marc->detail, at( '^c', marc->detail ) +3, 10 )
        case marc->tag = '100'
         mauthor := marc->detail
        case marc->tag = '245'
         mdesc := strtran( marc->detail,'^b','' )
        case marc->tag = '260'
         mp1 := at( '^b', marc->detail ) + 3
         mp2 := at( '^c', marc->detail )
         mbrand := upper( trim( substr( marc->detail, mp1, mp2 - mp1 ) ) )
         mdate := alltrim( substr( marc->detail, at( '^c', marc->detail ) + 3, 8 ) )
         mdate := substr( mdate, 1, 2 ) + substr( mdate, 6, 2 )
        case marc->tag = '300'
         mcomment := stuff( marc->detail, 1, '^b' )
        endcase
        marc->( dbskip() )
       enddo
       if !Codefind( sID )
        Add_rec( 'master' )
        mthstr := "JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"
        mpos := at( upper( substr( mdate,1,3 ) ),mthstr )
        master->id := CalcAPN( '978' + sID )
        master->desc := low_case( mdesc )
        master->alt_desc := mauthor
        master->brand := upper( strtran( mbrand, ' ', '' )  )
        master->supp_code := Lookitup( "brand", upper( substr( strtran( mbrand, ' ', '' ), 1, 6 ) ), "supp_code" )
        master->year := mdate
        master->minstock := 1
        master->binding := mform
        master->comments := if( !empty( mprice ),trim(mprice)+' ','')+trim(mcomment) +' '+mform
        master->entered := Bvars( B_DATE )
        cls
        Heading( 'GBIP Desc Editing screen' )
        Highlight( 02, 03, '      Code',master->id )
        Highlight( 02, 35, 'id',if( substr( master->id, 1, 3 ) = '978', idcheck( master->id ), 'No id') )
        @ 04, 03 say '     Desc' get master->desc pict '@S35'
        @ 05, 03 say '    Author' get master->alt_desc pict '@!'
        @ 07, 03 say '   Imprint' get master->brand pict '@!' valid( Dup_chk( master->brand, "brand" ) )
        Highlight( 07, 22, 'Full Imprint name->', mbrand )
        @ 08, 03 say '  Supplier' get master->supp_code pict '@!' valid( dup_chk( master->supp_code, "supplier") )
        Highlight( 08, 20, '', '<-- Must be filled in or Record will be Deleted' )
        Highlight( 09, 01, '', 'This Supplier Code is Extracted from the Imprint file it may not be accurate !')
        @ 11, 03 say '   Binding' get master->binding pict '@!' valid( Dup_chk( master->binding, "Binding" ) )
        @ 11, 25 say 'Department' get master->department pict '@!' valid( Dup_chk( master->department, "dept" ) )
        @ 13, 03 say 'Cost Price' get master->cost_price pict '9999.99'
        @ 13, 25 say 'Sell Price' get master->sell_price pict '9999.99'
        @ 13, 50 say '       RRP' get master->retail pict '9999.99'
        @ 15, 03 say ' Min Stock' get master->minstock pict '999'
        @ 15, 25 say ' Firm Sale' get master->sale_ret pict 'Y'
        @ 17, 25 say '      Year' get master->year
        @ 19, 03 say '  Comments' get master->comments
        Highlight( 21, 03, '', 'Hit <PgUp> to abort Append' )
        read
        if lastkey() = K_PGUP
         marc->( dbgobottom() )
        endif
        if lastkey() == K_ESC .or. empty( master->supp_code )
         Error("No Supplier Entered or Esc Pressed - Record Deleted",12)
         master->( dbdelete() )
        else
#ifndef __HARBOUR__

         if !empty( mabs )
          v_select( 0 )
          if V_use( Oddvars( SYSPATH ) + 'master' ) == -1
           Error( "Cannot Open master Abstract File, Error " + Ns( V_error() ), 12 )
          else
           Rec_lock('master')
           master->abs_ptr := V_replace( mabs, master->abs_ptr )
           v_close()
          endif
         endif
#endif
        endif
        master->( dbrunlock() )
       endif
      enddo
      marc->( dbclosearea() )
     endif
    endif
    Brest( mscr )
   endif
  endcase
 endif
enddo
Brest( oldscr )
return
*

procedure impo_stby
local sarr, mgo, mchoice, oldscr:=Bsave(), mfile, sID, aArray
local y, mfpos
while TRUE
 Brest( oldscr )
 Heading('Standby POS Systems')
 aArray := {}
 aadd( aArray, { 'Import', 'Return to Import Menu' } )
 aadd( aArray, { 'Create', 'Create a Master Image file for Standby POS' } )
 aadd( aArray, { 'Floppy', 'Import Sales from Floppy Standby POS' } )
 aadd( aArray, { 'HardDisk', 'Import Sales from Hard Disk Standby POS' } )
 mchoice := Menugen( aArray, 13, 51, 'Standby POS')
 do case
 case mchoice < 2
  exit
 case mchoice = 2
  Build_HDMast()  // Located in Proclib

 case mchoice = 3 .or. mchoice = 4
  Bsave( 02,02,18,78 )
  Center( 03,'This procedure will update the master file from a standby POS disk.' )
  Center( 04,'It will then zero the ' + if(mchoice=3,'Diskette','Hard Disk' )+' file.' )
  if Isready( 05 )
   mfile := if( mchoice=3, 'a:', 'c:\standby\')  + 's_sales.dbf'
   sarr := directory( mfile )
   if empty( sarr )
    Error( 'No '+mfile+' Standby Sales File',12 )
   else
    Center( 06,'The date of the upload file is ' + dtoc( sarr[1,3] ) )
    if Isready( 07 )
     Center( 08,'-=< Processing - Please Wait >=-' )
     mgo := NO
     if Netuse( "sales" )
      if Netuse( mfile, EXCLUSIVE, 10, "standby", NEW )
       mgo := YES
       Print_find( "docket","report" )
       while !standby->( eof() )
        @ 10,10 say 'id ' + standby->id
        if !empty( standby->id )
         if Codefind( standby->id )
          @ 12,10 say 'Desc ' + master->desc
       
          Rec_lock( 'master' )
          master->onhand -= standby->qty
          master->dsale := standby->sale_date
          sID := master->id
          master->( dbrunlock() )

          Add_rec( 'sales' )

          for y := 1 to standby->( fcount() )
           mfpos := sales->( fieldpos( standby->( fieldname( y ) ) ) )
           if mfpos != 0
            sales->( fieldput( mfpos, standby->( fieldget( y ) ) ) )
           endif
          next y

          sales->( dbrunlock() )
       
         else
          Printcheck()
          set printer on
          set console off
          ? standby->id,standby->unit_price,standby->qty
          set console on
          set printer off
          sID := ''
         endif
        else

         Add_rec( 'sales' )

         for y := 1 to standby->( fcount() )
          mfpos := sales->( fieldpos( standby->( fieldname( y ) ) ) )
          if mfpos != 0
           sales->( fieldput( mfpos, standby->( fieldget( y ) ) ) )
          endif
         next y

         sales->( dbrunlock() )

        endif

        Del_rec( 'standby', UNLOCK )
        standby->( dbskip() )

       enddo
       Center(14,'Now clearing temporary sales file')
       select standby
       zap
       pack
       Error('Upload Completed',16)
      endif
      standby->( dbclosearea() )
     endif
     sales->( dbclosearea() )
    endif
   endif
  endif
 endcase
enddo
return
*

procedure Bisac_Abort
if select("bt") != 0
 select bt
else
 select bis_titl
endif
go bott
select master
delete
keyboard chr( K_PGDN )
return
*

procedure bisac_recno 
local getlist:={},precno,mscr:=Bsave( 6, 30, 8, 55 )
if select("bt") != 0
 select bt
else
 select bis_titl
endif
precno := 1
@ 7,32 say 'Record to go to' get precno pict '99999' ;
       valid( precno < lastrec() .and. precno > 0)
read
Brest( mscr )
if updated()
 goto precno
endif
select master
return
*

procedure bisac_draft 
local getlist:={}, mhold:=Bvars( B_DEPTORDR ), mqty:=1, mcomm:=space(15), mmin:=Bvars( B_REORDQTY )
local okf10:=setkey( K_F10 , nil ), mscr:=Bsave( 3, 59, 7, 77 )
@ 4,60 say 'Qty to Order' get mqty pict '999'
@ 5,60 say '        Hold' get mhold pict 'Y'
@ 6,60 say '   Min Stock' get mmin pict '999'
read
Brest( mscr )
if mqty > 0
 select draft_po
 seek master->id
 locate for draft_po->source = 'Bi' .and. draft_po->supp_code = master->supp_code ;
        while draft_po->id = master->id
 if found()
  Rec_lock()
  draft_po->qty += mqty
 else
  Add_rec()
  draft_po->id := master->id
  draft_po->supp_code := master->supp_code
  draft_po->qty := mqty
  draft_po->date_ord := Bvars( B_DATE )
  draft_po->special := TRUE
  draft_po->hold := mhold
  draft_po->source := 'Bi'
  draft_po->skey := master->alt_desc
  draft_po->department := master->department
 endif
 select master
 replace minstock with mmin
endif
setkey( K_F10 , okf10 )
return
*

procedure bisac_id 
local getlist:={},sID:=space(10),retrec,mscr:=Bsave( 6, 08, 8, 72 )
@ 7,10 say 'Enter id to locate (No Scan Codes)' get sID
read
Brest( mscr )
select bis_titl
retrec := recno()
locate for bis_titl->id == sID
if found()
 bis_titl->( dbskip( -1 ) )
 retrec := recno()
else
 Error('id not in BISAC file',12)
endif
goto retrec
select master
return
*

procedure bisac_dump ( dump_flag )
* When Called will set/reset DUMP_FLAG to ignore "000000" (Dump Bin) id's
dump_flag := !dump_flag
return
*

procedure BisacAppAll ( append_all )
append_all := YES
keyboard chr( K_PGDN )
return
*

procedure BisacHelp ( dump_flag )
local mscr:=Bsave( 16, 60, 24, 79 )
if dump_flag
 @ 17,61 say '<F4> Ignore Dump'
else
 @ 17,61 say '<F4> Use Dump Bi'
endif
@ 18,61 say '<F5> Append All'
@ 19,61 say '<F7> Seek Rec. #'
@ 20,61 say '<F8> Seek id'
@ 21,61 say '<F9> Add to Draft'
@ 22,61 say '<F10> Abort Append'
@ 23,61 say '<Esc> Ignore Desc'
inkey(0)
Brest( mscr )
return
*

function ArraySkip( alen, curpos, howmany )
local actual
if howmany >= 0
 if (curpos +howmany) > alen
  actual := alen-curpos
  curpos := alen
 else
  actual := howmany
  curpos += howmany
 endif
else
 if (curpos +howmany) < 1
  actual := 1-curpos
  curpos := 1
 else
  actual := howmany
  curpos += howmany
 endif
endif
return actual
*

function GetFile ( mask, mpath )

local bisac_file := '', mscr, mdrive, indisp, element, mkey, tscr, dbfile

default mask to '*.*'
default mpath to Oddvars( SYSPATH ) + 'bisac\'

Heading("Select Drive for to search for files")
mscr := Bsave( 9, 10, 13, 60 )
@ 10,11 prompt 'A:'
@ 11,11 prompt 'B:'
#ifndef __HARBOUR__
@ 12,11 prompt chr(getdriv())+':'
#endif
@ 11,16 say '<ÍÍ Select Drive to append files from'
menu to mdrive
Brest( mscr )
do case
case mdrive = 1
 dbfile:=directory( "a:\" + mask )
case mdrive = 2
 dbfile:=directory( "b:\" + mask )
case mdrive = 3
 dbfile:=directory( mpath + mask )
otherwise
 return ''
endcase
if empty(dbfile)
 error("No Files Found or Drive Error",12)
 return ""
endif
element:=1
Heading("Select File")
mscr:=Bsave( 04, 02, 22, 50 )
indisp:=TBrowseNew( 05, 03, 21, 49 )
indisp:HeadSep:=HEADSEP
indisp:ColSep:=COLSEP
indisp:goTopBlock:={ || element:=1 }
indisp:goBottomBlock:={ || element:= len(dbfile) }
indisp:skipBlock:={ |n| ArraySkip( len( dbfile ), @element, n ) }
indisp:AddColumn( TBColumnNew( 'File Name', { || padr(dbfile[element,1],12) } ) )
indisp:AddColumn( TBColumnNew( 'Size', { || transform(dbfile[element,2],"999,999,999") } ) )
indisp:AddColumn( TBColumnNew( 'Date', { || dbfile[element,3] } ) )
mkey:=0
while mkey != K_ESC
 indisp:forcestable()
 mkey:=inkey(0)
 if !Navigate( indisp, mkey )
  do case
  case mkey == K_F1
   tscr := Bsave( 12, 50, 16, 75 )
   @ 13,51 say 'Del   Del File from Net'
   @ 14,51 say 'Enter Select File '
   @ 15,51 say 'F10   Copy File to Net'
   inkey(0)
   Brest( tscr )
  case mkey == K_ENTER
   bisac_file:=if(mdrive=1,'a:\',if(mdrive=2,'b:\',mpath))+dbfile[element,1]
   if !( '.' $ Bisac_file )
    bisac_file += '.'
   endif
   exit
  case mkey == K_DEL
   if mdrive < 2
    Error( 'Naughty, Naughty - Cannot delete the reps files', 12 )
   else
    tscr := Bsave( 2, 10, 4, 70 )
    @ 3, 12 say 'About to delete file ' + mpath + dbfile[element,1]
    if Isready( 12 )
     Kill( mpath + dbfile[ element, 1 ] )
     dbfile[ element, 1 ] := '*Deleted*'
    endif
    Brest( tscr )
    indisp:refreshall()
   endif
  case mkey == K_F10
   if mdrive = 3
    Error( 'No Copy from network drive', 12 )
   else
    tscr := Bsave( 2, 10, 5, 70 )
    @ 3, 12 say 'About to copy ' + dbfile[ element, 1 ] + ' to '+ Oddvars( SYSPATH ) + 'bisac\' +;
                 dbfile[ element, 1 ]
    if Isready( 12 )
     @ 4, 12 say 'Copying File ' + dbfile[ element, 1] + ' Please wait'
     copy file ( if(mdrive=1,'a:\','b:\') + dbfile[ element, 1 ] ) to ;
          ( Oddvars( SYSPATH ) + 'bisac\' + dbfile[ element, 1 ] )
    endif
    Brest( tscr )
   endif
  endcase
 endif
enddo
Brest( mscr )
return bisac_file
*

Function Low_case ( mdesc )
local mlen,x

#define NULCHAR '¾'

mdesc := strtran( lower( trim( mdesc ) ), ' ', NULCHAR )

mlen := len( mdesc )

x := at( NULCHAR, mdesc )

mdesc := upper( left( mdesc,1 ) ) + substr( mdesc, 2, mlen-1 )

while x != 0
                                                                                  
 if substr( mdesc, x+1, 4 ) $ '|and¾|the¾|but¾|can¾|are¾' .or.;
    substr( mdesc, x+1, 2 ) $ '|a¾' .or.;
    substr( mdesc, x+1, 3 ) $ '|or¾|be¾|in¾|an¾|to¾|as¾|do¾|on¾|at¾|by¾|of¾' .or.;
    substr( mdesc, x+1, 5 ) $ '|into¾|onto¾|this¾|that¾|upon¾|from¾' .or.;
    substr( mdesc, x+1, 6 ) = '|until¾' 

  mdesc := strtran( mdesc, NULCHAR, ' ', 1, 1 )

 else

  mdesc := left( mdesc, x-1 ) + ' ' + upper( substr( mdesc, x+1, 1 ) ) + ;
            substr( mdesc, x+2, mlen - x + 2 )
 endif

 x := at( NULCHAR, mdesc )

enddo

return mdesc
