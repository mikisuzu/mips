/* 
 * issue queue
 */

module ISSUE_QUEUE (
	CLK,
	RESET,
	FREEZE,
	/* output */
	BB,
	do_issue_out,
	out_entry,
	full,
	empty,
	/* input */
	do_write,
	write_data,
	mispredict,
	flush_fCOM,
	do_writeback1_WB,
	writeReg1_phy_WB,
	do_writeback1_WB_LS,
	writeReg1_phy_WB_LS,
        do_clear_2BB,
        clear_index_2BB,
	debug
);

/* 
 * parameters 
 */
parameter ISSUEE_QUEUE_SIZE =  16;
parameter ISSUEE_ENTRY_SIZE = 192;
parameter BB_SIZE	    =  64;

/* 
 * output
 */
output reg 				do_issue_out;
output reg     [ISSUEE_ENTRY_SIZE-1: 0] out_entry;
output reg				full;
output reg				empty;
output reg		 [BB_SIZE-1: 0] BB;	/*
						 * 1: reg is ready.
						 * 0: reg isn't ready.
						 */


/* 
 * input
 */
input					CLK;
input					RESET;
input					FREEZE;
input					do_write;
input		[ISSUEE_ENTRY_SIZE-1:0] write_data;
input					mispredict;
input					flush_fCOM;
input					do_writeback1_WB;
input		  		[ 5: 0] writeReg1_phy_WB;
input					do_writeback1_WB_LS;
input		  		[ 5: 0] writeReg1_phy_WB_LS;
input         				do_clear_2BB;
input        			[ 5: 0] clear_index_2BB;

input					debug;

/*
 * internal
 */
wire 	[ 5: 0] writeReg1_phy_in;
wire		do_writeback1_in;
wire 	[ 5: 0] writeReg1_phy_out;
wire		do_writeback1_out;
wire		memOpe_out;

wire		R0, R1, R2, R3, R;
wire		G0, G1, G2, G3, G;
wire		g00, g01, g02,  g03,  g10,  g11,  g12,  g13;
wire		g20, g21, g22,  g23,  g30,  g31,  g32,  g33;

wire	[ 3: 0] out_entry_index;
wire	[ 4: 0] counter;

reg    [ISSUEE_ENTRY_SIZE-1: 0] QUEUE [ISSUEE_QUEUE_SIZE-1:0];
reg     		[ 2: 0] READY [ISSUEE_QUEUE_SIZE-1:0];

reg			[ 3: 0] i;
reg			[ 3: 0] j;

/* 
 * combinational logic 
 */
/* wakeup */
always begin
	for (i = 0; i < 15; i = i + 1) begin
		READY[i][0] = BB[QUEUE[i][166:161]] && QUEUE[i][191];
		READY[i][1] = BB[QUEUE[i][173:168]] && QUEUE[i][191];
		READY[i][2] = READY[i][0] && READY[i][1];
	end
	READY[ISSUEE_QUEUE_SIZE-1][0] = BB[QUEUE[ISSUEE_QUEUE_SIZE-1][166:161]] && QUEUE[ISSUEE_QUEUE_SIZE-1][191];
	READY[ISSUEE_QUEUE_SIZE-1][1] = BB[QUEUE[ISSUEE_QUEUE_SIZE-1][173:168]] && QUEUE[ISSUEE_QUEUE_SIZE-1][191];
	READY[ISSUEE_QUEUE_SIZE-1][2] = READY[ISSUEE_QUEUE_SIZE-1][0] && READY[ISSUEE_QUEUE_SIZE-1][1];
end

assign writeReg1_phy_in = write_data[179:174]; 
assign do_writeback1_in = write_data[140];

assign full		= (counter == ISSUEE_QUEUE_SIZE);
assign empty		= (counter == 0);

/* select */
assign G 	    	= 1'b1;
assign do_issue_out 	= R0 || R1 || R2 || R3;

assign out_entry_index 	= g00*0  + g01*1  +  g02*2  + g03*3 +
			  g10*4  + g11*5  +  g12*6  + g13*7 +
			  g20*8  + g21*9  +  g22*10 + g23*11 +
			  g30*12 + g31*13 +  g32*14 + g33*15;

assign out_entry 	= do_issue_out ? QUEUE[out_entry_index] : 0;
assign writeReg1_phy_out= out_entry[179:174]; 
assign do_writeback1_out= out_entry[140]; 
assign memOpe_out	= out_entry[133] || out_entry[135];


select select0(g00, g01, g02, g03, R0,	READY[0][2],  READY[1][2],  READY[2][2],  READY[3][2],  G0);
select select1(g10, g11, g12, g13, R1,	READY[4][2],  READY[5][2],  READY[6][2],  READY[7][2],  G1);
select select2(g20, g21, g22, g23, R2,	READY[8][2],  READY[9][2],  READY[10][2], READY[11][2], G2);
select select3(g30, g31, g32, g33, R3,	READY[12][2], READY[13][2], READY[14][2], READY[15][2], G3);
select select4(G0,  G1,  G2,  G3,  R,	R0, R1, R2, R3, G);

/* 
 * sequencial logic
 */
/* for issue queue */
always @ (posedge CLK or negedge RESET) begin
	if (!RESET || flush_fCOM || mispredict) begin
		QUEUE[0]<=0;  QUEUE[1]<=0;  QUEUE[2]<=0;  QUEUE[3]<=0;  QUEUE[4]<=0;  QUEUE[5]<=0;  QUEUE[6]<=0;  QUEUE[7]<=0;
		QUEUE[8]<=0;  QUEUE[9]<=0; QUEUE[10]<=0; QUEUE[11]<=0; QUEUE[12]<=0; QUEUE[13]<=0; QUEUE[14]<=0; QUEUE[15]<=0;
		counter <= 0;
	end
	else if (!FREEZE) begin
		/* compact */
		if (do_issue_out) begin
			/*
			for (j = 0; j < counter[3:0]-1; j = j+1)
				QUEUE[j] <= ((j >= out_entry_index) ? QUEUE[j+1] : QUEUE[j]);
				QUEUE[j] <= 0;
			*/
			QUEUE[0] <= (( 0 < (counter[3:0]-1) && 0 >= out_entry_index) ? QUEUE[0+1] : 
						((0 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[0]));
			QUEUE[1] <= (( 1 < (counter[3:0]-1) && 1 >= out_entry_index) ? QUEUE[1+1] : 
						((1 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[1]));
			QUEUE[2] <= (( 2 < (counter[3:0]-1) && 2 >= out_entry_index) ? QUEUE[2+1] : 
						((2 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[2]));
			QUEUE[3] <= (( 3 < (counter[3:0]-1) && 3 >= out_entry_index) ? QUEUE[3+1] : 
						((3 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[3]));
			QUEUE[4] <= (( 4 < (counter[3:0]-1) && 4 >= out_entry_index) ? QUEUE[4+1] : 
						((4 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[4]));
			QUEUE[5] <= (( 5 < (counter[3:0]-1) && 5 >= out_entry_index) ? QUEUE[5+1] : 
						((5 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[5]));
			QUEUE[6] <= (( 6 < (counter[3:0]-1) && 6 >= out_entry_index) ? QUEUE[6+1] : 
						((6 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[6]));
			QUEUE[7] <= (( 7 < (counter[3:0]-1) && 7 >= out_entry_index) ? QUEUE[7+1] : 
						((7 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[7]));
			QUEUE[8] <= (( 8 < (counter[3:0]-1) && 8 >= out_entry_index) ? QUEUE[8+1] : 
						((8 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[8]));
			QUEUE[9] <= (( 9 < (counter[3:0]-1) && 9 >= out_entry_index) ? QUEUE[9+1] : 
						((9 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[9]));
			QUEUE[10] <= (( 10 < (counter[3:0]-1) && 10 >= out_entry_index) ? QUEUE[10+1] : 
						((10 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[10]));
			QUEUE[11] <= (( 11 < (counter[3:0]-1) && 11 >= out_entry_index) ? QUEUE[11+1] : 
						((11 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[11]));
			QUEUE[12] <= (( 12 < (counter[3:0]-1) && 12 >= out_entry_index) ? QUEUE[12+1] : 
						((12 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[12]));
			QUEUE[13] <= (( 13 < (counter[3:0]-1) && 13 >= out_entry_index) ? QUEUE[13+1] : 
						((13 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[13]));
			QUEUE[14] <= (( 14 < (counter[3:0]-1) && 14 >= out_entry_index) ? QUEUE[14+1] : 
						((14 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[14]));
			QUEUE[15] <= (( 15 < (counter[3:0]-1) && 15 >= out_entry_index) ? QUEUE[15+1] : 
						((15 == (counter[3:0]-1)) ? ((do_write && !full) ? {1'b1, write_data[190:0]} : 0) : QUEUE[15]));
			//QUEUE[counter[3:0]-1] <= (do_write && !full) ? {1'b1, write_data[190:0]} : 0;
		end

		if (do_write && !full) begin
			if (!do_issue_out)
				QUEUE[counter[3:0]]	 <= {1'b1, write_data[190:0]};
		end

		if (do_issue_out && (!do_write || full))
			counter <= counter - 1;
		else if (!do_issue_out && (do_write && !full))
			counter <= counter + 1;
	end
end

/* for Busy Bits */
always @ (posedge CLK or negedge RESET) begin
	if (!RESET || mispredict) begin
		BB <= 64'hffff_ffff_ffff_ffff;			/* at first, everything is ready */
	end
	else begin
		//if (do_issue_out && !memOpe_out)		/* issue a ALU inst */
		if (do_issue_out && do_writeback1_out)
			BB[writeReg1_phy_out] <= 1'b1;
		
		//if (do_writeback1_in && do_write && !full)	/* insert a inst into Issue Queue, clear the bit */
		//	BB[writeReg1_phy_in]  <= 1'b0;

		if (do_clear_2BB)
			BB[clear_index_2BB]   <= 1'b0;

		if (do_writeback1_WB)				/* when WB, set the bit */
			BB[writeReg1_phy_WB]  <= 1'b1;

		if (do_writeback1_WB_LS)			/* when WB_LS, set the bit */
			BB[writeReg1_phy_WB_LS]  <= 1'b1;
	end
end


always @ (posedge CLK or negedge RESET) begin
	if (debug) begin
		$display("[ISSQ]: Busy Bits");
		$display("\t 6 6 6 6 5 5 5 5 5 5 5 5 5 5 4 4 4 4 4 4 4 4 4 4 3 3 3 3 3 3 3 3 3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1 ");
		$display("\t 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 ");
                $display("\t+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+");
                $display("\t|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|",
                        BB[63], BB[62], BB[61], BB[60], BB[59], BB[58], BB[57], BB[56],
                        BB[55], BB[54], BB[53], BB[52], BB[51], BB[50], BB[49], BB[48],
                        BB[47], BB[46], BB[45], BB[44], BB[43], BB[42], BB[41], BB[40],
                        BB[39], BB[38], BB[37], BB[36], BB[35], BB[34], BB[33], BB[32],
                        BB[31], BB[30], BB[29], BB[28], BB[27], BB[26], BB[25], BB[24],
                        BB[23], BB[22], BB[21], BB[20], BB[19], BB[18], BB[17], BB[16],
                        BB[15], BB[14], BB[13], BB[12], BB[11], BB[10], BB[ 9], BB[ 8],
                        BB[ 7], BB[ 6], BB[ 5], BB[ 4], BB[ 3], BB[ 2], BB[ 1], BB[ 0]
                );
                $display("\t+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+");
		$display("[ISSQ]: Issue Queue");
                $display("\t+-+-+-+---15---+-+-+-+---14---+-+-+-+---13---+-+-+-+---12---+-+-+-+---11---+-+-+-+---10---+-+-+-+---09---+-+-+-+---08---+");
		$display("\t|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|",
              		READY[15][2], READY[15][1], READY[15][0], QUEUE[15][95:64], READY[14][2], READY[14][1], READY[14][0], QUEUE[14][95:64], 
              		READY[13][2], READY[13][1], READY[13][0], QUEUE[13][95:64], READY[12][2], READY[12][1], READY[12][0], QUEUE[12][95:64], 
              		READY[11][2], READY[11][1], READY[11][0], QUEUE[11][95:64], READY[10][2], READY[10][1], READY[10][0], QUEUE[10][95:64], 
              		READY[ 9][2], READY[ 9][1], READY[ 9][0], QUEUE[ 9][95:64], READY[ 8][2], READY[ 8][1], READY[ 8][0], QUEUE[ 8][95:64] 
		);

                $display("\t+-+-+-+---07---+-+-+-+---06---+-+-+-+---05---+-+-+-+---04---+-+-+-+---03---+-+-+-+---02---+-+-+-+---01---+-+-+-+---00---+");
		$display("\t|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|%d|%d|%d|%8x|",
              		READY[ 7][2], READY[ 7][1], READY[ 7][0], QUEUE[ 7][95:64], READY[ 6][2], READY[ 6][1], READY[ 6][0], QUEUE[ 6][95:64], 
              		READY[ 5][2], READY[ 5][1], READY[ 5][0], QUEUE[ 5][95:64], READY[ 4][2], READY[ 4][1], READY[ 4][0], QUEUE[ 4][95:64], 
              		READY[ 3][2], READY[ 3][1], READY[ 3][0], QUEUE[ 3][95:64], READY[ 2][2], READY[ 2][1], READY[ 2][0], QUEUE[ 2][95:64], 
              		READY[ 1][2], READY[ 1][1], READY[ 1][0], QUEUE[ 1][95:64], READY[ 0][2], READY[ 0][1], READY[ 0][0], QUEUE[ 0][95:64] 
		);
		$display("\t+-+-+-+--------+-+-+-+--------+-+-+-+--------+-+-+-+--------+-+-+-+--------+-+-+-+--------+-+-+-+--------+-+-+-+--------+");

		$display("[ISSQ]:\tdo_issue_out=%d\tout_entry_index=%d\tout_inst=0x%x\tcounter=%d", do_issue_out, out_entry_index, 
			out_entry[31:0], counter);
		$display("[ISSQ]:\tdo_writeback1_WB=%d\twriteReg1_phy_WB=%d", do_writeback1_WB, writeReg1_phy_WB);
	end
end

endmodule
