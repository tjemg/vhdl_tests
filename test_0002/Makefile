FLAGS  = --ieee=synopsys
TARGET = testbench

all:
	ghdl -a $(FLAGS) rom_file.vhd
	ghdl -a $(FLAGS) testbench.vhd
	ghdl -e $(FLAGS) $(TARGET)

simulate:
	ghdl -r $(TARGET) --vcd=test.vcd --stop-time=26ns
	gzip test.vcd

show:
	gtkwave test.gtkw

clean:
	rm -rf *.o
	rm -rf *~
	rm -rf *.cf
	rm -rf *.vcd.*
	rm -rf $(TARGET)
