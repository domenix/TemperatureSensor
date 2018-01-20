#include <avr/io.h>
#include <stdint.h>
#include "hal.h"

void init_timer()
{
	// Set up timer in CTC mode, top is calculated
	// using the formula used in the AVR130 Application Note,
	// page 11, section 4.1, or more precisely, but not using
	// the exact formula in the datasheet of the ATmega2560
	// microcontroller, on page 146, section 17.9.2.
	
	// T = (Prescaler*(TOP+1))/F_CPU
	
	// Used TIMER3, because TIMER1 and TIMER2 was interfering
	// with the library managing the serial connection.
	
	// Prescaler: 64
	// Mode: CTC
	// Immediate: 31249
	
	TCCR3B |= (1 << CS31) | (1 << CS30) | (1 << WGM32);
	OCR3A = 31249;
	TIMSK3 |= (1 << OCIE3A);
}

void set_led(uint8_t leds)
{
	// Check for edge cases
	if (leds < 0)
	{
		leds = 0;
	}
	
	if (leds > 8)
	{
		leds = 8;
	}
	
	for (int i = 0; i < 8; i++)
	{
		// Checks if it should turn on the LEDs or off
		if (leds - i > 0)
		{
			hal_set_led(i, 1);
		}
		else
		{
			hal_set_led(i, 0);
		}
	}
}

double get_temperature()
{
	// Compensate for 1.1 V offset and calculate
	// the correct temperature from the adjusted voltage
	// in millivolts to °C.
	return ((hal_get_adc_value()*1.1)/1024)*1000/20;
}