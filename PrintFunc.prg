/*

      PrintFunc.prg
        
      Last change:  TG   29 Apr 2011    1:26 pm
*/

#include "bpos.ch"

#define PR_FLD_EXPR 1
#define PR_FLD_NAME 2
#define PR_FLD_LEN  3
#define PR_FLD_DEC  4
#define PR_FLD_TOT  5
#define PR_NEW_LINE 6

#define FW_NORMAL  400
#define FW_BOLD    700


static nDefPrinterCharWidth  // Set in Create Printer

function print_find ( sPTRMain )
local mret:=FALSE
local sWarning := " has not been configured on this machine"

sPTRMain = lower( sPTRMAIN )

do case
Case sPTRMain = "docket"
 if !PrinterExists( trim( LVars( L_DOCKET_NAME ) ) )
  Alert( "The docket printer " + trim( LVars( L_DOCKET_NAME ) ) + sWarning )

 else
  set printer to ( trim( LVars( L_DOCKET_NAME ) ) )
  LVars( L_PRINTER, trim( LVars( L_DOCKET_NAME ) ) )

 endif

Case sPTRMain = "report"
 if !PrinterExists( trim( LVars( L_REPORT_NAME ) ) )
  Alert( "The report printer " + trim( LVars( L_REPORT_NAME ) ) + sWarning )

 else
  set printer to ( trim( LVars( L_REPORT_NAME ) ) )
  LVars( L_PRINTER, trim( LVars( L_REPORT_NAME ) ) )

 endif

Case sPTRMain = "barcode"
 if !PrinterExists( trim( LVars( L_BARCODE_NAME ) ) )
  Alert( "The barcode printer " + trim( LVars( L_BARCODE_NAME ) ) + sWarning )

 else
  set printer to ( trim( LVars( L_BARCODE_NAME ) ) )
  LVars( L_PRINTER, trim( LVars( L_BARCODE_NAME ) ) )

 endif

Case sPTRMain = "invoice"
 if !PrinterExists( trim( LVars( L_INVOICE_NAME ) ) )
  Alert( "The invoice printer " + trim( LVars( L_INVOICE_NAME ) ) + sWarning )

 else
  set printer to ( trim( LVars( L_INVOICE_NAME ) ) )
  LVars( L_PRINTER, trim( LVars( L_INVOICE_NAME ) ) )

 endif

EndCase

return mret                  // Have we found the required printer

*

function open_de_draw
static lPortOpen := FALSE
if lvars( L_AUTO_OPEN )
 do case
 case lvars( L_CDTYPE ) = 'N'
 
 case lvars( L_CDTYPE ) = 'C'    // Citizen Docket Printers with cashdraw kickout
  Print_Find( "Docket" )
  set console off
  set print on
  ?? chr( 7 )
  set print off
  set console on
  set printer to

 case lvars( L_CDTYPE ) = 'E'    // Epson Docket Printers with cashdraw kickout
  Print_Find( "Docket" )
  set console off
  set print on
  ?? chr( K_ESC ) + 'p' + chr( 0 ) + chr( 25 ) + chr( 250 )
  ??
  set print off
  set console on
  set printer to

 endcase

endif

return nil

*

Function CDOpen
local newpass, sScreen
if Secure( X_CASHDRAWER )
 sScreen := Box_Save( 3, 01, 5, 40 )
 set console off
 @ 4, 2 say 'Enter Cash Drawer Password'
 accept to newpass
 set console on
 Box_Restore( sScreen )
 if upper( newpass ) != 'CASH'
  Error( 'Cash Drawer Passwords not accepted', 12 )
  SysAudit( 'CDPassFail' )
 else
  SysAudit( 'CDOpen' )
  Open_de_Draw()
 endif
endif
return nil

*

// Saves having to issue newline, setpos, textout for every line

Function LP (oPrinter, cText, nPos, lNewline )

static nDefFontSize
static aSaveFont := {,,,}

local aPos

default cText to ''     // Just outputs a line
default nPos to 0
default lNewline to TRUE

if nDefFOntSize = nil
 nDefFontSize := oPrinter:FontPointSize

endif

if aSaveFont = nil
 aSaveFont := [ oPrinter:FontName, oPrinter:FontPointSize, oPrinter:FontWidth ]

endif

do CASE
case cText = DRAWLINE    // Just a horizontal Line
 oPrinter:SetPos( 0 )
 oPrinter:line( oPrinter:Posx , ;
                oPrinter:posY - ( oPrinter:charheight / 2 ), ;
                oPrinter:rightMargin, ;
                oPrinter:posY - ( oPrinter:charheight / 2 ) )
 oPrinter:Newline()
 oPrinter:SetPos(0)

case cText = BOLD
 oPrinter:Bold( FW_BOLD )

case cText = NOBOLD
 oPrinter:Bold( FW_NORMAL )

case cText = PRN_GREEN
 oPrinter:setColor( RGB_GREEN )

case cText = PRN_BLACK
 oPrinter:setColor( RGB_BLACK )

case cText = PRN_RED
 oPrinter:setColor( RGB_RED )

case cText = SCRIPTCHARS
 aSaveFont[1] := oPrinter:FontName
 aSaveFont[2] := oPrinter:FontPointSize
 aSaveFont[3] := oPrinter:FontWidth
 oPrinter:setFont( 'Lucida Handwriting Italic', P_BIGFONTSIZE, 10 )        // CPI
 aPos := oPrinter:SetPos()
 oPrinter:SetPos( apos[1], apos[2] + oPrinter:LineHeight ) // CharHeight )      // Should move it down enough

case cText = BIGCHARS
 aSaveFont[1] := oPrinter:FontName
 aSaveFont[2] := oPrinter:FontPointSize
 aSaveFont[3] := oPrinter:FontWidth
 oPrinter:setFont( oPrinter:FontName, P_BIGFONTSIZE, 10 )        // CPI
 aPos := oPrinter:SetPos()
 oPrinter:SetPos( apos[1], apos[2] + oPrinter:LineHeight ) // CharHeight )      // Should move it down enough

case cText = VERYBIGCHARS
 aSaveFont[1] := oPrinter:FontName
 aSaveFont[2] := oPrinter:FontPointSize
 aSaveFont[3] := oPrinter:FontWidth
 oPrinter:setFont( oPrinter:FontName, P_VERYBIGFONTSIZE, 5 )        // CPI
 aPos := oPrinter:SetPos()
 oPrinter:SetPos( apos[1], apos[2] + oPrinter:LineHeight )      // oPrinter:CharHeight )      // Should move it down enough

case cText = NOBIGCHARS
 oPrinter:SetDefaultFont()
 oPrinter:setFont( aSaveFont[1] ) // , aSaveFont[2], aSaveFont[3] )   // Should go back to default

otherwise
 oPrinter:SetPos( nPOS * nDefPrinterCharWidth )                 // Always use absolute printer positioning
// oPrinter:SetPos( nPOS * nDefPrinterCharWidth)
// oPrinter:setpos( aPos[1], apos[2] + oPrinter:LineHeight )                 // Always use absolute printer positioning

 oPrinter:TextOut( cText )

 if lNewLine
  oPrinter:NewLine()
//  oPrinter:SetPos( 0 )
//  aPos := oPrinter:SetPos()
//  oPrinter:SetPos(0, apos[2] + oPrinter:LineHeight )

 endif

endcase

return nil

*

function DocketStatus
lvars( L_DOCKET , !lvars( L_DOCKET ) )
@ 01,67 say 'Docket is ' + if( lvars( L_DOCKET ), 'On ', 'Off' )
return lvars( L_DOCKET )

*

Function printcheck ( cReportName, cOtherPrinter, lDefFont )
local oPrinter

default lDefFont to TRUE

if empty( cOtherPrinter )
 cOtherPrinter = 'report'

endif

Print_find( cOtherPrinter )

Center( 24, 'Printing to ' + LVars( L_PRINTER ) )

oPrinter:= Win32Prn():New( trim( LVars( L_PRINTER ) ) )
oPrinter:Landscape:= .F.
oPrinter:FormType := FORM_A4
oPrinter:Copies   := 1
if !oPrinter:Create()
 Alert( "Cannot create Printer " + Trim( lVars( L_PRINTER ) ) )

endif
oPrinter:StartDoc( cReportName )
oPrinter:SetPen( PS_SOLID, 1, RGB_BLACK )

nDefPrinterCharWidth := oPrinter:charwidth

if !lDefFont    // The default font is Clipper compatible Courier New Fixed Pitch....
 oPrinter:SetFont( 'Lucida Console' , 10 ,{3,-50} )

endif

/*
Box_Save( 2, 10, 12, 70 )
@ 3, 12 say "Height   " + Ns( oPrinter:Charheight )
@ 4, 12 say "Width    " + Ns( oPrinter:charWidth )
@ 5, 12 say "FontName " + oPrinter:FontName
@ 6, 12 say "Font Pt Sz " + Ns( oPrinter:FontPointSize )
@ 7, 12 say "Line Height " + Ns( oPrinter:lineheight )

wait
*/
return oPrinter

/*

Reporter - Generic Report function

aReport - is an array of arrays containing - 
       { cfield_expression, cfield_name, nwidth, ndecimals, ltotal }

*/

procedure Reporter( aReport,        ;
                    report_name, ; // string containing the Report Name
                    group_by,    ; // string containing the expression to group the report by
                    gh,          ; // is a string with the heading for the grouping above
                    sub_group_by,; // string containing the expression to sub group the report by
                    sh,          ; // is a string with the heading for the sub grouping above
                    msummary,    ; // Logical specifying Summary Report(.t.) or Full Report(.f.)
                    forcond,     ; // String with logical for expression
                    whilecond,   ; // String with logical expression while condition
                    page_width,  ; // 17 Pitch use 132 (default), 12 Pitch = 96, 10 Pitch = 80
                    allow_screen ; // can the report print to the screen?
                  )

local code,scode,i  
local sub_sub_tot := array( len( aReport ) )
local sub_tot := array( len( aReport ) )
local tot := array( len( aReport ) )
local page_number := 1
local oPrinter, sOut

local page_len:=0
local top_mar:=0
local bot_mar:=10
// local pwidth := lvars( val( substr( lvars( L_PRINTER ), 4, 1 ) ) + 7 )
local grp_code := { || &(group_by) }
local sub_code := { || &(sub_group_by) }
local grp_head := { || &(gh) }
local sub_head := { || &(sh) }

local bForCondition,bWhileCondition,pos
local totals:=FALSE
local cont:=TRUE,a,fldrec,fld
local done:=FALSE,prin:=FALSE,z,t
local toScreen := TRUE
local oFSO
local cFile, nPos
local oShell
// local oDocument

default page_width to 132
default msummary to FALSE
default allow_screen to TRUE

toScreen := if( !allow_screen, FALSE, Isready( 12, 10, 'Print to Screen' ) )
if toScreen
 //TRY
  oFSO := CreateObject( "Scripting.FileSystemObject" )

 //CATCH
  //Alert( "ERROR! Problem with Scripting host. [" + Ole2TxtError()+ "]" )
  //RETURN

 //END
 cFile := trim( Lvars( L_REGISTER ) ) + ".txt"
 oPrinter:= oFSO:CreateTextFile( cFile, VBTRUE )

else  // to Screen
 oPrinter := Win32Prn():New(Lvars( L_PRINTER ) )
 oPrinter:Landscape:= .F.
 oPrinter:FormType := FORM_A4
 oPrinter:Copies   := 1
 if !oPrinter:Create()
  Alert( "Cannot create Printer " + LVars( L_PRINTER ) )
  return

 endif
 oPrinter:StartDoc( report_name )
 oPrinter:SetPen( PS_SOLID, 1, RGB_RED )
 oPrinter:SetFont( 'Lucida Console', 8, {3,-50} )

endif
for i := 1 to len( aReport )    // Initialise the totals arrays and determine whether any fields
 if aReport[ i, PR_FLD_TOT ]    // require totals.
  totals := TRUE

 endif
 sub_sub_tot[ i ] := 0.0
 sub_tot[ i ] := 0.0
 tot[ i ] := 0.0

next

if empty( group_by )
 grp_code := { || '' }

endif

if empty( sub_group_by )
 sub_code := { || '' }

endif

if empty( forcond )
 bForCondition := { || .t. }

else
 bForCondition := { || &( forcond ) }

endif

if empty( whilecond )
 bWhileCondition := { || Pinwheel() }

else
 bWhileCondition := { || &( 'Pinwheel() .and. ' + whilecond ) }

endif

PageHead2( oPrinter, aReport, report_name, page_number, toScreen, page_width )
page_number++
dbsetfilter( bForCondition )
cont := eval( bWhileCondition )
while !eof() .and. cont
 code := eval( grp_code )
 if eval( bForCondition )
  if !empty( group_by ) 
   if !toScreen
    oPrinter:NewLine()
    oPrinter:NewLine()
    oPrinter:SetColor( RGB_BLUE )
    oPrinter:textout( '** ' + eval( grp_head ) )
    oPrinter:SetColor( RGB_BLACK )

   else
    oPrinter:Write( CRLF+CRLF+'** ' + eval( grp_head ) )

   endif

  endif

  while !eof() .and. eval( grp_code ) == code .and. cont
   scode := eval( sub_code )
   if eval( bForCondition )
    if !empty( sub_group_by )
     if !toScreen
      oPrinter:newline()
      oPrinter:newline()
      oPrinter:SetColor( RGB_MAGENTA )
      oPrinter:textout( '* '+eval( sub_head ) )
      oPrinter:SetColor( RGB_BLACK )

     else
      oPrinter:Write(  CRLF+'* '+eval( sub_head ) )

     endif

    endif

    while !(eof()) .and. eval( sub_code ) == scode .and. eval( grp_code ) == code .and. cont
     if !msummary .and. eval( bForCondition )
// Build an array of fields to be printed

      a := {}
      fldrec := {}

      for i := 1 to len( aReport )
       fld := eval( { || &( aReport[ i, PR_FLD_EXPR ] ) } )
       if valtype( fld ) != "C"
        aadd( fldrec, { fld } )

       else
        fld := alltrim( fld )
        if len( fld ) > aReport[ i, PR_FLD_LEN ]  // Is the field longer than the allocated length
         done := FALSE
         while !done
          t := backspace( aReport[ i, PR_FLD_LEN ], fld )   // Backspace finds a space to break a string at
          if ( len( fld ) > aReport[ i, PR_FLD_LEN ] )
           aadd( a, substr( fld, 1, t ) )

          else
           aadd( a, fld )
           done := TRUE

          endif
          fld := substr( fld, t+1 )

         enddo
         aadd( fldrec, a )
         a:= {}

        else
         aadd( fldrec, { fld } )

        endif

       endif

      next

// Ok print the field records here
      done := TRUE
      pos := 1
      for i := 1 to len( fldrec )
       if Pos = 1
        if !toScreen
         oPrinter:NewLine()

        else
         oPrinter:Write( CRLF )

        endif

       else
        if !toScreen
         oPrinter:setpos( pos * oPrinter:CharWidth )

        else
        //  oPrinter:Write( space( pos ) - len(  )

        endif

       endif

       if valtype( fldrec[ i, 1 ] ) = "N"
        sOut := padl( str( fldrec[i,1], sl(aReport,i), aReport[ i,PR_FLD_DEC]), sl(aReport,i) )

       else
        sOut := padr( fldrec[ i, 1 ], aReport[ i, PR_FLD_LEN ] )

       endif

       if !toScreen
        oPrinter:textOut( sOut )

       else
        oPrinter:Write( sOut )

       endif

       pos += sl( aReport, i ) + 1

       if len( fldrec[i] ) > 1
        done := FALSE   // Determine whether we need to run the loop below 

       endif            // to print columns on subsequent lines.

      next
      if !toScreen
       prin := TRUE
       z := 2
       while !done
        prin := FALSE
        for i := 1 to len(fldrec)
         if len(fldrec[i]) >= z
          prin := TRUE

         endif

        next
        if !prin
         done := TRUE

        else
         if toScreen
          oPrinter:Write( CRLF )

         else
          oPrinter:NewLine()

         endif

         pos := 1
         for i := 1 to len(fldrec)
          if len(fldrec[i]) >= z
           if PageEject2( oPrinter, toScreen )
            PageHead2( oPrinter, aReport, report_name, page_number, toScreen, page_width )
            page_number ++

           endif
           if !toScreen
            oPrinter:SetPos( pos * oPrinter:CharWidth )
            oPrinter:TextOut( padr( fldrec[i,z], aReport[i,PR_FLD_LEN] ) )

           else
            oPrinter:Write( padr( fldrec[i,z], aReport[i,PR_FLD_LEN] ) )

           endif

          endif
          pos += sl(aReport,i) + 1

         next

        endif
        z++

       enddo  // Done

      endif   // to Screen

     endif

     if PageEject2( oPrinter, toScreen,  )
      PageHead2( oPrinter, aReport, report_name, page_number, toScreen, page_width )
      page_number ++

     endif

     if totals .and. eval(bForCondition)
      for i := 1 to len(aReport)
       if aReport[i,PR_FLD_TOT]
        sub_sub_tot[i] += eval({||&(aReport[i,1])})

       endif

      next

     endif
     dbskip()
     cont := eval(bWhileCondition)
     if empty(sub_group_by)
      exit

     endif

    enddo // Sub group

    if totals
     if !empty( sub_group_by )
      if !toScreen
       oPrinter:NewLine()
       oPrinter:TextOut( '* Subsubtotal *' )

      else
	    oPrinter:NewLine()
        oPrinter:Write( '* Subsubtotal *' )

      endif

     endif
     pos := 1
     for i := 1 to len(aReport)
      if aReport[ i, PR_FLD_TOT ]
       if !empty(sub_group_by)
        if !toScreen
         oPrinter:setpos( pos * oPrinter:CharWidth )
         oPrinter:TextOut( padl(alltrim(str(sub_sub_tot[i],sl(aReport,i),aReport[i,PR_FLD_DEC])),sl(aReport,i)) )

        else
         oPrinter:Write( padl(alltrim(str(sub_sub_tot[i],sl(aReport,i),aReport[i,PR_FLD_DEC])),sl(aReport,i)) )

        endif

       endif
       sub_tot[i] += sub_sub_tot[i]

      endif
      pos += sl(aReport,i) + 1

     next
     afill(sub_sub_tot,0.0)

    else

     if !empty(sub_group_by)
      oPrinter:NewLine()

     endif

    endif // totals
       
    if PageEject2( oPrinter, toScreen )
     PageHead2( oPrinter, aReport, report_name, page_number, toScreen, page_width )
     page_number ++

    endif

   else
    dbskip()
    cont := eval( bWhileCondition )

   endif // eval( codeblock )
   if empty(group_by)
    exit

   endif

  enddo // Group By
  if totals
   if !empty( group_by )
    sOut := '** Subtotal **'
    if !toScreen
     oPrinter:NewLine()
     oPrinter:SetColor( RGB_GREEN )
     oPrinter:TextOut( sOut )

    else
     oPrinter:Write( CRLF + sOut + CRLF )

    endif

   endif
   pos := 1
   nPos := 0
   for i := 1 to len( aReport )
    nPos = sl( aReport, i )
    sOut := padl( alltrim( str( sub_tot[ i ], nPos, aReport[ i, PR_FLD_DEC ] ) ), nPos )
    if aReport[ i, PR_FLD_TOT ]
     if !toScreen
      oPrinter:Setpos( pos * oPrinter:CharWidth )
      oPrinter:TextOut( sOut )

     else
      oPrinter:Write( sOut )

     endif
     tot[i] += sub_tot[ i ]

    else
     if toScreen
      oPrinter:Write( space( nPos ) ) // Need to keep the cursor moving outwards

     endif

    endif

    pos += sl( aReport, i ) + 1

   next

   afill( sub_tot, 0.0 )

   if !toScreen
    oPrinter:SetColor( RGB_BLACK )

   endif

  else
   if !empty(group_by)
    if !toScreen
     oPrinter:NewLine()

    else
     oPrinter:Write( CRLF )

    endif
   endif
  endif // totals

 else
  dbskip()
  cont := eval( bWhileCondition )

 endif // eval( codeblock )

 if PageEject2( oPrinter, toScreen )
  PageHead2( oPrinter, aReport, report_name, page_number, toScreen, page_width )
  page_number ++

 endif

enddo
if totals
 if !toScreen
  oPrinter:NewLine()
  oPrinter:NewLine()
  oPrinter:SetColor( RGB_RED )
  oPrinter:TextOut( '*** Grand Totals ***' )
 else
  oPrinter:Write( CRLF + CRLF + '*** Grand Totals ***' + CRLF )

 endif

 pos := 1
 nPos := 0
 for i := 1 to len( aReport )
  nPos = sl( aReport, i )
  sOut := padl( alltrim( str( tot[ i ], nPos, aReport[ i, PR_FLD_DEC ] ) ), nPos )
  if aReport[ i, PR_FLD_TOT ]
   if !toScreen
    oPrinter:Setpos( pos * oPrinter:CharWidth )
    oPrinter:TextOut( sOut )

   else
    oPrinter:Write( sOut )

   endif

  else
   if toScreen
    oPrinter:Write( space( nPos ) ) // Need to keep the cursor moving outwards

   endif

  endif

  pos += sl( aReport, i ) + 1 

 next

endif // totals
dbclearfilter()
if toScreen
 oShell := CreateObject( "Wscript.Shell" )
 oShell:Exec( "notepad " + cFile )

else
 oPrinter:endDoc()
 oPrinter:Destroy()

endif

return

*

Function PageHead2( oPrinter, aReport, report_name, page, toScreen, page_width )
local a := dtoc( Bvars( B_DATE ) )
local b := time()+" Page "+Ns(page)
local i, pos, pass, hd, padblock
local sOut, nColWidth := 0, nPad, nTotWidth

default toScreen to FALSE

report_name := trim( report_name )

nTotWidth := 0                  // trying to figure out how wide the report is for the on screen stuff
for i := 1 to len( aReport )
 nTotWidth += sl( aReport,i )   // SL adds the spaces between columns

next

nTotWidth = max( nTotWidth, page_width )

if report_name != nil
 if !toScreen
  oPrinter:NewLine()
  oPrinter:TextOut( BPOSCUST )
  oprinter:setpos( (oPrinter:maxcol - len(a) ) * oPrinter:CharWidth )
  oPrinter:TextOut( a )
  oPrinter:NewLine()
  oPrinter:TextOut( report_name )
  oprinter:setpos( (oPrinter:maxcol - len(b) ) * oPrinter:CharWidth )
  oPrinter:TextOut( b )

 else
  oPrinter:Write( BPOSCUST + space( nTotWidth - len( BPOSCUST ) - len(a) ) + a + CRLF )
  oPrinter:Write( report_name + space( nTotWidth - len( report_name ) - len(b) ) + b + CRLF )

 endif

endif

if !toScreen
 oPrinter:NewLine()
 oPrinter:TextOut( replicate( DBL_ULINE, oPrinter:maxcol() ) )

else
 oPrinter:Write( replicate( DBL_ULINE, nTotWidth ) )

endif

// Print the Column Headings
for pass := 1 to 2              // Need two passes for the 2 lines
 for i := 1 to len( aReport )   // Each field in the report
  if i = 1                      // First field so a new line is required
   pos := 1
   if !toScreen
    oPrinter:NewLine()

   else
    oPrinter:Write( CRLF )

   endif

  else
   if !toScreen
    oprinter:setpos( pos * oPrinter:CharWidth )

   endif

  endif

  hd := aReport[ i, PR_FLD_NAME ]
  if valtype( eval( { || &( aReport[ i, PR_FLD_EXPR ] ) } ) ) = "N"
   padblock := {|string,i|padl(string,i)}

  else
   padblock := {|string,i|padr(string,i)}

  endif

  nPad := sl( aReport, i )

  if at( ';', hd ) = 0
   if pass = 1
    sOut := eval( padblock, hd, nPad )

   else
     sOut = space( nPad )

   endif

  else
   if pass = 1
    sOut := eval( padblock, substr( hd, 1, at(';', hd )-1 ), nPad )

   else
     sOut := eval( padblock, substr( hd, at(';', hd )+1, len( hd ) ), nPad )

   endif

  endif

  if !toScreen
   oPrinter:textOut( sOut )

  else
   oPrinter:Write( sOut )

  endif
  sOut := ''
  pos += sl(aReport,i) + 1

 next                           // i

next                            // pass

return nil

*

Function PageEject ( length, top, bottom )
local need_eject := ( ( prow() + bottom ) > length )
if need_eject
  eject
  setprc(0,0)
  @ prow() + top, 0 say ""

endif
return need_eject

*

Function PageEject2 (  oPrinter, toScreen )
local need_eject := FALSE
default toScreen to FALSE
if !toScreen
 if oPrinter:PRow() > oPrinter:MaxRow() - 10  // Could use "oPrinter:NewPage()" to start a new page
  oPrinter:NewPage()
  need_eject = TRUE

 endif
endif

return need_eject

* Formating function used by Reporter to determine field lengths

function sl( arr, i )
local nlength
if ( arr[ i, PR_FLD_DEC ] != 0 ) .and. ( valtype( eval( { || &( arr[ i, PR_FLD_EXPR ] ) } ) ) = "N" )
 nlength := arr[i,PR_FLD_LEN]+arr[i,PR_FLD_DEC]+1

else
 nlength := arr[i,PR_FLD_LEN ]

endif
return nlength

*

function break_string( fld, size )
local rec:={}, done:= FALSE, t
fld := alltrim( fld )
if len(fld) > size
 while !done 
  t := backspace(size,fld)
  if ( len(fld) > size )
   aadd(rec,substr(fld,1,t))
  else
   aadd(rec,fld)
   done := TRUE
  endif 
  fld := substr(fld,t+1)
 enddo

else
 aadd( rec, fld )

endif
return (rec)

*

Function EndPrint ( )
eject
set printer to
return nil

*

function print_swap
local pnm
return pnm

*

function Pitch10
local mprinter, mrow, mcol, ocons := set( _SET_CONSOLE, FALSE )
local pnm := val( substr( lvars( L_PRINTER ), 4, 1 ) )
local mval := ''
mprinter := set( _SET_PRINTER, TRUE )
mrow := prow()
mcol := pcol()
if empty( mval )
 ?? PITCH_10
else
 ?? mval
endif
setprc( mrow, mcol )
set( _SET_PRINTER, mprinter )
set( _SET_CONSOLE, ocons )
return ''

*

function Pitch12
local mprinter, mrow, mcol, ocons := set( _SET_CONSOLE, FALSE )
local pnm := val( substr( lvars( L_PRINTER ), 4, 1 ) )
local mval := ''
mprinter := set( _SET_PRINTER, TRUE )
mrow := prow()
mcol := pcol()
if empty( mval )
 ?? PITCH_12
else
 ?? mval
endif
setprc( mrow, mcol )
set( _SET_PRINTER, mprinter )
set( _SET_CONSOLE, ocons )
return ''

*

function Pitch17
local mprinter, mrow, mcol, ocons := set( _SET_CONSOLE, FALSE )
local pnm := val( substr( lvars( L_PRINTER ), 4, 1 ) )
local mval := ''
mprinter := set( _SET_PRINTER, TRUE )
mrow := prow()
mcol := pcol()
if empty( mval )
 ?? PITCH_17
else
 ?? mval
endif
setprc( mrow, mcol )
set( _SET_PRINTER, mprinter )
set( _SET_CONSOLE, ocons )
return ''

*

Function PageHead( oPrinter, rptName, page_width, page, col_head1, col_head2 )
local a := dtoc( date() ) + " "
local b := time() + " Page " + Ns( page )
local mlicense := BPOSCUST

if rptName != nil
 oPrinter:TextOut( mlicense )
 oPrinter:SetPos( (page_width -len(a)) * oPrinter:CharWidth )
 oPrinter:TextOut( a )
 oPrinter:NewLine()
 oPrinter:TextOut( rptName )
 oPrinter:SetPos( (page_width -len(b)) * oPrinter:CharWidth )
 oPrinter:TextOut( b )

endif

if col_head1 != nil
  oPrinter:NewLine()
  oPrinter:setPos(1)
  oPrinter:textOut( col_head1 )

endif

if col_head2 != nil
  oPrinter:NewLine()
  oPrinter:setPos(1)
  oPrinter:textOut( col_head2 )

endif

oPrinter:newline()
oPrinter:textOut( replicate( chr( 196 ), page_width ) )

return nil

