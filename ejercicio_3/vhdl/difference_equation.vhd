library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity difference_equation is
    generic (
            -- input bits
            N_INPUT  : integer := 8;
            -- output bits
            N_OUTPUT : integer := 16;
            -- past input samples
            M_INPUT  : integer := 3;
            -- past output samples
            M_OUTPUT : integer := 2;
            -- "real" output bits (11 bits for Q4.7)
            N_OUTPUT_USED : integer := 11
        );
    port (
        i_clk                   : in std_logic;
        i_rst                   : in std_logic;
        -- slave axis
        i_slave_axis_tdata      : in  std_logic_vector(N_INPUT-1 downto 0);
        i_slave_axis_tvalid     : in  std_logic;
        o_slave_axis_tready     : out std_logic;
        -- master axis
        o_master_axis_tdata     : out std_logic_vector(N_OUTPUT-1 downto 0);
        o_master_axis_tvalid    : out std_logic;
        i_master_axis_tready    : in  std_logic
    );
end entity;

architecture rtl of difference_equation is

    component ffd_vector is
        generic (
            N : integer := 8
        );
        port (
            i_clk       : in  std_logic;
            i_rst       : in  std_logic;
            i_enable    : in  std_logic;
            i_data      : in  std_logic_vector(N-1 downto 0);
            o_data      : out std_logic_vector(N-1 downto 0)
        );
    end component ffd_vector;

    -- vector for past input samples
    type input_vector_type is array (integer range <>) of std_logic_vector(N_INPUT-1 downto 0);
    signal input_vector_reg : input_vector_type(0 to M_INPUT);  -- x(n),x(n-1),x(n-2) ... x(n-(M-1))

    -- vector for past output samples
    type output_vector_type is array (integer range <>) of std_logic_vector(N_OUTPUT-1 downto 0);
    signal output_vector_reg : output_vector_type(0 to M_OUTPUT);  -- y(n),y(n-1),y(n-2) ... y(n-(M-1))

    -- states to control the block
    type state_type is (
        ST_WAIT_DATA,
        ST_PROCESS_DATA,
        ST_TRANSMIT_DATA
    );

    -- internal variables
    signal state            : state_type;
    -- signal current_input    : std_logic_vector(N_INPUT-1 downto 0);
    -- signal current_output   : std_logic_vector(N_OUTPUT-1 downto 0);

    signal current_sum      : std_logic_vector(N_OUTPUT_USED-1 downto 0);
    signal enable_dsp       : std_logic;

begin

    -- generate input vector with past input samples
    input_vector_reg(0) <= i_slave_axis_tdata;
    generate_input_array : for i in 0 to M_INPUT-1 generate
        reg_inst_in : ffd_vector
            generic map (
                N => N_INPUT
            )
            port map (
                i_clk       => i_clk,
                i_rst       => i_rst,
                i_data      => input_vector_reg(i),
                o_data      => input_vector_reg(i+1),
                i_enable    => enable_dsp
            );              
    end generate;

    -- generate output vector with past output samples
    -- output_vector_reg(0) <= std_logic_vector(resize(signed(current_sum), N_OUTPUT));
    -- output_vector_reg(0) <= (others => '0');
    -- output_vector_reg(0) <= current_output;
    generate_output_array : for i in 0 to M_OUTPUT-1 generate
        reg_inst_out : ffd_vector
            generic map (
                N => N_OUTPUT
            )
            port map (
                i_clk       => i_clk,
                i_rst       => i_rst,
                i_data      => output_vector_reg(i),
                o_data      => output_vector_reg(i+1),
                i_enable    => enable_dsp
            );              
    end generate;


    -- calculate y(n) = x(n)-x(n-1)+x(n-2)+x(n-3)+0.5y(n-1)+0.25y(n-2)
    sum_process : process(all) is
        variable max_res_out  : integer := N_OUTPUT_USED + 2;       -- 13 bits
        variable temp_sum_in  : signed((N_INPUT+2)-1 downto 0);     -- Q(3.7)
        variable temp_sum_out : signed(max_res_out-1 downto 0);     -- Q(6.7)

        constant MAX_OV : integer := (2**(N_OUTPUT_USED-1))-1; 
        constant MIN_OV : integer := (-2**(N_OUTPUT_USED-1)); 

    begin
        temp_sum_in  := (others => '0');
        temp_sum_out := (others => '0');
        -- very hardcoded
        temp_sum_in := temp_sum_in + signed(input_vector_reg(0));
        temp_sum_in := temp_sum_in - signed(input_vector_reg(1));
        temp_sum_in := temp_sum_in + signed(input_vector_reg(2));
        temp_sum_in := temp_sum_in + signed(input_vector_reg(3));

        -- keep only the outputs bits used to represent the number in Q4.7 (the 11 LSB bits)
        temp_sum_out := temp_sum_out + shift_right(signed(output_vector_reg(0)(max_res_out-1 downto 0)), 1); -- number * 0.5  --> 1 right shift
        temp_sum_out := temp_sum_out + shift_right(signed(output_vector_reg(1)(max_res_out-1 downto 0)), 2); -- number * 0.25 --> 2 right shift
        temp_sum_out := temp_sum_out + resize(temp_sum_in, max_res_out-1);             -- resize to the same bits as the output

        -- saturate the output to 11 bits only
        -- MSB = '0' --> positive (sature to max value)
       if ((temp_sum_out(max_res_out-1) = '0') and (or temp_sum_out(max_res_out-1 downto N_OUTPUT_USED-1) = '1')) then
           current_sum <= std_logic_vector(to_signed(MAX_OV, current_sum'LENGTH));
       -- MSB = '1' --> negative (saturate to min value)
       elsif (temp_sum_out(max_res_out-1) = '1' and (and temp_sum_out(max_res_out-1 downto N_OUTPUT_USED-1) = '0')) then
           current_sum <= std_logic_vector(to_signed(MIN_OV, current_sum'LENGTH));
       -- saturate
       else
           current_sum <= std_logic_vector(temp_sum_out(N_OUTPUT_USED-1 downto 0));
       end if;

    end process; -- sum_process


    reg_process : process (i_clk, i_rst)
    begin
        if (i_rst = '0' ) then
            state                <= ST_WAIT_DATA;
            enable_dsp           <= '0';
            o_slave_axis_tready  <= '1';
            o_master_axis_tdata  <= (others => '0');
            o_master_axis_tvalid <= '1';
            -- current_output       <= (others => '0');
            output_vector_reg(0) <= (others => '0');
        elsif (rising_edge(i_clk)) then

            case state is
                when ST_WAIT_DATA =>
                    if (i_slave_axis_tvalid = '1' and o_slave_axis_tready = '1') then
                        state <= ST_PROCESS_DATA;
                        enable_dsp <= '1';
                        -- tready to 0 because the module will be processing in the next cycle, so it cant accept new data
                        o_slave_axis_tready <= '0';
                    else
                        enable_dsp <= '0';
                        o_slave_axis_tready <= '1';
                    end if;
                when ST_PROCESS_DATA =>
                    -- processing is done in a single cycle, so change state immediately
                    state                <= ST_TRANSMIT_DATA;
                    enable_dsp           <= '0';
                    o_slave_axis_tready  <= '0';
                    o_master_axis_tvalid <= '1';
                    -- resize current sum to use N_OUTPUT bits
                    o_master_axis_tdata  <= std_logic_vector(resize(signed(current_sum), N_OUTPUT));
                    -- current_output       <= std_logic_vector(resize(signed(current_sum), N_OUTPUT));
                    output_vector_reg(0) <= std_logic_vector(resize(signed(current_sum), N_OUTPUT));
                when ST_TRANSMIT_DATA =>
                    enable_dsp           <= '0';
                    -- o_slave_axis_tready  <= '0';
                    -- o_master_axis_tvalid <= '1';
                    if (i_master_axis_tready = '1' and o_master_axis_tvalid = '1') then
                        state                <= ST_WAIT_DATA;
                        o_slave_axis_tready  <= '1';
                        o_master_axis_tvalid <= '0';
                    else
                        state                <= ST_TRANSMIT_DATA;
                        o_slave_axis_tready  <= '0';
                        o_master_axis_tvalid <= '1';
                    end if;
                when others =>
                    -- invalid state, so reset everything
                    state                <= ST_WAIT_DATA;
                    enable_dsp           <= '0';
                    o_slave_axis_tready  <= '1';
                    o_master_axis_tdata  <= (others => '0');
                    o_master_axis_tvalid <= '1';
            end case;

        end if;

    end process reg_process;

end architecture ; -- rtl
