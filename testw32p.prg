/** @package 

        testw32p.prg
     
      Last change: APG 9/08/2008 6:12:56 PM
*/
#define FORM_A4 9

#define PS_SOLID            0

#define RGB( nR,nG,nB )   ( nR + ( nG * 256 ) + ( nB * 256 * 256 ) )

#define BLACK          RGB( 0x0 ,0x0 ,0x0  )
#define BLUE           RGB( 0x0 ,0x0 ,0x85 )
#define GREEN          RGB( 0x0 ,0x85,0x0  )
#define CYAN           RGB( 0x0 ,0x85,0x85 )
#define RED            RGB( 0x85,0x0 ,0x0  )
#define MAGENTA        RGB( 0x85,0x0 ,0x85 )
#define BROWN          RGB( 0x85,0x85,0x0  )
#define WHITE          RGB( 0xC6,0xC6,0xC6 )

FUNCTION testw32prn()
  LOCAL nPrn:=1, cBMPFile:= SPACE( 40 )
  LOCAL aPrn:= GetPrinters()
  LOCAL GetList:= {}
  CLS
  IF EMPTY(aPrn)
    Alert("No printers installed - Cannot continue")
    QUIT
  ENDIF
  DO WHILE !EMPTY(nPrn)
    CLS
    @ 0,0 SAY 'Win32Prn() Class test program. Choose a printer to test'
    @ 1,0 SAY 'Bitmap file name' GET cBMPFile PICT '@!K'
    READ
    @ 2,0 TO maxRow(),maxCol()
    nPrn:= ACHOICE(3,1,maxRow()-1,maxCol()-1,aPrn,.T.,,nPrn)
    IF !EMPTY(nPrn)
        PrnTest(aPrn[nPrn], cBMPFile)
    ENDIF
  ENDDO
  RETURN(NIL)

STATIC FUNCTION PrnTest(cPrinter, cBMPFile)
  LOCAL oPrinter:= Win32Prn():New(cPrinter), aFonts, x, nColFixed, nColTTF, nColCharSet
  oPrinter:Landscape:= .F.
  oPrinter:FormType := FORM_A4
  oPrinter:Copies   := 1
  IF !oPrinter:Create()
    Alert("Cannot Create Printer")
  ELSE
    IF !oPrinter:startDoc('Win32Prn(Doc name in Printer Properties)')
      Alert("StartDoc() failed")
    ELSE
      oPrinter:SetPen(PS_SOLID, 1, RED)
      oPrinter:Bold(800)
      oPrinter:TextOut(oPrinter:PrinterName+': MaxRow() = '+STR(oPrinter:MaxRow(),4)+'   MaxCol() = '+STR(oPrinter:MaxCol(),4))
      oPrinter:Bold(0)     // Normal
      oPrinter:NewLine()
      oPrinter:TextOut('   Partial list of available fonts that are available for OEM_')
      oPrinter:NewLine()
      oPrinter:UnderLine(.T.)
      oPrinter:Italic(.T.)
//      oPrinter:SetFont('Courier New',7,{3,-50})  // Compressed print
      nColFixed:= 40 * oPrinter:CharWidth
      nColTTF  := 48 * oPrinter:CharWidth
      nColCharSet  := 60 * oPrinter:CharWidth
      oPrinter:TextOut('FontName')
      oPrinter:SetPos(nColFixed)
      oPrinter:TextOut('Fixed?')
      oPrinter:SetPos(nColTTF)
      oPrinter:TextOut('TrueType?')
      oPrinter:SetPos(nColCharset)
      oPrinter:TextOut('CharSet#',.T.)
      oPrinter:NewLine()
      oPrinter:Italic(.F.)
      oPrinter:UnderLine(.F.)
      aFonts:= oPrinter:GetFonts()
      oPrinter:NewLine()
      FOR x:= 1 TO LEN(aFonts) STEP 2
        oPrinter:CharSet(aFonts[x,4])
        IF oPrinter:SetFont(aFonts[x,1])       // Could use "IF oPrinter:SetFontOk" after call to oPrinter:SetFont()
          IF oPrinter:FontName == aFonts[x,1]  // Make sure Windows didn't pick a different font
            oPrinter:TextOut(aFonts[x,1])
            oPrinter:SetPos(nColFixed)
            oPrinter:TextOut(IIF(aFonts[x,2],'Yes','No'))
            oPrinter:SetPos(nColTTF)
            oPrinter:TextOut(IIF(aFonts[x,3],'Yes','No'))
            oPrinter:SetPos(nColCharSet)
            oPrinter:TextOut(STR(aFonts[x,4],5))
            oPrinter:SetPos(oPrinter:LeftMargin, oPrinter:PosY + (oPrinter:CharHeight*2))
            IF oPrinter:PRow() > oPrinter:MaxRow() - 10  // Could use "oPrinter:NewPage()" to start a new page
              oPrinter:NewPage()
          ENDIF
          ENDIF
        ENDIF
        oPrinter:Line(0, oPrinter:PosY+5, 2000, oPrinter:PosY+5)
      NEXT x
      oPrinter:SetFont('Lucida Console',8,{3,-50})  // Alternative Compressed print
      oPrinter:CharSet(0)  // Reset default charset
      oPrinter:Bold(800)
      oPrinter:NewLine()
      oPrinter:TextOut('This is on line'+STR(oPrinter:Prow(),4)+', Printed bold, ' )
      oPrinter:TextOut(' finishing at Column: ')
      oPrinter:TextOut(STR(oPrinter:Pcol(),4))
      oPrinter:SetPrc(oPrinter:Prow()+3, 0)
      oPrinter:Bold(0)
      oPrinter:TextOut("Notice: UNDERLINE only prints correctly if there is a blank line after",.T.)
      oPrinter:TextOut("        it. This is because of ::LineHeight and the next line",.T.)
      oPrinter:TextOut("        printing over top of the underline. To avoid this happening",.T.)
      oPrinter:TextOut("        you can to alter ::LineHeight or use a smaller font")
      oPrinter:NewLine()
      oPrinter:NewLine()
      oPrinter:SetFont('Lucida Console',18, 0)  // Large print
      oPrinter:SetColor( GREEN )
      oPrinter:TextOut("Finally some larger print")
      oPrinter:Box(  0, oPrinter:PosY+100, 100, oPrinter:PosY+200)
      oPrinter:Arc(200, oPrinter:PosY+100, 300, oPrinter:PosY+200)
      oPrinter:Ellipse(400, oPrinter:PosY+100, 500, oPrinter:PosY+200)
      oPrinter:FillRect(600, oPrinter:PosY+100, 700, oPrinter:PosY+200, RED)

//    To print a barcode;
//    Replace 'BCod39HN' with your own bar code font or any other font
//      oPrinter:TextAtFont( oPrinter:MM_TO_POSX( 30 ) , oPrinter:MM_TO_POSY(60 ), '1234567890', 'BCod39HN', 24, 0 )
//
      PrintBitMap( oPrinter, cBMPFile )

      oPrinter:EndDoc()
    ENDIF
    oPrinter:Destroy()
  ENDIF
  RETURN(NIL)


procedure PrintBitMap( oPrn, cBitFile )
  LOCAL oBMP

  IF EMPTY( cBitFile )
    *
  ELSEIF !FILE( cBitFile )
    Alert( cBitFile + ' not found ' )
  ELSE
    oBMP:= Win32BMP():new()
    IF oBmp:loadFile( cBitFile )

      oBmp:Draw( oPrn,  { 200,200, 2000, 1500 } )

      // Note: Can also use this method to print bitmap
      //   oBmp:Rect:= { 200,2000, 2000, 1500 }
      //   oPrn:DrawBitMap( oBmp )

    ENDIF
    oBMP:Destroy()
  ENDIF
  RETURN

