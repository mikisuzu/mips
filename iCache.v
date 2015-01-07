
module iCache (	CLK,
		RESET,
		SYS,
		dread,
		bread,
		bwrite,
		address,
		block_in,
		block_out,
		data_out1,
		data_out2,
		busy,
		miss,
		mispredict,
		debug
);

	// cache parameters
	parameter data = 32;
	parameter addr = 32;
	parameter ofst = 5;
	parameter indx = 10;
	parameter blck = 8<<ofst;
	//parameter plty = 10;
	parameter plty = 2;

	// input/output ports
	input              CLK;
	input              RESET;
	input              SYS;
	input              dread;
	output             bread;
	output             bwrite;
	input  [addr-1: 0] address;
	input  [blck-1: 0] block_in;
	output [blck-1: 0] block_out;
	output [data-1: 0] data_out1;
	output [data-1: 0] data_out2;
	output             busy;
	output [     1: 0] miss;

	input	mispredict;
	input	debug;

	// internal signals
	wire               hit1;
	wire               hit2;
	wire               bread0;
	wire               bwrite0;
	wire   [blck-1: 0] block_out0;

	wire               dwrite;
	wire   [     1: 0] dwmode;
	wire   [data-1: 0] data_in;
	reg                comment;

	initial comment = 0; // shows D$ displays


	// penalty counter
	reg    [     3: 0] waitCount;

	assign dwrite = 0;
	assign dwmode = 2'b00;
	assign data_in = 0;
	assign busy = dread &(~hit1|~hit2) & ~SYS;
	assign bread   = (waitCount == plty-2);
	assign bwrite0 = (waitCount == plty-1);
	assign miss = {~hit2, ~hit1};

	// cache controller
	always @ (posedge CLK)
	begin
		if(!RESET || mispredict) begin
			//$display("RESET I$ ...");
			waitCount <= 4'd0;
		end
		else begin
			if(busy)
				waitCount <= waitCount+1;
			else
				waitCount <= 4'd0;
		end
	end

	// cache cores
	instr_cache_core #(data, addr, ofst, indx) cc0 ( CLK, RESET, SYS, 
			dread, dwrite, dwmode, bread0, bwrite0, 
			address, data_in, block_in, block_out0, 
			data_out1, data_out2, hit1, hit2,
			debug);

	// test and debug
	always @ (posedge CLK or negedge RESET) begin
		if (debug) begin
			$display("[I$]:\taddress=0x%x\twaitCount=%d", address, waitCount);
		end

		if (comment) begin
			$display("=============================================================");
			$display("[D$]:\taddress:%x", address);
			$display("[D$]:\tdread:%x", dread);
			$display("[D$]:\tdwrite:%x", dwrite);
			$display("[D$]:\tdwmode:%x", dwmode);
			$display("[D$]:\tbusy:%x", busy);
			$display("[D$]:\twaitCount:%x", waitCount);
			//$display("[D$]:block_out0:%x", block_out0);
			$display("[D$]:data_out1:%x", data_out1);
			$display("[D$]:data_out2:%x", data_out2);
			$display("[D$]:bwrite0:%x", bwrite0);
			$display("[D$]:hit1:%x", hit1);
			$display("[D$]:hit2:%x", hit2);
     		end
	end

endmodule
