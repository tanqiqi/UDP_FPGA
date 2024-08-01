/*********************************
MDIO SIMPLE READ WRITE
GET LINK STATE
******************************/
module mdio_read_write(
    input                clk           ,
    input                rst_n         ,
    input                rst_trig , //软复位触发信号
    input                done       , //读写完成
    input        [15:0]  read_data    , //读出的数据
    input                read_ack     , //读应答信号 0:应答 1:未应答
    output  reg          mdio_triger       , //触发开始信号
    output  reg          write_read      , //低电平写，高电平读
    output  reg  [4:0]   reg_addr       , //寄存器地址
    output  reg  [15:0]  write_data    , //写入寄存器的数据
    output       [1:0]   state_led             //LED灯指示以太网连接状态
    );

parameter SOFT_RESET_CMD=16'hB100;
parameter REG_BMCR=5'h00;
parameter REG_BMSR=5'h01;
parameter REG_PHYSR=5'h11;
//reg define
reg          rst_trig_d0;    
reg          rst_trig_d1;    
reg          rst_trig_flag;   //soft_rst_trig信号触发标志
reg  [23:0]  timer_cnt;       //定时计数器 
reg          timer_done;      //定时完成信号
reg          start_next;      //开始读下一个寄存器标致
reg          read_next;       //处于读下一个寄存器的过程
reg          link_error;      //链路断开或者自协商未完成
reg  [2:0]   flow_cnt;        //流程控制计数器 
reg  [1:0]   speed_status;    //连接速率 
//wire define
wire         pos_rst_trig;    //rst_trig posedge
//rst_trig  posedge
assign pos_rst_trig = ~rst_trig_d1 & rst_trig_d0;
//未连接或连接失败时led赋值00
// 01:10Mbps  10:100Mbps  11:1000Mbps 00：其他情况
assign state_led = link_error ? 2'b00: speed_status;
//复位打两拍
always @(posedge clk or negedge rst_n) begin
    if(rst_n==1'b0) begin
        rst_trig_d0 <= 1'b0;
        rst_trig_d1 <= 1'b0;
    end
    else begin
        rst_trig_d0 <= rst_trig;
        rst_trig_d1 <= rst_trig_d0;
    end
end

//counter
always @(posedge clk or negedge rst_n) begin
    if(rst_n==1'b0) begin
        timer_cnt <= 1'b0;
        timer_done <= 1'b0;
    end
    else begin
        if(timer_cnt == 24'd1_000_000 - 1'b1) begin
            timer_done <= 1'b1;
            timer_cnt <= 1'b0;
        end
        else begin
            timer_done <= 1'b0;
            timer_cnt <= timer_cnt + 1'b1;
        end
    end
end    

//复位PHY并且定时读取状态
always @(posedge clk or negedge rst_n) begin
    if(rst_n==1'b0) begin
        flow_cnt <= 3'd0;
        rst_trig_flag <= 1'b0;
        speed_status <= 2'b00;
        mdio_triger <= 1'b0; 
        write_read <= 1'b0; 
        reg_addr <= 1'b0;       
        write_data <= 1'b0; 
        start_next <= 1'b0; 
        read_next <= 1'b0; 
        link_error <= 1'b0;
    end
    else begin
        mdio_triger <= 1'b0; 
        if(pos_rst_trig)                      
            rst_trig_flag <= 1'b1;             //拉高软复位触发标志
        case(flow_cnt)
            2'd0 : begin
                if(rst_trig_flag) begin        //softreset mdio module
                    mdio_triger <= 1'b1; 
                    write_read <= 1'b0; 
                    reg_addr <=REG_BMCR; 
                    write_data <= SOFT_RESET_CMD;    //Bit[15]=1'b1,表示软复位
                    flow_cnt <= 3'd1;
                end
                else if(timer_done) begin      //定时完成,获取以太网连接状态
                    mdio_triger <= 1'b1; 
                    write_read <= 1'b1; 
                    reg_addr <= REG_BMSR; 
                    flow_cnt <= 3'd2;
                end
                else if(start_next) begin       //获取以太网通信速度
                    mdio_triger <= 1'b1; 
                    write_read <= 1'b1; 
                    reg_addr <= REG_PHYSR; 
                    flow_cnt <= 3'd2;
                    start_next <= 1'b0; 
                    read_next <= 1'b1; 
                end
            end    
            2'd1 : begin
                if(done) begin              //MDIO接口软复位完成
                    flow_cnt <= 3'd0;
                    rst_trig_flag <= 1'b0;
                end
            end
            2'd2 : begin                       
                if(done) begin              //MDIO接口读操作完成
                    if(read_ack == 1'b0 && read_next == 1'b0) //读第一个寄存器
                        flow_cnt <= 3'd3;                      //读第下一个寄存器
                    else if(read_ack == 1'b0 && read_next == 1'b1)begin 
                        read_next <= 1'b0;
                        flow_cnt <= 3'd4;
                    end
                    else begin
                        flow_cnt <= 3'd0;
                     end
                end    
            end
            2'd3 : begin                     
                flow_cnt <= 3'd0;          //链路连接完成且自协商完成
                if(read_data[5] == 1'b1 && read_data[2] == 1'b1)begin
                    start_next <= 1;
                    link_error <= 0;
                end
                else begin
                    link_error <= 1'b1;  
               end           
            end
            3'd4: begin
                flow_cnt <= 3'd0;
                if(read_data[15:14] == 2'b10)
                    speed_status <= 2'b11; //1000Mbps
                else if(read_data[15:14] == 2'b01) 
                    speed_status <= 2'b10; //100Mbps 
                else if(read_data[15:14] == 2'b00) 
                    speed_status <= 2'b01; //10Mbps
                else
                    speed_status <= 2'b00; //erro
            end
        endcase
    end    
end    
    
endmodule
