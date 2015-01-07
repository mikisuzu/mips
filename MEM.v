/*
 * Data Memory Stage
 */
module MEM (	
	CLK, 
	RESET,
	FREEZE,
	/* output */
	MemRead_2DM,
	MemWrite_2DM,
	data_write_2DM,
	data_address_2DM,
	Instr_OUT,
	writeRegister1_PR,
	do_writeback1_PR,
	Data1_2ID,
	bubble_MEM,
	retire_entry,
	//do_read_MEMQUEUE,
	//do_write_RETQUEUE,
	/* input */
	do_writeback1_RET,
	writeRegister1_RET,
	writeData1_RET,
	mispredict,
	flush_fCOM,
	mem_entry,
	data_read_fDM,
	//empty_MEMQUEUE,
	//full_RETQUEUE,
	debug
);

/*
 * parameters
 */
parameter MEM_ENTRY_SIZE = 320;
parameter RET_ENTRY_SIZE = 256;


/*
 * output
 */
   /*output reg    [31: 0] aluResult1_PR;
   output reg    [31: 0] data_read1_PR;
   output reg    [ 4: 0] writeRegister1_PR;
   output reg            MemtoReg1_PR;
   output reg            do_writeback1_PR;*/
/* to data cache */
output reg	      		 MemRead_2DM;
output reg            		 MemWrite_2DM;   
output reg    		 [31: 0] data_write_2DM;
output reg    		 [31: 0] data_address_2DM;
output reg    		 [31: 0] Instr_OUT;
/* for bypass */
output reg		 [ 5: 0] writeRegister1_PR;
output reg			 do_writeback1_PR;
/* forwarding back */ 
output reg    		 [31: 0] Data1_2ID;
/* for store bubble */
output reg			 bubble_MEM;

//output reg			 do_read_MEMQUEUE;
//output reg			 do_write_RETQUEUE;

output reg [RET_ENTRY_SIZE-1: 0] retire_entry;

/*
 * input
 */
   //input         [31: 0] aluResult1;
   //input         [31: 0] Dest_Value1;
   //input         [31: 0] readDataB1;
   //input         [31: 0] Instr1;
   //input         [ 5: 0] ALU_control1;
   //input         [ 4: 0] writeRegister1;
   //input                 ALUSrc1;
   //input                 do_writeback1;
   //input                 MemtoReg1;
   //input                 MemRead1;
   //input                 MemWrite1;
input                 CLK;
input                 RESET;
input		      FREEZE;
/* forwarding */
input                 do_writeback1_RET;
input         [ 5: 0] writeRegister1_RET;
input         [31: 0] writeData1_RET;
/* for mispredict */
input		      mispredict;
input		      flush_fCOM;
  
input [MEM_ENTRY_SIZE-1: 0] mem_entry;
input         [31: 0] data_read_fDM;

//input		      empty_MEMQUEUE;
//input		      full_RETQUEUE;

input 		      debug;

/*
 * internal variables
 */
wire         [31: 0] data_read_aligned;
wire         [31: 0] Dest_Value;
wire         [31: 0] aluResult;
wire         [31: 0] readDataB;
wire         [31: 0] writeData_WB;
wire         [31: 0] Instr;
wire         [ 5: 0] ALU_control;
wire                 MemRead;
wire                 MemWrite;
wire                 select1_WB;
wire                 select2_WB;

wire	     [31: 0] Instr1;
wire          [5: 0] writeRegister1;
wire		     MemRead1;
wire		     MemWrite1;
wire         [31: 0] readDataB1;
wire         [31: 0] aluResult1;
wire	     [31: 0] Dest_Value1;
wire          [5: 0] ALU_control1;
wire 		     do_writeback1;
wire		     MemtoReg1;
//wire	     [31: 0] pre_inst;
//wire		     branch_inst;

//reg	     [ 2: 0] bubble_counter;

/* parse entry */
assign Dest_Value1 	= mem_entry[319:288];
assign readDataB1 	= mem_entry[287:256];
assign aluResult1 	= mem_entry[223:192];
assign writeRegister1 	= mem_entry[179:174];
assign do_writeback1 	= mem_entry[140];
assign MemRead1 	= mem_entry[135];
assign MemtoReg1	= mem_entry[134];
assign MemWrite1 	= mem_entry[133];
assign ALU_control1 	= mem_entry[121:116];
assign Instr1 		= mem_entry[ 31:  0];

/* get previous inst */
//assign pre_inst		= retire_entry[31: 0];

assign Instr_OUT 	= Instr1;
assign select1_WB 	= (do_writeback1_RET && (writeRegister1_RET == writeRegister1));

assign MemRead_2DM 	= MemRead1;
//assign MemWrite_2DM 	= (mispredict || flush_fCOM) ? 1'b0 : MemWrite1;	/* mispredict, don't do write mem operation */
//assign MemWrite_2DM 	= (flush_fCOM || empty_MEMQUEUE || full_RETQUEUE || mispredict) ? 1'b0 : MemWrite1;
assign MemWrite_2DM 	= (flush_fCOM || mispredict) ? 1'b0 : MemWrite1;
assign data_write_2DM 	= (select1_WB) ? writeData1_RET : readDataB1;
assign data_address_2DM = aluResult1;
   

/* bypass back */
assign Data1_2ID 	= (MemRead_2DM) ? data_read_aligned : aluResult1;

//assign bubble_MEM	= MemtoReg1 && (bubble_counter != 0);
//assign bubble_MEM	= (!branch_inst && MemWrite1) && (bubble_counter != 0);

/* for read/write queue */
//assign do_read_MEMQUEUE  = (!RESET || FREEZE || mispredict || flush_fCOM || empty_MEMQUEUE || full_RETQUEUE) ? 1'b0 : 1'b1;
//assign do_read_MEMQUEUE  = (!RESET || FREEZE || mispredict || flush_fCOM || empty_MEMQUEUE) ? 1'b0 : 1'b1;
//assign do_write_RETQUEUE = do_read_MEMQUEUE;
//assign retire_entry 	 = (!do_write_RETQUEUE) ? 0 : {data_read_aligned, aluResult1, mem_entry[191: 0]};


/* previous instruction is branch instruction ? */
/*
always begin
        case(pre_inst[31:26])
                6'b000001, 6'b000100, 6'b000101, 6'b000110, 6'b000111:
                        branch_inst = 1'b1;
                default:
                        branch_inst = 1'b0;
        endcase
end
*/

   always
     begin
        data_read_aligned = (select1_WB) ? writeData1_RET : Dest_Value1;
	ALU_control = ALU_control1;
	aluResult = aluResult1;
	
	       case(ALU_control)
        		6'b101101: begin //LWX
                        	case( aluResult[1:0] )
                       	   		0:  data_read_aligned = data_read_fDM;
                      	        	1:  data_read_aligned[31:8] = data_read_fDM[23:0];
                       	        	2:  data_read_aligned[31:16] = data_read_fDM[15:0];
                       	        	3:  data_read_aligned[31:24] = data_read_fDM[7:0];
               		        endcase
                        end
                	6'b101110: begin //LWX
                    		case( aluResult[1:0] )
                     		   	0:  data_read_aligned[7:0] = data_read_fDM[31:24];
                        		1:  data_read_aligned[15:0] = data_read_fDM[31:16];
                        		2:  data_read_aligned[23:0] = data_read_fDM[31:8];
                       		 	3:  data_read_aligned = data_read_fDM;
                    		endcase
                	end
                	6'b100001: begin //LB
		    		case( aluResult[1:0] )
		  			3: data_read_aligned={{24{data_read_fDM[7]}},data_read_fDM[7:0]};
					2: data_read_aligned={{24{data_read_fDM[15]}},data_read_fDM[15:8]};
					1: data_read_aligned={{24{data_read_fDM[23]}},data_read_fDM[23:16]};
					0: data_read_aligned={{24{data_read_fDM[31]}},data_read_fDM[31:24]};
					default: begin end
		    		endcase
      	         	end
         	        6'b101011: begin //LH
		    		case( aluResult[1:0] )
					0:data_read_aligned={{16{data_read_fDM[15]}},data_read_fDM[15:0]};
					2:data_read_aligned={{16{data_read_fDM[31]}},data_read_fDM[31:16]};
					default: begin end
		    		endcase
                	end
                	6'b101010: begin //LBU
                    		case( aluResult[1:0] )
					0: data_read_aligned={24'b0,data_read_fDM[31:24]};
					1: data_read_aligned={24'b0,data_read_fDM[23:16]};
					2: data_read_aligned={24'b0,data_read_fDM[15:8]};
					3: data_read_aligned={24'b0,data_read_fDM[7:0]};
					default: begin end 
		    		endcase
                	end
                	6'b101100: begin //LHU
		    		case(aluResult%4)
					0:data_read_aligned={16'b0,data_read_fDM[15:0]};
	            			2:data_read_aligned={16'b0,data_read_fDM[31:16]};
					default: begin end
		    		endcase
                	end
                        default: data_read_aligned = data_read_fDM;  
		endcase
     end


always @ (posedge CLK or posedge RESET) begin
	if (!RESET) begin
		//bubble_counter	  <= 3'b110;	/* freeze for 6 cycles */
	end
	else if (!FREEZE) begin
		//bubble_counter    <= (MemWrite1 && !branch_inst) ? bubble_counter - 1 : 3'b110;

	end
end

always @ (posedge CLK or posedge RESET) begin
	//if(RESET == 1'b0 || mispredict || bubble_MEM) begin
	//if(RESET == 1'b0 || mispredict || bubble_MEM) begin
	//if(RESET == 1'b0 || mispredict || flush_fCOM || empty_MEMQUEUE || full_RETQUEUE) begin
	if(RESET == 1'b0 || mispredict || flush_fCOM) begin
           	//MemtoReg1_PR <= 1'b0;
           	//writeRegister1_PR <= 5'b0;
           	//aluResult1_PR <= 32'b0;
           	//data_read1_PR <= 32'b0;
           	//do_writeback1_PR <= 1'b0;
		writeRegister1_PR <= 6'b0;
		do_writeback1_PR  <= 1'b0;
           	retire_entry 	  <= 256'b0;
        end
       	//else if(!FREEZE && !bubble_MEM) begin
       	else if(!FREEZE) begin
           	//MemtoReg1_PR <= MemtoReg1;
           	//writeRegister1_PR <= writeRegister1;
           	//aluResult1_PR <= aluResult1;
           	//data_read1_PR <= data_read_aligned;
	   	//do_writeback1_PR <= do_writeback1;
		writeRegister1_PR <= writeRegister1;
		do_writeback1_PR  <= do_writeback1;
	   	retire_entry 	  <= {data_read_aligned, aluResult1, mem_entry[191: 0]};
	end
end

always @ (posedge CLK or posedge RESET) begin
	if (debug) begin
		$display("============================================================================================================================================CYCLE=");
		$display("[MEM]:\tFREEZE=%d", FREEZE);
		$display("[MEM]:\tMemRead=%d\tMemWrite=%d\tdata_address=0x%x\tdata_write=0x%x\tdata_read=0x%x", 
					MemRead_2DM, MemWrite_2DM, data_address_2DM, data_write_2DM, data_read_fDM);
		$display("[MEM]:\tselect1_WB=%d", select1_WB);
	end
end

endmodule
