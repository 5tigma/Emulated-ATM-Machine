.model small
.stack 200h

.data
    ; -- balances ----------------------------------
    bal1    DW 5000
    bal2    DW 12000
    bal3    DW 3500

    ; -- passwords ---------------------------------
    pw1     DW 5678
    pw2     DW 1234
    pw3     DW 7890

    ; -- variables ---------------------------------
    usr     DB 0        ; which user logged in (1,2,3)
    tries   DB 0        ; wrong PIN counter

    ; -- screen messages ---------------------------
    msg_line  DB '+===================+',13,10,'$'
    msg_title DB '| EMU-BANK ATM v2.0 |',13,10,'$'
    msg_u1    DB '| 1) Maheem         |',13,10,'$'
    msg_u2    DB '| 2) Mayhem         |',13,10,'$'
    msg_u3    DB '| 3) Muhim          |',13,10,'$'
    msg_m1    DB '| 1) Check Balance  |',13,10,'$'
    msg_m2    DB '| 2) Deposit        |',13,10,'$'
    msg_m3    DB '| 3) Withdraw       |',13,10,'$'
    msg_m4    DB '| 4) Logout         |',13,10,'$'

    msg_pickuser  DB 13,10,'  Pick user  [1-3] : $'
    msg_enterpin  DB 13,10,'  Enter PIN [####] : $'
    msg_attempt   DB 13,10,'  Attempt: $'
    msg_of3       DB ' of 3',13,10,'$'
    msg_pickoption DB 13,10,'  Pick option[1-4] : $'
    msg_enteramt  DB 13,10,'  Enter amount, then ENTER: $'

    msg_welcome   DB 13,10,'  Welcome, $'
    msg_balance   DB 13,10,'  Your Balance: $'
    msg_taka      DB ' Taka',13,10,'$'
    msg_dep_ok    DB 13,10,'  Deposit successful!',13,10,'$'
    msg_wit_ok    DB 13,10,'  Withdrawal successful!',13,10,'$'
    msg_newbal    DB '  New Balance: $'
    msg_lowbal    DB 13,10,'  ERROR: Not enough balance!',13,10,'$'
    msg_badinput  DB 13,10,'  Invalid choice, try again.',13,10,'$'
    msg_anykey    DB 13,10,'  Press any key to continue...$'
    msg_goodbye   DB 13,10,'  Goodbye! Have a nice day!',13,10,'$'

    msg_wrongbox1 DB 13,10,'  +-----------------+',13,10,'$'
    msg_wrongbox2 DB '  | !! WRONG PIN !! |',13,10,'$'
    msg_wrongbox3 DB '  +-----------------+',13,10,'$'
    msg_attleft   DB '  Attempts left: $'

    msg_lockbox1  DB 13,10,'  +---------------------+',13,10,'$'
    msg_lockbox2  DB '  | !! CARD IS LOCKED !! |',13,10,'$'
    msg_lockbox3  DB '  |  Contact your bank   |',13,10,'$'
    msg_lockbox4  DB '  +---------------------+',13,10,'$'

    nm1  DB 'Maheem',13,10,'$'
    nm2  DB 'Mayhem',13,10,'$'
    nm3  DB 'Muhim',13,10,'$'

.code
main PROC
    ; step 1: point DS to our data segment
    MOV AX, @data
    MOV DS, AX

    ; step 2: set screen to 80x25 color text mode
    MOV AH, 00h
    MOV AL, 03h
    INT 10h

; +--------------------------------------+
; ¦           LOGIN SCREEN               ¦
; +--------------------------------------+
login:
    ; clear screen — blue background, yellow text (color 1Eh)
    MOV AH, 06h
    MOV AL, 00h
    MOV BH, 1Eh
    MOV CX, 0000h
    MOV DX, 184Fh
    INT 10h

    ; move cursor to top-left
    MOV AH, 02h
    MOV BH, 00h
    MOV DH, 03h
    MOV DL, 25h
    INT 10h

    ; print ATM box
    MOV AH, 09h
    LEA DX, msg_line
    INT 21h
    LEA DX, msg_title
    INT 21h
    LEA DX, msg_line
    INT 21h
    LEA DX, msg_u1
    INT 21h
    LEA DX, msg_u2
    INT 21h
    LEA DX, msg_u3
    INT 21h
    LEA DX, msg_line
    INT 21h
    LEA DX, msg_pickuser
    INT 21h

    ; read user choice
    MOV AH, 01h
    INT 21h             ; key goes into AL

    CMP AL, '1'
    JE  user1
    CMP AL, '2'
    JE  user2
    CMP AL, '3'
    JE  user3

    ; bad key pressed
    MOV AH, 09h
    LEA DX, msg_badinput
    INT 21h
    LEA DX, msg_anykey
    INT 21h
    MOV AH, 01h
    INT 21h
    JMP login           ; loop back

user1:
    MOV usr, 1
    MOV tries, 0        ; reset wrong PIN counter
    JMP pin_screen

user2:
    MOV usr, 2
    MOV tries, 0
    JMP pin_screen

user3:
    MOV usr, 3
    MOV tries, 0

; +--------------------------------------+
; ¦           PIN SCREEN                 ¦
; +--------------------------------------+
pin_screen:
    ; clear screen — blue background
    MOV AH, 06h
    MOV AL, 00h
    MOV BH, 1Eh
    MOV CX, 0000h
    MOV DX, 184Fh
    INT 10h

    MOV AH, 02h
    MOV BH, 00h
    MOV DH, 03h
    MOV DL, 25h
    INT 10h

    ; print box and PIN prompt
    MOV AH, 09h
    LEA DX, msg_line
    INT 21h
    LEA DX, msg_title
    INT 21h
    LEA DX, msg_line
    INT 21h

    ; show "Attempt: X of 3"
    LEA DX, msg_attempt
    INT 21h
    MOV AL, tries
    INC AL              ; show 1,2,3 not 0,1,2
    ADD AL, '0'         ; convert number to character
    MOV DL, AL
    MOV AH, 02h
    INT 21h
    MOV AH, 09h
    LEA DX, msg_of3
    INT 21h

    LEA DX, msg_enterpin
    INT 21h

    ; read the PIN number typed by user
    CALL read_number    ; result comes back in AX

    ; check which user and compare PIN
    CMP usr, 1
    JE  check_pin1
    CMP usr, 2
    JE  check_pin2
    CMP AX, pw3
    JE  home_screen
    JMP wrong_pin

check_pin1:
    CMP AX, pw1
    JE  home_screen
    JMP wrong_pin

check_pin2:
    CMP AX, pw2
    JE  home_screen

; +--------------------------------------+
; ¦         WRONG PIN HANDLER            ¦
; +--------------------------------------+
wrong_pin:
    INC tries           ; add 1 to wrong attempt counter

    ; show wrong PIN popup box
    MOV AH, 09h
    LEA DX, msg_wrongbox1
    INT 21h
    LEA DX, msg_wrongbox2
    INT 21h
    LEA DX, msg_wrongbox3
    INT 21h

    ; show how many attempts are left
    LEA DX, msg_attleft
    INT 21h
    MOV AL, 3
    SUB AL, tries       ; remaining = 3 - tries
    ADD AL, '0'         ; convert to character
    MOV DL, AL
    MOV AH, 02h
    INT 21h

    ; check if 3 wrong tries ? lock card
    CMP tries, 3
    JE  card_locked

    ; not locked yet — let user try again
    MOV AH, 09h
    LEA DX, msg_anykey
    INT 21h
    MOV AH, 01h
    INT 21h
    JMP pin_screen      ; go back to PIN entry

; +--------------------------------------+
; ¦          CARD LOCKED SCREEN          ¦
; +--------------------------------------+
card_locked:
    ; clear screen — red background
    MOV AH, 06h
    MOV AL, 00h
    MOV BH, 4Eh         ; red background, yellow text
    MOV CX, 0000h
    MOV DX, 184Fh
    INT 10h

    MOV AH, 02h
    MOV BH, 00h
    MOV DH, 08h
    MOV DL, 20h
    INT 10h

    ; show locked box
    MOV AH, 09h
    LEA DX, msg_lockbox1
    INT 21h
    LEA DX, msg_lockbox2
    INT 21h
    LEA DX, msg_lockbox3
    INT 21h
    LEA DX, msg_lockbox4
    INT 21h

    ; HALT — infinite loop, program stops here
halt_loop:
    JMP halt_loop

; +--------------------------------------+
; ¦           HOME / MENU SCREEN         ¦
; +--------------------------------------+
home_screen:
    ; clear screen — red background, white text (4Fh)
    MOV AH, 06h
    MOV AL, 00h
    MOV BH, 4Fh
    MOV CX, 0000h
    MOV DX, 184Fh
    INT 10h

    MOV AH, 02h
    MOV BH, 00h
    MOV DH, 02h
    MOV DL, 25h
    INT 10h

    ; print welcome + user name
    MOV AH, 09h
    LEA DX, msg_welcome
    INT 21h

    CMP usr, 1
    JE  print_name1
    CMP usr, 2
    JE  print_name2
    LEA DX, nm3
    INT 21h
    JMP show_balance

print_name1:
    LEA DX, nm1
    INT 21h
    JMP show_balance

print_name2:
    LEA DX, nm2
    INT 21h

show_balance:
    ; always show balance at top of menu
    MOV AH, 09h
    LEA DX, msg_balance
    INT 21h
    CALL get_balance    ; balance goes into AX
    CALL print_number   ; print AX on screen
    MOV AH, 09h
    LEA DX, msg_taka
    INT 21h

    ; print menu box
    LEA DX, msg_line
    INT 21h
    LEA DX, msg_m1
    INT 21h
    LEA DX, msg_m2
    INT 21h
    LEA DX, msg_m3
    INT 21h
    LEA DX, msg_m4
    INT 21h
    LEA DX, msg_line
    INT 21h
    LEA DX, msg_pickoption
    INT 21h

    ; read menu choice
    MOV AH, 01h
    INT 21h

    CMP AL, '1'
    JE  do_balance
    CMP AL, '2'
    JE  do_deposit
    CMP AL, '3'
    JE  do_withdraw
    CMP AL, '4'
    JE  do_logout

    ; invalid key
    MOV AH, 09h
    LEA DX, msg_badinput
    INT 21h
    JMP wait_and_home

; -- OPTION 1: CHECK BALANCE ------------
do_balance:
    MOV AH, 09h
    LEA DX, msg_balance
    INT 21h
    CALL get_balance
    CALL print_number
    MOV AH, 09h
    LEA DX, msg_taka
    INT 21h
    JMP wait_and_home

; -- OPTION 2: DEPOSIT ------------------
do_deposit:
    MOV AH, 09h
    LEA DX, msg_enteramt
    INT 21h
    CALL read_number    ; amount in AX
    CALL get_bal_ptr    ; pointer to balance in BX
    ADD [BX], AX        ; balance = balance + amount
    MOV AH, 09h
    LEA DX, msg_dep_ok
    INT 21h
    LEA DX, msg_newbal
    INT 21h
    CALL get_balance
    CALL print_number
    MOV AH, 09h
    LEA DX, msg_taka
    INT 21h
    JMP wait_and_home

; -- OPTION 3: WITHDRAW -----------------
do_withdraw:
    MOV AH, 09h
    LEA DX, msg_enteramt
    INT 21h
    CALL read_number    ; amount in AX
    MOV SI, AX          ; save amount in SI (safe register)
    CALL get_bal_ptr    ; pointer to balance in BX
    MOV AX, SI          ; restore amount back to AX
    CMP AX, [BX]        ; is amount > balance?
    JA  not_enough      ; yes ? error

    SUB [BX], AX        ; balance = balance - amount
    MOV AH, 09h
    LEA DX, msg_wit_ok
    INT 21h
    LEA DX, msg_newbal
    INT 21h
    CALL get_balance
    CALL print_number
    MOV AH, 09h
    LEA DX, msg_taka
    INT 21h
    JMP wait_and_home

not_enough:
    MOV AH, 09h
    LEA DX, msg_lowbal
    INT 21h

wait_and_home:
    MOV AH, 09h
    LEA DX, msg_anykey
    INT 21h
    MOV AH, 01h
    INT 21h
    JMP home_screen     ; loop back to menu

; -- OPTION 4: LOGOUT -------------------
do_logout:
    MOV AH, 06h
    MOV AL, 00h
    MOV BH, 1Eh
    MOV CX, 0000h
    MOV DX, 184Fh
    INT 10h

    MOV AH, 02h
    MOV BH, 00h
    MOV DH, 10h
    MOV DL, 25h
    INT 10h

    MOV AH, 09h
    LEA DX, msg_goodbye
    INT 21h
    LEA DX, msg_anykey
    INT 21h
    MOV AH, 01h
    INT 21h
    JMP login           ; back to login screen

main ENDP

; +--------------------------------------+
; ¦   PROCEDURE: get_balance ? AX        ¦
; ¦   reads balance of current user      ¦
; +--------------------------------------+
get_balance PROC
    CMP usr, 1
    JE  gb_user1
    CMP usr, 2
    JE  gb_user2
    MOV AX, bal3        ; user 3
    RET
gb_user1:
    MOV AX, bal1
    RET
gb_user2:
    MOV AX, bal2
    RET
get_balance ENDP

; +--------------------------------------+
; ¦   PROCEDURE: get_bal_ptr ? BX        ¦
; ¦   returns memory address of balance  ¦
; +--------------------------------------+
get_bal_ptr PROC
    CMP usr, 1
    JE  gp_user1
    CMP usr, 2
    JE  gp_user2
    LEA BX, bal3
    RET
gp_user1:
    LEA BX, bal1
    RET
gp_user2:
    LEA BX, bal2
    RET
get_bal_ptr ENDP

; +--------------------------------------+
; ¦   PROCEDURE: print_number            ¦
; ¦   prints the number stored in AX     ¦
; +--------------------------------------+
print_number PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, 10          ; divide by 10 each time
    MOV CX, 0           ; digit counter

    ; extract digits by dividing by 10
    ; push each remainder (digit) onto stack
divide_loop:
    MOV DX, 0
    DIV BX              ; AX = quotient, DX = remainder
    PUSH DX             ; save digit on stack
    INC CX              ; count digits
    CMP AX, 0
    JNE divide_loop     ; keep going if quotient not zero

    ; pop digits off stack and print (reverses order = correct)
print_loop:
    POP DX
    ADD DL, '0'         ; convert digit to ASCII character
    MOV AH, 02h
    INT 21h
    LOOP print_loop

    POP DX
    POP CX
    POP BX
    POP AX
    RET
print_number ENDP

; +--------------------------------------+
; ¦   PROCEDURE: read_number ? AX        ¦
; ¦   reads digits until Enter pressed   ¦
; +--------------------------------------+
read_number PROC
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, 0           ; BX accumulates the result
    MOV CX, 10          ; multiplier

read_loop:
    MOV AH, 01h
    INT 21h             ; read one key into AL

    CMP AL, 13          ; Enter key (ASCII 13)?
    JE  read_done

    CMP AL, '0'         ; ignore if below '0'
    JB  read_loop
    CMP AL, '9'         ; ignore if above '9'
    JA  read_loop

    ; valid digit — add to running total
    SUB AL, '0'         ; convert ASCII to number
    MOV AH, 0
    PUSH AX             ; save new digit

    MOV AX, BX
    MUL CX              ; AX = previous total * 10
    MOV BX, AX

    POP AX
    ADD BX, AX          ; BX = (old total * 10) + new digit
    JMP read_loop

read_done:
    MOV AX, BX          ; return result in AX
    POP DX
    POP CX
    POP BX
    RET
read_number ENDP

END main