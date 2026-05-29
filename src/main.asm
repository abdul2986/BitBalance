; ========================= BIT BALANCE =========================
; FULL PROFESSIONAL ACCOUNTING + INVENTORY SYSTEM
; MASM32 SAFE VERSION
; ================================================================

.386
.model flat, stdcall
option casemap:none

include C:\masm32\include\windows.inc
include C:\masm32\include\user32.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\comctl32.inc
include C:\masm32\include\gdi32.inc
include C:\masm32\include\masm32.inc

includelib C:\masm32\lib\user32.lib
includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\comctl32.lib
includelib C:\masm32\lib\gdi32.lib
includelib C:\masm32\lib\masm32.lib

include resources.inc

WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD

AddTransaction PROTO
AddProduct PROTO
LoadRecordsFromFile PROTO
RefreshProductList PROTO
UpdateDashboard PROTO
LoadProductsFromFile PROTO
InsertReportItem PROTO
ClearInputs PROTO

; Macro for inline strings
CSTR macro text:VARARG
    LOCAL local_label
    .const
        local_label db text,0
    .code
    exitm <offset local_label>
endm

.const

EditClass      db "edit",0
ButtonClass    db "button",0
StaticClass    db "static",0
ComboClass     db "combobox",0
ListViewClass  db "SysListView32",0

MAX_PRODUCTS equ 100

.data

.data

icc INITCOMMONCONTROLSEX <SIZEOF INITCOMMONCONTROLSEX,\
ICC_LISTVIEW_CLASSES>

ClassName db "SentryClass",0
AppName db "Bit Balance",0
productsFile db "data\\products.txt",0
recordsFile db "data\\records.txt",0
newline db 13,10,0
comma db ",",0
headerTitle db "BIT BALANCE PROFESSIONAL ACCOUNTING SYSTEM",0

txtTransaction db "TRANSACTION",0
txtAddProduct db "ADD PRODUCT",0
txtManage db "MANAGE PRODUCTS",0
txtReports db "REPORTS",0

txtProduct db "Product",0
txtAccount db "Account No",0
txtPurpose db "Purpose",0
txtAmount db "Amount",0
txtQuantity db "Quantity",0
txtType db "Type",0

txtDebit db "Debit",0
txtCredit db "Credit",0

txtSave db "SAVE TRANSACTION",0
txtAdd db "ADD PRODUCT",0

txtTotalDebit db "TOTAL DEBIT",0
txtTotalCredit db "TOTAL CREDIT",0
txtEarnings db "EARNINGS",0

msgSaved db "Transaction Saved",0
msgProductAdded db "Product Added",0
msgDuplicate db "Product Already Exists",0
msgError db "Please Fill All Fields",0
msgStock db "Not Enough Stock Available",0

productsNames db MAX_PRODUCTS*32 dup(0)
productsQty dd MAX_PRODUCTS dup(0)

productCount dd 0

selectedProduct db 64 dup(0)
accountBuffer db 64 dup(0)
purposeBuffer db 64 dup(0)
amountBuffer db 64 dup(0)
qtyBuffer db 64 dup(0)
newProductBuffer db 64 dup(0)

currentType db 32 dup(0)

totalDebit dd 0
totalCredit dd 0
totalEarning dd 0

strBuffer db 64 dup(0)
formatInt db "%d",0

hSidebar dd ?
hTransactionPanel dd ?
hProductPanel dd ?
hManagePanel dd ?
hReportPanel dd ?

hCombo dd ?
hAccount dd ?
hPurpose dd ?
hAmount dd ?

hNewProduct dd ?
hNewQty dd ?

hLblProd dd ?
hLblAcc dd ?
hLblPurp dd ?
hLblAmt dd ?
hLblNewProd dd ?
hLblNewQty dd ?
hBtnSave dd ?
hBtnAdd dd ?
hRadDebit dd ?
hRadCredit dd ?

hManageList dd ?
hReportList dd ?

hDebitLabel dd ?
hCreditLabel dd ?
hEarnLabel dd ?

.code

start:

    invoke GetModuleHandle,NULL
    invoke WinMain,eax,NULL,NULL,SW_SHOWDEFAULT
    invoke ExitProcess,eax

; ================================================================

WinMain proc hInst:DWORD,hPrev:DWORD,\
CmdLine:DWORD,CmdShow:DWORD

LOCAL wc:WNDCLASSEX
LOCAL msg:MSG
LOCAL hwnd:HWND

    invoke InitCommonControlsEx,ADDR icc

    mov wc.cbSize,SIZEOF WNDCLASSEX
    mov wc.style,CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc,OFFSET WndProc
    mov wc.cbClsExtra,0
    mov wc.cbWndExtra,0

    push hInst
    pop wc.hInstance

    mov wc.hbrBackground,COLOR_BTNFACE+1
    mov wc.lpszMenuName,0
    mov wc.lpszClassName,OFFSET ClassName

    invoke LoadIcon,NULL,IDI_APPLICATION
    mov wc.hIcon,eax
    mov wc.hIconSm,eax

    invoke LoadCursor,NULL,IDC_ARROW
    mov wc.hCursor,eax

    invoke RegisterClassEx,ADDR wc

    invoke CreateWindowEx,\
    0,\
    ADDR ClassName,\
    ADDR AppName,\
    WS_OVERLAPPEDWINDOW,\
    100,\
    30,\
    1400,\
    850,\
    NULL,\
    NULL,\
    hInst,\
    NULL

    mov hwnd,eax

    invoke ShowWindow,hwnd,SW_SHOWNORMAL
    invoke UpdateWindow,hwnd

msgLoop:

    invoke GetMessage,ADDR msg,NULL,0,0

    cmp eax,0
    je finish

    invoke TranslateMessage,ADDR msg
    invoke DispatchMessage,ADDR msg

    jmp msgLoop

finish:

    mov eax,msg.wParam
    ret

WinMain endp

; ================================================================

WndProc proc hWnd:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD

LOCAL lvc:LVCOLUMN
LOCAL lvi:LVITEM

    .if uMsg == WM_CREATE

; ================= HEADER =================

        invoke CreateWindowEx,\
        0,\
        ADDR StaticClass,\
        ADDR headerTitle,\
        WS_VISIBLE or WS_CHILD,\
        500,\
        15,\
        700,\
        35,\
        hWnd,\
        NULL,\
        NULL,\
        NULL

; ================= SIDEBAR =================

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR StaticClass,\
        NULL,\
        WS_VISIBLE or WS_CHILD,\
        0,\
        0,\
        230,\
        850,\
        hWnd,\
        NULL,\
        NULL,\
        NULL

        mov hSidebar,eax

        invoke CreateWindowEx,\
        0,\
        ADDR ButtonClass,\
        ADDR txtTransaction,\
        WS_VISIBLE or WS_CHILD,\
        20,\
        100,\
        180,\
        45,\
        hWnd,\
        IDC_TRANSACTION_MENU,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        0,\
        ADDR ButtonClass,\
        ADDR txtAddProduct,\
        WS_VISIBLE or WS_CHILD,\
        20,\
        170,\
        180,\
        45,\
        hWnd,\
        IDC_PRODUCT_MENU,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        0,\
        ADDR ButtonClass,\
        ADDR txtManage,\
        WS_VISIBLE or WS_CHILD,\
        20,\
        240,\
        180,\
        45,\
        hWnd,\
        IDC_MANAGE_MENU,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        0,\
        ADDR ButtonClass,\
        ADDR txtReports,\
        WS_VISIBLE or WS_CHILD,\
        20,\
        310,\
        180,\
        45,\
        hWnd,\
        IDC_REPORT_MENU,\
        NULL,\
        NULL

; ================= DASHBOARD =================

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR StaticClass,\
        ADDR txtTotalDebit,\
        WS_VISIBLE or WS_CHILD,\
        980,\
        15,\
        120,\
        30,\
        hWnd,\
        NULL,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR StaticClass,\
        CSTR("0"),\
        WS_VISIBLE or WS_CHILD or SS_CENTER,\
        980,\
        45,\
        120,\
        35,\
        hWnd,\
        IDC_TOTAL_DEBIT,\
        NULL,\
        NULL

        mov hDebitLabel,eax

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR StaticClass,\
        ADDR txtTotalCredit,\
        WS_VISIBLE or WS_CHILD,\
        1120,\
        15,\
        120,\
        30,\
        hWnd,\
        NULL,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR StaticClass,\
        CSTR("0"),\
        WS_VISIBLE or WS_CHILD or SS_CENTER,\
        1120,\
        45,\
        120,\
        35,\
        hWnd,\
        IDC_TOTAL_CREDIT,\
        NULL,\
        NULL

        mov hCreditLabel,eax

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR StaticClass,\
        ADDR txtEarnings,\
        WS_VISIBLE or WS_CHILD,\
        1260,\
        15,\
        120,\
        30,\
        hWnd,\
        NULL,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR StaticClass,\
        CSTR("0"),\
        WS_VISIBLE or WS_CHILD or SS_CENTER,\
        1260,\
        45,\
        120,\
        35,\
        hWnd,\
        IDC_TOTAL_EARNING,\
        NULL,\
        NULL

        mov hEarnLabel,eax

; ================= TRANSACTION MODULE =================

        invoke CreateWindowEx,\
        0,\
        ADDR StaticClass,\
        ADDR txtProduct,\
        WS_CHILD,\
        400,\
        120,\
        120,\
        25,\
        hWnd,\
        NULL,\
        NULL,\
        NULL
    mov hLblProd, eax

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR ComboClass,\
        NULL,\
        WS_CHILD or CBS_DROPDOWNLIST,\
        550,\
        120,\
        250,\
        300,\
        hWnd,\
        IDC_PRODUCT_COMBO,\
        NULL,\
        NULL

        mov hCombo,eax

        ; Fetch products from file into the dropdown
        invoke LoadProductsFromFile

        invoke CreateWindowEx,\
        0,\
        ADDR StaticClass,\
        ADDR txtAccount,\
        WS_CHILD,\
        400,\
        180,\
        120,\
        25,\
        hWnd,\
        NULL,\
        NULL,\
        NULL
    mov hLblAcc, eax

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR EditClass,\
        NULL,\
        WS_CHILD,\
        550,\
        180,\
        250,\
        30,\
        hWnd,\
        IDC_ACCOUNT,\
        NULL,\
        NULL

        mov hAccount,eax

        invoke CreateWindowEx,\
        0,\
        ADDR StaticClass,\
        ADDR txtPurpose,\
        WS_CHILD,\
        400,\
        240,\
        120,\
        25,\
        hWnd,\
        NULL,\
        NULL,\
        NULL
    mov hLblPurp, eax

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR EditClass,\
        NULL,\
        WS_CHILD,\
        550,\
        240,\
        250,\
        30,\
        hWnd,\
        IDC_PURPOSE,\
        NULL,\
        NULL

        mov hPurpose,eax

        invoke CreateWindowEx,\
        0,\
        ADDR StaticClass,\
        ADDR txtAmount,\
        WS_CHILD,\
        400,\
        300,\
        120,\
        25,\
        hWnd,\
        NULL,\
        NULL,\
        NULL
    mov hLblAmt, eax

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR EditClass,\
        NULL,\
        WS_CHILD,\
        550,\
        300,\
        250,\
        30,\
        hWnd,\
        IDC_AMOUNT,\
        NULL,\
        NULL

        mov hAmount,eax

        invoke CreateWindowEx,\
        0,\
        ADDR ButtonClass,\
        ADDR txtDebit,\
        WS_CHILD or BS_AUTORADIOBUTTON,\
        550,\
        360,\
        100,\
        35,\
        hWnd,\
        IDC_DEBIT,\
        NULL,\
        NULL
    mov hRadDebit, eax

        invoke CreateWindowEx,\
        0,\
        ADDR ButtonClass,\
        ADDR txtCredit,\
        WS_CHILD or BS_AUTORADIOBUTTON,\
        680,\
        360,\
        100,\
        35,\
        hWnd,\
        IDC_CREDIT,\
        NULL,\
        NULL
    mov hRadCredit, eax

        invoke CreateWindowEx,\
        0,\
        ADDR ButtonClass,\
        ADDR txtSave,\
        WS_CHILD,\
        550,\
        430,\
        250,\
        45,\
        hWnd,\
        IDC_SAVE,\
        NULL,\
        NULL
    mov hBtnSave, eax

; ================= ADD PRODUCT =================

        invoke CreateWindowEx,\
        0,\
        ADDR StaticClass,\
        CSTR("New Product"),\
        WS_CHILD,\
        400,\
        120,\
        150,\
        25,\
        hWnd,\
        NULL,\
        NULL,\
        NULL
    mov hLblNewProd, eax

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR EditClass,\
        NULL,\
        WS_CHILD,\
        550,\
        120,\
        250,\
        30,\
        hWnd,\
        IDC_NEW_PRODUCT,\
        NULL,\
        NULL

        mov hNewProduct,eax

        invoke CreateWindowEx,\
        0,\
        ADDR StaticClass,\
        ADDR txtQuantity,\
        WS_CHILD,\
        400,\
        180,\
        150,\
        25,\
        hWnd,\
        NULL,\
        NULL,\
        NULL
    mov hLblNewQty, eax

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR EditClass,\
        NULL,\
        WS_CHILD,\
        550,\
        180,\
        250,\
        30,\
        hWnd,\
        IDC_NEW_QTY,\
        NULL,\
        NULL

        mov hNewQty,eax

        invoke CreateWindowEx,\
        0,\
        ADDR ButtonClass,\
        ADDR txtAdd,\
        WS_CHILD,\
        550,\
        240,\
        250,\
        45,\
        hWnd,\
        IDC_ADD_PRODUCT,\
        NULL,\
        NULL
    mov hBtnAdd, eax

; ================= MANAGE PRODUCTS =================

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR ListViewClass,\
        NULL,\
        WS_CHILD or LVS_REPORT,\
        300,\
        150,\
        800,\
        500,\
        hWnd,\
        IDC_MANAGE_LIST,\
        NULL,\
        NULL

        mov hManageList,eax

        mov lvc.imask,LVCF_TEXT or LVCF_WIDTH

        mov lvc.lx,200
        mov lvc.pszText,OFFSET txtProduct
        invoke SendMessage,hManageList,LVM_INSERTCOLUMN,0,ADDR lvc

        mov lvc.lx,200
        mov lvc.pszText,OFFSET txtQuantity
        invoke SendMessage,hManageList,LVM_INSERTCOLUMN,1,ADDR lvc

; ================= REPORTS =================

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR ListViewClass,\
        NULL,\
        WS_VISIBLE or WS_CHILD or LVS_REPORT,\
        260,\
        150,\
        1100,\
        600,\
        hWnd,\
        IDC_REPORT_LIST,\
        NULL,\
        NULL

        mov hReportList,eax

        mov lvc.imask,LVCF_TEXT or LVCF_WIDTH

        mov lvc.lx,120
        mov lvc.pszText,OFFSET txtProduct
        invoke SendMessage,hReportList,LVM_INSERTCOLUMN,0,ADDR lvc

        mov lvc.lx,120
        mov lvc.pszText,OFFSET txtAccount
        invoke SendMessage,hReportList,LVM_INSERTCOLUMN,1,ADDR lvc

        mov lvc.lx,120
        mov lvc.pszText,OFFSET txtPurpose
        invoke SendMessage,hReportList,LVM_INSERTCOLUMN,2,ADDR lvc

        mov lvc.lx,120
        mov lvc.pszText,OFFSET txtAmount
        invoke SendMessage,hReportList,LVM_INSERTCOLUMN,3,ADDR lvc

        mov lvc.lx,100
        mov lvc.pszText,OFFSET txtType
        invoke SendMessage,hReportList,LVM_INSERTCOLUMN,4,ADDR lvc

        ; Load historical transactions from file
        invoke LoadRecordsFromFile

; ================= DEFAULT STATE =================
        ; Force show only Transaction Module at startup
        invoke SendMessage, hWnd, WM_COMMAND, IDC_TRANSACTION_MENU, 0

; ================================================================

    .elseif uMsg == WM_COMMAND

        mov eax,wParam

        .if ax == IDC_TRANSACTION_MENU
            ; Show Transaction
            invoke ShowWindow, hLblProd, SW_SHOW
            invoke ShowWindow, hCombo, SW_SHOW
            invoke ShowWindow, hLblAcc, SW_SHOW
            invoke ShowWindow, hAccount, SW_SHOW
            invoke ShowWindow, hLblPurp, SW_SHOW
            invoke ShowWindow, hPurpose, SW_SHOW
            invoke ShowWindow, hLblAmt, SW_SHOW
            invoke ShowWindow, hAmount, SW_SHOW
            invoke ShowWindow, hRadDebit, SW_SHOW
            invoke ShowWindow, hRadCredit, SW_SHOW
            invoke ShowWindow, hBtnSave, SW_SHOW
            ; Hide Others
            invoke ShowWindow, hLblNewProd, SW_HIDE
            invoke ShowWindow, hNewProduct, SW_HIDE
            invoke ShowWindow, hLblNewQty, SW_HIDE
            invoke ShowWindow, hNewQty, SW_HIDE
            invoke ShowWindow, hBtnAdd, SW_HIDE
            invoke ShowWindow, hManageList, SW_HIDE
            invoke ShowWindow, hReportList, SW_HIDE

        .elseif ax == IDC_PRODUCT_MENU
            ; Hide Transaction
            invoke ShowWindow, hLblProd, SW_HIDE
            invoke ShowWindow, hCombo, SW_HIDE
            invoke ShowWindow, hLblAcc, SW_HIDE
            invoke ShowWindow, hAccount, SW_HIDE
            invoke ShowWindow, hLblPurp, SW_HIDE
            invoke ShowWindow, hPurpose, SW_HIDE
            invoke ShowWindow, hLblAmt, SW_HIDE
            invoke ShowWindow, hAmount, SW_HIDE
            invoke ShowWindow, hRadDebit, SW_HIDE
            invoke ShowWindow, hRadCredit, SW_HIDE
            invoke ShowWindow, hBtnSave, SW_HIDE
            ; Show Add Product
            invoke ShowWindow, hLblNewProd, SW_SHOW
            invoke ShowWindow, hNewProduct, SW_SHOW
            invoke ShowWindow, hLblNewQty, SW_SHOW
            invoke ShowWindow, hNewQty, SW_SHOW
            invoke ShowWindow, hBtnAdd, SW_SHOW
            ; Hide Others
            invoke ShowWindow, hManageList, SW_HIDE
            invoke ShowWindow, hReportList, SW_HIDE

        .elseif ax == IDC_MANAGE_MENU
            ; Hide All
            invoke ShowWindow, hLblProd, SW_HIDE
            invoke ShowWindow, hCombo, SW_HIDE
            invoke ShowWindow, hLblAcc, SW_HIDE
            invoke ShowWindow, hAccount, SW_HIDE
            invoke ShowWindow, hLblPurp, SW_HIDE
            invoke ShowWindow, hPurpose, SW_HIDE
            invoke ShowWindow, hLblAmt, SW_HIDE
            invoke ShowWindow, hAmount, SW_HIDE
            invoke ShowWindow, hRadDebit, SW_HIDE
            invoke ShowWindow, hRadCredit, SW_HIDE
            invoke ShowWindow, hBtnSave, SW_HIDE
            
            invoke ShowWindow, hLblNewProd, SW_HIDE
            invoke ShowWindow, hNewProduct, SW_HIDE
            invoke ShowWindow, hLblNewQty, SW_HIDE
            invoke ShowWindow, hNewQty, SW_HIDE
            invoke ShowWindow, hBtnAdd, SW_HIDE

            ; Show Manage Only
            invoke ShowWindow, hManageList, SW_SHOW
            invoke ShowWindow, hReportList, SW_HIDE

        .elseif ax == IDC_REPORT_MENU
            ; Hide All
            invoke ShowWindow, hLblProd, SW_HIDE
            invoke ShowWindow, hCombo, SW_HIDE
            invoke ShowWindow, hLblAcc, SW_HIDE
            invoke ShowWindow, hAccount, SW_HIDE
            invoke ShowWindow, hLblPurp, SW_HIDE
            invoke ShowWindow, hPurpose, SW_HIDE
            invoke ShowWindow, hLblAmt, SW_HIDE
            invoke ShowWindow, hAmount, SW_HIDE
            invoke ShowWindow, hRadDebit, SW_HIDE
            invoke ShowWindow, hRadCredit, SW_HIDE
            invoke ShowWindow, hBtnSave, SW_HIDE

            invoke ShowWindow, hLblNewProd, SW_HIDE
            invoke ShowWindow, hNewProduct, SW_HIDE
            invoke ShowWindow, hLblNewQty, SW_HIDE
            invoke ShowWindow, hNewQty, SW_HIDE
            invoke ShowWindow, hBtnAdd, SW_HIDE

            ; Show Report Only
            invoke ShowWindow, hManageList, SW_HIDE
            invoke ShowWindow, hReportList, SW_SHOW

        .elseif ax == IDC_DEBIT

            invoke lstrcpy,ADDR currentType,ADDR txtDebit

        .elseif ax == IDC_CREDIT

            invoke lstrcpy,ADDR currentType,ADDR txtCredit

        .elseif ax == IDC_ADD_PRODUCT

            invoke AddProduct

        .elseif ax == IDC_SAVE

            invoke AddTransaction

        .endif

    .elseif uMsg == WM_DESTROY

        invoke PostQuitMessage,0

    .else

        invoke DefWindowProc,hWnd,uMsg,wParam,lParam
        ret

    .endif

    xor eax,eax
    ret

WndProc endp

; ================================================================

LoadProductsFromFile proc uses ebx esi edi
    LOCAL hFile:HANDLE
    LOCAL fSize:DWORD
    LOCAL nRead:DWORD
    LOCAL pMem:DWORD
    
    invoke CreateFile, ADDR productsFile, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    .if eax == INVALID_HANDLE_VALUE
        ret
    .endif
    mov hFile, eax
    
    invoke GetFileSize, hFile, NULL
    mov fSize, eax
    
    .if fSize == 0
        invoke CloseHandle, hFile
        ret
    .endif

    invoke GetProcessHeap
    invoke HeapAlloc, eax, HEAP_ZERO_MEMORY, fSize
    mov pMem, eax
    
    invoke ReadFile, hFile, pMem, fSize, ADDR nRead, NULL
    invoke CloseHandle, hFile
    
    mov esi, pMem
    mov edi, pMem
    add edi, fSize ; End of buffer
    
parse_loop:
    cmp esi, edi
    jae done_parsing
    
    ; Skip whitespace and newlines
    mov al, [esi]
    .if al == 13 || al == 10 || al == ' ' || al == 9
        inc esi
        jmp parse_loop
    .endif

    mov eax, productCount
    imul eax, 32
    lea edx, [productsNames + eax]
    
copy_name:
    cmp esi, edi
    jae name_done
    mov al, [esi]
    .if al == ',' || al == 13 || al == 10
        jmp name_done
    .endif
    mov [edx], al
    inc edx
    inc esi
    jmp copy_name

name_done:
    mov byte ptr [edx], 0 ; Null terminate
    
    mov eax, productCount
    imul eax, 32
    lea edx, [productsNames + eax]
    invoke SendMessage, hCombo, CB_ADDSTRING, 0, edx
    
    ; Parse quantity if comma exists
    mov ebx, 0
    .if byte ptr [esi] == ','
        inc esi
        lea edx, qtyBuffer
    copy_qty:
        cmp esi, edi
        jae qty_done
        mov al, [esi]
        .if al == 13 || al == 10
            jmp qty_done
        .endif
        mov [edx], al
        inc edx
        inc esi
        jmp copy_qty
    qty_done:
        mov byte ptr [edx], 0
        invoke atodw, ADDR qtyBuffer
        mov ebx, eax
    .endif
    
    mov eax, productCount
    shl eax, 2
    mov productsQty[eax], ebx
    
    inc productCount
    .if productCount < MAX_PRODUCTS
        jmp parse_loop
    .endif

done_parsing:
    invoke GetProcessHeap
    invoke HeapFree, eax, 0, pMem
    invoke RefreshProductList
    ret
LoadProductsFromFile endp

LoadRecordsFromFile proc uses ebx esi edi
    LOCAL hFile:HANDLE
    LOCAL fSize:DWORD
    LOCAL nRead:DWORD
    LOCAL pMem:DWORD
    LOCAL amount:DWORD
    
    invoke CreateFile, ADDR recordsFile, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    .if eax == INVALID_HANDLE_VALUE
        ret
    .endif
    mov hFile, eax
    
    invoke GetFileSize, hFile, NULL
    mov fSize, eax
    
    .if fSize == 0
        invoke CloseHandle, hFile
        ret
    .endif

    invoke GetProcessHeap
    invoke HeapAlloc, eax, HEAP_ZERO_MEMORY, fSize
    mov pMem, eax
    
    invoke ReadFile, hFile, pMem, fSize, ADDR nRead, NULL
    invoke CloseHandle, hFile
    
    mov esi, pMem
    mov edi, pMem
    add edi, fSize ; End of buffer
    
parse_loop:
    cmp esi, edi
    jae done_parsing

    ; Field 1: Product
    lea edx, selectedProduct
    @@: cmp esi, edi
    jae f1_e
    mov al, [esi]
    inc esi
    cmp al, ','
    je f1_e
    mov [edx], al
    inc edx
    jmp @b
    f1_e: mov byte ptr [edx], 0

    ; Field 2: Account
    lea edx, accountBuffer
    @@: cmp esi, edi
    jae f2_e
    mov al, [esi]
    inc esi
    cmp al, ','
    je f2_e
    mov [edx], al
    inc edx
    jmp @b
    f2_e: mov byte ptr [edx], 0

    ; Field 3: Purpose
    lea edx, purposeBuffer
    @@: cmp esi, edi
    jae f3_e
    mov al, [esi]
    inc esi
    cmp al, ','
    je f3_e
    mov [edx], al
    inc edx
    jmp @b
    f3_e: mov byte ptr [edx], 0

    ; Field 4: Amount
    lea edx, amountBuffer
    @@: cmp esi, edi
    jae f4_e
    mov al, [esi]
    inc esi
    cmp al, ','
    je f4_e
    mov [edx], al
    inc edx
    jmp @b
    f4_e: mov byte ptr [edx], 0

    ; Field 5: Type
    lea edx, currentType
    @@: cmp esi, edi
    jae f5_e
    mov al, [esi]
    inc esi
    cmp al, 13
    je skip_cr
    cmp al, 10
    je f5_e
    mov [edx], al
    inc edx
    jmp @b
    skip_cr:
    .if byte ptr [esi] == 10
        inc esi
    .endif
    f5_e: mov byte ptr [edx], 0

    invoke InsertReportItem
    
    ; Update Dashboard totals from history
    invoke atodw, ADDR amountBuffer
    mov amount, eax
    invoke lstrcmpi, ADDR currentType, ADDR txtDebit
    .if eax == 0
        mov eax, amount
        add totalDebit, eax
    .else
        mov eax, amount
        add totalCredit, eax
    .endif

    jmp parse_loop

done_parsing:
    mov eax, totalDebit
    sub eax, totalCredit
    mov totalEarning, eax
    invoke UpdateDashboard
    invoke GetProcessHeap
    invoke HeapFree, eax, 0, pMem
    ret
LoadRecordsFromFile endp

AddProduct proc uses ebx esi

LOCAL index:DWORD
LOCAL qty:DWORD
LOCAL hFile:HANDLE
LOCAL bytesWritten:DWORD

    invoke GetWindowText,hNewProduct,ADDR newProductBuffer,64
    invoke GetWindowText,hNewQty,ADDR qtyBuffer,64

    invoke lstrlen,ADDR newProductBuffer

    .if eax == 0
        invoke MessageBox,NULL,ADDR msgError,ADDR AppName,MB_OK
        ret
    .endif

    mov ecx,productCount
    xor ebx,ebx

checkLoop:

    cmp ebx,ecx
    jge addNow

    mov eax,ebx
    imul eax,32

        lea edx, [productsNames + eax]
        invoke lstrcmpi, ADDR newProductBuffer, edx

    .if eax == 0

        invoke MessageBox,NULL,ADDR msgDuplicate,ADDR AppName,MB_OK
        ret

    .endif

    inc ebx
    jmp checkLoop

addNow:

    mov eax,productCount
    imul eax,32

    lea edx, [productsNames + eax]
    invoke lstrcpy, edx, ADDR newProductBuffer

    invoke atodw,ADDR qtyBuffer
    mov qty,eax

    mov eax,productCount
    mov ebx,qty
    mov esi,eax
    shl esi,2
    mov productsQty[esi],ebx

    invoke SendMessage,\
    hCombo,\
    CB_ADDSTRING,\
    0,\
    ADDR newProductBuffer

    invoke RefreshProductList
    
    ; Save product to products.txt
    invoke CreateFile,ADDR productsFile,FILE_APPEND_DATA,FILE_SHARE_READ,NULL,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
    .if eax != INVALID_HANDLE_VALUE
        mov hFile,eax
        
        ; Write product name
        invoke lstrlen,ADDR newProductBuffer
        mov ecx, eax
        invoke WriteFile,hFile,ADDR newProductBuffer,ecx,ADDR bytesWritten,NULL
        
        ; Write comma
        invoke lstrlen,ADDR comma
        mov ecx, eax
        invoke WriteFile,hFile,ADDR comma,ecx,ADDR bytesWritten,NULL
        
        ; Convert quantity to string and write
        invoke wsprintf,ADDR strBuffer,ADDR formatInt,qty
        invoke lstrlen,ADDR strBuffer
        mov ecx, eax
        invoke WriteFile,hFile,ADDR strBuffer,ecx,ADDR bytesWritten,NULL
        
        ; Write newline
        invoke lstrlen,ADDR newline
        mov ecx, eax
        invoke WriteFile,hFile,ADDR newline,ecx,ADDR bytesWritten,NULL
        
        invoke CloseHandle,hFile
    .endif

    inc productCount

    invoke MessageBox,NULL,ADDR msgProductAdded,ADDR AppName,MB_OK

    ret

AddProduct endp

; ================================================================

RefreshProductList proc uses esi

LOCAL lvi:LVITEM
LOCAL i:DWORD

    invoke SendMessage,hManageList,LVM_DELETEALLITEMS,0,0

    mov i,0

nextItem:

    mov eax,i
    cmp eax,productCount
    jge done

    mov lvi.iItem,eax
    imul eax,32

    mov DWORD PTR lvi.iSubItem,0
    mov DWORD PTR lvi.imask,LVIF_TEXT
    mov edx,OFFSET productsNames
    add edx,eax
    mov DWORD PTR lvi.pszText,edx

    invoke SendMessage,\
    hManageList,\
    LVM_INSERTITEM,\
    0,\
    ADDR lvi

    mov eax,i
    mov esi,eax
    shl esi,2
    mov eax,productsQty[esi]

    invoke wsprintf,\
    ADDR strBuffer,\
    ADDR formatInt,\
    eax

    mov DWORD PTR lvi.iSubItem,1
    mov DWORD PTR lvi.pszText,OFFSET strBuffer

    invoke SendMessage,\
    hManageList,\
    LVM_SETITEMTEXT,\
    i,\
    ADDR lvi

    inc i
    jmp nextItem

done:

    ret

RefreshProductList endp

; ================================================================

AddTransaction proc uses ebx esi

LOCAL amount:DWORD
LOCAL lvi:LVITEM
LOCAL i:DWORD
LOCAL hFile:HANDLE
LOCAL tempFile:HANDLE
LOCAL bytesWritten:DWORD
LOCAL pMem:DWORD
LOCAL fSize:DWORD
LOCAL nRead:DWORD
LOCAL tempPath[256]:BYTE

    invoke SendMessage,\
    hCombo,\
    CB_GETCURSEL,\
    0,\
    0

    invoke SendMessage,\
    hCombo,\
    CB_GETLBTEXT,\
    eax,\
    ADDR selectedProduct

    invoke GetWindowText,hAccount,ADDR accountBuffer,64
    invoke GetWindowText,hPurpose,ADDR purposeBuffer,64
    invoke GetWindowText,hAmount,ADDR amountBuffer,64

    invoke atodw,ADDR amountBuffer
    mov amount,eax

    mov ecx,productCount
    mov i,0

findProduct:

    mov eax,i
    cmp eax,ecx
    jge finish

    mov eax,i
    imul eax,32

    lea edx, [productsNames + eax]
    invoke lstrcmpi, ADDR selectedProduct, edx

    .if eax == 0

        mov eax,i
        mov esi,eax
        shl esi,2
        mov ebx,productsQty[esi]

        cmp ebx,0
        jle noStock

        dec ebx
        mov esi,eax
        shl esi,2
        mov productsQty[esi],ebx

        invoke RefreshProductList
        
        ; Initialize temp path
        invoke lstrcpy,ADDR tempPath,CSTR("data\\temp.txt")
        
        ; Update products.txt with new stock quantity
        ; First, rewrite entire products file with updated quantities
        invoke CreateFile,ADDR productsFile,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
        .if eax != INVALID_HANDLE_VALUE
            mov hFile,eax
            invoke GetFileSize,hFile,NULL
            mov fSize,eax
            .if fSize > 0
                invoke GetProcessHeap
                invoke HeapAlloc,eax,HEAP_ZERO_MEMORY,fSize
                mov pMem,eax
                invoke ReadFile,hFile,pMem,fSize,ADDR nRead,NULL
                invoke CloseHandle,hFile
                
                ; Create temp file to write updated data
                invoke CreateFile,ADDR tempPath,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
                .if eax != INVALID_HANDLE_VALUE
                    mov tempFile,eax
                    
                    ; Rewrite all products with their current quantities
                    push esi
                    mov esi,0
rewriteProducts:
                    cmp esi,productCount
                    jge doneRewrite
                    
                    ; Write product name
                    mov eax,esi
                    imul eax,32
                    lea edx,[productsNames+eax]
                    push edx
                    invoke lstrlen,edx
                    mov ecx, eax
                    pop edx
                    invoke WriteFile,tempFile,edx,ecx,ADDR bytesWritten,NULL
                    
                    ; Write comma
                    invoke lstrlen,ADDR comma
                    mov ecx, eax
                    invoke WriteFile,tempFile,ADDR comma,ecx,ADDR bytesWritten,NULL
                    
                    ; Write quantity
                    mov eax,esi
                    shl eax,2
                    mov eax,productsQty[eax]
                    invoke wsprintf,ADDR strBuffer,ADDR formatInt,eax
                    invoke lstrlen,ADDR strBuffer
                    mov ecx, eax
                    invoke WriteFile,tempFile,ADDR strBuffer,ecx,ADDR bytesWritten,NULL
                    
                    ; Write newline
                    invoke lstrlen,ADDR newline
                    mov ecx, eax
                    invoke WriteFile,tempFile,ADDR newline,ecx,ADDR bytesWritten,NULL
                    
                    inc esi
                    jmp rewriteProducts
doneRewrite:
                    pop esi
                    invoke CloseHandle,tempFile
                    invoke GetProcessHeap
                    invoke HeapFree,eax,0,pMem
                    
                    ; Replace original file with temp file
                    invoke DeleteFile,ADDR productsFile
                    invoke MoveFile,ADDR tempPath,ADDR productsFile
                .endif
            .endif
        .endif

        invoke InsertReportItem
        
        ; Record transaction in records.txt
        invoke CreateFile,ADDR recordsFile,FILE_APPEND_DATA,FILE_SHARE_READ,NULL,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
        .if eax != INVALID_HANDLE_VALUE
            mov hFile,eax
            
            ; Write product
            invoke lstrlen,ADDR selectedProduct
            mov ecx, eax
            invoke WriteFile,hFile,ADDR selectedProduct,ecx,ADDR bytesWritten,NULL
            
            invoke lstrlen,ADDR comma
            mov ecx, eax
            invoke WriteFile,hFile,ADDR comma,ecx,ADDR bytesWritten,NULL
            
            ; Write account
            invoke lstrlen,ADDR accountBuffer
            mov ecx, eax
            invoke WriteFile,hFile,ADDR accountBuffer,ecx,ADDR bytesWritten,NULL
            
            invoke lstrlen,ADDR comma
            mov ecx, eax
            invoke WriteFile,hFile,ADDR comma,ecx,ADDR bytesWritten,NULL
            
            ; Write purpose
            invoke lstrlen,ADDR purposeBuffer
            mov ecx, eax
            invoke WriteFile,hFile,ADDR purposeBuffer,ecx,ADDR bytesWritten,NULL
            
            invoke lstrlen,ADDR comma
            mov ecx, eax
            invoke WriteFile,hFile,ADDR comma,ecx,ADDR bytesWritten,NULL
            
            ; Write amount
            invoke lstrlen,ADDR amountBuffer
            mov ecx, eax
            invoke WriteFile,hFile,ADDR amountBuffer,ecx,ADDR bytesWritten,NULL
            
            invoke lstrlen,ADDR comma
            mov ecx, eax
            invoke WriteFile,hFile,ADDR comma,ecx,ADDR bytesWritten,NULL
            
            ; Write type
            invoke lstrlen,ADDR currentType
            mov ecx, eax
            invoke WriteFile,hFile,ADDR currentType,ecx,ADDR bytesWritten,NULL
            
            ; Write newline
            invoke lstrlen,ADDR newline
            mov ecx, eax
            invoke WriteFile,hFile,ADDR newline,ecx,ADDR bytesWritten,NULL
            
            invoke CloseHandle,hFile
        .endif

        invoke lstrcmpi,\
        ADDR currentType,\
        ADDR txtDebit

        .if eax == 0

            mov eax,amount
            add totalDebit,eax

        .else

            mov eax,amount
            add totalCredit,eax

        .endif

        mov eax,totalDebit
        sub eax,totalCredit
        mov totalEarning,eax

        invoke UpdateDashboard

        ret

    .endif

    inc i
    jmp findProduct

noStock:

    invoke MessageBox,NULL,ADDR msgStock,ADDR AppName,MB_OK

finish:

    ret

AddTransaction endp

; ================================================================

InsertReportItem proc

LOCAL lvi:LVITEM

    invoke SendMessage,\
    hReportList,\
    LVM_GETITEMCOUNT,\
    0,\
    0

    mov DWORD PTR lvi.iItem,eax
    mov DWORD PTR lvi.imask,LVIF_TEXT

    mov DWORD PTR lvi.iSubItem,0
    mov DWORD PTR lvi.pszText,OFFSET selectedProduct

    invoke SendMessage,\
    hReportList,\
    LVM_INSERTITEM,\
    0,\
    ADDR lvi

    mov DWORD PTR lvi.iSubItem,1
    mov DWORD PTR lvi.pszText,OFFSET accountBuffer

    invoke SendMessage,\
    hReportList,\
    LVM_SETITEMTEXT,\
    lvi.iItem,\
    ADDR lvi

    mov DWORD PTR lvi.iSubItem,2
    mov DWORD PTR lvi.pszText,OFFSET purposeBuffer

    invoke SendMessage,\
    hReportList,\
    LVM_SETITEMTEXT,\
    lvi.iItem,\
    ADDR lvi

    mov DWORD PTR lvi.iSubItem,3
    mov DWORD PTR lvi.pszText,OFFSET amountBuffer

    invoke SendMessage,\
    hReportList,\
    LVM_SETITEMTEXT,\
    lvi.iItem,\
    ADDR lvi

    mov DWORD PTR lvi.iSubItem,4
    mov DWORD PTR lvi.pszText,OFFSET currentType

    invoke SendMessage,\
    hReportList,\
    LVM_SETITEMTEXT,\
    lvi.iItem,\
    ADDR lvi

    ret

InsertReportItem endp

; ================================================================

UpdateDashboard proc

    invoke wsprintf,\
    ADDR strBuffer,\
    ADDR formatInt,\
    totalDebit

    invoke SetWindowText,\
    hDebitLabel,\
    ADDR strBuffer

    invoke wsprintf,\
    ADDR strBuffer,\
    ADDR formatInt,\
    totalCredit

    invoke SetWindowText,\
    hCreditLabel,\
    ADDR strBuffer

    invoke wsprintf,\
    ADDR strBuffer,\
    ADDR formatInt,\
    totalEarning

    invoke SetWindowText,\
    hEarnLabel,\
    ADDR strBuffer

    ret

UpdateDashboard endp
end start