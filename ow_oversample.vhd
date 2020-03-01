----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.parameters.all;

entity ow_oversample is
    port(
        clk : in std_logic;
        rx : in std_logic;
        sample : out std_logic;
        ce : out std_logic;
        rst : in std_logic
    );
end ow_oversample;

architecture rtl of ow_oversample is
    
    -- constant ow_sample_rate : natural := 9;
    
    signal sample_reg : std_logic_vector(ow_sample_rate - 1 downto 0);
    signal mask_reg : std_logic_vector(ow_sample_rate downto 0);

begin

    process(rst,clk)
    begin
        if (rst = '1') then
            sample_reg <= (others => '1');
            mask_reg(mask_reg'left) <= '1';
            mask_reg(mask_reg'left - 1 downto 0) <= (others => '0');
            sample <= '1';
        elsif (rising_edge(clk)) then
            mask_reg <= mask_reg(mask_reg'left - 1 downto 0) & mask_reg(mask_reg'left);
            
            if (mask_reg(ow_sample_rate - 1) = '1' ) then                
                sample <= sample_reg(ow_sample_rate / 2 + 1);
                sample_reg <= (others => '1');            
            elsif (rx = '0') then
                sample_reg <= sample_reg(sample_reg'left - 1 downto 0) & rx;
            end if;
        end if;    
    end process;
    
    ce <= mask_reg(ow_sample_rate - 1);
    
end rtl;
