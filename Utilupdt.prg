/** @package 

        Utilupdt.prg
        
        Copyright(c) DEPT OF FOREIGN AFFAIRS TRADE 2000
        
        Author: DEPT OF FOREIGN AFFAIRS TRADE
        Created: DOF 14/07/2008 10:16:53 PM
      Last change:  TG   16 Jan 2011    6:40 pm
*/
Procedure U_Update

#include "bpos.ch"

local mgo:=FALSE, oldscr:=Bsave(), mupdate, mdate, aArray
local choice,mapp,last_id,tchoice,msum,x,mloc,stkfile,mscr,mfile,mdrive
local getlist:={}, mrecs, mord, mstr, mres, strpos, farr:={}
local updtbrow, hitkey, tscr

Center( 24, 'Opening Files For Database Update' )

if Netuse( "stock", EXCLUSIVE )
 if Netuse( "branch" ) 
  mgo := Master_use()
 endif
endif

Line_clear(24)

while mgo
 Brest( oldscr )
 Heading( 'Update Maintenance Menu' )
 aArray := {}
 aadd( aArray, { 'Utility', 'Return to Utility Menu' } )
 aadd( aArray, { 'Descs', 'Create/Retrieve Desc Update' } )
 aadd( aArray, { 'Stock', 'Create/Retrieve Stock Updates' } )
#ifdef COOP
 aadd( aArray, { 'Prices', 'Check Price Changes from Head Office' } )
#endif
 choice := MenuGen( aArray, 10, 50, 'Update')
 do case
 case choice < 2
  mgo := FALSE
 case choice = 2
  aArray := {}
  aadd( aArray, { 'Update', 'Return to Update Menu' } )
  aadd( aArray, { 'Create', 'Create Update File for Remote' } )
  aadd( aArray, { 'Retrieve', 'Add Descs from Update Diskette' } )
  aadd( aArray, { 'Report', 'Print Desc Update File Report' } )
  tchoice := MenuGen( aArray, 12, 51, 'Descs')
  do case
  case tchoice = 2
   Heading('Create Update Diskette for Remote')
   select master
   Heading("Select Drive to write update to")
   mscr := Bsave( 9, 10, 13, 60 )
   @ 10,11 prompt 'A:'
   @ 11,11 prompt 'B:'
#ifndef __HARBOUR__
   @ 12,11 prompt chr(getdriv())+':'
#endif
   @ 11,16 say '<ออ Select Drive to write update files to'
   menu to mdrive
   Brest( mscr )
   mdate := dtoc( Bvars( B_DATE ) )
   do case
   case mdrive = 1
    mupdate := ( 'a:'+Bvars( B_BRANCH )+substr(mdate,1,2)+substr(mdate,4,2)+'.ti' )
   case mdrive = 2
    mupdate := ( 'b:'+Bvars( B_BRANCH )+substr(mdate,1,2)+substr(mdate,4,2)+'.ti' )
   case mdrive = 3
    mupdate := ( Oddvars( SYSPATH ) + 'bisac\'+Bvars( B_BRANCH )+substr(mdate,1,2)+substr(mdate,4,2)+'.ti' )
   endcase
   last_id := Sysinc("last_up_rec","G")
   if empty( last_id )
    if lastrec() > 501
     goto lastrec() - 500
    else
     go top
    endif
   else
    seek last_id
   endif
   ordsetfocus(  )
   Bsave(4,10,7,70,8)
   mrecs := lastrec() - recno()
   @ 5, 12 say SYS_TYPE + ' will upload ' +Ns( mrecs )+' records ' get mrecs pict '999999';
           valid( if( mdrive < 3 ,mrecs < 5001, TRUE ) )
   read
   goto lastrec() - mrecs
   if !empty( mupdate )
    if mdrive < 3
     mscr := Bsave( 5, 10, 9, 70 )
     Center( 6, 'Insert Update Diskette into drive ' + if( mdrive=1, 'A:', 'B:' ) )
    endif
    if Isready( 8 )

     Center( 6, 'Copying Update records to file ' + mupdate )
     copy rest to ( Oddvars( TEMPFILE2 ) ) fields id, desc, alt_desc, brand, supp_code, ;
          supp_code2, supp_code3 ,cost_price, sell_price, retail, department, ;
         edition, status, binding, year, comments, sale_ret while Pinwheel()

     Shell( 'copy ' + Oddvars( TEMPFILE2 ) + '.dbf ' + mupdate )   // (*&*)

     master->( dbgobottom() )

     Sysinc("last_up_rec","R",master->id)

    endif
    syscolor( C_NORMAL )
    ordsetfocus( 1 )
   endif
  case tchoice = 3
   Heading('Update Master File from Remote')
   stkfile := trim( getfile( "*.ti" ) )
   Bsave(2,10,4,70)
   Center(3,'Insert Update Diskette into drive A:')
   if Isready(6)
    if !file( stkfile )
     Error( "No update database found on A: drive" , 12 )
    else

     Kill( Oddvars( TEMPFILE2 ) )
     Shell( 'copy ' + stkfile + ' ' + Oddvars( TEMPFILE2 ) + '.dbf' )  // (*&*)

     if Netuse( Oddvars( TEMPFILE2 ), SHARED, 10, "update", NEW )

      Bsave( 2, 10, 5, 70 )
      @ 3,12 say 'Number of Records in Update ' + Ns( reccount() )
      @ 3,52 say 'Appended '
      mapp := 0
      while !update->( eof() ) .and. Pinwheel()

       if !master->( dbseek( update->id ) )

        Add_rec( 'master' )
        master->id := update->id
        master->desc := update->desc
        master->alt_desc := update->alt_desc
        master->brand := update->brand
        master->department := update->department
        master->retail := update->retail
        master->cost_price := update->cost_price
        master->sell_price := update->sell_price
        master->year := update->year
        master->sale_ret := update->sale_ret
        master->supp_code := update->supp_code
        master->supp_code2 := update->supp_code2
        master->supp_code3 := update->supp_code3
        master->binding := update->binding
        master->comments := update->comments
        master->entered := Bvars( B_DATE )
        Highlight( 4, 12, 'Desc', left( master->desc, 40 ) ) // (*&*)

        master->( dbrunlock() )
        mapp++
        @ 3,62 say Ns(mapp)
       endif
       update->( dbskip() )
      enddo
     endif
     update->( dbclosearea() )
    endif
   endif
  case tchoice = 4
   stkfile := trim( getfile( "*.ti" ) )
   if file(stkfile) 
    if IsReady(12) 
     if Netuse( stkfile, EXCLUSIVE, 10, 'tupdate', NEW )
      tupdate -> (dbgotop())
      Print_find("report")
      PrintCheck()
      Pitch17()
      aadd( farr, { 'id','id',13,0,FALSE} ) 
      aadd( farr, { 'substr(desc,1,35)','Desc',35,0,FALSE} ) 
      aadd( farr, { 'substr(alt_desc,1,20)','Author',20,0,FALSE} )
      aadd( farr, { 'substr(lookitup("brand",field->brand),1,12)','Imprint',12,0,FALSE}) 
      aadd( farr, { 'supp_code','Prim;Supp',4,0,FALSE} ) 
      aadd( farr, { 'department','Dept',4,0,FALSE} ) 
      aadd( farr, { 'binding','Binding',4,0,FALSE} )
      aadd( farr, { 'cost_price','Invoice;Cost',7,2,FALSE} )
      aadd( farr, { 'sell_price','Sell;Price',7,2,FALSE} )
      aadd( farr, { 'retail','Retail;Price',7,2,FALSE} )
      Reporter(farr,'"Update Descs File Listing"')
      Pitch10()
      endprint()
      tupdate->( dbclosearea() )
     endif
    endif
   endif
  endcase

 case choice = 3
  aArray := {}
  aadd( aArray, { 'Update   ', 'Return to Update Menu' } )
  aadd( aArray, { ' Create  ', 'Create Stock Update File' } )
  aadd( aArray, { ' Retrieve', 'Retrieve Stock Update File' } )
  aadd( aArray, { ' Purge   ', 'Delete dead Stock Items' } )
  tchoice := MenuGen( aArray, 13, 51, 'Stock')
  do case
  case tchoice = 2
   if empty( Bvars( B_BRANCH ) )
    Error( 'You must set up a store code in Utilities/Details', 12)
   else
    Heading('Create Stock Update Diskette')
    mupdate := ''
    mdate := dtoc( Bvars( B_DATE ) )
    Heading("Select Drive to write update to")
    mscr := Bsave( 9, 10, 13, 60 )
    @ 10,11 prompt 'A:'
    @ 11,11 prompt 'B:'

#ifndef __HARBOUR__
    @ 12,11 prompt chr(getdriv())+':'
#endif
    @ 11,16 say '<ออ Select Drive to write update files to'
    menu to mdrive
    Brest( mscr )
    do case
    case mdrive = 1
     mupdate := ( 'a:'+Bvars( B_BRANCH )+substr(mdate,1,2)+substr(mdate,4,2)+'.stk' )
    case mdrive = 2
     mupdate := ( 'b:'+Bvars( B_BRANCH )+substr(mdate,1,2)+substr(mdate,4,2)+'.stk' )
    case mdrive = 3
     mupdate := ( Oddvars( SYSPATH ) + 'bisac\'+Bvars( B_BRANCH )+substr(mdate,1,2)+substr(mdate,4,2)+'.stk' )
    endcase
    if !empty( mupdate )
     if mdrive < 3
      mscr := Bsave( 5, 10, 9, 70 )
      Center( 6, 'Insert Update Diskette into drive ' + if( mdrive=1, 'A:', 'B:' ) )
     endif
     if Isready( 12 )
      if mdrive < 3 .and. !drivetest( if( mdrive=1, 'A:', 'B:' ) )
       loop
      else

       mfile := Oddvars( SYSPATH ) + Oddvars( TEMPFILE )
       mscr := Bsave( 5, 10, 9, 70 )

       Center( 7, 'Creating Stock Update file')
       
       select master
       ordsetfocus( NATURAL )
       master->( dbgotop() )
       
       copy to ( mfile ) fields id, onhand, onorder, special ;
               for master->onhand > 0 .or. master->onorder > 0 .or. master->special > 0;
               while Pinwheel()

       Center( 8, 'Copying Stock Update Data to ' + mupdate )

       Shell( 'copy ' + ( mfile + '.dbf ' ) + ( mupdate ) )  

      endif
     endif
     Brest( mscr )
    endif
    master->( ordsetfocus( BY_ID ) )
   endif
   syscolor( C_NORMAL )

  case tchoice = 3
   if Isready( 12 )
    stkfile := trim( getfile( "*.stk" ) )
    if !empty( stkfile )
     if !branch->( dbseek( substr( stkfile, -10, BRANCH_CODE_LEN ) ) )
      Error( 'Branch code ' + substr( stkfile, -10, BRANCH_CODE_LEN ) + ' not on branch file', 12 )
     else

      mloc := padr( branch->code, BRANCH_CODE_LEN )
      stock->( ordsetfocus( BY_STORE ) )

/* Need to delete Purge all Stock Records as updates are total updates */

      Bsave( 05, 10, 08, 35 )
      @ 05, 12 say '< Zeroing Records >'
      Highlight( 06, 12, 'Records to Check', Ns( lastrec() ) )
      dbseek( mloc )
      while stock->branch = mloc .and. !stock->( eof() )

       stock->( dbdelete() )
       stock->( dbskip() )

       Highlight( 07, 12,'Records Checked',Ns( recno() ) )

      enddo

      if Netuse( stkfile, EXCLUSIVE, 10, 'stkupdt', NEW )
       Bsave( 11, 10, 15, 35 )
       @ 11, 12 say '< Updating from Disk >'
       Highlight( 12, 12, 'Records to Check', Ns( stkupdt->( lastrec() ) ) )

       stock->( ordsetfocus( BY_ID ) )
       while !stkupdt->( eof() )

        if !stock->( dbseek( stkupdt->id + mloc ) )
         Add_rec( 'stock' )
         stock->id := stkupdt->id
         stock->branch := mloc
        endif

        Rec_lock( 'stock' )
        stock->onhand := stkupdt->onhand
        stock->onorder := stkupdt->onorder
        stock->available := stkupdt->available

        stkupdt->( dbskip() )
        Highlight( 13, 12,'Records Checked',Ns( stkupdt->( recno() ) ) )

       enddo
       stkupdt->( dbclosearea() )
      endif
     endif
    endif
   endif

  case tchoice = 4
   Heading( 'Delete Dead Stock Records' )
   if Isready( 12 )
    select stock
    ordsetfocus( NATURAL )
    dbgotop()

    Bsave( 11,10,15,35 )
    Highlight( 12, 12, 'Records to Check', Ns( lastrec() ) )
    while !stock->( eof() )

     msum := 0
#ifndef COOP
     if stock->onhand = 0 .and. stock->onorder = 0 .and. stock->special = 0 
#else
     if stock->onhand = 0 .and. stock->onorder = 0 .and. stock->special = 0 ;
        .and. stock->excess = 0
#endif
      stock->( dbdelete() )

     endif
     stock->( dbskip() )
     Highlight( 13, 12,'Records Checked',Ns( recno() ) )

    enddo
    ordsetfocus( 1 )
   endif
  endcase

 case choice = 4  // Should only appear for COOP

  if Netuse( 'hoprices', EXCLUSIVE )

   set relation to hoprices->id into master
   
   mscr := Bsave( 02, 10, 04, 50 )
   @ 3, 12 say 'Setting up - Please Wait'
   replace all hoprices->labels with master->onhand while Pinwheel( NOINTERUPT )
   brest( mscr )

   hoprices->( dbgotop() )

   mscr:=Bsave( 00, 00, 24, 79 )
   Heading( 'Price Check System' )
   Bsave( 01, 00, 24, 79 )
   for x = 1 to 24-4
    @ x+3,1 say row()-3 pict '99'
   next

   updtbrow:=tbrowsedb( 02, 04, 24-1, 79-1 )
   updtbrow:colorspec := TB_COLOR
   updtbrow:HeadSep:=HEADSEP
   updtbrow:ColSep:=COLSEP

   updtbrow:addcolumn( tbcolumnnew( 'id', { || idCheck( hoprices->id ) } ) )
   updtbrow:addcolumn( tbcolumnnew( 'Desc', { || left( master->desc, 30 ) } ) )
   updtbrow:addcolumn( tbcolumnnew( 'Current', { || transform( master->sell_price, PRICE_PICT ) } ) )
   updtbrow:addcolumn( tbcolumnnew( 'Revised', { || transform( hoprices->new_price, PRICE_PICT ) } ) )
   updtbrow:addcolumn( tbcolumnnew( 'Labels', { || transform( hoprices->labels, QTY_PICT ) } ) )

   hitkey := 0

   while hitkey != K_ESC .and. hitkey != K_END
    updtbrow:forcestable()
    hitkey := inkey(0)
    do case
    case hitkey == K_F1
     Build_help( { { 'F10', 'Display Desc Details' }, ;
                   { 'Del', 'Delete Item from list' }, ;
                   { 'Enter', 'Revise Price' } } )
                  
    case hitkey == K_ENTER
     tscr := Bsave( 3, 10, 7, 50 )
     @ 4, 12 say 'Labels to print' get hoprices->labels pict QTY_PICT
     read
     brest( tscr )
     updtbrow:refreshcurrent()

    case hitkey == K_F10
     itemdisp( FALSE )

    case hitkey == K_DEL
     if Isready( 12, 10, 'Ok to delete this item' )

      Del_rec( 'hoprices', UNLOCK )
      hoprices->( dbgotop() )
      updtbrow:refreshall()

     endif 

    otherwise 
     Navigate( updtbrow, hitkey )

    endcase

   enddo 

   if ( hoprices->( lastrec() ) != 0 ) .and. Isready( 12, 10, 'Ok to process this list' )

    hoprices->( dbgotop() )
    while !hoprices->( eof() ) 

     Rec_lock( 'master' )
     master->sell_price := hoprices->new_price
     master->( dbrunlock() )

     if hoprices->labels > 0
      Code_print( master->id, hoprices->labels )
     endif

     hoprices->( dbdelete() )
     hoprices->( dbskip() )

    enddo 

    EndPrint( NO_EJECT )

   endif 
   Brest( mscr )

   hoprices->( dbclosearea() )

  endif 
 endcase

enddo

dbcloseall()
return

*

func drivetest( drive )
local mhandle := fcreate( drive + '___' ), merror := ferror(), mdir
if mhandle = -1
 Error( 'Floppy Diskette error (' + Ns( merror ) + ') - try again!', 12 )
 return FALSE
else
 fclose( mhandle )
 ferase( drive + '___' )
endif
return TRUE
