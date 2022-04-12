;****************************************
;*					*
;* Titel: EMU64 "Der C64 Emulator"	*
;* Autor: Thorsten Kattanek		*
;* Datum: 01/03/98			*
;* Ort  : Berlin			*
;* Vers : 1.00 Beta			*
;* Info : Diese Modul beinhaltet den	*
;*	  Kern des Emulators.		*
;*	  Hier wird der Emu vorbereitet *
;*	  und ordnungsgemäß beendet	*
;*	  Die anderen Module beinhalten *
;*	  die Einzelnen Baugruppen des  *
;*	  C64.				*
;*					*
;****************************************

; ************ Hier werden die Variablen gesetzt die in anderen Modulen sind ************

EXTRN	V_RAM_ADRESSEN:WORD,SCREEN_WAIT:BYTE						; Modul VIC6569
EXTRN	CPU_6510:NEAR,PC:WORD,SR:BYTE,I_FLAGS:BYTE,ABSTURZ_TST:BYTE			; Modul CPU6510
EXTRN	C64_TASTEN_1:BYTE,C64_TASTEN_2:BYTE						; Modul CIA1
EXTRN	PORT_A:BYTE,ZEIGER:WORD								; Modul CIA2
EXTRN	SOUND_RESET:PROC,SID_RESET:PROC,DSP_AN:PROC,DSP_AUS:PROC			; Modul SID
EXTRN   GR_READ_MODUS:PROC,GR_SET_MODUS:PROC,GR_MAUS_AN:PROC,GR_MAUS_AUS:PROC		; Modul GRAFIK
EXTRN	GUI:PROC,GUI_INIT:PROC,FILE_PUFFER:WORD						; Modul GBO
EXTRN	INTU_STATUS:BYTE								; Modul INTUIT

; ***** Hier werden alle Variablen gesetzt die in anderen Modulen gebraucht werden ******

PUBLIC	C64_RAM,C64_ROM,FARBEN_C64,ENDE
PUBLIC	V_MODUS_C64,V_MODUS_TXT,FARBEN_C64,SET_FARBEN,L015
PUBLIC  CHECK_KEY,ENDE,FLAGS_1,CONFIG,DSP_PUFFER
PUBLIC	V_MODUS_GUI,C64_GRAFIK_MODUS,RESET_1,C64_GRAFIK_MODUS,DOS_ERROR_TST


.MODEL SMALL
.STACK 300h
.DATA

;************************************ TEXTE sowie File Handler **************************
	
	; *** Belegung der Config Bytes ****
	; [0] Rahmen Emu 0=aus/1=an
	; [1] Franes Pro Sekunde (FPS) 0=aus/1=an
	; [2] Aktuelle Nummer des Screenshots
	; [3] X Auflösung der GUI
	; [5] Y Auflösung der GUI
	; [7] Grafikmodus 0=320*200 1=360*240
	; [8] Illegale Opcodes Ja/Nein 0=nein >0=ja 
	; [9] Grau oder Farbe 0=Farbe 1=Grau
	; [10] Timing 0=PAL 1=NTSC
	
	CONFIG		DB  	0,0,0
			DW      1024,768;
			DB	1,0FFH,0,0,0
			
	VESA_PUFFER	DB	100 DUP(0)
			
	T000		DB	10,13,176,177,178," EMU64 von Thorsten Kattanek V1.00 Beta ",178,177,176,10,13,"$"

	T004		DB	10,13,254," Speicher f",129,"r DSP Puffer... ","$"
	T005		DB	10,13,254," Speicher f",129,"r C64 RAM... ","$"
	T006		DB	10,13,254," Speicher f",129,"r C64 ROM... ","$"
	T007		DB	"OK !","$"
	T008		DB	"ERROR !","$"
	T009		DB	10,13,254," ",153,"ffne C64 Kernel ROM... ","$"
	T010		DB	10,13,254," ",153,"ffne C64 Basic ROM... ","$"
	T011		DB	10,13,254," ",153,"ffne C64 Char ROM... ","$"
	T012		DB	10,13,254," C64 Kernel geladen","$"
	T013		DB	10,13,254," C64 Basic geladen","$"
	T014		DB	10,13,254," C64 Charrom geladen","$"
	T016		DB	10,13,254," Programm ins Ram ab "
	T017		DB	10,13,254," Speicher f",129,"r C64 RAM wieder freigegeben !","$"
	T018		DB	10,13,254," Speicher f",129,"r C64 ROM wieder freigegeben !","$"
	T019		DB	10,13,10,13,"... By By ! ...",10,13,"$"
	T020		DB	10,13,254," Soundkarte... ","$"
	T021		DB	10,13,254," Joystick... ","$"
	T022		DB	10,13,254," Mouse... ","$"
        T023            DB      10,13,254," Speicher f",129,"r DSP Puffer wieder freigegeben !","$"
        T024		DB      10,13,254," Super VGA Grafikkarte... ","$"
	T025		DB	10,13,254," Speicher f",129,"r File Puffer... ","$"
	T026		DB	10,13,254," Speicher f",129,"r File Puffer wieder freigegeben !","$"
        T999		DB	10,10,13,"-- TASTE --","$"
	F00		DB	"KERNEL.ROM",0
	FH00		DW	0
	F01		DB	"Basic.rom",0
	FH01		DW	0
	F02		DB	"CHAR.ROM",0
	FH02		DW	0
	F03		DB	"EMU64.CFG",0
	FH03		DW	0
	FARBEN_C64 	DB 0,0,0,62,62,62,42,0,0,21,62,62,42,0,42,0,42,0,0,0,42,62,62,0,42,21,0,32,11,0,62,21,21,21,21,21,32,32,32,21,62,21,21,21,62,42,42,42
	GRAU_C64	DB 0,0,0,62,62,62,14,14,14,48,48,48,28,28,28,13,13,13,12,12,12,41,41,41,21,21,21,14,14,14,35,35,35,21,21,21,32,32,32,34,34,34,33,33,33,42,42,42
	FARBEN_FPS	DB 0,0,0,4,4,4,8,8,8,12,12,12,16,16,16,20,20,20,24,24,24,28,28,28,32,32,32,36,36,36,40,40,40,44,44,44,48,48,48,52,52,52,56,56,56,60,60,60,64,64,64,60,60,60,56,56,56,52,52,52,48,48,48,44,44,44,40,40,40,36,36,36,32,32,32,28,28,28,24,24,24,20,20,20,16,16,16,12,12,12,8,8,8,4,4,4

;***************************** PC Grafikeinstellungen ***********************************

	V_MODUS_ALT	DB 0
	V_MODUS_C64	DB 13H
	V_MODUS_TXT	DB 03H
	V_MODUS_GUI	DW 0

;**************************** Variablen und Hilfsregister *******************************

	DOS_ERROR_TST	DB	0
	C64_RAM		DW	0
	C64_ROM		DW	0
	DSP_PUFFER	DW	0

	PAL		DW	5D37H
	NTSC		DW	4DAEH

	FLAGS_1		DW 2			; *** Bit 0=1 Dann Scrennshot Bit 1=1 Dann Flip/FPS *** Bit 2=1 Dann keine Videoausgabe Bit 3=1 Sprung in GUI


;***************************************************************************************

.486
.CODE

;*************************** Installation vor der Emulation ****************************

START:
	JMP	START_00
START_00:
	MOV	DX,@DATA
	MOV	DS,DX

	MOV	AH,09H				; *** Programmname sowie Version und Autor ausgeben ***
	LEA	DX,T000
	INT	21H

	MOV   	BX,SS             		; *** Speicher neu setzen ***
        MOV   	AX,ES
        SUB   	BX,AX
        MOV   	AX,SP
        ADD   	AX,15
        SHR   	AX,4
        ADD   	BX,AX
        MOV   	AH,4AH
        INT   	21H

        MOV	AH,09H				; *** C64 RAM reservieren ***
        LEA	DX,T005
        INT	21H
        MOV  	BX,4096
        MOV  	AH,48H
        INT  	21H
        JNB  	L000

        MOV	AH,09H
        LEA	DX,T007
        INT	21H

        MOV	AH,4CH
        INT	21H
L000:
        MOV	C64_RAM,AX

        LEA	DX,T007
        MOV	AH,09H
        INT	21H

        MOV	AH,09H				; *** C64 ROM reservieren ***
	LEA	DX,T006
	INT	21H

       	MOV  	BX,4096
        MOV  	AH,48H
        INT  	21H
        JNB  	L0010

        MOV	AH,09H
        LEA	DX,T008
        INT	21H

        MOV	AH,4CH
        INT	21H
L0010:
        MOV	C64_ROM,AX
        
        LEA	DX,T007
        MOV	AH,09H
        INT	21H
        
        MOV	AH,09H				; *** DSP Puffer reservieren ***
	LEA	DX,T004
	INT	21H

       	MOV  	BX,32
        MOV  	AH,48H
        INT  	21H
        JNB  	L0015

        MOV	AH,09H
        LEA	DX,T008
        INT	21H

        MOV	AH,4CH
        INT	21H
L0015:
        MOV	DSP_PUFFER,AX
       
	LEA	DX,T007
        MOV	AH,09H
        INT	21H
        
        MOV	AH,09H				; *** File Puffer reservieren ***
	LEA	DX,T025
	INT	21H

       	MOV  	BX,4096
        MOV  	AH,48H
        INT  	21H
        JNB  	L0020

        MOV	AH,09H
        LEA	DX,T008
        INT	21H

        MOV	AH,4CH
        INT	21H
L0020:
	MOV	FILE_PUFFER,AX 
        
        LEA	DX,T007
        MOV	AH,09H
        INT	21H
             
        MOV	AH,09H				; *** C64 Kernel öffnen ***
        LEA	DX,T009
        INT	21H
        MOV  	AH,3DH
        MOV  	AL,0
        LEA  	DX,F00
        INT  	21H
        JB   	L0030
        MOV  	FH00,AX

        MOV	AH,09H
        LEA	DX,T007
        INT	21H

        JMP  	L0040
L0030:
        MOV  	AH,09H
        LEA  	DX,T008
        INT  	21H
        MOV	AH,4CH
        INT	21H
L0040:
	MOV	AH,09H				; *** Basic Rom öffnen
	LEA	DX,T010
	INT	21H

	MOV  	AH,3DH
        MOV  	AL,0
        LEA  	DX,F01
        INT  	21H
        JB   	L0050
        MOV  	FH01,AX

	MOV	AH,09H
	LEA	DX,T007
	INT	21H
        JMP  	L0060
L0050:
        MOV  	AH,09H
        LEA  	DX,T008
        INT  	21H

        MOV	AH,4CH
        INT	21H
L0060:
	MOV	AH,09H				; *** C64 Charrom öffnen ***
	LEA	DX,T011
	INT	21H

	MOV  	AH,3DH
        MOV  	AL,0
        LEA  	DX,F02
        INT  	21H
        JB   	L0070
        MOV  	FH02,AX

       	MOV	AH,09H
       	LEA	DX,T007
       	INT	21H

        JMP  	L0080
L0070:
        MOV  	AH,09H
        LEA  	DX,T008
        INT  	21H

        MOV	AH,4CH
        INT	21H    
L0080:
	MOV	AH,09H				; *** Kernelrom laden an $E000 ***
	LEA	DX,T012
	INT	21H

	MOV  	AH,3FH
        MOV  	BX,FH00
        MOV  	CX,8192
        MOV  	DX,0E000H
        PUSH 	DS
        MOV  	DS,C64_ROM
        INT  	21H
        POP  	DS

       	MOV	AH,09H				; *** Basicrom laden an $A000 ***
       	LEA	DX,T013
       	INT	21H

        MOV  	AH,3FH
        MOV  	BX,FH01
        MOV  	CX,8192
        MOV  	DX,0A000H
        PUSH 	DS
        MOV  	DS,C64_ROM
        INT  	21H
        POP  	DS

        MOV	AH,09H				; *** Charrom laden an $D000 ***
        LEA	DX,T014
        INT	21H

        MOV  	AH,3FH
        MOV  	BX,FH02
        MOV  	CX,8192
        MOV  	DX,0D000H
        PUSH 	DS
        MOV  	DS,C64_ROM
        INT  	21H
        POP  	DS

	MOV  	AH,3DH				; *** CFG öffnen ***
        MOV  	AL,0
        LEA  	DX,F03
        INT  	21H
        JB   	L0090				; *** Keine Datei dann weiter ***
        MOV  	FH03,AX

	MOV  	AH,3FH				; *** CFG lesen ***
        MOV  	BX,FH03
        MOV  	CX,12
        LEA  	DX,CONFIG
        INT  	21H
L0090:
	MOV  	AH,3CH				; *** CFG öffnen und leeren ***
        XOR	CX,CX
        LEA  	DX,F03
        INT  	21H
        MOV  	FH03,AX

	MOV	AH,09H				; *** Adlibkarte suchen ***
	LEA	DX,T020
	INT	21H
	
	CALL	SOUND_RESET			; *** Soundprozessor Reset ***
	JB	L0100				; *** Carry gesetzt SB OK !! ***

	MOV	AH,09H
	LEA	DX,T008
	INT	21H
	JMP	L0110
L0100:
	MOV	AH,09H
	LEA	DX,T007
	INT	21H
L0110:
	MOV	AH,09H				; *** Joystick suchen ***
	LEA	DX,T021
	INT	21H

	MOV	AH,84H
	MOV	DX,01H				; *** Unterfunktion Position Joystick ***
	INT	15H

	CMP	AX,0
	JNE	L0120
	CMP	BX,0
	JNE	L0120

	MOV	AH,09H
	LEA	DX,T008
	INT	21H

	JMP	L0130

L0120:
	MOV	AH,09H
	LEA	DX,T007
	INT	21H
L0130:
	MOV	AH,09H
	LEA	DX,T022
	INT	21H

	MOV	AX,00H				; *** Mouse Reset ***
	INT	33H
	CMP	AX,0FFFFH
	JE	L0140

	MOV	AH,09H
	LEA	DX,T008
	INT	21H

	JMP	ENDE_10
L0140:
	MOV	AH,09H
	LEA	DX,T007
	INT	21H

	MOV	AH,09H				; *** Nach Vesa Bios suchen ***
	LEA	DX,T024
	INT	21H
	
	LEA	DI,VESA_PUFFER
	CALL	GR_READ_MODUS
	JNC	L0150
	
	MOV	AH,09H
	LEA	DX,T008
	INT	21H
	
	JMP	ENDE_10
L0150:
	MOV	AH,09H
	LEA	DX,T007
	INT	21H
L0155:
	MOV	BX,WORD PTR CONFIG[3]		; *** Grafikmodus für GUI suchen ***
	MOV	CX,WORD PTR CONFIG[5]
	MOV	DI,0					
L0160:
	CMP	WORD PTR VESA_PUFFER[DI+2],BX	
	JE	L0170

	ADD	DI,6
	DEC	AX
	JZ	L0180
	JMP	L0160
L0170:
	CMP	WORD PTR VESA_PUFFER[DI+4],CX
	JE	L0190
	
	ADD	DI,6
	DEC	AX
	JZ	L0180
	JMP	L0160
L0180:
	MOV	WORD PTR CONFIG[3],640
	MOV	WORD PTR CONFIG[5],480
	JMP	L0155
L0190:
	MOV	AX,WORD PTR VESA_PUFFER[DI]	; *** Videomodus für GUI setzen **
	MOV	V_MODUS_GUI,AX

  	MOV	ES,C64_RAM
  	MOV	BYTE PTR ES:01,007H  		; *** Prozessorport beschreiben ***

	LEA	DX,T999
	MOV	AH,09H
	INT	21H
	
	MOV	AH,01H				; *** auf eine Taste warten ***
	INT	21H
L012:
	MOV	AH,0FH				; *** Videomodus sichern ***
	INT	10H
	
	MOV	V_MODUS_ALT,AL
	MOV	AH,25H				; Timer Interrupt 0H auf eigenen IRQ Handle (TIMER_IRQ)
	MOV	AL,08H
	PUSH	DS
	PUSH	CS
	POP	DS
	LEA	DX,TIMER_IRQ
	INT	21H
	POP	DS

	MOV	AH,25H				; Timer Interrupt 0H auf eigenen IRQ Handle (TIMER_IRQ)
	MOV	AL,24H
	PUSH	DS
	PUSH	CS
	POP	DS
	LEA	DX,DOS_ERROR
	INT	21H
	POP	DS

;***************************** Ab hier beginnt die emulation !! ************************

L013:
	CALL	GUI_INIT

	
	MOV	AL,INTU_STATUS
	AND	AL,00000010B
	JNZ	ENDE
	
	AND	INTU_STATUS,11111100B
	AND	FLAGS_1,1111111111110111B
	
	CALL	DSP_AN
	CALL	SET_FREQUENZ
	CALL	GR_MAUS_AUS
	CALL	C64_GRAFIK_MODUS
L015:
	CALL	CS:CPU_6510
	CMP	ABSTURZ_TST,0
	JNE	L020
	CLC
	BT	FLAGS_1,3
	JNC	L015
	
L020:
	CALL	DSP_AUS
	CALL	GUI

	
	MOV	AL,INTU_STATUS
	AND	AL,00000010B
	JNZ	ENDE
	
	AND	INTU_STATUS,11111100B
	AND	FLAGS_1,1111111111110111B

	CALL	DSP_AN
	CALL	SET_FREQUENZ
	CALL	GR_MAUS_AUS
	CALL	C64_GRAFIK_MODUS

	
	JMP	L015
;L020:
	;CALL	GUI
	
	;MOV	AL,INTU_STATUS
	;AND	AL,00000010B
	;JNZ	ENDE
	
	;AND	INTU_STATUS,11111100B
	;AND	FLAGS_1,1111111111110111B

	;CALL	GR_MAUS_AUS
	;CALL	C64_GRAFIK_MODUS
	
	;JMP	L015

;***************** Hier ist das Ende des EMU64 hier wird alles zurückgesetzt ************

ENDE:
	MOV	AH,42H
	MOV	AL,0
	MOV	BX,FH03
	XOR	CX,CX
	XOR	DX,DX
	INT	21H

	MOV  	AH,40H				; *** CFG schreiben ***
        MOV  	BX,FH03
        MOV  	CX,12
        LEA  	DX,CONFIG
        INT  	21H

        MOV	AH,3EH
        MOV	BX,FH03
        INT	21H

	CALL	SOUND_RESET
	MOV	AH,00H
	MOV	AL,V_MODUS_ALT
	INT	10H
ENDE_10:
	MOV	ES,C64_ROM			; *** Speicher freimachen ***
	MOV	AH,49H
	INT	21H
	MOV	AH,09H
	LEA	DX,T017
	INT	21H
	
	MOV	ES,C64_RAM			; *** Speicher freimachen ***
	MOV	AH,49H
	INT	21H
	MOV	AH,09H
	LEA	DX,T018
	INT	21H
	
	MOV	ES,DSP_PUFFER			; *** Speicher freimachen ***
	MOV	AH,49H
	INT	21H
	MOV	AH,09H
	LEA	DX,T023
	INT	21H

	MOV	ES,FILE_PUFFER			; *** Speicher freimachen ***
	MOV	AH,49H
	INT	21H
	MOV	AH,09H
	LEA	DX,T026
	INT	21H

	LEA	DX,T019				; *** Und Tschüss ***
	INT	21H
	
	;CALL	SOUND_OFF

	MOV	AH,4CH
	INT	21H

;************************************ Unterprogramme ************************************

SET_FREQUENZ:
	MOV	DX,043H				; Geschwindigkeit einstellen
	MOV	AL,036H
	OUT	DX,AL
	DEC	DX
	DEC	DX
	DEC	DX
	
	CMP	CONFIG[10],1
	JE	SF_10
	
	MOV	AL,37H
	OUT	DX,AL
	MOV	AL,5DH
	OUT	DX,AL
	RET
SF_10:	
	MOV	AL,0AEH
	OUT	DX,AL
	MOV	AL,4DH
	OUT	DX,AL
	RET
DOS_ERROR:
	PUSH	DX DS
	MOV	DX,@DATA
	MOV	DS,DX
	MOV	AL,3
	MOV	DOS_ERROR_TST,1
	POP	DS DX
	IRET
TIMER_IRQ:
	PUSH	DX DS
	MOV	DX,@DATA
	MOV	DS,DX
	MOV	SCREEN_WAIT,1
	POP	DS DX
	IRET

;************** Setzt die C64 Farben in die DAC Farbtabelle der VGA-Karte ***************

SET_FARBEN:

        PUSH 	AX
        MOV  	AH,10H
        MOV  	AL,12H
        PUSH 	DS
        POP  	ES
        POP  	DX
        MOV  	CX,255
        INT  	10H
        RET

;******* Diese Routiene Fragt die Funktionstasten für die Steuerung des EMUS ab *********

CHECK_KEY:

    	IN	AX,060H
	CMP	AL,01H
	JE	CH04				; ESC  EMU64 GUI
	CMP	AL,058H				; F12  EMU SOFTRESET
	JE	RESET
	CMP	AL,057H				; F11  Screen Drucken
	JNE	CH01
	OR	FLAGS_1,1
CH01:
	CMP	AL,52H				; -Einfg- C64 RESTORE Taste
	JE	RESTORE
	MOV	AH,01
	INT	16H
	JZ	CHECK_KEY_00
	DEC	AH
	INT	16H
	RET
CH04:
	OR	FLAGS_1,0000000000001000B

CHECK_KEY_00:
	RET
RESTORE:
	OR	I_FLAGS,00000001B
	RET


RESET:						; *** Softreset Routiene ***
	POP	AX BX CX DX
RESET_1:
	MOV	PORT_A,0			; *** FLOPPY REINSTALIEREN ***
	MOV	ZEIGER,0
	MOV	PC,0FCE2H
	MOV	ES,C64_RAM
	MOV	DI,7
RESET_000:
	MOV	C64_TASTEN_1[DI],0
	MOV	C64_TASTEN_2[DI],0FFH
	DEC	DI
	CMP	DI,0FFFFH
	JNE	RESET_000
	MOV	SR,00000100B
  	MOV	BYTE PTR ES:01,007H  		; *** Prozessorport beschreiben ***
	CALL	SOUND_RESET
	CALL	SID_RESET
	RET
	
C64_GRAFIK_MODUS:

	MOV	AX, 13H       
	INT	010H           
	
	CMP	CONFIG[7],0
	JE	CGM_10
	
	MOV	DX,03C4H			; *** Sequencer Register ***
	MOV	AX,00604H			; *** Disable Chain 4 Mode ***
	OUT	DX,AX         
	MOV	AX,00100H			; *** (A)synchronous Reset ***
	OUT	DX,AX         
	MOV	DX,03C2H			; *** VGA Misc Register ***
	MOV	AL,0E7H       			; *** Use 28Mhz Clock & 60Hz ***	
	OUT	DX,AL        
	MOV	DX,03C4H      			; *** Sequencer Register ***
	MOV	AX,00300H     			; *** Restart Sequencer ***
	OUT	DX,AX         
	MOV	DX,03D4H      			; *** VGA CrtC Registers ***
	MOV	AL,011H       			; *** CrtC register 11h ***
	OUT	DX,AL         			; *** Load current value ***
	INC	DX             			; *** Point to data ***
	IN	AL,DX         			; *** Get CrtC register 11h ***
	AND	AL,07FH       			; *** Mask out Write protect ***
	OUT	DX,AL         			; *** and send it back ***
	MOV	DX,03D4H      			; *** VGA CrtC Registers ***
	CLD                  			; *** Forward block load ***
	MOV	AX,06B00H     			; *** Horizontal total ***
	OUT	DX,AX         
	MOV	AX,05901H     			; *** Horizontal displayed ***
	OUT	DX,AX         
	MOV	AX,05A02H     			; *** Start horizontal blanking ***
	OUT	DX,AX         
	MOV	AX,08E03H     			; *** 8E - end horizontal blanking ***
	OUT	DX,AX         
	MOV	AX,05E04H     			; *** Start H sync. ***
	OUT	DX,AX         
	MOV	AX,08A05H     			; *** 8A - end H sync. *** 
	OUT	DX,AX         
	MOV 	AX,00D06H     			; *** Vertical total ***
	OUT	DX,AX         
	MOV	AX, 03E07H     			; *** Overflow 0011-1110 ***
	OUT	DX,AX        
	MOV	AX,04109H     			; *** Cell height  0100-0001 ***
	OUT	DX,AX        
	MOV	AX,0EA10H     			; *** V sync. start ***
	OUT	DX,AX         
	MOV	AX,0AC11H     			; *** V sync. end/Prot CR0 CR7 ***
	OUT	DX,AX      
	MOV	AX,0DF12H     			; *** Vertical displayed ***
	OUT	DX,AX         
	MOV	AX,02D13H     			; *** 2D offset       5A->180 40->128 ***
	OUT	DX,AX         
	MOV	AX,00014H     			; *** DWord mode off ***
	OUT	DX,AX        
	MOV	AX,0E715H     			; *** V Blank start ***
	OUT	DX,AX       
	MOV	AX,00616H     			; *** V Blank end ***
	OUT	DX,AX      
	MOV	AX,0E317H     			; *** Turn on Byte mode ***
	OUT	DX,AX      
	MOV	DX,03D4H      			; *** VGA CrtC Registers ***
	MOV	AL,011H       			; *** CrtC register 11h ***
	OUT	DX,AL         			; *** Load current value ***
	INC	DX             			; *** Point to data ***
	IN	AL,DX         			; *** Get CrtC register 11h ***
	OR	AL,080H       			; *** Mask *in* Write protect ***
	OUT	DX,AL         			; *** and send it back ***
	MOV	DX,03C4H         
	MOV	AX,0F02H        
	OUT	DX,AX            
	MOV	AX,0000H                  
	   
 	CALL	INIT_TBL_360
 	JMP	CGM_20
 CGM_10:	
 	CALL	INIT_TBL_320
 CGM_20:
 	CMP	CONFIG[9],0
 	JNE	CGM_30
 	LEA  	AX,FARBEN_C64     		; *** C64 Farbensetzen ***
        MOV	BX,0
        CALL 	CS:SET_FARBEN
        JMP	CGM_40
CGM_30:
 	LEA  	AX,GRAU_C64     		; *** C64 Farbensetzen ***
        MOV	BX,0
        CALL 	CS:SET_FARBEN	
CGM_40:
	CMP	CONFIG,1
	JNE	L015
        MOV     ES,C64_RAM                      ; *** C64 Rahmenfarbe setzen ***
	MOV	AH,BYTE PTR ES:0D020H
	AND	AH,00001111B
	MOV	DX,03C0H
	MOV	AL,11H OR 11110000B
	OUT	DX,AL
	MOV	AL,AH
	OUT	DX,AL
	RET


INIT_TBL_320:					; *** Tabellen Instalieren ***

	MOV	AX,64000
	MOV	DI,0

INIT_TBL_320_000:

	MOV	V_RAM_ADRESSEN[DI],AX
	INC	DI
	INC	DI
	CMP	DI,624
	JNE	INIT_TBL_320_000

	MOV	AX,0
	MOV	DI,0+33H*2

INIT_TBL_320_010:

	MOV	V_RAM_ADRESSEN[DI],AX
	ADD	AX,320				; *** Bei Videomodus 13 H muss 320 stehen ***
	INC	DI
	INC	DI
	CMP	DI,400+33H*2
	JNE	INIT_TBL_320_010
	RET
	
INIT_TBL_360:					; *** Tabellen Instalieren ***

	MOV	AX,64000
	MOV	DI,0

INIT_TBL_360_000:

	MOV	V_RAM_ADRESSEN[DI],AX
	INC	DI
	INC	DI
	CMP	DI,624
	JNE	INIT_TBL_360_000

	MOV	AX,0
	MOV	DI,0+1FH*2

INIT_TBL_360_010:

	MOV	V_RAM_ADRESSEN[DI],AX
	ADD	AX,90				; *** Bei Videomodus 13 H muss 320 stehen ***
	INC	DI
	INC	DI
	CMP	DI,480+20H*2
	JNE	INIT_TBL_360_010
	RET

;****************************************************************************************

END
