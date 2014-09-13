
/*

 Kit Processing


 Last change: APG 16/07/2008 7:56:01 PM

      Last change:  TG   15 May 2010   10:32 am
*/

#include "bpos.ch"

Procedure p_kits

local mgo := NO,choice,msupp:=space(4),mscr,kit_name,max_kits,kit_cost,kit_tax
local oldscr := Box_Save(), kit_price, kitbrow, mqty, aArray
local change_flag, lAppend, kit_id, mkits, getlist:={}, sID, mkey, mrec

if Netuse( "draft_po" )
 if Netuse( "stkhist" )
  if master_use()
   if Netuse( "kit" )
    set relation to kit->id into master
    mgo := YES
   endif
  endif
 endif
endif

kit_id := space(12)
*
while mgo
 Box_Restore( oldscr )
 Heading('Kit Processing Menu')

 aArray := {}
 aadd( aArray, { 'Exit', 'Return to Purchasing Menu' } )
 aadd( aArray, { 'Create/Edit', 'Create and Edit Kit Lists' } )
 aadd( aArray, { 'Assemble', 'Produce a Kit for Sale' } )
 aadd( aArray, { 'Disassemble', 'Restore Component Items' } )
 aadd( aArray, { 'Reports', 'Reports on Kits' } )
 choice := MenuGen( aArray, 08, 18, 'Kits')

 do case
 case choice < 2
  mgo := NO
 case choice = 2
  Heading('Create/Edit Kit Lists')
  change_flag := YES
  @ 10,31 say 'ออ>Enter Kit #' get kit_id pict '@!K'
  read
  if lastkey() != K_ESC
   lAppend := NO
   if !kit->( dbseek( kit_id ) )
    if Codefind(kit_id)
     Box_Save( 02, 08, 04, 72 )
     Highlight( 03, 10, 'Desc ', trim( master->desc ) )
     Error( 'ID in use on master file - Cannot use for Kit', 12 )
     loop
    endif
    mscr := Box_Save( 11, 10, 13, 70 )
    lAppend := NO
    @ 12,12 say 'Kit ' + trim(kit_id) + ' not found - create a new one ?';
            get lAppend pict 'Y'
    read
    Box_Restore( mscr )
    if !lAppend
     loop
    else
     select master
     Add_rec()
     master->id := kit_id
     master->department := 'KIT'
     master->supp_code := '^KIT'
     master->minstock := 0
     master->binding := 'KI'
     itemdisp( YES )
     dbrunlock()
     keyboard chr( K_INS )
    endif
   else
    change_flag := !( master->( dbseek( kit->id ) ) .and. master->onhand > 0 )
   endif
   cls
   select kit
   Heading( 'Edit Kit # ' + trim( kit_id ) )
   Highlight( 02, 1, 'Kits Onhand',Ns( master->onhand ) )
   Highlight( 02, 20, '', if( !change_flag, 'Kit has Stock attached - No Editing allowed', '' ) )
   Highlight( 03, 1, 'Kit Desc',substr( master->desc, 1, 40 ) )
   kitbrow:=Tbrowsedb(05, 0, 23, 79)
   kitbrow:HeadSep:=HEADSEP
   kitbrow:ColSep:=COLSEP
   kitbrow:goTopBlock:={ || dbseek( kit_id ) }
   kitbrow:goBottomBlock:={ || jumptobott( kit_id ) }
   kitbrow:skipBlock:=Keyskipblock( { || kit->id }, kit_id, YES ) 
   kitbrow:AddColumn(TBColumnNew('Code',{ || idcheck( master->id ) } ) )
   kitbrow:AddColumn(TBColumnNew('Desc',{ || substr( master->desc, 1, 40 ) } ) )
   kitbrow:Addcolumn(TBColumnNew('Qty',{ || transform( kit->qty,'9999' ) } ) )
   kitbrow:AddColumn(TBColumnNew('Avail',{ || transform( MASTAVAIL, '999' ) } ) )
   kitbrow:AddColumn(TBColumnNew('Price',{ || transform( master->sell_price, '9999.99' ) } ) )
   kitbrow:freeze:=1
   kitbrow:goTop()
   mkey:=0
   while mkey != K_ESC .and. mkey != K_END
    while !kitbrow:stabilize() .and. ( mkey := inkey() ) == 0
    enddo
    if kitbrow:stable
     mkey:=inkey(0)
    endif
    if !Navigate( kitbrow,mkey ) .and. change_flag
     do case
     case mkey == K_F8
      mrec := recno()
      kit_price := 0
      kit_cost := 0
      select kit
      seek kit_id
      while kit->id = kit_id .and. !kit->( eof() )
       kit_price += master->sell_price * kit->qty

       kit_cost += master->cost_price * kit->qty
       kit->( dbskip() )

      enddo
      Highlight( 02, 60, 'Kit Cost', Ns( kit_cost, 8, 2 ) )
      Highlight( 03, 60, 'Kit Sell', Ns( kit_price, 8, 2 ) )
      goto mrec
     case mkey == K_F10
      itemdisp( FALSE )
      kitbrow:refreshcurrent()

     case mkey == K_DEL
      if Isready( 6, 12, 'Ok to delete desc "' + trim( substr( master->desc, 1, 20 ) );
                 + '" from kit' )
         Del_rec( 'kit', UNLOCK )
       eval( kitbrow:skipblock , -1 )
       kitbrow:refreshall()
      endif

     case mkey == K_INS
      mscr := Box_Save( 2, 10, 4, 40 )
      sID := space( 12 )
      @ 3,12 say 'Code/id' get sID pict '@!'
      read
      Box_Restore( mscr )
      if !codefind( sID )
       select kit
       Error('id not on File',12)
      else
       select kit
       mscr:= Box_Save( 6,10,9,70 )
       mqty := 0
       Highlight( 7,12,'Desc',substr(master->desc,1,35) )
       @ 7,65 say master->onhand pict '9999'
       @ 8,12 say 'Kit Qty' get mqty pict '999'
       read
       Box_Restore( mscr )
       if mqty > 0
        Add_rec()
        replace id with kit_id,;
                id with master->id,;
                qty with mqty
        dbrunlock()
       endif
       seek kit_id
       kitbrow:refreshall()
      endif
     case mkey == K_ENTER
      mscr:= Box_Save( 6,10,9,70 )
      mqty := kit->qty
      Highlight( 7, 12, 'Desc', substr( master->desc, 1, 35 ) )
      @ 7,65 say master->onhand pict '9999'
      @ 8,12 say 'Kit Qty ' get mqty pict '999'
      read
      Box_Restore( mscr )
      kitbrow:refreshall()
     endcase
    endif
   enddo
   if !kit->( dbseek( kit_id ) ) .and. !lAppend
    Error( "No items on kit file - About to Delete Kit Record?", 12 )
    if Isready( 16 )
     if Codefind( kit_id )
      Del_rec( 'master', UNLOCK )
      exit
     endif
    endif
   endif
  endif
 case choice = 3
  Heading("Assemble Kits from Components")
  @ 11,31 say 'Enter Kit #ออ>' get kit_id PICT '@!K'
  read
  if lastkey() != K_ESC
   if !kit->( dbseek( kit_id ) ) 
    Error( "Kit not on Kit Master File", 12 )
   else
    if !Codefind( kit_id )
     Error( "Kit ID not on Desc file", 12 )
    else
     kit_name := trim( master->desc )
     max_kits := 999999
     kit_price := 0
     kit_cost := 0
     kit_tax := 0
     kit->( dbseek( kit_id ) )
     while kit->id = kit_id .and. !kit->( eof() )
      max_kits := min( max_kits, int( MASTAVAIL / kit->qty ) )
      kit_price += master->sell_price * kit->qty
      kit_cost += master->cost_price * kit->qty
      skip alias kit
     enddo
     if max_kits <= 0
      Error( "Insufficent Stock to assemble kit", 12 )
     else
      mkits := 0
      Box_Save(02,08,10,72)
      @ 3,10 say "You May Assemble " + Ns(max_kits) + ' ' + kit_name + '(s)'
      Highlight(4,50,'Kit price ',Ns(kit_price,7,2))
      @ 5,10 say 'Number of Kits to Assemble' get mkits pict '999';
             valid( mkits <= max_kits )
      read
      if updated()

       if Isready(7)

        kit->( dbseek(  kit_id ) )

        while kit->id = kit_id .and. !kit->( eof() )

         Rec_lock('master')
         Update_oh( -( master->onhand - mkits ) )
         master->( dbrunlock() )

         Add_rec( 'stkhist' )    // Update Stock History file //
         stkhist->id := master->id
         stkhist->reference := kit_id
         stkhist->date := Bvars( B_DATE )
         stkhist->qty := -( kit->qty * mkits )
         stkhist->type := 'K'
         stkhist->( dbrunlock() )

         skip alias kit
        enddo

        master->( dbseek( kit_id ) )
        Rec_lock('master')
        Update_oh( mkits ) 
//      master->onhand := master->onhand + mkits
        master->cost_price := kit_cost
        master->sell_price := kit_price
        master->( dbrunlock() )
        Add_rec( 'stkhist' ) // Update Stock History file //
        stkhist->id := master->id
        stkhist->reference := kit_id
        stkhist->date := Bvars( B_DATE )
        stkhist->qty := mkits
        stkhist->type := 'K'
        stkhist->( dbrunlock() )
        
        Error( Ns( mkits ) + ' ' + kit_name + ' Built', 12 )

       endif

      endif
     endif
    endif
   endif
  endif
 case choice = 4
  Heading( "Disassemble Kits" )
  @ 12,31 say 'ออ>Enter Kit #' get kit_id pict '@!K'
  read
  if lastkey() != K_ESC
   if !kit->( dbseek( kit_id ) )
    Error("Kit ID not on Kit Master File",12)
   else
    if !Codefind( kit_id )
     Error("Kit ID not on Desc file",12)
    else
     max_kits := master->onhand
     Box_Save( 3, 08, 6, 72 )
     Center( 4, 'You may dissassemble ' + Ns( max_kits ) + ' Kit(s)' )
     mkits := 0
     @ 5,10 say 'Number of Kits to Disassemble' get mkits ;
            valid ( mkits > -1 .and. mkits <= max_kits )
     read
     if updated()
      if Isready(12)
       select kit
       while kit->id = kit_id .and. !kit->( eof() )

        if Codefind( kit->id )

         Rec_lock( 'master' )
         Update_oh( kit->qty * mkits )
         master->( dbrunlock() )

         Add_rec( 'stkhist' )       // Update Stock History file //
         stkhist->id := master->id
         stkhist->reference := kit_id
         stkhist->date := Bvars( B_DATE )
         stkhist->qty := kit->qty*mkits
         stkhist->type := 'K'
         stkhist->( dbrunlock() )

        endif

        skip alias kit
       enddo

       if Codefind( kit_id )

        Rec_lock( 'master' )
        Update_oh( -mkits )
        master->( dbrunlock() )

        Add_rec( 'stkhist' )         // Update Stock History file //
        stkhist->id := master->id 
        stkhist->reference := lvars( L_REGISTER )
        stkhist->date := Bvars( B_DATE )
        stkhist->qty := -mkits
        stkhist->type :='K'
        stkhist->( dbrunlock() )
        
       endif
      endif
     endif
    endif
   endif
  endif
 endcase
enddo
close databases
return
