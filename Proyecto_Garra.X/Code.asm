;*******************************************************************************
;                                                                              *
;    Filename:		    Code -> code.asm				       *
;    Date:                  03/11/2020                                         *
;    File Version:          v.1                                                *
;    Author:                Ricardo Pellecer Orellana                          *
;    Company:               UVG                                                *
;    Description:           LAB 8	                                       *
;                                                                              *
;*******************************************************************************

#include "p16f887.inc"

; CONFIG1
; __config 0xE0D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
; TODO PLACE VARIABLE DEFINITIONS GO HERE

 
GPR_VAR				UDATA
    W_TEMP			RES	    1	; PARA GUARDAR INFO MIENTRAS SE EJECUTA LA INTERRUPCIÓN
    STATUS_TEMP			RES	    1
    VAR_ADCX			RES	    1
    VAR_ADCY			RES	    1
    FLAG_ADC			RES	    1
    FLAG			RES	    1
    FLAG_ANTIREBOTE		RES	    1
    DISPLAY_HX			RES	    1	
    DISPLAY_LX			RES	    1	
    DISPLAY_HY			RES	    1	
    DISPLAY_LY			RES	    1
    ITERACIONES			RES	    1
    CONTROL			RES	    1
    MODO			RES	    1
    TOGGLE			RES	    1
    CONT1			RES	    1
		

;*******************************************************************************
; RESET VECTOR
;*******************************************************************************

RES_VECT    CODE    0x0000		; processor reset vector
    GOTO    START			; go to beginning of program

;*******************************************************************************
; ISR VECTOR
;*******************************************************************************

ISR_VECTOR  CODE    0x0004

PUSH:			    ; PUSHEA LOS DATOS DE STATUS Y W A UNA VARIABLE TEMPORAL EN CASO SE VEAN AFECTADOS EN LA INTERRUPCIÓN 
    BCF	    INTCON, GIE	    ; DESACTIVA INTERRUPCIONES PARA EVITAR INTERRUPCIONES MIENTRAS SE ESTÁ EN EL ISR
    MOVWF   W_TEMP
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP

ISR:
    BTFSC   INTCON, T0IF
    CALL    BANDERA_TIMER0
        
POP:			    ; POPEA LOS DATOS DE UNA VARIABLE TEMPORAL A STATUS Y W PARA RECUPERAR CUALQUIER DATO PERDIDO EN LA INTERRUPCIÓN
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
RETFIE			    ; INCLUYE LA REACTIVACION DEL GIE

BANDERA_TIMER0:
    MOVFW   MODO
    SUBLW   .0	    ; VERIFICO QUE NO ESTÉ EN ALGÚN MODO DE EDICIÓN
    BTFSC   STATUS, Z
    GOTO    CERRADO
    ABIERTO:
	BTFSC	TOGGLE, 0
	GOTO	LOW_OPEN
	HIGH_OPEN:
	    MOVLW   .253
	    MOVWF   TMR0
	    BSF	    PORTC, 0
	    BSF	    TOGGLE, 0
	    BCF	    INTCON, T0IF
	RETURN
	LOW_OPEN:
	    MOVLW   .181
	    MOVWF   TMR0
	    BCF	    PORTC, 0
	    BCF	    TOGGLE, 0
	    BCF	    INTCON, T0IF
	RETURN
    
    CERRADO:
	BTFSC	TOGGLE, 1
	GOTO	LOW_CLOSED
	HIGH_CLOSED:
	    MOVLW   .250
	    MOVWF   TMR0
	    BSF	    PORTC, 0
	    BSF	    TOGGLE, 1
	    BCF	    INTCON, T0IF
	RETURN
	LOW_CLOSED:
	    MOVLW   .184
	    MOVWF   TMR0
	    BCF	    PORTC, 0
	    BCF	    TOGGLE, 1
	    BCF	    INTCON, T0IF
	RETURN

;*******************************************************************************
; TABLA DE DISPLAYS
;*******************************************************************************

TABLA:
    ANDLW   b'00001111' ; MASK
    ADDWF   PCL, F
    RETLW   b'10001000' ; 0
    RETLW   b'11101011'	; 1
    RETLW   b'01001100'	; 2
    RETLW   b'01001001'	; 3
    RETLW   b'00101011'	; 4
    RETLW   b'00011001'	; 5
    RETLW   b'00011000'	; 6
    RETLW   b'11001011'	; 7
    RETLW   b'00001000' ; 8
    RETLW   b'00001011' ; 9
    RETLW   b'00001010' ; A
    RETLW   b'00111000' ; b
    RETLW   b'10011100' ; C
    RETLW   b'01101000' ; d
    RETLW   b'00011100' ; E
    RETLW   b'00011110' ; F      
    
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************

MAIN_PROG   CODE     0x0100                 ; let linker place main program

START
SETUP:
    CALL    CONFIGURACION_BASE		    ; EXPLICACIONES EN LA SECCIÓN DE CONFIGURACIONES
    CALL    CONFIGURACION_PWM
    CALL    CONFIGURACION_TIMER0
    CALL    CONFIGURACION_TIMER2
    CALL    CONFIGURACION_INTERRUPCION
    CALL    CONFIGURACION_ADC
    
;*******************************************************************************
; MAIN LOOP
;*******************************************************************************    
LOOP:        
    BTFSS   PORTB, RB7		; REVISA SI EL BOTÓN DE CAMBIO DE ESTADO SE HA PRESIONADO
    CALL    ANTIR		; INDICA QUE YA SE PRESIONÓ 
    BTFSC   PORTB, RB7		; NO EJECUTA LA INSTRUCCIÓN SI SIGUE PRESIONADO EL BOTÓN
    CALL    MODO_FUNCIONAMIENTO	; SE EJECUTA EL CAMBIO DE ESTADO
    CALL    MAPPEO
    CALL    CONVERSION_ADC
    GOTO    LOOP

;*******************************************************************************
; RUTINA DE SELECCIÓN DE MODOS DE FUNCIONAMIENTO
;*******************************************************************************    
MODO_FUNCIONAMIENTO:
    MOVFW   FLAG_ANTIREBOTE
    SUBLW   .1			; REVISA QUE SÍ HAYA PASADO POR EL ANTIREBOTE
    BTFSS   STATUS, Z		; SI NO PASÓ POR EL ANTIREBOTE, SIGNIFICA QUE NO SE PRESIONÓ EL BOTÓN Y NO EJECUTA LA INSTRUCCIÓN
RETURN
    CLRF    FLAG_ANTIREBOTE	; LIMPIA LA BANDERA PARA QUE SE PUEDA VOLVER A PRESIONAR EL BOTÓN SIN REBOTES
    MOVFW   MODO		
    SUBLW   .1			
    BTFSC   STATUS, Z
    GOTO    REINICIOA		; SIRVE PARA QUE NO SE PASE DEL MODO 8
    CONTEO:
    	INCF    MODO
    RETURN
    REINICIOA:
	CLRF	MODO
    RETURN   

;*******************************************************************************
; RUTINA DE ANTIREBOTE
;*******************************************************************************        
ANTIR:
    BSF   FLAG_ANTIREBOTE, 0	; YA QUE SE USAN PULL UPS, ESTE MASKING ME PERMITE VER QUÉ VALOR SE COLOCÓ EN CERO, ES DECIR, SE PRESIONÓ
RETURN        

;*******************************************************************************
; RUTINA DE MAPPEO PARA SERVOS
;*******************************************************************************    
MAPPEO:
    RRF	    VAR_ADCX, 0
    ANDLW   b'01111111'
    ADDLW   .32
    MOVWF   CCPR1L
    RRF	    VAR_ADCY, 0
    ANDLW   b'01111111'
    ADDLW   .32
    MOVWF   CCPR2L    
RETURN    
    
;*******************************************************************************
; RUTINA DE CONVERSION ADC
;*******************************************************************************         
CONVERSION_ADC:
    BANKSEL ADCON0
    MOVLW   b'00000011'			
    MOVWF   ADCON0  
    CALL    DELAY
   
    BSF	    ADCON0,GO
    BTFSC   ADCON0,GO 
    GOTO    $-1
    
    BANKSEL ADRESH
    MOVFW   ADRESH
    MOVWF   VAR_ADCY			
    
    BANKSEL ADCON0
    MOVLW   b'00010011'			
    MOVWF   ADCON0
    CALL    DELAY
    BSF	    ADCON0,GO
    BTFSC   ADCON0,GO 
    GOTO    $-1
    
    BANKSEL ADRESH
    MOVFW   ADRESH
    MOVWF   VAR_ADCX			
RETURN    

;*******************************************************************************
; RUTINA DE DELAYS
;*******************************************************************************                
DELAY:
    MOVLW   .23			    
    MOVWF   CONT1
    DECFSZ  CONT1, F
    GOTO    $-1                       
RETURN    
  
DELAY_BIG:
    MOVLW   .255			    
    MOVWF   CONT1
    DECFSZ  CONT1, F
    GOTO    $-1                       
    MOVLW   .255			    
    MOVWF   CONT1
    DECFSZ  CONT1, F
    GOTO    $-1                       
    MOVLW   .255			  
    MOVWF   CONT1
    DECFSZ  CONT1, F
    GOTO    $-1                       
RETURN            
    
;*******************************************************************************
; CONFIGURACIONES
;*******************************************************************************         
CONFIGURACION_BASE:
    BANKSEL PORTA
    CLRF    PORTA		; LIMPIA LOS PUERTOS PARA EVITAR QUE TENGAN CUALQUIER VALOR INICIAL DISTINTO DE 0
    CLRF    PORTB
    CLRF    PORTC
    CLRF    PORTD
    CLRF    PORTE

    BANKSEL ANSEL
    CLRF    ANSEL
    BSF	    ANSEL, 0		; POT EN X
    BSF	    ANSEL, 5		; POT EN Y
    CLRF    ANSELH		; BORRA EL CONTROL DE ENTRADAS ANALÓGICAS	

    BANKSEL TRISA
    MOVLW   b'00100001'		; POT Y TRANSISTORES
    MOVWF   TRISA
		
    MOVLW   b'10000000'		; PUSHES EN EL PUERTO B PARA INCLUIR LOS PULL UPS POR SOFTWARE - TIENE 4 SALIDAS PUES SE CONECTARON AHÍ LOS TRANSISTORES (NPN 3904)
    MOVWF   TRISB
    MOVWF   WPUB		; PARA PULL UPS
    BCF	    OPTION_REG, 7
    
    CLRF    TRISC		; SIN USAR
    CLRF    TRISD		; PARA DISPLAY
    
    CLRF    TRISE
    
    BANKSEL PORTA
    CLRF    FLAG_ADC
    CLRF    FLAG_ANTIREBOTE
    CLRF    VAR_ADCX  
    CLRF    VAR_ADCY  
    CLRF    ITERACIONES
    CLRF    CONTROL
    CLRF    MODO
    CLRF    TOGGLE
    CLRF    CONT1
RETURN
    
CONFIGURACION_PWM:
    SERVO1:
    BANKSEL CCP1CON
    BCF	    CCP1CON, 7
    BCF	    CCP1CON, 6		; 6 Y 7 PARA SINGLE OUTPUT
    BCF	    CCP1CON, 5		
    BCF	    CCP1CON, 4		; BITS MENOS SIGNIFICATIVOS PARA EL ANCHO DE PULSO
    BSF	    CCP1CON, 3
    BSF	    CCP1CON, 2
    BCF	    CCP1CON, 1
    BCF	    CCP1CON, 0
    SERVO2:
    BANKSEL CCP2CON
    BCF	    CCP2CON, 5		
    BCF	    CCP2CON, 4		; BITS MENOS SIGNIFICATIVOS PARA EL ANCHO DE PULSO
    BSF	    CCP2CON, 3
    BSF	    CCP2CON, 2
    BSF	    CCP2CON, 1
    BSF	    CCP2CON, 0
RETURN    
    
CONFIGURACION_TIMER0:
    BANKSEL TRISA
    CLRWDT			; CONFIGURACIÓN PARA EL FUNCIONAMIENTO DEL TIMER0
    MOVLW   b'01010111'		; PRESCALER DE 1:256 PARA PODER GENERAR INTERRUPCIONES DE 0.5ms
    MOVWF   OPTION_REG 
    BANKSEL PORTA
RETURN 
    
CONFIGURACION_TIMER2:
    BANKSEL PORTA
    MOVLW   b'11111111'	; PRESCALER Y POSTSCALER DE 16 CADA UNO Y TIMER 2 ACTIVADO
    MOVWF   T2CON    
RETURN
    
CONFIGURACION_INTERRUPCION:
    BANKSEL TRISA
    BSF	    INTCON, T0IE
    
    MOVLW   .187		; TECHO PARA TIMER2 - PARA QUE EL PWM FUNCIONE CON 3ms
    MOVWF   PR2			; PARA PULSO DE 0° --> CCPR1L = 0x20 ^ CCP1CON<5:4> = b'00
				; PARA PULSO DE 180° --> CCP1L = 0x9D ^ CCP1CON<5:4> = b'00
				; FUNCION PARA CONVERSION DE DATOS ADC PARA METER EN EL CCPR1L:
				; CCP1RL = 32 + ADC/2
    
    BANKSEL PORTA
    BSF	    INTCON, GIE		; HABILITA LAS INTERRUPCIONES
    BCF	    INTCON, T0IF	; PARA ASEGURARSE DE QUE NO TENGA OVERFLOW AL INICIO
RETURN

CONFIGURACION_ADC:    
    BANKSEL ADCON1 
    CLRF    ADCON1		; VDD Y VSS COMO REFERENCIA / JUSTIFICADO A LA IZQUIERDA
    
    BANKSEL ADCON0 
    BSF	    ADCON0, 0
    BSF	    ADCON0, 1  
    BCF	    ADCON0, 2
    BCF	    ADCON0, 3
    BCF	    ADCON0, 5
    BCF	    ADCON0, 6
    BCF	    ADCON0, 7   
RETURN
    
;*******************************************************************************
    
    END 