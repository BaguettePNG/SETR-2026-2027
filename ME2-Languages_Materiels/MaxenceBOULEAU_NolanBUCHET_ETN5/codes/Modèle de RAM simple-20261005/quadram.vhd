library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;

entity quadram is
	generic(ADDR_SELECT : INTEGER := 2;
		ADDR_LENGHT : INTEGER := 10;
		DATA_LENGHT : INTEGER := 8
	);
	
    port (
		clock   : in  std_logic;
		we      : in  std_logic;
		address : in  unsigned((ADDR_LENGHT - 1) downto 0);
		datain  : in  unsigned((DATA_LENGHT - 1) downto 0);
		dataout : out unsigned((DATA_LENGHT - 1) downto 0)
    );
end entity quadram;

architecture RTL of quadram is

	signal cs_array : unsigned(((2**ADDR_SELECT) - 1) downto 0);
	
begin

DECODER : entity work.decoder(RTL)
generic map (
	SEL_LENGHT => ADDR_SELECT  
)
port map (
	cs      => cs_array,	-- OUTPUT
	address => address((ADDR_LENGHT - 1) downto ((ADDR_LENGHT - 1) - ( ADDR_SELECT - 1)))	-- INPUT
);

GenRam : for i in 0 to (2**ADDR_SELECT) - 1 generate 
	Ram : entity work.sync_ram(RTL)
	generic map (
		DataLenght => DATA_LENGHT,
		AddrLenght => ADDR_LENGHT - ADDR_SELECT
	)
	port map (
	cs			=> cs_array(i),
    clock   	=> clock,
    we    		=> we,
    address 	=> address(((ADDR_LENGHT - 1) - ADDR_SELECT) downto 0),
    datain  	=> datain,
    dataout     => dataout
);
end generate;


end architecture RTL;







