/*
   MainCust - customer Maintenance

   Last change: APG 9/03/2009 5:37:46 PM

      Last change:  TG   13 Jan 2012    4:43 pm
*/
Procedure f_customer

#include "bpos.ch"

#define FIND_THIS 1
#define FIRSTNEXT 2
#define CASESENSE 3
#define WILDCARDS 4

local mgo:=FALSE,choice,loopval,mscr,rec_list[25],pos,mflag,row,c,aArray
local oldscr:=Box_Save(),akey,getlist:={}, enqbrow
local x,catlist,catnames,m_and_cat,mcat,lAnswer,newchoice,pcodentx
local pchoice,abs_temp,abs_search:=FALSE, msel,pcodesel,mprintfromtop,mprintletter
local mpart,msearch,mfield,mchoice,dstru,astru,mlen,mdate,mdbf,mkey,mqty
local handle, mbuff, mcode, sobj, keypress, mseq, mcount, mprice, mdisc, farr, pw

local aQry := {}
local lDBVEverLooked := FALSE
local lDBFEverLooked := FALSE
local l33exclude

memvar startdate,enddate,mcust,mdollar
private startdate,enddate,mcust,mdollar

Center( 24, 'Opening Customer File' )
if master_use()
 if Netuse( 'salehist' )
  set relation to salehist->id into master
  if Netuse( 'category' )
   if Netuse( 'custcate' )
    set relation to custcate->code into category
    if Netuse( 'customer' )
     mgo := TRUE
    endif
   endif
  endif
 endif
endif
Line_clear(24)
while mgo
 Box_Restore( oldscr )
 Heading('Customer Mailout System')
 aArray := {}
 aadd( aArray, { 'File', 'Return to File Menu' } )
 aadd( aArray, { 'Add/Edit', 'Add/Edit Customer Details' } )
 aadd( aArray, { 'Print', 'Mailmerge/Print/Labels' } )
 aadd( aArray, { 'Search', 'Part Search for Customers' } )
 aadd( aArray, { 'Boolean', 'Boolean Search on Customers' } )
 aadd( aArray, { 'Category', 'Display customers on Categories' } )
 choice := MenuGen( aArray, 06, 02, 'Mailout' )
 oldscr:=Box_Save( 0, 0, 24, 79 )
 loopval := TRUE
 while loopval
  do case
  case Choice = 2
   Heading('Customer Maintenance')
   if CustFind( FALSE )
    CustScr( FALSE )
   else
    loopval := FALSE
   endif
  case Choice = 3
   Heading('Printing Options')
   aArray := {}
   aadd( aArray, { 'Return','Return to Mailout Menu' } )
   aadd( aArray, { 'All', 'List Customers' } )
   aadd( aArray, { 'Mailmerge', 'Prepare Mailmerge List' } )
   aadd( aArray, { 'Labels', 'Print Labels' } )
   aadd( aArray, { 'Purchases', 'List Customers Purchases' } )
   aadd( aArray, { 'Envelopes', 'Print single Envelopes' } )
   aadd( aArray, { 'Area','Print Customers in Area' } )
   aadd( aArray, { 'On Stop','Print All Customers on Stop' } )
   newchoice := MenuGen( aArray, 09, 03, 'Print' )
   if newchoice > 1 .and. newchoice < 5
    Box_Save( 02, 02, 12, 78 )
    Heading('Select Category Codes')
    catlist := { space( 6 ), space( 6 ), space( 6 ) }
    m_and_cat := space(6)
    mcat := FALSE
    lAnswer := 'A'
    pcodentx := NO
    pcodesel := '0'
    @ 3,10 say 'Select All Customers or by Interest classification (A/I)' ;
           get lAnswer pict '!' valid( lAnswer $ 'AI')
    @ 4,10 say 'Index file on Postcode' get pcodentx pict 'y'
    @ 4,40 say 'Post code to print' get pcodesel pict '!' when pcodentx
    read
    if lastkey() = K_ESC
     loop
    endif
    akey := {}
    aadd( akey , { "key","c",10,0 } )
    aadd( akey , { "pcode",'c',4,0 } )
    aadd( akey , { "qty",'n',4,0 } )
    aadd( akey , { "code",'c',10,0 } )
    aadd( akey , { "mlist",'c',10,0 } )
    dbcreate( Oddvars( TEMPFILE ), aKey )
    if !Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "keys", NEW )
     loop
    endif
    if lAnswer = 'I'
     catlist := {}
     catnames := {}
     while TRUE
      mcat := space( 6 )
      @ 05, 03 say 'Category ' + str( len( catlist ) + 1, 2, 0 ) get mcat pict '@!' ;
               valid empty( mcat ) .or. dup_chk( mcat, "category" )
      read
      if empty( mcat )
       exit
      else
       if ascan( catlist, mcat ) != 0
        Error( 'Category Code already on list', 12 )
       else
        aadd( catlist, mcat )
        aadd( catnames, Lookitup( 'category', mcat ) )
        keyboard K_ESC
        Box_Save( 5, 50, 6 + min( len( catnames ), 18 ), 76 )
        for x := 1 to len( catnames )
         if x > 18
          scroll( 6, 51, 23, 75, 1 )
         endif
         @ 5 + min( x, 18 ), 51 say substr( catnames[ x ], 1, 25 )
        next
       endif
      endif
     enddo

     @ 05,22 say 'AND Category' get m_and_cat pict '@!' ;
            valid empty( m_and_cat ) .or. dup_chk( m_and_cat, "category" )
     read

     if len( catlist ) = 0  // !updated()
      keys -> ( dbclosearea() )
      Error('You must enter a Category',12)
      loop
     else
      Highlight( 6, 6,'', 'Processing - Please Wait' )
      for x := 1 to len( catlist )
       select custcate
       ordsetfocus( 2 )
       set relation to custcate->key into customer
       if !empty( catlist[ x ] )
        seek catlist[ x ]
        while custcate->code == catlist[ x ] .and. !custcate->(eof())
         add_rec('keys')
         keys->key := custcate->key
         keys->pcode := customer->pcode
         keys->code := catlist[ x ]
         skip alias custcate
        enddo
       endif
      next
      select custcate
      ordsetfocus( 1 )
      select keys
      if !empty( m_and_cat )
       keys->( dbgotop() )
       set relation to keys->key into custcate
       while !keys->( eof() )
        select custcate
        locate for custcate->code = m_and_cat while custcate->key = keys->key
        if !found()
         keys->( dbdelete() )
        endif
        keys->( dbskip() )
       enddo
       set relation to
      endif
     endif
    else
     select keys
     append from customer
    endif
    Highlight( 7, 6, '', 'Deleting non Unique Customer Keys' )
    select keys
    indx( "keys->key", 'key', ,UNIQUE )    // unique
    copy to ( Oddvars( TEMPFILE2 ) ) for if( pcodesel = '0', TRUE, keys->pcode = pcodesel )
    keys->( orddestroy( 'key' ) )
    keys->( dbclosearea() )
    Netuse( Oddvars( TEMPFILE2 ), EXCLUSIVE, 10, "tmp", FALSE )
    pack
    if pcodentx
     Highlight( 8, 6, '', 'Indexing on Postcode' )
     indx( "tmp->pcode", 'pcode' )
    else
     indx( "tmp->key", 'key' )
    endif
    Highlight( 9, 6, 'Records Selected', Ns( lastrec() ) )
    set relation to tmp->key into customer
    if lastrec() > 0
     Heading( 'Browse Selected Records' )
     mscr:=Box_Save(1,39,22,77)
     enqbrow:=tbrowsedb(2,40,21,76)
     enqbrow:HeadSep:=HEADSEP
     enqbrow:ColSep:=COLSEP
     enqbrow:addcolumn( tbcolumnnew( "Code", { || field->code } ) )
     enqbrow:addcolumn( tbcolumnnew( "Key", { || field->key } ) )
     enqbrow:addcolumn( tbcolumnnew( "Name", { || substr( customer->name, 1, 15 ) } ) )
     mkey:=0
     while TRUE
      enqbrow:forcestable()
      mkey:=inkey( 0 )
      if !navigate( enqbrow, mkey )
       do case
       case mkey == K_F10
        select customer
        CustScr( FALSE )
        select tmp
       case mkey == K_INS
        if CustFind( FALSE )
         Add_rec( 'tmp' )
         tmp->key := customer->key
         tmp->code := 'Operator'
         tmp->( dbrunlock() )

         enqbrow:refreshall()
        endif
        select tmp
        case mkey == K_DEL
        if Isready( 12, 02, 'Ok to delete ' + field->key + ' from mailout' )
         Del_rec( ,UNLOCK )
         eval( enqbrow:skipblock , -1 )
         enqbrow:refreshall()
        endif
       case mkey == K_ESC .or. mkey == K_END
        exit
       endcase
      endif
     enddo
     Box_Restore( mscr )
    endif
    mprintfromtop := TRUE
    @ 10, 6 say 'Print from top' get mprintfromtop pict 'y'
    read
    if !mprintfromtop
     if pcodentx
      mprintletter := 0
      @ 10, 06 say 'Print from Number' get mprintletter pict '9'
     else
      mprintletter := ' '
      @ 10, 6 say 'Print from letter' get mprintletter pict '!'
     endif
     read
    endif
   endif
   do case
   case newchoice = 7
    CustAreas()

   case newchoice = 8
    StopCust()

   case newchoice = 2
    Heading('Print Mailout File')
    Print_find("report")
    
    if Isready(12)
     select tmp
     if mprintfromtop
      tmp->( dbgotop() )

     else
      tmp->( dbseek( mprintletter, SOFTSEEK ) )

     endif
     farr := {}
     aadd(farr,{'customer->key','Key',10,0,FALSE})
     aadd(farr,{'customer->name','Name',25,0,FALSE})
     aadd(farr,{'trim(customer->add1)+" "+trim(customer->add2)+" "+trim(customer->add3)','Address',50,0,FALSE})
     aadd(farr,{'customer->pcode','Post;Code',4,0,FALSE})
     aadd(farr,{'customer->phone1','Telephone1',14,0,FALSE})
     aadd(farr,{'customer->phone2','Telephone2',14,0,FALSE})
     aadd(farr,{'customer->fax','Fax',14,0,FALSE})
     Reporter(farr,"'Customer Listing'")

    endif
   case newchoice = 3
    Heading( 'Mailmerging in progress' )
    Center( 11, 'Mailmerge is being written to file "'+Oddvars( SYSPATH )+'merge.txt"' )
    if bvars( B_WPTYPE ) = 'TD'
     aArray := {}
     aadd( aArray, { 'key', 'c', CUST_KEY_LEN , 0 } )
     aadd( aArray, { 'name', 'c', 40 , 0 } )
     aadd( aArray, { 'address1', 'c', 40 , 0 } )
     aadd( aArray, { 'address2', 'c', 40 , 0 } )
     aadd( aArray, { 'address3', 'c', 40 , 0 } )
     aadd( aArray, { 'postcode', 'c', 4 , 0 } )
     aadd( aArray, { 'contact', 'c', 40 , 0 } )
     dbcreate( 'merge', aArray )
     if Netuse( 'merge' )
      if mprintfromtop
       tmp->( dbgotop() )
      else
       tmp->( dbseek( mprintletter, SOFTSEEK ) )
      endif
      mcount := 1
      while !tmp->( eof() )
       Add_rec( 'merge' )
       merge->key := tmp->key
       merge->name := customer->name
       merge->address1 :=  customer->add1
       merge->address2 :=  customer->add2
       merge->address3 :=  customer->add3
       merge->postcode :=  customer->pcode
       merge->contact :=  customer->contact
       merge->( dbrunlock() )
       @ 9, 56 say Ns( mcount )
       tmp->( dbskip() )
       mcount++
      enddo
      Error( 'File "merge.dbf" has been written', 14 )
     endif

    else

     @ 09, 40 say 'Records Written'
     mcount := 1
     handle := fcreate( 'merge.txt' )
     if handle = -1
      Error( 'Problem creating merge file - Error #'+Ns( Ferror() ) , 12 )
     else
      if mprintfromtop
       tmp->( dbgotop() )
      else
       tmp->( dbseek( mprintletter, SOFTSEEK ) )
      endif
      while !tmp->( eof() )
       mbuff := '"' + trim( customer->name ) + '","' + trim( customer->add1 ) + '","';
             + trim( customer->add2 ) + '","' + trim( customer->add3 ) + '","';
             + trim( customer->pcode ) + '"' + CRLF

       fwrite( handle, mbuff )
       @ 9, 56 say Ns( mcount )
       tmp->( dbskip() )
       mcount++
      enddo
      fclose( handle )
      Error( 'File has been written', 14 )
     endif

    endif

   case newchoice = 4
    Heading('Label Print')
    Print_find( "label", "barcode" )
    
    if Isready(12)
     select tmp
     Pitch12()
     if mprintfromtop
      tmp->( dbgotop() )
     else
      tmp->( dbseek( mprintletter, SOFTSEEK ) )
     endif
     label form maillabe.frm to print noconsole while Pinwheel() sample
     // Pitch10()
    endif
    select customer
   case newchoice = 5
    Heading("Customer Purchases Print")
    aArray := {}
    aadd( aArray, { 'Print', 'Return to Print Menu' } )
    aadd( aArray, { 'All' ,'Print all Purchases for all Customers' } )
    aadd( aArray, { 'Individual','Print purchases for specified Customer' } )
    aadd( aArray, { 'Best Cust','Print the Best Customer listing' } )
    aadd( aArray, { 'Delete','Delete Customer Purchase Records' } )
    pchoice := MenuGen( aArray, 14, 04, 'Purchases' )
    farr := {}
    aadd(farr,{'substr(master->desc,1,25)','Desc',25,0,FALSE})
    aadd(farr,{'substr(master->alt_desc,1,15)','Contact',15,0,FALSE})
    aadd(farr,{'date','Date;Purch.',8,0,FALSE})
    aadd(farr,{'unit_price','Price',9,2,FALSE})
    aadd(farr,{'discount','Discount',8,2,TRUE})
    aadd(farr,{'qty','Qty',6,0,TRUE})
    aadd(farr,{'(unit_price-discount)*qty','Extend;(Inc Disc)',10,2,TRUE})
    do case
    case pchoice = 2
     Heading("Print all Customer Purchases")
     Print_find("report")
     startdate := Bvars( B_DATE ) - 365
     enddate := Bvars( B_DATE )
     Box_Save(2,08,10,72)
     @ 5,10 say 'Start Date for Print' get startdate
     @ 7,10 say '  End Date for Print' get enddate
     read
     if Isready(12)
      
      Pitch12()
      select salehist
      ordsetfocus( 2 )
      go top
      set rela addi to salehist->key into customer

      Reporter(farr,"'List Of All Customer Purchases From '+dtoc(startdate)+' to '+dtoc( enddate )",;
      'salehist->key','"Customer : "+trim(customer->name)+"    Key : "+salehist->key','','',FALSE,;
      '!empty(salehist->key) .and. salehist->date >= startdate .and. salehist->date <= enddate',,96)
      set rela to salehist->id into master
      ordsetfocus( 1 )

     endif
    case pchoice = 3
     if CustFind( FALSE )
      startdate := Bvars( B_DATE ) - 365
      enddate := Bvars( B_DATE )
      Box_Save(2,08,10,72)
      mcust := customer->name
      Highlight( 3, 10, 'Customer Name', mcust )
      select salehist
      ordsetfocus( 2 )
      if !salehist->( dbseek( customer->key ) )
       Error('No History on file for Customer',12)
      else
       Print_find( "report" )
       @ 5,10 say 'Start Date for Print' get startdate
       @ 7,10 say '  End Date for Print' get enddate
       read
       if Isready(12)
        
        Pitch12()
        pw := 96
        Reporter(farr,"'Customer Purchase List For '+alltrim(mcust)+' from '+dtoc(startdate)+' to '+dtoc( enddate )",;
        'salehist->key','"Customer : "+alltrim(customer->name)+"    Key : "+salehist->key','','',FALSE,;
        'salehist->date >= startdate .and. salehist->date <= enddate','salehist->key = customer->key',pw)
        Endprint()
       endif
      endif
     endif

    case pchoice = 4
     Heading("Print Best Customer Report")
     Print_find("report")
     
     startdate := Bvars( B_DATE ) - 365
     enddate := Bvars( B_DATE )
     mdollar := 0
     l33exclude := TRUE
     Box_Save(2,08,10,72)
     @ 5,10 say 'Start Date for Print' get startdate
     @ 7,10 say '  End Date for Print' get enddate
     @ 8,10 say '      Cutoff $ value' get mdollar pict '99999'
     read
     if Isready(12)

      mdbf := {}
      aadd( mdbf, { "key", 'C', 10, 0 } )
      aadd( mdbf, { "qty", 'N', 12, 0 } )
      aadd( mdbf, { "unit_price", 'N', 12, 0 } )
      aadd( mdbf, { "date", 'D', 8, 0 } )
      aadd( mdbf, { "discount", 'N', 12, 0 } )
      dbcreate( Oddvars( TEMPFILE ) , mdbf )
      Netuse( Oddvars( TEMPFILE ), EXCLUSIVE , 10 , "total", NEW )
      select salehist
      ordsetfocus( 2 )

      dbseek( '!', TRUE )  // do a softseek to get over empty() keys
      mkey := salehist->key

      while !salehist->( eof() )
       mscr:=Box_Save(2,20,4,60)
       Center( 3,'Processing Customer ' + mkey )
       sum ( salehist->unit_price - salehist->discount ) * salehist->qty, salehist->qty, ;
           salehist->discount * salehist->qty ;
           to mprice, mqty, mdisc while salehist->key = mkey .and. Pinwheel( NOINTERUPT ) ;
           for ( salehist->date >= startdate .and. salehist->date <= enddate ) .and. ;
           if( l33exclude, salehist->sale_type != '33', TRUE )
       dbskip( -1 )
       mdate := salehist->date
       dbskip()

       Add_rec( 'total' )
       total->key := mkey
       total->unit_price := mprice
       total->qty := mqty
       total->discount := mdisc
       total->date := mdate

       select salehist
       mkey := salehist->key

      enddo

      Box_Restore( mscr )
      select total
      indx( "unit_price * -1 ", 'unit_price' )
      set relation to total->key into customer
      Pitch12()

      Reporter(farr,"'Best Customer List From '+dtoc(startdate)+' to '+dtoc( enddate )",;
      'total->key','"Customer : "+trim(customer->name)+"    Key : "+total->key','','',FALSE,;
      '','total->unit_price > mdollar',96)
      Endprint()

      total->( dbclosearea() )

     endif

    case pchoice = 5
     if Secure( X_SYSUTILS )
      mdate := Bvars( B_DATE ) - 365
      Box_Save(2,08,9,72)
      Heading('Purge Old Customer Histories')
      @ 3,10 say 'Clear Customer Histories older than' get mdate
      read
      Center(5,'You are about to clear all histories older than ' + dtoc(mdate))
      if Isready(7)
       Center(7,'-=< Processing - Please Wait >=-')
       select salehist
       if Netuse( 'salehist', EXCLUSIVE, 10, NOALIAS, OLD )
        delete for salehist->date < mdate .and. !empty( salehist->key )
        Netuse( 'salehist', SHARED, 10, NOALIAS, OLD )
        set rela to salehist->id into master
        SysAudit("PurgeCustHist"+dtoc(mdate))
       endif
      endif
     endif
    endcase
   case newchoice = 6
    while TRUE
     if !CustFind( FALSE )
      exit
     else
      Print_find( "label", "barcode" )
      Box_Save(17,10,19,70)
      Highlight(18,12,'Customer Name -> ',trim(customer->name))
      if Isready(19)
       
       // Pitch10()
       set printer on
       set console off
       ?
       ?
       ?
       ?
       ? space(24) + customer->name
       if !empty(customer->add1)
         ? space(24) + customer->add1
       endif
       if !empty(customer->add2)
         ? space(24) + customer->add2
       endif
       ? space(24) + trim( customer->add3 ) + ' ' + customer->pcode
       Endprint()
       set console on
       set printer off
      endif
     endif
    enddo
   case newchoice < 2
    loopval := FALSE
   endcase
   if select("tmp") != 0
    select tmp
    use
   endif
  case Choice = 4
   Heading('Part of field (Slow Search)')
   dstru := dbstruct()
   astru := {}
   mlen := len(dstru)
   msel := 0
   for x:=1 to mlen
    if dstru[x,2] = 'C'
     aadd(astru,dstru[x,1])
    endif
   next
   mscr := Box_Save(2,2,22,20)
   mchoice:=achoice(3,3,21,19,astru)
   if mchoice = 0
    loopval := FALSE
   else
    mfield:=astru[mchoice]
    mfield:=upper(substr(mfield,1,1))+lower(substr(mfield,2,len(mfield)-1))
    Box_Save(2,8,6,72)
    @ 3,10 say 'This option will search for part of a '+mfield
    @ 4,10 say '      It may take a considerable period of time'
    mpart := space(10)
    @ 05,10 say 'Part of ' + mfield get mpart pict '@!'
    read
    if !updated()
     loopval := FALSE
    else
     if upper(mfield)='ABS_PTR'
      abs_search := YES
     endif
     msearch := TRUE
     select customer
     ordsetfocus( 0 )
     dbgotop()
     cls
     Heading('')
     row := 4
     pos := 1
     @ 2,1 say ' No Name                      Address               Suburb'
     @ 3,1 say 'ÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
     mflag := TRUE
     Highlight(1,02,'Records to search',NS(lastrec()))
     while mflag .and. inkey() = 0 .and. !eof()
      if !abs_search
       if (trim(mpart) $ upper(trim(&mfield)))
        @ row,1 say pos pict '999'
        @ row,5 say substr( customer->name, 1, 25 )
        @ row,31 say customer->Add1
        @ row,53 say customer->add2
        rec_list[pos] := recno()
        row++
        pos++
       endif
      else
       if (trim(mpart) $ upper(trim(abs_temp)))
        @ row,1 say pos pict '999'
        @ row,5 say substr(customer->name,1,25)
        @ row,31 say customer->add1
        @ row,53 say customer->add2
        rec_list[pos] := recno()
        row++
        pos++
       endif
      endif
      Highlight(1,50,'Record Number',Ns(recno()))
      skip
      if row = 23 .or. customer->( eof() )
       msel := 0
       @ 24,10 say 'Enter No to Examine or <Enter> for next page';
                     get msel pict '99' valid(msel < pos)
       read
       if lastkey() = K_ESC
        exit
       endif
       if !updated()
        pos := 1
        row := 4
        @ 4,0 clear
       endif
      endif
      if msel > 0
       goto rec_list[msel]
       CustScr( FALSE )
       if Isready( 12,,'Quit Searching' )
        exit
       else
        @ 4,0 clear
        msel := 0
        pos := 1
        row := 4
       endif
      endif
     enddo
    endif
    ordsetfocus( BY_KEY )
   endif
  case choice = 5
#ifndef __HARBOUR__
   Boolean( 'customer' )  // Routine in Saleinq1.prg
#endif
   loopval := FALSE

  case choice = 6
   select custcate
   ordsetfocus( BY_KEY )
   set relation to custcate->key into customer additive
   mcode := space(6)
   while TRUE
    Box_Restore( oldscr )
    Heading('Customers on Category')
    mcode += space(6-len(mcode))
    @ 11,12 say 'ÍÍÍÍ¯' get mcode pict '@K!' valid dup_chk( mcode, "category" )
    read
    if lastkey() = K_ESC
     select custcate
     set relation to custcate->code into category
     ordsetfocus( BY_CODE )
     loopval := FALSE
     exit
    else
     seek mcode
     cls
     Heading('Inquire by Category')
     for x = 1 to 24-2
      @ x+2,0 say row()-2 pict '99'
     next
     sobj:=tbrowsedb( 01, 03, 24, 79 )
     sobj:colorspec := TB_COLOR
     sobj:HeadSep := HEADSEP
     sobj:ColSep := COLSEP
     sobj:goTopBlock := { || dbseek( mcode ) }
     sobj:goBottomBlock  := { || jumptobott( mcode ) }
     sobj:skipBlock := KeySkipBlock( {|| custcate->code }, mcode )
     c:=tbcolumnnew('Name', { || substr( customer->name, 1, 21 ) } )
     c:colorBlock := { || if( customer->stop , {8, 9} , ;
     if( customer->amtcur+customer->amt30+customer->amt60+customer->amt90 > 0, {6, 5}, {1, 2} ) ) }
     sobj:addcolumn( c )
     sobj:addcolumn( tbcolumnnew('Address Line 1',{ || substr(customer->add1,1,15) }))
     sobj:addcolumn( tbcolumnnew('Suburb',{||substr(customer->add2,1,15)} ) )
     sobj:addcolumn( tbcolumnnew('Comments',{||substr(customer->comments,1,15)} ) )
     sobj:freeze := 1
     keypress := 0
     while keypress != K_ESC .and. keypress != K_END
      sobj:forcestable()
      keypress := inkey(0)
      if !navigate( sobj, keypress )
       do case
       case keypress >= 48 .and. keypress <= 57
        keyboard chr( keypress )
        mseq := 0
        mscr:=Box_Save( 2, 08, 4, 40 )
        @ 3,10 say 'Selecting No' get mseq pict '999'
        read
        Box_Restore( mscr )
        if !updated()
         loop
        else
         skip mseq - sobj:rowpos
         select customer
         CustScr( FALSE )
         select custcate
        endif
       case keypress == K_ENTER .or. keypress == K_F10
        select customer
        CustScr( FALSE )
        select custcate
        sobj:refreshall()
       case keypress == K_INS
        if CustFind( FALSE )
         Add_rec('custcate')
         custcate->code := mcode
         custcate->key := customer->key
         custcate->( dbrunlock() )
         sobj:refreshall()
        endif
        select custcate
       case keypress == K_DEL
        if Isready( 3, 10 , 'Ok to delete customer from list' )
         Del_rec( 'custcate', UNLOCK )
         eval( sobj:skipblock , -1 )
         sobj:refreshall()
        endif
       endcase
      endif
     enddo
    endif
   enddo
   select customer
  case choice < 2
   close databases
   return
  endcase
  Box_Restore( oldscr )
 enddo
enddo

*

function rectach
@ 24,10 say recno()
return TRUE

*

function CustFind ( isdebtor )
local mkey,mscr,okf5,okf6,okf8,custobj,hitkey,c, ccopened:=FALSE
local mrec:=0,getlist:={},oc:=setcolor(),x,mreq,mseq,tscr,mord:=1, mfound
static oldkey:=''
if select( "customer" ) = 0
 if !Netuse( "customer" )
  return FALSE

 endif

endif
if select("custcate") = 0
 if !Netuse("custcate" )
  return FALSE

 else
  ccopened := TRUE

 endif

endif
while TRUE
 select customer
 Heading('Customer Select')
 mscr := Box_Save( 3, 28, 07, 42 + CUST_KEY_LEN, C_MAUVE )
 mkey := space( CUST_KEY_LEN )
 @ 04,29 say 'Customer Key' get mkey pict CUST_KEY_PICT
 @ 05,30 say '<F8>-Add new Customer'
 CustDispmode()
 okf5 := setkey( K_F5, { || InvAllSpecs() } )
 okf6 := setkey( K_F6 , { || DebtSwap( @mord ) } )
 okf8 := setkey( K_F8 , { || CustAdd( isdebtor ) } )

 set function 3 to oldkey + chr( K_ENTER )
 read
 set function 3 to

 setkey( K_F5, okf5 )
 setkey( K_F6, okf6 )
 setkey( K_F8, okf8 )
 Box_Restore( mscr )
 syscolor( C_NORMAL )
 if !updated()
  customer->( dbclearfilter() )
  setcolor(oc)
  if ccopened
   custcate->( dbclosearea() )
  endif
  return FALSE
 else
  mkey := trim(mkey)
  mkey := if( mord=3, soundex( mkey ), mkey )
  customer->( ordsetfocus( mord ) )
  if customer->( dbseek( mkey ) )
   mscr:=Box_Save( 01, 00, 24, 79 )
   for x = 1 to 24-4
    @ x+3,1 say row()-3 pict '99'
   next
   select customer
   custobj:=tbrowsedb( 02, 04, 23, 78 )
   custobj:colorspec := TB_COLOR
   custobj:HeadSep:=HEADSEP
   custobj:ColSep:=COLSEP
   custobj:goTopBlock:={ || dbseek( mkey ) }
   custobj:goBottomBlock:={ || jumptobott( mkey ) }
   custobj:skipBlock:=KeySkipBlock( { || if(mord=1,customer->key,if(mord=2,upper(customer->name),soundex(customer->name))) },mkey )
   custobj:addcolumn( tbcolumnnew('D', { || if(customer->debtor,'Y','N') } ) )
   c:=tbcolumnnew('Name', { || substr( customer->name, 1, 21 ) } )
   custobj:addcolumn( c )
   custobj:addcolumn( tbcolumnnew( 'Address Line 1', { || substr(customer->add1,1,20) }))
   custobj:addcolumn( tbcolumnnew( 'Contact', { || substr( customer->contact,1,15) } ) )
   custobj:addcolumn( tbcolumnnew( 'Phone', { || customer->phone1 } ) )
   custobj:addcolumn( tbcolumnnew( 'Key', { || customer->key } ) )
   custobj:addcolumn( tbcolumnnew( 'Amt Cur', { || transform( customer->amtcur , '99999.99' ) } ) )
   custobj:addcolumn( tbcolumnnew( 'Amt 30', { || transform( customer->amt30 , '99999.99' ) } ) )
   custobj:addcolumn( tbcolumnnew( 'Amt 60', { || transform( customer->amt60 , '99999.99' ) } ) )
   custobj:addcolumn( tbcolumnnew( 'Amt 90', { || transform( customer->amt90 , '99999.99' ) } ) )
   custobj:addcolumn( tbcolumnnew( 'Total Out', { || transform( ;
   customer->amtcur+customer->amt30+customer->amt60+customer->amt90 , '99999.99' ) } ) )
   custobj:addcolumn( tbcolumnnew( 'C Limit', { || transform( customer->C_limit , '999999' ) } ) )
   custobj:freeze := 2
   hitkey := 0
   while hitkey != K_ESC .and. hitkey != K_END
    custobj:forcestable()
    hitkey := inkey(0)
    if !Navigate( custobj, hitkey )

     do case
     case hitkey >= 48 .and. hitkey <= 57
      keyboard chr( hitkey )
      mseq := 0
      tscr := Box_Save( 2, 08, 4, 40 )
      @ 3,10 say 'Selecting No' get mseq pict '999' range 1,X
      read
      Box_Restore( tscr )
      if !updated()
       loop
      else
       mreq := recno()
       skip mseq - custobj:rowpos
       if isdebtor .and. !customer->debtor
        Error("Selected Customer is not a Debtor !",12)
       else
        oldkey := customer->key
        customer->( ordsetfocus( BY_KEY ) )
        if ccopened
         custcate->( dbclosearea() )
        endif
        return TRUE
       endif
       goto mreq
      endif

     case hitkey == K_F10
      if Secure( X_EDITFILES )
       oldkey := customer->key
       CustScr( FALSE )
       custobj:refreshcurrent()
      endif

     case hitkey == K_F9
      tscr := Box_Save( 2, 10, 10, 70 )
      Highlight(3,12,"    Name ",customer->name)
      Highlight(4,12," Contact ",'Attn: '+customer->contact)
      Highlight(6,12,"    Add1 ",customer->add1)
      Highlight(7,12,"         ",trim(customer->add2))
      Highlight(8,12,"         ",trim(customer->add3)+' '+customer->pcode)
      Error( '', 16 )
      Box_Restore( tscr )

     case hitkey == K_ENTER
      if isdebtor .and. !customer->debtor
       Error("Selected Customer is not a Debtor !",12)
      else
       oldkey := customer->key
       setcolor(oc)
       customer->( ordsetfocus( BY_KEY ) )
       if ccopened
        custcate->( dbclosearea() )
       endif
       return TRUE
      endif

     case hitkey == K_DEL
      if Secure( X_DELFILES )
       Box_Save(07,08,09,72)
       Center(08,'You are about to delete -> ' + trim(customer->name))
       if Isready(12)
        if customer->debtor .and. ;
           ( customer->amtcur!=0 .or. customer->amt30!=0 .or. ;
             customer->amt60!=0 .or. customer->amt90!=0 )
          Error( 'Balances Not Zero - Debtor not Deleted', 12 )
        else

         if Netuse( "special", SHARED, 10, 'custdel', NEW )
          ordsetfocus( 'key' )
          if dbseek( customer->key )
           locate for custdel->delivered < custdel->qty ;
                  while custdel->key = customer->key
           if found()
            Error("Outstanding Special Orders found! - Customer not deleted",12)
            custdel->( dbclosearea() )
            select customer
            loop
           endif
          endif
          custdel->( dbclosearea() )
         endif

#ifdef PREPACK     // Hopefully will fix the 'Mostly Items' Syndrome
         if Netuse( 'students', SHARED, 10, 'studdel' )
          studdel->( ordsetfocus( 'key' ) )
          while dbseek( customer->key )
           Del_rec( 'studdel', UNLOCK )
          enddo
          studdel->( dbclosearea() )
         endif
#endif

         if Netuse( "layby", SHARED, 10, 'custdel', NEW )
          ordsetfocus( 'key' )
          mfound := dbseek( customer->key )
          custdel->( dbclosearea() )
          if mfound
           Error("Outstanding layby's found! - Customer not deleted",12)
           select customer
           loop
          endif
         endif

         if Netuse( "debtrans", SHARED, 10, 'dbt', NEW )
          if dbseek( customer->key )
           Error("Debtor Transactions found! - Cannot Delete",12)
          else
           if Netuse( "invline", SHARED, 5, 'inl', NEW )
            if Netuse( "invhead", SHARED, 5, 'inh', NEW )
             ordsetfocus( 'key' )
             set relation to inh->number into inl
             if dbseek( customer->key )
              while inh->key = customer->key .and. !eof()
               select inl
               while inl->number = inh->number .and. !eof()
                Del_rec( 'inl', UNLOCK )
                inl->( dbskip() )
               enddo
               Del_rec( 'inh', UNLOCK )
               inh->( dbskip() )
              enddo
             endif
             custcate->( dbseek( customer->key ) )
             while custcate->key = customer->key .and. !custcate->( eof() )
              Del_rec( 'custcate', UNLOCK )
              skip alias custcate
             enddo
             SysAudit( "CustDel" + trim( customer->key ) )
             Del_rec( 'customer' )
             customer->( dbrunlock() )
             Error('Customer Deleted',14)
             inh->( dbclosearea() )
            endif
            inl->( dbclosearea() )
           endif
          endif
          dbt->( dbclosearea() )
         endif
        endif
        select customer
        eval( custobj:skipblock , -1 )
       endif
      endif
      select customer
      custobj:refreshall()
     endcase
    endif
   enddo
   Box_Restore( mscr )
  endif
 endif
enddo
return FALSE

*

procedure CustAdd ( isdebtor )
local midnum, testkey, mkey, mrec
if isdebtor
 if !Secure( X_ADDFILES )
  return
 endif
endif
select customer
Add_rec()
customer->sort_ord := 'T'
customer->op_it := !Bvars( B_OPENITEM )
customer->debtor := isdebtor
customer->entered := Bvars( B_DATE )
customer->disc_type := 'A'

CustScr( TRUE )

if empty( customer->key ) .or. empty( customer->name ) .or. lastkey() = K_ESC

 Del_rec( 'customer', UNLOCK )

 if lastkey() != K_ESC
  Error('You must enter at least a key and a name',12)
 else
  Error('Last Key hit was <ESC> - Customer ' + trim( customer->name ) + ' deleted', 12 )
 endif

else

 customer->( dbclearfilter() )
 midnum := 1
 mrec := customer->( recno() )
 testkey := customer->key

#ifdef UNIQUE_CUST_KEY
 mkey := testkey
#else
 mkey := trim( testkey ) + padl( midnum, 3, '0' )
#endif

 customer->( ordsetfocus( BY_KEY ) )

 while TRUE
  customer->( dbseek( mkey ) )
#ifdef UNIQUE_CUST_KEY
  locate for customer->key = mkey .and. customer->( recno() ) != mrec while customer->key = mkey
#endif
  if found()
#ifdef UNIQUE_CUST_KEY
   Error( 'Your Customer key of ' + trim( mkey ) + ' is not Unique! - BPOS will create a Unique key', 12, , ;
          'Key ' + trim( mkey ) + ' currently belongs to ' + trim( customer->name ) )
#endif
   midnum++
   mkey := trim( testkey ) + padl( midnum, 3, '0' )
  else
   goto mrec
   exit
  endif
 enddo

 Rec_lock( 'customer' )
 customer->key := mkey
 customer->( dbrunlock() )
 keyboard customer->key + chr( K_ENTER )

endif
return

*

procedure DebTypeChange
if Secure( X_EDITFILES )
 if !customer->debtor
  customer->debtor := TRUE
  customer->op_it := !Bvars( B_OPENITEM )
  Highlight( 02, 40, '', 'Debtor' )
 else
  if customer->amtcur != 0 .or. customer->amt30 != 0 .or. ;
     customer->amt60 != 0 .or. customer->amt90 != 0
   Error( 'Customer has account balance - Cannot change status', 12 )
  else
   if Netuse( "debtrans", SHARED, 10, 'dbt', NEW )
    if dbseek( customer->key )
     Error( 'Debtor Transactions found! - Cannot Change Status', 12 )
    else
     customer->debtor := FALSE
    endif
    dbt->( dbclosearea() )
   endif
   select customer
  endif
 endif
 SysAudit("DebChg"+customer->key)
endif
return

*

function CustScr ( newrec )
local getlist:={}, oldcur, mkey
local mscr := Box_Save()
local okf1 := setkey( K_F1, { || CustHelp() } )
local sFunKey3 := setkey( K_F3, { || Hold_em( FALSE, TRUE ) } )  // No refresh, order by key
local sFunKey4 := setkey( K_F4, { || ChangeCustKey() } )
local okf6 := setkey( K_F6, nil )
local okf5 := setkey( K_F5, { || ReverseStop() } )
local okf8 := setkey( K_F8, nil )
local okf9 := setkey( K_F9, { || CustSales() } )
local okf10 := setkey( K_F10, { || CustEdScr( newrec ) } )
#ifdef NO_SEE_UM
 local okf11 := setkey( K_F11, { || DispCredCard() } )
#endif
local okafa := setkey( K_ALT_A, { || abs_edit( "customer" ) } )

CustDispScr( newrec )

if newrec
 CustEdScr( TRUE )
endif

setkey( K_F6, { || Custcate() } )

while TRUE
 oldcur:=setcursor(0)
 mkey := inkey(0)
 setcursor( oldcur )
 if setkey(mkey) != nil
  eval(setkey(mkey))
 else
  exit
 endif
enddo

setkey( K_F1, okf1 )
setkey( K_F3, sFunKey3 )
setkey( K_F4, sFunKey4 )
setkey( K_F6, okf6 )
setkey( K_F5, okf5 )
setkey( K_F8, okf8 )
setkey( K_F9, okf9 )
setkey( K_F10, okf10 )
setkey( K_ALT_A, okafa )

#ifdef NO_SEE_UM
  setkey( K_F11, nil )

#endif

Box_Restore( mscr )
return TRUE

*

Function CustDispScr
Box_Save( 01, 00, 24, 79, C_CYAN )
Heading( 'Customer Data Entry Form' )
// Highlight( 02, 73, '', if( !empty( customer->abs_ptr ),  'Abs', '' ) )
if customer->debtor
 Highlight( 02, 50, '', 'Customer is a Debtor' )
endif
if customer->stop
 Highlight( 2, 28, '', '*** Stopped ***' )
endif
Highlight( 02, 01, 'Customer Key', customer->key  )
Highlight( 03, 02, '       Name', customer->name )
#ifdef BILL_TO_KEY
Highlight( 04, 01, ' Bill to Key' , customer->bill_key )
#endif
#ifdef EXTRA_KEY
Highlight( 4, 25, EXTRA_KEY_NAME , customer->extra_key )
#endif
Highlight( 05, 02, '    Contact' , customer->contact )
Highlight( 06, 02, 'Address (Postal)', '' )
Highlight( 07, 01, '', customer->add1 )
Highlight( 08, 01, '', customer->add2 )
Highlight( 09, 01, '', customer->add3 )
Highlight( 10, 02, 'Postcode', customer->pcode )
Highlight( 06, 40, 'Address (Delivery)', '' )
Highlight( 07, 39, '', customer->dadd1 )
Highlight( 08, 39, '', customer->dadd2 )
Highlight( 09, 39, '', customer->dadd3 )
Highlight( 10, 40, 'Postcode', customer->dpcode )
Highlight( 12, 02, '   Phone 1', customer->phone1 )
Highlight( 13, 02, '   Phone 2', customer->phone2 )
Highlight( 14, 02, '       Fax', customer->fax )
if customer->debtor
 Highlight( 11, 38, ' Cred Limit', Ns( customer->c_limit ) )
 Highlight( 12, 40, '     Bank', customer->bank )
 Highlight( 13, 40, '   Branch', customer->branch )
 Highlight( 15, 01, ' Open Items', if( customer->op_it, 'Y', 'N' ) )
endif
if !TRUE
 Highlight( 14, 39, 'Tax Exempt', if( customer->exempt, 'Y', 'N' ) )
 Highlight( 14, 52, 'Tax Number', customer->salestaxno )
endif
#ifndef NO_SEE_UM
// Highlight( 16, 02, 'Credit Cd', customer->credit_card )
#endif
Highlight( 16, 46, 'SAN', customer->san )
Highlight( 17, 04, '   Email', customer->email )
Highlight( 18, 04, 'Comments', customer->comments )
Highlight( 17, 64, 'S/O Letters', if( customer->spec_let, 'Y', 'N' ) )
Highlight( 18, 54, 'Inv Sort Order (OTAN)', customer->sort_ord )
Highlight( 19, 02, ' Cust Type', customer->type )
Highlight( 19, 22, '  SalesRep', customer->salesman )
Highlight( 20, 02, '      Area', customer->area )
if Bvars( B_MATRIX )
 Highlight( 21, 02 , ' Disc Type', customer->disc_type )
endif
#ifdef MULTI_COMPANY
Highlight( 21, 30, 'Company Code', customer->company )
#endif
Highlight( 22, 02, 'Customer since', dtoc( customer->entered ) )
Highlight( 22, 40, 'Last Sale', dtoc( customer->date_lp ) )

return nil

*

function CustEdScr
local getlist := {}

local okf1 := setkey( K_F1, nil )
local sFunKey3 := setkey( K_F3, nil )  // No refresh, order by key
local sFunKey4 := setkey( K_F4, nil )
local okf5 := setkey( K_F5, nil )
local okf6 := setkey( K_F6, nil )
local okf7 := setkey( K_F7, nil )
local okf8 := setkey( K_F8, nil )
local okf9 := setkey( K_F9, nil )
local okf10 := setkey( K_F10, nil )
#ifdef NO_SEE_UM
  local okf11 := setkey( K_F11, nil )

#endif
local okafa := setkey( K_ALT_A, nil )

if empty( customer->key )
 @ 02, 14 get customer->key pict NEW_CUST_KEY_PICT
endif

@ 03, 14 get customer->name pict '@s35'

#ifdef BILL_TO_KEY
@ 04, 14 get customer->bill_key pict '@!' ;
        valid( empty( customer->bill_key ) .or. BillKeyCheck( customer->bill_key ) )
#endif

#ifdef EXTRA_KEY
@ 04, 40 get customer->extra_key pict '@!'
#endif

@ 05, 14 get customer->contact pict '@s35'
@ 07, 02 get customer->add1 pict '@s35'
@ 08, 02 get customer->add2 pict '@s35'
@ 09, 02 get customer->add3 pict '@s35'
@ 10, 11 get customer->pcode pict '9999'
@ 07, 40 get customer->dadd1 pict '@s35'
@ 08, 40 get customer->dadd2 pict '@s35'
@ 09, 40 get customer->dadd3 pict '@s35'
@ 10, 49 get customer->dpcode pict '9999'
@ 12, 13 get customer->phone1 pict '@!'
@ 13, 13 get customer->phone2 pict '@!'

@ 14, 13 get customer->fax pict '@!'


if customer->debtor
 @ 11, 50 get customer->c_limit pict '999999'
 @ 12, 50 get customer->bank
 @ 13, 50 get customer->branch
 if customer->amtcur = 0 .and. customer->amt30 = 0 .and. customer->amt60 = 0 ;
   .and. customer->amt90 = 0
  @ 15, 13 get customer->op_it pict 'y'
 endif
endif

if !TRUE
 @ 14, 50 get customer->exempt pict 'y'
 @ 14, 63 get customer->salestaxno pict '@!'

endif

@ 16, 50 get customer->san pict '@!'
@ 17, 13 get customer->email
@ 18, 13 get customer->comments pict '@s35'


@ 17, 76 get customer->spec_let pict 'y'
@ 18, 76 get customer->sort_ord pict '!'

@ 19, 13 get customer->type pict '!'

@ 19, 33 get customer->salesman pict '@!' ;
       valid( empty( customer->salesman ) .or. Dup_chk( customer->salesman, "salesrep" ) )

@ 20, 13 get customer->area pict '@!'

if Bvars( B_MATRIX )
 @ 21, 13 get customer->disc_type pict '!' ;
          valid( ( customer->disc_type >= 'A' .and. customer->disc_type <= 'Z' );
          .or. !Bvars( B_MATRIX ) )
endif

#ifdef MULTI_COMPANY
@ 21, 43 get customer->company pict '!!' valid( Dup_chk( customer->company, 'companys' ) )
#endif

Rec_lock( 'customer' )

read

customer->( dbrunlock() )

setkey( K_F1, okf1 )
setkey( K_F3, sFunKey3 )
setkey( K_F4, sFunKey4 )
setkey( K_F5, okf5 )
setkey( K_F6, okf6 )
setkey( K_F7, okf7 )
setkey( K_F8, okf8 )
setkey( K_F9, okf9 )
setkey( K_F10, okf10 )
setkey( K_ALT_A, okafa )

#ifdef NO_SEE_UM
  setkey( K_F11, nil )

#endif

CustDispScr( FALSE )

return nil

*

Function CustHelp
local aArray := { { '<F3>', 'Check Holds' }, ;
                { '<F4>', 'Change Customer Key' }, ;
                { '<F5>', 'Reverse Stop Status' } }
if !empty( customer->key )
 aadd( aArray, { '<F6>', 'Categories' } )
endif
aadd( aArray, { '<F7>', 'Debtor Status' } )
aadd( aArray, { '<F9>', 'Purchases' } )
aadd( aArray, { '<Alt-A>', 'Edit Abstract' } )
Build_help( aArray )
return nil
*

function BillKeyCheck ( mbillkey )
local mrec:=customer->( recno() ), mret := FALSE, oldord:=ordsetfocus( BY_KEY )
mret := customer->( dbseek( mbillkey ) )
if !mret
 Error( 'Bill to key not on file', 12, ,'You must have an existing customer key as a Bill to Key' )
endif
customer->( dbgoto( mrec ) )
ordsetfocus( oldord )
return mret

*

procedure CustDisp
Box_Save( 01, 00, 08, 79 )
Highlight( 02, 02, '          Name', customer->name )
Highlight( 03, 02, '       Contact', customer->contact )
Highlight( 04, 02, 'Address Line 1', customer->add1 )
Highlight( 05, 02, '        Line 2', customer->add2 )
Highlight( 06, 02, '        Line 3', customer->add3 )
Highlight( 07, 02, 'Comments', substr( customer->comments, 1, 20 ) )
Highlight( 02, 52, 'Cust. Key', customer->key )
Highlight( 03, 52, 'Phone (H)', customer->phone1 )
Highlight( 04, 52, 'Phone (W)', customer->phone2 )
Highlight( 06, 52, 'Pcode', customer->pcode )
return

*

procedure ReverseStop
if Secure( X_EDITFILES )
 Rec_lock( 'customer' )
 customer->stop := !customer->stop
 if customer->stop
  Syscolor( C_MAUVE )
 endif
 Highlight(02,01,'Customer Key',customer->key)
 Syscolor( C_NORMAL )
 SysAudit( "RevStop" + trim( customer->key ) )
endif
return

*

procedure CustCate
local mscr, cscr, custkey:=customer->key, getlist:={}
local mcode, mkey, enqbrow, olddbf:=select(), mqty
if Netuse( "category", SHARED, 10, "CA" )
 if Netuse( "custcate", SHARED, 10, "CC" )
  set relation to cc->code into ca
  seek custkey
  cscr:=Box_Save(1,39,22,77)
  enqbrow:=tbrowsedb(2,42,21,76)
  enqbrow:HeadSep:=HEADSEP
  enqbrow:ColSep:=COLSEP
  enqbrow:goTopBlock:={ || dbseek( custkey ) }
  enqbrow:goBottomBlock:={ || jumptobott( custkey ) }
  enqbrow:skipBlock:=Keyskipblock( { || cc->key }, custkey )
  enqbrow:addcolumn( tbcolumnnew( "Code", { || cc->code } ) )
  enqbrow:addcolumn( tbcolumnnew( "Name", { || ca->name } ) )
  mkey:=0
  while TRUE
   enqbrow:forcestable()
   mkey:=inkey(0)
   if !navigate(enqbrow,mkey)
    do case
    case mkey == K_INS
     mscr := Box_Save( 02, 02, 04, 38 )
     mcode := space(6)
     mqty := 0
     @ 03,05 say 'New Category' get mcode pict '@!' valid( Dup_chk( mcode, "category" ) )
     read
     if updated()
      seek custkey
      locate for cc->code = mcode while cc->key = custkey
      if found()
       Error("Category already Attached to Customer",12)

      else
       Add_rec('cc')
       cc->code := mcode
       cc->key := custkey
       dbrunlock()

      endif
      seek custkey
      enqbrow:refreshall()

     endif
     Box_Restore( mscr )
    case mkey == K_DEL
     if Isready( 12, 02, 'Ok to delete ' + cc->code + ' from customer' )
      Del_rec( 'cc', UNLOCK )
      eval( enqbrow:skipblock , -1 )
      enqbrow:refreshall()
     endif
    case mkey == K_ESC .or. mkey == K_END
     exit
    endcase
   endif
  enddo
  Box_Restore( cscr )
  cc->( dbclosearea() )
  ca->( dbclosearea() )
 endif
endif
select (olddbf)
return

*

func i ( mfield ) //This tiny proc overcomes space limits in label definitions
return customer->( mfield )

*

func DebtSwap ( mord )
mord := if( mord = 1, 2, 1 )
ordsetfocus( mord )
Custdispmode( mord )
return nil

*

func CustDispMode
Highlight( 6, 30, '<F6>', 'Search by ' + if( indexord() = 1, 'Key ', 'Name' ) )
return nil

*

function ChangeCustKey
local newkey := space( 10 ), tscr := Box_Save( 02, 10, 04, 40 ), keyfocus
local oldkey := customer->key, mscr,  mrec, x, olddbf, getlist := {}
local dbflist:={"custcate","debtrans","invhead","layby",;
                "special","salehist","pickslip","po","hold",;
                "arhist","approval","sales","psales","debbank","students"}
local sFunKey4 := setkey( K_F4, nil )
@ 3,12 say 'New Customer Key' get newkey pict '@!'
read
Box_Restore( tscr )
if updated()
 mrec := recno()
 if customer->( dbseek( newkey ) )
  Error('Customer Key already in use - Key not changed',12, ,substr( customer->name, 1, 40 ))
 else
  mscr:=Box_Save( 2, 8, 4, 72 )
  @ 3,10 say 'About to change all occurences of ' + trim( oldkey ) + ' to ' + newkey
  if Isready( 12 )
   Box_Restore( mscr )
   olddbf:=select()
   mscr:=Box_Save( 2, 8, 4, 72 )
   Center( 3, 'Exchanging Key on Customer file', TRUE )
   select customer
   goto mrec
   Rec_lock()
   replace oldKey with customer->Key                              // SWW 21/12/95
   replace key with newkey
   for x := 1 to len( dbflist )
    keyfocus := FALSE
    if Netuse( dbflist[x], SHARED, 10, 'keychg' )
     Center( 3, '   Exchanging Key on ' + dbflist[x] + ' file   ', TRUE )
     if ordnumber( 'key' ) != 0
      ordsetfocus( 'key' )
      dbseek( oldkey )
      keyfocus := TRUE
     else
      locate for keychg->key == oldkey  // no index by id for dbf so seek by locate
     endif
     while found()
      Rec_lock( 'keychg' )
      keychg->key := newkey
      keychg->( dbrunlock() )
      if keyfocus
       dbseek( oldkey )
      else
       keychg->( dbskip() )
       continue
      endif
     enddo
     keychg->( dbclosearea() )
    endif
   next
  endif
  Box_Restore( mscr )
 endif
 select customer
 goto mrec
 Highlight(02,01,'Customer Key',customer->key)
endif
setkey( K_F4, sFunKey4 )
return nil

*

#ifdef NO_SEE_UM
Function DispCredCard
setkey( K_F11, nil)
setkey( K_F11, { || DispCredCard() } )
return nil
#endif

*

func CustSales
local mscr,o_dbf:=select(),enqbrow,retval:=0,getlist:={},oldrec:=recno()
local oldcur:=setcursor(1), tscr, totqty, totval, mrec, mkey, totdisc
local mcustkey := customer->key, totret, totretval
local sFunKey4, okf5, okf6, okf8, okf9, okf10

if select( 'master' ) = 0
 if !Master_use()
  return nil
 endif
endif
sFunKey4 := setkey( K_F4, nil )
okf5 := setkey( K_F5, nil )
okf6 := setkey( K_F6, nil )
okf8 := setkey( K_F8, nil )
okf9 := setkey( K_F9, nil )
okf10 := setkey( K_F10, nil )
if Netuse( "salehist", SHARED, 10, 'ehist' )
 ordsetfocus( 'key' )
 set relation to ehist->id into master
 if !dbseek( mcustkey )
  Error("No sales History on File",12)
 else
  mscr:=Box_Save( 1, 39, 24-2, 79-3, 8 )
  enqbrow:=tbrowsedb(2,40,24-3,79-4)
  enqbrow:HeadSep:=HEADSEP
  enqbrow:ColSep:=COLSEP
  enqbrow:goTopBlock := { || dbseek( mcustkey ) }
  enqbrow:goBottomBlock := { || jumptobott( mcustkey ) }
  enqbrow:skipBlock := KeySkipBlock( { || ehist->key }, mcustkey )
  enqbrow:addcolumn( tbcolumnnew( "Desc", { || substr( master->desc, 1, 20) } ) )
  enqbrow:addcolumn( tbcolumnnew( "Date", { || ehist->date } ) )
  enqbrow:addcolumn( tbcolumnnew( "Qty", { || ehist->qty } ) )
  enqbrow:addcolumn( tbcolumnnew( "Sell", { || transform( ehist->unit_price-ehist->discount, '9999.99' ) } ) )
  enqbrow:addcolumn( tbcolumnnew( "Cost", { || transform( ehist->cost_price, '9999.99' ) } ) )
  enqbrow:addcolumn( tbcolumnnew( "Inv No", { || ehist->invno } ) )
  enqbrow:freeze := 1
  mkey := 0
  while mkey != K_ESC .and. mkey != K_END
   enqbrow:forcestable()
   mkey:=inkey(0)
   if !navigate(enqbrow,mkey)
    do case
    case mkey == K_F10   // Edit a line item in history
     if Secure( X_EDITFILES )
      tscr := Box_Save( 2,10,4,70 )
      Rec_lock()
      @ 3,12 say 'Date' get date valid( !empty( ehist->date ) )
      @ 3,50 say 'Qty' get qty valid ( !empty( ehist->qty ) )
      read
      dbrunlock()
      Box_Restore( tscr )
     endif
    case mkey == K_F8
     mrec := ehist->( recno() )
     dbseek( mcustkey, TRUE )
     totret := 0
     totretval := 0
     totqty := 0
     totval := 0
     totdisc := 0
     while ehist->key = mcustkey .and. Pinwheel( NOINTERUPT )
      if ehist->qty > 0
       totqty += ehist->qty
       totval += ( ehist->unit_price - ehist->discount ) * ehist->qty
      else
       totret += ehist->qty
       totretval += ( ehist->unit_price - ehist->discount ) * ehist->qty
      endif
      totdisc += ehist->discount
      skip alias ehist
     enddo
     ehist->( dbgoto( mrec ) )
     tscr := Box_Save( 2, 1, 9, 35 )
     Highlight( 3, 3, 'Total Items Sold    ', Ns( totqty ) )
     Highlight( 4, 3, 'Total Nett Sales   $', Ns( totval, 10, 2 ) )
     Highlight( 5, 3, 'Total Discounts    $', Ns( totdisc, 10, 2 ) )
     Highlight( 6, 3, 'Total Items Ret     ', Ns( totret ) )
     Highlight( 7, 3, 'Total Nett Returns $', Ns( totretval, 10, 2 ) )
     Highlight( 8, 3, 'Sales / Returns %   ', Ns( abs(totretval)/(totval/100) ) +'%' )
     Error( '', 12 )
     Box_Restore( tscr )
    endcase
   endif
  enddo
  Box_Restore( mscr )
 endif
 ehist->( dbclosearea() )
endif
select ( o_dbf )
goto oldrec
setcursor( oldcur )
setkey( K_F4, sFunKey4 )
setkey( K_F5, okf5 )
setkey( K_F6, okf6 )
setkey( K_F8, okf9 )
setkey( K_F9, okf9 )
setkey( K_F10, okf10 )
return nil

*

procedure CustCats

local curr_code, counter := 1
local i, x:=1, custkey := '', custname := ''
local by_key := 'K'
local getlist:={}
local scrn, aArray:={}
local page_number:=1
local page_width:=132
local page_len:=66
local top_mar:=0
local bot_mar:=10
local report_name := ''
local pwidth := lvars( val( substr( lvars( L_PRINTER ), 4, 1 ) ) + 7 )
local cats, choice

Box_Save( 16, 04, 20, 19 )
aadd( aArray, { "Print" } )
aadd( aArray, { "All Customers" } )
aadd( aArray, { "Starting From" } )
choice := MenuGen( aArray, 16, 04, 'Categories')

if choice > 1
 if choice = 3
  if CustFind( FALSE )
   custname := customer->name
   custkey := padl(customer->key,10,'0')
  endif
 endif
 if !( empty(custname) .and. empty(custkey) ) .or. choice = 2
  scrn := Box_Save(10,25,14,56)
  @ 12,27 say 'Sort on Key or Name (K/N):' get by_key valid by_key == 'K' .or. by_key = 'N' pict '@!'
  read
  if Isready(12)
   select custcate
   set index to
   custcate->( dbclearrel() )

   set relation to custcate->key into customer, custcate->code into category
   if by_key == 'K'
    indx("padl( key, 10, '0' ) + code", 'key' )
    report_name := 'Category Listing Sorted by Customer Key'

   else
    indx("customer->name+key+code", 'name')
    report_name := 'Category Listing Sorted by Customer Name'

   endif

   if choice = 2
    custcate->( dbgotop() )
   else
    set softseek on
    if by_key == 'K'
     custcate-> ( dbseek( alltrim(custkey) ) )
    else
     custcate-> ( dbseek( alltrim(custname) ) )
    endif
    set softseek off
   endif


   Setprc(0,0)

   Print_find("report")

   if pwidth = 132
 //   // Pitch10()

   else
 //   // Pitch17()

   endif

   set device to print
   set console off

   PageHead( report_name, page_width, page_number )
   @ prow()+1,0 say replicate( chr( 196 ), 132 )
   page_number ++

   while !custcate->( eof() ) .and. Pinwheel()
    cats := array( 3, 500 )
    for i := 1 to 3
     while empty( customer->key ) .and. !custcate->( eof() )
      skip alias custcate
     enddo
     if custcate->( eof() )
      exit
     endif
     x := 1
     curr_code := custcate->key
     cats[ i, 1 ] := customer->key
     cats[ i, 2 ] := customer->name
     cats[ i, 3 ] := if( !empty( customer->contact ),'Attn: ' + customer->contact,'')
     cats[ i, 4 ] := customer->add1
     cats[ i, 5 ] := if(empty(customer->add3),alltrim(customer->add2)+'  '+customer->pcode,customer->add2)
     cats[ i, 6 ] := if(!empty(customer->add3),alltrim(customer->add3)+'  '+customer->pcode,'')
     cats[ i, 7 ] := "Code      Category Name"
     cats[ i, 8 ] := replicate( chr(196), 28 )
     x := 9
     while ( custcate->key == curr_code ) .and. !eof()
      cats[ i, x ] := padr( custcate->code, 10, ' ' ) + category->name
      x++
      custcate->( dbskip() )
     enddo
    next
    x := 1
    while cats[ 1, x ] != nil .or. cats[ 2, x ] != nil .or. cats[ 3, x ] != nil
     if cats[ 1, x ] != nil
      @ prow()+1, 4 say cats[ 1, x ]
     else
      @ prow()+1, 0 say ''
     endif
     if cats[ 2, x ] != nil
      @ prow(), 48 say cats[ 2, x ]
     endif
     if cats[ 3, x ] != nil
      @ prow(), 92 say cats[ 3, x ]
     endif

     if PageEject( 66, top_mar, bot_mar )
      PageHead( report_name, page_width, page_number )
      @ prow()+1, 0 say replicate( chr( 196 ), 132 )
      @ prow()+1, 0 say ''
      page_number ++
     endif

     x++
    enddo

    @ prow()+1,0 say replicate( chr( 196 ), 132 )
    if counter = 2 .and. !eof()
     eject
     PageHead( report_name, page_width, page_number )
     @ prow()+1,0 say replicate( chr( 196 ), 132 )
     @ prow()+1,0 say ''
     page_number ++
     counter := 0
    else
     @ prow()+1,0 say replicate( chr( 196 ), 132 )
    endif
    counter ++
    x := 1
   enddo
   // Pitch10()
   Endprint()
   set device to screen
   set console on
   select custcate
   custcate->( dbclearrel() )
   set relation to custcate->code into category

  endif
 endif
endif
return

*

procedure CustAreas()
local farr:={},getlist:={},scrn,oldarea:=select()
memvar area_code
private area_code := space(4)

scrn := Box_Save(11,30,13,51)
@ 12,27 say 'Customer Area' get area_code pict "@!"
read
if IsReady( 14 )

 select customer
 customer -> ( dbgotop() )
 aadd(farr,{'customer->name','Name',25,0,FALSE})
 aadd(farr,{'customer->contact','Contact',20,0,FALSE})
 aadd(farr,{'trim(customer->add1)+" "+trim(customer->add2)+" "+trim(customer->add3)','Address',50,0,FALSE})
 aadd(farr,{'customer->pcode','Post;Code',4,0,FALSE})
 aadd(farr,{'customer->phone1','Telephone1',14,0,FALSE})
 aadd(farr,{'customer->ytdamt','Ytd;Sales',10,2,TRUE})
 Print_find("report")

 Reporter(farr,"'Listing of Customers For Area ('+area_code+') '",;
 '','','','',FALSE,'customer->area == area_code')

 select (oldarea)

endif
Box_Restore(scrn)
return

*

procedure StopCust()
local farr := {},getlist:={},oldarea:=select()

if IsReady( 14 )

 select customer
 customer -> ( dbgotop() )
 aadd(farr,{'customer->key','Key',10,0,FALSE})
 aadd(farr,{'customer->name','Name',25,0,FALSE})
 aadd(farr,{'customer->contact','Contact',20,0,FALSE})
 aadd(farr,{'trim(customer->add1)+" "+trim(customer->add2)+" "+trim(customer->add3)','Address',50,0,FALSE})
 aadd(farr,{'customer->pcode','Post;Code',4,0,FALSE})
 aadd(farr,{'customer->phone1','Telephone1',14,0,FALSE})

 Print_find("report")

 Reporter(farr,"'Listing of Customers On Stop'",'','','','',FALSE,'customer->stop = .t.')

 select (oldarea)

endif
return
