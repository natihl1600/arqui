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
;	print cont_config
;	print newline
;	movzx rax, word [cont_lineas]
;	print rax

	call ordenar_filas
;	print cont_lineas
;	print newline
	
;	print array

	;final extraccion datos config
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
	mov r12, rax

    ; Cerrar el archivo
    	mov rax, 3              ; syscall: close
    	syscall

    ; Imprimir el contenido del segundo archivo
;    	print notas           ; Imprimir el contenido del buffer
 ;   	print newline           ; Imprimir un salto de línea
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
	mov qword [cont_archivo], r12
	mov qword [long_lineas], 0	;primera linea empieza en cero
	jmp contar_loop

contar_loop:
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
	mov qword r13, [cont_lineas]			;r13 tiene cant total de lineas
	mov qword r8, [cont_lineas1]			;r8 tiene el contador de linea 1
	mov qword r9, [cont_lineas2]			;r9 tiene contador de linea 2

	mov qword rax, [cont_lineas]
	mov qword rbx, [contador]
	cmp rax, rbx					;pregunto si todas las lineas estan ordenadas
	je full_ordenado				
	cmp r9, r13					;pregunto si ya se revisaron todas y no esta
	jge volver_a_empezar				;full ordenado
	
	imul r8, r8, 8
	imul r9, r9, 8					

	mov qword r10, [long_lineas + r8]		;byte final linea 1 (inicio 2)
	mov qword r11, [long_lineas + r9]		;byte final linea 2 (inicio 3)


	mov r12, [long_lineas + r8 - 8]			;inicio linea 1
	mov r13, [long_lineas + r9 - 8]			;inicio linea 2 


	sub r10, r12					;longitud linea 1
	call negativo1

	sub r11, r13					;longitud linea 2
	call negativo2
	

	mov rcx, 0
	jmp compara_bytes


negativo1:
	cmp r10, 0
	jl cambiar1
	ret

cambiar1:
	neg r10
	ret

negativo2:
	cmp r11, 0
	jl cambiar2
	ret
cambiar2:
	neg r11
	ret
	

compara_bytes:
	movzx r14, byte [notas + r12 + rcx]		;si encuentra byte diferente guarda la ubi
	movzx r15, byte [notas + r13 + rcx]	

	
	cmp r15, r14					;comparo los bytes
	je misma_letra					;si es la misma letra, avanza de byte
	cmp r15, r14					;si no es la mis:>ma letra
	jg mismo_orden					;si estan ordenadas


	call ordenamiento				;ordeno si son diferentes
	jmp ordenar_filas	

volver_a_empezar:					;tengo que hacer el bubble varias veces
	mov qword [cont_lineas1], 0			;hasta verificar que todo esta ordenado
	mov qword [cont_lineas2], 1
	mov qword [contador], 1
	jmp ordenar_filas

misma_letra:
	inc rcx
	jmp compara_bytes

ordenamiento:	;r13 linea 1		r12 linea 2
		
	lea rsi, [notas + r12]	
	lea rdi, [copia_linea]
	mov rcx, r10
	rep movsb	
	
	lea rsi, [notas + r13]	;ahora lo de rsi esta tamvbien escrito en rdi
	lea rdi, [notas + r12]	;"rsi 2 veces"
	mov rcx, r11
	rep movsb

	lea rsi, [copia_linea]	;ahora debo copiar lo de copia_linea donde esta rsi
	lea rdi, [notas + r13]	
	mov rcx, r10
	rep movsb

	
	lea r14, [long_lineas + r8]
	lea r15, [long_lineas + r9]
	
	
	mov r10, [r14]
	mov r11, [r15]
cambio:
	mov r14, [r11]
	mov r15, [r10]


	inc qword [cont_lineas1]			;para ver las otras lineas
	inc qword [cont_lineas2]			;hay que seguir el loop
	mov qword [contador], 1
	ret			

mismo_orden:
	inc qword [cont_lineas1]
	inc qword [cont_lineas2]
	inc qword [contador]
	jmp ordenar_filas

full_ordenado:	
	ret

salir:
    ; Salir del programa
	exit    

