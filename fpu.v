/* Copyright 2023 Desrep

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
// It contains addition, multiplication, division,square root and fp compare.
// 32 (single precision) bit Floating point unit 
// Need to find a way to generate the Done flag correctly
// This is the top level instantiation
`include "special_characters.v"
`include "fp_mul.v"
`include "fp_div.v"
`include "fp_comp.v"
`include "fp_add.v"
`include "fp_sqr.v"
`include  "sram_1rw1r_32_256_8_sky130.v"

module fpu(
input [31:0] inp, // external input to memory
input clk,
input [4:0] addr1,addr2,addr3, // addr1 for op1, addr2 for op2, addr3 to store the output
input rstp,act,
input [2:0] round_mp, // rounding mode selector
output reg [31:0] out,
output reg ov,un,less,eq,great,done,inv,inexact,div_zero,
input [2:0] opcode_in, // 1 = mul, 0 = add, 2 = division, 3 = square root, 4 = compare
input enable,ld // this set to 0 enables the fpu operations, 1 enables write to memory from the inputs
//ld loads from memory to the fp registers
  );

 
reg [31:0] out0;
reg [31:0] in1pa,in2pa,in1pm,in2pm,in1pc,in2pc,in1pd,in2pd,in1ps,in1p,in2p;
wire [31:0] aout,mout,dout,sout,din0,dout0,dout1;
wire [4:0] addr0;
reg [4:0] addrx;
reg [2:0] opcode; // opcode register
wire aov,aun,mov,mun,dov,dun,sov,sun,eq0,less0,great0;
wire inva,invm,invd,invs,div_zerod,invc;
wire inexacta,inexactm,inexactd,inexacts;
reg ov0,un0,done0,inv0,inexact0,div_zero0;
wire adone,mdone,cdone,ddone,sdone;
reg rsta,rstm,rstd,rstc,rsts,eq1,less1,great1;
reg csb0,csb1,web0;
wire [3:0] wmask0;
reg [3:0] done_count;

  //add
  fp_add addu(.in1(in1pa),.in2(in2pa),.out(aout),.ov(aov),.un(aun),.clk(clk),.rst(rstp),.round_m(round_mp),.act(act),.done(adone),.inv(inva),.inexact(inexacta));
  //mul
  fp_mul mulu(.in1(in1pm),.in2(in2pm),.out(mout),.ov(mov),.un(mun),.clk(clk),.rst(rstp),.round_m(round_mp),.act(act),.done(mdone),.inv(invm),.inexact(inexactm));
  //compare
  fp_comp com1(.in1(in1pc),.in2(in2pc),.eq(eq0),.great(great0),.less(less0),.act(act),.done(cdone),.clk(clk),.rst(rstp),.inv(invc));
  // division
  fp_div dv1(.in1(in1pd),.in2(in2pd),.out(dout),.ov(dov),.un(dun),.rst(rstp),.clk(clk),.round_m(round_mp),.act(act),.done(ddone),.inv(invd),.inexact(inexactd),.div_zero(div_zerod));
  //square root
  fp_sqr   sqr1(.in1(in1ps),.out(sout),.ov(sov),.un(sun),.clk(clk),.rst(rstp),.round_m(round_mp),.act(act),.done(sdone),.inv(invs),.inexact(inexacts));

 // Sram
 sram_1rw1r_32_256_8_sky130 sram1(.clk0(clk),.clk1(clk),.csb0(csb0),.web0(web0),.wmask0(wmask0),.addr0(addr0),.addr1(addr2),.din0(din0),.dout0(dout0),.dout1(dout1),.csb1(csb1)
);

always @(posedge clk or negedge rstp) begin //sample opcode
	if(!rstp) begin
	     opcode <= 0;
        end
	else begin
	     opcode <= opcode_in;
	end
end

  // Select inputs and outputs depending on the operation
always @* begin
    
  case (opcode) 
    0: begin
      out0 = aout;
      ov0= aov;
      un0= aun;
      in1pa = in1p;
      in2pa = in2p;
      in1pm = 0;
      in2pm = 0;
      in1pc = in1p;
      in2pc = in2p;
      in1pd = 0;
      in2pd = 0;
      in1ps = 0;
      eq1 = eq0;
      great1  = great0;
      less1 = less0;
      inv0 = inva;
      inexact0 = inexacta;
      div_zero0 = 0;
    end
    1: begin
      out0 = mout;
      ov0 = mov;
      un0 = mun;
      in1pa = 0;
      in2pa = 0;
      in1pm = in1p;
      in2pm = in2p;
      in1pc = 0;
      in2pc = 0;
      in1pd = 0;
      in2pd = 0;
      in1ps = 0;
      eq1 = 0;
      great1  = 0;
      less1 = 0;
      inv0 = invm;
      inexact0 = inexactm;
      div_zero0 = 0;
    end
    2: begin
      out0 = dout;
      ov0 = dov;
      un0 = dun;
      in1pa = 0;
      in2pa = 0;
      in1pm = 0;
      in2pm = 0;
      in1pc = 0;
      in2pc = 0;
      eq1 = 0;
      great1  = 0;
      less1 = 0;
      in1pd = in1p;
      in2pd = in2p;
      in1ps = 0;
       inv0 = invd;
      inexact0 = inexactd;
      div_zero0 = div_zerod;
    end
    3: begin
      out0 = sout;
      ov0 = sov;
      un0 = sun;
      in1pa = 0;
      in2pa = 0;
      in1pm = 0;
      in2pm = 0;
      in1pc = 0;
      in2pc = 0;
      in1pd = 0;
      in2pd = 0;
      eq1 = 0;
      great1  = 0;
      less1 = 0;
      in1ps = in1p;
      inv0 = invs;
      inexact0 = inexacts;
      div_zero0 = 0;
    end
    4: begin
      out0 = 0;
      ov0 = sov;
      un0 = sun;
      in1pa = 0;
      in2pa = 0;
      in1pm = 0;
      in2pm = 0;
      in1pc = in1p;
      in2pc = in2p;
      in1pd = 0;
      in2pd = 0;
      in1ps = 0;
      eq1 = 0;
      great1  = 0;
      less1 = 0;
      inv0 = invc;
      inexact0 = inexacta;
      div_zero0 = 0;
    end

   default : begin
     out0 = aout;
      ov0= aov;
      un0= aun;
    in1pa = in1p;
    in2pa = in2p;
    in1pm = 0;
    in2pm = 0;
    in1pc = 0;
    in2pc = 0;
    in1pd = 0;
    in2pd = 0;
    in1ps = 0;
    eq1 = eq0;
    great1  = 0;
    less1 = 0;
    inv0 = 0;
    inexact0 = 0;
    div_zero0 = 0;
   end
  endcase
   
end
  
assign wmask0 = 4'b1111;
assign addr0 = addrx; 

always @* begin //memory setup
	if((done0 && enable && !ld)||(!enable)) begin
		web0 = 0;
		csb0 = 0;
		csb1 = 1;
		if(done0) 
		addrx = addr3;
		else
		addrx = addr1;
	end
	else begin
		if(done0)
                addrx = addr3;
                else
                addrx = addr1;
		web0 = 1;
		csb0 = 0;
		csb1 = 0;
	end

end

always @(posedge clk or negedge rstp) begin //load FP registers
	if(!rstp) begin
           {in1p,in2p} <= {32'b0,32'b0};
	end
	else begin
	    if(ld) begin
	 	{in1p,in2p} <= {dout0,dout1};
	    end
	    else
	        {in1p,in2p} <= {in1p,in2p};
	end
end

assign din0 = enable?out0:inp; //select data to write to memory

always @(posedge clk or negedge rstp) begin // done counter
	if(!rstp) begin
	   done_count <= 0;
	end
	else begin
     if(enable) begin
	   case (opcode)
	      0:begin
		  if(done_count == 2)
                  	{done_count,done0} <= {4'b0000,1'b1};
                  else
                  	{done_count,done0} <= {done_count+4'b0001,1'b0};
		 end
	      1:begin
		  if(done_count == 2)
			  {done_count,done0} <= {4'b0000,1'b1};
                  else
			  {done_count,done0} <= {done_count+4'b0001,1'b0};
	      	end
		2:begin
		  if(done_count == 7)
			  {done_count,done0} <= {4'b0000,1'b1};
                  else
			  {done_count,done0} <= {done_count+4'b0001,1'b0};
		  end
		3:begin
		  if(done_count == 7)
			  {done_count,done0} <= {4'b0000,1'b1};
                  else
			  {done_count,done0} <= {done_count+4'b0001,1'b0};
		  end
		4:begin
	        if(done_count == 1)
			{done_count,done0} <= {4'b0000,1'b1};
                  else
			{done_count,done0} <= {done_count+4'b0001,1'b0};
		 end
		 default:begin
		     {done_count,done0} <= {done_count+4'b0001,1'b0};
	     	  end
		endcase
	      end
	else 
	   {done_count,done0} <= {4'b0000,1'b0};
   	end

end



always @*
begin  
  {out,ov,un,done,inv,inexact,div_zero,eq,great,less} = {out0,ov0,un0,done0,inv0,inexact0,div_zero0,eq1,great1,less1};
end



endmodule
