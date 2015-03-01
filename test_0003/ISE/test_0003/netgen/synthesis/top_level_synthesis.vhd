--------------------------------------------------------------------------------
-- Copyright (c) 1995-2008 Xilinx, Inc.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version: K.31
--  \   \         Application: netgen
--  /   /         Filename: top_level_synthesis.vhd
-- /___/   /\     Timestamp: Sun Mar  1 21:52:15 2015
-- \   \  /  \ 
--  \___\/\___\
--             
-- Command	: -intstyle ise -ar Structure -tm top_level -w -dir netgen/synthesis -ofmt vhdl -sim rom.ngc top_level_synthesis.vhd 
-- Device	: xc2s300e-6-ft256
-- Input file	: rom.ngc
-- Output file	: /home/gasiba/Tests/test_0003/ISE/test_0003/netgen/synthesis/top_level_synthesis.vhd
-- # of Entities	: 1
-- Design Name	: rom
-- Xilinx	: /opt/Xilinx/10.1/ISE
--             
-- Purpose:    
--     This VHDL netlist is a verification model and uses simulation 
--     primitives which may not represent the true implementation of the 
--     device, however the netlist is functionally correct and should not 
--     be modified. This file cannot be synthesized and should only be used 
--     with supported simulation tools.
--             
-- Reference:  
--     Development System Reference Guide, Chapter 23
--     Synthesis and Simulation Design Guide, Chapter 6
--             
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
use UNISIM.VPKG.ALL;

entity top_level is
  port (
    clk : in STD_LOGIC := 'X'; 
    dout : out STD_LOGIC_VECTOR ( 7 downto 0 ); 
    addr : in STD_LOGIC_VECTOR ( 3 downto 0 ) 
  );
end top_level;

architecture Structure of top_level is
  signal Mrom_dout_rom000011 : STD_LOGIC; 
  signal Mrom_dout_rom0000111 : STD_LOGIC; 
  signal Mrom_dout_rom0000221 : STD_LOGIC; 
  signal Mrom_dout_rom000031 : STD_LOGIC; 
  signal Mrom_dout_rom000041 : STD_LOGIC; 
  signal Mrom_dout_rom000051 : STD_LOGIC; 
  signal Mrom_dout_rom0000611 : STD_LOGIC; 
  signal Mrom_dout_rom000071 : STD_LOGIC; 
  signal addr_0_IBUF_12 : STD_LOGIC; 
  signal addr_1_IBUF_13 : STD_LOGIC; 
  signal addr_2_IBUF_14 : STD_LOGIC; 
  signal addr_3_IBUF_15 : STD_LOGIC; 
  signal clk_BUFGP_17 : STD_LOGIC; 
  signal dout_0_26 : STD_LOGIC; 
  signal dout_1_27 : STD_LOGIC; 
  signal dout_2_28 : STD_LOGIC; 
  signal dout_3_29 : STD_LOGIC; 
  signal dout_4_30 : STD_LOGIC; 
  signal dout_5_31 : STD_LOGIC; 
  signal dout_6_32 : STD_LOGIC; 
  signal dout_7_33 : STD_LOGIC; 
begin
  addr_3_IBUF : IBUF
    port map (
      I => addr(3),
      O => addr_3_IBUF_15
    );
  addr_2_IBUF : IBUF
    port map (
      I => addr(2),
      O => addr_2_IBUF_14
    );
  addr_1_IBUF : IBUF
    port map (
      I => addr(1),
      O => addr_1_IBUF_13
    );
  addr_0_IBUF : IBUF
    port map (
      I => addr(0),
      O => addr_0_IBUF_12
    );
  dout_7_OBUF : OBUF
    port map (
      I => dout_7_33,
      O => dout(7)
    );
  dout_6_OBUF : OBUF
    port map (
      I => dout_6_32,
      O => dout(6)
    );
  dout_5_OBUF : OBUF
    port map (
      I => dout_5_31,
      O => dout(5)
    );
  dout_4_OBUF : OBUF
    port map (
      I => dout_4_30,
      O => dout(4)
    );
  dout_3_OBUF : OBUF
    port map (
      I => dout_3_29,
      O => dout(3)
    );
  dout_2_OBUF : OBUF
    port map (
      I => dout_2_28,
      O => dout(2)
    );
  dout_1_OBUF : OBUF
    port map (
      I => dout_1_27,
      O => dout(1)
    );
  dout_0_OBUF : OBUF
    port map (
      I => dout_0_26,
      O => dout(0)
    );
  dout_0 : FDR
    port map (
      C => clk_BUFGP_17,
      D => Mrom_dout_rom000011,
      R => addr_2_IBUF_14,
      Q => dout_0_26
    );
  Mrom_dout_rom0000112 : LUT3
    generic map(
      INIT => X"41"
    )
    port map (
      I0 => addr_3_IBUF_15,
      I1 => addr_0_IBUF_12,
      I2 => addr_1_IBUF_13,
      O => Mrom_dout_rom000011
    );
  dout_1 : FDR
    port map (
      C => clk_BUFGP_17,
      D => Mrom_dout_rom0000111,
      R => addr_3_IBUF_15,
      Q => dout_1_27
    );
  Mrom_dout_rom00001111 : LUT3
    generic map(
      INIT => X"45"
    )
    port map (
      I0 => addr_2_IBUF_14,
      I1 => addr_1_IBUF_13,
      I2 => addr_0_IBUF_12,
      O => Mrom_dout_rom0000111
    );
  dout_2 : FDR
    port map (
      C => clk_BUFGP_17,
      D => Mrom_dout_rom0000221,
      R => addr_3_IBUF_15,
      Q => dout_2_28
    );
  Mrom_dout_rom00002211 : LUT3
    generic map(
      INIT => X"17"
    )
    port map (
      I0 => addr_0_IBUF_12,
      I1 => addr_2_IBUF_14,
      I2 => addr_1_IBUF_13,
      O => Mrom_dout_rom0000221
    );
  dout_3 : FDR
    port map (
      C => clk_BUFGP_17,
      D => Mrom_dout_rom000031,
      R => addr_3_IBUF_15,
      Q => dout_3_29
    );
  Mrom_dout_rom0000311 : LUT3
    generic map(
      INIT => X"45"
    )
    port map (
      I0 => addr_2_IBUF_14,
      I1 => addr_0_IBUF_12,
      I2 => addr_1_IBUF_13,
      O => Mrom_dout_rom000031
    );
  dout_4 : FDR
    port map (
      C => clk_BUFGP_17,
      D => Mrom_dout_rom000041,
      R => addr_3_IBUF_15,
      Q => dout_4_30
    );
  Mrom_dout_rom0000411 : LUT3
    generic map(
      INIT => X"19"
    )
    port map (
      I0 => addr_0_IBUF_12,
      I1 => addr_1_IBUF_13,
      I2 => addr_2_IBUF_14,
      O => Mrom_dout_rom000041
    );
  dout_5 : FDR
    port map (
      C => clk_BUFGP_17,
      D => Mrom_dout_rom000051,
      R => addr_2_IBUF_14,
      Q => dout_5_31
    );
  Mrom_dout_rom0000511 : LUT2
    generic map(
      INIT => X"1"
    )
    port map (
      I0 => addr_0_IBUF_12,
      I1 => addr_3_IBUF_15,
      O => Mrom_dout_rom000051
    );
  dout_6 : FDR
    port map (
      C => clk_BUFGP_17,
      D => Mrom_dout_rom0000611,
      R => addr_3_IBUF_15,
      Q => dout_6_32
    );
  Mrom_dout_rom00006111 : LUT3
    generic map(
      INIT => X"27"
    )
    port map (
      I0 => addr_0_IBUF_12,
      I1 => addr_1_IBUF_13,
      I2 => addr_2_IBUF_14,
      O => Mrom_dout_rom0000611
    );
  dout_7 : FDR
    port map (
      C => clk_BUFGP_17,
      D => Mrom_dout_rom000071,
      R => addr_3_IBUF_15,
      Q => dout_7_33
    );
  Mrom_dout_rom0000711 : LUT3
    generic map(
      INIT => X"71"
    )
    port map (
      I0 => addr_1_IBUF_13,
      I1 => addr_2_IBUF_14,
      I2 => addr_0_IBUF_12,
      O => Mrom_dout_rom000071
    );
  clk_BUFGP : BUFGP
    port map (
      I => clk,
      O => clk_BUFGP_17
    );

end Structure;

