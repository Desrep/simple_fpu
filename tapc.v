module tapc(tms,trst,tck,clockdr,shiftdr,updatedr,clockir,shiftir,updateir,enable,rst,select);
input tms;
input trst;
input tck;
output reg shiftdr;
output reg updatedr;
output reg clockdr;
output reg shiftir;
output reg updateir;
output reg clockir;
output reg enable;
output reg rst;
output reg select;

//define states
localparam TEST_LOGIC_RESET = 4'b0000;
localparam RUN_TEST_IDLE = 4'b0001;
localparam SELECT_DR_SCAN = 4'b0010;
localparam CAPTURE_DR = 4'b0011;
localparam SHIFT_DR = 4'b0100;
localparam EXIT1_DR = 4'b0101;
localparam PAUSE_DR = 4'b0110;
localparam EXIT2_DR = 4'b0111;
localparam UPDATE_DR = 4'b1000;
localparam SELECT_IR_SCAN = 4'b1001;
localparam CAPTURE_IR = 4'b1010;
localparam SHIFT_IR = 4'b1011;
localparam EXIT1_IR = 4'b1100;
localparam PAUSE_IR = 4'b1101;
localparam EXIT2_IR = 4'b1110;
localparam UPDATE_IR = 4'b1111;
reg [3:0] current_state;
reg [3:0] next_state;

//next state
always @* begin
	case (current_state)
		TEST_LOGIC_RESET: begin
			if(tms)
				next_state = TEST_LOGIC_RESET;
			else
				next_state = RUN_TEST_IDLE;
		end
		RUN_TEST_IDLE: begin
			if(tms)
				next_state = SELECT_DR_SCAN;
			else
				next_state = RUN_TEST_IDLE;
		end
		SELECT_DR_SCAN:begin
			if(tms)
				next_state = SELECT_IR_SCAN;
			else
				next_state = CAPTURE_DR;
		end
		CAPTURE_DR:begin
			if(tms)
				next_state = EXIT1_DR;
			else
				next_state = SHIFT_DR;
		end
		SHIFT_DR:begin
			if(tms)
				next_state = EXIT1_DR;
			else
				next_state = SHIFT_DR;
		end
		EXIT1_DR:begin
			if(tms)
				next_state = UPDATE_DR;
			else
				next_state = PAUSE_DR;
		end
		PAUSE_DR:begin
			if(tms)
				next_state = EXIT2_DR;
			else
				next_state = PAUSE_DR;
		end
		EXIT2_DR:begin
			if(tms)
				next_state = UPDATE_DR;
			else
				next_state = SHIFT_DR;
		end
		UPDATE_DR:begin
			if(tms)
				next_state = SELECT_DR_SCAN;
			else
				next_state = RUN_TEST_IDLE;
		end
		SELECT_IR_SCAN:begin
                        if(tms)
                                next_state = TEST_LOGIC_RESET;
                        else
                                next_state = CAPTURE_IR;
                end
                CAPTURE_IR:begin
                        if(tms)
                                next_state = EXIT1_IR;
                        else
                                next_state = SHIFT_IR;
                end
                SHIFT_IR:begin
                        if(tms)
                                next_state = EXIT1_IR;
                        else
                                next_state = SHIFT_IR;
                end
                EXIT1_IR:begin
                        if(tms)
                                next_state = UPDATE_IR;
                        else
                                next_state = PAUSE_IR;
                end
                PAUSE_IR:begin
                        if(tms)
                                next_state = EXIT2_IR;
                        else
                                next_state = PAUSE_IR;
                end
                EXIT2_IR:begin
                        if(tms)
                                next_state = UPDATE_IR;
                        else
                                next_state = SHIFT_IR;
                end
                UPDATE_IR:begin
                        if(tms)
                                next_state = SELECT_DR_SCAN;
                        else
                                next_state = RUN_TEST_IDLE;
                end
		default:begin
			next_state = TEST_LOGIC_RESET;
		end
	endcase

end



//state mem
always @(posedge tck or negedge trst) begin
	if(!trst)
		current_state <= TEST_LOGIC_RESET;
	else
		current_state <= next_state;

end


// output computation, revisar luego???
always @* begin
	case(current_state)
		CAPTURE_DR:begin
			shiftdr = 0;
			clockdr = 1; // se ocupa un pulso
			updatedr = 0;
			shiftir = 0;
			clockir = 0;
			updateir = 0;
			enable =1;
			rst = 1;
			select = 0;// ver este
		end
		SHIFT_DR: begin
			shiftdr = 1;
                        clockdr = tck; // se ocupa un reloj
                        updatedr = 0;
                        shiftir = 0;
                        clockir = 0;
                        updateir = 0;
                        enable =1;
                        rst = 1;
                        select = 0;// ver este

		end
		UPDATE_DR:begin
			shiftdr = 0;
                        clockdr = 0; 
                        updatedr = 1; // se ocupa un pulso
                        shiftir = 0;
                        clockir = 0;
                        updateir = 0;
                        enable =1;
                        rst = 1;
                        select = 0;// ver este
		end
		CAPTURE_IR:begin
                        shiftdr = 0;
                        clockdr = 0; 
                        updatedr = 0;
                        shiftir = 0;
                        clockir = 1;//un pulso
                        updateir = 0;
                        enable =1;
                        rst = 1;
                        select = 1;// ver este
                end
                SHIFT_IR: begin
                        shiftdr = 0;
                        clockdr = 0; 
                        updatedr = 0;
                        shiftir =1;
                        clockir = tck;// se ocupa reloj
                        updateir = 0;
                        enable =1;
                        rst = 1;
                        select = 1;// ver este

                end
                UPDATE_IR:begin
                        shiftdr = 0;
                        clockdr = 0;
                        updatedr = 0; 
                        shiftir = 0;
                        clockir = 0;
                        updateir = 1; // se ocupa un pulso
                        enable =1;
                        rst = 1;
                        select = 1;// ver este
                end
		TEST_LOGIC_RESET:begin // revisar este
			shiftdr = 0;
                        clockdr = 0;
                        updatedr = 0;
                        shiftir = 0;
                        clockir = 0;
                        updateir = 0; // se ocupa un pulso
                        enable =0;
                        rst = 0;
                        select = 0;// ver este

		end
		default:begin
	                shiftdr = 0;
                        clockdr = 0;
                        updatedr = 0;
                        shiftir = 0;
                        clockir = 0;
                        updateir = 0; // se ocupa un pulso
                        enable =0;
                        rst = 1;
                        select = 0;// ver este
		end

	endcase


end


endmodule
