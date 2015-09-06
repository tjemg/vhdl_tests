ZPUCCDIR = /opt/zpugcc
ZPUCORE  = zpu_core.vhd
ZPUCCOPT = -O4
FLAGS    = --ieee=synopsys
TARGET   = sim_fpga_top
DEVICE   = xc2s300e-6-pq208
SOURCES  = zpu_config.vhd     \
           zpupkg.vhd         \
           txt_util.vhd       \
           $(ZPUCORE)         \
           fpga_top.vhd       \
           sim_fpga_top.vhd
OBJECTS  = $(subst .vhd,.o,$(SOURCES))
MAIN     = main

all: $(OBJECTS) prog_ram.o
	ghdl -e $(FLAGS) $(TARGET)

ram: zpuramgen
	$(ZPUCCDIR)/bin/zpu-elf-gcc -o $(MAIN).elf crt0_phi.S $(MAIN).c -phi -Wl,--gc-sections -abel -Wl,--relax -nostdlib $(ZPUCCOPT)
	$(ZPUCCDIR)/bin/zpu-elf-objdump --disassemble-all $(MAIN).elf > $(MAIN).dis
	$(ZPUCCDIR)/bin/zpu-elf-objcopy -O binary $(MAIN).elf $(MAIN).bin
	#./zpuramgen $(MAIN).bin > prog_ram.vhd
	chmod -x $(MAIN).bin
	chmod -x $(MAIN).elf

zpuramgen:
	gcc -o zpuramgen zpuramgen.c

%.o: %.vhd
	ghdl -a $(FLAGS) $<

prog_ram.o: ram
	ghdl -a $(FLAGS) prog_ram.vhd

run:
#	ghdl -r $(TARGET) --wave=test.ghw --stop-time=1ms
	ghdl -r $(TARGET) --wave=test.ghw --stop-time=4us

bit:
	rm -rf build
	rm -rf xlnx_auto*
	rm -rf _impact*
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
	gtkwave test.gtkw

clean:
	rm -rf *.o
	rm -rf *~
	rm -rf \#*\#
	rm -rf .\#*
	rm -rf _impact*
	rm -rf *.cf
	rm -rf *.ghw
	rm -rf *.bit
	rm -rf *.elf
	rm -rf *.dis
	rm -rf *.ram
	rm -rf *.bin
#	rm -rf prog_ram.vhd
	rm -rf log.txt
	rm -rf trace.txt
	rm -rf $(TARGET)
	rm -rf build
	rm -rf zpuramgen
	rm -rf xlnx_auto*
