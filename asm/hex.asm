as_hex:
  cmp rax, '0'
  jl .next
  cmp rax, '9'
  jg .next

  sub rax, '0'
  jmp .end

.next:
  cmp rax, 'a'
  jl .err
  cmp rax, 'f'
  jg .err

  sub rax, 'a'
  add rax, 10
  jmp .end

.err:
  mov rax, 255
.end:
  ret

get_next_char:
  mov rax, 0
  mov rdi, 0
  mov rsi, rw_buffer
  mov rdx, 1
  syscall

  cmp rax, 0
  je .err

  mov rax, [rw_buffer]

  cmp rax, 'A'
  jl .end
  cmp rax, 'Z'
  jg .end

  add rax, 0x20

  jmp .end

.err:
  mov rax, 255
.end: 
  ret

get_hex_digit:
  call get_next_char
  cmp rax, '#'
  jne .check_hex

.comment_loop:
  call get_next_char
  cmp rax, 255
  je .check_hex
  cmp rax, '\n'
  jne .comment_loop

.check_hex:
  cmp rax, 255
  je .end
  call as_hex
  cmp eax, 255
  je get_hex_digit
.end:
  ret

global main
main:
  call read_byte

read_byte:
  call get_hex_digit
  push rax
  call get_hex_digit
  pop rbx

  cmp rbx, 255
  je exit

  shl rbx, 4

  cmp rax, 255
  jne .lower_half
  mov rax, rbx
  call write_byte
  jmp exit

.lower_half:
  or rax, rbx
  call write_byte
  jmp read_byte

write_byte:
  push rax
  mov rax, 1
  mov rdi, 1
  mov rsi, rw_buffer
  mov rdx, 1
  pop rbx
  mov [rw_buffer], rbx
  syscall
  ret

exit:
  mov rax, 60
  mov rdi, 0
  syscall

section .data
rw_buffer db 0,0,0,0
