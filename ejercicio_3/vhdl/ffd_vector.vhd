-- FFD vector

library ieee ;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ffd_vector is
    generic (
        N : integer := 8
    );
    port (
        i_clk       : in  std_logic;
        i_rst       : in  std_logic;
        i_enable    : in  std_logic;
        i_data      : in  std_logic_vector(N-1 downto 0);
        o_data      : out std_logic_vector(N-1 downto 0)
    );
end entity;

architecture rtl of ffd_vector is
    signal reg_in : std_logic_vector(o_data'RANGE);
begin

    reg_process : process (i_rst, i_clk)
    begin
        if (i_rst = '0') then
            reg_in <= (others => '0');
        elsif (rising_edge(i_clk)) then
            if (i_enable = '1') then
                reg_in <= i_data;         
            end if;    
        end if;
    end process reg_process;

    o_data <= reg_in;

end architecture rtl;
