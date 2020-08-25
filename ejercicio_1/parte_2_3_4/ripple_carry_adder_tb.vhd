-- bibliotecas
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entidad
entity tb_ripple_carry_adder is
end entity tb_ripple_carry_adder;

-- arquitetura
architecture testbench of tb_ripple_carry_adder is

    component ripple_carry_adder is
        generic (
            N : integer
        );
        port (
            i_input_a  : in  std_logic_vector(N-1 downto 0);
            i_input_b  : in  std_logic_vector(N-1 downto 0);
            o_sum      : out std_logic_vector(N-1 downto 0);
            o_carry    : out std_logic
        );
    end component ripple_carry_adder;

    constant tb_N     : natural := 4;
    signal tb_input_a : std_logic_vector(tb_N-1 downto 0);
    signal tb_input_b : std_logic_vector(tb_N-1 downto 0);
    signal tb_sum     : std_logic_vector(tb_N-1 downto 0);
    signal tb_carry   : std_logic;

begin

    dut : ripple_carry_adder
    generic map (
        N => tb_N
    )
    port map(
        i_input_a => tb_input_a,
        i_input_b => tb_input_b,
        o_sum     => tb_sum,
        o_carry   => tb_carry
    );

    tb_process: process
        constant period : time := 50 ns;
    begin
        tb_input_a <= X"5";
        tb_input_b <= X"4";
        wait for period;
        assert ( (tb_sum = X"9") and (tb_carry = '0') ) report "Test failed" severity error;

        tb_input_a <= X"4";
        tb_input_b <= X"2";
        wait for period;
        assert ( (tb_sum = X"6") and (tb_carry = '0') ) report "Test failed" severity error;

        tb_input_a <= X"F";
        tb_input_b <= X"2";
        wait for period;
        assert ( (tb_sum = X"1") and (tb_carry = '1') ) report "Test failed" severity error;

        wait;

    end process tb_process;

end architecture testbench;
