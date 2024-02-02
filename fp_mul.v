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
// fp multiplication of 2 32 bit fp numbers
// 5 rounding modes implemented
//
// fp multiplication of 2 32 bit fp numbers
// 5 rounding modes implemented
`include "special_characters.v"
`include "mulxbit.v"
module fp_mul(in1,in2,out,ov,un,clk,rst,round_m,act,inv,inexact);
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
  output reg ov,un,inv,inexact;
  wire [E-M-1:0] E1,E2;
  reg [E-M-1:0] E0,E01,E001,Eround;
  reg [M+1:0] M1,M2;
  
  reg ov_f,un_f,done_f,inv_f,inexact_f; //forward exception variables
  reg ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c; //forward exception variables
  reg [W-1:0] out_f,out_f_c;
  reg forward,forward_c; // forward an exception
  reg ov0,un0,inexact0;
  wire [2*M+3:0] M00;
  reg [E:0] next_number;
  reg [2*M+3:0] M000,M01;
  
  reg t,g,l;
  reg [M:0] Mround;
  reg [M:0] M0;
  wire done0;
  reg done0_reg,done1;
  wire S1,S2,S0;
  integer i;

  //initialize values
 assign  E1  = in1[E:M+1];
 assign E2 = in2[E:M+1] ;
 assign S1 = in1[W-1];
  assign S2 = in2[W-1];

  
 // the following are exceptions
 always @* begin
     
     if(((in1 == `FP_INFP)&&(in2 == `FP_ZEROP))||((in1 == `FP_INFN)&&(in2 == `FP_ZEROP))
        	||((in1 == `FP_INFP)&&(in2 == `FP_ZERON))||((in1 == `FP_INFN)&&(in2 == `FP_ZERON)))
     			{out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_NANQ,1'b0,1'b0,1'b1,1'b1,1'b0,1'b1};
     else if( (in1 == `FP_ZEROP) || (in2 == `FP_ZEROP) || (in1 == `FP_ZERON) || (in2 == `FP_ZERON)) begin // Case for cero
       {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {32'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b1};
    end
     else if((in1 == `FP_NANS)||(in2 == `FP_NANS))
     	{out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_NANQ,1'b0,1'b0,1'b1,1'b1,1'b0,1'b1};
     else if( (in1 == `FP_INFP) || (in2 == `FP_INFP) || (in1 == `FP_INFN) || (in2 == `FP_INFN)) begin 
          if(((in1 == `FP_INFP)&&(in2 == `FP_INFN))||((in1 == `FP_INFN)&&(in2 == `FP_INFP)))
          {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_INFN,1'b0,1'b0,1'b1,1'b0,1'b0,1'b1};
       else if(((in1 == `FP_INFP)&&(in2 == `FP_INFP))||((in1 == `FP_INFN)&&(in2 == `FP_INFN)))
       	{out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_INFP,1'b0,1'b0,1'b1,1'b0,1'b0,1'b1};
       else if((S1 == 1'b1)&&(in2 == `FP_INFP))     
      	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_INFN,1'b0,1'b0,1'b1,1'b0,1'b0,1'b1};
       else if((S1 == 1'b0)&&(in2 == `FP_INFP))
      	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_INFP,1'b0,1'b0,1'b1,1'b0,1'b0,1'b1};
       else if((S1 == 1'b1)&&(in2 == `FP_INFN))
     	  {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_INFP,1'b0,1'b0,1'b1,1'b0,1'b0,1'b1};
       else  
      	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_INFN,1'b0,1'b0,1'b1,1'b0,1'b0,1'b1};
     end
     else
 	{out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_INFN,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0}; 
  end
  
  
  

  always @(posedge clk or negedge rst) begin // Forward results (exceptions)
    if(!rst) begin
      {out_f,ov_f,un_f,done_f,inv_f,inexact_f,forward} <= {32'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
    end
   else begin
     {out_f,ov_f,un_f,done_f,inv_f,inexact_f,forward} <= {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c};
   end
    
  end
  
  always @* begin
    {M1,M2} = {{1'b1,in1[M:0]},{1'b1,in2[M:0]}};
  end

  // Determine sign
  assign S0 = S1^S2;




  // multiplication block (include hidden bit)
  mulxbit  m1 (.in1(M1),.in2(M2),.out(M00),.done(done0));
  //assign M00 = M1*M2;


  always @(posedge clk or negedge rst) begin
     if(!rst) 
     {M000,done0_reg} <= {48'b0,1'b0};
     else
     {M000,done0_reg} <= {M00,done0};
  end
 
    always @*
    begin // normalize to scientific notation and standard
      M01 = M000;
      E0 = E2+E1-`B; // calculate exponent
      t = |M01[M-1:0]; // sticky  
      if(M000[2*M+3] == 1'b1) begin
           M01 = M01 >> 1;
           E0 = E0 +1;
          end
    end
  
 
  always @* begin // rounding schemes
    next_number = {E0,M01[2*M+1:M+1]};
    next_number = next_number +1;
  	done1 = 0;  
  
    g = M01[M]; // round (actually)
   
    l= M01[M+1]; // lsb
    
    
    if((round_m == `RD)||((!S0)&(round_m==`RZ))||((round_m == `RU)&&(S0))) begin// RD or RZ (RU for x < 0)
     	 Mround = M01[2*M+1:M+1]; 
      	Eround = E0;
    end
    
    else if(round_m == `RNe) begin //RN ties to even
      case ({g,t})
        2'b00: begin
          Mround = M01[2*M+1:M+1];
          Eround = E0;
        end
        2'b01:begin
          Mround = M01[2*M+1:M+1];
          Eround = E0;
        end
        2'b10: begin
          if(next_number[0] == 1'b0) begin
            Mround = next_number[M:0];
          	Eround = next_number[E:M+1];
          end
          else begin
            Mround = M01[2*M+1:M+1];
           Eround = E0;
          end
        end
        2'b11:begin
           Mround = next_number[M:0];
           Eround = next_number[E:M+1];
        end 
      endcase
    end
    
    else if (((round_m == `RU)&&(!S0))||(S0&(round_m==`RZ))) begin //RU(x>=0) or RZ 
      
      
      if({g,t} == 2'b00) begin
        Mround = M01[2*M+1:M+1];
         Eround = E0;
      end
      else begin
        Mround = next_number[M:0];
        Eround = next_number[E:M+1];
      end 
    end

    else if(round_m == `RNa) begin //RN ties to away
      case ({g,t})
        2'b00: begin
          Mround = M01[2*M+1:M+1];
          Eround = E0;
        end
        2'b01:begin
          Mround = M01[2*M+1:M+1];
          Eround = E0;
        end
        2'b10: begin
            Mround = next_number[M:0];
          	Eround = next_number[E:M+1];
        end
        2'b11:begin
           Mround = next_number[M:0];
           Eround = next_number[E:M+1];

        end
      endcase
    end
    else begin
        Mround = M01[2*M+1:M+1];
        Eround = E0;

    end


  ///////////////////////////////////////////////////////////////////// inexact flag calculation
    if((Mround == M01[2*M+1:M+1])&&(t == 0)&&(g == 0)) begin
    	inexact0 = 1'b0;
    	done1 = done0_reg;
    end else begin
        inexact0 = 1'b1;
     	done1 = done0_reg;
     end
  end
 

    // determine overflow or underflow
  always @* begin
    {ov0,un0} = {(E0>254|Eround>254)?1'b1:1'b0,(E0<1|Eround<1)?1'b1:1'b0};
  end


  always @(posedge clk or negedge rst)  begin// output the values and exceptions
   if(!rst) begin
     	 {out[W-1],out[E:M+1],out[M:0],ov,un,inv,inexact} <= {1'b0,8'b0,23'b0,1'b0,1'b0,1'b0,1'b0};
   end
   else begin
     if(!forward)
     {out[M:0],out[E:M+1],out[W-1],ov,un,inv,inexact} <= {Mround,Eround,S0,ov0,un0,1'b0,inexact0};
     else
    	 {out,ov,un,inv,inexact} <= {out_f,ov_f,un_f,inv_f,inexact_f};
   end
    
  end
endmodule
