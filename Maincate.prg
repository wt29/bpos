/*
      MainCate - Category Maintenance

      Last change:  TG   18 Oct 2010    9:44 pm
*/
Procedure f_Category

#include "bpos.ch"

local mgo := FALSE, choice, mcat, mloop, mcat2, getlist:={}, gchoice
local oldscr:=Box_Save(), mrec, mkey, mqty, sID, aArray
local mcat1name, mloop1, farr := {}

Center(24,'Opening Category File')
mgo := Netuse( "Category" )
line_clear(24)

while mgo
 Box_Restore( oldscr )
 Heading('Category File Maintenance Menu')
 aArray := {}
 aadd( aArray, { 'File', 'Return to file Maintenance Menu' } )
 aadd( aArray, { 'Add', 'Add New Categories' } )
 aadd( aArray, { 'Edit', 'Change Category Details' } )
 aadd( aArray, { 'Global', 'Global Category Change' } )
 aadd( aArray, { 'Clone', 'Clone on Category list off another' } )
 aadd( aArray, { 'Delete', 'Delete a Category from System' } )
 aadd( aArray, { 'Print', 'Print Categories' } )
 choice := MenuGen( aArray, 05, 02, 'Category' )
 oldscr:=Box_Save()
 mloop := TRUE
 while mloop
  mcat := space(6)
  do case
  case choice = 2 .and. Secure( X_ADDFILES )
   Heading('Category File Add')
   @ 7,10 say 'ÍÍÍ¯ New Category Code' get mcat pict '@!'
   read
   if !updated()
    mloop := FALSE
   else
    select category
    if dbseek( mcat )
     Box_Save(11,08,13,72)
     Center(12,'Category Name ÍÍÍ¯ ' + category->name )
     Error('Category Code already on file',15)
    else
     Add_rec( 'category' )
     category->code := mcat
     Box_Save(08,07,13,72)
     @ 09,10 say 'Category Code  ' + mcat
     @ 11,10 say 'Category Name ' get name
     read
     if empty( category->name )
      Error("Name field is empty - Category deleted",13)
      delete
     endif
     dbrunlock()
    endif
   endif

  case choice = 3 .and. Secure( X_EDITFILES )
   Heading('Change Category Details')
   @ 8,10 say 'ÍÍÍ¯ Category Code' get mcat pict '@!'
   read
   if ! updated()
    mloop := FALSE
   else
    if !category->( dbseek( mcat ) )
     Error('Category code not found',12)
    else
     Rec_lock( 'category' )
     Box_Save( 08, 07, 13, 72 )
     Highlight( 09, 10, 'Category Code', mcat )
     @ 11,10 say 'Category Name ' get category->name valid !empty( category->name )
     read
     category->( dbrunlock() )
    endif
   endif

  case choice = 4
   if Secure( X_GLOBALS )
    Heading('Global Category Change')
    aArray := {}
    aadd( aArray, { 'Exit', 'Return to Category Menu' } )
    aadd( aArray, { 'Master', 'Perform Global Change on Master file only' } )
    aadd( aArray, { 'Customer', 'Perform Global Change on Customer file only' } )
    aadd( aArray, { 'Both', 'Global Category Change to Customer & Master Files' } )
    gchoice := MenuGen( aArray, 09, 03, 'Global' )
    Box_Save( 02, 08, 11, 71 )
    mcat:=mcat2:=space(6)
    @ 3,10 say 'Enter Old Category Code' get mcat pict '@!'
    read
    if !updated()
     mloop := FALSE
    else
     select category
     seek mcat
     mcat1name := category->name
     mcat2 := space(6)
     @ 05,10 say 'Enter Category to change to' get mcat2 pict '@!'
     read
     if !updated()
      mloop1 := FALSE
     else
      seek mcat2
      if !found()
       Error( 'Category Record not found', 14 )
      else
       Box_Save( 01, 02, 12, 78 )
       Center( 3, 'You are about to change all ' + if( gchoice=2 .or. gchoice=4, 'Master ', '' ) ;
             + if( gchoice=3, '& ', '' ) + if( gchoice > 2, 'Customer', '' ) + 'file records for -' )
       Center( 4, mcat1name + '- to -' + category->name )
       if( gchoice=4, Center( 5,'Old Code ' + mcat + ' will be deleted' ), '' )
       if Isready( 6 )
        if Isready( 10, 15, 'Again - are you sure this is correct?' )
         if Netuse( "custcate"  )
          if Netuse( "macatego" )
           if gchoice = 2 .or. gchoice = 4

            while macatego->( dbseek( mcat ) )
             Rec_lock( 'macatego' )
             macatego->code := mcat2
             macatego->( dbrunlock() )
            enddo

           endif

           if gchoice > 2
            while custcate->( dbseek( mcat ) )
             Rec_lock( 'custcate' )
             custcate->code := mcat2
             custcate->( dbrunlock() )
            enddo
           endif

           if gchoice = 4
            if category->( dbseek( mcat ) )
             Del_rec( 'category', UNLOCK )
            endif
           endif

           macatego -> (dbclosearea() )
          endif
          custcate -> ( dbclosearea() )
         endif
        endif
       endif
      endif
     endif
    endif
   endif
   mloop := FALSE

  case choice = 5
   if Secure( X_GLOBALS )
    Heading("Clone Category Lists")
    aArray := {}
    aadd( aArray, { 'Exit', 'Return to Category Menu' } )
    aadd( aArray, { 'Master', 'Category List on Master file only' } )
    aadd( aArray, { 'Customer', 'Category List on Customer file only' } )
    aadd( aArray, { 'Both', 'Category list on Customer & Master Files' } )
    gchoice := MenuGen( aArray, 10, 03, 'Clone' )
    Box_Save(02,08,11,71)
    mcat:=mcat2:=space(6)
    @ 3,10 say 'Category Code to clone' get mcat pict '@!'
    read
    if !updated()
     mloop := FALSE
    else
     select category
     seek mcat
     mcat1name := category->name
     mcat2 := space(6)
     @ 05,10 say 'New Category for cloned list' get mcat2 pict '@!'
     read
     if !updated()
      mloop1 := FALSE
     else
      if !dbseek( mcat2 )
       Error( 'Category Record not found', 12 )
      else
       Box_Save( 01, 02, 12, 78 )
       Center( 3, 'You are about to clone all ' + if( gchoice=2 .or. gchoice=4, 'Master ', '' ) ;
             +if(gchoice=3,'& ','')+if(gchoice>2,'Customer','')+'file records for -')
       Center(4,mcat1name + '- to -' + category->name)
       if Isready(6)
        If Isready( 10, 15, 'Again - are you sure this is correct?' )
         if Netuse( "custcate" )
          if Netuse( "macatego" )
           if gchoice = 2 .or. gchoice = 4

            macatego->( dbseek( mcat ) )
            while macatego->code = mcat .and. !macatego->( eof() )
             mrec := macatego->( recno() )
             sID := macatego->id
             mqty := macatego->qty
             add_rec( 'macatego' )
             macatego->code := mcat2
             macatego->id := sID
             macatego->qty := mqty
             macatego->( dbrunlock() )
             macatego->( dbgoto( mrec ) )
             macatego->( dbskip() )
            enddo
           endif
           if gchoice > 2

            custcate->( dbseek( mcat ) )
            while custcate->code = mcat .and. !custcate->( eof() )
             mrec := custcate->( recno() )
             mkey := custcate->key
             add_rec( 'custcate' )
             custcate->key := mkey
             custcate->code := mcat2
             custcate->( dbrunlock() )
             custcate->( dbgoto( mrec ) )
             custcate->( dbskip() )
            enddo

           endif
           macatego->( dbclosearea() )
          endif
          custcate->( dbclosearea() )
         endif
        endif
       endif
      endif
     endif
    endif
   endif
   mloop := FALSE

  case choice = 6
   if Secure( X_DELFILES )
    Heading( "Delete Category from System" )
    @ 11,10 say 'ÍÍÍ¯ Category Code' get mcat pict '@!'
    read
    if !updated()
     mloop := FALSE
    else
     select category
     if !dbseek( mcat )
      Error('Category Code not on file',12)
     else
      Box_Save(2,08,6,71)
      Center( 3, 'This option will delete ' + trim( category->name ) + ' category from the' )
      Center( 4, 'Master, Customer and Category Files')
      if Isready( 12 )
       if Isready( 12, 10 , 'Again - Ok to proceed'  )
        if Netuse("custcate" )
         if Netuse("macatego" )

          while macatego->( dbseek( mcat ) )
           Del_rec( 'macatego', UNLOCK )
          enddo
          macatego->( dbclosearea() )

          while custcate->( dbseek( mcat ) )
           Del_rec( 'custcate', UNLOCK )
          enddo
          custcate->( dbclosearea() )

          select category
          if category->( dbseek( mcat ) )
           Del_rec( 'category', UNLOCK )
          endif

          SysAudit('CatDel'+mcat)
         endif
        endif
       endif
      endif
     endif
    endif
   endif
  case choice = 7
   Heading('Print Category Codes')
   Print_find("report")
   if Isready(9)
    select category
    aadd(farr,{'category->code','Code',11,0,FALSE})
    aadd(farr,{'category->name','Name',50,0,FALSE})
    Reporter(farr,'"Listing of Categories Sorted by Code"','','','','',FALSE, , ,80)

   endif
   mloop := FALSE
  case choice < 2
   mgo := FALSE
   mloop := FALSE

  endcase
  Box_Restore( oldscr )
 enddo
enddo
dbcloseall()
return
