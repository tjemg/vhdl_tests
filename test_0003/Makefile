FLAGS  = --ieee=synopsys
TARGET = testbench

all:
	ghdl -a $(FLAGS) rom_mem.vhd
	ghdl -a $(FLAGS) testbench.vhd
	ghdl -e $(FLAGS) $(TARGET)

simulate:
	ghdl -r $(TARGET) --vcd=test.vcd --stop-time=1700ps
	gzip test.vcd

show:
	gtkwave test.vcd.gz

clean:
	rm -rf *.o
	rm -rf *~
	rm -rf *.cf
	rm -rf *.vcd.*
	rm -rf $(TARGET)
