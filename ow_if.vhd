----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;
use work.parameters.all;

entity ow_if is
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
end ow_if;

architecture struct_rtl of ow_if is

	component ow_bus_ct is
    port(
        clk : in std_logic;
        rst : in std_logic;
        l : in std_logic;
        d : in std_logic_vector(ow_ct_data_width downto 0);
        ce : in std_logic;
        q : out std_logic
    );	
	end component;
	
	component ow_busctl_fsm is
	port(
        clk : in std_logic;
        rst : in std_logic;
        cmd : in std_logic_vector(1 downto 0);
        q : in std_logic;
        tx : in std_logic;
        data_bus : in std_logic;
        rx_valid : out std_logic;
        addr : out std_logic_vector(2 downto 0);
        l : out std_logic;
        bus_pdwn : out std_logic;
        status : out std_logic_vector(1 downto 0);
        ce : out std_logic
    ); 
	end component;
    
    component ow_oversample is
    port(
        clk : in std_logic;
        rx : in std_logic;
        sample : out std_logic;
        ce : out std_logic;
        rst : in std_logic
    );
    end component;
    
    component ow_crc is
    port(
        clk : in std_logic;
        rx : in std_logic;
        n_bit : in std_logic;
        crc_err : out std_logic;
        rst : in std_logic
    );
    end component;

    type rom is array (0 to 7) of std_logic_vector(ow_ct_data_width downto 0);
	
	constant time_slots : rom := (
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 500*clk_freq/(ow_sample_rate + 1), ow_ct_data_width + 1),    -- Reset Time Low 500 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 61*clk_freq/(ow_sample_rate + 1), ow_ct_data_width + 1),		-- Presence Detect High 61 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 58*clk_freq/(ow_sample_rate + 1), ow_ct_data_width +1),		-- Presence Detect Low 58 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 420*clk_freq/(ow_sample_rate + 1), ow_ct_data_width + 1),	-- Reset Recovery 420 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 6*clk_freq/(ow_sample_rate + 1), ow_ct_data_width + 1),	    -- Read-Write initial bus pull down 6 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 8*clk_freq/(ow_sample_rate + 1), ow_ct_data_width + 1),		-- Read sampling wait 8 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 60*clk_freq/(ow_sample_rate + 1), ow_ct_data_width + 1),		-- Read-Write time slot 60 us
		CONV_STD_LOGIC_VECTOR(2**ow_ct_data_width - 1*clk_freq/(ow_sample_rate + 1), ow_ct_data_width + 1)		-- Recovery Time Low 1 us		
	);
    
    signal l, l_fsm, q_ct, crc_err, rx_valid , tx: std_logic;
    signal ce, ce_fsm, ce_ov : std_logic;
    signal sample : std_logic;
    signal d : std_logic_vector(ow_ct_data_width downto 0);
    signal crc_rst : std_logic;
    signal status : std_logic_vector(1 downto 0);
    signal status_xor : std_logic;
    signal circle_reg : std_logic;
    signal circle_fin : std_logic;
    signal circle_start : std_logic;
    signal cmd_rst : std_logic;
    signal mask_e : std_logic_vector(7 downto 0);
    signal data_reg_ce : std_logic;
    signal data_reg_in : std_logic;
    signal d_out_l : std_logic;
    signal acc_reg_ce : std_logic;
    signal addr : std_logic_vector(2 downto 0);
    signal cmd_reg : std_logic_vector(1 downto 0);
    signal data_reg : std_logic_vector(7 downto 0);
    signal mask_reg : std_logic_vector(7 downto 0);
    signal d_out_ext : std_logic_vector(12 downto 0);
    signal d_out_reg : std_logic_vector(12 downto 0);
    signal acc_reg : std_logic_vector(1 downto 0);

    

begin
-----------------------------------------------------------------------------------------
-- main bus control logic
-----------------------------------------------------------------------------------------
    d <= time_slots(conv_integer(addr));
    l <= l_fsm or q_ct;
    
    fsm_entity: ow_busctl_fsm 
    port map(
        clk => clk,
        rst => rst,
        cmd => cmd_reg,
        q => q_ct,
        tx => tx,
        data_bus => sample,
        rx_valid => rx_valid,
        addr => addr,
        l => l_fsm,
        bus_pdwn => bus_pdwn,
        status => status,
        ce => ce_fsm
    );

    ce <= ce_ov and ce_fsm;
    counter_entity: ow_bus_ct 
    port map(
        clk => clk,
        rst => rst,
        l => l,
        d => d,
        ce => ce,
        q => q_ct
    );
    
    crc_rst <= rst or (not cmd_reg(1) and cmd_reg(0));
    crc_entity: ow_crc
    port map(
        clk => clk,
        rx => sample,
        n_bit => rx_valid,
        crc_err => crc_err,
        rst => crc_rst
    );
    
    oversample_entity: ow_oversample
    port map(
        clk => clk,
        rx => data_bus,
        sample => sample,
        ce => ce_ov,
        rst => rst
    );
    
-----------------------------------------------------------------------------------------
-- auxilary registers and logic
-----------------------------------------------------------------------------------------    
    status_xor <= status(1) xor status(0);
    
    circle_register: process (rst, clk)
    begin
        if (rst = '1') then
            circle_reg <= '0';
        elsif (rising_edge(clk)) then
            circle_reg <= status_xor;
        end if;
    end process;
    
    circle_fin <= circle_reg and not status_xor;
    circle_start <= not circle_reg and status_xor;
    
    cmd_rst <= rst or (not mask_reg(0) and circle_fin);
    
    cmd_register: process(cmd_rst, clk) 
    begin
        if (cmd_rst = '1') then
            cmd_reg <= "00";
        elsif (rising_edge(clk)) then
            if (cs = '1') then
                cmd_reg <= cmd_in(1 downto 0);
            end if;
        end if;
    end process;
    
    mask_register: process(rst, clk)
    begin
        if (rst = '1') then
            mask_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            if (cs = '1') then
                for i in 7 downto 1
                loop
                    mask_reg(i) <= cmd_in(2);
                end loop;
                mask_reg(0) <= '1';
            elsif (circle_start = '1') then
                mask_reg <= '0' & mask_reg(7 downto 1);
            end if;    
        end if;    
    end process;
    
    data_reg_ce <= (not cmd_reg(0) and cmd_reg(1) and rx_valid) or
                   (cmd_reg(0) and cmd_reg(1) and circle_fin);
    data_reg_in <= not cmd_reg(0) and cmd_reg(1) and data_bus;
    
    data_register: process(clk, rst)
    begin
        if (rst = '1') then
            data_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            if (cs = '1') then
                data_reg <= d_in;            
            elsif (data_reg_ce = '1') then
                data_reg <= data_reg_in & data_reg(7 downto 1);                
            end if;
        end if;
    end process;
    
    tx <= data_reg(0);
    
    d_out_ext(10 downto 8) <= cmd_in when (cs = '1') else d_out_reg(10 downto 8); 
    d_out_ext(12 downto 11) <= (status(1) or crc_err) & status(0);
    d_out_ext(7 downto 0) <= data_reg;
    
    d_out_l <= cs or circle_fin;
    
    output_register: process(rst, clk)
    begin
        if (rst = '1') then
            d_out_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            if (d_out_l = '1') then
                d_out_reg <= d_out_ext;
            end if;
        end if;
    end process;
    
    d_out <= d_out_reg;
    
    acc_reg_ce <= not acc_check and ((not mask_reg(0) and circle_fin) or acc_reg(0) or acc_reg(1));
    
    output_access: process(rst, clk)
    begin
        if (rst = '1') then
            acc_reg <= "00";
        elsif (rising_edge(clk)) then
            if (acc_reg_ce = '1') then
                acc_reg <= acc_reg(0) & circle_fin;
            end if;
        end if;
    end process;

    acc_req <= acc_reg(1);

end struct_rtl;

