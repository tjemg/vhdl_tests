--------------------------------------------------------------------------------
-- Copyright (c) 1995-2008 Xilinx, Inc.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____ 
--  /   /\/   / 
-- /___/  \  /    Vendor: Xilinx 
-- \   \   \/     Version : 10.1
--  \   \         Application : sch2vhdl
--  /   /         Filename : top_level.vhf
-- /___/   /\     Timestamp : 03/01/2015 21:56:37
-- \   \  /  \ 
--  \___\/\___\ 
--
--Command: /opt/Xilinx/10.1/ISE/bin/lin/unwrapped/sch2vhdl -intstyle ise -family spartan2e -flat -suppress -w /home/gasiba/Tests/test_0003/ISE/test_0003/top_level.sch top_level.vhf
--Design Name: top_level
--Device: spartan2e
--Purpose:
--    This vhdl netlist is translated from an ECS schematic. It can be 
--    synthesis and simulted, but it should not be modified. 
--

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
library UNISIM;
use UNISIM.Vcomponents.ALL;

entity top_level is
   port ( ADDR_IN  : in    std_logic_vector (3 downto 0); 
          CLK_IN   : in    std_logic; 
          DATA_OUT : out   std_logic_vector (7 downto 0));
end top_level;

architecture BEHAVIORAL of top_level is
   component rom
      port ( clk  : in    std_logic; 
             addr : in    std_logic_vector (3 downto 0); 
             dout : out   std_logic_vector (7 downto 0));
   end component;
   
begin
   XLXI_1 : rom
      port map (addr(3 downto 0)=>ADDR_IN(3 downto 0),
                clk=>CLK_IN,
                dout(7 downto 0)=>DATA_OUT(7 downto 0));
   
end BEHAVIORAL;


