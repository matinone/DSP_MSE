-- bibliotecas
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entidad
entity tb_register_operation is
end entity tb_register_operation;

-- arquitetura
architecture testbench of tb_register_operation is

    component register_operation is
        generic (
            N : integer
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
    end component register_operation;

    constant tb_N      : integer := 8;
    signal tb_clk      : std_logic;
    signal tb_rst      : std_logic;
    signal tb_enable   : std_logic;
    signal tb_input_1  : std_logic_vector(tb_N-1 downto 0);
    signal tb_input_2  : std_logic_vector(tb_N-1 downto 0);
    signal tb_input_3  : std_logic_vector(tb_N-1 downto 0);
    signal tb_input_4  : std_logic_vector(tb_N-1 downto 0);
    signal tb_output_1 : std_logic_vector(tb_N-1 downto 0);
    signal tb_output_2 : std_logic_vector(tb_N-1 downto 0);

    constant CLK_PERIOD : real := 10.0e-9; -- ns

begin

    -----------------------------------------------------------
    -- Entity Under Test
    -----------------------------------------------------------
    dut : register_operation
    generic map (
        N => tb_N
    )
    port map(
        i_clk      => tb_clk,
        i_rst      => tb_rst,
        i_enable   => tb_enable,
        i_input_1  => tb_input_1, 
        i_input_2  => tb_input_2, 
        i_input_3  => tb_input_3, 
        i_input_4  => tb_input_4, 
        o_output_1 => tb_output_1,
        o_output_2 => tb_output_2
    );

    -----------------------------------------------------------
    -- Clocks and Reset
    -----------------------------------------------------------
    CLK_GEN : process
    begin
        tb_clk <= '1';
        wait for CLK_PERIOD / 2.0 * (1 SEC);
        tb_clk <= '0';
        wait for CLK_PERIOD / 2.0 * (1 SEC);
    end process CLK_GEN;

    RESET_GEN : process
    begin
        tb_rst <= '0',
                  '1' after 20.0 * CLK_PERIOD * (1 SEC);
        wait;
    end process RESET_GEN;

    -----------------------------------------------------------
    -- Testbench Stimulus
    -----------------------------------------------------------
    tb_process : process is
    begin
        tb_enable <= '0';
        tb_input_1 <= (others => '0');
        tb_input_2 <= (others => '0');
        tb_input_3 <= (others => '0');
        tb_input_4 <= (others => '0');
        wait until (tb_rst = '1');
        -- wait 10 clock cycles
        delay_1 : for i in 0 to 10 loop
            wait until (tb_clk'event and tb_clk = '1');           
            end loop;
            
        -- generate 100 numbers and select 1 out of 10
        loop_gen : for i in 0 to 99 loop
            tb_input_1 <= std_logic_vector(to_unsigned(i,   tb_input_1'LENGTH));
            tb_input_2 <= std_logic_vector(to_unsigned(i+1, tb_input_2'LENGTH));
            tb_input_3 <= std_logic_vector(to_unsigned(i+2, tb_input_3'LENGTH));
            tb_input_4 <= std_logic_vector(to_unsigned(i+3, tb_input_4'LENGTH));
            
            tb_enable <= '0';
            if (i mod 10 = 0) then
                tb_enable <= '1';
            end if;
            
            wait until (tb_clk'event and tb_clk = '1');
        end loop;

        -- wait 10 clock cycles
        delay_2 : for i in 0 to 10 loop
            wait until (tb_clk'event and tb_clk = '1');           
        end loop;
    
        wait;
    end process tb_process;

end architecture testbench;
