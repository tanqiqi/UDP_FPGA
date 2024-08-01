/**************************************
MDIO DRIVER
*************************************/

module mdio_driver
    (
    input                clk       , //时钟信号
    input                rst_n     , //复位信号,低电平有效
    input                mdio_triger   , //触发开始信号
    input                write_read  , //低电平写，高电平读
    input        [4:0]   reg_addr   , //寄存器地址
    input        [15:0]  write_data, //写入寄存器的数据
    output  reg          done   , //读写完成
    output  reg  [15:0]  read_data, //读出的数据
    output  reg          read_ack , //读应答信号 0:应答 1:未应答
    output  reg          divid_clk   , //驱动时钟
    
    output  reg          phy_mdc   , //PHY管理接口的时钟信号
    inout                phy_mdio    //PHY管理接口的双向数据信号
    );
localparam  PHY_ADDR = 5'b00001;//PHY地址
localparam  CLK_DIVIDE  = 6'd10;//分频系数


localparam state_idle    = 6'b00_0001;  //空闲状态
localparam state_pre     = 6'b00_0010;  //发送PRE(前导码)
localparam state_start   = 6'b00_0100;  //开始状态,发送ST(开始)+OP(操作码)
localparam state_addr    = 6'b00_1000;  //写地址,发送PHY地址+寄存器地址
localparam state_wr_data = 6'b01_0000;  //TA+写数据
localparam state_rd_data = 6'b10_0000;  //TA+读数据

//reg define
reg    [5:0]  now_state ;
reg    [5:0]  next_state;

reg    [5:0]  clk_cnt   ;  //分频计数                      
reg   [15:0]  wr_data_t ;  //缓存写寄存器的数据
reg    [4:0]  addr_t    ;  //缓存寄存器地址
reg    [6:0]  cnt       ;  //计数器
reg           state_done   ;  //状态开始跳转信号
reg    [1:0]  op_code   ;  //操作码  2'b01(写)  2'b10(读)                  
reg           mdio_dir  ;  //MDIO数据(SDA)方向控制
reg           mdio_out  ;  //MDIO输出信号
reg   [15:0]  rd_data_reg ;  //缓存读寄存器数据

//wire 
wire   [5:0]  clk_divide ; //PHY_CLK的分频系数

assign phy_mdio = mdio_dir ? mdio_out : 1'bz; //控制双向io方向

//分频分频系数除以2
assign clk_divide = CLK_DIVIDE >> 1;

//分频得到dri_clk时钟
always @(posedge clk or negedge rst_n) begin
    if(rst_n==1'b0) begin
        divid_clk <=  1'b0;
        clk_cnt <= 1'b0;
    end
    else if(clk_cnt == clk_divide[5:1] - 1'd1) begin
        clk_cnt <= 1'b0;
        divid_clk <= ~divid_clk;
    end
    else
        clk_cnt <= clk_cnt + 1'b1;
end

//产生PHY_MDC时钟
always @(posedge divid_clk or negedge rst_n) begin
    if(!rst_n)
        phy_mdc <= 1'b1;
    else if(cnt[0] == 1'b0)
        phy_mdc <= 1'b1;
    else    
        phy_mdc <= 1'b0;  
end

//状态机
always @(posedge divid_clk or negedge rst_n) begin
    if(!rst_n)
        now_state <= state_idle;
    else
        now_state <= next_state;
end  

//状态机转换条件
always @(*) begin
    next_state = state_idle;
    case(now_state)
        state_idle : begin
            if(mdio_triger)
                next_state = state_pre;
            else 
                next_state = state_idle;   
        end  
        state_pre : begin
            if(state_done)
                next_state = state_start;
            else
                next_state = state_pre;
        end
        state_start : begin
            if(state_done)
                next_state = state_addr;
            else
                next_state = state_start;
        end
        state_addr : begin
            if(state_done) begin
                if(op_code == 2'b01)                //MDIO接口写操作  
                    next_state = state_wr_data;
                else
                    next_state = state_rd_data;        //MDIO接口读操作  
            end
            else
                next_state = state_addr;
        end
        state_wr_data : begin
            if(state_done)
                next_state = state_idle;
            else
                next_state = state_wr_data;
        end        
        state_rd_data : begin
            if(state_done)
                next_state = state_idle;
            else
                next_state = state_rd_data;
        end                                                                          
        default : next_state = state_idle;
    endcase
  end

//状态输出
always @(posedge divid_clk or negedge rst_n) begin
    if(rst_n==1'b0) begin
        cnt <= 5'd0;
        op_code <= 1'b0;
        addr_t <= 1'b0;
        wr_data_t <= 1'b0;
        rd_data_reg <= 1'b0;
        done <= 1'b0;
        state_done <= 1'b0; 
        read_data <= 1'b0;
        read_ack <= 1'b1;
        mdio_dir <= 1'b0;
        mdio_out <= 1'b1;
    end
    else begin
        state_done <= 1'b0 ;                            
        cnt     <= cnt +1'b1 ;          
        case(now_state)
            state_idle : begin
                mdio_out <= 1'b1;                     
                mdio_dir <= 1'b0;                     
                done <= 1'b0;                     
                cnt <= 7'b0;  
                if(mdio_triger) begin
                    op_code <= {write_read,~write_read}; //OP_CODE: 2'b01(写)  2'b10(读) 
                    addr_t <= reg_addr;
                    wr_data_t <= write_data;
                    read_ack <= 1'b1;
                end     
            end 
            state_pre : begin                          //发送前导码:32个1bit 
                mdio_dir <= 1'b1;                   //切换MDIO引脚方向:输出
                mdio_out <= 1'b1;                   //MDIO引脚输出高电平
                if(cnt == 7'd62) 
                    state_done <= 1'b1;
                else if(cnt == 7'd63)
                    cnt <= 7'b0;
            end            
            state_start  : begin
                case(cnt)
                    7'd1 : mdio_out <= 1'b0;        //发送开始信号 2'b01
                    7'd3 : mdio_out <= 1'b1; 
                    7'd5 : mdio_out <= op_code[1];  //发送操作码
                    7'd6 : state_done <= 1'b1;
                    7'd7 : begin
                               mdio_out <= op_code[0];
                               cnt <= 7'b0;  
                           end    
                    default : ;
                endcase
            end    
            state_addr : begin
                case(cnt)
                    7'd1 : mdio_out <= PHY_ADDR[4]; //发送PHY地址
                    7'd3 : mdio_out <= PHY_ADDR[3];
                    7'd5 : mdio_out <= PHY_ADDR[2];
                    7'd7 : mdio_out <= PHY_ADDR[1];  
                    7'd9 : mdio_out <= PHY_ADDR[0];
                    7'd11: mdio_out <= addr_t[4];  //发送寄存器地址
                    7'd13: mdio_out <= addr_t[3];
                    7'd15: mdio_out <= addr_t[2];
                    7'd17: mdio_out <= addr_t[1];  
                    7'd18: state_done <= 1'b1;
                    7'd19: begin
                               mdio_out <= addr_t[0]; 
                               cnt <= 7'd0;
                           end    
                    default : ;
                endcase                
            end    
            state_wr_data : begin
                case(cnt)
                    7'd1 : mdio_out <= 1'b1;         //发送TA,写操作(2'b10)
                    7'd3 : mdio_out <= 1'b0;
                    7'd5 : mdio_out <= wr_data_t[15];//发送写寄存器数据
                    7'd7 : mdio_out <= wr_data_t[14];
                    7'd9 : mdio_out <= wr_data_t[13];
                    7'd11: mdio_out <= wr_data_t[12];
                    7'd13: mdio_out <= wr_data_t[11];
                    7'd15: mdio_out <= wr_data_t[10];
                    7'd17: mdio_out <= wr_data_t[9];
                    7'd19: mdio_out <= wr_data_t[8];
                    7'd21: mdio_out <= wr_data_t[7];
                    7'd23: mdio_out <= wr_data_t[6];
                    7'd25: mdio_out <= wr_data_t[5];
                    7'd27: mdio_out <= wr_data_t[4];
                    7'd29: mdio_out <= wr_data_t[3];
                    7'd31: mdio_out <= wr_data_t[2];
                    7'd33: mdio_out <= wr_data_t[1];
                    7'd35: mdio_out <= wr_data_t[0];
                    7'd37: begin
                        mdio_dir <= 1'b0;
                        mdio_out <= 1'b1;
                    end
                    7'd39: state_done <= 1'b1;           
                    7'd40: begin
                               cnt <= 7'b0;
                               done <= 1'b1;      //写操作完成,拉高op_done信号 
                           end    
                    default : ;
                endcase    
            end
            state_rd_data : begin
                case(cnt)
                    7'd1 : begin
                        mdio_dir <= 1'b0;            //MDIO引脚切换至输入状态
                        mdio_out <= 1'b1;
                    end
                    7'd2 : ;                         //TA[1]位,该位为高阻状态,不操作             
                    7'd4 : read_ack <= phy_mdio;     //TA[0]位,0(应答) 1(未应答)
                    7'd6 : rd_data_reg[15] <= phy_mdio; //接收寄存器数据
                    7'd8 : rd_data_reg[14] <= phy_mdio;
                    7'd10: rd_data_reg[13] <= phy_mdio;
                    7'd12: rd_data_reg[12] <= phy_mdio;
                    7'd14: rd_data_reg[11] <= phy_mdio;
                    7'd16: rd_data_reg[10] <= phy_mdio;
                    7'd18: rd_data_reg[9] <= phy_mdio;
                    7'd20: rd_data_reg[8] <= phy_mdio;
                    7'd22: rd_data_reg[7] <= phy_mdio;
                    7'd24: rd_data_reg[6] <= phy_mdio;
                    7'd26: rd_data_reg[5] <= phy_mdio;
                    7'd28: rd_data_reg[4] <= phy_mdio;
                    7'd30: rd_data_reg[3] <= phy_mdio;
                    7'd32: rd_data_reg[2] <= phy_mdio;
                    7'd34: rd_data_reg[1] <= phy_mdio;
                    7'd36: rd_data_reg[0] <= phy_mdio;
                    7'd39: state_done <= 1'b1;
                    7'd40: begin
                        done <= 1'b1; //读操作完成,拉高op_done信号          
                        read_data <= rd_data_reg;
                        rd_data_reg <= 16'd0;
                        cnt <= 7'd0;
                    end
                    default : ;
                endcase   
            end                
            default : ;
        endcase               
    end
end                    

endmodule
