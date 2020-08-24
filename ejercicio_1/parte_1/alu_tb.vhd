-- bibliotecas
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entidad
entity tb_alu is
end entity tb_alu;

-- arquitetura
architecture testbench of tb_alu is

    component alu is
        generic (
            N: integer
        );
        port (
            i_input_a : in  std_logic_vector(N-1 downto 0);
            i_input_b : in  std_logic_vector(N-1 downto 0);
            i_sel     : in  std_logic_vector(1 downto 0);
            o_output  : out std_logic_vector(N-1 downto 0)
        );
    end component alu;

    constant tb_N     : natural := 16;
    signal tb_sel     : std_logic_vector(1 downto 0);
    signal tb_input_a : std_logic_vector(tb_N-1 downto 0);
    signal tb_input_b : std_logic_vector(tb_N-1 downto 0);
    signal tb_output  : std_logic_vector(tb_N-1 downto 0);

begin

    dut : alu
    generic map (
        N => tb_N
    )
    port map(
        i_input_a => tb_input_a,
        i_input_b => tb_input_b,
        i_sel     => tb_sel,
        o_output  => tb_output
    );

    -- asignacion de senales de entrada
    -- senal 0
    tb_input_a  <=  X"0002",
                    X"00FF" after 10 ns;

    -- senal 1
    tb_input_b  <=  X"0FFA",
                    X"FFF0" after 50 ns;

    tb_sel      <=  "00",
                    "01" after 25 ns,
                    "10" after 50 ns,
                    "11" after 75 ns;

end architecture testbench;
