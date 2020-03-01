--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY ow_crc_tst IS
END ow_crc_tst;
 
ARCHITECTURE behavior OF ow_crc_tst IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ow_crc
    PORT(
         clk : IN  std_logic;
         rx : IN  std_logic;
         n_bit : IN  std_logic;
         crc_err : OUT  std_logic;
         rst : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rx : std_logic := '0';
   signal n_bit : std_logic := '0';
   signal rst : std_logic := '0';

 	--Outputs
   signal crc_err : std_logic;

   type row is array (0 to 7) of std_logic_vector(7 downto 0);
   
   signal td : row := (x"10", x"8b", x"c6", x"2c", x"03", x"08", x"00", x"a7");
   signal t : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ow_crc PORT MAP (
          clk => clk,
          rx => rx,
          n_bit => n_bit,
          crc_err => crc_err,
          rst => rst
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      rst <= '1';
      rx <= '1';
      n_bit <= '0';
      
      wait for clk_period * 2;
      rst <= '0';
      wait until falling_edge(clk);
      
      for i in 0 to 7 
      loop
        t <= td(i);
        wait until falling_edge(clk);
        for j in 0 to 7 
        loop
            rx <= t(j);
            n_bit <= '1';
            wait until rising_edge(clk);            
            wait until falling_edge(clk);
            n_bit <= '0';
        end loop;
      end loop;

      wait;
   end process;

END;
