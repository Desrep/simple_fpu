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
// square root
// Restoring algorithm
// Remainder is positive since it's a restoring algorithm
module sqrt(in,out,sticky,clk,rst,done);
  parameter WIDTH = 8;
  parameter STAGES = 9; // control the number of pipeline stages
  input [WIDTH-1:0] in;
  input rst,clk;
  output reg sticky;
  output reg done;
  output reg [WIDTH-1:0] out;
  
  
  reg [WIDTH-1:0] quotf,quot_temp;
  reg [WIDTH-1:0] quot [STAGES:0];
  reg [WIDTH-1:0] quot_double [STAGES:0];
  reg [WIDTH-1:0] quot_reg [STAGES:0];
  
  reg [WIDTH-1:0] twop [STAGES:0];
  reg [WIDTH-1:0] twop_double [STAGES:0];
  reg [WIDTH-1:0] twop_reg [STAGES:0];
  
  reg [2*WIDTH-1:0] rem [STAGES:0];
  reg [2*WIDTH-1:0] rem_double [STAGES:0];
  reg [2*WIDTH-1:0] rem_reg [STAGES:0];
  
  
  reg donei [STAGES:0];
  reg done_reg [STAGES:0];
  
  integer i;
  genvar j;
  
 always @* begin
   twop_reg[0] = {1'b0,1'b1,{(WIDTH-2){1'b0}}};//2^-1   
   rem_reg[0] = in;
   quot_reg[0] = 0;
   done_reg[0] = 1'b1;
 end

 generate
   for(j=1;j<=STAGES;j=j+1) begin
  
  always @* begin    
    twop[j] = twop_reg[j-1];
    rem[j] = rem_reg[j-1];
    quot[j]= quot_reg[j-1];
    
    for (i = ((j-1)*WIDTH/STAGES);i < (j*WIDTH/STAGES);i=i+1) begin 
      rem_double[j] = rem[j] << 1;
        quot_double[j] = quot[j];
      quot_double[j] = quot_double[j]&({(WIDTH){1'b1}}>>1); // 0.q1q2....
        quot_double[j] = quot_double[j] << 1;//2qi
        
      	 twop_double[j] = twop[j] >> i;// 2^-i
     	 rem[j] = rem_double[j]-(quot_double[j]+twop_double[j]); // 2r  -(2qi-2^-i)

      if(((rem[j]&({1'b1,{(2*WIDTH-1){1'b0}}}))== 0)||(|rem[j]== 0)) begin // 2R >= 0?
        quot[j]= quot[j]|({1'b1,{(WIDTH-1){1'b0}}}>>(i+1)); // q(i) = 1
      end
      else begin
        quot[j] = quot[j]&(~({1'b1,{(WIDTH-1){1'b0}}}>>(i+1))); // q(i) = 0
        rem[j] = rem_double[j];// restore remi = 2remi-1     
      end
      if(i == (j*WIDTH/STAGES)-1)
        donei[j]=done_reg[j-1];
      else
        donei[j] = 0;
    end
  end
  
  
 if(j != STAGES) begin 
  	always @(posedge clk or negedge rst) begin
      if(!rst)
   	  {quot_reg[j],rem_reg[j],twop_reg[j],done_reg[j]} <= {0,0,0,0};
    	else
      	  {quot_reg[j],rem_reg[j],twop_reg[j],done_reg[j]}  <= {quot[j],rem[j],twop[j],donei[j]};
      end
  end
  
   end
 endgenerate
  

  
  always @* begin // final output
	quotf = quot[STAGES];
    for(i = 0; i<WIDTH;i=i+1) begin
      if(!quotf[WIDTH-1])
        quotf = quotf <<1;
      else
        quotf = quotf;
    end
    
      out= quotf;
      sticky = |rem[STAGES];// if remainder is nonzero set the sticky bit
      done = donei[STAGES];
  end 
  
  
  
  


endmodule
