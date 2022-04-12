;****************************************
;*					*
;* Titel: SID-Emulation (für Emu64)	*
;* Autor: Thorsten Kattanek		*
;* Datum: 16.12.1998			*
;* Ort  : Berlin			*
;* Vers : 1.1				*
;* Info : Hier wird der SID emuliert	*
;*	  also Sound.			*
;*	  		 		*
;****************************************

PUBLIC	SOUND_RESET,SID

.MODEL SMALL
.DATA

;****************************************

	OPL_SHADOW	DB 256 DUP (?)
	SID_FREQ_1	DW 0
	SID_FREQ_2	DW 0
	SID_FREQ_3	DW 0
	WAVES		DB 0,0,3,0,1,0,3,0,2,0,3,0,1,0,3,0
	SPRUNGTABELLE	DW R0,R1,R2,R3,R4,R5,R6,R7,R8,R9,R10,R11,R12,R13,R14,R15,R16,R17,R18,R19,R20,R21,R22,R23,R24,R25,R26,R27,R28
	ATTACK		DB (15-4)*16,(15-6)*16,(15-7)*16,(15-8)*16
 			DB (15-8)*16,(15-9)*16,(15-9)*16,(15-9)*16
  			DB (15-10)*16,(15-11)*16,(15-12)*16,(15-13)*16
  			DB (15-13)*16,(15-14)*16,(15-14)*16,(15-14)*16

  	DECAY		DB 15-4,15-5,15-6,15-6
 			DB 15-6,15-6,15-6,15-7
  			DB 15-8,15-9,15-10,15-11
 			DB 15-12,15-13,15-14,15-14
;****************************************
.486
.CODE


SID:
	SUB	DI,0D400H			; *** Registernr errechnen ***
	SAL	DI,1
	MOV	BX,SPRUNGTABELLE[DI]
	JMP	BX				; *** zum gewünschten Register springen ***





;********* Hier sind alle Register des SID aufgeführt **********

;********* Oszillatorfrequenz niederwertiges Byte für Stimme 1 *********

R0:
	MOV	BYTE PTR SID_FREQ_1[0],AL
	JMP	R1_10

;********** Oszillatorfrequenz höherwertiges Byte für Stimme 1 ********

R1:
	MOV	BYTE PTR SID_FREQ_1[1],AL
R1_10:
	
	MOV	AX,SID_FREQ_1
	XOR	DX,DX
	MOV	BX,17
	DIV	BX				;*** Hier ist jetzt die zu spielende Frequenz 0-3855 Hz ***
	OR	AH,00010000B
	PUSH	AX
	MOV	AH,AL
	MOV	AL,0A0H
	CALL	OPL_WRITE
	MOV	AL,0B0H
	CALL	OPL_READ
	MOV	BH,AH
	AND	BH,11100000B
	POP	AX
	AND	AH,00011111B
	OR	AH,BH
	MOV	AL,0B0H
	JMP	OPL_WRITE
R2:
	RET
R3:
	RET

;********** Steuerregister der Stimme 1 **********

R4:
	PUSH	AX		; *** Key Bit übernehmen ***
	MOV	BH,AL
	AND	BH,00000001B
	MOV	CL,3
	ROR	BH,CL
	MOV	AL,0B0H
	CALL	OPL_READ
	AND	AH,11011111B
	OR	AH,BH
	CALL	OPL_WRITE
	POP	AX		; *** Wave umsetzen ***
	AND	AL,11110000B
	MOV	CL,4
	ROL	AL,CL
	MOVZX	DI,AL
	MOV	AH,WAVES[DI]
	MOV	AL,0E0H
	CALL	OPL_WRITE
	MOV	AL,0E3H	
	JMP	OPL_WRITE

;********** Attack/Decay Stimme 1 **********

R5:
	MOV	BL,AL
	XOR	BH,BH
	AND	BL,11110000B
	MOV	CL,4
	ROR	BL,CL
	MOV	CH,ATTACK[BX]
	MOV	BL,AL
	AND	BL,00001111B
	MOV	AH,DECAY[BX]
	OR	AH,CH
	MOV	AL,60H
	CALL	OPL_WRITE
	MOV	AL,63H
	JMP	OPL_WRITE

;********** Sustain/Release Stimme 1 **********

R6:
	MOV	AH,AL
	AND	AL,11110000B
	AND	AH,00001111B
	NOT	AH	
	OR	AH,AL
	MOV	AL,80H
	CALL	OPL_WRITE
	MOV	AL,83H
	JMP	OPL_WRITE

;********* Oszillatorfrequenz niederwertiges Byte für Stimme 2 *********

R7:
	MOV	BYTE PTR SID_FREQ_2[0],AL
	JMP	R8_10

;********** Oszillatorfrequenz höherwertiges Byte für Stimme 2 ********

R8:
	MOV	BYTE PTR SID_FREQ_2[1],AL
R8_10:
	
	MOV	AX,SID_FREQ_2
	XOR	DX,DX
	MOV	BX,17
	DIV	BX					;*** Hier ist jetzt die zu spielende Frequenz 0-3855 Hz ***
	OR	AH,00010000B
	PUSH	AX
	MOV	AH,AL
	MOV	AL,0A1H
	CALL	OPL_WRITE
	MOV	AL,0B1H
	CALL	OPL_READ
	MOV	BH,AH
	AND	BH,11100000B
	POP	AX
	AND	AH,00011111B
	OR	AH,BH
	MOV	AL,0B1H
	JMP	OPL_WRITE
R9:
	RET
R10:
	RET

;********** Steuerregister der Stimme 2 **********

R11:
	PUSH	AX		; *** Key Bit übernehmen ***
	MOV	BH,AL
	AND	BH,00000001B
	MOV	CL,3
	ROR	BH,CL
	MOV	AL,0B1H
	CALL	OPL_READ
	AND	AH,11011111B
	OR	AH,BH
	CALL	OPL_WRITE
	POP	AX		; *** Wave umsetzen ***
	AND	AL,11110000B
	MOV	CL,4
	ROL	AL,CL
	MOVZX	DI,AL
	MOV	AH,WAVES[DI]
	MOV	AL,0E1H
	CALL	OPL_WRITE
	MOV	AL,0E4H	
	JMP	OPL_WRITE

;********** Attack/Decay Stimme 2 **********

R12:
	MOV	BL,AL
	XOR	BH,BH
	AND	BL,11110000B
	MOV	CL,4
	ROR	BL,CL
	MOV	CH,ATTACK[BX]
	MOV	BL,AL
	AND	BL,00001111B
	MOV	AH,DECAY[BX]
	OR	AH,CH
	MOV	AL,61H
	CALL	OPL_WRITE
	MOV	AL,64H
	JMP	OPL_WRITE

;********** Sustain/Release Stimme 2 **********

R13:
	MOV	AH,AL
	AND	AL,11110000B
	AND	AH,00001111B
	NOT	AH	
	OR	AH,AL
	MOV	AL,81H
	CALL	OPL_WRITE
	MOV	AL,84H
	JMP	OPL_WRITE

;********* Oszillatorfrequenz niederwertiges Byte für Stimme 3 *********

R14:
	MOV	BYTE PTR SID_FREQ_3[0],AL
	JMP	R15_10

;********** Oszillatorfrequenz höherwertiges Byte für Stimme 3 ********

R15:
	MOV	BYTE PTR SID_FREQ_3[1],AL
R15_10:
	
	MOV	AX,SID_FREQ_3
	XOR	DX,DX
	MOV	BX,17
	DIV	BX					;*** Hier ist jetzt die zu spielende Frequenz 0-3855 Hz ***
	OR	AH,00010000B
	PUSH	AX
	MOV	AH,AL
	MOV	AL,0A2H
	CALL	OPL_WRITE
	MOV	AL,0B2H
	CALL	OPL_READ
	MOV	BH,AH
	AND	BH,11100000B
	POP	AX
	AND	AH,00011111B
	OR	AH,BH
	MOV	AL,0B2H
	JMP	OPL_WRITE

R16:
	RET
R17:
	RET

;********** Steuerregister der Stimme 3 **********

R18:
	PUSH	AX		; *** Key Bit übernehmen ***
	MOV	BH,AL
	AND	BH,00000001B
	MOV	CL,3
	ROR	BH,CL
	MOV	AL,0B2H
	CALL	OPL_READ
	AND	AH,11011111B
	OR	AH,BH
	CALL	OPL_WRITE
	POP	AX		; *** Wave umsetzen ***
	AND	AL,11110000B
	MOV	CL,4
	ROL	AL,CL
	MOVZX	DI,AL
	MOV	AH,WAVES[DI]
	MOV	AL,0E2H
	CALL	OPL_WRITE
	MOV	AL,0E5H	
	JMP	OPL_WRITE

;********** Attack/Decay Stimme 3 **********

R19:
	MOV	BL,AL
	XOR	BH,BH
	AND	BL,11110000B
	MOV	CL,4
	ROR	BL,CL
	MOV	CH,ATTACK[BX]
	MOV	BL,AL
	AND	BL,00001111B
	MOV	AH,DECAY[BX]
	OR	AH,CH
	MOV	AL,62H
	CALL	OPL_WRITE
	MOV	AL,65H
	JMP	OPL_WRITE

;********** Sustain/Release Stimme 3 **********

R20:
	MOV	AH,AL
	AND	AL,11110000B
	AND	AH,00001111B
	NOT	AH	
	OR	AH,AL
	MOV	AL,82H
	CALL	OPL_WRITE
	MOV	AL,85H
	JMP	OPL_WRITE

R21:
	RET
R22:
	RET
R23:
	RET
R24:
	RET
R25:
	RET
R26:
	RET
R27:
	RET
R28:
	RET




;********** OPL-Chip und Shadow-Ram auf Null setzen *********

SOUND_RESET:
	MOV	AL,80H
	MOV	AH,4
	CALL	OPL_WRITE
	MOV	AL,60H
	MOV	AH,4
	CALL	OPL_WRITE
	XOR	AX,AX
SOUND_RESET_10:
	CALL	OPL_WRITE
	INC	AL
	JNZ	SOUND_RESET_10

	MOV	AL,1			
	MOV	AH,00100000B
	CALL	OPL_WRITE

	MOV	AX,0120H			; *** STIMME 1 ***
	CALL	OPL_WRITE

	MOV	AX,00140H
	CALL	OPL_WRITE

	MOV	AX,0123H
	CALL	OPL_WRITE

	MOV	AX,00143H
	CALL	OPL_WRITE
	
	MOV	AX,0121H			; *** STIMME 2 ***
	CALL	OPL_WRITE

	MOV	AX,00141H
	CALL	OPL_WRITE

	MOV	AX,0124H
	CALL	OPL_WRITE

	MOV	AX,00144H
	CALL	OPL_WRITE

	MOV	AX,0122H			; *** STIMME 3 ***
	CALL	OPL_WRITE

	MOV	AX,00142H
	CALL	OPL_WRITE

	MOV	AX,0125H
	CALL	OPL_WRITE

	MOV	AX,00145H
	CALL	OPL_WRITE

	STC
	RET

;********** Warten auf OPL-Chip [ CX-> Wartezeit (6) **********

OPL_WAIT:
	PUSH	AX DX
        MOV 	DX,0388H
OPL_WAIT_1:
        IN	AL,DX
        LOOP 	OPL_WAIT_1
        POP  	DX AX
        RET

;********** Schreiben in ein OPL Register [ AL->Register,AH->Wert ] **********

OPL_WRITE:
	PUSH	AX DX
	MOV	DX,0388H
	OUT	DX,AL
	MOV	CX,60
	CALL	OPL_WAIT
	MOVZX	DI,AL
	MOV	OPL_SHADOW[DI],AH
	INC	DX
	MOV	AL,AH
	OUT	DX,AL
	POP	DX AX
	RET

;********** Lesen eines OPL Registers [ AL->Register,AH->Wert] **********

OPL_READ:
	MOVZX	DI,AL
	MOV	AH,OPL_SHADOW[DI]
	RET	
;***************************************
END





