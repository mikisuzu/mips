/*
 * Instruction Fetch Stage
 */

module IF(	
	CLK, 
	RESET, 
	FREEZE,
	/* output */
	Instr_address_2IM,
	decode_entry,
	Instr1_PR,
	Instr2_PR,
	do_write_IDQUEUE,
	/* input */
	nextInstruction_address,
	mispredict,
	PC_init,
	Instr1_fIM,
	//single_fetch,
	no_new_fetch,
	//fetchNull2,
	flush_fCOM,
	do_delay_syscall,
	jump_inst,
	full_IDQUEUE,
	debug
);

/*
 * parameters
 */
parameter		 DECODE_ENTRY_SIZE = 96;



/*
 * output
 */
output reg     [31: 0] Instr1_PR;
output reg     [31: 0] Instr2_PR;
//output reg     [31: 0] PCA_PR;
//output reg     [31: 0] CIA_PR;
output reg                  [31: 0] Instr_address_2IM;
output reg [DECODE_ENTRY_SIZE-1: 0] decode_entry;
/* to DECODER QUEUE */
output reg			    do_write_IDQUEUE;

/*
 * input
 */
input                  	CLK;
input                  	RESET;
input			FREEZE;
/* for branch */
input           [31: 0] nextInstruction_address;
input 			mispredict;
input 			flush_fCOM;
//input                  	taken_branch1;

input           [31: 0] PC_init;
input           [31: 0] Instr1_fIM;
//input                  	single_fetch;
input                  	no_new_fetch;		/* from ID, for syscall bubble */
//input			fetchNull2;		/* from ID, for branch slot, this signal will be issued from COM */
input			do_delay_syscall;
input			jump_inst;
input			full_IDQUEUE;
input			debug;


/* 
 * internal 
 */
wire           [31: 0] Instr1;
wire           [31: 0] Instr2;
wire           [31: 0] PCA;
wire           [31: 0] CIA;
wire		       debug;
//wire [DECODE_ENTRY_SIZE-1: 0] entry_out;

reg            [31: 0] PC;
reg            [31: 0] FPC;
//reg    	       [31: 0] Instr2_PR;


/* 
 * combinational logic
 */
//assign Instr_address_2IM   = (taken_branch1)? nextInstruction_address: PC; /* if syscall bubble, nextInstruction_address is 0 */
assign Instr_address_2IM   = PC; /* if syscall bubble, nextInstruction_address is 0 */
assign PCA                 = PC; 
assign CIA                 = FPC; 
assign Instr1              = Instr2_PR;
//assign Instr2              = (fetchNull2)? 32'h00000000:Instr1_fIM;
assign Instr2              = Instr1_fIM;

//assign do_write_IDQUEUE   = (!RESET || flush_fCOM || FREEZE || mispredict || no_new_fetch || full_IDQUEUE || do_delay_syscall) ? 1'b0 : 1'b1;
assign do_write_IDQUEUE   = (!RESET || flush_fCOM || FREEZE || mispredict || no_new_fetch || full_IDQUEUE || do_delay_syscall) ? 1'b0 : 1'b1;
assign decode_entry	   = (do_write_IDQUEUE) ? {CIA, PCA, Instr1} : 0;

/*
 * sequential logic
 */
always @ (posedge CLK or negedge RESET) begin
	if (mispredict) begin
        	Instr1_PR            <= 32'b0;
        	Instr2_PR            <= 32'b0;
		//decode_entry	     <= 96'b0;
		FPC                  <= nextInstruction_address - 32'h4;
		PC                   <= nextInstruction_address;
	end
	else if (!RESET || flush_fCOM) begin
        	Instr1_PR            <= 32'b0;
        	Instr2_PR            <= 32'b0;
		//PCA_PR               <= 32'b0;
		//CIA_PR               <= 32'b0;
		//decode_entry	     <= 96'b0;
		FPC                  <= 32'b0;
		PC                   <= PC_init;
  	end
	/*
	else if (mispredict) begin
        	Instr1_PR            <= 32'b0;
        	Instr2_PR            <= 32'b0;
		//decode_entry	     <= 96'b0;
		FPC                  <= nextInstruction_address - 32'h4;
		PC                   <= nextInstruction_address;
	end*/
   	//else if(!no_new_fetch && !FREEZE && !full_IDQUEUE) begin
   	else if(!no_new_fetch && !FREEZE && do_write_IDQUEUE) begin
        	Instr1_PR            <= Instr1;
        	Instr2_PR            <= Instr2;
		//PCA_PR               <= PCA;
		//CIA_PR               <= CIA;
		//decode_entry	     <= {CIA, PCA, Instr1};
		//FPC          	       <= Instr_address_2IM;
		FPC                  <= do_delay_syscall ? FPC : Instr_address_2IM;
		//PC                   <= Instr_address_2IM + 32'h00000004;        
		PC                   <= do_delay_syscall ? Instr_address_2IM : Instr_address_2IM + 32'h00000004;        
      	end
end

always @ (posedge CLK or negedge RESET) begin
	//if (full_IDQUEUE)
	//	$display("[IF]: full IDQUEUE");
	//if (FREEZE)
	//	$display("[IF]:\tFreeze!");
	//$display("[IF]:\t0x%x: %x", Instr_address_2IM, Instr2);
	if (debug) begin
		//$display("===================0x%x: %x=============================", Instr_address_2IM, Instr2);
		$display("[IF]:\t0x%x: %x", Instr_address_2IM, Instr2);
		//$display("[IF]:\tdo_delay_syscall=%d", do_delay_syscall);
		//$display("[IF]:\tflush_fCOM=%d\tmispredict=%d\tbran_addr=%x\tFREEZE=%d", 
		//	flush_fCOM, mispredict, nextInstruction_address, FREEZE);
	end
end

endmodule
