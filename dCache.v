
module dCache (	CLK,
		RESET,
		SYS,
		dread,
		dwrite,
		dwmode,
		bread,
		bwrite,
		address,
		data_in,
		block_in,
		block_out,
		data_out,
		busy,
		debug	
);

	// cache parameters
	parameter data = 32;
	parameter addr = 32;
	parameter ofst = 5;
	parameter indx = 9;
	parameter blck = 8<<ofst;
	//parameter plty = 10;
	parameter plty = 2;

	// input/output ports	
	input              CLK;
	input              RESET;
	input              SYS;
	input              dread;
	output             bread;
	input              dwrite;
	output             bwrite;
	input  [     1: 0] dwmode;
	input  [addr-1: 0] address;
	input  [data-1: 0] data_in;
	input  [blck-1: 0] block_in;
	output [blck-1: 0] block_out;
	output [data-1: 0] data_out;
	output             busy;

	input		  debug;


	// internal signals
	wire               hit0;
	wire               hit1;
	wire               bread0;
	wire               bwrite0;
	wire               bread1;
	wire               bwrite1;
	wire   [data-1: 0] data_out0;
	wire   [data-1: 0] data_out1;
	wire   [blck-1: 0] block_out0;
	wire   [blck-1: 0] block_out1;
	reg                comment;

	initial comment = 0; // shows D$ displays


	// penalty counter
	reg    [     3: 0] waitCount;
        reg    [1<<indx-1: 0] policy;

	assign busy = (dread | dwrite)&(~hit0 & ~hit1);
	assign data_out = hit0? data_out0: data_out1;
	assign bread   = (waitCount == plty-2);
	assign bwrite0 = (policy[address[indx+ofst-1: ofst]] == 1'b0)? (waitCount == plty-1): 1'b0;
	assign bwrite1 = (policy[address[indx+ofst-1: ofst]] == 1'b1)? (waitCount == plty-1): 1'b0;

	// cache controller
	always @ (posedge CLK)
	begin
		if(!RESET)
		begin
			//$display("RESET D$ ...");
			waitCount <= 4'd0;
			policy    <= 0;
		end
		else
		begin
			if(busy)
				waitCount <= waitCount+1;
			else
				waitCount <= 4'd0;

			if(dread | dwrite)
				policy[address[indx+ofst-1: ofst]] <= hit0;
		end
	end

	// cache cores
	cache_core #(data, addr, ofst, indx) cc0 (CLK, RESET, SYS, dread, dwrite, dwmode, bread0, bwrite0, address, data_in, block_in, block_out0, data_out0, hit0);
	cache_core #(data, addr, ofst, indx) cc1 (CLK, RESET, SYS, dread, dwrite, dwmode, bread1, bwrite1, address, data_in, block_in, block_out1, data_out1, hit1);

	// test and debug
	always begin
		if (comment) begin
			$display("=============================================================");
			$display("[D$]:\taddress:%x", address);
			$display("[D$]:\tdread:%x", dread);
			$display("[D$]:\tdwrite:%x", dwrite);
			$display("[D$]:\tdwmode:%x", dwmode);
			$display("[D$]:\tbusy:%x", busy);
			$display("[D$]:\twaitCount:%x", waitCount);
			//$display("[D$]:block_out0:%x\t\tblock_out1:%x", block_out0, block_out1);
			$display("[D$]:data_out0:%x\t\tdata_out1:%x", data_out0, data_out1);
			$display("[D$]:bwrite0:%x\t\tbwrite1:%x", bwrite0, bwrite1);
			$display("[D$]:hit0:%x\t\t\thit1:%x", hit0, hit1);
     		end
	end

endmodule
