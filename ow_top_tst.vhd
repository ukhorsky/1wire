--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY ow_top_tst IS
END ow_top_tst;
 
ARCHITECTURE behavior OF ow_top_tst IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ow_top
    PORT(
         clk : IN  std_logic;
         we : IN  std_logic;
         d_in : IN  std_logic_vector(15 downto 0);
         data_bus : IN  std_logic_vector(0 downto 0);
         bus_pdwn : OUT  std_logic_vector(0 downto 0);
         d_out : OUT  std_logic_vector(15 downto 0);
         int : OUT  std_logic;
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
   signal we : std_logic := '0';
   signal d_in : std_logic_vector(15 downto 0) := (others => '0');
   signal data_bus : std_logic_vector(0 downto 0) := (others => '0');
   signal rst : std_logic := '0';

 	--Outputs
   signal bus_pdwn : std_logic_vector(0 downto 0);
   signal d_out : std_logic_vector(15 downto 0);
   signal int : std_logic;

   -- Slave
   signal slave_out : std_logic;
   signal test_data : std_logic;
   signal we_s : std_logic;
   
   -- Clock period definitions
   constant clk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ow_top PORT MAP (
          clk => clk,
          we => we,
          d_in => d_in,
          data_bus => data_bus,
          bus_pdwn => bus_pdwn,
          d_out => d_out,
          int => int,
          rst => rst
        );
        
    uut_slave: ow_slave
    port map(
        d_in => data_bus(0),
        d_out => slave_out,
        tst_data => test_data,
        err => 0,
        we => we_s
    );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   data_bus(0) <= not bus_pdwn(0) and slave_out;

   -- Stimulus process
   stim_proc: process
   begin		
      rst <= '1';
      test_data <= '0';
      we <= '0';
      we_s <= '1';
      test_data <= '1';
      wait for clk_period * 2;
      rst <= '0';
      d_in <= x"0100";
      we <= '1';
      wait for clk_period;
      we <= '0';
      wait until rising_edge(int);
      wait for clk_period;
      d_in <= x"07CC";
      we <= '1';
      wait for clk_period;
      we <= '0';
      wait until rising_edge(int);
      wait for clk_period;
      d_in <= x"0600";
      we <= '1';
      wait for clk_period;
      we <= '0';
      wait;
   end process;

END;
