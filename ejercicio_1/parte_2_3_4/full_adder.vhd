-- Full adder using 2 half adders

-- bibliotecas
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entidad
entity full_adder is
    port (
        i_input_a  : in  std_logic;
        i_input_b  : in  std_logic;
        i_carry_in : in  std_logic;
        o_sum      : out std_logic;
        o_carry    : out std_logic
    );
end entity full_adder;

-- arquitectura
architecture rtl of full_adder is

    -- components
    component half_adder is
        port (
            i_input_a : in  std_logic;
            i_input_b : in  std_logic;
            o_sum     : out std_logic;
            o_carry   : out std_logic
        );
    end component half_adder;

    signal half_adder_connection : std_logic;
    signal first_carry_out       : std_logic;
    signal second_carry_out      : std_logic;

begin

    u_half_adder_0: half_adder
    port map (
        i_input_a => i_input_a,
        i_input_b => i_input_b,
        o_sum     => half_adder_connection,
        o_carry   => first_carry_out
    );

    u_half_adder_1: half_adder
    port map (
        i_input_a => half_adder_connection,
        i_input_b => i_carry_in,
        o_sum     => o_sum,
        o_carry   => second_carry_out
    );

    comb_process: process(all)
    begin
        o_carry <= first_carry_out or second_carry_out;
    end process comb_process;

end architecture rtl;
