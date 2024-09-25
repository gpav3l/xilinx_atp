/*
 * utils_print.c
 *
 *  Created on: Dec 29, 2014
 *      Author: williamk
 */

#include "utils_print.h"

//#include "xbasic_types.h"
#include "xil_types.h"
#include <string.h>
#include <math.h>

#include "stdlib.h"
#include "xil_printf.h"
#include "xstatus.h"

// global variables
u8 only_nl = 0;


/*
 * end_line
 *
 * end the line with the designated line ending (either \n or \n\r
 */
void end_line() {
	if (only_nl) { xil_printf("\n"); }
	else         { xil_printf("\n\r"); }
}

/*
 * use_only_nl
 *
 * uses only the \n character at the end of a line instead of the pair \n\r
 *
 */
void use_only_nl() {
	only_nl = 1;
}

/*
 * use_nl_and_cr
 *
 * uses both the \n and \r characters at the end of a line
 *
 */
void use_nl_and_cr () {
	only_nl = 0;
}

/*
 * printing_character(c)
 *
 * returns non-zero if c is a printable character (that is, it causes ink to be spilled when printing).
 * control characters (tabs, new-line, line feed, bel, etc.) are non-printing characters and return zero.
 *
 */
unsigned is_printing_character(char c) {
    if ((c>=' ') && (c<='~')) return(1);
    return (0);
}

/*
 * isDigit
 *
 * returns 1 if character is a decimal digit ('0'-'9'), 0 otherwise
 *
 */
unsigned isDigit(char c) {
   if ((c >= '0') && (c <= '9')) { return 1; }
   else                          { return 0; }
}

/* fltToString: convert a floating point number to a string */
/* only works for floats near zero +/- 1M */
char* fltToString(float f) {
	// define local variables
	int   integerPart     = (int)(f);
	int   fractionalPart  = (int)((f - integerPart) * 1000000.0);
	static char  returnValue[32];

	// is it too big?
	if (f > 999999.999999) { return "---too big---"; }

	// build the full string based on the integer and fractional parts
	strcpy(returnValue,intToString(integerPart));
	strcat(returnValue,".");
	strcat(returnValue,intToString(fractionalPart));

	return &returnValue[0];
}

/* intToString: convert integer n to a string */
char* intToString(int n) {
	int i, sign;
    static char  s[16];		   	   									  	    // max 16 digits including sign - value is returned - must be static
	if ((sign = n) < 0) 													// record sign
		n = -n; 															// make n positive
	i = 0;
	do { 																	// generate digits in reverse order
		s[i++] = n % 10 + '0'; 												// get next digit
	} while ((n /= 10) > 0); 												// delete it
	if (sign < 0) { s[i++] = '-'; } 										// append the minus sign
	s[i] = '\0';															// terminate the string
	strReverse(s);															// reverse the string
	return s;
}

/* intToHexString: convert integer n to a hexadecimal string */
char* intToHexString(int n) {
	int i, sign;
    static char  s[16];		   	   									    	// max 16 digits including sign - value is returned - must be static
	if ((sign = n) < 0) { n = -n; }											// record sign and make n positive
	i = 0;
	do { 																	// generate digits in reverse order
		if (s[i] > '9') { s[i++] = (n % 16) - 10 + 'A'; }                   // if the value is between A-F
		else            { s[i++] = (n % 16)      + '0'; }				    // if the value is between 0-9
	} while ((n /= 10) > 0); 												// delete it
	if (sign < 0) { s[i++] = '-'; } 										// append the minus sign
	s[i] = '\0';															// terminate the string
	strReverse(s);															// reverse the string
	return s;
}

/* reverse: reverses the order of a string */
void strReverse(char s[]) {
	int c, i, j;
	for (i=0, j = strlen(s)-1; i<j; i++, j--) {
		c = s[i];
		s[i] = s[j];
		s[j] = c;
	}
}


/*
 * to_BCD
 *
 * converts the least significant decimal digit of the passed value into its BCD equivalent
 * argument must be less than 10 billion
 *
 */
unsigned char to_BCD(int x) {
	u32 i, mask;
	unsigned char digit;
    mask = 1000000000;
	for (i=0; i<10; i++) {
		digit  = x / mask;							// get the digit in this position
		x     -= digit * mask;						// remaining value
		mask  /= 10;								// go after the next digit
	}
	return digit;
}


/*
 * bin2secsStr()
 *  converts the binary elapsed stopwatch time to 6 asc digits with a decimal point.
 *  The value must be less than 999,999.
 *
 * INPUTS:
 *  val - binary value to be converted, must be < 1,000,000.
 *
 * OUTPUTS:
 *  valStr - pointer to the tenths of a second value converted to ascii string with decimal point added.
 *
 */
char *bin2secsStr(u32 val) {
    // local variables
	u32             zx;
    ldiv_t              result;
    static char         valStr[8];

    result = ldiv(val, (u32)100000);         // convert hundred thousands digit
    valStr[0] = (unsigned char)result.quot + 0x30;

    result = ldiv(result.rem, (u32)10000);       // convert ten thousands digit
    valStr[1] = (unsigned char)result.quot + 0x30;

    result = ldiv(result.rem, (u32)1000);        // convert thousands digit
    valStr[2] = (unsigned char)result.quot + 0x30;

    result = ldiv(result.rem, (u32)100);         // convert hundreds digit
    valStr[3] = (unsigned char)result.quot + 0x30;

    result = ldiv(result.rem, (u32)10);          // convert tens digit
    valStr[4] = (unsigned char)result.quot + 0x30;

    valStr[5] = '.';                                // add decimal point

    valStr[6] = (unsigned char)result.rem + 0x30;   // convert ones digit

    valStr[7] = 0;                                  // add null termination character

    // blank leading zeros
    for (zx = 0; zx < 4; zx++)   { 	// test each if digit == 0
        if (valStr[zx] == '0') { 	// blank digit if 0
            valStr[zx] = ' ';
        } else  { 					// don't blank digit or any to the right
            break;
        } // don't blank digit or any to the right
    }
    return(valStr); // return the address of the string
}

/*
 * *** check_status(status_code,message)
 *
 * shorthand function for displaying a message when status_code is not XST_SUCCESS.
 * function deliberately hangs if not successful
 *
 */
void check_status(int status_code, char* msg) {
	if (status_code != XST_SUCCESS) {
		xil_printf(msg);
		while (1) {};						// deliberate infinite loop
	}
}

/*
 * *** check_null(status_code,message)
 *
 * shorthand function for displaying a message when status_code is not NULL.
 * function deliberately hangs if not successful
 *
 */
void  check_null(void* ptr, char* msg) {
	if (ptr != NULL) {
		xil_printf(msg);
		while (1) {};						// deliberate infinite loop
	}
}




