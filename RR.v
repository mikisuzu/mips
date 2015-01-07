/*
 * Register Read Stage
 */
module RR ( 	
	CLK,
	RESET,
	FREEZE,
	/* output */
	exe_entry,
	//do_read_ISSQUEUE,
	//do_write_EXEQUEUE,
	/* input */
	Reg,
	R2_input,
	aluResult1_EXE,
	do_writeback1_MEM,
	writeRegister1_MEM,
	Data1_MEM,
	do_writeback1_RET,
	writeRegister1_RET,
	Data1_RET,
	writeData1_RET,
	mispredict,
	flush_fCOM,
	issue_entry,
	RAT_fRN,
	//empty_ISSQUEUE,
	//full_EXEQUEUE,
	debug
);
   	
/*
 * parameters
 */
parameter ISSUE_ENTRY_SIZE = 192;
parameter EXE_ENTRY_SIZE   = 320;
parameter REG_SIZE         =  64;
parameter RAT_SIZE         =  32;
parameter RAT_ENTRY_SIZE   =   7;


/*
 * output
 */
/*output reg      [31: 0] R2_output_PR;
output reg      [31: 0] Operand_A1_PR;
output reg      [31: 0] Operand_B1_PR;
output reg      [31: 0] Dest_Value1_PR;
output reg      [31: 0] nextInstruction_address_PR;
output reg      [31: 0] readDataB1_PR;
output reg      [31: 0] Instr1_PR;
output reg      [ 5: 0] ALU_control1_PR;
output reg      [ 4: 0] writeRegister1_PR;
output reg      [ 4: 0] readRegisterA1_PR;
output reg      [ 4: 0] readRegisterB1_PR;
output reg      [ 4: 0] Instr1_10_6_PR;
output reg              ALUSrc1_PR;
output reg 	        single_fetch_OUT;
output reg 	        taken_branch1_PR;
output reg              MemRead1_PR;
output reg              MemtoReg1_PR;
output reg              MemWrite1_PR;
output reg	        do_writeback1_PR;
output reg              insertBubble_OUT;
output reg              SYS_OUT;
output reg              fetchNull2_OUT;*/
output reg [EXE_ENTRY_SIZE-1: 0] exe_entry;
//output reg			 do_read_ISSQUEUE;
//output reg			 do_write_EXEQUEUE;

output reg   [RAT_ENTRY_SIZE-2: 0] RAT_fRN [0:RAT_SIZE-1];


/* 
 * input
 */
/*input           [31: 0] Instr1;//_IN;
input           [31: 0] PCA;
input           [31: 0] CIA;
input                   do_writeback1_MEM;*/
input                   	CLK;
input                   	RESET;
input				FREEZE;
input               [31: 0] Reg [0:REG_SIZE-1];
input           	[31: 0] R2_input;
input   [ISSUE_ENTRY_SIZE-1: 0] issue_entry;
/* for bypass */
input           [31: 0] aluResult1_EXE;
input                   do_writeback1_MEM;
input           [ 5: 0] writeRegister1_MEM;
input           [31: 0] Data1_MEM;
input                   do_writeback1_RET;
input           [ 5: 0] writeRegister1_RET;
input           [31 :0] Data1_RET;		/* for bypass */
//input           [31: 0] aluResult1_RET;
input           [31: 0] writeData1_RET;		/* for reg write back */
/* for mispredict */
input			mispredict;
input			flush_fCOM;

//input			empty_ISSQUEUE;
//input			full_EXEQUEUE;

input                   debug;

/* 
 * internal
 */
wire            [31: 0] Instr1;
wire            [31: 0] com_OpA1;
wire            [31: 0] com_OpB1;
wire            [31: 0] signExtended_output1;
wire            [31: 0] Shift_addResult1;
wire            [31: 0] Jump_address1;
wire            [31: 0] R2_output;
wire            [31: 0] readDataA1;
wire            [31: 0] readDataB1;
wire            [31: 0] Operand_A1;
wire            [31: 0] Operand_B1;
wire            [31: 0] nextInstruction_address;
wire            [31: 0] CIAp4;	
wire            [31: 0] CIA;	
wire            [31: 0] PCAp4;	
wire            [31: 0] PCA;	
wire            [31: 0] nia1;	
wire            [ 5: 0] ALU_control1;
wire            [ 5: 0] readRegisterA1;
wire            [ 5: 0] readRegisterA1_OUT;
wire            [ 5: 0] readRegisterB1;
wire            [ 5: 0] readRegisterB1_OUT;
wire            [ 5: 0] writeRegister1;
wire                    taken_branch1;
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
wire		[31: 0] Dest_Value1;
/* for bypass from output pipeline register */
wire 			do_writeback1_PR;
wire 		 [5: 0] writeRegister1_PR;

reg			single_fetch_PR;
reg [EXE_ENTRY_SIZE-1: 0] exe_entry_PR;
	
/*
 * combinational logic
 */
//assign fetchNull2_OUT = taken_branch1;
//assign insertBubble_OUT = syscal1 && (syscalBubbleCounter != 0);
//assign SYS_OUT = syscal1 && (syscalBubbleCounter == 0);
/* parse issue entry */
assign writeRegister1 	    = issue_entry[179:174];
assign readRegisterB1	    = issue_entry[173:168];
assign readRegisterA1	    = issue_entry[166:161]; 
assign link1 		    = issue_entry[139];
assign RegDst1		    = issue_entry[138];
assign jump1 		    = issue_entry[137];
assign ALUSrc1 		    = issue_entry[132];
assign jumpRegister_Flag1   = issue_entry[130];
assign sign_or_zero_Flag1   = issue_entry[129];
assign syscal1 		    = issue_entry[128];
assign CIA 		    = issue_entry[ 95: 64];
assign PCA 		    = issue_entry[ 63: 32];
assign Instr1 		    = issue_entry[ 31:  0];
//assign = issue_entry[];
/* parse exe entry */
assign writeRegister1_PR    = exe_entry_PR[179:174];
assign do_writeback1_PR	    = exe_entry_PR[140];

/* change physical register */
assign readRegisterA1_OUT   = (link1 || syscal1) ? 6'b000000 : readRegisterA1;
assign readRegisterB1_OUT   = (ALUSrc1 || link1 || syscal1) ? 6'b000000 : readRegisterB1;

assign CIAp4 			= CIA + 32'h00000004;
assign PCAp4 			= PCA + 32'h00000004;
assign Jump_address1		=(jumpRegister_Flag1)?{CIA[31:28],Instr1[25:0],2'b0}:com_OpA1;//readDataA1;
assign signExtended_output1 	= (sign_or_zero_Flag1)?{{16{Instr1[15]}},Instr1[15:0]}:{16'b0,Instr1[15:0]};
assign Shift_addResult1 	= PCA+(signExtended_output1<<2);	
assign nia1 			= (jump1)? Jump_address1: ((taken_branch1)? Shift_addResult1: PCA);
assign nextInstruction_address 	= nia1;
assign readDataA1 		= Reg[readRegisterA1];
assign readDataB1 		= Reg[readRegisterB1];
//assign Operand_B1 		= (ALUSrc1)?signExtended_output1:readDataB1;
assign R2_output 		= Reg[2];
assign Operand_A1     		= (link1) ? PCA : ((syscal1)?R2_input:readDataA1);
assign Operand_B1     		= (link1) ? 32'h00000004 : 
					((syscal1) ? 32'h00000000 : 
						((ALUSrc1) ? signExtended_output1 : readDataB1));
assign Dest_Value1		= Reg[writeRegister1];

/* for read/write queue */
//assign do_read_ISSQUEUE  = (!RESET || FREEZE || mispredict || flush_fCOM || empty_ISSQUEUE || full_EXEQUEUE) ? 1'b0 : 1'b1;
//assign do_read_ISSQUEUE  = (!RESET || FREEZE || mispredict || flush_fCOM || empty_ISSQUEUE) ? 1'b0 : 1'b1;
//assign do_write_EXEQUEUE = do_read_ISSQUEUE;
//assign exe_entry         = (!do_write_EXEQUEUE) ? 0 : {Dest_Value1, readDataB1, Operand_B1, Operand_A1, issue_entry[191:174], 
//							readRegisterB1_OUT, issue_entry[167], readRegisterA1_OUT, 
//							issue_entry[160:142], taken_branch1, issue_entry[140:96], 
//							nextInstruction_address, issue_entry[63:0]};


always begin 
	//Forwarded Operand A
	if (do_writeback1_PR && (readRegisterA1 == writeRegister1_PR))
		com_OpA1 = aluResult1_EXE;
	else if (do_writeback1_MEM && (readRegisterA1 == writeRegister1_MEM))
		com_OpA1 = Data1_MEM;
	else if (do_writeback1_RET && (readRegisterA1 == writeRegister1_RET))	
		com_OpA1 = Data1_RET;	
	else com_OpA1 = readDataA1;
	//Forwarded Operand B
	if (do_writeback1_PR && (readRegisterB1 == writeRegister1_PR)/* && (ALUSrc1!=1)/**/)
		com_OpB1 = aluResult1_EXE;
	else if (do_writeback1_MEM && (readRegisterB1 == writeRegister1_MEM)/* && (ALUSrc1!=1)/**/)
		com_OpB1 = Data1_MEM;
	else if (do_writeback1_RET && (readRegisterB1 == writeRegister1_RET)/* && (ALUSrc1!=1)/**/)
		com_OpB1 = Data1_RET;
	else com_OpB1 = Operand_B1;
end
	
compare compare1(jump1, com_OpA1, com_OpB1, Instr1, taken_branch1);

// PIPE REGISTERS 0
/*
always @ (posedge CLK or negedge RESET) begin
	if(!RESET) begin
		R2_output_PR <= 32'b0;
		nextInstruction_address_PR <= 32'b0;
                syscalBubbleCounter <= 2'b11; /// only allowed here
		single_fetch_PR <= 1'b0;
     	end
    	else if(!FREEZE) begin
			R2_output_PR <= (insertBubble_OUT)? 0: R2_output;
			nextInstruction_address_PR <= (insertBubble_OUT)? 0: nextInstruction_address;
                        syscalBubbleCounter <= (syscal1)? syscalBubbleCounter - 1: 2'b11;
			single_fetch_PR <= single_fetch_OUT;
	end
end
*/
//REGISTER FILE
/*
always @ (posedge CLK) begin
	if (do_writeback1_RET) 
		Reg[writeRegister1_RET] = writeData1_RET;
end
*/

//PIPE REGISTERS 1
always @ (posedge CLK or negedge RESET) begin
	//if(!RESET || insertBubble_OUT) begin
	//if(!RESET || mispredict || flush_fCOM || empty_ISSQUEUE || full_EXEQUEUE) begin
	if(!RESET || mispredict || flush_fCOM) begin
		/*
		Operand_A1_PR <= 32'b0;
			Operand_B1_PR <= 32'b0;
			writeRegister1_PR <= 5'b0;
			taken_branch1_PR <= 1'b0;
			MemRead1_PR <= 1'b0;
			MemtoReg1_PR <= 1'b0;
			MemWrite1_PR <= 1'b0;
			ALU_control1_PR <=6'b0;
			readRegisterA1_PR <= 5'b0;
			readRegisterB1_PR <= 5'b0;
			do_writeback1_PR <= 1'b0;
                        Instr1_10_6_PR <= 5'b0;
			readDataB1_PR <= 32'b0;
                        Dest_Value1_PR <= 32'b0;
			Instr1_PR <= 32'b0;
			ALUSrc1_PR <= 1'b0;
		*/
		exe_entry <= 320'b0;
		exe_entry_PR <= 320'b0;
	end
    	else if(!FREEZE) begin
			/*
			Operand_A1_PR <= (link1)?PCA:((syscal1)?R2_input:readDataA1);
			Operand_B1_PR <= (link1)?32'h00000004:((syscal1)?32'h00000000:Operand_B1);
			writeRegister1_PR <= writeRegister1;
			taken_branch1_PR <= taken_branch1;
			MemRead1_PR <= MemRead1;
			MemtoReg1_PR <= MemtoReg1;
			MemWrite1_PR <= MemWrite1;
			ALU_control1_PR <= ALU_control1;
			readRegisterA1_PR <= (link1 || syscal1)?5'b00000:readRegisterA1;
			readRegisterB1_PR <= (ALUSrc1 || link1 || syscal1)?5'b00000:readRegisterB1;
			do_writeback1_PR <= ((RegWrite1)&&(writeRegister1!=5'b00000)&&(ALU_control1!=6'b110100))||MemtoReg1;
                        Instr1_10_6_PR <= Instr1[10: 6];
			readDataB1_PR <= readDataB1;
                        Dest_Value1_PR <= Reg[writeRegister1];
			Instr1_PR <= Instr1;
			ALUSrc1_PR <= ALUSrc1;
			*/
		exe_entry <= {Dest_Value1, readDataB1, Operand_B1, Operand_A1, issue_entry[191:174], readRegisterB1_OUT, issue_entry[167], readRegisterA1_OUT, issue_entry[160:142], taken_branch1, issue_entry[140:96], nextInstruction_address, issue_entry[63:0]};
		exe_entry_PR <= {Dest_Value1, readDataB1, Operand_B1, Operand_A1, issue_entry[191:174], readRegisterB1_OUT, issue_entry[167], readRegisterA1_OUT, issue_entry[160:142], taken_branch1, issue_entry[140:96], nextInstruction_address, issue_entry[63:0]};
        end
end

always @ (posedge CLK or negedge RESET) begin
	if (debug) begin
		//$display("============================================================================================================================================CYCLE=");
		$display("[RR]:\tdo_writeback1_MEM=%d\twriteRegister1_MEM=%d\tData1_MEM=0x%x", 
				do_writeback1_MEM, writeRegister1_MEM, Data1_MEM);
		$display("[RR]:\tCIA=0x%x\treadRegA1=%d\treadRegB1=%d", CIA, readRegisterA1, readRegisterB1);
	end
end

endmodule
