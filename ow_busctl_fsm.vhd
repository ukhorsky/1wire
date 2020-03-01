----------------------------------------------------------------------------------
-- 1-Wire bus control FSM
-- Main idea is that during all basic opperarions (bus reset, bit tx, bit rx)
-- device passes the similar number of states: initial pull down, bus recovery,
-- main operations (presence pulse, data sampling, data output), one more recovery.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity ow_busctl_fsm is
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        cmd         : in std_logic_vector(1 downto 0);
        q           : in std_logic;
        tx          : in std_logic;
        data_bus    : in std_logic;
        rx_valid    : out std_logic;
        addr        : out std_logic_vector(2 downto 0);
        l           : out std_logic;
        status      : out std_logic_vector(1 downto 0);
        bus_pdwn    : out std_logic;
        ce          : out std_logic
   );     
end ow_busctl_fsm;

architecture rtl of ow_busctl_fsm is

    type state is (S0, S1, S2, S3, S4, S5, S6);
    
    signal c_state, n_state : state;
    
begin

    state_reg: process (rst, clk)
    begin
        if (rst = '1') then
            c_state <= S0;
        elsif (rising_edge(clk)) then
            c_state <= n_state;
        end if;	
    end process;

    next_state_logic: process (c_state, q, cmd, data_bus)
    begin
        case c_state is
            when S0 =>
                if ((data_bus and (cmd(1) or cmd(0))) = '1') then
                    n_state <= S1;
                else
                    n_state <= S0;
                end if;
            when S1 =>                
                if (q = '1') then
                    if(cmd = "01") then
                        n_state <= S6;
                    else
                        n_state <= S2;
                    end if;
                else
                    n_state <= S1;
                end if;
            when S2 =>
                if (((cmd(1) and q) or (not cmd(1) and not data_bus)) = '1') then
                    n_state <= S3;
                elsif ((not cmd(1) and data_bus and q) = '1') then
                    n_state <= S0;
                else
                    n_state <= S2;
                end if;
            when S3 =>
                -- NB! Presence Detect Low meaning shall be checked!!!
                if (q = '1') then
                    n_state <= S4;
                elsif ((not cmd(1) and data_bus) = '1') then
                    n_state <= S0;
                else
                    n_state <= S3;
                end if;    
            when S4 =>
                if (q = '1') then
                    n_state <= S5;
                else
                    n_state <= S4;
                end if;
            when S5 =>
                n_state <= S0;
            when S6 =>
                if (data_bus = '1') then
                    n_state <= S2;
                else
                    n_state <= S6;
                end if;
            when others =>
                null;
        end case;	
    end process;

    output_logic: process (rst, clk)   
    begin        
        if (rst = '1') then
            addr <= (others => '0');
            l <= '0';
            ce <= '0';
            rx_valid <= '0';
            status <= (others => '0');
            bus_pdwn <= '0';
        elsif (rising_edge(clk)) then
            case c_state is
                when S0 =>
                    status <= (not data_bus) & (cmd(1) or cmd(0));
                    addr <= cmd(1) & "00";
                    l <= cmd(1) or cmd(0);
                    ce <= cmd(1) or cmd(0);
                    bus_pdwn <= '0';
                    rx_valid <= '0';
                when S1 =>                    
                    bus_pdwn <= not q or cmd(1);
                    l <= '0';
                    ce <= '1';
                    rx_valid <= '0';
                    addr <= cmd(1) & "01";
                when S2 =>
                    ce <= cmd(1) or data_bus;
                    addr <= cmd(1) & "10";
                    l <= not cmd(1) and cmd(0) and not data_bus;
                    status <= (not cmd(1) and cmd(0) and data_bus and q) & '1';
                    rx_valid <= cmd(1) and not cmd(0) and q;
                    bus_pdwn <= not tx and cmd(1) and cmd(0);
                when S3 =>
                    l <= '0';
                    ce <= '1';
                    rx_valid <= '0';
                    addr <= cmd(1) & "11";
                    bus_pdwn <= not tx and cmd(1) and cmd(0);
                    status <= (not cmd(1) and cmd(0) and data_bus) & '1'; 
                when S4 =>
                    l <= '0';
                    ce <= '1';
                    status <= "0" & not q;
                    bus_pdwn <= '0';
                    addr <= (others => '0');
                    rx_valid <= '0';
                when S5 =>
                    l <= '0';
                    ce <= '0';
                    status <= "00";
                    bus_pdwn <= '0';
                    addr <= (others => '0');
                    rx_valid <= '0';
                when S6 =>
                    l <= '0';
                    ce <= '0';
                    status <= "01";
                    bus_pdwn <= '0';
                    addr <= cmd(1) & "01";
                    rx_valid <= '0';
                when others =>
                    null;
            end case;		
        end if;	
    end process;
end rtl;