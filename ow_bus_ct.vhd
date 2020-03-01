----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

library work;
use work.parameters.all;

entity ow_bus_ct is
	port(
        clk : in std_logic;
        d : in std_logic_vector (ow_ct_data_width downto 0);
        l : in std_logic;
        ce : in std_logic;
        q : out std_logic;
        rst : in std_logic
	);
end ow_bus_ct;

architecture rtl of ow_bus_ct is
    
    signal ct_reg : std_logic_vector(ow_ct_data_width downto 0);

begin
    
    q <= ct_reg(ct_reg'left);
    
    process (rst, clk)
    begin        
        if (rst = '1') then            
            ct_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            if (l = '1') then
                ct_reg <= d; 
            elsif (ce = '1') then
                ct_reg <= CONV_STD_LOGIC_VECTOR((CONV_INTEGER(ct_reg) + 1), ct_reg'length);  
            else
                null;            
            end if;           
        end if;
    end process;

end rtl;

