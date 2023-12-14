/* Copyright 2023 Desrep

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" `BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/


// fp division 2 32 bit fp numbers
//5 rounding modes implemented
`include "special_characters.v"
module fp_div(in1,in2,out,ov,un,clk,rst,round_m,act,done,inv,div_zero,inexact);
  parameter W = 32;
  parameter M = 22;
  parameter E = 30;
  parameter IWID=M+4;
  parameter OWID = M+1;
  input clk;
  input rst,act;
  input [W-1:0] in1;
  input [2:0] round_m; // rounding mode selector
  input [W-1:0] in2;
  output reg [W-1:0] out;
  output reg ov,un,done,inv,div_zero,inexact;
  wire [E-M-1:0] E1,E2;
  reg [E-M-1:0] Ef1,Ef2;
  reg [E-M-1:0] E0,E01,E02,E001,Eround;
  reg [M+3:0] M1,M2,M01,Mf2,Mf1,w_convergent,M02,M00r;
  wire [M+3:0] M0r,rem;
  reg [M:0] M0;
  reg ov0,un0,inexact0,t,g,l,tmerge;
  wire tdiv;
  reg [E:0] next_number;
  reg ov_f,un_f,done_f,inv_f,inexact_f,div_zero_f; //forward exception variables
  reg ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,div_zero_f_c; //forward exception variables
  reg [W-1:0] out_f,out_f_c;
  reg done0_reg,done1;
  wire done0;
  reg forward,forward_c;
  reg [1:0] gr; // guard and round bits
  reg sticky; // sticky bit
  wire S1,S2,S0;
  integer i;



  //initialize values
 assign  E1  = in1[E:M+1];
 assign E2 = in2[E:M+1] ;
 assign S1 = in1[W-1];
  assign S2 = in2[W-1];


  always @* begin   //exception computation
      if( ((in1==`FP_ZEROP)&&(in2==`FP_ZEROP))||((in1==`FP_ZERON)&&(in2==`FP_ZERON))
        ||((in1==`FP_ZEROP)&&(in2==`FP_ZERON))||((in1==`FP_ZERON)&&(in2==`FP_ZEROP)))
     			{out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_NANQ,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1};
    else if( ((in1==`FP_INFP)&&(in2==`FP_INFP))||((in1==`FP_INFN)&&(in2==`FP_INFN))
            ||((in1==`FP_INFP)&&(in2==`FP_INFN))||((in1==`FP_INFN)&&(in2==`FP_INFP)))
      			{out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_NANQ,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1};
     else if( ((in1==`FP_ZEROP)&&(in2==`FP_INFP))||((in1==`FP_ZEROP)&&(in2==`FP_INFN))
             ||((in1==`FP_ZERON)&&(in2==`FP_INFP))||((in1==`FP_ZERON)&&(in2==`FP_INFN)))
    			 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_NANQ,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1};
     else if ((in1==`FP_ZEROP)||(in1==`FP_ZERON))
   		  {out_f_c[M:0],out_f_c[E:M+1],out_f_c[W-1],ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {23'b0,8'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1};
     else if ((in2==`FP_INFP)||(in2==`FP_INFN)) begin
       if((S1 == 1'b1)&&(in2==`FP_INFP))
      	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_ZERON,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1};
       else if((S1 == 1'b1)&&(in2==`FP_INFN))
      	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_ZEROP,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1};
       else if((S1 == 1'b0)&&(in2==`FP_INFP))
       	{out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_ZEROP,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1};
       else
      	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_ZERON,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1};
     end
     else if ((in2==`FP_ZEROP)||(in2==`FP_ZERON)) begin
         if((S1 == 1'b1)&&(in2==`FP_ZEROP))
       	  {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_INFN,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1};
         else if((S1 == 1'b1)&&(in2==`FP_ZERON))
        	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_INFP,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1};
         else if((S1 == 1'b0)&&(in2==`FP_ZEROP))
         	{out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_INFP,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1};
       else
      	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_INFN,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b1};
     end
     else if((in1 == `FP_NANS)||(in2 == `FP_NANS))
    	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_NANQ,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,1'b1};
    else
	{out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c} = {`FP_NANQ,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0,~rst};
  end


  always @(posedge clk or negedge rst) begin // calculate forward exceptions
  if(!rst) begin
  	  {out_f,ov_f,un_f,done_f,inv_f,div_zero_f,inexact_f,forward} <= {32'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
    end
   else begin
     {out_f,ov_f,un_f,done_f,inv_f,div_zero_f,inexact_f,forward} <= {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,div_zero_f_c,inexact_f_c,forward_c};
   end
  end


  always @* begin
    {M1,M2} = {{1'b1,in1[M:0],2'b00},{1'b1,in2[M:0],2'b00}};
  end

  // Determine sign
  assign S0 = S1^S2;

  always @* begin
    Mf1 = M1;
    Mf2 = M2 ;
    Ef1 = E1;
    Ef2 = E2;
    sticky = 1'b0;
   t=1'b0;
    for( i = 0; i < M+3; i = i+1) begin //The fixed point division algo requires that Mantissa 1 (M1) be less than Mantissa 2 (M2)

      if(Mf1 >= Mf2) begin
        if(Mf1[0]) begin
           t = 1'b1;
        end
        Mf1 =  Mf1 >> 1;
        Ef1 = Ef1  +1;
      end
    end

  end


  //calculate exponent
  always @* begin
    if(Ef1>Ef2) begin
    E01 = Ef1-Ef2+`B;

    end
    else begin
      E01 = `B-(Ef2-Ef1);
    end
  end

  divide_r  div1i(.num(Mf1),.den(Mf2),.quot(M0r),.sticky(tdiv),.clk(clk),.rst(rst),.done(done0),.remo(rem));

  always @(posedge clk or negedge rst) begin
  	if(!rst)
    {M00r,done0_reg} <= {26'b0,1'b0};
   	else
    {M00r,done0_reg} <= {M0r,done0};
  end


  always @*
    begin // normalize to scientific notation and standard
      M01 = M00r;
      E0 = E01;
      for(i=0;i<= M+3;i=i+1) begin
        if(M01[M+3] == 1'b0) begin
           	M01 = M01 << 1;
          	E0 = E0 - 1;
          end
        end

    end


  always @* begin // rounding schemes
    next_number = {E0,M01[M+2:2]};
    next_number = next_number +1;


    g = M01[1]; // round (actually)
    tmerge = t|tdiv;
    l= M01[2]; // lsb


    if((round_m == `RD)||((!S0)&(round_m==`RZ))||((round_m == `RU)&&(S0))) begin// RD or RZ (RU for x < 0)
     	M0 = M01[M+2:2];
      	Eround = E0;
    end

    else if(round_m == `RNe) begin //RN ties to even
      case ({g,tmerge})
        2'b00: begin
          M0 = M01[M+2:2];
          Eround = E0;
        end
        2'b01:begin
          M0 = M01[M+2:2];
          Eround = E0;
        end
        2'b10: begin
          if(next_number[0] == 1'b0) begin
            M0 = next_number[M:0];
          	Eround = next_number[E:M+1];
          end
          else begin
            M0 = M01[M+2:2];
            Eround = E0;
          end
        end
        2'b11:begin
           M0 = next_number[M:0];
           Eround = next_number[E:M+1];
        end
      endcase
    end

    else if (((round_m == `RU)&&(!S0))||(S0&(round_m==`RZ))) begin //RU(x>=0) or RZ
      if({g,tmerge} == 2'b00) begin
         M0 = M01[M+2:2];
         Eround = E0;
      end
      else begin
        M0 = next_number[M:0];
        Eround = next_number[E:M+1];
      end
    end

    else if(round_m == `RNa) begin //RN ties to away
      case ({g,tmerge})
        2'b00: begin
          M0 = M01[M+2:2];
          Eround = E0;
        end
        2'b01:begin
          M0 = M01[M+2:2];
          Eround = E0;
        end
        2'b10: begin
            M0 = next_number[M:0];
          	Eround = next_number[E:M+1];
        end
        2'b11:begin
           M0 = next_number[M:0];
           Eround = next_number[E:M+1];
        end
      endcase
    end
    else begin
          M0 = M01[M+2:2];
          Eround = E0;
    end
  ///////////////////////////////////////////////////////////////////// inexact flag calculation
    if((M0 == M01[M+2:2])&&(t == 0)&&(g == 0)) begin
    	inexact0 = 1'b0;
    	done1 = done0_reg;
    end
   	 else begin
        inexact0 = 1'b1;
    	done1= done0_reg;
     end

  end

    // determine overflow or underflow
  always @* begin
    {ov0,un0} = {(E01>254|E0>254)?1'b1:1'b0,(E01<1|E0<1)?1'b1:1'b0};
  end


  always @(posedge clk or negedge rst)  begin// output the values and exceptions
    if(!rst) begin
      {out[W-1],out[E:M+1],out[M:0],ov,un,done,inv,div_zero,inexact} <= {1'b0,8'b0,23'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
    end

    else begin
      if(!forward)
      {out[M:0],out[E:M+1],out[W-1],ov,un,done,inv,div_zero,inexact} <= {M0,E0,S0,ov0,un0,done1,1'b0,1'b0,inexact0};
      else
      	{out,ov,un,done,inv,div_zero,inexact} <= {out_f,ov_f,un_f,done_f,inv_f,div_zero_f,inexact_f};
    end

  end
endmodule
