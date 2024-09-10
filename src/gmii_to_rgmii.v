//port ddr to sdr,4bit to 8bit rgmii<->gmii
module gmii_to_rgmii(
    input              refclk_200m  , //IDELAY clk
    //GMII
    output             gmii_rxc ,      
    output             gmii_rxdv  ,   
    output      [7:0]  gmii_rxd    ,
    output             gmii_txc ,  
    input              gmii_txen  ,   
    input       [7:0]  gmii_txd    ,  
    //RGMII 
    input              rgmii_rxc   ,
    input              rgmii_rx_ctrl,  
    input       [3:0]  rgmii_rxd   ,
    output             rgmii_txc   ,  
    output             rgmii_tx_ctrl,  
    output      [3:0]  rgmii_txd         
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