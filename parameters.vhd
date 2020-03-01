library IEEE;
use IEEE.STD_LOGIC_1164.all;

library work;
use work.functions_pack.all;

package parameters is

    constant clk_freq : natural := 50; -- MHz
    constant ow_sample_rate : natural := 9;
    constant ow_ct_data_width : natural := slv_length(500*clk_freq/(ow_sample_rate + 1));
    constant uart_baud_rate : natural := 9600;
    constant uart_tx_ct_max : natural := clk_freq*1000000/uart_baud_rate;
    constant uart_tx_ct_len : natural := slv_length(uart_tx_ct_max); -- 13;
    constant uart_rx_ct_max : natural := clk_freq*1000000/(uart_baud_rate*16);
    constant uart_rx_ct_len : natural := slv_length(uart_rx_ct_max); -- 9;
    constant onewire_channels : natural := 1; --number of 1-Wire channels    

end parameters;

package body parameters is
 
end parameters;
