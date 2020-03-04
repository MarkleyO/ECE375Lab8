;***********************************************************
;*
;* Enter Name of file here
;*
;* Enter the description of the program here
;*
;* This is the TRANSMIT skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*  Author: Enter your name
;*    Date: Enter Date
;*
;***********************************************************
.include "m128def.inc"   ; Include definition file
;***********************************************************
;* Internal Register Definitions and Constants
;***********************************************************
.def mpr = r16    ; Multi-Purpose Register
.def    data = r17    ; Data to transmit via USART
.def waitcnt = r23    ; Wait Loop Counter
.def ilcnt = r24    ; Inner Loop Counter
.def olcnt = r25    ; Outer Loop Counter
.equ EngEnR = 4    ; Right Engine Enable Bit
.equ EngEnL = 7    ; Left Engine Enable Bit
.equ EngDirR = 5    ; Right Engine Direction Bit
.equ EngDirL = 6    ; Left Engine Direction Bit
.equ Button0 = 4    
.equ Button1 = 5    
.equ Button2 = 6    
.equ Button3 = 7    
.equ WTime = 100    ; Time to wait in wait loop
.equ robotID = $1A   ; Robot ID for this robot
; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1)) ;0b10110000 Move Forward Action Code
.equ MovBck =  ($80|$00)						   ;0b10000000 Move Backward Action Code
.equ TurnR =   ($80|1<<(EngDirL-1))				   ;0b10100000 Turn Right Action Code
.equ TurnL =   ($80|1<<(EngDirR-1))                ;0b10010000 Turn Left Action Code
.equ Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))   ;0b11001000 Halt Action Code

;***********************************************************
;* Start of Code Segment
;***********************************************************
.cseg       ; Beginning of code segment
;***********************************************************
;* Interrupt Vectors
;***********************************************************
.org $0000     ; Beginning of IVs
  rjmp  INIT   ; Reset interrupt
.org $0046     ; End of Interrupt Vectors
;***********************************************************
;* Program Initialization
;***********************************************************
INIT:
 ;Stack Pointer (VERY IMPORTANT!!!!)
  ldi  mpr, low(RAMEND)
  out  SPL, mpr  ; Load SPL with low byte of RAMEND
  ldi  mpr, high(RAMEND)
  out  SPH, mpr  ; Load SPH with high byte of RAMEND
 ;I/O Ports
  ;Initialize Port B for output
  ldi mpr, 0b11111111
  out DDRB, mpr ; Set the DDR register for Port B
  ldi mpr, $00
  out PORTB, mpr
  ; Initialize Port D for input
  ldi mpr, (1<<PD3) | (0<<Button0) | (0<<Button1) | (0<<Button2) | (0<<Button3)
  out DDRD, mpr ; Set the DDR register for Port D
  ldi mpr, (1<<Button0)|(1<<Button1)|(1<<Button2)|(1<<Button3)
  out PORTD, mpr


 ;USART1
  ;Initalize USART1
  ldi mpr, (1<<U2X1) ; Set double data rate
  sts UCSR1A, mpr
  ;Set baudrate at 2400bps
  ldi mpr, high(832) ; Load high byte of baudrate
  sts UBRR1H, mpr ; UBRR01 in extended I/O space
  ldi mpr, low(832) ; Load low byte of baudrate
  sts UBRR1L, mpr
  
  ; Set frame format: 8 data, 2 stop bits, asynchronous
  ldi mpr, (0<<UMSEL1 | 1<<USBS1 | 1<<UCSZ11 | 1<<UCSZ10)
  sts UCSR1C, mpr ; UCSR0C in extended I/O space
  
  ; Enable transmitter
  ldi mpr, (1<<TXEN1)
  sts UCSR1B, mpr
  sei ; Enable global interrupt
 ;Other
;***********************************************************
;* Main Program
;***********************************************************
MAIN:
  in mpr, PIND

  cpi mpr, 0b11011111
  brne NEXT
  rcall moveForward
NEXT:

  cpi mpr, 0b10111111
  brne NEXT2
  rcall moveBackward
NEXT2:

  cpi mpr, 0b01111111
  BRNE NEXT3
  rcall moveLeft
NEXT3:
  
  cpi mpr, 0b11101111
  BRNE NEXT4
  rcall moveRight
NEXT4:

  rjmp MAIN
  
;***********************************************************
;* Functions and Subroutines
;***********************************************************

moveForward:
  ldi mpr, 0b00100000
  out PORTB, mpr

//Transmit robotid
USART_Transmit_fwd1:
  lds mpr, UCSR1A ; Loop until UDR1 is empty
  sbrs mpr, UDRE1
  rjmp USART_Transmit_fwd1
  ldi  data, robotID
  sts UDR1, data ; Move data to transmit data buffer

//Transmit move code
USART_Transmit_fwd2:
  lds mpr, UCSR1A ; Loop until UDR1 is empty
  sbrs mpr, UDRE1
  rjmp USART_Transmit_fwd2
  ldi  data, MovFwd
  sts UDR1, data ; Move data to transmit data buffer
ret



moveBackward:
  ldi mpr, 0b01000000
  out PORTB, mpr

//Transmit robotid
USART_Transmit_bwd1:
  lds mpr, UCSR1A ; Loop until UDR1 is empty
  sbrs mpr, UDRE1
  rjmp USART_Transmit_bwd1
  ldi  data, robotID
  sts UDR1, data ; Move data to transmit data buffer

//Transmit move code
USART_Transmit_bwd2:
  lds mpr, UCSR1A ; Loop until UDR1 is empty
  sbrs mpr, UDRE1
  rjmp USART_Transmit_bwd2
  ldi  data, MovBck
  sts UDR1, data ; Move data to transmit data buffer
ret

moveLeft:
  ldi mpr, 0b10000000
  out PORTB, mpr

//Transmit robotid
USART_Transmit_lft1:
  lds mpr, UCSR1A ; Loop until UDR1 is empty
  sbrs mpr, UDRE1
  rjmp USART_Transmit_lft1
  ldi  data, robotID
  sts UDR1, data ; Move data to transmit data buffer

//Transmit move code
USART_Transmit_lft2:
  lds mpr, UCSR1A ; Loop until UDR1 is empty
  sbrs mpr, UDRE1
  rjmp USART_Transmit_lft2
  ldi  data, TurnL
  sts UDR1, data ; Move data to transmit data buffer
ret


moveRight:
  ldi mpr, 0b00010000
  out PORTB, mpr

//Transmit robotid
USART_Transmit_rht1:
  lds mpr, UCSR1A ; Loop until UDR1 is empty
  sbrs mpr, UDRE1
  rjmp USART_Transmit_rht1
  ldi  data, robotID
  sts UDR1, data ; Move data to transmit data buffer

//Transmit move code
USART_Transmit_rht2:
  lds mpr, UCSR1A ; Loop until UDR1 is empty
  sbrs mpr, UDRE1
  rjmp USART_Transmit_rht2
  ldi  data, TurnR
  sts UDR1, data ; Move data to transmit data buffer
ret

;----------------------------------------------------------------
; Sub: Wait
; Desc: A wait loop that is 16 + 159975*waitcnt cycles or roughly
;  waitcnt*10ms.  Just initialize wait for the specific amount
;  of time in 10ms intervals. Here is the general eqaution
;  for the number of clock cycles in the wait loop:
;   ((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;----------------------------------------------------------------
Wait:
  push waitcnt   ; Save wait register
  push ilcnt   ; Save ilcnt register
  push olcnt   ; Save olcnt register
Loop: ldi  olcnt, 224  ; load olcnt register
OLoop: ldi  ilcnt, 237  ; load ilcnt register
ILoop: dec  ilcnt   ; decrement ilcnt
  brne ILoop   ; Continue Inner Loop
  dec  olcnt  ; decrement olcnt
  brne OLoop   ; Continue Outer Loop
  dec  waitcnt  ; Decrement wait
  brne Loop   ; Continue Wait loop 
  pop  olcnt  ; Restore olcnt register
  pop  ilcnt  ; Restore ilcnt register
  pop  waitcnt  ; Restore wait register
  ret    ; Return from subroutine
;***********************************************************
;* Stored Program Data
;***********************************************************
;***********************************************************
;* Additional Program Includes
;***********************************************************
