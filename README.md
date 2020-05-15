# MIPT Assembly course Printf implementation
NASM implemented `printf` C function.
**Notes:** it's better to use buffered output and two versions of itoa: one version for bin, oct and hex, other for dec.
**Useful instructions**
1. `bsr` - MSB
2. `xlat` - get byte from table located by address in `rbx`, according to index in `al`
3. `ret imm16` - return to calling procedure and pop `imm16` bytes from stack. Useful for calling conventions with callee-cleanup

This example uses cdecl calling convention.

Calling conventions:
![8086](/images/8086_conventions.png)

![IA-32](/images/IA32_conventions.png)

![x86-64](/images/x86-64_conventions.png)
