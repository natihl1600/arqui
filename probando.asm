%include "linux64.inc"

section .data
    newline db 10, 0
    msg_error_abrir db "Error al abrir el archivo", 0
    msg_error_leer db "Error al leer el archivo", 0
    msg_arg_error db "Error en cantidad de argumentos", 0

section .bss
    config resb 1000
    notas resb 1000
    filename1 resq 1000
    filename2 resb 1000

    num_bytes_archivo resq 1000
    copia_linea resq 100
    long_lineas resq 1500
    longitud_1 resq 25 
    longitud_2 resq 25
    
    cont_archivo resw 500
    cont_config resw 1000
    cont_lineas resq 1
    contador resq 3
    cont_lineas1 resq 1
    cont_lineas2 resq 1

    aprobado resb 3        
    reposicion resb 3
    tamano resb 3
    escala resb 3
    ordenamientos resb 1

section .text
    global _start

_start:
    cmp qword [rsp], 3
    jl arg_error
    
    mov word [cont_archivo], 0
    mov word [cont_config], 0
    mov qword [cont_lineas], 0
    mov qword [contador], 1
    mov qword [cont_lineas1], 0
    mov qword [cont_lineas2], 1
    mov qword [long_lineas], 0

    mov rdi, [rsp + 16]
    call abrir_leer_imprimir
    mov rdi, [rsp + 24]
    call segundo_archivo

    print config
    print newline
    print notas
    print newline

    lea rdi, [aprobado]
    call extraer_valor
    lea rdi, [reposicion]
    call extraer_valor
    lea rdi, [tamano]
    call extraer_valor
    lea rdi, [escala]
    call extraer_valor
    call buscar_espacio
    movzx r8, word [cont_config]
    add r8, 1
    mov al, [config + r8]
    mov [ordenamientos], al

    print aprobado
    print newline
    print reposicion
    print newline
    print tamano
    print newline
    print escala
    print newline
    print ordenamientos
    print newline

    call contar_lineas
    call ordenar_filas
    print newline
    print notas
    exit

arg_error:
    print msg_arg_error
    print newline
    exit

abrir_leer_imprimir:
    mov rax, 2
    mov rsi, 0
    mov rdx, 0
    syscall
    cmp rax, 0
    jl error_abrir
    mov rdi, rax
    mov rax, 0
    mov rsi, config
    mov rdx, 1000
    syscall
    cmp rax, 0
    jl error_leer
    mov rax, 3
    syscall
    ret

segundo_archivo:
    call abrir_leer_imprimir2
    ret

abrir_leer_imprimir2:
    mov rax, 2
    mov rsi, 0
    mov rdx, 0
    syscall
    cmp rax, 0
    jl error_abrir
    mov rdi, rax
    mov rax, 0
    mov rsi, notas
    mov rdx, 1000
    syscall
    cmp rax, 0
    jl error_leer
    mov qword [num_bytes_archivo], rax
    mov rax, 3
    syscall
    ret

error_abrir:
    print msg_error_abrir
    print newline
    exit 

error_leer:
    print msg_error_leer
    print newline
    exit 

extraer_valor:
    call buscar_corchete
    movzx r8, word [cont_config]
    add r8, 1
    mov al, [config + r8]
    mov [rdi], al
    mov al, [config + r8 + 1]
    mov [rdi + 1], al
    mov byte [rdi + 2], 0
    add r8, 1
    mov [cont_config], r8w
    ret

buscar_corchete:
    mov r8w, word [cont_config]
    cmp r8w, 1000
    jge error
    cmp byte [config + r8], '['
    je encontrado
    inc word [cont_config]
    jmp buscar_corchete
error:
    ret

buscar_espacio:
    mov r8w, [cont_config]
    cmp byte [config + r8], 32
    je encontrado
    inc word [cont_config]
    jmp buscar_espacio

encontrado:
    ret

contar_lineas:
    mov qword [cont_lineas], 0
    mov rcx, 0
    mov rbx, 0
    mov qword [long_lineas], 0
    jmp contar_loop

contar_loop:
    cmp rcx, [num_bytes_archivo]
    je listo
    mov al, [notas + rcx]
    inc rcx
    cmp al, 10d
    je es_salto
    jmp contar_loop
es_salto:
    inc qword [cont_lineas]
    mov qword [long_lineas + rbx * 8], rcx
    inc rbx
    jmp contar_loop
listo:
    ret
no_trailing_newline:
    ret

ordenar_filas:
    mov r13, [cont_lineas]
    dec r13
    mov qword [contador], 0

outer_loop:
    mov r8, 0
    mov r9, 1
    cmp qword [contador], r13
    jge full_ordenado
inner_loop:
    cmp r9, r13
    jge next_pass
    mov rax, r8
    shl rax, 3
    mov r12, [long_lineas + rax]
    mov rax, r9
    shl rax, 3
    mov r13, [long_lineas + rax]
    mov rax, r8
    shl rax, 3
    mov r10, [long_lineas + rax + 8]
    sub r10, r12
    dec r10
    mov rax, r9
    shl rax, 3
    mov r11, [long_lineas + rax + 8]
    sub r11, r13
    dec r11
    call compara_bytes
    jne swap_lines
next_inner:
    inc r8
    inc r9
    jmp inner_loop
next_pass:
    inc qword [contador]
    jmp outer_loop

compara_bytes:
    mov rcx, 0
compare_loop:
    cmp rcx, r10
    jge same_or_shorter
    cmp rcx, r11
    jge greater
    movzx r14, byte [notas + r12 + rcx]
    movzx r15, byte [notas + r13 + rcx]
    cmp r14, r15
    jg greater
    jl less
    inc rcx
    jmp compare_loop
same_or_shorter:
    cmp r10, r11
    jle equal
    jmp greater
greater:
    mov rax, 1
    ret
less:
    mov rax, -1
    ret
equal:
    mov rax, 0
    ret

swap_lines:
    lea rsi, [notas + r12]
    lea rdi, [copia_linea]
    mov rcx, r10
    inc rcx
    rep movsb

    lea rsi, [notas + r13]
    lea rdi, [notas + r12]
    mov rcx, r11
    inc rcx
    rep movsb

    lea rsi, [copia_linea]
    lea rdi, [notas + r13]
    mov rcx, r10
    inc rcx
    rep movsb

    call contar_lineas
    jmp next_inner

full_ordenado:
    ret

salir:
    exit