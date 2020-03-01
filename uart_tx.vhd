----------------------------------------------------------------------------------
--! UART interface based on Intro to Spartan-3 FPGA book 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.parameters.all;

entity uart_tx is
    port(
        clk : in std_logic;
        load : in std_logic;
        data_tx : in std_logic_vector (7 downto 0);
        tx : out std_logic;
        busy : out std_logic;
        rst : in std_logic
    );
end uart_tx;

architecture rtl of uart_tx is

    constant counter_max : std_logic_vector(uart_tx_ct_len - 1 downto 0) := CONV_STD_LOGIC_VECTOR(uart_tx_ct_max, uart_tx_ct_len);
    
    signal busyreg : std_logic_vector (9 downto 0) := (others => '0');
    signal datareg : std_logic_vector (9 downto 0) := (others => '1');
    signal counter : std_logic_vector (uart_tx_ct_len - 1 downto 0) := (others => '0');

begin
    
    -----------------------------------------------------------------------
    -- UART transmitter
    -----------------------------------------------------------------------
    
    tx <= datareg(0);
    busy <= busyreg(0);
        
    process(rst,clk)
    begin
        if (rst = '1') then
            datareg <= (others => '1');
            busyreg <= (others => '0');
            counter <= (others => '0');
        elsif (rising_edge(clk)) then
            if (busyreg(0) = '0') then
                if (load = '1') then
                    datareg <= '1' & data_tx & '0';
                    busyreg <= (others => '1');
                end if;    
                
                counter <= (others => '0');
            else
                if (counter = counter_max) then
                    datareg <= '1' & datareg(datareg'left downto 1);
                    busyreg <= '0' & busyreg(busyreg'left downto 1);
                    counter <= (others => '0');
                else                    
                    counter <= CONV_STD_LOGIC_VECTOR(CONV_INTEGER(counter) + 1, counter'length);
                end if;    
            end if;    
        end if;    
    end process;           

end rtl;

