;; COURSE - Spring 2018 - PROJECT
;; Matthew Manzi
;; mmanzi1@umbc.edu
;; Plays a game of Tic Tac Toe.  In this version, a user may select board sizes
;; of 3x3, 4x4, or 5x5.  Additionally, each player will place a "mine" for the
;; other, so that if the other attempts to put a mark on that position, the
;; mine will "detonate" and the player who placed the mine will win.  Players
;; *will* be able to select the same spot for their respective mines.  At the
;; start of the program, the user may enable "Debug Mode" which prints two
;; linearized versions of the board.

;; handy instruction aliases
%define cmpb    cmp byte
%define decb    dec byte
%define xorb    xor byte
%define movb    mov byte
%define movq    mov qword

;;;; lable naming conventions (uses snake_case) ;;;;
;;;;
;; *#   = is a numerical continuation of the data identified by '*' using number '#'
;; *_l  = length of the data identified by '*'
;; abrt = abort
;; bd   = board
;; char = character
;; d    = debug
;; dv   = divider
;; e    = hex(adecimal) version
;; en   = enable
;; err  = error
;; exp  = exploded
;; god  = G.o.D. = Grid of Death
;; m    = message
;; mn   = mine
;; off  = offset
;; p    = player
;; s#   = is a size specifier (e.g. s3 is for a 3x3 game)
;; sz   = size

section .bss
    buffer      resb    4   ; 4 bytes for general user input (temporary holding)
    pfunc       resq    1   ; 8 bytes (qword) for the address of the function for printing the board
    atoi_val    resb    2   ; 2 bytes for ascii input converted to integer
    d_en        resb    1   ; 1 byte for if debug is enabled
    mn_en       resb    1   ; 1 byte for whether or not to show the mines
    mn_off_X    resb    1   ; 1 byte for offest of player X's mine
    mn_off_O    resb    1   ; 1 byte for offest of player O's mine
    mn_exp_X    resb    1   ; 1 byte for whether or not player X's mine exploded
    mn_exp_O    resb    1   ; 1 byte for whether or not player O's mine exploded

section .data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; size-independent data ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    m_bd_sz     db      "What size board do you want to use (3/4/5)?", 0xA
    m_bd_sz_l   equ     $ - m_bd_sz

    m_d_en      db      "Do you want to enable debug information (Y/y/D/d, default=N)?", 0xA
    m_d_en_l    equ     $ - m_d_en

    m_abrt      db      "Unacceptable input...exiting.", 0xA
    m_abrt_l    equ     $ - m_abrt

    m_p         db      "Player X"              ; starts with player X by default
    m_p_l       equ     $ - m_p
    m_win       db      " wins!", 0xA
    m_win_l     equ     $ - m_win
    p_char_off  equ     7                       ; offset of X/O in the m_p data
    p_switch    equ     0x17                    ; when xor'd with the player's char, yields the other player's char

    m_tie       db      "It's a draw (tie)!", 0xA   ;atom fix'
    m_tie_l     equ     $ - m_tie
    m_final     db      "Final board:", 0xA
    m_final_l   equ     $ - m_final
    m_err       db      "That location is out of range or already taken.", 0xA
    m_err_l     equ     $ - m_err

    m_lose      db      " blew up! :(", 0xA
    m_lose_l    equ     $ - m_lose

    hexdigits   db      '0123456789ABCDEF'
    m_bd1       db      "Current board (mem):", 0xA, "&board = 0x"
    m_bd1_l     equ     $ - m_bd1
    m_bd        db      "FFFFFFFFFFFFFFFF", 0xA
    m_bd_l      equ     $ - m_bd

    d_bd2       db      "]", 0xA
    d_bd2_l     equ     $ - d_bd2

    d_mn_char   db      "0123456789ABCDEFGHIJKLMNO"
    d_mn1       db      "Mine Offsets:", 0xA, "Player X (1/!): "
    d_mn1_l     equ     $ - d_mn1
    d_mn2       db      0xA, "Player O (2/@): "
    d_mn2_l     equ     $ - d_mn2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; s3 data ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    max_off_s3  equ     8

    m_mn_s3     db      ", choose your mine location (0-8): "
    m_mn_s3_l   equ     $ - m_mn_s3

    m_p2_s3     db      ", choose your location (0-8):", 0xA, \
                        "Current board:", 0xA
    m_p2_s3_l   equ     $ - m_p2_s3

    bd_dv1_s3   db      " | | ", 0xA                    ; column dividers
    bd_dv1_s3_l equ     $ - bd_dv1_s3
    bd_dv2_s3   db      "-----", 0xA                    ; row dividers
    bd_dv2_s3_l equ     $ - bd_dv2_s3

    d_bd1_s3    db      " 012345678 ", 0xA, "["
    d_bd1_s3_l  equ     $ - d_bd1_s3
    bd_s3       db      "         "                     ; 3x3 linearized game board
    bd_s3_l     equ     $ - bd_s3

    e_bd1_s3    db      "Current board (hex):", 0xA, \
                        "  0  1  2  3  4  5  6  7  8 ", 0xA, "["
    e_bd1_s3_l  equ     $ - e_bd1_s3
    e_bd_s3     db      "20 20 20 20 20 20 20 20 20"    ; 3x3 hex linearized game board
    e_bd_s3_l   equ     $ - e_bd_s3
    e_bd2_s3    db      "]", 0xA
    e_bd2_s3_l  equ     $ - e_bd2_s3

    god_s3      db      2,1,6,3,8,4,9,9, \
                        2,0,4,7,9,9,9,9, \
                        1,0,6,4,8,5,9,9, \
                        5,4,6,0,9,9,9,9, \
                        5,3,6,2,7,1,8,0, \
                        4,3,8,2,9,9,9,9, \
                        3,0,4,2,8,7,9,9, \
                        4,1,8,6,9,9,9,9, \
                        4,0,5,2,7,6,9,9
    turns_s3    equ     god_s3+7                        ; number of turns remaining in the game
    wins_s3     db      5,3,5, \
                        3,7,3, \
                        5,3,5                           ; 2 * (number of possible winning combinations in TTT for the corresponding spot) - 1


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; s4 data ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    max_off_s4  equ     15

    m_mn_s4     db      ", choose your mine location (0-15): "
    m_mn_s4_l   equ     $ - m_mn_s4

    m_p2_s4     db      ", choose your location (0-15):", 0xA, \
                        "Current board:", 0xA
    m_p2_s4_l   equ     $ - m_p2_s4

    bd_dv1_s4   db      " | | | ", 0xA                                      ; column dividers
    bd_dv1_s4_l equ     $ - bd_dv1_s4
    bd_dv2_s4   db      "-------", 0xA                                      ; row dividers
    bd_dv2_s4_l equ     $ - bd_dv2_s4

    d_bd1_s4    db      " 0123456789ABCDEF ", 0xA, "["
    d_bd1_s4_l  equ     $ - d_bd1_s4
    bd_s4       db      "                "                                  ; 4x4 linearized game board
    bd_s4_l     equ     $ - bd_s4

    e_bd1_s4    db      "Current board (hex):", 0xA, \
                        "  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F ", 0xA, "["
    e_bd1_s4_l  equ     $ - e_bd1_s4
    e_bd_s4     db      "20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20"   ; 4x4 hex linearized game board
    e_bd_s4_l   equ     $ - e_bd_s4
    e_bd2_s4    db      "]", 0xA
    e_bd2_s4_l  equ     $ - e_bd2_s4

    god_s4      db       3, 2, 1,12, 8, 4,15,10, 5,16,16,16,16,16,16,16, \
                         3, 2, 0,13, 9, 5,16,16,16,16,16,16,16,16,16,16, \
                         3, 1, 0,14,10, 6,16,16,16,16,16,16,16,16,16,16, \
                         2, 1, 0,12, 9, 6,15,11, 7,16,16,16,16,16,16,16, \
                         7, 6, 5,12, 8, 0,16,16,16,16,16,16,16,16,16,16, \
                         7, 6, 4,13, 9, 1,15,10, 0,16,16,16,16,16,16,16, \
                         7, 5, 4,14,10, 2,12, 9, 3,16,16,16,16,16,16,16, \
                         6, 5, 4,15,11, 3,16,16,16,16,16,16,16,16,16,16, \
                        11,10, 9,12, 4, 0,16,16,16,16,16,16,16,16,16,16, \
                        11,10, 8,12, 6, 3,13, 5, 1,16,16,16,16,16,16,16, \
                        11, 9, 8,14, 6, 2,15, 5, 0,16,16,16,16,16,16,16, \
                        10, 9, 8,15, 7, 3,16,16,16,16,16,16,16,16,16,16, \
                         8, 4, 0, 9, 6, 3,15,14,13,16,16,16,16,16,16,16, \
                         9, 5, 1,15,14,12,16,16,16,16,16,16,16,16,16,16, \
                        10, 6, 2,15,13,12,16,16,16,16,16,16,16,16,16,16, \
                        10, 5, 0,11, 7, 3,14,13,12,16,16,16,16,16,16,16
    turns_s4    equ     god_s4+15                                           ; number of turns remaining in the game
    wins_s4     db      8,5,5,8, \
                        5,8,8,5, \
                        5,8,8,5, \
                        8,5,5,8                                             ; 3 * (number of possible winning combinations in TTT for the corresponding spot) - 1


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; s5 data ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    max_off_s5  equ     24

    m_mn_s5     db      ", choose your mine location (0-24): "
    m_mn_s5_l   equ     $ - m_mn_s5

    m_p2_s5     db      ", choose your location (0-24):", 0xA, \
                        "Current board:", 0xA
    m_p2_s5_l   equ     $ - m_p2_s5

    bd_dv1_s5   db      " | | | | ", 0xA                                                                ; column dividers
    bd_dv1_s5_l equ     $ - bd_dv1_s5
    bd_dv2_s5   db      "---------", 0xA                                                                ; row dividers
    bd_dv2_s5_l equ     $ - bd_dv2_s5

    d_bd1_s5    db      " 0123456789ABCDEFGHIJKLMNO ", 0xA, "["
    d_bd1_s5_l  equ     $ - d_bd1_s5
    bd_s5       db      "                         "                                                     ; 5x5 linearized game board
    bd_s5_l     equ     $ - bd_s5

    e_bd1_s5    db      "Current board (hex):", 0xA, \
                        "  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O ", 0xA, "["
    e_bd1_s5_l  equ     $ - e_bd1_s5
    e_bd_s5     db      "20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20 20"    ; 5x5 hex linearized game board
    e_bd_s5_l   equ     $ - e_bd_s5
    e_bd2_s5    db      "]", 0xA
    e_bd2_s5_l  equ     $ - e_bd2_s5

    god_s5      db       4, 3, 2, 1,20,15,10, 5,24,18,12, 6,25,25,25,25, \
                         4, 3, 2, 0,21,16,11, 6,25,25,25,25,25,25,25,25, \
                         4, 3, 1, 0,22,17,12, 7,25,25,25,25,25,25,25,25, \
                         4, 2, 1, 0,23,18,13, 8,25,25,25,25,25,25,25,25, \
                         3, 2, 1, 0,20,16,12, 8,24,19,14, 9,25,25,25,25, \
                         9, 8, 7, 6,20,15,10, 0,25,25,25,25,25,25,25,25, \
                         9, 8, 7, 5,21,16,11, 1,24,18,12, 0,25,25,25,25, \
                         9, 8, 6, 5,22,17,12, 2,25,25,25,25,25,25,25,25, \
                         9, 7, 6, 5,20,16,12, 4,23,18,13, 3,25,25,25,25, \
                         8, 7, 6, 5,24,19,14, 4,25,25,25,25,25,25,25,25, \
                        14,13,12,11,20,15, 5, 0,25,25,25,25,25,25,25,25, \
                        14,13,12,10,21,16, 6, 1,25,25,25,25,25,25,25,25, \
                        14,13,11,10,20,16, 8, 4,22,17, 7, 2,24,18, 6, 0, \
                        14,12,11,10,23,18, 8, 3,25,25,25,25,25,25,25,25, \
                        13,12,11,10,24,19, 9, 4,25,25,25,25,25,25,25,25, \
                        19,18,17,16,20,10, 5, 0,25,25,25,25,25,25,25,25, \
                        19,18,17,15,20,12, 8, 4,21,11, 6, 1,25,25,25,25, \
                        19,18,16,15,22,12, 7, 2,25,25,25,25,25,25,25,25, \
                        19,17,16,15,23,13, 8, 3,24,12, 6, 0,25,25,25,25, \
                        18,17,16,15,24,14, 9, 4,25,25,25,25,25,25,25,25, \
                        15,10, 5, 0,16,12, 8, 4,24,23,22,21,25,25,25,25, \
                        16,11, 6, 1,24,23,22,20,25,25,25,25,25,25,25,25, \
                        17,12, 7, 2,24,23,21,20,25,25,25,25,25,25,25,25, \
                        18,13, 8, 3,24,22,21,20,25,25,25,25,25,25,25,25, \
                        18,12, 6, 0,19,14, 9, 4,23,22,21,20,25,25,25,25
    turns_s5    equ     god_s5+15                                                                       ; number of turns remaining in the game
    wins_s5     db      11, 7, 7, 7,11, \
                         7,11, 7,11, 7, \
                         7, 7,15, 7, 7, \
                         7,11, 7,11, 7, \
                        11, 7, 7, 7,11                                                                  ; 4 * (number of possible winning combinations in TTT for the corresponding spot) - 1


section .text
global _start                           ; export entry point


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; size-independent code ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_int:                              ; ecx: const char* msg, edx: size_t msgl
    mov         eax,4                   ; system call number (sys_write)
    mov         ebx,1                   ; first argument: file descriptor (stdout == 1)
    int         0x80                    ; call kernel
ret

read_int:                               ; ecx: char* msg, ; edx: size_t msgl
    mov         eax,3                   ; system call number (sys_read)
    xor         ebx,ebx                 ; first argument: file descriptor (stdin == 0)
    int         0x80                    ; call kernel
ret

;; read in a decimal number with varying number of digits (0-3)
;; result is in ebx
read_num:
    mov         dword [buffer], 0       ; clear the buffer
    mov         ecx,buffer
    mov         edx,4
    call        read_int
    mov         ecx,3                   ; offset/counter for number of digits
    mov         esi,10                  ; need register with 10 in it for mutliplying
count_digit:
    cmpb        [buffer+ecx],0xA        ; is `Enter` key?
    je          compute_ones            ; yes: compute with ecx number of digits
    dec         ecx                     ; no: one less digit, check again
    jmp         count_digit
compute_ones:
    mov         ebx,1000                ; set ebx to out-of-range value
    dec         ecx                     ; get from offest for `Enter` to offset for 1's
    js          done_read_num           ; if there was no input, leave now
    sub         byte [buffer+ecx],'0'   ; account for ascii
    movzx       ebx, byte [buffer+ecx]  ; 1's byte into ebx
compute_digit:
    dec         ecx                     ; next digit
    js          done_read_num           ; if no more digits
    sub         byte [buffer+ecx],'0'   ; account for ascii
    movzx       edx, byte [buffer+ecx]  ; move digit into edx for math
    mov         eax,esi                 ; scale factor into eax
    mul         edx                     ; edx:eax = eax * edx (scale to correct value)
    add         ebx,eax                 ; ebx = ebx + eax (update total)
    mov         eax,10                  ; increase scale factor 10x
    mul         esi                     ; edx:eax = edx * esi (increase scale)
    mov         esi,eax                 ; move new scale factor back into esi
    jmp         compute_digit
done_read_num:
ret

;; check if the player landed on a mine
check_mine:
    cmpb        [m_p+p_char_off],'O'    ; which player just went
    je          check_mine_O
;; fallthrough (check_mine_X)

;; check if player X blew up
check_mine_X:
    cmp         al,[mn_off_O]
    je          lose_X
ret

;; check if player O blew up
check_mine_O:
    cmp         al,[mn_off_X]
    je          lose_O
ret

;; player X lost/blew up
lose_X:
    mov         byte [mn_exp_O],1
jmp             lose

;; player O lost/blew up
lose_O:
    mov         byte [mn_exp_X],1
;; fallthrough (lose)

;; someone lost/blew up
lose:
    mov         ecx,m_p                 ; tell the player they lost
    mov         edx,m_p_l
    call        print_int
    mov         ecx,m_lose
    mov         edx,m_lose_l
    call        print_int
    xor         byte [m_p+p_char_off],p_switch  ; switch player (to winner)
jmp             win


;; it's a tie
tie:
    mov         ecx,m_tie               ; tie message
    mov         edx,m_tie_l+m_final_l
    call        print_int
jmp             pfinalb

;; someone won
win:
    mov         ecx,m_p                 ; player name message
    mov         edx,m_p_l
    call        print_int
    mov         ecx,m_win               ; wins message
    mov         edx,m_win_l
    call        print_int
    mov         ecx,m_final             ; final board message
    mov         edx,m_final_l
    call        print_int
;; fallthrough (pfinalb)

;; print final board and exit (no return)
pfinalb:
    mov         byte [mn_en],1          ; show mines in final board print
    call        [pfunc]
    mov         eax,1                   ; system call number (sys_exit)
    xor         ebx,ebx                 ; first syscall argument: exit code
    int         0x80                    ; call kernel
;; no return (exit)

;; exiting with abort message
abort:
    mov         ecx,m_abrt              ; exiting message
    mov         edx,m_abrt_l
    call        print_int
    mov         eax,1                   ; system call number (sys_exit)
    xor         ebx,ebx                 ; first syscall argument: exit code
    int         0x80                    ; call kernel
;; no return (exit)

_start:
    ;; enable debug?
    mov         ecx,m_d_en              ; ask for debug
    mov         edx,m_d_en_l
    call        print_int
    mov         ecx,buffer              ; store input in buffer temporarily
    mov         edx,2                   ; 2 bytes for debug enable input
    call        read_int
    ;; handle debug enable with switch
    movb        [d_en],0                ; no debug, by default
    cmpb        [buffer],'Y'
    je          debug_enable
    cmpb        [buffer],'y'
    je          debug_enable
    cmpb        [buffer],'D'
    je          debug_enable
    cmpb        [buffer],'d'
    je          debug_enable
jmp             board_size

debug_enable:
    movb        [d_en],1
;; fallthrough (board_size)

;; what board size?
board_size:
    mov         ecx,m_bd_sz             ; ask for board size
    mov         edx,m_bd_sz_l
    call        print_int
    mov         ecx,buffer              ; store input temporarily
    mov         edx,2                   ; 2 bytes for board size input
    call        read_int
    ;; handle debug enable with if
    cmpb        [d_en],1
    je          board_size_debug
    ;; handle non-debug board size with switch
    cmpb        [buffer],'3'
    je          do_standard_s3
    cmpb        [buffer],'4'
    je          do_standard_s4
    cmpb        [buffer],'5'
    je          do_standard_s5
jmp             abort

;; handle debug board size with switch
board_size_debug:
    cmpb        [buffer],'3'
    je          do_debug_s3
    cmpb        [buffer],'4'
    je          do_debug_s4
    cmpb        [buffer],'5'
    je          do_debug_s5
jmp             abort

;; print mines
print_mine_X:
    cmpb        [mn_en],1
    jne         print_mine_done
    cmp         r15b, byte [mn_off_X]
    jne         print_mine_done
    cmp         byte [mn_exp_X],1
    je          print_exploded_X
    mov         dl,'1'
jmp             print_mine_done
print_mine_O:
    cmpb        [mn_en],1
    jne         print_mine_done
    cmp         r15b, byte [mn_off_O]
    jne         print_mine_done
    cmp         byte [mn_exp_O],1
    je          print_exploded_O
    mov         dl,'2'
jmp             print_mine_done
print_exploded_X:
    mov         dl,'!'
jmp             print_mine_done
print_exploded_O:
    mov         dl,'@'
;; fallthrough (print_mine_done)
print_mine_done:
ret
;; end print mines

;; debug output for mines
debug_mine:
    mov         ecx,d_mn1               ; printing mine locations
    mov         edx,d_mn1_l
    call        print_int
    movzx       esi, byte [mn_off_X]    ; move location identifier into buffer
    movzx       edi, byte [d_mn_char+rsi]
    mov         [buffer],edi
    mov         ecx,buffer              ; print player X's location
    mov         edx,1
    call        print_int
    mov         ecx,d_mn2
    mov         edx,d_mn2_l             ; printing player O's mine location
    call        print_int
    movzx       esi, byte [mn_off_O]    ; move location identifier into buffer
    movzx       edi, byte [d_mn_char+rsi]
    mov         [buffer],edi
    movb        [buffer+1],0xA          ; extra newline after character
    mov         ecx,buffer              ; print player O's location
    mov         edx,2
    call        print_int
ret
;; end debug output for mines


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; s3 code ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
check_line_s3:                          ; the other offsets for places in the line are expected in esi and edi
    mov         bl,[m_p+p_char_off]     ; one of the player's char in bl
    add         bl,bl                   ; two of the player's char in bl
    sub         bl,[bd_s3+esi]          ; if matching char here, one char again
    sub         bl,[bd_s3+edi]          ; if matching char here, 0
    jz          win                     ; means there were two others of the same, three in a row
ret                                     ; otherwise return

;; debug printing
debug_board_s3:
    mov         ecx,d_bd1_s3            ; debug version of board: part 1 & board
    mov         edx,d_bd1_s3_l+bd_s3_l
    call        print_int
    mov         ecx,d_bd2               ; debug version of board: part 2
    mov         edx,d_bd2_l
    call        print_int
    mov         ecx,8                   ; Locations
hexboard_s3:
    mov         bl,[bd_s3+ecx]
    mov         dx,'20'
    cmp         bl,' '
    cmove       ax,dx
    mov         dx,'58'
    cmp         bl,'X'
    cmove       ax,dx
    mov         dx,'4F'
    cmp         bl,'O'
    cmove       ax,dx
    mov         [e_bd_s3+2*ecx+ecx],al
    mov         [e_bd_s3+2*ecx+ecx+1],ah
    dec         ecx
    jns         hexboard_s3
    mov         ecx,e_bd1_s3            ; hex version of board: part 1, board, part 2
    mov         edx,e_bd1_s3_l+e_bd_s3_l+e_bd2_s3_l
    call        print_int
    mov         ecx,m_bd1               ; message for hex version of board: part 1, board, part 2
    mov         edx,m_bd1_l+m_bd_l
    call        print_int
    call        debug_mine
ret
;; end debug printing

;; standard printing
print_board_s3:
    xor         esi,esi                 ; Row
nrow_s3:
    mov         edi,2                   ; Col
ncol_s3:
    mov         dl,[bd_s3+esi+edi]      ; Src
    xor         r15d,r15d
    mov         r15d,esi
    add         r15d,edi                ; current printing offest in r15d
    call        print_mine_X            ; each of the next 4 calls may modify dl, the last call having highest precedence
    call        print_mine_O
    mov         [bd_dv1_s3+edi*2],dl    ; Dst
    dec         edi
    jns         ncol_s3                 ; Three columns
    mov         ecx,bd_dv1_s3           ; empty dividers for board
    add         esi,3                   ; Next row
    cmp         esi,9                   ; Last row
    je          pdone_s3
    mov         edx,bd_dv1_s3_l+bd_dv2_s3_l
    call        print_int
    jmp         nrow_s3
pdone_s3:
    mov         edx,bd_dv1_s3_l
    call        print_int
ret
;; end standard printing

;; setup debug printing
do_debug_s3:
    movq        [pfunc],debug_board_s3
    mov         ecx,15                  ; Offset of last hexdigit of address
    mov         rdx, bd_s3              ; rdx will be tampered with
    mov         rbx, hexdigits          ; Table
memheader_s3:
    mov         rax,rdx                 ; Need nibble in al
    and         rax,0x000000000000000f
    xlatb                               ; al updated
    mov byte    [m_bd+ecx],al
    dec         ecx
    mov         rax,rdx                 ; Need nibble in al
    and         rax,0x00000000000000f0
    shr         rax,4                   ; This time, higher nibble
    xlatb                               ; al updated
    mov byte    [m_bd+ecx],al
    shr         rdx,8                   ; Next byte (two nibbles)
    dec         ecx
    jns         memheader_s3
jmp             place_mine_s3
;; end setup debug printing

;; setup standard printing
do_standard_s3:
    movb        [mn_en],0             ; turn off mine location printing
    movq        [pfunc],print_board_s3
jmp             place_mine_s3
;; end setup standard printing

;; placing mines onto the board
place_mine_s3:
    mov         byte [mn_exp_X],0       ; mines have not exploded yet
    mov         byte [mn_exp_O],0
    mov         ecx,m_p                 ; prompt player X to choose a mine location
    mov         edx,m_p_l
    call        print_int
    mov         ecx,m_mn_s3
    mov         edx,m_mn_s3_l
    call        print_int
    call        read_num                ; read in player X mine location
    cmp         bl,8
    ja          abort
    mov         byte [mn_off_X],bl      ; location into memory
    xor         byte [m_p+p_char_off],p_switch  ; switch players
    mov         ecx,m_p                 ; prompt player O to choose a mine location
    mov         edx,m_p_l
    call        print_int
    mov         ecx,m_mn_s3
    mov         edx,m_mn_s3_l
    call        print_int
    call        read_num                ; read in player O mine location
    cmp         bl,8
    ja          abort
    mov         byte [mn_off_O],bl      ; location into memory
    xor         byte [m_p+p_char_off],p_switch  ; switch players
jmp             play_s3

;; output for invalid input
invalid_s3:
    mov         ecx,m_err               ; error messge for invalid position
    mov         edx,m_err_l
    call        print_int
;; fallthrough (play_s3)

;; setup is done, now let's play
play_s3:
    ;; print messages and board
    mov         ecx,m_p                 ; prompt player to choose spot on board
    mov         edx,m_p_l
    call        print_int
    mov         ecx,m_p2_s3
    mov         edx,m_p2_s3_l
    call        print_int
    call        [pfunc]
    ;; read position input
    call        read_num
    mov         eax,ebx
    ;; validate position range
    cmp         al,8
    ja          invalid_s3
    ;; position is valid in the range
    ;; validate position is empty
    cmpb        [bd_s3+eax],' '         ; Is empty?
    jne         invalid_s3
    ;; check for mines
    call        check_mine
    ;; position is fully valid
    mov         bl,[m_p+p_char_off]
    mov         [bd_s3+eax],bl          ; Place mark
    ;; check if winning move
    movzx       ecx, byte [wins_s3+eax] ; Terms (adjusted)
pair_s3:
    movzx       esi, byte [god_s3+eax*8+ecx]
    dec         ecx
    movzx       edi, byte [god_s3+eax*8+ecx]
    call        check_line_s3
    dec         ecx
    jns         pair_s3                 ; Next term pair
    decb        [turns_s3]              ; Check if tie
    jz          tie
    xorb        [m_p+p_char_off],p_switch   ; Ready the other player's mark
jmp             play_s3


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; s4 code ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
check_line_s4:                          ; the other offsets for places in the line are expected in esi, edi, and r8d
    xor         bx,bx
    xor         r14w,r14w
    mov         r14b,[m_p+p_char_off]   ; player's char copy in r14
    add         bx,r14w                 ; one of the player's char in bx
    add         bx,r14w                 ; two of the player's char in bx
    add         bx,r14w                 ; three of the player's char in bx

    xor         r15w,r15w
    mov         r15b,[bd_s4+esi]
    sub         bx,r15w                 ; if matching char here, two chars again
    mov         r15b,[bd_s4+edi]
    sub         bx,r15w                 ; if matching char here, one char again
    mov         r15b,[bd_s4+r8d]
    sub         bx,r15w                 ; if matching char here, 0
    jz          win                     ; means there were three others of the same, four in a row
ret                                     ; otherwise return

;; debug printing
debug_board_s4:
    mov         ecx,d_bd1_s4            ; debug version of board: part 1 & board
    mov         edx,d_bd1_s4_l+bd_s4_l
    call        print_int
    mov         ecx,d_bd2               ; debug version of board: part 2
    mov         edx,d_bd2_l
    call        print_int
    mov         ecx,8                   ; Locations
hexboard_s4:
    mov         bl,[bd_s4+ecx]
    mov         dx,'20'
    cmp         bl,' '
    cmove       ax,dx
    mov         dx,'58'
    cmp         bl,'X'
    cmove       ax,dx
    mov         dx,'4F'
    cmp         bl,'O'
    cmove       ax,dx
    mov         [e_bd_s3+2*ecx+ecx],al
    mov         [e_bd_s3+2*ecx+ecx+1],ah
    dec         ecx
    jns         hexboard_s4
    mov         ecx,e_bd1_s4            ; hex version of board: part 1, board, part 2
    mov         edx,e_bd1_s4_l+e_bd_s4_l+e_bd2_s4_l
    call        print_int
    mov         ecx,m_bd1               ; other hex version of board: part 1, board, part 2
    mov         edx,m_bd1_l+m_bd_l
    call        print_int
    call        debug_mine
ret
;; end debug printing

;; standard printing
print_board_s4:
    xor         esi,esi                 ; Row
nrow_s4:
    mov         edi,3                   ; Col
ncol_s4:
    mov         dl,[bd_s4+esi+edi]      ; Src
    xor         r15d,r15d
    mov         r15d,esi
    add         r15d,edi                ; current printing offest in r15d
    call        print_mine_X            ; each of the next 4 calls may modify dl, the last call having highest precedence
    call        print_mine_O
    mov         [bd_dv1_s4+edi*2],dl    ; Dst
    dec         edi
    jns         ncol_s4                 ; Three columns
    mov         ecx,bd_dv1_s4           ; empty dividers for board
    add         esi,4                   ; Next row
    cmp         esi,16                  ; Last row
    je          pdone_s4
    mov         edx,bd_dv1_s4_l+bd_dv2_s4_l
    call        print_int
    jmp         nrow_s4
pdone_s4:
    mov         edx,bd_dv1_s4_l
    call        print_int
ret
;; end standard printing

;; setup debug printing
do_debug_s4:
    movq        [pfunc],debug_board_s4
    mov         ecx,15                  ; Offset of last hexdigit of address
    mov         rdx, bd_s4              ; rdx will be tampered with
    mov         rbx, hexdigits          ; Table
memheader_s4:
    mov         rax,rdx                 ; Need nibble in al
    and         rax,0x000000000000000f
    xlatb                               ; al updated
    mov byte    [m_bd+ecx],al
    dec         ecx
    mov         rax,rdx                 ; Need nibble in al
    and         rax,0x00000000000000f0
    shr         rax,4                   ; This time, higher nibble
    xlatb                               ; al updated
    mov byte    [m_bd+ecx],al
    shr         rdx,8                   ; Next byte (two nibbles)
    dec         ecx
    jns         memheader_s4
jmp             place_mine_s4
;; end setup debug printing

;; setup standard printing
do_standard_s4:
    movq        [pfunc],print_board_s4
jmp             place_mine_s4
;; end setup standard printing

;; placing mines onto the board
place_mine_s4:
    mov         byte [mn_exp_X],0       ; mines have not exploded yet
    mov         byte [mn_exp_O],0
    movb        [mn_en],0               ; turn off mine location printing
    mov         ecx,m_p                 ; prompt player X to choose a mine location
    mov         edx,m_p_l
    call        print_int
    mov         ecx,m_mn_s4
    mov         edx,m_mn_s4_l
    call        print_int
    call        read_num                ; read in player X mine location
    cmp         bl,15
    ja          abort
    mov         byte [mn_off_X],bl      ; location into memory
    xor         byte [m_p+p_char_off],p_switch  ; switch players
    mov         ecx,m_p                 ; prompt player O to choose a mine location
    mov         edx,m_p_l
    call        print_int
    mov         ecx,m_mn_s4
    mov         edx,m_mn_s4_l
    call        print_int
    call        read_num                ; read in player O mine location
    cmp         bl,15
    ja          abort
    mov         byte [mn_off_O],bl      ; location into memory
    xor         byte [m_p+p_char_off],p_switch  ; switch players
jmp             play_s4

;; output for invalid input
invalid_s4:
    mov         ecx,m_err               ; error messge for invalid position
    mov         edx,m_err_l
    call        print_int
;; fallthrough (play_s4)

;; setup is done, now let's play
play_s4:
    ;; print messages and board
    mov         ecx,m_p                 ; prompt player to choose spot on board
    mov         edx,m_p_l
    call        print_int
    mov         ecx,m_p2_s4
    mov         edx,m_p2_s4_l
    call        print_int
    call        [pfunc]
    ;; read position input
    call        read_num
    mov         eax,ebx
    ;; validate position range
    cmp         al,15
    ja          invalid_s4
    ;; position is valid in the range
    ;; validate position is empty
    cmpb        [bd_s4+eax],' '         ; Is empty?
    jne         invalid_s4
    ;; check for mines
    call        check_mine
    ;; position is fully valid
    mov         bl,[m_p+p_char_off]
    mov         [bd_s4+eax],bl          ; Place mark
    ;; check if winning move
    movzx       ecx, byte [wins_s4+eax] ; Terms (adjusted)
    add         eax,eax                 ; double eax to fake a scale size of 16 in addressing
pair_s4:
    movzx       esi, byte [god_s4+eax*8+ecx]
    dec         ecx
    movzx       edi, byte [god_s4+eax*8+ecx]
    dec         ecx
    movzx       r8d, byte [god_s4+eax*8+ecx]
    call        check_line_s4
    dec         ecx
    jns         pair_s4                 ; Next term tripple
    decb        [turns_s4]              ; Check if tie
    jz          tie
    xorb        [m_p+p_char_off],p_switch   ; Ready the other player's mark
jmp             play_s4


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; s5 code ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
check_line_s5:                          ; the other offsets for places in the line are expected in esi, edi, r8d, and r9d
    xor         bx,bx
    xor         r14w,r14w
    mov         r14b,[m_p+p_char_off]   ; player's char copy in r14
    add         bx,r14w                 ; one of the player's char in bx
    add         bx,r14w                 ; two of the player's char in bx
    add         bx,r14w                 ; three of the player's char in bx
    add         bx,r14w                 ; four of the player's char in bx

    xor         r15w,r15w
    mov         r15b,[bd_s5+esi]
    sub         bx,r15w                 ; if matching char here, three chars again
    mov         r15b,[bd_s5+edi]
    sub         bx,r15w                 ; if matching char here, two chars again
    mov         r15b,[bd_s5+r8d]
    sub         bx,r15w                 ; if matching char here, one char again
    mov         r15b,[bd_s5+r9d]
    sub         bx,r15w                 ; if matching char here, 0
    jz          win                     ; means there were four others of the same, five in a row
ret                                     ; otherwise return


;; debug printing
debug_board_s5:
    mov         ecx,d_bd1_s5            ; debug version of board: part 1 & board
    mov         edx,d_bd1_s5_l+bd_s5_l
    call        print_int
    mov         ecx,d_bd2               ; debug version of board: part 2
    mov         edx,d_bd2_l
    call        print_int
    mov         ecx,8                   ; Locations
hexboard_s5:
    mov         bl,[bd_s5+ecx]
    mov         dx,'20'
    cmp         bl,' '
    cmove       ax,dx
    mov         dx,'58'
    cmp         bl,'X'
    cmove       ax,dx
    mov         dx,'4F'
    cmp         bl,'O'
    cmove       ax,dx
    mov         [e_bd_s5+2*ecx+ecx],al
    mov         [e_bd_s5+2*ecx+ecx+1],ah
    dec         ecx
    jns         hexboard_s5
    mov         ecx,e_bd1_s5            ; hex version of board: part 1, board, part 2
    mov         edx,e_bd1_s5_l+e_bd_s5_l+e_bd2_s5_l
    call        print_int
    mov         ecx,m_bd1               ; other hex version of board: part 1, board, part 2
    mov         edx,m_bd1_l+m_bd_l
    call        print_int
    call        debug_mine
ret
;; end debug printing

;; standard printing
print_board_s5:
    xor         esi,esi                 ; Row
nrow_s5:
    mov         edi,4                   ; Col
ncol_s5:
    mov         dl,[bd_s5+esi+edi]      ; Src
    xor         r15d,r15d
    mov         r15d,esi
    add         r15d,edi                ; current printing offest in r15d
    call        print_mine_X            ; each of the next 4 calls may modify dl, the last call having highest precedence
    call        print_mine_O
    mov         [bd_dv1_s5+edi*2],dl    ; Dst
    dec         edi
    jns         ncol_s5                 ; Three columns
    mov         ecx,bd_dv1_s5           ; empty dividers for board
    add         esi,5                   ; Next row
    cmp         esi,25                  ; Last row
    je          pdone_s5
    mov         edx,bd_dv1_s5_l+bd_dv2_s5_l
    call        print_int
    jmp         nrow_s5
pdone_s5:
    mov         edx,bd_dv1_s5_l
    call        print_int
ret
;; end standard printing

;; setup debug printing
do_debug_s5:
    movq        [pfunc],debug_board_s5
    mov         ecx,15                  ; Offset of last hexdigit of address
    mov         rdx, bd_s5              ; rdx will be tampered with
    mov         rbx, hexdigits          ; Table
memheader_s5:
    mov         rax,rdx                 ; Need nibble in al
    and         rax,0x000000000000000f
    xlatb                               ; al updated
    mov byte    [m_bd+ecx],al
    dec         ecx
    mov         rax,rdx                 ; Need nibble in al
    and         rax,0x00000000000000f0
    shr         rax,4                   ; This time, higher nibble
    xlatb                               ; al updated
    mov byte    [m_bd+ecx],al
    shr         rdx,8                   ; Next byte (two nibbles)
    dec         ecx
    jns         memheader_s5
jmp             place_mine_s5
;; end setup debug printing

;; setup standard printing
do_standard_s5:
    movq        [pfunc],print_board_s5
jmp             place_mine_s5
;; end setup standard printing

;; placing mines onto the board
place_mine_s5:
    mov         byte [mn_exp_X],0       ; mines have not exploded yet
    mov         byte [mn_exp_O],0
    movb        [mn_en],0               ; turn off mine location printing
    mov         ecx,m_p                 ; prompt player X to choose a mine location
    mov         edx,m_p_l
    call        print_int
    mov         ecx,m_mn_s5
    mov         edx,m_mn_s5_l
    call        print_int
    call        read_num                ; read in player X mine location
    cmp         bl,24
    ja          abort
    mov         byte [mn_off_X],bl      ; location into memory
    xor         byte [m_p+p_char_off],p_switch  ; switch players
    mov         ecx,m_p                 ; prompt player O to choose a mine location
    mov         edx,m_p_l
    call        print_int
    mov         ecx,m_mn_s5
    mov         edx,m_mn_s5_l
    call        print_int
    call        read_num                ; read in player O mine location
    cmp         bl,24
    ja          abort
    mov         byte [mn_off_O],bl      ; location into memory
    xor         byte [m_p+p_char_off],p_switch  ; switch players
jmp             play_s5

;; output for invalid input
invalid_s5:
    mov         ecx,m_err               ; error messge for invalid position
    mov         edx,m_err_l
    call        print_int
;; fallthrough (play_s5)

;; setup is done, now let's play
play_s5:
    ;; print messages and board
    mov         ecx,m_p                 ; prompt player to choose spot on board
    mov         edx,m_p_l
    call        print_int
    mov         ecx,m_p2_s5
    mov         edx,m_p2_s5_l
    call        print_int
    call        [pfunc]
    ;; read position input
    call        read_num
    mov         eax,ebx
    ;; validate position range
    cmp         al,24
    ja          invalid_s5
    ;; position is valid in the range
    ;; validate position is empty
    cmpb        [bd_s5+eax],' '         ; Is empty?
    jne         invalid_s5
    ;; check for mines
    call        check_mine
    ;; position is fully valid
    mov         bl,[m_p+p_char_off]
    mov         [bd_s5+eax],bl          ; Place mark
    ;; check if winning move
    movzx       ecx, byte [wins_s5+eax] ; Terms (adjusted)
    add         eax,eax                 ; double eax to fake a scale size of 16 in addressing
pair_s5:
    movzx       esi, byte [god_s5+eax*8+ecx]
    dec         ecx
    movzx       edi, byte [god_s5+eax*8+ecx]
    dec         ecx
    movzx       r8d, byte [god_s5+eax*8+ecx]
    dec         ecx
    movzx       r9d, byte [god_s5+eax*8+ecx]
    call        check_line_s5
    dec         ecx
    jns         pair_s5                 ; Next term tripple
    decb        [turns_s5]              ; Check if tie
    jz          tie
    xorb        [m_p+p_char_off],p_switch   ; Ready the other player's mark
jmp             play_s5
