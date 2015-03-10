FLAGS   = --ieee=synopsys
TARGET  = spi_loopback_test
DEVICE  = xc2s300e-6-pq208
SOURCES = grp_debouncer.vhd      \
          spi_master.vhd         \
          spi_slave.vhd          \
          spi_loopback.vhd       \
          spi_loopback_test.vhd
          
OBJECTS = $(subst .vhd,.o,$(SOURCES))
MAIN    = main

all: $(OBJECTS)
	ghdl -e $(FLAGS) $(TARGET)

%.o: %.vhd
	ghdl -a $(FLAGS) $<

run:
	ghdl -r $(TARGET) --wave=test.ghw --stop-time=1000ms

show:
	gtkwave test.ghw

clean:
	rm -rf *.o
	rm -rf *~
	rm -rf *.cf
	rm -rf *.ghw
	rm -rf $(TARGET)
