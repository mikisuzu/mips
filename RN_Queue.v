/*
 * RN_Queue
 */
module RN_Queue (
	CLK,
	RESET,
	FREEZE,
	/* output */
	empty_FIFO,
	full_FIFO,
	data_out,
	//tail,
	//head,
	//reg_counter,
	/* input */
	do_write,
	do_read,
	data_in,
	mispredict,
	flush_fCOM,
	debug
);

/*
 * parameters
 */
parameter POINTER_SIZE    =   3;
parameter FIFO_SIZE 	  =   8;			/* 1<<3 */
parameter FIFO_ENTRY_SIZE = 160;


/* 
 * output
 */
output reg			 empty_FIFO;
output reg			 full_FIFO;
output reg [FIFO_ENTRY_SIZE-1:0] data_out;
//output reg   [POINTER_SIZE-1: 0] head;
//output reg   [POINTER_SIZE-1: 0] tail;
//output reg		[POINTER_SIZE-1: 0] reg_counter;


/*
 * input
 */
input				CLK;
input				RESET;
input				FREEZE;
input				debug;
input				do_write;
input				do_read;
input				mispredict;
input				flush_fCOM;
input 	  [FIFO_ENTRY_SIZE-1:0] data_in; 


/*
 * internal 
 */
wire [POINTER_SIZE-1:0] i;
//wire			  do_writeback1_in;
//wire			  do_writeback1_out;

reg 	[POINTER_SIZE: 0] counter;
reg [FIFO_ENTRY_SIZE-1:0] FIFO [0:FIFO_SIZE-1];
reg   [POINTER_SIZE-1: 0] head;
reg   [POINTER_SIZE-1: 0] tail;


//assign do_writeback1_in   = data_in[11];
//assign do_writeback1_out  = data_out[11];
assign empty_FIFO	  = (counter == 0);
assign full_FIFO  	  = (counter == FIFO_SIZE);
assign data_out    	  = FIFO[head];


always @ (posedge CLK or negedge RESET) begin
        if (!RESET || mispredict || flush_fCOM) begin
		head 		<= 0;	
		tail 		<= 0;	
		counter 	<= 0;
		//reg_counter	<= 0;
		for (i = 0; i < ((1<<POINTER_SIZE)-1); i = i + 1) begin
			FIFO[i] <= 0;
		end
		FIFO[FIFO_SIZE-1] <= 0;
		/*
		FIFO[63]<= 64'b0; FIFO[62]<= 64'b0; FIFO[61]<= 64'b0; FIFO[60]<= 64'b0; 
		FIFO[59]<= 64'b0; FIFO[58]<= 64'b0; FIFO[57]<= 64'b0; FIFO[56]<= 64'b0;
                FIFO[55]<= 64'b0; FIFO[54]<= 64'b0; FIFO[53]<= 64'b0; FIFO[52]<= 64'b0; 
		FIFO[51]<= 64'b0; FIFO[50]<= 64'b0; FIFO[49]<= 64'b0; FIFO[48]<= 64'b0;
                FIFO[47]<= 64'b0; FIFO[46]<= 64'b0; FIFO[45]<= 64'b0; FIFO[44]<= 64'b0; 
		FIFO[43]<= 64'b0; FIFO[42]<= 64'b0; FIFO[41]<= 64'b0; FIFO[40]<= 64'b0;
                FIFO[39]<= 64'b0; FIFO[38]<= 64'b0; FIFO[37]<= 64'b0; FIFO[36]<= 64'b0; 
		FIFO[35]<= 64'b0; FIFO[34]<= 64'b0; FIFO[33]<= 64'b0; FIFO[32]<= 64'b0;
		FIFO[31]<= 64'b0; FIFO[30]<= 64'b0; FIFO[29]<= 64'b0; FIFO[28]<= 64'b0; 
		FIFO[27]<= 64'b0; FIFO[26]<= 64'b0; FIFO[25]<= 64'b0; FIFO[24]<= 64'b0;
                FIFO[23]<= 64'b0; FIFO[22]<= 64'b0; FIFO[21]<= 64'b0; FIFO[20]<= 64'b0; 
		FIFO[19]<= 64'b0; FIFO[18]<= 64'b0; FIFO[17]<= 64'b0; FIFO[16]<= 64'b0;
                FIFO[15]<= 64'b0; FIFO[14]<= 64'b0; FIFO[13]<= 64'b0; FIFO[12]<= 64'b0; 
		FIFO[11]<= 64'b0; FIFO[10]<= 64'b0; FIFO[ 9]<= 64'b0; FIFO[ 8]<= 64'b0;
                FIFO[ 7]<= 64'b0; FIFO[ 6]<= 64'b0; FIFO[ 5]<= 64'b0; FIFO[ 4]<= 64'b0; 
		FIFO[ 3]<= 64'b0; FIFO[ 2]<= 64'b0; FIFO[ 1]<= 64'b0; FIFO[ 0]<= 64'b0;		
		*/
	end
	else if (!FREEZE) begin
		if (do_write && !full_FIFO) begin
			FIFO[tail] <= data_in;
			tail 	   <= tail + 1;
		end

		if (do_read && !empty_FIFO) begin
			head	  <= head + 1;
		end

		/* update list counter */
		if ((do_write && !full_FIFO) && (!do_read || empty_FIFO))
			counter   <= counter + 1;
		else if ((do_read && ! empty_FIFO) && (!do_write || full_FIFO))
			counter   <= counter - 1;

		/* update reg counter */
		/*
		if ((do_write && !full_FIFO && do_writeback1_in) && (!do_read || empty_FIFO || !do_writeback1_out))
			reg_counter <= reg_counter + 1;
		else if ((do_read && ! empty_FIFO && do_writeback1_out) && (!do_write || full_FIFO || !do_writeback1_in))
			reg_counter <= reg_counter - 1;
		*/
	end
end
always @ (posedge CLK or negedge RESET) begin
	if (debug) begin
 		$display("[RNQ]:\thead=%d\ttail=%d\tcounter=%d", head, tail, counter);
	end
end

endmodule
