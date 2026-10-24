 /*
 Authors: Teo Biton
 Date: 07.11.2025
 Description: Simple single-cycle RISC-V processor (RV32I) for simulation
 
 RISC-V Unprivileged Specifications Volume I: https://riscv.org/technical/specifications/
 Chapters and pages from this Volume are referenced for help (see the one on madoc).
*/

module system (
  input wire clk,   // Horloge
  input wire rst,   // Reset
  
  // Interface externe vers la mémoire (Quadram)
  output reg 	[11:0] 	mem_addr,   	// Changed from wire to reg
  output reg 	[31:0] 	mem_wdata,  	// Changed from wire to reg
  input  wire 	[31:0] 	mem_rdata,
  output reg         	mem_we     	// Changed from wire to reg
);

  // Parameters declaration
  parameter 
    Step      = 10,           // execution time of one instruction
    DataWidth = 32,           // data bus width
    AddrWidth = 12,           // address bus width
    MemSize   = 1<<AddrWidth; // memory size

  // Local parameters declaration
  localparam InstrSize = 32; // instructions are on 32 bits
  localparam NRegs  = 32;   // number of internal registers

  reg [InstrSize-1:0] instr;              // Registre d'instruction
  reg [AddrWidth-1:0] pc;                 // Program Counter
  reg [DataWidth-1:0] regs[0:NRegs-1];    // Banc de registres

  reg [31:0] memory [0:MemSize-1];

  // Load memory
  initial begin
 	// Load memory avec des slashs (/)
 	$readmemh("Z:/5A-ETN/ME2-Langages_materiels/Modèle processeur-20261005/instr2.mem", memory);
	$display("Memory load");
  end 
  
  /*
    Instruction Fields
    Chapter 2.2 Base Instruction Formats
  */

  // instruction identifiers - Pages 15, 16
  `define OPCODE  instr[6:0]     // opcode
  `define F3      instr[14:12]   // funct3
  `define F7      instr[31:25]   // funct7

  // register fields - Pages 15, 16
  `define RS1   instr[19:15]    // source register 1
  `define RS2   instr[24:20]    // source register 2
  `define RD    instr[11:7]     // destination register

  // immediates - Pages 15, 16
  `define I_IMM   $signed(instr[31:20])                 // I-type immediate
  `define S_IMM   $signed(instr[31:25] << 5 | instr[11:7]) // S-type immediate
  //`define S_IMM  $signed({instr[31:25], instr[11:7]})

  // addresses (for Load and Store instructions
  // chapter 2.6 Load and Store Instructions
  `define LOAD_OFFSET     instr[31:20] << 12
  //`define STORE_OFFSET   (instr[31:25] << 5 | instr[11:7]) << 12
  `define STORE_OFFSET   (instr[31:25] << 5 | instr[11:7])

  /*
    Instruction Declarations
    Chapter 24 RV32/64G Instruction Set Listings
    Page 130
  */

  /* Opcodes */
  `define ARITHMETIC        7'b0110011
  `define IMM_ARITHMETIC    7'b0010011
  `define LOAD              7'b0000011
  `define STORE             7'b0100011
  `define EBREAK            7'b1110011

  /* Arithmetic instructions
     Format:    {Funct3, Funct7    } */
  `define ADD   {3'b000, 7'b0000000}
  `define SUB   {3'b000, 7'b0100000}
  `define SLL   {3'b001, 7'b0000000}  // Shift Left
  `define SRL   {3'b101, 7'b0000000}  // Shift Right
  
  // Add functions RV32IM
  `define MUL   {3'b000, 7'b0000001}
  `define DIV   {3'b100, 7'b0000001}

  /* Load instructions */
  `define LW    3'b010  // Load Word

  /* Store instructions */
  `define SW    3'b010  // Store Word

  /* Arithmetic immediates instructions */
  `define ADDI  3'b000  // Add Immediate
  `define ANDI  3'b111  // And Immediate
  `define ORI   3'b110  // Or Immediate

  /*
    Reset (start module)
  */
  integer index;

  initial begin
    
    // initialize program counter to 0
    pc = 0;
    // initialize all registers to 0
    for (index = 0; index < NRegs; index = index + 1) begin
      regs[index] = 0;
    end

  end

  /*
    Main cycle for one instruction
  */

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      pc       <= 0;
      instr    <= 0;
      mem_addr <= 0;
      mem_wdata<= 0;
      mem_we   <= 0;
      for (index = 0; index < NRegs; index = index + 1) begin
        regs[index] <= 0;
      end
    end 
    else begin
		instr      = memory[pc];
        
        // --- AJOUTE CES LIGNES DE DEBUG ---
        $display("Temps=%0t ns | PC=%0d | Instruction=%h | Opcode=%b", $time, pc, memory[pc], `OPCODE);
        // ----------------------------------

        pc         <= pc + 1;         // Incrémentation du PC

        // Valeurs par défaut du bus externe à chaque cycle
        mem_we     <= 1'b0;
        mem_addr   <= 0;
        mem_wdata  <= 0;
	  
      case(`OPCODE)
        `ARITHMETIC: begin
          case({`F3, `F7})
            `ADD: regs[`RD] <= regs[`RS1] + regs[`RS2];
            `SUB: regs[`RD] <= regs[`RS1] - regs[`RS2];
            `SRL: regs[`RD] <= regs[`RS1] >> regs[`RS2][4:0];
            `SLL: regs[`RD] <= regs[`RS1] << regs[`RS2][4:0];

            // Addictionnal function
			`MUL: regs[`RD] <= regs[`RS1] * regs[`RS2];
            `DIV: regs[`RD] <= regs[`RS1] / regs[`RS2];
            default: $display("erreur: mauvaise instruction arithmétique");
          endcase
        end
        `IMM_ARITHMETIC: begin
          case(`F3)
            `ADDI: regs[`RD] <= regs[`RS1] + `I_IMM;
            `ANDI: regs[`RD] <= regs[`RS1] & `I_IMM;
            `ORI:  regs[`RD] <= regs[`RS1] | `I_IMM;
            default: $display("erreur: mauvaise instruction arithmétique immédiate");
          endcase
        end
        `LOAD: begin
          case(`F3)
            `LW: begin
              mem_addr    <= regs[`RS1] + `I_IMM;
              regs[`RD]   <= mem_rdata; 
            end
            default: $display("erreur: mauvaise instruction load");
          endcase
        end
        `STORE: begin
          case(`F3)
            `SW: begin
              mem_we      <= 1'b1;
              mem_addr    <= regs[`RS1] + `S_IMM;
              mem_wdata   <= regs[`RS2];
            end
            default: $display("erreur: mauvaise instruction store");
          endcase
        end
        `EBREAK: $finish;
        default: $display("erreur: mauvaise valeur dans op-code");
      endcase
    end
  end
  
endmodule
