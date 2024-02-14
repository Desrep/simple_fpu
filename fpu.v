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
`include  "sram_fault.v"
`include "mbist.v"
`include "tapc.v"
`include "ir_decoder.v"


`define SA0_FAULT   // uncoment to inyect a stuck at 0 fault in the sram for now
//`define SA1_FAULT  // stuck at 1 fault inyection for sram

module fpu(
input clk,
//memory
input [31:0] inp, // external input to memory
input [4:0] addr1,addr2,addr3, // addr1 for op1, addr2 for op2, addr3 to store the output
//fpu
input rstp,act,
input [2:0] round_mp, // rounding mode selector
output reg [31:0] out,
output reg ov,un,less,eq,great,done,inv,inexact,div_zero,
input [2:0] opcode_in, // 1 = mul, 0 = add, 2 = division, 3 = square root, 4 = compare
input enable,ld, // this set to 0 enables the fpu operations, 1 enables write to memory from the inputs
//ld loads from memory to the fp registers
input test_mode,

//tap signals
input tdi,tms,tck,trst,tdo,
output reg td
  );



localparam width = 32;
localparam addr_width = 5;

localparam BYPASS = 4'b0000;
localparam SAMPLE = 4'b0001;
localparam PRELOAD = 4'b0010;
localparam EXTEST = 4'b0011;
localparam RUN_MBIST = 4'b0100;
localparam RUNSCAN = 4'b0101;
localparam INTEST = 4'b0110;
localparam PROG_MBIST = 4'b0111;
localparam PROG_LBIST = 4'b1001;
localparam RUN_LBIST = 4'b1010;




// fpu signals
reg [31:0] out0;
reg [31:0] in1pa,in2pa,in1pm,in2pm,in1pc,in2pc,in1pd,in2pd,in1ps,in1p,in2p;
wire [31:0] aout,mout,dout,sout;
reg [2:0] opcode; // opcode register
wire aov,aun,mov,mun,dov,dun,sov,sun,eq0,less0,great0;
wire inva,invm,invd,invs,div_zerod,invc;
wire inexacta,inexactm,inexactd,inexacts;
reg ov0,un0,done0,inv0,inexact0,div_zero0;
wire adone,mdone,cdone,ddone,sdone;
reg eq1,less1,great1;
reg [2:0] done_count;

// memory signals
wire [4:0] fpu_addr0;
wire [4:0] addr0;
reg [4:0] addrx;
reg csb0,csb1,web0;
wire [3:0] wmask0;
reg fpu_csb0,fpu_csb1,fpu_web0;
wire [31:0] din0, fpu_din0,dout0,dout1;
wire sram_clk;

// tap signals and decoder signals
wire ckdr,sdr,usr,ckir,sir,uir,tapenable,taprst,tapselect;
reg [3:0] ir;
reg [10:0] mbist_ir;

//mbist signals
wire mbist_write, mbist_read,mbist_web;
wire [width -1:0] mbist_output_data;
wire [addr_width-1:0] mbist_address;
wire [10:0] mbist_inst_reg_out;
//wire [10:0] mbist_inst_reg;

//decoder signals
wire sample,bypass,preload,extest,intest,runmbist,runscan,runlbist,progmbist,proglbist;
//wire [3:0] ir;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


  //add
  fp_add addu(.in1(in1pa),.in2(in2pa),.out(aout),.ov(aov),.un(aun),.clk(clk),.rst(rstp),.round_m(round_mp),.inv(inva),.inexact(inexacta));
  //mul
  fp_mul mulu(.in1(in1pm),.in2(in2pm),.out(mout),.ov(mov),.un(mun),.clk(clk),.rst(rstp),.round_m(round_mp),.inv(invm),.inexact(inexactm));
  //compare
  fp_comp com1(.in1(in1pc),.in2(in2pc),.eq(eq0),.great(great0),.less(less0),.clk(clk),.rst(rstp),.inv(invc));
  // division
  fp_div dv1(.in1(in1pd),.in2(in2pd),.out(dout),.ov(dov),.un(dun),.rst(rstp),.clk(clk),.round_m(round_mp),.inv(invd),.inexact(inexactd),.div_zero(div_zerod));
  //square root
  fp_sqr   sqr1(.in1(in1ps),.out(sout),.ov(sov),.un(sun),.clk(clk),.rst(rstp),.round_m(round_mp),.inv(invs),.inexact(inexacts));

 // Sram
 sram sram1(.clk(sram_clk),.csb0(csb0),.web0(web0),.wmask0(wmask0),.addr0(addr0),.addr1(addr2),.din0(din0),.dout0(dout0),.dout1(dout1),.csb1(csb1));

 mbist mb(.reg_input(mbist_ir),.clk(tck),.rst(rstp),.reg_out(mbist_inst_reg_out),.write(mbist_write),.read(mbist_read),.addr(mbist_address),.input_data(dout0),.output_data(mbist_output_data),.web(mbist_web));


tapc tc1 (.tms(tms),.trst(rstp),.tck(tck),.clockdr(ckdr),.shiftdr(sdr),.updatedr(udr),.clockir(ckir),.shiftir(sir),.updateir(uir),.enable(tapenable),.rst(taprst),.select(tapselect));

ir_decoder ird1 (.ir_in(ir),.sample(sample),.bypass(bypass),.preload(preload),.extest(extest),.intest(intest),.runmbist(runmbist),.runscan(runscan),.runlbist(runlbist),.progmbist(progmbist),.proglbist(proglbist));


//mbist muxes
assign csb0 = (progmbist&!sdr)?1'b0:fpu_csb0;
assign web0 = (progmbist&!sdr)?mbist_web:fpu_web0;
assign din0 = (progmbist&!sdr)?mbist_output_data:fpu_din0;
assign addr0 = (progmbist&!sdr)?mbist_address:addrx;
assign csb1 = (progmbist&!sdr)?1'b1:fpu_csb1;
assign sram_clk = (progmbist&!sdr)?tck:clk;
/////

/////TAP Instruction register

always @(posedge ckir or negedge taprst)
begin
	if(!taprst)
		ir <= BYPASS;
	else begin
	    if(sir)
	      {ir[0],ir[3:1]} <= {tdi,ir[2:0]};
	end
end

///Mbist instruction register
always @(posedge ckdr or negedge taprst)
begin
	if(!taprst)
		mbist_ir <= 11'b01110100000;
	else begin
	if(progmbist&sdr)
		{mbist_ir[0],mbist_ir[10:1]} <= {tdi,mbist_ir[9:0]};
	end
end
////////////////////////




///////////////////////////////////

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

always @* begin //memory setup
	if((done0 && enable && !ld)||(!enable)) begin
		fpu_web0 = 0;
		fpu_csb0 = 0;
		fpu_csb1 = 1;
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
		fpu_web0 = 1;
		fpu_csb0 = 0;
		fpu_csb1 = 0;
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

assign fpu_din0 = enable?out0:inp; //select data to write to memory

always @(posedge clk or negedge rstp) begin // done counter
	if(!rstp) begin
	   {done_count,done0} <= {3'b000,1'b0};
	end
	else begin
     if(enable) begin
	   case (opcode)
	      0:begin
		  if(done_count == 2)
                  	{done_count,done0} <= {3'b000,1'b1};
                  else
                  	{done_count,done0} <= {done_count+3'b001,1'b0};
		 end
	      1:begin
		  if(done_count == 2)
			  {done_count,done0} <= {3'b000,1'b1};
                  else
			  {done_count,done0} <= {done_count+3'b001,1'b0};
	      	end
		2:begin
		  if(done_count == 7)
			  {done_count,done0} <= {3'b000,1'b1};
                  else
			  {done_count,done0} <= {done_count+3'b001,1'b0};
		  end
		3:begin
		  if(done_count == 7)
			  {done_count,done0} <= {3'b000,1'b1};
                  else
			  {done_count,done0} <= {done_count+3'b001,1'b0};
		  end
		4:begin
	        if(done_count == 1)
			{done_count,done0} <= {3'b000,1'b1};
                  else
			{done_count,done0} <= {done_count+3'b001,1'b0};
		 end
		 default:begin
		     {done_count,done0} <= {done_count+3'b001,1'b0};
	     	  end
		endcase
	      end
	else 
	   {done_count,done0} <= {3'b000,1'b0};
   	end

end



always @*
begin  
  {out,ov,un,done,inv,inexact,div_zero,eq,great,less} = {out0,ov0,un0,done0,inv0,inexact0,div_zero0,eq1,great1,less1};
end



endmodule
