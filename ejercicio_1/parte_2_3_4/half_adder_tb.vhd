-- bibliotecas
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entidad
entity tb_half_adder is
end entity tb_half_adder;

-- arquitetura
architecture testbench of tb_half_adder is

    component half_adder is
        port (
            i_input_a : in  std_logic;
            i_input_b : in  std_logic;
            o_sum     : out std_logic;
            o_carry   : out std_logic
        );
    end component half_adder;

    signal tb_input_a : std_logic;
    signal tb_input_b : std_logic;
    signal tb_sum     : std_logic;
    signal tb_carry   : std_logic;

begin

    dut : half_adder
    port map(
        i_input_a => tb_input_a,
        i_input_b => tb_input_b,
        o_sum     => tb_sum,
        o_carry   => tb_carry
    );

    tb_process: process
        constant period : time := 50 ns;
    begin
        tb_input_a <= '0';
        tb_input_b <= '0';
        wait for period;
        assert ( (tb_sum = '0') and (tb_carry = '0') ) report "Test failed for input 00" severity error;

        tb_input_a <= '0';
        tb_input_b <= '1';
        wait for period;
        assert ( (tb_sum = '1') and (tb_carry = '0') ) report "Test failed for input 01" severity error;

        tb_input_a <= '1';
        tb_input_b <= '0';
        wait for period;
        assert ( (tb_sum = '1') and (tb_carry = '0') ) report "Test failed for input 10" severity error;

        tb_input_a <= '1';
        tb_input_b <= '1';
        wait for period;
        assert ( (tb_sum = '0') and (tb_carry = '1') ) report "Test failed for input 11" severity error;

        wait;

    end process tb_process;

end architecture testbench;
