----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_top is
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
end uart_top;

architecture rtl_struct of uart_top is

    component uart_rx is
    port(
        clk : in std_logic;
        rx : in std_logic;        
        data_rx : out std_logic_vector (7 downto 0);
        byte : out std_logic;
        rst : in std_logic
    );
    end component;
    
    component uart_tx is
    port(
        clk : in std_logic;
        load : in std_logic;
        data_tx : in std_logic_vector (7 downto 0);
        tx : out std_logic;
        busy : out std_logic;
        rst : in std_logic
    );
    end component;

    signal we_rst : std_logic;
    signal we_ce : std_logic;
    signal byte : std_logic;
    signal we_reg : std_logic_vector(2 downto 0);
    signal data_rx : std_logic_vector(7 downto 0);
    signal int_rst : std_logic;
    signal int_ce : std_logic;    
    signal busy : std_logic;
    signal load : std_logic;
    signal int_reg : std_logic_vector(2 downto 0);
    signal data_tx : std_logic_vector(7 downto 0);
    --signal d_out_reg : std_logic_vector(15 downto 0);
    signal d_in_reg : std_logic_vector(15 downto 0);
    
begin

----------------------------------------------------------------------------------------
-- receiving data from host
----------------------------------------------------------------------------------------
    we <= we_reg(1);
    we_rst <= rst or we_reg(2);
    we_ce <= byte or we_reg(1);
    
    we_control: process (we_rst, clk)
    begin
        if (we_rst = '1') then
            we_reg <= "000";
        elsif (rising_edge(clk)) then
            if (we_ce = '1') then
                we_reg <= we_reg(1 downto 0) & byte;
            end if;
        end if;
    end process; 

    output_reg: process (rst, clk)
    begin
        if (rst = '1') then
            d_out <= (others => '0');
        elsif (rising_edge(clk)) then
            if (byte = '1') then
                -- d_out_reg <= d_out_reg(7 downto 0) & data_rx;
                if (we_reg(0) = '0') then
                    d_out(15 downto 8) <= data_rx;
                else
                    d_out(7 downto 0) <= data_rx;
                end if;
            end if;
        end if;
    end process;
    
    --d_out <= d_out_reg;
    
    usrt_rx_entity: uart_rx
    port map(
        clk => clk,
        rx => rx,
        data_rx => data_rx,
        byte => byte,
        rst => rst
    );
    
----------------------------------------------------------------------------------------
-- transmitting data to host
----------------------------------------------------------------------------------------    
    int_rst <= rst or int_reg(2);
    load <= int_reg(1) or int_reg(0);
    int_ce <= not busy and (load or int);
    
    int_control: process (int_rst, clk)
    begin
        if (int_rst = '1') then
            int_reg <= "000";
        elsif (rising_edge(clk)) then
            if (int_ce = '1') then
                int_reg <= int_reg(1 downto 0) & int;
            end if;
        end if;
    end process;
    
    input_reg: process (rst, clk)
    begin
        if (rst = '1') then
            d_in_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            if (int = '1') then
                d_in_reg <= d_in;
            end if;
        end if;
    end process;
    
    tx_mux: process (int_reg(1), d_in_reg)
    begin
        case int_reg(1) is
            when '0' =>
                data_tx <= d_in_reg(15 downto 8);
            when '1' =>
                data_tx <= d_in_reg(7 downto 0);
            when others =>
                null;
        end case;
    end process;
    
    uart_tx_entity: uart_tx
    port map(
        clk => clk,
        load => load,
        data_tx => data_tx,
        tx => tx,
        busy => busy,
        rst => rst
    );

end rtl_struct;

