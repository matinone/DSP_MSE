-- AXI stream convolutional encoder

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity convolutional_encoder is
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
end entity;

architecture rtl of convolutional_encoder is
    -- shift register size
    constant K : integer := 7;
    constant CYCLES_TO_FILL_OUTPUT : integer := N_INPUT;

    -- generator polynomials
    constant POL_1_SLV : std_logic_vector(K-1 downto 0) := std_logic_vector(to_unsigned(POL_1, K));
    constant POL_2_SLV : std_logic_vector(K-1 downto 0) := std_logic_vector(to_unsigned(POL_2, K));

    -- states to control the block
    type state_type is (
        ST_WAIT_DATA,
        ST_PROCESS_DATA,
        ST_TRANSMIT_DATA
    );

    -- internal registers
    signal current_input    : std_logic_vector(N_INPUT-1 downto 0);
    signal current_output   : std_logic_vector(N_OUTPUT-1 downto 0);
    signal state            : state_type;
    signal count            : integer range 0 to N_INPUT;

begin

    reg_process : process (i_clk, i_rst)
        -- signal to temporarily store each XOR results
        variable temp_result : std_logic_vector(1 downto 0);
        variable shift_reg   : std_logic_vector(K-1 downto 0);
    begin
        if (i_rst = '0' ) then
            -- internal signals
            current_input   <= (others => '0');
            current_output  <= (others => '0');
            state           <= ST_WAIT_DATA;
            shift_reg       := (others => '0');
            count           <= 0;
            temp_result     := (others => '0');
            -- outputs (AXIS signals)
            o_master_axis_tdata  <= (others => '0');
            o_slave_axis_tready  <= '0';
            o_master_axis_tvalid <= '0';

        elsif (rising_edge(i_clk)) then

            case state is
                when ST_WAIT_DATA =>
                    o_slave_axis_tready <= '1';
                    -- new data available (slave tvalid) and it can be received (slave tready)
                    if (i_slave_axis_tvalid = '1' and o_slave_axis_tready = '1') then
                        state               <= ST_PROCESS_DATA;
                        current_input       <= i_slave_axis_tdata;
                        count               <= 0;
                        -- tready to 0 because the module will be processing in the next cycle, so it cant accept new data
                        o_slave_axis_tready <= '0';
                    end if;
                when ST_PROCESS_DATA =>
                    o_slave_axis_tready <= '0';
                    -- FIX: > or >= ?
                    if (count >= CYCLES_TO_FILL_OUTPUT) then
                        state <= ST_TRANSMIT_DATA;
                        count <= 0;
                        -- the module output will have valid data
                        o_master_axis_tvalid    <= '1';
                        o_master_axis_tdata     <= current_output;
                    else
                        -- put the next bit in the shift register
                        shift_reg := current_input(count) & shift_reg(shift_reg'left downto 1);
                        -- compute new outputs based on the polynomial
                        temp_result(0) := xor(shift_reg and POL_1_SLV);
                        temp_result(1) := xor(shift_reg and POL_2_SLV);
                        -- put the partial output in the corresponding part full output
                        current_output( (count*2+1) downto (count*2) ) <= temp_result;
                        -- increase count
                        count <= count + 1;
                    end if;
                when ST_TRANSMIT_DATA =>
                    o_slave_axis_tready     <= '0';
                    o_master_axis_tvalid    <= '1';
                    o_master_axis_tdata     <= current_output;
                    if (i_master_axis_tready = '1' and o_master_axis_tvalid = '1') then
                        -- valid transmission done
                        o_master_axis_tvalid <= '0';
                        state <= ST_WAIT_DATA;
                    else
                        state <= ST_TRANSMIT_DATA;
                    end if;
                when others =>
                    -- invalid state, so reset everything
                    current_input        <= (others => '0');
                    current_output       <= (others => '0');
                    state                <= ST_WAIT_DATA;
                    shift_reg            := (others => '0');
                    count                <= 0;
                    temp_result          := (others => '0');
                    o_master_axis_tdata  <= (others => '0');
                    o_slave_axis_tready  <= '0';
                    o_master_axis_tvalid <= '0';
            end case;

        end if;
    end process reg_process;

end architecture rtl;
