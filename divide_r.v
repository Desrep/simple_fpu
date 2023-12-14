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
// unsigned restoring fraction divider, fixed point division
// num <= den
// since it's restoring the remainder is positive

module divide_r(num,den,quot,remo,sticky,clk,rst,done);
  parameter WIDTH = 26;
  parameter STAGES = 6;
  input [WIDTH-1:0] num,den;
  input clk;
  input rst;
  output reg done;
  output reg sticky;
  output reg [WIDTH-1:0] quot,remo;


  reg [WIDTH-1:0] quotf;
  reg [WIDTH:0] den_minus;


  reg [WIDTH:0] rem [STAGES:0];
  reg [WIDTH:0] rem_reg [STAGES:0];
  reg [WIDTH-1:0] quoti [STAGES:0];
  reg [WIDTH:0] quot_reg [STAGES:0];
  reg donei [STAGES:0];
  reg done_reg [STAGES:0];

  integer i;
  genvar j;

  always @* begin
    rem_reg[0] = num;
    done_reg[0] = 1;
    den_minus = ~den;
    den_minus = den_minus + 1; // -den
    quot_reg[0] = 0;
  end


generate
   for(j=1;j<=STAGES;j=j+1) begin

  always @* begin

    rem[j] = rem_reg[j-1];
    quoti[j] = quot_reg[j-1];

    for (i = (((STAGES-j+1)*WIDTH)/STAGES)-1;i>=((STAGES-j)*WIDTH)/STAGES;i=i-1) begin

      rem[j] = rem[j] << 1;
      rem[j] = rem[j]+den_minus; // 2r-D


      if(!(rem[j]&({1'b1,{(WIDTH){1'b0}}}))||(|rem[j] == 0)) begin
        quoti[j]= quoti[j]|({{(WIDTH-1){1'b0}},1'b1} << i); // q(i) = 1;

      end
      else begin
        quoti[j]= quoti[j]&(~({{(WIDTH-1){1'b0}},1'b1} << i)); // q(i) = 0
        rem[j] = rem[j]+den;// 2r + D   //this is the restoring step

      end

      if(i == ((STAGES-j)*WIDTH)/STAGES) begin
        	donei[j] = done_reg[j-1];
      end else begin
        	donei[j] =0;
      end

    end

  end

if(j != STAGES) begin

  always @(posedge clk or negedge rst) begin
    if(!rst)
    {quot_reg[j],rem_reg[j],done_reg[j]} <= {27'b0,27'b0,1'b0};
    else
    {quot_reg[j],rem_reg[j],done_reg[j]} <= {quoti[j],rem[j],donei[j]};
  end

end

   end

endgenerate

always @* begin //final output
    quotf = quoti[STAGES];
    quot= {1'b0,quotf[WIDTH-1:1]};
    sticky = |rem[STAGES]; // if remainder is nonzero set the sticky bit
    done = donei[STAGES];
    remo = rem[STAGES];
  end

endmodule


