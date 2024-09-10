//eth control module
module eth_ctrl(
    input              clk       ,    //系统时钟
    input              rst_n     ,    //系统复位信号，低电平有效 
    //arp port                                 
    input              arp_rx_done,   //ARP RX
    input              arp_rx_type,   //ARP_RX_TYPE 0:request  1:ACK
    output             arp_tx_en,     //ARP发送使能信号
    output             arp_tx_type,   //ARP发送类型 0:请求  1:应答
    input              arp_tx_done,   //ARP发送完成信号
    input              arp_gmii_txen,//ARP GMII输出数据有效信号 
    input     [7:0]    arp_gmii_txd,  //ARP GMII输出数据
    //UDP  data input
    input              udp_gmii_txen,//UDP GMII输出数据有效信号  
    input     [7:0]    udp_gmii_txd,  //UDP GMII输出数据   
    //gmii tx data 
    output             gmii_txen,    //GMII输出数据有效信号 
    output    [7:0]    gmii_txd       //UDP GMII输出数据 
    );

//indicate whitch protocal
reg        protocol; //协议切换信号  选择udp协议发送还是arp协议发送 

assign arp_tx_en = arp_rx_done && (arp_rx_type == 1'b0);  //arp 请求 
assign arp_tx_type = 1'b0;   //arp type fixed                               
assign gmii_txen = protocol ? udp_gmii_txen : arp_gmii_txen;
assign gmii_txd = protocol ? udp_gmii_txd : arp_gmii_txd;

//根据ARP发送使能/完成信号,切换GMII引脚
always @(posedge clk or negedge rst_n) begin
    if(rst_n==1'b0)           protocol <= 1'b1;
    else if(arp_tx_en)   protocol <= 1'b0;  //arp 请求 
    else if(arp_tx_done) protocol <= 1'b1;   //arp 请求完毕 ，切换回udp协议
end

endmodule