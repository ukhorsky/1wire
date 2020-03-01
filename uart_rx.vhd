---------------------------------------------------------------------------------------------
--! UART interface based on http://web.engr.oregonstate.edu/~traylor/ece473/lectures/uart.pdf
--! Main idea is to use x16 uart speed to sample data
---------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.parameters.all;

entity uart_rx is
    port(
        clk : in std_logic;
        rx : in std_logic;        
        data_rx : out std_logic_vector (7 downto 0);
        byte : out std_logic;
        rst : in std_logic
    );
end uart_rx;

architecture rtl of uart_rx is

    constant counter_max : std_logic_vector(uart_rx_ct_len - 1 downto 0) := CONV_STD_LOGIC_VECTOR(uart_rx_ct_max, uart_rx_ct_len);
    
    type fsm_states is (S0, S1, S2, S3, S4);
    
    signal state,nextstate : fsm_states;
    signal sample : std_logic_vector (2 downto 0);
    signal cycles : std_logic_vector (4 downto 0);
    signal counter : std_logic_vector (uart_rx_ct_len - 1 downto 0);
    signal busyreg : std_logic_vector (9 downto 0);
    signal datareg : std_logic_vector (9 downto 0);
    
begin

    fsm_reg: process (rst,clk)
    begin
        if (rst = '1') then
            state <= S0;
        elsif (rising_edge(clk)) then
            state <= nextstate;
       end if;
    end process;
    
    fsm_nextstate_logic: process(state, rx, cycles, busyreg, sample)
    begin
        case state is
            when S0 =>
                if (rx = '0') then
                    nextstate <= S1;
                else
                    nextstate <= S0;
                end if;    
            when S1 =>
                if (cycles < "01001") then
                    nextstate <= S1;
                else
                    if (sample = "000") then
                        nextstate <= S2;
                    else
                        nextstate <= S0;
                    end if;
                end if;    
            when S2 =>
                nextstate <= S3;
            when S3 =>    
                if (busyreg(0) = '0') then
                    nextstate <= S4;
                else
                    if(cycles(4) = '1') then
                        nextstate <= S2;
                    else
                        nextstate <= S3;
                    end if;
                end if;    
            when S4 =>
                nextstate <= S0;
            when others =>
                null;
        end case;    
    end process;
    
	fsm_otput_logic: process (rst, clk)
    begin
        if (rst = '1') then
            byte <= '0';
            busyreg <= (others => '1');
            datareg <= (others => '0');
            cycles <= (others => '0');
        elsif (rising_edge(clk)) then
            data_rx <= datareg (8 downto 1);
            case state is 
                when S0 =>                    
                    byte <= '0';
                    busyreg <= (others => '1');
                    cycles <= (others => '0');
                    counter <= (others => '0');
                when S1 =>
                    if (counter = counter_max) then
                        counter <= (others => '0');
                        sample <= rx & sample(sample'left downto 1);
                        cycles <= conv_std_logic_vector(conv_integer(cycles) + 1, cycles'length);                            
                    else 
                        counter <= conv_std_logic_vector(conv_integer(counter) + 1, counter'length);
                    end if;
                when S2 =>
                    cycles <= (others => '0');
                    counter <= (others => '0');
                    datareg <= (sample(0) and sample(1) and sample(2)) & datareg(datareg'left downto 1);
                    busyreg <= '0' & busyreg(busyreg'left downto 1);
                when S3 =>
                    if (counter = counter_max) then
                        counter <= (others => '0');
                        sample <= rx & sample(sample'left downto 1);
                        cycles <= conv_std_logic_vector(conv_integer(cycles) + 1, cycles'length);   
                    else 
                        counter <= conv_std_logic_vector(conv_integer(counter) + 1, counter'length);
                    end if;
                when S4 =>
                    if ((datareg(9) and not datareg(0)) = '1') then
                        byte <= '1';
                    else
                        byte <= '0';
                    end if;    
                when others =>
                    null;
            end case;        
        end if;
    end process;

end rtl;

