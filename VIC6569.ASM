;****************************************
;*					*
;* Titel: VIC-Emulation	(für Emu64)	*
;* Autor: Thorsten Kattanek		*
;* Datum: 1.7.1998			*
;* Ort  : Berlin			*
;* Vers : 				*
;* Info : 				*
;*					*
;*					*
;****************************************

EXTRN	C64_RAM:WORD,C64_ROM:WORD,ZYKLEN:BYTE,COUNT_TIMER_A:NEAR,I_FLAGS:BYTE,FLAGS_1:WORD,PCX_OUT:NEAR
EXTRN	FPS:NEAR,TASTE:BYTE,JOYSTICKS:NEAR,CONFIG:BYTE,GBO:NEAR

PUBLIC	VIC_6569,V_RAM_ADRESSEN,RASTER_LATCH_LO,RASTER_LATCH_HI,LP,SCREEN_WAIT

.MODEL SMALL
.DATA


;****************************************

	X_SPRITE_KOOR	DW	194H,19CH,1A4H,1ACH,1B4H,1BCH,1C4H,1CCH,1D4H,1DCH,1E4H,1ECH,1F4H,004H,00CH,014H
			DW	01CH,024H,02CH,034H,03CH,044H,04CH,054H,05CH,064H,06CH,074H,07CH,084H,08CH,094H
			DW	09CH,0A4H,0ACH,0B4H,0BCH,0C4H,0CCH,0D4H,0DCH,0E4H,0ECH,0F4H,0FCH,104H,10CH,114H
			DW	11CH,124H,12CH,134H,13CH,144H,14CH,154H,15CH,164H,16CH,174H,17CH,184H,18CH
	ADR_VRAM DW	0A000H
	RZ_X	DW	0			; X Position des Rasterstrahls ( Pixelgenau !!)
	RZ_Y	DW	0			; Y Position des Rasterstrahls
	RZ	DB	604 DUP (0)		; Komplette Rasterzeile mit Rahmen und Vertical Refresh (63 Zyklen)
	RZ_PRIO	DB	604 DUP (0)		; Komplette Rasterzeile mit Rahmen als Priorität ( 0=Hintrgrund 1=Vordergrund)
	RZ_ZK	DB	1			; X Position des Rasterstrahls ( Zyklengenau !!)
	V_RAM_ADRESSEN  DW 312 DUP (0)
	DEN_STATUS 	DB	0		; Hier wird vermerkt ob in Rasterzeile $30 das DEN Bit gesetzt wurde
	BAD_STATUS	DB	0
	C_MODE		DB	0		; Hier wird vermerkt ob die C Zugriffe schon gestartet sind
	IRQ_ENABLE	DB	0
	LP		DB	0		; Hier wird eine Negative Flanke an LP registriert
	LP_TEST		DB	0		; Wenn hier eine 1 ist wird Kein LP-IRQ kontrolliert

	VCBASE		DW	0		; Interne VIC Register !!!
	VC		DW	0
	RC		DB	0
	VMLI		DW  	0
	VIC_PUFFER_0	DB 60 DUP (0)
	VIC_PUFFER_1	DB 60 DUP (0)
	
;******************** Interne VIC Register für Sprites !!! ****************

	MXE		DB	0		; Sprie AN/AUS Register 
	SEQU_0		DD	0		; 24 Bit Sprite Sequencer
	MC_0		DB	0		; MC Register		
	MCBASE_0	DB	0		; MC-Base Register
	FLIP_0		DB	0		; Y Expansions Flip/Flop 
	Y_POS_0		DB	0		; Y Position 		
	DMA_0		DB	0		; DMA AN/AUS [0=Aus 1=An]
	SON_0		DB	0		; Sequencer AN/AUS
	PDAT_0		DB	0		; Hier ist immer der Wert des P Zugriffs ( Jede Rasterzeile Zykl 58 )

	YSCROLL		DW	0
	XSCROLL		DW	0
	ANZEIGELOGIK	DB	0		; 0 = Idle-Zustand / 1 = Display-Zustand
	C_ADRESSE	DB	0
	G_ADRESSE	DB	0
	V_MODUS		DB	0
	RF0		DB	0
	FLIP		DB	0
	HF0		DB	0
	HF1		DB	0
	HF2		DB	0
	SF0		DB	0
	RASTER_LATCH_LO DB	0
	RASTER_LATCH_HI DB	0
	SCREEN_WAIT	DB 	0

;****************************************

.486
.CODE


VIC_6569:; PROC
	
	MOV	ES,C64_RAM
	
	MOV	AH,ES:0D020H
	AND	AH,00001111B
	MOV	RF0,AH

	MOV	AH,ES:0D021H			; *** Hintergrundfarbe 0 ***
	AND	AH,00001111B
	MOV	HF0,AH

	MOV	AH,ES:0D022H			; *** Hintergrundfarbe 1 ***
	AND	AH,00001111B
	MOV	HF1,AH
	
	MOV	AH,ES:0D023H			; *** Hintergrundfarbe 2 ***
	AND	AH,00001111B
	MOV	HF2,AH
	
	MOV	AH,ES:0D027H
	AND	AH,00001111B
	MOV	SF0,AH

	MOVZX	AX,ES:0D011H			; *** Y-Scroll ***
	AND	AL,00000111B
	MOV	YSCROLL,AX

	MOV	AL,ES:0D016H			; *** X-Scroll ***
	AND	AL,00000111B
	XOR	AH,AH
	MOV	XSCROLL,AX
	
	MOV	AH,ES:0D015H
	MOV	MXE,AH
	
	MOV	AH,ES:0D001H			; *** Y-Koordinate Sprite 0 ***
	MOV	Y_POS_0,AH

	MOV	AL,ES:0D01AH			; *** Interrupt-Enable ***
	AND	AL,00001111B
	MOV	IRQ_ENABLE,AL

	MOV	AL,ES:0D018H			; *** Adresse für C-Zugriffe vorbereiten ***
	AND	AL,11110000B
	ROR	AL,1
	ROR	AL,1
	MOV	AH,ES:0DD00H
	NOT	AH
	AND	AH,00000011B
	ROR	AH,1
	ROR	AH,1
	MOV	G_ADRESSE,AH			; *** Bit 14 und 15 schon in G-Adressen einschreiben ***
	OR	AL,AH
	MOV	C_ADRESSE,AL
						; *** Für jeden Videomodus wird eine ander G-Adresse gebraucht ***
	MOV	AH,ES:0D011H
	AND	AH,01100000B
	MOV	AL,ES:0D016H
	AND	AL,00010000B
	OR	AH,AL
	MOV	CL,4
	ROR	AH,CL
	MOV	V_MODUS,AH
	CMP	AH,0
	JE	L1
	CMP	AH,1
	JE	L1
	CMP	AH,2
	JE	L2
	CMP	AH,3
	JE	L2
	CMP	AH,4
	JE	L1
	CMP	AH,5
	JE	L1
	CMP	AH,6
	JE	L2
	CMP	AH,7
	JE	L2
L1:
	MOV	AH,ES:0D018H
	AND	AH,00001110B
	MOV	CL,2
	ROL	AH,CL
	OR	G_ADRESSE,AH
	JMP	L000
L2:
	MOV	AH,ES:0D018H
	AND	AH,00001000B
	MOV	CL,2
	ROL	AH,CL
	OR	G_ADRESSE,AH
L000:
	MOV	ES,C64_RAM
	MOV	BAD_STATUS,0

;***************** RASTER-IRQ ********************************

	CMP	RZ_ZK,1
	JNE	L001

	MOV	AX,RZ_Y				; *** Aktuelle Rasterzeile in Register $D011 und $D012 schreiben ***
	MOV	ES:0D012H,AL
	AND	AH,00000001B
	ROR	AH,1
	AND	BYTE PTR ES:0D011H,01111111B
	OR	ES:0D011H,AH

	MOV	AX,RZ_Y				; *** Rasterlatch mit aktuelle Rasterzeile Vergleichen ***
	CMP	AX,WORD PTR RASTER_LATCH_LO
	JNE	L001

	OR	BYTE PTR ES:0D019H,00000001B

;*************************************************************
L001:
	CMP	LP,1			; *** Test ob ein LP aufgetreten ist ***
	JNE	L008
	
	CMP	LP_TEST,1		; *** Test ob schon im akt. Bildaufbau LP aufgtreten ist ***
	JE	L008
		
	MOVZX	DI,RZ_ZK
	DEC	DI
	SHL	DI,1
	MOV	AX,X_SPRITE_KOOR[DI]
	SHR	AX,1
	MOV	ES:0D013H,AL

	MOV	AX,RZ_Y
	MOV	ES:0D014H,AL
L008:
	MOV	AL,IRQ_ENABLE			; *** Wenn VIC irgendein IRQ hat wird ein IRQ an CPU ausgelöst ***
	AND	AL,ES:0D019H
	JZ	L009
	OR	BYTE PTR ES:0D019H,10000000B
	OR	I_FLAGS,00000010B	
L009:
	CMP	RZ_Y,030H			; *** wenn Rasterzeile $30 dann auf DEN Bit Testen !!! ***
	JNE	L010
	MOV	AH,ES:0D011H
	AND	AH,00010000B
	JZ	L010
	MOV	DEN_STATUS,1			; *** Das DEN-Bit war in Rasterzeile $30 gesetzt ***
L010:
	CMP	RZ_Y,030H			; *** Zyklus auf Bad zustand testen ***
	JL	L020				; *** springe wenn Kleiner $30 ( Kein BAD Line ) ***
	CMP	RZ_Y,0F7H
	JG	L020				; *** springe wenn Größer $F7 ( Kein BAD Line ) ***

	MOV	AX,RZ_Y				; *** Vergleiche YSCROLL mit RASTER ***
	AND	AX,0000000000000111B
	CMP	AX,YSCROLL
	JNE	L020

	CMP	DEN_STATUS,1
	JNE	L020
	MOV	BAD_STATUS,1			; *** Hier ist ein BAD_LINE zustand ***

	CMP	C_MODE,1
	JE	L020

	CMP	RZ_ZK,12			; *** wennn RZ_ZK zwischen 12 und 54 dann CPU sperren ***
	JL	L020
	CMP	RZ_ZK,54
	JG	L020
						; *** JA ! CPU gespert ***
	MOV	AL,54
	SUB	AL,RZ_ZK
	DEC	AL
	ADD	ZYKLEN,AL
	MOV	C_MODE,1
L020:
	CMP	RZ_ZK,14			; *** in Zyklus 14 jeder Zeile VC mit VCBASE laden ***
	JNE	L050
	MOV	AX,VCBASE
	MOV	VC,AX
	MOV	VMLI,0				; *** und VMLI löschen ***
	CMP	BAD_STATUS,1
	JNE	L050
	MOV	RC,0
L050:
	CMP	ANZEIGELOGIK,1			; *** Idle oder Display-Zustand ??? ***
	JE	L200				; *** Sprung zum Displaymodus ***

; *********     IDLE-ZUSTAND     ***********
L055:
	MOV	ANZEIGELOGIK,0
	CMP	BAD_STATUS,1
	JE	L200				; *** Wechsel von IDLE zum Display-Zustand ***

	MOV	DI,RZ_X
	MOV	AH,0
	MOV	CL,RF0
L060:
	MOV	RZ[DI],CL
	INC	DI
	INC	AH
	CMP	AH,8
	JNE	L060
	MOV	RZ_X,DI
	JMP	L01000


; ***********  DISPLAY-ZUSTAND  ***********

L200:
	MOV	ANZEIGELOGIK,1
	CMP	RZ_ZK,58
	JNE	L230
	CMP	RC,7
	JNE	L220
	MOV	AX,VC				; *** Wechsel von Display in den IDLE-Zustand ***
	MOV	VCBASE,AX
	MOV	BAD_STATUS,0
	JMP	L055

L220:
	INC	RC
	AND	RC,00000111B
L230:
	CMP	RZ_ZK,15
	JL	L0900
	CMP	RZ_ZK,55
	JG	L0900
						; *** Hier sind die g und (c) Zugriffe ***
	MOV	DI,RZ_X
	MOV	AH,0
	MOV	AL,HF0

	CMP	RZ_ZK,15			; *** in Zyklus 15 nur 1 C Zugriff kein G Zugriff !!! ***
	JNE	L240

	CMP	C_MODE,1
	JNE	L0900				; *** Keine C-Zugriffe ***

	MOV	SI,VC				; *** C-ZUGRIFF ***
	MOV	CL,ES:0D800H[SI]
	MOV	DI,VMLI
	MOV	VIC_PUFFER_0[DI],CL

	MOV	AX,VC
	OR	AH,C_ADRESSE
	MOV	SI,AX
	MOV	CL,ES:[SI]
	MOV	VIC_PUFFER_1[DI],CL
	JMP	L0900
L240:
	CMP	V_MODUS,0
	JE	L245
	CMP	V_MODUS,1
	JE	L280
	CMP	V_MODUS,2
	JE	L350
	CMP	V_MODUS,3
	JE	L390
	CMP	V_MODUS,4
	JE	L420
	JMP	L0800

;************* Standart-Textmodus  (ECM/BMM/MCM=0/0/0) **************

L245:						; *** G-ZUGRIFF ***
	MOV	SI,VMLI
	MOV	CH,VIC_PUFFER_0[SI]
	MOVZX	AX,VIC_PUFFER_1[SI]
	MOV	CL,3
	ROL	AX,CL
	OR	AL,RC
	OR	AH,G_ADRESSE
	MOV	SI,AX

	CMP	SI,01000H
	JL	L248
	CMP	SI,02000H
	JL	L246
	CMP	SI,09000H
	JL	L248
	CMP	SI,0A000H
	JL	L247
	JMP	L248
L246:
	MOV	ES,C64_ROM
	ADD	SI,0C000H
	JMP	L249
L247:
	MOV	ES,C64_ROM
	ADD	SI,04000H
	JMP	L249
L248:
	MOV	ES,C64_RAM
L249:
	MOV	AH,ES:[SI]
	MOV	ES,C64_RAM

	INC	VC
	AND	VC,0000001111111111B		; *** nach G-Zugriff Vic Register erhöhen ***
	INC	VMLI
	AND	VMLI,0000000000111111B

	MOV	CL,HF0				; *** BYTE AUSGEBEN ***
	MOV	AL,0
	MOV	DI,RZ_X
	ADD	DI,XSCROLL
L250:
	SAL	AH,1				; *** (0) Hintergrund setzen ***
	JB	L260
	MOV	RZ[DI],CL
	MOV	RZ_PRIO[DI],0
	INC	DI
	JMP	L270
L260:
	MOV	RZ[DI],CH			; *** (1) Vordergrund setzen ***
	MOV	RZ_PRIO[DI],1
	INC	DI
L270:
	INC	AL
	CMP	AL,8
	JNE	L250
	SUB	DI,XSCROLL
	MOV	RZ_X,DI
	JMP	L0850

;************* Multicolor-Textmodus  (ECM/BMM/MCM=0/0/1) **************

L280:						; *** G-ZUGRIFF ***
	MOV	SI,VMLI
	MOV	CH,VIC_PUFFER_0[SI]
	MOVZX	AX,VIC_PUFFER_1[SI]
	MOV	CL,3
	ROL	AX,CL
	OR	AL,RC
	OR	AH,G_ADRESSE
	MOV	SI,AX
	
	;JMP	L286

	CMP	SI,01000H
	JL	L286
	CMP	SI,02000H
	JL	L282
	CMP	SI,09000H
	JL	L286
	CMP	SI,0A000H
	JL	L284
	JMP	L286
L282:
	MOV	ES,C64_ROM
	ADD	SI,0C000H
	JMP	L288
L284:
	MOV	ES,C64_ROM
	ADD	SI,04000H
	JMP	L288
L286:
	MOV	ES,C64_RAM
L288:
	MOV	AH,ES:[SI]
	MOV	ES,C64_RAM

	INC	VC
	AND	VC,0000001111111111B		; *** nach G-Zugriff Vic Register erhöhen ***
	INC	VMLI
	AND	VMLI,0000000000111111B

	MOV	AL,CH
	AND	AL,00001000B
	JNZ	L315				; *** sprung zum 4 Bit Modus ***

; *** Multicolormodus 8 Bit Modus ***

	MOV	CL,HF0				; *** BYTE AUSGEBEN ***
	MOV	AL,0
	MOV	DI,RZ_X
	AND	CH,00000111B
	ADD	DI,XSCROLL
L300:
	SAL	AH,1				; *** (0) Hintergrund setzen ***
	JB	L305
	MOV	RZ[DI],CL
	MOV	RZ_PRIO[DI],0
	INC	DI
	JMP	L310
L305:
	MOV	RZ[DI],CH
	MOV	RZ_PRIO[DI],1
	INC	DI
L310:
	INC	AL				; *** (1) Vordergrund setzen ***
	CMP	AL,8
	JNE	L300
	SUB	DI,XSCROLL
	MOV	RZ_X,DI
	JMP	L0850

; *** Multicolormodus 4 Bit Modus ***

L315:
	AND	CH,00000111B
	MOV	AL,0
	MOV	DI,RZ_X
	ADD	DI,XSCROLL
L320:
	SAL	AH,1
	JB	L330
	SAL	AH,1
	JB	L325

	MOV	CL,HF0				; *** Bit 00 ***
	MOV	RZ[DI],CL
	MOV	WORD PTR RZ_PRIO[DI],0000H
	INC	DI
	MOV	RZ[DI],CL
	INC	DI
	JMP	L340
L325:
	MOV	CL,HF1				; *** Bit 01 ***
	MOV	RZ[DI],CL
	MOV	WORD PTR RZ_PRIO[DI],0000H
	INC	DI
	MOV	RZ[DI],CL
	INC	DI
	JMP	L340
L330:
	SAL	AH,1
	JB	L335

	MOV	CL,HF2				; *** Bit 10 ***
	MOV	RZ[DI],CL
	MOV	WORD PTR RZ_PRIO[DI],0101H
	INC	DI
	MOV	RZ[DI],CL
	INC	DI
	JMP	L340
L335:
	MOV	RZ[DI],CH
	MOV	WORD PTR RZ_PRIO[DI],0101H	; *** Bit 11 ***
	INC	DI
	MOV	RZ[DI],CH
	INC	DI
L340:
	INC	AL
	CMP	AL,4
	JNE	L320
	SUB	DI,XSCROLL
	MOV	RZ_X,DI
	JMP	L0850

;************* Standard-Bitmap-Modus  (ECM/BMM/MCM=0/1/0) **************

L350:
	MOV	SI,VMLI
	MOV	CH,VIC_PUFFER_1[SI]
	MOV	AX,VC
	MOV	CL,3
	ROL	AX,CL
	OR	AL,RC
	OR	AH,G_ADRESSE
	MOV	SI,AX

	MOV	AH,ES:[SI]

	INC	VC
	AND	VC,0000001111111111B		; *** nach G-Zugriff Vic Register erhöhen ***
	INC	VMLI
	AND	VMLI,0000000000111111B

	MOV	DL,CH				; *** BYTE AUSGEBEN ***
	AND	DL,00001111B
	AND	CH,11110000B
	MOV	CL,4
	ROR	CH,CL

	MOV	AL,0
	MOV	DI,RZ_X
L375:
	SAL	AH,1				; *** (0) Hintergrund setzen ***
	JB	L380
	MOV	RZ[DI],dl
	MOV	RZ_PRIO[DI],0
	INC	DI
	JMP	L385
L380:
	MOV	RZ[DI],ch			; *** (1) Vordergrund setzen ***
	MOV	RZ_PRIO[DI],1
	INC	DI
L385:
	INC	AL
	CMP	AL,8
	JNE	L375
	MOV	RZ_X,DI
	JMP	L0850

;************* Multicolor-Bitmap-Modus  (ECM/BMM/MCM=0/1/1) **************

L390:
	MOV	SI,VMLI
	MOV	CH,VIC_PUFFER_0[SI]
	MOV	CL,VIC_PUFFER_1[SI]
	PUSH	CX
	MOV	AX,VC
	MOV	CL,3
	ROL	AX,CL
	OR	AL,RC
	OR	AH,G_ADRESSE
	MOV	SI,AX

	MOV	AH,ES:[SI]

	INC	VC
	AND	VC,0000001111111111B		; *** nach G-Zugriff Vic Register erhöhen ***
	INC	VMLI
	AND	VMLI,0000000000111111B

	POP	CX	

	MOV	DH,CL
	MOV	DL,CL
	
	AND	DH,11110000B
	MOV	CL,4
	ROR	DH,CL				; *** DH Farbe für 01 Pixel ***
	AND	DL,00001111B			; *** DL Farbe für 10 Pixel ***
	AND	CH,00001111B			; *** CH Farbe für 11 Pixel ***
	MOV	CL,HF0				; *** CL Farbe für 00 Pixel ***

	MOV	AL,0				; *** Byte Ausgeben ***
	MOV	DI,RZ_X
L395:
	SAL	AH,1
	JB	L405
	SAL	AH,1
	JB	L400

						; *** Bit 00 ***
	MOV	RZ[DI],CL
	MOV	WORD PTR RZ_PRIO[DI],0000H
	INC	DI
	MOV	RZ[DI],CL
	INC	DI
	JMP	L415
L400:
						; *** Bit 01 ***
	MOV	RZ[DI],DH
	MOV	WORD PTR RZ_PRIO[DI],0000H
	INC	DI
	MOV	RZ[DI],DH
	INC	DI
	JMP	L415
L405:
	SAL	AH,1
	JB	L410

						; *** Bit 10 ***
	MOV	RZ[DI],DL
	MOV	WORD PTR RZ_PRIO[DI],0101H
	INC	DI
	MOV	RZ[DI],DL
	INC	DI
	JMP	L415
L410:
	MOV	RZ[DI],CH			; *** Bit 11 ***
	MOV	WORD PTR RZ_PRIO[DI],0101H
	INC	DI
	MOV	RZ[DI],CH
	INC	DI
L415:
	INC	AL
	CMP	AL,4
	JNE	L395
	MOV	RZ_X,DI
	JMP	L0850

;************* ECM-Text-Modus  (ECM/BMM/MCM=1/0/0) **************

L420:						; *** G-ZUGRIFF ***
	MOV	SI,VMLI
	MOV	CH,VIC_PUFFER_0[SI]
	MOVZX	AX,VIC_PUFFER_1[SI]
	MOV	CL,3
	ROL	AX,CL
	OR	AL,RC
	OR	AH,G_ADRESSE
	MOV	SI,AX

	CMP	SI,01000H
	JL	L428
	CMP	SI,02000H
	JL	L426
	CMP	SI,09000H
	JL	L428
	CMP	SI,0A000H
	JL	L427
	JMP	L428
L426:
	MOV	ES,C64_ROM
	ADD	SI,0C000H
	JMP	L429
L427:
	MOV	ES,C64_ROM
	ADD	SI,04000H
	JMP	L429
L428:
	MOV	ES,C64_RAM
L429:
	MOV	AH,ES:[SI]
	MOV	ES,C64_RAM

	INC	VC
	AND	VC,0000001111111111B		; *** nach G-Zugriff Vic Register erhöhen ***
	INC	VMLI
	AND	VMLI,0000000000111111B

	MOV	CL,HF0				; *** BYTE AUSGEBEN ***
	MOV	AL,0
	MOV	DI,RZ_X
L430:
	SAL	AH,1				; *** (0) Hintergrund setzen ***
	JB	L435
	MOV	RZ[DI],CL
	INC	DI
	JMP	L440
L435:
	MOV	RZ[DI],CH			; *** (1) Vordergrund setzen ***
	INC	DI
L440:
	INC	AL
	CMP	AL,8
	JNE	L430
	MOV	RZ_X,DI
	JMP	L0850




L0800:
	MOV	DI,RZ_X
	MOV	AH,0
L0801:
	MOV	RZ[DI],2
	INC	DI
	INC	AH
	CMP	AH,8
	JNE	L0801
	MOV	RZ_X,DI







L0850:
	CMP	RZ_ZK,55			; *** in ZK 55 wird nur ein G-Zugriff gemacht ***
	JE	L01000

	CMP	C_MODE,1
	JNE	L01000

	MOV	SI,VC				; *** C-ZUGRIFF ***
	MOV	CL,ES:0D800H[SI]
	MOV	DI,VMLI
	MOV	VIC_PUFFER_0[DI],CL

	MOV	AX,VC
	OR	AH,C_ADRESSE
	MOV	SI,AX
	MOV	CL,ES:[SI]
	MOV	VIC_PUFFER_1[DI],CL
	JMP	L01000
L0900:						; *** Ausserhalb der g und c Zugriffe ***
	MOV	DI,RZ_X
	MOV	AH,0
L0950:
	MOV	CL,RF0				
	MOV	RZ[DI],CL			
	INC	DI
	INC	AH
	CMP	AH,8
	JNE	L0950
	MOV	RZ_X,DI
L01000:
;************************************** SPRITES ******************************************
	
	CMP	RZ_ZK,55			; *** In Zyklus 55 Vergleiche ob Sprite 0 eingeschaltet und an Y ist ***
	JNE	L01100
	MOV	AH,BYTE PTR RZ_Y[0]
	CMP	AH,Y_POS_0
	JNE	L01100
	MOV	AH,MXE
	AND	AH,00000001B
	JZ	L01100				; *** Nein Trift nicht zu ***
	MOV	DMA_0,1
						; *** Ja DMA Einschalten  ***
L01100:
	CMP	RZ_ZK,58
	JNE	L01110
	MOV	AH,MCBASE_0			; *** In Zyklus 58 MC mit MCBASE laden ***
	MOV	MC_0,AH	
	
	MOV	AH,BYTE PTR RZ_Y[0]
	CMP	AH,Y_POS_0			; *** Y=Rasterstrahl ? ***
	JNE	L01110				
	CMP	DMA_0,1				; *** DMA an ? ***
	JNE	L01110
	MOV	SON_0,1				; *** Spritedarstellung anschalten ***
L01110:
	CMP	RZ_ZK,60
	JNE	L01120
	MOV	BH,C_ADRESSE			; *** P Zugriffe immer jede Rasterzeile ***
	MOV	BL,0				; *** Sprite Nummer ***
	OR	BX,0000001111111000B		; *** Bit 3-9 mit 9 Auffüllen ***
	MOV	BH,ES:[BX]
	MOV	PDAT_0,AH
	CMP	DMA_0,1
	JNE	L01120
	
	INC	ZYKLEN				; *** 3 S Zugriffe ***
	XOR	BL,BL
	ROR	BX,1
	ROR	BX,1
	OR	BH,G_ADRESSE
	OR	BL,MC_0
	MOV	AH,ES:[BX]
	MOV	BYTE PTR SEQU_0[0],AH
	INC	BX
	MOV	AH,ES:[BX]
	MOV	BYTE PTR SEQU_0[1],AH
	INC	BX
	MOV	AH,ES:[BX]
	MOV	BYTE PTR SEQU_0[2],AH
	ADD	MC_0,3
L01120:
	MOV	CL,SF0
	CMP	SON_0,1
	JNE	L01500
	CMP	RZ_ZK,40
	JE	S110
	CMP	RZ_ZK,41
	JE	S210
	CMP	RZ_ZK,42
	JE	S310
	JMP	L01500
S110:
	MOV	AL,0
	MOV	DI,RZ_X
	SUB	DI,8
S120:
	SAL	BYTE PTR SEQU_0[0],1				; *** (0) Hintergrund setzen ***
	JB	S130
	INC	DI
	JMP	S140
S130:
	MOV	RZ[DI],CL					; *** (1) Vordergrund setzen ***
S135:
	INC	DI
S140:
	INC	AL
	CMP	AL,8
	JNE	S120
	INC	MCBASE_0
	JMP	L01500
S210:
	MOV	AL,0
	MOV	DI,RZ_X
	SUB	DI,8
S220:
	SAL	BYTE PTR SEQU_0[1],1				; *** (0) Hintergrund setzen ***
	JB	S230
	INC	DI
	JMP	S240
S230:

	MOV	RZ[DI],CL
S235:								; *** (1) Vordergrund setzen ***
	INC	DI
S240:
	INC	AL
	CMP	AL,8
	JNE	S220
	INC	MCBASE_0
	JMP	L01500
S310:
	MOV	AL,0
	MOV	DI,RZ_X
	SUB	DI,8
S320:
	SAL	BYTE PTR SEQU_0[2],1				; *** (0) Hintergrund setzen ***
	JB	S330
	INC	DI
	JMP	S340
S330:

	MOV	RZ[DI],CL					; *** (1) Vordergrund setzen ***
S335:
	INC	DI
S340:
	INC	AL
	CMP	AL,8
	JNE	S320
	INC	MCBASE_0
	JMP	L01500
L01500:
	CMP	RZ_ZK,16
	JNE	L01510
	CMP	MCBASE_0,63
	JNE	L01510
	MOV	MCBASE_0,0
	MOV	DMA_0,0
	MOV	SON_0,0
L01510:

;*****************************************************************************************
	
	INC	RZ_ZK
	CMP	RZ_ZK,62
	JNE	L03000				; *** wenn ja dann Rasterzeile darstellen (62)***

	MOV	RZ_X,0
	MOV	RZ_ZK,1

	BT	FLAGS_1,2
	JC	L02000

	MOV	SI,RZ_Y
	SHL	SI,1
	MOV	DI,V_RAM_ADRESSEN[SI]
	CMP	DI,64000
	JE	L02000
	
;********** für 320 * 200 *********

	CMP	CONFIG[7],1
	JE	L01520

	LEA	SI,RZ
	ADD	SI,120
	MOV	ES,ADR_VRAM
	MOV	CX,80
	REP MOVSD
	JMP	L02000
	
;**************************************

;********** für 360 * 480 ***********

L01520:
	MOV	DX,03C4H
	MOV	AX,0102H
	OUT	DX,AX
	
	LEA	SI,RZ
	ADD	SI,100
	MOV	ES,ADR_VRAM
	MOV	BX,90
	PUSH	DI
L0000100:
	MOV	AL,[SI]
	MOV	ES:[DI],AL
	ADD	SI,4
	INC	DI
	DEC	BX
	JNZ	L0000100
	POP	DI
	
	
	MOV	DX,03C4H
	MOV	AX,0202H
	OUT	DX,AX
	
	LEA	SI,RZ
	ADD	SI,100
	MOV	ES,ADR_VRAM
	MOV	BX,90
	ADD	SI,1
	PUSH	DI
L0000200:
	MOV	AL,[SI]
	MOV	ES:[DI],AL
	ADD	SI,4
	INC	DI
	DEC	BX
	JNZ	L0000200
	POP	DI
	
	
	MOV	DX,03C4H
	MOV	AX,0402H
	OUT	DX,AX
	
	LEA	SI,RZ
	ADD	SI,100
	MOV	ES,ADR_VRAM
	MOV	BX,90
	ADD	SI,2
	PUSH	DI
L0000300:
	MOV	AL,[SI]
	MOV	ES:[DI],AL
	ADD	SI,4
	INC	DI
	DEC	BX
	JNZ	L0000300
	POP	DI
	
	
	MOV	DX,03C4H
	MOV	AX,0802H
	OUT	DX,AX
	
	LEA	SI,RZ
	ADD	SI,100
	MOV	ES,ADR_VRAM
	MOV	BX,90
	ADD	SI,3
L0000400:
	MOV	AL,[SI]
	MOV	ES:[DI],AL
	ADD	SI,4
	INC	DI
	DEC	BX
	JNZ	L0000400
	

	

;**************************************

L02000:
	INC	RZ_Y
	CMP	RZ_Y,312
	JNE	L03000				; *** Hier ist immer ein Komplettes Bild Zu Ende ***

	BTR	FLAGS_1,0			; *** Wenn Sreenshot ja dann zu PCX_OUT Routiene ***
	JAE	L020010	
	CALL	CS:PCX_OUT
L020010:					; *** Wenn Performance Anzeige AN dann Ausgeben ***
	CMP	CONFIG[1],0
	JE	L02050
	CALL	CS:FPS

L02050:
	CMP	SCREEN_WAIT,1
	JNE	L02050
	MOV	SCREEN_WAIT,0


L02100:
	MOV	RZ_Y,0				
	MOV	DEN_STATUS,0
	MOV	VCBASE,0
	MOV	LP_TEST,0			; *** Lightpen wieder zulassen ***
L03000:
	CALL	CS:COUNT_TIMER_A
	DEC	ZYKLEN
	JNS	L000
	MOV	C_MODE,0
	
	RET
HALT:
	RET
;VIC_6569 ENDP



;****************************************
END
