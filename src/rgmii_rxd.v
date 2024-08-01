//rgmii rx data to gmii
module rgmii_rxd(
    input              refclk_200m  , //200Mhz时钟，IDELAY时钟
    //rgmii
    input              rgmii_rxc   , //RGMII接收时钟
    input              rgmii_rx_ctrl, //RGMII接收数据控制信号
    input       [3:0]  rgmii_rxd   , //RGMII接收数据    
    //gmii
    output             gmii_rxc , //GMII接收时钟
    output             gmii_rxdv  , //GMII接收数据有效信号
    output      [7:0]  gmii_rxd      //GMII接收数据   
    );

//default iodelay tap ，no delay
parameter IDELAY_VALUE = 0;
//wire define
wire         rgmii_rxc_bufg;     //全局时钟缓存
wire         rgmii_rxc_bufio;    //全局时钟IO缓存
wire  [3:0]  rgmii_rxd_delay;    //rgmii_rxd输入延时
wire         rgmii_rx_ctl_delay; //rgmii_rx_ctrl输入延时
wire  [1:0]  gmii_rxdv_t;        //两位GMII接收有效信号 

assign gmii_rxdv = gmii_rxdv_t[0] & gmii_rxdv_t[1];

//to global clock net
BUFG BUFG_inst (
  .I            (rgmii_rxc),     // 1-bit input: Clock input
  .O            (gmii_rxc) // 1-bit output: Clock output
);

//rxc clock buffer to rxd data delay
BUFIO BUFIO_inst (
  .I            (rgmii_rxc),      // 1-bit input: Clock input
  .O            (rgmii_rxc_buf) // 1-bit output: Clock output
);

//idelay control
// Specifies group name for associated IDELAYs/ODELAYs and IDELAYCTRL
(* IODELAY_GROUP = "rgmii_rx_delay" *) 
IDELAYCTRL  IDELAYCTRL_inst (
    .RDY(),                      // 1-bit output: Ready output
    .REFCLK(refclk_200m),         // 1-bit input: Reference clock input
    .RST(1'b0)                   // 1-bit input: Active high reset input
);

//rgmii_rx_ctrl输入延时与双沿采样
(* IODELAY_GROUP = "rgmii_rx_delay" *) 
IDELAYE2 #(
  .IDELAY_TYPE     ("FIXED"),           // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
  .IDELAY_VALUE    (IDELAY_VALUE),      // Input delay tap setting (0-31)
  .REFCLK_FREQUENCY(200.0)              // IDELAYCTRL clock input frequency in MHz 
)
IDELAYE2_inst (
  .CNTVALUEOUT     (),                  // 5-bit output: Counter value output
  .DATAOUT         (rgmii_rx_ctl_delay),// 1-bit output: Delayed data output
  .C               (1'b0),              // 1-bit input: Clock input
  .CE              (1'b0),              // 1-bit input: enable increment/decrement
  .CINVCTRL        (1'b0),              // 1-bit input: Dynamic clock inversion input
  .CNTVALUEIN      (5'b0),              // 5-bit input: Counter value input
  .DATAIN          (1'b0),              // 1-bit input: Internal delay data input
  .IDATAIN         (rgmii_rx_ctrl),      // 1-bit input: Data input from the I/O
  .INC             (1'b0),              // 1-bit input: Increment / Decrement tap delay
  .LD              (1'b0),              // 1-bit input: Load IDELAY_VALUE input
  .LDPIPEEN        (1'b0),              // 1-bit input: Enable PIPELINE register
  .REGRST          (1'b0)               // 1-bit input: Active-high reset tap-delay input
);

//IDDR ,DDR TO SDR
IDDR #(
    .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),// "OPPOSITE_EDGE", "SAME_EDGE" 
                                        //    or "SAME_EDGE_PIPELINED" 
    .INIT_Q1  (1'b0),                   // Initial value of Q1: 1'b0 or 1'b1
    .INIT_Q2  (1'b0),                   // Initial value of Q2: 1'b0 or 1'b1
    .SRTYPE   ("SYNC")                  // Set/Reset type: "SYNC" or "ASYNC" 
) IDDR_inst (
    .Q1       (gmii_rxdv_t[0]),         // 1-bit output for positive edge of clock
    .Q2       (gmii_rxdv_t[1]),         // 1-bit output for negative edge of clock
    .C        (rgmii_rxc_buf),        // 1-bit clock input
    .CE       (1'b1),                   // 1-bit clock enable input
    .D        (rgmii_rx_ctl_delay),     // 1-bit DDR data input
    .R        (1'b0),                   // 1-bit reset
    .S        (1'b0)                    // 1-bit set
);

//rgmii_rxd输入延时与双沿采样
genvar i;
generate for (i=0; i<4; i=i+1)
    (* IODELAY_GROUP = "rgmii_rx_delay" *) 
    begin : rxdata_bus
        //input rgmii_rxd delay       
        (* IODELAY_GROUP = "rgmii_rx_delay" *) 
        IDELAYE2 #(
          .IDELAY_TYPE     ("FIXED"),           // FIXED,VARIABLE,VAR_LOAD,VAR_LOAD_PIPE
          .IDELAY_VALUE    (IDELAY_VALUE),      // Input delay tap setting (0-31)    
          .REFCLK_FREQUENCY(200.0)              // IDELAYCTRL clock input frequency in MHz
        )
        IDELAYE2_inst (
          .CNTVALUEOUT     (),                  // 5-bit output: Counter value output
          .DATAOUT         (rgmii_rxd_delay[i]),// 1-bit output: Delayed data output
          .C               (1'b0),              // 1-bit input: Clock input
          .CE              (1'b0),              // 1-bit input: enable increment/decrement
          .CINVCTRL        (1'b0),              // 1-bit input: Dynamic clock inversion
          .CNTVALUEIN      (5'b0),              // 5-bit input: Counter value input
          .DATAIN          (1'b0),              // 1-bit input: Internal delay data input
          .IDATAIN         (rgmii_rxd[i]),      // 1-bit input: Data input from the I/O
          .INC             (1'b0),              // 1-bit input: Inc/Decrement tap delay
          .LD              (1'b0),              // 1-bit input: Load IDELAY_VALUE input
          .LDPIPEEN        (1'b0),              // 1-bit input: Enable PIPELINE register 
          .REGRST          (1'b0)               // 1-bit input: Active-high reset tap-delay
        );
        //input data DDR to SDR
        IDDR #(
            .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),// "OPPOSITE_EDGE", "SAME_EDGE" 
                                                //    or "SAME_EDGE_PIPELINED" 
            .INIT_Q1  (1'b0),                   // Initial value of Q1: 1'b0 or 1'b1
            .INIT_Q2  (1'b0),                   // Initial value of Q2: 1'b0 or 1'b1
            .SRTYPE   ("SYNC")                  // Set/Reset type: "SYNC" or "ASYNC" 
        ) IDDR_inst (
            .Q1       (gmii_rxd[i]),            // 1-bit output for positive edge of clock
            .Q2       (gmii_rxd[4+i]),          // 1-bit output for negative edge of clock
            .C        (rgmii_rxc_buf),        // 1-bit clock input rgmii_rxc_buf
            .CE       (1'b1),                   // 1-bit clock enable input
            .D        (rgmii_rxd_delay[i]),     // 1-bit DDR data input
            .R        (1'b0),                   // 1-bit reset
            .S        (1'b0)                    // 1-bit set
        );
    end
endgenerate

endmodule