/*
* TemperatureSensor.c
*
* Created: 06/11/2017 11:19:21
* Author: GrzeWho, SherzadAli46, domenix
*/

#define F_CPU	10000000L

#include <avr/io.h>
#include <stdio.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include "atmega2560_drivers.h"
#include "hal.h"
#include "app.h"

uint8_t can_probe = 0;

int main(void)
{
	init_stdio(0, F_CPU);
	init_timer();
	hal_create();
	sei();

	uint8_t logging = 0;
	uint8_t leds = 0;
	double temperature = 0;
	
	while (1)
	{
		if (hal_is_pressed(0))
		{
			logging = 1;
		}
		if (hal_is_pressed(1))
		{
			logging = 0;
		}

		// If the can_probe variable is true, this will run,
		// we set that variable to true in the interrupt function,
		// and to false at the end of this statement.
		if (can_probe)
		{
			temperature = get_temperature();
			
			if (logging)
			{
				printf("%.3f\n", temperature);
			}

			// Calculate how many LEDs do we need for which exact degree
			leds = ceil((temperature-20)/2.5);

			set_led(leds);
			
			// Set the can_probe global variable to 0 again,
			// so the setting of the LEDs and the logging (if enabled)
			// does not happen constantly, only when the required time elapses.
			can_probe = 0;
		}
	}
}

// Interrupt vector which triggers when the timer reaches the top value
ISR(TIMER3_COMPA_vect)
{
	can_probe = 1;
}