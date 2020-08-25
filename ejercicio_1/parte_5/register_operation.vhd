-- Full adder using 2 half adders

-- bibliotecas
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entidad
entity register_operation is
    generic (
        N : integer := 8
    );
    port (
        i_clk      : in   std_logic;
        i_rst      : in   std_logic;
        i_enable   : in   std_logic;
        i_input_1  : in   std_logic_vector(N-1 downto 0);
        i_input_2  : in   std_logic_vector(N-1 downto 0);
        i_input_3  : in   std_logic_vector(N-1 downto 0);
        i_input_4  : in   std_logic_vector(N-1 downto 0);
        o_output_1 : out  std_logic_vector(N-1 downto 0);
        o_output_2 : out  std_logic_vector(N-1 downto 0)
    );
end entity register_operation;

-- arquitectura
architecture rtl of register_operation is

    signal reg_in_1 : std_logic_vector(N-1 downto 0);
    signal reg_in_2 : std_logic_vector(N-1 downto 0);
    signal reg_in_3 : std_logic_vector(N-1 downto 0);
    signal reg_in_4 : std_logic_vector(N-1 downto 0);

begin

    -- asynchronous reset, active low
    reg_process: process(i_clk, i_rst)
    begin
        if (i_rst = '0') then
            reg_in_1 <= (others => '0');
            reg_in_2 <= (others => '0');
            reg_in_3 <= (others => '0');
            reg_in_4 <= (others => '0');
        elsif (rising_edge(i_clk)) then
            if (i_enable = '1') then
                reg_in_1 <= i_input_1;
                reg_in_2 <= i_input_2;
                reg_in_3 <= i_input_3;
                reg_in_4 <= i_input_4;
            end if;
        end if;
    end process reg_process;

    o_output_1 <= std_logic_vector(to_unsigned(to_integer(unsigned(reg_in_1)) + to_integer(unsigned(reg_in_2))
                + to_integer(unsigned(reg_in_3)) + to_integer(unsigned(reg_in_4)), o_output_1'LENGTH));
    o_output_2 <= reg_in_1 and reg_in_2 and reg_in_3 and reg_in_4;

end architecture rtl;
