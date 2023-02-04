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