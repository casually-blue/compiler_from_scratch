---
layout: post
title: Writing some actual machine code 
draft: true
---

It's post three of the series and we're finally ready to write some actual machine code.
The first thing we want to do is to test that the program can actually run something simple,
so we will just have the program return immediately instead of segmentation faulting.

In a normal program we could just return from the function, but since we are writing a very basic
ELF binary we don't have any of the normal libc features. Because of this we'll have to manually
make the `exit` system call to end our program.

## The Linux system call ABI
To make a system call or "syscall" we have to set up some values into various registers and then 
call the `0x80` interrupt which instructs the kernel to service our request. Unlike a normal function,
all the syscall arguments have to be passed via registers rather than the stack.

## Writing our program

For our program we want to just exit immediately returning a value so we will use the exit syscall which 
is syscall number one. We pass the syscall number in the eax register and the return value in the ebx register.
The basic assembly code to do this is
```nasm
mov eax, 1 ; We are calling system call 1
mov ebx, 0 ; We want to return 0 from the program
int 0x80 ; Execute the 0x80 processor interrupt
```

Our next step is converting this assembly code into machine code. We could run it through an assembler and get 
the code, but we're trying to write a compiler from scratch so instead we'll manually encode these instructions 
into hex.

We first want to `mov` the immediate value `1` into the eax register so we need to open up the [Intel software
developers manual](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html) and look
up the encoding of the `mov` instruction. 

Here is the section of the table that corresponds to the version of the instruction that we want:

| Opcode | Instruction | Op/En | 64-Bit Mode| Compat / Leg Mode | Description |
| -------- | ------------- | ------- | ------------ | ------------------- | ------------- |
| ... | ... | ... | ... | ... | ... |
| B8+ rd id | MOV r32, imm32 | OI | Valid | Valid | Move imm32 to r32 |
| ... | ... | ... | ... | ... | ... |

The only important fields for us now are the `Opcode` field and the `Op/En` (Operand Encoding) field. We next need
to look at the table of operand encodings for `mov` to see how we need to encode our numbers

| Op/EN | Operand 1 | Operand 2 | Operand 3 | Operand 4 |
| ----- | --------- | --------- | --------- | --------- |
| ... | ... | ... | ... | ... |
| OI | opcode + rd (w) | imm8/16/32/64 | NA | NA |

The first byte of the move instruction is `0xb8` ORed with the register number. If we look at the binary 
representation of the opcode (`0b10111000`) we can see that the last three bytes of the opcode are zero
leaving us enough space to select between the first eight registers. For `eax` that register is at index
zero, leaving us with just `b8`. The next part of the instruction is the "immediate" value which is encoded
directly in the instruction as the 32 bit version of the number so it's just `0x010000000` for `1`. This gives
us a final instruction encoding of 

```c
0xb8 // Opcode
0x01 0x00 0x00 0x00 // Syscall number
```

We now need to encode `move ebx, 0` which is pretty similar except that the immediate value is `0` and our
instruction index is `3` or `0x011` which gives us a opcode of `0xbb` and an immediate value of `0x00000000` giving
us an encoding of:

```c
0xbb // Opcode
0x00 0x00 0x00 0x00 // Return value
```

We now must call the interrupt instruction `int` with our interrupt number of `0x80`

| Opcode | Instruction | Op/En | 64-Bit Mode| Compat / Leg Mode | Description |
| -------- | ------------- | ------- | ------------ | ------------------- | ------------- |
| ... | ... | ... | ... | ... | ... |
| CD ib | INT imm8 | I | Valid | Valid | Generate software interrupt with vector specified by immediate byte. |
| ... | ... | ... | ... | ... | ... |

We can see that this instruction is just the opcode byte followed by the immediate byte representing the
interrupt number, giving us
```c
0xCD // Opcode
0x80 // Interrupt number
```

We can now put this code right after our elf header giving us a working binary that immediately returns zero.
If we want, we can change the value we put in `ebx` to give us a different return value encoded as 
a 32 bit little endian value.
