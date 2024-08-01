
/*============================================
# Filename        : bt656_decoder.v  YUV 4:2:2
# irene20240531   
#  add one row parameters at the end row 
#	output 640 pixel+ 2 row pixel = 642 byte   11:40

//20240801
============================================*/
module bt656_decoder
#(
	parameter	P_DATA_WIDTH = 8	,			
	parameter	P_IMG_WIDTH  = 768	,   //1280+128+128
	parameter	P_IMG_HEIGHT = 576,	   //288*2
    
    parameter	P_IMG_WIDTH_DIS  =640	,   
	parameter	P_IMG_HEIGHT_DIS =480 	  

)
(
	input									clk		,
	input 								    rst_n		,
	input 			[P_DATA_WIDTH-1:0]		i_bt656_data,
    input    	[191:0]          parameter_in,   //just for add IR parameter 

    output reg                               dout_eop_ff3,
    output reg	[P_DATA_WIDTH-1:0]          dout,
    output reg                              dout_vld,
   (*mark_debug="true"*)output reg [ 5:0]	    		r_cstate	,
   input                                vio_cap_1	
	

);
//??????
localparam	IDLE 	= 6'b00001	;
localparam	EBANK1 	= 6'b00010	;
localparam	EDATA 	= 6'b00100	;
localparam	EBANK2 	= 6'b01000	;
localparam	ODATA 	= 6'b10000	;
localparam	PARAMETER = 6'b100000	;


wire [15:0]  total_one_package;



//??????
//??????
reg 		[P_DATA_WIDTH-1:0]			r_bt656_data1 = 'd0 ;
reg 		[P_DATA_WIDTH-1:0]			r_bt656_data2 = 'd0 ;
reg 		[P_DATA_WIDTH-1:0]			r_bt656_data3 = 'd0 ;



(*mark_debug="true"*) reg	   	[P_DATA_WIDTH-1:0]	        	o_yuv_data	;
(*mark_debug="true"*) reg							        	o_video	;
		

//(*mark_debug="true"*)reg			[ 5:0]			r_cstate			 ;
reg			[ 5:0]			r_nstate			 ;


(*mark_debug="true"*)reg			[15:0]			r_col_data_cnt		 ;



wire  r_eblank_start;
wire  r_edata_start;
wire  r_odata_start;
wire  r_parameter_start ;
wire r_idle_start;
reg flag_data_valid;

reg o_video_ff0;
reg o_video_ff1;
reg o_video_ff2;

reg[P_DATA_WIDTH-1:0] o_yuv_data_ff1;
reg[P_DATA_WIDTH-1:0] o_yuv_data_ff2;
reg[P_DATA_WIDTH-1:0]	 o_yuv_data_ff0;

/////////////the parameter add ////////irene20240618///////////


wire[15:0] version_num;
wire[15:0] hor_resolution;
wire[15:0] ver_resolution;
wire[15:0] image_format;

//0x0000   8�?
//0x0001   16位NucTempCor
//0x0002   16位NucNotCor
//0x0003   16位RAW
//0x0004   2字节0.1K
//0x0005   2字节0.01K
//0x0006   4字节浮点K
//0x0007   2字节YUV422

wire[63:0] prepare_blank1;
wire[31:0]  planck_r1;
wire[31:0]  planck_r2;
wire[31:0]  planck_b;
wire[31:0]  planck_f;
wire[31:0]  planck_0;

wire[31:0]  alpha1;
wire[31:0]  alpha2;

wire[31:0]  beta1;
wire[31:0]  beta2;

wire[31:0]  transx;
wire[63:0]  prepare_blank2;

wire[127:0]  cameraname;
wire[127:0]  camaraserial;

wire[127:0]  lensname;
wire[127:0]  lensserial;
wire[223:0]  prepare_blank3;
wire[15:0]    maxtemp;
wire[15:0]     mintemp;

wire[15:0]     maxgray;
wire[15:0]     mingray;

wire[31:0]     fpatemap;
wire[31:0]     coolertemp;

wire[31:0]    camerahousetemp;
wire[31:0]    lenstemp;
wire[31:0]    currentlensfovs;

wire[31:0]    emiss;
wire[31:0]    reftemp;
wire[31:0]    envtemp;
wire[31:0]    humidity;

wire[31:0]    distance;
wire[31:0]    wintrans;
wire[31:0]    wintemp;

wire [63:0] parameter_total;
//wire [63:0] measuremen_parameter;


//just add the 481 line data: image parameter   20240625 
assign version_num = 16'h0101; //0x0000       2bytes
assign  hor_resolution = 16'd640; //0x0002    2bytes
assign  ver_resolution =16'd480;  //0x0004    2bytes
assign  image_format = 16'h0000;  //0x0006    2bytes   

assign  prepare_blank1 =64'b0;    //0x0008         8bytes  

assign  planck_r1 = 32'b0;// 0x0010               4bytes     
assign  planck_r2 =32'b0;// 0x0014               4bytes 
assign  planck_b = 32'b0;// 0x0018                4bytes 
assign  planck_f = 32'b0;// 0x001c                4bytes 
assign  planck_0 = 32'b0;// 0x0020                4bytes

assign  alpha1 = 32'b0;//   0x0024                 4bytes 
assign  alpha2 = 32'b0;//   0x0028                 4bytes 

assign  beta1 = 32'b0;//   0x002C                  4bytes 
assign  beta2 =32'b0;//   0x0030                  4bytes 

assign  transx = 32'b0;//   0x0034                 4bytes 

assign  prepare_blank2 =64'b0;    //0x0038         8bytes 

assign  cameraname =128'b0;    //0x0040             16bytes 
assign  camaraserial =128'b0;    //0x0050          16bytes 

assign  lensname =128'b0;    //0x0060              16bytes
assign  lensserial =128'b0;    //0x0070            16bytes


assign  prepare_blank3 =224'b0;    //0x0080         28bytes 

////////////important///////////
assign  maxtemp =16'b0;    //0x009c               2bytes 
assign  mintemp =16'b0;    //0x009e               2bytes 
assign  maxgray =16'b0;    //0x00a0               2bytes 
assign  mingray =16'b0;    //0x00a2               2bytes 
////////////////////////////////

assign  fpatemap =32'b0;    //0x00a4              4bytes 
assign  coolerTemp =32'b0;    //0x00a8            4bytes

assign  camerahouseTemp =32'b0;    //0x00ac       4bytes 

assign  lenstemp =32'b0;    //0x00b0             4bytes 

assign  currentlensfovs =32'b0;    //0x00b4            4bytes 

assign  emiss =32'b0;    //0x00b8             4bytes 

assign  reftemp =32'b0;    //0x00bc            4bytes 

assign  envTemp =32'b0;    //0x00c0           4bytes 
assign  humidity =32'b0;    //0x00c4          4bytes

assign  distance =32'b0;    //0x00c8         4bytes
assign  wintrans=32'b0;    //0x00cc        4bytes
assign  wintemp=32'b0;    //0x00d0       4bytes


assign parameter_total = {version_num,hor_resolution,ver_resolution,image_format};

assign measuremen_parameter = {maxtemp,mintemp,maxgray,mingray };


//////////////////////////////////////////////////////////////////////////////////////

//just for test
wire r_eblank_start_1;
wire  r_eblank_start_2;
wire r_edata_start_1;
wire r_edata_start_2 ;
wire  r_odata_start_1;
wire  r_odata_start_2;

//reduce the unstable state
always@(posedge clk)
begin
	r_bt656_data1 <= i_bt656_data ;
	r_bt656_data2 <= r_bt656_data1;
	r_bt656_data3 <= r_bt656_data2;
end


//assign   total_one_package = P_IMG_WIDTH*2+4;

assign   total_one_package =	P_IMG_WIDTH_DIS+4;


//state  design 
always @(posedge clk or negedge rst_n) 
begin
	if(rst_n==1'b0)
		begin
			r_cstate <= IDLE;	
		end
	else
		begin
			r_cstate <= r_nstate;
		end	
end


always @(*) 
begin
	case(r_cstate)
		IDLE : 
			begin
		
				if (r_eblank_start_1) 
					begin
						r_nstate = EBANK1;
					end
				else 
					begin
						r_nstate = IDLE;
					end
			end					
		EBANK1 : 
			begin
			
				if (r_edata_start_1) 
					begin
						r_nstate = EDATA;
					end					
				else 
					begin
						r_nstate = EBANK1;
					end
			end				
		EDATA :	 		
			begin
		
				if (r_eblank_start_2) 
					begin
						r_nstate = EBANK2;
					end
				else 
					begin
						r_nstate = EDATA;
					end
			end
		EBANK2 : 
			begin
		
				if ( r_odata_start_1) 
					begin
						r_nstate = ODATA;
					end					
				else 
					begin
						r_nstate = EBANK2;
					end
			end	

      	ODATA : 
			begin
		
				if ( r_parameter_start ) 
					begin
						r_nstate = PARAMETER;
					end
				else 
					begin
						r_nstate = ODATA;
					end
            end
		
        

		PARAMETER : 
			begin
		
				if (  r_idle_start ) 
					begin
						r_nstate = IDLE;
					end
				else 
					begin
						r_nstate = PARAMETER ;
					end
			end
        


		default : 
			begin
				r_nstate = IDLE;
			end	
	endcase 		
end


assign r_edata_start  = r_edata_start_1==1 ||r_edata_start_2==1 ;

assign  r_odata_start = r_odata_start_1==1 || r_odata_start_2==1;


//assign  r_eblank_start_1 = 	r_cstate==IDLE&&(r_bt656_data3 ==8 'hff) && (r_bt656_data2 == 8'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data ==8 'hab)&&vio_en==1;
assign  r_eblank_start_1 = 	r_cstate==IDLE&&(r_bt656_data3 ==8 'hff) && (r_bt656_data2 == 8'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data ==8 'hab)&&vio_cap_1==1;
assign  r_eblank_start_2 = 	r_cstate==EDATA&& (r_bt656_data3 ==8 'hff) && (r_bt656_data2 == 8'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data ==8 'hab);

assign 	r_edata_start_1  =	r_cstate==EBANK1 &&(r_bt656_data3 ==8 'hff) && (r_bt656_data2 ==8 'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data ==8 'h80);
assign 	r_edata_start_2  =	r_cstate==EDATA &&(r_bt656_data3 ==8 'hff) && (r_bt656_data2 ==8 'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data ==8 'h80);

assign  r_odata_start_1  =	r_cstate==EBANK2&& (r_bt656_data3 ==8 'hff) && (r_bt656_data2 == 8'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data == 8'hc7);
assign  r_odata_start_2  =	r_cstate==ODATA&& (r_bt656_data3 ==8 'hff) && (r_bt656_data2 == 8'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data == 8'hc7);


assign  r_parameter_start  = r_cstate==	ODATA &&(r_bt656_data3 ==8 'hff) && (r_bt656_data2 ==8 'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data ==8 'hec);

assign r_idle_start   = 	r_cstate== PARAMETER&&flag_data_valid==1&&r_col_data_cnt==P_IMG_WIDTH*2-1;  //just for add parameter ; one row 



//calculate one row pixel 
always @(posedge clk or negedge rst_n) 
begin
	if(rst_n==1'b0)begin
    	r_col_data_cnt <= 0;
   end    
    else if(flag_data_valid==1)begin
        if(r_col_data_cnt==P_IMG_WIDTH*2-1)begin
            r_col_data_cnt<=0;
        end
        else begin
            r_col_data_cnt<=r_col_data_cnt+1;
        end
    end
  
end

//one row flag 
//reg[15:0] x;


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        flag_data_valid<=0;
    end
    else if( flag_data_valid==0&&r_cstate!=IDLE&&(r_edata_start==1||r_odata_start==1||r_parameter_start==1))begin   //add r_parameter_start;
        flag_data_valid<=1;
    end
    else if(flag_data_valid==1&&r_col_data_cnt==P_IMG_WIDTH *2-1)begin
        flag_data_valid<=0;
    end
end


//calculate the actual row of even or odd field    the true:240 
 
reg[15:0] r_cnt_line;
 
reg[15:0] cnt_line0;

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        r_cnt_line<=0;
                
    end
    else if(r_parameter_start==1|| r_eblank_start_2==1)begin
        r_cnt_line<=0;
       
    end

    else if(r_cstate!=IDLE)begin
        if (r_edata_start==1||r_odata_start==1)begin
             r_cnt_line<=r_cnt_line+1;
         end
     end
        
     
 
end

assign r_edata_start  = r_edata_start_1==1 ||r_edata_start_2==1 ;

assign  r_odata_start = r_odata_start_1==1 || r_odata_start_2==1;

//r_cnt_line;

always  @(*)begin
    if(r_cstate==EDATA&&(r_cnt_line>=25&&r_cnt_line<=264))begin
        cnt_line0= 2*(r_cnt_line-24);  //even
    end
    else if(r_cstate==ODATA&&(r_cnt_line>=25&&r_cnt_line<=264)) begin
        cnt_line0= 2*(r_cnt_line-24)-1;  //odd 
    end
    else begin
        cnt_line0 =P_IMG_HEIGHT_DIS +1;  //the last row:parameter
    end
end


(*mark_debug="true"*)wire valid_data_area;
(*mark_debug="true"*) wire parameter_en;
(*mark_debug ="true"*) wire head_en;

//just for test 
assign  parameter_en = (r_cstate== PARAMETER&&(r_col_data_cnt>=128+320)&&(r_col_data_cnt<=128+320+48-1));
assign head_en = (r_cstate== PARAMETER&&(r_col_data_cnt>=128&&r_col_data_cnt<=128+16-1));
//////////////////////////////////////////////////////////////////////////////////////////////////////////////



assign valid_data_area =(r_cnt_line>=25&&r_cnt_line<=25+240-1)&&(r_col_data_cnt>=128&&r_col_data_cnt<=128+1280-1);


// o_yuv_data/o_video
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        o_yuv_data<=0;
        o_video<=0;

    end
    else if(flag_data_valid==1&&r_col_data_cnt[0]==1)begin
    //    if(r_cstate== EDATA||r_cstate== ODATA)begin  //just extract the grayscale 
          if((r_cstate== EDATA||r_cstate== ODATA)&&valid_data_area==1)begin  //just send the 640 valid data 
            o_yuv_data<=i_bt656_data;
            o_video<=1; 
          end
        else if(r_cstate== PARAMETER&&(r_col_data_cnt>=128&&r_col_data_cnt<=128+16-1))begin   //just for add parameter  8byte send   Interval data retrieval 
            o_yuv_data<= parameter_total[63-((r_col_data_cnt-129)>>1)*8 -:8] ;
            o_video<=1;
        end
        else if(r_cstate== PARAMETER&&(r_col_data_cnt>=128+320)&&(r_col_data_cnt<=128+320+48-1))begin
            o_yuv_data<= parameter_in[191-((r_col_data_cnt-128-320-1)>>1)*8 -:8] ;
            o_video<=1;

        end

        else if(r_cstate== PARAMETER&&(r_col_data_cnt>=128&&r_col_data_cnt<=128+1280-1))begin
            o_yuv_data<=0 ;
            o_video<=1;
        end

    end
   
    else begin
        o_yuv_data<=0;
        o_video<=0;

    end

end
/////////////////////////////////////////////



//Take a few shots to align the output  ---so upset    20240605 10:25 
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        o_video_ff0<=0;
        o_video_ff1<=0;
        o_video_ff2<=0;

        o_yuv_data_ff0<=0;
        o_yuv_data_ff1<=0;
        o_yuv_data_ff2<=0;
  
    end
    else begin
        o_video_ff0<= o_video;
        o_video_ff1<= o_video_ff0;
        o_video_ff2<= o_video_ff1;

        o_yuv_data_ff0<=o_yuv_data;
        o_yuv_data_ff1<=o_yuv_data_ff0;
        o_yuv_data_ff2<=o_yuv_data_ff1;

    end
end


//dout_eop 
reg dout_eop_ff0;
reg dout_eop_ff1;
reg dout_eop;
reg dout_eop_ff2;


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin 
        dout_eop<=0;
    end
   // else if(flag_data_valid==1&&r_col_data_cnt==P_IMG_WIDTH*2-1) begin  //
     else if(flag_data_valid==1&&r_col_data_cnt==128+1280-1) begin

        dout_eop<=1;
    end
    else begin
        dout_eop<=0;
    end
end


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        dout_eop_ff0<=0;
        dout_eop_ff1<=0;

        dout_eop_ff2<=0;
        dout_eop_ff3<=0;
    end
    else begin
        dout_eop_ff0<=dout_eop;
        dout_eop_ff1<=dout_eop_ff0;

        dout_eop_ff2<=dout_eop_ff1;
        dout_eop_ff3<=dout_eop_ff2;
    end
end


reg[15:0]  contral_command;
wire[31:0] pre_send;

assign  pre_send = { total_one_package,  contral_command};  

always  @(*)begin
    if(r_cstate== EDATA||r_cstate== ODATA)begin
        contral_command = cnt_line0;
    end
    else begin
        contral_command = 16'h8003;
    end
end

wire en_data;
wire en_parameter;

assign en_data      =      (r_cstate== EDATA||r_cstate== ODATA)&&valid_data_area==1;
assign en_parameter =       r_cstate== PARAMETER&&flag_data_valid==1;
//dout
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
       dout<=0;
    end
   
  //  else if(flag_data_valid==1&&r_col_data_cnt>=0&&r_col_data_cnt<=4-1)begin   //

      else if(r_col_data_cnt>=128&&r_col_data_cnt<=128+4-1&&(en_data==1|| en_parameter==1))begin  
       dout<=pre_send[31-(r_col_data_cnt-128)*8 -:8] ;
       
      end

    else begin
         dout<= o_yuv_data_ff2;
    end
            
end


//dout_vld
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        dout_vld<=0;
    end
 //   else if(flag_data_valid==1&&r_col_data_cnt<=4-1)begin
 //   else if(flag_data_valid==1&&r_col_data_cnt>=128&&r_col_data_cnt<=128+4-1)begin
     else if(r_col_data_cnt>=128&&r_col_data_cnt<=128+4-1&&(en_data==1|| en_parameter==1))begin

         dout_vld<=1;
    end
    else begin
         dout_vld<= o_video_ff2;
    end

end





















//////////////just for test//////////////////////////////////////////////////////////////////////////
/////////////design r_cnt_line_error_flag or everyline_r_pixel_error_flag ///////////////////////////

reg[15:0] cnt_pixel;
wire r_sav_edata_start;
wire r_eav_edata_start;
wire r_eav_blank_start_even;

wire r_sav_odata_start;
wire r_eav_odata_start;
wire  r_eav_blank_start_odd;

wire cnt_pixel_end;

reg  cnt_pixel_flag;

reg error_line_flag;
reg error_pixel_flag;


assign r_sav_edata_start =(r_cstate==EBANK1||r_cstate==	EDATA)&&(r_bt656_data3 ==8 'hff) && (r_bt656_data2 ==8 'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data ==8 'h80);
assign r_eav_edata_start = (r_cstate==	EDATA) &&(r_bt656_data3 ==8 'hff) && (r_bt656_data2 ==8 'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data ==8 'h9d);
assign r_eav_blank_start_even = (r_cstate==	EBANK2 )&& (r_bt656_data3 ==8 'hff) && (r_bt656_data2 ==8 'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data ==8 'hb6);

assign r_sav_odata_start = (r_cstate==	EBANK2 ||r_cstate==ODATA) && (r_bt656_data3 ==8 'hff) && (r_bt656_data2 ==8 'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data ==8 'hc7);
assign r_eav_odata_start = (r_cstate==	ODATA)&&(r_bt656_data3 ==8 'hff) && (r_bt656_data2 ==8 'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data ==8 'hda);
assign r_eav_blank_start_odd = (r_cstate==PARAMETER)&&(r_bt656_data3 ==8 'hff) && (r_bt656_data2 ==8 'h0) && (r_bt656_data1 == 8'h0) && (i_bt656_data ==8 'hf1);

assign cnt_pixel_end=(r_eav_edata_start==1||r_eav_blank_start_even==1|| r_eav_odata_start==1||r_eav_blank_start_odd==1);

/*
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        cnt_pixel_flag<=0;
    end
    else if(cnt_pixel_flag==0&&	r_cstate!=IDLE&&(r_sav_edata_start==1||r_sav_odata_start==1))begin
        cnt_pixel_flag<=1;
    end
    else if(cnt_pixel_flag==1&&cnt_pixel_end==1)begin
        cnt_pixel_flag<=0;
    end
end



always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_pixel <= 0;
    end
    else if(cnt_pixel_flag==1)begin
        cnt_pixel<=cnt_pixel+1;
    end
    else begin
        cnt_pixel<=0;
    end
end    


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        error_pixel_flag<=0;
    end
    else if( error_pixel_flag==0&&cnt_pixel_flag==1&&cnt_pixel_end==1&&(cnt_pixel!=P_IMG_WIDTH*2+4-1))begin
      error_pixel_flag<=1;
    end
   
end

*/


//design r_cnt_line_error_flag 
always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
      error_line_flag<=0;
    end
   // else if(((r_cstate==EDATA&&r_eblank_start_2==1)||(r_cstate==ODATA&&r_parameter_start==1))&&r_cnt_line!=P_IMG_HEIGHT>>1)begin
    else if(((r_cstate==EDATA&&r_eblank_start_2==1)||(r_cstate==ODATA&&r_parameter_start==1))&&r_cnt_line>=	P_IMG_HEIGHT-1)begin
        error_line_flag<=1;
    end
   
end

//just for test 16:01  20240614

reg edata_flag;
(*mark_debug="true"*)reg[15:0] cnt_0;

always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        edata_flag<=0;
    end
    else if(edata_flag==0&& r_eblank_start_1==1)begin
        edata_flag<=1;
    end
    else if(edata_flag==1&&r_eblank_start_2==1)begin
        edata_flag<=0;
    end
end


always  @(posedge clk or negedge rst_n)begin
    if(rst_n==1'b0)begin
        cnt_0<=0;
    end
    else if( edata_flag==0)begin
        cnt_0<=0;
    end
    else if(edata_flag==1&&r_edata_start ==1)begin
        cnt_0<=cnt_0+1;
    end
end


//////////////////////////////////////////////////////////////////////









endmodule















