/*

      Maindept.prg
        
      Last change:  TG   18 Oct 2010    9:44 pm
*/
Procedure f_department

#include "bpos.ch"

local lGo := FALSE,choice,oldscr:=Box_Save()
local mdept,mscr,mdept2,x,y,last_year,this_year,gchoice
local mjan,mfeb,mmar,mapr,mmay,mjun,mjul,maug,msep,moct,mnov,mdec,mcat
local report_name,page_width,page_number,col_head1,col_head2,top_mar,bot_mar
local tlycost,tlysell,ttycost,ttysell,lycost,lysell,tycost,tysell
local weeknum,page_len,ly,ty,start_week,first_day,p_sel,this_arr,last_arr
local getlist:={}, mstr, tot_lysell, tot_tysell, s, mtot, aArray, farr

if Netuse( "deptmove" )
 if Netuse( "dept" )
  lGo := TRUE
 endif
endif

while lGo

 Box_Restore( oldscr )
 Heading( 'Department File Maintenance Menu' )
 aArray := {}
 aadd( aArray, { 'File', 'Return to file Maintenance Menu' } )
 aadd( aArray, { 'Add', 'Add New Departments' } )
 aadd( aArray, { 'Change', 'Change Department Details' } )
 aadd( aArray, { 'Global', 'Global Department Changes' } )
 aadd( aArray, { 'Print', 'Print Department Details' } )
 choice := MenuGen( aArray, 07, 02, 'Department' )

 mdept := space( DEPT_CODE_LEN )

 do case
 case Choice = 2
  Heading('Department File Add')
  @ 9,10 say 'ÍÍÍ¯ New Department Code' get mdept pict '@!'
  read
  if updated()
   if dept->( dbseek( mdept ) )
    Box_Save(11,08,13,72)
    Center(12,'Department Name ÍÍÍ¯ ' + dept->name )
    Error('Department Code already on file',14)
   else
    Add_rec('dept')
    dept->code := mdept
    Box_Save(08,07,15,72)
    Highlight(09,10,'Department Code',mdept)
    @ 11,10 say 'Department Name' get dept->name
    @ 13,10 say '  Lineal Metres' get dept->shelf_len pict '9999.99'
    read
    if empty(dept->name)
     dept->( dbdelete() )
    endif
    dept->( dbrunlock() )
   endif
  endif

 case Choice = 3
  Heading('Change Department Details')
  @ 10,10 say 'ÍÍÍ¯ Department Code' get mdept pict '@!';
          valid( Dup_chk( mdept , "dept" ) )
  read
  if updated()
   dept->( dbseek( mdept ) )
   Box_Save(08,07,15,72)
   Highlight( 09,10, 'Department Code', mdept )
   @ 11,10 say 'Department Name' get dept->name
   @ 13,10 say '  Lineal Metres' get dept->shelf_len pict '9999.99'
   @ 19,0 clear to 23,79
   Center( 19,'Stock Movement',TRUE )
   @ 20,06 say 'Jan   Feb   Mar   Apr   May   Jun   Jul   Aug   Sep   Oct   Nov   Dec'
   select deptmove
   dbseek(  trim( mdept ) )
   locate for deptmove->type = 'SAL' while deptmove->code = mdept .and. !eof()
   if found()
    @ 21,00 say 'Sales'
    @ 21,06 say abs(deptmove->jan) pict '@B 99999'
    @ 21,12 say abs(deptmove->feb) pict '@B 99999'
    @ 21,18 say abs(deptmove->mar) pict '@B 99999'
    @ 21,24 say abs(deptmove->apr) pict '@B 99999'
    @ 21,30 say abs(deptmove->may) pict '@B 99999'
    @ 21,36 say abs(deptmove->jun) pict '@B 99999'
    @ 21,42 say abs(deptmove->jul) pict '@B 99999'
    @ 21,48 say abs(deptmove->aug) pict '@B 99999'
    @ 21,54 say abs(deptmove->sep) pict '@B 99999'
    @ 21,60 say abs(deptmove->oct) pict '@B 99999'
    @ 21,66 say abs(deptmove->nov) pict '@B 99999'
    @ 21,72 say abs(deptmove->dec) pict '@B 99999'
   endif
   seek trim(mdept)
   locate for deptmove->type = 'REC' while deptmove->code = mdept .and. !eof()
   if found()
    @ 22,00 say 'Recv'
    @ 22,06 say deptmove->jan pict '@B 99999'
    @ 22,12 say deptmove->feb pict '@B 99999'
    @ 22,18 say deptmove->mar pict '@B 99999'
    @ 22,24 say deptmove->apr pict '@B 99999'
    @ 22,30 say deptmove->may pict '@B 99999'
    @ 22,36 say deptmove->jun pict '@B 99999'
    @ 22,42 say deptmove->jul pict '@B 99999'
    @ 22,48 say deptmove->aug pict '@B 99999'
    @ 22,54 say deptmove->sep pict '@B 99999'
    @ 22,60 say deptmove->oct pict '@B 99999'
    @ 22,66 say deptmove->nov pict '@B 99999'
    @ 22,72 say deptmove->dec pict '@B 99999'
   endif
   seek trim(mdept)
   locate for deptmove->type = 'RET' while deptmove->code = mdept .and. !eof()
   if found()
    @ 23,00 say 'Retn'
    @ 23,06 say abs(deptmove->jan) pict '@B 99999'
    @ 23,12 say abs(deptmove->feb) pict '@B 99999'
    @ 23,18 say abs(deptmove->mar) pict '@B 99999'
    @ 23,24 say abs(deptmove->apr) pict '@B 99999'
    @ 23,30 say abs(deptmove->may) pict '@B 99999'
    @ 23,36 say abs(deptmove->jun) pict '@B 99999'
    @ 23,42 say abs(deptmove->jul) pict '@B 99999'
    @ 23,48 say abs(deptmove->aug) pict '@B 99999'
    @ 23,54 say abs(deptmove->sep) pict '@B 99999'
    @ 23,60 say abs(deptmove->oct) pict '@B 99999'
    @ 23,66 say abs(deptmove->nov) pict '@B 99999'
    @ 23,72 say abs(deptmove->dec) pict '@B 99999'
   endif
   Rec_lock('dept')
   read
   dept->( dbrunlock() )
  endif
 case choice = 4
  Heading('Global Department Change')
  aArray := {}
  aadd( aArray, { 'Exit', 'Return to Category Menu' } )
  aadd( aArray, { 'Dept', 'Change all ' + ITEM_DESC + ' from one Department to another' } )
  aadd( aArray, { 'Category', 'Change the department using a category code' } )
  gchoice := Menugen( aArray, 11, 03, 'Global' )

  do case
  case gchoice = 2
   if Secure( X_GLOBALS )
    Heading('Global Department Change')
    Box_Save(02,08,11,71)
    mdept := space( len( dept->code ) )
    mdept2 := mdept
    Heading('Change one Department into another')
    @ 03,10 say 'Enter Old Department Code' get mdept pict '@!';
            valid( Dup_chk( mdept , "dept" ) )
    read
    if !updated()
     loop
    else
     @ 05,10 say 'Enter Department to change to' get mdept2 pict '@!' ;
             valid( Dup_chk( mdept2 , "dept" ) )
     read
     if !updated()
      loop
     else
      Box_Save( 01, 08, 12, 70 )
      Heading( 'Global Department Change' )
      Center( 3, 'You are about to change all Master file records for -' )
      Center( 5, mdept + ' - to - ' + mdept2 )
      if Isready( 6 )
       if Isready( 12, 15, 'Again - are you sure this is correct' )
        if Netuse( "master", EXCLUSIVE )
         ordsetfocus(  )
         replace all department with mdept2 for master->department = mdept
         use
        endif
        if Netuse( "draft_po", EXCLUSIVE )
         ordsetfocus(  )
         replace department with mdept2 for draft_po->department = mdept
         use
        endif
        select deptmove
        mstr := 'RECSALRET'
        for x := 1 to 3
         seek mdept
         locate for deptmove->type = substr( mstr,x*3-2,3 ) ;
                while deptmove->code = mdept
         if found()
          mjan := deptmove->jan
          mfeb := deptmove->feb
          mmar := deptmove->mar
          mapr := deptmove->apr
          mmay := deptmove->may
          mjun := deptmove->jun
          mjul := deptmove->jul
          maug := deptmove->aug
          msep := deptmove->sep
          moct := deptmove->oct
          mnov := deptmove->nov
          mdec := deptmove->dec
          seek mdept2
          locate for deptmove->type = substr( mstr,x*3-2,3 ) ;
                 while deptmove->code = mdept2
          if !found()
           Add_rec()
           replace code with mdept2,;
                   type with substr( mstr,x*3-2,3 )
          endif
          Rec_lock()
          deptmove->jan += mjan
          deptmove->feb += mfeb
          deptmove->mar += mmar
          deptmove->apr += mapr
          deptmove->may += mmay
          deptmove->jun += mjun
          deptmove->jul += mjul
          deptmove->aug += maug
          deptmove->sep += msep
          deptmove->oct += moct
          deptmove->nov += mnov
          deptmove->dec += mdec
         endif
        next
        select dept
        if dbseek( mdept )
         Del_rec( , UNLOCK )
        endif
       endif
      endif
     endif
    endif
   endif
  case gchoice = 3
   Heading( 'Global using Category' )
   mcat := space( 6 )
   mdept := space( len( dept->code ) )
   mdept2 := space( len( dept->code ) )
   Box_Save( 02, 08, 11, 71 )
   @ 03, 10 say 'Category Code to Global' get mcat pict '@!' valid( Dup_chk( mcat , "category" ) )
   @ 04, 10 say 'Department Code' get mdept pict '@!' valid( Dup_chk( mdept , "dept" ) )
   read
   if lastkey() != K_ESC
    Center( 5, 'About to change the department of all ' + ITEM_DESC + '' )
    Center( 6, 'which have a category of ' + trim( Lookitup( 'category', mcat ) ) )
    Center( 7, 'to a department of ' + trim( Lookitup( 'dept', mdept ) ) )
    if Isready( 12 )
     if Netuse( 'master' )
      if Netuse( 'macatego' )
       set relation to macatego->id into master
       macatego->( dbseek( mcat ) )
       while macatego->code = mcat .and. !macatego->( eof() ) .and. Pinwheel( NOINTERUPT )
        Rec_lock( 'master' )
        master->department := mdept
        master->( dbrunlock() )
        skip alias macatego
       enddo
       macatego->( dbclosearea() )
      endif
      master->( dbclosearea() )
     endif   
    endif 
   endif 
  endcase 
 case Choice = 5
  Heading('Departments Print Menu')
  aArray := {}
  aadd( aArray, { 'Department', 'Return to Departments Menu' } )
  aadd( aArray, { 'Code', 'Print Departments by Code' } )
  aadd( aArray, { 'Purchases', 'Print Purchases/Department' } )
  aadd( aArray, { 'Sales', 'Print Sales/Department' } )
  aadd( aArray, { 'Movement', 'Print Movement/Department' } )
  aadd( aArray, { 'Weekly', 'Comparitive Weekly Sales' } )
  aadd( aArray, { 'YTD sales', 'Year to date Comparision' } )
  p_sel := Menugen( aArray, 12, 03, 'Print' )

  farr := {}
  aadd(farr,{'TYPE','Movement; Type',8,0,FALSE})
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
  
  Print_find( 'report' )
  
  do case
  case p_sel = 2
   Heading('Print Departments by Code')
   select dept
   go top
   if Isready(12)
    farr := {}
    aadd(farr,{'dept->code','Code',5,0,FALSE})
    aadd(farr,{'dept->name','Description',20,0,FALSE})
    Reporter(farr,'"Listing of Department Codes"','','','','',FALSE, , ,80)

   endif
  case p_sel = 3
   Heading('Receipts by Department by Month')
   if Isready(12)
    select deptmove
    go top

    Reporter(farr,'"Receipts by Department by Month"','code',;
    '"Department Code : "+code','','',FALSE,"deptmove->type = 'REC'")

    select dept
   endif
  case p_sel = 4
   Heading('Sales by Department by Month')
   if Isready(12)
    select deptmove
    go top
    Reporter(farr,'"Sales by Department by Month"','code',;
    '"Department Code : "+code','','',FALSE,"deptmove->type = 'SAL'")

    select dept
   endif

  case p_sel = 5
   Heading('Stock Movement by Department by Month')
   if Isready(12)
    select deptmove
    go top
    
    Reporter(farr,'"Stock Movement by Department by Month"','code',;
    '"Department Code : "+code','','',FALSE)

    s := array( 3,12 )
    sum deptmove->jan, deptmove->feb, deptmove->mar, deptmove->apr, deptmove->may, deptmove->jun, ;
        deptmove->jul, deptmove->aug, deptmove->sep, deptmove->oct, deptmove->nov, deptmove->dec ; 
        to s[1,1],s[1,2],s[1,3],s[1,4],s[1,5],s[1,6],s[1,7],s[1,8],s[1,9],s[1,10],s[1,11],s[1,12] ;
        for deptmove->type = 'SAL'
    sum deptmove->jan, deptmove->feb, deptmove->mar, deptmove->apr, deptmove->may, deptmove->jun, ;
        deptmove->jul, deptmove->aug, deptmove->sep, deptmove->oct, deptmove->nov, deptmove->dec ; 
        to s[2,1],s[2,2],s[2,3],s[2,4],s[2,5],s[2,6],s[2,7],s[2,8],s[2,9],s[2,10],s[2,11],s[2,12] ;
        for deptmove->type = 'RET'
    sum deptmove->jan, deptmove->feb, deptmove->mar, deptmove->apr, deptmove->may, deptmove->jun, ;
        deptmove->jul, deptmove->aug, deptmove->sep, deptmove->oct, deptmove->nov, deptmove->dec ; 
        to s[3,1],s[3,2],s[3,3],s[3,4],s[3,5],s[3,6],s[3,7],s[3,8],s[3,9],s[3,10],s[3,11],s[3,12] ;
        for deptmove->type = 'REC'

 //   // Pitch17()
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
    EndPrint()
    select dept
   endif
  case p_sel = 6
   if Secure( X_SALESREPORTS )
    SysAudit("DptWkComRe")
    Heading( 'Comparitive Weekly Sales Report' )
    first_day := ctod( "01/01/" + substr( ltrim( str( year( Bvars( B_DATE ) ) ) ), 3, 2 ) )
    weeknum := int( ( Bvars( B_DATE )-first_day )/7 ) + if( dow( first_day ) < 5, 1, 0 )
    this_year := ns( year( Bvars( B_DATE ) ) )
    last_year := ns( year( Bvars( B_DATE ) ) - 1 )
    start_week := 1
    mscr := Box_Save( 2, 20, 6, 60 )
    @ 3,22 say 'Starting Week number' get start_week pict '99' range 1,53
    @ 5,22 say this_year + space( 10 ) + last_year
    Highlight( 4, 22, 'Current Week is' , Ns( weeknum ) )
    read
    if Isready(12)
     if Netuse( "deptweek" )
      indx( "deptweek->code", 'code' )
      select dept
      set relation to dept->code into deptweek
      page_number:=1
      page_width:=132
      page_len:=66
      top_mar:=0
      bot_mar:=10
      col_head1 := 'Department    Yr'
      col_head2 := 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'
      for x := start_week to min( start_week+18, 53 )
       col_head1 += padl( 'W' + ns( x ) , 6 )
       col_head2 += ' ' + 'ÄÄÄÄÄ'
      next
      report_name := 'Sales by Department by Week Variance '
  //    // Pitch17()
      set device to print
      PageHead( report_name, page_width, page_number, col_head1, col_head2 )
      tot_lysell := {}
      tot_tysell := {}
      go top
      while !dept->(eof()) .and. Pinwheel()
       select deptweek
       locate for deptweek->year = last_year while deptweek->code = dept->code
       last_arr := {}
       if found()
        for x := start_week to min( start_week+18, 53 )
         aadd( last_arr, { fieldget( fieldpos( 'C' + Ns( x ) ) ), fieldget( fieldpos( 'S' + Ns( x ) ) ) } )
         aadd( tot_lysell, 0 )
        next
       endif
       seek dept->code
       locate for deptweek->year = this_year while deptweek->code = dept->code
       this_arr := {}
       if found()
        for x := start_week to min( start_week+18 , 53 )
         aadd( this_arr, { fieldget( fieldpos( 'C' + Ns( x ) ) ), fieldget( fieldpos( 'S' + Ns( x ) ) ) } )
         aadd( tot_tysell, 0 )
        next
       endif
       if len( last_arr ) != 0
        @ prow()+1,0 say substr( dept->name,1,13 ) + ' '+substr(last_year,3,2)
        for x := 1 to len( this_arr )
         @ prow(),x*6+11 say last_arr[x,2] pict '99999'
         tot_lysell[x] += last_arr[x,2]
        next
       endif
       @ prow()+1,0 say substr( dept->name,1,13 ) + ' '+substr(this_year,3,2)
       for x := 1 to len( this_arr )
        @ prow(),x*6+11 say this_arr[x,2] pict '99999'
        tot_tysell[x] += this_arr[x,2]
       next
       if len( last_arr ) != 0
        @ prow()+1,0 say substr( dept->name,1,13 ) + ' Va%'
        for x := 1 to len( this_arr )
         ly = last_arr[x,2]
         ty = this_arr[x,2]
         @ prow(),x*6+11 say (ty-ly)/(ly/100) pict '99999'
        next
       endif
       if PageEject( page_len, top_mar, bot_mar )
        page_number++
        PageHead( report_name, page_width, page_number, col_head1, col_head2 )
       endif
       @ prow()+1,0 say ''
       skip alias dept
      enddo
      @ prow()+1,0 say replicate( chr( 205 ) , 130 )
      if len( tot_lysell ) != 0
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
        @ prow(),x*6+11 say ( ty-ly )/( ly / 100 ) pict '99999'
       next
      endif
      set device to screen
      // Pitch10()
      endprint()
      select dept
      set relation to
      deptweek->( orddestroy( 'code' ) )
      deptweek->( dbclosearea() )
     endif
    endif
   endif
  case p_sel = 7
   if Secure( X_SALESREPORTS )
    SysAudit("YtdDeptRpt")
    Heading( 'Year to date Comparision' )
    first_day := ctod( "01/01/" + substr( ltrim( str( year( Bvars( B_DATE ) ) ) ), 3, 2 ) )
    weeknum := int( ( Bvars( B_DATE ) - first_day )/7 ) + if( dow( first_day ) < 5, 1, 0 )
    this_year := ns( year( Bvars( B_DATE ) ) )
    last_year := ns( year( Bvars( B_DATE ) ) - 1 )
    start_week := 0
    Box_Save( 02, 20, 04, 60 )
    Highlight( 03, 22, 'Week to Print to is ' , Ns( weeknum - 1 ) )
    if Isready(12)
     if Netuse( "deptweek"  )
      indx( "deptweek->code", 'code' )
      select dept
      set relation to dept->code into deptweek
      page_number:=1
      page_width:=80
      page_len:=66
      top_mar:=0
      bot_mar:=10
      ly := substr( last_year, 3, 2 )
      ty := substr( this_year, 3, 2 )
      col_head1 := 'Department         Cost ' + ly + '   Cost ' + ty + ;
                   '   Var %     Sell ' + ly + '   Sell ' + ty + '   Var %'
      col_head2 := replicate(chr(196),80)
      tlycost := 0
      tlysell := 0
      ttycost := 0
      ttysell := 0
      report_name := 'Ytd Sales Variance by Department to Week ' + Ns( weeknum - 1 )
      // Pitch10()
      set device to print
      PageHead( report_name, page_width, page_number, col_head1, col_head2 )
      while !dept->(eof()) .and. Pinwheel()
       select deptweek
       locate for deptweek->year = last_year while deptweek->code = dept->code
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
       seek dept->code
       locate for deptweek->year = this_year while deptweek->code = dept->code
       tycost := 0
       tysell := 0
       if found()
        for x := 1 to weeknum -1
         tycost += fieldget( fieldpos( 'C' + Ns( x ) ) )
         tysell += fieldget( fieldpos( 'S' + Ns( x ) ) )
        next
        ttycost += tycost
        ttysell += tysell
       endif

       @ prow()+1,0 say substr( dept->name,1,13 )
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
       dept->( dbskip() )
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
      endprint()
      select dept
      set relation to
      deptweek->( orddestroy( 'code' ) )
      deptweek->( dbclosearea() )
     endif
    endif
   endif
  endcase
 case Choice < 2
  lGo := FALSE
  exit
 endcase
 Box_Restore( oldscr )
enddo
dbcloseall()
return
