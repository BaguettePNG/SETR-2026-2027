`timescale 1ns / 1ps

module tb_top;
  reg clk;
  reg rst;

  // Instanciation du module principal 'top' (et non 'system')
  top uut (
    .clk(clk),
    .rst(rst)
  );

  // Horloge (période de 20ns : bascule toutes les 10ns)
  always #10 clk = ~clk;

  initial begin
    // Initialisation des signaux
    clk = 0;
    rst = 1; // Activation du reset au démarrage

    // Attendre 30 ns puis désactiver le reset
    #30;
    rst = 0;

    #2000;

    $display("[TIMEOUT] La simulation s'arrête par sécurité.");
    $finish;
  end

  // Affichage de suivi 
  initial begin
    $monitor("Temps = %0t ns | PC = %0d | Instruction = %h | x1 = %0d | x2 = %0d", 
             $time, uut.pc, uut.instr, uut.regs[1], uut.regs[2]);
  end

endmodule