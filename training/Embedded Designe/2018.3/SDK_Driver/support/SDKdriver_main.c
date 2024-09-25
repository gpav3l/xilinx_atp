/******************************************************************************
 * SDKintro_main.c
 *
 *  Created on: Apr 29, 2016
 *      Author: williamk
 ******************************************************************************
 *
 * Copyright (C) 2009 - 20164 Xilinx, Inc.  All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Use of the Software is limited solely to applications:
 * (a) running on a Xilinx device, or
 * (b) that interact with a Xilinx device through a bus or interconnect.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
 * OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Except as contained in this notice, the name of the Xilinx shall not be used
 * in advertising or otherwise to promote the sale, use or other dealings in
 * this Software without prior written authorization from Xilinx.
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <stdlib.h>				// for abs function
#include "platform.h"
#include "xil_types.h"
#include "hardware_support.h"
#include "utils_print.h"
#include "serialPort_helper.h"

#include "xparameters.h"
#include "LED_drivers.h"

// externally defined global variables
extern u32 intensityTable[];
extern u32 LEDintensity[];

/*
 * ***** main() *****
 */
int main()
{
	// initialize the platform and welcome the user
    init_platform();
    writeStr_NL("SDKintro test code starting...");

    // configure the hardware unique to this system (GPIOs, interrupt, timer)
    {
       u32 status;
       status = HWconfig();
       if (status != SUCCESS) {
    	   writeStr_NL("Failed to properly configure the hardware - quitting!");
    	   return status;
       }
    }

    // accept + or - to move the "center" of the LED pattern
    u8 userSelection;
    u8 centerOfPattern = 2;
    u8 distanceFromCenter;
    u8 LEDid;
    u8 mode = NONE;
    while (1 {
    	userSelection = getCharFromUART(0);
    	
   	if (userSelection == '+') {
   	    mode = GAUSSIAN;
   		if (++centerOfPattern >= 8) {  // move to the right and stick at right-hand limit
   			centerOfPattern = 7;
   			writeStr_NL("At high endpoint");
   		}
   	} else if (userSelection == '-') {
   		mode = GAUSSIAN;
   		if (--centerOfPattern == 255) { // move to the left and stick at left-hand limit
   			centerOfPattern = 0;
   			writeStr_NL("At low endpoint");
   		}
   	} else if ((userSelection >= '0') && (userSelection <= '7')) {
   		mode = SELECT;
   		LEDid = userSelection - '0';	// convert the character digit to a number
   	} else if ((userSelection == '\r') || (userSelection == '\n')) {
   		// consume with no message
   	} else {		// was some other character
   		writeStr_NL("illegal symbol - please use + or - or digit 1 through 4");
   	}
    	

    	// change the LEDs
    	if (mode == SELECT) {
    		LED_driver_select(LEDid);
    		mode = NONE;					// prevents future calls to this routine until a new character entered
    	} else if (mode == GAUSSIAN) {
    	    // determine the intensity for each LED
    	   	for (LEDid=0; LEDid<8; LEDid++) {
    	   		distanceFromCenter = abs(LEDid-centerOfPattern);
    	   		LEDintensity[LEDid] = intensityTable[distanceFromCenter];
    	   	}

    	   	// drive the LEDs
    		LED_driver_Gaussian();
    	}
    }

    cleanup_platform();
    return 0;
}







