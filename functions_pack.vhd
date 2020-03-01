library IEEE;
use IEEE.STD_LOGIC_1164.all;

package functions_pack is

    function slv_length (number:integer) return integer;

end functions_pack;

package body functions_pack is

    -- calculaiting length of std_logic_vector that can contain desired integer
    function slv_length (number:integer)
    return integer is
        variable power : integer;
    begin
        power := 1;
        while (number - 2**power >= 0)
        loop
            power := power + 1;
        end loop;
        return power;
    end slv_length;
 
end functions_pack;
