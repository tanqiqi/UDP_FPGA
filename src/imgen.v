module imgen #(parameter PIXEL=640,parameter LINE =480)
(

	input				clk		,	
	input				rst_n	,
	(*mark_debug="true"*)	output reg[15:0]	img_dat	   ,
	(*mark_debug="true"*)	output reg      img_line_vld	,
	(*mark_debug="true"*)	output reg      img_frame_vld 

);

parameter	TIME10M = 10_000_000;
//parameter      PIXEL=640;
//parameter      LINE =480;

reg[23:0]	cnt_s;
	(*mark_debug="true"*) reg[15:0]cnt_piex;
	(*mark_debug="true"*) reg[15:0]cnt_line;

	(*mark_debug="true"*) reg[1:0]		state;

always @(posedge clk ,negedge rst_n)
	if(!rst_n)begin
		cnt_s 	<= 0;
		state 	<= 0;
		cnt_piex <=0;
		cnt_line <= 0;      
		img_dat				<= 0;			
		img_line_vld	<= 0;	
		img_frame_vld <= 0;	
	end
	else begin
		case(state)
			0:begin 
            img_frame_vld <= 1;
            state<=1;
            img_dat<=0;
            end
			1:if(cnt_piex==PIXEL)
            begin
                cnt_piex<=0;
                state<=2;
                cnt_line<=cnt_line+1; 
                img_line_vld	<= 0;
            end
			else begin
						cnt_piex <= cnt_piex+1;
					    img_dat	 <=cnt_piex;
                      //  img_dat	 <=	(cnt_piex[8]^cnt_line[9]);
					    img_line_vld	<= 1;	
									
			end
			2:if(cnt_line== LINE) begin
               cnt_line<=0; 
               state <=3;
               img_frame_vld <= 0;	
              end
		      else begin 
                  state <= 1;
              end	
			3:begin
				
				if(cnt_s==TIME10M-1) begin
                    state<=0;cnt_s<=0;
                end
				else         cnt_s<=cnt_s+1;
			end
		endcase
	end

endmodule
