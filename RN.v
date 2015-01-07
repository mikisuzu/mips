/*
 * Rename Stage
 */

/*
 * Rename RAT:			Free List:		
 *
 *	 6 5     0                      63       2 1 0
 *	+-+-------+			+-+-----+-+-+-+	
 *	| |	  | 0			| |	| | | |0
 *	+-+-------+			| |	| | | |
 *	| |	  | 1			| |	| | | | <- physical
 *	+-+-------+			| |	| | | |    reg name
 *	| |	  |			| |	| | | |5
 *	| | ....  | <- physical		+-+-----+-+-+-+
 *	| |	  |    reg name
 *	+-+-------+
 *	| |	  | 31
 *	+-+-------+
 *       ^
 * 	 |
 *	valid
 *
 * - allocate physical reg
 * - update free list
 * - update RAT
 */


module RN (
	CLK,
	RESET,
	FREEZE,
	/* output */
	empty_freelist_signal,
	issue_entry,
	do_write_2ROB,
	ROB_entry,
	RAT_fRN,
	do_read_RNQUEUE,
	//do_wirte_ISSQUEUE,
   	do_wirte_2ISSQ,
	do_wirte_2LSQ,
   	do_clear_2BB,
	clear_index_2BB,
	/* input */
	rename_entry,
	do_reclaim,
	reclaimed_reg,
	do_copy_RAT,
	old_RAT,
	mispredict,
	flush_fCOM,
	full_ROB,
	ROB_tail,
	ROB_head,
	reg_counter,
	empty_RNQUEUE,
	full_ISSQ,
	full_LSQ,
	debug
);

/* parameters */
parameter ISSUE_ENTRY_SIZE	= 192;
parameter RENAME_ENTRY_SIZE	= 160;
parameter RAT_SIZE       	=  32;
parameter RAT_ENTRY_SIZE 	=   7;
parameter FREELIST_SIZE       	=  64;
parameter FREELIST_ENTRY_SIZE 	=   6;
parameter ROB_ENTRY_SIZE	= 192;
parameter ROB_SIZE		=  64;


/*
 * output variables
 */
output reg			   empty_freelist_signal;

output reg [ISSUE_ENTRY_SIZE-1: 0] issue_entry;
output				   do_wirte_2ISSQ;
output				   do_wirte_2LSQ;
/* for ROB */
output reg 			   do_write_2ROB;
output reg   [ROB_ENTRY_SIZE-1: 0] ROB_entry;

output reg   [RAT_ENTRY_SIZE-2: 0] RAT_fRN [0:RAT_SIZE-1];
output				   do_read_RNQUEUE;
//output				   do_wirte_ISSQUEUE;
/* for BB */
output reg			   do_clear_2BB;
output reg		   [ 5: 0] clear_index_2BB;


/*
 * input variables
 */
input 	 			CLK;
input 	 			RESET;
input 				FREEZE;
input  [RENAME_ENTRY_SIZE-1: 0] rename_entry;
/* for reg reclaiming */
input   	 		do_reclaim;
input	         	 [5: 0] reclaimed_reg;
/* for RAT restore */
input				do_copy_RAT;
input     [RAT_ENTRY_SIZE-1: 0] old_RAT [0:RAT_SIZE-1];
/* for mispredict */
input				mispredict;
input				flush_fCOM;
/* from ROB */
input				full_ROB;
input			[ 5: 0] ROB_tail;
input			[ 5: 0] ROB_head;
input			[ 5: 0] reg_counter;

input				empty_RNQUEUE;
input				full_ISSQ;
input				full_LSQ;

input                   	debug;

/*
 * internel variables
 */
/* rename RAT */
reg	  [RAT_ENTRY_SIZE-1: 0] RAT [0:RAT_SIZE-1];
/* free list */
reg       		 [5: 0] in;			/* point to the empty entry */
reg       	  	 [5: 0] out;			/* point to the valid entry */
reg	  	         [6: 0] freelist_counter;
reg  [FREELIST_ENTRY_SIZE-1: 0] FREELIST [0:FREELIST_SIZE-1];

wire	  [4: 0] i;
wire	  [5: 0] j;
wire	  [5: 0] k;
wire	  	 do_writeback1;
wire      [4: 0] write_arcReg1;
wire	  [4: 0] read_arcReg_A1;
wire	  [4: 0] read_arcReg_B1;
wire      [5: 0] write_phyReg1;
wire      [5: 0] read_phyReg_A1;
wire      [5: 0] read_phyReg_B1;
wire	  [6: 0] RAT_entry_A1;
wire	  [6: 0] RAT_entry_B1;
wire		 empty_freelist;
wire	  [5: 0] ROB_num;
wire	  [5: 0] reclaimed_reg_num;
wire		 MemRead1;
wire		 MemWrite1;
wire		 ALUOperation;
wire		 MemOperation;

/*
initial begin
	head 		<= 6'b000000;
	tail 		<= 6'b000000;
	list_counter 	<= 7'b1000000;
end
*/

/*
 * combinational logic 
 */
/* parse rename entry */
assign   do_writeback1  = rename_entry[140];
assign 	 MemRead1	= rename_entry[135];
assign 	 MemWrite1	= rename_entry[133];
assign   read_arcReg_A1 = rename_entry[100: 96];
assign   read_arcReg_B1 = rename_entry[105:101];
assign   write_arcReg1  = rename_entry[110:106];

/* allocate physical reg */
assign	 RAT_entry_A1   = RAT[read_arcReg_A1];
assign	 RAT_entry_B1   = RAT[read_arcReg_B1];
assign   read_phyReg_A1 = RAT_entry_A1[5:0];
assign   read_phyReg_B1 = RAT_entry_B1[5:0];

assign   empty_freelist	= (freelist_counter == 7'b0);
assign   write_phyReg1  = do_writeback1 ? (empty_freelist ? 6'b0 : FREELIST[out]) : RAT[write_arcReg1][5:0];
//assign   write_phyReg1  = do_writeback1 ? (empty_freelist ? 6'b0 : FREELIST[out]) : 6'b0;

//assign reclaimed_reg_num = (ROB_tail >= ROB_head) ? (ROB_tail-ROB_head) : (ROB_SIZE-(ROB_head-ROB_tail));
//assign reclaimed_reg_num = (ROB_tail >= ROB_head) ? (ROB_tail-ROB_head-1) : (ROB_tail-ROB_head-1);
assign reclaimed_reg_num = reg_counter;

/* for read/write queue */
assign MemOperation	= MemRead1 || MemWrite1;
assign do_read_RNQUEUE  = (!RESET || FREEZE || mispredict || flush_fCOM || empty_RNQUEUE || 
				(MemOperation ? full_LSQ : full_ISSQ) || full_ROB || empty_freelist) ? 1'b0 : 1'b1;
assign do_wirte_2ISSQ 	= MemOperation ? 1'b0 : do_read_RNQUEUE;
assign do_wirte_2LSQ 	= MemOperation ? do_read_RNQUEUE : 1'b0;
//assign issue_entry       = (!do_wirte_ISSQUEUE) ? 0 : {1'b1, 11'b0, write_phyReg1, read_phyReg_B1, 1'b0, 
assign issue_entry       = (!do_read_RNQUEUE) ? 0 : {1'b1, 11'b0, write_phyReg1, read_phyReg_B1, 1'b0, 
							read_phyReg_A1, 1'b0, ROB_num, rename_entry[153:0]};
/* for clear BB */
assign do_clear_2BB	= do_writeback1 && do_read_RNQUEUE;
assign clear_index_2BB  = write_phyReg1;


/* allocate ROB */
always begin
	if (!full_ROB && do_read_RNQUEUE) begin
	//if (!full_ROB && !FREEZE) begin
		ROB_num 	= ROB_tail;
		do_write_2ROB 	= 1'b1;
		//ROB_entry 	= {32'b0, 1'b1, 19'b0, do_writeback1, write_arcReg1, write_phyReg1};
		ROB_entry 	= {1'b1, 11'b0, write_phyReg1, read_phyReg_B1, 1'b0,
                                  	read_phyReg_A1, 1'b0, ROB_num, rename_entry[153:0]};
	end
	else begin
		ROB_num 	= 6'b0;
		do_write_2ROB 	= 1'b0;
		ROB_entry 	= 192'b0;
	end
end


always begin
	for (i = 0; i < 31; i ++)
		RAT_fRN[i] = RAT[i][5:0];
	RAT_fRN[31] = RAT[31][5:0];
end

/*
 * running
 */

/* free list */
always @ (posedge CLK or negedge RESET) begin
	if (!RESET) begin
		in 		<= 6'b00_0000;
		out 		<= 6'b00_0011;
		freelist_counter<= 7'b011_1101;

		for (k = 63; k > 2; k = k - 1)
			FREELIST[k] <= k - 2;
		FREELIST[2] <= 6'b0; 
		FREELIST[1] <= 6'b0; 
		FREELIST[0] <= 6'b0; 
		/*
		FREELIST[ 0] <= 6'b000000; FREELIST[ 1] <= 6'b000001; FREELIST[ 2] <= 6'b000010; FREELIST[ 3] <= 6'b000011;
		FREELIST[ 4] <= 6'b000100; FREELIST[ 5] <= 6'b000101; FREELIST[ 6] <= 6'b000110; FREELIST[ 7] <= 6'b000111;
		FREELIST[ 8] <= 6'b001000; FREELIST[ 9] <= 6'b001001; FREELIST[10] <= 6'b001010; FREELIST[11] <= 6'b001011;
		FREELIST[12] <= 6'b001100; FREELIST[13] <= 6'b001101; FREELIST[14] <= 6'b001110; FREELIST[15] <= 6'b001111;
		FREELIST[16] <= 6'b010000; FREELIST[17] <= 6'b010001; FREELIST[18] <= 6'b010010; FREELIST[19] <= 6'b010011;
		FREELIST[20] <= 6'b010100; FREELIST[21] <= 6'b010101; FREELIST[22] <= 6'b010110; FREELIST[23] <= 6'b010111;
		FREELIST[24] <= 6'b011000; FREELIST[25] <= 6'b011001; FREELIST[26] <= 6'b011010; FREELIST[27] <= 6'b011011;
		FREELIST[28] <= 6'b011100; FREELIST[29] <= 6'b011101; FREELIST[30] <= 6'b011110; FREELIST[31] <= 6'b011111;
		FREELIST[32] <= 6'b100000; FREELIST[33] <= 6'b100001; FREELIST[34] <= 6'b100010; FREELIST[35] <= 6'b100011;
		FREELIST[36] <= 6'b100100; FREELIST[37] <= 6'b100101; FREELIST[38] <= 6'b100110; FREELIST[39] <= 6'b100111;
		FREELIST[40] <= 6'b101000; FREELIST[41] <= 6'b101001; FREELIST[42] <= 6'b101010; FREELIST[43] <= 6'b101011;
		FREELIST[44] <= 6'b101100; FREELIST[45] <= 6'b101101; FREELIST[46] <= 6'b101110; FREELIST[47] <= 6'b101111;
		FREELIST[48] <= 6'b110000; FREELIST[49] <= 6'b110001; FREELIST[50] <= 6'b110010; FREELIST[51] <= 6'b110011;
		FREELIST[52] <= 6'b110100; FREELIST[53] <= 6'b110101; FREELIST[54] <= 6'b110110; FREELIST[55] <= 6'b110111;
		FREELIST[56] <= 6'b111000; FREELIST[57] <= 6'b111001; FREELIST[58] <= 6'b111010; FREELIST[59] <= 6'b111011;
		FREELIST[60] <= 6'b111100; FREELIST[61] <= 6'b111101; FREELIST[62] <= 6'b111110; FREELIST[63] <= 6'b111111;
		*/
	end
	else if (mispredict) begin
	//else if (do_copy_RAT) begin	/* do in the same cycle with copying RAT */
		out <= out - reclaimed_reg_num;
		freelist_counter <= freelist_counter + reclaimed_reg_num;
	end
	else if (!FREEZE) begin
		if (do_reclaim) begin
			FREELIST[in] <= reclaimed_reg;
			in	     <= in + 6'b1;
		end
		
		if (do_writeback1 && !empty_freelist && do_read_RNQUEUE) begin
			out	     <= out + 6'b1;
		end

		if (do_reclaim && (!do_writeback1 || empty_freelist || !do_read_RNQUEUE))
			freelist_counter <= freelist_counter + 7'b1;
		else if (!do_reclaim && (do_writeback1 && !empty_freelist) && do_read_RNQUEUE)
			freelist_counter <= freelist_counter - 7'b1;
	end
end

/* rename RAT */
always @ (posedge CLK or negedge RESET) begin
	if (!RESET) begin
                /* 
                 * init rename RAT, 
                 * phy_reg[62] and phy_reg[63] are allocated to 
                 * arc_reg[29] and arc_reg[31] seperately. 
                 */
		RAT[ 0] <= 7'b0; RAT[ 1] <= 7'b0; RAT[ 2] <= 7'b0; RAT[ 3] <= 7'b0;
		RAT[ 4] <= 7'b0; RAT[ 5] <= 7'b0; RAT[ 6] <= 7'b0; RAT[ 7] <= 7'b0;
		RAT[ 8] <= 7'b0; RAT[ 9] <= 7'b0; RAT[10] <= 7'b0; RAT[11] <= 7'b0;
		RAT[12] <= 7'b0; RAT[13] <= 7'b0; RAT[14] <= 7'b0; RAT[15] <= 7'b0;
		RAT[16] <= 7'b0; RAT[17] <= 7'b0; RAT[18] <= 7'b0; RAT[19] <= 7'b0;
		RAT[20] <= 7'b0; RAT[21] <= 7'b0; RAT[22] <= 7'b0; RAT[23] <= 7'b0;
		RAT[24] <= 7'b0; RAT[25] <= 7'b0; RAT[26] <= 7'b0; RAT[27] <= 7'b0;
		RAT[28] <= 7'b0; RAT[29] <= 7'b1_11_1110;   RAT[30] <= 7'b0; RAT[31] <= 7'b1_11_1111; 
	end
	else if (!FREEZE) begin
		if (do_copy_RAT)
			RAT 		   <= old_RAT;		/* exception or mispredict happends, restore RAT */
		else if (do_writeback1 && do_read_RNQUEUE)
			RAT[write_arcReg1] <= {1'b1, write_phyReg1};
	end
end

always @ (posedge CLK or negedge RESET) begin
	if (!RESET || mispredict || flush_fCOM || full_ROB || full_ISSQ || empty_RNQUEUE || empty_freelist) begin
		//empty_freelist_signal <= 1'b0;
		//issue_entry           <= 192'b0;
	end
	else if (!FREEZE) begin
		//empty_freelist_signal <= empty_freelist;
		//issue_entry           <= {1'b1, 11'b0, write_phyReg1, read_phyReg_B1, 1'b0, read_phyReg_A1, 1'b0, ROB_num, rename_entry[153:0]};
	end
end

always @ (posedge CLK or negedge RESET) begin
	if (debug) begin
		/* display FREE LIST */
		$display("[RN]: FREE LIST");
		$display("\t 63 62 61 60 59 58 57 56 55 54 53 52 51 50 49 48 47 46 45 44 43 42 41 40 39 38 37 36 35 34 33 32 ");
		$display("\t+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+");
		$display("\t|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|\thead =%3d\ttail =%3d", 
			FREELIST[63], FREELIST[62], FREELIST[61], FREELIST[60], FREELIST[59], FREELIST[58], FREELIST[57], FREELIST[56],
			FREELIST[55], FREELIST[54], FREELIST[53], FREELIST[52], FREELIST[51], FREELIST[50], FREELIST[49], FREELIST[48],
			FREELIST[47], FREELIST[46], FREELIST[45], FREELIST[44], FREELIST[43], FREELIST[42], FREELIST[41], FREELIST[40],
			FREELIST[39], FREELIST[38], FREELIST[37], FREELIST[36], FREELIST[35], FREELIST[34], FREELIST[33], FREELIST[32],
			out, in
		);
		$display("\t+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+");
		//$display("");
		$display("\t 31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0");
		$display("\t+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+");
		$display("\t|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|%2d|\tcounter =%4d", 
			FREELIST[31], FREELIST[30], FREELIST[29], FREELIST[28], FREELIST[27], FREELIST[26], FREELIST[25], FREELIST[24],
			FREELIST[23], FREELIST[22], FREELIST[21], FREELIST[20], FREELIST[19], FREELIST[18], FREELIST[17], FREELIST[16],
			FREELIST[15], FREELIST[14], FREELIST[13], FREELIST[12], FREELIST[11], FREELIST[10], FREELIST[ 9], FREELIST[ 8],
			FREELIST[ 7], FREELIST[ 6], FREELIST[ 5], FREELIST[ 4], FREELIST[ 3], FREELIST[ 2], FREELIST[ 1], FREELIST[ 0],
			freelist_counter
		);
		$display("\t+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+");
		/* display Rename RAT */
		$display("[RN]: Rename RAT");
                $display("\t 31  30  29  28  27  26  25  24  23  22  21  20  19  18  17  16  15  14  13  12  11  10  9   8   7   6   5   4   3   2   1   0");
                $display("\t+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+");
                $display("\t|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|",
                        RAT[31][5:0], RAT[30][5:0], RAT[29][5:0], RAT[28][5:0], RAT[27][5:0], RAT[26][5:0], RAT[25][5:0], RAT[24][5:0],
                        RAT[23][5:0], RAT[22][5:0], RAT[21][5:0], RAT[20][5:0], RAT[19][5:0], RAT[18][5:0], RAT[17][5:0], RAT[16][5:0],
                        RAT[15][5:0], RAT[14][5:0], RAT[13][5:0], RAT[12][5:0], RAT[11][5:0], RAT[10][5:0], RAT[ 9][5:0], RAT[ 8][5:0],
                        RAT[ 7][5:0], RAT[ 6][5:0], RAT[ 5][5:0], RAT[ 4][5:0], RAT[ 3][5:0], RAT[ 2][5:0], RAT[ 1][5:0], RAT[ 0]
                );
                $display("\t+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+");
		/*
		$display("\t 31  30  29  28  27  26  25  24  23  22  21  20  19  18  17  16");
		$display("\t+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+");
		$display("\t|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|", 
			RAT[31][5:0], RAT[30][5:0], RAT[29][5:0], RAT[28][5:0], RAT[27][5:0], RAT[26][5:0], RAT[25][5:0], RAT[24][5:0],
			RAT[23][5:0], RAT[22][5:0], RAT[21][5:0], RAT[20][5:0], RAT[19][5:0], RAT[18][5:0], RAT[17][5:0], RAT[16][5:0]
		);
		$display("\t+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+");
		//$display("");
		$display("\t 15  14  13  12  11  10  9   8   7   6   5   4   3   2   1   0");
		$display("\t+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+");
		$display("\t|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|", 
			RAT[15][5:0], RAT[14][5:0], RAT[13][5:0], RAT[12][5:0], RAT[11][5:0], RAT[10][5:0], RAT[ 9][5:0], RAT[ 8][5:0],
			RAT[ 7][5:0], RAT[ 6][5:0], RAT[ 5][5:0], RAT[ 4][5:0], RAT[ 3][5:0], RAT[ 2][5:0], RAT[ 1][5:0], RAT[ 0]
		);
		$display("\t+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+");
		*/
		/*
		for (j = 0; j < 63; j = j + 1) begin
			$display("\t\t  +--------+");
			$display("\t\t%2d|      %2d|", j, FREELIST[j]);
		end
		$display("\t\t+--------+");
		*/
		
		$display("[RN]:\twrite_arcReg1=%d\twrite_phyReg1=%d\tread_arcReg_A1=%d\tread_phyReg_A1=%d\tread_arcReg_B1=%d\tread_phyReg_B1=%d", 
				write_arcReg1, write_phyReg1, read_arcReg_A1, read_phyReg_A1, read_arcReg_B1, read_phyReg_B1);
		$display("[RN]:\tdo_read_RNQUEUE=%d\tinst=0x%x", do_read_RNQUEUE, rename_entry[31:0]);
	end
//+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
end

endmodule
