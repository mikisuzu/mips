/*
 * Load/Store Queue
 */
module LSQ (
	CLK,
	RESET,
	FREEZE,
	/* output */
	empty_FIFO,
	full_FIFO,
	data_out,
	do_issue,
	/* input */
	DMISS,
	BB,
	ROB_head,
	do_write,
	data_in,
	mispredict,
	flush_fCOM,
	debug
);

/*
 * parameters
 */
parameter POINTER_SIZE    =   4;
parameter FIFO_SIZE 	  =  16;			/* 1<<3 */
parameter FIFO_ENTRY_SIZE = 192;
parameter BB_SIZE	  =  64;


/* 
 * output
 */
output reg			 empty_FIFO;
output reg			 full_FIFO;
output reg [FIFO_ENTRY_SIZE-1:0] data_out;
output reg			 do_issue;
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
//input				do_read;
input				mispredict;
input				flush_fCOM;
input 	  [FIFO_ENTRY_SIZE-1:0] data_in; 
input		[BB_SIZE-1 : 0] BB;
input			[ 5: 0] ROB_head;
input				DMISS;


/*
 * internal 
 */
wire   	     [POINTER_SIZE-1:0] i;
wire 	  [FIFO_ENTRY_SIZE-1:0] head_entry;
wire			[ 5: 0] ROB_num;
wire				MemWrite1;
wire				MemRead1;
wire				valid;
//wire			  do_writeback1_in;
//wire			  do_writeback1_out;


reg 	[POINTER_SIZE: 0] counter;
reg [FIFO_ENTRY_SIZE-1:0] FIFO [0:FIFO_SIZE-1];
reg   [POINTER_SIZE-1: 0] head;
reg   [POINTER_SIZE-1: 0] tail;
reg               [ 2: 0] READY [FIFO_SIZE-1:0];

/*
 * combinational logic 
 */
/* parse head entry */
assign head_entry	= FIFO[head];
assign valid		= head_entry[191];
assign ROB_num   	= head_entry[159:154];
assign MemRead1  	= head_entry[135];
assign MemWrite1 	= head_entry[133];

/* wakeup */
always begin
        for (i = 0; i < 15; i = i + 1) begin
                READY[i][0] = BB[FIFO[i][166:161]] && FIFO[i][191];
                READY[i][1] = BB[FIFO[i][173:168]] && FIFO[i][191];
                READY[i][2] = READY[i][0] && READY[i][1];
        end
        READY[FIFO_SIZE-1][0] = BB[FIFO[FIFO_SIZE-1][166:161]] && FIFO[FIFO_SIZE-1][191];
        READY[FIFO_SIZE-1][1] = BB[FIFO[FIFO_SIZE-1][173:168]] && FIFO[FIFO_SIZE-1][191];
        READY[FIFO_SIZE-1][2] = READY[FIFO_SIZE-1][0] && READY[FIFO_SIZE-1][1];
end

assign do_issue = !DMISS && valid && READY[head][2] && (ROB_head == ROB_num);
//assign do_issue = !DMISS && valid && READY[head][2] && 
//			(MemRead1 ? 1'b1 : (ROB_head == ROB_num));	
									/*
									 * requirments for issuing:
									 * 	- head of FIFO
									 * 	- ready
									 * 	- if write to memoty, become the head of ROB
									 */
assign empty_FIFO	  = (counter == 0);
assign full_FIFO  	  = (counter == FIFO_SIZE);
assign data_out    	  = do_issue ? FIFO[head] : 0;


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
	end
	else if (!FREEZE) begin
		if (do_write && !full_FIFO) begin
			FIFO[tail] <= data_in;
			tail 	   <= tail + 1;
		end

		if (do_issue && !empty_FIFO) begin
			head	  <= head + 1;
		end

		/* update list counter */
		if ((do_write && !full_FIFO) && (!do_issue || empty_FIFO))
			counter   <= counter + 1;
		else if ((do_issue && ! empty_FIFO) && (!do_write || full_FIFO))
			counter   <= counter - 1;
	end
end
always @ (posedge CLK or negedge RESET) begin
	if (debug) begin
                $display("[LSQ]: Load/Store Queue");
                $display("\t+-+-+-+---15---+-+-+-+---14---+-+-+-+---13---+-+-+-+---12---+-+-+-+---11---+-+-+-+---10---+-+-+-+---09---+-+-+-+---08---+");
                $display("\t|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|  H=%d, T=%d",
                        READY[15][2], READY[15][1], READY[15][0], FIFO[15][95:64], READY[14][2], READY[14][1], READY[14][0], FIFO[14][95:64],
                        READY[13][2], READY[13][1], READY[13][0], FIFO[13][95:64], READY[12][2], READY[12][1], READY[12][0], FIFO[12][95:64],
                        READY[11][2], READY[11][1], READY[11][0], FIFO[11][95:64], READY[10][2], READY[10][1], READY[10][0], FIFO[10][95:64],
                        READY[ 9][2], READY[ 9][1], READY[ 9][0], FIFO[ 9][95:64], READY[ 8][2], READY[ 8][1], READY[ 8][0], FIFO[ 8][95:64],
			head, tail
                );

                $display("\t+-+-+-+---07---+-+-+-+---06---+-+-+-+---05---+-+-+-+---04---+-+-+-+---03---+-+-+-+---02---+-+-+-+---01---+-+-+-+---00---+");
                $display("\t|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|  counter=%d",
                        READY[ 7][2], READY[ 7][1], READY[ 7][0], FIFO[ 7][95:64], READY[ 6][2], READY[ 6][1], READY[ 6][0], FIFO[ 6][95:64],
                        READY[ 5][2], READY[ 5][1], READY[ 5][0], FIFO[ 5][95:64], READY[ 4][2], READY[ 4][1], READY[ 4][0], FIFO[ 4][95:64],
                        READY[ 3][2], READY[ 3][1], READY[ 3][0], FIFO[ 3][95:64], READY[ 2][2], READY[ 2][1], READY[ 2][0], FIFO[ 2][95:64],
                        READY[ 1][2], READY[ 1][1], READY[ 1][0], FIFO[ 1][95:64], READY[ 0][2], READY[ 0][1], READY[ 0][0], FIFO[ 0][95:64],
			counter
                );
                $display("\t+-+-+-+--------+-+-+-+--------+-+-+-+--------+-+-+-+--------+-+-+-+--------+-+-+-+--------+-+-+-+--------+-+-+-+--------+");
		$display("[LSQ]:\treadRegB=%d", FIFO[4][173:168]);

	end
end

endmodule
