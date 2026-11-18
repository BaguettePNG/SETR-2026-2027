library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;

entity decoder_TB is
end entity decoder_TB;

architecture Bench of decoder_TB is
  signal Address 	: unsigned(1 downto 0);	-- INPUT
  signal CS 		: unsigned(3 downto 0); -- OUTPUT


begin

  UUT: entity work.decoder(RTL)
  port map (
    cs      => CS,
    address => Address
  );

  Stim: process is

  begin


	address <= "00";
	wait for 100 ns;

	address <= "01";
	wait for 100 ns;
	
	address <= "10";
	wait for 100 ns;
	
	address <= "11";
	wait for 100 ns;
	
	address <= "ZZ";
	wait for 100 ns;
	
	address <= "XX";
	wait for 100 ns;
	
    wait;
  end process;

end architecture Bench;
