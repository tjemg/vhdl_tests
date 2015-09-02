FLAGS    = --ieee=synopsys
TARGET   = testbench
SOURCES  = division.vhd       \
           testbench.vhd
OBJECTS  = $(subst .vhd,.o,$(SOURCES))

all: $(OBJECTS)
	ghdl -e $(FLAGS) $(TARGET)

%.o: %.vhd
	ghdl -a $(FLAGS) $<

run:
	ghdl -r $(TARGET) --wave=test.ghw --stop-time=400ns

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
	rm -rf log.txt
	rm -rf trace.txt
	rm -rf $(TARGET)
	rm -rf build
