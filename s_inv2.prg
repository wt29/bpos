/* 

  Saleinv2.prg - The Guts of Invoicing in BPOS


      Last change:  TG   29 Apr 2011    3:40 pm
*/

#include "bpos.ch"

#define APPR_AVAIL approval->qty-approval->received-approval->delivered

#define SOURCE     1
#define CARRIER    2
#define TAXCERT    3
#define REPORDER   4
#define FREIGHT    5
#define CUSTORDER  6
#define ZOPERATOR  7  // This is funny because we already have an operator define in bpos.ch
#define SALESREP   8
#define APPEMODE   9
#define STUDFLAG  10
#define APPRKEY   11
#define STUDARR   12
#define ORDINAL   13
#define STUDTAG   14
#define BKLSCODE  15
#define STWASINV  16
#define MCUSTORD  17
#define SPECARR   18
#define SPECFLAG  19
#define APPEFILE  20
#define PDTARR    21
#define DESTPRINT 22
#define SPDEPTOT  23

#define INV_VARIANCE 50

static mcom3, mcom2, mcom1, invvars

procedure invcreate ( proforma, minv, mtrmac )

local sID, mdisc, minst1, minst2, msave, mscr, mspecno
local okaf1, okaf2, okaf3, okaf4, okaf5, okaf6, okaf7, munalloc, getlist:={}, minvno,x,munit
local mprint,mproc_pick_slip,mpickno,msundries,mtnett, mdesc_len
local mbillkey, mqty, mkey, mfield, mextend, lAnswer, mast_qty, mrecno, mpos
local mspec, autopick:=FALSE, lastsort, bo_qty, oldf8, aHelpLines
local invbrow,mrec,mcomments,msellprice,msell,mord, oldf4, oldf5, oldf6, oldf7
local specqty, mfinish, mpost_it, goloop, fksave, tcol, offset
local autoappe, mtotdisc, mgross, mnett, mcogs, mtax, mserial, minvsort
local HeaderProcessed, mmktg_type, discdone, adding, mcustkey, mspecnum

// local mdepamt   // Amount of Deposits to use to pay invoice

invvars := array( 25 )

invvars[ STWASINV ] := FALSE
invvars[ STUDFLAG ] := FALSE
invvars[ SPECFLAG ] := FALSE
invvars[ DESTPRINT ] := 'Report'

default proforma to FALSE
 
while TRUE
 
#ifdef INV_COMM_CARRIED
 if mcom1 = nil
  mcom1 := mcom2 := mcom3 := space( 40 )
 endif
#else
 mcom1 := mcom2 := mcom3 := space( 40 )
#endif

 mgross := 0                    // Gross of all the invoice
 mnett := 0                     // Nett after discounts
 mcogs := 0                     // Cost of goods
 mtax := 0                      // Sales tax totals
 invvars[ FREIGHT ] := 0        // Freight
 msundries := 0                 // Sundries ( small order charge etc )
 mtotdisc := 0                  // Our initial Discount Amount
 invvars[ APPEMODE ] := 0       // No append mode in progress
 mspecnum := 0                  // The Special/Approval under Question
 invvars[ APPEFILE ] := ''      // File for append from
 autoappe := FALSE              // Automatically append Apps/Specs
 mInst1 := space(30)            // Some instructions
 mInst2 := space(30)

 invvars[ ZOPERATOR ] := space( OPERATOR_CODE_LEN )
 mproc_pick_slip := FALSE       // Processing Picking Slip ( not creating it! )
 mpickno := 0                   // Picking slip number
 mmktg_type := ''               // Marketing Types

 Heading('Select Customer to ' + mtrmac )

 if Bvars( B_PICKSLIP )
  if !autopick
   mscr := Box_Save( 3, 10, 5, 50 )
   @ 4,12 say 'About to process Picking Slip?' get mproc_pick_slip pict 'y'
   read
   Box_Restore( mscr )
  else
   mproc_pick_slip := YES
  endif
  if !mproc_pick_slip
   if lastkey() = K_ESC
    return
   endif
  else
   if !autopick
    mscr:=Box_Save( 3, 10, 5, 45 )
    @ 4,12 say 'Picking Slip Number' get mpickno
    read
    Box_Restore( mscr )
   endif
   mproc_pick_slip := NO
   if !updated() .and. !autopick
    loop
   else
    select pickslip
    if mpickno = -1 .or. autopick
     if !autopick     // not doing it yet
      lAnswer := FALSE
      mscr := Box_Save( 3,10,5,55 )
      @ 4, 12  say 'About to process all open Picking Slips'
      if !Isready( 12 )
       loop
      else
       Heading("Comments On Invoice")
       mscr := Box_Save( 02, 18, 06, 62 )
       @ 03,20 get mcom1 pict '@k'
       @ 04,20 get mcom2 pict '@k'
       @ 05,20 get mcom3 pict '@k'
       read
       Box_Restore( mscr )
      endif
     endif
     select pickslip
     locate for !pickslip->invoiced
     if !found() .or. pickslip->( eof() )
      if pickslip->( eof() )
       Error( 'Invoicing Run Completed', 12 )
      else
       Error( 'No picking slips to process', 12 )
      endif
      autopick := FALSE
      loop
     else
      mpickno := pickslip->number
      minv := pickslip->invoice
      autopick := TRUE
     endif
    endif
    if !pickslip->( dbseek( mpickno ) )
     Error("Picking Slip number " + Ns( mpickno) + " not found on file",12)
     loop
    else
     if pickslip->invoiced
      Error( "Picking Slip already invoiced", 12 )
      loop
     else
      invvars[ FREIGHT ] := pickslip->freight
      mtotdisc := pickslip->tot_disc
      mproc_pick_slip := YES
     endif
    endif
   endif
  endif
 endif

 if ( Bvars( B_PICKSLIP ) .and. !mproc_pick_slip ) .or. !Bvars( B_PICKSLIP )
#ifdef PREPACK
  if invvars[ STUDFLAG ]
   invvars[ ORDINAL ]++            // Position in array of students
   invvars[ STWASINV ] := FALSE
   if invvars[ ORDINAL ] <= len( invvars[ STUDARR ] )
    students->( dbseek( invvars[ STUDARR ][ invvars[ ORDINAL ] ] ) )
    while students->key = invvars[ STUDARR ][ invvars[ ORDINAL ] ] .and. ;
        ( students->invoiced = students->required ) .and. !students->( eof() )
     invvars[ STWASINV ] := TRUE
     students->( dbskip() )
    enddo
    if students->key = invvars[ STUDARR ][ invvars[ ORDINAL ] ] .and. !students->( eof() )
     keyboard invvars[ STUDARR ][ invvars[ ORDINAL ] ] + chr( K_ENTER )
     invvars[ STUDTAG ] := students->stud_tag
     invvars[ BKLSCODE ] := students->bkls_code
     invvars[ STUDFLAG ] := TRUE
     invvars[ APPEMODE ] := APPE_FROM_BOOKLIST
    else
     loop
    endif
   else
    Error( "Student Invoice Run Completed", 12 )
    exit
   endif
  endif
#endif

  if invvars[ SPECFLAG ]     // Auto Invoice flag
   invvars[ ORDINAL ]++      // Position in array of customers
   if invvars[ ORDINAL ] <= len( invvars[ SPECARR ] )
    keyboard invvars[ SPECARR ][ invvars[ ORDINAL ] ] + chr( K_ENTER )
    invvars[ APPEMODE ] := APPE_SP_BY_KEY
    invvars[ APPEFILE ] := 'Special'
    special->( ordsetfocus( 'key' ) )
    special->( dbseek( invvars[ SPECARR ][ invvars[ ORDINAL ] ] ) )
   else
    Error( "Auto Invoice Run Completed", 12 )
    exit
   endif
  endif
  if !CustFind( TRUE )
   return

  else
   if customer->stop
    Error( 'Customer is on Stop !!!', 12 )
    return
   endif

  endif

 else
  if Bvars( B_PICKSLIP )
   if !customer->( dbseek( pickslip->key ) )
    Error( 'Pick Slip Customer ' + trim( pickslip->key ) + ' on Pickslip #' + ;
           Ns( pickslip->number) + ' not Found', 12 )
    if autopick
     pickslip->( dbskip() )
    else
     loop
    endif
   endif
  endif
 endif

 cls
 Heading('Enter ' + if( proforma, 'Proforma ', '' ) + mtrmac + ' Details')
 mcustkey := customer->key
 minvsort := customer->sort_ord
 Highlight( 01, 01, 'Customer =>', substr( customer->name, 1, 39 ) )
 Highlight( 02, 01, 'Cust Key =>', customer->key )
 Highlight( 03, 01, 'Comments =>', customer->comments )

 Highlight( 01, 65, 'Amt90', str( customer->amt90, 8, 2 ) )
 Highlight( 02, 65, 'Amt60', str( customer->amt60, 8, 2 ) )
 Highlight( 03, 65, 'Amt30', str( customer->amt30, 8, 2 ) )
 Highlight( 04, 65, 'Curr.', str( customer->amtCur,8, 2 ) )
 Highlight( 01, 40, 'Amt Outstand.=>', str( customer->amtcur + customer->amt30 + customer->amt60 + customer->amt90, 8, 2 ) )
 Highlight( 02, 40, 'Credit Limit =>', str( customer->c_limit, 8, 2 ) )
 Cred_check( mnett )

 select invline

 if select( "invtemp" ) != 0
  invtemp->( dbclosearea() )

 endif

 copy stru to ( Oddvars( TEMPFILE ) )
 if !Netuse( Oddvars( TEMPFILE ), EXCLUSIVE, 10, "invtemp", TRUE )
  loop
 endif
 set relation to invtemp->id into master

 invvars[ CUSTORDER ] := space( 15 )
 mspec := 0

 if Bvars( B_PICKSLIP ) .and. mproc_pick_slip
  if autopick
   Box_Save( 5, 10, 7, 40 )
   Highlight( 6, 12, 'Processing Pickslip #', Ns( pickslip->number ) )
  endif
  select pickslip
  invvars[ ZOPERATOR ] := pickslip->operator
  invvars[ CUSTORDER ] := pickslip->req_no
  invvars[ SALESREP ] := pickslip->salesman
  while pickslip->number = mpickno .and. !pickslip->( eof() )
   select invtemp
   Add_Rec( 'invtemp' )
   for x := 1 to fcount()
    mfield := pickslip->( fieldpos( invtemp->( fieldname( x ) ) ) )
    if mfield != 0
     invtemp->( fieldput( x, pickslip->( fieldget( mfield ) ) ) )

    endif

   next
   pickslip->( dbskip() )

  enddo
  select invtemp
  invtemp->( dbgotop() )
  minv := invtemp->invoice   // Set flag up for c/note or invoices
  locate for invtemp->spec_no != 0
  if found()
   if invtemp->special       // = appended from special/approval
    invvars[ APPEFILE ] := 'Special'

   else
    invvars[ APPEFILE ] := 'Approval'

   endif

  endif
  Inv_tot( mtotdisc, @mgross, @mnett, @mcogs, @mtax )    // Pass by reference

 else
  invvars[ ZOPERATOR ] := space( OPERATOR_CODE_LEN )
  invvars[ CARRIER ] := invvars[ SOURCE ] := ' '
  invvars[ TAXCERT ] := 'N'
  invvars[ REPORDER ] := space(10)
  invvars[ SALESREP ] := customer->salesman
  invvars[ SPDEPTOT ] := 0  // Deposit Totals = 0

  if minv .and. !invvars[ STUDFLAG ]
   invvars[ CUSTORDER ] := space(25)
   mscr := Box_Save( 18, 09, 20, 71 )
   @ 19,12 say 'Customer Order No' get invvars[ CUSTORDER ]
   @ 19, 58 say 'Sales Rep' get invvars[ SALESREP ] pict '!!' ;
            valid( dup_chk( invvars[ SALESREP ], 'salesrep' ) )
   read
   Box_Restore( mscr )

  endif

 endif

 if autopick
  mpost_it := TRUE
  mprint := TRUE

 else
  lastsort := ''
  adding := TRUE
  mtotdisc := 0
  select invtemp
  HeaderProcessed := FALSE
  invbrow:=tbrowsedb( 05, 0, 24-2, 79 )
  invbrow:HeadSep := HEADSEP
  invbrow:ColSep := COLSEP
  mdesc_len := 30
  tcol := tbcolumnNew('Desc',{ || ;
          if( invtemp->id != '*' , substr( master->desc, 1, mdesc_len ), ;
              substr( invtemp->comments, 1, 30 ) ) } )
  invbrow:addcolumn( tcol )
  offset := 32

  invbrow:addcolumn(tbcolumnNew('Ord',{ || if( invtemp->id != '*',;
          transform(invtemp->ord,'9999'), substr( invtemp->comments,offset,4) ) } ) )
  offset += 4

  invbrow:addcolumn(tbcolumnNew('Supp',{ || transform(invtemp->qty,'9999') } ) )
  invbrow:addcolumn(tbcolumnNew('Sell',{ || transform(invtemp->sell,PRICE_PICT) } ) )
  invbrow:addcolumn(tbcolumnNew('Extend',{ || transform(invtemp->price*invtemp->qty, TOTAL_PICT ) } ) )
  invbrow:addcolumn(tbcolumnNew(' Disc',{ || Ns(Zero((invtemp->sell-invtemp->Price),;
          (invtemp->sell/100)),4,1)+'%' } ) )
  invbrow:addcolumn(tbcolumnNew('  Av', { || transform( MASTAVAIL, '9999' ) } ) )
  invbrow:addcolumn(tbcolumnNew('Comments', { || invtemp->comments } ) )
  invbrow:addcolumn(tbcolumnNew('Order No', { || invtemp->req_no } ) )
  invbrow:addcolumn(tbcolumnNew( ID_DESC, { || idcheck(invtemp->id) } ) )
  invbrow:freeze:=1
  invbrow:goTop()
  mkey:=0
  goloop := TRUE
  while goloop
   invbrow:forcestable()
   if adding
    keyboard chr( K_INS )
   endif
   mkey:=inkey(0)
   if !Navigate( invbrow,mkey )
    select invtemp

    do case
    case mkey == K_F1
     aHelpLines := { ;
     { 'Ins','Add Item' } ,;
     { 'Del','Delete Item' },;
     { 'Enter','Adjust Item' },;
     { 'F4','Process Header' },;
     { 'F5','Change Cust Order #' },;
     { 'F10','Disp Desc' },;
     { '<ESC>','Finish Processing' } }
     aadd( aHelpLines, { 'F11','Edit Customer' } )
     Build_help( aHelpLines )
     
    case mkey == K_F11
     InvEditCust()

    case mkey == K_F4    // Header Processing Key?
     HeaderProcessed := ProcHeader( mtrmac, @mtotdisc, @mgross, @mnett, @mcogs, @mtax )

    case mkey == K_F5    // Edit Customer Order #
     if customer->sort_ord != 'O'
      mscr := Box_Save( 5, 10, 7, 70 )
      @ 6, 12 say 'Customer Order Number' get invvars[ CUSTORDER ]
      read
      if updated()
       mrecno := invtemp->( recno() )
       invtemp->( dbgotop() )
       while !invtemp->( eof() )
        invtemp->req_no := invvars[ CUSTORDER ]
        invtemp->( dbskip() )
       enddo
       invtemp->( dbgoto( mrecno ) )
      endif
      Box_Restore( mscr )
     endif

    case mkey == K_F10
     if invtemp->( lastrec() ) > 0
      select master
      itemdisp( FALSE )
      select invtemp
     endif 

    case mkey == K_DEL

     if Isready( 06, 12, 'Ok to delete ' + if( invtemp->id = '*', 'comment line', ;
            'desc "'+trim( substr( master->desc, 1, 20 ) ) + '" from invoice' ) ) 

      Del_rec('invtemp')
      eval( invbrow:skipblock , -1 )
      invbrow:refreshall()
      Inv_tot( mtotdisc, @mgross, @mnett, @mcogs, @mtax )

     endif

    case mkey == K_INS
     mspec := 0
     mdisc := 0
     mserial := space( 15 )

     do case
     case ( invvars[ APPEMODE ] > 0 .and. invvars[ APPEMODE ] <= APPE_AP_BY_NUMBER )
      sID := ( invvars[ APPEFILE ] )->id 
      keyboard chr( K_ENTER ) + chr( K_ENTER )

     case invvars[ APPEMODE ] = APPE_FROM_BOOKLIST
      sID := bklsid->id
      keyboard chr( K_ENTER ) + chr( K_ENTER )
      
     case invvars[ APPEMODE ] = APPE_BY_CATEGORY
      sID := macatego->id
      keyboard chr( K_ENTER ) + chr( K_ENTER )

     case invvars[ APPEMODE ] = APPE_BY_PROFORMA
      sID := invline->id
      keyboard chr( K_ENTER ) + chr( K_ENTER )

     otherwise
      sID := space( ID_ENQ_LEN )
      adding := TRUE

     endcase

     mscr:=Box_Save( 11, 18, 13, 62 )
     @ 12,20 say 'Scan Code or Enter id' get sID pict '@!'

     if invvars[ APPEMODE ] = 0 .and. minv
      okaf1 := setkey( K_ALT_F1, { || Invspec( @mspecnum, mcustkey, @autoappe, @adding ) } )  
      okaf2 := setkey( K_ALT_F2, { || Invspec( @mspecnum, mcustkey, @autoappe, @adding ) } )
      okaf3 := setkey( K_ALT_F3, { || Invspec( @mspecnum, mcustkey, @autoappe, @adding ) } ) 
      okaf4 := setkey( K_ALT_F4, { || Invspec( @mspecnum, mcustkey, @autoappe, @adding ) } )
      okaf5 := setkey( K_ALT_F5, { || Invspec( @mspecnum, mcustkey, @autoappe, @adding ) } )
      okaf6 := setkey( K_ALT_F6, { || Invspec( @mspecnum, mcustkey, @autoappe, @adding ) } )
      okaf7 := setkey( K_ALT_F7, { || Invspec( @mspecnum, mcustkey, @autoappe, @adding ) } )

     endif
     fksave := Box_Save( 23, 00, 24, 79 )
     Fkon()
     read
     Fkoff()
     Box_Restore( fksave )
     setkey( K_ALT_F1, okaf1 )
     setkey( K_ALT_F2, okaf2 )
     setkey( K_ALT_F3, okaf3 )
     setkey( K_ALT_F4, okaf4 )
     setkey( K_ALT_F5, okaf5 )
     setkey( K_ALT_F6, okaf6 )
     setkey( K_ALT_F7, okaf7 )
     Box_Restore( mscr )
     if ( !updated() .and. invvars[ APPEMODE ] = 0 ) .or. lastkey() = K_ESC
      adding := FALSE

     else
      if sID != '*' .and. !Codefind( sID )
       clear typeahead
       Error( ID_DESC + sID + ' not on file', 12 )
       if invvars[ APPEMODE ] > 0 .and. invvars[ APPEMODE ] < 5
        Error( 'Check the ' + invvars[ APPEFILE ], 12 )
        invvars[ APPEMODE ]:=0

       endif
       loop

      else
       if sID != '*'

        mord := Bvars( B_INQTY )
        mqty := Bvars( B_INQTY )

        if invvars[ APPEMODE ] > 0       // Funny append modes engaged

         do case
         case invvars[ APPEMODE ] = APPE_SP_BY_KEY .OR. invvars[ APPEMODE ] = APPE_SP_BY_NUMBER    // Append from Special Order Modes
          invvars[ APPEFILE ] := 'Special'
          mord := special->received-special->delivered
          if mord <= 0
           special->( dbskip() )
           if ( special->( eof() ) .or. ;
             if( invvars[ APPEMODE ] = APPE_SP_BY_NUMBER, special->number != mspecnum, special->key != mcustkey ) )
            invtemp->( dbgotop() )
            invbrow:refreshall()
            invvars[ APPEMODE ] := 0
            autoappe := FALSE
           endif
           select invtemp
           loop
          endif

          mqty := mord

          mspec := special->number
          invvars[ CUSTORDER ] := if( !empty( special->ordno ), special->ordno, invvars[ CUSTORDER ] )

         case invvars[ APPEMODE ] = APPE_AP_BY_KEY .or. invvars[ APPEMODE ] = APPE_AP_BY_NUMBER  // Approval append modes
          invvars[ APPEFILE ] := 'Approval'
          mord := max( APPR_AVAIL, 0 )
          mqty := max( APPR_AVAIL, 0 )
          if mqty <= 0
           approval->( dbskip() )
           if ( approval->( eof() ) .or. ;
             if( invvars[ APPEMODE ] = APPE_AP_BY_NUMBER, approval->number != mspecnum, approval->key != invvars[ APPRKEY ] ) )
            invtemp->( dbgotop() )
            invbrow:refreshall()
            invvars[ APPEMODE ] := 0
            autoappe := FALSE
           endif
           select invtemp
           loop
          endif
          mspec := approval->number

         case invvars[ APPEMODE ] = APPE_AP_BY_FOREIGN_KEY
          invvars[ APPEFILE ] := 'Approval'
          select approval
          seek invvars[ APPRKEY ]
          locate for approval->id = master->id .and. APPR_AVAIL > 0 ; 
                 while approval->key = invvars[ APPRKEY ]
          if !found() 
           if approval->key != invvars[ APPRKEY ]
            Error( 'This '+ID_DESC+' is not on approval for customer ' + invvars[ APPRKEY ], 12 )
           else
            Error( 'No undelivered qty on approval for customer ' + invvars[ APPRKEY ], 12 )
           endif
           if !Isready( 12 )
            loop
           endif
          endif
          mspec := approval->number
          select invtemp

         case invvars[ APPEMODE ] = APPE_FROM_BOOKLIST
          invvars[ APPEFILE ] := 'Booklist'
          mqty := max( students->picked - students->invoiced , 0 )
          mord := students->required
          keyboard chr( K_PGDN ) + chr( K_PGDN ) + chr( K_PGDN )

         case invvars[ APPEMODE ] = APPE_BY_CATEGORY
          invvars[ APPEFILE ] := 'Macatego'
          mqty := 1
          mord := 1
          keyboard chr( K_PGDN ) + chr( K_PGDN ) + chr( K_PGDN )

         case invvars[ APPEMODE ] = APPE_BY_PROFORMA
          invvars[ APPEFILE ] := 'Invline'
          Invvars[ CUSTORDER ] := invline->req_no
          mord := invline->ord
          mqty := invline->qty
          keyboard chr( K_PGDN ) + chr( K_PGDN ) + chr( K_PGDN )

         case invvars[ APPEMODE ] = APPE_FROM_PDT
          mpos := at( ',', invvars[ PDTARR ][ invvars[ ORDINAL ] ] )
          if mpos > 0
           mqty := val( substr( invvars[ PDTARR ][ invvars[ ORDINAL ] ], mpos+1, 10 ) )
           mord := mqty
          endif
         endcase

        endif
        mscr := Box_Save( 7, 00, 10, 79 )
        @ 07,03 say 'Desc 컴컴컴컴컴컴컴컴컴컴컴컴컴컴?Price 컴 Disc컴 Ord Supp ?Extend?%?Av'
 #ifndef NO_NETT_DISCOUNTS
        @ 8,01 say substr( master->desc, 1, 38 ) 
 #else
        @ 8,01 say substr( master->desc, 1, if( !master->nodisc, 38, 30 ) ) + if( master->nodisc, ' NETT!!', '' )
 #endif
        @ 8,76 say MASTAVAIL pict '999'

        if invvars[ APPEMODE ] != APPE_FROM_BOOKLIST
         mSellPrice := master->sell_price
         if customer->exempt
          mSellPrice := master->nett_price
         endif
        else
         msellprice := bklsid->price_firm
        endif
        @ 8,34 get mSellPrice pict PRICE_PICT valid( mSellPrice < MAXSCAN )
        if autoappe
         keyboard chr( K_ENTER )
        endif
        read
        msell := mSellPrice
 #ifdef NO_NETT_DISCOUNTS
         if !(master->nodisc)
           mSellPrice := mSellPrice - ( (msellprice/100) * Bvars( B_STD_DISC ) )
         endif
 #else
        mSellPrice := mSellPrice - ( (msellprice/100) * Bvars( B_STD_DISC ) )
 #endif
        if Bvars( B_MATRIX )
         mdisc := LookItUp( "brand" ,master->brand ,'disc_'+;
            if( empty(customer->disc_type),'a',customer->disc_type ) )
         @ 8,71 say mdisc pict '999.9'
         mSellPrice := mSellPrice - ( (mSellPrice/100) * mdisc )
        endif
        @ 8,44 get mSellPrice pict PRICE_PICT valid(mSellPrice < MAXSCAN )
        msave := Box_Save(9,3,15,30)
        discdone := FALSE
        @ 10,05 say '<F4> = '+str( Bvars( B_DISC1 ), 5, 2 )+'% Discount'
        @ 11,05 say '<F5> = '+str( Bvars( B_DISC2 ), 5, 2 )+'% Discount'
        @ 12,05 say '<F6> = '+str( Bvars( B_DISC3 ), 5, 2 )+'% Discount'
        @ 13,05 say '<F7> = '+str( Bvars( B_DISC4 ), 5, 2 )+'% Discount'
        @ 14,05 say '<F8> = Add your own Disc.'
        oldf4 := setkey( K_F4, { || InvLineDisc( @msellprice, Bvars( B_DISC1 ), K_F4, @discdone ) } )
        oldf5 := setkey( K_F5, { || InvLineDisc( @msellprice, Bvars( B_DISC2 ), K_F5, @discdone ) } )
        oldf6 := setkey( K_F6, { || InvLineDisc( @msellprice, Bvars( B_DISC3 ), K_F6, @discdone ) } )
        oldf7 := setkey( K_F7, { || InvLineDisc( @msellprice, Bvars( B_DISC4 ), K_F7, @discdone ) } )
        oldf8 := setkey( K_F8, { || InvLineDisc( @msellprice, 0, K_F8, @discdone ) } )
        if autoappe
         keyboard chr( K_ENTER )
        endif
        read
        Box_Restore( msave )
        setkey( K_F4, oldf4 )
        setkey( K_F5, oldf5 )
        setkey( K_F6, oldf6 )
        setkey( K_F7, oldf7 )
        setkey( K_F8, oldf8 )
        @ 8, 72 say str( Zero((msell-mSellPrice),(msell/100)),5,1 ) pict '999.9'
        @ 8, 54 get mord pict '9999'
        @ 8, 59 get mqty pict '9999' valid if( invvars[ APPEMODE ] != APPE_AP_BY_FOREIGN_KEY, ;
               if( minv, mqty <= mord, mqty <= 999 ), mqty <= APPR_AVAIL )
        mcomments := space( 80 )
        @ 9, 1 say 'Comments' get mcomments pict '@S38'
        if minv .and. customer->sort_ord = 'O'
         if !autoappe
          @ 9,50 say 'Cust. Order No' get invvars[ CUSTORDER ] pict '@!KS16'
         endif
        endif

#ifdef SERIAL_NUMBERS
        @ 9, 50 say 'Serial No' get mserial pict '@!' valid( empty( mserial ) .or. Serial_chk( master->id, mserial ) )
        if autoappe
         keyboard chr( K_ENTER ) + chr( K_ENTER ) + chr( K_ENTER )

        endif
#endif

        read
        Box_Restore( mscr )
        if mqty > 0 .or. mord > 0 .and. lastkey() != K_ESC
         if master->onhand-mqty  < -499
          Error('Lower Stock Limit reached on ' + substr(master->desc,1,20),12)

         endif
         mextend := round( mqty * msellprice, 2 )
         @ 8,62 say mextend pict TOTAL_PICT
         mnett += mextend
         Add_rec( 'invtemp' )
         invtemp->id := master->id
         invtemp->qty := mqty
         invtemp->ord := mord
         invtemp->sell := msell
         invtemp->price := mSellPrice
         invtemp->spec_no := mspec
         invtemp->req_no := invvars[ CUSTORDER ]
         invtemp->tax := msellprice - ( msellprice * ( 1/ ( 1 + ( Stret() / 100 ) ) ) )
         do case
         case minvsort = 'O'
          lastsort := trim( invvars[ CUSTORDER ] ) + master->desc

         case minvsort = 'T'
          lastsort := master->desc

         case minvsort = 'A'
          lastsort := master->alt_desc

         otherwise
          lastsort := ''

         endcase

         invtemp->comments := mcomments
         invtemp->skey := lastsort

#ifdef PREPACK
         if invvars[ STUDFLAG ]
          invtemp->bkls_seq := students->sequence
          invtemp->skey := '' // Fix sort order in prepack invoices
         endif
#endif

         invtemp->serial := mserial
         invtemp->( dbrunlock() )

        endif

       else          // id = '*'
        mcomments := space( 80 )
        @ 8,0 get mcomments
        read
        if lastkey() != K_ESC
         Add_rec( 'invtemp' )
         invtemp->id := '*'
         invtemp->comments := mcomments
         invtemp->skey := lastsort
         invtemp->( dbrunlock() )
        endif

       endif

       Inv_tot ( mtotdisc, @mgross, @mnett, @mcogs, @mtax )

       if !autoappe
        invbrow:gobottom()
       endif
      endif
     endif

    case mkey == K_ENTER
     if invtemp->( lastrec() ) != 0
      Rec_Lock( 'invtemp')
      mscr:=Box_Save( 05, 00, 10, 79, C_MAUVE )
      if invtemp->id = '*'
       @ 7, 02 say 'Comments'
       @ 8, 02 get invtemp->comments pict '@S75'
      else
       @ 06,04 say 'Desc'
       @ 06,42 say 'Sell     Disc      Ord  Qty'
       Highlight( 07,01,'', substr( master->desc, 1, 24 ) )
       @ 07,39 get invtemp->sell pict PRICE_PICT valid( invtemp->sell < MAXSCAN )
       @ 07,47 get invtemp->price pict PRICE_PICT valid( invtemp->price < MAXSCAN )
       @ 07,60 get invtemp->ord pict QTY_PICT
       @ 07,65 get invtemp->qty pict QTY_PICT
       @ 08,01 say 'Comments' get invtemp->comments pict '@S37'
       @ 08,50 say 'Order No' get invtemp->req_no pict '@S16'
#ifdef SERIAL_NUMBERS
       @ 09,01 say 'Serial No' get invtemp->serial pict '@!' valid( Serial_chk( master->id, invtemp->serial ) )
#endif
      endif
      read
      invtemp->( dbrunlock() )
      Box_Restore( mscr )
      mrec := invtemp->( recno() )
      Inv_tot( mtotdisc, @mgross, @mnett, @mcogs, @mtax )
      invtemp->( dbgoto( mrec ) )
      invbrow:Refreshall()
     endif

    case mkey == K_CTRL_P
     Box_Save( 20,2,22,78 )
     Center( 21, '-=< ' + mtrmac + ' Test Printing in Progress >=-' )
     Invform( 0,FALSE )
     Invbrow:refreshall()

    case mkey == K_ESC .or. mkey == K_END 
     if invtemp->( lastrec() ) != 0
      if !HeaderProcessed
       HeaderProcessed := ProcHeader( mtrmac, @mtotdisc, @mgross, @mnett, @mcogs, @mtax)

      endif

     endif

     mpost_it := YES
     mprint := if( invvars[ STWASINV ], NO, YES )
     mscr := Box_Save( 19,20,23,54 )
     mfinish := FALSE
     @ 20,28 say 'Finished Processing' get mfinish pict 'y'
     if invtemp->( lastrec() ) = 0
      mpost_it := FALSE

     else
      if ( Bvars( B_PICKSLIP ) .and. !mproc_pick_slip )
       @ 21,22 say 'Ok to produce Picking Slip' get mpost_it pict 'y'

      else
       @ 21,22 say ' Ok to Post this ' + mtrmac + '?' get mpost_it pict 'y'
       @ 22,22 say 'Ok to Print this ' + mtrmac + '?' get mprint pict 'y'

      endif

     endif
     read
     Box_Restore( mscr )

     goloop := !mfinish

    endcase
   endif        // !Navigate()

   if invvars[ APPEMODE ] > 0

    do case
    case invvars[ APPEMODE ] = APPE_BY_CATEGORY
     macatego->( dbskip() )
     if macatego->( eof() ) .or. macatego->code != invvars[ APPRKEY ]
      invvars[ APPEMODE ] := 0
      autoappe := FALSE

     endif

    case invvars[ APPEMODE ] = APPE_BY_PROFORMA
     invline->( dbskip() )
     if invline->( eof() ) .or. invline->number != invvars[ APPRKEY ]
      invvars[ APPEMODE ] := 0
      autoappe := FALSE
      invbrow:gotop()
      invbrow:refreshall()

     endif
                                                           
    case invvars[ APPEMODE ] = APPE_FROM_BOOKLIST   //  was ->  if invvars[ STUDFLAG ]
     students->( dbskip() )
     while students->key = invvars[ STUDARR ][ invvars[ ORDINAL ] ] .and. ;
           students->invoiced = students->required .and. !students->(eof())
      invvars[ STWASINV ] := TRUE
      students->( dbskip() )

     enddo

     if students->( eof() ) .or. students->key != invvars[ STUDARR ][ invvars[ ORDINAL ] ]
      invvars[ APPEMODE ] := 0

     endif
     select invtemp

    case invvars[ APPEMODE ] < APPE_AP_BY_FOREIGN_KEY
     select ( invvars[ APPEFILE ] ) 
     (invvars[ APPEFILE ])->( dbskip() )
     if (invvars[ APPEFILE ])->( eof() ) .or. ;
      if( ( invvars[ APPEMODE ] = APPE_AP_BY_NUMBER .or. invvars[ APPEMODE ] = APPE_SP_BY_NUMBER ), (invvars[ APPEFILE ])->number != mspecnum, ;
        if( invvars[ APPEFILE ]='Special', special->key != mcustkey, approval->key != invvars[ APPRKEY ] ) )
      invvars[ APPEMODE ] := 0
      autoappe := FALSE
      invbrow:refreshall()
     endif
     select invtemp

    case invvars[ APPEMODE ] = APPE_FROM_PDT 
     invvars[ ORDINAL ]++
     if invvars[ ORDINAL ] > len( invvars[ PDTARR ] )
      invvars[ APPEMODE ] := 0
      autoappe := FALSE
      invbrow:gotop()
      invbrow:refreshall()
      Error( 'PDT Append Run finished', 12, , 'Remember to Clear the PDT Memory with FUNCTION 19' )
     endif
    endcase

   endif

   if autoappe .and. inkey() = K_ESC
    autoappe := FALSE
    invvars[ APPEMODE ] := 0
    invbrow:refreshall()
   endif

  enddo         // !Escape

 endif          // Auto Picking Slips

 if mpost_it
  Box_Save( 19,19,23,61 )
  if ( Bvars( B_PICKSLIP ) .and. !mproc_pick_slip )
   mpickno := Sysinc( 'pickslip', 'I', 1, 'pickslip' )
   @ 20,22 say 'Picking Slip #' + Ns( mpickno )


   invtemp->( dbgotop() )
   while !invtemp->( eof() )
    Add_rec( 'pickslip' )
    pickslip->number := mpickno
    pickslip->key := mcustkey
    pickslip->id := invtemp->id
    pickslip->qty := invtemp->qty
    pickslip->ord := invtemp->ord
    pickslip->sell := invtemp->sell
    pickslip->price := invtemp->price
    pickslip->tax := invtemp->tax
    pickslip->skey := invtemp->skey
    pickslip->req_no := invtemp->req_no
    pickslip->spec_no := invtemp->spec_no
    pickslip->invoiced := FALSE
    pickslip->invoice := minv
    pickslip->comments := invtemp->comments
    pickslip->tot_disc := mtotdisc
    pickslip->freight := invvars[ FREIGHT ]
    pickslip->special := if(invtemp->spec_no!=0,if(invvars[ APPEFILE ]='Special',TRUE,FALSE),FALSE)
    pickslip->date := Bvars( B_DATE )
    pickslip->salesman := invvars[ SALESREP ]

    pickslip->message1 := mcom1
    pickslip->message2 := mcom2
    pickslip->message3 := mcom3

    pickslip->operator := invvars[ ZOPERATOR ]

    invtemp->( dbskip() )
   enddo
   Print_find( "pickslip","report" )
   PickSlip( mpickno )

  else

   if autopick
    mprint := YES
   endif
   
#ifdef CREDIT_NOTE_NUMS
   if mtrmac = 'Credit Note' 
    minvno := Sysinc( if( invvars[ STUDFLAG ], 'booklist', 'creditnote' ), 'I', 1, 'invhead' )
   else
    minvno := Sysinc( if( invvars[ STUDFLAG ], 'booklist', 'invno' ), 'I', 1, 'invhead' )
   endif

#else
   minvno := Sysinc( if( invvars[ STUDFLAG ], 'booklist', 'invno' ), 'I', 1, 'invhead' )

#endif

   mspecno := 0    // For automatic Backordering
   
   Center( 20, 'Posting Invoice #' + Ns( minvno ) )

   if Bvars( B_PICKSLIP ) .and. mproc_pick_slip    // Flag Picking slip as invoiced
    if pickslip->( dbseek( mpickno ) )
     while pickslip->number = mpickno .and. !pickslip->( eof() )
      Rec_lock( 'pickslip' )
      pickslip->invoiced := YES
      pickslip->( dbrunlock() )
      pickslip->( dbskip() )

     enddo

    endif

   endif
   select invtemp

   indx( 'invtemp->skey', 'skey' )

   Add_rec( 'invhead' )
   invhead->key := mcustkey
   invhead->number := mInvno
   invhead->date := Bvars( B_DATE )
   invhead->order_no := invvars[ CUSTORDER ]
   invhead->tot_disc := mtotdisc
   invhead->printed := FALSE
   invhead->inv := mInv
   invhead->inst1 := mInst1
   invhead->inst2 := mInst2
   invhead->freight := invvars[ FREIGHT ]
   invhead->message1 := mcom1
   invhead->message2 := mcom2
   invhead->message3 := mcom3

#ifdef PREPACK
   if invvars[ STUDFLAG ]
    invhead->stud_tag := invvars[ STUDTAG ]
    invhead->bkls_code := invvars[ BKLSCODE ]
   endif
#endif
   invhead->operator := invvars[ ZOPERATOR ]

   invhead->operator := Oddvars( OPERCODE )
   if proforma
    invhead->proforma := proforma
   endif      

   invhead->( dbrunlock() )
   invtemp->( dbgotop() )

   if !proforma
    Add_rec( 'sales' )
    sales->tran_type := if( minv, 'INV', 'C/N' )
    sales->sale_date := Bvars( B_DATE )
    sales->time := time()
    sales->register := lvars( L_REGISTER )
    sales->operator := Oddvars( OPERCODE )
    sales->cost_price := mcogs
    sales->sales_tax := mtax
    sales->qty := if( minv,1,-1 )
    sales->discount := mgross - mnett
    sales->key := mcustkey
    sales->invno := minvno
    sales->name := customer->name
    sales->tran_num := lvars( L_CUST_NO )
    sales->freight := invvars[ FREIGHT ]

    sales->unit_price := mgross + invvars[ FREIGHT ]
    sales->( dbrunlock() )

   endif


   while !invtemp->( eof() )

    bo_qty := invtemp->ord - invtemp->qty

    if Bvars( B_AUTOBACK ) .and. bo_qty > 0 .and. minv .and. invtemp->spec_no = 0 ;
       .and. !invvars[ STUDFLAG ]

     mspecno := iif( mspecno = 0, Sysinc( 'specno', 'I', 1 ), mspecno )

     Center( 21, 'Raising Special Order #' + Ns( mspecno ) )
     mrec := special->( recno() )
     Add_rec( 'special' )
     special->number := mspecno
     special->key := mcustkey
     special->date := Bvars( B_DATE )
     special->desc := master->desc
     special->alt_desc := master->alt_desc
     special->qty := bo_qty
     special->notfound := ''
     special->ordno := invtemp->req_no
     special->supp_code := master->supp_code
     special->id := invtemp->id
     special->specmode := 1
     special->( dbrunlock() )
     special->( dbgoto( mrec ))

     if master->( dbseek( invtemp->id ) )
      Rec_lock( 'master' )
      master->special += bo_qty
      master->( dbrunlock() )

     endif

     select draft_po
     seek invtemp->id
     locate for draft_po->source = 'In' .and. draft_po->supp_code = master->supp_code ;
            while draft_po->id = invtemp->id

     if found()
      Rec_lock( 'draft_po' )
      draft_po->qty += bo_qty

     else
      Add_rec( 'draft_po' )
      draft_po->id := master->id
      draft_po->supp_code := master->supp_code
      draft_po->qty := bo_qty
      draft_po->date_ord := Bvars( B_DATE )
      draft_po->special := TRUE
      draft_po->hold := TRUE
      draft_po->skey := master->alt_desc
      draft_po->source := 'In'
      draft_po->department := master->department
      draft_po->skey := master->desc

     endif
     draft_po->( dbrunlock() )

    endif              // Back Order Processing

    if minv
     mqty := invtemp->qty
     mast_qty := invtemp->qty

    else
     mqty := -invtemp->qty
     mast_qty := -invtemp->qty

    endif
    if !proforma
     if master->( dbseek( invtemp->id ) )
      Rec_lock('master')
      Update_oh( -mast_qty )
      master->dsale := Bvars( B_DATE )
      master->( dbrunlock() )

     endif

    endif
    if invtemp->spec_no != 0
     select ( invvars[ APPEFILE ] )
     if invvars[ APPEFILE ] = 'Special'
      ordsetfocus( BY_NUMBER )
      dbseek( invtemp->spec_no )
      locate for special->id = invtemp->id .and. special->qty - special->delivered > 0 ;
            while special->number = invtemp->spec_no .and. !special->( eof() )
      specqty := min( mqty, special->qty - special->delivered )
     else
      ordsetfocus( BY_NUMBER )
      dbseek( invtemp->spec_no )
      locate for approval->id = invtemp->id .and. APPR_AVAIL > 0 ;
             while approval->number = invtemp->spec_no .and. !approval->( eof() )
      specqty := min( mqty, APPR_AVAIL )
     endif
     if !found()
      Error( 'Trouble locating '+invvars[ APPEFILE ]+' Order #' + Ns( invtemp->spec_no ), 21 )
     else
      Rec_lock( invvars[ APPEFILE ] )
      (invvars[ APPEFILE ])->delivered += specqty
      (invvars[ APPEFILE ])->comments := trim( (invvars[ APPEFILE ])->comments ) + ' Inv#' + Ns( minvno )
      (invvars[ APPEFILE ])->( dbrunlock() )
      Rec_lock( 'master' )
      if invvars[ APPEFILE ] = 'Approval'
       master->approval -= specqty
      else
       master->special -= specqty
      endif
      master->( dbrunlock() )
     endif         // found in approval/special file
     ordsetfocus( 1 )

    endif          // Auto Backordering

#ifdef PREPACK
    if invvars[ STUDFLAG ] .and. invtemp->bkls_seq != 0
     if !students->( dbseek( customer->key + chr( invtemp->bkls_seq ) ) )
      Error( "Trouble posting seq#"+Ns(invtemp->bkls_seq)+" for customer " + customer->key , 12 )
     else
      Rec_lock( 'students' )
      students->invoiced += mqty
      students->date_inv := Bvars( B_DATE )
      students->( dbrunlock() )
     endif
    endif
#endif

    if mqty != 0 .and. !proforma
     munit := invtemp->price

     if mtotdisc > 0
      munit -= munit/100*mtotdisc

     endif

     Add_rec( 'sales' )
     sales->id := master->id
     sales->qty := mqty
     sales->unit_price := invtemp->sell
     sales->cost_price := master->cost_price
     sales->discount := invtemp->sell - munit
     sales->sales_tax := if( customer->exempt, 0, invtemp->tax )
     sales->tran_num := lvars( L_CUST_NO )
     sales->register := lvars( L_REGISTER )
     sales->sale_date := Bvars( B_DATE )
     sales->time := time()
     sales->tran_type := if( minv, 'INV', 'C/N' )
     sales->key := customer->key
     sales->invno := minvno
     sales->operator := Oddvars( OPERCODE )
     sales->( dbrunlock() )

    endif

    Add_rec( 'invline' )
    invline->number := minvno
    invline->id := invtemp->id
    invline->qty := invtemp->qty
    invline->ord := invtemp->ord
    invline->sell := invtemp->sell
    invline->price := invtemp->price
    invline->tax := invtemp->tax
    invline->skey := invtemp->skey
    invline->req_no := invtemp->req_no
    invline->spec_no := invtemp->spec_no
    invline->comments := invtemp->comments
  //  invline->branch := Bvars( B_BRANCH )
    invline->( dbrunlock() )

#ifdef SERIAL_NUMBERS
    if !empty( invtemp->serial )
     if Netuse( 'serial' )
      serial->( dbseek( invline->id ) )
      locate for serial->serial = invtemp->serial while serial->id = invtemp->id
      if !found()
       Add_rec()
       serial->id := invtemp->id
       serial->serial := invtemp->serial

      endif 
      Rec_lock( 'serial' )
      serial->invno := minvno
      serial->key := mcustkey
      serial->date_sold := Bvars( B_DATE )
      serial->( dbrunlock() )
      serial->( dbclosearea() )
     endif
    endif

#endif

    invtemp->( dbskip() )

   enddo
#ifdef CN_TO_BACKORDERS
   if !minv .and. !proforma
    if !Netuse( "recvhead" ) .or. !Netuse( 'recvline' )
     Error( 'Cannot open Stock Receiving - you must post C/N through receiving', 12 )
     SysAudit( 'C/N-RecvPostError' )
    else

     Add_rec( 'recvhead' )
     recvhead->supp_code := '!C/N'
     recvhead->invoice := 'Cn:' + Ns( minvno )
     recvhead->dreceived := Bvars( B_DATE )
     recvhead->( dbrunlock() )

     invtemp->( dbgotop() )
     while !invtemp->( eof() )
      Add_rec( 'recvline' )
      recvline->key := recvhead->supp_code + recvhead->invoice
      recvline->id := invtemp->id
      recvline->qty := invtemp->qty
   //   recvline->branch := Bvars( B_BRANCH )
      recvline->( dbrunlock() )

      invtemp->( dbskip() )
     enddo
     recvline->( dbclosearea() )
     recvhead->( dbclosearea() )
    endif
   endif   // is minv
#endif

   if proforma
    mnett := invvars[ FREIGHT ] := mtax := msundries := 0

   endif

   customer->( dbseek( mcustkey ) )
   mbillkey := if( !empty( customer->bill_key ), customer->bill_key, customer->key )
   if !customer->( dbseek( mbillkey) )
    Error( "Incorrect Bill key on customer " + mcustkey +" on invoice #" +Ns( minvno ), 12 )
    SysAudit( "BillKeyErr" + mcustkey )

   else
    mtnett := mnett + invvars[ FREIGHT ] + msundries      // Temp nett
    Rec_lock( 'customer' )
    if minv .or. !customer->op_it           // For Balance BF
     customer->amtcur += if( minv, mtnett, -mtnett )
     customer->lastbuy := 1
     customer->amt_lp := mtnett
     customer->date_lp := if( minv, Bvars( B_DATE ), customer->date_lp )
     customer->ytdamt += if( minv, mtnett, -mtnett )

    endif
    customer->( dbrunlock() )
// No unlock here as Open_proc assumes records locked for update
    munalloc:=0
    if !minv .and. customer->op_it   // Process Invoices Credited Here
     Heading( "Credit Invoices outstanding" )
     munalloc := Open_proc( customer->key, mtnett, mtnett, 2 )

    endif

    mnett := mnett + invvars[ FREIGHT ] + msundries

    Add_rec( 'debtrans' )
    debtrans->key := mbillkey
    debtrans->bill_key := mbillkey
    debtrans->amt := if( minv, mnett, -mnett )
    debtrans->amtpaid := if( minv, munalloc, -munalloc )
    debtrans->salestax := if( customer->exempt, 0, if( minv, mtax, -mtax ) )
    debtrans->freight := if( minv, invvars[ FREIGHT ], -invvars[ FREIGHT ] )
    debtrans->date := Bvars( B_DATE )
    debtrans->ttype := if( minv, 1, 2 )
    debtrans->tnum := Ns( mInvno ) + if( proforma, 'Pf:', '' )
    debtrans->tage := 1
    debtrans->salesman := invvars[ SALESREP ]
    debtrans->operator := invvars[ ZOPERATOR ]
    debtrans->comment := invvars[ CUSTORDER ]
    debtrans->( dbrunlock() )
   endif


   if mprint

    Center( 22,'-=< '+mtrmac+' Printing in Progress >=-' )
    if upper( Invvars[ DESTPRINT ] ) == 'DOCKET'         // if docket print only 1 invoice
      Print_find( "docket")
      Invform( minvno )
    else
      for x := 1 to if( minv,if( invvars[ STUDFLAG ], Bvars( B_PREPINV ), Bvars( B_ININ ) ) ,Bvars( B_INCR ) )
        Print_find( "invoice" )
        Invform( minvno )
      next
    endif

   endif

  endif  // !pickslip

 endif

 invtemp->( orddestroy( 'skey' ) )
 invtemp->( dbclosearea() )
 Kill( Oddvars( TEMPFILE ) + ordbagext() )
 
 if select("macatego") != 0
  macatego->( dbclosearea() )
 endif

enddo
return

*

Function InvEditCust
local olddbf := select()
select customer
CustEdScr( FALSE )
select ( olddbf )
return nil

*

function RoundDisc ( p_val )
local pb, new_bit
while TRUE
 pb := substr( Ns( p_val, 10, 1 ), -1, 1 )   // for Parameter Bit
 new_bit := if( pb $ "0123" , "0" , "5" )
 if pb $ '01234567'
  exit
 else
  p_val += 0.2   // Must add .2 dollar and go again
 endif
enddo
return val(substr(Ns(p_val,10,1),1,len(Ns(p_val,10,1))-1)+new_bit)

*

Function ProcHeader( mtrmac, mtotdisc, mgross, mnett, mcogs, mtax )

local mscr:=Box_Save( 6, 1, 18, 77 ),getlist:={}
local oldkf4, oldkf5, oldkf6, oldkf7, oldkf8
local mpost := FALSE

mtotdisc := 0

Inv_tot( mtotdisc, @mgross, @mnett, @mcogs, @mtax )

mgross := mnett
oldkf4 := setkey( K_F4 ,{ || InvTotDisc( @mnett, Bvars( B_DISC1 ), K_F4, mtrmac ) } )
oldkf5 := setkey( K_F5 ,{ || InvTotDisc( @mnett, Bvars( B_DISC2 ), K_F5, mtrmac ) } )
oldkf6 := setkey( K_F6 ,{ || InvTotDisc( @mnett, Bvars( B_DISC3 ), K_F6, mtrmac ) } )
oldkf7 := setkey( K_F7 ,{ || InvTotDisc( @mnett, Bvars( B_DISC4 ), K_F7, mtrmac ) } )
oldkf8 := setkey( K_F8 ,{ || InvTotDisc( @mnett, 0 , K_F8, mtrmac ) } )
Box_Save( 07, 01, 13, 31 )

@ 08,02 say '<F4> = '+str(Bvars( B_DISC1 ), 5, 2 ) + '% Discount'
@ 09,02 say '<F5> = '+str(Bvars( B_DISC2 ), 5, 2 ) + '% Discount'
@ 10,02 say '<F6> = '+str(Bvars( B_DISC3 ), 5, 2 ) + '% Discount'
@ 11,02 say '<F7> = '+str(Bvars( B_DISC4 ), 5, 2 ) + '% Discount'
@ 12,02 say '<F8> = Add your own Discount'
@ 07,46 say 'Total '+padr( mtrmac, 11 ) get mnett pict TOTAL_PICT
read
setkey( K_F4, oldKF4 )
setkey( K_F5, oldKF5 )
setkey( K_F6, oldKF6 )
setkey( K_F7, oldKF7 )
setkey( K_F8, oldkf8 )

mtotdisc := (100-( Zero( mnett,( mgross/100 ) ) ) )
@ 08,46 say 'Freight Charge   ' get invvars[ FREIGHT ] pict PRICE_PICT
read

Inv_tot( mtotdisc, @mgross, @mnett, @mcogs, @mtax )

Cred_check( mnett )
Heading("Comments On Invoice")
mcom1 := mcom2 := mcom3 := space( 80 )
Highlight( 10, 35, '', trim( mtrmac) + ' Comments' )
@ 11,35 get mcom1 pict '@ks40'
@ 12,35 get mcom2 pict '@ks40'
@ 13,35 get mcom3 pict '@ks40'
read
@ 14, 35 say 'Operator' get invvars[ ZOPERATOR ] pict '!!' valid dup_chk( invvars[ ZOPERATOR ], 'operator' )
read
Box_Restore( mscr )
return TRUE

*

procedure inv_tot ( mtotdisc, mgross, mnett, mcogs, mtax )
local mtemp, mdisctemp := 0, mtqty := 0

select invtemp
dbgotop()

sum invtemp->qty * invtemp->sell, ;
    round( invtemp->qty * invtemp->price, 2 ),;
    invtemp->qty * master->COST_FIELD, ;
    invtemp->qty * invtemp->tax, invtemp->qty ;
    to mgross, mnett, mcogs, mtax, mtqty

if mtotdisc > 0
#ifdef NO_NETT_DISCOUNTS
 invtemp->( dbgotop() )
 while !invtemp->( eof() )
  if !master->nodisc
   mdisctemp += invtemp->qty * ( invtemp->price/100 * mtotdisc )
  endif
  invtemp->( dbskip() )
 enddo 
 mtemp := mnett
 mnett -= round( mdisctemp, 2 )

#else
 mtemp := mnett
 mnett -= round( ( mnett / 100 * mtotdisc ), 2 )

#endif
 mtax := Zero( mtax, round( Zero( mtemp, mnett ), 2 ) )     // Rationalise tax ??
endif
@ 3,44 say 'Nett      Tax    Qty'
Syscolor( 3 )
// mnett := if( customer->exempt, mnett, mnett + mtax )
@ 4,40 say mnett pict '99999.99'
@ 4,49 say mtax pict '99999.99'  // Tax amount
@ 4,60 say mtqty pict '9999'
Syscolor( 1 )

if mtotdisc > 0
 Highlight( 04, 70, '', '(-'+Ns( mtotdisc, 4, 1 ) + '%)' )

endif
Cred_check( mnett )
invtemp->( dbgotop() )
return

*

Func InvLineDisc ( msellprice, mdisc, mkey, discdone )
local getlist:={}
#ifdef NO_NETT_DISCOUNTS
if master->nodisc
 Error( 'Item is Nett Priced! - No Discount allowed', 12 )
 return nil
endif
#endif
if !discdone
 if mkey == K_F8
  @ 9, 35 say 'Enter Discount % ' get mdisc pict '99.9'
  read
 endif
 discdone := TRUE
 mSellPrice -= round( ( mSellPrice/100 * mdisc ), 2 )
endif
return nil

*

#ifdef SERIAL_NUMBERS
function serial_chk ( sID, mserial )
local mret := TRUE
if Netuse( 'serial' )
 if !serial->( dbseek( sID ) )
  Error( 'No record of this id ( serial # ) being received!', 12 )
 else
  locate for serial->serial = mserial while serial->id = sID
  if !found()
   Error( 'No record of this serial received under this stock code', 12 )
  else
   if !empty( serial->key ) .or. !empty( serial->invno )
    Error( 'Serial number invoiced to Customer ' + serial->key + ' on Inv No ' + Ns( serial->invno ), 12 )
    mret := FALSE
   endif
  endif  
 endif  
 serial->( dbclosearea() )
endif
return mret

#endif

*

function InvAllSpecs

// Designed to enable sequential invoicing of all outstanding Special Orders 
// A kind of Batch processing

local getlist:={}, mscr, olddbf:=select(), aArray := {}
local indisp, mkey, element, x, tscr, aHelpLines

if select( 'invhead' ) != 0   // Are we in invoicing?

 special->( ordsetfocus( 'invoiced' ) )
 special->( dbseek( 1 ) )
 while !special->( eof() ) .and. Pinwheel()
  if ascan( aArray, { |a| a[1] = special->key }  ) = 0
   customer->( dbseek( special->key ) )
   aadd( aArray, { special->key, customer->name, customer->stop, special->date } )
  endif
  special->( dbskip() )
 enddo
 special->( ordsetfocus( 'number' ) )

 if len( aArray ) = 0
  Error( 'No Special Order Customers found to Invoice', 12 )
 else
  element:=1
  Heading("Select Customer")
  mscr := Box_Save( 04, 02, 22, 50 )
  indisp := TBrowseNew( 05, 03, 21, 49 )
  indisp:HeadSep := HEADSEP
  indisp:ColSep := COLSEP
  indisp:goTopBlock := { || element:=1 }
  indisp:goBottomBlock := { || element:= len( aArray ) }
  indisp:skipBlock := { |n| ArraySkip( len( aArray ), @element, n ) }
  indisp:AddColumn( TBColumnNew( 'Name', { || padr( aArray[ element, 2 ], 20 ) } ) )
  indisp:AddColumn( TBColumnNew( 'Stop', { || if( aArray[ element, 3 ], 'Y', 'N' ) } ) )
  indisp:AddColumn( TBColumnNew( 'Date', { || aArray[ element, 4 ] } ) )
  indisp:AddColumn( TBColumnNew( 'Key', { || aArray[ element, 1 ] } ) )
  mkey:=0
  while mkey != K_ESC
   indisp:forcestable()
   mkey:=inkey(0)
   if !Navigate( indisp, mkey )
    do case
    case mkey == K_F4
     if Isready( 12, , 'Ok to resort this list Alphabetically' )
      asort( aArray,,, { | x, y | x[ 2 ] < y[ 2 ] } )
      element:=1
      indisp:gotop()
      indisp:refreshall()
     endif

    case mkey == K_F1
     aHelpLines := { { 'F4', 'Sort list Alphabetically' }, ;
                  { 'F8', 'Count Customers' }, ;
                  { 'F10', 'Process List' }, ;
                  { 'Del', 'Delete from List' }, ;
                  { 'Esc', 'Exit without Processing' } }
     Build_help( aHelpLines )

    case mkey == K_F8
     tscr := Box_Save( 10, 04, 12, 40, C_MAUVE )
     Highlight( 11, 06, 'Number of Customers to Invoice', Ns( len( aArray ) ) )
     inkey(0)
     Box_Restore( tscr )

    case mkey == K_F10
     if Isready( 12 )
      invvars[ SPECARR ] := {}
      for x := 1 to len( aArray )
       if aArray[ x, 2 ] != '***DELETED'
        aadd( invvars[ SPECARR ], aArray[ x, 1 ] )
       endif
      next
      invvars[ ORDINAL ] := 1
      invvars[ SPECFLAG ] := TRUE
      invvars[ APPEMODE ] := APPE_SP_BY_KEY
      invvars[ APPEFILE ] := 'Special'
      special->( ordsetfocus( 'key' ) )
      special->( dbseek( invvars[ SPECARR ][ 1 ] ) )
      keyboard chr( K_ESC ) + invvars[ SPECARR ][ 1 ] + chr( K_ENTER )
     endif

    case mkey == K_DEL
     aArray[ element, 2 ] := '***DELETED'
     indisp:refreshall()
    endcase

   endif
  enddo
  Box_Restore( mscr )
 endif
 select( olddbf )
endif
return nil

*

proc Ppappend ( appefile )

// This proc is called from maincust ( F7 ) - customer selection system
// It builds an array ( student_arr ) of students to invoice.

local getlist:={},mscr,olddbf:=select(),mnew, mtype, canadd, mkey
local x, temp_arr, mbklist

setkey( K_F7 , { || nil } )
if select( "students" ) = 0
 if !Netuse( "bklsid" )
  Error( "Cannot invoice Booklist here", 12 )
  return
 else
  if !Netuse( "students", SHARED, 5, , TRUE )
   Error( "Cannot invoice Booklist here", 12 )
   bklsid->( dbclosearea() )
   return
  else
   mscr:=Box_Save( 02, 08, 05, 72 )
   mbklist := space( 10 )
   mnew := FALSE
   mtype := '*'
   @ 03,10 say 'Booklist to invoice' get mbklist pict '@!'
   @ 04,10 say '  New Students only' get mnew pict 'y'
   @ 04,40 say "Student Type ('*' = All )" get mtype pict '!'
   read
   Box_Restore( mscr )
   if !bklsid->( dbseek( mbklist ) )
    Error( "No Booklist on file", 12 )
   else
    mscr := Box_Save( 2, 08, 08, 72 )
    Highlight( 3, 10, 'About to Invoice Booklist ', mbklist )
    if Isready(7)
     select students
     ordsetfocus( 'code' )
     set relation to students->key into customer
     seek mbklist          // Scan their booklists
     Center( 4, 'Preparing List of Students to invoice' )
     temp_arr := {}
     mkey := ''

/* This mkey shit is used to stop BPOS attempting to process students which have been entered on the students PP
    and subsequently deleted from customer file. During auto posting run prg will exit if non customer encountered */

     while students->bkls_code = mbklist .and. !students->( eof() )
      if !customer->( eof() )
       if students->picked - students->invoiced > 0   // check the student needs invoicing first!
        if mtype = '*' .or. customer->type = mtype
         if ascan( temp_arr, students->key ) = 0
          aadd( temp_arr, students->key )
         endif
        endif
       endif
      else
       if students->key != mkey
        Error( 'Student key ' + students->key + ' not found on customer file!', 12 )
        mkey := students->key
       endif
      endif
      students->( dbskip() )
     enddo

     ordsetfocus( 'key' ) 
     set relation to
     if !mnew
      invvars[ STUDARR ] := temp_arr
     else
      invvars[ STUDARR ] := {}
      for x := 1 to len( temp_arr )
       canadd := TRUE
       mkey := temp_arr[ x ]
       seek mkey
       while students->key = mkey .and. !students->( eof() )
        if students->invoiced > 0
         canadd := FALSE
        endif
        students->( dbskip() )
       enddo
       if canadd
        aadd( invvars[ STUDARR ], mkey )
       endif
      next
     endif

     if len( invvars[ STUDARR ] ) = 0
      Error( "No Students found to invoice" , 12 )
     else
      Center( 5, Ns( len( invvars[ STUDARR ] ) ) + ' students found to invoice' )
      set relation to students->bkls_code + chr( students->sequence ) ;
          into bklsid
      invvars[ ORDINAL ] := 1    // This is the first student to invoice
      seek invvars[ STUDARR ][ invvars[ ORDINAL ] ]
      invvars[ STWASINV ] := FALSE
      invvars[ STUDTAG ] := students->stud_tag  // Carries forward the tag number
      invvars[ BKLSCODE ] := students->bkls_code
// Check that we dont try to reinvoice the first item on list
      while students->key = invvars[ STUDARR ][ invvars[ ORDINAL ] ] .and. ;
              ( students->invoiced = students->required ) .and. ;
              !students->( eof() )
       invvars[ STWASINV ] := TRUE
       students->( dbskip() )
      enddo
      invvars[ APPEMODE ] := APPE_FROM_BOOKLIST
      invvars[ STUDFLAG ] := TRUE
      appefile := "Students"
      keyboard invvars[ STUDARR ][ invvars[ ORDINAL ] ] + chr(13) // Stuff kbrd with cust. key
     endif
    endif
    Box_Restore( mscr )
   endif
  endif
 endif
endif
select ( olddbf )
return

*

function invspec ( mspecnum, mcustkey, autoappe, adding )

local getlist:={},mscr,custrecno,mcustname, appefile, mmode :=0
local mstr, sID, mpos

setkey( K_ALT_F1, { || nil } )
setkey( K_ALT_F2, { || nil } )
setkey( K_ALT_F3, { || nil } )
setkey( K_ALT_F4, { || nil } )
setkey( K_ALT_F5, { || nil } )
setkey( K_ALT_F6, { || nil } )
setkey( K_ALT_F7, { || nil } )
setkey( K_ALT_F8, { || nil } )

do case
case lastkey() = K_ALT_F1
 mmode = APPE_SP_BY_KEY
case lastkey() = K_ALT_F2
 mmode = APPE_SP_BY_NUMBER
case lastkey() = K_ALT_F3
 mmode = APPE_AP_BY_KEY
case lastkey() = K_ALT_F4
 mmode = APPE_AP_BY_NUMBER
case lastkey() = K_ALT_F5
 mmode = APPE_AP_BY_FOREIGN_KEY
case lastkey() = K_ALT_F6
 mmode = APPE_BY_CATEGORY
case lastkey() = K_ALT_F7
 mmode = APPE_BY_PROFORMA
case lastkey() = K_ALT_F8
 mmode = APPE_BY_PROFORMA
endcase 

do case
case mmode = APPE_SP_BY_KEY .or. mmode = APPE_SP_BY_NUMBER

 appefile := 'Special'

 if mmode = APPE_SP_BY_NUMBER
  special->( ordsetfocus( BY_NUMBER ) )
 else
  special->( ordsetfocus( BY_KEY ) )
 endif

case mmode = APPE_AP_BY_KEY .or. mmode = APPE_AP_BY_NUMBER .or. mmode = APPE_AP_BY_FOREIGN_KEY

 appefile := 'Approval'

 if mmode = APPE_AP_BY_NUMBER
  approval->( ordsetfocus( BY_NUMBER ) )
 else
  approval->( ordsetfocus( BY_KEY ) )
 endif

case mmode = APPE_BY_CATEGORY

 appefile := 'macatego'
 if select( 'macatego' ) = 0

  if !Netuse( 'macatego' )
   invvars[ APPEMODE ] := NO_APPE_MODE
   return nil
  endif

 endif

endcase

mcustname := customer->name

select ( appefile )

do case

case mmode = APPE_SP_BY_NUMBER .or. mmode = APPE_AP_BY_NUMBER
 mscr:=Box_Save( 2, 08, 04, 72 )
 mspecnum := 0
 @ 3,10 say appefile + ' Order Number to invoice' get mspecnum pict '999999'
 read
 dbseek( mspecnum )
 Box_Restore( mscr )

case mmode = APPE_SP_BY_KEY .or. mmode = APPE_AP_BY_KEY .or. mmode = APPE_AP_BY_FOREIGN_KEY
 if appefile = 'Approval'
  if mmode = APPE_AP_BY_FOREIGN_KEY
   Heading( 'Find Approved from Customer' )
   custrecno := customer->( recno() )
   if !CustFind( TRUE )
    select approval
    customer->( dbgoto( custrecno ) )
    invvars[ APPEMODE ] := NO_APPE_MODE
    return nil
   else
    mcustname := customer->name
    select approval
    invvars[ APPRKEY ] := customer->key
    customer->( dbgoto( custrecno ) )
   endif
  else
   invvars[ APPRKEY ] := mcustkey
  endif
  seek invvars[ APPRKEY ]
  locate for approval->qty - approval->received - approval->delivered > 0 ;
         while approval->key = invvars[ APPRKEY ] .and. !eof()
 else
  seek mcustkey
  locate for ( appefile )->received - ( appefile )->delivered > 0 ;
         while ( appefile )->key = mcustkey .and. !eof()
 endif

case mmode = APPE_BY_CATEGORY
 mscr:=Box_Save( 2, 08, 04, 72 )
 invvars[ APPRKEY ] := space( 6 )
 @ 3,10 say 'Category code to invoice' get invvars[ APPRKEY ] pict '@!'
 read
 seek invvars[ APPRKEY ]
 Box_Restore( mscr )

case mmode = APPE_BY_PROFORMA
 appefile := 'Invline'
 mscr:=Box_Save( 2, 08, 04, 72 )
 invvars[ APPRKEY ] := 0
 @ 3,10 say 'Proforma Invoice to append' get invvars[ APPRKEY ] pict '999999'
 read
 Box_Restore( mscr )
 invhead->( dbseek( invvars[ APPRKEY ] ) )

case mmode = APPE_FROM_PDT

 select invtemp  // Need this

 mscr := Box_Save( 06, 08, 15, 72 )
 @ 07,10 say 'Ready to Append Data from Portable'
 @ 08,10 say 'Hit "Function" followed by "11"'
 @ 12,10 say 'Esc to halt downloading '
 invvars[ PDTARR ] := {}
 invvars[ ORDINAL ] := 1

 while TRUE
  mstr := space( 25 )
  @ 10,10 say 'Data' get mstr
  read
  if lastkey() = K_ESC .or. mstr = 'EOF'
   exit
  else
   aadd( invvars[ PDTARR ], mstr )
  endif
 enddo

 invvars[ APPEMODE ] := NO_APPE_MODE

 if len( invvars[ PDTARR ] ) > 0

  @ 14,10 say 'Automatic Append' get autoappe pict 'y'
  read

  if Isready( 12 )

   mpos := at( ',', invvars[ PDTARR ][ invvars[ ORDINAL ] ] )
   if mpos > 0
    sID := left( invvars[ PDTARR ][ invvars[ ORDINAL ] ], mpos-1 )
   else
    sID := invvars[ PDTARR ][ invvars[ ORDINAL ] ]
   endif

   keyboard sID + chr( K_ENTER )
   adding := TRUE
   invvars[ APPEMODE ] := mmode

  endif
 endif

 Box_Restore( mscr )

 return nil

endcase

if ( mmode != APPE_BY_PROFORMA .and. !found() ) .or. ( mmode = APPE_BY_PROFORMA .and. !invhead->( found() ) )

 if mmode != APPE_BY_PROFORMA
  Error( "No " + appefile + "s on file for customer", 12 )
 else  //   !invhead->( found() )
  Error( 'Proforma Invoice No not on file', 12 )
 endif
 invvars[ APPEMODE ] := NO_APPE_MODE

else

 mscr := Box_Save( 2, 08, 06, 72 )

 do case 
 case mmode = APPE_BY_CATEGORY
  Highlight( 3, 10, 'Category to be appended is', Lookitup( 'category', invvars[ APPRKEY ] ) )

 case mmode = APPE_BY_PROFORMA
 // We must reposition as customer file may be incorrectly positioned above in invhead->dbseek( invvars[ APPRKEY ] ) )
  customer->( dbseek( mcustkey ) )
  if !invhead->proforma
   Error( 'Selected Invoice No is not a Proforma Invoice', 12 )
   invvars[ APPEMODE ] := NO_APPE_MODE
   return nil
  else
   if invhead->key != mcustkey
    Error( 'Proforma Invoice key ' + trim( invhead->key ) + ;
           ' does not match customer', 12, ,trim( customer->name ) + ' (' + trim( mcustkey )+')' )
   endif
  endif 

 otherwise
  Highlight( 3, 10, if( mmode > 2 ,'Approval','Special Order') + ' was placed for ', mcustname )

 endcase

 if mmode != APPE_AP_BY_FOREIGN_KEY

  @ 05,10 say 'Automatic Append' get autoappe pict 'y'
  read

 else

  Highlight( 04, 10, 'To be appended to', customer->name )

 endif

 if Isready(7)

  if mmode != APPE_AP_BY_FOREIGN_KEY
   keyboard ( appefile )->id + chr( K_ENTER )
  endif

  adding := TRUE
  invvars[ APPEMODE ] := mmode

 else
 
  invvars[ APPEMODE ] := NO_APPE_MODE

 endif

 Box_Restore( mscr)

endif

return nil

/*

static function MakeDocketLines( cName, aItems, lQtyFlag )
  // Puts together lines for docket printing!
  // cName := customer name
  // aItems := line items array  {{ Desc, Quantity, SellPrice}}
#define ITEM_TITLE 1
#define ITEM_QTY   2
#define ITEM_PRICE 3

  local aLines := {}
  local nElem  := 0

  
  aadd( aLines, '~Customer : ' + left( cName, 26 ))

  for nElem := 1 to len( aItems)
    if lQtyFlag
      aadd( aLines, substr( aItems[ nElem, ITEM_TITLE], 1, 18 )+' '+str( aItems[ nElem, ITEM_QTY], 3 ) +;
                  ' @'+str( aItems[ nElem, ITEM_PRICE], 7, 2 )+' '+str( aItems[ nElem, ITEM_PRICE] * aItems[ nElem, ITEM_QTY], 8, 2 ) )
    else
      aadd( aLines, substr( aItems[ nElem, ITEM_TITLE], 1, 31 )+' '+str( aItems[ nElem, ITEM_PRICE] * aItems[ nElem, ITEM_QTY], 8, 2 ) )
    endif
  next

#undef ITEM_TITLE
#undef ITEM_QTY
#undef ITEM_PRICE

return( aLines)

* Returns an array of items in a temporary invoice file

static function Items( )

    local nAt := invTemp->( recno())
    local aItems := {}

    invTemp->( dbgotop())
    while ! invTemp->( eof())
      master->( dbseek( invtemp->id))
      aadd( aItems, {master->Desc, invtemp->qty, invtemp->price})
      invTemp->( dbskip())
    end

    invTemp->( dbgoto( nAt))

return( aItems)

*/