; ----------------------------------------------------------
; NASM test program
;-----------------------------------------------------------

		global _start
		
		section .text

_start: 	mov	rsi, message
		push	0x64
		push 	greater
		
		
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

putline:	mov	rdx, rsi
		call 	strlen
		mov 	rax, 1
		mov	rdi, 1
		syscall
		ret
		

;--------------------------------------------------
; Finds zero-terminated string length.
; Enter: RDX - pointer to string
; Uses: RAX, RDX
; Output: RDX - length
;---------------------------------------------------
strlen:		mov 	rax, rdx
lenCycle:	cmp 	byte [rdx], 0
		je	lenCycleEnd
		inc	rdx			
		jmp	lenCycle
lenCycleEnd:	sub rdx, rax
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
		jne	parseEnd
		
		push	rsi
		mov 	rsi, [rbp]
		add	rbp, 8
		call 	putline
		pop 	rsi
		jmp 	parseEnd
		
parseEnd:	ret


		section .data
message:	db 	"Hello,%s %% %c!", 10, 0
greater:	db	"I am the test string", 0	
