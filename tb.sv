module top_tb();
  parameter WIDTH = 32;
  
  logic [WIDTH-1:0] in1,in2,out;
  logic [2:0] round_m;
 
  logic ov,un,clk,rst,eq,great,less,act,done,inv,dz,inxt,enable,load_fp;
  logic [2:0] op;
  logic [4:0] addr1,addr2,addr3;

  //-1.35
  
 initial begin 
    //fill memory
    round_m = 3'b001;
    rst = 1;
    #1
    rst = 0;
    #1
    rst = 1;
    op = 3'b100;
    enable = 0;
    load_fp = 0;
    addr1 = 5'b00000;
    addr2 = 5'b00001;
    addr3 = 5'b00010;
    clk =0;
    in1 = 32'b00111111100011001100110011001101;//1.1
    #10
    addr1 = 5'b00001;
    in1 = 32'b10111111101001100110011001100110; //1.3
    #10
    addr1 = 5'b00000;
    in1 = 32'b01000011101000001100110011001101;//321.6
    addr1 = 5'b00011;
    #10;
    addr1 = 5'b00100;
    in1 = 32'b10111111111001100110011001100110;// 1.8
    #10
    
    // load registers 
    addr1 = 5'b00000;
    enable = 1;
    #10
    load_fp = 1;
    #10
    enable = 0;
    load_fp = 0;
    #10
    // Start operations
    op = 3'b10;
    enable = 1;
    #80
    op = 3'b01;
    #30
    op = 3'b00;
    #30
    op = 3'b11;
    #80
    enable  = 0;
    #10
  //load registers
    enable = 1;
    op = 3'b100;
    addr1 = 5'b00011;
    addr2 = 5'b00100;
    addr3 = 5'b00101;
    #10
    load_fp = 1;
    #10
    enable = 0;
    load_fp = 0;
    #10
    //start operations
    enable = 1;
    op = 3'b11;
    #80
    op = 3'b10;
    #80
    op = 3'b01;
    #30
    op = 3'b00;
   #30
    op = 3'b100;
   #30
    $finish;
  end


  
  always #5 clk = ~clk;


  
  fpu  fpu1(.inexact(inxt),.addr1(addr1),.addr2(addr2),.addr3(addr3),.enable(enable),.ld(load_fp),.inp(in1),.out(out),.ov(ov),.un(un),.opcode_in(op),.clk(clk),.rstp(rst),.eq(eq),.great(great),.less(less),.round_mp(round_m),.act(act),.done(done),.inv(inv),.div_zero(dz));
  
  
  
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0);
  end
  
  

  
endmodule
