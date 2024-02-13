module top_tb();
 
  //tap instructions
  localparam BYPASS = 4'b0000;
  localparam SAMPLE = 4'b0001;
  localparam PRELOAD = 4'b0010;
  localparam EXTEST = 4'b0011;
  localparam RUN_MBIST = 4'b0100;
  localparam RUNSCAN = 4'b0101;
  localparam INTEST = 4'b0110;
  localparam PROG_MBIST = 4'b0111;
  localparam PROG_LBIST = 4'b1001;
  localparam RUN_LBIST = 4'b1010;
  



  parameter WIDTH = 32;
  
  logic [WIDTH-1:0] in1,in2,out;
  logic [2:0] round_m;
 
  logic ov,un,clk,rst,eq,great,less,act,done,inv,dz,inxt,enable,load_fp;
  logic [2:0] op;
  logic [4:0] addr1,addr2,addr3;
  logic test_mode;
  logic tdi,tdo,tck,tms;
  logic [10:0] mbist_ir;
  logic [3:0] ir;
  




 initial begin 
    //fill memory
    ir = BYPASS;
    mbist_ir = 11'b01110100000;
    tms = 1;
    ///

    round_m = 3'b001;
    rst = 1;
    #1
    rst = 0;
    #1
    rst = 1;
    test_mode = 0;
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
   /// start mbist
   //////////////////////////////////////
   ////////////////////////////////////
   mbist_ir =  11'b01110100010;
   ir = RUN_MBIST;
   #1700
   /////Test tapc
   /////////////////////////////
   tms = 0;
   @(posedge clk);
   tms = 1;
   @(posedge clk);
   tms = 0;
   @(posedge clk);
   #1
   @(posedge clk);
   #50
   tms =1;
   @(posedge clk);
   #1
   @(posedge clk);
   #1
   tms = 0;
   @(posedge clk);
   #1
   tms = 1;
   @(posedge clk);
   #1
   @(posedge clk);
   tms = 0;
   @(posedge clk);
   #1
   @(posedge clk);
   #50
   tms =1;
   @(posedge clk);
   #1
   @(posedge clk);
   tms =0;
   #1
   @(posedge clk);
   tms =1;
   #40

    $finish;
  end


  
  always #5 clk = ~clk;


  
  fpu  fpu1(.inexact(inxt),.addr1(addr1),.addr2(addr2),.addr3(addr3),.enable(enable),.ld(load_fp),.inp(in1),.out(out),.ov(ov),.un(un),.opcode_in(op),.clk(clk),.rstp(rst),.eq(eq),.great(great),.less(less),.round_mp(round_m),.act(act),.done(done),.inv(inv),.div_zero(dz),.test_mode(test_mode),.tdi(tdi),.tdo(tdo),.tck(clk),.ir(ir),.mbist_inst_reg(mbist_ir),.tms(tms));
  
  
  
  initial begin 
    #1900	  
    $dumpfile("wave.vcd");
    $dumpvars(0);
  end
  
  

  
endmodule
