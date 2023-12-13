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
`define FP_ZEROP {1'b0,8'h00,23'b0} // positive zero
`define FP_ZERON {1'b1,8'h00,23'b0} // negative zero
`define FP_INFP {1'b0,8'hFF,23'b0} //positive infinity 
`define FP_INFN {1'b1,8'hFF,23'b0} // negative infinity
`define FP_NANQ {1'b0,8'hFF,1'b1,22'b0} // quiet NAN
`define FP_NANS {1'b0,8'hFF,1'b0,22'b0} // signaling NAN
`define RD 3'b000 // round towards minus infinity 
`define RNe 3'b001 // Round to nearest ties to even
`define RU 3'b010 // Round towards plus infinity
`define RZ 3'b011 // Round towards zero
`define RNa 3'b100 // RN ties to away