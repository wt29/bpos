/*

 
  Last change:  APG  10 Jun 2004    9:29 pm

      Last change:  TG   16 Jan 2011    6:40 pm
*/
Procedure archive

#include "bpos.ch"

local oldscr:=Box_Save(), getlist:={}, aArray, aHelpLines, y, mfpos
local choice, arcobj, keypress, tscr, mscr, mkey, mlen, mmacro

if Netuse( Oddvars( SYSPATH ) + "archive\archive" )

 while TRUE
  Box_Restore( oldscr )
  Heading( 'Archive File Enquiry/Retrieve' )
  aArray := {}
  aadd( aArray, { 'Return', 'Return to Archive Menu' } )
  aadd( aArray, { 'Desc', 'Search Archive by desc' } )
  aadd( aArray, { 'Author', 'Search Archive by Author' } )
  aadd( aArray, { 'Boolean', 'Boolean Search Archive' } )
  aadd( aArray, { 'id', 'Archive by id' } )
  choice := MenuGen( aArray, 15, 36, 'Archive' )
  do case
  case choice > 1
   do case
   case choice = 2
    mmacro := 'Desc'
    mkey := space(10)
    archive->( ordsetfocus( BY_DESC ) )

   case choice = 3
    mmacro := 'alt_desc'
    mkey := space(10)
    archive->( ordsetfocus( BY_ALTDESC ) )

   case choice = 4
#ifndef __HARBOUR__
    Boolean( 'archive' )
#endif
    loop

   case choice = 5
    mmacro := 'id'
    mkey := space( ID_ENQ_LEN )
    archive->( ordsetfocus( BY_ID ) )

   endcase
   tscr:=Box_Save()

   while TRUE
    Box_Restore( tscr )
    Heading('Archive Inquire by '+mmacro )
    mkey := padr( mkey, 10 )
    @ 15 + choice, 44 say 'ออออฏ' get mkey pict '@K!'
    read
    if lastkey() = K_ESC
     exit

    else
     if choice = 5 
      if left( mkey, 3 ) != '978'
       mkey := '978' + mkey
      endif
     endif
     mkey := trim( mkey )
     mlen := len( mkey )

     select archive
     if !archive->( dbseek( mkey ) )
      Error('No '+mmacro+' match on File',12)

     else
      // vidmode( lvars( L_MAXROWS ) )
      cls
      Heading('Select desc from Archive')
      arcobj := TBrowseDB( 01, 0, 24, 79 )
      arcobj:colorspec := TB_COLOR
      arcobj:HeadSep := HEADSEP
      arcobj:ColSep := COLSEP
      arcobj:goTopBlock := { || dbseek( mkey ) }
      arcobj:goBottomBlock := { || jumptobott( mkey ) }
      do case
      case choice = 2
       arcobj:skipBlock:=KeySkipBlock( { || left( upper( archive->desc ), mlen ) }, mkey )
      case choice = 3
       arcobj:skipBlock:=KeySkipBlock( { || left( upper( archive->alt_desc ), mlen ) }, mkey )
      case choice = 4
       arcobj:skipBlock:=KeySkipBlock( { || left( upper( archive->id ), mlen ) }, mkey )
      endcase
      arcobj:AddColumn(TBColumnNew('Desc', { || left( archive->desc, 20 ) } ) )
      arcobj:AddColumn(TBColumnNew( ALT_DESC, { || left( archive->alt_desc, 12 ) } ) )
      arcobj:AddColumn(TBColumnNew('Supp', { || archive->supp_code } ) )
      arcobj:AddColumn(TBColumnNew('Bi', { || archive->binding } ) )
      arcobj:AddColumn(TBColumnNew('Price', { || transform( archive->sell_price ,'999.99') } ) )
      arcobj:AddColumn(TBColumnNew('Last Sold', { || archive->dsale } ) )
      arcobj:AddColumn(TBColumnNew('id',{ || idcheck( archive->id ) } ) )
      arcobj:freeze := 1
      keypress := 0
      while keypress != K_ESC .and. keypress != K_END
       arcobj:forcestable()
       keypress := inkey(0)
       if !navigate(arcobj,keypress)

        do case
        case keypress == K_F1
         aHelpLines := { ;
         { 'Enter', 'Select Desc to Add to Main Database' },;
         { 'Alt-S', 'Examine Stock Other Stores' },;
         { 'Esc/End', 'Exit this Screen' } }
         Build_help( aHelpLines )

        case keypress == K_ALT_S
         Stockdisp( archive->id )

        case keypress == K_ENTER
         if Codefind( archive->id )
          Error('id No already found on Master File',12)
         else
          mscr:=Box_Save(2,08,8,72)
          Highlight(3,10,' Desc ',archive->desc)
          Highlight(5,10,'Author ',archive->alt_desc)

          if Isready( 7, 10, 'Ok to retrieve this desc from archive' )

           Add_rec( 'master' )
           for y := 1 to archive->( fcount() )
            mfpos := master->( fieldpos( archive->( fieldname( y ) ) ) )
            if mfpos != 0
             master->( fieldput( mfpos, archive->( fieldget( y ) ) ) )
            endif
           next y
           if archive->( fieldpos( 'brand' ) ) != 0
            master->supp_code := ;
            if( lookitup( 'supplier', archive->supp_code ) != '',archive->supp_code,;
                lookitup( 'brand', archive->brand, 'supp_code' ) )
           else
            master->supp_code := archive->supp_code
           endif

           itemdisp( TRUE )         // Edit rec assume record is locked

           if lastkey() = K_ESC .or. empty( master->desc )

            Del_rec( 'master', UNLOCK )

            Error( "Archived record deleted from master file", 12 )

           endif

           master->( dbrunlock() )
          endif
          Box_Restore( mscr )
         endif
         select archive
        endcase

       endif
      enddo
      Vidmode( 25 )
     endif
    endif
   enddo
  case choice < 2
   Box_Restore( oldscr )
   select master
   archive->( dbclosearea() )
   return
  endcase
 enddo

endif
return
