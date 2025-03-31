%include "linux64.inc"

section .data
;    	filename1 db "config.txt", 0   ; Nombre del primer archivo
 ;   	filename2 db "archivo.txt", 0  ; Nombre del segundo archivo
	newline db 10, 0               ; Carácter de nueva línea
	msg_error_abrir db "Error al abrir el archivo", 0
	msg_error_leer db "Error al leer el archivo", 0

section .bss
	swap_flag resb 1
	
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

	call find_lines
	call ordenar_filas
	print newline
	call print_ordered

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

;;;;;;;;;;;;EXTRAER VALORES PARA ORDENAMIENTO NUM;;;;;;;;;;;;;;;;

;_____________________inicio: extraer nota de una línea
; Entrada: rax = dirección de inicio de la línea (e.g., "Ana Ramirez [92]")
; Salida: r14 = valor numérico de la nota (e.g., 92)
extraer_nota:
    mov r14, 0                  ; Inicializar el valor numérico de la nota
    mov r12, rax                ; Copiar la dirección de inicio a r12 para recorrer la línea

buscar_corchete_izq:
    mov al, [r12]               ; Leer el carácter actual
    cmp al, '['                 ; ¿Es un corchete izquierdo?
    je found_corchete_izq       ; Si sí, continuar
    inc r12                     ; Avanzar al siguiente carácter
    jmp buscar_corchete_izq     ; Repetir

found_corchete_izq:
    inc r12                     ; Avanzar al primer dígito después de '['
    mov r14, 0                  ; Reiniciar el acumulador numérico

convertir_numero:
    mov al, [r12]               ; Leer el carácter actual
    cmp al, ']'                 ; ¿Es un corchete derecho?
    je fin_nota                 ; Si sí, terminar conversión
;    cmp al, '0'                 ; ¿Es menor que '0'?
;    jl error_nota               ; Si sí, error
 ;   cmp al, '9'                 ; ¿Es mayor que '9'?
  ;  jg error_nota               ; Si sí, error

    ; Convertir carácter ASCII a valor numérico (e.g., '9' -> 9)
    sub al, '0'                 ; Convertir ASCII a número
    movzx r13, al               ; Mover el dígito a r13 (zero-extend)
    imul r14, r14, 10           ; Multiplicar el acumulador por 10 (desplazar dígitos)
    add r14, r13                ; Sumar el nuevo dígito
    inc r12                     ; Avanzar al siguiente carácter
    jmp convertir_numero        ; Repetir

error_nota:
    mov r14, 0                  ; En caso de error, devolver 0 (o podrías manejar esto de otra forma)
    ret

fin_nota:
    ret
;_____________________fin: extraer nota de una línea


;;;;;;;;;;;OBTENER CANT DE LINEAS A LEER;;;;;;;;;;;;; ya esta hecho
find_lines:
	mov [cont_archivo], r12
    	mov rsi, notas              	; rsi = puntero al inicio del buffer notas
    	xor rcx, rcx                	; rcx = contador de líneas
    	xor rdx, rdx                	; rdx = índice para long_lineas
    	mov qword [cont_lineas], 0  	; Reiniciar contador de líneas
    	mov r12, [cont_archivo]     	; r12 = número de bytes leídos
    	mov r13, 0                  	; r13 = índice en el buffer

find_lines_loop:
    	cmp r13, r12                	; ¿Fin del buffer?
    	jge find_lines_end          	; Si sí, terminar

    	test rcx, rcx               	; ¿Es la primera línea?
    	jz store_line               	; Si sí, almacenar

    	cmp byte [rsi - 1], 10      	; ¿Carácter anterior es '\n'?
    	jne skip_store              	; Si no, saltar

store_line:
    	mov [long_lineas + rdx * 8], rsi ; Guardar dirección de inicio
    	inc rdx                     	; Incrementar índice
    	inc rcx                     	; Incrementar contador de líneas
    	cmp rdx, 1500               	; ¿Límite de long_lineas?
    	jge find_lines_end          	; Si sí, terminar

skip_store:
    	inc rsi                     	; Avanzar al siguiente carácter
    	inc r13                     	; Avanzar índice en el buffer
    	jmp find_lines_loop         	; Repetir

find_lines_end:
    	cmp r13, 0                 	 ; ¿Buffer vacío?
    	je end_no_lines
    	cmp byte [rsi - 1], 10      	; ¿Último carácter es '\n'?
    	je end_no_lines             	; Si sí, no hay línea adicional
    	mov [long_lineas + rdx * 8], rsi ; Guardar última línea
    	inc rcx                     	; Contar última línea
    	inc rdx	

end_no_lines:
    	mov [cont_lineas], rcx      ; Guardar número total de líneas
    	ret

;;;;;;;ALFABETICO;;;;;;;;;	ordenamiento, intercambio de filas

ordenar_filas:
    	mov rcx, [cont_lineas]     	;cant de lineas del doc 
    	cmp rcx, 1                  	;si solo hay 1 linea en doc no hay nada que 
    	jle full_ordenado           	;ordenar
	dec rcx				;necesito lineas-1 aciertos
    	mov r15, 0                  	;contador de aciertos


outer_loop:
    	cmp r15, rcx			;Cantidad de aciertos debe ser igual a lineas-1
    	je full_ordenado            	;Para poder ssalir del loop

    	mov r15, 0     			;Reinicio contador de aciertos
    	mov r8, 0                   	;reinicio indice a la primera linea

inner_loop:
    	mov r9, r8                  	;Índice para la segunda línea = primera + 8
    	add r9, 8
    	mov rax, [cont_lineas]      	;Cargar número total de líneas
    	shl rax, 3                  	;Multiplicar por 8 (tamaño de cada entrada)
    	cmp r9, rax                 	;¿Llegamos al final del arreglo?
    	jge next_pass               	;Si sí, terminar esta pasada

    	mov rax, [long_lineas + r8] 	;Dirección de inicio de la línea 1
    	mov rbx, [long_lineas + r9] 	;Dirección de inicio de la línea 2

	cmp byte [ordenamientos], 97
	je alpha
	jmp num

alpha:
    	mov dl, [rax]               	;Primer carácter de la línea 1
    	mov dh, [rbx]               	;Primer carácter de la línea 2
    	cmp dl, dh                  	;Comparar caracteres
    	jle no_swap                 	;Si línea 1 <= línea 2, no intercambiar
	jg dirr

num:
	call extraer_nota		;rax ya tiene direccion de primera linea
	mov r11, r14			;primera nota extraida, guardada en r11
	mov rax, rbx			;direccion segunda linea
	call extraer_nota
	mov r13, r14			;segunda nota extraida, guardada en r15
		
	cmp r11, r13
	jle no_swap
	
dirr:
     	mov rax, [long_lineas + r8] 	;Cargar dirección de línea 1
    	mov rbx, [long_lineas + r9] 	;Cargar dirección de línea 2
    	mov [long_lineas + r8], rbx 	;Mover línea 2 a posición de línea 1
    	mov [long_lineas + r9], rax 	;Mover línea 1 a posición de línea 2

	mov r15, 0
	add r8, 8
	jmp inner_loop

no_swap:
    	add r8, 8                   	;Avanzar al siguiente par
	inc r15
    	jmp inner_loop              	;Repetir bucle interno

next_pass:
    	jmp outer_loop              	;Repetir hasta que no haya intercambios

full_ordenado:
    ret

;;;;;;;;;NUMERICO;;;;;;;;;;;;;;

;_____________________inicio: impresión byte por byte de las líneas ordenadas
; Imprime cada línea en long_lineas carácter por carácter
print_ordered:
    	mov r12, 0                  	;Índice inicial en long_lineas
				;por alguna razon con r11, mi intento incial, no funciona
print_line_loop:
    	mov r12, [long_lineas + r10 * 8] ; rsi = dirección de inicio de la línea actual
	call imprimir_byte
	add r10, 1
	
	cmp r10, [long_lineas]
	jb print_line_loop

	ret

imprimir_byte:
	mov rax, 1			;aca por alguna razon no funciona print
	mov rdi, 1
	mov rsi, r12
	mov rdx, 1
	syscall	

	mov al, [r12]
	cmp al, 10			;verifico si ya es cambio de linea
	je fin_linea
	inc r12				;imprimo siguiente byte
	jmp imprimir_byte	
fin_linea:
	ret



salir:
    					; Salir del programa
	exit    
