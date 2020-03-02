;***********************************************************
;*
;*	Lab 8 Robot (Receiver)
;*
;*	Program receives instruction from the remote and instructs
;*  the robot to act according to received instructions
;*
;*
;***********************************************************
;*
;*	 Author: Owen Markley, Alex Molotkov, Sonia Camacho
;*	   Date: 3/1/19
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	data = r17

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ WTime = 100			; Time to wait in wait loop 
.def waitcnt = r20			; Wait Loop Counter
.def ilcnt = r18			; Inner Loop Counter
.def olcnt = r19			; Outer Loop Counter

.equ	BotAddress = $1A;(Enter your robot's address here (8 bits))

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

;.org	$0002					;- Left whisker
;		ldi mpr, (1<<0)
;		reti

;.org	$0004					;- Right whisker
;		ldi mpr, (1<<1)
;		reti

.org	$003C					;- USART1 receive
		rjmp Receive	
		

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi mpr, high(RAMEND)
	out sph, mpr
	ldi mpr, low(RAMEND)
	out spl, mpr

	;I/O Ports B out D in
	ldi mpr, (1<<EngEnL)|(1<<EngEnR)|(1<<EngDirR)|(1<<EngDirL)
	out DDRB, mpr
	ldi mpr, (0<<EngEnL)|(0<<EngEnR)|(0<<EngDirR)|(0<<EngDirL)
	out PORTB, mpr

	ldi mpr, (0<<WskrL)|(0<<WskrR)
	out DDRD, mpr
	ldi mpr, (1<<WskrL)|(1<<WskrR)
	out PORTD, mpr

	;USART1
	ldi mpr, $00 ;Set baudrate at 2400bps
	sts UBRR1L, mpr
	ldi mpr, $18
	sts UBRR1H, mpr

	ldi mpr, (1<<RXCIE1)|(1<<RXEN1)|(0<<UCSZ12) ;Enable receiver and enable receive interrupts
	sts UCSR1B, mpr
	ldi mpr, (0<<UMSEL1)|(0<<UPM11)|(0<<UPM10)|(1<<USBS1)|(1<<UCSZ10)|(1<<UCSZ11) ;Set frame format: 8 data bits, 2 stop bits
	sts UCSR1C, mpr

		
		
		
	;External Interrupts
	ldi mpr, $03 ;Set the External Interrupt Mask
	out EIMSK, mpr
	ldi mpr, (1<<ISC11)|(0<<ISC10)|(1<<ISC01)|(0<<ISC00) ;Set the Interrupt Sense Control to falling edge detection
	sts EICRA, mpr

	ldi mpr, 0b11111111
	out PORTB, mpr


	sei

	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	;TODO: ???
	
	;Receive:
	;	ldi mpr, UCSR1A
	;	rol mpr
	;	brcc next
	;	lds mpr, UDR1
	;	out PORTB, mpr
	;ldi waitcnt, WTime
	;ldi mpr, 0b11111111
	;out PORTB, mpr
	;rcall Wait
	;ldi mpr, 0b00000000
	;out PORTB, mpr
	;rcall Wait

	rjmp	MAIN
	
;	USART_Receive:
;		push	mpr
;		in		r17, UDR1
;		pop		mpr
		

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
Receive:
	ldi mpr, 0b00000000
	out PORTB, mpr

	;lds data, UDR1
	;out PORTB, data
	;rcall Wait

	;ldi mpr, 0b00000011 ; Write logical one to INT0 and INT1
	;out EIFR, mpr
	reti


Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine
;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
