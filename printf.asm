; ----------------------------------------------------------
; NASM printf implementation (c) fckxorg, 2020
;-----------------------------------------------------------

		global _start
		
		section .text

_start: 	    push	qword 0x64   ; Pushing bunch of args 		
                push 	qword 127    ; to stack and calling printf
                push	qword 0x21
                push	qword 100
                push 	qword 3802
                push 	qword greater
                push 	qword format
                call 	printf
                
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


;--------------------------------------------------------
; Outputs formatted string to stdout
; Enter: push args through stack: format, then values for
; fromat specifiers 
; Uses:	RAX, RDX, RDI, RSI, RBP
;--------------------------------------------------------
printf:		    push	rbp
                mov 	rbp, rsp
                add 	rbp, 0x10                   ; setting up stack frame

                mov	    rsi, [rbp]                  ; getting format string
                add	    rbp, 8

nextCharacter:	cmp 	byte [rsi], 0
                je	    formatLineEnd
            
                cmp 	byte [rsi], 0x25 	        ; checking if symbol is format specifier
                jne	    usualChar
                
                push 	rsi			                ; if so, printing accumulated symbols
                mov	    rdx, [bufferStart]
                sub	    rsi, rdx
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
formatLineEnd:	
                pop 	rbp			                ; restoring rbp
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
                mov 	rax, 1
                mov	    rdi, 1
                syscall
                ret

;------------------------------------------------------------
; Outputs value of RAX to stdout as integer in number system 
; defined in RCX. 
; Eneter: RAX - number, RCX - number system
; Uses: RDX, RBX, RSI, RDI, R0
;------------------------------------------------------------
itoa:		    mov 	rbx, charTable
		        mov 	r8, 31	
renomLoop:	    cmp	    rax, 0
		        je 	    renomLoopEnd
		        xor	    rdx, rdx
                div	    rcx
                push	rax
                mov 	rax, rdx	
                xlat
                mov	    [revItoaBuff + r8], al
                pop 	rax
                dec	    r8
                xor	    rdx, rdx
                jmp 	renomLoop
		
		
renomLoopEnd:	mov 	rsi, revItoaBuff
		        add 	rsi, r8
		        add 	rsi, 1
		        call 	putline
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
                cmp	    byte [rsi], 0x25 ; checking if we need to output %
                jne 	checkChar
                putc
                jmp 	parseEnd

checkChar:	    cmp	    byte [rsi], 0x63 ; cheking if need to output char
                jne 	checkStr
                
                push 	rsi	
                mov 	rsi, rbp
                add	    rbp, 8

                putc
                pop 	rsi
                jmp 	parseEnd

checkStr:	    cmp	    byte [rsi], 0x73
		        jne	    checkUint
		
                push	rsi
                mov 	rsi, [rbp]
                add	    rbp, 8
                call 	putline
                pop 	rsi
                jmp 	parseEnd

checkUint:	    cmp     byte [rsi], 0x75
                jne	    checkHex
                parse_print_int 10
                jmp	    parseEnd

checkHex:	    cmp	    byte [rsi], 0x78
                jne	    checkOct
                parse_print_int	16
                jmp	    parseEnd

checkOct:	    cmp	    byte [rsi], 0x6f
                jne	    checkBin
                parse_print_int	8
                jmp	    parseEnd

checkBin:	    cmp	    byte [rsi], 0x62
                jne	    checkInt
                parse_print_int	2
                jmp	    parseEnd


checkInt:	    cmp	    byte [rsi], 0x64
		        jne	    parseEnd
		
		        mov 	rax, [rbp]
	    	    add	    rbp, 8
		
                cmp	    rax, 0
                jg	    positive	
                push	rsi
                mov	    rsi, 0x2d
                putc
                pop 	rsi
                shl	    rax, 33
                shr	    rax, 33
                        

positive:	    mov 	rcx, 10
		        push	rsi
		        call 	itoa
		        pop 	rsi
		        ret
		
		
parseEnd:	    ret


		section .data
format:		    db 	"I %s %x %d%%%c%b", 10, 0
greater:	    db	"love", 0	
charTable:	    db	"0123456789abcdef"
bufferStart:	dd	format

		section	.bss
itoaBuff:	    resb	32
revItoaBuff:	resb	32
