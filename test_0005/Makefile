ZPUCORE = zpu_core.vhd
FLAGS   = --ieee=synopsys
TARGET  = fpga_top
DEVICE  = xc2s300e-6-pq208
SOURCES = zpu_config_trace.vhd            \
          zpupkg.vhd                      \
          txt_util.vhd                    \
          sim_fpga_top.vhd                \
          $(ZPUCORE)                      \
	  prog_ram.vhd                    \
          timer.vhd                       \
          io.vhd                          \
          trace.vhd
OBJECTS = $(subst .vhd,.o,$(SOURCES))

all: ram $(OBJECTS)
	ghdl -e $(FLAGS) $(TARGET)

ram: zpuramgen
	/opt/ZPU/bin/zpu-elf-gcc -o hello.elf hello.c -phi -Wl,--gc-sections -O3 -Wl,--relax
	/opt/ZPU/bin/zpu-elf-objdump --disassemble-all hello.elf > hello.dis
	/opt/ZPU/bin/zpu-elf-objcopy -O binary hello.elf hello.bin
	./zpuramgen hello.bin > prog_ram.vhd
	chmod -x hello.bin
	chmod -x hello.elf

zpuramgen:
	gcc -o zpuramgen zpuramgen.c

%.o: %.vhd
	ghdl -a $(FLAGS) $<

prog_ram.o:
	ghdl -a $(FLAGS) prog_ram.vhd

run:
	ghdl -r $(TARGET) --wave=test.ghw --stop-time=1ms

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
	rm -rf *.elf
	rm -rf *.dis
	rm -rf *.ram
	rm -rf *.bin
	rm -rf prog_ram.vhd
	rm -rf log.txt
	rm -rf trace.txt
	rm -rf $(TARGET)
	rm -rf build
	rm -rf zpuramgen
	rm -rf xlnx_auto*
