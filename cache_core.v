/**********************************************************/
/*                    cache core module                   */
/*  This is a basic block for constructing cache mosules  */
/*                ---------<<<()>>>---------              */
/*                                                        */
/*             +-------+-------+-------+                  */
/*  address  : | tbits | ibits | bbits |                  */
/*             +-------+-------+-------+                  */
/*  tbits = abits - ibits - bbits                         */
/*                                                        */
/*  data_in & data_out are of size dsize                  */
/*                                                        */
/*  block_in & block_out are of size bsize                */
/**********************************************************/

`timescale 1ns/1ps

module cache_core (	CLK,
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
			hit);

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
	input  [asize-1: 0] address;
	input  [dsize-1: 0] data_in;
	input  [bsize-1: 0] block_in;
	output [bsize-1: 0] block_out;
	output [dsize-1: 0] data_out;
	output              hit;

	// memory part
	reg    [isize-1: 0] valid;
	reg    [isize-1: 0] dirty;
	reg    [tbits-1: 0] tags   [isize-1: 0];
	reg    [bsize-1: 0] blocks [isize-1: 0];

	// wires
	wire   [bbits-1: 0] offset;
	wire   [ibits-1: 0] index;
	wire   [tbits-1: 0] tag;

	assign offset = address[bbits-1: 0];
	assign index  = address[ibits+bbits-1: bbits];
	assign tag    = address[asize-1: ibits+bbits];
	assign hit    = (tags[index] == tag)&&valid[index];

	// read content of the cache
	assign block_out = blocks[index];
	always @ (block_out or offset)
	begin
		case(offset)
			// Word Aligned
			5'b00000: begin data_out = block_out[bsize-     1: bsize-     dsize]; end
			5'b00100: begin data_out = block_out[bsize- 4*8-1: bsize- 4*8-dsize]; end
			5'b01000: begin data_out = block_out[bsize- 8*8-1: bsize- 8*8-dsize]; end
			5'b01100: begin data_out = block_out[bsize-12*8-1: bsize-12*8-dsize]; end
			5'b10000: begin data_out = block_out[bsize-16*8-1: bsize-16*8-dsize]; end
			5'b10100: begin data_out = block_out[bsize-20*8-1: bsize-20*8-dsize]; end
			5'b11000: begin data_out = block_out[bsize-24*8-1: bsize-24*8-dsize]; end
			5'b11100: begin data_out = block_out[bsize-28*8-1: bsize-28*8-dsize]; end

			// Half-Word Aligned
			5'b00010: begin data_out = block_out[bsize-     1: bsize-     dsize]; end
			5'b00110: begin data_out = block_out[bsize- 4*8-1: bsize- 4*8-dsize]; end
			5'b01010: begin data_out = block_out[bsize- 8*8-1: bsize- 8*8-dsize]; end
			5'b01110: begin data_out = block_out[bsize-12*8-1: bsize-12*8-dsize]; end
			5'b10010: begin data_out = block_out[bsize-16*8-1: bsize-16*8-dsize]; end
			5'b10110: begin data_out = block_out[bsize-20*8-1: bsize-20*8-dsize]; end
			5'b11010: begin data_out = block_out[bsize-24*8-1: bsize-24*8-dsize]; end
			5'b11110: begin data_out = block_out[bsize-28*8-1: bsize-28*8-dsize]; end

			// Byte Aligned
			5'b00001: begin data_out = block_out[bsize-     1: bsize-     dsize]; end
			5'b00101: begin data_out = block_out[bsize- 4*8-1: bsize- 4*8-dsize]; end
			5'b01001: begin data_out = block_out[bsize- 8*8-1: bsize- 8*8-dsize]; end
			5'b01101: begin data_out = block_out[bsize-12*8-1: bsize-12*8-dsize]; end
			5'b10001: begin data_out = block_out[bsize-16*8-1: bsize-16*8-dsize]; end
			5'b10101: begin data_out = block_out[bsize-20*8-1: bsize-20*8-dsize]; end
			5'b11001: begin data_out = block_out[bsize-24*8-1: bsize-24*8-dsize]; end
			5'b11101: begin data_out = block_out[bsize-28*8-1: bsize-28*8-dsize]; end

			5'b00011: begin data_out = block_out[bsize-     1: bsize-     dsize]; end
			5'b00111: begin data_out = block_out[bsize- 4*8-1: bsize- 4*8-dsize]; end
			5'b01011: begin data_out = block_out[bsize- 8*8-1: bsize- 8*8-dsize]; end
			5'b01111: begin data_out = block_out[bsize-12*8-1: bsize-12*8-dsize]; end
			5'b10011: begin data_out = block_out[bsize-16*8-1: bsize-16*8-dsize]; end
			5'b10111: begin data_out = block_out[bsize-20*8-1: bsize-20*8-dsize]; end
			5'b11011: begin data_out = block_out[bsize-24*8-1: bsize-24*8-dsize]; end
			5'b11111: begin data_out = block_out[bsize-28*8-1: bsize-28*8-dsize]; end
		endcase

//		if(dread & hit)
//			$display("[$Core] data_out:%x", data_out);

	end

	// update content of the cache
	always @ (posedge CLK)
	begin
		if(!RESET | SYS)
		begin
			valid = 0;
			dirty = 0;
		end
		else
		begin
			if(dwrite && hit)
			begin
				case(offset)
					// Word, Half-word, Byte
					5'b00000: begin if(dwmode == 2'b01) blocks[index][bsize-     1: bsize-     8] = data_in[7: 0]; else if(dwmode == 2'b10) blocks[index][bsize-     1: bsize-     16] = data_in[15: 0]; else blocks[index][bsize-     1: bsize-     dsize] = data_in; end
					5'b00100: begin if(dwmode == 2'b01) blocks[index][bsize- 4*8-1: bsize- 4*8-8] = data_in[7: 0]; else if(dwmode == 2'b10) blocks[index][bsize- 4*8-1: bsize- 4*8-16] = data_in[15: 0]; else blocks[index][bsize- 4*8-1: bsize- 4*8-dsize] = data_in; end
					5'b01000: begin if(dwmode == 2'b01) blocks[index][bsize- 8*8-1: bsize- 8*8-8] = data_in[7: 0]; else if(dwmode == 2'b10) blocks[index][bsize- 8*8-1: bsize- 8*8-16] = data_in[15: 0]; else blocks[index][bsize- 8*8-1: bsize- 8*8-dsize] = data_in; end
					5'b01100: begin if(dwmode == 2'b01) blocks[index][bsize-12*8-1: bsize-12*8-8] = data_in[7: 0]; else if(dwmode == 2'b10) blocks[index][bsize-12*8-1: bsize-12*8-16] = data_in[15: 0]; else blocks[index][bsize-12*8-1: bsize-12*8-dsize] = data_in; end
					5'b10000: begin if(dwmode == 2'b01) blocks[index][bsize-16*8-1: bsize-16*8-8] = data_in[7: 0]; else if(dwmode == 2'b10) blocks[index][bsize-16*8-1: bsize-16*8-16] = data_in[15: 0]; else blocks[index][bsize-16*8-1: bsize-16*8-dsize] = data_in; end
					5'b10100: begin if(dwmode == 2'b01) blocks[index][bsize-20*8-1: bsize-20*8-8] = data_in[7: 0]; else if(dwmode == 2'b10) blocks[index][bsize-20*8-1: bsize-20*8-16] = data_in[15: 0]; else blocks[index][bsize-20*8-1: bsize-20*8-dsize] = data_in; end
					5'b11000: begin if(dwmode == 2'b01) blocks[index][bsize-24*8-1: bsize-24*8-8] = data_in[7: 0]; else if(dwmode == 2'b10) blocks[index][bsize-24*8-1: bsize-24*8-16] = data_in[15: 0]; else blocks[index][bsize-24*8-1: bsize-24*8-dsize] = data_in; end
					5'b11100: begin if(dwmode == 2'b01) blocks[index][bsize-28*8-1: bsize-28*8-8] = data_in[7: 0]; else if(dwmode == 2'b10) blocks[index][bsize-28*8-1: bsize-28*8-16] = data_in[15: 0]; else blocks[index][bsize-28*8-1: bsize-28*8-dsize] = data_in; end

					// Half-word, Byte
					5'b00010: begin if(dwmode == 2'b01) blocks[index][bsize- 2*8-1: bsize- 2*8-8] = data_in[7: 0]; else blocks[index][bsize- 2*8-1: bsize- 2*8-16] = data_in[15: 0]; end
					5'b00110: begin if(dwmode == 2'b01) blocks[index][bsize- 6*8-1: bsize- 6*8-8] = data_in[7: 0]; else blocks[index][bsize- 6*8-1: bsize- 6*8-16] = data_in[15: 0]; end
					5'b01010: begin if(dwmode == 2'b01) blocks[index][bsize-10*8-1: bsize-10*8-8] = data_in[7: 0]; else blocks[index][bsize-10*8-1: bsize-10*8-16] = data_in[15: 0]; end
					5'b01110: begin if(dwmode == 2'b01) blocks[index][bsize-14*8-1: bsize-14*8-8] = data_in[7: 0]; else blocks[index][bsize-14*8-1: bsize-14*8-16] = data_in[15: 0]; end
					5'b10010: begin if(dwmode == 2'b01) blocks[index][bsize-18*8-1: bsize-18*8-8] = data_in[7: 0]; else blocks[index][bsize-18*8-1: bsize-18*8-16] = data_in[15: 0]; end
					5'b10110: begin if(dwmode == 2'b01) blocks[index][bsize-22*8-1: bsize-22*8-8] = data_in[7: 0]; else blocks[index][bsize-22*8-1: bsize-22*8-16] = data_in[15: 0]; end
					5'b11010: begin if(dwmode == 2'b01) blocks[index][bsize-26*8-1: bsize-26*8-8] = data_in[7: 0]; else blocks[index][bsize-26*8-1: bsize-26*8-16] = data_in[15: 0]; end
					5'b11110: begin if(dwmode == 2'b01) blocks[index][bsize-30*8-1: bsize-30*8-8] = data_in[7: 0]; else blocks[index][bsize-30*8-1: bsize-30*8-16] = data_in[15: 0]; end

					// Byte
					5'b00001: begin blocks[index][bsize- 1*8-1: bsize- 1*8-8] = data_in[7: 0]; end
					5'b00101: begin blocks[index][bsize- 5*8-1: bsize- 5*8-8] = data_in[7: 0]; end
					5'b01001: begin blocks[index][bsize- 9*8-1: bsize- 9*8-8] = data_in[7: 0]; end
					5'b01101: begin blocks[index][bsize-13*8-1: bsize-13*8-8] = data_in[7: 0]; end
					5'b10001: begin blocks[index][bsize-17*8-1: bsize-17*8-8] = data_in[7: 0]; end
					5'b10101: begin blocks[index][bsize-21*8-1: bsize-21*8-8] = data_in[7: 0]; end
					5'b11001: begin blocks[index][bsize-25*8-1: bsize-25*8-8] = data_in[7: 0]; end
					5'b11101: begin blocks[index][bsize-29*8-1: bsize-29*8-8] = data_in[7: 0]; end

					5'b00011: begin blocks[index][bsize- 3*8-1: bsize- 3*8-8] = data_in[7: 0]; end
					5'b00111: begin blocks[index][bsize- 7*8-1: bsize- 7*8-8] = data_in[7: 0]; end
					5'b01011: begin blocks[index][bsize-11*8-1: bsize-11*8-8] = data_in[7: 0]; end
					5'b01111: begin blocks[index][bsize-15*8-1: bsize-15*8-8] = data_in[7: 0]; end
					5'b10011: begin blocks[index][bsize-19*8-1: bsize-19*8-8] = data_in[7: 0]; end
					5'b10111: begin blocks[index][bsize-23*8-1: bsize-23*8-8] = data_in[7: 0]; end
					5'b11011: begin blocks[index][bsize-27*8-1: bsize-27*8-8] = data_in[7: 0]; end
					5'b11111: begin blocks[index][bsize-31*8-1: bsize-31*8-8] = data_in[7: 0]; end
				endcase

//				if(dwmode == 2'b01)
//					$display("[$Core] write byte.");
//				$display("[$Core] data_in:%d", data_in);

				dirty[index]  = 1'b1;
			end
			else if(bwrite)
			begin
				tags[index]   = tag;
				dirty[index]  = 1'b0;
				valid[index]  = 1'b1;
				blocks[index] = block_in;
//				$display("[$Core] block_in:%x", block_in);
			end
		end
	end

	// debugging
	/*always @ (posedge CLK)
	begin
		$display("[%x][%x][%x][%x]: %d", tag, index, offset, valid[index], hit);
	end/**/
endmodule
