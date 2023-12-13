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
// FP add for 32 bit numbers
//5 rounding modes implemented
//

// FP add for 32 bit numbers
//5 rounding modes implemented
`include "special_characters.v"
module fp_add(in1,in2,out,ov,un,clk,rst,round_m,done,act,inv,inexact);
  parameter W = 32;
  parameter M = 22;
  parameter E = 30;
  parameter IWID=M+4;
  parameter OWID = M+1;
  input [W-1:0] in1;
  input [W-1:0] in2;
  input [2:0] round_m;
  input clk,rst,act;
  output reg [W-1:0] out;
  output reg ov,un,done,inv,inexact;
  wire [E-M-1:0] E1,E2;
  reg [E-M-1:0] E0,E02,E002,E10,E20,Eround;
  reg [M+3:0] M1,M2,M10,M20,Mtemp;
  reg  [M+4:0] M00,M01,M000; //extra bit accounts for carry
  reg [M:0] M0;
   reg [E:0] next_number;
  reg ov_f,un_f,done_f,inv_f,inexact_f; //forward exception variables\
  reg ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c; //forward exception variables
  reg [W-1:0] out_f,out_f_c;
  reg forward,forward_c;
  reg ov0,un0,inexact0,t,l,g,tmerge;
  wire S1,S2;
  reg S0,S00;
  reg done0,done1,done0_r;
  integer i;

  //initialize values
  assign  E1  = in1[E:M+1];
  assign E2 = in2[E:M+1] ;
  assign S1 = in1[W-1];
  assign S2 = in2[W-1];





  always @* begin // pipelining
    {M10,M20,E20,E10} = {{1'b1,in1[M:0],2'b00},{1'b1,in2[M:0],2'b00},E2,E1};
  end


//the following are exceptions
  always @* begin

      if(((in1 == `FP_INFN)&&(in2 == `FP_INFP))||((in1 == `FP_INFP)&&(in2 == `FP_INFN)))
        	{out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_NANQ,1'b0,1'b0,1'b1,1'b1,1'b0,1'b1};
        else if(((M10==M20)&&(E1 == E2)&&(S1 != S2))||((in1 == `FP_ZERON)&&( in2 == `FP_ZERON))
               ||((in1 == `FP_ZEROP)&&( in2 == `FP_ZEROP))||((in1 == `FP_ZERON)&&( in2 == `FP_ZEROP))
               ||((in1 == `FP_ZEROP)&&( in2 == `FP_ZERON))) begin

         	 if( (!S1)&&(!S2))
           		  {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_ZEROP,1'b0,1'b0,1'b0,1'b0,1'b1};

      	    else if( ((!S1)&&(S2))||((S1)&&(!S2))) begin
              if((round_m==`RNe)||(round_m==`RNa)||(round_m==`RZ)||(round_m==`RU))
                	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_ZEROP,1'b0,1'b0,1'b0,1'b0,1'b1};
           		  else
                  	{out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_ZERON,1'b0,1'b0,1'b0,1'b0,1'b1};
          	 end

     		  else if( (S1)&&(S2)) begin
                {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_ZERON,1'b0,1'b0,1'b0,1'b0,1'b1};
          		 end
      		 else
            	 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_ZEROP,1'b0,1'b0,1'b0,1'b0,1'b1};

     	 end
        else if((in1 == `FP_NANS)||(in2 == `FP_NANS))
       		 {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_NANQ,1'b0,1'b0,1'b1,1'b1,1'b0,1'b1};
    	else
           {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c} = {`FP_NANQ,1'b0,1'b0,1'b1,1'b1,1'b0,1'b0};

  end


  always @(posedge clk or negedge rst) begin // exception forwarding
      if (!rst)
   		{out_f,ov_f,un_f,done_f,inv_f,inexact_f,forward} <= {0,0,0,1'b0,1'b0,1'b0,1'b0};
      else begin
        {out_f,ov_f,un_f,done_f,inv_f,inexact_f,forward} <= {out_f_c,ov_f_c,un_f_c,done_f_c,inv_f_c,inexact_f_c,forward_c};
      end
  end

  always @* begin // calculate shift for lower exponent number and sticky
    if (E20 > E10) begin
      Mtemp = {(M+4){1'b1}};
      Mtemp = Mtemp << (E20-E10);
      Mtemp = ~Mtemp;
      Mtemp = Mtemp&M10;
      t = |Mtemp;
      M1 = M10 >> (E20-E10);
      E02 = E20;
      M2 = M20;
    end
    else if( E10 > E20) begin
      Mtemp = {(M+4){1'b1}};
      Mtemp = Mtemp << (E10-E20);
      Mtemp = ~Mtemp;
      Mtemp = Mtemp&M20;
      t = |Mtemp;
      M2 = M20 >> (E10-E20);
      E02 = E10;
      M1 = M10;
    end
     else begin
       E02 = E10;
       M1 = M10;
       M2 = M20;
       t = 0;
     end
  end

  always @* // perform the sum or subtraction
    begin
      done0 = 0;
      case ({S1,S2})
        2'b00: begin
          M00 = M1+M2;
          S0 = 1'b0;
        end
        2'b01: begin
          if(M2>M1) begin
            M00 = M2-M1;
            S0 = 1'b1;
           end
          else if (M1 > M2) begin
            M00 = M1-M2;
            S0 = 1'b0;
          end
          else begin
            M00 = 0;
            S0 = 0;
          end
        end
        2'b10: begin
          if(M1 > M2) begin
             M00 = M1 - M2;
             S0 = 1'b1;
          end
          else if (M2 > M1) begin
             M00 = M2 - M1;
             S0 = 1'b0;
          end
          else begin //zero case
            M00 = 0;
            S0 = 0;
          end
        end
      2'b11: begin
          M00 = M2+M1;
          S0 = 1'b1;
        end
      endcase
      done0 = 1;
    end


 always @(posedge clk or negedge rst) begin
 	if(!rst)
    {M000,done0_r} <= {0,0};
   	else
    {M000,done0_r} <= {M00,done0};
 end


  always @*
    begin // normalize to scientific notation and standard
      M01 = M000;
      E0 = E02;
      for(i= 0; i <= M+4;i= i+1) begin
        if(M01[M+4] == 1'b0) begin
             M01 = M01 << 1;
             E0 = E0 -1;
        end
      end
      if(M01[M+4] == 1'b1) begin
      	M01 = M01 >> 1;
     	 E0 = E0 + 1;
      end
    end

  always @* begin // rounding schemes
    next_number = {E0,M01[M+2:2]};
    next_number = next_number +1;


    g = M01[1]; // round (actually)
    tmerge = t|M01[0];
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
    	done1 = done0_r;
    end else begin
        inexact0 = 1'b1;
      	done1 = done0_r;
    end

  end

  // determine overflow or underflow
  always @* begin

    {ov0,un0} = {(E02>254|Eround>254)?1:0,(E02<1|Eround<1)?1:0};

  end

  always @(posedge clk or negedge rst) begin // output values
      if (!rst)
     	 {out[W-1],out[E:M+1],out[M:0],ov,un,done,inv,inexact} <= {0,0,0,1'b0,1'b0,1'b1,1'b0,1'b0};
      else begin
        if(!forward)
        {out[W-1],out[E:M+1],out[M:0],ov,un,done,inv,inexact} <= {S0,Eround,M0,ov0,un0,done1,1'b0,inexact0};
        else
        {out,ov,un,done,inv,inexact} <= {out_f,ov_f,un_f,done_f,inv_f,inexact_f};
      end

  end


endmodule

