-- Implementacion basica de una ALU
-- NO se considera el overflow de la suma/resta.

-- bibliotecas
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entidad
entity alu is
    generic (
        N: integer := 16
    );
    port (
        i_input_a : in  std_logic_vector(N-1 downto 0);
        i_input_b : in  std_logic_vector(N-1 downto 0);
        i_sel     : in  std_logic_vector(1   downto 0);
        o_output  : out std_logic_vector(N-1 downto 0)
    );
end entity alu;

-- arquitectura
architecture rtl of alu is
    -- declaracion de senales, variables y constantes internas de la arquitectura
begin

    comb_alu_process: process(all)
        -- variables
    begin
        case (i_sel) is
            when "00" =>
                o_output <= std_logic_vector(to_signed(to_integer(signed(i_input_a)) + to_integer(signed(i_input_b)), o_output'LENGTH));
            when "01" =>
                o_output <= std_logic_vector(to_signed(to_integer(signed(i_input_a)) - to_integer(signed(i_input_b)), o_output'LENGTH));
            when "10" =>
                o_output <= i_input_a or i_input_b;
            when "11" =>
                o_output <= i_input_a and i_input_b;
             when others =>
                 o_output <= std_logic_vector(to_unsigned(0, o_output'LENGTH));
        end case;
    end process comb_alu_process;

end architecture rtl;
