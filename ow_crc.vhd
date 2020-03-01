----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ow_crc is
    port(
        clk : in std_logic;
        rx : in std_logic;
        n_bit : in std_logic;
        crc_err : out std_logic;
        rst : in std_logic
    );
end ow_crc;

architecture rtl of ow_crc is
    signal crc_reg : std_logic_vector(7 downto 0);
    signal crc_reg_xored : std_logic_vector(2 downto 0);
begin
    crc_err <= '0' when crc_reg = x"00" else '1';
    crc_reg_xored(2) <= (crc_reg(0) xor rx);
    crc_reg_xored(1) <= (crc_reg(0) xor rx) xor crc_reg(4);
    crc_reg_xored(0) <= (crc_reg(0) xor rx) xor crc_reg(3);
                     
    process(rst, clk)
    begin
        if (rst = '1') then
            crc_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            if (n_bit = '1') then
                crc_reg <= crc_reg_xored(2) & crc_reg(7 downto 5) &
                           crc_reg_xored(1 downto 0) & crc_reg(2 downto 1);
--                crc_reg <= (crc_reg(0) xor rx) & crc_reg(7 downto 5) & 
--                           (crc_reg(4) xor rx) & (crc_reg(3) xor rx) &
--                            crc_reg(2 downto 1);
            end if;
        end if;    
    end process;
end rtl;

