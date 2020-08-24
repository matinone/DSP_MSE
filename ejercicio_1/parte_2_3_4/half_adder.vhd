-- Half adder

-- bibliotecas
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entidad
entity half_adder is
    port (
        i_input_a : in  std_logic;
        i_input_b : in  std_logic;
        o_sum     : out std_logic;
        o_carry   : out std_logic
    );
end entity half_adder;

-- arquitectura
architecture rtl of half_adder is
begin

    comb_process: process(all)
    begin
        o_sum   <= i_input_a xor i_input_b;
        o_carry <= i_input_a and i_input_b;
    end process comb_process;

end architecture rtl;
