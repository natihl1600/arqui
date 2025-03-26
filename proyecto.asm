%include "linux64.inc"

section .data
;    	filename1 db "config.txt", 0   ; Nombre del primer archivo
 ;   	filename2 db "archivo.txt", 0  ; Nombre del segundo archivo
	newline db 10, 0               ; Carácter de nueva línea
	msg_error_abrir db "Error al abrir el archivo", 0
	msg_error_leer db "Error al leer el archivo", 0

section .bss
    	config resb 1000               ; Buffer para almacenar el contenido del primer archivo
    	notas resb 1000              ; Buffer para almacenar el contenido del segundo archivo

	filename1 resq 1000
	filename2 resb 1000

	copia_linea resq 100
	long_lineas resq 1500
	longitud_1 resq 25 
	longitud_2 resq 25
	
	cont_archivo resw 500	;bytes
	cont_config resw 1000	;contador para recorrer el archivo de config ;bytes
	cont_lineas resq 1	;va a contener la cant de lineas del doc
	contador resq 3		;simple contador
	cont_lineas1 resq 1	;para proceso de ordenamiento
	cont_lineas2 resq 1	;para proceso ordenamiento

	aprobado resb 3        
	reposicion resb 3
	tamano resb 3
	escala resb 3
	ordenamientos resb 1

section .text
    	global _start

_start:
	mov word [cont_archivo], 0
	mov word [cont_config], 0
	mov qword [cont_lineas], 0
	mov qword [contador], 1
	mov qword [cont_lineas1], 1
	mov qword [cont_lineas2], 2
	mov qword [long_lineas], 0
    ; Abrir, leer e imprimir el primer archivo (config.txt)

	mov rdi, [rsp + 16]
    	call abrir_leer_imprimir
	mov rdi, [rsp + 24]
    	call segundo_archivo            ; Saltar al segundo archivo

	print config
	print newline
	print notas
	print newline

    ;INICIALIZACION GUARDADO DE VARIABLES

	;GUARDAR VARIABLE APROBADO
    	lea rdi, [aprobado]
    	call extraer_valor
	;GUARDAR VARIABLE REPROBADO
    	lea rdi, [reposicion]
    	call extraer_valor
	;GUARDAR VARIABLE TAMANO 
    	lea rdi, [tamano]
   	call extraer_valor
	;GUARDAR VARIABLE ESCALA
    	lea rdi, [escala]
    	call extraer_valor
	;GUARDAR VARIABLE ORDENAMIENTO
    	call buscar_espacio
    	movzx r8, word [cont_config]	;a diferencia de los numeros, aca quiero guardar solo la primera
    	add r8, 1				;letra, ya se a de alfabetico o n de numerico
    	mov al, [config + r8]
    	mov [ordenamientos], al
    ;FINALIZACION GUARDADO DE VARIABLES

    ; Imprimir valores 
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
lineas:
	call contar_lineas
;	print cont_config
;	print newline
;	movzx rax, word [cont_lineas]
;	print rax
orden:
	call ordenar_filas
;	print cont_lineas
	print newline
	print notas
;	print array

	;final extraccion datos config
	exit

abrir_leer_imprimir:
    ; Abrir el archivo
    	mov rax, 2              ; syscall: open
    	mov rdi, rdi      ; nombre del primer archivo
    	mov rsi, 0              ; flags: O_RDONLY
    	mov rdx, 0              ; mode
    	syscall

    ; Leer el archivo
    	mov rdi, rax            ; descriptor de archivo
    	mov rax, 0              ; syscall: read
    	mov rsi, config        ; buffer para almacenar el contenido
    	mov rdx, 1000           ; número de bytes a leer
    	syscall
	
    ; Cerrar el archivo
    	mov rax, 3              ; syscall: close
    	syscall

    ; Imprimir el contenido del primer archivo
  ;  	print config            ; Imprimir el contenido del buffer
   ; 	print newline           ; Imprimir un salto de línea
    	ret

segundo_archivo:
    ; Abrir, leer e imprimir el segundo archivo (archivo.txt)
    	call abrir_leer_imprimir2
    	ret               ; Saltar a la salida del programa

abrir_leer_imprimir2:
    ; Abrir el archivo
    	mov rax, 2              ; syscall: open
    	mov rdi, rdi      ; nombre del segundo archivo
    	mov rsi, 0              ; flags: O_RDONLY
    	mov rdx, 0              ; mode
    	syscall

    ; Leer el archivo
    	mov rdi, rax            ; descriptor de archivo
    	mov rax, 0              ; syscall: read
    	mov rsi, notas        ; buffer para almacenar el contenido
    	mov rdx, 1000           ; número de bytes a leer
    	syscall
	mov r12, rax

    ; Cerrar el archivo
    	mov rax, 3              ; syscall: close
    	syscall

    ; Imprimir el contenido del segundo archivo
;    	print notas           ; Imprimir el contenido del buffer
 ;   	print newline           ; Imprimir un salto de línea
    	ret


;;;;;;;;;;;;;EXTRAER VALORES DE CONFIGURACION;;;;;;;;;;;;;;
extraer_valor:
    	call buscar_corchete
    	movzx r8, word [cont_config]
    	add r8, 1			;me acomodo al byte del numero
    	mov al, [config + r8]
    	mov [rdi], al
    	mov al, [config + r8 + 1]
    	mov [rdi + 1], al
    	add r8, 1
    	mov [cont_config], r8w
    	ret
	
buscar_corchete:
    	mov r8w, word [cont_config]		;estamos usando 16 bits para buscar
    	cmp byte [config + r8], '['		;comparo hasta encontrar corchete
    	je encontrado			;si lo encuentro tengo funcion de retorno
    	inc word [cont_config]		;si no se ha encontrado aumento contador
    	jmp buscar_corchete			;loop

buscar_espacio:
    	mov r8w, [cont_config]		;misma logica de busqueda que buscar_corche nada mas
    	cmp byte [config + r8], 32		;que con un espacio
    	je encontrado
    	inc word [cont_config]
    	jmp buscar_espacio

encontrado:
    	ret


;;;;;;;;;;;OBTENER CANT DE LINEAS A LEER;;;;;;;;;;;;; ya esta hecho
contar_lineas:
	mov qword [cont_lineas], 0		;conteo cant lineas
	mov rcx, 0			;puntero al inicio del buffer
	mov rbx, 0
	mov qword [cont_archivo], r12
	mov rdx, 0
	jmp contar_loop

contar_loop:
;	print array
	cmp rcx, [cont_archivo]			;cant de bytes leidos == cant bytes del documento
	je listo
	mov al, [notas + rcx]				;documento leido
	inc rcx
	cmp al, 10d		;byte es un cambio de linea?
	je es_salto				;no, siguiente byte
	jmp contar_loop				;si, voy a sumar al contador de lineas
es_salto:
	mov qword [long_lineas + rbx * 8], rcx
	inc rbx
	inc qword [cont_lineas]
	jmp contar_loop			
listo:
	ret


;;;;;;;ALFABETICO;;;;;;;;;	ordenamiento, intercambio de filas

ordenar_filas:
    mov r13, [cont_lineas]  ; Total lines
    dec r13                 ; Last line index to compare
    mov qword [contador], 0 ; Outer loop counter

outer_loop:
    mov r8, 0               ; Line1 index
    mov r9, 1               ; Line2 index
    cmp qword [contador], r13
    jge full_ordenado
inner_loop:
    cmp r9, r13
    jge next_pass
    ; Get start positions
	imul r8, r8, 8
	imul r9, r9, 8
    mov r12, [long_lineas + r8]  ; Start of line1
    mov r13, [long_lineas + r9]  ; Start of line2
    ; Calculate lengths
    mov r10, [long_lineas + r8 + 8] ; Next line start
    sub r10, r12
    dec r10                 ; Exclude \n
    mov r11, [long_lineas + r9 + 8]
    sub r11, r13
    dec r11
    ; Compare strings
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
    ; Save both lines’ start and end positions
    mov r14, r12            ; Start of Line1
    mov r15, [long_lineas + r8 + 8]  ; End of Line1 + 1
    mov rbx, r13            ; Start of Line2
    mov rbp, [long_lineas + r9 + 8]  ; End of Line2 + 1

    ; Copy Line1 to copia_linea
    lea rsi, [notas + r14]
    lea rdi, [copia_linea]
    mov rcx, r15
    sub rcx, r14            ; Full length including \n
    mov r10, rcx            ; Save Line1 length
    rep movsb

    ; Shift Line2 to Line1’s position
    lea rsi, [notas + rbx]
    lea rdi, [notas + r14]
    mov rcx, rbp
    sub rcx, rbx            ; Full length of Line2
    mov r11, rcx            ; Save Line2 length
    rep movsb

    ; Copy Line1 to Line2’s new position
    lea rsi, [copia_linea]
    lea rdi, [notas + r14]
    add rdi, r11            ; Position after shifted Line2
    mov rcx, r10
    rep movsb

    jmp next_inner

full_ordenado:
    ret

salir:
    ; Salir del programa
	exit    

