Personal repository containing VHDL Tests (pure models and/or synthetizable)
These tests can be run using GHDL and the generated signals can be observed with GTKWave
Programming is done with Xilinx 10.1 Impact
(yes, its an old version, but it supports one of my FPGA boards with a Spartan-2E 300K gates!)

Sub-Directory  Synth    Description
test_0001:       N      file_read testbench
test_0002:       N      ROM model (loading rom external file)
test_0003:       Y      ROM model (synthetizable)
test_0004:       Y      ROM model (synthetizable)
test_0005:       N      ZPU test project
test_0006:       Y      ZPU project (synthetizable, low memory size 2Kx32bit)
test_0007:       Y      Blink LED for BurchED FPGA board
