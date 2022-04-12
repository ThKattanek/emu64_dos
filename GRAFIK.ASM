;****************************************
;*					*
;* Titel: * Grafik Bibliotek für 256 F	*
;* Autor: * Thorsten Kattanek		*
;* Datum: * 24.05.1999			*
;* Ort  : * Berlin			*
;* Vers : * 1.00			*
;* Info : * Grundlage für GUI		*
;*					*
;*					*
;****************************************

PUBLIC	GR_READ_MODUS,GR_SET_MODUS,GR_SET_POINT,GR_INV_POINT,GR_READ_POINT,GR_SET_H_LINE,GR_SET_PAGE,GR_VIEW_PAGE
PUBLIC	GR_INV_H_LINE,GR_SET_V_LINE,GR_INV_H_LINE,GR_INV_REC,GR_SET0_REC,GR_SET1_REC,GR_SET_BOX
PUBLIC	GR_INV_BOX,GR_INIT_MAUS,GR_SET_CHAR,GR_SET_CHAR_TRANS,GR_SET_CHAR_FONT,GR_TEXT,GR_MAUS_AN,GR_MAUS_AUS
PUBLIC	X,Y,MAUS_X,MAUS_Y,MAUS_TASTEN,CHAR_X,CHAR_Y,CHAR_COLOR,CHAR_BACK_COLOR,FARBE,ROT,GRÜN,BLAU,GR_SET_RGB
PUBLIC	GR_TEXT_TRANS,GR_READ_RGB,GR_RAM_TO_VRAM,GR_RAM_TO_VRAM_TRANS,GR_LINE


.MODEL SMALL

;****************************************
.DATA

R_FENSTER	DD	?
V_RAM		DW	?
TMP_0		DW	?
TMP_1		DW	?
TMP_2		DW	?
TMP_2_OLD	DW	?
TMP_3		DW	?
X		DW	?		
X1_LO		DW	?
X1_HI		DW	?
Y		DW	?
X1		DW	?
Y1		DW	?
GRANULAT_1	DB	?	; Granulat durch 64 = ergibt den Factor für ein ganzes 64 KB Fenster
PAGE_OFFSETT_LO	DW	?	; 00000000 Für Page A und (Auflösug X * Auflösung Y) für Page B
PAGE_OFFSETT_HI DW 	?

Z_ADRESSEN	DD	1200 DUP (?)

PUFFER_1	DB	512 DUP(?)
PUFFER_2	DB	512  DUP(?)

X_TMP		DW	0	; Aktueller Modus X Breite -1
Y_TMP		DW	0	; Aktueller Modus Y Breite -1

MAUS_X		DW	0
MAUS_Y		DW	0
MAUS_TASTEN	DW	0
MAUS_X_OLD	DW	0
MAUS_Y_OLD	DW	0
POINTER_BREITE	DW	0
POINTER_HÖHE	DW	0
POINTER_OFFSETT	DW	0
POINTER_PUFFER	DW	0
CHAR_ROM	DB	8192 DUP (?)
CHAR_X		DW	0
CHAR_X_TMP	DW	0
CHAR_Y		DW	0
CHAR_COLOR	DB	1
CHAR_BACK_COLOR DB 	15

FARBE		DB	0
ROT		DB	0
GRÜN		DB	0
BLAU		DB	0

LX1		DW 	?
LY1		DW	?
LX2		DW	?
LY2		DW	?
LFARBE		DW	?
LS1		DW	?
LS2		DW	?
LS3		DW	?
LS4		DW	?

;****************************************
.486
.CODE

AKTIV		DB	0
AKTIV1		DB	0

;**************************************************************************************************

;* Fragt über Vesa die zu Verfügung stehenden 256 Farben Videomodi ab
;* Eingabe: DS:DI Puffer über 256 Byte
;* Ausgabe: AX Anzahl der gefundenen Video Modi
;* Pufferinhalt: [0] Modusnummer [2] X-Auflösung [4] Y-Auflösung
;* Fehler: Carry=1 AH=0 Kein Vesa AH=1 kein 256 Grafikmodus

GR_READ_MODUS PROC
	MOV	TMP_0,DI			; *** Vesa Infos abrufen ***
	MOV	AX,4F00H
	PUSH	DS
	POP	ES
	LEA	DI,PUFFER_1
	INT	10H
	CMP	DWORD PTR PUFFER_1,"ASEV"	; *** ( auf VESA prüfen )
	JE	GRM_10				; *** keine Vesa Karte Instaliert ***
	MOV	AH,0				; *** AH=0 ERROR " Keine VESA Karte gefunden ***
	STC					; *** Errorkennung durch gestztem Carry ***
	RET
GRM_10:
	MOV	SI,WORD PTR PUFFER_1[0EH]	; *** Zeiger ermitteln auf verfügbare V-Modi ***
	MOV	ES,WORD PTR PUFFER_1[10H]
GRM_20:
	MOV	CX,ES:[SI]			; *** Alle 256 Grafikmodi ausfiltern und in überg. Puffer schreiben ***
	CMP	CX,0FFFFH
	JE	GRM_30
	PUSH	SI ES
	CALL	ABFRAGE
	POP	ES SI
	INC	SI
	INC	SI
	JMP	GRM_20
GRM_30:
	MOV	AX,TMP_1
	CMP	AX,0
	JNE	GRM_40
	MOV	AH,1				; *** AH=1 ERROR " Kein 256 Grafikmodus gefunden ***
	STC
	RET
GRM_40:
	CLC					
	RET
ABFRAGE:
	MOV	AX,4F01H			; *** Unterfunktion zum detailierten auswerten eines Video Modi ***
	PUSH	DS
	POP	ES
	LEA	DI,PUFFER_2
	INT	10H
	AND	WORD PTR PUFFER_2,16
	JZ	ABFRAGE_10
	
	CMP	PUFFER_2[19H],8			; *** Ist Dieser Modus ein 8 Bit Farbmodus ? ***
	JNE	ABFRAGE_10
	
	MOV	DI,TMP_0
	MOV	WORD PTR [DI],CX		; *** Modusnummer eintragen ***
	ADD	DI,2
	INC	TMP_1
	MOV	AX,WORD PTR PUFFER_2[12H]
	MOV	WORD PTR [DI],AX		; *** X-Auflösung eintragen ***
	ADD	DI,2
	MOV	AX,WORD PTR PUFFER_2[14H]
	MOV	WORD PTR [DI],AX		; *** Y-Auflösung eintragen ***
	ADD	DI,2
	MOV	TMP_0,DI
ABFRAGE_10:
	RET
ENDP

;**************************************************************************************************

;* Stellt einen Videomodus über Vesa ein
;* Eingabe: AX Videomodus
;* Ausgabe: Carry 1 Einschalten missglückt

GR_SET_MODUS PROC

;*********** Zeichensatz Rom auslesen und in Datensegment speichern ***********
	PUSH	AX AX
	
	MOV	AH,0				
	MOV	AL,01H
	INT	10H
	
	MOV	DX,0A000H
	MOV	ES,DX
	MOV	DX,03C4H			; *** Sequenzer Controller Verändern ***
	MOV	AL,02H				; *** Map Mask ***
	OUT	DX,AL
	INC	DX
	MOV	AL,04H				; *** Bit Map #2 ausmaskieren ***
	OUT	DX,AL
	
	DEC	DX
	MOV	AL,04H				; *** Memory Mode ***
	OUT	DX,AL
	INC	DX
	MOV	AL,07H				; *** Wert ist 7 ***
	OUT	DX,AL
		
	MOV	DX,03CEH			; *** Graphics Controller Verändern ***
	MOV	AL,04H				; *** Read Map Select ***
	OUT	DX,AL
	INC	DX
	MOV	AL,02H				; *** Bitmap #2 informationen an die CPU ***
	OUT	DX,AL
	DEC	DX
	MOV	AL,05H				; *** Graphics Mode ***
	OUT	DX,AL
	INC	DX
	MOV	AL,0				; *** Grafikmodus festlegen ***
	OUT	DX,AL
	DEC	DX
	MOV	AL,06H				; *** Miscellaneous ***
	OUT	DX,AL			
	INC	DX
	MOV	AL,04H				; *** Lage des V-Rams auf 64 KB bei A000 festlegen ***
	OUT	DX,AL

	MOV	SI,0
	MOV	DI,0
CRC:
	MOV	AH,ES:[DI]
	MOV	CHAR_ROM[SI],AH			; *** Hier werden die Zeichensatzdaten ausgelesen und in Arry Char_Rom gespeichert ***
	INC	DI
	INC	SI
	CMP	SI,1024*8			
	JNE	CRC
	
	
;******************************************************************************
	MOV	AX,0				; *** Mausreset hervorrufen damit alter Eventhandler eingetragen wird ***
	INT	33H				; *** Ansonsten können merkwürdige sachen Passieren ***
	MOV	MAUS_TASTEN,0
	
	POP	AX				; *** Neuen Video Modus über Vesa Funktion einstellen ***
	MOV	BX,AX
	MOV	AX,4F02H
	INT	10H
	CMP	AL,04FH
	JE	GSM_10	
	STC					; *** wenn es nicht geklappt hat wird das Carry gesetzt ***
	RET
GSM_10:
	POP	CX				; *** Details über geforderten V-Modus abfragen ***
	MOV	AX,4F01H
	PUSH	DS
	POP	ES
	LEA	DI,PUFFER_2
	INT	10H
	
	MOV	AX,WORD PTR PUFFER_2[12H]	; *** X Auflösung für Grafikroutienen eintragen ***
	MOV	X,AX
	
	MOV	AX,WORD PTR PUFFER_2[12H]	; *** X Auflösung für Grafikroutienen eintragen ***
	MOV	X1,AX
	
	MOV	AX,WORD PTR PUFFER_2[14H]	; *** Y Auflösung für Grafikroutienen eintragen ***
	INC	AX
	MOV	Y,AX
	
	MOV	AX,WORD PTR PUFFER_2[14H]	; *** Y Auflösung für Grafikroutienen eintragen ***
	MOV	Y1,AX
	
	MOV	EAX,DWORD PTR PUFFER_2[0CH]	; *** FAR_ZEIGER für Zugriffsfenster eintragen ***
	MOV	R_FENSTER,EAX
	
	MOV	AX,WORD PTR PUFFER_2[04H]	; *** Granularität für Grafikroutienen eintragen ***
	MOV	CL,10				; *** mal 1024 ***
	SHL	AX,CL
	MOV	BX,WORD PTR PUFFER_2[04H]	; *** durch 64 ***
	MOV	AX,64
	XOR	DX,DX
	DIV	BX
	MOV	GRANULAT_1,AL
	
	MOV	AX,WORD PTR PUFFER_2[08H]	; *** Segment Adresse für V RAM eintragen ***
	MOV	ES,AX
	MOV	V_RAM,AX
	
	MOV	TMP_2,0H			; *** Vergleichs Variable ob Anderes Zugriffsfenster
						;	Zurücksetzen ***
	XOR	BX,BX
	MOV	DX,0
	CALL	[R_FENSTER]	
	
	MOV	DI,0				; *** Tabelle erzeugen wo alle Anfangsadressen jeder Zeile
	MOV	AX,0				;     enthalten sind (schnelleres ermitteln als Multiplizieren
	MOV	BX,Y				;     für jeden PUNKT) ***
	SHL	BX,1
	SHL	BX,1
	MOVZX	EAX,X
	MOV	DWORD PTR X1_LO,EAX
	XOR	EAX,EAX
GSM_20:
	MOV	Z_ADRESSEN[DI],EAX
	ADD	EAX,DWORD PTR X1_LO
	ADD	DI,4
	CMP	DI,BX
	JNE	GSM_20
	
	MOV	TMP_2,0
	XOR	AX,AX
	XOR	BX,BX
	MOV	DX,0
	CALL	[R_FENSTER]	
	
	DEC	X1
	DEC	Y1
	
	;*************** Alles für das Double Buffering ***************
	
	MOV	AH,4FH
	MOV	AL,7
	MOV	BX,0
	MOV	CX,0
	MOV	DX,0
	INT	10H
	
	MOV	DWORD PTR PAGE_OFFSETT_LO,0
	
	;**************************************************************
	
	CLC
	RET
ENDP

;**************************************************************************************************

;* Deffiniert die Page A oder B als Zeichenfenster, auf ihr werden dann alle Grafikfunktionen *
;* ausgeführt.Wenn die andere Page sichtbar ist sieht mann nicht den Aufbau *
;* Eingabe: AL=0 oder >=1 0=PAGE A >=1=PAGE B

GR_SET_PAGE PROC

	CMP	AL,0
	JNE	GSP_10
	MOV	DWORD PTR PAGE_OFFSETT_LO,0
	JMP	GSP_40
GSP_10:
	MOV	AX,X
	MUL	Y
	MOV	PAGE_OFFSETT_HI,DX
	MOV	PAGE_OFFSETT_LO,AX
GSP_40:
	RET
ENDP

;**************************************************************************************************

;* Page A oder B wird auf dem Bildschirm dargestellt *
;* Eingabe: AL=0 oder >=1 0=PAGE A >=1=PAGE B

GR_VIEW_PAGE PROC

	CMP	AL,0
	JNE	GVP_10
	MOV	DX,03DAH
FP1_10:					; *** Auf Rasterstrahl warten ***
	IN	AL,DX
	TEST	AL,8
	;JNE	FP1_10
FP1_20:
	IN	AL,DX
	TEST	AL,8
	;JE	FP1_20
	
	MOV	AH,4FH
	MOV	AL,7
	MOV	BX,0
	MOV	CX,0
	MOV	DX,0
	INT	10H
	JMP	GVP_20
GVP_10:
	MOV	DX,03DAH
FP2_10:					; *** Auf Rasterstrahl warten ***
	IN	AL,DX
	TEST	AL,8
	JNE	FP2_10
FP2_20:
	IN	AL,DX
	TEST	AL,8
	JE	FP2_20
	MOV	AH,4FH
	MOV	AL,7
	MOV	BX,0
	MOV	CX,0
	MOV	DX,Y
	INT	10H
GVP_20:
	RET
ENDP

;**************************************************************************************************

;* Setzt einen Grafikpunkt
;* Eingabe: AX=X BX=Y CL=Farbe

GR_SET_POINT PROC
	PUSHA
	CMP	AX,X				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GSP_30
	CMP	BX,Y
	JG	GSP_30
	PUSH	CX
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	
	CMP	TMP_2,DX
	JE	GSP_20
	MOV	TMP_2,DX
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GSP_20:
	POP	CX
	MOV	ES:[DI],CL			; *** Pixel setzen ***
GSP_30:
	POPA	
	RET
ENDP

;**************************************************************************************************

;* Invertiert einen Grafikpunkt
;* Eingabe: AX=X BX=Y

GR_INV_POINT PROC
	PUSHA
	CMP	AX,X				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GIP_30
	CMP	BX,Y
	JG	GIP_30
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	
	CMP	TMP_2,DX
	JE	GIP_20
	MOV	TMP_2,DX
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GIP_20:
	MOV	CL,ES:[DI]			; *** Pixel lesen ***
	NOT	CL				; *** Pixel invertieren ***
	MOV	ES:[DI],CL			; *** Pixel setzen ***
GIP_30:
	POPA
	RET
ENDP

;**************************************************************************************************

;* liest einen Grafikpunkt
;* Eingabe: AX=X BX=Y
;* Ausgabe: CL=Farbnummer

GR_READ_POINT PROC
	CMP	AX,X				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GRP_30
	CMP	BX,Y
	JG	GRP_30
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	
	CMP	TMP_2,DX
	JE	GRP_20
	MOV	TMP_2,DX
	PUSH	DI BX DX
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DX BX DI

	INC	BL
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GRP_20:
	MOV	CL,ES:[DI]			; *** Pixel lesen ***
GRP_30:
	RET
ENDP
;**************************************************************************************************

;** Zeichnet eine Horizontale Linie **
;** Eingabe: AX=X BX=Y DX=Länge (immer nach Rechts) CL=FARBE

GR_SET_H_LINE PROC
	PUSH	AX BX CX DX
	MOV	X_TMP,AX
	CMP	AX,X1				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GSHL_30
	CMP	BX,Y1
	JG	GSHL_30
	PUSH	AX CX DX
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	
	CMP	TMP_2,DX
	JE	GSHL_20
	MOV	TMP_2,DX
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GSHL_20:
	POP	DX CX AX
GSHL_25:
	MOV	ES:[DI],CL			; *** Pixel setzen ***
	ADD	DI,1
	JNC	GSHL_27
	
	PUSH	DX
	MOVZX	BX,GRANULAT_1
	ADD	TMP_2,BX
	MOV	DX,TMP_2
	XOR	BX,BX
	PUSH	AX CX DI
	CALL	[R_FENSTER]
	POP	DI CX AX
	POP	DX
GSHL_27:
	INC	AX
	CMP	AX,X
	JE	GSHL_30
	DEC	DX
	JNZ	GSHL_25
GSHL_30:
	POP	DX CX BX AX
	RET
ENDP	

;**************************************************************************************************

;** Invertiert eine Horizontale Linie **
;** Eingabe: AX=X BX=Y DX=Länge (immer nach Rechts)

GR_INV_H_LINE PROC
	PUSH	AX BX DX
	MOV	X_TMP,AX
	CMP	AX,X1				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GIHL_30
	CMP	BX,Y1
	JG	GIHL_30
	PUSH	AX DX
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	
	CMP	TMP_2,DX
	JE	GIHL_20
	MOV	TMP_2,DX
	PUSH	DI BX DX
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DX BX DI

	INC	BL
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GIHL_20:
	POP	DX AX
GIHL_25:
	MOV	CL,ES:[DI]
	NOT	CL
	MOV	ES:[DI],CL			; *** Pixel setzen ***
	ADD	DI,1
	JNC	GIHL_27
	
	PUSH	DX
	MOVZX	BX,GRANULAT_1
	ADD	TMP_2,BX
	PUSH	DI BX DX
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DX BX DI

	INC	BL
	PUSH	AX CX DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI CX AX
	POP	DX
GIHL_27:
	INC	AX
	CMP	AX,X
	JE	GIHL_30
	DEC	DX
	JNZ	GIHL_25
GIHL_30:
	POP	DX BX AX
	RET
ENDP
	
;**************************************************************************************************

;** Zeichnet eine Vertikale Linie **
;** Eingabe: AX=X BX=Y DX=Länge (immer nach Unten) CL=FARBE

GR_SET_V_LINE PROC
	PUSH	AX BX CX DX
	MOV	X_TMP,AX
	CMP	AX,X1				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GSVL_30
	CMP	BX,Y1
	JG	GSVL_30
	PUSH	BX CX DX
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	
	CMP	TMP_2,DX
	JE	GSVL_20
	MOV	TMP_2,DX
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GSVL_20:
	POP	DX CX BX
GSVL_25:
	MOV	ES:[DI],CL			; *** Pixel setzen ***
	ADD	DI,X
	JNC	GSVL_27
	PUSH	BX CX DX
	MOVZX	BX,GRANULAT_1
	ADD	TMP_2,BX
	MOV	DX,TMP_2
	XOR	BX,BX
	CALL	[R_FENSTER]
	POP	DX CX BX
GSVL_27:
	INC	BX
	CMP	BX,Y
	JE	GSVL_30
	DEC	DX
	JNZ	GSVL_25
GSVL_30:
	POP	DX CX BX AX
	RET
ENDP
	
;**************************************************************************************************

;** Invertiert eine Vertikale Linie **
;** Eingabe: AX=X BX=Y DX=Länge (immer nach Unten)

GR_INV_V_LINE PROC
	PUSH	AX BX DX
	MOV	X_TMP,AX
	CMP	AX,X1				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GSIL_30
	CMP	BX,Y1
	JG	GSIL_30
	PUSH	BX DX
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	
	CMP	TMP_2,DX
	JE	GSIL_20
	MOV	TMP_2,DX
	PUSH	DI BX DX
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DX BX DI

	INC	BL
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GSIL_20:
	POP	DX BX
GSIL_25:
	MOV	CL,ES:[DI]			; *** Pixel invertieren ***
	NOT	CL
	MOV	ES:[DI],CL
	ADD	DI,X
	JNC	GSIL_27
	PUSH	BX CX DX
	MOVZX	BX,GRANULAT_1
	ADD	TMP_2,BX
	MOV	DX,TMP_2
	XOR	BX,BX
	PUSH	DI BX DX
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DX BX DI

	INC	BL
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
	POP	DX CX BX
GSIL_27:
	INC	BX
	CMP	BX,Y
	JE	GSIL_30
	DEC	DX
	JNZ	GSIL_25
GSIL_30:
	POP	DX BX AX
	RET
ENDP
	
;**************************************************************************************************

;** Invertiert ein Rechteck **
;** Eingabe: AX=X BX=Y CX=Länge DX=Höhe **

GR_INV_REC PROC

	PUSH	CX DX
	MOV	DX,CX
	CALL	GR_INV_H_LINE
	POP	CX
	PUSH	BX CX
	ADD	BX,CX
	DEC	BX
	DEC	BX
	CALL	GR_INV_H_LINE
	POP	CX BX
	INC	BX
	MOV	DX,CX
	SUB	DX,3
	CALL	GR_INV_V_LINE
	POP	CX
	ADD	AX,CX
	DEC	AX
	CALL	GR_INV_V_LINE
	RET

ENDP 

;**************************************************************************************************

;** Zeichnet ein Rechteck **
;** Eingabe: AX=X BX=Y CX=Länge DX=Höhe SI Farbe **

GR_SET0_REC PROC
	
	PUSH	AX BX CX DX
	PUSH	CX DX
	MOV	DX,CX
	MOV	CX,SI
	CALL	GR_SET_H_LINE
	POP	CX
	PUSH	BX CX
	ADD	BX,CX
	DEC	BX
	DEC	BX
	MOV	CX,SI
	CALL	GR_SET_H_LINE
	POP	CX BX
	INC	BX
	MOV	DX,CX
	SUB	DX,3
	MOV	CX,SI
	CALL	GR_SET_V_LINE
	POP	CX
	ADD	AX,CX
	DEC	AX
	MOV	CX,SI
	DEC	BX
	INC	DX
	INC	DX
	CALL	GR_SET_V_LINE
	POP	DX CX BX AX
	RET
	
ENDP
	
;**************************************************************************************************

;** Zeichnet ein Rechteck **
;** Eingabe: AX=X BX=Y CX=Länge DX=Höhe SI Farbe **

GR_SET1_REC PROC
	
	PUSH	AX BX CX DX SI
	PUSH	CX DX
	MOV	DX,CX
	MOV	CX,SI
	CALL	GR_SET_H_LINE
	POP	CX
	PUSH	BX CX
	ADD	BX,CX
	DEC	BX
	DEC	BX
	MOV	CL,8
	ROR	SI,CL
	MOV	CX,SI
	CALL	GR_SET_H_LINE
	MOV	CL,8
	ROR	SI,CL
	POP	CX BX
	INC	BX
	MOV	DX,CX
	SUB	DX,3
	MOV	CX,SI
	CALL	GR_SET_V_LINE
	POP	CX
	ADD	AX,CX
	DEC	AX
	MOV	CL,8
	ROR	SI,CL
	MOV	CX,SI
	DEC	BX
	INC	DX
	INC	DX
	CALL	GR_SET_V_LINE
	MOV	CL,8
	ROR	SI,CL
	POP	SI DX CX BX AX 
	RET

ENDP

;**************************************************************************************************

;** Zeichnet ein ausgefülltes Rechteck **
;** Eingabe: AX=X BX=Y CX=Länge DX=Höhe SI Farbe **

GR_SET_BOX PROC

	PUSH	AX BX CX DX SI
	XCHG	CX,DX
	XCHG	CX,SI
	DEC	SI
GSB_10:
	PUSH	SI
	CALL	GR_SET_H_LINE
	INC	BX
	POP	SI
	DEC	SI
	JNZ	GSB_10
	
	POP	SI DX CX BX AX
	RET
	
ENDP
	
;**************************************************************************************************

;** Invertiert ein ausgefülltes Rechteck **
;** Eingabe: AX=X BX=Y CX=Länge DX=Höhe **

GR_INV_BOX PROC

	PUSH	AX BX CX DX
	XCHG	CX,DX
	XCHG	CX,SI
	DEC	SI
GIB_10:
	PUSH	SI
	CALL	GR_INV_H_LINE
	INC	BX
	POP	SI
	DEC	SI
	JNZ	GIB_10
	
	POP	DX CX BX AX
	RET
	
ENDP

;**************************************************************************************************

;** Kopiert einen Block aus dem Speicher in das Video-RAM **
;** Eingabe: AX=X Position BX=Y Position CX=Breite DX=Höhe SI= Offsett auf Daten DS= Segment auf Daten **

GR_RAM_TO_VRAM PROC

	PUSHA
	XCHG	CX,DX
GRTV_10:
	CALL	GRTV_15
	INC	BX
	DEC	CX
	JNZ	GRTV_10
	POPA
	RET
GRTV_15:	
	PUSH	AX BX CX DX
	MOV	X_TMP,AX
	CMP	AX,X1				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GRTV_30
	CMP	BX,Y1
	JG	GRTV_30
	PUSH	AX DX
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	CMP	TMP_2,DX
	JE	GRTV_20
	MOV	TMP_2,DX
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GRTV_20:
	POP	DX AX
GRTV_25:
	MOV	CL,DS:[SI]
	MOV	ES:[DI],CL			; *** Pixel setzen ***
GRTV_26:
	INC	SI
	ADD	DI,1
	JNC	GRTV_27
	
	PUSH	DX
	MOVZX	BX,GRANULAT_1
	ADD	TMP_2,BX
	MOV	DX,TMP_2
	XOR	BX,BX
	PUSH	AX CX DI
	CALL	[R_FENSTER]
	POP	DI CX AX
	POP	DX
GRTV_27:
	INC	AX
	CMP	AX,X
	JE	GRTV_30
	DEC	DX
	JNZ	GRTV_25
GRTV_30:
	POP	DX CX BX AX
	RET
ENDP

;**************************************************************************************************

;** Kopiert einen Block aus dem Speicher in das Video-RAM und die Farbe 0 ist Transparent **
;** Eingabe: AX=X Position BX=Y Position CX=Breite DX=Höhe SI= Offsett auf Daten DS= Segment auf Daten **

GR_RAM_TO_VRAM_TRANS PROC
	PUSHA
	XCHG	CX,DX
GRTVS_10:
	CALL	GRTVS_15
	INC	BX
	DEC	CX
	JNZ	GRTVS_10
	POPA
	RET
GRTVS_15:	
	PUSH	AX BX CX DX
	MOV	X_TMP,AX
	CMP	AX,X1				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GRTVS_30
	CMP	BX,Y1
	JG	GRTVS_30
	PUSH	AX DX
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	CMP	TMP_2,DX
	JE	GRTVS_20
	MOV	TMP_2,DX
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GRTVS_20:
	POP	DX AX
GRTVS_25:
	MOV	CL,DS:[SI]
	CMP	CL,0
	JE	GRTVS_26
	MOV	ES:[DI],CL			; *** Pixel setzen ***
GRTVS_26:
	INC	SI
	ADD	DI,1
	JNC	GRTVS_27
	
	PUSH	DX
	MOVZX	BX,GRANULAT_1
	ADD	TMP_2,BX
	MOV	DX,TMP_2
	XOR	BX,BX
	PUSH	AX CX DI
	CALL	[R_FENSTER]
	POP	DI CX AX
	POP	DX
GRTVS_27:
	INC	AX
	CMP	AX,X
	JE	GRTVS_30
	DEC	DX
	JNZ	GRTVS_25
GRTVS_30:
	POP	DX CX BX AX
	RET
ENDP

;**************************************************************************************************

;** Kopiert einen Block aus dem Video-Ram in das RAM **
;** Eingabe: AX=X Position BX=Y Position CX=Breite DX=Höhe SI= Offsett auf Daten DS= Segment auf Daten **

GR_VRAM_TO_RAM PROC
	PUSHA
	XCHG	CX,DX
GVTR_10:
	CALL	GVTR_15
	INC	BX
	DEC	CX
	JNZ	GVTR_10
	POPA
	RET
GVTR_15:	
	PUSH	AX BX CX DX
	MOV	X_TMP,AX
	CMP	AX,X1				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GVTR_30
	CMP	BX,Y1
	JG	GVTR_30
	PUSH	AX DX
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	MOV	TMP_2,DX
	PUSH	DI BX DX
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DX BX DI
	
	INC	BL
	PUSH	DI 
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GVTR_20:
	POP	DX AX
GVTR_25:
	MOV	CL,ES:[DI]
	MOV	DS:[SI],CL
GVTR_26:
	INC	SI
	ADD	DI,1
	JNC	GVTR_27
	
	PUSH	DX
	MOVZX	BX,GRANULAT_1
	ADD	TMP_2,BX
	MOV	DX,TMP_2
	
	XOR	BX,BX
	PUSH	AX CX DI BX DX
	CALL	[R_FENSTER]
	POP	DX BX DI CX AX
	
	INC	BL
	PUSH	AX CX DI
	CALL	[R_FENSTER]
	POP	DI CX AX
	
	POP	DX
GVTR_27:
	INC	AX
	CMP	AX,X
	JE	GVTR_30
	DEC	DX
	JNZ	GVTR_25
GVTR_30:
	POP	DX CX BX AX
	RET
ENDP

;**************************************************************************************************

;** Setz ein Zeichen an einer beliebigen Position des Bildschirms **
;** Eingabe: AL-Ascii-Code des Zeichen VAR[CHAR_X]-X Position VAR[CHAR_Y]-Y Position VAR[CHAR_COLOR] Zeichen Farbe VAR[CHAR_BACK_COLOR] Zeichen Hintergrund Farbe

GR_SET_CHAR PROC

	PUSH	AX AX
	MOV	AX,CHAR_X
	CMP	AX,X				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GSC_50
	MOV	BX,CHAR_Y
	CMP	BX,Y
	JG	GSC_50
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	CMP	TMP_2,DX
	JE	GSC_10
	MOV	TMP_2,DX
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GSC_10:
	POP	AX
	MOVZX	SI,AL
	MOV	CL,5
	SHL	SI,CL
	MOV	AH,CHAR_COLOR
	MOV	CL,CHAR_BACK_COLOR
	MOV	BH,15
GSC_20:
	MOV	AL,CHAR_ROM[SI]
	MOV	BL,9
GSC_30:
	SHL	AL,1
	JNC	GSC_40
	MOV	ES:[DI],AH
	JMP	GSC_41
GSC_40:
	MOV	ES:[DI],CL
GSC_41:
	ADD	DI,1
	JNC	GSC_45
	
	PUSH	AX BX DI SI
	INC	TMP_2
	MOV	DX,TMP_2
	XOR	BX,BX
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	SI DI BX AX
GSC_45:	
	DEC	BL
	JNZ	GSC_30
	SUB	DI,9
	ADD	DI,X
	JNC	GSC_47
	
	PUSH	AX BX DI SI
	INC	TMP_2
	MOV	DX,TMP_2
	XOR	BX,BX
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	SI DI BX AX
GSC_47:	
	INC	SI
	DEC	BH
	JNZ	GSC_20
GSC_50:
	POP	AX
	RET
ENDP

;**************************************************************************************************

;** Setz ein Zeichen an einer beliebigen Position des Bildschirms **
;** Eingabe: AL-Ascii-Code des Zeichen VAR[CHAR_X]-X Position VAR[CHAR_Y]-Y Position VAR[CHAR_COLOR] Zeichen Farbe

GR_SET_CHAR_TRANS PROC

	PUSH	AX AX
	MOV	AX,CHAR_X
	CMP	AX,X				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GSCT_50
	MOV	BX,CHAR_Y
	CMP	BX,Y
	JG	GSCT_50
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	CMP	TMP_2,DX
	JE	GSCT_10
	MOV	TMP_2,DX
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GSCT_10:
	POP	AX
	MOVZX	SI,AL
	MOV	CL,5
	SHL	SI,CL
	MOV	AH,CHAR_COLOR
	MOV	BH,15
GSCT_20:
	MOV	AL,CHAR_ROM[SI]
	MOV	BL,8
GSCT_30:
	SHL	AL,1
	JNC	GSCT_40
	MOV	ES:[DI],AH
GSCT_40:
	ADD	DI,1
	JNC	GSCT_45
	
	PUSH	AX BX DI SI
	INC	TMP_2
	MOV	DX,TMP_2
	XOR	BX,BX
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	SI DI BX AX
GSCT_45:	
	DEC	BL
	JNZ	GSCT_30
	SUB	DI,8
	ADD	DI,X
	JNC	GSCT_47
	
	PUSH	AX BX DI SI
	INC	TMP_2
	MOV	DX,TMP_2
	XOR	BX,BX
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	SI DI BX AX
GSCT_47:	
	INC	SI
	DEC	BH
	JNZ	GSCT_20
GSCT_50:
	POP	AX
	RET
ENDP

;**************************************************************************************************

;** Setz ein Zeichen an einer beliebigen Position des Bildschirms und einen Beliebigen Zeichensatz (8*8 Pixel pro zeichen) **
;** Eingabe: FS:SI-Zeiger auf Zeichensatzrom AL-Ascii-Code des Zeichen VAR[CHAR_X]-X Position VAR[CHAR_Y]-Y Position VAR[CHAR_COLOR] Zeichen Farbe VAR[CHAR_BACK_COLOR] Zeichen Hintergrund Farbe

GR_SET_CHAR_FONT PROC

	PUSH	AX AX SI
	MOV	AX,CHAR_X
	CMP	AX,X				; *** Prüfen ob Punkt innerhalb des Bildschirms liegt ***		
	JG	GSCF_50
	MOV	BX,CHAR_Y
	CMP	BX,Y
	JG	GSCF_50
	MOV	DI,BX				; *** OFFSETT und WERT für Pageregister ermitteln ***
	SHL	DI,1
	SHL	DI,1
	MOVZX	EBX,AX
	MOV	EAX,Z_ADRESSEN[DI]
	ADD	EAX,EBX
	ADD	EAX,DWORD PTR PAGE_OFFSETT_LO
	
	MOV	DWORD PTR X1_LO,EAX		; *** Durch 64KB ***
	MOV	CL,16
	MOV	DI,X1_LO
	SHR	DWORD PTR X1_LO,CL
	
	XOR	BX,BX
	MOV	AX,X1_LO
	MUL	GRANULAT_1
	XCHG	DX,AX
	CMP	TMP_2,DX
	JE	GSCF_10
	MOV	TMP_2,DX
	PUSH	DI
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	DI
GSCF_10:
	POP	SI AX 
	MOVZX	BX,AL
	MOV	CL,3
	SHL	BX,CL
	ADD	SI,BX
	MOV	AH,CHAR_COLOR
	MOV	CL,CHAR_BACK_COLOR
	MOV	BH,7
GSCF_20:
	MOV	AL,FS:[SI]
	MOV	BL,9
GSCF_30:
	SHL	AL,1
	JNC	GSCF_40
	MOV	ES:[DI],AH
	JMP	GSCF_41
GSCF_40:
	MOV	ES:[DI],CL
GSCF_41:
	ADD	DI,1
	JNC	GSCF_45
	
	PUSH	AX BX DI SI
	INC	TMP_2
	MOV	DX,TMP_2
	XOR	BX,BX
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	SI DI BX AX
GSCF_45:	
	DEC	BL
	JNZ	GSCF_30
	SUB	DI,9
	ADD	DI,X
	JNC	GSCF_47
	
	PUSH	AX BX DI SI
	INC	TMP_2
	MOV	DX,TMP_2
	XOR	BX,BX
	CALL	[R_FENSTER]			; *** Funktion zum Verschieben des Zugriffsfensters aufrufen ***
	POP	SI DI BX AX
GSCF_47:	
	INC	SI
	DEC	BH
	JNZ	GSCF_20
GSCF_50:
	POP	AX
	RET
ENDP

;**************************************************************************************************

;** Bringt einen Text auf dem Bildschirm **
;** [CHAR_X]-X Position [CHAR_Y]-Y Position [CHAR_COLOR]-Frabnummer DS:DI-Zeiger auf Text **
;** Im Text: 0-textende 10 -zum Zeilenanfang 13- eine Zeile runter **

GR_TEXT PROC
	PUSH	AX BX CX DI
	MOV	AX,CHAR_X
	MOV	CHAR_X_TMP,AX
TEXT_10:
	MOV	AL,[DI]
	CMP	AL,0
	JE	TEXT_ENDE
	CMP	AL,13
	JE	ZEILE_RUNTER
	CMP	AL,10
	JE	ZUM_ANFANG
	PUSH	DI
	CALL	GR_SET_CHAR
	POP	DI
	ADD	CHAR_X,9
	INC	DI
	JMP	TEXT_10
ZEILE_RUNTER:
	ADD	CHAR_Y,13
	INC	DI
	JMP	TEXT_10
ZUM_ANFANG:
	MOV	AX,CHAR_X_TMP
	MOV	CHAR_X,AX
	INC	DI
	JMP	TEXT_10
TEXT_ENDE:
	POP	DI CX BX AX
	RET
ENDP

;**************************************************************************************************

;** Bringt einen Text auf dem Bildschirm **
;** [CHAR_X]-X Position [CHAR_Y]-Y Position [CHAR_COLOR]-Frabnummer DS:DI-Zeiger auf Text **
;** Im Text: 0-textende 10 -zum Zeilenanfang 13- eine Zeile runter **

GR_TEXT_TRANS PROC
	PUSH	AX BX CX DI
	MOV	AX,CHAR_X
	MOV	CHAR_X_TMP,AX
TEXT_T_10:
	MOV	AL,[DI]
	CMP	AL,0
	JE	TEXT_ENDE_T
	CMP	AL,13
	JE	ZEILE_RUNTER_T
	CMP	AL,10
	JE	ZUM_ANFANG_T
	PUSH	DI
	CALL	GR_SET_CHAR_TRANS
	POP	DI
	ADD	CHAR_X,9
	INC	DI
	JMP	TEXT_T_10
ZEILE_RUNTER_T:
	ADD	CHAR_Y,13
	INC	DI
	JMP	TEXT_T_10
ZUM_ANFANG_T:
	MOV	AX,CHAR_X_TMP
	MOV	CHAR_X,AX
	INC	DI
	JMP	TEXT_T_10
TEXT_ENDE_T:
	POP	DI CX BX AX
	RET
ENDP

;**************************************************************************************************

;** Installiert ein Maus Interrupt Event und Erzeugt einen Mauspointer **
;** Eingabe: AX-Breite des Pointer BX-Höhe CX-Offsett für Mauspointer Daten DX-Puffer für Pointer **

GR_INIT_MAUS PROC

	PUSH	AX BX CX DX ES
	
	MOV	POINTER_BREITE,AX		; *** Übergebene Werte für Interruptroutiene Sichern ***
	MOV	POINTER_HÖHE,BX
	MOV	POINTER_OFFSETT,CX
	MOV	POINTER_PUFFER,DX
	
	MOV	AX,0				; *** Maus Reset Durchführen ***
	INT	33H
	
	MOV	CX,X				; *** Maus Position auf Mitte Bildschirm stellen ***
	SHR	CX,1
	MOV	MAUS_X_OLD,CX

	MOV	DX,Y
	SHR	DX,1
	MOV	MAUS_Y_OLD,DX	
	
	MOV	AX,04H				
	INT	33H
	
	MOV	AX,MAUS_X_OLD
	MOV	BX,MAUS_Y_OLD
	MOV	CX,POINTER_BREITE
	MOV	DX,POINTER_HÖHE
	MOV	SI,POINTER_PUFFER
	CALL	GR_VRAM_TO_RAM
	
	MOV	SI,POINTER_OFFSETT
	CALL	GR_RAM_TO_VRAM_TRANS
	
	MOV	AX,07H				; *** Mausbewegungsbereich für X festlegen ***	
	MOV	CX,0
	MOV	DX,X
	DEC	DX
	INT	33H
	
	MOV	AX,08H				; *** Mausbewegungsbereich für Y festlegen ***
	MOV	CX,0
	MOV	DX,Y
	DEC	DX
	DEC	DX
	INT	33H
	
	MOV	AX,0CH				; *** Evendhandler auf I-Routiene "MIR" stellen ***
	MOV	CX,0FFFFH
	LEA	DX,MIR
	PUSH	CS
	POP	ES
	INT	33H	
	POP	ES DX CX BX AX
	RET
	
;******** Maus Interrupt Routiene **********
MIR:				
	PUSH	AX BX CX DX DI SI ES
	
	MOV	SI,DX				; *** Datensegment holen da er auf Maustreiber steht ***
	MOV	DX,@DATA
	MOV	DS,DX
	
	MOV	MAUS_TASTEN,BX			; *** Parameter in Variablen speichern ***
	MOV	MAUS_X,CX
	MOV	MAUS_Y,SI
	
	CMP	CS:AKTIV,0			; *** Testen ob MIR schon Aktiv ist ***
	JNE	MIR_ENDE	
	MOV	CS:AKTIV,1
	
	MOV	ES,V_RAM			; *** Video Ram ins ES Register eintragen ***
	MOV	SI,POINTER_PUFFER
	MOV	AX,MAUS_X_OLD
	MOV	BX,MAUS_Y_OLD
	MOV	CX,POINTER_BREITE
	MOV	DX,POINTER_HÖHE
	CALL	GR_RAM_TO_VRAM			; *** Pointer mit alten Video Daten überschreiben ***
	
	MOV	AX,MAUS_X
	MOV	BX,MAUS_Y
	MOV	MAUS_X_OLD,AX
	MOV	MAUS_Y_OLD,BX
	CALL	GR_VRAM_TO_RAM			; *** An neuer Position Video Daten sichern ***
	
	MOV	SI,POINTER_OFFSETT
	CALL	GR_RAM_TO_VRAM_TRANS		; *** An neuer Position Pointer Zeichnen 0 ist Transparent ***			
	
	MOV	CS:AKTIV,0
	
MIR_ENDE:
	POP	ES SI DI DX CX BX AX
	RETF
ENDP

;**************************************************************************************************

;** Schaltet den Mauspointer ab **

GR_MAUS_AUS PROC
	PUSHA
GMAUS_10:
	CMP	CS:AKTIV,0
	JNE	GMAUS_10
	MOV	CS:AKTIV,1
		
	MOV	AX,MAUS_X_OLD
	MOV	BX,MAUS_Y_OLD
	MOV	CX,POINTER_BREITE
	MOV	DX,POINTER_HÖHE
	MOV	SI,POINTER_PUFFER
	CALL	GR_RAM_TO_VRAM
	
	POPA
	RET
ENDP

;**************************************************************************************************

;** Schaltet den Mauspointer an **

GR_MAUS_AN PROC
	PUSHA
	
	MOV	AX,MAUS_X_OLD
	MOV	BX,MAUS_Y_OLD
	MOV	CX,POINTER_BREITE
	MOV	DX,POINTER_HÖHE
	MOV	SI,POINTER_PUFFER
	CALL	GR_VRAM_TO_RAM
	
	MOV	SI,POINTER_PUFFER
	PUSH	AX BX CX DX
	CALL	GR_VRAM_TO_RAM
	POP	DX CX BX AX
	MOV	SI,POINTER_OFFSETT
	CALL	GR_RAM_TO_VRAM_TRANS
	
	MOV	CS:AKTIV,0
	POPA
	RET
ENDP

;**************************************************************************************************

;** Setzt die RGB Werte für eine Farbe **

GR_SET_RGB PROC
	MOV	AH,10H
	MOV	AL,12H
	MOVZX	BX,FARBE
	MOV	CX,1
	LEA	DX,ROT
	PUSH	ES
	PUSH	DS
	POP	ES
	INT	10H
	POP	ES
	RET
ENDP

;**************************************************************************************************

;** Liest die RGB Werte für eine Farbe **

GR_READ_RGB PROC
	MOV	AH,10H
	MOV	AL,17H
	MOVZX	BX,FARBE
	MOV	CX,1
	LEA	DX,ROT
	PUSH	ES
	PUSH	DS
	POP	ES
	INT	10H
	POP	ES
	RET
ENDP
;*******************************************



GR_LINE	PROC
	PUSHA
        MOV LX1,AX       ; šbergebene Parameter sichern
        MOV LY1,BX
        MOV LX2,CX
        MOV LY2,DX
        MOV LFARBE,SI

        MOV AX,LX2       ; Differenz X2 - X1 nach AX
        SUB AX,LX1
        JNS LAB1
        NEG AX          ; Vorzeichentausch
LAB1:
        MOV BX,LY2       ; Differenz von Y2 - Y1 nach BX
        SUB BX,LY1
        JNS LAB2
        NEG BX          ; Vorzeichentausch
LAB2:
        CMP AX,BX       ; Steigung <= 1 ?
        JGE LAB3A       ; Ja
        JMP LAB20       ; Nein
LAB3A:  
        MOV CX,LX1       ; Ist X1 <= X2 ?
        CMP CX,LX2
        JG LAB4
        MOV CX,1        ; X steigt
        JMP SHORT LAB5
LAB4:
        MOV CX,-1       ; X f„llt
LAB5:
        MOV DX,LY1       ; Ist Y1 <= Y2
        CMP DX,LY2
        JG LAB6
        MOV DX,1        ; Y steigt
        JMP SHORT LAB7
LAB6:
        MOV DX,-1       ; Y f„llt
LAB7:
        MOV LS1,CX       ; Steigung auf dem Stack speichern
        MOV LS2,DX
        ADD BX,BX       ; Steigung berechnen
        MOV LS3,BX
        SUB BX,AX
        MOV CX,BX
        SUB CX,AX
        MOV LS4,CX
        MOV AX,LFARBE    ; Ersten Punkt setzen
        MOV CX,LX1
        MOV DX,LY1
        CALL LPOINT	 ; Funktion zum Setzen eines Punktes
LAB8:
        CMP CX,LX2       ; Weitere Punkte?
        JZ LAB3
        ADD CX,LS1       ; X-Koordinate erh”hen
        OR BX,BX        ; Entscheiden, ob Y-Koordinate erh”ht
        JNS LAB10       ; wird
        ADD BX,LS3
        JMP SHORT LAB11
LAB10:
        ADD BX,LS4       ; N„chsten Punkt ausgeben
        ADD DX,LS2
LAB11:
        CALL LPOINT	  ; Funktion zum Setzen eines Punktes
        JMP SHORT LAB8
LAB20:

;----------------------------------------------------------
; Dieser Teil wird durchlaufen, wenn die Steigung > 1 ist
;----------------------------------------------------------

        MOV CX,LY1       ; Steigung ist > 1
        CMP CX,LY2       ; Ist Y1 <= Y2 ?
        JG LAB12
        MOV CX,1        ; Y steigt
        JMP SHORT LAB13
LAB12:
        MOV CX,-1       ; Y f„llt
LAB13:
        MOV DX,LX1       ; Ist X1 <= X2 ?
        CMP DX,LX2
        JG LAB14
        MOV DX,1        ; X steigt
        JMP SHORT LAB15
LAB14:
        MOV DX,-1       ; X f„llt
LAB15:
        MOV LS1,CX       ; Steigung auf dem Stack speichern
        MOV LS2,DX
        ADD AX,AX       ; Steigung berechnen
        MOV LS3,AX
        SUB AX,BX
        MOV CX,AX
        SUB CX,BX
        MOV LS4,CX
        MOV BX,AX
        MOV AX,LFARBE    ; 1. Punkt ausgeben
        MOV CX,LX1
        MOV DX,LY1
        CALL LPOINT	  ; Diese Funktion setzt einen Punkt
LAB16:
        CMP DX,LY2       ; Weitere Punkte ausgeben?
        JZ LAB3
        ADD DX,LS1
        OR BX,BX
        JNS LAB18
        ADD BX,LS3
        JMP SHORT LAB19
LAB18:
        ADD BX,LS4
        ADD CX,LS2
LAB19:
        CALL LPOINT   ; Diese Funktion setzt einen Punkt
        JMP SHORT LAB16
;
LAB3:
	POPA
        RET             ; Zurück zum Hauptprogramm
ENDP

LPOINT:
	PUSHA
	XCHG	AX,CX
	MOV	BX,DX
	CALL	GR_SET_POINT
	
	POPA
	RET
; -----------------------------------------------------------------------------
; Prozedur zum Setzen eines Punktes (leicht modifiziert gegenber SETXY)
; Aufruf mit:   AX      =       Modus (0= löschen, 1 = schreiben)
;               CX      =       X-Koordinate
;               DX      =       Y-Koordinate
END