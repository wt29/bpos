/*

 Layby Procedure

      Last change:  TG   16 Jan 2011    2:16 am
*/

procedure s_layby

#include "bpos.ch"

local mgo:=FALSE, choice, oldscr:=Box_Save(), aArray

Center( 24, 'Opening files for Layby' )
if Netuse( "laybypay" )
 if Netuse( "customer" )
  if Netuse( "sales" )
   if master_use()
    if Netuse( "layby" )
     set relation to layby->id into master,;
                  to layby->key into customer,;
                  to layby->number into laybypay
     mgo := TRUE
    endif
   endif
  endif
 endif
endif
line_clear(24)
while mgo
 Box_Restore( oldscr )
 Heading( 'Laybys' )
 aArray := {}
 aadd( aArray, { 'Sales', 'Return to Sales Menu'  } )
 aadd( aArray, { 'Create', 'Create Layby', { || LaybyAdd() } } )
 aadd( aArray, { 'Payments', 'Add Payments', { || Laybypay() } } )
 aadd( aArray, { 'Delete', 'Remove Layby from file', { || LaybyDel() } } )
 aadd( aArray, { 'Enquire', 'Make Layby Enquiries', { || Laybyenq( 'layby' ) } } )
 aadd( aArray, { 'Reports', 'Reports Menu', { || Laybyprint() } } )
 choice := Menugen( aArray, 05, 35, 'Layby' )
 if choice < 2
  exit
 else
  Eval( aArray[ choice, 3 ] )
 endif
enddo
close databases
return

*

procedure laybyadd
local firstpass,mtotal,mcost,mlaybyno,mscr,s_ok,s_finished,getlist:={}
local mbank,mbranch,mdrawer,mdeposit,mamt_ten,mtot,x,msellprice,mqty
local oldscr := Box_Save( 0, 0, 24, 79 ), row, sID
local sFunKey4, okf5, okf6, okf7, okf8, discdone

while CustFind(FALSE)
 firstpass := YES
 mtotal := 0
 mcost := 0
 if select("laytemp") != 0
  select laytemp
  use
 endif
 select layby
 copy stru to (Oddvars( TEMPFILE ))
 if !Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "laytemp" )
  loop

 endif
 cls
 Heading( 'Create Layby' )
 row := 7
 @ 05,03 say  'ID              Desc                             Price   Qty  Extend'
 @ 06,00 say replicate( chr( 196 ) , 79 )
 while TRUE
  discdone := FALSE
  sID := space( ID_ENQ_LEN )
  Highlight(2,10,'Customer Name',customer->name)
  Line_clear(3)
  @ 3,10 say 'Scan Code or Enter ' + ID_DESC get sID pict '@!'
  fkon()
  read
  fkoff()
  if !updated()
   if firstpass
    exit
   else
    mscr:=Box_Save(06,18,09,62)
    s_finished := NO
    @ 07,20 say 'Finished entering Layby Details' get s_finished pict 'Y'
    read
    if !s_finished
     Box_Restore( mscr )
     loop
    else
     s_ok := NO
     @ 08,20 say 'Ok to Process this Layby' get s_ok pict 'Y'
     read
     if !s_ok
      firstpass := YES
     endif
    endif
    Box_Restore( mscr )
    exit
   endif
  else
   if !codefind(sID)
    Error( ID_DESC + ' not on file', 12 )
   else
    Line_clear(row)
    @ row,01 say idcheck( master->id )
    @ row,17 say substr( master->desc, 1, 30 )
    mqty := 1
    msellprice := master->sell_price
    @ row,50 get msellprice pict '9999.99' valid(msellprice < 9000)
    @ row,60 get mqty pict '99'
    mscr := Box_Save( row+1, 3, row+7, 30, 5 )
    @ row+2,05 say '<F4> = '+str( Bvars( B_DISC1 ), 5, 2 )+'% Discount'
    @ row+3,05 say '<F5> = '+str( Bvars( B_DISC2 ), 5, 2 )+'% Discount'
    @ row+4,05 say '<F6> = '+str( Bvars( B_DISC3 ), 5, 2 )+'% Discount'
    @ row+5,05 say '<F7> = '+str( Bvars( B_DISC4 ), 5, 2 )+'% Discount'
    @ row+6,05 say '<F8> = Add your own Disc.'
    sFunKey4 := setkey( K_F4, { || CashLineDisc( @msellprice, Bvars( B_DISC1 ), K_F4, nil, @discdone, row ) } )
    okf5 := setkey( K_F5, { || CashLineDisc( @msellprice, Bvars( B_DISC2 ), K_F5, nil, @discdone, row ) } )
    okf6 := setkey( K_F6, { || CashLineDisc( @msellprice, Bvars( B_DISC3 ), K_F6, nil, @discdone, row ) } )
    okf7 := setkey( K_F7, { || CashLineDisc( @msellprice, Bvars( B_DISC4 ), K_F7, nil, @discdone, row ) } )
    okf8 := setkey( K_F8, { || CashLineDisc( @msellprice, 0, K_F8, nil, @discdone, row ) } )
    Syscolor( 1 )
    read
    setkey( K_F4, sFunKey4 )
    setkey( K_F5, okf5 )
    setkey( K_F6, okf6 )
    setkey( K_F7, okf7 )
    setkey( K_F8, okf8 )
    Box_Restore( mscr )
    @ row,64 say mqty * msellprice pict '9999.99'
    mtotal += mqty * msellprice
    mcost += master->cost_price * mqty
    Highlight( row+1, 54, 'Sub Total  ', Ns( mtotal, 7, 2 ) )

    Add_rec( 'laytemp' )
    laytemp->key := customer->key
    laytemp->id := master->id
    laytemp->qty := mqty
    laytemp->price := msellprice
    laytemp->( dbrunlock() )

    firstpass := NO
    row++

    if row = 20
     row := 7
     line_clear(7)
     Highlight(8,55,'Sub Total  ',Ns(mtotal,8,2))

    endif
   endif
  endif
 enddo
 if !firstpass
  mbank := space(3)
  mbranch := space(15)
  mdrawer := space(20)
  mamt_ten := 0
  mdeposit := 0
  Highlight(row+2,47,'Total Layby       ',Ns( mtotal, 8, 2 ) )
  @ row+3,46 say 'Amount of Deposit ' get mdeposit pict '999.99' valid( mdeposit >= 0 )
  read
  mlaybyno := Sysinc( "laybyno", 'I', 1, 'layby' )
  laytemp->( dbgotop() )
  while !laytemp->( eof() )

   Add_rec( 'layby' )
   layby->number := mlaybyno
//   layby->branch := Bvars( B_BRANCH )
   layby->key := laytemp->key
   layby->id := laytemp->id
   layby->qty := laytemp->qty
   layby->price := laytemp->price
   layby->date := Bvars( B_DATE )
   layby->pay_date := Bvars( B_DATE )
   layby->to_date := mdeposit
   layby->( dbrunlock() )

   Add_rec( 'sales' )
   sales->id := laytemp->id
   sales->qty := laytemp->qty
   sales->unit_price := laytemp->price
   sales->cost_price := master->cost_price
   sales->sale_date := Bvars( B_DATE )
   sales->time := time()
   sales->tran_num := lvars( L_CUST_NO )
   sales->key := customer->key
   sales->name := customer->name
   sales->register := Lvars( L_REGISTER )
   sales->tran_type = 'LAY'
   sales->( dbrunlock() )
   
   if master->( dbseek( laytemp->id ) )
    Rec_lock( 'master' )
    update_oh( -laytemp->qty )
    master->dsale := Bvars( B_DATE )
    master->( dbrunlock() )

   endif

   laytemp->( dbskip() )

  enddo


  if Bvars( B_LACASH )
   Add_rec('sales')
   sales->qty := 1
   sales->register := lvars( L_REGISTER )
   sales->tran_type := 'LBT'
   sales->unit_price := mtotal-mdeposit
   sales->cost_price := mcost
   sales->sale_date := Bvars( B_DATE )
   sales->time := time()
   sales->tran_num := lvars( L_CUST_NO )
   sales->name := Ns(mlaybyno)+customer->name
   sales->( dbrunlock() )

  endif
  if mdeposit > 0
   Add_rec( 'laybypay' )
   laybypay->number := mlaybyno
   laybypay->date := Bvars( B_DATE )
   laybypay->unit_price := mdeposit
   laybypay->( dbrunlock() )

  endif
  Dock_head()
  if mdeposit > 0
   row++
   Tender( mdeposit, mdeposit, 0, 0, 1, "sales", 'LBD', row, customer->name )

  endif

  Dock_line( 'Layby #' + BIGCHARS + Ns( mlaybyno, 5 ) + NOBIGCHARS )
  Dock_line( '' )
  Dock_line( 'Please Layby the following goods for :' )
  Dock_line( customer->name )
  Dock_line( customer->add1 )
  Dock_line( customer->add2 )
  Dock_line( substr( trim( customer->add3 ) + if( !empty( customer->add3 ), ' ', '' );
             + customer->pcode, 1, 40 ) )
  Dock_line( 'Tele Hm ' + customer->phone1 )
  Dock_line( 'Tele Wk ' + customer->phone2 )
  Dock_line( '' )
  Dock_line( 'Item Description          Price   Extend' )
  Dock_line( replicate( '-', 40 ) )
  mtot := 0
  laytemp->( dbgotop() )
  while !laytemp->( eof() )
   master->( dbseek( laytemp->id ) )
   Dock_line( substr(master->desc,1,22)+' '+str( laytemp->price, 8, 2 ) + ' ' + ;
      str( laytemp->price * laytemp->qty, 8, 2 ) )
   mtot += laytemp->price * laytemp->qty
   laytemp->( dbskip() )

  enddo
  Dock_line( replicate('-',40) )
  Dock_line( 'Total Value of Layby $' + str( mtot, 7, 2 ) )
  Dock_line( 'This Payment         $' + str( mdeposit, 7, 2 ) )
  Dock_line( 'Balance Due          $' + str( mtot-mdeposit, 7, 2 ) )
  Dock_line( 'Balance Due By        ' + dtoc( Bvars( B_DATE ) + 90 ) )
  Dock_line( replicate('-',40) )

  laybycond( )

  dock_foot( )

  for x := 1 to Bvars( B_LADOCK )
   Dock_print()

  next
  Lvars( L_CUST_NO, Custnum() )

 endif
 laytemp->( dbclosearea()  )

enddo
return

*

procedure laybypay
local oldscr:=Box_Save(), mamt_ten
local x, mno, nPayment, mtot, mto_date, getlist:={}

while TRUE
 Box_Restore( oldscr )
 Heading('Layby Payments')
 @ 01,67 say 'Docket is ' + if( lvars( L_DOCKET ), 'On', 'Off' )
 mno := 0
 @ 8,45 say 'ÍÍ¯Enter Layby No' get mno pict '999999'
 read
 if !updated()
  exit
 else
  select layby
  ordsetfocus( 'number' )
  if !dbseek( mno ) 
   Error('Layby not on file',12)

  else
   select laybypay
   seek mno
   sum laybypay->unit_price to mto_date while laybypay->number = mno .and. !eof()
   select layby
   sum layby->price * layby->qty to mtot while layby->number = mno .and. !eof()
   seek mno
   Box_Save( 04, 12, 22, 69 )
   mamt_ten := 0
   nPayment := 0
   Highlight( 05, 14, '               Name', customer->name )
   Highlight( 07, 14, '            Address', customer->add1 )
   Highlight( 09, 14, '        Total Layby', str( mtot, 8, 2 ) )
   Highlight( 11, 14, '   Payments to date', str( mto_date, 8, 2 ) )
   Highlight( 13, 14, ' Amount Outstanding', str( mtot-mto_date, 8, 2 ) )
   @ 15,14 say        'Amount this Payment' get nPayment pict '99999.99'
   read
   if nPayment > 0
    if mtot - mto_date - nPayment < 0
     Error( 'Overpayment! Amount Adjusted', 12 )
     nPayment := mtot - mto_date

    endif
    select layby
    Dock_head()
    Dock_line( chr(17) + BIGCHARS + '  Payment on Layby' + NOBIGCHARS )
    Dock_line( chr(17) + BIGCHARS + '    Number: ' + Ns( mno, 6 ) + NOBIGCHARS )
    Dock_line( '' )
    Dock_line( '   Total Layby         ' + Ns( mtot, 6, 2 ) )
    Dock_line( '' )
    Dock_line( '   Amount this payment ' + Ns( nPayment, 6, 2 ) )
    Dock_line( '   Payments to Date    ' + Ns( mto_date+nPayment, 6, 2 ) )
    Dock_line( '   Amount Outstanding  ' + Ns( mtot-mto_date-nPayment, 6, 2 ) )
    Dock_line( '' )
    Dock_line( '' )
    Tender( nPayment, nPayment, 0, 0, 1, "sales", 'LBP', 17, customer->name )
    Dock_foot( )

    for x := 1 to Bvars( B_LAPAY )
     Dock_print()

    next

    layby->( dbseek( mno ) )

    if Vs( layby->to_date + nPayment, 10, 2 ) >= Vs( mtot, 10, 2 )

     SysAudit( "LayPayDel" + Ns( layby->number ) )
     Highlight( 17, 30, '', 'This Layby is now finished' )
     Highlight( 18, 28, '', 'The system will now delete it!!' )
     Error('')

     while layby->number=mno .and. !layby->( eof() )
      Del_rec('layby')
      layby->( dbskip() )

     enddo

     laybypay->( dbseek( mno ) )
     while laybypay->number = mno .and. !laybypay->( eof() )
      Del_rec('laybypay')
      laybypay->( dbskip() )

     enddo

    else

     layby->( dbseek( mno ) )
     Rec_lock( 'layby' )
     layby->to_date += nPayment
     layby->pay_date := Bvars( B_DATE )
     layby->( dbrunlock() )

     Add_rec( 'laybypay' )
     laybypay->number := mno
     laybypay->unit_price := nPayment
     laybypay->date := Bvars( B_DATE )
     laybypay->( dbrunlock() )
     
    endif
    lvars( L_CUST_NO, custnum() )

   endif
  endif
 endif
enddo
return

*

procedure laybydel
local oldscr:=Box_Save(), mtot, mcost, mto_date
local x, mcust, mno, getlist:={}

while TRUE
 Box_Restore( oldscr )
 Heading('Delete Layby')
 @ 01,67 say 'Docket is ' + if(lvars( L_DOCKET ),'On','Off')
 mno := 0
 @ 9,46 say 'ÍÍ¯Enter Layby No' get mno pict '999999'
 read
 if !updated()
  exit

 else
  layby->( ordsetfocus( 1 ) )
  if !layby->( dbseek( mno ) )
   Error('Layby not on file',12)

  else
   select laybypay
   sum laybypay->unit_price to mto_date while laybypay->number = mno .and. !eof()
   mcust := customer->name
   Box_Save( 04, 08, 17, 71 )
   Highlight( 05, 10, 'Name    ', customer->name )
   Highlight( 07, 10, 'Address ', customer->add1 )
   Highlight( 08, 10, '        ', customer->add3 )
   Highlight( 10, 10, '        ', customer->add2 )
   Highlight( 12, 10, 'First Item => ', trim( master->desc ) )
   if Isready( 14, 10, 'Is this the Layby to Delete' )
    if Secure( X_SALEVOID )
     SysAudit("LayDel"+Ns(layby->number)+trim(customer->key))
     Highlight(14,10,'Refund due $',Ns(mto_date,7,2))
     @ 16,10 say 'Amount of Layby to refund' get mto_date pict '9999.99'
     read

     select layby
     sum layby->price*layby->qty,master->cost_price*layby->qty to mtot,mcost ;
         while layby->number = mno .and. !eof()

     select layby
      seek mno
      Dock_head()
      Dock_line( chr(14) + '  Refund on Layby' )
      Dock_line( chr(14) + '   Number: ' + Ns(mno,6) )
      Dock_line( "" )
      Dock_line( '             Total Layby         ' + Ns(mtot,6,2) )
      Dock_line( "" )
      Dock_line( '             Refund Amount       ' + Ns(layby->to_date,6,2) )
      Dock_line( "" )
      Dock_line( "" )


     if mto_date > 0
      layby->( dbseek( mno ) )   // reposition layby file ( and customer file )
      Tender( mto_date, mto_date, 0, mcost, -1, "sales", 'LDE', 17, customer->name )

     endif

     dock_foot( )

     for x := 1 to Bvars( B_LADELE )
      Dock_print()

     next

     seek mno
     while layby->number = mno .and. !layby->( eof() )
      Rec_lock( 'master' )
      Update_oh( layby->qty )
      master->( dbrunlock() )

      Add_rec( 'sales' )
      sales->id := layby->id
      sales->qty := -(layby->qty) 
      sales->unit_price := layby->price
      sales->cost_price := master->cost_price
      sales->register := lvars( L_REGISTER )
      sales->sale_date := Bvars( B_DATE )
      sales->time := time()
      sales->tran_num := lvars( L_CUST_NO )
      sales->key := customer->key
      sales->name := customer->name
      sales->( dbrunlock() )

      Del_rec( 'layby', UNLOCK )
      layby->( dbskip() )

     enddo

     laybypay->( dbseek( mno ) )
     while laybypay->number = mno .and. !laybypay->( eof() )
      Del_rec( 'laybypay' )
      laybypay->( dbskip() )

     enddo
     lvars( L_CUST_NO, custnum() )

    endif
   endif
  endif
 endif
enddo
return

*

procedure laybyenq ( mfile )
local oldscr:=Box_Save(0,0,24,79), choice, aArray
local mnum, nuloop:=TRUE
local nMenuOffset :=0
local mkey, mname, saverec
local hitkey, mnumber, custobj, getlist:={}

do case
case mfile = 'approval'
 nMenuOffset := 6

case mfile = 'quote'
 nMenuOffset := 4

endcase

while nuloop
 Box_Restore( oldscr )
 Heading( mfile + ' File Inquiry' )
 aArray := {}
 aadd( aArray, { 'Exit', 'Return to ' + mfile + ' Menu' } )
 aadd( aArray, { 'Number', 'Inquiry by ' + mfile + ' Number.' } )
 aadd( aArray, { 'Customer', 'Inquiry on ' + mfile + 'by Customer' } )
 choice := MenuGen( aArray, 10+nMenuOffset, 36, 'Enquire' )
 oldscr := Box_Save(0,0,24,79)
 do case
 case choice = 2
  Heading(mfile+' File Inquiry')
  mnum := 0
  @ 12 + nMenuOffset,46 say 'ÍÍ¯'+mfile+' Number' get mnum pict '999999'
  read
  if updated()
   select (mfile)
   ordsetfocus( BY_NUMBER )
   Laybdisp( mnum, mfile )

  endif
 case choice = 3
  select (mfile)
  ordsetfocus( BY_KEY )
  while CustFind( FALSE )
   Box_Restore( oldscr )
   Heading( 'Inquiry by Customer Key' )
   mname := trim( customer->name )
   mkey := customer->key
   select (mfile)
   if !dbseek( mkey )
    Error( 'No ' + mfile + ' found for ' + trim(customer->name) , 12 )
   else
    Box_Save( 02, 00, 24, 79 )
    custobj := TBrowseDB( 03, 01, 23, 78)
    custobj:HeadSep := HEADSEP
    custobj:ColSep := COLSEP
    custobj:goTopBlock := { || dbseek( mkey ) }
    custobj:goBottomBlock  := { || jumptobott( mkey ) }
    custobj:skipBlock:=KeySkipBlock( { || (mfile)->key }, mkey )
    custobj:AddColumn( TBColumnNew('Order #', { || transform( (mfile)->number , '999999') } ) )
    custobj:AddColumn( TBColumnNew('Date', { || (mfile)->date } ) )
    custobj:AddColumn( TBColumnNew('Desc', { || substr( master->desc, 1, 40) } ) )
    hitkey := 0
    while hitkey != K_ESC .and. hitkey != K_END
     custobj:forcestable()
     hitkey := inkey(0)
     if !Navigate( custobj, hitkey )
      if hitkey == K_ENTER
       saverec := (mfile) -> ( recno() )
       mnumber := (mfile)->number
       ordsetfocus( BY_NUMBER )
       seek mnumber
       Laybdisp( mnumber, mfile )
       ordsetfocus( BY_KEY )
       goto saverec
      endif
     endif
    enddo
   endif
  enddo
  select (mfile)
  ordsetfocus( BY_NUMBER )
 case choice < 2
  exit
 endcase
enddo
return

*

procedure laybdisp ( mnumber, mfile )
local mscr:=Box_Save(0,0,24,79),specbrow,hitkey,tscr,mtot,paid
local labbrow,lakey,c,getlist:={}, aHelpLines

Heading( 'Inquiry on ' + mfile + ' No ' + Ns( mnumber ) )

if mfile = 'layby'
 select laybypay
 seek mnumber
 sum laybypay->unit_price to paid while laybypay->number = mnumber .and. !eof()
 select (mfile)
 seek mnumber
 sum layby->price*layby->qty to mtot while (mfile)->number = mnumber .and. !eof()
endif

select ( mfile )
if !dbseek( mnumber )
 Error( "Number not on file", 12 )
else
 Custdisp()
 Highlight( 07, 52, 'Days Outstanding', Ns( Bvars( B_DATE ) - (mfile)->date ) )
 specbrow:=TBrowseDB( 09, 00, 24, 79 )
 specbrow:colorspec := TB_COLOR
 specbrow:HeadSep:= HEADSEP
 specbrow:ColSep:= COLSEP
 specbrow:goTopBlock:={||dbseek( mnumber )}
 specbrow:goBottomBlock:={||jumptobott( mnumber)}
 specbrow:skipBlock:=KeySkipBlock( {||(mfile)->number}, mnumber )
 specbrow:AddColumn(tbcolumnNew('Desc',{|| substr(master->desc,1,30) } ) )
 specbrow:AddColumn(tbcolumnNew('Qty',{||(mfile)->qty }))
 if mfile = 'approval'
  c:=TBColumnNew( 'Recv', { || (mfile)->received } )
  specbrow:AddColumn( c )
  c:=TBColumnNew( 'Del', { || (mfile)->delivered } )
  c:colorblock:={ || if( (mfile)->qty-(mfile)->delivered <= 0 , { 5, 6} , { 1, 2 } ) }
  specbrow:AddColumn( c )

 endif
 specbrow:AddColumn(TBColumnNew('Price',{||transform( (mfile)->price,'9999.99')}))
 specbrow:AddColumn(TBColumnNew('Extend',{||transform( (mfile)->price*(mfile)->qty,'9999.99')}))
 specbrow:AddColumn(TBColumnNew('Date',{||(mfile)->date}))
 specbrow:AddColumn(TBColumnNew('Master Comments',{||master->comments}))
 hitkey:=0
 specbrow:freeze := 1
 while hitkey != K_ESC .and. hitkey != K_END
  specbrow:forcestable()
  hitkey := inkey(0)
  if !Navigate(specbrow,hitkey)
   do case
   case hitkey == K_F1
    aHelpLines := { ;
               { 'Esc', 'Escape from function' }, ;
               { 'F10', 'Desc Details' }, ;
               { 'F4', 'Hold/Release Item' } }
    if mfile = 'approval'
     aadd( aHelpLines, { 'F9', 'Modify Qtys' } )
    endif 
    if mfile = 'layby'
     aadd( aHelpLines, { 'F8',  'Payment Details' } )
    endif 
    Build_help( aHelpLines )

   case hitkey == K_F8
    if mfile = 'layby'
     tscr:=Box_Save( 10,10,24,70 )
     Box_Save( 10,10,14,31 )
     Highlight(11,12,'Layby Total',Ns(mtot,8,2))
     Highlight(12,12,'   Payments',Ns(paid,8,2))
     Highlight(13,12,'      Owing',Ns(mtot-paid,8,2))
     select laybypay
     Box_Save( 10,39,23,61 )
     labbrow:=TBrowseDB(11, 40, 22, 60)
     labbrow:HeadSep:= HEADSEP
     labbrow:ColSep:= COLSEP
     labbrow:goTopBlock:={||dbseek(layby->number)}
     labbrow:goBottomBlock:={||jumptobott(layby->number)}
     labbrow:skipBlock:=KeySkipBlock( { || laybypay->number }, layby->number )
     labbrow:AddColumn(tbcolumnNew('Date',{|| laybypay->date } ) )
     labbrow:AddColumn(tbcolumnNew('Payment',{|| transform( laybypay->unit_price , '999.99' ) }))
     lakey := 0
     while lakey != K_ESC .and. lakey != K_END
      labbrow:forcestable()
      lakey := inkey(0)
      Navigate(labbrow,lakey)
     enddo
     Box_Restore( tscr )
     select (mfile)

    endif
   case hitkey == K_F9
    if mfile = 'approval' .and. Secure( X_SUPERVISOR )
     Rec_lock( mfile )
     tscr:=Box_Save( 10, 10, 13, 40 )
     @ 11, 12 say ' Received' get approval->received pict QTY_PICT
     @ 12, 12 say 'Delivered' get approval->delivered pict QTY_PICT
     read
     (mfile)->( dbrunlock() )
     Box_Restore( tscr )
     specbrow:refreshcurrent()
    endif
   case hitkey == K_F10
    itemdisp( NO )
    select (mfile)
    specbrow:refreshcurrent()
   endcase
  endif
 enddo
endif
Box_Restore( mscr )
return

*

procedure laybyprint
local choice,oldscr:= Box_Save(),getlist:={},aArray,farr
memvar mdate
while TRUE
 Print_find("report")
 Box_Restore( oldscr )
 Heading('Layby Print Menu')
 aArray := {}
 aadd( aArray, { 'Exit', 'Return to Layby Menu' } )
 aadd( aArray, { 'All', 'Print entire Layby File' } )
 aadd( aArray, { 'Overdue', 'Laybys approaching redemption' } )
 choice := MenuGen( aArray, 11, 36, 'Reports' )

 farr := {}
 aadd(farr,{'idcheck(id)','id',13,0,FALSE})
 aadd(farr,{'master->desc','Desc',20,0,FALSE})
 aadd(farr,{'qty','Qty',3,0,FALSE})
 aadd(farr,{'price','Price',6,2,FALSE})
 aadd(farr,{'price*qty','Price;Extended',10,2,TRUE})
 aadd(farr,{'date','Date of;Layby',8,0,FALSE})
 aadd(farr,{'date()-date','Days;Outstand',10,0,TRUE})
 aadd(farr,{'customer->name','Customer Name',25,0,FALSE})
 aadd(farr,{'customer->phone1','Telephone 1',14,0,FALSE})
 
 do case
 case choice = 2
  Heading('Print All Layby Details')
  if Isready(12)

   // Pitch17()
   select layby
   
   Reporter(farr,'"All Laybys"','Ns(number)+"   ($"+Ns(to_date,10,2)+")"',;
   '"Layby # ($ Paid to Date) : "+Ns(number)+"   ($"+Ns(to_date,10,2)+")"','','',FALSE)
   
   // Pitch10()
   Endprint()
  endif
 case choice = 3
  Heading('Print Laybys approaching Redemption')
  mdate := Bvars( B_DATE ) - 60
  Box_Save(4,20,6,60)
  @ 5,25 say 'Enter Cutoff Date ' get mdate
  read
  if Isready(12)
   
   // Pitch17()
   select layby

   Reporter(farr,'All Laybys older than '+dtoc(mdate),'Ns( number )',;
   '"Layby # ($ Paid to Date) : "+Ns(layby->number)+"   ($"+Ns(layby->to_date,10,2)+")"','','',FALSE,'layby->date <= mdate')
   
   // Pitch10()
   Endprint()
  endif
 case choice < 2
  exit
 endcase
enddo
return
*

procedure laybycond()
local laybywks := Ns( Bvars( B_LACOMP ) /7, 3, 0 )

Dock_Line( padc('~LAY-BY TERMS AND CONDITIONS', 38 ) )
Dock_Line( 'A deposit of 25c in the $ is to be' )
Dock_Line( 'paid when lay-by is made.' )
Dock_Line( 'Instalments may be paid any time' )
Dock_Line( 'within the specified period, but a' )
Dock_Line( 'payment must be made each month.' )
Dock_Line( 'Lay-bys must be finalised within ' + laybywks )
Dock_Line( 'weeks. Goods held on lay-by cannot' )
Dock_Line( 'be exchanged. Lay-bys consisting of' )
Dock_Line( 'two or more articles cannot be broken.' )

Dock_Line( ' ' )

return

