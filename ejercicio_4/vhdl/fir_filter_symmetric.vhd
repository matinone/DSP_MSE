library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity fir_filter_symmetric is
    generic (
            -- input bits
            N_INPUT  : integer := 16;
            -- coefficients bits
            N_COEF   : integer := 16;
            -- multiplication output bits
            N_TRUNC  : integer := 18;
            -- output bits
            N_OUTPUT : integer := N_TRUNC+3;
            -- past input samples (current + 6 previous)
            M        : integer := 6
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

architecture rtl of fir_filter_symmetric is

    component ffd_vector is
        generic (
            N : integer := 16
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
    signal input_vector_reg : input_vector_type(0 to M);  -- x(n),x(n-1),x(n-2) ... x(n-(M-1))

    -- vector for filter coefficients (values generated in Python and converted to fixed point Q1.15)
    -- conviene que esto sea signed en vez de std_logic_vector?
    type coef_vector_type is array (integer range <>) of signed(N_COEF-1 downto 0);
    constant coef_vector_reg : coef_vector_type(0 to M) := (
        (to_signed(-1604, N_COEF)),     -- -0.04895594
        (to_signed(2056,  N_COEF)),     --  0.06275537
        (to_signed(9583,  N_COEF)),     --  0.29246401
        (to_signed(13848, N_COEF)),     --  0.4226075
        (to_signed(9583,  N_COEF)),     --  0.29246401
        (to_signed(2056,  N_COEF)),     --  0.06275537
        (to_signed(-1604, N_COEF))      -- -0.04895594
    );

    -- vector for multiplication results (input * coef) in max resolution
    type mult_vector_type is array (integer range <>) of std_logic_vector(N_INPUT+N_COEF-1 downto 0);
    signal mult_vector_reg : mult_vector_type(0 to M);

    -- vector for truncated multiplication results
    type trunc_vector_type is array (integer range <>) of std_logic_vector(N_TRUNC-1 downto 0);
    signal trunc_vector_reg : trunc_vector_type(0 to M/2);

    -- states to control the block
    type state_type is (
        ST_WAIT_DATA,
        ST_PROCESS_DATA,
        ST_TRANSMIT_DATA
    );

    -- internal variables
    signal state            : state_type;

    signal current_output   : std_logic_vector(N_OUTPUT-1 downto 0);
    signal enable_dsp       : std_logic;

begin

    -- generate input vector with past input samples
    input_vector_reg(0) <= i_slave_axis_tdata;
    generate_input_array : for i in 0 to M-1 generate
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

    -- multiplicate input samples and filter coefficients
    mult_process : process(all) is

        variable mult_vector_var : mult_vector_type(0 to M/2);

        constant MAX_OV : integer := (2**(N_TRUNC-1))-1; 
        constant MIN_OV : integer := (-2**(N_TRUNC-1)); 

    begin
        -- take advantage of the symmetric filter
        for i in 0 to M/2 loop

            if (i = M/2) then
                mult_vector_var(i) := std_logic_vector(signed(input_vector_reg(i)) * coef_vector_reg(i));
            else
                mult_vector_var(i) := std_logic_vector((signed(input_vector_reg(i)) + signed(input_vector_reg(M-i))) * coef_vector_reg(i));
            end if;

            -- truncate the output to N_TRUNC bits
--            -- MSB = '0' --> positive (sature to max value)
--            if ((mult_vector_var(i)(N_INPUT+N_COEF-1) = '0') and (or mult_vector_var(i)(N_INPUT+N_COEF-1 downto N_TRUNC-1) = '1')) then
--                trunc_vector_reg(i) <= std_logic_vector(to_signed(MAX_OV, trunc_vector_reg(i)'LENGTH));
--            -- MSB = '1' --> negative (saturate to min value)
--            elsif ((mult_vector_var(i)(N_INPUT+N_COEF-1) = '1') and (and mult_vector_var(i)(N_INPUT+N_COEF-1 downto N_TRUNC-1) = '0')) then
--                trunc_vector_reg(i) <= std_logic_vector(to_signed(MIN_OV, trunc_vector_reg(i)'LENGTH));
--            -- truncate
--            else
--                trunc_vector_reg(i) <= std_logic_vector(mult_vector_var(i)( mult_vector_var(i)'LEFT downto (mult_vector_var(i)'LEFT - N_TRUNC + 1) ));
--            end if;
            trunc_vector_reg(i) <= std_logic_vector(mult_vector_var(i)( mult_vector_var(i)'LEFT downto (mult_vector_var(i)'LEFT - N_TRUNC + 1) ));
            mult_vector_reg(i) <= mult_vector_var(i);
        end loop;

    end process; -- mult_process

    -- sum multiplication results
    sum_process : process(all) is
        variable temp_sum : signed(N_OUTPUT-1 downto 0);
    begin
        temp_sum  := (others => '0');
        for i in trunc_vector_reg'range loop
            temp_sum := temp_sum + signed(trunc_vector_reg(i));
        end loop;
    
        current_output <= std_logic_vector(temp_sum);

    end process; -- sum_process


    reg_process : process (i_clk)
    begin
        if (rising_edge(i_clk)) then
            -- active high synchronous reset
            if (i_rst = '1' ) then
                state                <= ST_WAIT_DATA;
                enable_dsp           <= '0';
                o_slave_axis_tready  <= '1';
                o_master_axis_tdata  <= (others => '0');
                o_master_axis_tvalid <= '1';
                -- current_output       <= (others => '0');
            else
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
                        o_master_axis_tdata  <= current_output;
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

            end if; -- if/else i_rst

        end if; -- rising_edge(clk)

    end process reg_process;

end architecture ; -- rtl
