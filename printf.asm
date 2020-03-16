; ----------------------------------------------------------
; NASM test program
;-----------------------------------------------------------

		global _start
		
		section .text

_start: 	mov	rsi, message
		call 	printf
	
		mov 	rax, 60
		xor 	rdi, rdi
		syscall

;--------------------------------------------------------
; Outputs format string to stdout
; Enter: RSI - string address
; Uses:	RAX, RDX, RDI, RSI
;--------------------------------------------------------
printf:	
nextCharacter:	cmp 	byte [rsi], 0
		je	formatLineEnd
		call 	putc
		inc 	rsi
		jmp 	nextCharacter
formatLineEnd:	ret	

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


		section .data
message:	db 	"Hello, world!", 10, 0
	
