-- test bench solution to ex09

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;

entity QuadRam_TB is
end entity QuadRam_TB;

architecture Bench of QuadRam_TB is
  signal Address :unsigned(9 downto 0);
  signal DataIn, DataOut :unsigned(7 downto 0);
  signal WE : Std_logic;
  signal clock : Std_logic;
  signal StopClock : boolean := FALSE;

begin

  UUT: entity work.quadram(RTL)
  port map (
    clock   => clock,
    we      => WE,
    address => Address,
    datain  => DataIn,
    DataOut => DataOut
  );

  ClockGen: process is
  begin
    while not StopClock loop
      clock <= '0';
      wait for 5 ns;
      clock <= '1';
      wait for 5 ns;
    end loop;
    wait;
  end process ClockGen;

  Stim: process is

  begin

    wait until rising_edge(clock); -- cycle 1
	we <= '1';
	
	address <= "00" & "00000001";
	datain <= x"55";

    wait until rising_edge(clock); -- cycle 2
	address <= "01" & "00000001";
	datain <= x"AA";

    wait until rising_edge(clock); -- cycle 3
	address <= "10" & "00000001";
	datain <= x"BB";

    wait until rising_edge(clock); -- cycle 4
	address <= "11" & "00000001";
	datain <= x"CC";
	
	
	
	wait until rising_edge(clock); -- cycle 1
	we <= '0';
	
	address <= "00" & "00000001";
	datain <= x"11";

    wait until rising_edge(clock); -- cycle 2
	address <= "01" & "00000001";
	datain <= x"22";

    wait until rising_edge(clock); -- cycle 3
	address <= "10" & "00000001";
	datain <= x"33";

    wait until rising_edge(clock); -- cycle 4
	address <= "11" & "00000001";
	datain <= x"44";
	
    StopClock <= true;
    wait;
  end process;

end architecture Bench;


