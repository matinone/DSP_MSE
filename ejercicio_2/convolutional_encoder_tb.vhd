library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;


entity convolutional_encoder_tb is
end entity convolutional_encoder_tb;

architecture testbench of convolutional_encoder_tb is

    component convolutional_encoder is
        generic (
            POL_1       : integer := 8#171#;
            POL_2       : integer := 8#133#;
            N_INPUT     : integer := 16;
            N_OUTPUT    : integer := 32
        );
        port (
            i_clk                : in std_logic;
            i_rst                : in std_logic;
            -- slave AXIS
            i_slave_axis_tdata   : in  std_logic_vector(N_INPUT-1 downto 0);
            i_slave_axis_tvalid  : in  std_logic;
            o_slave_axis_tready  : out std_logic;
            -- master AXIS
            o_master_axis_tdata  : out std_logic_vector(N_OUTPUT-1 downto 0);
            o_master_axis_tvalid : out std_logic;
            i_master_axis_tready : in  std_logic
        );
    end component convolutional_encoder;

    constant POL_1    : integer := 8#171#;
    constant POL_2    : integer := 8#133#;
    constant N_INPUT  : integer := 16;
    constant N_OUTPUT : integer := 32;

    signal i_clk                : std_logic;
    signal i_rst                : std_logic;
    signal i_slave_axis_tdata   : std_logic_vector(N_INPUT-1 downto 0);
    signal i_slave_axis_tvalid  : std_logic;
    signal o_slave_axis_tready  : std_logic;
    signal o_master_axis_tdata  : std_logic_vector(N_OUTPUT-1 downto 0);
    signal o_master_axis_tvalid : std_logic;
    signal i_master_axis_tready : std_logic;

    constant C_CLK_PERIOD : real := 10.0e-9; -- NS

    -- procedure to generate delays of M clock cycles
    procedure generate_delay (
        signal      i_clk   : in std_logic;
        constant    M_CYCLE : in integer 
    ) is    
    begin
        wait_ncycle : for i in 0 to M_CYCLE-1 loop
            wait until rising_edge(i_clk);                                    
        end loop;
    end procedure generate_delay;


    type test_vector_array is array (natural range <>) of integer;
    constant test_vectors : test_vector_array := (
        (5    ),
        (4100 ),
        (44970),
        (4660 ),
        (30802)
    );

begin
    -----------------------------------------------------------
    -- Clocks and Reset
    -----------------------------------------------------------
    CLK_GEN : process
    begin
        i_clk <= '1';
        wait for C_CLK_PERIOD / 2.0 * (1 SEC);
        i_clk <= '0';
        wait for C_CLK_PERIOD / 2.0 * (1 SEC);
    end process CLK_GEN;

    RESET_GEN : process
    begin
        i_rst <= '0',
                 '1' after 20.0*C_CLK_PERIOD * (1 SEC);
        wait;
    end process RESET_GEN;

    -----------------------------------------------------------
    -- Testbench Stimulus
    -----------------------------------------------------------
    generate_stimulus : process is
        variable i      : integer;
        variable temp   : std_logic_vector(N_INPUT-1 downto 0);
    begin
        i_slave_axis_tdata  <= (others => '0');
        i_slave_axis_tvalid <= '0';
        wait until i_rst = '1';
        generate_delay(i_clk, 10);
        -- loop_generate_data : for i in 0 to 15 loop
        for i in test_vectors'range loop
                i_slave_axis_tdata  <= std_logic_vector(to_unsigned(test_vectors(i), N_INPUT));
                i_slave_axis_tvalid <= '1';

                wait until (rising_edge(i_clk) and o_slave_axis_tready = '1');
                i_slave_axis_tvalid <= '0';
                generate_delay(i_clk, 9);
        end loop;
        generate_delay(i_clk, 20);
    wait;
    end process; -- generate_stimulus


    print_data : process is
        variable my_line : line;
    begin
        i_master_axis_tready <= '1';
        process_data_valid : while true loop
            wait until o_master_axis_tvalid = '1';
            report "Received value: 0x" & to_hstring(o_master_axis_tdata);
        end loop; -- process_data_valid
        wait;
    end process print_data;

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    DUT : convolutional_encoder
        generic map (
            POL_1    => POL_1,
            POL_2    => POL_2,
            N_INPUT  => N_INPUT,
            N_OUTPUT => N_OUTPUT
        )
        port map (
            i_clk                => i_clk,
            i_rst                => i_rst,
            i_slave_axis_tdata   => i_slave_axis_tdata,
            i_slave_axis_tvalid  => i_slave_axis_tvalid,
            o_slave_axis_tready  => o_slave_axis_tready,
            o_master_axis_tdata  => o_master_axis_tdata,
            o_master_axis_tvalid => o_master_axis_tvalid,
            i_master_axis_tready => i_master_axis_tready
        );

end architecture testbench;
