-- bibliotecas
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entidad
entity tb_full_adder is
end entity tb_full_adder;

-- arquitetura
architecture testbench of tb_full_adder is

    component full_adder is
        port (
            i_input_a  : in  std_logic;
            i_input_b  : in  std_logic;
            i_carry_in : in  std_logic;
            o_sum      : out std_logic;
            o_carry    : out std_logic
        );
    end component full_adder;

    signal tb_input_a  : std_logic;
    signal tb_input_b  : std_logic;
    signal tb_carry_in : std_logic;
    signal tb_sum      : std_logic;
    signal tb_carry    : std_logic;

    type test_vector is record
        carry_in, a, b : std_logic;
        carry_out, sum : std_logic;
    end record;

    type test_vector_array is array (natural range <>) of test_vector;
    constant test_vectors : test_vector_array := (
    --  c_in   a    b  c_out sum
        ('0', '0', '0', '0', '0'),
        ('0', '0', '1', '0', '1'),
        ('0', '1', '0', '0', '1'),
        ('0', '1', '1', '1', '0'),
        ('1', '0', '0', '0', '1'),
        ('1', '0', '1', '1', '0'),
        ('1', '1', '0', '1', '0'),
        ('1', '1', '1', '1', '1')
    );

begin

    dut : full_adder
    port map(
        i_input_a  => tb_input_a,
        i_input_b  => tb_input_b,
        i_carry_in => tb_carry_in,
        o_sum      => tb_sum,
        o_carry    => tb_carry
    );

    tb_process: process
        constant period : time := 50 ns;
    begin

        for i in test_vectors'range loop
            tb_carry_in <= test_vectors(i).carry_in;
            tb_input_a  <= test_vectors(i).a;
            tb_input_b  <= test_vectors(i).b;
            wait for period;
            assert ( (tb_sum = test_vectors(i).sum) and (tb_carry = test_vectors(i).carry_out) ) report "Test failed" severity error;
            -- report  "test_vector " & integer'image(i) & " failed " & " for input a = " & std_logic'image(a) & 
            --         " and b = " & std_logic'image(b) severity error;

        end loop;
        wait;


    end process tb_process;

end architecture testbench;
