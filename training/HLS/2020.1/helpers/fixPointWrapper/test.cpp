#include "test.h"


#define W 5
#define I 3

ap_fixed<W, I, AP_RND, AP_WRAP, 1> fxTest1;
ap_fixed<W, I, AP_RND, AP_WRAP, 2> fxTest2;
ap_fixed<W, I> fxAdd;
ap_int<W+1> testInteger;


void printFixBin(uint32_t val, uint32_t bitCnt, uint32_t binPoint, bool addNewLine = false);

/*!
 *  Main test function
 */
void test()
{
	fxAdd(0, 0) = 1;
	fxTest1 = 0;
	fxTest2 = 0;

	printf("Adder info: ");
	printFixBin(fxAdd(W-1, 0).to_uint(), W, I);
	printf("%f\n", fxAdd.to_float());


	for(int i=0; i<(2<<W); i++)
	{
		testInteger += fxAdd(W-1, 0);
		fxTest1 += fxAdd;
		fxTest2 += fxAdd;

		printf("Raw result is ");
		printFixBin(testInteger, W+1, W+1);

		printf(" get ");
		printFixBin(fxTest1(W-1, 0).to_uint(), W, I);
		printf("(%f)", fxTest1.to_float());

		printf(" get ");
		printFixBin(fxTest2(W-1, 0).to_uint(), W, I);
		printf("(%f)", fxTest2.to_float());

		printf("\n");
		testInteger = fxTest1(W-1, 0).to_uint();
	}

}

/*!
 *  Print uint value as fixed-point in binary format
 */
void printFixBin(uint32_t val, uint32_t bitCnt, uint32_t binPoint, bool addNewLine)
{
	for(uint32_t i=0; i<binPoint; i++)
	{
		if(val & (1<<(bitCnt-1 - i)))
			printf("1");
		else
			printf("0");
	}

	if(bitCnt == binPoint)
	{
		printf(" ");
		return;
	}

	printf(".");

	for(uint32_t i=0; i<(bitCnt-binPoint); i++)
	{
		if(val & (1<<((bitCnt-binPoint-1)-i)))
			printf("1");
		else
			printf("0");
	}

	printf(" ");
	if(addNewLine)
		printf("\n");
}
