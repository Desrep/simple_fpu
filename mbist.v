//`define SA0_FAULT   // uncoment to inyect a stuck at 0 fault in the sram for now
//`define SA1_FAULT  // stuck at 1 fault inyection
// Code your design here
`define MODE_BIT 0
`define INIT_BIT 1
`define DONE_BIT 2
`define PASS_FAIL_BIT 3
`define ADDRESS_BIT 4


module mbist(reg_input,clk,rst,reg_out,write,read,addr,input_data,output_data,web);
  localparam width = 32;
  //states
  localparam IDLE_RST = 4'b0000;
  localparam WRT = 4'b0001;
  localparam READ = 4'b0010;
  localparam COMPARE = 4'b0011;
  localparam COMPLETE = 4'b0100;
  localparam COUNT_UP = 4'b0101;
  localparam COMPLETE_FAIL = 4'b0110;
  localparam LFSR = 4'b0111;
  localparam MISR = 4'b1000;
  localparam COMP_MISR = 4'b1001;
  localparam TEST_MISR = 4'b1010;
  localparam CAPTURE_LFSR = 4'b1011;
  localparam CAPTURE_MISR = 4'b1100;
  localparam CAPTURE_DATA = 4'b1101;
  
 
  //constants
  localparam addr_bits = 5;
  localparam misr_width = 8;
  localparam lfsr_width = 8;
  localparam depth = 1<<addr_bits;
  localparam misr_depth = 1<<misr_width;
  localparam LFSR_SEED = 32'h5F43FAB1;
  
  //test patterns
  localparam ZERO_PATTERN = 32'h00000000;
  localparam ONE_PATTERN = 32'hFFFFFFFF;
  localparam CHK_PATTERN = 32'h55555555;
  localparam INCORRECT_PATTERN = 32'hF50F5F0F;
  
  //inputs and outputs
  input [10:0] reg_input;
  input rst;
  input clk;
  output reg [addr_bits-1:0] addr;
  output reg write;
  output reg read;
  input [width-1:0] input_data;
  output reg [width-1:0] output_data;
  output reg [10:0] reg_out;
  output reg web;
  
  //additional signals
  reg [addr_bits-1:0] count;
  reg mode,init;
  reg [1:0] pattern;
  reg [addr_bits-1:0] address;
  reg [3:0] current_state, next_state;
  reg test_fail,mismatch;
  reg done;
  reg clear_count;
  reg [width-1:0] lfsr_pattern;
  reg [width-1:0] lfsr;
  reg [misr_width-1:0] misr;
  reg [width-1:0] misr_input;
  reg misr_mismatch;
  reg [lfsr_width:0] lfsr_count;///////////////
  reg [misr_width-1:0] misr_count;
  reg [misr_width-1:0] current_misr;
  reg [misr_width-1:0] misr_reference;
  reg [width-1:0] data_store;
  
//web calculation
always @*
  begin
    if(write&!read)
      web = 0; // write
    else if(!read&write)
      web = 1; //read 
    else
      web = 1;
  end
  
// read input configuration
always @*
  begin
    mode = reg_input[`MODE_BIT];
    init = reg_input[`INIT_BIT];
    address = reg_input[`ADDRESS_BIT+addr_bits-1:`ADDRESS_BIT];
    pattern = reg_input[10:`ADDRESS_BIT+addr_bits];
  end

//next_state calculation
  always @*
    begin
      case(current_state)
        IDLE_RST:begin
          if(init) begin
            if(pattern == 2'b11)
              next_state = LFSR;
            else
              next_state = WRT;
          end
          else
            next_state = IDLE_RST;
        end
        LFSR:begin
          if(!init)
            next_state = COMPLETE_FAIL;
          else begin
            if(lfsr_count == width-1+lfsr_width)
            	next_state = CAPTURE_LFSR;
          	else
            	next_state = LFSR;
          end
        end
        CAPTURE_LFSR:begin
          if(!init)
            next_state = COMPLETE_FAIL;
          else
            next_state = MISR;
        end
        MISR:begin
          if(!init)
            next_state = COMPLETE_FAIL;
          else begin
            if(misr_count == width-1)
              next_state = CAPTURE_MISR;
            else
              next_state = MISR;
          end
        end
        CAPTURE_MISR:begin
          if(!init)
            next_state = COMPLETE_FAIL;
          else
            next_state = WRT;
        end
        WRT:begin
          if(!init)
            next_state = COMPLETE_FAIL;
          else begin
            next_state = READ;
          end
        end
        READ:begin
          if(!init)
            next_state = COMPLETE_FAIL;
          else begin
            if(pattern == 2'b11)
            	next_state = CAPTURE_DATA;
            else
              next_state = COMPARE;
          end
        end
        CAPTURE_DATA:begin
          if(!init)
            next_state = COMPLETE_FAIL;
          else
            next_state = COMP_MISR;
        end
        COMPARE:begin
          if(mismatch)
            next_state = COMPLETE_FAIL;
          else begin
            if(!init)
              next_state = COMPLETE_FAIL;
            else begin
              if(mode)
                next_state = COMPLETE;
              else
                next_state = COUNT_UP;
            end
          end			
        end
        COMP_MISR:begin
          if(!init)
            next_state = COMPLETE_FAIL;
          else begin
            if(misr_count != width-1)
              next_state = COMP_MISR;
            else begin
              if(mode)
                next_state = COMPLETE;
              else 
				next_state = TEST_MISR;
            end             
          end
        end
        TEST_MISR:begin
          if(misr_mismatch)
            next_state = COMPLETE_FAIL;
          else begin
            if(!init)
              next_state = COMPLETE_FAIL;
            else
              next_state = COUNT_UP;
          end           
        end
        COUNT_UP:begin
          if(!init)
            next_state = COMPLETE_FAIL;
          else begin
            if(count == depth-1) // full test complete
              next_state = COMPLETE;
            else
              next_state = WRT;
          end
        end
        COMPLETE:begin
          if(!init)
            next_state = IDLE_RST;
          else
            next_state = COMPLETE;
        end
        COMPLETE_FAIL:begin
          if(!init)
            next_state = IDLE_RST;
          else
            next_state = COMPLETE_FAIL;
        end
        default:begin
        	next_state = current_state;
       	end
      endcase
    end
  
 // state actions
  
  always @*
    begin
      case(current_state)
        IDLE_RST:begin
          write =0;
          read = 0;
          test_fail = 0;
          clear_count = 1;
          mismatch =0;
          done = 0;
           misr_mismatch = 0;
        end
        WRT:begin
          write = 1;
          read = 0;
          test_fail = 0;
          clear_count = 0;
          mismatch =0;
          done = 0;
          misr_mismatch = 0;
          if(mode)
            addr = address;
          else
            addr = count; // address has the same value as count
        end
        READ:begin
          write = 0;
          read = 1;
          test_fail = 0;
          clear_count = 0;
          mismatch =0;
          done = 0;
           misr_mismatch = 0;
        end
        COMPARE:begin
          write = 0;
          read = 0;
          clear_count =0;
          test_fail =0;
          done = 0;
           misr_mismatch = 0;
          if(pattern == 2'b00)
            mismatch = (input_data == ZERO_PATTERN)?1'b0:1'b1;
          else if(pattern == 2'b01)
            mismatch = (input_data == ONE_PATTERN)?1'b0:1'b1;
          else if(pattern == 2'b10)
            mismatch = (input_data == CHK_PATTERN)?1'b0:1'b1;
          else
            mismatch = 0; // por ahora
        end
        COUNT_UP:begin
          write = 0;
          read = 0;
          test_fail =0;
          clear_count = 0;
          mismatch =0;
          done = 0;
           misr_mismatch = 0;
        end
        COMPLETE:begin
          done = 1;
          write = 0;
          read = 0;
           misr_mismatch = 0;
          clear_count =0;
          test_fail = 0;
          mismatch =0;
        end
        COMPLETE_FAIL:begin //test failed or interrupted
          done =1;
          write = 0;
          read = 0;
          clear_count =0;
          test_fail = 1;
          mismatch =0;
          misr_mismatch = 0;
        end
        TEST_MISR:begin
          misr_mismatch = (misr_reference == misr)?1'b0:1'b1;
        end
        default:begin
          done = 0;
          write = 0;
          read=0;
          misr_mismatch = 0;
          clear_count =0;
          test_fail = 0;
          mismatch =0;
          addr = 0;
        end
      endcase
    end
  
// state memory
  always @(posedge clk or negedge rst) 
    begin
      if(!rst)
        current_state <= IDLE_RST;
      else
        current_state <= next_state;
    end
  
// counter update
  always @(posedge clk)
    begin
      if(current_state == IDLE_RST)
        count <= 0;
      else if(current_state == COUNT_UP)
        count <= count+1'b1;
      else
        count <= count;
    end
  
//write data update
  always @*
    begin
      `ifdef INYECT
      if(count == 10)
        output_data = INCORRECT_PATTERN; // fail inyection for now
      else begin
      case(pattern)
        2'b00:begin
          output_data = ZERO_PATTERN;
        end
        2'b01:begin
          output_data = ONE_PATTERN;
        end
        2'b10:begin
          output_data = CHK_PATTERN;
        end
        2'b11:begin
          output_data = lfsr_pattern; // por ahora
        end
        default:begin
          output_data = ZERO_PATTERN;
        end
      endcase
      end
      `else
      case(pattern)
        2'b00:begin
          output_data = ZERO_PATTERN;
        end
        2'b01:begin
          output_data = ONE_PATTERN;
        end
        2'b10:begin
          output_data = CHK_PATTERN;
        end
        2'b11:begin
          output_data = lfsr_pattern; // por ahora
        end
        default:begin
          output_data = ZERO_PATTERN;
        end
      endcase
      `endif
       
    end
  

  
//lfsr
  always @(posedge clk)
    begin
      if(current_state == IDLE_RST)
        lfsr <= LFSR_SEED;
      else if(current_state == LFSR)
        {lfsr[width-1:1],lfsr[0]} <= {lfsr[width-2:0],((lfsr[width-1]^lfsr[width-3])^lfsr[width-4])^lfsr[width-5]};
      else
        lfsr <= lfsr;
    end

//lfsr output pattern
  always @(posedge clk)
    begin
      if(current_state == IDLE_RST)
        lfsr_pattern <= 0;
      else if(current_state == LFSR)
      	{lfsr_pattern[0],lfsr_pattern[width-1:1]} <= {lfsr[width-1],lfsr_pattern[width-2:0]};
      else
        lfsr_pattern <= lfsr_pattern;
    end
  
 //MISR calculation
    always @(posedge clk)
    begin
      if((current_state == IDLE_RST) | (current_state == WRT))
        misr <= 0;
      else if((current_state == MISR) | (current_state == COMP_MISR)) 
      {misr[misr_width-1:2],misr[1],misr[0]} <= {misr[misr_width-2:1],misr[0]^misr[misr_width-1],misr_input[width-1]^misr[misr_width-1]};
      else
        misr <= misr;
    end
  
  //lfsr output serial
  always @(posedge clk)
    begin
      if((current_state == CAPTURE_LFSR))
      	misr_input <= lfsr_pattern;
      else if((current_state == COMP_MISR) | (current_state == MISR))
        misr_input <= misr_input << 1;
      else if(current_state == CAPTURE_DATA)
        misr_input <= input_data;
      else
        misr_input = misr_input;
    end
  
  //lfsr counter
  always @(posedge clk)
    begin
      if(current_state == IDLE_RST)
        lfsr_count <= 0;
      else if(current_state == LFSR)
        lfsr_count <= lfsr_count+1'b1;
      else
        lfsr_count <= lfsr_count;
    end
  
  //misr counter
   always @(posedge clk)
    begin
      if((current_state == IDLE_RST) | (current_state == WRT))
        misr_count <= 0;
      else if((current_state == COMP_MISR) | (current_state == MISR))
        misr_count <= misr_count+1'b1;
      else
        misr_count <= misr_count;
    end
  
  //save misr
  always @(posedge clk)
    begin
      if(current_state == IDLE_RST)
        misr_reference <= 0;
      else if(current_state == CAPTURE_MISR)
        misr_reference <= misr;
      else
        misr_reference <= misr_reference;
    end

  
endmodule
