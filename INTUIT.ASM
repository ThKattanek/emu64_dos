;****************************************
;*					*
;* Titel: Intuitions Funktionen		*
;* Autor: Thorsten Kattanek		*
;* Datum: 15.06.1999			*
;* Ort  : Berlin			*
;* Vers : 1.00				*
;* Info : Hier sind alle Funktionen	*
;*	für die Fenstertechnik 		*
;*					*
;****************************************

PUBLIC	INTU_OPEN_WINDOW,INTU_START,INTU_REDRAW_WINDOW,INTU_MOVE_WINDOW,INTU_16BIT_ASCII,WINDOW_X,WINDOW_Y
PUBLIC	INTU_REDRAW_OBJEKT,INTU_CLOSE_WINDOW,WINDOW_ANZAHL,INTU_STATUS,INTU_FILE_REQUEST,INTU_FILE_REQUEST_CLOSE,FILE_PUFFER

EXTRN	GR_SET_BOX:PROC,GR_SET1_REC:PROC,GR_SET0_REC:PROC,GR_TEXT:PROC,CHAR_X:WORD,CHAR_Y:WORD,CHAR_COLOR:BYTE,CHAR_BACK_COLOR:BYTE
EXTRN	GR_SET_H_LINE:PROC,MAUS_X:WORD,MAUS_Y:WORD,MAUS_TASTEN:WORD,GR_INV_REC:PROC,GR_MAUS_AN:PROC,GR_MAUS_AUS:PROC,GR_SET_V_LINE:PROC
EXTRN	GR_READ_POINT:PROC,GR_TEXT_TRANS:PROC,GR_SET_PAGE:PROC,GR_VIEW_PAGE:PROC,X:WORD,Y:WORD,GR_SET_CHAR:PROC,GR_RAM_TO_VRAM:PROC
EXTRN	GR_RAM_TO_VRAM_TRANS:PROC

.MODEL SMALL
.STACK 100h

;****************************************
.DATA

WINDOW_LIST	DB	255 DUP(?)
WINDOW_ANZAHL	DB	0
WINDOW_LIST_TMP	DW	2 DUP(?)
WINDOW_BREITE	DW	?
WINDOW_HÖHE	DW	?
WINDOW_X_DIF_MIN	DW	?
WINDOW_Y_DIF_MIN	DW	?
WINDOW_X_DIF_MAX	DW	?
WINDOW_Y_DIF_MAX	DW	?
WINDOW_X_OLD	DW	0
WINDOW_Y_OLD	DW	0
WINDOW_X	DW	0
WINDOW_Y	DW	0
OBJEKT_ZEIGER	DW	0
TMP00		DW	0
TMP01		DW	0
TMP02		DW	0
TMP03		DW	0
OLD_X		DW	0
OLD_Y		DW	0
ASCII_16BIT_PUFFER	DB 6 DUP(" "),0 
PS		DB	0
PV		DB	0
TITEL_FARBE	DB  	0
F_RAHMEN	DB 	1
F_HINTERGRUND	DB	0
F_TITELLEISTE	DB	0
INTU_STATUS	DB  	0			;Bit0 =1 Ende aus Endlosschleife
						;Bit1 =1 Keine Prüfung auf Fenster die nicht Vorne sind


OBJEKT_TBL	DW	O1,O1,O2,O3,O4,O5,O6,O7,O8,O9,O10,O11,O12,O13,O14,O15,O15,O17
OBJEKT_CLICK_TBL DW	OC1,OC1,OC2,OC3,OC4,OC1,OC6,OC7,OC8,OC9,OC10,OC11,OC12,OC13,OC14,OC15,OC16,OC11

;********************** FILE REQUEST ********************

FENSTER_255	DB 255
		DW 10,10,198,300
		DW F_NAME_255
		DB 7+8
		DB 1
		DW F255_00
		DB 1
		DW F255_01
		DB 11
		DW F255_02
		DB 4
		DW F255_03
		DB 14
		DW F255_04
		DB 0
F_NAME_255	DB "Diskimage laden",0

F255_00		DW 45,262,100,15
		DW OK
		DB 2,"OK",0
F255_01		DW 45,277,100,15
		DW ABBRUCH
		DB 7,"Abbruch",0
F255_02		DW 10,25,165,212
		DB 12+6
		DB 13
		DB 15
		DB 0
		DB 0
		DB 0
		DB 0
		DW 0
		DW 0
		DW D64_AUSWAHL	
F255_03		DW 180,25,13,212
		DW 0
		DW 198
		DW D64_LIST_SCROLLEN
F255_04		DW 10,240,165,18
		DB 15
		DB 0
		DW 12
		DW 12
		DW 0
		DW 0
		DW FILE_NAME_PUFFER
		DB 0
		DB 0
		DW 0

;******* Puffer für D64 Laden ********

FILE_PUFFER	DW 0
OLD_DTA_SEG	DW 0
OLD_DTA_OFF	DW 0
DTA		DB 265 DUP(?)
SUCHMASKE	DB "*.*",0

FILE_NAME_PUFFER	DB 12 DUP(?)

;****************************************
.486
.CODE	
;**************************************************************************************************

;** Schliesst ein Fenster **
;** Eingabe AL Fensternummer **

INTU_CLOSE_WINDOW PROC

	MOVZX	SI,WINDOW_ANZAHL
	MOV	CL,2
	SHL	SI,CL
	MOV	BX,SI
ICW_10:
	CMP	WINDOW_LIST[SI],AL
	JE	ICW_20
	SUB	SI,4
	JNS	ICW_10
	JMP	ICW_40
ICW_20:
	MOV	DI,WORD PTR WINDOW_LIST[SI+2]
ICW_30:
	MOV	EAX,DWORD PTR WINDOW_LIST[SI+4]
	MOV	DWORD PTR WINDOW_LIST[SI],EAX
	ADD	SI,4
	CMP	SI,BX
	JNE	ICW_30
	DEC	WINDOW_ANZAHL
	CALL	INTU_REDRAW_ALL_WINDOW
	AND 	INTU_STATUS,11111101B
ICW_40:
	RET

ENDP


;** Öffnet ein Fenster auf dem Screen **
;** Eingabe: DS:DI Zeiger auf Fensterstruktur **

INTU_OPEN_WINDOW PROC

	MOVZX	SI,WINDOW_ANZAHL
	MOV	CL,2
	SHL	SI,CL
IOW_20:
	CMP	WORD PTR WINDOW_LIST[SI+2],DI
	JE	IOW_ENDE
	SUB	SI,4
	JNS	IOW_20
	
	MOVZX	SI,WINDOW_ANZAHL
	MOV	CL,2
	SHL	SI,CL
	MOV	AL,[DI]
	MOV	AH,[DI+11]
	AND	AH,8
	JZ	IOW_25
	OR	INTU_STATUS,2
IOW_25:
	MOV	WINDOW_LIST[SI],AL
	MOV	WORD PTR WINDOW_LIST[SI+2],DI
	INC	WINDOW_ANZAHL
	CALL	INTU_REDRAW_ALL_WINDOW
	RET
	
;***** Fenster Objekte Zeichnen ******

IOW_0:	
	ADD	DI,12
IOW_10:	
	MOVZX	SI,BYTE PTR [DI]
	CMP	SI,0
	JE	IOW_ENDE
	SHL	SI,1
	MOV	BX,OBJEKT_TBL[SI]
	MOV	SI,[DI+1]
	CALL	BX
	ADD	DI,3
	JMP	IOW_10
IOW_ENDE:
	RET
ENDP

;***** Zeichnet ein Objekt Neu *****

INTU_REDRAW_OBJEKT PROC
	PUSHA
	MOV	BX,DI[1]
	MOV	WINDOW_X,BX
	MOV	BX,DI[3]
	MOV	WINDOW_Y,BX
	MOV	CL,3
	MUL	CL
	ADD	DI,12
	ADD	DI,AX
	
	MOVZX	SI,BYTE PTR [DI]
	SHL	SI,1
	MOV	BX,OBJEKT_TBL[SI]
	MOV	SI,[DI+1]
	CALL	BX
	POPA
	RET
ENDP

;******* Erzeugt ein File Request ******

INTU_FILE_REQUEST PROC

	MOV	WORD PTR FENSTER_255[9],AX
	MOV	WORD PTR F255_00[8],DI
	MOV	F255_04[18],DX
	CALL	DTA_TO_DIR
	MOV	AX,FILE_PUFFER
	MOV	F255_02[17],AX
	LEA	DI,FENSTER_255
	CALL	INTU_OPEN_WINDOW
	RET
ENDP
	
INTU_FILE_REQUEST_CLOSE PROC

	JMP	ABBRUCH
ENDP


;************** Hier sind alle Unterprogramme für die jeweiligen Objekte untergebracht ***************

;********** TEXT BUTTON **********

O1:
	PUSH	DI	
	MOV	AX,[SI]
	MOV	BX,[SI+2]
	ADD	AX,WINDOW_X
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	MOV	DX,[SI+6]
	PUSH	SI
	MOV	SI,1BH
	CALL	GR_SET_BOX
	MOV	SI,181DH
	CALL	GR_SET1_REC
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	CALL	GR_SET1_REC
	
	POP	SI
	MOV	AX,[SI+4]
	MOV	BX,[SI+6]
	SHR	AX,1
	SHR	BX,1
	ADD	AX,WINDOW_X
	ADD	AX,[SI]
	ADD	BX,WINDOW_Y
	ADD	BX,[SI+2]
	SUB	BX,8

	INC	AX
	MOV	CHAR_X,AX
	INC	BX
	MOV	CHAR_Y,BX
	
	ADD	SI,10
	MOV	AX,[SI]
	MOV	AH,9
	MUL	AH
	SHR	AX,1
	SUB	CHAR_X,AX
		
	INC	SI
	MOV	DI,SI
	MOV	CHAR_COLOR,0
	CALL	GR_TEXT_TRANS
	POP	DI
	RET
	
OC1:
	PUSH	DI
	PUSH	SI
	MOV	AX,[SI]
	MOV	BX,[SI+2]
	ADD	AX,WINDOW_X
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	MOV	DX,[SI+6]
	MOV	SI,1D18H
	CALL	GR_MAUS_AUS
	CALL	GR_SET1_REC
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	CALL	GR_SET1_REC
	CALL	GR_MAUS_AN
OC1_10:
	MOV	AX,MAUS_TASTEN
	AND	AX,1
	JNZ	OC1_10
	
	POP	SI
	PUSH	SI
	MOV	AX,[SI]
	MOV	BX,[SI+2]
	ADD	AX,WINDOW_X
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	MOV	DX,[SI+6]
	MOV	SI,181DH
	CALL	GR_MAUS_AUS
	CALL	GR_SET1_REC
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	CALL	GR_SET1_REC
	CALL	GR_MAUS_AN
	
	POP	SI
	MOV	BX,[SI+8]
	CALL	BX
	POP	DI
	RET

;********** PRINT TEXT **********

O2:
	PUSH	DI
	MOV	AX,[SI]					
	ADD	AX,WINDOW_X
	MOV	CHAR_X,AX
	MOV	AX,[SI+2]
	ADD	AX,WINDOW_Y
	MOV	CHAR_Y,AX
	MOV	AL,[SI+8]
	MOV	CHAR_COLOR,AL
	MOV	AL,[SI+9]
	MOV	CHAR_BACK_COLOR,AL
	MOV	DI,SI
	ADD	DI,10
	CALL	GR_TEXT
	POP	DI
	RET
OC2:
	RET
	
;********** HORIZONTAL SCROLLBALKEN **********

O3:
	PUSH	DI
	MOV	AX,[SI]
	ADD	AX,WINDOW_X
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	SUB	CX,2
	MOV	DX,[SI+6]
	PUSH	SI
	MOV	SI,0
	CALL	GR_SET0_REC
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	MOV	SI,15
	CALL	GR_SET_BOX
	DEC	AX
	DEC	BX
	ADD	CX,2
	ADD	DX,2
	
	POP	SI
	INC	AX
	ADD	AX,[SI+8]
	INC	BX
	MOV	CX,[SI+10]
	SUB	CX,1
	MOV	DX,[SI+6]
	SUB	DX,2
	MOV	SI,1BH
	CALL	GR_SET_BOX
	MOV	SI,181DH
	CALL	GR_SET1_REC
	
	POP	DI
	RET
OC3:
	PUSH	DI
	
	MOV	OBJEKT_ZEIGER,SI
	
	MOV	DI,MAUS_X
	SUB	DI,WINDOW_X
	SUB	DI,[SI]
	SUB	DI,[SI+8]
	MOV	TMP01,DI
	
	MOV	DI,[SI]
	INC	DI
	ADD	DI,WINDOW_X
	MOV	TMP02,DI					;*** Minimum X_Position des Reglers ***
	ADD	DI,[SI+4]
	SUB	DI,3
	SUB	DI,[SI+10]
	MOV	TMP03,DI					;*** Maximum X_Position des Reglers ***
	
	
	MOV	AX,[SI]						;*** X_MIN für Knopf ***
	INC	AX
	ADD	AX,WINDOW_X
	ADD	AX,[SI+8]
	
	MOV	BX,AX						;*** X_MAX für Knopf ***
	ADD	BX,[SI+10]
	SUB	BX,3
	
	MOV	CX,[SI+2]					;*** Y_MIN für Knopf ***
	INC	CX
	ADD	CX,WINDOW_Y
	
	MOV	DX,CX
	ADD	DX,[SI+6]
	SUB	DX,3
	
	CMP	MAUS_X,AX
	JL	OC3_100
	CMP	MAUS_X,BX
	JG	OC3_100
	CMP	MAUS_Y,CX
	JL	OC3_100
	CMP	MAUS_Y,DX
	JG	OC3_100
	
	MOV	AX,[SI]
	ADD	AX,WINDOW_X
	INC	AX
	ADD	AX,[SI+8]
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y	
	INC	BX
	MOV	CX,[SI+10]
	DEC	CX
	MOV	DX,[SI+6]
	SUB	DX,2
OC3_05:	
	CALL	GR_MAUS_AUS
	MOV	SI,1BH
	CALL	GR_SET_BOX
	MOV	SI,1D18H
	CALL	GR_SET1_REC
	CALL	GR_MAUS_AN
	
	MOV	TMP00,AX
	
	MOV	AX,MAUS_X
OC3_10:
	MOV	DI,MAUS_TASTEN
	AND	DI,1
	JZ	OC3_20
	CMP	MAUS_X,AX
	JE	OC3_10
	
	
	MOV	AX,MAUS_X
	SUB	AX,TMP01
	
	CMP	AX,TMP02
	JL	OC3_10
	CMP	AX,TMP03
	JG	OC3_10

	MOV	AX,TMP00
	MOV	SI,15
	CALL	GR_MAUS_AUS
	CALL	GR_SET_BOX
	CALL	GR_MAUS_AN
	
	MOV	AX,MAUS_X
	SUB	AX,TMP01
	
	PUSHA
	MOV	SI,OBJEKT_ZEIGER
	
	SUB	AX,WINDOW_X
	SUB	AX,[SI]
	DEC	AX
	MOV	[SI+8],AX
	
	MOV	BX,[SI+12]
	CALL	BX	
	POPA
	
	JMP	OC3_05
OC3_20:
	CMP	AX,TMP02
	JL	OC3_30
	CMP	AX,TMP03
	JG	OC3_40
	JMP	OC3_50
OC3_30:
	MOV	AX,TMP02
	ADD	AX,TMP01
	DEC	AX
	JMP	OC3_50
OC3_40:
	MOV	AX,TMP03
	ADD	AX,TMP01
	DEC	AX
OC3_50:
	PUSH	AX
	
	MOV	AX,TMP00
	MOV	SI,15
	CALL	GR_MAUS_AUS
	CALL	GR_SET_BOX
	CALL	GR_MAUS_AN
	
	POP	AX
	SUB	AX,TMP01
	INC	AX
	CALL	GR_MAUS_AUS
	MOV	SI,1BH
	CALL	GR_SET_BOX
	MOV	SI,181DH
	CALL	GR_SET1_REC
	CALL	GR_MAUS_AN
	
	MOV	SI,OBJEKT_ZEIGER
	SUB	AX,WINDOW_X
	SUB	AX,[SI]
	DEC	AX
	MOV	[SI+8],AX	
OC3_100:
	POP	DI
	RET
		
;********** VERTICAL SCROLLBALKEN **********

O4:
	PUSH	DI
	MOV	AX,[SI]
	ADD	AX,WINDOW_X
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	SUB	CX,2
	MOV	DX,[SI+6]
	PUSH	SI
	MOV	SI,0
	CALL	GR_SET0_REC
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	MOV	SI,15
	CALL	GR_SET_BOX
	DEC	AX
	DEC	BX
	ADD	CX,2
	ADD	DX,2
	
	POP	SI
	INC	BX
	ADD	BX,[SI+8]
	INC	AX
	MOV	CX,[SI+4]
	SUB	CX,4
	MOV	DX,[SI+10]
	SUB	DX,1
	MOV	SI,1BH
	CALL	GR_SET_BOX
	MOV	SI,181DH
	CALL	GR_SET1_REC
	
	POP	DI
	RET
OC4:
	PUSH	DI
	
	MOV	OBJEKT_ZEIGER,SI
	
	MOV	DI,MAUS_Y					;*** TMP01 abstand von Mauszeiger zu oberes Knopfende
	SUB	DI,WINDOW_Y
	SUB	DI,[SI+2]
	SUB	DI,[SI+8]
	MOV	TMP01,DI
	
	MOV	DI,[SI+2]
	INC	DI
	ADD	DI,WINDOW_Y
	MOV	TMP02,DI					;*** Minimum X_Position des Reglers ***
	ADD	DI,[SI+6]
	SUB	DI,[SI+10]
	DEC	DI
	MOV	TMP03,DI					;*** Maximum X_Position des Reglers ***
	
	
	MOV	AX,[SI]						;*** X_MIN für Knopf ***
	INC	AX
	ADD	AX,WINDOW_X
	
	MOV	BX,AX						;*** Länge für Knopf ***
	ADD	BX,[SI+4]
	SUB	BX,3
	
	MOV	CX,[SI+2]					;*** Y_MIN für Knopf ***
	INC	CX
	ADD	CX,WINDOW_Y
	ADD	CX,[SI+8]
	
	MOV	DX,CX						;*** Höhe für Knopf ***
	ADD	DX,[SI+10]
	SUB	DX,3
	
	CMP	MAUS_X,AX
	JL	OC4_100
	CMP	MAUS_X,BX
	JG	OC4_100
	CMP	MAUS_Y,CX
	JL	OC4_100
	CMP	MAUS_Y,DX
	JG	OC4_100
	
	MOV	AX,[SI]
	ADD	AX,WINDOW_X
	INC	AX
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	ADD	BX,[SI+8]	
	INC	BX
	MOV	CX,[SI+4]
	SUB	CX,4
	MOV	DX,[SI+10]
	DEC	DX
OC4_05:	
	CALL	GR_MAUS_AUS
	MOV	SI,1BH
	CALL	GR_SET_BOX
	MOV	SI,1D18H
	CALL	GR_SET1_REC
	CALL	GR_MAUS_AN
	
	MOV	TMP00,BX
	
	MOV	BX,MAUS_Y
OC4_10:
	MOV	DI,MAUS_TASTEN
	AND	DI,1
	JZ	OC4_20
	CMP	MAUS_Y,BX
	JE	OC4_10
	
	
	MOV	BX,MAUS_Y
	SUB	BX,TMP01
	
	CMP	BX,TMP02
	JL	OC4_10
	CMP	BX,TMP03
	JG	OC4_10

	MOV	BX,TMP00
	MOV	SI,15
	CALL	GR_MAUS_AUS
	CALL	GR_SET_BOX
	CALL	GR_MAUS_AN
	
	MOV	BX,MAUS_Y
	SUB	BX,TMP01
	
	PUSHA
	MOV	SI,OBJEKT_ZEIGER
	
	SUB	BX,WINDOW_Y
	SUB	BX,[SI+2]
	DEC	BX
	MOV	[SI+8],BX
	
	MOV	BX,[SI+12]
	CALL	BX	
	POPA
	
	JMP	OC4_05
OC4_20:
	CMP	BX,TMP02
	JL	OC4_30
	CMP	BX,TMP03
	JG	OC4_40
	JMP	OC4_50
OC4_30:
	MOV	BX,TMP02
	ADD	BX,TMP01
	DEC	BX
	JMP	OC4_50
OC4_40:
	MOV	BX,TMP03
	ADD	BX,TMP01
	DEC	BX
OC4_50:
	PUSH	BX
	
	MOV	BX,TMP00
	MOV	SI,15
	CALL	GR_MAUS_AUS
	CALL	GR_SET_BOX
	CALL	GR_MAUS_AN
	
	POP	BX
	SUB	BX,TMP01
	INC	BX
	CALL	GR_MAUS_AUS
	MOV	SI,1BH
	CALL	GR_SET_BOX
	MOV	SI,181DH
	CALL	GR_SET1_REC
	CALL	GR_MAUS_AN
	
	MOV	SI,OBJEKT_ZEIGER
	SUB	BX,WINDOW_Y
	SUB	BX,[SI+2]
	DEC	BX
	MOV	[SI+8],BX	
OC4_100:
	POP	DI
	RET

;********** USER OBJEKT **********
	
O5:
	PUSH	DI
	MOV	BX,[SI+8]
	CALL	BX
	POP	DI
	RET
	
;********** READ FARB INDEX **********

O6:
	PUSH	DI
	POP	DI
	RET
OC6:
	PUSH	DI
	CALL	GR_MAUS_AUS
	MOV	AX,MAUS_X
	MOV	BX,MAUS_Y
	CALL	GR_READ_POINT
	CALL	GR_MAUS_AN
OC6_10:
	MOV	DI,MAUS_TASTEN
	AND	DI,1
	JNZ	OC6_10
	

	MOV	[SI+8],CL
	MOV	BX,[SI+9]
	CALL	BX
	POP	DI
	RET
	
;********** HEX IN/OUT **********

O7:
	PUSH	DI
	
	MOV	WORD PTR ASCII_16BIT_PUFFER[0],"  "
	MOV	WORD PTR ASCII_16BIT_PUFFER[2],"  "
	MOV	WORD PTR ASCII_16BIT_PUFFER[4],"  "
	
	MOV	AX,[SI]
	ADD	AX,WINDOW_X
	MOV	CHAR_X,AX
	MOV	AX,[SI+2]
	ADD	AX,WINDOW_Y
	MOV	CHAR_Y,AX
	MOV	AL,[SI+8]
	MOV	CHAR_COLOR,AL
	MOV	AX,[SI+9]
	LEA	DI,ASCII_16BIT_PUFFER
	CALL	INTU_16BIT_ASCII
	CALL	GR_TEXT
	
	
	POP	DI
	RET
OC7:
	PUSH	DI
	POP	DI
	RET

;********** SET BLOCK **********

O8:
	PUSH	DI
	MOV	AX,[SI]
	MOV	BX,[SI+2]
	ADD	AX,WINDOW_X
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	MOV	DX,[SI+6]
	MOVZX	SI,[SI+8]
	CALL	GR_SET_BOX
	POP	DI
	RET
OC8:
	RET

;********** RADIO BUTTON **********

O9:
	PUSH	DI
	PUSH	SI
	MOV	AX,[SI]
	MOV	BX,[SI+2]
	ADD	AX,WINDOW_X
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	MOV	DX,[SI+6]
	MOV	SI,15
	CALL	GR_SET_BOX
	MOV	SI,18
	CALL	GR_SET0_REC
	
	POP	SI
	CMP	BYTE PTR [SI+8],0
	JE	O9_10
	ADD	AX,2
	ADD	BX,2
	SUB	CX,4
	SUB	DX,4
	MOVZX	SI,BYTE PTR [SI+9]
	CALL	GR_SET_BOX
O9_10:
	POP	DI
	RET
OC9:
	PUSH	DI
	MOV	AX,[SI]
	ADD	AX,WINDOW_X
	ADD	AX,2
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	ADD	BX,2
	MOV	CX,[SI+4]
	SUB	CX,4
	MOV	DX,[SI+6]
	SUB	DX,4
	PUSH	SI
	NOT	BYTE PTR [SI+8]
	CMP	BYTE PTR [SI+8],0
	JNE	OC9_10
	MOV	SI,15
	JMP	OC9_20
OC9_10:
	MOVZX	SI,BYTE PTR [SI+9]
OC9_20:
	CALL	GR_MAUS_AUS
	CALL	GR_SET_BOX
	CALL	GR_MAUS_AN
	POP	SI
	
	MOV	BX,[SI+10]
	CALL	BX
OC9_30:
	MOV	DI,MAUS_TASTEN
	AND	DI,1
	JNZ	OC9_30
	
	POP	DI
	RET
	
;********** RAHMEN **********
	
O10:
	PUSH	DI
	MOV	AX,[SI]
	ADD	AX,WINDOW_X
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	MOV	DX,[SI+6]
	MOV	SI,[SI+8]
	CALL	GR_SET0_REC
	POP	DI
	RET
OC10:
	RET
	
;********** LISTFELD **********
	
O11:
	PUSH	DI
	MOV	AX,[SI]						
	ADD	AX,WINDOW_X
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	MOV	DX,[SI+6]
	PUSH	SI
	MOV	SI,18
	CALL	GR_SET0_REC
	POP	SI
	
	
	MOV	DL,BYTE PTR [SI+12]				; *** Oberste Zeile die Dargestellt werden soll ***
	ADD	DL,BYTE PTR [SI+9]				; *** Addiere Anzahl der Dargestellten Zeilen ***
	CMP	DL,BYTE PTR [SI+14]				; *** Vergleiche mit Anzahl der Zeilen im Arry
	JL	O11_30						; *** Wenn Kleiner dann kann ab da Dargestellt werden ***
					
	MOV	DL,BYTE PTR [SI+14]				; *** Wenn Grösser dann Arry Zeilen - Anzahl Darstellbarer Zeilen ***
	SUB	DL,BYTE PTR [SI+9]
	JNC	O11_40
	MOV	DL,0
	JMP	O11_40
O11_30:
	MOV	DL,BYTE PTR [SI+12]	
O11_40:
	ADD	AX,2						; *** Text Liste ausgeben vorbereiten ***
	MOV	CHAR_X,AX
	ADD	BX,2
	MOV	CHAR_Y,BX
	MOV	BX,AX						; *** In DX befindet sich immer die X Position des Textes ***
	MOV	CL,BYTE PTR [SI+10]
	MOV	CHAR_BACK_COLOR,CL
	MOV	CL,BYTE PTR [SI+11]
	MOV	CHAR_COLOR,CL
	
	MOV	DI,[SI+15]					; *** Zeiger auf List Arry holen ***
	MOV	FS,[SI+17]
	
	MOV	AL,BYTE PTR [SI+8]
	MUL	DL
	ADD	DI,AX	
	
	MOV	DX,BX
	MOV	BH,[SI+9]
O11_10:
	MOV	AH,[SI+8]					; *** Anzahl der Zeichen in einer Zeile holen ***
O11_20:
	MOV	AL,FS:[DI]
	PUSH	DI BX DX SI
	CALL	GR_SET_CHAR
	POP	SI DX BX DI
	INC	DI
	ADD	CHAR_X,9
	DEC	AH
	JNZ	O11_20
	MOV	CHAR_X,DX
	ADD	CHAR_Y,16
	DEC	BH
	JNZ	O11_10
	
	POP	DI
	RET
OC11:
	MOV	DI,1
	MOV	AX,MAUS_Y
	SUB	AX,WINDOW_Y
	SUB	AX,[SI+2]
	MOV	BX,[SI+6]
	SUB	BX,6
	CMP	AX,BX
	JG	OC11_20
	MOV	BL,16
	DIV	BL
	MOV	[SI+13],AL
	MOV	BL,16
	MUL	BL
	INC	AX
	MOV	BX,AX
	ADD	BX,WINDOW_Y
	ADD	BX,[SI+2]
	MOV	AX,[SI]
	ADD	AX,WINDOW_X
	INC	AX
	MOV	CX,[SI+4]
	DEC	CX
	DEC	CX
	MOV	DX,18
	PUSH	SI
	MOV	SI,40
	CALL	GR_MAUS_AUS
	CALL	GR_SET0_REC
	CALL	GR_MAUS_AN
OC11_10:
	MOV	DI,MAUS_TASTEN
	AND	DI,1
	JNZ	OC11_10
	MOV	SI,15
	CALL	GR_MAUS_AUS
	CALL	GR_SET0_REC
	CALL	GR_MAUS_AN
	POP	SI
	MOV	BX,[SI+19]
	CALL	BX
OC11_20:
	RET
	
;********** BMP **********
	
O12:
	PUSH 	DI
	MOV	AX,[SI]
	ADD	AX,WINDOW_X
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	MOV	CX,[Si+4]
	MOV	DX,[Si+6]
	MOV	SI,[SI+8]
	CALL	GR_RAM_TO_VRAM
	POP	DI
	RET
OC12:
	RET
	
;********** READ POS **********
	
O13:
	RET
OC13:
	PUSH	DI
	MOV	AX,MAUS_X
	MOV	BX,MAUS_Y
	SUB	AX,WINDOW_X
	SUB	AX,[SI]
	SUB	BX,WINDOW_Y
	SUB	BX,[SI+2]
	MOV	[SI+8],AX
	MOV	[SI+10],BX
	CMP	AX,OLD_X
	JNE	OC13_10
	CMP	BX,OLD_Y
	JNE	OC13_10
	POP	DI
	RET
OC13_10:
	MOV	OLD_X,AX
	MOV	OLD_Y,BX
	MOV	BX,[SI+12]
	CALL	BX
	POP	DI
	RET
	
;********** STRING EINGABE **********
	
O14:
	PUSH	DI
	MOV	AX,[SI]						;** Rahmen Zeichen **
	ADD	AX,WINDOW_X
	MOV	CHAR_X,AX
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	MOV	CHAR_Y,BX
	ADD	CHAR_X,3
	INC	CHAR_Y
	MOV	CX,[SI+4]
	MOV	DX,[SI+6]
	PUSH	SI
	MOV	SI,15
	CALL	GR_SET_BOX
	POP	SI
	PUSH	SI
	MOV	SI,0
	CALL	GR_SET0_REC
	POP	SI
	
	MOV	AL,[SI+8]
	MOV	CHAR_BACK_COLOR,AL
	MOV	AL,[SI+9]
	MOV	CHAR_COLOR,AL
	
	MOV	DI,[SI+18]
	ADD	DI,[SI+16]
	
	MOV	BX,[SI+14]
	SUB	BX,[SI+16]
	
	MOV	CX,[SI+10]
O14_10:	
	CMP	BX,0
	JE	O14_20
	CMP	CX,0
	JE	O14_20
	
	MOV	AL,[DI]
	PUSH	CX BX DI
	CALL	GR_SET_CHAR
	POP	DI BX CX
	INC	DI
	DEC	BX
	DEC	CX
	ADD	CHAR_X,9
	JMP	O14_10
O14_20:	
	
	POP	DI
	RET
OC14:
	PUSH	DS						;** Tastaturpuffer löschen **
	MOV	DX,0040H
	MOV	DS,DX
	MOV	BX,01AH
	MOV	WORD PTR [BX],1EH
	ADD	BX,2
	MOV	WORD PTR [BX],1EH
	POP	DS
	
	PUSH	DI						;** Rahmen Rot zeichnen und CHAR_Y setzen **
	MOV	AX,[SI]
	ADD	AX,WINDOW_X
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	MOV	CHAR_Y,BX
	INC	CHAR_Y
	MOV	CX,[SI+4]
	MOV	DX,[SI+6]
	PUSH	SI
	MOV	SI,40
	CALL	GR_MAUS_AUS
	CALL	GR_SET0_REC
	POP	SI
	
	CALL	SET_COURSOR
OC14_10:
	MOV	AH,0
	INT	16H
	
	CMP	AH,04BH				
	JE    	OC14_20						;** Taste [Coursor Left] wurde gedrückt **
	CMP	AH,04DH
	JE	OC14_30						;** Taste [Coursor Right] wurde gedrückt **
	CMP	AH,00EH
	JE	OC14_70						;** Taste [Backspace] wurde gedrückt **
	CMP 	AH,053H
	JE	OC14_30						;** Taste [Entfernen] wurde gedrückt **
	CMP	AH,01CH
	JE	OC14_160					;** Taste [Return] wurde gedrückt **
	
	PUSH	AX
	MOV	AL,[SI+20]					;** Eine andere Taste wie oben wurde gedrückt **
	MOV	CL,9						;** Zeichen an Aktueller Coursor Position ausgeben **
	MUL	CL
	ADD	AX,WINDOW_X
	ADD	AX,3
	ADD	AX,[SI]
	MOV	CHAR_X,AX
	POP	AX
	
	MOV	BL,BYTE PTR [SI+10]				;** Ist der Coursor schon ganz rechts am Rand der Eingabe Maske ? **
	CMP	BYTE PTR [SI+20],BL
	JE	OC14_10
	
	MOV	BX,[SI+14]					;** Maximale Stringgrösse schon erreicht ? **
	CMP	BX,[SI+12]
	JE	OC14_10
	
	MOV	DI,[SI+18]					;** Zeichen in Stringpuffer eintragen **
	ADD	DI,[SI+16]
	MOVZX   BX,BYTE PTR [SI+20]
	ADD	DI,BX
	MOV	BYTE PTR [DI],AL
	
	INC	WORD PTR [SI+14]				;** Stringgrösse um eins erhöhen **
	
	PUSH	SI
	CALL	GR_SET_CHAR
	POP	SI
	
	INC	BYTE PTR [SI+20]
	CALL	SET_COURSOR
	
	
	JMP	OC14_10
OC14_20:							;** Coursor eins nach links **
	CMP	BYTE PTR [SI+20],0				;** Ist der Coursor schon ganz links am Rand der Eingabe Maske ? **					
	JE	OC14_55
	
	DEC	BYTE PTR [SI+20]
	CALL	SET_COURSOR
	JMP	OC14_10
OC14_30:							;** Coursor eins nach rechts **	
	MOV	AL,BYTE PTR [SI+10]
	CMP	BYTE PTR [SI+20],AL				;** Ist der Coursor schon ganz rechts am Rand der Eingabe Maske ? **
	JE	OC14_40
	
	MOVZX  	AX,BYTE PTR [SI+20]				;** Ist der Coursor am Ende des Strings ? **
	ADD	AX,[SI+16]
	CMP	AX,[SI+14]
	JE	OC14_10
	
	INC	BYTE PTR [SI+20]
	CALL	SET_COURSOR
	JMP	OC14_10
OC14_40:
	MOVZX  	AX,BYTE PTR [SI+20]				;** Geht der String noch weiter nach rechts ? **
	ADD	AX,[SI+16]
	CMP	AX,[SI+14]
	JE	OC14_10
	
	INC	WORD PTR [SI+16]				;** Ja String um eins nach Links schieben **
OC14_43:	
	MOV	AX,[SI]						;** String neu Zeicnen **	
	ADD	AX,WINDOW_X
	MOV	CHAR_X,AX
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	MOV	CHAR_Y,BX
	ADD	CHAR_X,3
	INC	CHAR_Y
	MOV	CX,[SI+4]
	MOV	DX,[SI+6]
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	PUSH	SI
	MOV	SI,15
	CALL	GR_SET_BOX
	POP	SI
	
	MOV	AL,[SI+8]					
	MOV	CHAR_BACK_COLOR,AL
	MOV	AL,[SI+9]
	MOV	CHAR_COLOR,AL
	
	MOV	DI,[SI+18]
	ADD	DI,[SI+16]
	
	MOV	BX,[SI+14]
	SUB	BX,[SI+16]
	
	MOV	CX,[SI+10]
OC14_45:	
	CMP	BX,0
	JE	OC14_50
	CMP	CX,0
	JE	OC14_50
	
	MOV	AL,[DI]
	PUSH	CX BX DI SI
	CALL	GR_SET_CHAR
	POP	SI DI BX CX
	INC	DI
	DEC	BX
	DEC	CX
	ADD	CHAR_X,9
	JMP	OC14_45
OC14_50:
	CALL	SET_COURSOR
	JMP	OC14_10
OC14_55:
	MOVZX  	AX,BYTE PTR [SI+20]				;** Ist der Coursor am Anfang des Strings ? **
	ADD	AX,[SI+16]
	JZ	OC14_10
	DEC	WORD PTR [SI+16]				;** Nein String um eins nach rechts schieben **
	JMP	OC14_43						

OC14_70:							;** Backspace Funktion **
	CMP	WORD PTR [SI+14],0
	JE	OC14_10						;** Wenn kein zeichen mehr da ist, kann auch keins gelöscht werden **
	
	MOVZX 	DI,[SI+20]
	ADD	DI,[SI+16]
	JZ	OC14_10						;** Wenn am Anfang des Strings dann auch nicht löschen **
	CMP	DI,[SI+14]
	JE	OC14_76
	ADD	DI,[SI+18]
	
	MOV	BX,[SI+14]
	SUB	BX,DI
	ADD	BX,[SI+18]
OC14_75:
	MOV	AL,[DI]
	MOV	[DI-1],AL
	INC	DI
	DEC	BX
	JNZ	OC14_75
	CMP	BYTE PTR [SI+20],0
	JE	OC14_80
OC14_76:
	DEC	WORD PTR [SI+14]
	DEC	BYTE PTR [SI+20]
	JMP	OC14_43						
OC14_80:
	DEC	WORD PTR [SI+14]
	DEC	WORD PTR [SI+16]
	JMP	OC14_43




OC14_160:
	MOV	AX,[SI]
	ADD	AX,WINDOW_X
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	MOV	DX,[SI+6]
	PUSH	SI
	MOV	SI,0
	CALL	GR_SET0_REC
	POP	SI
	
	ADD	BX,2
	MOV	DX,13
	MOV	AL,[SI+21]
	MOV	CL,9
	MUL	CL
	ADD	AX,WINDOW_X
	ADD	AX,[SI]
	ADD	AX,2
	MOV	CL,15
	CALL	GR_SET_V_LINE
	
	
	CALL	GR_MAUS_AN
	
	POP	DI
	RET
	
	
SET_COURSOR:
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	ADD	BX,2
	MOV	DX,13
	MOV	AL,[SI+21]
	MOV	CL,9
	MUL	CL
	ADD	AX,WINDOW_X
	ADD	AX,[SI]
	ADD	AX,2
	MOV	CL,15
	CALL	GR_SET_V_LINE
	MOV	AL,[SI+20]
	MOV	[SI+21],AL
	MOV	CL,9
	MUL	CL
	ADD	AX,WINDOW_X
	ADD	AX,[SI]
	ADD	AX,2
	MOV	CL,40
	CALL	GR_SET_V_LINE
	RET
	
;********** BITMAP BUTTON ***********

O15:
	PUSH	DI	
	MOV	AX,[SI]
	MOV	BX,[SI+2]
	ADD	AX,WINDOW_X
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	ADD	CX,4
	MOV	DX,[SI+6]
	ADD	DX,4
	PUSH	SI
	MOV	SI,06H
	CALL	GR_SET_BOX
	MOV	SI,0705H
	CALL	GR_SET1_REC
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	CALL	GR_SET1_REC
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	
	POP	SI
	MOV	SI,[SI+8]
	CALL	GR_RAM_TO_VRAM_TRANS

	POP	DI
	RET

OC15:
	PUSH	DI
	PUSH	SI
	MOV	AX,[SI]
	MOV	BX,[SI+2]
	ADD	AX,WINDOW_X
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	ADD	CX,4
	MOV	DX,[SI+6]
	ADD	DX,4
	MOV	SI,1D18H
	CALL	GR_MAUS_AUS
	CALL	GR_SET1_REC
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	CALL	GR_SET1_REC
	CALL	GR_MAUS_AN
OC15_10:
	MOV	AX,MAUS_TASTEN
	AND	AX,1
	JNZ	OC15_10
	
	POP	SI
	PUSH	SI
	MOV	AX,[SI]
	MOV	BX,[SI+2]
	ADD	AX,WINDOW_X
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	ADD	CX,4
	MOV	DX,[SI+6]
	ADD	DX,4
	MOV	SI,181DH
	CALL	GR_MAUS_AUS
	CALL	GR_SET1_REC
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	CALL	GR_SET1_REC
	CALL	GR_MAUS_AN
	
	POP	SI
	MOV	BX,[SI+10]
	CALL	BX
	POP	DI
	RET

;********** BITMAP BUTTON NO WAIT ***********

OC16:
	PUSH	DI
	PUSH	SI
	MOV	AX,[SI]
	MOV	BX,[SI+2]
	ADD	AX,WINDOW_X
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	ADD	CX,4
	MOV	DX,[SI+6]
	ADD	DX,4
	MOV	SI,1D18H
	CALL	GR_MAUS_AUS
	CALL	GR_SET1_REC
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	CALL	GR_SET1_REC
	CALL	GR_MAUS_AN
	POP	SI
	
	PUSH	SI
	MOV	BX,[SI+10]
OC16_10:
	PUSH	BX
	CALL	BX
	POP	BX
	MOV	AX,MAUS_TASTEN
	AND	AX,1
	JNZ	OC16_10
	
	POP	SI
	PUSH	SI
	MOV	AX,[SI]
	MOV	BX,[SI+2]
	ADD	AX,WINDOW_X
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	ADD	CX,4
	MOV	DX,[SI+6]
	ADD	DX,4
	MOV	SI,181DH
	CALL	GR_MAUS_AUS
	CALL	GR_SET1_REC
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	CALL	GR_SET1_REC
	CALL	GR_MAUS_AN
	POP	SI

	POP	DI
	RET
	
;********** LISTFELD WITH COLOR **********
	
O17:
	PUSH	DI
	MOV	AX,[SI]						
	ADD	AX,WINDOW_X
	MOV	BX,[SI+2]
	ADD	BX,WINDOW_Y
	MOV	CX,[SI+4]
	MOV	DX,[SI+6]
	PUSH	SI
	MOV	SI,18
	CALL	GR_SET0_REC
	POP	SI
	
	
	MOV	DL,BYTE PTR [SI+12]				; *** Oberste Zeile die Dargestellt werden soll ***
	ADD	DL,BYTE PTR [SI+9]				; *** Addiere Anzahl der Dargestellten Zeilen ***
	CMP	DL,BYTE PTR [SI+14]				; *** Vergleiche mit Anzahl der Zeilen im Arry
	JL	O17_30						; *** Wenn Kleiner dann kann ab da Dargestellt werden ***
					
	MOV	DL,BYTE PTR [SI+14]				; *** Wenn Grösser dann Arry Zeilen - Anzahl Darstellbarer Zeilen ***
	SUB	DL,BYTE PTR [SI+9]
	JNC	O17_40
	MOV	DL,0
	JMP	O17_40
O17_30:
	MOV	DL,BYTE PTR [SI+12]	
O17_40:
	ADD	AX,2						; *** Text Liste ausgeben vorbereiten ***
	MOV	CHAR_X,AX
	ADD	BX,2
	MOV	CHAR_Y,BX
	MOV	BX,AX						; *** In DX befindet sich immer die X Position des Textes ***
	MOV	CL,BYTE PTR [SI+10]
	MOV	CHAR_BACK_COLOR,CL
	MOV	CL,BYTE PTR [SI+11]
	MOV	CHAR_COLOR,CL
	
	MOV	DI,[SI+15]					; *** Zeiger auf List Arry holen ***
	MOV	FS,[SI+17]
	
	MOV	AL,BYTE PTR [SI+8]
	MUL	DL
	ADD	DI,AX	
	
	MOV	DX,BX
	MOV	CX,0
	MOV	BH,[SI+9]
O17_10:
	PUSH	BX
	MOV	BX,CX
	MOV	AH,[SI+21+BX]
	MOV	CHAR_COLOR,AH
	POP	BX
	MOV	AH,[SI+8]					; *** Anzahl der Zeichen in einer Zeile holen ***
O17_20:
	MOV	AL,FS:[DI]
	PUSH	DI CX BX DX SI
	CALL	GR_SET_CHAR
	POP	SI DX BX CX DI
	INC	DI
	ADD	CHAR_X,9
	DEC	AH
	JNZ	O17_20
	MOV	CHAR_X,DX
	ADD	CHAR_Y,16
	INC	CX
	DEC	BH
	JNZ	O17_10
	
	POP	DI
	RET
	
;**************************************************************************************************

;** Zeichnet alle Fenster neu **

INTU_REDRAW_ALL_WINDOW PROC
	
	CALL	GR_MAUS_AUS
	
	NOT	PS
	MOV	AL,PS
	CALL	GR_SET_PAGE
	
	MOV	AX,0
	MOV	BX,0
	MOV	CX,X
	MOV	DX,Y
	MOV	SI,0
	CALL	GR_SET_BOX
	
	MOV	AL,0
IRAW_10:	
	CMP	AL,WINDOW_ANZAHL
	JE	IRAW_ENDE
	MOVZX	SI,AL
	SHL	SI,1
	SHL	SI,1
	PUSH	AX
	CALL	IRW
	POP	AX
	INC	AL
	JMP	IRAW_10
	
IRAW_ENDE:
	NOT	PV
	MOV	AL,PV
	CALL	GR_VIEW_PAGE
	CALL	GR_MAUS_AN
	RET
ENDP
	
;**************************************************************************************************

;** Zeichnet ein Fenster auf dem Screen neu **
;** Eingabe: AL Fensternummer **

INTU_REDRAW_WINDOW PROC

	CALL	INTU_AL_TO_SI
	JC	IRW_ENDE
IRW:	
	MOV	DI,WORD PTR WINDOW_LIST[SI+2]
	
	MOV	F_RAHMEN,0
	MOV	F_HINTERGRUND,0
	MOV	F_TITELLEISTE,0
	
	MOV	AH,[DI+11]
	AND	AH,1
	JZ	IRW_01
	MOV	F_RAHMEN,1
IRW_01:
	MOV	AH,[DI+11]
	AND	AH,2
	JZ	IRW_02
	MOV	F_HINTERGRUND,1
IRW_02:
	MOV	AH,[DI+11]
	AND	AH,4
	JZ	IRW_03
	MOV	F_TITELLEISTE,1
IRW_03:
	MOV	TITEL_FARBE,3
	MOV	AX,SI
	MOV	CL,2
	SHR	AX,CL
	MOV	AH,WINDOW_ANZAHL
	DEC	AH
	CMP	AL,AH
	JNE	IRW_10
	MOV	TITEL_FARBE,2
IRW_10:
	MOV	AX,WORD PTR [DI+1]
	MOV	WINDOW_X,AX
	MOV	BX,WORD PTR [DI+3]
	MOV	WINDOW_Y,BX
	MOV	CX,WORD PTR [DI+5]
	MOV	WINDOW_BREITE,CX
	MOV	DX,WORD PTR [DI+7]
	MOV	WINDOW_HÖHE,DX
	
	PUSH	DI
	
	CMP	F_HINTERGRUND,0
	JE	IRW_20
	MOV	SI,1
	CALL	GR_SET_BOX
IRW_20:
	CMP	F_RAHMEN,0
	JE	IRW_30
	MOV	SI,0705H
	CALL	GR_SET1_REC
	INC	AX
	INC	BX
	SUB	CX,2
	SUB	DX,2
	MOV	SI,06H
	CALL	GR_SET0_REC
IRW_30:
	POP	DI

	CMP	F_TITELLEISTE,0
	JE	IRW_40
	
	PUSH	DI
	INC	AX
	INC	BX
	SUB	CX,2
	MOV	DX,19
	MOVZX	SI,TITEL_FARBE
	CALL	GR_SET_BOX
	
	PUSH	AX BX
	ADD	BX,17
	MOV	DX,CX
	MOV	CL,1AH
	CALL	GR_SET_H_LINE
	POP	BX AX
	
	ADD	AX,3
	INC	BX
	MOV	CHAR_X,AX
	MOV	CHAR_Y,BX
	
	POP	DI
	PUSH	DI
	MOV	SI,WORD PTR [DI+9]
	MOV	DI,SI
	MOV	CHAR_COLOR,15
	CALL	GR_TEXT_TRANS
	POP	DI
IRW_40:
	CALL	IOW_0
IRW_ENDE:
	RET
ENDP

;**************************************************************************************************

;** Verschiebt ein Fenster auf dem Screen neu **
;** Eingabe: AL Fensternummer BX-X CX-Y **

INTU_MOVE_WINDOW PROC
	PUSHA
	CALL	INTU_AL_TO_SI
	JC	IMW_ENDE
	MOV	DI,WORD PTR WINDOW_LIST[SI+2]
	
	PUSH	AX BX CX
	MOV	AX,WORD PTR [DI+1]
	MOV	BX,WORD PTR [DI+3]
	MOV	CX,WORD PTR [DI+5]
	MOV	DX,WORD PTR [DI+7]
	MOV	SI,0
	PUSH  	DI
	POP	DI
	POP	CX BX AX

	MOV	WORD PTR [DI+1],BX
	MOV	WORD PTR [DI+3],CX
	CALL	INTU_REDRAW_ALL_WINDOW
IMW_ENDE:
	POPA
	RET
ENDP
	
;**************************************************************************************************

;** Übergibt die Steuerung des Programms der Intuitions Routiene **
;** Diese kümmert sich ab jetzt um jeden Mausklick etc. **

INTU_START PROC

	CALL	INTU_REDRAW_ALL_WINDOW
IS_10:
	MOV	AH,INTU_STATUS
	AND	AH,1
	JNZ	IS_ENDE
	MOV	AX,MAUS_TASTEN					;** Testen ob linke Maustaste gedrückt wird **
	AND	AX,1
	JNZ	IS_20						;** Wenn ja dann bei IS_20 Weiter **		
	JMP	IS_10
IS_20:
	MOV	AX,MAUS_X
	MOV	BX,MAUS_Y
	CALL	INTU_DESKTOP_CLICK_CHECK			;** Wo fand der Klick statt **
	JC	IS_10						;** Irgendwo auf dem Desktop nur nicht in einem Fenster **
	
	CMP	AL,0
	JNE	IS_30						;** Ein Fenster was nicht ganz oben war ( bei IS_30 gehts Weiter )**

IS_25:								;** Oberstes Fenster wurde angeklickt **
	CALL	INTU_WINDOW_CLICK_CHECK
	JC	IS_10						;** Es wurde ein Window_Objekt angeklickt **					
	
	MOV	BX,WINDOW_Y					;** Kucken ob Mausklick in Titeleiste war ? **
	ADD	BX,20
	CMP	BX,MAUS_Y
	JG	IS_26
IS_26A:
	MOV	DI,MAUS_TASTEN					;** auf loslassen der Maustaste warten **
	AND	DI,1
	JNZ	IS_26A
		
	JMP	IS_10						;** Nein war nicht dann bei IS_10 weiter **
IS_26:	
	MOV	BX,MAUS_X					;** Ja ! Klick war in Titelleiste -Window verschieben- **
	MOV	CX,MAUS_Y
	MOV	WINDOW_X_OLD,BX					;** Positionierrahmen darstellen und solange mit Maus bewegen
	MOV	WINDOW_Y_OLD,CX					;   bis linke Maustaste losgelassen wurde **
	MOV	AL,AH
	CALL	INTU_AL_TO_SI
	PUSH	AX
	
	MOV	DI,WORD PTR WINDOW_LIST[SI+2]
	PUSH  	BX CX
	
	MOV	BX,[DI+5]
	MOV	CX,[DI+7]
	MOV	WINDOW_X_DIF_MAX,BX
	MOV	WINDOW_Y_DIF_MAX,CX
	
	POP	CX BX
	SUB	BX,[DI+1]
	SUB	CX,[DI+3]
	MOV	WINDOW_X_DIF_MIN,BX
	MOV	WINDOW_Y_DIF_MIN,CX	

	SUB	WINDOW_X_OLD,BX
	JNS	IS_25A
	MOV	WINDOW_X_OLD,0
IS_25A:
	SUB	WINDOW_Y_OLD,CX
	JNS	IS_25B
	MOV	WINDOW_Y_OLD,0
IS_25B:
	MOV	AX,[DI+5]
	MOV	BX,[DI+7]
	MOV	WINDOW_BREITE,AX
	MOV	WINDOW_HÖHE,BX
IS_27:
	MOV	AX,MAUS_X
	MOV	BX,MAUS_Y
	SUB	AX,WINDOW_X_DIF_MIN
	JNS	IS_27A1
	XOR	AX,AX
IS_27A1:
	ADD	AX,WINDOW_X_DIF_MAX
	CMP	AX,X
	JL	IS_27A2
	MOV	AX,X
	SUB	AX,WINDOW_X_DIF_MAX
	JMP	IS_27A
IS_27A2:
	SUB	AX,WINDOW_X_DIF_MAX
IS_27A:
	SUB	BX,WINDOW_Y_DIF_MIN
	JNS	IS_27B1
	XOR	BX,BX
IS_27B1:
	ADD	BX,WINDOW_Y_DIF_MAX
	CMP	BX,Y
	JL	IS_27B2
	MOV	BX,Y
	SUB	BX,WINDOW_Y_DIF_MAX
	JMP	IS_27B
IS_27B2:
	SUB	BX,WINDOW_Y_DIF_MAX
IS_27B:
	CMP	AX,WINDOW_X_OLD
	JNE	IS_28
	CMP	BX,WINDOW_Y_OLD
	JNE	IS_28
	JMP	IS_29
IS_28:
	PUSH	AX BX
	MOV	AX,WINDOW_X_OLD
	MOV	BX,WINDOW_Y_OLD
	MOV	CX,WINDOW_BREITE
	MOV	DX,WINDOW_HÖHE
	PUSH	CX DX
	CALL	GR_MAUS_AUS
	CALL	GR_INV_REC
	CALL	GR_MAUS_AN
	POP	DX CX
	POP	BX AX
	MOV	WINDOW_X_OLD,AX
	MOV	WINDOW_Y_OLD,BX

	CALL	GR_MAUS_AUS
	CALL	GR_INV_REC
	CALL	GR_MAUS_AN
IS_29:
	MOV	SI,MAUS_TASTEN
	AND	SI,1
	JNZ	IS_27
	MOV	CX,BX						;** linke Maustaste wurde losgelassen **
	MOV	BX,AX
	POP	AX
	CALL	INTU_MOVE_WINDOW				;** Window verschieben **
	JMP	IS_10
IS_30:
	MOV	AL,INTU_STATUS
	AND	AL,2
	JNZ	IS_10

	MOV	AL,AH						;** Fenster an oberste stelle bringen **
	CALL	INTU_WINDOW_NACH_OBEN
	MOV	AL,AH
	CALL	INTU_REDRAW_ALL_WINDOW
IS_40:
	MOV	BX,MAUS_TASTEN					;** Watern bist linke Maustaste losgelassen wurde **
	AND	BX,1
	JMP	IS_10
IS_ENDE:
	RET
ENDP
;**************************************************************************************************

;** Verschiebt in der Window_List das Fenster [AL] an oberster stelle **
;** Eingabe: AL- Fensternummer

INTU_WINDOW_NACH_OBEN PROC
	
	PUSHA
	CALL	INTU_AL_TO_SI
	JC	IWNO_ENDE
	MOV	AX,WORD PTR WINDOW_LIST[SI]
	MOV	BX,WORD PTR WINDOW_LIST[SI+2]
	MOV	WINDOW_LIST_TMP[0],AX
	MOV	WINDOW_LIST_TMP[2],BX
	
	MOV	BX,SI
	SHR	BX,1
	SHR	BX,1
IWNO_10:
	MOV	AX,WORD PTR WINDOW_LIST[SI+4]
	MOV	WORD PTR WINDOW_LIST[SI],AX
	MOV	AX,WORD PTR WINDOW_LIST[SI+6]
	MOV	WORD PTR WINDOW_LIST[SI+2],AX
	ADD	SI,4
	INC	BL
	CMP	BL,WINDOW_ANZAHL
	JNE	IWNO_10
	
	SUB	SI,4
	MOV	AX,WINDOW_LIST_TMP[0]
	MOV	BX,WINDOW_LIST_TMP[2]
	MOV	WORD PTR WINDOW_LIST[SI],AX
	MOV	WORD PTR WINDOW_LIST[SI+2],BX
IWNO_ENDE:
	POPA
	RET
	
ENDP

;**************************************************************************************************

;** Prüft den Desktop nach einen Klick **
;** Eingabe AX-X_MAUS BX-Y_MAUS **
;** Ausgabe: gestztes Carry bedeutet ein Klick auf einen Leeren bereich im Desktop **
;**	     gelöschtes Carry bedeutet ein Klick in ein Fenster, wenn AL-0 dann oberstest Fenster
;**								 wenn AL-1 dann ein anderes Fenster
;**								      AH- immer Nummer des Fensters	
								 
INTU_DESKTOP_CLICK_CHECK PROC
	MOVZX	SI,WINDOW_ANZAHL
IC_10:
	CMP	SI,0
	JE	IC_20
	DEC	SI
	PUSH	SI
	SHL	SI,1
	SHL	SI,1
	MOV	DI,WORD PTR WINDOW_LIST[SI+2]
	MOV	DL,WINDOW_LIST[SI]
	POP	SI
	CMP	AX,[DI+1]
	JL	IC_10
	MOV	CX,[DI+1]
	ADD	CX,[DI+5]
	CMP	AX,CX
	JG	IC_10
	CMP	BX,[DI+3]
	JL	IC_10
	MOV	CX,[DI+3]
	ADD	CX,[DI+7]
	CMP	BX,CX
	JG	IC_10
	INC	SI
	MOV	BX,SI
	CMP	BL,WINDOW_ANZAHL
	JE	IC_25
	MOV	AH,DL
	MOV	AL,1
	CLC
	RET
IC_25:
	MOV	AH,DL
	MOV	AL,0
	CLC
	RET
IC_20:
	STC
	RET
ENDP

;**************************************************************************************************

INTU_WINDOW_CLICK_CHECK PROC
	PUSH	AX
	MOV	AL,AH
	CALL	INTU_AL_TO_SI
	MOV	DI,WORD PTR WINDOW_LIST[SI+2]
	MOV	CX,[DI+1]
	MOV	DX,[DI+3]
	MOV	WINDOW_X,CX
	MOV	WINDOW_Y,DX
IWCC_10:	
	MOVZX	SI,BYTE PTR [DI+12]
	CMP	SI,0
	JE	IWCC_ENDE
	SHL	SI,1
	MOV	BX,OBJEKT_CLICK_TBL[SI]
	MOV	SI,[DI+13]
	
	MOV	CX,MAUS_X
	MOV	DX,MAUS_Y
	MOV	AX,[SI]
	ADD	AX,WINDOW_X
	CMP	CX,AX
	JL	IWCC_20
	MOV	AX,[SI+2]
	ADD	AX,WINDOW_Y
	CMP	DX,AX
	JL	IWCC_20
	MOV	AX,[SI]
	ADD	AX,[SI+4]
	ADD	AX,WINDOW_X
	CMP	CX,AX
	JG	IWCC_20
	MOV	AX,[SI+2]
	ADD	AX,[SI+6]
	ADD	AX,WINDOW_Y
	CMP	DX,AX
	JG	IWCC_20
	CALL    BX
	STC
	POP	AX
	RET
IWCC_20:
	ADD	DI,3
	JMP	IWCC_10
IWCC_ENDE:
	POP	AX
	RET
ENDP

;**************************************************************************************************

;** Sucht in der Window_Liste nach dem Fenster mit der Nummer in AL und gibt den Offsett in SI wieder
;** Eingabe: AL-Fensternummer 
;** Ausgabe: SI-Offset in Window_List

INTU_AL_TO_SI PROC
	PUSH	AX
	MOVZX	SI,WINDOW_ANZAHL
	SHL	SI,1
	SHL	SI,1
IATS_10:
	SUB	SI,4
	JS	IATS_ENDE
	CMP	AL,WINDOW_LIST[SI]
	JE	IATS_20
	JMP	IATS_10
IATS_20:
	CLC
	POP	AX
	RET
IATS_ENDE:
	STC
	POP	AX
	RET
ENDP

;**************************************************************************************************

;** Rechnet eine 16 Bit Zahl um und hängt eine 0 am Ende an **
;** DI-Zeiger auf Asscii Puffer AX-16 Bit Wert **

INTU_16BIT_ASCII PROC
	PUSHA
	OR	AX,AX
	JNS	O_10
	MOV	[DI],BYTE PTR "-"
	INC	DI
	NEG	AX
O_10:
	MOV	BX,10
	XOR	CX,CX
O_20:
	XOR	DX,DX
	DIV	BX
	ADD	DL,30H
	PUSH	DX
	INC	CX
	OR	AX,AX
	JNE	O_20
O_30:
	POP	DX
	MOV	[DI],DL
	INC	DI
	LOOP	O_30
	POPA
	RET
ENDP

;***************** Unterfunktionen File Request ******************

D64_LIST_SCROLLEN:
	MOV	AX,[SI+8]
	MOV	BYTE PTR F255_02[12],AL
	LEA	DI,FENSTER_255
	MOV	AL,2
	CALL	INTU_REDRAW_OBJEKT
	RET

D64_AUSWAHL:
	MOV	AL,BYTE PTR F255_02[12]
	ADD	AL,BYTE PTR F255_02[13]
	MOV	CL,12+6
	MUL	CL
	MOV	DI,AX
	MOV	FS,FILE_PUFFER
	
	CMP	BYTE PTR FS:[DI+17],"]"
	JE	LA_30

	MOV	BX,F255_04[18]
LA_10:
	MOV	AL,FS:[DI]
	CMP	AL,0
	JE	LA_20
	MOV	[BX],AL
	INC	DI
	INC	BX
	JMP	LA_10
LA_20:
	MOV	F255_04[14],BX
	MOV	AL,4
	LEA	DI,FENSTER_255
	CALL	INTU_REDRAW_OBJEKT
	RET
LA_30:									;*** Verzeichnis wechseln ***
	PUSH	DS
	MOV	DS,FILE_PUFFER
	MOV     DX,DI
	MOV	AH,03BH
	INT	21H
	POP	DS
	CALL	DTA_TO_DIR
	MOV	F255_03[8],0
	MOV	F255_02[12],0
	CALL	GR_MAUS_AUS
	LEA	DI,FENSTER_255
	MOV	AL,2
	CALL	INTU_REDRAW_OBJEKT
	LEA	DI,FENSTER_255
	MOV	AL,3
	CALL	INTU_REDRAW_OBJEKT
	CALL	GR_MAUS_AN
	RET

OK:
	MOV	AL,255
	CALL	INTU_CLOSE_WINDOW
	RET

ABBRUCH:
	MOV	AL,255
	CALL	INTU_CLOSE_WINDOW
	RET

DTA_TO_DIR:
	MOV	FS,FILE_PUFFER
	PUSH	ES						; *** Aktuellen DTA Bereich ermitteln und Sichern ***
	MOV	AH,02FH
	INT	21H
	MOV	OLD_DTA_SEG,ES
	MOV	OLD_DTA_OFF,BX
	POP	ES
	
	MOV	AH,01AH						; *** DTA auf Datenbereich setzen ***
	LEA	DX,DTA
	INT	21H

	MOV	AH,04EH						; *** Nach ersten Directory Eintrag suchen ***
	XOR	CH,CH
	MOV	CL,0FFH						
	LEA	DX,SUCHMASKE
	INT	21H

	MOV	SI,30000
DTD_5:								; *** Alle File suchen und nach File Puffer kopieren ***
	DEC	SI
	MOV	BYTE PTR FS:[SI],0
	CMP	SI,0
	JNE	DTD_5
DTD_10:	
	MOV	AH,DTA[15H]
	AND	AH,00010000B
	JZ	DTD_15

	PUSH	SI
	MOV	WORD PTR FS:[SI+12],"[ "
	MOV	WORD PTR FS:[SI+14],"ID"
	MOV	WORD PTR FS:[SI+16],"]R"
	
	
	MOV	DI,30
DTD_13:
	MOV	AL,DTA[DI]
	CMP	AL,0
	JE	DTD_14
	MOV	FS:[SI],AL
	INC	DI
	INC	SI
	JMP	DTD_13
DTD_14:
	POP	SI
	JMP	DTD_35
DTD_15:
	PUSH	SI
	MOV	DI,30
DTD_20:
	MOV	AL,DTA[DI]
	CMP	AL,0
	JE	DTD_30
	MOV	FS:[SI],AL
	INC	DI
	INC	SI
	JMP	DTD_20
DTD_30:
	POP	SI
DTD_35:
	ADD	SI,12+6
	
	MOV	AH,04FH
	INT	21H
	JNC	DTD_10
	
	MOV	AX,SI
	MOV	CL,12+6
	DIV	CL
	MOV	BYTE PTR F255_02[14],AL				; *** Anzahl der Files in FILE_LIST Objekt eintragen ***
	
	MOV 	BX,13
	XOR	AH,AH
	SUB     AX,BX
	JNS	DTD_40
	XOR	AX,AX
DTD_40:
	MOV	BX,211
	SUB	BX,AX
	MOV	F255_03[10],BX
	RET
	

;****************************************
END