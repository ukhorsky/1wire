--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY ow_if_tst IS
END ow_if_tst;
 
ARCHITECTURE behavior OF ow_if_tst IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ow_if
    PORT(
         clk : IN  std_logic;
         cmd_in : IN  std_logic_vector(2 downto 0);
         d_in : IN  std_logic_vector(7 downto 0);
         cs : IN  std_logic;
         data_bus : IN  std_logic;
         acc_check : IN  std_logic;
         acc_req : OUT  std_logic;
         d_out : OUT  std_logic_vector(12 downto 0);
         bus_pdwn : OUT  std_logic;
         rst : IN  std_logic
        );
    END COMPONENT;
    
    component ow_slave
    port(
        d_in : in std_logic;
        tst_data : in std_logic;
        d_out : out std_logic;
        err : in integer;
        we : in std_logic
    );
    end component;

   --Inputs
   signal clk : std_logic := '0';
   signal cmd_in : std_logic_vector(2 downto 0) := (others => '0');
   signal d_in : std_logic_vector(7 downto 0) := (others => '0');
   signal cs : std_logic := '0';
   signal data_bus : std_logic := '1';
   signal acc_check : std_logic := '0';
   signal rst : std_logic := '0';

 	--Outputs
   signal acc_req : std_logic;
   signal d_out : std_logic_vector(12 downto 0);
   signal bus_pdwn : std_logic;

   signal slave_out : std_logic;
   signal test_data : std_logic;
   signal we : std_logic;

   -- Clock period definitions
   constant clk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ow_if PORT MAP (
          clk => clk,
          cmd_in => cmd_in,
          d_in => d_in,
          cs => cs,
          data_bus => data_bus,
          acc_check => acc_check,
          acc_req => acc_req,
          d_out => d_out,
          bus_pdwn => bus_pdwn,
          rst => rst
        );
        
   uut_slave: ow_slave
    port map(
        d_in => data_bus,
        d_out => slave_out,
        tst_data => test_data,
        err => 0,
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

   data_bus <= not bus_pdwn and slave_out;

   -- Stimulus process
   stim_proc: process
   begin		
      rst <= '1';
      test_data <= '0';
      we <= '0';
      wait for clk_period * 2;
      rst <= '0';
      cmd_in <= "001";
      cs <= '1';
      wait for clk_period;
      cmd_in <= "000";
      cs <= '0';
      wait until rising_edge(acc_req);
      wait for clk_period * 2;
      cmd_in <= "111";
      cs <= '1';
      d_in <= x"99";
      wait for clk_period;
      cmd_in <= "000";
      cs <= '0';
      d_in <= x"00";
      wait until rising_edge(acc_req);
      wait;
   end process;

END;
