; ----------------------------------------------------------
; NASM test program
;-----------------------------------------------------------

		global _start
		
		section .text

_start: 	mov	rsi, message
		push 	0x6b
		
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
formatLineEnd:	mov 	rsp, rbp
		pop 	rbp
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

formatParse:	inc 	rsi
		cmp	byte [rsi], 0x25 ; checking if we need to output %
		jne 	checkChar
		call 	putc
		jmp 	parseEnd

checkChar:	cmp	byte [rsi], 0x63 ; cheking if need to output char
		jne 	parseEnd
		mov 	rsi, rbp
		add	rsi, 0x10

		call	putc
		jmp 	parseEnd

parseEnd:	ret


		section .data
message:	db 	"Hello, %c!", 10, 0
	
