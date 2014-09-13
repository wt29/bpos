/**
        Dpurord.prg
 
      Last change:  TG   18 Oct 2010    9:44 pm
*/
static mby_supp    

Procedure p_drafts

#include "bpos.ch"

local mgo := FALSE,choice,oldscr:=Box_Save(), sFunKey4, msupp := Oddvars( MSUPP ), aArray
local tscr // Temp screen array

Center(24,'Opening files for Draft Purchase Order Maintenance')

if Netuse( "purhist" )
 if Netuse( "ytdsales" )
  if Master_use()
   if Netuse( "supplier" )
    if Netuse( "draft_po" )
     set relation to padr( draft_po->id, ID_CODE_LEN ) into master,;
                  to draft_po->supp_code into supplier
     mgo := TRUE
    endif
   endif
  endif
 endif
endif

Line_clear( 24 )

mby_supp := TRUE   // Always default to supplier order

while mgo
 Box_Restore( oldscr )
 Heading( 'Draft Purchase Orders Menu' )
 aArray := {}
 aadd( aArray, { 'Exit', 'Return to Purchasing Menu', nil, nil } )
 aadd( aArray, { 'Add/Change', 'Edit/Add/Delete Draft Purchase Orders', { || Dpoadd( @msupp ) }, nil } )
 aadd( aArray, { 'Print', 'Print Current Draft Purchase Orders', { || Dpoprint( @msupp ) }, nil } )
 aadd( aArray, { 'Regenerate', 'Regenerate all Draft Purchase Orders', { || Dporegen( @msupp ) }, nil } )

 if Bvars( B_DEPTORDR ) 
  tscr := Dpodispmode( @msupp )     
  sFunKey4 := setkey( K_F4, { || dpomodechg( @msupp ) } )
 endif

 choice = MenuGen( aArray, 03, 18, 'Draft PO' )

 if Bvars( B_DEPTORDR ) 
  setkey( K_F4, sFunKey4 )
  Box_Restore( tscr )
 endif

 if choice < 2
  if !mby_supp
   msupp := padr( msupp, 4 )
  endif
  Oddvars( MSUPP, msupp )
  exit
 else
  if Secure( aArray[ choice, 4 ] )
   Eval( aArray[ choice, 3 ] )
  endif
 endif
enddo
close databases
return

*

proc dpoadd ( msupp )
local mpur, mmonpur, sID, mmonth, x, dpbrow, mkey, tsupp, c, mseq
local suppcom1, suppcom2, mscr, getlist:={}, gotchya
local okf10, oldscr:=Box_Save(), suppname, mfilter:=FALSE
local mfiltertext:='', mfiltchoice, lAnswer, aHelpLines, aArray
local tscr, mreq // Temp screen array
local lProceed
select draft_po
ordsetfocus( if( mby_supp, BY_SUPPLIER, BY_DEPARTMENT ) )
while TRUE

 tscr := Box_Save( 04, 34, 07, 62 )   
 @ 05,36 say if(mby_supp,'Supplier','Department')+' Code' get msupp pict '@K!';
 valid( msupp='*'.or.Dup_chk( msupp , if(mby_supp,'Supplier','Dept') ) )

 @ 06,36 say '<F10> for '+if(mby_supp,'Supplier','Department')+' List'
 okf10 := setkey( K_F10 , {|| All_dpo( msupp, mby_supp ) } )
 read
 setkey( K_F10 , okf10 )
 Box_Restore( tscr )                    


 if lastkey() = K_ESC
  exit

 else

  if msupp != '*' .and. mby_supp
   supplier->( dbseek( msupp ) )
   suppname := trim(substr(supplier->name,1,25))
   suppcom1 := supplier->comm1
   suppcom2 := supplier->comm2
   Oddvars( MSUPP, msupp )

  endif

  if ( mby_supp .and. ( supplier->( found() ) ) ) .or. msupp = '*' .or. !mby_supp
   mmonth := substr(upper(cmonth(Bvars( B_DATE ) ) ), 1, 3 )
   mpur := 0
   mmonpur := 0
   if msupp = '*' .and. draft_po->( lastrec() = 0 )
    Error('No Drafts on file',12)
    loop

   endif
   if msupp != '*' .and. mby_supp
    if mby_supp
     select purhist
     dbseek( msupp )
     locate for purhist->code = trim(msupp) +'_REC' ;
            while purhist->code = trim( msupp )
     if found()
      mpur := purhist->jan+purhist->feb+purhist->mar+purhist->apr+;
              purhist->may+purhist->jun+purhist->jul+purhist->aug+;
              purhist->sep+purhist->oct+purhist->nov+purhist->dec 
      mmonpur := fieldget( fieldpos( mmonth ) )
     endif
    endif 
    draft_po->( ordsetfocus( BY_SUPPLIER ) )
    draft_po->( dbseek( msupp ) )
   endif

   cls
   Heading('List Draft Purchase Order')
   select draft_po

   if msupp != '*' .and. mby_supp
    Highlight( 01, 01, 'Supplier', suppname )
    Highlight( 02, 01, 'Comments', suppcom1 )
    Highlight( 03, 01, '        ', suppcom2 )
    Highlight( 02, 46, 'Purchases this month $', Ns( mmonpur ) )
    Highlight( 03, 46, 'Purchases this year  $', Ns( mpur ) )
    for x = 1 to 24-5
     @ x+5,0 say row()-5 pict '99'
    next
    dpbrow:= TBrowseDB( 04, 3, 24, 79 )
   else
    for x = 1 to 24-3
     @ x+3,0 say row()-3 pict '99'
    next
    dpbrow := TBrowseDB( 02, 3, 24, 79)
   endif

   Highlight( 1, 46, '', if( mfilter, 'Only Specials Displayed', space( 27 ) ) )
   dpbrow:colorspec := TB_COLOR
   dpbrow:HeadSep:= HEADSEP
   dpbrow:ColSep:= COLSEP
   if msupp != '*'
    dpbrow:goTopBlock:= { || dbseek( msupp ) }
    dpbrow:goBottomBlock:= { || jumptobott( msupp ) }
    if mby_supp
     dpbrow:skipblock:=Keyskipblock( { || draft_po->supp_code }, msupp )
    else
     dpbrow:skipblock:=Keyskipblock( { || draft_po->department }, msupp )
     dpbrow:addcolumn( TBColumnNew('Dep', { || draft_po->department } ) )
    endif
   else
    if !mby_supp
     dpbrow:addcolumn( TBColumnNew('Dept', { || draft_po->department } ) )
    endif 
    dpbrow:addcolumn( TBColumnNew('Supp',  { || draft_po->supp_code } ) )
   endif
   c:=tbcolumnnew( 'Desc', { || substr(master->desc,1,22) } )
   c:colorBlock := { || if( draft_po->special, {5, 6}, {1, 2} ) }
   dpbrow:addcolumn( c )
   dpbrow:addcolumn( tbcolumnnew( ALT_DESC, { || substr(master->alt_desc,1,15) } ) )
   c:=tbcolumnnew('H', { || if( draft_po->hold,'*',' ' ) } )
   c:colorblock:= { || if( draft_po->hold, {5, 6}, {1, 2} ) }
   dpbrow:addcolumn( c )
   dpbrow:addcolumn( tbcolumnnew( 'OrdQ',{ || transform( draft_po->qty,'9999') } ) )
   dpbrow:addcolumn( tbcolumnnew( 'OnHnd',{ || transform( master->onhand , '9999')} ) )
   dpbrow:addcolumn( tbcolumnnew( 'OnOrd',{ || transform( master->onorder ,'9999') } ) )
   dpbrow:addcolumn( tbcolumnnew( 'Spec',{ || transform( master->special , '9999')} ) )
   dpbrow:addcolumn( tbcolumnnew( 'Orig', { || draft_po->Source } ) )
   dpbrow:freeze := if( msupp="*",4,3 )
   dpbrow:goTop()
   mkey := 0
   while mkey != K_ESC .and. mkey != K_END
    if msupp!='*' .and. if(mby_supp,draft_po->supp_code != msupp,draft_po->department!=msupp )
     seek msupp  // Reposition dbf if all records deleted by user
    endif
    dpbrow:forcestable()
    mkey := inkey(0)
    if !navigate(dpbrow,mkey)
     do case
     case mkey >= 48 .and. mkey <= 57
      keyboard chr( mkey )
      mseq := 0
      mscr:=Box_Save( 2,08,4,40 )
      @ 3,10 say 'Selecting No' get mseq pict '999' range 1,24-2
      read
      Box_Restore( mscr )
      if !updated()
       loop
      else
       mreq := recno()
       skip mseq - dpbrow:rowpos
       if dpo_edit( dpbrow, msupp )
        dpbrow:refreshcurrent()
       endif
       goto mreq
      endif
      dpbrow:refreshall()

     case mkey == K_F3
      aArray := {}
      aadd( aArray, { ' Specials only', nil } )
      aadd( aArray, { 'Non Specials Only', nil } )
      aadd( aArray, { 'Regenerated Items Only', nil } )
      aadd( aArray, { 'Backorder (PO) Items Only', nil }  )
      aadd( aArray, { 'Backorder (Inv) Items Only', nil } )
      mfiltchoice := MenuGen( aArray, 6, 10 )
      mfiltertext := ''
      do case
      case mfiltchoice < 1
       draft_po->( dbclearfilter() )
       mfilter := FALSE
      case mfiltchoice = 1
       draft_po->( dbsetfilter( { || draft_po->source = 'Sp' } ) )
       mfiltertext := 'Only Specials Displayed'
      case mfiltchoice = 2
       draft_po->( dbsetfilter( { || draft_po->source != 'Sp' } ) )
       mfiltertext := 'NO Specials Displayed'
      case mfiltchoice = 3
       draft_po->( dbsetfilter( { || draft_po->source = 'Re' } ) )
       mfiltertext := 'Only Regenerated Items Displayed'
      case mfiltchoice = 4
       draft_po->( dbsetfilter( { || draft_po->source = 'Bo' } ) )
       mfiltertext := 'Only PO BO Items Displayed'
      case mfiltchoice = 5
       draft_po->( dbsetfilter( { || draft_po->source = 'In' } ) )
       mfiltertext := 'Only Inv BO Items Displayed'
      endcase
      mfilter := ( mfiltchoice > 0 )
      Highlight( 1, 46, '', padr( mfiltertext, 33 ) )
      dpbrow:gotop()
      dpbrow:refreshall()

     case mkey == K_F4
      Rev_hold( FALSE, mby_supp )
      dpbrow:refreshcurrent()

     case mkey == K_F5 .and. msupp != '*' .and. mby_supp
      mscr := Box_Save( 3,3,6,77 )
      seek msupp
      Center( 4, 'Draft Purchase Order to => '+ trim( supplier->name ) , TRUE )
      lAnswer := NO
      @ 05,10 say 'Do you really wish to delete all of Draft PO' get lAnswer pict 'y'
      read
      Box_Restore( mscr )
      if lAnswer
       mscr:=Box_Save( 3,10,5,70 )
       while draft_po->supp_code = msupp .and. !draft_po->( eof() )
        @ 04,12 say space( 58 )
        @ 04,12 say 'Deleting Desc < ' + substr(master->desc,1,35) + ' >'
        Del_rec( 'draft_po', UNLOCK )
        skip alias draft_po
       enddo
       SysAudit( 'DraftPODEL' + msupp )
       Box_Restore( mscr )
       keyboard chr( K_ESC )  // Stuff keyboard to exit
      endif

     case mkey == K_F6 .and. mby_supp
      Supp_Swap( dpbrow, msupp )
      setkey(K_F6,nil)

     case mkey == K_F7 .and. msupp != '*' .and. mby_supp
      Skip_to( dpbrow, msupp )

     case mkey == K_F8
      Draft_val( msupp, mby_supp )

     case mkey == K_F9
      Hold_all( msupp, dpbrow, mby_supp )

     case mkey == K_F10
      Unhold_all( msupp, dpbrow, mby_supp )

     case mkey == K_F11
      Invert_Hold( msupp, dpbrow, mby_supp )

     case mkey == K_F1
      aHelpLines := { ;
                 { 'Enter', 'Edit Item' }, ;
                 { 'Esc', 'Escape from function' }, ;
                 { 'Del', 'Delete Item' }, ;
                 { 'F3', 'Filter Functions' }, ;
                 { 'F4', 'Hold/Release Item' } ;
                 }
      if msupp != '*'
       aadd( aHelpLines, { 'F5', 'Delete All' } )
       aadd( aHelpLines, { 'F6', 'Swap Supplier' } )
       aadd( aHelpLines, { 'F7', 'Skip to alt_desc' } )
       aadd( aHelpLines, { 'F8', 'Value Draft' } )
       aadd( aHelpLines, { 'F9', 'Hold all' } )
       aadd( aHelpLines, { 'F10', 'Unhold all' } )
       aadd( aHelpLines, { 'F11', 'Invert Holds' } )
       aadd( aHelpLines, { 'Ins', 'Add New Item' } )
       aadd( aHelpLines, { 'Alt-S', 'Check Stock in other Locs' } )
      endif
      Build_help( aHelpLines )

     case mkey == K_ENTER
      dpo_edit( dpbrow, msupp )
      dpbrow:refreshcurrent()
      dbunlockall()
      dpbrow:down()

     case mkey == K_INS
      while TRUE
       tsupp := draft_po->supp_code
       if msupp = '*'
        suppname := 'Any ' + if( mby_supp, 'Supplier', 'Department' )
       endif
       sID := space( ID_ENQ_LEN )
       mscr := Box_Save( 5, 08, 7, 72 )
       Heading( 'Add Items to order for ' + if( mby_supp, suppname, ' Dept ' + msupp ) )
       @ 6,10 say 'Code/id No to add to Order' get sID pict '@!'
       read
       Box_Restore( mscr )
       if !updated()
        exit
       else 
        gotchya := Codefind( sID )
        if !gotchya .and. !( substr( sID,1,1 ) $ "/.,';" )
         gotchya := add_item( sID, msupp )
        endif
        if gotchya
         lProceed := TRUE
         if msupp != master->supp_code
          if !IsReady( 12, 05, "Item Supplier does not match draft purchase order supplier - Proceed?" )
           lProceed := FALSE
          endif
         endif
         if lProceed
          select draft_po
          Add_rec()
          draft_po->date_ord := Bvars( B_DATE )
          draft_po->id := master->id
          draft_po->supp_code := if( msupp != '*', msupp, master->supp_code )
          draft_po->special := NO
          draft_po->source := 'Op'
          draft_po->skey := master->alt_desc
          draft_po->department := master->department
          draft_po->hold := Bvars( B_DEPTORDR )
#ifdef DPO_BY_DESC 
          draft_po->skey := master->desc
#endif
          dpo_edit( dpbrow, msupp )
         endif
        endif
       endif
      enddo
      select draft_po
      set relation to padr( draft_po->id, ID_ENQ_LEN ) into master,;
                   to draft_po->supp_code into supplier
      dpbrow:refreshall()

     case mkey == K_DEL
      mscr:=Box_Save( 15, 2, 17, 77 )
      @ 16,05 say 'About to delete อออฏ ' + left( master->desc, 45 )
      if Isready(18)
       Rec_lock( 'draft_po' )
       draft_po->qty := 0
      endif
      Box_Restore( mscr )

     case mkey == K_ALT_S
      Stockdisp( master->id )

     endcase

     if draft_po->qty = 0
      Del_Rec( 'draft_po', UNLOCK )
      eval( dpbrow:skipblock, -1 )
      dpbrow:refreshall()
     endif

    endif
   enddo
  else
   Error('Supplier Code not Found',12)
  endif
 endif
enddo
select draft_po
dbunlockall()
return

*

procedure dpoprint ( msupp )

local getlist:={}, farr

memvar msupptmp, mholds

Heading('Print Draft Purchase Orders')
Print_find("report")
select draft_po
msupp:=space( if( mby_supp, SUPP_CODE_LEN ,3) )
@ 06,30 say 'อออ>Enter '+if(mby_supp,'Supplier','Department')+' Code' ;
        get msupp pict '@K!'
read
msupptmp := msupp
if lastkey() != K_ESC
 ordsetfocus( if( mby_supp, 1, 4 ) )
 if msupp != '*'
  if !dbseek( msupp )
   Error('No Drafts found for this '+if(mby_supp,'supplier','department')+'!',12)
   return
  endif
 else
  dbgotop()
 endif
 mholds := Isready( 12, 30, 'Include Held Items' )
 if Isready(12)
  
 // // Pitch17()
  
  farr := {}
  aadd(farr,{'idcheck(id)','Item ID',13,0,FALSE})
  aadd(farr,{'space(1)','',1,0,FALSE})
  aadd(farr,{'master->catalog','Catalog',12,0,FALSE})
  aadd(farr,{'space(1)','',1,0,FALSE})
  aadd(farr,{'substr(master->alt_desc,1,10)','Alt_desc',10,0,FALSE})
  aadd(farr,{'substr(master->desc,1,20)','Description',20,0,FALSE})
  aadd(farr,{'master->department','Dept',4,0,FALSE})
  aadd(farr,{'qty','Qty to;Order',6,0,FALSE})
  aadd(farr,{'space(1)','',1,0,FALSE})
  aadd(farr,{'master->onhand','On;Hand',4,0,FALSE})
  aadd(farr,{'space(1)','',1,0,FALSE})
  aadd(farr,{'master->onorder','On Order;Quantity',8,0,FALSE})
  aadd(farr,{'space(1)','',1,0,FALSE})
  aadd(farr,{'master->cost_price','Last Inv;Cost',10,2,FALSE})
  aadd(farr,{'master->cost_price*qty','Inv Cost;Extended',9,2,TRUE})
  aadd(farr,{'space(1)','',1,0,FALSE})
  aadd(farr,{'master->lastpo','Last;PO',6,0,FALSE})
  aadd(farr,{'space(1)','',1,0,FALSE})
  aadd(farr,{'master->date_po','Last;Date',8,0,FALSE})
  aadd(farr,{'master->lastqty','Last;Qty',5,0,TRUE})
  
  if mby_supp
   Reporter(farr,;
            "'Draft Purchase Order Listing - Supplier Code '+msupptmp",;
            'supp_code',;
            'supp_code',;
            '',;
            '',;
            FALSE,;
            'if( mholds, .t., !draft_po->hold )',;
            'if( msupptmp = "*", .t., draft_po->supp_code = msupptmp )')

  else
   Reporter(farr,;
            "'Draft Purchase Order Listing - Department Code '+msupptmp",;
            'department',;
            'department',;
            '',;
            '',;
            FALSE,;
            'if( mholds, .t., !draft_po->hold )',;
            'if( msupptmp = "*", .t., draft_po->department = msupptmp )')

  endif

  Endprint()

 endif
endif
ordsetfocus( 1 )
return

*

procedure dporegen ( msupp )
local start_time:=seconds(),mqty,mscr,elapsed,getlist:={}
msupp:=space(if(mby_supp,4,3))
Heading('Regenerate Draft Purchase Orders')
@ 07,30 say 'อออ> Enter Supplier Code' get msupp pict '@K!';
        valid( if( mby_supp, msupp != 'MISC', TRUE ) )
read
if Isready(12)
 mscr:=Box_Save( 13, 10, 16, 70, C_MAUVE )
 Center(14,'Please Wait - now regenerating the Draft Purchase Orders')
 select draft_po
 if Netuse( "draft_po", EXCLUSIVE, 10, NOALIAS, OLD )
  ordsetfocus( if( mby_supp, 'supplier', 'department' ) )
  if msupp != '*'
   seek msupp
   delete for !draft_po->special while msupp = ;
          if( mby_supp, draft_po->supp_code, draft_po->department )

  else
   delete for !draft_po->special

  endif
  pack
  select master
  ordsetfocus( NATURAL )
  dbgotop()
  while !master->( eof() ) .and. Pinwheel()
   if ( msupp = '*' .and.  master->supp_code != 'MISC' );
     .or. ( mby_supp .and. master->supp_code = msupp );
     .or. ( Bvars( B_DEPTORDR ) .and. !mby_supp .and. master->department = msupp )

    if master->onhand < ( master->minstock - master->onorder )

     mqty := master->minstock - master->onhand - master->onorder
     Add_rec( 'draft_po' )
     draft_po->id := master->id
     draft_po->supp_code := master->supp_code
     draft_po->date_ord := Bvars( B_DATE )
     draft_po->qty := mqty
     draft_po->source := 'Re'
     draft_po->special := FALSE
     draft_po->skey := master->alt_desc
     draft_po->department := master->department
     draft_po->hold := Bvars( B_DEPTORDR )
#ifdef DPO_BY_DESC
     draft_po->skey := master->desc
#endif
     draft_po->( dbrunlock() )

    endif
   endif
   master->( dbskip() )
  enddo

  master->( ordsetfocus( BY_ID ) )
  select draft_po
 
  elapsed:=seconds()-start_time
  Center(15,"Time to prepare Draft "+Ns(elapsed/60,2)+" minutes "+ ;
      Ns(elapsed%60,2)+"  seconds ")
  Error("Regeneration finished ",18)
  SysAudit("ReGenDpo"+msupp)
  Box_Restore( mscr )
  syscolor( C_NORMAL )
 endif
 Netuse( "draft_po", SHARED, 10, NOALIAS, OLD )
 set relation to draft_po->id into master

endif
return

*

procedure all_dpo ( msupp )
local mrow:=7,mcol:=1,item_count,mspec:=TRUE,mscr:=Box_Save(3,20,6,60)
local mrec:=recno(),spec_found,getlist:={}
@ 04,22 say 'Total only Specials' get mspec pict 'y'
read
if mspec
 Center(5,'Reindexing - Please Wait')
 if mby_supp
  indx( "if(draft_po->special,'Y','N')+draft_po->supp_code", 'special' )
 else
  indx( "if(draft_po->special,'Y','N')+draft_po->department", 'special' )
 endif
endif
Box_Restore( mscr )
mscr:=Box_Save(06,00,24,79)
Heading( "Suppliers with " + if( mspec, "Outstanding Specials", "Outstanding Drafts" ) )
if mspec
 seek 'Y'
else
 go top
endif
while !eof() .and. inkey() = 0
 @ mrow,mcol say if( mby_supp,draft_po->supp_code,draft_po->department)
 msupp := if(mby_supp,draft_po->supp_code,draft_po->department)
 item_count := 1
 spec_found := NO
 while !eof() .and. if(mby_supp,draft_po->supp_code,draft_po->department) = msupp
  if !spec_found .and. draft_po->special
   spec_found := TRUE
  endif
  skip
  item_count++
 enddo
 if(spec_found,syscolor( C_INVERSE ),nil)
 @ mrow,mcol+04 say item_count-1 pict '999'
 if(spec_found,syscolor( C_NORMAL ),nil)
 mrow++
 if mrow = 24
  mrow := 07
  mcol += 08
  if mcol > 70
   Error("End of Page Reached")
   mcol := 01
  endif
 endif
enddo
Error("")
if mspec
 draft_po->( orddestroy( 'special' ) )
endif
if !mby_supp
 draft_po->( ordsetfocus( BY_DEPARTMENT ) )
endif
goto mrec
return

*

procedure edit_master
select master
itemdisp( TRUE )
if select( "draft_po" ) != 0
 select draft_po
else
 select returns
 if updated()
  returns->cost := master->cost_price
  returns->rrp := master->retail
 endif
endif
return

*

procedure rev_hold ( stuff_kbd )
Rec_lock()
if alias() = 'RETURNS'
 returns->hold := !returns->hold
elseif alias() = 'DRAFT_PO'
 draft_po->hold := !draft_po->hold
elseif alias() = 'BKLSid'
 bklsid->hold := !bklsid->hold
endif
if stuff_kbd 
 keyboard chr( K_PGDN )
endif
return

*

function dpo_edit ( dpbrow, msupp )
local getlist:={},sFunKey3,sFunKey4,oKF5,oKF6,oKF7,oKF8,oKF9,oKF10,oks,nrec,mrec
local mscr:=Box_Save(0,0,24,79),mcomments,mminstock,mstatus

sFunKey3 := setkey( K_F3, { || Enq_Sales() } )
okf5 := setkey( K_F4, { || Rev_hold( TRUE ) } )
sFunKey4 := setkey( K_F5, { || Enq_hist() } )
okf6 := setkey( K_F6, { || Supp_swap( dpbrow, msupp ) } )
okf7 := setkey( K_F7, { || Enq_appr() } )
okf8 := setkey( K_F8, { || Enq_spec() } )
okf9 := setkey( K_F9, { || Enq_po() } )
okf10 := setkey( K_F10, { || itemdisp( FALSE ) } )
oks := setkey( K_ALT_S, { || Stockdisp() } )

cls

if msupp != '*'
 Heading( 'Desc on Draft for ' + trim(supplier->name) )
else
 Heading( 'Edit Draft Purchase Order' )
endif
Highlight( 02, 08, 'Item ID', idcheck( master->id ) )
Highlight( 03, 11, 'Desc', master->desc )
Highlight( 04, 15 - Len( ALT_DESC), ALT_DESC, master->alt_desc )
Highlight( 05, 15 - Len( BRAND_DESC) , BRAND_DESC, LookItup( "brand" , master->brand ) )
Highlight( 07, 05, 'Supplier 1', master->supp_code )
Highlight( 08, 05, 'Supplier 2', master->supp_code2 )
Highlight( 09, 05, 'Supplier 3', master->supp_code3 )
Highlight( 07, 00, '','<F6>')
Highlight( 10, 00, '','<F3>')
Highlight( 10, 06, 'Last Sold', dtoc(master->dsale) )
Highlight( 11, 03, 'Last Ordered', dtoc(master->date_po) )
Highlight( 13, 03, 'Order Source', OrdSource())
Highlight( 14, 05, 'Sell Price', Ns(master->sell_price) )
Highlight( 15, 05, 'Cost Price', Ns(master->cost_price) )
Highlight( 16, 06, 'Qty Avail', Ns( MASTAVAIL, 5 ) )
Highlight( 08, 21, 'Department', master->department)
Highlight( 09, 24, 'Binding', master->binding)
Highlight( 10, 27, 'Year', master->year)
Highlight( 14, 30, '<F7> On Approval', Ns( master->approval, 5 ) )
Highlight( 15, 30, '<F9>    On Order', Ns( master->onorder, 5) )
Highlight( 16, 30, '<F8>  On Special', Ns( master->special, 5) )
@ 17,06 say 'Order Qty' get draft_po->qty pict '99999'
if draft_po->special
 Highlight( 17,22,'', '<อออ Special Order' )

endif

mrec := master->( recno() )
mminstock := master->minstock
mcomments := master->comments
mstatus := master->status
@ 17, 56 say 'Minimum Stock' get mminstock
@ 18, 00 say '<F10>Master Com' get mcomments
@ 18, 60 say '<F4> Hold' get draft_po->hold pict 'Y'
@ 06, 51 say '<F5> Receiving History'
@ 19, 04 say 'PO Comments' get draft_po->comment pict '@S40'
@ 19, 63 say 'Status' get mstatus valid( dup_chk( mstatus, 'status' ) )
Salesdisp()
Stkhistdisp()
Rec_lock( 'draft_po' )
read
draft_po->( dbrunlock() )

nrec := master->( recno() )
master->( dbgoto( mrec ) )
Rec_lock( 'master' )
master->comments := mcomments
master->minstock := mminstock
master->status := mstatus
master->( dbrunlock() )
master->( dbgoto( nrec ) )
select draft_po
setkey( K_F3, sFunKey3 )
setkey( K_F4, sFunKey4 )
setkey( K_F5, okf5 )
setkey( K_F6, okf6 )
setkey( K_F7, okf7 )
setkey( K_F8, okf8 )
setkey( K_F9, okf9 )
setkey( K_F10, okf10 )
setkey( K_ALT_S, oks )
Box_Restore( mscr )
return updated()

*

function OrdSource
local mret
do case
case field->Source = 'Op'
 mret := "Operator"
case field->Source = 'Bo'
 mret := "Back Orders"
case field->Source = 'Sp'
 mret := "Special Orders"
case field->Source = 'Re'
 mret := "Regenerate"
case field->Source = 'Sa'
 mret := "Sales (Min Stock)"
case field->source = 'In'
 mret := "Invoicing (Bo)"
case field->source = 'Tr'
 mret := "Supplier Transfer"
case field->source = 'St'
 mret := "Stock Transfer"
otherwise
 mret := "Unknown (" + field->Source + ")"
endcase
return mret

*

proc draft_val ( msupp )
local mrec:=recno(),mmin,cost_tot,sell_tot,mqty,mscr
if mby_supp == nil
 mby_supp := TRUE
endif
if msupp != '*'
 Heading('Calculate Draft Order Value')
 mscr:=Box_Save(4,20,6,60)
 Center(5,'Calculating - Please wait')
 seek msupp
 mmin := supplier->min_ord
 if select("draft_po") != 0
  sum master->cost_price*draft_po->qty,master->sell_price*draft_po->qty,draft_po->qty to ;
      cost_tot,sell_tot,mqty for !draft_po->hold ;
      while if( mby_supp, draft_po->supp_code, draft_po->department ) = msupp
 else
  sum returns->cost*returns->qty,returns->sell*returns->qty,returns->qty to ;
      cost_tot,sell_tot,mqty for !returns->hold while returns->supp_code = msupp
 endif
 Box_Restore( mscr )
 Heading( 'Total Order Value' )
 mscr := Box_Save( 4, 08, 14, 72 )
 if mby_supp
  Highlight( 05, 10, '         Totals for => ', Lookitup( "supplier", msupp ) )
  if !empty(supplier->std_disc).and.empty(cost_tot)
   Highlight( 07, 60, '', '<' + Ns( sell_tot- (sell_tot* (supplier->std_disc/100)),9,2)+'>' )
  endif
 endif
 Highlight( 07, 10, '      Value at Cost =>$', Ns( cost_tot,8,2 ) )
 Highlight( 09, 10, '      Value at sell =>$', Ns( sell_tot,8,2 ) )
 Highlight( 11, 10, 'Minimum order value =>$', Ns( mmin,8,2 ) )
 Highlight( 13, 10, '        Total Items => ', Ns( mqty ) )
 Error( '', 15 )
 goto mrec
 Box_Restore( mscr )
endif
return

*

procedure supp_swap ( dpbrow, msupp )
local getlist:={}, supsel, newsupp:=space( SUPP_CODE_LEN ), f_arr, x
local mscr:=Box_Save(2,53,7,73), mchoices:={}
local mfirst:={ master->supp_code, master->supp_code2, master->supp_code3 }

setkey( K_F6, nil )
for x := 1 to 3              // Copy array for !empty suppliers
 if( !empty( mfirst[x] ) , aadd( mchoices, mfirst[x] ), nil )
next
aadd( mchoices,'Pick your Own' )
supsel := achoice( 3,54,6,72,mchoices )
if supsel != 0
 if mchoices[ supsel ]  = 'Pick your Own'
  @ 6,54 say 'Supplier Code' get newsupp pict '@!';
        valid( Dup_chk( newsupp,"supplier") .and. !empty( newsupp ) )
  read
 else
  newsupp := mchoices[ supsel ]
 endif
 if !empty( newsupp )
  f_arr := {}                // An array to save field values in
  for x := 1 to fcount()
   aadd( f_arr, draft_po->( fieldget( x ) ) )
  next
  Rec_lock( 'draft_po' )
  draft_po->( dbdelete() )   // Kill Old Record
  draft_po->( dbrunlock() )   // Added by DAC
  Add_rec( 'draft_po' )      // New dpo record
  for x := 1 to len( f_arr )
   draft_po->( fieldput( x , f_arr[ x ] ) )   // Append field data
  next
  draft_po->supp_code := newsupp   // New supplier code on dpo
  draft_po->source := 'Tr'
  draft_po->( dbseek( msupp ) )
  draft_po->( dbrunlock() )   // Added by DAC
  Rec_lock( 'draft_po' )
  if dpbrow != nil
   dpbrow:refreshall()

  endif

 endif

endif
Box_Restore( mscr )
setkey( K_F6, { || Supp_swap( dpbrow, msupp ) } )
return

*

procedure skip_to ( dpbrow, msupp )
local mlet:=' ',getlist:={},mscr,mrec:=recno()
if msupp != '*'
 mscr:=Box_Save(16,20,18,60)
 if alias() = 'DRAFT_PO'
  @ 17,22 say 'First Letter of alt_desc' get mlet pict '!'
 else
  @ 17,22 say 'First Letter of Department' get mlet pict '!'
 endif
 read
 if updated()
  draft_po->( dbseek( msupp+mlet, TRUE ) ) // a softseek
  if draft_po->supp_code != msupp
   goto mrec
  endif
 endif
 Box_Restore( mscr )
 dpbrow:refreshall()
endif
return

*

procedure salesdisp
if ytdsales->(dbseek(master->id))
 @ 20,03 say 'Jan   Feb   Mar   Apr   May   Jun   Jul   Aug   Sep   Oct   Nov'
 @ 20,69 say 'Dec   Tot'
 syscolor( C_BRIGHT )
 @ 21,02 say ytdsales->jan
 @ 21,08 say ytdsales->feb
 @ 21,14 say ytdsales->mar
 @ 21,20 say ytdsales->apr
 @ 21,26 say ytdsales->may
 @ 21,32 say ytdsales->jun
 @ 21,38 say ytdsales->jul
 @ 21,44 say ytdsales->aug
 @ 21,50 say ytdsales->sep
 @ 21,56 say ytdsales->oct
 @ 21,62 say ytdsales->nov
 @ 21,68 say ytdsales->dec
 @ 21,74 say ytdsales->jan+ytdsales->feb+ytdsales->mar+ytdsales->apr+;
             ytdsales->may+ytdsales->jun+ytdsales->jul+ytdsales->aug+;
             ytdsales->sep+ytdsales->oct+ytdsales->nov+ytdsales->dec ;
             pict '9999'

 syscolor( C_NORMAL )
 Center( 22,'Sales Period is '+Ns(Bvars( B_PERLEN ) ) + ' days - Last Period Close was ' + ;
        dtoc( Bvars( B_LASTPER ) ) )
 syscolor( C_INVERSE )
 @ 23,02 say ytdsales->per1
 syscolor( C_BRIGHT )
 @ 23,08 say ytdsales->per2
 @ 23,14 say ytdsales->per3
 @ 23,20 say ytdsales->per4
 @ 23,26 say ytdsales->per5
 @ 23,32 say ytdsales->per6
 @ 23,38 say ytdsales->per7
 @ 23,44 say ytdsales->per8
 @ 23,50 say ytdsales->per9
 @ 23,56 say ytdsales->per10
 @ 23,62 say ytdsales->per11
 @ 23,68 say ytdsales->per12
 @ 23,74 say ytdsales->per1+ytdsales->per2+ytdsales->per3+ytdsales->per4+;
             ytdsales->per5+ytdsales->per6+ytdsales->per7+ytdsales->per8+;
             ytdsales->per9+ytdsales->per10+ytdsales->per11+ytdsales->per12 ;
             pict '9999'
 syscolor( C_NORMAL )
else
 Center(21,'-=< No Sales History on file >=-')
endif
return

*

procedure hold_all ( msupp, dpbrow )
local mscr
default mby_supp to TRUE
if msupp = '*'
 Error( "No hold all for supplier = '*'",12 )
else
 if Isready( 12, 10, 'Hold all for ' + msupp )
  mscr:=Box_Save(2,10,4,70)
  Center( 3, 'Holding all '+trim(supplier->name)+' - Please Wait')
  draft_po->( dbseek( msupp ) )
  while !draft_po->( eof() ) .and. if( mby_supp,draft_po->supp_code,draft_po->department ) = msupp
   Rec_lock( 'draft_po' )
   draft_po->hold := YES
   draft_po->( dbrunlock() )
   draft_po->( dbskip() )
  enddo
  Box_Restore( mscr )
  draft_po->( dbseek( msupp ) )
  dpbrow:refreshall()
 endif
endif
return

*

procedure unhold_all ( msupp, dpbrow )
local mscr, getlist := {}
default mby_supp to TRUE
if msupp = '*'
 Error( "No unhold all for supplier = '*'",12 )
else
 mscr := Box_Save(2,10,4,70)
 Center(3,'Releasing '+trim(supplier->name)+' - Please Wait')
 seek msupp
 while !eof() .and. if( mby_supp,draft_po->supp_code,draft_po->department ) = msupp
  Rec_lock( 'draft_po' )
  draft_po->hold := FALSE
  draft_po->( dbrunlock() )
  dbskip()

 enddo
 seek msupp
 Box_Restore( mscr )
 dpbrow:refreshall()
endif
return

*

procedure Invert_Hold( msupp, dpbrow )
local mscr, getlist := {}
default mby_supp to TRUE
if msupp = '*'
 Error( "No Inverting holds for supplier = '*'",12 )
else
 if Isready( 12, 10, 'Invert holds for ' + msupp )
  mscr := Box_Save(2,10,4,70)
  Center(3,'Inverting '+trim(supplier->name)+' - Please Wait')
  draft_po->( dbseek( msupp ) )
  while !draft_po->( eof() ) .and. if( mby_supp,draft_po->supp_code,draft_po->department ) = msupp
   Rec_lock( 'draft_po' )
   draft_po->hold := !(draft_po->hold)
   draft_po->( dbrunlock() )

   draft_po->( dbskip() )

  enddo
  draft_po->( dbseek( msupp ) )
  Box_Restore( mscr )
  dpbrow:refreshall()
 endif
endif
return

*

func dpodispmode ( msupp )
local tscr := Box_Save( 5,0,7,15 )
@ 5,1 say '<F4 to change>'
@ 6,1 say if( mby_supp, 'By Supplier', 'By Department' )
msupp := if( mby_supp, padr( msupp, SUPP_CODE_LEN ), '   ' )
return tscr

*
func dpomodechg ( msupp ) 
mby_supp := !mby_supp
Dpodispmode( @msupp )
return nil

*

func StkhistDisp()
local x
if select( "stkhist" ) = 0
 if !netuse( "stkhist" )
  return nil
 endif
endif
if !stkhist->( dbseek( master->id ) )
 Highlight( 06,50,'','*** No receiving history *** ' )
else
 Box_Save( 6,43,12,79 )
 @ 6,50 say '[ Receiving History ]'
 for x := 1 to 5
  @ 6+x, 44 say stkhist->date
  @ 6+x, 54 say stkhist->reference
  @ 6+x, 65 say stkhist->qty pict '9999'
  @ 6+x, 70 say substr( histtype( stkhist->type ) , 1 , 8 )
  stkhist->( dbskip() )
  if stkhist->id != master->id .or. stkhist->(eof())
   exit
  endif
 next
endif
return nil
