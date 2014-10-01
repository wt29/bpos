/*

     BPOS System Header File

      Last change:  TG   13 Jan 2012    4:44 pm

v1.17 - Backup fixed, colours fixed. More closely aligned with WinRent
v1.18 - Added bits to support bookshops!
v1.19 - Bit of a slog to get invoices - and then everything else printing using Win32prn
v1.20 - Quotes subsystem, ErrorSys revisons
v1.21 - Last of the converted Forms. Errorsys now writes files into errors
v1.22 - Fixed the stocktake forms - did some work around the GST printing problems
v1.23 - Work around Invoices and GST
v1.24 - Current Sales File print


*/

#include "inkey.ch"
#include "setcurs.ch"

// #include "wvtgui.ch"

#define __GTWVW__

#define BUILD_NO "1.24"
#define DEVELOPER_PHONE "+61 2 4751 8497"
#define DEVELOPER_FAX "+61 2 4751 8479"
#define SUPPORT_FAX "No Number - use email"
#define SUPPORT_EMAIL "tglynn@hotmail.com"
#define SUPPORT_PHONE "+61 2 4751 8497"
#define EXECUTABLE "bpos.exe"
#define SYSNAME 'BPOS'
#define DEVELOPER 'Bluegum Software'

// BPOS Customer Information

#define THELOOK
// #define DUCKWORTHS

#ifdef THELOOK
 #define EPSON
 #define BPOSCUST "The Look"

#endif

#ifdef DUCKWORTHS
 #define EPSON
 #define BPOSCUST "Duckworths"
 #define IS_BOOKSHOP
 #define CONTACT_NO  "02 9602 7377"

#endif

#ifdef DEMO
 #define BPOSCUST 'Demonstration'

#endif
 
#ifndef BPOSCUST
 #define BPOSCUST 'Development'

#endif


#ifdef IS_BOOKSHOP
 #define STORETYPE 'Bookshop'
 #define STORENAMEDESC 'Bookshop'
 #define ITEM_DESC 'Title'
 #define ID_DESC 'ISBN'
 #define DESC_DESC 'Title'                    // Odd name - the "description" of the description field
 #define ALT_DESC 'Author'
 #define BRAND_DESC 'Imprint'
 #define PACKAGE_DESC 'Binding'
 #define ILLUSTRATOR_DESC 'Illustrator'
 #define PLU_DESC 'ISBN'

#else
 #define STORETYPE 'Store'
 #define STORENAMEDESC 'Store Name'
 #define ITEM_DESC 'Items'
 #define ID_DESC 'Code'
 #define DESC_DESC 'Description'
 #define ALT_DESC 'Alt. Descrpt'
 #define BRAND_DESC 'Brand'
 #define PACKAGE_DESC 'Package'
 #define ILLUSTRATOR_DESC '2nd Description'
 #define PLU_DESC 'PLU'
 
#endif

#define MEMO_EXT 'fpt'
#define NEW_DBF_EXT '.bps'

#define FORM_A4 9

#define PS_SOLID            0

#define RGB( nR,nG,nB )   ( nR + ( nG * 256 ) + ( nB * 256 * 256 ) )

#define RGB_BLACK          RGB( 0x0 ,0x0 ,0x0  )
#define RGB_BLUE           RGB( 0x0 ,0x0 ,0x85 )
#define RGB_GREEN          RGB( 0x0 ,0x85,0x0  )
#define RGB_CYAN           RGB( 0x0 ,0x85,0x85 )
#define RGB_RED            RGB( 0x85,0x0 ,0x0  )
#define RGB_MAGENTA        RGB( 0x85,0x0 ,0x85 )
#define RGB_BROWN          RGB( 0x85,0x85,0x0  )
#define RGB_WHITE          RGB( 0xC6,0xC6,0xC6 )

#define NEWLINE        .t.
#define NONEWLINE      .f.

#define CRLF chr( 13 ) + chr( 10 )
#define CR chr( 13 )
#define FF chr( 12 )
#define LF chr( 10 )   
#define BELL chr( 7 )
#define TRUE .t.
#define FALSE .f.
#define YES .t.
#define NO .f.
#define SHARED .f.
#define EXCLUSIVE .t.
#define SOFTSEEK .t.
#define NOEOF .f.
#define NEW .t.
#define OLD .f.
#define NOALIAS nil
#define UNLOCK .t.    // placeholder for Del_rec unlock function
#define NO_EJECT .t.  // placeholder for EndPrint Function
#define NOINTERUPT .t.
#define UNIQUE .t.
#define ALLOW_WILD .t.
#define GO_TO_EDIT .t.
#define WAIT_FOREVER 0   // Used in Inkey - seems prettier then inkey( 0 )

#define VBTRUE          -1
#define VBFALSE          0
#define VBUSEDEFAULT    -2

// Some Color Defines
#define C_NORMAL  1
#define C_INVERSE 2
#define C_BRIGHT  3
#define C_MAUVE   4
#define C_GREY    5
#define C_YELLOW  6
#define C_GREEN   7
#define C_CYAN    8
#define C_BLACK   9

#define C_BACKGROUND 'BG'

// Colour defines for Tbrowse objs
//#define TB_COLOR  'GR+/' + C_BACKGROUND + ', N/W'
#define TB_COLOR  'W/' + C_BACKGROUND + ', N/W'
/* W/R, +GR/R, N/BG, +W/BG, W/RB, +GR/RB, W/B, +W/B, W/G, +GR/G, R/W, B/W, W/GR, +GR/GR' */

#define HEADSEP 'Í'
#define COLSEP '³'

#define ULINE  chr(95)

#define CRYPTKEY 'charlotte89'   // Should work if ever this is needed now uses HB_CRYPT

#ifdef SYSTEM_OPTIONS
 #define SECURITY           // Turns on operator logons
 #define SERIAL_NUMBERS     // Can record serial numbers for stock items

#endif

#define SYSTEM_MAX_RECS 100000   //How many records to keep in the audit trail

// Printing Bits
#define BIGCHARS chr(27) + chr(33) + chr(48)
#define VERYBIGCHARS chr(27) + chr(33) + chr(49)
#define NOBIGCHARS chr(27) + chr(33) + chr(0)
#define SCRIPTCHARS chr(27) + chr(33) + chr(50)

#define PAPERCUT chr(29) + "V" + chr(66) + chr(0)                            // Used in S_CASH

#define ITALICS chr(27)+chr(37)+'G'
#define NOITALICS chr(27)+chr(37)+'H'

#define BOLD chr(27)+'E'
#define NOBOLD chr(27)+'F'

#define DRAWLINE  chr(08)                   // Irrevant for ESC/POS but useful for Win32Prn
#define PRN_GREEN 'PRN_GREEN'
#define PRN_BLACK 'PRN_BLACK'
#define PRN_RED   'PRN_RED'

#define P_BIGFONTSIZE           24
#define P_VERYBIGFONTSIZE       36
#define P_BIGFONTWIDTH          100    // Pixels?

// This doesn't work ---- > #define RPT_SPACE "{ 'space(1)', ' ', 1, 0, .f. }"

#define CONDENSE .t.

// EPSON seems to be the default docket printer emulation
#ifdef EPSON
 #define PITCH_17 chr(27)+chr(103)
 #define PITCH_10 chr(27)+chr(80)
 #define PITCH_12 chr(27)+chr(77)

#else
 #define PITCH_17 chr(15)
 #define PITCH_12 chr( 27 ) + chr( 77 )
 #define PITCH_10 chr(18)
 #define DRAFT_PRINT chr(27)+'x'+chr(0)
 #define QUALITY_PRINT chr(27)+'x'+chr(1)

#endif

#xcommand DEFAULT <v1> TO <x1> [, <vn> TO <xn> ]                        ;
          =>                                                            ;
          IF <v1> == NIL ; <v1> := <x1> ; END                           ;
          [; IF <vn> == NIL ; <vn> := <xn> ; END ]
  
// Set up the lengths of various fields - Note these values are used when 
//  the DB tables are first created
#ifndef ID_CODE_LEN
 #define ID_CODE_LEN 13
#endif

#ifndef ID_ENQ_LEN    // field length for enquiry
 #define ID_ENQ_LEN 13
#endif

#ifndef DESC_LEN
 #define DESC_LEN 60
#endif

#ifndef ALT_DESC_LEN
 #define ALT_DESC_LEN 25
#endif

#ifndef SUPP_CODE_LEN
 #define SUPP_CODE_LEN 4
#endif

#ifndef DEPT_CODE_LEN
 #define DEPT_CODE_LEN 3 

#endif

#ifndef BRAND_CODE_LEN
 #define BRAND_CODE_LEN 6

#endif

#ifndef CUST_KEY_LEN
 #define CUST_KEY_LEN 10

#endif

#ifndef NEW_CUST_KEY_PICT
 #define NEW_CUST_KEY_PICT '!!!!!'

#endif

#ifndef CUST_KEY_PICT
 #define CUST_KEY_PICT '!!!!!99999'

#endif

#ifndef DISC_PICT
 #define DISC_PICT '999.9'

#endif

#ifndef BRANCH_CODE_LEN
 #define BRANCH_CODE_LEN 2

#endif

#ifndef OPERATOR_CODE_LEN
 #define OPERATOR_CODE_LEN 3

#endif

#ifndef PHONE_NUM_LEN
 #define PHONE_NUM_LEN 15

#endif

#ifndef PO_NUM_LEN
 #define PO_NUM_LEN 6
 #define PO_NUM_PICT '999999'

#endif

#ifndef INV_NUM_LEN   // Used for Invoices, Credit Notes, Quotes, Approvals etc
 #define INV_NUM_LEN 6
 #define INV_NUM_PICT '999999'

#endif
 
#ifndef PRICE_PICT
 #define PRICE_PICT '9999.99'

#endif

#ifndef TOTAL_PICT
 #define TOTAL_PICT '99999.99'

#endif
 
#ifndef QTY_PICT
 #define QTY_PICT '9999'

#endif

#ifndef QTY_LEN
 #define QTY_LEN 5

#endif

#ifndef SALES_CODE_LEN
 #define SALES_CODE_LEN 2

#endif

#ifndef SALESREP_CODE_LEN
 #define SALESREP_CODE_LEN 2

#endif

#ifndef SEMESTER_CODE_LEN
 #define SEMESTER_CODE_LEN 3
#endif
 
#ifndef MAXSCAN
 #define MAXSCAN 9000

#endif

#ifndef MAXNEGSTOCK    // This is how far we will let negative stock go - used in invoicing
 #define MAXNEGSTOCK -999

#endif
 
#ifndef CREDPICT
 #define CREDPICT '9999999999999999 !!! 99/99'

#endif

#ifndef AVR_COST_BASIS
 #define LAST_COST_BASIS
 #define COST_FIELD cost_price

#endif

#define MASTAVAIL master->onhand-master->held-master->approval

#ifndef SEARCH_KEY_LEN
 #define SEARCH_KEY_LEN 20

#endif
 
#ifndef GST_RATE
 #define GST_RATE 10

#endif
 
#ifndef CURRENCY
 #define CURRENCY 'AUS$'

#endif
 
// Some defines for easy handling of index relations
#define NATURAL         ''
#define BY_ID           'ID'
#define BY_DESC         'desc'
#define BY_ALTDESC      'alt_desc'
#define BY_DEPARTMENT   'department'
#define BY_SUPPLIER     'supplier'
#define BY_CATALOG      'catalog'
#define BY_KEY          'key'
#define BY_NUMBER       'number'
#define BY_SUPP_BY_ID   'suppid'
#define BY_SOURCE       'source'
#define BY_NOTFOUND     'notfound'
#define BY_ORDNO        'ordno'
#define BY_NAME         'name'
#define BY_STORE        'store'
#define BY_CODE         'code'

#define NO_APPE_MODE           0
#define APPE_SP_BY_KEY         1
#define APPE_SP_BY_NUMBER      2
#define APPE_AP_BY_KEY         3
#define APPE_AP_BY_NUMBER      4
#define APPE_AP_BY_FOREIGN_KEY 5
#define APPE_FROM_BOOKLIST     6
#define APPE_BY_CATEGORY       7
#define APPE_BY_PROFORMA       8
#define APPE_FROM_PDT          9

// BPOS Config variables - direct map to the BVARS file
#define B_NAME        1
#define B_SERIAL      2
#define B_ADDRESS1    3
#define B_ADDRESS2    4
#define B_SUBURB      5
#define B_PHONE       6
#define B_FAX         7
#define B_SAN         8
#define B_ACN         9
#define B_POINST      10
#define B_GREET       11
#define B_COUNTRY     12
#define B_WP          13
#define B_WPTYPE      14
#define B_STD_DISC    15
#define B_DISC1       16
#define B_DISC2       17
#define B_DISC3       18
#define B_DISC4       19
#define B_DATE        20
#define B_ST1         21
#define B_ST2         22
#define B_ST3         23
#define B_ST4         24
#define B_GST_RATE    25
#define B_BCPTR       26
#define B_DOCKLN1     27
#define B_DOCKLN2     28
#define B_BARLINE1    29
#define B_BARLINE2    30
#define B_GST         31
#define B_GSTRATE     32
#define B_NUMSTORE    33
#define B_MTHCLEAR    34
#define B_STMESS1     35
#define B_STMESS2     36
#define B_STMESS3     37
#define B_SPECCOMM    38
#define B_LASTPER     39
#define B_PERLEN      40
#define B_BELLS       41
#define B_SPDOCK      42
#define B_SPECSLIP    43
#define B_SPDELE      44
#define B_SPADNO      45
#define B_SPECSTAND   46
#define B_SPLET       47
#define B_SPLETGROUP  48
#define B_SPMIN       49
#define B_LADOCK      50
#define B_LAPAY       51
#define B_LADELE      52
#define B_LACOMP      53
#define B_LACASH      54
#define B_ININ        55
#define B_INCR        56
#define B_INQTY       57
#define B_AUTOBACK    58
#define B_APNOTE      59
#define B_APQTY       60
#define B_POQTY       61
#define B_CREDCL      62
#define B_SPECLABE    63
#define B_BOOKLIST    64
#define B_REORDQTY    65
#define B_SALERET     66
#define B_OPENITEM    67
#define B_OPENCRED    68
#define B_AUTOCRED    69
#define B_NEWSORT     70
#define B_PROCOMM     71
#define B_STKRPT      72
#define B_SALECONS    73
#define B_CENTROUND   74
#define B_DIARY       75
#define B_PO1NAME     76
#define B_PO2NAME     77
#define B_PO3NAME     78
#define B_PO4NAME     79
#define B_PO5NAME     80
#define B_MATRIX      81
#define B_PICKSLIP    82
#define B_BRANCH      83
#define B_SUPERINDEX  84
#define B_DEPTORDR    85
#define B_CHKIMPR     86
#define B_CHKSTAT     87
#define B_CHKBIND     88
#define B_CHKCATE     89
#define B_PREPINV     90
#define B_SAN1        91
#define B_SAN2        92
#define B_MDISCCASH   93
#define B_MDISCCARD   94

// **TODO**
#define FIRST_PTR        4

// Node (workstation) variables - direct map to the NODES files
#define L_NODE           1
#define L_REGISTER       2
#define L_PRINTER        3
#define L_REPORT_NAME    4
#define L_BARCODE_NAME   5
#define L_INVOICE_NAME   6
#define L_DOCKET_NAME    7
#define L_F1             8
#define L_F1N            9
#define L_F1MARGIN      10
#define L_F2            11
#define L_F2N           12
#define L_F2MARGIN      13
#define L_F3            14
#define L_F3N           15
#define L_F3MARGIN      16
#define L_F4            17
#define L_F4N           18
#define L_F4MARGIN      19
#define L_F5            20
#define L_F5N           21
#define L_F5MARGIN      22
#define L_F6            23
#define L_F6N           24
#define L_F6MARGIN      25
#define L_F7            26
#define L_F7N           27
#define L_F7MARGIN      28
#define L_F8            29
#define L_F8N           30
#define L_F8MARGIN      31
#define L_F9            32
#define L_F9N           33
#define L_F9MARGIN      34
#define L_F10           35
#define L_F10N          36
#define L_F10MARGIN     37
#define L_DATE          38
#define L_CUST_NO       39
#define L_CDTYPE        40
#define L_AUTO_OPEN     41
#define L_CDPORT        42
#define L_DOCKET        43
#define L_COLATTR       44
#define L_BACKGR        45
#define L_SHADOW        46
#define L_GOOD          47
#define L_BAD           48
#define L_MEMORY        49
#define L_CUTTER        50
#define L_SPEED         51
#define L_SPACE         52
#define L_RES           53
#define L_MAXROWS       54
#define L_C1            55
#define L_C2            56
#define L_C3            57
#define L_C4            58
#define L_C5            59
#define L_C6            60
#define L_C7            61
#define L_C8            62
#define L_C9            63
#define L_COLOR         64
#define L_POZ           65
#define L_ONP           66

// X - Security defines 
#define X_SUPERVISOR    1
#define X_FILES         2
#define X_PURCHASE      3
#define X_SALES         4
#define X_UTILITY       5
#define X_DEBTORS       6
#define X_CREDITORS     7
#define X_GENERAL       8
#define X_REPORTER      9
#define X_STOCKTAKE    10
#define X_SALEVOID     11
#define X_CREDITNOTES  12
#define X_INVOICES     13
#define X_ADDFILES     14
#define X_EDITFILES    15
#define X_DELFILES     16
#define X_DEBTRANS     17
#define X_DEBREPS      18
#define X_DEBEOM       19
#define X_CASHDRAWER   20
#define X_DEBBALMOD    21
#define X_CREDTRANS    22
#define X_CREDREPS     23
#define X_CREDEOM      24
#define X_CREDBALMOD   25
#define X_SYSUTILS     26
#define X_SALESREPORTS 27
#define X_GLOBALS      28

#define SYSPATH        1       // Where to find - write files
#define HASGST         2       // Does this support GST
#define TEMPFILE       3       // Tempfile name - set up in BPOS.prg
#define TEMPFILE2      4       // Sometimes we need 2 temp files
#define MSUPP          5       // Carries the supplier code around
#define OPERCODE       6       // Operator logged on in Security System
#define CRE_OP_BAL     7       // Creditors opening Balance
#define CRE_AGE        8       // Last date of Creditors ageing
#define DEB_OP_BAL     9       // Debtors Opening Balance
#define DEB_AGE        10      // Last date of Debtors ageing
#define RETURNS_OFFSET 11      // The offset into the stkhist file of returns invoice number
#define SPFILE_NO      12      // Counter for spool files
#define SPFILE         13      // Current Spool file name
#define START_SCR      14      // Save the screen before startup here
#define OPERNAME       15      // Operator Name
#define IS_CONSIGNED   16      // Was last title looked up by consignment

// Strings for some basic printer functions
#define L_LPT1_10      2
#define L_LPT1_12      3  
#define L_LPT1_17      4  
#define L_LPT1_LQ      5  
#define L_LPT1_DR      6  
#define L_LPT2_10      7  
#define L_LPT2_12      8  
#define L_LPT2_17      9  
#define L_LPT2_LQ      10 
#define L_LPT2_DR      11 
#define L_LPT3_10      12 
#define L_LPT3_12      13 
#define L_LPT3_17      14 
#define L_LPT3_LQ      15 
#define L_LPT3_DR      16 
#define L_LPT4_10      17 
#define L_LPT4_12      18 
#define L_LPT4_17      19 
#define L_LPT4_LQ      20 
#define L_LPT4_DR      21 

// Windows defines
#define MB_OK                       0
#define MB_OKCANCEL                 1
#define MB_ABORTRETRYIGNORE         2
#define MB_YESNOCANCEL              3
#define MB_YESNO                    4
#define MB_RETRYCANCEL              5

#define MB_RET_OK                   1
#define MB_RET_YES                  6
#define MB_RET_NO                   7
// Eof - bpos.ch
