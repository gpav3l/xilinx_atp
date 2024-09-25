/*
 * utils_print.h
 *
 *  Created on: Dec 29, 2014
 *      Author: williamk
 */

#include "stdio.h"
#include "xil_types.h"
#include "xil_printf.h"


/* function prototypes */
void  		   end_line();
void		      use_only_nl();
void	         use_nl_and_cr();
void           strReverse(char s[]);
char*          intToString(int n);
char*          fltToString(float f);
char*          intToHexString(int n);
unsigned       isDigit(char c);
unsigned       is_printing_character(char c);
unsigned char  to_BCD(int x);
void check_status(int status_code, char* msg);
void check_null(void* ptr, char* msg);

/* handy macros */
#define writeStr_NL(x) xil_printf("%s",x); end_line()
#define writeStr xil_printf
#define writeNL  end_line
#define writeHex putnum
#define writeFloat(x)  writeStr(fltToString(x))
#define writeDbl(x)    xil_printf("%E",x)
#define writeInt_NL(x) xil_printf("%d",x); end_line()
#define writeInt(x)    xil_printf("%0d",x)


