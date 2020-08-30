library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity difference_equation_tb is
end entity difference_equation_tb;

architecture testbench of difference_equation_tb is

    component difference_equation is
        generic (
                N_INPUT  : integer := 8;
                N_OUTPUT : integer := 16;
                M_INPUT  : integer := 3;
                M_OUTPUT : integer := 2;
                N_OUTPUT_USED : integer := 11
            );
        port (
            i_clk                   : in std_logic;
            i_rst                   : in std_logic;
            i_slave_axis_tdata      : in  std_logic_vector(N_INPUT-1 downto 0);
            i_slave_axis_tvalid     : in  std_logic;
            o_slave_axis_tready     : out std_logic;
            o_master_axis_tdata     : out std_logic_vector(N_OUTPUT-1 downto 0);
            o_master_axis_tvalid    : out std_logic;
            i_master_axis_tready    : in  std_logic
        );
    end component;

    -- absolute paths
--    constant in_file        : string  := "/home/mbrignone/MAESTRIA/MSE/dsp/tp1_dsp_mse/ejercicio_3/vhdl/data_in_const.txt";
    constant in_file        : string  := "/home/mbrignone/MAESTRIA/MSE/dsp/tp1_dsp_mse/ejercicio_3/vhdl/data_in_sin.txt";
    constant out_file       : string  := "/home/mbrignone/MAESTRIA/MSE/dsp/tp1_dsp_mse/ejercicio_3/vhdl/data_out.txt";
    constant values_to_save : integer := 200;
    -- pointers for the files
    file r_fptr, w_fptr : text;

    constant N_INPUT  : integer := 8;
    constant N_OUTPUT : integer := 16;

    signal i_clk                : std_logic;
    signal i_rst                : std_logic;
    signal i_slave_axis_tdata   : std_logic_vector(N_INPUT-1 downto 0);
    signal i_slave_axis_tvalid  : std_logic;
    signal o_slave_axis_tready  : std_logic;
    signal o_master_axis_tdata  : std_logic_vector(N_OUTPUT-1 downto 0);
    signal o_master_axis_tvalid : std_logic;
    signal i_master_axis_tready : std_logic;

    constant C_CLK_PERIOD : real := 10.0e-9; -- nanoseconds

    -- procedure to generate delays of M clock cycl
    procedure generate_delay (
        signal      i_clk   : in std_logic;
        constant    M_CYCLE : in integer 
    ) is    
    begin
        wait_ncycle : for i in 0 to M_CYCLE-1 loop
            wait until rising_edge(i_clk);                                    
        end loop;
    end procedure generate_delay;

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
        variable fstatus    : file_open_status;
        variable file_line  : line;
        variable input_val  : integer;
    begin
        file_open(fstatus, r_fptr, in_file, read_mode);

        -- just accept all the data
        i_master_axis_tready <= '1';
        -- reset vaues for the input signals
        i_slave_axis_tdata  <= (others => '0');
        i_slave_axis_tvalid <= '0';
        wait until i_rst = '1';
        generate_delay(i_clk, 10);

        loop_file : while not endfile(r_fptr) loop
            readline(r_fptr, file_line);
            read(file_line, input_val);
            report "Input value read from file: " & integer'image(input_val);

            i_slave_axis_tdata  <= std_logic_vector(to_signed(input_val, N_INPUT));
            i_slave_axis_tvalid <= '1';

            wait until (rising_edge(i_clk) and o_slave_axis_tready = '1');
            i_slave_axis_tvalid <= '0';
            generate_delay(i_clk, 20);

        end loop;

        report "Done reading input file";
        file_close(r_fptr);

        wait;

    end process; -- generate_stimulus

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    DUT : difference_equation
        generic map (
            N_INPUT => N_INPUT,
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
