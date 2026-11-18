/*
  Authors: Teo Biton
  Date: 07.11.2025
  Description: Simple single-cycle RISC-V processor (RV32I) adapted for external memory (Quadram)
*/

module system (
  input wire clk,   // Horloge
  input wire rst,   // Reset
  
  // Interface externe vers la mémoire (Quadram)
  output reg  [11:0] mem_addr,
  output reg  [31:0] mem_wdata,
  input  wire [31:0] mem_rdata,
  output reg         mem_we,
  
  // Interface d'instruction
  output wire [11:0] pc_out,
  input  wire [31:0] instr_in
);

  // Parameters declaration
  parameter 
    Step      = 10,           // execution time of one instruction
    DataWidth = 32,           // data bus width
    AddrWidth = 12,           // address bus width
    MemSize   = 1<<AddrWidth; // memory size

  // Local parameters declaration
  localparam InstrSize = 32; // instructions are on 32 bits
  localparam NRegs  = 32;    // number of internal registers

  reg[InstrSize-1:0] instr;               // instruction register declaration
  reg[AddrWidth-1:0] pc;                  // program counter
  reg[DataWidth-1:0] regs[0:NRegs-1];     // regfile declaration

  /*
    Instruction Fields
  */
  `define OPCODE  instr[6:0]     // opcode
  `define F3      instr[14:12]   // funct3
  `define F7      instr[31:25]   // funct7

  // register fields
  `define RS1   instr[19:15]    // source register 1
  `define RS2   instr[24:20]    // source register 2
  `define RD    instr[11:7]     // destination register

  // immediates
  `define I_IMM   $signed(instr[31:20])                    // I-type immediate
  `define S_IMM   $signed(instr[31:25] << 5 | instr[11:7]) // S-type immediate

  // addresses
  `define LOAD_OFFSET    instr[31:20]
  `define STORE_OFFSET   (instr[31:25] << 5 | instr[11:7])

  /* Opcodes */
  `define ARITHMETIC      7'b0110011
  `define IMM_ARITHMETIC  7'b0010011
  `define LOAD            7'b0000011
  `define STORE           7'b0100011
  `define EBREAK          7'b1110011

  /* Arithmetic instructions */
  `define ADD   {3'b000, 7'b0000000}
  `define SUB   {3'b000, 7'b0100000}
  `define SLL   {3'b001, 7'b0000000}  
  `define SRL   {3'b101, 7'b0000000}  
  
  `define MUL   {3'b000, 7'b0000001}
  `define DIV   {3'b100, 7'b0000001}

  /* Load instructions */
  `define LW    3'b010  

  /* Store instructions */
  `define SW    3'b010  

  /* Arithmetic immediates instructions */
  `define ADDI  3'b000  
  `define ANDI  3'b111  
  `define ORI   3'b110  

  integer index;
  assign pc_out = pc;

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
      pc       <= pc + 1;         // Incrémentation du PC
      instr    <= instr_in;       // Récupération de l'instruction externe
      
      // Valeurs par défaut du bus externe à chaque cycle
      mem_we   <= 1'b0;
      mem_addr <= 0;
      mem_wdata<= 0;

      case(`OPCODE)
        `ARITHMETIC: begin
          case({`F3, `F7})
            `ADD: regs[`RD] <= regs[`RS1] + regs[`RS2];
            `SUB: regs[`RD] <= regs[`RS1] - regs[`RS2];
            `SRL: regs[`RD] <= regs[`RS1] >> regs[`RS2][4:0];
            `SLL: regs[`RD] <= regs[`RS1] << regs[`RS2][4:0];
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
              // La donnée lue sur mem_rdata sera disponible au cycle suivant (ou combinatoirement selon la RAM)
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