;***********************************************************
;*
;*	Filename: Chalida_Ruangrotsakun_and_Tristan_Luther_Lab4_challangecode.asm
;*
;*	Description: When PD0 is pressed Chalida is Written on the first line 
;*  & Tristan is written on the second line of an LCD. When you press PD1 
;*  the lines swap. When you press PD7 the lines are cleared. When PD6 is 
;*  pressed the text begins to scroll to the left and when PD5 is pressed
;*  the text scrolls to the right
;*
;*	This is the source code file for Lab 4 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Chalida Ruangrotsakun & Tristan Luther
;*	   Date: 1/25/2020
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is
								; required for LCD Driver
.def	ilcnt = r24				; Inner Loop Counter
.def	olcnt = r25				; Outer Loop Counter
.def	lcdwidth = r23			; Counter register

.equ	WTime = 35				; Time to wait in wait loop

.equ	writebtn = 0			; Write to LCD Button Input Bit
.equ	swpbtn = 1				; Swap the text Button Input Bit
.equ	rightbtn = 5			; Scroll Right Button Input Bit
.equ	leftbtn = 6				; Scroll Left Button Input Bit
.equ	clrbtn = 7				; Clear the screen Button Input Bit

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND

		; Initialize LCD Display
		rcall	LCDInit

		; Initialize Port D for Input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; Move strings from Program Memory to Data Memory
		ldi		lcdwidth, LCDMaxCnt ; Width of the LCD & Message 
		ldi		ZH, high(NAME_ONE_BEG<<1) ; Initialize the Z pointer with Name One
		ldi		ZL, low(NAME_ONE_BEG<<1)

		ldi		YL, low(LCDLn1Addr)	; Write the data address to the Y-regsiter
		ldi		YH, high(LCDLn1Addr) 
		
RDLPA:	lpm		mpr, Z+ ; Loop though the entire LCD width and place the message bytes
		st		Y+, mpr
		dec		lcdwidth
		brne	RDLPA

		; Load the next word into the second line
		ldi		lcdwidth, LCDMaxCnt ; Restore the LCD width
		ldi		ZH, high(NAME_TWO_BEG<<1) ; Initialize the Z pointer with Name Two
		ldi		ZL, low(NAME_TWO_BEG<<1)

		ldi		YL, low(LCDLn2Addr) ; Initialize the data address
		ldi		YH, high(LCDLn2Addr)

RDLPB:	lpm		mpr, Z+ ; Loop though the entire LCD width and place the message bytes
		st		Y+, mpr
		dec		lcdwidth
		brne	RDLPB

		; NOTE that there is no RET or RJMP from INIT, this
		; is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		; Display the strings on the LCD Display
		;rcall LCDWrite
		in		mpr, PIND		; Get button input from Port D
		andi	mpr, (1<<writebtn) ; Check for write button input (Recall Active Low)
		brne	NEXTONE				; Branch if the button was not pressed
		rcall	LCDWrite				; Call the WRITE subroutine
		rjmp	MAIN				; Go back to the top of MAIN
NEXTONE: in		mpr, PIND			; Get the status of PIND
		andi	mpr, (1<<swpbtn)	; Check the swap button input
		brne	NEXTTWO			; No input, continue program
		rcall	SWAPLINE			; Call subroutine SWAPLINE
		rcall	LCDWrite		; Write the new data to the LCD
		ldi		mpr, WTime	; Wait for 1 second
		rcall	Delay			; Call wait function
		rjmp	MAIN			; Continue through main
NEXTTWO: in		mpr, PIND	; Check the button input
		andi	mpr, (1<<rightbtn) ; Check the right scroll btn
		brne	NEXTTHREE	; Brnach to the next check if not 0
		rcall	SCROR		; Call the right scroll function
		rjmp	MAIN		; Go back to the top
NEXTTHREE: in	mpr, PIND	; Check PIND
		andi	mpr, (1<<leftbtn) ; Get the left button input status
		brne	NEXTFOUR	; Branch to the next check if not 0
		rcall	SCROL		; Call the scroll left function
		rjmp	MAIN		; Jump back to the top
NEXTFOUR: in	mpr, PIND		; Get the PIND status
		andi	mpr, (1<<clrbtn) ; Check the clear button input
		brne	MAIN			; Branch back to MAIN if no buttons pressed
		rcall	LCDClear		; Call subroutine CLEAR
		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: SWAPLINE
; Desc: This function will swap the txt lines on the LCD
;		screen
;-----------------------------------------------------------
SWAPLINE:							; Beginning of function with a label SWAPLINE
		; Save variables by pushing them to the stack
		push	mpr ; Save the mpr register
		in		mpr, SREG ; Save the program state
		push	mpr	;
		; Execute the function here
		ldi		lcdwidth, 16 ; Width of the LCD & Message 

		ldi		XH, high(LCDLn1Addr) ; Load in the first line
		ldi		XL, low(LCDLn1Addr)

		ldi		YH, high(LCDLn2Addr) ; Load in the second line 
		ldi		YL, low(LCDLn2Addr)

CYCLE:	ld		mpr, X ; Store the x pointer to mpr
		ld		r24, Y ; Store the y pointer to r24
		st		X+, r24 ; Swap the bits in-place
		st		Y+, mpr
		dec		lcdwidth ; Until the lcd width is complete
		brne	CYCLE


		; Restore variables by popping them from the stack,
		; in reverse order
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		mpr		; Restore mpr

		ret						; End of function with RET

;-----------------------------------------------------------
; Func: SCROL
; Desc: This function will scroll the txt lines on the LCD
;		screen to the left
;-----------------------------------------------------------
SCROL:				; Beginning of function with a label SCROL
	; Save variables by pushing them to the stack
	push	mpr ; Save the mpr register
	in		mpr, SREG ; Save the program state
	push	mpr	;
	push	r15
	push	r24
	push	r25
	; Function is preformed below
	ldi		lcdwidth, 15 ; Width of the LCD & Message - 1

	ldi		ZH, high(LCDLn1Addr) ; Store the address of LCD line 1 into the X pointer
	ldi		ZL, low(LCDLn1Addr)  
	ld		r15, Z+				 ; Store the first location of Z into r15

	ldi		YH, high(LCDLn2Addr) ; Store the address of LCD line 2 into the Y pointer
	ldi		YL, low(LCDLn2Addr)
	ld		r25, Y+				 ; Store the first location of Y into r25

; Loop 15 times
CYCLE2: ld		mpr, Z ; Load in whatever z is pointing to 
		ld		r24, Y ; Load in whatever y is pointing to
		st		-Z, mpr ; Store the contents of z back one pointer location (Z-1)
		st		-Y, r24 ; Store the contents of y back one pointer location (Y-1)
		adiw	ZH:ZL,2 ; Add two to the Z pointer to go to the next location (Z+1)
		adiw	YH:YL,2 ; Add two to the Y pointer to go to the next location (Y+1) 
		dec		lcdwidth ; Decrement the counter to keep track of the location in the Z,Y pointers we are at
		brne	CYCLE2 ; When we have gone though all of characters in the LCD exit loop

	st		-Y, r25 ; Place the first character of Y into the end of the Y+15 pointer
	st		-Z, r15 ; Place the first character of Z into the end of the Z+15 pointer

	ldi		mpr, WTime	; Wait for 1 second
	rcall	Delay			; Call wait function
	rcall	LCDWrite    ; Write the modified result to the screen
	; Restore variables by popping them from the stack,
	; in reverse order
	pop		r25
	pop		r24
	pop		r15
	pop		mpr		; Restore program state
	out		SREG, mpr	;
	pop		mpr		; Restore mpr
	ret				; End of function with RET

;-----------------------------------------------------------
; Func: SCROR
; Desc: This function will scroll the txt lines on the LCD
;		screen to the right
;-----------------------------------------------------------
SCROR:				; Beginning of function with a label SCROR
	; Save variables by pushing them to the stack
	push	mpr ; Save the mpr register
	in		mpr, SREG ; Save the program state
	push	mpr	;
	push	r15
	push	r24
	push	r25
	; Function is preformed below
	; Function is preformed below
	ldi		lcdwidth, 15 ; Width of the LCD & Message - 1

	ldi		ZH, high(LCDLn1Addr) ; Store the address of LCD line 1 into the X pointer
	ldi		ZL, low(LCDLn1Addr)  
	adiw	ZH:ZL, 15      ; Point to the end of the Z pointer
	ld		r15, Z				 ; Store the last location of Z into r15

	ldi		YH, high(LCDLn2Addr) ; Store the address of LCD line 2 into the Y pointer
	ldi		YL, low(LCDLn2Addr)
	adiw	YH:YL, 15		 ; Point to the end of the Y pointer
	ld		r25, Y				 ; Store the last location of Y into r25

; Loop 15 times
CYCLE3: ld		mpr, -Z ; Load in whatever z is pointing to 
		ld		r24, -Y ; Load in whatever y is pointing to
		adiw	ZH:ZL, 1 ; Add 1 to Z
		adiw	YH:YL, 1 ; Add 1 to Y
		st		Z, mpr ; Store the contents of z back one pointer location (Z+1)
		st		Y, r24 ; Store the contents of y back one pointer location (Y+1)
		sbiw	ZH:ZL,1 ; Subtract two to the Z pointer to go to the next location (Z-1)
		sbiw	YH:YL,1 ; Subtract two to the Y pointer to go to the next location (Y-1) 
		dec		lcdwidth ; Decrement the counter to keep track of the location in the Z,Y pointers we are at
		brne	CYCLE3 ; When we have gone though all of characters in the LCD exit loop

	st		Y, r25 ; Place the last character of Y into the beginning of the Y-15 pointer
	st		Z, r15 ; Place the last character of Z into the beginning of the Z-15 pointer

	ldi		mpr, WTime	; Wait for 1 second
	rcall	Delay			; Call wait function
	rcall	LCDWrite    ; Write the modified result to the screen
	; Restore variables by popping them from the stack,
	; in reverse order
	pop		r25
	pop		r24
	pop		r15
	pop		mpr		; Restore program state
	out		SREG, mpr	;
	pop		mpr		; Restore mpr
	ret				; End of function with RET
;----------------------------------------------------------------
; Func:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly 
;		waitcnt*10ms.  Just initialize wait for the specific amount 
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Delay:
		push	mpr			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		mpr		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		mpr		; Restore wait register
		ret				; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; Storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------

NAME_ONE_BEG:
.DB		"Chalida         "		; Declaring data in ProgMem
NAME_ONE_END:

NAME_TWO_BEG:
.DB		"Tristan         "		; Declaring data in ProgMem
NAME_TWO_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver



