;*******************************************************************************
;                                                                              *
;    Filename:		    Code -> code.asm				       *
;    Date:                  03/11/2020                                         *
;    File Version:          v.1                                                *
;    Author:                Ricardo Pellecer Orellana                          *
;    Company:               UVG                                                *
;    Description:           PROYECTO FINAL                                     *
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
    FLAG_ANTIREBOTE		RES	    1
    FLAG_ADC			RES	    1
    TX_FLAG			RES	    1
    ALTO			RES	    1
    BAJO			RES	    1
    TOGGLE			RES	    1
    RXB0			RES	    1	 
    RXB1			RES	    1	 
    RXB2			RES	    1	 
    RXB3			RES	    1	 
    RXB4			RES	    1	 
    RXB5			RES	    1	 
    RXB6			RES	    1	 
    RXB7			RES	    1	 
    RXB8			RES	    1	 
    RXB9			RES	    1	 
    SERVO_GARRA			RES	    1	 
    SERVO_EJE1			RES	    1	 
    SERVO_EJE2			RES	    1	 
    SERVO_FUN			RES	    1	 
    USUARIO			RES	    1	 
    LAST_USER			RES	    1	 
    USER_FLAG			RES	    1	 
    CUENTARX			RES	    1	 
    DIVISION			RES	    1	 
    CONT1			RES	    1	 
    MODO			RES	    1	 
			

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
    BTFSC   PIR1, ADIF	    ; CÓDIGO PARA SABER DE PARTE DE QUIÉN ES LA INTERRUPCIÓN
    CALL    BANDERA_ADC
    BTFSC   INTCON, T0IF
    CALL    BANDERA_TIMER0
    BTFSC   PIR1, RCIF
    CALL    BANDERA_RX
    BTFSC   PIR1, TXIF    ; CÓDIGO PARA SABER DE PARTE DE QUÉ TIMER SE REALIZÓ LA INTERRUPCIÓN
    CALL    BANDERA_TX
        
POP:			    ; POPEA LOS DATOS DE UNA VARIABLE TEMPORAL A STATUS Y W PARA RECUPERAR CUALQUIER DATO PERDIDO EN LA INTERRUPCIÓN
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
RETFIE			    ; INCLUYE LA REACTIVACION DEL GIE     

;*******************************************************************************
; TABLA DE CONVERSIONES
;*******************************************************************************
; SE USARA ESTA TABLA PARA REALIZAR LAS CONVERSIONES A ASCII 
; Y ENVIAR LOS DATOS EN EL FORMATO DESEADO   
CONVERSIONES:       
    ANDLW   b'00001111'	
    ADDWF   PCL, F
    RETLW   .48		;0 
    RETLW   .49		;1 
    RETLW   .50		;2 
    RETLW   .51		;3 
    RETLW   .52		;4 
    RETLW   .53		;5 
    RETLW   .54		;6 
    RETLW   .55		;7 
    RETLW   .56		;8
    RETLW   .57		;9 
    RETLW   .65		;A   
    RETLW   .66		;B   
    RETLW   .67		;C  
    RETLW   .68		;D   
    RETLW   .69		;E  
    RETLW   .70		;F     
    
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
    CALL    CONFIGURACION_TX_9600
    CALL    CONFIGURACION_RX
    CALL    CONFIGURACION_ADC
    
;*******************************************************************************
; MAIN LOOP
;*******************************************************************************    
LOOP:
    BANKSEL TRISA
    BSF	    PIE1, TXIE
    BANKSEL PORTA
    CALL    EEPROM_ESCRITURA
    MOVLW   .9
    SUBWF   SERVO_FUN, W
    BTFSC   STATUS, Z
    GOTO    AUTOMATIC
    MANUAL:
	BTFSS   PORTB, RB7		; REVISA SI EL BOTÓN DE CAMBIO DE ESTADO SE HA PRESIONADO
	CALL    ANTIR			; INDICA QUE YA SE PRESIONÓ 
	BTFSC   PORTB, RB7		; NO EJECUTA LA INSTRUCCIÓN SI SIGUE PRESIONADO EL BOTÓN
	CALL    MODO_FUNCIONAMIENTO	; SE EJECUTA EL CAMBIO DE ESTADO
	CALL    MAPPEO
	GOTO    LOOP
    AUTOMATIC:
	MOVLW	.9
	SUBWF   SERVO_GARRA, W
	BTFSC   STATUS, Z
	GOTO    AUTOMATIC_HIGH
	AUTOMATIC_LOW:
	    MOVLW	.253
	    MOVWF	BAJO
	    MOVLW	.245
	    MOVWF	ALTO
	    CALL	CONVERSION_COMPU
	    GOTO	LOOP
	AUTOMATIC_HIGH:
	    MOVLW	.245
	    MOVWF	BAJO
	    MOVLW	.253
	    MOVWF	ALTO
	    CALL	CONVERSION_COMPU
	    GOTO	LOOP	    

;*******************************************************************************
; SUBRUTINAS DE INTERRUPCION
;*******************************************************************************	    
BANDERA_TX:
    MOVLW   .1
    SUBWF   TX_FLAG, W
    BTFSC   STATUS, Z
    GOTO    ENTER
    DIGITO1:
	MOVFW	LAST_USER
	CALL	CONVERSIONES
	MOVWF	TXREG
	INCF	TX_FLAG
	GOTO	LIMPIEZA
    ENTER:
	MOVLW	.10
	MOVWF	TXREG
	CLRF	TX_FLAG
    LIMPIEZA:
	BANKSEL	TRISA
	BCF	PIE1, TXIE
	BANKSEL PORTA
    RETURN
    
BANDERA_ADC:
    BTFSC   FLAG_ADC, 0
    GOTO    ADCY
    ADCX:
	MOVFW   ADRESH	    ; MANDA LA CODIFICACION DIGITAL DE MI SEÑAL ANALOGICA AL PUERTO B
	MOVWF   VAR_ADCX
	CALL	CONFIGURACION_ADCY
	BCF	PIR1, ADIF
	BSF	ADCON0, 1
	BSF	FLAG_ADC, 0
    RETURN   
    ADCY:		    ; FUNGIONA CON EL SERVO DERECHO
	MOVFW   ADRESH	    ; MANDA LA CODIFICACION DIGITAL DE MI SEÑAL ANALOGICA AL PUERTO B
	MOVWF   VAR_ADCY
	CALL	CONFIGURACION_ADCX
	BCF	PIR1, ADIF
	BSF	ADCON0, 1
	BCF	FLAG_ADC, 0
    RETURN    
    
BANDERA_TIMER0:
    BTFSC   TOGGLE, 0
    GOTO    LOW_OPEN
    HIGH_OPEN:
	MOVFW   BAJO
	MOVWF   TMR0
	BSF     PORTC, 0
	BSF     TOGGLE, 0
	BCF     INTCON, T0IF
    RETURN
    LOW_OPEN:
	MOVFW   ALTO
	MOVWF   TMR0
	BCF     PORTC, 0
	BCF     TOGGLE, 0
	BCF     INTCON, T0IF
    RETURN

BANDERA_RX:    
    INCF    CUENTARX,1	
    MOVFW   RXB8		    
    MOVWF   RXB9
    
    MOVFW   RXB7		    
    MOVWF   RXB8
    
    MOVFW   RXB6		    
    MOVWF   RXB7
    
    MOVFW   RXB5		    
    MOVWF   RXB6
    
    MOVFW   RXB4		    
    MOVWF   RXB5
    
    MOVFW   RXB3		    
    MOVWF   RXB4
    
    MOVFW   RXB2		    
    MOVWF   RXB3	
    
    MOVFW   RXB1		    
    MOVWF   RXB2
    
    MOVFW   RXB0		    
    MOVWF   RXB1
        
    MOVFW   RCREG		    
    MOVWF   RXB0		       
    
    XORLW   .10			    
    BTFSC   STATUS,Z		    
    GOTO    VERIFICACION
    RETURN
    
    VERIFICACION:  
	MOVLW   .10			    
	SUBWF   CUENTARX,W
	BTFSS   STATUS,Z
	GOTO    ERRONEO

	MOVLW	.44		
	SUBWF	RXB2,W
	BTFSS	STATUS,Z
	GOTO	ERRONEO

	MOVLW	.44		
	SUBWF	RXB4,W
	BTFSS	STATUS,Z
	GOTO	ERRONEO
	
	MOVLW	.44		
	SUBWF	RXB6,W
	BTFSS	STATUS,Z
	GOTO	ERRONEO

	MOVLW	.44		
	SUBWF	RXB8,W
	BTFSS	STATUS,Z
	GOTO	ERRONEO
	
	MOVLW   .48		    
	SUBWF   RXB1,W
	MOVWF   USUARIO
	
	MOVLW   .48		    
	SUBWF   RXB3,W
	MOVWF   SERVO_EJE1

	MOVLW   .48		   
	SUBWF   RXB5,W
	MOVWF   SERVO_EJE2

	MOVLW   .48		   
	SUBWF   RXB7,W
	MOVWF   SERVO_GARRA

	MOVLW   .48		
	SUBWF   RXB9,W
	MOVWF   SERVO_FUN
	CLRF	CUENTARX
	RETURN

    ERRONEO:
	CLRF    CUENTARX		
	RETURN 	    
	    
;*******************************************************************************
; RUTINA EEPROM
;*******************************************************************************	    
EEPROM_ESCRITURA:
    MOVFW   USUARIO
    SUBWF   LAST_USER, W
    BTFSS   STATUS, Z
    GOTO    ACCION
RETURN
    ACCION:
    BANKSEL EEADR
    MOVLW   .0
    MOVWF   EEADR
    BANKSEL PORTA
    MOVFW   USUARIO
    BANKSEL EEDAT
    MOVWF   EEDAT
    BANKSEL EECON1
    BCF	    EECON1, EEPGD
    BSF	    EECON1, WREN
    
    BCF	    INTCON, GIE
    MOVLW   0x55
    MOVWF   EECON2
    MOVLW   0xAA
    MOVWF   EECON2
    BSF	    EECON1, WR
    BSF	    INTCON, GIE
    
    BCF	    EECON1, WREN
    BANKSEL PORTA
    CALL    EEPROM_LECTURA
RETURN	    

;*******************************************************************************
; RUTINA DE LECTURA DE LA EEPROM
;*******************************************************************************        
EEPROM_LECTURA:
    BCF	    INTCON, GIE
    MOVLW   .0
    BANKSEL EEADR
    MOVWF   EEADR
    BANKSEL EECON1
    BCF	    EECON1, EEPGD
    BSF	    EECON1, RD
    BANKSEL EEDATA
    MOVFW   EEDATA
    BANKSEL PORTA
    MOVWF   LAST_USER
    MOVWF   PORTD
    BSF	    INTCON, GIE
RETURN        
	    
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
	MOVLW	.253
	MOVWF	BAJO
	MOVLW	.245
	MOVWF	ALTO
    	INCF    MODO
    RETURN
    REINICIOA:
	MOVLW	.245
	MOVWF	BAJO
	MOVLW	.253
	MOVWF	ALTO
	CLRF	MODO
    RETURN   

;*******************************************************************************
; RUTINA DE ANTIREBOTE
;*******************************************************************************        
ANTIR:
    BSF   FLAG_ANTIREBOTE, 0	; YA QUE SE USAN PULL UPS, ESTE MASKING ME PERMITE VER QUÉ VALOR SE COLOCÓ EN CERO, ES DECIR, SE PRESIONÓ
RETURN 	    
	    
;*******************************************************************************
; RUTINA DE CONVERSION COMPU
;*******************************************************************************         
CONVERSION_COMPU:   
    SWAPF   SERVO_EJE1, 0
    ADDLW   .32
    MOVWF   CCPR1L    
    SWAPF   SERVO_EJE2, 0
    ADDLW   .32
    MOVWF   CCPR2L    
RETURN           
 
;*******************************************************************************
; RUTINA DE CONVERSION ADC
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
    CLRF    FLAG_ANTIREBOTE
    CLRF    FLAG_ADC
    CLRF    TX_FLAG
    CLRF    VAR_ADCX  
    CLRF    VAR_ADCY  
    CLRF    MODO
    CLRF    ALTO
    CLRF    BAJO
    CLRF    TOGGLE
    CLRF    SERVO_GARRA
    CLRF    SERVO_EJE1
    CLRF    SERVO_EJE2
    CLRF    SERVO_FUN
    CLRF    CUENTARX
    CLRF    RXB0
    CLRF    RXB1
    CLRF    RXB2
    CLRF    RXB3
    CLRF    RXB4
    CLRF    RXB5
    CLRF    RXB6
    CLRF    RXB7
    CLRF    RXB8
    CLRF    RXB9
    CLRF    USUARIO
    CLRF    LAST_USER
    MOVLW   .1
    MOVWF   USER_FLAG
    CLRF    DIVISION
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
    MOVLW   b'11111111'		; PRESCALER Y POSTSCALER DE 16 CADA UNO Y TIMER 2 ACTIVADO
    MOVWF   T2CON    
RETURN
    
CONFIGURACION_INTERRUPCION:
    BANKSEL TRISA
    BSF	    PIE1, ADIE
    BSF	    PIE1, RCIE		; HABILITA INTERRUPCION DE RECEPCION SERIAL CON RX
    BSF	    PIE1, TXIE		; HABILITA INTERRUPCION DE RECEPCION SERIAL CON TX
    BSF	    INTCON, PEIE	; INTERRUPCIONES PERIFÉRICAS -RC-
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

CONFIGURACION_TX_9600:
    BANKSEL TRISA
    BCF	    TXSTA, TX9    
    BCF	    TXSTA, SYNC	    ; PARA LOGRAR UN BAUD DE 9600 CON UN FOSC DE 4MHz
    BSF	    TXSTA, BRGH	    ; PARA LOGRAR UN BAUD DE 9600 CON UN FOSC DE 4MHz

    BANKSEL ANSEL
    BCF	    BAUDCTL, BRG16  ; PARA LOGRAR UN BAUD DE 9600 CON UN FOSC DE 4MHz
    
    BANKSEL TRISA
    MOVLW   .25
    MOVWF   SPBRG	    ; PARA LOGRAR UN BAUD DE 9600 CON UN FOSC DE 4MHz
    CLRF    SPBRGH	    ; PARA LOGRAR UN BAUD DE 9600 CON UN FOSC DE 4MHz
    BSF	    TXSTA, TXEN    
    BANKSEL PORTA
RETURN
    
CONFIGURACION_RX:
    BANKSEL PORTA
    BSF	    RCSTA, SPEN
    BCF	    RCSTA, RX9
    BSF	    RCSTA, CREN
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
    BSF	    ADCON0, 7   
RETURN    

CONFIGURACION_ADCX:
    BANKSEL ADCON0 
    BCF	    ADCON0, 4
RETURN
    
CONFIGURACION_ADCY:    
    BANKSEL ADCON0 
    BSF	    ADCON0, 4
RETURN
;*******************************************************************************
    
    END 