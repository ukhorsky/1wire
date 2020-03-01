----------------------------------------------------------------------------------
-- NB: this module is for simulation only
-- it shall not be used in sinthesis
-- Main purpose of this module is to simulate 1-Wire slave functions such as
-- reset sequence, bit receiving and bit transmission,
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


entity ow_slave is
    port(
        d_in : in std_logic;
        tst_data : in std_logic;
        d_out : out std_logic;
        s_rx : out std_logic;
        err : in integer;
        we : in std_logic
    );
end ow_slave;

architecture sim_rtl of ow_slave is
    
    signal t : std_logic;
    signal init_len : integer;

begin

    process
        --variable init_len : time;
    begin
        loop
            d_out <= '1';
            init_len <= 0;
            wait until falling_edge(d_in);
            while (d_in = '0')
            loop
                wait until rising_edge(d_in) or rising_edge(t);
                init_len <= init_len + 1;
            end loop;
            
            if (init_len > 480) then
                wait for 30 us;
                if (err = 0) then
                    d_out <= '0';
                    wait for 120 us;
                    d_out <= '1';
                elsif (err = 1) then
                    d_out <= '1';
                elsif (err = 3) then
                    d_out <= '0';
                    wait for 30 us;
                    d_out <= '1';
                end if;
            elsif (init_len >= 1 and init_len < 15) then
                wait for 4 us;
                d_out <= we and tst_data;
                s_rx <= d_in;
                wait for (12 - init_len) * 1 us;
                d_out <= '1';
            end if;
        end loop;
    end process;
    
    timer: process
    begin
        loop
            wait for 0.5 us;
            t <= '0';
            wait for 0.5 us;
            t <= '1';
        end loop;
    end process;
    
end sim_rtl;

