`include "fpu.v"
`include "fp_add.v"
`include "fp_mul.v"
`include "fp_div.v"
`include "fp_comp.v"
`include "fp_sqr.v"

module top_tb();
  parameter WIDTH = 32;
  
  logic [WIDTH-1:0] in1,in2,out;
  logic [2:0] round_m;
 
  logic ov,un,clk,rst,eq,great,less,act,done,inv,enable_add,power_off_add,retain_add,isolate_add;
  logic [2:0] op;
  //-1.35
  
 initial begin
    clk =0;
    enable_add= 1'b1;
    retain_add = 1'b1;
    power_off_add = 1'b0;
    isolate_add = 1'b0;
    round_m = 3'b001;
    act = 1;
    rst = 1;
    in1 = 32'b00111111100011001100110011001101;//1.1
    in2 = 32'b10111111101001100110011001100110; //1.3
    op = 3'b10;
    #1
    rst = 0;
    #1 
    rst = 1;
    #350
    act = 0;
    #5
    act = 1;
    op = 3'b01;
    #350
    act = 0;
   #4
   act = 1;
    op = 3'b00;
    #350
    op = 3'b11;
    #450
    rst = 0;
    #1 
    rst = 1;
    in1 = 32'b01000011101000001100110011001101;//321.6
    in2 = 32'b10111111111001100110011001100110;// 1.8
    #350
    act = 0;
    #4
    act = 1;
    op = 3'b10;
    #350
    act = 0;
    #4
    act = 1;
    op = 3'b01;
    #350
    act = 0;
    #4
    act = 1;
    op = 3'b00;
   #350
   act = 0;
   #4
   act = 1;
    op = 3'b100;
   #350
    $finish;
  end


  
  always #50 clk = ~clk;


  
  fpu  fpu1(.isolate_add(isolate_add),.retain_add(retain_add),.in1p(in1),.power_off_add(power_off_add),.enable_add(enable_add),.in2p(in2),.out(out),.ov(ov),.un(un),.opcode(op),.clk(clk),.rstp(rst),.eq(eq),.great(great),.less(less),.round_mp(round_m),.act(act),.done(done),.inv(inv));
  
  
  
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0);
  end
  
  

  
endmodule
