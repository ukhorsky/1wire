--------------------------------------------------------------------------------
-- Check list:
-- 1.
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;
use work.parameters.all;
 
ENTITY ow_busctl_tst IS
END ow_busctl_tst;
 
ARCHITECTURE behavior OF ow_busctl_tst IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ow_busctl_fsm
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         cmd : IN  std_logic_vector(1 downto 0);
         q : IN  std_logic;
         tx : IN  std_logic;
         data_bus : IN  std_logic;
         rx_valid : OUT  std_logic;
         addr : OUT  std_logic_vector(2 downto 0);
         l : OUT  std_logic;
         status : OUT  std_logic_vector(1 downto 0);
         bus_pdwn : OUT  std_logic;
         ce : OUT  std_logic
        );
    END COMPONENT;
    
    component ow_bus_ct
    port(
        clk : in std_logic;
        d : in std_logic_vector (ow_ct_data_width downto 0);
        l : in std_logic;
        ce : in std_logic;
        q : out std_logic;
        rst : in std_logic
    );
    end component; 
    
    component ow_slave
    port(
        d_in : in std_logic;
        tst_data : in std_logic;
        d_out : out std_logic;
        s_rx : out std_logic;
        err : in integer;
        we : in std_logic
    );
    end component;

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal cmd : std_logic_vector(1 downto 0) := (others => '0');
   signal q : std_logic := '0';
   signal tx : std_logic := '0';
   signal data_bus : std_logic := '0';

 	--Outputs
   signal rx_valid : std_logic;
   signal addr : std_logic_vector(2 downto 0);
   signal l_fsm : std_logic;
   signal status : std_logic_vector(1 downto 0);
   signal bus_pdwn : std_logic;
   signal ce : std_logic;
   
   -- ct signals
   signal l : std_logic;
   signal d : std_logic_vector(ow_ct_data_width downto 0);
   
   -- slave signals
   signal test_data : std_logic;
   signal slave_out : std_logic;
   signal we : std_logic;
   signal s_rx : std_logic;
   signal err : integer;
   
   -- other signals
   signal cut : std_logic;

   type rom is array (0 to 7) of std_logic_vector(ow_ct_data_width downto 0);
	
   constant time_slots : rom := (
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 500*clk_freq, ow_ct_data_width + 1),    -- Reset Time Low 500 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 61*clk_freq, ow_ct_data_width + 1),		-- Presence Detect High 61 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 59*clk_freq, ow_ct_data_width +1),		-- Presence Detect Low 58 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 420*clk_freq, ow_ct_data_width + 1),	-- Reset Recovery 420 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 6*clk_freq, ow_ct_data_width + 1),	    -- Read-Write initial bus pull down 6 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 8*clk_freq, ow_ct_data_width + 1),		-- Read sampling wait 8 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 60*clk_freq, ow_ct_data_width + 1),		-- Read-Write time slot 60 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 1*clk_freq, ow_ct_data_width + 1)		-- Recovery Time Low 1 us		
	);

   -- Clock period definitions
   constant clk_period : time := 20 ns;
 
BEGIN
 
    l <= l_fsm or q;
    d <= time_slots(conv_integer(addr));
    
	-- Instantiate the Unit Under Test (UUT)
   uut1: ow_busctl_fsm 
   PORT MAP(
          clk => clk,
          rst => rst,
          cmd => cmd,
          q => q,
          tx => tx,
          data_bus => data_bus,
          rx_valid => rx_valid,
          addr => addr,
          l => l_fsm,
          status => status,
          bus_pdwn => bus_pdwn,
          ce => ce
        );
        
    uut2: ow_bus_ct
    port map(
        clk => clk,
        d => d,
        l => l,
        ce => ce,
        q => q,
        rst => rst
    );
    
    uut3: ow_slave
    port map(
        d_in => data_bus,
        d_out => slave_out,
        tst_data => test_data,
        s_rx => s_rx,
        err => err,
        we => we
    );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

    data_bus <= not bus_pdwn and slave_out and cut;
   -- Stimulus process
   stim_proc: process
   begin		
      cmd <= "00";
      rst <= '1';
      test_data <= '1';
      wait for clk_period * 1.4;
      rst <= '0';
      we <= '0';
      err <= 0;
---------------------------------------------------------------------------------
-- case 1: onewire bus cut off
---------------------------------------------------------------------------------      
      cut <= '0';
      report "case 1: bus cut off";
      cmd <= "01";
      wait on status;
      report "cease 1 exit status is " & integer'image(conv_integer(status));
      cmd <= "00";
      cut <= '1';
      wait until status = "00";
      wait for clk_period;
---------------------------------------------------------------------------------
-- case 2: no presence pull down puls
---------------------------------------------------------------------------------       
      report "case 2: no presence";
      err <= 1;
      cmd <= "01";
      wait on status;
      wait on status;
      report "case 2 exit status is " & integer'image(conv_integer(status));
      cmd <= "00";
      wait until status = "00";
      wait for clk_period;
---------------------------------------------------------------------------------
-- case 3: presence puls too short
--------------------------------------------------------------------------------- 
      report "case 3: presence too short";
      err <= 2;
      cmd <= "01";
      wait on status;
      wait on status;
      report "case 3 exit status is " & integer'image(conv_integer(status));
      cmd <= "00";
      wait until status = "00";
      wait for clk_period;
---------------------------------------------------------------------------------
-- case 4: normal reset
---------------------------------------------------------------------------------       
      report "case 4: normal";
      err <= 0;
      cmd <= "01";
      wait until status = "00";
      report "case 4 exit status is " & integer'image(conv_integer(status));
      cmd <= "00";      
      wait for clk_period;
---------------------------------------------------------------------------------
-- case 5: writing low bit 
--------------------------------------------------------------------------------- 
      report "case 5: tx 0";
      err <= 0;
      cmd <= "11";
      tx <= '0';
      wait until status = "00";
      report "case 5 exit status is " & integer'image(conv_integer(s_rx));
      cmd <= "00";
      wait for clk_period;
---------------------------------------------------------------------------------
-- case 6: writing high bit 
--------------------------------------------------------------------------------- 
      report "case 6: tx 1";
      err <= 0;
      cmd <= "11";
      tx <= '1';
      wait until status = "00";
      report "case 4 exit status is " & integer'image(conv_integer(s_rx));
      cmd <= "00";
      wait for clk_period;
---------------------------------------------------------------------------------
-- case 7: reading low bit 
--------------------------------------------------------------------------------- 
      report "case 7: rx 0";
      err <= 0;
      cmd <= "10";
      we <= '1';
      test_data <= '0';
      wait on status;
      wait until rx_valid = '1';
      wait for clk_period;
      report "case 7 received data is " & integer'image(conv_integer(data_bus));
      wait until status = "00";
      cmd <= "00";
      wait for clk_period;
---------------------------------------------------------------------------------
-- case 8: reading high bit 
--------------------------------------------------------------------------------- 
      report "case 8: rx 1";
      err <= 0;
      cmd <= "10";
      we <= '1';
      test_data <= '1';
      wait on status;
      wait until rx_valid = '1';
      wait for clk_period;
      report "case 8 received data is " & integer'image(conv_integer(data_bus));
      wait until status = "00";
      cmd <= "00";
      wait for clk_period;
      wait;
   end process;

END;
