# VHDL Tests

Personal repository containing VHDL Tests (pure models and/or synthetizable)

These tests can be run using GHDL and the generated signals can be observed with GTKWave

Programming is done with Xilinx 10.1 Impact

(yes, its an old version, but it supports one of my FPGA boards with a Spartan-2E 300K gates!)


```
Sub-Directory  GHDL Synth  FPGA  Description
test_0001:      Y      N     ?   file_read testbench
test_0002:      Y      N     ?   ROM model (loading rom external file)
test_0003:      Y      Y     ?   ROM model (synthetizable)
test_0004:      Y      Y     ?   ROM model (synthetizable)
test_0005:      Y      N     ?   ZPU test project
test_0006:      Y      Y     ?   ZPU project (synthetizable, low memory size 2Kx32bit)
test_0007:      Y      Y     Y   Blink LED for BurchED FPGA board
test_0008:      N      ?     -   OpenCore SPI Master/Slave
test_0009:      ?      ?     -   OpenCore GRP Debouncer
test_0010:      Y      ?     -   RAM with loaded SIN function
test_0011:      Y      Y     Y   Test Inferred RAM initialization in FPGA
test_0012:      Y      Y     Y   Blinky 2 with clock divider (test PulseView)
test_0013:      Y      Y     Y   ZPU + Sinus Generator
test_0014:      Y      Y     Y   Cleanup, documentation and improvement of ZPU core
test_0015:      Y      ?     ?   VHDL implementation of unsigned division
test_0016:      Y      ?     ?   ZPU simulation with debugging output
```
