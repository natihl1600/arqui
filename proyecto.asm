%include "linux64.inc"

section .data
	newline db 10, 0               ; Carácter de nueva línea
	msg_error_abrir db "Error al abrir el archivo", 0
	msg_error_leer db "Error al leer el archivo", 0
	msg_arg_error db "Error en cantidad de argumentos", 0

section .bss
    	config resb 1000               ; Buffer para almacenar el contenido del primer archivo
    	notas resb 1000              ; Buffer para almacenar el contenido del segundo archivo
	filename1 resq 1000
	filename2 resb 1000

	num_bytes_archivo resq 1000
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
	cmp qword [rsp], 3
	jl arg_error
	
	mov word [cont_archivo], 0
	mov word [cont_config], 0
	mov qword [cont_lineas], 0
	mov qword [contador], 1
	mov qword [cont_lineas1], 0
	mov qword [cont_lineas2], 1
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
    ; Abrir el archivo
    	mov rax, 2              ; syscall: open
    	mov rdi, rdi      ; nombre del primer archivo
    	mov rsi, 0              ; flags: O_RDONLY
    	mov rdx, 0              ; mode
    	syscall
	cmp rax, 0
	jl error_abrir

    ; Leer el archivo
    	mov rdi, rax            ; descriptor de archivo
    	mov rax, 0              ; syscall: read
    	mov rsi, config        ; buffer para almacenar el contenido
    	mov rdx, 1000           ; número de bytes a leer
    	syscall
	cmp rax, 0
	jl error_leer

    ; Cerrar el archivo
    	mov rax, 3              ; syscall: close
    	syscall

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
	cmp rax, 0
	jl error_abrir

    ; Leer el archivo
    	mov rdi, rax            ; descriptor de archivo
    	mov rax, 0              ; syscall: read
    	mov rsi, notas        ; buffer para almacenar el contenido
    	mov rdx, 1000           ; número de bytes a leer
    	syscall
	cmp rax, 0
	jl error_leer
	mov qword [num_bytes_archivo], rax

    ; Cerrar el archivo
    	mov rax, 3              ; syscall: close
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

;;;;;;;;;;;;;EXTRAER VALORES DE CONFIGURACION;;;;;;;;;;;;;;
extraer_valor:
    	call buscar_corchete
    	movzx r8, word [cont_config]
    	add r8, 1			;me acomodo al byte del numero
    	mov al, [config + r8]
    	mov [rdi], al
    	mov al, [config + r8 + 1]
    	mov [rdi + 1], al
	mov byte [rdi + 2], 0
    	add r8, 1
    	mov [cont_config], r8w
    	ret
	
buscar_corchete:
    	mov r8w, word [cont_config]		;estamos usando 16 bits para buscar+
	cmp r8w, 1000
	jge error
    	cmp byte [config + r8], '['		;comparo hasta encontrar corchete
    	je encontrado			;si lo encuentro tengo funcion de retorno
    	inc word [cont_config]		;si no se ha encontrado aumento contador
    	jmp buscar_corchete			;loop
error:
	ret


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
	mov rbx, 0			;indx de la linea
;	mov qword [cont_archivo], [num_bytes_archivo] 
	mov qword [long_lineas], 0	;primera linea empieza en cero
	jmp contar_loop

contar_loop:
	cmp rcx, [num_bytes_archivo]			;cant de bytes leidos == cant bytes del documento
	je listo
	mov al, [notas + rcx]				;documento leido
	inc rcx
	cmp al, 10d		;byte es un cambio de linea?
	je es_salto				;no, siguiente byte
	jmp contar_loop				;si, voy a sumar al contador de lineas
es_salto:
	inc qword [cont_lineas]
	mov qword [long_lineas + rbx * 8], rcx
	inc rbx
	jmp contar_loop			
listo:	
	cmp rcx, [num_bytes_archivo]
	je no_trailing_newline
	ret
no_trailing_newline:
	inc qword [cont_lineas]
	mov [long_lineas + rbx * 8], rcx
	ret


;;;;;;;ALFABETICO;;;;;;;;;	ordenamiento, intercambio de filas


ordenar_filas:
	mov r13, [cont_lineas]
	dec r13
	mov qword [contador], 1

outer_loop:
	mov r8, 0	;valores iniciales de las lineas
	mov r9, 1
	cmp qword [contador], r13
	jge full_ordenado

inner_loop:
	cmp r9, r13
	jge next_pass

	imul r8, r8, 8
	imul r9, r9, 8

	mov r12, [long_lineas + r8]		;creo que es el final de la linea
	mov r13, [long_lineas + r9]		
	
	mov r10, [long_lineas + r8 - 8]	;siguiente linea para calcular largo
	sub r10, r12
	neg r10
	dec r10		;ignoro el salto de liena
		
	mov r11, [long_lineas + r9 - 8]
	sub r11, r13
	neg r11
	dec r11
	
	call compara_bytes
	jne swap_lines

next_inner:
	inc r8
	inc r9
	jmp inner_loop

next_pass:
	cmp qword [contador], r13
	jmp full_ordenado
	mov qword [contador], 1
	jmp outer_loop

compara_bytes:
	mov rcx, 0
compare_loop:
	cmp rcx, r10
	jge same_or_shorter
	cmp rcx, r11
	jge greater

	mov r12, [long_lineas + r8 - 8]		;vuelvo a se;alar el bit del incio de la linea
	mov r13, [long_lineas + r9 - 8]
	
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
greater:	;no esta ordenado, entra a swap
	mov rax, 1
	ret
less:		;esta ordenado, no entra a swap
	mov rax, -1
	inc qword [contador]
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

	shr r8, 3
	shr r9, 3

	call contar_lineas
	mov qword [contador], 1
	jmp next_inner

full_ordenado:	
	ret

salir:
    ; Salir del programa
	exit    

