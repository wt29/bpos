/*

      Last change:  TG   29 Apr 2011    1:44 pm
*/
Procedure S_Approval

#include "bpos.ch"

#define AP_BY_NUM .t.
#define AP_BY_KEY .f.

local mgo:=FALSE, choice, oldscr:=Box_Save(), aArray
Center( 24,'Opening files for Approval' )
if Netuse( "customer" )
 if Netuse( "sales" )
  if Master_use()
   if Netuse( "approval" )
    set relation to approval->id into master,;
                 to approval->key into customer
    mgo := TRUE
   endif
  endif
 endif
endif
line_clear(24)
while mgo
 Box_Restore( oldscr )
 Heading("Approvals")
 aArray := {}
 aadd( aArray, { 'Sales', 'Return to Sales Menu' } )
 aadd( aArray, { 'Create', 'Create Approval Sale', { || Appradd() } } )
 aadd( aArray, { 'Return N', 'Scan in by Approval number', { || Apprret( AP_BY_NUM ) } } )
 aadd( aArray, { 'Return K', 'Scan in by Customer Key', { || Apprret( AP_BY_KEY ) } } )
 aadd( aArray, { 'Delete', 'Remove Approval from file', { || Apprdel() } } )
 aadd( aArray, { 'Enquire', 'Make Approval Enquiries', { || Laybyenq( 'approval' ) } } )
 aadd( aArray, { 'Print', 'Reports Menu', { || Appr_print() } } )
 aadd( aArray, { 'Purge', 'Remove old Approvals from file', { || Apprpurge() } } )
 choice := MenuGen( aArray, 10, 35, 'Approval' )
 if choice < 2
  exit

 else
  Eval( aArray[ choice, 3 ] )

 endif

enddo
close databases
return
*
procedure appradd

local mtot,mkey,mcomm,sID,mqty,mrec,mscr,mappno,x,getlist:={}
local mprint,mitems,mdef,keypress,appbrow
local mprice, adding, goloop, mpost_it, mfinish

while CustFind( NO )

 cls
 Heading('Enter Approval Details')

 if select( "apptemp" ) != 0
  apptemp->( dbclosearea() )
 endif

 select approval
 copy stru to ( Oddvars( TEMPFILE ) )

 if !Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "apptemp" )
  exit

 else
  mdef := NO
  mtot := 0
  mitems := 0
  mkey := customer->key
  mcomm := space(30)
  Highlight( 02, 05, 'Cust. No      => ', mkey )
  Highlight( 02, 35, 'Customer Name => ', left( customer->name, 42 ) )
  mscr:=Box_Save(3,10,6,70)
  @ 04,12 say 'Default Quantities to 1' get mdef pict 'y'
  @ 05,12 say 'Comments' get mcomm
  read
  Box_Restore( mscr )
  adding := TRUE
  select apptemp
  set relation to apptemp->id into master
  appbrow:=TBrowseDB(04, 0, 23, 79)
  appbrow:HeadSep:=HEADSEP
  appbrow:ColSep:=COLSEP
  appbrow:addColumn( tbcolumnnew( 'Desc', { || substr( master->desc, 1, 25 ) } ) )
  appbrow:addColumn( tbcolumnnew( 'Qty', { || transform( apptemp->qty ,'999') } ) )
  appbrow:addcolumn( tbcolumnnew( 'Price', { || transform( apptemp->price*apptemp->qty , '99999.99' ) } ) )
  appbrow:addColumn( tbcolumnnew( 'Extend', { || transform( apptemp->price*apptemp->qty,'99,999.99') } ) )
  appbrow:addcolumn( tbcolumnnew( 'Avail', { || transform( MASTAVAIL, '9999') } ) )
  appbrow:addColumn( tbcolumnnew( 'id', { || idcheck( master->id) } ) )
  appbrow:freeze:=1
  appbrow:goTop()
  keypress := 0
  goloop := TRUE
  while goloop
   appbrow:forcestable()
   if adding
    keyboard chr( K_INS )

   endif
   keypress := inkey(0)
   if !Navigate( appbrow, keypress )

    do case
    case keypress == K_F8
     mrec := apptemp->( recno() )
     sum apptemp->price * apptemp->qty, apptemp->qty to mtot, mitems
     @ 3,50 say 'Sub Total ' + Ns( mtot, 7, 2 ) + ' (' + Ns( mitems ) + ')'
     apptemp->( dbgoto( mrec ) )

    case keypress == K_DEL
     if Isready( 6, 12 , 'Ok to delete desc "'+trim( left( master->desc, 20 ) ) + '" from approval' ) 
      Del_rec( 'apptemp', UNLOCK )
      eval( appbrow:skipblock , -1 )
      appbrow:refreshall()
     endif

    case keypress == K_INS
     sID := space( ID_ENQ_LEN )
     mscr := Box_Save( 3, 18, 5, 62 )
     @ 4,20 say 'Scan Code or Enter id' get sID pict '@!'
     read
     Box_Restore( mscr )
     if !updated()
      adding := FALSE
      appbrow:gotop()

     else
      if !Codefind(sID)
       select apptemp
       Error( 'Desc not on File', 12 )

      else
       mrec := master->( recno() )
       sID:=master->id
       select approval
       ordsetfocus( BY_ID )
       seek master->id
       locate for approval->key = mkey .and. ;
              approval->qty-approval->delivered-approval->received > 0 ;
              while approval->id = sID
       ordsetfocus( BY_NUMBER )
       select apptemp
       if approval->( found() )
        Error( 'Desc already on approval to customer', 12 )
        if !Isready( 15 )
         loop

        endif

       endif
       master->( dbgoto( mrec ) )
       select apptemp
       mscr:=Box_Save( 6, 02, 9, 75 )
       @ 07, 04 say 'Desc                      Price     Qty'
       @ 08, 03 say left( master->desc, 24 )
       mqty := if( mdef, 1, 0 )
       mprice := master->sell_price
       if !mdef
        @ 8,29 get mprice pict '9999.99' valid( mPrice < 9000 )
        @ 8,41 get mqty pict '999'
        read

       endif
       Box_Restore( mscr )
       if mqty > 0
        Add_Rec('apptemp')
        apptemp->id := master->id
        apptemp->key := mkey
        apptemp->qty := mqty
        apptemp->price := mprice
        apptemp->desc := master->desc
        apptemp->date := Bvars( B_DATE )
        apptemp->comments := mcomm
        apptemp->( dbrunlock() )
        if adding
         appbrow:down()
         mtot += apptemp->price * apptemp->qty
         mitems += apptemp->qty
         Highlight( 3, 50, 'Sub Total ', Ns(mtot,7,2)+' ('+Ns(mitems)+')' )

        endif

       endif

      endif

     endif
     appbrow:gobottom()

    case keypress == K_ENTER
     mscr := Box_Save( 04, 08, 08, 72 )
     @ 05,11 say 'Desc                                Price       Qty'
     @ 06,10 say left( master->desc, 30 )
     @ 06,46 get price pict '9999.99' valid( apptemp->price < 9000 )
     @ 06,59 get qty pict '999'
     Rec_lock()
     read
     if apptemp->qty = 0
      delete

     endif
     dbrunlock()
     Box_Restore( mscr )
     appbrow:Refreshcurrent()

    case keypress == K_ESC .or. keypress == K_END
     mpost_it := NO
     mprint := YES
     mfinish := FALSE
     mscr := Box_Save( 19, 20, 23, 54 )
     @ 20,29 say 'Finished Processing' get mfinish pict 'y'
     @ 21,23 say 'Ok to Post this approval?' get mpost_it pict 'y'
     @ 22,22 say 'Ok to Print this approval?' get mprint pict 'y'
     read
     Box_Restore( mscr )
     goloop := !mfinish

    endcase

   endif

  enddo

  if mpost_it
   mappno := Sysinc( 'appno', 'I', 1, 'approval' )
   Box_Save( 21, 08, 24, 71 )
   Center( 22,'Now Posting Approval #' + Ns( mappno ) )

   select apptemp
   indx( "id", 'id' )
   total on apptemp->id to ( Oddvars( TEMPFILE2 ) ) fields qty
   apptemp->( orddestroy( 'id' ) )
   apptemp->( dbclosearea() )

   if Netuse( Oddvars( TEMPFILE2 ), EXCLUSIVE , 10 , 'apptemp' )
    indx( "desc", 'desc' )
    apptemp->( dbgotop() )
    while !apptemp->( eof() ) .and. Pinwheel()
     Add_rec( 'approval' )
     approval->number := mappno
     approval->key := apptemp->key
     approval->id := apptemp->id
     approval->qty := apptemp->qty
     approval->price := apptemp->price
     approval->date := Bvars( B_DATE )
     approval->comments := apptemp->comments
     approval->( dbrunlock() )

     if master->( dbseek( apptemp->id ) )
      Rec_lock( 'master' )
      master->approval += apptemp->qty
      master->( dbrunlock() )

     endif

     apptemp->( dbskip() )

    enddo
    apptemp->( orddestroy( 'desc' ) )
    apptemp->( dbclosearea() )

   endif
   select approval

   if mprint
    Center(23,'-=< Approval Printing in Progress >=-')
    for x:=1 to Bvars( B_APNOTE )

     Print_find("report")
     Appform( mappno, YES )

    next

   endif
  endif
 endif
enddo
return

*

procedure apprret ( by_appr_number )

local oldscr := Box_Save(), mno, sID, mqty, getlist:={}
local firstpass, mkey:='', ntempfile
local page_number,page_width,page_len,top_mar,bot_mar,col_head1,col_head2, report_name 

while TRUE
 Box_Restore( oldscr )
 Heading('Return Approvals for Invoicing')
 if by_appr_number
  mno := 0
  @ 13,46 say 'ÍÍ¯Enter Approval No' get mno pict '999999'
  read
  if !updated()
   exit
  endif
 else
  if !CustFind( NO )
   exit
  endif
  mkey := customer->key
 endif
 select approval
 ordsetfocus( if( by_appr_number, BY_NUMBER, BY_KEY ) )
 seek if( by_appr_number, mno, mkey )
 if !found()
  Error( if( by_appr_number, 'Approval NOT on file', 'Approval not found for Customer' ), 12 )

 else
  cls
  Heading(if(by_appr_number,'Return on Approval #'+Ns(mno),'Customer Approval Return'))
  Highlight(01,10,'Customer Name ',customer->name)
  @ 03,01 say '   '+ID_DESC+'         Desc                               Appr  Qty  Ret  Inv  Spec'
  @ 04,01 say replicate(chr(196),78)
  firstpass := FALSE
  if select( "apptemp" ) != 0
   apptemp->( dbclosearea() )
  endif
  ntempfile := '__' + right( Oddvars( TEMPFILE ),6)
  select approval
  copy stru to ( Oddvars( TEMPFILE ) )
  if !Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "apptemp", NEW )
   exit
  else
   while TRUE
    select approval
    sID := space( ID_ENQ_LEN )
    @ 2,10 say 'Scan code or enter id' get sID pict '@!'
    read
    if !updated()
     exit
    else
     if !Codefind( sID )
      Error('Code not on file !!!',12)
     else
      sID := master->id
      select approval
      ordsetfocus( BY_ID )
      seek sID
      locate for if( by_appr_number, approval->number = mno, approval->key = mkey ) .and. ;
             approval->qty - ( approval->received - approval->delivered ) > 0 ;
             while approval->id = sID
      if !found()
       Error( if( by_appr_number,'id not found on approval ' + Ns( mno ),;
               'Item not found on approval for customer' ), 12 )
      else
       scroll(5,01,15,79,-1)
       @ 5,01 say idcheck( sID )
       @ 5,16 say substr( master->desc, 1, 40 )
       mqty := approval->qty
       @ 5,53 say mqty pict '999'
       @ 5,57 get mqty pict '999' ;
              valid( mqty <= ( approval->qty - approval->received ) ;
             .and. mqty <= ( approval->qty - approval->delivered ) ) 
       @ 5,62 say approval->received pict '999'
       @ 5,67 say approval->delivered pict '999'
       @ 5,72 say master->special pict '999'
       read

       if lastkey() != K_ESC .and. mqty > 0
        Rec_lock('approval')
        approval->received += mqty
        approval->( dbrunlock() )

        if master->( dbseek( approval->id ) )
         Rec_lock( 'master' )
         master->approval -= mqty
         master->( dbrunlock() )
        endif

        Add_rec( 'apptemp' )
        apptemp->id := approval->id
        apptemp->qty := approval->qty
        apptemp->number := approval->number
        apptemp->key := approval->key
        apptemp->received := mqty
        apptemp->delivered := approval->received // temp storage for pre received
        apptemp->( dbrunlock() )

       endif

      endif

     endif

    endif

   enddo
   if apptemp->( lastrec() ) != 0
    if Isready( 12, 10 , 'Ok to print Approvals Returns Receipt' )
     select apptemp
     set relation to apptemp->id into master

     page_number:=1
     page_width:=80
     page_len:=66
     top_mar:=0
     bot_mar:=10
     col_head1 := 'Desc                   Author         Qty Returned   Qty Outstanding   App No'
     col_head2 := 'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ÄÄÄÄÄÄÄÄÄÄÄÄÄ  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ÄÄÄÄÄÄÄÄ'
     report_name := 'Approval Returns Receipt from ' + trim( customer->name )

     Print_find( "report" )
     
     // Pitch10()

     set device to printer
     setprc(0,0)              // Could be superfluous

     PageHead( report_name, page_width, page_number, col_head1, col_head2 )

     apptemp->( dbgotop() )
     while !apptemp->( eof() ) .and. Pinwheel( NOINTERUPT ) // Start print Routine
      if PageEject( page_len, top_mar, bot_mar )
       page_number++
       PageHead( report_name, page_width, page_number, col_head1, col_head2 )
      endif
      @ prow()+1, 0 say Substr( master->desc, 1, 23 )
      @ prow(), 24 say Substr( master->alt_desc, 1, 15 )
      @ prow(), 43 say apptemp->received  pict '9999'
      @ prow(), 58 say apptemp->qty - apptemp->delivered - apptemp->received pict '9999'
      @ prow(), 68 say apptemp->number

      apptemp->( dbskip() )
     enddo
     // Pitch10()
     Endprint()
     set device to screen

    endif

   endif
   apptemp->( dbclosearea() )

  endif

 endif

enddo
return

*

procedure apprdel
local oldscr:=Box_Save(),mno,getlist:={}
if Secure( X_DELFILES )
 while TRUE
  Box_Restore( oldscr )
  Heading('Delete Approval')
  mno := 0
  @ 15,46 say 'ÍÍ¯Enter Approval No' get mno pict '99999'
  read
  if !updated()
   exit

  else
   if !approval->( dbseek( mno ) )
    Error('Approval not on file',12)

   else
    Box_Save( 04, 08, 15, 71 )
    Highlight( 05, 10, '   Name ', customer->name )
    Highlight( 07, 10, 'Address ', customer->add1 )
    Highlight( 08, 10, '        ', customer->add2 )
    Highlight( 10, 10, '        ', customer->add3 )
    read
    if Isready(12)
     SysAudit( "ApprDel" + Ns( approval->number ) )
     while !approval->( eof() ) .and. approval->number = mno
      if master->( dbseek( approval->id ) )
       Rec_lock( 'master' )
       master->approval -= (approval->qty-approval->received-approval->delivered)
       master->( dbrunlock() )

      endif
      Del_rec( 'approval', UNLOCK )
      approval->( dbskip() )

     enddo

    endif

   endif

  endif

 enddo

endif
return

*

procedure appr_print

local mappno,oldscr:=Box_Save(), choice, aArray, getlist:={}, mscr, farr, sHeadStr

memvar mall, mdate, mkey, moutstand

private mall := NO, mdate, mkey, moutstand


while TRUE

 Box_Restore( oldscr )
 Heading('Approval Print Menu')
 Print_find( 'Report' )
 aArray := {}
 aadd( aArray, { 'Exit', 'Return to Approval Menu' } )
 aadd( aArray, { 'Reprint', 'Reprint Single Approval' } )
 aadd( aArray, { 'All', 'Print entire Approval File' } )
 aadd( aArray, { '14 Days', 'Approvals Outstanding 14 Days or More' } )
 aadd( aArray, { 'Customer', 'Print all approvals for customer' } )
 choice := Menugen( aArray, 17, 36, 'Print' )
 select approval

 farr := {}
 aadd(farr,{'idcheck(id)','id',13, 0, FALSE})
 if choice = 5
  aadd(farr,{'master->desc','Desc', 55, 0, FALSE})

 else
  aadd(farr,{'master->desc','Desc', 20, 0, FALSE})

 endif

 aadd(farr,{'qty','Qty', 3, 0, TRUE } )
 aadd(farr,{'received','Qty;Ret', 6, 0, TRUE } )
 aadd(farr,{'delivered','Qty;Inv',6, 0, TRUE } )
 aadd(farr,{'price','Price', 6, 2, FALSE})
 aadd(farr,{'price*qty','Price;Extended',10,2,TRUE})
 aadd(farr,{'date','Date of;Approval',8,0,FALSE})

 if choice < 5
//  aadd(farr,{'date()-date','Days;Outstand',10,0,TRUE})
  aadd(farr,{'customer->name','Customer Name',25,0,FALSE})
  aadd(farr,{'customer->phone1','Telephone1',14,0,FALSE})

 endif

 do case
 case choice = 2
  mappno := 0
  Heading( 'Reprint Approval' )
  @ 19,47 say 'ÍÍÍ>Approval #' get mappno pict '999999'
  read
  if updated()
   if !dbseek( mappno )
    Error( "Approval Number not on File", 12 )

   else
    Box_Save( 2, 08, 6, 72 )
    Highlight( 03, 10, 'Customer >',  customer->name )
    Highlight( 05, 10, 'First ' + DESC_DESC + ' on file ',  alltrim(master->desc) )
    if Isready(12)
     Appform( mappno, YES )

    endif

   endif

  endif

 case choice = 3
  Heading('Print All Approval Details')
  mscr:=Box_Save( 20,25,22,55 )
  @ 21,27 say 'Print all Approvals ( Including Filled )' get mall pict 'y'
  read
  if Isready(17)

   Reporter(    farr, ;
                'All Outstanding Approvals on file', ;
                'number', ;
                '"Approval Number : "+Ns(number)', ;
                '', ;
                '', ;
                FALSE, ;
                'if( mall, .t. , approval->qty - approval->received - approval->delivered > 0 )')

   Endprint()

  endif
  Box_Restore( mscr )

 case choice = 4
  Heading('Print Outstanding Approvals')
  Box_Save(02,10,4,70)
  mdate := Bvars( B_DATE ) - 14
  @ 03,15 say 'Enter Cutoff Date' get mdate
  read
  if Isready(07)
   Reporter(farr,'All Approvals older than' +dtoc( mdate ),'number','"Approval Number : "+Ns(number)','','',;
   FALSE,'approval->date <= mdate .and. approval->qty - approval->received - approval->delivered > 0')

   Endprint()

  endif

 case choice = 5
  Heading('Print all Approvals for Customer')
  if CustFind( FALSE )
   mkey := customer->key
   select approval
   ordsetfocus( BY_KEY )
   if !dbseek( mkey )
    Error( 'No Approvals found for Customer', 12 )

   else
    moutstand := TRUE
    Box_Save( 2, 10, 5, 70 )
    Highlight( 3, 12, 'Print all approval details for', trim( customer->name ) )
    @ 4, 12 say 'Print Outstanding Items only' get moutstand pict 'y'
    read
    if Isready(07)
     sHeadStr := 'All Approvals for ' + trim( customer->name) + ' Telephone No:' + customer->Phone1
     Reporter(  farr,;
                sHeadStr,;
                'number',;
                '"Approval Number : "+Ns(number)',;
                '', ;
                '', ;
                FALSE, ;
                'if( !moutstand, .t., approval->qty - approval->delivered > 0 )', ;
                'approval->key = mkey')

     Endprint()

    endif

   endif
   ordsetfocus( BY_NUMBER )

  endif

 case choice < 2
  return

 endcase

enddo

*

proc apprpurge
local mdate := Bvars( B_DATE ) - 60, getlist:={}
if Secure( X_SYSUTILS )
 Heading('Purge Old Approvals')
 @ 18,46 say 'ÍÍÍ>Enter Date for Purge' get mdate
 read
 if lastkey() != K_ESC
  select approval
  Box_Save( 2, 08, 10, 72 )
  Center( 3, 'You are about to delete all filled Approvals older than' )
  Center( 5, dtoc( mdate ) )
  if Isready(7)
   ordsetfocus( BY_NUMBER )
   approval->( dbgotop() )
   while !approval->( eof() )
    if approval->date <= mdate .and. approval->delivered + ;
       approval->received >= approval->qty
     Highlight( 6, 10, 'Approval No ', Ns( approval->number ) )
     Highlight( 7, 10, 'Customer ', customer->name)
     Rec_lock('approval')
     approval->( dbdelete() )

    endif
    approval->( dbskip() )

   enddo
   SysAudit("AprPurge"+dtoc(mdate))

  endif

 endif

endif
return

*

procedure AppForm ( nAppNo )

local nTotItems:=0, nApprovalTot:=0, cComments
local oPrinter := Printcheck( 'Approval No: ' + Ns( nAppNo ), 'Report' )

approval->( dbseek( nAppNo ) )
cComments := approval->comments

AppFormHead( nAppNo, oPrinter, TRUE )  // New approval

while approval->number = nAppNo .and. !approval->( eof() )

 LP( oPrinter, idcheck( master->id ), 0, NONEWLINE )
 LP( oPrinter, substr( master->desc, 1, 25 ), 15, NONEWLINE )
 LP( oPrinter, substr( master->alt_desc, 1, 15 ), 42 , NONEWLINE )
 LP( oPrinter, transform( approval->qty-approval->received-approval->delivered, '999'), 59, NONEWLINE )
 LP( oPrinter, transform( approval->price, '9999.99'), 63, NONEWLINE )
 LP( oPrinter, transform( approval->price * approval->qty, '99999.99'), 71 )


 nTotItems += approval->qty
 napprovalTot += approval->qty * approval->price


 if oPrinter:prow() > 60
  LP( oPrinter, 'continued....', 6 )
  oPrinter:Newpage()
  AppFormhead( nappNo, oPrinter, TRUE )  // New page

 endif

 approval->( dbSkip() )

enddo

napprovalTot := round( napprovalTot, 2 )

oPrinter:NewLine()

LP( oPrinter, DRAWLINE )

LP( oPrinter, BOLD )
LP( oPrinter, 'Total Value of Approval ', 0, NONEWLINE )
LP( oPrinter, Transform( ntotItems,  '9999' ), 58, NONEWLINE )
LP( oPrinter, Transform( nApprovaltot, '99999.99'), 71 )
LP( oPrinter, NOBOLD )

if !empty( cComments )
 LP( oPrinter, 'Comments ' + cComments )

endif
LP( oPrinter )
LP( oPrinter, 'It is our pleasure to supply you with the goods listed on Approval. If you'   )
LP( oPrinter, 'do not wish to keep them, Please return them (IN GOOD CONDITION, of course)'  )
LP( oPrinter, 'by ___/___/___ . We will Invoice you for anything you keep beyond this date.' )

oPrinter:endDoc()
oPrinter:Destroy()

return

*

Procedure AppFormHead ( napprovalNo,  oPrinter, lNewapproval )

static nPage

if lNewapproval
 nPage := 1

else
 nPage++

endif

if nPage > 1
 LP( oPrinter, DRAWLINE )
 LP( oPrinter, BPOSCUST, 0, NONEWLINE )
 LP( oPrinter, 'Approval No: ' + Ns( napprovalNo, 6 ), 32, NONEWLINE )
 LP( oPrinter, 'Page No: ' + Ns( nPage, 3 ), 66 )
 LP( oPrinter, DRAWLINE )
else

 LP( oPrinter, VERYBIGCHARS )
 LP( oPrinter, BOLD )
 LP( oPrinter, 'Goods on Approval', 10 )
 LP( oPrinter, NOBOLD )
 LP( oPrinter, NOBIGCHARS )

 LP( oPrinter, 'Approval Number:', 0 , NONEWLINE )
 LP( oPrinter, BOLD )
 LP( oPrinter, Ns( napprovalNo ), 19, NONEWLINE )
 LP( oPrinter, NOBOLD )
 LP( oPrinter, 'Date: ', 60, NONEWLINE ) //  + NOBIGCHARS
 LP( oPrinter, BOLD )
 LP( oPrinter, dtoc( approval->date ), 66 ) //  + NOBIGCHARS
 LP( oPrinter, NOBOLD )

 oPrinter:NewLine()
 LP( oPrinter, PRN_GREEN )
 LP( oPrinter, BOLD )
 LP( oPrinter, BIGCHARS )
 LP( oPrinter, BPOSCUST, 20 )
 LP( oPrinter, NOBIGCHARS )
 LP( oPrinter, NOBOLD )
 LP( oPrinter, PRN_BLACK )
 LP( oPrinter, 'ACN ' + Bvars( B_ACN ), 20 )
 LP( oPrinter, Bvars( B_ADDRESS1 ), 20 )
 LP( oPrinter, Bvars( B_ADDRESS2 ), 20 )
 LP( oPrinter, Bvars( B_SUBURB ), 20 )
 LP( oPrinter, Bvars( B_PHONE ), 20 )
 oPrinter:NewLine()
 oPrinter:NewLine()

 LP( oPrinter, BOLD )
 LP( oPrinter, 'Customer:', 10 )   // New line
 LP( oPrinter, NOBOLD )

 LP( oPrinter, customer->name, 10 )
 if !empty( customer->contact )
  LP( oPrinter, 'Attn: ' + customer->contact, 10 )

 endif

 LP( oPrinter, customer->add1, 10 )
 LP( oPrinter, customer->add2, 10  )   // New line
 LP( oPrinter, trim( customer->add3 ) + if( !empty(customer->add3), ' ',  "" ) + customer->pcode, 10 )  // New Line
 LP( oPrinter, '  Account No:', 56, NONEWLINE )
 LP( oPrinter, BOLD )
 LP( oPrinter, customer->key, 70 )
 LP( oPrinter, NOBOLD )

 LP( oPrinter,  "--", 0, NONEWLINE )  // New Line
 LP( oPrinter, "--", 78 )

 LP( oPrinter, ' Qty', 0, NONEWLINE )
 LP( oPrinter, DESC_DESC, 6, NONEWLINE )
 LP( oPrinter, 'Price', 66, NONEWLINE )
 LP( oPrinter, 'Extend', 74 )
 LP( oPrinter, DRAWLINE )

endif // New Page

return

