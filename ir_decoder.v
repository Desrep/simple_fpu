module ir_decoder(ir_in,sample,bypass,preload,extest,intest,runmbist,runscan,runlbist,progmbist,proglbist);
input [3:0] ir_in;
output reg sample;
output reg bypass;
output reg preload;
output reg extest;
output reg intest;
output reg runmbist;
output reg runscan;
output reg runlbist;
output reg progmbist;
output reg proglbist;

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


// decoder
always @* begin
	case(ir_in)
		BYPASS:begin
			bypass = 1;
			sample =0;
			preload =0;
			extest = 0;
			intest  =0;
			runmbist=0;
			runscan=0;
			runlbist =0;
			progmbist =0;
			proglbist = 0;

		end
		SAMPLE:begin
                        bypass = 0;
                        sample =1;
                        preload =0;
                        extest = 0;
                        intest  =0;
                        runmbist=0;
                        runscan=0;
			runlbist =0;
                        progmbist =0;
                        proglbist = 0;

		end
		PRELOAD:begin
			bypass = 0;
                        sample =0;
                        preload =1;
                        extest = 0;
                        intest  =0;
                        runmbist=0;
                        runscan=0;
			runlbist =0;
                        progmbist =0;
                        proglbist = 0;

		end
		EXTEST:begin
			bypass = 0;
                        sample =0;
                        preload =0;
                        extest = 1;
                        intest  =0;
                        runmbist=0;
                        runscan=0;
			runlbist =0;
                        progmbist =0;
                        proglbist = 0;

		end
		RUN_MBIST:begin
			bypass = 0;
                        sample =0;
                        preload =0;
                        extest = 0;
                        intest  =0;
                        runmbist=1;
                        runscan=0;
			runlbist =0;
                        progmbist =0;
                        proglbist = 0;

		end
		RUNSCAN:begin
			bypass = 0;
                        sample =0;
                        preload =0;
                        extest = 0;
                        intest = 0;
                        runmbist=0;
                        runscan=1;
			runlbist =0;
                        progmbist =0;
                        proglbist = 0;

		end
		INTEST:begin
			bypass = 0;
                        sample =0;
                        preload =0;
                        extest = 0;
                        intest = 1;
                        runmbist=0;
                        runscan=0;
			runlbist =0;
                        progmbist =0;
                        proglbist = 0;

		end
		RUN_MBIST:begin
			bypass = 0;
                        sample =0;
                        preload =0;
                        extest = 0;
                        intest = 0;
                        runmbist=1;
                        runscan=0;
                        runlbist =0;
                        progmbist =0;
                        proglbist = 0;

		end
		RUN_LBIST:begin
			bypass = 0;
                        sample =0;
                        preload =0;
                        extest = 0;
                        intest = 0;
                        runmbist=0;
                        runscan=0;
                        runlbist =1;
                        progmbist =0;
                        proglbist = 0;
		end
		PROG_MBIST:begin
			bypass = 0;
                        sample =0;
                        preload =0;
                        extest = 0;
                        intest = 0;
                        runmbist=0;
                        runscan=0;
                        runlbist =0;
                        progmbist =1;
                        proglbist = 0;

		end
		PROG_LBIST:begin
			bypass = 0;
                        sample =0;
                        preload =0;
                        extest = 0;
                        intest = 0;
                        runmbist=0;
                        runscan=0;
                        runlbist =0;
                        progmbist =0;
                        proglbist = 1;
		end
		default:begin
			bypass = 0;
                        sample =0;
                        preload =0;
                        extest = 0;
                        intest  =0;
                        runmbist=0;
                        runscan=0;
			runlbist =0;
                        progmbist =0;
                        proglbist = 0;


		end
	endcase
	

end


endmodule
