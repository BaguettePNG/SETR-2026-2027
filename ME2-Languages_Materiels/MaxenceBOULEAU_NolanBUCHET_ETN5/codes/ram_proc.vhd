library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity system_top is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC
    );
end entity system_top;

architecture RTL of system_top is

    signal mem_addr  : std_logic_vector(11 downto 0);
    signal mem_wdata : std_logic_vector(31 downto 0);
    signal mem_rdata : std_logic_vector(31 downto 0);
    signal mem_we    : std_logic;

    signal quadram_addr  : unsigned(11 downto 0);
    signal quadram_wdata : unsigned(31 downto 0);
    signal quadram_rdata : unsigned(31 downto 0);

begin

    quadram_addr  <= unsigned(mem_addr);
    quadram_wdata <= unsigned(mem_wdata);
    mem_rdata     <= std_logic_vector(quadram_rdata);

    processor_inst : entity work.system
        port map (
            clk       => clk,
            rst       => rst,
            mem_addr  => mem_addr,
            mem_wdata => mem_wdata,
            mem_rdata => mem_rdata,
            mem_we    => mem_we
        );

    quadram_inst : entity work.quadram
        generic map (
            ADDR_SELECT => 2,
            ADDR_LENGHT => 12,
            DATA_LENGHT => 32
        )
        port map (
            clock    => clk,
            we       => mem_we,
            address  => quadram_addr,
            datain   => quadram_wdata,
            dataout  => quadram_rdata
        );

end architecture RTL;