/*
 * retire stage
 */

module RET (	
	CLK,
	RESET,
	FREEZE,
	/* output */
	writeData1_OUT,
	aluResult1_OUT,
	writeData1_PR,
	writeRegister1_PR,
	writeRegister1_OUT,
	do_writeback1_OUT,
	do_writeback1_PR,
	com_entry,
	//do_read_RETQUEUE,
	//do_write_COMQUEUE,
	/* input */
	retire_entry,
	mispredict,
	flush_fCOM,
	//empty_RETQUEUE,
	//full_COMQUEUE,
	debug
);

/*
 * parameters
 */
parameter RET_ENTRY_SIZE = 256;
parameter COM_ENTRY_SIZE = 192;


/* 
 * output 
 */
output reg      	[31: 0] writeData1_OUT;
output reg      	[31: 0] aluResult1_OUT;
output reg      	[31: 0] writeData1_PR;
output reg      	[ 5: 0] writeRegister1_PR;
output reg      	[ 5: 0] writeRegister1_OUT;
output reg              	do_writeback1_OUT;
output reg              	do_writeback1_PR;
output reg [COM_ENTRY_SIZE-1:0] com_entry;

//output reg			do_read_RETQUEUE;
//output reg			do_write_COMQUEUE;


/* 
 * input
 */
   /*input           [31: 0] aluResult1;
   input           [31: 0] Data_input1;
   input           [ 4: 0] writeRegister1;
   input   	           MemtoReg1;
   input            	   do_writeback1;*/
input  	           	    	CLK;
input   	            	RESET;
input		   	    	FREEZE;
input     [RET_ENTRY_SIZE-1: 0] retire_entry;
/* for mispredict */
input				mispredict;
input				flush_fCOM;

//input				empty_RETQUEUE;
//input				full_COMQUEUE;

input                   	debug;


/* 
 * interneal
 */
wire		do_writeback1;     
wire	[ 5: 0] writeRegister1;
wire	[31: 0] Data_input1;
wire	[31: 0] aluResult1;
wire   		MemtoReg1;


/* 
 * parse retire entry
 */
assign Data_input1 	= retire_entry[255:224];
assign aluResult1	= retire_entry[223:192];
assign writeRegister1 	= retire_entry[179:174];
assign do_writeback1 	= retire_entry[140];
assign MemtoReg1	= retire_entry[134];

assign writeRegister1_OUT = writeRegister1; 
assign do_writeback1_OUT  = do_writeback1;
assign aluResult1_OUT 	  = aluResult1;
assign writeData1_OUT     = (MemtoReg1) ? Data_input1 : aluResult1;
//assign writeData1_OUT     = Data_input1;

/* for read/write queue */
//assign do_read_RETQUEUE  = (!RESET || FREEZE || mispredict || empty_RETQUEUE || full_COMQUEUE) ? 1'b0 : 1'b1;
//assign do_read_RETQUEUE  = (!RESET || FREEZE || mispredict || flush_fCOM || empty_RETQUEUE) ? 1'b0 : 1'b1;
//assign do_write_COMQUEUE = do_read_RETQUEUE;
//assign com_entry	 = (!do_write_COMQUEUE) ? 0 : retire_entry[191: 0];



//Pipe Register 1
always @ (posedge CLK or negedge RESET) begin
	//if(!RESET || mispredict || empty_RETQUEUE || full_COMQUEUE) begin
	if(!RESET || mispredict) begin
             	writeData1_PR 		<= 32'b0;
	     	writeRegister1_PR 	<= 6'b0;
             	do_writeback1_PR 	<= 1'b0;
		com_entry		<= 192'b0;
       	end
       	else if(!FREEZE)
	begin
             	writeData1_PR 		<= writeData1_OUT;
	     	writeRegister1_PR 	<= writeRegister1;
             	do_writeback1_PR 	<= do_writeback1;
		com_entry		<= retire_entry[191: 0];
       	end
end

always @ (posedge CLK or negedge RESET) begin
	if (debug) begin
		$display("[RET]:\taddr=0x%x\tinst=0x%x\twriteReg=%d\tdata=%x", (retire_entry[63:32]==0 ? 0 : retire_entry[63:32]-4), 
			retire_entry[31:0], writeRegister1_OUT, writeData1_OUT);
	end
end
endmodule
