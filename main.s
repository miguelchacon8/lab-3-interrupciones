;*******************************************************************************
; Universidad del Valle de Guatemala
; IE2023 Programación de Microcontroladores
; Autor: Miguel Chacón   
; Compilador: PIC-AS (v2.4), MPLAB X IDE (v6.00)
; Proyecto: lab 3 - interrupciones
; Hardware: PIC16F887
; Creado: 08/08/22
; Última Modificación: 15/08/22 
;******************************************************************************* 
PROCESSOR 16F887
#include <xc.inc>
;******************************************************************************* 
; Palabra de configuración    
;******************************************************************************* 
 ; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits 
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit 
  CONFIG  PWRTE = OFF         ; Power-up Timer Enable bit 
  CONFIG  MCLRE = OFF         ; RE3/MCLR pin function select bit 
  CONFIG  CP = OFF              ; Code Protection bit 
  CONFIG  CPD = OFF             ; Data Code Protection bit 
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits 
  CONFIG  IESO = OFF            ; Internal External Switchover bit 
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit 
  CONFIG  LVP = OFF       ; Low Voltage Programming Enable bit 

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit 
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits 
;******************************************************************************* 
; Variables    
;******************************************************************************* 
PSECT udata_shr
 W_TEMP:
    DS 1
 STATUS_TEMP:
    DS 1
 cont20ms: ;tmr0
    DS 1
 CONTDP:
    DS 1
 flag: 
    DS 1
    
;******************************************************************************* 
; Vector Reset    
;******************************************************************************* 
PSECT CODE, delta=2, abs
 ORG 0x0000
    GOTO MAIN
    
;******************************************************************************* 
; Vector ISR Interrupciones    
;******************************************************************************* 
PSECT CODE, delta=2, abs
 ORG 0x0004
PUSH:
    MOVWF W_TEMP	    ; guardamos el valor de w
    SWAPF STATUS, W	    ; movemos los nibles de status en w
    MOVWF STATUS_TEMP	    ; guardamos el valor de w en variable. 
			    ; temporal de status
ISR:
    BTFSC INTCON, 0	    ; Está encendido el bit T0IF?
    GOTO RRBIF 
    BTFSC INTCON, 2    ; Está encendido el bit RBIF?
    GOTO RTMR
    GOTO POP
    
RTMR:
    BCF INTCON, 2	    ; apagamos la bandera de T0IF
    BANKSEL TMR0
    INCF cont20ms	    ; incrementamos la variable
    MOVLW 179
    MOVWF TMR0		    ; reinicamos el valor de N en TMR0
    GOTO POP

RRBIF:
    BANKSEL PORTB
    BTFSS PORTB, 6
    INCF PORTD
    BTFSS PORTB, 7
    DECF PORTD
    BCF INTCON, 0
    GOTO POP

    
POP:
    SWAPF STATUS_TEMP, W    ; movemos los nibles de status de nuevo y los cargamos a W
    MOVWF STATUS	    ; movemos el valor de W al registro STATUS
    SWAPF W_TEMP, F	    ; Movemos los nibles de W en el registro temporal
    SWAPF W_TEMP, W	    ; Movemos los nibles de vuelta para tenerlo en W
    RETFIE		    ; Retornamos de la interrupción
;******************************************************************************* 
; Código Principal    
;******************************************************************************* 
    
PSECT CODE, delta=2, abs
 ORG 0x0100
   
MAIN:
    BANKSEL OSCCON
    ; Frecuencia del oscilador
    BSF OSCCON, 6	; IRCF2 Selección de 4 MHz
    BSF OSCCON, 5	; IRCF1
    BCF OSCCON, 4	; IRCF0
    
    BSF OSCCON, 0	; SCS Reloj Interno
    
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH  ; analógicos desactivados
     
;****************************************************************************
; OUTPUTS E INPUTS*
;****************************************************************************
    BANKSEL TRISB
    CLRF TRISA ; salidas display 1
    CLRF TRISC ; salida display 2
    CLRF TRISD ; salida de interrupciones
    MOVLW 11000000B ; configuración salida tmr0 e inputs
    MOVWF TRISB
    
    BANKSEL PORTA
    CLRF PORTA ; 
    CLRF PORTB ; contador de interrupciones
    CLRF PORTC
    CLRF PORTD
    
    BANKSEL INTCON 
    BSF INTCON, 7	; Habilitamos el GIE interrupciones globales
    BSF INTCON, 5	; Habilitando la interrupcion T0IE TMR0
    BSF INTCON, 3
    BCF INTCON, 2	; Apagamos la bandera T0IF del TMR0
    BCF INTCON, 0
    ;    CLRF contdisplay
    

    ; Configuración TMR0 **********************************************************
    BANKSEL OPTION_REG ;TEMPORIZADOR DEL TMR0
    BCF OPTION_REG, 5	; T0CS: FOSC/4 COMO RELOJ (MODO TEMPORIZADOR)
    BCF OPTION_REG, 3	; PSA: ASIGNAMOS EL PRESCALER AL TMR0
    
    BSF OPTION_REG, 2
    BSF OPTION_REG, 1
    BSF OPTION_REG, 0	; PS2-0: PRESCALER 1:256 SELECIONADO 
  
    BCF OPTION_REG, 7   ; NO RBPU, se habilitan los pullups internos
    
    ;********************************************************************************
    
   
    BANKSEL WPUB
    MOVLW 11000000B ;bits para los inputs
    MOVWF IOCB
    MOVWF WPUB
    
    BANKSEL TMR0
    MOVLW 179
    MOVWF TMR0 ; se carga el valor de desborde de 20 ms
    CLRF cont20ms ;empieza en cero la variable
    CLRF CONTDP
    
;***************************************************************************
    ;LOOP
;***************************************************************************
LOOP:
    INCF PORTB, F ; incrementamos puerto b
    GOTO DISPLAY1
    BTFSC flag, 0
    CALL sumar
    BTFSC flag, 1
    CALL restar
    

;ETIQUETA DEL TMR0 
VERIFICACION:    
    MOVF cont20ms, W
    SUBLW 50
    BTFSS STATUS, 2	; verificamos bandera z
    GOTO VERIFICACION
    CLRF cont20ms
    GOTO LOOP; Regresamos a la etiqueta LOOP
    
;ETIQUETA DISPLAY 1

DISPLAY1: 
    BCF STATUS, 2	; bit de status 2 en 0
    MOVF PORTB, W	; porta en W
    ANDLW 0x0F		; el and chequea qeu esté dentro de 0 y F
    SUBLW 10		; restar a 10 segundos
    BTFSC STATUS, 2	; cuando se llegue a cero se inicia display 2 
    
    CALL DISPLAY2	
    MOVF PORTB, W	; se carga el valor a w
    CALL valores		
    MOVWF PORTA	    ; se carga el valor al portc
    GOTO VERIFICACION
    
; DISPLAY 2
DISPLAY2:
    CLRF PORTB		; empezar en 0 porta
    BCF STATUS, 2	; se empieza en 0
    INCF CONTDP, F	; se incrementa la cantidad del display de decenas
    MOVF CONTDP, W	; se mueve a W
    SUBLW 6		;sse hacen las 6 decenas
    BTFSC STATUS, 2	; si está en 0 se reinician todos los puertos
    CALL reinicio
   
    
    MOVF CONTDP, W	; movemos el valor de contdp1 a contdp2 para 
    CALL valores		
    MOVWF PORTC	; se carga a portc, el valor de las decenas
    RETURN
    
reinicio:
    CLRF PORTA ; se reinicia a 0 después de los 60 segundos
    CLRF PORTC
    CLRF CONTDP 
    

;INCREMENTOS EN EL CONTADOR ****************************************    
sumar:
    INCF PORTD, F ;se incrementa el valor de f
    CLRF flag
    RETURN
    
restar:
    DECF PORTD, F ;se decrementa el valor de f
    CLRF flag
    RETURN
    
;TABLA DE VALORES ************************************************************   
valores: 
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0x0F
    ADDWF PCL
    ; cátodo
    RETLW 00111111B  ;0
    RETLW 00000110B  ;1
    RETLW 01011011B  ;2
    RETLW 01001111B  ;3
    RETLW 01100110B  ;4
    RETLW 01101101B  ;5
    RETLW 01111101B  ;6
    RETLW 00000111B  ;7
    RETLW 01111111B  ;8
    RETLW 01100111B  ;9
    RETLW 01110111B  ;A
    RETLW 01111100B  ;B
    RETLW 00111001B  ;C
    RETLW 01011110B  ;D
    RETLW 01111001B  ;E
    RETLW 01110001B  ;F

;******************************************************************************* 
; Fin de Código    
;******************************************************************************* 
END   




