/*
 * Execute Stage
 */
module EXE(	
	CLK, 
	RESET,
	FREEZE,
	/* output */
	aluResult1_OUT,
	mem_entry,
	do_writeback1_PR,
	writeRegister1_PR,
	//do_read_EXEQUEUE,
	//do_write_MEMQUEUE,
	/* input */
	exe_entry,
	do_writeback1_MEM,
	writeRegister1_MEM,
	Data1_MEM,
	do_writeback1_RET,
	writeRegister1_RET,
	Data1_RET,
	mispredict,
	flush_fCOM,
	//empty_EXEQUEUE,
	//full_MEMQUEUE,
	debug	
);

/*
 * parameters
 */
parameter EXE_ENTRY_SIZE = 320;
parameter MEM_ENTRY_SIZE = 320;


/*
 * output
 */
/*   output reg     [31: 0] aluResult1_PR;
   output reg     [31: 0] Dst1_PR;
   
output reg     [31: 0] readDataB1_PR;
   output reg     [31: 0] Instr1_PR;
   output reg     [ 5: 0] ALU_control1_PR;
   output reg     [ 4: 0] writeRegister1_PR;
   output reg             MemtoReg1_PR;
   output reg             ALUSrc1_PR;
   output reg        	  MemRead1_PR;
   output reg        	  MemWrite1_PR;
   output reg        	  do_writeback1_PR;*/
output reg              [31: 0] aluResult1_OUT;  /* for bypass to RR */
output reg [MEM_ENTRY_SIZE-1:0] mem_entry;
/* for bypass back */
output reg			do_writeback1_PR;
output reg  		[ 5: 0] writeRegister1_PR;

//output reg			do_read_EXEQUEUE;
//output reg			do_write_MEMQUEUE;


/*
 * input
 */
/*   input          [31: 0] Operand_A1;
   input          [31: 0] Operand_B1;
   input          [31: 0] Dest_Value1;
   input          [31: 0] readDataB1;
   input          [31: 0] Instr1;
   input          [ 5: 0] ALU_control1;
   input          [ 4: 0] readRegisterA1;
   input          [ 4: 0] readRegisterB1;
   input          [ 4: 0] writeRegister1;
   input          [ 4: 0] Instr1_10_6;
   input                  ALUSrc1;
   input                  MemtoReg1;
   input                  MemRead1;
   input                  MemWrite1;
   input         	  do_writeback1_ID;*/
input		  	    FREEZE;
input                       CLK;
input        	  	    RESET;
input [EXE_ENTRY_SIZE-1: 0] exe_entry;
/* for bypass */
input         	            do_writeback1_MEM;
input          	    [ 5: 0] writeRegister1_MEM;
input               [31: 0] Data1_MEM;
input                       do_writeback1_RET;
input               [ 5: 0] writeRegister1_RET;
input          	    [31: 0] Data1_RET;
/* for mispredict */
input			    mispredict;
input			    flush_fCOM;

//input			    empty_EXEQUEUE;
//input			    full_MEMQUEUE;

input                       debug;

/*
 * internal
 */

/* for bypass from pipeline regs */
//wire 			do_writeback1_PR;
wire  		[ 5: 0] writeRegister1_PR;
wire 		[31: 0] aluResult1_PR;
 
wire            [31: 0] aluResult1;
wire            [31: 0] OpA1;
wire            [31: 0] OpB1;
wire            [31: 0] Dst1;
reg             [31: 0] HI;
reg             [31: 0] LO;

wire 		[ 5: 0] readRegisterA1;
wire 		[31: 0] Operand_A1;
wire 		[ 5: 0] readRegisterB1;
wire 		[31: 0] Operand_B1;
wire 		[ 5: 0] writeRegister1;
wire 		[31: 0] Dest_Value1;
wire 		[ 5: 0] ALU_control1;
wire 		[ 4: 0] Instr1_10_6;
wire		[31: 0] oldDataB1;
wire         	[31: 0] readDataB1;

reg [MEM_ENTRY_SIZE-1:0] mem_entry_PR;


/*
 * combinational logic
 */
/* parse exe entry */
assign Dest_Value1 	= exe_entry[319:288];
assign oldDataB1	= exe_entry[287:256];
assign Operand_B1 	= exe_entry[255:224];
assign Operand_A1 	= exe_entry[223:192];
assign writeRegister1	= exe_entry[179:174];
assign readRegisterB1 	= exe_entry[173:168];
assign readRegisterA1 	= exe_entry[166:161];
assign ALU_control1 	= exe_entry[121:116];
assign Instr1_10_6 	= exe_entry[115:111];
/* parse mem entry */
assign aluResult1_PR 	 = mem_entry_PR[223:192];
assign writeRegister1_PR = mem_entry_PR[179:174];
assign do_writeback1_PR  = mem_entry_PR[140];

assign readDataB1 	 = ((do_writeback1_MEM)&&(writeRegister1_MEM==writeRegister1)) ? Data1_MEM : 
				(((do_writeback1_RET)&&(writeRegister1_RET==writeRegister1)) ? Data1_RET : oldDataB1);

/* for read/write queue */
//assign do_read_EXEQUEUE  = (!RESET || FREEZE || mispredict || flush_fCOM || empty_EXEQUEUE || full_MEMQUEUE) ? 1'b0: 1'b1;
//assign do_read_EXEQUEUE  = (!RESET || FREEZE || mispredict || flush_fCOM || empty_EXEQUEUE) ? 1'b0: 1'b1;
//assign do_write_MEMQUEUE = do_read_EXEQUEUE;
//assign mem_entry	 = (!do_write_MEMQUEUE) ? 0 : {Dst1, readDataB1, OpB1, aluResult1, exe_entry[191:0]};
//

// Forwarding for Slot 1
always begin
	// Operand A
	if(do_writeback1_PR && (writeRegister1_PR == readRegisterA1))
       		OpA1 = aluResult1_PR;
	else if(do_writeback1_MEM && (writeRegister1_MEM == readRegisterA1))
		OpA1 = Data1_MEM;
	else if(do_writeback1_RET && (writeRegister1_RET == readRegisterA1))
		OpA1 = Data1_RET;
	else OpA1 = Operand_A1;
	// Operand B
	if(do_writeback1_PR && (writeRegister1_PR == readRegisterB1)/* && (ALUSrc1!=1)/**/)
		OpB1 = aluResult1_PR;
	else if(do_writeback1_MEM && (writeRegister1_MEM == readRegisterB1)/* && (ALUSrc1!=1)/**/)
		OpB1 = Data1_MEM;
	else if(do_writeback1_RET && (writeRegister1_RET == readRegisterB1)/* && (ALUSrc1!=1)/**/)
		OpB1 = Data1_RET;
	else OpB1 = Operand_B1;
	
	// Destination
	if(do_writeback1_PR && (writeRegister1_PR == writeRegister1))
		Dst1 = aluResult1_PR;
	else if(do_writeback1_MEM && (writeRegister1_MEM == writeRegister1))
		Dst1 = Data1_MEM;
	else if(do_writeback1_RET && (writeRegister1_RET == writeRegister1))
		Dst1 = Data1_RET;
	else Dst1 = Dest_Value1;
end

assign aluResult1_OUT = aluResult1;

ALU ALU1(HI, LO, aluResult1, OpA1, OpB1, ALU_control1, Instr1_10_6, CLK);

//Pipeline Stage 1
always @ (posedge CLK or negedge RESET) begin
	//if(!RESET || mispredict || flush_fCOM || empty_EXEQUEUE) begin
	if(!RESET || mispredict || flush_fCOM) begin
		/*
			MemtoReg1_PR <= 1'b0;
			MemRead1_PR <= 1'b0;
			MemWrite1_PR <= 1'b0;
			aluResult1_PR <= 32'b0;
			writeRegister1_PR <= 5'b0;
			do_writeback1_PR <= 1'b0;
			ALU_control1_PR <= 6'b0;
			readDataB1_PR <= 32'b0;
			Dst1_PR <= 32'b0;
			Instr1_PR <= 32'b0;
			ALUSrc1_PR <= 1'b0;
		*/
		mem_entry <= 320'b0;
		mem_entry_PR <= 320'b0;
	end
	else if(!FREEZE) begin
		/*
		     	MemtoReg1_PR <= MemtoReg1;
		     	readDataB1_PR <= ((do_writeback1_MEM)&&(writeRegister1_MEM==writeRegister1))?Data1_MEM:(((do_writeback1_WB)&&(writeRegister1_WB==writeRegister1))?Data1_WB:readDataB1);
        	     	aluResult1_PR <= aluResult1;
		     	MemRead1_PR <= MemRead1;
		     	MemWrite1_PR <= MemWrite1;
		     	writeRegister1_PR <= writeRegister1;
		     	do_writeback1_PR <= do_writeback1_ID;
        	     	ALU_control1_PR <= ALU_control1;
		     	Dst1_PR <= Dst1;
		     	Instr1_PR <= Instr1;
		     	ALUSrc1_PR <= ALUSrc1;
		*/
		mem_entry <= {Dst1, readDataB1, OpB1, aluResult1, exe_entry[191:0]};
		mem_entry_PR <= {Dst1, readDataB1, OpB1, aluResult1, exe_entry[191:0]};
	end
end

always @ (posedge CLK or negedge RESET) begin
	if (debug) begin
		//$display("[EXE]:\tdo_writeback_MEM=%d\twriteReg_MEM=%d\tData1_MEM=0x%x", do_writeback1_MEM, writeRegister1_MEM, Data1_MEM);
	end
end
 
endmodule
