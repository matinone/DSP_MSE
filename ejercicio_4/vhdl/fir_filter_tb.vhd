library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity fir_filter_tb is
end entity fir_filter_tb;

architecture testbench of fir_filter_tb is 

    component fir_filter_symmetric_round is
        generic (
                N_INPUT  : integer := 16;
                N_COEF   : integer := 16;
                N_TRUNC  : integer := 18;
                N_OUTPUT : integer := 18+3;
                M        : integer := 6
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
    constant in_file        : string  := "/home/mbrignone/MAESTRIA/MSE/dsp/tp1_dsp_mse/ejercicio_4/vhdl/data/data_in_fny_0p8.txt";
    constant out_file       : string  := "/home/mbrignone/MAESTRIA/MSE/dsp/tp1_dsp_mse/ejercicio_4/vhdl/data/data_out_fny_0p8_symmetric_round.txt";
    constant values_to_save : integer := 200;
    -- pointers for the files
    file r_fptr, w_fptr     : text;

    constant N_INPUT  : integer := 16;
    constant N_COEF   : integer := 16;
    constant N_TRUNC  : integer := 18;
    constant N_OUTPUT : integer := N_TRUNC+3;

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
        i_rst <= '1',
                 '0' after 20.0*C_CLK_PERIOD * (1 SEC);
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
    
    p_write_file : process is
        variable fstatus    : file_open_status;
        variable file_line  : line;
        variable v_int      : integer;
        variable v_std_lv   : std_logic_vector((o_master_axis_tdata'LENGTH - 1) downto 0);
    begin
        file_open(fstatus, w_fptr, out_file, write_mode);
        wait until (i_rst = '1');
        
        write_file : for i in 0 to values_to_save loop
            wait until (o_master_axis_tvalid = '1');
            v_int    := to_integer(signed(o_master_axis_tdata));    
            v_std_lv := o_master_axis_tdata;
            write(file_line, v_int);
            write(file_line, v_std_lv, right, 40);
            writeline(w_fptr, file_line);
            report "Written value: " & integer'image(v_int);
        end loop;
        report "Done writing output file";
        file_close(w_fptr);
        wait;
    end process;

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    DUT : fir_filter_symmetric_round
        generic map (
            N_INPUT  => N_INPUT,
            N_COEF   => N_COEF,
            N_TRUNC  => N_TRUNC,
            N_OUTPUT => N_OUTPUT,
            M        => 6
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
