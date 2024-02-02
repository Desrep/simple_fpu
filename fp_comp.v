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
// Simple FP comparator
//

`include "special_characters.v"
module fp_comp(in1,in2,eq,great,less,clk,rst,inv);
  parameter W = 32;
  parameter M = 22;
  parameter E = 30;
  input [31:0] in1,in2;
  input clk,rst;
  output reg eq,great,less,inv;
  reg   eq0,great0,less0,done0;
  wire [E-M-1:0] E1,E2;
  wire [M:0] M1,M2;
  wire S1,S2;
  reg ov_f,un_f,done_f,inv_f,inexact_f,less_f,eq_f,great_f; //forward exception variables
  reg forward;

  assign  E1  = in1[E:M+1];
  assign E2 = in2[E:M+1] ;
  assign S1 = in1[W-1];
  assign S2 = in2[W-1];
  assign M1 = in1[M:0];
  assign M2 = in2[M:0];



  always @(posedge clk or negedge rst) begin //exceptions
     if(!rst)
     	{less_f,eq_f,great_f,done_f,inv_f,forward} <= {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0};
    else begin
      if((in1 == `FP_NANS)||(in2 == `FP_NANS))
        {less_f,eq_f,great_f,done_f,inv_f,forward} <= {1'b0,1'b0,1'b0,1'b1,1'b1,1'b1};
      else  if( ((in1==`FP_ZEROP)&&(in2==`FP_ZERON))||((in1==`FP_ZERON)&&(in2==`FP_ZEROP)))
       {less_f,eq_f,great_f,done_f,inv_f,forward} <= {1'b0,1'b1,1'b0,1'b1,1'b1,1'b1};
      else if( (in1 == `FP_INFP) || (in2 == `FP_INFP) || (in1 == `FP_INFN) || (in2 == `FP_INFN))
       {less_f,eq_f,great_f,done_f,inv_f,forward} <= {1'b0,1'b0,1'b0,1'b1,1'b1,1'b1};
       else
	{less_f,eq_f,great_f,done_f,inv_f,forward} <= {1'b0,1'b0,1'b0,1'b1,1'b1,1'b1};
      end
  end


  always @* begin
    done0 = 0;
    if(S1 == S2) begin
      if ( E1 == E2) begin
        if(M1 == M2) begin
          eq0 = 1'b1;
          less0 =1'b0;
          great0 = 1'b0;
          done0 = 1'b1;
        end
        else begin
          if(M1 > M2) begin
            great0 = 1'b1;
            less0 = 1'b0;
            eq0 = 1'b0;
            done0 = 1'b1;
          end
          else begin
            great0 = 1'b0;
            less0 = 1'b1;
            eq0 = 1'b0;
            done0 = 1'b1;
          end

        end
      end
      else begin
        if(E1 > E2) begin
           great0 = 1'b1;
           less0 = 1'b0;
           eq0 = 1'b0;
          done0 = 1'b1;
        end
        else begin
           great0 = 1'b0;
           less0 = 1'b1;
           eq0 = 1'b0;
          done0 = 1'b1;
        end
      end

    end
    else begin
      if(S1 == 1'b1) begin
          less0 = 1'b1;
           great0 = 1'b0;
           eq0 = 1'b0;
           done0 = 1'b1;
      end
      else begin
          great0 = 1'b1;
          less0 = 1'b0;
           eq0 = 1'b0;
           done0 = 1'b1;
      end
    end
  end

  always @(posedge clk or negedge rst) begin
    if(!rst)
    	{less,eq,great,inv} <= {1'b0,1'b0,1'b0,1'b0};
    else begin
      if(!forward)
      		{less,eq,great,inv} <= {less0,eq0,great0,1'b0};
      else
    	  {less,eq,great,inv} <= {less_f,eq_f,great_f,inv_f};
      end
  end

endmodule
