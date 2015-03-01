FLAGS  = --ieee=synopsys
TARGET = testbench
DEVICE = xc2s300e-6-pq208

all:
	ghdl -a $(FLAGS) rom_mem.vhd
	ghdl -a $(FLAGS) testbench.vhd
	ghdl -e $(FLAGS) $(TARGET)

run:
	ghdl -r $(TARGET) --wave=test.ghw --stop-time=1700ps

bit:
	rm -rf build
	rm -rf xlnx_auto*
	mkdir build
	mkdir build/xst
	mkdir build/xst/projnav.tmp
	cp top_level.* build
	cd build; xst -intstyle ise -ifn top_level.xst -ofn top_level.syr
	cd build; ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc top_level.ucf -p $(DEVICE) top_level.ngc top_level.ngd
	cd build; map -intstyle ise -p $(DEVICE) -cm area -pr off -k 4 -c 100 -tx off -o top_level.ncd top_level.ngd top_level.pcf
	cd build; par -w -intstyle ise -ol high top_level.ncd top_level.ncd top_level.pcf
	cd build; trce -intstyle ise -e 3 -s 6 -xml top_level top_level.ncd -o top_level.twr top_level.pcf -ucf top_level.ucf
	cd build; bitgen -intstyle ise -f top_level.ut top_level.ncd
	cp build/*.bit .

show:
	gtkwave test.ghw

clean:
	rm -rf *.o
	rm -rf *~
	rm -rf *.cf
	rm -rf *.ghw
	rm -rf *.bit
	rm -rf $(TARGET)
	rm -rf build
	rm -rf xlnx_auto*
