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
.def	lastTrans = r18
.def	lastDir = r22

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ WTime = 100			; Time to wait in wait loop 
.def waitcnt = r19			; Wait Loop Counter
.def ilcnt = r20			; Inner Loop Counter
.def olcnt = r21			; Outer Loop Counter

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

.org	$0002					;- Left whisker
		rcall HitLeft
		reti

.org	$0004					;- Right whisker
		rcall HitRight
		reti

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

	ldi mpr, (0<<PD2)|(0<<WskrL)|(0<<WskrR)
	out DDRD, mpr
	ldi mpr, (1<<WskrL)|(1<<WskrR)
	out PORTD, mpr

	;USART1
	ldi mpr, high(832)
	sts UBRR1H, mpr
	ldi mpr, low(832) ;Set baudrate at 2400bps
	sts UBRR1L, mpr
	
	ldi mpr, (1<<U2X1)
	sts UCSR1A, mpr
	ldi mpr, (1<<RXEN1)|(1<<RXCIE1)|(0<<UCSZ12) ;Enable receiver and enable receive interrupts
	sts UCSR1B, mpr
	ldi mpr, (0<<UMSEL1)|(0<<UPM11)|(0<<UPM10)|(1<<USBS1)|(1<<UCSZ10)|(1<<UCSZ11) ;Set frame format: 8 data bits, 2 stop bits
	sts UCSR1C, mpr

	ldi lastTrans, $00
	ldi lastDir, $00
	
	sei	
		
	;External Interrupts
	ldi mpr, $03 ;Set the External Interrupt Mask
	out EIMSK, mpr
	ldi mpr, (1<<ISC11)|(0<<ISC10)|(1<<ISC01)|(0<<ISC00) ;Set the Interrupt Sense Control to falling edge detection
	sts EICRA, mpr

	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	;TODO: ???

	rjmp	MAIN
		

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;------------------------------------------------------------
;Receive
;------------------------------------------------------------
Receive:
				clr mpr
				clr data
				lds data, UDR1

checkHandshake: ldi mpr, BotAddress
				cp mpr, lastTrans
				brne end

checkMovFwd:	ldi mpr, 0b10110000
				cp data, mpr
				brne checkMovBck
				ldi mpr, MovFwd
				out PORTB, mpr
				ldi lastDir, MovFwd
				rjmp end

checkMovBck:	ldi mpr, 0b10000000
				cp data, mpr
				brne checkTurnR
				ldi mpr, MovBck
				out PORTB, mpr
				ldi lastDir, MovBck
				rjmp end

checkTurnR:		ldi mpr, 0b10100000
				cp data, mpr
				brne checkTurnL
				ldi mpr, TurnR
				out PORTB, mpr
				ldi lastDir, TurnL
				rjmp end

checkTurnL:		ldi mpr, 0b10010000
				cp data, mpr
				brne checkHalt
				ldi mpr, TurnL
				out PORTB, mpr
				ldi lastDir, TurnR
				rjmp end

checkHalt:		ldi mpr, 0b11001000
				cp data, mpr
				brne checkFutureUse
				ldi mpr, Halt
				out PORTB, mpr
				ldi lastDir, Halt
				rjmp end

checkFutureUse:	ldi mpr, 0b11111000
				cp data, mpr
				//brne end



end:			mov lastTrans, data
				reti
;------------------------------------------------------------
;Wait
;------------------------------------------------------------
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
;------------------------------------------------------------
;HitLeft
;------------------------------------------------------------
HitLeft:
			cli

			push mpr   ; Save mpr register
			push waitcnt   ; Save wait register
			in  mpr, SREG ; Save program state
			push mpr   ;

			ldi  mpr, MovBck ; Load Move Backward command
			out  PORTB, mpr ; Send command to port
			ldi  waitcnt, WTime ; Wait for 1 second
			rcall Wait   ; Call wait function

			ldi  mpr, TurnR ; Load Turn Left Command
			out  PORTB, mpr ; Send command to port
			ldi  waitcnt, WTime ; Wait for 1 second
			rcall Wait   ; Call wait function
			
			out PORTB, lastDir

			ldi mpr, 0b11111111 
			out EIFR, mpr ;pushes to register 
			
			rcall EmptyUSART
			
			pop  mpr  ; Restore program state
			out  SREG, mpr ;
			pop  waitcnt  ; Restore wait register
			pop  mpr  ; Restore mpr

			sei
leftEnd:	reti




;------------------------------------------------------------
;HitRight
;------------------------------------------------------------
HitRight:
			cli

			push mpr   ; Save mpr register
			push waitcnt   ; Save wait register
			in  mpr, SREG ; Save program state
			push mpr   ;

			ldi  mpr, MovBck ; Load Move Backward command
			out  PORTB, mpr ; Send command to port
			ldi  waitcnt, WTime ; Wait for 1 second
			rcall Wait   ; Call wait function

			ldi  mpr, TurnL ; Load Turn Left Command
			out  PORTB, mpr ; Send command to port
			ldi  waitcnt, WTime ; Wait for 1 second
			rcall Wait   ; Call wait function
			
			out PORTB, lastDir

			ldi mpr, 0b11111111 
			out EIFR, mpr ;pushes to register 
			
			rcall EmptyUSART
			
			pop  mpr  ; Restore program state
			out  SREG, mpr ;
			pop  waitcnt  ; Restore wait register
			pop  mpr  ; Restore mpr

			sei
rightEnd:	reti

;------------------------------------------------------------
;EmptyUSART
;------------------------------------------------------------
EmptyUSART:
			lds mpr, UCSR1A
			sbrs mpr, RXC1
			ret
			lds mpr, UDR1
			rjmp EmptyUSART	

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
