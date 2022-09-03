----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/31/2022 04:14:27 PM
-- Design Name: 
-- Module Name: do_pivoting - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity divider_32 is
  Port (   dividend_tdata : in STD_LOGIC_VECTOR (31 downto 0);
           dividend_tvalid: in STD_LOGIC;
           divisor_tdata : in STD_LOGIC_VECTOR (31 downto 0);
           divisor_tvalid: in STD_LOGIC;
           clk : in STD_LOGIC;
           dout_tdata : out STD_LOGIC_VECTOR (31 downto 0);
           dout_tvalid: out STD_LOGIC );
end divider_32;


architecture Behavioral of divider_32 is
component div_gen_0
    port(
    aclk : IN STD_LOGIC;
    s_axis_divisor_tvalid : IN STD_LOGIC;
    s_axis_divisor_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_dividend_tvalid : IN STD_LOGIC;
    s_axis_dividend_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_dout_tvalid : OUT STD_LOGIC;
    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(55 DOWNTO 0));
end component;

signal dout_tdata_55: STD_LOGIC_VECTOR(55 DOWNTO 0);
signal dout_tdata_mid: STD_LOGIC_VECTOR(55 DOWNTO 0);
--signal divisor_tdata_s: STD_LOGIC_VECTOR(31 DOWNTO 0);
--signal dividend_tdata_s: STD_LOGIC_VECTOR(31 DOWNTO 0);

signal dout_tdata_div: STD_LOGIC_VECTOR(55 DOWNTO 0);
signal divisor_tdata_div: STD_LOGIC_VECTOR(31 DOWNTO 0);
signal dividend_tdata_div: STD_LOGIC_VECTOR(31 DOWNTO 0);
constant WIDTH :natural:=57;
signal xor_next: STD_LOGIC_VECTOR(WIDTH-1 downto 0);
signal xor_reg: STD_LOGIC_VECTOR(WIDTH downto 0);
begin
    div: div_gen_0
    port map(
        aclk => clk,
        s_axis_divisor_tvalid => divisor_tvalid,
        s_axis_divisor_tdata => divisor_tdata_div,
        s_axis_dividend_tvalid => dividend_tvalid,
        s_axis_dividend_tdata => dividend_tdata_div,
        m_axis_dout_tvalid => dout_tvalid,
        m_axis_dout_tdata => dout_tdata_div
    );
    xor_reg(WIDTH)<=divisor_tdata(31) xor dividend_tdata(31);
    dff_gen:for i in (WIDTH-1) downto 0 generate
        process(clk)
        begin
            if(rising_edge(clk)) then
                xor_reg(i)<=xor_next(i);
            end if;
        end process;
        xor_next(i)<=xor_reg(i+1);
    end generate;
    
    process(dividend_tdata,divisor_tdata)
    begin
        divisor_tdata_div<=divisor_tdata;
        dividend_tdata_div<=dividend_tdata;
        
        if(divisor_tdata(31)='1') then
            divisor_tdata_div<=std_logic_vector(unsigned(not divisor_tdata)+1);
        end if;
        if(dividend_tdata(31)='1') then
            dividend_tdata_div<=std_logic_vector(unsigned(not dividend_tdata)+1);
        end if;
        
    end process;
    process(dout_tdata_div,dout_tdata_mid,xor_reg(0))
    begin
        dout_tdata_mid<=dout_tdata_div;
        dout_tdata_55<=dout_tdata_mid;
        if(dout_tdata_div(21)='1') then
            dout_tdata_mid<=std_logic_vector(unsigned(dout_tdata_div)-1048576);
        end if;
        if(xor_reg(0)='1')  then --trebaju registri da cuvaju znakove kako ulaze
            dout_tdata_55<=std_logic_vector(unsigned(not dout_tdata_mid)+1);--ili 1
            report "xor je okino";
        --elsif(dout_tdata_div(21)='1') then
        --    dout_tdata_55<=std_logic_vector(unsigned(dout_tdata_div)-1048576);
        end if;
        
       -- if(dout_tdata_55(0) = '1') then
          --  dout_tdata_55 <= std_logic_vector(unsigned(dout_tdata_div)-1);
       -- end if;
    end process;
    
    --process(clk) is
    --begin
    --    if(rising_edge(clk)) then
            dout_tdata <= dout_tdata_55(30 DOWNTO 0)&'0';
    --    end if;
    --end process;
    
    
end Behavioral;
