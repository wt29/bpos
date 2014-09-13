/** @package 

        Alias.prg
        
      Created: DOF 14/07/2008 10:40:27 PM
        Last change:  TG   19 Jul 2011    6:24 pm

*/

#include "bpos.ch"

proc alias
external padr
use master
use supplier new
enqobj := master->( tbrowseDb( 0, 0, 10, 10 ) )
enqobj:=tbrowsedb( 03,09, 21, 71 )
enqobj:colorspec := if( iscolor(), TB_COLOR, setcolor() )
enqobj:HeadSep := HEADSEP
enqobj:ColSep := COLSEP
enqobj:skipBlock:={|SkipCnt| AwSkipIt( SkipCnt, { || TRUE }, TRUE, 'master' ) }
enqobj:addcolumn( tbcolumnNew( 'desc', { || master->desc } ) )
enqobj:freeze := 1
mkey := 0
while mkey != K_ESC
 enqobj:forcestable()
 mkey := inkey(0)
 if mkey == K_DOWN
  enqobj:down()
 endif
 if mkey == K_UP
  enqobj:up()
 endif
enddo
return nil
*
Function Awskipit( nmove, mval, xkey, mdbf )
local nmoved
nmoved := 0
if nmove == 0 .or. lastrec() == 0
 ( mdbf )->( dbskip( 0 ) )
elseif nmove > 0 .and. recno() != lastrec() + 1
 while nmoved <= nmove .and. !eof() .and. eval( mval ) = xkey
 ( mdbf )->( dbskip( 1 ) )
  nmoved++
 enddo
 ( mdbf )->( dbskip( -1 ) )
 nmoved--
elseif nmove < 0
 while nmoved >= nmove .and. !bof() .and. eval( mval ) = xkey
 ( mdbf )->( dbskip( -1 ) )
  nmoved--
 enddo
 if !bof()
  ( mdbf )->( dbskip( 1 ) )
 endif
 nmoved++
endif
return ( nmoved )

