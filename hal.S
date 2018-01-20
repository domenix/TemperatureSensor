#include <avr/io.h>

.GLOBAL hal_create
.GLOBAL hal_set_led
.GLOBAL hal_is_pressed
.GLOBAL hal_get_adc_value

; hal_create function implementation
hal_create:
	PUSH R16
	LDI R16, 0xFF					; Set the direction of the PORTB as output,
	STS DDRB, R16					; and turn all the LEDs off (active low operation).
	STS PORTB, R16					;

	LDI R16, 0x00					; Set the direction of the PORTA as input.
	STS DDRA, R16					;

	LDI R16, 0x80					; Set up the ADC.
	STS ADMUX, R16					;
	LDI R16, 0x86					;
	STS ADCSRA, R16					;

	POP R16
	RET

; hal_set_led function implementation
hal_set_led:
	PUSH R16
	PUSH R17

	LDS R16, PORTB					; Read the status of the PORTB.
	LDI R17, 0x01					; Write 0x01 to the R17 that can be shifted to the left.

	CPI R22, 0						; Check if the desireed state is 0 or not,
	BREQ hal_set_led_loop			; if yes, then skip to the loop,
	LDI R22, 0xFF					; if not, then set all bits to 1.

hal_set_led_loop:					; Shift R17 to the left until R24 reaches zero.
	RJMP hal_set_led_condition		;
hal_set_led_body:					;
	ROL R17							;
	DEC R24							;
hal_set_led_condition:				;
	CPI R24, 0						;
	BRNE hal_set_led_body			;

	; Perform boolean calculation while taking into account the LED's active low operation.
	; Calculation of the formula can be seen in the attached PDF.

	; A: PORTB (R16)
	; B: Set register (R17)
	; C: Control register (R22)
	; Y = (¬CB)*(¬BA)

	COM R22							; Turn C to ¬C
	AND R22, R17					; ¬CB

	COM R17							; Turn B to ¬B
	AND R16, R17					; ¬BA

	OR R16, R22						; (¬CB)*(¬BA)

	STS PORTB, R16					; Set the value of the LEDs to the logical expression.

	POP R17
	POP R16
	RET

; hal_is_pressed function implementation
hal_is_pressed:
	PUSH R16
	PUSH R17

	LDS R16, PINA					; Read the state of the switches (active low operation).
	COM R16							;
	LDI R17, 0x01					; Write 0x01 to the R17 that can be shifted to the left.

hal_is_pressed_loop:				; Shift R17 to the left until R24 reaches zero.
	RJMP hal_is_pressed_condition	;
hal_is_pressed_body:				;
	ROL R17							;
	DEC R24							;
hal_is_pressed_condition:			;
	CPI R24, 0						;
	BRNE hal_is_pressed_body		;

	; The way to check whether the two registers are equal is to perform an or on them,
	; then compare the result with the registers that contains the pressed down buttons.
	; This ensures that the subroutine will return true even if other buttons are pressed
	; apart from the one it is actually checking.

	LDI R24, 0x00					; Default return value is 0.
	OR R17, R16						; If the switch state register and the check register
	CP R16, R17						; are equal to each other, then set the return value to 1 (true).
	BRNE hal_is_pressed_skip		; Otherwise, skip the setting instruction.
	LDI R24, 0x01

hal_is_pressed_skip:
	LDI R25, 0x00

	POP R17
	POP R16
	RET

; hal_get_adc_value function implementation
hal_get_adc_value:
	PUSH R16

	LDS R16, ADCSRA					; Load the value from ADCSRA,
	ORI R16, (1 << ADSC)			; then set bit 6,
	STS ADCSRA, R16					; and set ADCSRA back to this value.

hal_get_adc_value_loop:				; Loop until bit 6 of ADCSRA is not zero
	LDS R16, ADCSRA					;
	SBRC R16, ADSC					;
	RJMP hal_get_adc_value_loop		;

	LDS R24, ADCL					; Load the values read from the ADC input
	LDS R25, ADCH					; to the registers holding the return value.

	POP R16
	RET