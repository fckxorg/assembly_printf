# MIPT Assembly course Printf implementation
NASM implemented `printf` C function.
**Notes:** it's better to use buffered output and two versions of itoa: one version for bin, oct and hex, other for dec.
**
Useful instructions*:*
1. `bsr` - MSB
2. `xlat` - get byte from table located by address in `rbx`, according to index in `al`
3. `ret imm16` - return to calling procedure and pop `imm16` bytes from stack. Useful for calling conventions with callee-cleanup

Also, it may be useful to know about *jump tables*.

**Short example:**
```
        jmp     qword [jmp_table + eax * 8 - 8]

case1:  mov     rsi, 1
        jmp end

case2:  mov     rsi, 2
        jmp end

case3:  mov     rsi, 3
        jmp end

...
        .section data
jmp_table:
dq      case1
dq      case2
dq      case3
``` 
If your data is bleak, you can use `dup` in your `dq` to fill in spaces.

This printf example uses cdecl calling convention.

**Calling conventions:**
![8086](/images/8086_conventions.png)

![IA-32](/images/IA32_conventions.png)

![x86-64](/images/x86-64_conventions.png)
Src: Table is based on information from Agner Fog's "Calling conventions for different C++ compilers and operating systems", created in published on https://en.wikipedia.org/wiki/X86_calling_conventions 
