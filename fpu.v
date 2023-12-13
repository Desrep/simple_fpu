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

module fpu(
`ifdef USE_POWER_PINS
        inout vccd1,
        inout vssd1,
`endif

input [31:0] in1p,in2p,
 input clk,
 input rstp,act,power_off_add,retain_add,isolate_add,
 input enable_add,enable_mul,enable_sqr,enable_div,enable_comp,
 input [2:0] round_mp, // rounding mode selector
output reg [31:0] out,
output reg ov,un,less,eq,great,done,inv,inexact,div_zero,
  input [2:0] opcode // 1 = mul, 0 = add, 2 = division, 3 = square root, 4 = compare
  );

 
reg [31:0] out0;
reg [31:0] in1pa,in2pa,in1pm,in2pm,in1pc,in2pc,in1pd,in2pd,in1ps;
wire [31:0] aout,mout,dout,sout;
wire aov,aun,mov,mun,dov,dun,sov,sun;
wire inva,invm,invd,invs,div_zerod,invc;
wire inexacta,inexactm,inexactd,inexacts;
reg ov0,un0,done0,inv0,inexact0,div_zero0;
wire adone,mdone,cdone,ddone,sdone;
reg rsta,rstm,rstd,rstc,rsts;
  

  //add
  fp_add addu(.in1(in1pa),.in2(in2pa),.out(aout),.ov(aov),.un(aun),.clk(clk),.rst(rsta),.round_m(round_mp),.done(adone),.inv(inva),.inexact(inexacta),.enable(enable_add));
  //mul
  fp_mul mulu(.in1(in1pm),.in2(in2pm),.out(mout),.ov(mov),.un(mun),.clk(clk),.rst(rstm),.round_m(round_mp),.act(act),.done(mdone),.inv(invm),.inexact(inexactm));
  //compare
  fp_comp com1(.in1(in1pc),.in2(in2pc),.eq(eq),.great(great),.less(less),.act(act),.done(cdone),.clk(clk),.rst(rstc),.inv(invc));
  // division
  fp_div dv1(.in1(in1pd),.in2(in2pd),.out(dout),.ov(dov),.un(dun),.rst(rstd),.clk(clk),.round_m(round_mp),.act(act),.done(ddone),.inv(invd),.inexact(inexactd),.div_zero(div_zerod));
  //square root
  fp_sqr   sqr1(.in1(in1ps),.out(sout),.ov(sov),.un(sun),.clk(clk),.rst(rsts),.round_m(round_mp),.act(act),.done(sdone),.inv(invs),.inexact(inexacts));

  // Select inputs and outputs depending on the operation
always @* begin
    
  case (opcode) 
    0: begin
      out0 = aout;
      ov0= aov;
      un0= aun;
      done0 = adone;
      rsta = rstp;
      rstc = 0;
      rstm = 0;
      rstd = 0;
      rsts = 0;
      in1pa = in1p;
      in2pa = in2p;
      in1pm = 0;
      in2pm = 0;
      in1pc = in1p;
      in2pc = in2p;
      in1pd = 0;
      in2pd = 0;
      in1ps = 0;
      inv0 = inva;
      inexact0 = inexacta;
      div_zero0 = 0;

    end
    1: begin
      out0 = mout;
      ov0 = mov;
      un0 = mun;
      done0 = mdone;
      rstm = rstp;
      rstc = 0;
      rsta = 0;
      rstd = 0;
      rsts = 0;
      in1pa = 0;
      in2pa = 0;
      in1pm = in1p;
      in2pm = in2p;
      in1pc = 0;
      in2pc = 0;
      in1pd = 0;
      in2pd = 0;
      in1ps = 0;
      inv0 = invm;
      inexact0 = inexactm;
      div_zero0 = 0;
    end
    2: begin
      out0 = dout;
      ov0 = dov;
      un0 = dun;
      done0 = ddone;
      rstd = rstp;
      rstc = 0;
      rsta = 0;
      rstm = 0;
      rsts = 0;
      in1pa = 0;
      in2pa = 0;
      in1pm = 0;
      in2pm = 0;
      in1pc = 0;
      in2pc = 0;
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
      done0 = sdone;
      rsts = rstp;
      rstc = 0;
      rsta = 0;
      rstm = 0;
      rstd = 0;
      in1pa = 0;
      in2pa = 0;
      in1pm = 0;
      in2pm = 0;
      in1pc = 0;
      in2pc = 0;
      in1pd = 0;
      in2pd = 0;
      in1ps = in1p;
      inv0 = invs;
      inexact0 = inexacts;
      div_zero0 = 0;

    end
    4: begin
      out0 = 0;
      ov0 = sov;
      un0 = sun;
      done0 = cdone;
      rstc = rstp;
      rsta = 0;
      rstm = 0;
      rstd = 0;
      rsts = 0;
      in1pa = 0;
      in2pa = 0;
      in1pm = 0;
      in2pm = 0;
      in1pc = in1p;
      in2pc = in2p;
      in1pd = 0;
      in2pd = 0;
      in1ps = 0;
      inv0 = invc;
      inexact0 = inexacta;
      div_zero0 = 0;
    end

   default : begin
     out0 = aout;
      ov0= aov;
      un0= aun;
    done0 = adone;
    rsta = rstp;
    rstc = 0;
    rstd = 0;
    rstm = 0;
    rsts = 0;
    in1pa = in1p;
    in2pa = in2p;
    in1pm = 0;
    in2pm = 0;
    in1pc = 0;
    in2pc = 0;
    in1pd = 0;
    in2pd = 0;
    in1ps = 0;
    inv0 = inva;
    inexact0 = inexacta;
    div_zero0 = 0;
   end
  endcase
   
end
  

  
always @*
begin  
  {out,ov,un,done,inv,inexact,div_zero} = {out0,ov0,un0,done0,inv0,inexact0,div_zero0};
end



endmodule
