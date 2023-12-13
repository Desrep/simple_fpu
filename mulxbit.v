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

// fixed point multiplier

module mulxbit(in1,in2,out,done);
  parameter WIDTH = 24;
  input wire [WIDTH-1:0] in1,in2;
  output reg [2*WIDTH-1:0] out;
  output reg done;
  reg [2*WIDTH-1:0] out0;
  reg [2*WIDTH-1:0] partprod0 [WIDTH-1:0];
  reg [2*WIDTH-1:0] partprod1 [WIDTH-1:0];
  reg done0;
  integer i;
  wire [2*WIDTH-1:0] temp;

  assign temp = in1;



 always @*
   begin
     for(i= 0; i<WIDTH/4;i=i+1) begin
       if( in2[i] == 1'b1)
         partprod0[i] = (temp<<i);
       if(in2[i+(WIDTH/4)]==1'b1)
         partprod0[i+(WIDTH/4)] = (temp << (i+(WIDTH/4)));
       if(in2[i+2*(WIDTH/4)]==1'b1)
         partprod0[i+2*(WIDTH/4)] = (temp << (i+2*(WIDTH/4)));
       if(in2[i+3*(WIDTH/4)]==1'b1)
         partprod0[i+3*(WIDTH/4)] = (temp << (i+3*(WIDTH/4)));
       if (in2[i] == 1'b0)
         partprod0[i] = 1'b0;
       if(in2[i+(WIDTH/4)]== 1'b0)
         partprod0[i+(WIDTH/4)] = 1'b0;
       if(in2[i+2*(WIDTH/4)]== 1'b0)
         partprod0[i+2*(WIDTH/4)] = 1'b0;
       if(in2[i+3*(WIDTH/4)]== 1'b0)
         partprod0[i+3*(WIDTH/4)] = 1'b0;
     end
   end


always @* begin
  out0=0;
  done0 = 0;
  for(i = 0;i<WIDTH/6;i= i+1) begin
    out0 = out0 + partprod0[i]+partprod0[i+(WIDTH/6)]+ partprod0[i+2*(WIDTH/6)]+partprod0[i+3*(WIDTH/6)]+partprod0[i+4*(WIDTH/6)]+partprod0[i+5*(WIDTH/6)];
     if(i == (WIDTH/6)-1)
    	done0 = 1;
  end

end


always @* begin
     out =out0;
  	 done = done0;
end

endmodule
