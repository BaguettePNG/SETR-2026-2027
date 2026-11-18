-- Decoder

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity decoder is
	generic(SEL_LENGHT : INTEGER := 2);
  port (
    address : in  unsigned((SEL_LENGHT - 1) downto 0);
    cs  : out unsigned(((2**SEL_LENGHT) - 1) downto 0)
  );
end entity decoder;

architecture RTL of decoder is
begin

	process(address)
	begin
		cs <= (others => '0');

		cs(to_integer(address)) <= '1' ;
		
		
	end process;

end architecture RTL;
