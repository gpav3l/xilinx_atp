# Vivado HLS FixedPoint Wrapper test
You can use it for investigating, how wrapper and overflow option is effect to result in mathematical operation with ap_fixed types.
 

# Example of output
```
Adder info: 000.01 0.250000
Raw result is 000001  get 000.01 (0.250000) get 000.01 (0.250000)
Raw result is 000010  get 000.10 (0.500000) get 000.10 (0.500000)
Raw result is 000011  get 000.11 (0.750000) get 000.11 (0.750000)
Raw result is 000100  get 001.00 (1.000000) get 001.00 (1.000000)
Raw result is 000101  get 001.01 (1.250000) get 001.01 (1.250000)
Raw result is 000110  get 001.10 (1.500000) get 001.10 (1.500000)
Raw result is 000111  get 001.11 (1.750000) get 001.11 (1.750000)
Raw result is 001000  get 010.00 (2.000000) get 010.00 (2.000000)
Raw result is 001001  get 010.01 (2.250000) get 010.01 (2.250000)
Raw result is 001010  get 010.10 (2.500000) get 010.10 (2.500000)
Raw result is 001011  get 010.11 (2.750000) get 010.11 (2.750000)
Raw result is 001100  get 011.00 (3.000000) get 011.00 (3.000000)
Raw result is 001101  get 011.01 (3.250000) get 011.01 (3.250000)
Raw result is 001110  get 011.10 (3.500000) get 011.10 (3.500000)
Raw result is 001111  get 011.11 (3.750000) get 011.11 (3.750000)
Raw result is 010000  get 000.00 (0.000000) get 010.00 (2.000000)
Raw result is 000001  get 000.01 (0.250000) get 010.01 (2.250000)
Raw result is 000010  get 000.10 (0.500000) get 010.10 (2.500000)
Raw result is 000011  get 000.11 (0.750000) get 010.11 (2.750000)
Raw result is 000100  get 001.00 (1.000000) get 011.00 (3.000000)
Raw result is 000101  get 001.01 (1.250000) get 011.01 (3.250000)
Raw result is 000110  get 001.10 (1.500000) get 011.10 (3.500000)
Raw result is 000111  get 001.11 (1.750000) get 011.11 (3.750000)
Raw result is 001000  get 010.00 (2.000000) get 010.00 (2.000000)
...
```