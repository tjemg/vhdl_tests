VERSION 6
BEGIN SCHEMATIC
    BEGIN ATTR DeviceFamilyName "spartan2e"
        DELETE all:0
        EDITNAME all:0
        EDITTRAIT all:0
    END ATTR
    BEGIN NETLIST
        SIGNAL CLK_IN
        SIGNAL DATA_OUT(7:0)
        SIGNAL ADDR_IN(3:0)
        PORT Input CLK_IN
        PORT Output DATA_OUT(7:0)
        PORT Input ADDR_IN(3:0)
        BEGIN BLOCKDEF rom
            TIMESTAMP 2015 3 1 20 44 0
            RECTANGLE N 64 -128 320 0 
            LINE N 64 -96 0 -96 
            RECTANGLE N 0 -44 64 -20 
            LINE N 64 -32 0 -32 
            RECTANGLE N 320 -108 384 -84 
            LINE N 320 -96 384 -96 
        END BLOCKDEF
        BEGIN BLOCK XLXI_1 rom
            PIN clk CLK_IN
            PIN addr(3:0) ADDR_IN(3:0)
            PIN dout(7:0) DATA_OUT(7:0)
        END BLOCK
    END NETLIST
    BEGIN SHEET 1 3520 2720
        BEGIN INSTANCE XLXI_1 1168 720 R0
        END INSTANCE
        BEGIN BRANCH CLK_IN
            WIRE 1008 624 1168 624
        END BRANCH
        IOMARKER 1008 624 CLK_IN R180 28
        BEGIN BRANCH DATA_OUT(7:0)
            WIRE 1552 624 1680 624
        END BRANCH
        IOMARKER 1680 624 DATA_OUT(7:0) R0 28
        BEGIN BRANCH ADDR_IN(3:0)
            WIRE 1008 688 1168 688
        END BRANCH
        IOMARKER 1008 688 ADDR_IN(3:0) R180 28
    END SHEET
END SCHEMATIC
