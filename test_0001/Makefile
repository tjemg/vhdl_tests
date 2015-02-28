all:
	ghdl -a --ieee=synopsys std_logic_arith.vhdl
	ghdl -a --ieee=synopsys txt_util.vhd
	ghdl -a --ieee=synopsys file_read.vhd
	ghdl -a --ieee=synopsys tb_file_read.vhd
	ghdl -e tb_file_read

simulate:
	ghdl -r tb_file_read --vcd=test.vcd --stop-time=250ns

show:
	gtkwave test.vcd

clean:
	rm -rf *.o
	rm -rf *~
	rm -rf *.cf
	rm -rf tb_file_read
