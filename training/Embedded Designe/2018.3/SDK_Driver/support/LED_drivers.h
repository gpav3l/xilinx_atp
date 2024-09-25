/*
 * LED_drivers.h
 *
 *  Created on: May 4, 2016
 *      Author: williamk
 */

#include "xil_types.h"
#include "hardware_support.h"

#ifndef SRC_LED_DRIVERS_H_
#define SRC_LED_DRIVERS_H_

void LED_driver_Gaussian();
void LED_driver_select(int LEDid);

// set the number of LEDs available on the board (ZCU104 has 4 user LEDs)
#define NLEDS 4

// PS GPIOs have 2 channels, each of 32 bits. The LEDs are use channel 1, channel 2 is unused and therefore doesn't exist in hardware
#define LED_CHANNEL 1

#define NONE        0
#define SELECT      1
#define GAUSSIAN    2

#define INTENSITY99 0xFFFFFFFF
#define INTENSITY50 0x55555555
#define INTENSITY25 0x11111111
#define INTENSITY12 0x01010101
#define INTENSITY06 0x00010001
#define INTENSITY03 0x00000001
#define INTENSITY01 0x00000000
#define INTENSITY00 0x00000000

#endif /* SRC_LED_DRIVERS_H_ */
