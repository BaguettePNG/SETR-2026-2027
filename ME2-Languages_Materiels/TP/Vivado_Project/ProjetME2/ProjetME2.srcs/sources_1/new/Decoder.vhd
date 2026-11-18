library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 

entity Decoder is
    generic( ADDR_SELECT : integer := 2);
    Port ( addr_sel : in unsigned ((ADDR_SELECT - 1) downto 0);
           cs       : out unsigned (((2**ADDR_SELECT) - 1) downto 0));
end Decoder;

architecture Behavioral of Decoder is
begin

    process(addr_sel)
        variable sel_int : integer;
    begin
        -- Valeur par défaut : tous les bits de cs à '0'
        cs <= (others => '0');
        
        -- Conversion du signal unsigned en entier
        sel_int := to_integer(addr_sel);

        -- Activation du bit correspondant à l'adresse
        if sel_int >= 0 and sel_int < (2**ADDR_SELECT) then
            cs(sel_int) <= '1';
        end if;
    end process;

end Behavioral;