;****************************************
;*					*
;* Titel: CIA2-Emulation (für Emu64)	*
;* Autor: Thorsten Kattanek		*
;* Datum: 1.7.1998			*
;* Ort  : Berlin			*
;* Vers : 1.0				*
;* Info : Hier wird die CIA 2 emuliert	*
;*	  also Timer unsw.		*
;*	  Haupts. für Floppy  		*
;****************************************

EXTRN  C64_RAM:WORD,ENDE:NEAR

PUBLIC CIA2_REG_READ,CIA2_REG_WRITE,PORT_A,ZEIGER,PUFFER_1

.MODEL SMALL
.DATA

;****************************************

	PORT_A		DB	00000000B
	PORT_B		DB	0

	PORT_A_TMP	DB	0

	WERTE		DB	0,128,64,32,16,8,4,2,1

	SPRUNG_TABELLE	DW	FLOPPY_OK_?,ATN_HIGH,HARDWARE_OK,WARTEN,READ_BYTE,PAUSE
	ZEIGER		DW	0
	ZÄHLER_1	DB	0
	PUFFER_1	DB	0

;****************************************
.486
.CODE

;********* CIA2 REGISTER LESEN *********

CIA2_REG_READ:

	MOV	ES,C64_RAM
	MOVZX	AX,BYTE PTR ES:[DI]		; Liest 1 Byte aus dem C64 Speicher
	RET

;********* CIA2 REGISTER SCHREIBEN *****

CIA2_REG_WRITE:
	RET

;************** FLOPPY 1541 EMULATION *************

FLOPPY_1541:

	MOV	DI,ZEIGER
	MOV	BX,SPRUNG_TABELLE[DI]
	CALL	BX
	RET

FLOPPY_OK_?:

	MOV	AH,PORT_A			; *** Warten auf ATN Signal ***
	AND 	AH,00001000B
	JZ	ATN_LOW
	MOV	ZEIGER,2
ATN_LOW:
	RET

ATN_HIGH:					; *** ATN Signal ist vorhanden und warten auf CLOCK=1 ***

	MOV	AH,PORT_A
	AND	AH,00010000B
	JZ	ATN_HIGH_10
	OR	PORT_A,10000000B
	MOV	ZEIGER,4
ATN_HIGH_10:
	RET

HARDWARE_OK:					; *** PLOPY vorhanden und auf CLOCK=0 warten dann bereit zum
							;Empfangen senden ***
	MOV	AH,PORT_A
	AND	AH,00010000B
	JNZ	HARDWARE_OK_10
	AND	PORT_A,01111111B
	MOV	ZEIGER,6
	MOV	ZÄHLER_1,0
	MOV	PUFFER_1,0
HARDWARE_OK_10:
	RET

WARTEN:
	MOV	AH,PORT_A
	AND	AH,00010000B			; *** Warten auf CLOCK=1 wenn ja dann werden Daten gesendet ***
	JZ	WARTEN_10
	MOV	ZEIGER,8
WARTEN_10:
	RET

READ_BYTE:					; *** Liest 8 Bit mit jedem Low Impuls ***
	MOV	AH,PORT_A
	AND	AH,00010000B
	JNZ	READ_BYTE_10
	MOV	AH,PORT_A
	AND	AH,00100000B
	ROL	AH,1
	ROL	AH,1
	OR	PUFFER_1,AH
	ROR	PUFFER_1,1
	INC	ZÄHLER_1
	CMP	ZÄHLER_1,8
	JE	READ_BYTE_20				; *** BYTE KOMPLETT ÜBERTRAGEN ***
	MOV	ZEIGER,6
READ_BYTE_10:
	RET
READ_BYTE_20:
	MOV	ZEIGER,10
	RET
PAUSE:
	RET
;***************************************
END





