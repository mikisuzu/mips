/*
 * Commit Stage
 */

module COM(
	CLK,
	RESET,
	FREEZE,
	/* output */
	do_reclaim_OUT,
	reclaimed_reg_OUT,
	mispredict_OUT,
	flush_fCOM,
	nexInstAddr_OUT,
	RAT_OUT,
	do_read_ROB,
	do_remend_ROB,
	remend_data,
	remend_index, 
	do_remend_ROB_LS,
	remend_data_LS,
	remend_index_LS, 
        //do_read_COMQUEUE,
	/* input */
	ROB_head,
	empty_ROB,
	com_entry,
	com_entry_LS,
	ROB_entry,
        //empty_COMQUEUE,
	debug
);

/*
 * parameters
 */
parameter COM_ENTRY_SIZE = 192;
parameter RAT_SIZE       =  32;
parameter RAT_ENTRY_SIZE =   7;
parameter ROB_ENTRY_SIZE = 192;

/*
 * output variables
 */
/* for reclaim reg */
output reg 			do_reclaim_OUT;
output reg 		[ 5: 0] reclaimed_reg_OUT;
/* for exeception or mispredict */
output reg			flush_fCOM;
output reg			mispredict_OUT;
output reg		[31: 0] nexInstAddr_OUT;
output reg [RAT_ENTRY_SIZE-1:0] RAT_OUT [0:RAT_SIZE-1];
/* to ROB */
output reg			do_read_ROB;
output reg			do_remend_ROB;
output reg		[64: 0] remend_data; 
output reg		[ 5: 0] remend_index; 
output reg			do_remend_ROB_LS;
output reg		[64: 0] remend_data_LS; 
output reg		[ 5: 0] remend_index_LS; 

//output reg                      do_read_COMQUEUE;


/* 
 * input variables
 */
input				CLK;
input				RESET;
input				FREEZE;
/* from ROB */
input			 [5: 0] ROB_head;
input			        empty_ROB;
input      [ROB_ENTRY_SIZE-1:0] ROB_entry;

input      [COM_ENTRY_SIZE-1:0] com_entry;
input      [COM_ENTRY_SIZE-1:0] com_entry_LS;
//input                           empty_COMQUEUE;

input                   	debug;


/* 
 * internal variables
 */
wire [RAT_ENTRY_SIZE-1:0] RAT_entry;

wire  			  do_writeback1;
wire 		  [ 5: 0] writeRegister1_phy;
wire 		  [ 4: 0] writeRegister1_arc;
wire		  [31: 0] nextInstAddr1;
wire			  jump1;
wire			  taken_branch1;
wire		  [31: 0] Instr1;
wire			  valid;
wire		  [ 5: 0] ROB_index;

wire  			  do_writeback1_LS;
wire 		  [ 5: 0] writeRegister1_phy_LS;
wire 		  [ 4: 0] writeRegister1_arc_LS;
wire		  [31: 0] nextInstAddr1_LS;
wire			  jump1_LS;
wire			  taken_branch1_LS;
wire		  [31: 0] Instr1_LS;
wire			  valid_LS;
wire		  [ 5: 0] ROB_index_LS;

wire 		[ 5: 0] writeRegister1_phy_fROB;
wire 			ready_fROB;
wire 			mispredict_fROB;
wire 			do_writeback1_fROB;
wire 		[ 4: 0] writeRegister1_arc_fROB;
wire 		[31: 0] nextInstAddr1_fROB;

wire			  branch_inst;		
wire			  mispredict;

reg [RAT_ENTRY_SIZE-1: 0] RAT [0:RAT_SIZE-1];
/* delay publishing branch result for 2 cycles */
reg                     [32: 0] branch_result1;
reg                     [32: 0] branch_result2;         /*      
							 *       3 3
                                                         *       2 1                   0
                                                         *      +-+---------...---------+
                                                         *      |b|      next addr	|
                                                         *      +-+---------...---------+
                                                         *
                                                         *      branch_result1 -> branch_result2
							 */

/*
 * combinational logic
 */
/* parse com entry */
assign writeRegister1_phy 	= com_entry[179:174];
assign ROB_index	  	= com_entry[159:154];
assign taken_branch1	  	= com_entry[141];
assign do_writeback1	  	= com_entry[140];
assign jump1		  	= com_entry[137];
assign writeRegister1_arc 	= com_entry[110:106];
assign nextInstAddr1	  	= com_entry[ 95: 64];
assign Instr1		  	= com_entry[ 31:  0];
assign valid		  	= com_entry[191];
//assign valid		 	= !empty_COMQUEUE;
//assign valid		  	= do_read_COMQUEUE;

/* parse com entry of LS */
assign writeRegister1_phy_LS	= com_entry_LS[179:174];
assign ROB_index_LS	  	= com_entry_LS[159:154];
assign taken_branch1_LS	  	= com_entry_LS[141];
assign do_writeback1_LS	  	= com_entry_LS[140];
assign jump1_LS		  	= com_entry_LS[137];
assign writeRegister1_arc_LS 	= com_entry_LS[110:106];
assign nextInstAddr1_LS	  	= com_entry_LS[ 95: 64];
assign Instr1_LS		= com_entry_LS[ 31:  0];
assign valid_LS		  	= com_entry_LS[191];

/* parse ROB entry */
assign writeRegister1_phy_fROB	= ROB_entry[179:174];
assign ready_fROB		= ROB_entry[153];
assign mispredict_fROB	  	= ROB_entry[141];
assign do_writeback1_fROB	= ROB_entry[140];
assign writeRegister1_arc_fROB 	= ROB_entry[110:106];
assign nextInstAddr1_fROB	= ROB_entry[ 95: 64];

/* for reclaim reg */
//assign do_reclaim_OUT 	  = (FREEZE) ? 1'b0 : (do_writeback1 && RAT_entry[6] && valid);
assign RAT_entry	  	= RAT[writeRegister1_arc_fROB]; 
assign do_reclaim_OUT 	  	= do_writeback1_fROB && RAT_entry[6] && ready_fROB;
assign reclaimed_reg_OUT  	= RAT_entry[5:0];

/* for exeception or mispredict */
//assign flush_fCOM	  = (FREEZE) ? 1'b0 : mispredict_fROB;
assign flush_fCOM	  = 1'b0;
//assign mispredict_OUT	  = (FREEZE) ? 1'b0 : branch_result2[32];
assign mispredict_OUT	  = branch_result2[32];
assign nexInstAddr_OUT	  = (FREEZE) ? 32'b0 : branch_result2[31:0];
//mispredict_OUT	  = (jump1 || (branch_inst ? taken_branch1 : 1'b0)) && valid;
//nexInstAddr_OUT	  = nextInstAddr1;
assign RAT_OUT		  = RAT; 
assign mispredict	  = (jump1 || (branch_inst ? taken_branch1 : 1'b0)) && valid;

/* read ROB */
assign do_read_ROB	  = !mispredict_OUT && ready_fROB  && !empty_ROB && !FREEZE;

/* for amend ROB */
assign do_remend_ROB 	  = valid;
assign remend_data	  = {mispredict, com_entry[191:160], nextInstAddr1};
assign remend_index 	  = ROB_index;
assign do_remend_ROB_LS   = valid_LS;
assign remend_data_LS	  = {1'b0, com_entry_LS[191:160], 32'b0};
assign remend_index_LS 	  = ROB_index_LS;

/* for read/write queue */
//assign do_read_COMQUEUE   = (!RESET || FREEZE || mispredict_OUT || empty_COMQUEUE) ? 1'b0 : 1'b1;

always begin
	case(Instr1[31:26])
        	6'b000001, 6'b000100, 6'b000101, 6'b000110, 6'b000111:
               		branch_inst = 1'b1;         	
                default:
               		branch_inst = 1'b0;         	
	endcase
end

/* update retire RAT */
/*
always begin
	if (!RESET) begin
                RAT[ 0] = 7'b0; RAT[ 1] = 7'b0; RAT[ 2] = 7'b0; RAT[ 3] = 7'b0;
                RAT[ 4] = 7'b0; RAT[ 5] = 7'b0; RAT[ 6] = 7'b0; RAT[ 7] = 7'b0;
                RAT[ 8] = 7'b0; RAT[ 9] = 7'b0; RAT[10] = 7'b0; RAT[11] = 7'b0;
                RAT[12] = 7'b0; RAT[13] = 7'b0; RAT[14] = 7'b0; RAT[15] = 7'b0;
                RAT[16] = 7'b0; RAT[17] = 7'b0; RAT[18] = 7'b0; RAT[19] = 7'b0;
                RAT[20] = 7'b0; RAT[21] = 7'b0; RAT[22] = 7'b0; RAT[23] = 7'b0;
                RAT[24] = 7'b0; RAT[25] = 7'b0; RAT[26] = 7'b0; RAT[27] = 7'b0;
                RAT[28] = 7'b0; RAT[29] = 7'b1_11_1110;   RAT[30] = 7'b0; RAT[31] = 7'b1_11_1111;
	end
	else if (!FREEZE) begin
		if (do_writeback1 && valid)
			RAT[writeRegister1_arc] = {1'b1, writeRegister1_phy};
	end
	
end
*/

/*
 * sequential logic
 */
always @ (posedge CLK or negedge RESET) begin
        if (!RESET) begin
		/* 
 		 * init retire RAT, 
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
		if (do_writeback1_fROB && ready_fROB && !branch_result2[32])
			RAT[writeRegister1_arc_fROB] <= {1'b1, writeRegister1_phy_fROB};
		
		/*
		else if (mispredict_OUT) begin
                	RAT[ 0][6] <= 1'b0; RAT[ 1][6] <= 1'b0; RAT[ 2][6] <= 1'b0; RAT[ 3][6] <= 1'b0;
                	RAT[ 4][6] <= 1'b0; RAT[ 5][6] <= 1'b0; RAT[ 6][6] <= 1'b0; RAT[ 7][6] <= 1'b0;
                	RAT[ 8][6] <= 1'b0; RAT[ 9][6] <= 1'b0; RAT[10][6] <= 1'b0; RAT[11][6] <= 1'b0;
                	RAT[12][6] <= 1'b0; RAT[13][6] <= 1'b0; RAT[14][6] <= 1'b0; RAT[15][6] <= 1'b0;
                	RAT[16][6] <= 1'b0; RAT[17][6] <= 1'b0; RAT[18][6] <= 1'b0; RAT[19][6] <= 1'b0;
                	RAT[20][6] <= 1'b0; RAT[21][6] <= 1'b0; RAT[22][6] <= 1'b0; RAT[23][6] <= 1'b0;
                	RAT[24][6] <= 1'b0; RAT[25][6] <= 1'b0; RAT[26][6] <= 1'b0; RAT[27][6] <= 1'b0;
                	RAT[28][6] <= 1'b0; RAT[29][6] <= 1'b0; RAT[30][6] <= 1'b0; RAT[31][6] <= 1'b0;
		end
		*/
	end
end

always @ (posedge CLK or negedge RESET) begin
	if (!RESET || mispredict_OUT) begin
		//mispredict_OUT	<= 1'b0;
		//nexInstAddr_OUT	<= 32'b0;
		branch_result1	<= 33'b0;
		branch_result2	<= 33'b0;
	end
	else if (!FREEZE && !empty_ROB) begin
		//mispredict_OUT	<= branch_result2[32];
		//nexInstAddr_OUT	<= branch_result2[31:0];
                branch_result1  <= {mispredict_fROB, nextInstAddr1_fROB};
                branch_result2  <= branch_result1;
	end
end

always @ (posedge CLK or negedge RESET) begin
	if (debug) begin
                //$display("=========================================================================================");
		/* display Retire RAT */
		$display("[COM]: Retire RAT");
                $display("\t 31  30  29  28  27  26  25  24  23  22  21  20  19  18  17  16  15  14  13  12  11  10  9   8   7   6   5   4   3   2   1   0");
                $display("\t+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+");
                $display("\t|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|",
                        RAT[31][5:0], RAT[30][5:0], RAT[29][5:0], RAT[28][5:0], RAT[27][5:0], RAT[26][5:0], RAT[25][5:0], RAT[24][5:0],
                        RAT[23][5:0], RAT[22][5:0], RAT[21][5:0], RAT[20][5:0], RAT[19][5:0], RAT[18][5:0], RAT[17][5:0], RAT[16][5:0],
                        RAT[15][5:0], RAT[14][5:0], RAT[13][5:0], RAT[12][5:0], RAT[11][5:0], RAT[10][5:0], RAT[ 9][5:0], RAT[ 8][5:0],
                        RAT[ 7][5:0], RAT[ 6][5:0], RAT[ 5][5:0], RAT[ 4][5:0], RAT[ 3][5:0], RAT[ 2][5:0], RAT[ 1][5:0], RAT[ 0]
                );
                $display("\t+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+");
                //$display("");
                /*
                $display("\t 15  14  13  12  11  10  9   8   7   6   5   4   3   2   1   0");
                $display("\t+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+");
                $display("\t|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|%3d|",
                        RAT[15][5:0], RAT[14][5:0], RAT[13][5:0], RAT[12][5:0], RAT[11][5:0], RAT[10][5:0], RAT[ 9][5:0], RAT[ 8][5:0],
                        RAT[ 7][5:0], RAT[ 6][5:0], RAT[ 5][5:0], RAT[ 4][5:0], RAT[ 3][5:0], RAT[ 2][5:0], RAT[ 1][5:0], RAT[ 0]
                );
                $display("\t+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+");
		*/
		$display("[COM]:\tmispredict=%d\tnexInstAddr_OUT=%x\tROB_index=%d", mispredict, nexInstAddr_OUT, com_entry[159:154]);
	end
end


endmodule
