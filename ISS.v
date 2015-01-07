/*
 * Issue Stage
 */

module ISS (
	CLK,
	RESET,
	FREEZE,
	/* output */
	issue_entry_OUT,
	do_write_ISSQUEUE,
	/* input */
	entry_IN,
	mispredict,
	flush_fCOM,
	debug
);

/*
 * parameters
 */
parameter ISSUE_ENTRY_SIZE = 192;


/*
 * output variables
 */
output reg [ISSUE_ENTRY_SIZE-1: 0] issue_entry_OUT;
//output				   do_read_QUEUE;
output			   	   do_write_ISSQUEUE;


/* 
 * input variables
 */
input 				   CLK;
input 				   RESET;
input 				   FREEZE;
input      [ISSUE_ENTRY_SIZE-1: 0] entry_IN;
/* for mispredict */
input				   mispredict;
input				   flush_fCOM;

//input				   empty_QUEUE;
//input				   full_ISSQUEUE;

input                   	   debug;

/* 
 * internal variables
 */
wire     [5: 0] write_phyReg1;
wire     [5: 0] read_phyReg_A1;
wire     [5: 0] read_phyReg_B1;
wire  		valid;
wire		ready;
wire		readyA1;
wire		readyB1;


assign write_phyReg1  	= entry_IN[179:174];
assign read_phyReg_B1 	= entry_IN[173:168];
assign read_phyReg_A1 	= entry_IN[166:161];
assign ready            = 1'b0;
assign readyA1		= 1'b0;
assign readyB1		= 1'b0;
assign valid		= 1'b1;

/* for read/write queue */
//assign do_read_QUEUE  = (!RESET || FREEZE || mispredict || flush_fCOM || empty_QUEUE || full_ISSQUEUE) ? 1'b0 : 1'b1;
assign do_write_ISSQUEUE = (!FREEZE && (entry_IN != 0));
assign issue_entry_OUT    = (!do_write_ISSQUEUE) ? 0 : {valid, 10'b0, ready, write_phyReg1, read_phyReg_B1, readyB1, 
							read_phyReg_A1, readyA1, entry_IN[159:0]};

always @ (posedge CLK or negedge RESET) begin
        //if (!RESET || mispredict || flush_fCOM || empty_ISSQUEUE1) begin
        if (!RESET || mispredict || flush_fCOM) begin
		//issue_entry_OUT <= 192'b0;	
	end
	else if (!FREEZE) begin
		//issue_entry_OUT <= {valid, 10'b0, ready, write_phyReg1, read_phyReg_B1, readyB1, read_phyReg_A1, readyA1, issue_entry_IN[159:0]};
	end
end

endmodule
