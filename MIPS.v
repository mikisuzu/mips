//-----------------------------------------
//            Pipelined MIPS
//-----------------------------------------
module MIPS (	
	R2_output,
        MemRead,
        MemWrite,
        dBlkRead,
        dBlkWrite,
        iBlkRead,
        iBlkWrite,
        data_write_2DM,
        //data_read_fDM,
	block_write_2IM,
	block_write_2DM,
	block_read_fIM,
	block_read_fDM,
        //Instr1_fIM,
	//Instr2_fIM,
        data_address_2DM,
        CLK,
	RESET,
        R2_input,
	do_delay_syscall,
        PC_init
);


/* parameters */
parameter BB_SIZE           	=  64;
parameter COM_ENTRY_SIZE 	= 192;
parameter DECODE_ENTRY_SIZE 	= 96;
parameter EXE_ENTRY_SIZE   	= 320;
parameter FREELIST_ENTRY_SIZE 	=   6;
parameter FREELIST_SIZE       	=  64;
parameter ISSUE_ENTRY_SIZE	= 192;
parameter MEM_ENTRY_SIZE 	= 320;
parameter RAT_ENTRY_SIZE 	=   7;
parameter RAT_SIZE       	=  32;
parameter REG_SIZE         	=  64;
parameter RET_ENTRY_SIZE 	= 256;
parameter ROB_ENTRY_SIZE	= 192;
parameter ROB_SIZE		=  64;
parameter RENAME_ENTRY_SIZE 	= 160;
parameter SYSCALL_BUBBLES   	=   7;

//parameter DECODE_ENTRY_SIZE =  96;
//parameter RENAME_ENTRY_SIZE	= 160;
//parameter ISSUE_ENTRY_SIZE = 192;
//parameter ISSUE_ENTRY_SIZE = 192;
//parameter EXE_ENTRY_SIZE = 320;
//parameter MEM_ENTRY_SIZE = 320;
//parameter RET_ENTRY_SIZE = 256;
//parameter COM_ENTRY_SIZE = 192;
//parameter RAT_SIZE       =  32;
//parameter RAT_ENTRY_SIZE =   7;

output [31: 0] R2_output;
output [31: 0] data_address_2DM;
output [31: 0] data_write_2DM;
output[255: 0] block_write_2DM;
output[255: 0] block_write_2IM;
output         MemRead;
output         MemWrite;
output         dBlkRead;
output         dBlkWrite;
output         iBlkRead;
output         iBlkWrite;

input  [31: 0]  PC_init;
input  [31: 0]  R2_input;
//   input  [31: 0]  data_read_fDM;
//   input  [31: 0]  Instr1_fIM;
//   input  [31: 0]  Instr2_fIM;
input [255: 0]  block_read_fDM;
input [255: 0]  block_read_fIM;
input 	   	CLK;
input           RESET;
input	       do_delay_syscall;

//connecting wires (signals passing through more than 1 stage)
/* iCache */
wire	 		[31: 0] Instr1_fIC/*verilator public*/;
wire	 		[31: 0] Instr2_fIC/*verilator public*/;
wire 			[ 1: 0] MVECT/*verilator public*/;
wire          			IMISS;
wire           			single_fetch_iCache;

/* dCache */
wire 			[31: 0] data_read_fDC;
wire 			[ 1: 0] DataWriteMode;
wire           			DMISS;

/* ROB */
wire           			FREEZE/*verilator public*/;
wire		  		empty_ROB/*verilator public*/;
wire		  		full_ROB;
wire 			[ 5: 0] ROB_tail;
wire 			[ 5: 0] ROB_head;
wire 	   [ROB_ENTRY_SIZE-1:0] data_out_fROB;
wire			[ 5: 0] reg_counter;

/* IF */
wire 			[31: 0] Instr_address_2IM/*verilator public*/;
wire 			[31: 0] Instr1_IFID/*verilator public*/;
wire 			[31: 0] Instr2_IFID/*verilator public*/;
wire   [DECODE_ENTRY_SIZE-1: 0] decode_entry_2FIFO;
wire                            do_write_IDQUEUE;

/* ID */
wire           			SYS/*verilator public*/;
wire           			do_fetch;
wire           			no_fetch/*verilator public*/;
wire           			single_fetch_IDIF/*verilator public*/;
wire   			[31: 0] R2_output_ID/*verilator public*/;
wire				jump_inst;
wire   [RENAME_ENTRY_SIZE-1: 0] rename_entry_2FIFO;
wire                            do_read_IDQUEUE;
wire                            do_write_RNQUEUE;

/* RegFile */
wire 			[31: 0] Reg_ID [0:REG_SIZE-1]/*verilator public*/;

/* RN */
wire				empty_freelist_signal;
wire 				do_write_2ROB;
wire      [ROB_ENTRY_SIZE-1: 0] data_2ROB;
wire      [RAT_ENTRY_SIZE-2: 0] RAT_fRN [0:RAT_SIZE-1]/*verilator public*/;
//wire   	[ISSUE_ENTRY_SIZE-1: 0] issue_entry1_2FIFO;
wire   	[ISSUE_ENTRY_SIZE-1: 0] issue_entry;
wire                            do_read_RNQUEUE;
wire                            do_wirte_2ISSQ;
wire                            do_wirte_2LSQ;
wire        			do_clear_2BB;
wire			[ 5: 0] clear_index_2BB;

/* ISS */
//wire    [ISSUE_ENTRY_SIZE-1: 0] issue_entry_2ISSQUEUE;
//wire                            do_read_ISSQUEUE1;
//wire                            do_write_ISSQUEUE;

/* RR */
wire 	  [EXE_ENTRY_SIZE-1: 0] exe_entry;
//wire 	  [EXE_ENTRY_SIZE-1: 0] exe_entry_2FIFO;
//wire                            do_read_ISSQUEUE;
//wire                            do_write_EXEQUEUE;

/* RR of LS */
wire 	  [EXE_ENTRY_SIZE-1: 0] exe_entry_LS;

/* EXE */
wire 			[31: 0] aluResult1_EXEID/*verilator public*/;
wire           			do_writeback1_EXEM/*verilator public*/;
wire 			[ 5: 0] writeRegister1_EXEM/*verilator public*/;
wire 	   [MEM_ENTRY_SIZE-1:0] mem_entry;
//wire 	   [MEM_ENTRY_SIZE-1:0] mem_entry_2FIFO;
//wire                            do_read_EXEQUEUE;
//wire                            do_write_MEMQUEUE;

/* EXE of LS */
wire 			[31: 0] aluResult1_EXEID_LS/*verilator public*/;
wire           			do_writeback1_EXEM_LS/*verilator public*/;
wire 			[ 5: 0] writeRegister1_EXEM_LS/*verilator public*/;
wire 	   [MEM_ENTRY_SIZE-1:0] mem_entry_LS;

/* MEM */
wire 			[31: 0] writeData1_MID/*verilator public*/;
wire           			do_writeback1_MEMW/*verilator public*/;
wire 			[ 5: 0] writeRegister1_MEMW/*verilator public*/;
wire 			[31: 0] Instr_fMEM_ALU/*verilator public*/;
wire 				bubble_fMEM;
wire 	  [RET_ENTRY_SIZE-1: 0] retire_entry;
wire				MemRead_ALU;
wire			        MemWrite_ALU;
wire			[31: 0] data_write_2DM_ALU;
wire			[31: 0] data_address_2DM_ALU;
//wire                            do_read_MEMQUEUE;
//wire                            do_write_RETQUEUE;

/* MEM of LS */
wire 			[31: 0] writeData1_MID_LS/*verilator public*/;
wire           			do_writeback1_MEMW_LS/*verilator public*/;
wire 			[ 5: 0] writeRegister1_MEMW_LS/*verilator public*/;
wire 			[31: 0] Instr_fMEM/*verilator public*/;
wire 				bubble_fMEM_LS;
wire 	  [RET_ENTRY_SIZE-1: 0] retire_entry_LS;

/* RET */
wire                            do_writeback1_WBEXE/*verilator public*/;
wire                    [ 5: 0] writeRegister1_WBEXE/*verilator public*/;
wire                    [31: 0] writeData1_WBEXE/*verilator public*/;
wire                    [31: 0] aluResult1_WBID/*verilator public*/;
wire           			do_writeback1_WBID/*verilator public*/;
wire 			[ 5: 0] writeRegister1_WBID/*verilator public*/;
wire 			[31: 0] writeData1_WBID/*verilator public*/;
wire       [COM_ENTRY_SIZE-1:0] com_entry;
//wire       [COM_ENTRY_SIZE-1:0] com_entry_2FIFO;
//wire                            do_read_RETQUEUE;
//wire                            do_write_COMQUEUE;

/* RET of LS */
wire                            do_writeback1_WBEXE_LS/*verilator public*/;
wire                    [ 5: 0] writeRegister1_WBEXE_LS/*verilator public*/;
wire                    [31: 0] writeData1_WBEXE_LS/*verilator public*/;
wire                    [31: 0] aluResult1_WBID_LS/*verilator public*/;
wire           			do_writeback1_WBID_LS/*verilator public*/;
wire 			[ 5: 0] writeRegister1_WBID_LS/*verilator public*/;
wire 			[31: 0] writeData1_WBID_LS/*verilator public*/;
wire       [COM_ENTRY_SIZE-1:0] com_entry_LS;

/* COM */
wire                            do_reclaim_OUT;
wire                    [ 5: 0] reclaimed_reg_OUT;
wire                            mispredict_OUT/*verilator public*/;
wire                            flush_fCOM;
wire                    [31: 0] nexInstAddr_OUT;
wire       [RAT_ENTRY_SIZE-1:0] RAT_OUT [0:RAT_SIZE-1];
wire                            do_read_2ROB;
wire				do_remend_ROB;
wire			[64: 0] remend_data_2ROB;
wire			[ 5: 0] remend_index_2ROB;
wire				do_remend_ROB_LS;
wire			[64: 0] remend_data_2ROB_LS;
wire			[ 5: 0] remend_index_2ROB_LS;

//wire                            do_read_COMQUEUE;


/* FIFO Queue, for pipeline register */
wire   [DECODE_ENTRY_SIZE-1: 0] decode_entry_fFIFO;
wire                            empty_IDQUEUE;
wire                            full_IDQUEUE;
wire   [RENAME_ENTRY_SIZE-1: 0] rename_entry_fFIFO;
wire                            empty_RNQUEUE;
wire                            full_RNQUEUE;
wire    [ISSUE_ENTRY_SIZE-1: 0] out_issue_entry;
wire				do_issue_out;
wire				full_issqueue;
wire				empty_issqueue;
wire 	         [BB_SIZE-1: 0] BB;
wire    [ISSUE_ENTRY_SIZE-1: 0] data_out_fLSQ;
wire				empty_LSQ;
wire				full_LSQ;
wire				do_issue_LS;

/*
wire    [ISSUE_ENTRY_SIZE-1: 0] issue_entry1_fFIFO;
wire                            empty_ISSQUEUE1;
wire                            full_ISSQUEUE1;
wire    [ISSUE_ENTRY_SIZE-1: 0] issue_entry2_fFIFO;
wire                            empty_ISSQUEUE2;
wire                            full_ISSQUEUE2;
wire      [EXE_ENTRY_SIZE-1: 0] exe_entry_fFIFO;
wire                            empty_EXEQUEUE;
wire                            full_EXEQUEUE;
wire       [MEM_ENTRY_SIZE-1:0] mem_entry_fFIFO;
wire                            empty_MEMQUEUE;
wire                            full_MEMQUEUE;
wire      [RET_ENTRY_SIZE-1: 0] retire_entry_fFIFO;
wire                            empty_RETQUEUE;
wire                            full_RETQUEUE;
wire       [COM_ENTRY_SIZE-1:0] com_entry_fFIFO;
wire                            empty_COMQUEUE;
wire                            full_COMQUEUE;
*/

/* for test FIFO queue */
reg			[4: 0] timer;
wire				PSEUDO_FREEZE;

wire				debug_2SIM/*verilator public*/;
reg 			[15: 0] debugs;
reg 			[15: 0] debugs_LS;
/*
 *			 1 1 1 1 1 1
 *	 		 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
 *			+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *			|s|M|I|F|R|d|i|C|R|M|E|R|I|R|I|I|
 *			|i|I|S|I|O|$|$|O|E|E|X|R|S|N|D|F|
 *			|m|P|S|F|B| | |M|T|M|E| |S| | | |
 *			| |S|Q|O| | | | | | | | | | | | |
 *			+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 */
//assign debugs =      16'b0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0;
//assign debugs =      16'b0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1;
//assign debugs =      16'b0_0_0_0_1_0_0_1_0_0_0_1_0_1_0_1;
//assign debugs =      16'b1_1_1_1_1_1_1_1_1_1_1_1_1_1_1_1;
assign debug_2SIM = debugs[15];

/*
 *			 1 1 1 1 1 1
 *	 		 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
 *			+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 *			| | |L| | | | | |R|M|E|R| | | | |
 *			| | |S| | | | | |E|E|X|R| | | | |
 *			| | |Q| | | | | |T|M|E| | | | | |
 *			| | | | | | | | | | | | | | | | |
 *			+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
 */
assign debugs_LS=    16'b0_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0;
//assign debugs_LS=    16'b0_0_1_0_0_0_0_0_1_0_0_0_0_0_0_0;

assign do_fetch 		= ~no_fetch;
assign FREEZE 			= DMISS | IMISS;
assign DataWriteMode 		= (Instr_fMEM[31: 26]==40)? 2'b01: ((Instr_fMEM[31: 26]==41)? 2'b10: 2'b00);
assign single_fetch_iCache 	= single_fetch_IDIF;
assign PSEUDO_FREEZE 		= (timer > 25);


iCache iCache1 (
	.CLK(CLK),
	.RESET(RESET),
	.SYS(SYS),
	.dread(do_fetch),
	.bread(iBlkRead),
	.bwrite(iBlkWrite),
	.address(Instr_address_2IM),
	.block_in(block_read_fIM),
	.block_out(block_write_2IM),
	.data_out1(Instr1_fIC),
	.data_out2(Instr2_fIC),
	.busy(IMISS),
	.miss(MVECT),
	.mispredict(mispredict_OUT),
	.debug(debugs[9])
);

dCache dCache1 (
	.CLK(CLK),
	.RESET(RESET),
	.SYS(SYS),
	.dread(MemRead),
	.dwrite(MemWrite),
	.dwmode(DataWriteMode),
	.bread(dBlkRead),
	.bwrite(dBlkWrite),
	.address(data_address_2DM),
	.data_in(data_write_2DM),
	.block_in(block_read_fDM),
	.block_out(block_write_2DM),
	.data_out(data_read_fDC),
	.busy(DMISS),
	.debug(debugs[10])
);


   integer n;
   always @ (posedge CLK) begin
     //$display("[%d] %x %x %x %x %x %x %x", n, SYS, do_fetch, iBlkRead, iBlkWrite, Instr_address_2IM, Instr1_fIC, IMISS);
     if(!FREEZE && do_fetch) begin
       //if(!single_fetch_iCache && Instr2_fIC != Instr2_fIM) begin
         //$display("[%d] @%x (%x) %x != %x", n, Instr_address_2IM, MVECT, Instr2_fIC, Instr2_fIM);
         //$stop();
       //end
     end
     n = n+1;
   end

always @ (posedge CLK or negedge RESET) begin
	if (!RESET) begin
		timer <= 0;
	end
	else begin
		timer <= timer + 1;
	end

	/*
	if (debugs[14]) begin
		$display("[MIPS]:\tIMISS=%d\tDMISS=%d\tSYS=%d", IMISS, DMISS, SYS);
	end
	*/
end

ROB ROB1(
	.CLK				(CLK),
	.RESET				(RESET),
	.FREEZE				(0),
        /* output */
	.empty_queue			(empty_ROB),
	.full_queue			(full_ROB),
	.data_out			(data_out_fROB),
	.tail				(ROB_tail),
	.head				(ROB_head),
	.reg_counter			(reg_counter),
        /* input */
	.do_write			(do_write_2ROB),
	.do_read			(do_read_2ROB),
	.data_in			(data_2ROB),
	.mispredict			(mispredict_OUT),
        .flush_fCOM			(flush_fCOM),
        .do_remend_ROB			(do_remend_ROB),
        .remend_data			(remend_data_2ROB),
        .remend_index			(remend_index_2ROB),
	.do_remend_ROB_LS		(do_remend_ROB_LS),
        .remend_data_LS			(remend_data_2ROB_LS),
        .remend_index_LS		(remend_index_2ROB_LS),
	.debug				(debugs[11])
);


// Pipeline Stages Instantiation
IF IF1( 
	.CLK				(CLK),
	.RESET				(RESET),
	.FREEZE				(IMISS),
        //.FREEZE                         (FREEZE || PSEUDO_FREEZE),
        /* output */
        .Instr_address_2IM		(Instr_address_2IM),
        .decode_entry			(decode_entry_2FIFO),
        .do_write_IDQUEUE               (do_write_IDQUEUE),
        /* input */
        .nextInstruction_address	(nexInstAddr_OUT),
        .mispredict			(mispredict_OUT),
        .flush_fCOM			(flush_fCOM),
        .PC_init			(PC_init),
        .Instr1_fIM			(Instr1_fIC),
        .Instr1_PR			(Instr1_IFID),
        .Instr2_PR			(Instr2_IFID),
        //.single_fetch			(),
        .no_new_fetch			(no_fetch),
	.do_delay_syscall		(do_delay_syscall),
	.jump_inst			(jump_inst),
        .full_IDQUEUE                   (full_IDQUEUE),
        //.fetchNull2			(),
        .debug				(debugs[0])
);

ID_Queue ID_Queue1(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (0),
        /* output */
        .empty_FIFO                     (empty_IDQUEUE),
        .full_FIFO                      (full_IDQUEUE),
        .data_out                       (decode_entry_fFIFO),
        /* input */
        .do_write                       (do_write_IDQUEUE),
        .do_read                        (do_read_IDQUEUE),
        .data_in                        (decode_entry_2FIFO),
        .mispredict                     (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        .debug                          (debugs[12])
);

ID ID1(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (0),
        //.FREEZE                         (PSEUDO_FREEZE),
        /* output */
        .single_fetch_OUT               (single_fetch_IDIF),
        .R2_output_PR                   (R2_output_ID),
        .rename_entry                   (rename_entry_2FIFO),
        .insertBubble_OUT               (no_fetch),
        .SYS_OUT                        (SYS),
	.jump_inst			(jump_inst),
        .do_write_RNQUEUE               (do_write_RNQUEUE),
        .do_read_IDQUEUE                (do_read_IDQUEUE),
	.empty_ROB			(empty_ROB),
        /* input */
        .R2_input                       (R2_input),
        .decode_entry                   (decode_entry_fFIFO),
        .mispredict                     (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        .empty_IDQUEUE                  (empty_IDQUEUE),
        .full_RNQUEUE                   (full_RNQUEUE),
        .debug                          (debugs[1])
);

RN_Queue RN_Queue1(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (0),
        /* output */
        .empty_FIFO                     (empty_RNQUEUE),
        .full_FIFO                      (full_RNQUEUE),
        .data_out                       (rename_entry_fFIFO),
        /* input */
        .do_write                       (do_write_RNQUEUE),
        .do_read                        (do_read_RNQUEUE),
        .data_in                        (rename_entry_2FIFO),
        .mispredict                     (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        .debug                          (debugs[12])
);

RegFile RegFile1(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (0),
        /* output */
        .Reg				(Reg_ID),
        /* input */
	.RAT_fRN			(RAT_fRN),
        .do_writeback1_RET		(do_writeback1_WBID),
        .writeRegister1_RET		(writeRegister1_WBID),
        .writeData1_RET			(writeData1_WBID),
        .do_writeback1_LS_RET		(do_writeback1_WBID_LS),
        .writeRegister1_LS_RET		(writeRegister1_WBID_LS),
        .writeData1_LS_RET		(writeData1_WBID_LS),
	.debug				(debugs[4])
);

RN RN1(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (0),
        /* output */
        .empty_freelist_signal          (empty_freelist_signal),
        .issue_entry                    (issue_entry),
        .do_write_2ROB                  (do_write_2ROB),
        .ROB_entry                      (data_2ROB),
        .RAT_fRN                        (RAT_fRN),
        .do_read_RNQUEUE                (do_read_RNQUEUE),
        .do_wirte_2ISSQ              	(do_wirte_2ISSQ),
        .do_wirte_2LSQ              	(do_wirte_2LSQ),
        .do_clear_2BB			(do_clear_2BB),
        .clear_index_2BB		(clear_index_2BB),
        /* input */
        .rename_entry                   (rename_entry_fFIFO),
        .do_reclaim                     (do_reclaim_OUT),
        .reclaimed_reg                  (reclaimed_reg_OUT),
        .do_copy_RAT                    (mispredict_OUT),
        .old_RAT                        (RAT_OUT),
        .mispredict                     (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        .full_ROB                       (full_ROB),
        .ROB_tail                       (ROB_tail),
        .ROB_head                       (ROB_head),
        .reg_counter                    (reg_counter),
        .empty_RNQUEUE                  (empty_RNQUEUE),
        .full_ISSQ                  	(full_issqueue),
        .full_LSQ                  	(full_LSQ),
        .debug                          (debugs[2])
);

/* data path1 */
ISSUE_QUEUE ISSUE_QUEUE_ALU(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (0),
        /* output */
	.BB				(BB),
        .do_issue_out			(do_issue_out),
        .out_entry			(out_issue_entry),
        .full				(full_issqueue),
        .empty				(empty_issqueue),
        /* input */
        .do_write			(do_wirte_2ISSQ),
        .write_data			(issue_entry),
        .mispredict			(mispredict_OUT),
	.flush_fCOM			(flush_fCOM),
        .do_writeback1_WB		(do_writeback1_WBID),
        .writeReg1_phy_WB		(writeRegister1_WBID),
        .do_writeback1_WB_LS		(do_writeback1_WBID_LS),
        .writeReg1_phy_WB_LS		(writeRegister1_WBID_LS),
        .do_clear_2BB			(do_clear_2BB),
        .clear_index_2BB		(clear_index_2BB),
        .debug				(debugs[13])
);

RR RR_ALU(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (0),
        /* output */
        .exe_entry                      (exe_entry),
        //.do_read_ISSQUEUE               (do_read_ISSQUEUE),
        //.do_write_EXEQUEUE              (do_write_EXEQUEUE),
        /* input */
        .Reg                            (Reg_ID),
        .R2_input                       (R2_input),
        .aluResult1_EXE                 (aluResult1_EXEID),
        .do_writeback1_MEM              (do_writeback1_EXEM),
        .writeRegister1_MEM             (writeRegister1_EXEM),
        .Data1_MEM                      (writeData1_MID),
        .do_writeback1_RET              (do_writeback1_WBID),
        .writeRegister1_RET             (writeRegister1_WBID),
        .Data1_RET                      (writeData1_WBID),
        .writeData1_RET                 (writeData1_WBID),
        .mispredict                     (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        .issue_entry                    (out_issue_entry),
        .RAT_fRN                        (RAT_fRN),
        //.empty_ISSQUEUE                 (empty_ISSQUEUE2),
        //.full_EXEQUEUE                  (full_EXEQUEUE),
        .debug                          (debugs[4])
);

EXE EXE_ALU(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (0),
        /* output */
        .aluResult1_OUT                 (aluResult1_EXEID),
        .mem_entry                      (mem_entry),
        .do_writeback1_PR               (do_writeback1_EXEM),
        .writeRegister1_PR              (writeRegister1_EXEM),
        //.do_read_EXEQUEUE               (do_read_EXEQUEUE),
        //.do_write_MEMQUEUE              (do_write_MEMQUEUE),
        /* input */
        .exe_entry                      (exe_entry),
        .do_writeback1_MEM              (do_writeback1_MEMW),
        .writeRegister1_MEM             (writeRegister1_MEMW),
        .Data1_MEM                      (writeData1_WBID),
        .do_writeback1_RET              (do_writeback1_WBEXE),
        .writeRegister1_RET             (writeRegister1_WBEXE),
        .Data1_RET                      (writeData1_WBEXE),
        .mispredict                     (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        //.empty_EXEQUEUE                 (empty_EXEQUEUE),
        //.full_MEMQUEUE                  (full_MEMQUEUE),
        .debug                          (debugs[5])
);

MEM MEM_ALU(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (0),
        /* output */
        .MemRead_2DM                    (MemRead_ALU),
        .MemWrite_2DM                   (MemWrite_ALU),
        .data_write_2DM                 (data_write_2DM_ALU),
        .data_address_2DM               (data_address_2DM_ALU),
        .Instr_OUT                      (Instr_fMEM_ALU),
        .writeRegister1_PR              (writeRegister1_MEMW),
        .do_writeback1_PR               (do_writeback1_MEMW),
        .Data1_2ID                      (writeData1_MID),
        .bubble_MEM                     (bubble_fMEM),
        .retire_entry                   (retire_entry),
        //.do_read_MEMQUEUE               (do_read_MEMQUEUE),
        //.do_write_RETQUEUE              (do_write_RETQUEUE),
        /* input */
        .do_writeback1_RET              (do_writeback1_WBID),
        .writeRegister1_RET             (writeRegister1_WBID),
        .writeData1_RET                 (writeData1_WBID),
        .mispredict                     (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        .mem_entry                      (mem_entry),
        .data_read_fDM                  (data_read_fDC),
        //.empty_MEMQUEUE                 (empty_MEMQUEUE),
        //.full_RETQUEUE                  (full_RETQUEUE),
        .debug                          (debugs[6])
);

RET RET_ALU (
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (0),
        /* output */
        .writeData1_OUT                 (writeData1_WBID),
        .aluResult1_OUT                 (aluResult1_WBID),
        .writeData1_PR                  (writeData1_WBEXE),
        .writeRegister1_PR              (writeRegister1_WBEXE),
        .writeRegister1_OUT             (writeRegister1_WBID),
        .do_writeback1_OUT              (do_writeback1_WBID),
        .do_writeback1_PR               (do_writeback1_WBEXE),
        .com_entry                      (com_entry),
        //.do_read_RETQUEUE               (do_read_RETQUEUE),
        //.do_write_COMQUEUE              (do_write_COMQUEUE),
        /* input */
        .retire_entry                   (retire_entry),
        .mispredict                     (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        //.empty_RETQUEUE                 (empty_RETQUEUE),
        //.full_COMQUEUE                  (full_COMQUEUE),
        .debug                          (debugs[7])
);

/* data path 2 */
LSQ LSQ_LS(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (0),
        /* output */
        .empty_FIFO			(empty_LSQ),
        .full_FIFO			(full_LSQ),
        .data_out			(data_out_fLSQ),
	.do_issue			(do_issue_LS),
        /* input */
	.DMISS				(DMISS),
	.BB				(BB),
	.ROB_head			(ROB_head),
        .do_write			(do_wirte_2LSQ),
        .data_in			(issue_entry),
        .mispredict			(mispredict_OUT),
        .flush_fCOM			(flush_fCOM),
        .debug				(debugs_LS[13])
);

RR RR_LS(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (DMISS),
        /* output */
        .exe_entry                      (exe_entry_LS),
        /* input */
        .Reg                            (Reg_ID),
        .R2_input                       (R2_input),
        .aluResult1_EXE                 (0),
        .do_writeback1_MEM              (0),
        .writeRegister1_MEM             (0),
        .Data1_MEM                      (0),
        .do_writeback1_RET              (0),
        .writeRegister1_RET             (0),
        .Data1_RET                      (0),
        .writeData1_RET                 (0),
        .mispredict                     (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        .issue_entry                    (data_out_fLSQ),
        .RAT_fRN                        (RAT_fRN),
        //.empty_ISSQUEUE                 (empty_ISSQUEUE2),
        //.full_EXEQUEUE                  (full_EXEQUEUE),
        .debug                          (debugs_LS[4])
);

EXE EXE_LS(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (DMISS),
        /* output */
        .aluResult1_OUT                 (aluResult1_EXEID_LS),
        .mem_entry                      (mem_entry_LS),
        .do_writeback1_PR               (do_writeback1_EXEM_LS),
        .writeRegister1_PR              (writeRegister1_EXEM_LS),
        /* input */
        .exe_entry                      (exe_entry_LS),
        .do_writeback1_MEM              (0),
        .writeRegister1_MEM             (0),
        .Data1_MEM                      (0),
        .do_writeback1_RET              (0),
        .writeRegister1_RET             (0),
        .Data1_RET                      (0),
        .mispredict                     (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        .debug                          (debugs_LS[5])
);

MEM MEM_LS(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (DMISS),
        /* output */
        .MemRead_2DM                    (MemRead),
        .MemWrite_2DM                   (MemWrite),
        .data_write_2DM                 (data_write_2DM),
        .data_address_2DM               (data_address_2DM),
        .Instr_OUT                      (Instr_fMEM),
        .writeRegister1_PR              (writeRegister1_MEMW_LS),
        .do_writeback1_PR               (do_writeback1_MEMW_LS),
        .Data1_2ID                      (writeData1_MID_LS),
        .bubble_MEM                     (bubble_fMEM_LS),
        .retire_entry                   (retire_entry_LS),
        /* input */
        .do_writeback1_RET              (0),
        .writeRegister1_RET             (0),
        .writeData1_RET                 (0),
        .mispredict                     (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        .mem_entry                      (mem_entry_LS),
        .data_read_fDM                  (data_read_fDC),
        .debug                          (debugs_LS[6])
);

RET RET_LS (
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (DMISS),
        /* output */
        .writeData1_OUT                 (writeData1_WBID_LS),
        .aluResult1_OUT                 (aluResult1_WBID_LS),
        .writeData1_PR                  (writeData1_WBEXE_LS),
        .writeRegister1_PR              (writeRegister1_WBEXE_LS),
        .writeRegister1_OUT             (writeRegister1_WBID_LS),
        .do_writeback1_OUT              (do_writeback1_WBID_LS),
        .do_writeback1_PR               (do_writeback1_WBEXE_LS),
        .com_entry                      (com_entry_LS),
        /* input */
        .retire_entry                   (retire_entry_LS),
        .mispredict                     (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        .debug                          (debugs_LS[7])
);

COM COM1(
        .CLK                            (CLK),
        .RESET                          (RESET),
        .FREEZE                         (0),
        /* output */
        .do_reclaim_OUT                 (do_reclaim_OUT),
        .reclaimed_reg_OUT              (reclaimed_reg_OUT),
        .mispredict_OUT                 (mispredict_OUT),
        .flush_fCOM                     (flush_fCOM),
        .nexInstAddr_OUT                (nexInstAddr_OUT),
        .RAT_OUT                        (RAT_OUT),
        .do_read_ROB                    (do_read_2ROB),
	.do_remend_ROB			(do_remend_ROB),
        .remend_data			(remend_data_2ROB),
        .remend_index			(remend_index_2ROB),
        .do_remend_ROB_LS		(do_remend_ROB_LS),
        .remend_data_LS			(remend_data_2ROB_LS),
        .remend_index_LS		(remend_index_2ROB_LS),
        //.do_read_COMQUEUE               (do_read_COMQUEUE),
        /* input */
        .ROB_head                       (ROB_head),
        .empty_ROB                      (empty_ROB),
	.ROB_entry			(data_out_fROB),
        .com_entry                      (com_entry),
        .com_entry_LS                   (com_entry_LS),
        //.empty_COMQUEUE                 (empty_COMQUEUE),
        .debug                          (debugs[8])
);

endmodule
