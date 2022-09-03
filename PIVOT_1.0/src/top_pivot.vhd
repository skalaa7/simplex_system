----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/08/2022 07:34:32 PM
-- Design Name: 
-- Module Name: top_pivot - Behavioral
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

entity top_pivot is
     Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           start : in STD_LOGIC;
           ready : out STD_LOGIC;
           --software to memory
           en_s : IN STD_LOGIC;
           we_s : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
           addr_s : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
           data_in_s : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
           data_out_s : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
end top_pivot;

architecture Behavioral of top_pivot is
component blk_mem_gen_0
PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
end component;


component ip_pivot
    Port ( clk : in STD_LOGIC;
           reset: in STD_LOGIC;
           --FIRST MEMORY PORT
           data1_in : in STD_LOGIC_VECTOR(31 DOWNTO 0);
           address1 : out STD_LOGIC_VECTOR(12 DOWNTO 0);
           data1_out : out STD_LOGIC_VECTOR(31 DOWNTO 0);
           en1_out : out STD_LOGIC;
           we1 : out STD_LOGIC;
           --SECOND MEMORY PORT
           data2_in : in STD_LOGIC_VECTOR(31 DOWNTO 0);
           address2 : out STD_LOGIC_VECTOR(12 DOWNTO 0);
           data2_out : out STD_LOGIC_VECTOR(31 DOWNTO 0);
           en2_out : out STD_LOGIC;
           we2 : out STD_LOGIC;
           
           start : in STD_LOGIC;
           ready: out STD_LOGIC;
           
           mux_sel : out STD_LOGIC
           
           );
end component;

--singnals for bram 
signal    ena_bram :  STD_LOGIC;
signal    wea_bram :  STD_LOGIC;
signal    addra_bram :  STD_LOGIC_VECTOR(12 DOWNTO 0);
signal    dina_bram : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal    douta_bram :  STD_LOGIC_VECTOR(31 DOWNTO 0);

signal    enb_muxout :  STD_LOGIC;
signal    web_muxout :  STD_LOGIC;
signal    addrb_muxout :  STD_LOGIC_VECTOR(12 DOWNTO 0);
signal    dinb_muxout :  STD_LOGIC_VECTOR(31 DOWNTO 0);
signal    doutb_demuxin :  STD_LOGIC_VECTOR(31 DOWNTO 0);

--referenciraju se na ip
signal data2_in_mux1 : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal address2_mux1 : STD_LOGIC_VECTOR(12 DOWNTO 0);
signal data2_out_demux1 : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal en2_out_mux1 : STD_LOGIC;
signal we2_mux1 : STD_LOGIC;

SIGNAL mux_sel_s:STD_LOGIC;

begin

bram:blk_mem_gen_0
     port map
     (
    --memorija mapirana na pomocne
    
    clka => clk,
    ena => ena_bram,
    wea(0) => wea_bram,
    addra => addra_bram,
    dina => dina_bram,
    douta => douta_bram,
    
    clkb => clk,
    enb => enb_muxout,
    web(0) => web_muxout,
    addrb => addrb_muxout,
    dinb => dinb_muxout,
    doutb => doutb_demuxin
     );
     
ip_core: ip_pivot
   port map( clk => clk,
             reset => reset,
           --FIRST MEMORY PORT
           data1_in => douta_bram,
           address1 => addra_bram,
           data1_out => dina_bram,
           en1_out => ena_bram,
           we1 => wea_bram,
           --SECOND MEMORY PORT
           data2_in => data2_out_demux1,
           address2 => address2_mux1,
           data2_out => data2_in_mux1 ,
           en2_out => en2_out_mux1,
           we2 => we2_mux1,
           
           start => start,
           ready => ready,
           mux_sel => mux_sel_s
           );
           
process(en_s, we_s, addr_s, data_in_s, start,mux_sel_s,
        address2_mux1, data2_in_mux1, en2_out_mux1, we2_mux1, doutb_demuxin) is
begin
    if(mux_sel_s = '0') then
        addrb_muxout <= addr_s;
        dinb_muxout <= data_in_s;
        enb_muxout <= en_s;
        web_muxout <= we_s(0);
        data_out_s <= doutb_demuxin ;
        data2_out_demux1 <= (others => '0');
    else
        addrb_muxout <= address2_mux1;
        dinb_muxout <= data2_in_mux1;
        enb_muxout <= en2_out_mux1;
        web_muxout <= we2_mux1;
        data_out_s <= (others => '0');
        data2_out_demux1 <= doutb_demuxin;
    end if;
    
end process;
end Behavioral;
