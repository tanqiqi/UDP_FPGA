//port ddr to sdr,4bit to 8bit rgmii<->gmii
module gmii_to_rgmii(
    input              refclk_200m  , //IDELAY时钟
    //GMII
    output             gmii_rxc , //GMII接收时钟
    output             gmii_rxdv  , //GMII接收数据有效信号
    output      [7:0]  gmii_rxd    , //GMII接收数据
    output             gmii_txc , //GMII发送时钟
    input              gmii_txen  , //GMII发送数据使能信号
    input       [7:0]  gmii_txd    , //GMII发送数据            
    //RGMII 
    input              rgmii_rxc   , //RGMII接收时钟
    input              rgmii_rx_ctrl, //RGMII接收数据控制信号
    input       [3:0]  rgmii_rxd   , //RGMII接收数据
    output             rgmii_txc   , //RGMII发送时钟    
    output             rgmii_tx_ctrl, //RGMII发送数据控制信号
    output      [3:0]  rgmii_txd     //RGMII发送数据          
    );

assign gmii_txc = gmii_rxc;

//RGMII RX DATA
rgmii_rxd rgmii_rxd_inst(
    .refclk_200m    (refclk_200m),
    .gmii_rxc      (gmii_rxc),
    .rgmii_rxc     (rgmii_rxc   ),
    .rgmii_rx_ctrl  (rgmii_rx_ctrl),
    .rgmii_rxd     (rgmii_rxd   ),
    .gmii_rxdv    (gmii_rxdv ),
    .gmii_rxd      (gmii_rxd   )
    );

//RGMII TX DATA
rgmii_txd rgmii_txd_inst(
    .gmii_txc      (gmii_txc ),
    .gmii_txen    (gmii_txen  ),
    .gmii_txd      (gmii_txd    ),
    .rgmii_txc     (rgmii_txc   ),
    .rgmii_tx_ctrl (rgmii_tx_ctrl),
    .rgmii_txd     (rgmii_txd   )
    );

endmodule