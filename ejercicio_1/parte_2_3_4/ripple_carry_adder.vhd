-- Full adder using 2 half adders

-- bibliotecas
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entidad
entity ripple_carry_adder is
    generic (
        N : integer := 4
    );

    port (
        i_input_a  : in  std_logic_vector(N-1 downto 0);
        i_input_b  : in  std_logic_vector(N-1 downto 0);
        o_sum      : out std_logic_vector(N-1 downto 0);
        o_carry    : out std_logic
    );
end entity ripple_carry_adder;

-- arquitectura
architecture rtl of ripple_carry_adder is

    -- components
    component full_adder is
        port (
            i_input_a  : in  std_logic;
            i_input_b  : in  std_logic;
            i_carry_in : in  std_logic;
            o_sum      : out std_logic;
            o_carry    : out std_logic
        );
    end component full_adder;

    type carry_connection_t is array (integer range <>) of std_logic;
    
    signal carry_connection : carry_connection_t(0 to N);

begin

    carry_connection(0) <= '0'; -- carry_in = 0

    generate_adder : for i in 0 to N-1 generate

        u_full_adder : full_adder
        port map (
            i_input_a  => i_input_a(i),
            i_input_b  => i_input_b(i),
            i_carry_in => carry_connection(i),
            o_sum      => o_sum(i),
            o_carry    => carry_connection(i+1)
        );

    end generate;

    o_carry <= carry_connection(N);

end architecture rtl;
