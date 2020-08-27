
In this folder there are two source (assembler) examples using IRQ:

**testEchoIRQ.asm:**      uses IRQ vector 33 to read a char from the virtual serial port

**testEchoBlinkIRQ.asm:** uses IRQ vector 33 to read a char from the virtial serial port and IRQ vector 34 for the system tick tiner (100ms) to blink the User led.

The executable .HEX files (Intel-Hex) are provided too.

NOTE 1: testEchoBlinkIRQ.asm require the IOS S260320-R260820_DEVEL1 to blink the led.
NOTE 2: both examples can run with IOS S260320-R230520 but the led will not blink in the testEchoBlinkIRQ.asm example
