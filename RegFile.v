/*
 * register file
 */
module RegFile(
	CLK,
	RESET,
	FREEZE,
	/* output */
	Reg,
	/* input */
	RAT_fRN,
	do_writeback1_RET,
	writeRegister1_RET,
	writeData1_RET,
	do_writeback1_LS_RET,
	writeRegister1_LS_RET,
	writeData1_LS_RET,
	debug
);
/*
 * parameters
 */
parameter REG_SIZE 	=  64;
parameter RAT_SIZE    	=  32;
parameter RAT_ENTRY_SIZE=   7;



/*
 * output
 */
output reg     	[31: 0] Reg [0:REG_SIZE-1];


/*
 * input
 */
input			CLK;
input			RESET;
input			FREEZE;
input                   do_writeback1_RET;
input           [ 5: 0] writeRegister1_RET;
input           [31 :0] writeData1_RET;
input                   do_writeback1_LS_RET;
input           [ 5: 0] writeRegister1_LS_RET;
input           [31 :0] writeData1_LS_RET;
input			debug;
input [RAT_ENTRY_SIZE-2: 0] RAT_fRN [0:RAT_SIZE-1];


/*
 * sequential logic
 */
always @ (posedge CLK) begin
        if (do_writeback1_RET)
                Reg[writeRegister1_RET] = writeData1_RET;

        if (do_writeback1_LS_RET)
                Reg[writeRegister1_LS_RET] = writeData1_LS_RET;
end

always @ (posedge CLK or negedge RESET) begin
	if (debug) begin
		$display("[REG]: REGISTER FILE");	
                $display("+---63---+---62---+---61---+---60---+---59---+---58---+---57---+---56---+---55---+---54---+---53---+---52---+---51---+---50---+---49---+---48---+");
                $display("|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|",
                                Reg[63], Reg[62], Reg[61], Reg[60], Reg[59], Reg[58], Reg[57], Reg[56],
                                Reg[55], Reg[54], Reg[53], Reg[52], Reg[51], Reg[50], Reg[49], Reg[48]
                );
                $display("+---47---+---46---+---45---+---44---+---43---+---42---+---41---+---40---+---39---+---38---+---37---+---36---+---35---+---34---+---33---+---32---+");
                $display("|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|",
                                Reg[47], Reg[46], Reg[45], Reg[44], Reg[43], Reg[42], Reg[41], Reg[40],
                                Reg[39], Reg[38], Reg[37], Reg[36], Reg[35], Reg[34], Reg[33], Reg[32]
                );
                $display("+---31---+---30---+---29---+---28---+---27---+---26---+---25---+---24---+---23---+---22---+---21---+---20---+---19---+---18---+---17---+---16---+");
                $display("|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|",
                                Reg[31], Reg[30], Reg[29], Reg[28], Reg[27], Reg[26], Reg[25], Reg[24],
                                Reg[23], Reg[22], Reg[21], Reg[20], Reg[19], Reg[18], Reg[17], Reg[16]
                );
                $display("+---15---+---14---+---13---+---12---+---11---+---10---+---09---+---08---+---07---+---06---+---05---+---04---+---03---+---02---+---01---+---00---+");
                $display("|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|",
                                Reg[15], Reg[14], Reg[13], Reg[12], Reg[11], Reg[10], Reg[09], Reg[08],
                                Reg[07], Reg[06], Reg[05], Reg[04], Reg[03], Reg[02], Reg[01], Reg[00]
                );
                $display("+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+");
$display("+---31---+---30---+---29---+---28---+---27---+---26---+---25---+---24---+---23---+---22---+---21---+---20---+---19---+---18---+---17---+---16---+");
                $display("|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|sh",
                                Reg[RAT_fRN[31]], Reg[RAT_fRN[30]], Reg[RAT_fRN[29]], Reg[RAT_fRN[28]], Reg[RAT_fRN[27]], Reg[RAT_fRN[26]], Reg[RAT_fRN[25]], Reg[RAT_fRN[24]],
                                Reg[RAT_fRN[23]], Reg[RAT_fRN[22]], Reg[RAT_fRN[21]], Reg[RAT_fRN[20]], Reg[RAT_fRN[19]], Reg[RAT_fRN[18]], Reg[RAT_fRN[17]], Reg[RAT_fRN[16]]
                );
                $display("+---15---+---14---+---13---+---12---+---11---+---10---+---09---+---08---+---07---+---06---+---05---+---04---+---03---+---02---+---01---+---00---+");
                $display("|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|%8x|",
                                Reg[RAT_fRN[15]], Reg[RAT_fRN[14]], Reg[RAT_fRN[13]], Reg[RAT_fRN[12]], Reg[RAT_fRN[11]], Reg[RAT_fRN[10]], Reg[RAT_fRN[09]], Reg[RAT_fRN[08]],
                                Reg[RAT_fRN[07]], Reg[RAT_fRN[06]], Reg[RAT_fRN[05]], Reg[RAT_fRN[04]], Reg[RAT_fRN[03]], Reg[RAT_fRN[02]], Reg[RAT_fRN[01]], Reg[RAT_fRN[00]]
                );
                $display("+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+");

	end
end

endmodule
