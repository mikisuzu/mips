/*
 * reorder buffer
 */
module ROB (
	CLK,
	RESET,
	FREEZE,
	/* output */
	empty_queue,
	full_queue,
	data_out,
	tail,
	head,
	reg_counter,
	/* input */
	do_write,
	do_read,
	data_in,
	mispredict,
	flush_fCOM,
       	do_remend_ROB,
	remend_data,
	remend_index,
       	do_remend_ROB_LS,
	remend_data_LS,
	remend_index_LS,
	debug
);

/*
 * parameters
 */
parameter ROB_SIZE 	 = 64;
parameter ROB_ENTRY_SIZE = 192;


/* 
 * output
 */
output reg			empty_queue;
output reg			full_queue;
output reg [ROB_ENTRY_SIZE-1:0] data_out;
output reg 		[ 5: 0] head;
output reg 		[ 5: 0] tail;
output reg		[ 5: 0] reg_counter;


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
input 	   [ROB_ENTRY_SIZE-1:0] data_in;
input                      	do_remend_ROB;
input              	[64: 0] remend_data;
input              	[ 5: 0] remend_index;
input                      	do_remend_ROB_LS;
input              	[64: 0] remend_data_LS;
input              	[ 5: 0] remend_index_LS;

/*
 * internal 
 */
wire			  do_writeback1_in;
wire			  do_writeback1_out;

reg 		  [ 6: 0] counter;
reg [ROB_ENTRY_SIZE-1: 0] ROB [0:ROB_SIZE-1];


assign do_writeback1_in = do_write ? data_in[140] : 0;
assign do_writeback1_out= do_read ? data_out[140] : 0;
assign empty_queue 	= (counter == 0);
assign full_queue  	= (counter == ROB_SIZE);
assign data_out    	= ROB[head];


always @ (posedge CLK or negedge RESET) begin
        if (!RESET || mispredict) begin
		head 		<= 6'b0;	
		tail 		<= 6'b0;	
		counter 	<= 7'b0;
		reg_counter	<= 6'b0;
		ROB[63]<= 0; ROB[62]<= 0; ROB[61]<= 0; ROB[60]<= 0; 
		ROB[59]<= 0; ROB[58]<= 0; ROB[57]<= 0; ROB[56]<= 0;
                ROB[55]<= 0; ROB[54]<= 0; ROB[53]<= 0; ROB[52]<= 0; 
		ROB[51]<= 0; ROB[50]<= 0; ROB[49]<= 0; ROB[48]<= 0;
                ROB[47]<= 0; ROB[46]<= 0; ROB[45]<= 0; ROB[44]<= 0; 
		ROB[43]<= 0; ROB[42]<= 0; ROB[41]<= 0; ROB[40]<= 0;
                ROB[39]<= 0; ROB[38]<= 0; ROB[37]<= 0; ROB[36]<= 0; 
		ROB[35]<= 0; ROB[34]<= 0; ROB[33]<= 0; ROB[32]<= 0;
		ROB[31]<= 0; ROB[30]<= 0; ROB[29]<= 0; ROB[28]<= 0; 
		ROB[27]<= 0; ROB[26]<= 0; ROB[25]<= 0; ROB[24]<= 0;
                ROB[23]<= 0; ROB[22]<= 0; ROB[21]<= 0; ROB[20]<= 0; 
		ROB[19]<= 0; ROB[18]<= 0; ROB[17]<= 0; ROB[16]<= 0;
                ROB[15]<= 0; ROB[14]<= 0; ROB[13]<= 0; ROB[12]<= 0; 
		ROB[11]<= 0; ROB[10]<= 0; ROB[ 9]<= 0; ROB[ 8]<= 0;
                ROB[ 7]<= 0; ROB[ 6]<= 0; ROB[ 5]<= 0; ROB[ 4]<= 0; 
		ROB[ 3]<= 0; ROB[ 2]<= 0; ROB[ 1]<= 0; ROB[ 0]<= 0;		
	end
	else if (!FREEZE) begin
		if (do_write && !full_queue) begin
			ROB[tail] <= data_in;
			tail 	  <= tail + 1;
		end

		if (do_remend_ROB) begin
			ROB[remend_index] <= {remend_data[63:32], 
						ROB[remend_index][159:154], 1'b1, ROB[remend_index][152:142], 
							remend_data[64], ROB[remend_index][140:128], 
						ROB[remend_index][127:96], remend_data[31:0], 
						ROB[remend_index][63:0]};
		end

		if (do_remend_ROB_LS) begin
			ROB[remend_index_LS] <= {remend_data_LS[63:32], 
						ROB[remend_index_LS][159:154], 1'b1, ROB[remend_index_LS][152:142], 
							remend_data_LS[64], ROB[remend_index_LS][140:128], 
						ROB[remend_index_LS][127:96], remend_data_LS[31:0], 
						ROB[remend_index_LS][63:0]};
		end

		if (do_read && !empty_queue) begin
			head	  <= head + 1;
		end

		/* update list counter */
		if ((do_write && !full_queue) && (!do_read || empty_queue))
			counter   <= counter + 1;
		else if ((do_read && ! empty_queue) && (!do_write || full_queue))
			counter   <= counter - 1;

		/* update reg counter */
		if ((do_write && !full_queue && do_writeback1_in) && (!do_read || empty_queue || !do_writeback1_out))
			reg_counter <= reg_counter + 1;
		else if ((do_read && ! empty_queue && do_writeback1_out) && (!do_write || full_queue || !do_writeback1_in))
			reg_counter <= reg_counter - 1;

	end
end
always @ (posedge CLK or negedge RESET) begin
	if (debug) begin
		//$display("=============================================================");
		//$display("[ROB]:\ttail=%x, head=%x, counter=%x", tail, head, counter);
		/* display FREE LIST */
                $display("[ROB]: ROB");
                $display("\t 63 62 61 60 59 58 57 56 55 54 53 52 51 50 49 48 47 46 45 44 43 42 41 40 39 38 37 36 35 34 33 32 ");
                $display("\t+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+");
                $display("\t|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|\thead =%3d\ttail =%3d",
                        ROB[63][11], ROB[62][11], ROB[61][11], ROB[60][11], ROB[59][11], ROB[58][11], ROB[57][11], ROB[56][11],
                        ROB[55][11], ROB[54][11], ROB[53][11], ROB[52][11], ROB[51][11], ROB[50][11], ROB[49][11], ROB[48][11],
                        ROB[47][11], ROB[46][11], ROB[45][11], ROB[44][11], ROB[43][11], ROB[42][11], ROB[41][11], ROB[40][11],
                        ROB[39][11], ROB[38][11], ROB[37][11], ROB[36][11], ROB[35][11], ROB[34][11], ROB[33][11], ROB[32][11],
                        head, tail
                );
                $display("\t+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+");
                $display("\t 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0");
                $display("\t+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+");
                $display("\t|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|\tcounter =%4d\treg_counter =%3d",
                        ROB[31][11], ROB[30][11], ROB[29][11], ROB[28][11], ROB[27][11], ROB[26][11], ROB[25][11], ROB[24][11],
                        ROB[23][11], ROB[22][11], ROB[21][11], ROB[20][11], ROB[19][11], ROB[18][11], ROB[17][11], ROB[16][11],
                        ROB[15][11], ROB[14][11], ROB[13][11], ROB[12][11], ROB[11][11], ROB[10][11], ROB[ 9][11], ROB[ 8][11],
                        ROB[ 7][11], ROB[ 6][11], ROB[ 5][11], ROB[ 4][11], ROB[ 3][11], ROB[ 2][11], ROB[ 1][11], ROB[ 0][11],
                        counter, reg_counter
                );
                $display("\t+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+");
	end
end

endmodule
