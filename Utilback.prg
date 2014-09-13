/*

 UtilBack - Utilities Backup

       Last change: APG 17/04/2009 12:25:00 PM

      Last change:  TG   16 Jan 2011    6:40 pm
*/

#include "bpos.ch"
#define BACKUPFILE "bposback"

Procedure UtilBack ( nX, nY )

local mscr, mdir, choice, getlist:={}
local rchoice, mfile, minit, mdate
local oldscr := Box_Save(), mdrive, mset, aArray

local cBakStr := Oddvars( SYSPATH ) + "zip " + Oddvars( SYSPATH ) + BACKUPFILE + " " +;
                 Oddvars( SYSPATH ) + "*.dbf " +;
                 Oddvars( SYSPATH ) + "Comments\*.* " +;
                 Oddvars( SYSPATH ) + "archive\*.*"

if !file( Oddvars( SYSPATH ) + "zip.exe" )
 Error( "zip.exe not found in system directory - Google is your friend", 12 )

endif

while TRUE

 Box_Restore( oldscr )
 Heading('Backup Menu')

 aArray := {}
 aadd( aArray, { 'Main', 'Return to Utility Menu' } )
 aadd( aArray, { 'Zip', 'Zip ' + SYSNAME + ' Data Files' } )
 aadd( aArray, { 'Backup', 'Backup Data files to Floppy' } )
 aadd( aArray, { 'Restore', 'Restore file from Floppy' } )
 choice := Menugen( aArray, nx, ny, 'Backup')

 do case
 case choice < 2
  exit

 case choice = 2
  Heading("Zip Data Files for backup")
  if !NetUse( "master", EXCLUSIVE, 10 )
   Error("Master File in use - Backup not Possible",12)

  else
   master->( dbclosearea() )
   mscr := Box_Save( 2, 10, 8, 72 )
   mdir:=directory(Oddvars( SYSPATH ) + BACKUPFILE + ".zip")
   Highlight(3,12,'Space remaining on hard disk ',transform(diskspace(),'999,999,999,999')+' Bytes')
   if len(mdir) > 0
    Highlight(5,12,'Minimum Space Required ',transform(mdir[1,2],'999,999,999,999')+' Bytes')
    Highlight(7,12,'The date of the current zipped file is',dtoc(mdir[1,3]))
    if diskspace() <= ( mdir[1,2] + (mdir[1,2]/10) )
     SysAudit("MinDsk")
     Error('Minimum disk space requirement exceeded !!!',12)

    endif

   else
    Center(5,'No zipped file on Disk')

   endif
   if Isready(12)
    Kill( Oddvars( SYSPATH ) + BACKUPFILE + ".zip" )
    close all

    if swap2dos( cBakStr )
     SysAudit( "BakSqh" )

    else
     Error( 'Trouble doing the zip', 12)

    endif

   endif
   Box_Restore( mscr )

  endif

 case choice = 3
  if !NetUse( "backlog", EXCLUSIVE, 10 )
   Error( "Backup Log file not Available - Call " + DEVELOPER, 12 )

  else
   mscr := Box_Save( 2, 10, 16, 72 )
   mdir := directory( Oddvars( SYSPATH ) + BACKUPFILE + ".zip" )
   if len(mdir) = 0
    Error('No zipped Backup File Found!!',12)

   else
    Highlight(03,12,'Date of the current zipped file is', dtoc(mdir[1,3]))
    Highlight(04,12,'Size of the current zipped file is', Ltrim(transform(mdir[1,2],'999,999,999'))+' Bytes')
    mdate := date() - 31              // Arbitrary date for max
    mset := ''
    minit := ''
    while !backlog->( eof() )
     if backlog->date > mdate
      mdate := backlog->date
      mset := backlog->disk_set
      minit := backlog->initials

     endif
     backlog->( dbskip() )

    enddo

    Highlight( 07, 12, 'Last Physical Backup Performed',dtoc(mdate))
    Highlight( 08, 12, "By '" + minit + "' on Backup Set",mset)
    if Isready(12)
     minit := '  '
     mset := '  '
     mdrive := ' '
     @ 9,12 say 'Initials' get minit pict '!!' valid( Dup_chk( minit, 'operator' ) )
     @ 9,40 say 'Backup Set Being Used' get mset pict '!!' valid(!empty(mset))
     @ 10, 12 say 'Target Drive (USB Key etc)' get mDrive pict '!'
     read
     if updated()
      select backlog
      locate for backlog->disk_set = mset
      if !found()
       add_rec()
       backlog->disk_set := mset

      endif

      rec_lock()
      backlog->initials := minit
      backlog->cumulative += 1
      backlog->date := date()
      backlog->time := time()
      dbrunlock()

      if swap2dos( "xcopy "+Oddvars( SYSPATH ) + BACKUPFILE + ".zip " + mDrive + ": " )
       SysAudit( "BakDsk" + minit)

      endif

     endif

    endif

   endif
   Box_Restore( mscr )

  endif
 case choice = 4
  if Syspass()
   Heading('Restore Menu')
   mdir := directory( Oddvars( SYSPATH )+ BACKUPFILE + ".zip" )
   Box_Save( 2, 10, 10, 72 )
   if len(mdir) > 0
    Highlight( 3, 12, 'Current zipped Backup file (on hard disk) size', Ns( mdir[1,2] ) )
    Highlight( 5, 12, 'Current zipped Backup file (on hard disk) Date', dtoc( mdir[1,3] ) )

   else
    Highlight( 3, 12, '', 'No zipped Backup file found on hard disk' )

   endif
   Box_Save( nY+3, nX, ny+5, nx+10 )
   aArray := {}
   aadd( aArray, { 'Backup', 'Return to Backup Menu' } )
   aadd( aArray, { 'Copy', 'Copy a ' + SYSNAME + ' backup from USB Key' } )
   aadd( aArray, { 'Single', 'Restore (unzip) a single database file' } )
   aadd( aArray, { 'All', 'Restore (unzip) all Database Files' } )
   rchoice := Menugen( aArray, nx+4, ny+1, 'Restore')

   do case
   case rchoice = 2
    Heading( "Restore zipped Data Files" )
    @ 7,12 say 'About to restore zipped Files from USB / Flash Drive'
    if Isready( 12 )
     mDrive = ' '
     @ 8,12 say 'Drive Letter containing zip file' get mdrive pict '!'
     read
     if Isready(12)
      mdir := directory( mDrive + ":" + BACKUPFILE + ".zip" )
      if empty(mdir)
       Error("No " + SYSNAME + " backup files found on drive",12)

      else
       @ 7,12 say space(58)
       @ 8,12 say space(58)
       Highlight( 7, 12, 'Backup file Date', dtoc(mdir[1,3] ) )
       if Isready(12)
//        mscr:=savescreen(0,0,24,79)
        Center(9,'Copying backup from Drive ' + mdrive + ': ...Please Wait')
//        @ 12,0 clear to 24,79
        if swap2dos( "xcopy " + mdrive +":" + BACKUPFILE + ".zip " + Oddvars( SYSPATH ) + BACKUPFILE + ".zip /y" )
         SysAudit( "ResDsk" )

        endif
//        restscreen(0,0,24,79,mscr)

       endif

      endif

     endif

    endif
   case rchoice = 3
    mscr := Box_Save( 0, 0, 24, 79 )
    Heading( "Unzip Single File" )
    mfile := space(12)
    @ 7,12 say 'Enter File to Unzip' get mfile pict '@!'
    read
    if updated()
     mfile:=trim(mfile)
     Highlight( 9, 12, 'You are about to unzip', mfile + ".DBF")
     if Isready(10)
      if Syspass()
       if !NetUse( mfile, EXCLUSIVE, 10 )
        Error("Your selected file is in use cannot unzip",12)

       else
        use
//        @ 12,0 clear to 24,79
        if Swap2dos( "unzip  " + Oddvars( SYSPATH ) + BACKUPFILE + " " + mfile + ".dbf" )
         SysAudit( "UnSqh" + mfile )
         Box_Save( 10, 08, 16, 72 )
         @ 11,10 say 'The file has been unzipped - You will need to reindex it.'
         @ 13,10 say 'Exit from backup, Select the pack option and perform a'
         @ 15,10 say '       selective pack upon ' + mfile
         Error( "Single File Restore Completed", 18 )

        endif

       endif

      endif

     endif

    endif
    Box_Restore( mscr )
   case rchoice = 4
    mscr:=Box_Save()
    Heading("Unzip All Database Files")
    Center(7,'You are about to unzip ALL Database files')
    if Syspass()
     if Isready(10)
      if !NetUse( "master", EXCLUSIVE, 10 )
       Error("Master File in use - cannot unzip",12)

      else
       use
       Syscolor(3)
       Center(9,"Last Chance - All current data will be overwritten")
       if Isready(12)
        Syscolor(1)
        if Swap2dos( "unzip -o " + Oddvars( SYSPATH ) + BACKUPFILE + " " + Oddvars( SYSPATH ) )
         SysAudit("UnSqhAll")
         Box_Restore( mscr )
         Box_Save( 10, 08, 17, 72 )
         @ 11,10 say 'All files have been restored - You will need to reindex them.'
         @ 13,10 say '  Exit from backup, Select the pack option and perform a'
         @ 15,10 say '         full pack upon your database files.'
         @ 16,10 say SYSNAME + ' will now exit to allow old System Date to be applied'
         Error( "Restore Completed", 18 )
         quit

        endif

       endif

      endif

     endif

    endif

    Box_Restore( mscr )

   endcase

  endif

 endcase

enddo
close databases
return

*

function swap2dos ( swpstring )
run (swpstring)
return TRUE

*

Function syspass
return TRUE

*

FUNCTION Shell ( sRunString )
Swap2Dos( sRunString )
return TRUE


