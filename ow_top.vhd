----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;
use work.parameters.all;

entity ow_top is
    port(
        clk : in std_logic;
        we : in std_logic;
        d_in : in std_logic_vector(15 downto 0);
        data_bus : in std_logic_vector(onewire_channels - 1 downto 0);
        bus_pdwn : out std_logic_vector(onewire_channels - 1 downto 0);
        d_out : out std_logic_vector(15 downto 0);
        int : out std_logic;
        rst : in std_logic
    );
end ow_top;

architecture struct_rtl of ow_top is
    
    component ow_if is
    port(
        clk : in std_logic;
        cmd_in : in std_logic_vector(2 downto 0);
        d_in : in std_logic_vector(7 downto 0);
        cs : in std_logic;
        data_bus : in std_logic;
        acc_check : in std_logic;        
        acc_req : out std_logic;
        d_out : out std_logic_vector(12 downto 0);
        bus_pdwn : out std_logic;
        rst : in std_logic
    );
    end component;
    
    type output_reg is array (0 to onewire_channels - 1) of std_logic_vector(12 downto 0);
    
    signal addr_in : std_logic_vector(onewire_channels - 1 downto 0);
    signal addr_out_buf : std_logic_vector(onewire_channels - 1 downto 0);
    signal addr_out : std_logic_vector(2 downto 0);
    signal d_out_buf : output_reg;
    signal d_in_buf : std_logic_vector(15 downto 0);
    signal dc_in : std_logic_vector (7 downto 0);
    signal acc_man : std_logic;
    signal acc_man_check : std_logic;
    signal cs_e : std_logic;

begin
    
    d_in_reg: process(clk, rst)
    begin
        if (rst = '1') then
            d_in_buf <= (others => '0');
            cs_e <= '0';
        elsif (rising_edge(clk)) then
            if (we = '1') then
                d_in_buf <= d_in;
                cs_e <= '1';
            else
                d_in_buf <= (others => '0');
                cs_e <= '0';
            end if;
        end if;
    end process;

    controls: for i in 0 to (onewire_channels - 1)
    generate
        ow_entity: ow_if
        port map(
            clk => clk,
            cmd_in => d_in_buf(10 downto 8),
            d_in => d_in_buf(7 downto 0),
            cs => addr_in(i),
            data_bus => data_bus(i),
            acc_check => acc_man_check,
            acc_req => addr_out_buf(i),
            d_out => d_out_buf(i),
            bus_pdwn => bus_pdwn(i),
            rst => rst
        );
    end generate;
    
    cd_logic: for i in 0 to (onewire_channels - 1)
    generate
        addr_in(i) <= cs_e when (conv_integer(d_in_buf(15 downto 13)) = i) else '0';        
    end generate;

--    for i in 0 to onewire_channels
--    generate
--        dc_in(i) <= addr_out_buf(i) when (i < onewire_channels) else '0';
--    end generate;
    
    dc_logic: process(addr_out_buf) --dc_in)
        variable dc_in : std_logic_vector(7 downto 0);
    begin
        for i in 0 to onewire_channels - 1
        loop
            dc_in(i) := addr_out_buf(i);
        end loop;

        for i in onewire_channels to 7
        loop
            dc_in(i) := '0';
        end loop;
        
        case dc_in is
            when x"80" =>
                addr_out <= "111";
            when x"40" =>
                addr_out <= "110";
            when x"20" =>
                addr_out <= "101";
            when x"10" =>
                addr_out <= "100";
            when x"08" =>
                addr_out <= "011";
            when x"04" =>
                addr_out <= "010";
            when x"02" =>
                addr_out <= "001";
            when x"01" =>    
                addr_out <= "000";
            when others =>
                addr_out <= "000";
        end case;
        
        if (dc_in = x"00") then
            acc_man <= '0';
        else
            acc_man <= '1';
        end if;
    end process;  

    process (rst, clk)
    begin
        if (rst = '1') then
            acc_man_check <= '0';
        elsif (rising_edge(clk)) then
            acc_man_check <= acc_man;
        end if;
    end process;
    
    d_out_reg: process(clk, rst)
    begin
        if (rst = '1') then
            d_out <= (others => '0');
            int <= '0';
        elsif (rising_edge(clk)) then
            if (acc_man = '1') then
                d_out <= addr_out & d_out_buf(conv_integer(addr_out));
            end if;
            int <= acc_man;
        end if;
    end process;
    
end struct_rtl;
