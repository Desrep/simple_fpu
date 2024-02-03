module top_tb();
  parameter WIDTH = 32;
  
  logic [WIDTH-1:0] in1,in2,out;
  logic [2:0] round_m;
 
  logic ov,un,clk,rst,eq,great,less,act,done,inv,dz,inxt,enable,load_fp;
  logic [2:0] op;
  logic [4:0] addr1,addr2,addr3;
  logic scan_e,scan_i,scan_o,test_mode;
  //-1.35
  logic [1971:0] test_vector;
  int errors;
  int index;
  int index2;
  logic [4:0] test_pattern;
 initial begin 
    // intial values
    test_pattern = 5'b01100;
    errors = 0;
    scan_e = 0;
    test_mode = 0;
    index = 0;
    scan_i = 0;
    index2=0;
    clk = 0;
    rst = 1;
    //start shift mode
    test_mode =1;
    scan_e =1;
     
     //stuck at 0-1 test
     //This can be reduced to 1974 -1 to reduce time
     while(index<2*1972-1) begin // at the end of the shift the first one is already at the output so we reduce 2 from normal logic for
     	@(posedge clk);
	 #1// reset the wait
	 if(index<1972)
		test_vector[index] = scan_i;
	index++;
	scan_i = ~scan_i;
        if(index>=1972) begin
                $display("scan_o = %d and test_vector = %d errores = %d scan_cell_number = %d",scan_o,test_vector[index2],errors,index);

                if(scan_o !== test_vector[index2])begin //compare to test vector
                        errors++;
                end
                index2++;
        end
     end
     index = 0;
     index2 = 0;
     
     //transition test 0-0 1-1 1-0 0-1
     while(index<1972+4) begin // at the end of the shift the first one is already at the output so we reduce 2 from normal logic for
	if(index<5)
		scan_i=test_pattern[index];
	@(posedge clk);
	#1
        index++;
        if(index>=1972) begin
                $display("scan_o = %d and test_vector = %d errores = %d scan_cell_number = %d",scan_o,test_pattern[index2],errors,index);

                if(scan_o !== test_pattern[index2])begin //compare to test vector
                        errors++;
                end
                index2++;
        end
     end



     if(errors)begin
	     $display("******************************************************");
	     $display("**************SCAN SHIFT FAILED**********************");
	     $display("******************************************************");
     end    
     else begin
	     $display("******************************************************");
	     $display("*************SCAN SHIFT CORRECT**********************");
	     $display("******************************************************");
     end

     $finish;

    
  end


  always #25 clk = ~clk;
  
  
  fpu  fpu1(.inexact(inxt),.addr1(addr1),.addr2(addr2),.addr3(addr3),.enable(enable),.ld(load_fp),.inp(in1),.out(out),.ov(ov),.un(un),.opcode_in(op),.clk(clk),.rstp(rst),.eq(eq),.great(great),.less(less),.round_mp(round_m),.act(act),.done(done),.inv(inv),.div_zero(dz),.scan_data_in(scan_i),.scan_data_out(scan_o),.scan_enable(scan_e),.test_mode(test_mode));
  
  
  
  initial begin
   // $dumpfile("wave.vcd");
   //$dumpvars(0);
  end
  
  

  
endmodule
