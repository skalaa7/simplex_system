----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/03/2022 10:03:50 PM
-- Design Name: 
-- Module Name: ip_pivot - Behavioral
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

--use ieee.std_logic_arith.all;
--use IEEE.MATH_REAL.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ip_pivot is
    generic (COLSIZE: integer := 101;
             ROWSIZE: integer := 51);
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
           
           mux_sel: out std_logic
           );
end ip_pivot;

architecture Behavioral of ip_pivot is
--declaration of divider component
    component divider_32
    Port (      dividend_tdata : in STD_LOGIC_VECTOR (31 downto 0);
                dividend_tvalid: in STD_LOGIC;
                divisor_tdata : in STD_LOGIC_VECTOR (31 downto 0);
                divisor_tvalid: in STD_LOGIC;
                clk : in STD_LOGIC;
                dout_tdata : out STD_LOGIC_VECTOR (31 downto 0);
                dout_tvalid: out STD_LOGIC );
    end component;
    --declaration of dsp component
    component dsp is
        generic(WIDTHA:natural:=32;
                WIDTHB:natural:=32;
                SIGNED_UNSIGNED: string:= "signed");
        Port ( clk: in std_logic;
                a_i: in std_logic_vector (31 downto 0);
                b_i: in std_logic_vector (31 downto 0);
                c_i: in std_logic_vector (31 downto 0);
                res_o: out std_logic_vector(31 downto 0));
        end component dsp;
   
    type state_type is (idle,S0,s1a,S1, S2,s2a, S3, S4, S5, S6, s6a, s6b,s6c, s7,s8,s9,s10, s11,s12,s13,s14,s15); --, S7, S8,S9, S10, S11, S12, S13, S14
    signal state_reg, state_next: state_type;
 
 --signals for counters
    signal i_reg, i_next: STD_LOGIC_VECTOR(6 downto 0);
    signal j_reg, j_next: STD_LOGIC_VECTOR(6 downto 0);
    
 --signals
    signal pivotCol_reg, pivotCol_next: STD_LOGIC_VECTOR(31 downto 0);
    signal pivot_reg, pivot_next: STD_LOGIC_VECTOR(31 downto 0);
 
 --signals for a (first) memory port
    --signal data1_in_reg, data1_in_next: STD_LOGIC_VECTOR(31 downto 0);
    signal addr1_reg, addr1_next: STD_LOGIC_VECTOR(12 downto 0);
    signal en1_reg, en1_next: STD_LOGIC;
    signal we1_reg, we1_next: STD_LOGIC;
    signal data1_out_reg, data1_out_next: STD_LOGIC_VECTOR(31 downto 0);
    
 --signals for b (second memory port)
    --signal data2_in_reg, data2_in_next: STD_LOGIC_VECTOR(31 downto 0);
    signal addr2_reg, addr2_next: STD_LOGIC_VECTOR(12 downto 0);
    signal en2_reg, en2_next: STD_LOGIC;
    signal we2_reg, we2_next: STD_LOGIC;
    signal data2_out_reg, data2_out_next: STD_LOGIC_VECTOR(31 downto 0);
 
    type newRow_type is array (0 to 100)
                  of STD_LOGIC_VECTOR(31 downto 0);
    signal newRow_reg,newRow_next: newRow_type;
 
    type pivotColVal_type is array (0 to 50)
                  of STD_LOGIC_VECTOR(31 downto 0);
 
    signal pivotColVal_reg, pivotColVal_next : pivotColVal_type;
 
    --signals for divider
    signal  dividend_tdata_s : STD_LOGIC_VECTOR (31 downto 0);
    signal  dividend_tvalid_s: STD_LOGIC;
    signal  divisor_tdata_s :  STD_LOGIC_VECTOR (31 downto 0);
    signal  divisor_tvalid_s:  STD_LOGIC;
    signal  dout_tdata_s :     STD_LOGIC_VECTOR (31 downto 0);
    signal  dout_tvalid_s:     STD_LOGIC ;

    -- signals for DSP1
    signal a_i_s_1, b_i_s_1,c_i_s_1: std_logic_vector(31 downto 0);
    signal res_o_s_1:            std_logic_vector(31 downto 0);
    -- signals for DSP1
    signal a_i_s_2, b_i_s_2,c_i_s_2: std_logic_vector(31 downto 0);
    signal res_o_s_2:            std_logic_vector(31 downto 0);
    
    signal addr1_reg_100: std_logic;
begin
 --port map for divider
 div: divider_32
     port map
      (    dividend_tdata =>  dividend_tdata_s,
           dividend_tvalid => dividend_tvalid_s,
           divisor_tdata =>   divisor_tdata_s,
           divisor_tvalid =>  divisor_tvalid_s,
           clk  =>            clk,
           dout_tdata =>      dout_tdata_s,
           dout_tvalid =>     dout_tvalid_s
      );
 --generic and port map for DSP
 dsp1: dsp
        generic map(
        WIDTHA => 32,
        WIDTHB => 32,
        SIGNED_UNSIGNED => "signed"
        )
        port map(
            a_i   => a_i_s_1,
            b_i   => b_i_s_1,
            clk   => clk,
            c_i   => c_i_s_1,
            res_o => res_o_s_1
        );
        
  dsp2: dsp
        generic map(
        WIDTHA => 32,
        WIDTHB => 32,
        SIGNED_UNSIGNED => "signed"
        )
        port map(
            a_i   => a_i_s_2,
            b_i   => b_i_s_2,
            clk   => clk,
            c_i   => c_i_s_2,
            res_o => res_o_s_2
        );
 ---------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------
 
 --state and data register
    process(reset, clk) begin
        if (rising_edge(clk)) then
            if (reset = '1') then
            --INNER SIGNALS AND STATES
                state_reg <= idle;
                
                i_reg <= (others => '0');
                j_reg <= (others => '0');
                pivotCol_reg <= (others => '0');
                pivot_reg <= (others => '0');
                
                 for index in 0 to 100 loop
                    newRow_reg(index) <= (others => '0');
                 end loop;
            --51 register defining pivotColVal
                 for index in 0 to 50 loop
                     pivotColVal_reg(index) <= (others => '0');
                 end loop;
                 
             --INTERFACE
                
                addr1_reg  <= (others => '0');
                en1_reg <= '0';
                we1_reg <= '0';
                data1_out_reg <= (others => '0');--------------------------------------
            
                
                addr2_reg  <= (others => '0');
                en2_reg <= '0';
                we2_reg <= '0';
                data2_out_reg <= (others => '0');
                
                
                
              else
                state_reg <= state_next;
                
                i_reg <= i_next;----------------------------------------------
                j_reg <= j_next;
                pivotCol_reg <= pivotCol_next;
                pivot_reg <= pivot_next;
                
                
                 for index in 0 to 100 loop
                    newRow_reg(index) <= newRow_next(index);
                 end loop;
            --51 register defining pivotColVal
                 for index in 0 to 50 loop
                     pivotColVal_reg(index) <= pivotColVal_next(index);
                 end loop;
                 
             --INTERFACE
                
                addr1_reg  <= addr1_next;
                en1_reg <= en1_next;
                we1_reg <= we1_next;
                data1_out_reg <= data1_out_next ;
            
               
                addr2_reg  <= addr2_next;
                en2_reg <= en2_next ;
                we2_reg <= we2_next;
                data2_out_reg <= data2_out_next;                
              end if;
        end if;
    end process;
    
    --Combinatorial Circuits
    process( dout_tvalid_s,dout_tdata_s,state_reg, start, i_reg,i_next, j_reg,j_next, data1_in, data2_in, pivotCol_reg,pivotCol_next, pivot_reg,pivot_next, newRow_reg, newRow_next,pivotColVal_reg,pivotColVal_next, addr1_reg ,addr1_next ,
                                                                                                                     en1_reg,en1_next, we1_reg,we1_next , data1_out_reg,data1_out_next,res_o_s_1,res_o_s_2,
                                                                                                                     addr2_reg ,addr2_next , en2_reg,en2_next, we2_reg,we2_next, data2_out_reg,data2_out_next)
    begin
        --Default Assignments
            state_next <= state_reg;
            
         --OUTPUT INTERFACE
            ready <= '0';
            
          --INNER SIGNALS
            i_next <= i_reg;
            j_next <= j_reg;
            pivotCol_next <= pivotCol_reg;
            pivot_next <= pivot_reg;
            newRow_next <= newRow_reg;
            pivotColVal_next <= pivotColVal_reg;
            
            
          --INTERFACE
                --data1_in_next <= data1_in_reg;
                addr1_next  <= addr1_reg;
                --en1_next <= en1_reg;
                en1_next <= '1'; --- DODATO!!!!
                we1_next <= we1_reg;
                data1_out_next <= data1_out_reg ;
            
                --data2_in_next <= data2_in_reg;
                addr2_next  <= addr2_reg;
                --en2_next <= en2_reg ;
                 en2_next <= en2_reg; ---- DODATO!!!!
                we2_next <= we2_reg;
                data2_out_next <= data2_out_reg; 
                
                dividend_tdata_s <= (others => '0');
                dividend_tvalid_s <= '0';
                divisor_tdata_s <= (others => '0');
                divisor_tvalid_s <= '0';
                
                c_i_s_1 <= (others => '0');
                a_i_s_1 <= (others => '0');
                b_i_s_1 <= (others => '0');
                    
                c_i_s_2 <= (others => '0');
                a_i_s_2 <= (others => '0');
                b_i_s_2 <= (others => '0');
                
                mux_sel <= '1';
                
           case state_reg is
            when idle =>
                    ready <= '1';
                    mux_sel <= '0';
                    
                    if(start = '1') then
                        mux_sel <= '1';
                        state_next <= s0;
                        i_next <= (others => '0');
                        addr1_next <= "1010000011111"; --5151
                        we1_next <= '0';
                        we2_next <= '0';
                    else
                        state_next <= idle;
                    end if;
             when S0 =>
                --addr1_next <= "1010000011111"; --5151
                state_next <= S1;
             --when s0a =>
             --    state_next <= S1;
             
             when S1 =>
                pivotCol_next <= "000000000000000000000" & data1_in(31 downto 21);
                addr1_next <= "00" & data1_in(31 downto 21);--& pivotCol_next(31 DOWNTO 22); --pivotCol_next(12 DOWNTO 0);
                state_next <= S1a;
             when s1a =>
                state_next <= s2a;
             when s2a=>
                state_next<=s2;
             when S2 =>
                pivot_next <= data1_in;
                addr1_next <= (others => '0');
                state_next <= S3;
             when S3 =>
               dividend_tvalid_s <= '1';
               divisor_tvalid_s <= '1';
               dividend_tdata_s <= data1_in;
               divisor_tdata_s <= pivot_reg;
               addr1_next <= STD_LOGIC_VECTOR(unsigned(addr1_reg) + 1);
               if(dout_tvalid_s = '1') then
                    state_next <= S4;
               else
                    state_next <= S3;
               end if;
             when S4 =>
                    newRow_next(conv_integer(i_reg)) <= dout_tdata_s;
                    dividend_tvalid_s <= '1';
                    divisor_tvalid_s <= '1';
                    dividend_tdata_s <= data1_in;
                    divisor_tdata_s <= pivot_reg;
                    addr1_next <= STD_LOGIC_VECTOR(unsigned(addr1_reg) + 1);
                    i_next <= STD_LOGIC_VECTOR(unsigned(i_reg) + 1);
                    if(addr1_reg = 101) then
                        state_next <= S5;
                    else
                        state_next <= S4;
                    end if;
             when S5 =>
                   dividend_tvalid_s <= '0';
                   divisor_tvalid_s <= '0';
                   newRow_next(conv_integer(i_reg)) <= dout_tdata_s;
                   addr1_next <= "0000000000000";
                   i_next <= STD_LOGIC_VECTOR(unsigned(i_reg) + 1);
                   if(i_reg = 100) then
                        state_next <= S6; --s5a
                        addr1_next <= "0000000000000";
                        data1_out_next <= newRow_reg(0);
                        -- CHANGE ROW 359
                        we1_next <= '1';
                        i_next <= "0000001";
                   else
                        state_next <= S5;
                   end if;
             --when s5a =>
             --      addr1_next <= (others => '0');
             --      data1_out_next <= newRow_reg(0);
                   --
             --      state_next<=s6;
             when S6 =>
                    --address = 0
                   data1_out_next <= newRow_reg(conv_integer(i_reg));
                   addr1_next <= STD_LOGIC_VECTOR(unsigned(addr1_reg) + 1);
                   i_next <= STD_LOGIC_VECTOR(unsigned(i_reg) + 1);
                   we1_next <= '1';
                   if(addr1_reg = 99) then
                         --state_next <= S7; promena skalice!!!!!!!!!!!!!!
                         state_next <= s6a;
                         --addr1_next <= STD_LOGIC_VECTOR(unsigned(pivotCol_reg(12 downto 0)) + COLSIZE);
                         --we1_next <= '0';
                    else                                          
                        state_next <= S6; 
                        
                    end if;
               when s6a =>
                   data1_out_next <=  newRow_reg(0);
                   addr1_next <= (others => '0');
                   we1_next <= '1';
                   i_next <= (others => '0');
                   state_next <= s6b; 
               when s6b =>
                     we1_next <= '0';
                     state_next <= s6c;
               when s6c =>
                     addr1_next <= STD_LOGIC_VECTOR(unsigned(pivotCol_reg(12 downto 0)) + COLSIZE);--STD_LOGIC_VECTOR(to_unsigned(19, 13) + COLSIZE);--unsigned(pivotCol_reg)
                     state_next <= s7; --ovde je pokrenut mod citanja     
               when S7 =>
                    
                    pivotColVal_next(conv_integer(i_reg)) <= data1_in;
                    addr1_next <= STD_LOGIC_VECTOR(unsigned(addr1_reg) + COLSIZE);
                    i_next <= STD_LOGIC_VECTOR(unsigned(i_reg) + 1);
                    if(i_reg = 50) then ----------------------------------------------NOVO!!!!!!!1
                       i_next <= (others => '0');
                       state_next <= s8;
                       addr1_next <= std_logic_vector(to_unsigned(COLSIZE, 13));
                       addr2_next <= std_logic_vector(to_unsigned(COLSIZE+COLSIZE, 13));
                       en2_next <= '1';
                       j_next <= std_logic_vector(to_unsigned(1, 7));
                    else
                       state_next <= S7;
                    end if;
           --              
               when S8 =>
                    
                    
                    state_next <= s9;
              when S9 =>
                    c_i_s_1 <= data1_in;
                    a_i_s_1 <= newRow_reg(conv_integer(i_reg));
                    b_i_s_1 <= pivotColVal_reg(conv_integer(j_reg));
                    
                    c_i_s_2 <= data2_in;
                    a_i_s_2 <= newRow_reg(conv_integer(i_reg));
                    b_i_s_2 <= pivotColVal_reg(conv_integer(j_reg) + 1);
                    state_next <= S10;
              when S10 =>
                    state_next <= s11;
                when S11 =>
                    state_next <= s12;
                    we1_next <= '1';
                    we2_next <= '1';
                when s12 =>
                    
                    data1_out_next <= res_o_s_1;
                    data2_out_next <= res_o_s_2;
                    we1_next <= '0';
                    we2_next <= '0';
                    state_next <= idle;
                   if( i_reg = COLSIZE - 1) then
                         state_next <= S13;
                    else
                        state_next <= S14;    
                    end if;   
                when S13 =>
                   
                    if(j_reg = ROWSIZE - 2) then
                        state_next <= idle;    
                     else
                        state_next <= S15;
                    end if;
               when S14 =>       
                        i_next <= STD_LOGIC_VECTOR(unsigned(i_reg) + 1);
                        --j_next <= STD_LOGIC_VECTOR(unsigned(j_reg) + 2);
                        addr1_next <= STD_LOGIC_VECTOR(unsigned(addr1_reg) + 1);
                        addr2_next <= STD_LOGIC_VECTOR(unsigned(addr2_reg) + 1); 
                        state_next <= S8;
                when S15 =>
                         i_next <= (others => '0');
                         j_next <= STD_LOGIC_VECTOR(unsigned(j_reg) + 2);
                        addr1_next <= STD_LOGIC_VECTOR(unsigned(addr1_reg) + COLSIZE + 1);
                        addr2_next <= STD_LOGIC_VECTOR(unsigned(addr2_reg) + COLSIZE + 1); 
                        state_next <= S8;    
           end case;
    end process;                                                                                                                   
      
    --addr1_reg100: process(addr1_reg) is
     --             begin
     --               if( addr1_reg = 101) then
     --                   addr1_reg_100 <= '1';
     --               else
     --                   addr1_reg_100 <= '0';
     --               end if;
     --             end process;
    data1_out <= data1_out_next;
    address1 <= addr1_next;
    we1 <= we1_reg;
    en1_out <= en1_reg;
    
    data2_out <= data2_out_next;
    we2 <= we1_reg;
    address2 <= addr2_next;
    en2_out <= en2_next;
    
end Behavioral;