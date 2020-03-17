; ----------------------------------------------------------
; NASM printf implementation (c) fckxorg, 2020
;-----------------------------------------------------------

		global _start
		
		section .text

_start: 	mov	rsi, message
		push	0x64
		push 	greater
		push	15
		push 	36
		push 	72
		xor	rax, rax
		mov	rax, 0x8000000a
		push	rax
		xor	rax, rax
		push 	10
		
		call 	printf
		
		mov 	rax, 60
		xor 	rdi, rdi
		syscall

;--------------------------------------------------------
; Outputs format string to stdout
; Enter: RSI - string address
; Uses:	RAX, RDX, RDI, RSI
;--------------------------------------------------------
printf:		push	rbp
		mov 	rbp, rsp
		add 	rbp, 0x10
nextCharacter:	cmp 	byte [rsi], 0
		je	formatLineEnd
		
		cmp 	byte [rsi], 0x25 ; checking if symbol is format specifier
		jne	usualChar
	
		call 	formatParse
		inc 	rsi
		jmp 	nextCharacter
	

usualChar:	call 	putc
		inc 	rsi
		jmp 	nextCharacter
formatLineEnd:	pop 	rbp
		ret	

;----------------------------------------------------
; Outputs ASCII-character located in provided memory
; address.
; Enter: RSI - memory address.
; Uses:	RAX, RDX, RDI, RSI
;----------------------------------------------------
putc:		mov 	rax, 1 ; syscall write 
		mov 	rdx, 1 ; size of buffer to output
		mov 	rdi, 1 ; file descriptor of stdout
		syscall
		ret

;-------------------------------------------------------
; Puts string to stdout
; Enter: RSI - pointer to zero-terminated string
; Uses:	RDX, RAX, RDI, RSI
;-------------------------------------------------------
putline:	mov	rdx, rsi
		call 	strlen
		mov 	rdx, rax
		mov 	rax, 1
		mov	rdi, 1
		syscall
		ret

;------------------------------------------------------------
; Outputs value of RAX to stdout as integer in number system 
; defined in RCX. 
; Eneter: RAX - number, RCX - number system
; Uses: RDX, RBX, RSI, RDI, R0
;------------------------------------------------------------
itoa:		mov 	rbx, charTable
		mov 	r8, 31	
renomCycle:	cmp	rax, 0
		je 	renomCycleEnd
		xor	rdx, rdx
		div	rcx
		push	rax
		mov 	rax, rdx	
		xlat
		mov	[revItoaBuff + r8], al
		pop 	rax
		dec	r8
		xor	rdx, rdx
		jmp 	renomCycle
		
		
renomCycleEnd:	mov 	rsi, revItoaBuff
		add 	rsi, r8
		add 	rsi, 1
		call 	putline
		ret
		

;--------------------------------------------------
; Finds zero-terminated string length.
; Enter: RDX - pointer to string
; Uses: RAX, RDX
; Output: RDX - length
;---------------------------------------------------
strlen:		mov 	rax, rdx
lenCycle:	cmp 	byte [rax], 0
		je	lenCycleEnd
		inc	rax			
		jmp	lenCycle
lenCycleEnd:	sub rax, rdx
		ret
;-----------------------------------------------------
; Parses printf format specifiers and calls handlers
; for each specifier
; Enter: RSI - pointer to format specifier
;----------------------------------------------------
formatParse:	inc 	rsi
		cmp	byte [rsi], 0x25 ; checking if we need to output %
		jne 	checkChar
		call 	putc
		jmp 	parseEnd

checkChar:	cmp	byte [rsi], 0x63 ; cheking if need to output char
		jne 	checkStr
		
		push 	rsi	
		mov 	rsi, rbp
		add	rbp, 8

		call	putc
		pop 	rsi
		jmp 	parseEnd

checkStr:	cmp	byte [rsi], 0x73
		jne	checkUint
		
		push	rsi
		mov 	rsi, [rbp]
		add	rbp, 8
		call 	putline
		pop 	rsi
		jmp 	parseEnd

checkUint:	cmp 	byte [rsi], 0x75
		jne	checkHex
		mov	rax, [rbp]
		add 	rbp, 8
		mov 	rcx, 10
		push	rsi
		call 	itoa
		pop	rsi
		jmp	parseEnd

checkHex:	cmp	byte [rsi], 0x78
		jne	checkOct
		mov 	rax, [rbp]
		add	rbp, 8
		mov	rcx, 16
		push 	rsi
		call	itoa
		pop	rsi
		jmp	parseEnd

checkOct:	cmp	byte [rsi], 0x6f
		jne	checkInt
		mov 	rax, [rbp]
		add	rbp, 8
		mov	rcx, 8
		push 	rsi
		call	itoa
		pop	rsi
		jmp	parseEnd

checkInt:	cmp	byte [rsi], 0x64
		jne	parseEnd
		
		mov 	rax, [rbp]
		add	rbp, 8
		push 	rax
		
		shr 	rax, 31
		cmp 	rax, 1
		jne	positive
		push	rsi
		mov	rsi, sign
		call 	putc
		pop 	rsi
		pop	rax
		shl	rax, 33
		shr	rax, 33
		push 	rax
				

positive:	pop 	rax
		mov	rcx, 10
		push	rsi
		call 	itoa
		pop 	rsi
		ret
		
		
parseEnd:	ret


		section .data
message:	db 	"Hello,%d %d %x %o %u %s %% %c!", 10, 0
greater:	db	"I am the test string", 0	
charTable:	db	"0123456789abcdef"
sign:		db	"-"

		section	.bss
itoaBuff:	resb	32
revItoaBuff:	resb	32
