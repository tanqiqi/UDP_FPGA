//arp txd module
module arp_txd( 
    input                clk        , //时钟信号
    input                rst_n      , //复位信号，低电平有效
    
     (*mark_debug="true"*) input                arp_tx_en  , //ARP发送使能信号
     (*mark_debug="true"*) input                arp_tx_type, //ARP发送类型 0:请求  1:应答
    (*mark_debug="true"*) input        [47:0]  destination_mac    , //发送的目标MAC地址
    (*mark_debug="true"*)  input        [31:0]  destination_ip     , //发送的目标IP地址
    input        [31:0]  crc_data   , //CRC校验数据
    input         [7:0]  crc_next   , //CRC下次校验完成数据
    output  reg          tx_done    , //以太网发送完成信号
    output  reg          gmii_txen , //GMII输出数据有效信号
    output  reg  [7:0]   gmii_txd   , //GMII输出数据
    output  reg          crc_en     , //CRC开始校验使能
    output  reg          crc_clear      //CRC数据复位信号 
    );

//parameter define
//board mac 
parameter  MY_MAC = 48'h12_34_56_78_90_ab;     
//board ip 192.168.1.10
parameter  MY_IP  = {8'd192,8'd168,8'd1,8'd10}; 
//destination mac ff_ff_ff_ff_ff_ff
parameter  DEST_MAC   = 48'hff_ff_ff_ff_ff_ff;    
//destination ip 192.168.1.100     
parameter  DEST_IP    = {8'd192,8'd168,8'd1,8'd5};  

localparam state_idle      = 'b0_0001; //初始状态，等待开始发送信号
localparam state_preamble  = 'b0_0010; //发送前导码+帧起始界定符
localparam state_eth_head  = 'b0_0100; //发送以太网帧头
localparam state_arp_data  = 'b0_1000; //
localparam state_crc       = 'b1_0000; //发送CRC校验值

localparam  ETH_TYPE     = 'h0806 ; //以太网帧类型 ARP协议
localparam  HD_TYPE      = 'h0001 ; //硬件类型 以太网
localparam  PROTOCOL_TYPE= 'h0800 ; //上层协议为IP协议
//以太网数据最小为46个字节,不足部分填充数据
localparam  MIN_DATA_NUM = 'd46   ;    

//reg define
(*mark_debug="true"*) reg  [4:0]  cur_state     ;
reg  [4:0]  next_state    ;
                          
reg  [7:0]  preamble[7:0] ; //前导码+SFD
reg  [7:0]  eth_head[13:0]; //以太网首部
(*mark_debug="true"*) reg  [7:0]  arp_data[27:0]; //ARP数据
                            
reg         tx_en_d0      ; //arp_tx_en信号延时
reg         tx_en_d1      ; 
(*mark_debug="true"*) reg         skip_en       ; //控制状态跳转使能信号
reg  [5:0]  cnt           ; 
(*mark_debug="true"*) reg  [4:0]  data_cnt      ; //发送数据个数计数器
(*mark_debug="true"*) reg         tx_done_reg     ; 
                                
//wire define                   
(*mark_debug="true"*) wire        pos_tx_en     ; //arp_tx_en信号上升沿

assign  pos_tx_en = (~tx_en_d1) & tx_en_d0;
                           
//对arp_tx_en信号延时打拍两次,用于采arp_tx_en的上升沿
always @(posedge clk or negedge rst_n) begin
    if(rst_n==1'b0) begin
        tx_en_d0 <= 1'b0;
        tx_en_d1 <= 1'b0;
    end    
    else begin
        tx_en_d0 <= arp_tx_en;
        tx_en_d1 <= tx_en_d0;
    end
end 

//(三段式状态机)同步时序描述状态转移
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cur_state <=state_idle;  
    else
        cur_state <= next_state;
end

//组合逻辑判断状态转移条件
always @(*) begin
    next_state =state_idle;
    case(cur_state)
       state_idle : begin                     //空闲状态
            if(skip_en)                
                next_state =state_preamble;
            else
                next_state =state_idle;
        end                          
       state_preamble : begin                 //发送前导码+帧起始界定符
            if(skip_en)
                next_state =state_eth_head;
            else
                next_state =state_preamble;      
        end
       state_eth_head : begin                 //发送以太网首部
            if(skip_en)
                next_state =state_arp_data;
            else
                next_state =state_eth_head;      
        end              
       state_arp_data : begin                 //发送ARP数据                      
            if(skip_en)
                next_state =state_crc;
            else
                next_state =state_arp_data;      
        end
       state_crc: begin                       //发送CRC校验值
            if(skip_en)
                next_state =state_idle;
            else
                next_state =state_crc;      
        end
        default : next_state =state_idle;   
    endcase
end                      

//时序电路描述状态输出，发送以太网数据
always @(posedge clk or negedge rst_n) begin
    if(rst_n==1'b0) begin
        skip_en <= 1'b0; 
        cnt <= 6'd0;
        data_cnt <= 5'd0;
        crc_en <= 1'b0;
        gmii_txen <= 1'b0;
        gmii_txd <= 8'd0;
        tx_done_reg <= 1'b0; 
        
        //初始化数组    
        //前导码 7个8'h55 + 1个8'hd5 
        preamble[0] <= 8'h55;                
        preamble[1] <= 8'h55;
        preamble[2] <= 8'h55;
        preamble[3] <= 8'h55;
        preamble[4] <= 8'h55;
        preamble[5] <= 8'h55;
        preamble[6] <= 8'h55;
        preamble[7] <= 8'hd5;
        //以太网帧头 
        eth_head[0] <= DEST_MAC[47:40];      //目的MAC地址
        eth_head[1] <= DEST_MAC[39:32];
        eth_head[2] <= DEST_MAC[31:24];
        eth_head[3] <= DEST_MAC[23:16];
        eth_head[4] <= DEST_MAC[15:8];
        eth_head[5] <= DEST_MAC[7:0];        
        eth_head[6] <= MY_MAC[47:40];    //源MAC地址
        eth_head[7] <= MY_MAC[39:32];    
        eth_head[8] <= MY_MAC[31:24];    
        eth_head[9] <= MY_MAC[23:16];    
        eth_head[10] <= MY_MAC[15:8];    
        eth_head[11] <= MY_MAC[7:0];     
        eth_head[12] <= ETH_TYPE[15:8];     //以太网帧类型
        eth_head[13] <= ETH_TYPE[7:0];      
        //ARP数据                           
        arp_data[0] <= HD_TYPE[15:8];       //硬件类型
        arp_data[1] <= HD_TYPE[7:0];
        arp_data[2] <= PROTOCOL_TYPE[15:8]; //上层协议类型
        arp_data[3] <= PROTOCOL_TYPE[7:0];
        arp_data[4] <= 8'h06;               //硬件地址长度,6
        arp_data[5] <= 8'h04;               //协议地址长度,4
        arp_data[6] <= 8'h00;               //OP,操作码 8'h01：ARP请求 8'h02:ARP应答
        arp_data[7] <= 8'h01;
        arp_data[8] <= MY_MAC[47:40];    //发送端(源)MAC地址
        arp_data[9] <= MY_MAC[39:32];
        arp_data[10] <= MY_MAC[31:24];
        arp_data[11] <= MY_MAC[23:16];
        arp_data[12] <= MY_MAC[15:8];
        arp_data[13] <= MY_MAC[7:0];
        arp_data[14] <= MY_IP[31:24];    //发送端(源)IP地址
        arp_data[15] <= MY_IP[23:16];
        arp_data[16] <= MY_IP[15:8];
        arp_data[17] <= MY_IP[7:0];
        arp_data[18] <= DEST_MAC[47:40];     //接收端(目的)MAC地址
        arp_data[19] <= DEST_MAC[39:32];
        arp_data[20] <= DEST_MAC[31:24];
        arp_data[21] <= DEST_MAC[23:16];
        arp_data[22] <= DEST_MAC[15:8];
        arp_data[23] <= DEST_MAC[7:0];  
        arp_data[24] <= DEST_IP[31:24];      //接收端(目的)IP地址
        arp_data[25] <= DEST_IP[23:16];
        arp_data[26] <= DEST_IP[15:8];
        arp_data[27] <= DEST_IP[7:0];
    end
    else begin
        skip_en <= 1'b0;
        crc_en <= 1'b0;
        gmii_txen <= 1'b0;
        tx_done_reg <= 1'b0;
        case(next_state)
           state_idle : begin
                if(pos_tx_en) begin
                    skip_en <= 1'b1;  
                    //如果目标MAC地址和IP地址已经更新,则发送正确的地址
                    if((destination_mac != 48'b0) || (destination_ip != 32'd0)) begin
                        eth_head[0] <= destination_mac[47:40];
                        eth_head[1] <= destination_mac[39:32];
                        eth_head[2] <= destination_mac[31:24];
                        eth_head[3] <= destination_mac[23:16];
                        eth_head[4] <= destination_mac[15:8];
                        eth_head[5] <= destination_mac[7:0];  
                        arp_data[18] <= destination_mac[47:40];
                        arp_data[19] <= destination_mac[39:32];
                        arp_data[20] <= destination_mac[31:24];
                        arp_data[21] <= destination_mac[23:16];
                        arp_data[22] <= destination_mac[15:8];
                        arp_data[23] <= destination_mac[7:0];  
                        arp_data[24] <= destination_ip[31:24];
                        arp_data[25] <= destination_ip[23:16];
                        arp_data[26] <= destination_ip[15:8];
                        arp_data[27] <= destination_ip[7:0];
                    end
                    if(arp_tx_type == 1'b0)
                        arp_data[7] <= 8'h01;            //ARP请求 
                    else 
                        arp_data[7] <= 8'h02;            //ARP应答
                end    
            end                                                                   
           state_preamble : begin                          //发送前导码+帧起始界定符
                gmii_txen <= 1'b1;
                gmii_txd <= preamble[cnt];
                if(cnt == 6'd7) begin                        
                    skip_en <= 1'b1;
                    cnt <= 1'b0;    
                end
                else    
                    cnt <= cnt + 1'b1;                     
            end
           state_eth_head : begin                          //发送以太网首部
                gmii_txen <= 1'b1;
                crc_en <= 1'b1;
                gmii_txd <= eth_head[cnt];
                if (cnt == 6'd13) begin
                    skip_en <= 1'b1;
                    cnt <= 1'b0;
                end    
                else    
                    cnt <= cnt + 1'b1;    
            end                    
           state_arp_data : begin                          //发送ARP数据  
                crc_en <= 1'b1;
                gmii_txen <= 1'b1;
                //至少发送46个字节
                if (cnt == MIN_DATA_NUM - 1'b1) begin    
                    skip_en <= 1'b1;
                    cnt <= 1'b0;
                    data_cnt <= 1'b0;
                end    
                else    
                    cnt <= cnt + 1'b1;  
                if(data_cnt <= 6'd27) begin
                    data_cnt <= data_cnt + 1'b1;
                    gmii_txd <= arp_data[data_cnt];
                end    
                else
                    gmii_txd <= 8'd0;                    //Padding,填充0
            end
           state_crc      : begin                          //发送CRC校验值
                gmii_txen <= 1'b1;
                cnt <= cnt + 1'b1;
                if(cnt == 6'd0)
                    gmii_txd <= {~crc_next[0], ~crc_next[1], ~crc_next[2],~crc_next[3],
                                 ~crc_next[4], ~crc_next[5], ~crc_next[6],~crc_next[7]};
                else if(cnt == 6'd1)
                    gmii_txd <= {~crc_data[16], ~crc_data[17], ~crc_data[18],
                                 ~crc_data[19], ~crc_data[20], ~crc_data[21], 
                                 ~crc_data[22],~crc_data[23]};
                else if(cnt == 6'd2) begin
                    gmii_txd <= {~crc_data[8], ~crc_data[9], ~crc_data[10],
                                 ~crc_data[11],~crc_data[12], ~crc_data[13], 
                                 ~crc_data[14],~crc_data[15]};                              
                end
                else if(cnt == 6'd3) begin
                    gmii_txd <= {~crc_data[0], ~crc_data[1], ~crc_data[2],~crc_data[3],
                                 ~crc_data[4], ~crc_data[5], ~crc_data[6],~crc_data[7]};  
                    tx_done_reg <= 1'b1;
                    skip_en <= 1'b1;
                    cnt <= 1'b0;
                end                                                                                                                                            
            end                          
            default :;  
        endcase                                             
    end
end            

//发送完成信号及crc值复位信号
always @(posedge clk or negedge rst_n) begin
    if(rst_n==1'b0) begin
        tx_done <= 1'b0;
        crc_clear <= 1'b0;
    end
    else begin
        tx_done <= tx_done_reg;
        crc_clear <= tx_done_reg;
    end
end

endmodule