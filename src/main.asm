.386
.model flat, stdcall
option casemap:none

include C:\masm32\include\windows.inc
include C:\masm32\include\user32.inc
include C:\masm32\include\kernel32.inc
include C:\masm32\include\comctl32.inc

includelib C:\masm32\lib\user32.lib
includelib C:\masm32\lib\kernel32.lib
includelib C:\masm32\lib\comctl32.lib

include resources.inc

WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
LoadProducts PROTO
SaveRecord PROTO
AddLedgerItem PROTO
UpdateSummary PROTO

.const
EditClass db "edit",0
ButtonClass db "button",0
StaticClass db "static",0
ComboClass db "combobox",0
ListViewClass db "SysListView32",0

.data

icc INITCOMMONCONTROLSEX <SIZEOF INITCOMMONCONTROLSEX,\
ICC_LISTVIEW_CLASSES>

ClassName db "SentryClass",0
AppName db "Sentry OS",0

titleText db "Sentry OS Accounting Dashboard",0

productLabel db "Product:",0
accountLabel db "Account No:",0
purposeLabel db "Purpose:",0
amountLabel db "Amount:",0

saveText db "Add Entry",0
exitText db "Exit",0

debitText db "Debit",0
creditText db "Credit",0

lblDebit db "Total Debit",0
lblCredit db "Total Credit",0
lblBalance db "Earnings",0

msgSaved db "Entry Saved",0
msgError db "Please Fill Fields",0

recordsFile db "data\records.txt",0
productsFile db "data\products.txt",0

productCol db "Product",0
accountCol db "Account",0
purposeCol db "Purpose",0
amountCol db "Amount",0
typeCol db "Type",0

productBuffer db 128 dup(0)
accountBuffer db 128 dup(0)
purposeBuffer db 128 dup(0)
amountBuffer db 64 dup(0)

currentType db "Debit",0

space db " | ",0
newline db 13,10,0
formatStr db "%d",0
zeroStr db "0",0

totalDebit dd 0
totalCredit dd 0
totalBalance dd 0
hDispDebit dd ?
hDispCredit dd ?
hDispBalance dd ?

entryBuffer db 512 dup(0)

bytesWritten dd ?

hProduct dd ?
hAccount dd ?
hPurpose dd ?
hAmount dd ?
hLedger dd ?
strSumBuffer db 32 dup(0)

.code

start:

    invoke GetModuleHandle,NULL
    invoke WinMain,eax,NULL,NULL,SW_SHOWDEFAULT
    invoke ExitProcess,eax

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

    mov wc.hbrBackground,COLOR_WINDOW+1
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
    50,\
    30,\
    1100,\
    700,\
    NULL,\
    NULL,\
    hInst,\
    NULL

    mov hwnd,eax

    invoke ShowWindow,hwnd,SW_SHOWNORMAL
    invoke UpdateWindow,hwnd

msg_loop:

    invoke GetMessage,ADDR msg,NULL,0,0

    cmp eax,0
    je finish

    invoke TranslateMessage,ADDR msg
    invoke DispatchMessage,ADDR msg

    jmp msg_loop

finish:

    mov eax,msg.wParam
    ret

WinMain endp

WndProc proc hWnd:DWORD,uMsg:DWORD,\
wParam:DWORD,lParam:DWORD

LOCAL lvc:LVCOLUMN
LOCAL lvi:LVITEM

    .if uMsg == WM_CREATE

        invoke CreateWindowEx,\
        0,\
        ADDR StaticClass,\
        ADDR titleText,\
        WS_VISIBLE or WS_CHILD,\
        320,\
        20,\
        400,\
        30,\
        hWnd,\
        NULL,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        0,\
        ADDR StaticClass,\
        ADDR productLabel,\
        WS_VISIBLE or WS_CHILD,\
        40,\
        70,\
        100,\
        25,\
        hWnd,\
        NULL,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR ComboClass,\
        NULL,\
        WS_VISIBLE or WS_CHILD or CBS_DROPDOWNLIST,\
        160,\
        70,\
        220,\
        200,\
        hWnd,\
        IDC_PRODUCTBOX,\
        NULL,\
        NULL

        mov hProduct,eax

        invoke CreateWindowEx,\
        0,\
        ADDR StaticClass,\
        ADDR accountLabel,\
        WS_VISIBLE or WS_CHILD,\
        40,\
        120,\
        100,\
        25,\
        hWnd,\
        NULL,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR EditClass,\
        NULL,\
        WS_VISIBLE or WS_CHILD,\
        160,\
        120,\
        220,\
        25,\
        hWnd,\
        IDC_ACCOUNT,\
        NULL,\
        NULL

        mov hAccount,eax

        invoke CreateWindowEx,\
        0,\
        ADDR StaticClass,\
        ADDR purposeLabel,\
        WS_VISIBLE or WS_CHILD,\
        40,\
        170,\
        100,\
        25,\
        hWnd,\
        NULL,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR EditClass,\
        NULL,\
        WS_VISIBLE or WS_CHILD,\
        160,\
        170,\
        220,\
        25,\
        hWnd,\
        IDC_PURPOSE,\
        NULL,\
        NULL

        mov hPurpose,eax

        invoke CreateWindowEx,\
        0,\
        ADDR StaticClass,\
        ADDR amountLabel,\
        WS_VISIBLE or WS_CHILD,\
        40,\
        220,\
        100,\
        25,\
        hWnd,\
        NULL,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR EditClass,\
        NULL,\
        WS_VISIBLE or WS_CHILD,\
        160,\
        220,\
        220,\
        25,\
        hWnd,\
        IDC_AMOUNT,\
        NULL,\
        NULL

        mov hAmount,eax

        invoke CreateWindowEx,\
        0,\
        ADDR ButtonClass,\
        ADDR debitText,\
        WS_VISIBLE or WS_CHILD or BS_AUTORADIOBUTTON,\
        160,\
        270,\
        100,\
        30,\
        hWnd,\
        IDC_DEBIT,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        0,\
        ADDR ButtonClass,\
        ADDR creditText,\
        WS_VISIBLE or WS_CHILD or BS_AUTORADIOBUTTON,\
        280,\
        270,\
        100,\
        30,\
        hWnd,\
        IDC_CREDIT,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        0,\
        ADDR ButtonClass,\
        ADDR saveText,\
        WS_VISIBLE or WS_CHILD,\
        160,\
        330,\
        120,\
        40,\
        hWnd,\
        IDC_SAVE,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        0,\
        ADDR ButtonClass,\
        ADDR exitText,\
        WS_VISIBLE or WS_CHILD,\
        300,\
        330,\
        120,\
        40,\
        hWnd,\
        IDC_EXIT,\
        NULL,\
        NULL

        invoke CreateWindowEx,\
        WS_EX_CLIENTEDGE,\
        ADDR ListViewClass,\
        NULL,\
        WS_VISIBLE or WS_CHILD or LVS_REPORT,\
        450,\
        70,\
        600,\
        500,\
        hWnd,\
        IDC_LEDGER_LISTVIEW,\
        NULL,\
        NULL

        mov hLedger,eax

        mov lvc.imask,LVCF_TEXT or LVCF_WIDTH

        mov lvc.lx,130
        mov lvc.pszText,OFFSET productCol
        invoke SendMessage,hLedger,LVM_INSERTCOLUMN,0,ADDR lvc

        mov lvc.lx,130
        mov lvc.pszText,OFFSET accountCol
        invoke SendMessage,hLedger,LVM_INSERTCOLUMN,1,ADDR lvc

        mov lvc.lx,160
        mov lvc.pszText,OFFSET purposeCol
        invoke SendMessage,hLedger,LVM_INSERTCOLUMN,2,ADDR lvc

        mov lvc.lx,110
        mov lvc.pszText,OFFSET amountCol
        invoke SendMessage,hLedger,LVM_INSERTCOLUMN,3,ADDR lvc

        mov lvc.lx,110
        mov lvc.pszText,OFFSET typeCol
        invoke SendMessage,hLedger,LVM_INSERTCOLUMN,4,ADDR lvc

        ; --- Summary UI Section ---
        invoke CreateWindowEx,0,ADDR StaticClass,ADDR lblDebit,\
            WS_VISIBLE or WS_CHILD, 730, 10, 100, 20, hWnd, NULL, NULL, NULL
            
        invoke CreateWindowEx,WS_EX_CLIENTEDGE,ADDR StaticClass,ADDR zeroStr,\
            WS_VISIBLE or WS_CHILD or SS_CENTER,\
            730, 35, 100, 25, hWnd, IDC_TOTAL_DEBIT, NULL, NULL
        mov hDispDebit, eax

        invoke CreateWindowEx,0,ADDR StaticClass,ADDR lblCredit,\
            WS_VISIBLE or WS_CHILD, 850, 10, 100, 20, hWnd, NULL, NULL, NULL
            
        invoke CreateWindowEx,WS_EX_CLIENTEDGE,ADDR StaticClass,ADDR zeroStr,\
            WS_VISIBLE or WS_CHILD or SS_CENTER,\
            850, 35, 100, 25, hWnd, IDC_TOTAL_CREDIT, NULL, NULL
        mov hDispCredit, eax

        invoke CreateWindowEx,0,ADDR StaticClass,ADDR lblBalance,\
            WS_VISIBLE or WS_CHILD, 970, 10, 100, 20, hWnd, NULL, NULL, NULL
            
        invoke CreateWindowEx,WS_EX_CLIENTEDGE,ADDR StaticClass,ADDR zeroStr,\
            WS_VISIBLE or WS_CHILD or SS_CENTER,\
            970, 35, 100, 25, hWnd, IDC_TOTAL_BALANCE, NULL, NULL
        mov hDispBalance, eax

        invoke LoadProducts

    .elseif uMsg == WM_COMMAND

        mov eax,wParam

        .if ax == IDC_DEBIT

            invoke lstrcpy,ADDR currentType,\
            ADDR debitText

        .elseif ax == IDC_CREDIT

            invoke lstrcpy,ADDR currentType,\
            ADDR creditText

        .elseif ax == IDC_SAVE

            invoke SendMessage,\
            hProduct,\
            CB_GETCURSEL,\
            0,\
            0

            invoke SendMessage,\
            hProduct,\
            CB_GETLBTEXT,\
            eax,\
            ADDR productBuffer

            invoke GetWindowText,\
            hAccount,\
            ADDR accountBuffer,\
            128

            invoke GetWindowText,\
            hPurpose,\
            ADDR purposeBuffer,\
            128

            invoke GetWindowText,\
            hAmount,\
            ADDR amountBuffer,\
            64

            invoke lstrlen,ADDR accountBuffer

            .if eax == 0

                invoke MessageBox,\
                hWnd,\
                ADDR msgError,\
                ADDR AppName,\
                MB_OK

            .else

                invoke SaveRecord
                invoke AddLedgerItem
                invoke UpdateSummary

                invoke MessageBox,\
                hWnd,\
                ADDR msgSaved,\
                ADDR AppName,\
                MB_OK

            .endif

        .elseif ax == IDC_EXIT

            invoke DestroyWindow,hWnd

        .endif

    .elseif uMsg == WM_DESTROY

        invoke PostQuitMessage,0

    .else

        invoke DefWindowProc,\
        hWnd,uMsg,wParam,lParam

        ret

    .endif

    xor eax,eax
    ret

WndProc endp

SaveRecord proc

LOCAL hFile:DWORD

    invoke RtlZeroMemory,\
    ADDR entryBuffer,\
    512

    invoke lstrcat,\
    ADDR entryBuffer,\
    ADDR productBuffer

    invoke lstrcat,\
    ADDR entryBuffer,\
    ADDR space

    invoke lstrcat,\
    ADDR entryBuffer,\
    ADDR accountBuffer

    invoke lstrcat,\
    ADDR entryBuffer,\
    ADDR space

    invoke lstrcat,\
    ADDR entryBuffer,\
    ADDR purposeBuffer

    invoke lstrcat,\
    ADDR entryBuffer,\
    ADDR space

    invoke lstrcat,\
    ADDR entryBuffer,\
    ADDR amountBuffer

    invoke lstrcat,\
    ADDR entryBuffer,\
    ADDR space

    invoke lstrcat,\
    ADDR entryBuffer,\
    ADDR currentType

    invoke lstrcat,\
    ADDR entryBuffer,\
    ADDR newline

    invoke CreateFile,\
    ADDR recordsFile,\
    GENERIC_WRITE,\
    FILE_SHARE_WRITE,\
    NULL,\
    OPEN_ALWAYS,\
    FILE_ATTRIBUTE_NORMAL,\
    NULL

    mov hFile,eax

    invoke SetFilePointer,\
    hFile,0,0,FILE_END

    invoke lstrlen,ADDR entryBuffer

    invoke WriteFile,\
    hFile,\
    ADDR entryBuffer,\
    eax,\
    ADDR bytesWritten,\
    NULL

    invoke CloseHandle,hFile

    ret

SaveRecord endp

AddLedgerItem proc

LOCAL lvi:LVITEM

    invoke SendMessage,\
    hLedger,\
    LVM_GETITEMCOUNT,\
    0,\
    0

    mov lvi.iItem,eax
    mov lvi.iSubItem,0
    mov lvi.imask, LVIF_TEXT
    mov lvi.pszText, OFFSET productBuffer

    invoke SendMessage,\
    hLedger,\
    LVM_INSERTITEM,\
    0,\
    ADDR lvi

    mov lvi.iSubItem,1
    mov lvi.pszText, OFFSET accountBuffer

    invoke SendMessage,\
    hLedger,\
    LVM_SETITEMTEXT,\
    lvi.iItem,\
    ADDR lvi

    mov lvi.iSubItem,2
    mov lvi.pszText, OFFSET purposeBuffer

    invoke SendMessage,\
    hLedger,\
    LVM_SETITEMTEXT,\
    lvi.iItem,\
    ADDR lvi

    mov lvi.iSubItem,3
    mov lvi.pszText, OFFSET amountBuffer

    invoke SendMessage,\
    hLedger,\
    LVM_SETITEMTEXT,\
    lvi.iItem,\
    ADDR lvi

    mov lvi.iSubItem,4
    mov lvi.pszText, OFFSET currentType

    invoke SendMessage,\
    hLedger,\
    LVM_SETITEMTEXT,\
    lvi.iItem,\
    ADDR lvi

    ret

AddLedgerItem endp

UpdateSummary proc
    LOCAL val:DWORD
    
    ; Simple string to integer conversion
    lea esi, amountBuffer
    xor eax, eax
    .while byte ptr [esi] != 0
        movzx ecx, byte ptr [esi]
        .if cl >= '0' && cl <= '9'
            sub ecx, '0'
            imul eax, 10
            add eax, ecx
        .endif
        inc esi
    .endw
    mov val, eax

    ; Check if current entry is Debit or Credit
    invoke lstrcmpi, ADDR currentType, ADDR debitText
    .if eax == 0
        mov eax, val
        add totalDebit, eax
    .else
        mov eax, val
        add totalCredit, eax
    .endif

    ; Calculate total earnings (Balance = Debit - Credit)
    mov eax, totalDebit
    sub eax, totalCredit
    mov totalBalance, eax

    ; Update the display boxes
    invoke wsprintf, ADDR strSumBuffer, ADDR formatStr, totalDebit
    invoke SetWindowText, hDispDebit, ADDR strSumBuffer

    invoke wsprintf, ADDR strSumBuffer, ADDR formatStr, totalCredit
    invoke SetWindowText, hDispCredit, ADDR strSumBuffer

    invoke wsprintf, ADDR strSumBuffer, ADDR formatStr, totalBalance
    invoke SetWindowText, hDispBalance, ADDR strSumBuffer

    ret
UpdateSummary endp

LoadProducts proc

    LOCAL hFile:DWORD
    LOCAL dwFileSize:DWORD
    LOCAL dwRead:DWORD
    LOCAL lpBuffer:DWORD
    LOCAL pLineStart:DWORD
    LOCAL hHeap:DWORD

    invoke CreateFile, ADDR productsFile, GENERIC_READ, FILE_SHARE_READ, \
                       NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    
    .if eax == INVALID_HANDLE_VALUE
        ret
    .endif
    mov hFile, eax

    invoke GetFileSize, hFile, NULL
    mov dwFileSize, eax

    .if eax == 0
        invoke CloseHandle, hFile
        ret
    .endif

    invoke GetProcessHeap
    mov hHeap, eax
    invoke HeapAlloc, hHeap, HEAP_ZERO_MEMORY, dwFileSize
    mov lpBuffer, eax

    invoke ReadFile, hFile, lpBuffer, dwFileSize, ADDR dwRead, NULL
    invoke CloseHandle, hFile

    mov eax, lpBuffer
    mov pLineStart, eax
    mov ecx, dwFileSize

    .while ecx > 0
        movzx edx, byte ptr [eax]
        .if dl == 13 || dl == 10
            mov byte ptr [eax], 0
            
            push eax
            push ecx
            invoke SendMessage, hProduct, CB_ADDSTRING, 0, pLineStart
            pop ecx
            pop eax

            inc eax
            dec ecx
            .if ecx > 0
                movzx edx, byte ptr [eax]
                .if dl == 10 || dl == 13
                    inc eax
                    dec ecx
                .endif
            .endif
            mov pLineStart, eax
        .else
            inc eax
            dec ecx
        .endif
    .endw

    ; Handle the last line if it doesn't end with a newline
    mov eax, pLineStart
    sub eax, lpBuffer
    .if eax < dwFileSize
        invoke SendMessage, hProduct, CB_ADDSTRING, 0, pLineStart
    .endif

    invoke HeapFree, hHeap, 0, lpBuffer

    invoke SendMessage,\
    hProduct,\
    CB_SETCURSEL,\
    0,\
    0

    ret

LoadProducts endp

end start