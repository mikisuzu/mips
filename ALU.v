//-----------------------------------------
//               ALU Module
//-----------------------------------------
module ALU( HI, LO, aluResult, A, B, ALU_control, shiftAmount, CLK );
   output reg [31: 0] aluResult;
   output reg [31: 0] HI;
   output reg [31: 0] LO; 

   input      [31: 0] A;
   input      [31: 0] B; 
   input      [ 5: 0] ALU_control;
   input      [ 4: 0] shiftAmount;
   input              CLK;

   wire       [63: 0] temp;
   wire       [ 4: 0] i;

   always begin
      case( ALU_control ) 
                    6'b000000,6'b000010,6'b000001,6'b110111,6'b110101:aluResult = A+B;//add,addi,addiu,addu,lwc
                    6'b111101,6'b100001,6'b101010,6'b101011,6'b101100,6'b101101,6'b101110,6'b101111,6'b110000,6'b110001,6'b110010,6'b110011,6'b111001:begin
			aluResult = A+{{16{B[15]}},B[15:0]};
			//$display("A:%d B:%d\n",A,B);
		    end//lw,lb,lbu,lh,lhu,lwl,lwr,sb,sh,sw,swl,swr,swc
                    6'b000100:aluResult = A & B;//and
                    6'b000101://div
                        begin
                            if(B!=0)begin
                                    LO[31] = A[31] | B[31];
                                    LO[30:0] = A[30:0] / B[30:0];
                                    HI[30:0] = A[30:0] % B[30:0];
                            end
                        end
                    6'b000110://divu
                        begin
                            if(B!=0)begin
                                    LO = A / B;
                                    HI = A % B;
                            end
                        end
                    6'b001000:aluResult = {B[15:0],16'b0};//lui
                    6'b001001:aluResult = HI;//mfhi
                    6'b001010:aluResult = LO;//mflo
                    6'b001011:HI = A;//mthi
                    6'b001100:LO = A;//mtlo
                    6'b001101://mult//multu
                        begin
                            temp[63:0] = A * B;
                            HI = temp[63:32];
                            LO = temp[31:0];
                        end
                    6'b001111:aluResult = ~(A | B);//nor
                    6'b010000:aluResult = A | B;//or,ori
                    6'b010011:aluResult = B << shiftAmount;//sll,LWC0
                    6'b010100:aluResult = B << A;//sllv
                    6'b010101://slt
                        begin
                            if( A[31] < B[31] ) aluResult = 0;
                            else if( A[30:0] > B[30:0] ) aluResult = 0;
                            else if( A == B ) aluResult = 0;
                            else aluResult = 1;
                        end
		    6'b111111://sltu
                        begin
                            if( A[31:0] > B[31:0] ) aluResult = 0;
                            else if( A == B ) aluResult = 0;
                            else aluResult = 1;
                        end
                    6'b011001://sra
                        begin
                            temp[32]=B[31];
                            temp[31:0] = {B[31:0] >> shiftAmount};
		            temp[31]=temp[32];
			    if(shiftAmount>=1)temp[30]=temp[32];
			    if(shiftAmount>=2)temp[29]=temp[32];
			    if(shiftAmount>=3)temp[28]=temp[32];
			    if(shiftAmount>=4)temp[27]=temp[32];
			    if(shiftAmount>=5)temp[26]=temp[32];
			    if(shiftAmount>=6)temp[25]=temp[32];
			    if(shiftAmount>=7)temp[24]=temp[32];
			    if(shiftAmount>=8)temp[23]=temp[32];
			    if(shiftAmount>=9)temp[22]=temp[32];
			    if(shiftAmount>=10)temp[21]=temp[32];
			    if(shiftAmount>=11)temp[20]=temp[32];
			    if(shiftAmount>=12)temp[19]=temp[32];
			    if(shiftAmount>=13)temp[18]=temp[32];
			    if(shiftAmount>=14)temp[17]=temp[32];
			    if(shiftAmount>=15)temp[16]=temp[32];
			    if(shiftAmount>=16)temp[15]=temp[32];
			    if(shiftAmount>=17)temp[14]=temp[32];
			    if(shiftAmount>=18)temp[13]=temp[32];
			    if(shiftAmount>=19)temp[12]=temp[32];
			    if(shiftAmount>=20)temp[11]=temp[32];
			    if(shiftAmount>=21)temp[10]=temp[32];
			    if(shiftAmount>=22)temp[9]=temp[32];
			    if(shiftAmount>=23)temp[8]=temp[32];
			    if(shiftAmount>=24)temp[7]=temp[32];
			    if(shiftAmount>=25)temp[6]=temp[32];
			    if(shiftAmount>=26)temp[5]=temp[32];
			    if(shiftAmount>=27)temp[4]=temp[32];
			    if(shiftAmount>=28)temp[3]=temp[32];
			    if(shiftAmount>=29)temp[2]=temp[32];
			    if(shiftAmount>=30)temp[1]=temp[32];
			    if(shiftAmount>=31)temp[0]=temp[32];
                            aluResult = temp[31:0];
                        end
                    6'b011010://srav
                        begin
                            temp[32]=B[31];
                            temp[31:0] = {B[31:0] >> (A[4:0])};
                            for(i=0;i<=A[4:0];i=i+1) temp[31-i] = temp[32];
                            aluResult = temp[31:0];
                        end
                    6'b011011: aluResult = (B[31:0] >> shiftAmount);//srl
                    6'b011100://srlv
                        begin
                            temp[31:0] = (B[31:0] >> A[4:0]);
                            aluResult = temp[31:0];
                        end
                    6'b011101,6'b011110:aluResult = A - B;//sub,subu
                    6'b011111,6'b100000:aluResult = A ^ B;//xor,xori
                    6'b110100,6'b111000:aluResult = B;//ctc,mtc
                    default: aluResult = 0;
      endcase
   end
endmodule
