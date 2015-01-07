/**********************************************************/
/*                    cache core module                   */
/*  This is a basic block for constructing cache mosules  */
/*                ---------<<<()>>>---------              */
/*                                                        */
/*             +-------+-------+-------+                  */
/*  address1  : | tbits | ibits | bbits |                  */
/*             +-------+-------+-------+                  */
/*  tbits = abits - ibits - bbits                         */
/*                                                        */
/*  data_in & data_out1 are of size dsize                  */
/*                                                        */
/*  block_in & block_out are of size bsize                */
/**********************************************************/

`timescale 1ns/1ps

module instr_cache_core (	CLK,
				RESET,
				SYS,
				dread,
				dwrite,
				dwmode,
				bread,
				bwrite,
				address1,
				data_in,
				block_in,
				block_out,
				data_out1,
				data_out2,
				hit1,
				hit2,
				debug);

	// configuration parameters
	parameter dsize = 32;
	parameter asize = 32;
	parameter bbits = 5;
	parameter ibits = 10;
	parameter tbits = asize - ibits - bbits;
	parameter bsize = 8<<bbits;
	parameter isize = 1<<ibits;

	// input/output ports	
	input               CLK;
	input               RESET;
	input               SYS;
	input               dread;
	input               bread;
	input               dwrite;
	input               bwrite;
	input  [      1: 0] dwmode;
	input  [asize-1: 0] address1;
	input  [dsize-1: 0] data_in;
	input  [bsize-1: 0] block_in;
	output [bsize-1: 0] block_out;
	output [dsize-1: 0] data_out1;
	output [dsize-1: 0] data_out2;
	output              hit1;
	output              hit2;

	input		    debug;

	// memory part
	reg    [isize-1: 0] valid;
	reg    [isize-1: 0] dirty;
	reg    [tbits-1: 0] tags   [isize-1: 0];
	reg    [bsize-1: 0] blocks [isize-1: 0];

	// wires
	wire   [bbits-1: 0] offset1;
	wire   [ibits-1: 0] index1;
	wire   [tbits-1: 0] tag1;
	wire   [bbits-1: 0] offset2;
	wire   [ibits-1: 0] index2;
	wire   [tbits-1: 0] tag2;
	wire   [asize-1: 0] address2;
	wire   [bsize-1: 0] block_out1;
	wire   [bsize-1: 0] block_out2;

	assign offset1     = address1[bbits-1: 0];
	assign index1      = address1[ibits+bbits-1: bbits];
	assign tag1        = address1[asize-1: ibits+bbits];
	assign hit1        = (tags[index1] == tag1)&&valid[index1];

	// read content of the cache
	assign block_out1 = blocks[index1];
	always @ (block_out1 or offset1)
	begin
		case(offset1)
			// Word Aligned
			5'b00000: begin data_out1 = block_out1[bsize-     1: bsize-     dsize]; end
			5'b00100: begin data_out1 = block_out1[bsize- 4*8-1: bsize- 4*8-dsize]; end
			5'b01000: begin data_out1 = block_out1[bsize- 8*8-1: bsize- 8*8-dsize]; end
			5'b01100: begin data_out1 = block_out1[bsize-12*8-1: bsize-12*8-dsize]; end
			5'b10000: begin data_out1 = block_out1[bsize-16*8-1: bsize-16*8-dsize]; end
			5'b10100: begin data_out1 = block_out1[bsize-20*8-1: bsize-20*8-dsize]; end
			5'b11000: begin data_out1 = block_out1[bsize-24*8-1: bsize-24*8-dsize]; end
			5'b11100: begin data_out1 = block_out1[bsize-28*8-1: bsize-28*8-dsize]; end

			// Half-Word Aligned
			5'b00010: begin data_out1 = block_out1[bsize-     1: bsize-     dsize]; end
			5'b00110: begin data_out1 = block_out1[bsize- 4*8-1: bsize- 4*8-dsize]; end
			5'b01010: begin data_out1 = block_out1[bsize- 8*8-1: bsize- 8*8-dsize]; end
			5'b01110: begin data_out1 = block_out1[bsize-12*8-1: bsize-12*8-dsize]; end
			5'b10010: begin data_out1 = block_out1[bsize-16*8-1: bsize-16*8-dsize]; end
			5'b10110: begin data_out1 = block_out1[bsize-20*8-1: bsize-20*8-dsize]; end
			5'b11010: begin data_out1 = block_out1[bsize-24*8-1: bsize-24*8-dsize]; end
			5'b11110: begin data_out1 = block_out1[bsize-28*8-1: bsize-28*8-dsize]; end

			// Byte Aligned
			5'b00001: begin data_out1 = block_out1[bsize-     1: bsize-     dsize]; end
			5'b00101: begin data_out1 = block_out1[bsize- 4*8-1: bsize- 4*8-dsize]; end
			5'b01001: begin data_out1 = block_out1[bsize- 8*8-1: bsize- 8*8-dsize]; end
			5'b01101: begin data_out1 = block_out1[bsize-12*8-1: bsize-12*8-dsize]; end
			5'b10001: begin data_out1 = block_out1[bsize-16*8-1: bsize-16*8-dsize]; end
			5'b10101: begin data_out1 = block_out1[bsize-20*8-1: bsize-20*8-dsize]; end
			5'b11001: begin data_out1 = block_out1[bsize-24*8-1: bsize-24*8-dsize]; end
			5'b11101: begin data_out1 = block_out1[bsize-28*8-1: bsize-28*8-dsize]; end

			5'b00011: begin data_out1 = block_out1[bsize-     1: bsize-     dsize]; end
			5'b00111: begin data_out1 = block_out1[bsize- 4*8-1: bsize- 4*8-dsize]; end
			5'b01011: begin data_out1 = block_out1[bsize- 8*8-1: bsize- 8*8-dsize]; end
			5'b01111: begin data_out1 = block_out1[bsize-12*8-1: bsize-12*8-dsize]; end
			5'b10011: begin data_out1 = block_out1[bsize-16*8-1: bsize-16*8-dsize]; end
			5'b10111: begin data_out1 = block_out1[bsize-20*8-1: bsize-20*8-dsize]; end
			5'b11011: begin data_out1 = block_out1[bsize-24*8-1: bsize-24*8-dsize]; end
			5'b11111: begin data_out1 = block_out1[bsize-28*8-1: bsize-28*8-dsize]; end
		endcase

//		if(dread & hit1)
//			$display("[$Core] data_out1:%x", data_out1);

	end


	assign address2    = address1;
	assign offset2     = address2[bbits-1: 0];
	assign index2      = address2[ibits+bbits-1: bbits];
	assign tag2        = address2[asize-1: ibits+bbits];
	//assign hit2        = (tags[index2] == tag2)&&valid[index2]||(index1 == index2);
	assign hit2        = 1'b1;

	assign block_out2 = blocks[index2];
	always @ (block_out2 or offset2)
	begin
		case(offset2)
			// Word Aligned
			5'b00000: begin data_out2 = block_out2[bsize-     1: bsize-     dsize]; end
			5'b00100: begin data_out2 = block_out2[bsize- 4*8-1: bsize- 4*8-dsize]; end
			5'b01000: begin data_out2 = block_out2[bsize- 8*8-1: bsize- 8*8-dsize]; end
			5'b01100: begin data_out2 = block_out2[bsize-12*8-1: bsize-12*8-dsize]; end
			5'b10000: begin data_out2 = block_out2[bsize-16*8-1: bsize-16*8-dsize]; end
			5'b10100: begin data_out2 = block_out2[bsize-20*8-1: bsize-20*8-dsize]; end
			5'b11000: begin data_out2 = block_out2[bsize-24*8-1: bsize-24*8-dsize]; end
			5'b11100: begin data_out2 = block_out2[bsize-28*8-1: bsize-28*8-dsize]; end

			// Half-Word Aligned
			5'b00010: begin data_out2 = block_out2[bsize-     1: bsize-     dsize]; end
			5'b00110: begin data_out2 = block_out2[bsize- 4*8-1: bsize- 4*8-dsize]; end
			5'b01010: begin data_out2 = block_out2[bsize- 8*8-1: bsize- 8*8-dsize]; end
			5'b01110: begin data_out2 = block_out2[bsize-12*8-1: bsize-12*8-dsize]; end
			5'b10010: begin data_out2 = block_out2[bsize-16*8-1: bsize-16*8-dsize]; end
			5'b10110: begin data_out2 = block_out2[bsize-20*8-1: bsize-20*8-dsize]; end
			5'b11010: begin data_out2 = block_out2[bsize-24*8-1: bsize-24*8-dsize]; end
			5'b11110: begin data_out2 = block_out2[bsize-28*8-1: bsize-28*8-dsize]; end

			// Byte Aligned
			5'b00001: begin data_out2 = block_out2[bsize-     1: bsize-     dsize]; end
			5'b00101: begin data_out2 = block_out2[bsize- 4*8-1: bsize- 4*8-dsize]; end
			5'b01001: begin data_out2 = block_out2[bsize- 8*8-1: bsize- 8*8-dsize]; end
			5'b01101: begin data_out2 = block_out2[bsize-12*8-1: bsize-12*8-dsize]; end
			5'b10001: begin data_out2 = block_out2[bsize-16*8-1: bsize-16*8-dsize]; end
			5'b10101: begin data_out2 = block_out2[bsize-20*8-1: bsize-20*8-dsize]; end
			5'b11001: begin data_out2 = block_out2[bsize-24*8-1: bsize-24*8-dsize]; end
			5'b11101: begin data_out2 = block_out2[bsize-28*8-1: bsize-28*8-dsize]; end

			5'b00011: begin data_out2 = block_out2[bsize-     1: bsize-     dsize]; end
			5'b00111: begin data_out2 = block_out2[bsize- 4*8-1: bsize- 4*8-dsize]; end
			5'b01011: begin data_out2 = block_out2[bsize- 8*8-1: bsize- 8*8-dsize]; end
			5'b01111: begin data_out2 = block_out2[bsize-12*8-1: bsize-12*8-dsize]; end
			5'b10011: begin data_out2 = block_out2[bsize-16*8-1: bsize-16*8-dsize]; end
			5'b10111: begin data_out2 = block_out2[bsize-20*8-1: bsize-20*8-dsize]; end
			5'b11011: begin data_out2 = block_out2[bsize-24*8-1: bsize-24*8-dsize]; end
			5'b11111: begin data_out2 = block_out2[bsize-28*8-1: bsize-28*8-dsize]; end
		endcase

//		if(dread & hit2)
//			$display("[$Core] data_out2:%x", data_out2);

	end

	// update content of the cache
	always @ (posedge CLK) begin
		if(!RESET | SYS) begin
			valid  = 0;		/* for instruction cache, no need to invalid it */ 
			dirty  = 0;
			//tags   = 0;
			//blocks = 0;
		end
		else begin
			if(bwrite) begin
				if(~hit1) begin
					tags[index1]   = tag1;
					dirty[index1]  = 1'b0;
					valid[index1]  = 1'b1;
					blocks[index1] = block_in;
					//$display("[$Core] *");
				end
				else begin
					tags[index2]   = tag2;
					dirty[index2]  = 1'b0;
					valid[index2]  = 1'b1;
					blocks[index2] = block_in;
					//$display("[$Core] **");
				end
//				$display("[$Core] block_in:%x", block_in);
			end
		end
	end
	// debugging
	/*always @ (posedge CLK)
	begin
		$display("[%x][%x][%x][%x]: %d", tag1, index1, offset1, valid[index1], hit1);
	end/**/

always @ (posedge CLK or negedge RESET) begin
	if (debug) begin
		//$display("[I$]:\tvalid=%d\ttag=%x", valid[index1], tags[index1]);
		//$display("[I$]:\tblock_in=%x", block_in);
	end
end
endmodule
