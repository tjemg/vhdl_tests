FLAGS  = --ieee=synopsys
TARGET = tb_file_read

all:
	ghdl -a $(FLAGS) txt_util.vhd
	ghdl -a $(FLAGS) file_read.vhd
	ghdl -a $(FLAGS) tb_file_read.vhd
	ghdl -e $(FLAGS) $(TARGET)

simulate:
	ghdl -r $(TARGET) --vcd=test.vcd --stop-time=250ns

show:
	gtkwave test.vcd

clean:
	rm -rf *.o
	rm -rf *~
	rm -rf *.cf
	rm -rf $(TARGET)
