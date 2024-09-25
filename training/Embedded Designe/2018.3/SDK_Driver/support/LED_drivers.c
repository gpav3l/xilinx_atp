/*
 * LED_drivers.c
 *
 * Contains a number of different LED drivers for the Linear and Rosetta (future) patterns
 *
 *  Created on: May 4, 2016
 *      Author: williamk
 */

#include "LED_drivers.h"


/*** global variables ***/
u32 intensityTable[] = {INTENSITY99, INTENSITY50, INTENSITY25, INTENSITY12, INTENSITY06, INTENSITY03, INTENSITY01, INTENSITY00};
u32 LEDintensity[]   = {INTENSITY06, INTENSITY12, INTENSITY25, INTENSITY50, INTENSITY99, INTENSITY50, INTENSITY25, INTENSITY12};		// initialized to center on LED 4


/*
 * ***************************************************************************************
 *
 * LED_driver_Gaussian
 *
 * Used to drive LEDs according to the LEDintensity per LED.
 * Intensity is a 32 bit pattern where '1' represents the LED is on
 * A full "cycle" is 32 passes. Each cycle represents one bit position in the intensity value
 *
 * ***************************************************************************************
 */
void LED_driver_Gaussian() {
   // local variables
   u8  LEDimage = 0;							// 8 bit value where each bit corresponds to an LED
   u8  LEDid;									// loop variable identifying each LED
   u32 intensity;								// temporary variable holding the selected intensity for the LED
   u8  onOrOff;									// indicates whether this LED is on or off for this cycle
   static u8 cycleCount = 0;					// tracks which position out of the 32 positions is active

   cycleCount = (cycleCount+1) & 0x1F;			// 32 bit positions for presenting intensity
   for (LEDid=0; LEDid<NLEDS; LEDid++) {		// check each LED position
	   intensity = LEDintensity[LEDid];			// intensity for this particular LED
	   onOrOff = ((intensity & (1 << cycleCount)) != 0);	// is this position within the intensity field on or off?
	   LEDimage |= onOrOff << LEDid;			// build the pattern for all the LEDs
   }

   // set all the LEDs in a single write
   XGpio_DiscreteWrite(&GPIO_LEDs, LED_CHANNEL, LEDimage);

   // add a delay to reduce the overall intensity of the LEDs
	{
   u16 dely;
		for (delay=0; delay<4000; delay++);		// delay loop
	}
}

/*
 * ***************************************************************************************
 *
 * LED_driver_select(led#)
 *
 * Toggles the specific LED indicated (values 0-7)
 *
 * ***************************************************************************************
 */

void LED_driver_select(int LEDid) {
	static u8 LEDimage = 0;
	u8 mask = (1 << LEDid);
	u8 currentState = LEDimage & mask;
	if (currentState == 0) {			// it's currently off
		LEDimage |= mask;
	} else {							// it's currently on
		LEDimage &= ~mask;
	}

   // set all the LEDs in a single write
   XGpio_DiscreteWrite(&GPIO_LEDs, LED_CHANNEL, LEDimage);
}


