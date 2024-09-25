/*
 * serialPort_helper.c
 *
 *  Created on: May 3, 2016
 *      Author: williamk
 */

#include "serialPort_helper.h"

// allows either MICROBLAZE or __MICROBLAZE__ to activate the MicroBlaze code
#ifdef MICROBLAZE
#define __MICROBLAZE__
#endif

#ifdef __MICROBLAZE__
#include "xuartlite_l.h"
#endif

/*
 * getCharFromUART() for Zynq
 *
 * note that UART1 is in the PS and has a fixed address
 *
 * History: WK 25 SEP 2013
 */

// constants defining the use of the UART (registers listed in TRM B.33)
//
// buffers for the UART
#define UART_BUFFER_SIZE 64
unsigned char sendBuffer[UART_BUFFER_SIZE];  // Buffer for Transmitting Data
unsigned char recvBuffer[UART_BUFFER_SIZE];  // Buffer for Receiving Data


//*********************** Functions for Using the PS UART *************************************

char getCharFromPSUART(int echo) {
	   static int      read_ptr  = 0;
	   static int      write_ptr = 0;
	   static int      volume    = 0;
	   unsigned char   c;                           // generic character variable
	   //unsigned long   *UART_read_addr  = 0;        // pointer directly to UART read  register
	   //unsigned long   *UART_write_addr  = 0;       // pointer directly to UART write register


	   // point to the specific location in memory where the UART should read from
	  // UART_read_addr = UART_write_addr = UART_BASE_ADDRESS + UART_READ_WRITE_REGISTER_OFFSET;

	   // is there more room in the buffer for data from the UART?
	   while (volume < UART_BUFFER_SIZE) {             // if space remains in the buffer
	     // c = *UART_read_addr;                   // attempt to read from the UART
	  	  c = XUartPs_RecvByte(STDIN_BASEADDRESS);
	      if ((c > 31) || (c == '\r')) {               // if it is valid data (printing character or cr/lf), then
	         recvBuffer[write_ptr++] = c;           // save it in the buffer
	         write_ptr = write_ptr % UART_BUFFER_SIZE;    // wrap if necessary - requires UART_BUFFER_SIZE to be a power of 2
	         volume++;                           // one more piece of data in the buffer
	      } else {
	         break;                              // exit the while loop
	      }
	   }

	   // return the next piece of valid data to the caller
	   if (volume > 0) {                         // there is something to return
	      c = recvBuffer[read_ptr++];                  // pull the character from the buffer
	      read_ptr = read_ptr % UART_BUFFER_SIZE;         // wrap if necessary - requires UART_BUFFER_SIZE to be a power of 2
	      volume--;                              // one less piece of data in the buffer
	     // if (echo) { *UART_write_addr = c; }          // should we echo the character back when it was pulled from the buffer?
	      if (echo) { XUartPs_SendByte(STDOUT_BASEADDRESS,c); }
	      return c;                              // return the datum to the caller
	   }

	   // no data left in buffer, return failure code
	   return (-1);                              // tell the caller that nothing was available (default condition)
}



//*********************** Functions for Using the UARTlite ************************************

// identify the base address of the UART depending on whether this is a UARTLite for a MicroBlaze system or a UART in the Zynq7000 PS
#ifdef __MICROBLAZE__
#define UART_BASE_ADDRESS                   XPAR_UARTLITE_0_BASEADDR
#else
#define UART_BASE_ADDRESS                   XPAR_PSU_UART_0_BASEADDR /* Z7000: 0xE0001000 */
#endif

#define UART_READ_WRITE_REGISTER_OFFSET     0x30

char getCharFromUART(int echo) {
   static int      read_ptr  = 0;
   static int      write_ptr = 0;
   static int      volume    = 0;
   unsigned char   c;                           // generic character variable
   unsigned long   *UART_read_addr  = 0;        // pointer directly to UART read  register
   unsigned long   *UART_write_addr  = 0;       // pointer directly to UART write register

   // point to the specific location in memory where the UART should read from
   UART_read_addr = UART_write_addr = UART_BASE_ADDRESS + UART_READ_WRITE_REGISTER_OFFSET;

   // is there more room in the buffer for data from the UART?
   while (volume < UART_BUFFER_SIZE) {             // if space remains in the buffer
      c = *UART_read_addr;                   // attempt to read from the UART
      if ((c > 31) || (c == '\r')) {               // if it is valid data (printing character or cr/lf), then
         recvBuffer[write_ptr++] = c;           // save it in the buffer
         write_ptr = write_ptr % UART_BUFFER_SIZE;    // wrap if necessary - requires UART_BUFFER_SIZE to be a power of 2
         volume++;                           // one more piece of data in the buffer
      } else {
         break;                              // exit the while loop
      }
   }

   // return the next piece of valid data to the caller
   if (volume > 0) {                         // there is something to return
      c = recvBuffer[read_ptr++];                  // pull the character from the buffer
      read_ptr = read_ptr % UART_BUFFER_SIZE;         // wrap if necessary - requires UART_BUFFER_SIZE to be a power of 2
      volume--;                              // one less piece of data in the buffer
      if (echo) { *UART_write_addr = c; }          // should we echo the character back when it was pulled from the buffer?
      return c;                              // return the datum to the caller
   }

   // no data left in buffer, return failure code
   return (-1);                              // tell the caller that nothing was available (default condition)
}

/*
 * Place a single character to the UART
 */
void putCharToUART(char c) {

#ifdef __MICROBLAZE__

   XUartLite_SendByte(UART_BASE_ADDRESS, c);

#else
   // local variables
   unsigned long *UART_write_addr  = 0;            // pointer directly to UART write register

   // point to the proper register
   UART_write_addr = UART_BASE_ADDRESS + UART_READ_WRITE_REGISTER_OFFSET;

   // write it!
   *UART_write_addr = c;
#endif
}
