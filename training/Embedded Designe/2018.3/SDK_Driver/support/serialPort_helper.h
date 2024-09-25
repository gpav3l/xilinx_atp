/*
 * serialPort_helper.h
 *
 *  Created on: May 3, 2016
 *      Author: williamk
 */

#ifndef SRC_SERIALPORT_HELPER_H_
#define SRC_SERIALPORT_HELPER_H_

#include "xparameters.h"
#ifdef MICROBLAZE
#include "xuartlite.h"
#else
#include "xuartps.h"
#include "xuartps_hw.h"
#endif

char getCharFromUART(int echo);
void putCharToUART(char c);

#endif /* SRC_SERIALPORT_HELPER_H_ */
