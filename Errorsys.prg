/*

 Generic Error System

      Last change:  TG   29 Jan 2011    1:00 pm
*/
#include "bpos.ch"

#include "error.ch"
#include "set.ch"

Procedure ErrorSys()
 ErrorBlock( { |oError| ErrorMenu( oError ) } )

Return

Static Function ErrorMenu(oEr)

Local nErrLines,nActCount,aMenu,nErrTop,nErrBot,nChoice,cChoice,cErrScr,nIntense,;
      cDevice,ccolor,bOldErr,cMsg,cErrWrnMsg,nLogFile

Local DosErr:={"Invalid function number","File not found","Path not found",;
"Too many open files","Access denied","Invalid handle","Memory",;
"Insufficient memory","Memory","Invalid environment","Invalid format",;
"Invalid access code","Invalid data","","Invalid drive",;
"Cannot remove directory","Not same device","No more files","Write-protect",;
"Unknown unit","Drive not ready","Unknown command","Data error (CRC)",;
"Bad request","Seek error","Unknown media type","Sector not found",;
"Printer out of paper","Write fault","Read fault","General failure",;
"Sharing violation","Lock violation","Invalid disk change","",;
"","","","","","","","","","","","","","","","","","Network name not found",;
"Network busy","","","Network adapter hardware error","Incorrect response from network",;
"Unexpected network error","Incompatible remote adapter","Print queue full",;
"Not enough space for print file","Print file deleted","Network name deleted",;
"Access denied","Network device type incorrect","Network name not found",;
"Network name limit exceeded","Network BIOS session limit exceeded",;
"Temporarily paused","Network request not accepted","","","","","","","","",;
"File already exists","","","","","Duplicate redirection",;
"Invalid password","Invalid parameter","Network device fault" }

local oPrinter
local aErrors := {}     // Captures the callstack for output to the printer
local x                 // loop counter
local nHandle           // File Handle to save the error

do case
case (oEr:genCode == EG_ZERODIV)
 return ( 0 )
case (oEr:genCode == EG_OPEN) .and. oEr:osCode == 32 .and. (oEr:canDefault)
 Neterr( TRUE )
 return ( FALSE )
case oEr:genCode == EG_APPENDLOCK .and. oEr:canDefault
 NetErr ( TRUE )
 return ( FALSE )
endcase

/* if error occurs within this error-handler, handle with DuplError */

bOldErr:=ErrorBlock( {|oError| DuplError(oError)} )

nLogFile:=-1
cChoice:=' '

while cchoice != 'A'

 ccolor:=setcolor('W/R')
 cdevice:=set(_SET_DEVICE)
 set device to screen

 if oEr:genCode == EG_PRINT
  nerrlines:=5
 else
  nerrlines:=6
 endif
 if oEr:genCode != EG_PRINT
  if valtype( lvars( L_MAXROWS ) ) == nil
   lvars( L_MAXROWS, 25 )

  endif

  nActCount := 2
  while !empty( ProcName( nActCount ) ) .and. nErrLines <= 10
   if procLine( nActCount ) != 0
    nerrlines++
   endif
   nactcount++
  enddo

  if valtype(oEr:args)=='A'
   if len(oEr:args) > 0
    nErrLines++
   endif
  endif

  nErrLines += if( oEr:filename == "", 0, 1 )
  nErrLines += if( oEr:osCode != 0, 1, 0 )

 endif

 nerrtop := 5
 nerrbot := min( nErrtop+nErrLines+5, 24-1 )

 @ nErrTop,0 clear to nErrBot,60
 @ nErrTop,0 to nErrBot,60 color 'B+/r'

 do case
 case oEr:severity==ES_CATASTROPHIC
  cErrWrnMsg := 'Severe error'

 case oEr:severity==ES_ERROR
  cErrWrnMsg := 'Error'

 case oEr:severity==ES_WARNING
  cErrWrnMsg := 'Warning'

 otherwise
  cErrWrnMsg := 'Message'

 endcase

 if !Empty(oEr:subSystem)
  cMsg := chr( 180 ) + SYSNAME + ' ' + cErrWrnMsg + chr( 195 )
  @ nErrTop, 2 say cMsg

 endif

 aadd( aErrors, 'Error Diagnostics' )
 cMsg := Ns( oEr:genCode ) + ': '+oEr:description + ' ( ' + alltrim( oEr:subsystem ) + '/' + Ns( oEr:subCode ) + ' ) '

 @ row()+1, 2 say cMsg
 aadd( aErrors, cMsg )

 if oEr:osCode!=0
  cMsg:='Dos error ' + Ns(oEr:osCode)
  aadd( aErrors, cMsg )
  @ row()+1,2 say cMsg + ': '
  if oEr:oscode<=Len( DosErr ) .and. oEr:oscode>0
   @ row(),Col() say DosErr[oEr:osCode]

  endif

 endif

 if !oEr:operation==""
  cMsg:='Operation attempted: '+oEr:operation
  @ row()+1,2 say cMsg
  aadd( aErrors, cMsg )

 endif

 if ValType(oEr:args)=='A'
  if Len(oEr:args) > 0
   cMsg:='Arguments: '+ErrDispArg(oEr:args[1])
   @ row()+1,2 say cMsg
   aadd( aErrors, cMsg )
   if Len(oEr:args) > 1
    cMsg:='& '+ErrDispArg(oEr:args[2])
    @ row(),col() say cMsg
    aadd( aErrors, cMsg )

   endif

  endif

 endif

 if oEr:filename != ""
  cMsg:='Filename: ' + oEr:filename
  @ row()+1,2 say cMsg
  aadd( aErrors, cMsg )

 endif

 @ row()+1,2 say 'Called from: '
 aadd( aErrors, 'Called from' )
 nActCount := 2
 while !( ProcName( nActCount ) == "" ) .and. nActCount <= 10
  if procline( nActCount ) != 0
   cMsg := padr( Procname( nActCount ), 20 ) + 'Line - ' + Ns( ProcLine( nActCount ) ) 
   if row() < 20
    @ row(),15 say cMsg
    @ row()+1,Col() say ''
    aadd( aErrors, cMsg )

   endif

  endif
  nActCount++

 enddo
 if select() != 0
  cMsg := 'File Selected->' + alias() + ' ' + Oddvars( SYSPATH )
  @ nErrbot-2, 2 say cMsg
  aadd( aErrors, cMsg )

 endif
 nIntense := set( _SET_INTENSITY , TRUE )
 @ nErrbot-1, 2 say 'Notify Bluegum Software with this error.'
 set( _SET_INTENSITY , nIntense )

 nIntense:=set( _SET_INTENSITY , TRUE )
 aMenu:={}

 if (oEr:canRetry)
  aadd( aMenu, { 'Retry', 'Retry the Operation' } )

 endif
 aadd( aMenu, { 'Abort', 'Exit from ' + SYSNAME } )
 aadd( aMenu, { 'Print', 'Print these details for sending to ' + DEVELOPER } )
 nchoice := MenuGen( aMenu, 12, 62, 'Select' )

 set( _SET_INTENSITY , nIntense )
 set( _SET_DEVICE , cDevice )
 setcolor( ccolor )

 do case
 case ( oEr:canretry ) .and. nchoice = 1
  Errorblock( bOldErr )
  Box_Restore( cErrScr )
  return TRUE

 case ( !oEr:canRetry .and. nchoice = 3 ) .or. (  oEr:canRetry .and. nchoice = 1 )
  dbcloseall()    // Shut all files - will allow Error( 4 ) to print ok
  set printer to ( trim( LVars( L_REPORT_NAME ) ) )
  oPrinter := PrintCheck( "System Error Report" )
  LP( oPrinter, DRAWLINE )
  LP( oPrinter, BIGCHARS )
  LP( oPrinter, SYSNAME + ' Build ' + BUILD_NO + ' Error Report   #' + Ns( Sysinc( 'Fax', 'I', 1 ) ) )
  LP( oPrinter, NOBIGCHARS )
  LP( oPrinter, BIGCHARS )
  LP( oPrinter, 'From ' + BPOSCUST)
  LP( oPrinter, NOBIGCHARS )
  LP( oPrinter, BIGCHARS )
  LP( oPrinter, 'Time ' + time() + '  Ph.' + Bvars( B_PHONE ) )
  LP( oPrinter, NOBIGCHARS )
  LP( oPrinter, trim( version() ) + ' ' + Bvars( B_BRANCH ) )
  LP( oPrinter, '' )
  for x := 1 to len( aErrors )
   LP( oPrinter, aErrors[ x ]  )

  next
//  Printgraph( oPrinter )    // Adds the screen print to the mix
  LP( oPrinter, '' )
  LP( oPrinter, BIGCHARS )
  LP( oPrinter, 'Please send me to Bluegum Software Email is ' + SUPPORT_EMAIL )
  LP( oPrinter, NOBIGCHARS )
  LP( oPrinter, BIGCHARS )
  LP( oPrinter, 'Fax number ' + SUPPORT_FAX )
  LP( oPrinter, NOBIGCHARS )
  LP( oPrinter, '' )
  LP( oPrinter, 'Comments ' + replicate( chr( 95 ), 60 ) )
  LP( oPrinter, '' )
  LP( oPrinter, '         ' + replicate( chr( 95 ), 60 ) )
  LP( oPrinter, '' )
  LP( oPrinter, 'Contact  ' + replicate( chr( 95 ), 60 ) )
  LP( oPrinter, '' )
  LP( oPrinter, '____________________ < Bluegum Software Office Use >___________________' )
  LP( oPrinter, '' )
  LP( oPrinter, 'Date ____________     Copies To : ______________   Log Number __________' )
  LP( oPrinter, '' )
  LP( oPrinter, 'Actioned   :     Yes      No     Date___________   By _____________' )
  oPrinter:EndDoc()
  oPrinter:Destroy()


  exit

 otherwise
  exit

 endcase

enddo

// Try to save the error locally

nHandle = HB_FTempCreate( OddVars( SYSPATH ) + 'errors' )
for x = 1 to len( aErrors )
   Fwrite( nHandle, aErrors[ x ] + CRLF )

next
FClose( nHandle )

setCursor( 1 )     // don't leave them in DOS without a cursor!
ErrorLevel( 0 )

quit               // We are out of here

Return FALSE       // superfluous return required to compile without warning

*

Static Function ErrDispArg(arg)
Local cStr
do case
case ValType(arg)=='A'
 cStr:='(Array) '

case ValType(arg)=='B'
 cStr:='(Block) '

case ValType(arg)=='C'
 cStr:='(C) "'+arg+'" '

case ValType(arg)=='D'
 cStr:='(D) '+dtoc(arg)+' '

case ValType(arg)=='L'
 cStr:='(L) .'+if(arg,'T','F')+'. '

case ValType(arg)=='M'
 cStr:='(M) "'+arg+'" '

case ValType(arg)=='N'
 cStr:='(N) '+AllTrim(Str(arg))+' '

case ValType(arg)=='O'
 cStr:='(Object) '

otherwise
 cStr:='(NIL) '

endcase
Return cStr

*

Static Function DuplError( oEr )
set print off
set console on
? "Error (" + Trim( oEr:description ) + ") at " + Trim( ProcName( 2 ) ) + ' (' + Ns( ProcLine( 2 ) ) + ')'
? Procname( 1 ) + ' ' + Ns( Procline( 1 ) )
? Procname( 0 ) + ' ' + Ns( Procline( 0 ) )
?
wait
Errorlevel( 0 )
quit
return (FALSE)


