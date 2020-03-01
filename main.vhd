----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.parameters.all;

entity main is
    port(
        clk : in std_logic;
        ow_buses : inout std_logic_vector(onewire_channels - 1 downto 0);
        uart_rx : in std_logic;
        uart_tx : out std_logic;
        pdwn : out std_logic;
        rst_l : in std_logic
    );
end main;

architecture struct_rtl of main is

    component ow_top is
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
    end component;
    
    component uart_top is
    port(
        clk : in std_logic;
        int : in std_logic;
        d_in : in std_logic_vector(15 downto 0);
        rx : in std_logic;
        d_out : out std_logic_vector(15 downto 0);
        tx : out std_logic;
        we : out std_logic;
        rst : in std_logic
    );
    end component;

    signal rst : std_logic;
    signal we : std_logic;
    signal int : std_logic;
    signal uart2ow : std_logic_vector(15 downto 0);
    signal ow2uart : std_logic_vector(15 downto 0);
    signal ow_data_bus : std_logic_vector(onewire_channels - 1 downto 0);
    signal ow_bus_pdwn : std_logic_vector(onewire_channels - 1 downto 0);
    
    
begin
    
    pdwn <= we or rst;
    
    rst <= not rst_l;
    
    ow_entity: ow_top
    port map(
        clk => clk,
        we => we,
        d_in => uart2ow,
        data_bus => ow_data_bus,
        bus_pdwn => ow_bus_pdwn,
        d_out => ow2uart,
        int => int,
        rst => rst
    );
    
    uart_entity: uart_top
    port map(
        clk => clk,
        int => int,
        d_in => ow2uart,
        rx => uart_rx,
        d_out => uart2ow,
        tx => uart_tx,
        we => we,
        rst => rst
    );

    ow_inouts: for i in 0 to onewire_channels - 1
    generate
        ow_buses(i) <= '0' when (ow_bus_pdwn(i) = '1') else 'Z';
        ow_data_bus(i) <= ow_buses(i);
    end generate;

end struct_rtl;

