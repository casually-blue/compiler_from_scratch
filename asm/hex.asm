bits 64

global main
main:
  call get_hex_digit
  push rax
  call get_hex_digit
  pop rbx

  cmp bl, 255
  je exit

  shl ebx, 4

  cmp al, 255
  jne .lower_half
  mov eax, ebx
  call write_byte
  jmp exit

.lower_half:
  or eax, ebx
  call write_byte
  jmp main 

exit:
  mov rax, 60
  mov rdi, 0
  syscall

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

get_hex_digit:
  call get_next_char
  cmp rax, '#'
  jne .check_hex

.comment_loop:
  call get_next_char
  cmp rax, 255
  je .end
  cmp rax, 0x0a
  jne .comment_loop

.check_hex:
  cmp rax, 255
  je .end
  call as_hex
  cmp eax, 255
  je get_hex_digit
.end:
  ret


as_hex:
  cmp al, '0'
  jl .next
  cmp al, '9'
  jg .next

  sub al, '0'
  jmp .end

.next:
  cmp al, 'a'
  jl .err
  cmp al, 'f'
  jg .err

  sub al, 'a'
  add al, 10
  jmp .end

.err:
  mov eax, 255
.end:
  ret

get_next_char:
  mov rax, 0
  mov rdi, 0
  mov rsi, rw_buffer
  mov rdx, 1
  syscall

  cmp al, 0
  je .err

  mov rax, [rw_buffer]

  cmp al, 'A'
  jl .end
  cmp al, 'Z'
  jg .end

  add al, 0x20

  jmp .end

.err:
  mov eax, 255
.end: 
  ret


section .data
rw_buffer db 0,0,0,0
