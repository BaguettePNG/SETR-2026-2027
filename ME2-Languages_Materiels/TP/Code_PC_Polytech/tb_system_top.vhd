library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_system_top is
end entity tb_system_top;

architecture sim of tb_system_top is

    -- Déclaration des signaux de test
    signal clk : STD_LOGIC := '0';
    signal rst : STD_LOGIC := '1';

    -- Période de l'horloge (10 ns -> 100 MHz)
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instanciation de ton composant principal (system_top)
    uut : entity work.system_top
        port map (
            clk => clk,
            rst => rst
        );

    -- Processus de génération de l'horloge
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Processus de simulation (Stimulus)
    stim_process : process
    begin
        -- Maintien du reset actif au démarrage
        rst <= '1';
        wait for 30 ns; -- On maintient le reset pendant 3 cycles complets
        
        -- Relâchement propre du reset sur un flanc descendant pour éviter les conflits
        wait until falling_edge(clk);
        rst <= '0';
        
        -- On laisse tourner (le $finish de ton code Verilog arrêtera 
        -- automatiquement la simulation lorsque l'instruction EBREAK sera atteinte)
        wait for 2000 ns;
        
        -- Fin de simulation de secours si aucun EBREAK n'est atteint
        report "Fin de la simulation de testbench." severity note;
        wait;
    end process;

end architecture sim;
