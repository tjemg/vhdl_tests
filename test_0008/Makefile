FLAGS   = --ieee=synopsys
TARGET  = spi_loopback_test
DEVICE  = xc2s300e-6-pq208
PREVHDL = spi_master._vhdl       \
	  spi_slave._vhdl
SOURCES = grp_debouncer.vhd      \
          spi_master._vhdl       \
          spi_slave._vhdl        \
          spi_loopback.vhd       \
          spi_loopback_test.vhd
          
OBJECTS = $(subst ._vhdl,._o,$(subst .vhd,.o,$(SOURCES)))
MAIN    = main

all: $(OBJECTS)
	ghdl -e $(FLAGS) $(TARGET)

%.o: %.vhd
	@echo $(OBJECTS)
	ghdl -a $(FLAGS) $<

%._o: %._vhdl
	ghdl -a $(FLAGS) $<

%._vhdl: %.vhd
	vpp $< $@

run:
	ghdl -r $(TARGET) --wave=test.ghw --stop-time=1000ms

show:
	gtkwave test.ghw

clean:
	rm -rf *.o
	rm -rf *~
	rm -rf *.cf
	rm -rf *.ghw
	rm -rf *._vhdl
	rm -rf $(TARGET)
