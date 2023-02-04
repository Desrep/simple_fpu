/* Copyright 2023 Fereie

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
// fp multiplication of 2 32 bit fp numbers
//pipelined fp multiplier, supports 2 of the 2 rounding modes truncate and round to nearest (even on tie)
// fp multiplication of 2 32 bit fp numbers
//5 rounding modes implemented
module fp_sqr(in1,out,ov,un,clk,rst,round_m,done,act,inv,inexact);
  parameter W = 32;
  parameter M = 22;
  parameter E = 30;
  parameter IWID=M+2;
  parameter OWID = M+1;
  input clk;
  input rst,act;
  input [W-1:0] in1;
  input [2:0] round_m; // rounding mode selector
  output reg [W-1:0] out;
  output reg ov,un,done,inv,inexact; // flags (inv,ov,un are exception flags)
  wire [E-M-1:0] E1;
  reg [E-M-1:0] Ef1;
  reg [E-M-1:0] E0,E01,E02,E001,Eround;
  reg [M+2:0] M1,Mf1;
  reg [M+3:0] M0r,M00r,M01;
  reg [M:0] M0;
  reg ov0,un0,inexact0;
  reg done0_r,done1;
  wire done0;
  reg [E:0] next_number;//next FP number
  reg l,g; // lsb and round bit
  wire t; // sticky bit
  reg ov_f,un_f,done_f,inv_f,inexact_f; //forward exception variables
   reg ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c; //forward exception variables
  reg [W-1:0] out_f,out_f_c;
  reg forward,forward_c;
  wire S1,S0;
  reg   [E-M-1:0] B = 127;
  integer i;
  

  //initialize values
  assign  E1  = in1[E:M+1]+1;
 assign S1 = in1[W-1];

  
  always @* begin // calculate forward_c exceptions
       if(S1==1'b1)
      	{out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_NANQ,0,0,1'b1,1'b1,1'b0,1'b1};
       else if((in1 == `FP_NANS))
      	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_NANQ,0,0,1'b1,1'b1,1'b0,1'b1};
       else if((in1 == `FP_INFP))
      	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_INFP,1'b1,1'b0,1'b1,1'b0,1'b0,1'b1};
       else
	   forward_c = 0;
 end
  
  
  always @(posedge clk or negedge rst) begin // calculate forward exceptions
     if(!rst)
     {out_f,ov_f,un_f,done_f,inv_f,inexact_f,forward} <= {0,0,0,0,0,0};
     else begin
       {out_f,ov_f,un_f,done_f,inv_f,inexact_f,forward} <= {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c};
     end
  end
  
  
  
  
/*
 the square root requires that the Mantissa be multiplied by 2 if 
 exponent is odd, the following always block does this
*/
  always @* begin // 
    M1 = {2'b01,in1[M:0]};
    if(E1[0] == 1'b1)
      M1 = M1<<1;
  end
  
  // Determine sign
  assign S0 = 0;
  
 
  //calculate exponent

   
  sqrt #(.WIDTH(M+3+1)) sq (.in({1'b0,M1}),.out(M0r),.sticky(t),.clk(clk),.rst(rst),.done(done0)); // add one more bit than the Width to be able to perform the arithmetic inside sqrt
 
  always @(posedge clk or negedge rst) begin// pipeline?????
	if(!rst)
    {M00r,done0_r} <= {0,0};
	else
    {M00r,done0_r} <= {M0r,done0};

 end	 

  
   
  always @* begin // rounding schemes
    M01 = M00r;
    E0=E1>>1; //calculate exponent
    E0 = E0 +63;
    next_number = {E0,M01[M+2:2]};
    next_number = next_number +1;
    
  
    g = M01[1]; // round bit (actually)
   
    l= M01[2]; // lsb
    
   
    if((round_m == `RD)||((!S0)&(round_m==`RZ))||((round_m == `RU)&&(S0))) begin// RD or RZ (RU for x < 0)
     	M0 = M01[M+2:2]; 
      	Eround = E0;
    end
    
    else if(round_m == `RNe) begin //RN ties to even
      case ({g,t})
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
      if({g,t} == 2'b00) begin
         M0 = M01[M+2:2];
         Eround = E0;
      end
      else begin
        M0 = next_number[M:0];
        Eround = next_number[E:M+1];
      end
    end
    

    else if(round_m == `RNa) begin //RN ties to away
      case ({g,t})
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
    
  ///////////////////////////////////////////////////////////////////// inexact flag calculation
    if((M0 == M01[M+2:2])&&(t == 0)&&(g == 0)) begin
    	inexact0 = 1'b0;
    	done1 = done0_r;
    end else begin
        inexact0 = 1'b1;
    	done1 = done0_r;
    end
  end
  
  

    // determine overflow or underflow
  always @* begin
    {ov0,un0} = {(E0>254|E0>254)?1'b1:1'b0,(E0<1|E0<1)?1'b1:1'b0}; 
  end
  
  
  always @(posedge clk or negedge rst)  begin// output the values and exceptions
      if(!rst)
      {out[M:0],out[E:M+1],out[W-1],ov,un,done,inv,inexact} <= {0,0,0,0,0,0,0,0};
     else begin
       if(!forward)
       {out[M:0],out[E:M+1],out[W-1],ov,un,done,inv,inexact} <= {M0,E0,S0,ov0,un0,done1,1'b0,inexact0};
       else
        {out,ov,un,done,inv,inexact} <= {out_f,ov_f,un_f,done_f,inv_f,inexact_f};
     end
  end
  
  
  
endmodule
