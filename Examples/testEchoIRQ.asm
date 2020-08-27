;
; Test Echo using serial port and IRQ - HW ref: A250220 (V20-MBC)
;
; The IRQ vector 33 is used to receive a char from the virtual serial port.
;
; REQUIRED: IOS S260320-R230520 (or following revisions until stated otherwise).
;
; Assemble with "nasm -f bin  filename.asm -o filename.bin"
;
    CPU     8086            ; Set 8086/8088 opcodes only
    BITS    16              ; Set default 16 bit

; Commons ASCII chars
eos         equ     0x00    ; End of string
cr          equ     0x0d    ; Carriage return
lf          equ     0x0a    ; Line feed
prompt      equ     '>'     ; Prompt char
    
; IOS equates
EXC_WR_OPCD equ    0x00     ; Address of the EXECUTE WRITE OPCODE write port
EXC_RD_OPCD equ    0x00     ; Address of the EXECUTE READ OPCODE read port
STO_OPCD    equ    0x01     ; Address of the STORE OPCODE write port
SERIAL_RX   equ    0x01     ; Address of the SERIAL RX read port
SYSFLAGS    equ    0x02     ; Address of the SYSFLAGS read port
SERTX_OPC   equ    0x01     ; SERIAL TX opcode
SET_IRQ_OPC equ    0x02     ; SET IRQ opcode

    org  0x0000
start:
    jmp     init
    
    times   0x0084-$+start      db 0        ; Vectors 0 to 32 reserved area (33*4=132=0x84).
                                            ; Fill 0s until address 0x0084
    
IRQ33_Vector:
    dw      readRx_ISR      ; ISR Offset
    dw      0x0000          ; ISR Segment
    
; -------------------------------------------------------------------
    
    ;
    ; Read a char from the serial rx and store it
    ;
readRx_ISR:
    push    ax
    in      al, SERIAL_RX   ; Read a char from the serial port
    mov     [rxchar], al        ; Store it
    mov     [rxflag], byte 1
    pop     ax
    sti                     ; Re-enable interrupts
    iret

    ; -------------------------------------------------------------------
    
    ;
    ; Init
    ;
init:
    mov     ax, cs          ; DS = SS = CS
    mov     ds, ax
    mov     ss, ax
    mov     sp, stack       ; Set the stack
    ;
    ; Enable IRQ trigger (vector 33) from IOS
    ;
    mov     al, SET_IRQ_OPC ; AL = SET IRQ opcode
    out     STO_OPCD, al    ; Write the opcode
    mov     al, 1           ; Set the Serial Rx IRQ enable code
    out     EXC_WR_OPCD, al ; Enable the IRQ trigger on Serial Rx
    sti                     ; Enable CPU IRQ
    ;
    ; Print a message and the prompt
    ;
    mov     bx, msg
    call    puts
    mov     ah, prompt
    call    putc
    ;
    ; Echo loop
    ;
eloop:
    mov     al, [rxflag]
    or      al, al          ; Is a valid char stored (AL > 0)?
    jz      eloop           ; No, jump
    cli                     ; Yes, disable IRQ
    mov     ah, [rxchar]    ; Read the char
    mov     [rxflag], byte 0; Reset the char flag
    sti                     ; Re-enable IRQ
    call    putc            ; Print it
    jmp     eloop           ; Continue for ever...
    
; =========================================================================== ;
;
; Send a string to the serial line, DX contains the pointer to the string.
; NOTE: Only AX and BX are used
;
; =========================================================================== ;
puts:
    mov     ah, [bx]        ; AL = current char to print
    cmp     ah, eos         ; End of string reached?
    jz      puts_end        ; Yes, jump
    call    putc            ; Print the char in AH
    inc     bx              ; Increment character pointer
    jmp     puts            ; Transmit next character
    
puts_end:
    ret
    
; =========================================================================== ;
;
; Send a single character to the serial line (AH contains the character)
; NOTE: Only AL and AH are used
;
; =========================================================================== ;
putc:
    mov     al, SERTX_OPC   ; AL = SERIAL TX opcode
    out     STO_OPCD, al    ; Write the opcode
    mov     al, ah
    out     EXC_WR_OPCD, al ; Print char in AL
    ret
    
rxchar  db  0
rxflag  db  0
msg     db  'Echo test using the serial port', cr, cr, lf, eos  ; eos is the string terminator

        times   64   db  0                                  ; Space for the local Stack
stack: