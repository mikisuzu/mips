/*
 * Instruction Decode Stage
 */

module ID ( 	
	CLK,
	RESET,
	FREEZE,
	/* output */
	single_fetch_OUT,
	R2_output_PR,
	rename_entry,
	insertBubble_OUT,
	SYS_OUT,
	jump_inst,
	do_write_RNQUEUE,
	do_read_IDQUEUE,
	/* input */
	R2_input,
	decode_entry,
	mispredict,
	flush_fCOM,
	empty_IDQUEUE,
	full_RNQUEUE,
	empty_ROB,
	debug
);

/* 
 * parameters
 */
parameter DECODE_ENTRY_SIZE =  96;
parameter RENAME_ENTRY_SIZE = 160;
parameter SYSCALL_BUBBLES   =   7;


/*
 * output
 */
//output reg      [31: 0] Operand_A1_PR;
//output reg      [31: 0] Operand_B1_PR;
//output reg      [31: 0] Dest_Value1_PR;
//output reg      [31: 0] nextInstruction_address_PR;
//output reg      [31: 0] readDataB1_PR;
//output reg      [31: 0] Instr1_PR;
//output reg      [ 5: 0] ALU_control1_PR;
//output reg      [ 4: 0] writeRegister1_PR;
//output reg      [ 4: 0] readRegisterA1_PR;
//output reg      [ 4: 0] readRegisterB1_PR;
//output reg      [ 4: 0] Instr1_10_6_PR;
//output reg              ALUSrc1_PR;
//output reg 	        taken_branch1_PR;
//output reg              MemRead1_PR;
//output reg              MemtoReg1_PR;
//output reg              MemWrite1_PR;
//output reg	        do_writeback1_PR;
//output reg              fetchNull2_OUT;
//output reg      	    [31: 0] Reg [0:31];
output reg 	        single_fetch_OUT;
output reg      	    [31: 0] R2_output_PR;
output reg			    do_read_IDQUEUE;
output reg			    do_write_RNQUEUE;
output reg [RENAME_ENTRY_SIZE-1: 0] rename_entry;
/* for syscall */
output reg              	    insertBubble_OUT;
output reg              	    SYS_OUT;
output reg              	    jump_inst;


/* 
 * input
 */
//input           [31: 0] Data1_MEM;
//input           [31 :0] Data1_WB;
//input           [31: 0] Instr1;//_IN;
//input           [31: 0] aluResult1;
//input           [31: 0] aluResult1_WB;
//input           [31: 0] PCA;
//input           [31: 0] writeData1_WB;
//input           [31: 0] CIA;
//input           [ 4: 0] writeRegister1_WB;
//input           [ 4: 0] writeRegister1_MEM;
//input                   do_writeback1_WB;
//input                   do_writeback1_MEM;
input                          CLK;
input                          RESET;
input			       FREEZE;
input                  [31: 0] R2_input;
input			       empty_IDQUEUE;
input			       full_RNQUEUE;
input [DECODE_ENTRY_SIZE-1: 0] decode_entry;
/* for mispredict */
input			       mispredict;
input			       flush_fCOM;
input 			       empty_ROB;

input                          debug;

/*
 * internal
 */
//wire            [31: 0] Instr1;
//wire            [31: 0] com_OpA1;
//wire            [31: 0] com_OpB1;
//wire            [31: 0] signExtended_output1;
//wire            [31: 0] Shift_addResult1;
//wire            [31: 0] Jump_address1;
//wire            [31: 0] R2_output;
//wire            [31: 0] readDataA1;
//wire            [31: 0] readDataB1;
//wire            [31: 0] Operand_B1;
//wire            [31: 0] nextInstruction_address;
//wire            [31: 0] CIAp4;	
//wire            [31: 0] PCAp4;	
//wire            [31: 0] nia1;	
//wire            [ 5: 0] ALU_control1;
//wire                    taken_branch1;
wire            [ 5: 0] ALU_control1;
wire            [ 5: 0] opcode1;
wire            [ 5: 0] funct1;
wire            [ 4: 0] format1;
wire            [ 4: 0] rt1;
wire		[31: 0] Instr1;
wire            [ 4: 0] readRegisterA1;
wire            [ 4: 0] readRegisterB1;
wire            [ 4: 0] writeRegister1;
wire                    link1;
wire                    RegDst1;
wire                    jump1;
wire                    branch1;
wire                    MemRead1;
wire                    MemtoReg1;
wire                    MemWrite1;
wire                    ALUSrc1;
wire                    RegWrite1;
wire                    jumpRegister_Flag1;
wire                    sign_or_zero_Flag1;
wire                    syscal1;
wire			do_writeback1;
/* for hazard */
wire			MemHazard;
wire			SysHazard;
wire			WAWHazard;
wire			RAWHazard;
wire			JMPHazard;
wire			NOPHazard;
wire			comment1;

reg			single_fetch_PR;
reg             [ 2: 0] syscalBubbleCounter;

/* 
 * combinational logic
 */
/*assign fetchNull2_OUT = taken_branch1;
assign CIAp4 = CIA + 32'h00000004;
assign PCAp4 = PCA + 32'h00000004;
assign Jump_address1=(jumpRegister_Flag1)?{CIA[31:28],Instr1[25:0],2'b0}:com_OpA1;//readDataA1;
assign signExtended_output1 = (sign_or_zero_Flag1)?{{16{Instr1[15]}},Instr1[15:0]}:{16'b0,Instr1[15:0]};
assign Shift_addResult1 = PCA+(signExtended_output1<<2);	
assign nia1 = (jump1)? Jump_address1: ((taken_branch1)? Shift_addResult1: PCA);
assign nextInstruction_address = nia1;
assign readRegisterA1=Instr1[25:21];
assign readRegisterB1 = Instr1[20:16];
assign readDataA1 = Reg[readRegisterA1];
assign readDataB1 = Reg[readRegisterB1];
assign Operand_B1 = (ALUSrc1)?signExtended_output1:readDataB1;
assign R2_output = Reg[2];*/

/* parse decode entry */
assign Instr1		= decode_entry[31: 0];

/* for syscall */
//assign insertBubble_OUT = syscal1 && (syscalBubbleCounter != 0);
//assign SYS_OUT          = syscal1 && (syscalBubbleCounter == 0);
assign insertBubble_OUT = syscal1 && (!empty_ROB);
assign SYS_OUT          = syscal1 && empty_ROB;
//assign readRegisterA1   = (link1 || syscal1) ? 5'b00000 : Instr1[25:21];
assign readRegisterA1   = Instr1[25:21];
//assign readRegisterB1   = (ALUSrc1 || link1 || syscal1) ? 5'b00000 : Instr1[20:16];
assign readRegisterB1   = Instr1[20:16];
assign writeRegister1   = (RegDst1) ? Instr1[15:11] : ((link1) ? 5'b11111 : ((syscal1) ? 5'b00000 : Instr1[20:16]));
assign do_writeback1 	= ((RegWrite1)&&(writeRegister1!=5'b00000)&&(ALU_control1!=6'b110100)) || MemtoReg1;
/* for read/write queue */
assign do_write_RNQUEUE = (!RESET || FREEZE || mispredict || insertBubble_OUT || flush_fCOM|| 
				full_RNQUEUE || empty_IDQUEUE) ? 1'b0 : 1'b1;
//assign do_read_IDQUEUE = (!RESET || FREEZE || mispredict || flush_fCOM || full_RNQUEUE || empty_IDQUEUE) ? 1'b0 : 1'b1;
assign do_read_IDQUEUE = do_write_RNQUEUE; 
//assign do_read_IDQUEUE = (!RESET || FREEZE || mispredict || insertBubble_OUT || flush_fCOM|| 
//				empty_IDQUEUE) ? 1'b0 : 1'b1;
assign rename_entry    = (!do_write_RNQUEUE) ? 0 : {19'b0, do_writeback1, link1,RegDst1, jump1, branch1, MemRead1, MemtoReg1, 
				MemWrite1, ALUSrc1, RegWrite1, jumpRegister_Flag1, sign_or_zero_Flag1, syscal1, 6'b0, 
				ALU_control1, Instr1[10: 6], writeRegister1, readRegisterB1, readRegisterA1, decode_entry};

assign jump_inst	=  jump1;

//assign comment1 = (debug && !FREEZE);
assign comment1 = debug;
	/*
	always begin 
		//Forwarded Operand A
		if (do_writeback1_PR && (readRegisterA1 == writeRegister1_PR))
			com_OpA1 = aluResult1;
		else if (do_writeback1_MEM && (readRegisterA1 == writeRegister1_MEM))
			com_OpA1 = Data1_MEM;
		else if (do_writeback1_WB && (readRegisterA1 == writeRegister1_WB))	
			com_OpA1 = Data1_WB;	
		else com_OpA1 = readDataA1;
		//Forwarded Operand B
		if (do_writeback1_PR && (readRegisterB1 == writeRegister1_PR))// && (ALUSrc1!=1)
			com_OpB1 = aluResult1;
		else if (do_writeback1_MEM && (readRegisterB1 == writeRegister1_MEM))// && (ALUSrc1!=1))
			com_OpB1 = Data1_MEM;
		else if (do_writeback1_WB && (readRegisterB1 == writeRegister1_WB))// && (ALUSrc1!=1)
			com_OpB1 = Data1_WB;
		else com_OpB1 = Operand_B1;
	end
	*/
	
	//compare compare1(jump1,com_OpA1,com_OpB1,Instr1,taken_branch1);
	/* TA: These signals may be used for superscalar operation
	assign MemHazard = 
	assign SysHazard =
	assign WAWHazard = 
	assign RAWHazard =
	assign JMPHazard =
	assign NOPHazard =
	assign single_fetch_OUT = 
	*/

	//CONTROLLER1
	//*note, syscall, and all link instructions have been assigned alucontrol of addi
	always begin
		//$display("============================================================================================================================================CYCLE=");
     		opcode1 = Instr1[31:26];
     		format1 = Instr1[25:21];
     		rt1     = Instr1[20:16];
     		funct1  = Instr1[5:0];
		case ( opcode1 )
		     6'b000000: begin //SPECIAL
                    	case ( funct1 )
                        		6'b000000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001000010011;if(comment1)$display("[1]sll,nop\n");end//SLL,NOP
					6'b000010: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001000011011;if(comment1)$display("[1]srl\n");end//SRL
					6'b000011: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001000011001;if(comment1)$display("[1]sra\n");end//SRA
					6'b000100: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001000010100;if(comment1)$display("[1]sllv\n");end//SLLV
					6'b000110: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001000011100;if(comment1)$display("[1]srlv\n");end//SRLV
					6'b000111: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001000011010;if(comment1)$display("[1]srav\n");end//SRAV
					6'b001000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b001100000000111110;if(comment1)$display("[1]jr\n");end//JR
					6'b001001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b101100001000000001;if(comment1)$display("[1]jalr\n");end//JALR
					6'b001100: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000011011000001;if(comment1)$display("[1]syscal1\n");end//syscal1*
					6'b001101: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000011000010011;if(comment1)$display("[1]break\n");end//BREAK*
					6'b010000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001000001001;if(comment1)$display("[1]mfhi\n");end//MFHI
					6'b010001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000000000001011;if(comment1)$display("[1]mthi\n");end//MTHI
					6'b010010: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001000001010;if(comment1)$display("[1]mflo\n");end//MFLO
					6'b010011: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000000000001100;if(comment1)$display("[1]mtlo\n");end//MTLO
					6'b011000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000000000001101;if(comment1)$display("[1]mult\n");end//mult
					6'b011001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000000000001101;if(comment1)$display("[1]multu\n");end//multu
					6'b011010: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000000000000101;if(comment1)$display("[1]div\n");end//div
					6'b011011: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000000000000110;if(comment1)$display("[1]divu\n");end//divu
					6'b100000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001100000000;if(comment1)$display("[1]add\n");end//add
					6'b100001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001100110111;if(comment1)$display("[1]addu\n");end//addu
					6'b100010: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001100011101;if(comment1)$display("[1]sub\n");end//sub
					6'b100011: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001100011110;if(comment1)$display("[1]subu\n");end//subu
					6'b100100: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001100000100;if(comment1)$display("[1]and\n");end//and
					6'b100101: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001100010000;if(comment1)$display("[1]or\n");end//or
					6'b100110: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001100011111;if(comment1)$display("[1]xor\n");end//Xor
					6'b100111: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001100001111;if(comment1)$display("[1]nor\n");end//nor
					6'b101010: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001100010101;if(comment1)$display("[1]slt\n");end//slt
					6'b101011: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000001000111111;if(comment1)$display("[1]sltu\n");end//sltu
                        		default: $display("Not an Instruction!");
                    		endcase
                	end
			6'b000001: begin
                		case ( rt1 )
                     			5'b00000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000100000010100111;if(comment1)$display("[1]bltz\n");end//BLTZ
					5'b00001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000100000010100011;if(comment1)$display("[1]bgez\n");end//BGEZ
					5'b10000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b100100011010000001;if(comment1)$display("[1]bltzal\n");end//BLTZAL
					5'b10001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b100100011010000001;if(comment1)$display("[1]bgezal\n");end//BGEZAL
                        		default: $display("Not an Instruction!");
                    		endcase
                	end
			6'b000010: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b001100000100001110;if(comment1)$display("[1]jump\n");end//J
			6'b000011: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b101000011010000001;if(comment1)$display("[1]jal\n");end//JAL
			6'b000100: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000100000010100010;if(comment1)$display("[1]beq\n");end//BEQ
			6'b000101: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000100000010101001;if(comment1)$display("[1]bne\n");end//BNE
			6'b000110: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000100000010100110;if(comment1)$display("[1]blez\n");end//BLEZ
			6'b000111: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000100000010100101;if(comment1)$display("[1]bgtz\n");end//BGTZ
			6'b001000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000011010000001;if(comment1)$display("[1]addi\n");end//ADDI  
			6'b001001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000011010000010;if(comment1)$display("[1]addiu\n");end//ADDIU
			6'b001010: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000011010010101;if(comment1)$display("[1]slti\n");end//SLTI
			6'b001011: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000011010010101;if(comment1)$display("[1]sltiu\n");end//SLTIU
			6'b001100: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000011000000100;if(comment1)$display("[1]andi\n");end//ANDI
			6'b001101: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000011000010000;if(comment1)$display("[1]ori\n");end//ORI
			6'b001110: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000011000100000;if(comment1)$display("[1]xori\n");end//XorI
			6'b001111: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000011000001000;if(comment1)$display("[1]lui\n");end//LUI
	        	6'b010001: begin //COP1
		     		case( format1 )
		          		5'b00000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000001010011100;if(comment1)$display("[1]mfc1\n");end//MFC1
			  		5'b00010: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000001010011010;if(comment1)$display("[1]cfc1\n");end//CFC1
			  		5'b00100: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000000010111000;if(comment1)$display("[1]mtc1\n");end//MTC1
			  		5'b00110: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000000010110100;if(comment1)$display("[1]ctc1\n");end//CTC1
			  		5'b01000:begin
			       			case( Instr1[16] )
			            			1'b1: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000100000010011101;if(comment1)$display("[1]bc1t\n");end//BC1T
				    			1'b0: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000100000010001111;if(comment1)$display("[1]bc1f\n");end//BC1F
			       			endcase
			  		end
			  		5'b10000:begin 
						if( Instr1[7:4] == 4'b0011 ) begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000000000011111;if(comment1)$display("[1]fp c.cond\n");end//fp c.cond
			       			else begin
			        			case( funct1 )
				         			6'b000000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000000000011011;if(comment1)$display("[1]fp add\n");end//fp add
			                 			6'b000001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000000000000000;if(comment1)$display("[1]fp sub\n");end//fp sub
                                     				6'b000010: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000000000001101;if(comment1)$display("[1]fp mul\n");end//fp mul
                                    				6'b000011: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000000000000101;if(comment1)$display("[1]fp div\n");end//fp div
                                    				6'b000101: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000000000110111;if(comment1)$display("[1]fp abs\n");end//fp abs
                                    				6'b000110: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000000010000100;if(comment1)$display("[1]fp mov\n");end//MOV.FMT
                                   				6'b000111: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000000000010000;if(comment1)$display("[1]fp neg\n");end//fp neg
				         			default: $display("Not an Instruction!");
			            			endcase
			       			end
					end
		     			5'b10001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b010000000010001000;if(comment1)$display("[1]fp cvt.s\n");end//CVT.S.FMT
		          		default: $display("Not an Instruction!");
		 		endcase
			end
			6'b100000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000011011100100001;if(comment1)$display("[1]lb\n");end//LB
			6'b100001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000011011100101011;if(comment1)$display("[1]lh\n");end//LH
			6'b100010: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000011011100101101;if(comment1)$display("[1]lwl\n");end//LWL
			6'b100011: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000011011100111101;if(comment1)$display("[1]lw\n");end//LW
	        	6'b110000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000011011100111101;if(comment1)$display("[1]lwc0\n");end//LWC0
			6'b100100: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000011011100101010;if(comment1)$display("[1]lbu\n");end//LBU
			6'b100101: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000011011100101100;if(comment1)$display("[1]lhu\n");end//LHU
			6'b100110: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000011011100101110;if(comment1)$display("[1]lwr\n");end//LWR
			6'b101000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000110100101111;if(comment1)$display("[1]sb\n");end//SB
			6'b101001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000110100110000;if(comment1)$display("[1]sh\n");end//SH
			6'b101010: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000110100110010;if(comment1)$display("[1]swl\n");end//SWL
			6'b101011: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000110100110001;if(comment1)$display("[1]sw\n");end//SW
	        	6'b111000: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000110100110001;if(comment1)$display("[1]swc0\n");end//SWC0
			6'b101110: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000110100110011;if(comment1)$display("[1]swr\n");end//SWR
			6'b110001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000011010010110101;if(comment1)$display("[1]lwc1\n");end//LWC1
			6'b111001: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000000110010111001;if(comment1)$display("[1]swc1\n");end//SWC1
			6'b010100: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000100000010111010;if(comment1)$display("[1]beql\n");end//BEQL
			6'b010110: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000100000010111011;if(comment1)$display("[1]blezl\n");end//BLEZL
			6'b010101: begin {link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1,ALU_control1} = 18'b000100000010111100;if(comment1)$display("[1]bnel\n");end//BNEL
			default: $display("Not an Instruction!");
		endcase
	end

// PIPE REGISTERS 0
always @ (posedge CLK or negedge RESET) begin
	if(!RESET || mispredict || flush_fCOM) begin
			//R2_output_PR <= 32'b0;
			//nextInstruction_address_PR <= 32'b0;
                        syscalBubbleCounter 	<= 3'b111; /// only allowed here
			single_fetch_PR 	<= 1'b0;
	end
    	else if(!FREEZE) begin
			//R2_output_PR <= (insertBubble_OUT)? 0: R2_output;
			//nextInstruction_address_PR <= (insertBubble_OUT)? 0: nextInstruction_address;
                        syscalBubbleCounter 	<= (syscal1) ?  (syscalBubbleCounter-1): 3'b111;
			single_fetch_PR 	<= single_fetch_OUT;
	end
end

	/*
	//REGISTER FILE
	always @ (posedge CLK)
		begin
			if (do_writeback1_WB) 
				Reg[writeRegister1_WB] = writeData1_WB;
		end
	*/

//PIPE REGISTERS 1
always @ (posedge CLK or negedge RESET) begin
	if(!RESET || insertBubble_OUT || mispredict) begin
		//Operand_A1_PR <= 32'b0;
		//Operand_B1_PR <= 32'b0;
		//writeRegister1_PR <= 5'b0;
		//taken_branch1_PR <= 1'b0;
		//MemRead1_PR <= 1'b0;
		//MemtoReg1_PR <= 1'b0;
		//MemWrite1_PR <= 1'b0;
		//ALU_control1_PR <=6'b0;
		//readRegisterA1_PR <= 5'b0;
		//readRegisterB1_PR <= 5'b0;
		//do_writeback1_PR <= 1'b0;
                //Instr1_10_6_PR <= 5'b0;
		//readDataB1_PR <= 32'b0;
                //Dest_Value1_PR <= 32'b0;
		//Instr1_PR <= 32'b0;
		//ALUSrc1_PR <= 1'b0;
		//rename_entry <= 160'b0;
	end
    	else if(!FREEZE && do_read_IDQUEUE) begin
		//Operand_A1_PR <= (link1)?PCA:((syscal1)?R2_input:readDataA1);
		//Operand_B1_PR <= (link1)?32'h00000004:((syscal1)?32'h00000000:Operand_B1);
		//writeRegister1_PR <= writeRegister1;
		//taken_branch1_PR <= taken_branch1;
		//MemRead1_PR <= MemRead1;
		//MemtoReg1_PR <= MemtoReg1;
		//MemWrite1_PR <= MemWrite1;
		//ALU_control1_PR <= ALU_control1;
		//readRegisterA1_PR <= (link1 || syscal1)?5'b00000:readRegisterA1;
		//readRegisterB1_PR <= (ALUSrc1 || link1 || syscal1)?5'b00000:readRegisterB1;
		//do_writeback1_PR <= ((RegWrite1)&&(writeRegister1!=5'b00000)&&(ALU_control1!=6'b110100))||MemtoReg1;
                //Instr1_10_6_PR <= Instr1[10: 6];
		//readDataB1_PR <= readDataB1;
                //Dest_Value1_PR <= Reg[writeRegister1];
		//Instr1_PR <= Instr1;
		//ALUSrc1_PR <= ALUSrc1;
		//rename_entry <= {19'b0, do_writeback1, link1,RegDst1,jump1,branch1,MemRead1,MemtoReg1,MemWrite1,ALUSrc1,RegWrite1,jumpRegister_Flag1,sign_or_zero_Flag1,syscal1, 6'b0, ALU_control1, Instr1[10: 6], writeRegister1, readRegisterB1, readRegisterA1, decode_entry};
	end
end

always @ (posedge CLK or negedge RESET) begin
	if (debug) begin
		$display("[ID]:\tdo_writeback1=%x\tsyscalCounter=%d\tFREEZE=%d", 
			do_writeback1, syscalBubbleCounter, FREEZE);
		$display("[ID]:\tinst=%x", decode_entry[31:0]);
	end
end

endmodule
