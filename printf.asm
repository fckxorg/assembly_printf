; ----------------------------------------------------------
; NASM printf implementation (c) fckxorg, 2020
;-----------------------------------------------------------

		global _start
		
		section .text

buffSize        equ     31
signShift       equ     33

main: 	        push    qword '!'
                push    qword edastr
                push 	qword 127  ; Pushing bunch of args
                push	qword '!' ; to stack and calling printf
                push	qword 100
                push 	qword 3802
                push 	qword greater
                push 	qword format
                call 	printf
                add     rsp, 0x40
                ret

_start:         call    main                
                mov 	rax, 60
                xor 	rdi, rdi ; finishing execution
                syscall

%macro	parse_print_int 1
                mov	    rax, [rbp]
                add 	rbp, 8
                mov 	rcx, %1
                push	rsi
                call 	itoa
                pop	    rsi
%endmacro


%macro  putc 0
                mov     rdx, 1
                call    printNChars
%endmacro

%macro  get_arg 1
                mov     %1, [rbp]
                add     rbp, 8
%endmacro


;--------------------------------------------------------
; Outputs formatted string to stdout
; Enter: push args through stack: format, then values for
; fromat specifiers 
;--------------------------------------------------------
printf:		    push	rbp
                mov 	rbp, rsp
                add 	rbp, 0x10                   ; setting up stack frame
                push    rdi 
                push    rsi 
                push    r8    

                get_arg rsi                         ; getting format string


nextCharacter:	cmp 	byte [rsi], 0
                je	    formatLineEnd
            
                cmp 	byte [rsi], 0x25 	        ; checking if symbol is format specifier
                jne	    usualChar
                
                push 	rsi			                ; if so, printing accumulated symbols
                sub	    rsi, [bufferStart]
                mov	    rdx, rsi
                mov	    rsi, [bufferStart]
                call	printNChars		            ; calling format parser
                pop 	rsi
            
                call 	formatParse
                inc 	rsi
                mov 	[bufferStart], rsi	        ; changing position of pointer to not-formatted
                jmp 	nextCharacter		        ; part of string
        

usualChar:	    inc 	rsi			                ; if usual character, just increase pointer to
		        jmp 	nextCharacter		        ; current character in format string
formatLineEnd:	pop 	r8 
                pop     rsi 
                pop     rdi 
                pop     rbp	
                
		        ret	


;----------------------------------------------------
; Outputs part of the provided buffer with length of 
; n symbols
; Enter: RSI - buffer address, RDX - n characters 
; to output
; Uses:	RAX, RDX, RDI, RSI
;----------------------------------------------------
printNChars:    mov     rax, 1                      ; system call write
		        mov	    rdi, 1                      ; stdout
		        syscall
		        ret

;-------------------------------------------------------
; Puts string to stdout
; Enter: RDI - pointer to zero-terminated string
; Uses:	RDX, RAX, RDI, RSI
;-------------------------------------------------------
putline:	    mov	    rdi, rsi 
                call 	strlen
                mov 	rdx, rax
                call    printNChars
                ret

;------------------------------------------------------------
; Outputs value of RAX to stdout as decimal 
; Eneter: RAX - number
; Uses: RDX, RBX, RCX, RSI, RDI, R0
;------------------------------------------------------------
itoaDec:		mov 	rbx, charTable
		        mov 	r8, buffSize	
                mov     rcx, 10
.renomLoop:	    cmp	    rax, 0
		        je 	    .renomLoopEnd
		        xor	    rdx, rdx
                div	    rcx
                push	rax
                mov 	rax, rdx	
                xlat
                mov	    [revItoaBuff + r8], al                  ; writing to reversed buffer         
                pop 	rax
                dec	    r8
                xor	    rdx, rdx
                jmp 	.renomLoop
		
		
.renomLoopEnd:	mov 	rsi, revItoaBuff
		        add 	rsi, r8
		        add 	rsi, 1
		        call 	putline
		        ret
	
;------------------------------------------------------------
; Outputs value of RAX to stdout as integer in system, that
; is a degree of 2
; Eneter: RAX - number, RCX - number system
; Uses: RDX, RBX,RCX, RSI, RDI, R0
;------------------------------------------------------------
itoaBin:	    mov     rdx, rcx                                ; creating mask
                dec     rdx
                bsr     rcx, rcx
                mov     rbx, charTable
		        mov 	r8, buffSize	
.renomLoop:	    cmp	    rax, 0
		        je 	    .renomLoopEnd
                push	rax
                and     rax, rdx
                xlat
                mov	    [revItoaBuff + r8], al                  ; writing to reversed buffer         
                pop 	rax
                dec	    r8
                shr     rax, cl
                jmp 	.renomLoop
.renomLoopEnd:	mov 	rsi, revItoaBuff
		        add 	rsi, r8
		        add 	rsi, 1
		        call 	putline
		        ret	

;===============================================
; Wrapper-selector for itoaDec and itoaBin
; For the list of parameters look to itoaBin
; and itoaDec
;================================================
itoa:          cmp      rcx, 10
               jne      binRel
               call     itoaDec
               ret
binRel:        call     itoaBin
               ret


;--------------------------------------------------
; Finds zero-terminated string length.
; Enter: RDI - pointer to string
; Uses: RAX, RDI, RCX
; Output: RAX - length
;---------------------------------------------------
strlen:		    push    rdi
                xor     rax, rax
                xor     rcx, rcx
                not     rcx
                repne   scasb
                mov     rax, rdi
                pop     rdi
                sub 	rax, rdi
		        ret
;-----------------------------------------------------
; Parses printf format specifiers and calls handlers
; for each specifier
; Enter: RSI - pointer to format specifier
;----------------------------------------------------
formatParse:	inc 	rsi
                cmp	    byte [rsi], '%' ; checking if we need to output %
                jne 	checkChar
                putc
                jmp 	parseEnd

checkChar:	    cmp	    byte [rsi], 'c' ; cheking if need to output char
                jne 	checkStr
                
                push 	rsi	
                mov     rsi, rbp
                putc
                add     rbp, 8
                pop 	rsi
                jmp 	parseEnd

checkStr:	    cmp	    byte [rsi], 's'
		        jne	    checkUint
		
                push	rsi
                get_arg rsi
                call 	putline
                pop 	rsi
                jmp 	parseEnd

checkUint:	    cmp     byte [rsi], 'u'
                jne	    checkHex
                parse_print_int 10
                jmp	    parseEnd

checkHex:	    cmp	    byte [rsi], 'x'
                jne	    checkOct
                parse_print_int	16
                jmp	    parseEnd

checkOct:	    cmp	    byte [rsi], 'o'
                jne	    checkBin
                parse_print_int	8
                jmp	    parseEnd

checkBin:	    cmp	    byte [rsi], 'b'
                jne	    checkInt
                parse_print_int	2
                jmp	    parseEnd


checkInt:	    cmp	    byte [rsi], 'd'
		        jne	    parseEnd
		
	            get_arg rax	
                cmp	    rax, 0
                jg	    positive	
                push	rsi
                mov	    rsi, sign
                putc
                pop 	rsi
                shl	    rax, signShift
                shr	    rax, signShift
                        

positive:	    mov 	rcx, 10
		        push	rsi
		        call 	itoa
		        pop 	rsi
		        ret
		
		
parseEnd:	    ret


		section .data
format:		    db 	"I %s %x %d%%%c%b%s%c", 10, 0
greater:	    db	"love", 0	
edastr:         db  ", especially in Phystech.Bio!", 0
charTable:	    db	"0123456789abcdef"
degTable:       db  1, 2, 4
sign:           db  "-"
bufferStart:	dd	format

		section	.bss
itoaBuff:	    resb	32
revItoaBuff:	resb	32
