create_clock -period 20.000 -name clk [get_ports clk]
create_clock -period 8.000 -name phy_rxc -waveform {0.000 4.000} [get_ports phy_rxc]


set_property IOSTANDARD LVCMOS33 [get_ports phy_rxc]
set_property IOSTANDARD LVCMOS33 [get_ports phy_txc]

#set_property IOSTANDARD LVCMOS33 [get_ports {linkspeed[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {linkspeed[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {phy_rxd[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rxd[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rxd[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_rxd[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_txd[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_txd[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_txd[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {phy_txd[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports clk]
set_property PACKAGE_PIN D15 [get_ports clk]

set_property IOSTANDARD LVCMOS18 [get_ports rst_n]
set_property PACKAGE_PIN B16 [get_ports rst_n]

set_property IOSTANDARD LVCMOS33 [get_ports mdc]
set_property IOSTANDARD LVCMOS33 [get_ports mdio]
set_property IOSTANDARD LVCMOS33 [get_ports phy_rx_ctrl]
set_property IOSTANDARD LVCMOS33 [get_ports phy_tx_ctrl]
set_property PACKAGE_PIN AE25 [get_ports mdc]
set_property PACKAGE_PIN AD25 [get_ports mdio]

#set_property PACKAGE_PIN Y2 [get_ports phy_rstn]

set_property PACKAGE_PIN AE22 [get_ports phy_rx_ctrl]
set_property PACKAGE_PIN AD26 [get_ports phy_tx_ctrl]

#set_property PACKAGE_PIN A23 [get_ports {linkspeed[0]}]
#set_property PACKAGE_PIN A24 [get_ports {linkspeed[1]}]

set_property PACKAGE_PIN AB26 [get_ports phy_txc]
set_property PACKAGE_PIN AB24 [get_ports {phy_txd[0]}]
set_property PACKAGE_PIN AB25 [get_ports {phy_txd[1]}]
set_property PACKAGE_PIN AF23 [get_ports {phy_txd[2]}]
set_property PACKAGE_PIN AC26 [get_ports {phy_txd[3]}]
set_property PACKAGE_PIN AC23 [get_ports phy_rxc]
set_property PACKAGE_PIN AE23 [get_ports {phy_rxd[0]}]
set_property PACKAGE_PIN AD24 [get_ports {phy_rxd[1]}]
set_property PACKAGE_PIN AF24 [get_ports {phy_rxd[2]}]
set_property PACKAGE_PIN AF25 [get_ports {phy_rxd[3]}]


set_property PACKAGE_PIN AE13 [get_ports {imgen_bt656_data[7]}]
set_property PACKAGE_PIN AF15 [get_ports {imgen_bt656_data[6]}]
set_property PACKAGE_PIN AF13 [get_ports {imgen_bt656_data[4]}]
set_property PACKAGE_PIN AB14 [get_ports {imgen_bt656_data[3]}]
set_property PACKAGE_PIN AD14 [get_ports {imgen_bt656_data[1]}]
set_property PACKAGE_PIN AB15 [get_ports {imgen_bt656_data[0]}]



set_property IOSTANDARD LVCMOS33 [get_ports {imgen_bt656_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {imgen_bt656_data[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {imgen_bt656_data[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {imgen_bt656_data[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {imgen_bt656_data[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {imgen_bt656_data[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {imgen_bt656_data[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {imgen_bt656_data[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports imgen_bt656_clk]


set_property PACKAGE_PIN AD15 [get_ports i_pc_rxd]
set_property PACKAGE_PIN AD11 [get_ports o_pc_txd]
set_property PACKAGE_PIN AD13 [get_ports i_thv_rxd]
set_property PACKAGE_PIN AC13 [get_ports o_thv_txd]
set_property IOSTANDARD LVCMOS33 [get_ports i_pc_rxd]
set_property IOSTANDARD LVCMOS33 [get_ports i_thv_rxd]
set_property IOSTANDARD LVCMOS33 [get_ports o_pc_txd]
set_property IOSTANDARD LVCMOS33 [get_ports o_thv_txd]




create_clock -period 8.000 -name phy_rxc -waveform {0.000 4.000} [get_ports phy_rxc]





set_property PACKAGE_PIN AC12 [get_ports imgen_bt656_clk]


set_property PACKAGE_PIN AF19 [get_ports {imgen_bt656_data[5]}]
set_property PACKAGE_PIN AE18 [get_ports {imgen_bt656_data[2]}]










connect_debug_port dbg_hub/clk [get_nets u_ila_0_clk_out2]



connect_debug_port u_ila_0/probe9 [get_nets [list overload_inst01/flag_1s]]
connect_debug_port u_ila_0/probe10 [get_nets [list overload_inst01/flag_link]]
connect_debug_port u_ila_0/probe15 [get_nets [list overload_inst01/rec_flag]]
connect_debug_port u_ila_0/probe16 [get_nets [list overload_inst01/rx_lost_flag]]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_wiz_inst0/inst/clk_out2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {overload_inst01/cnt_reset0[0]} {overload_inst01/cnt_reset0[1]} {overload_inst01/cnt_reset0[2]} {overload_inst01/cnt_reset0[3]} {overload_inst01/cnt_reset0[4]} {overload_inst01/cnt_reset0[5]} {overload_inst01/cnt_reset0[6]} {overload_inst01/cnt_reset0[7]} {overload_inst01/cnt_reset0[8]} {overload_inst01/cnt_reset0[9]} {overload_inst01/cnt_reset0[10]} {overload_inst01/cnt_reset0[11]} {overload_inst01/cnt_reset0[12]} {overload_inst01/cnt_reset0[13]} {overload_inst01/cnt_reset0[14]} {overload_inst01/cnt_reset0[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 4 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {overload_inst01/r_cstate[0]} {overload_inst01/r_cstate[1]} {overload_inst01/r_cstate[2]} {overload_inst01/r_cstate[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 20 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {overload_inst01/cnt_reset[0]} {overload_inst01/cnt_reset[1]} {overload_inst01/cnt_reset[2]} {overload_inst01/cnt_reset[3]} {overload_inst01/cnt_reset[4]} {overload_inst01/cnt_reset[5]} {overload_inst01/cnt_reset[6]} {overload_inst01/cnt_reset[7]} {overload_inst01/cnt_reset[8]} {overload_inst01/cnt_reset[9]} {overload_inst01/cnt_reset[10]} {overload_inst01/cnt_reset[11]} {overload_inst01/cnt_reset[12]} {overload_inst01/cnt_reset[13]} {overload_inst01/cnt_reset[14]} {overload_inst01/cnt_reset[15]} {overload_inst01/cnt_reset[16]} {overload_inst01/cnt_reset[17]} {overload_inst01/cnt_reset[18]} {overload_inst01/cnt_reset[19]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 2 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {linkspeed[0]} {linkspeed[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list overload_inst01/add_cnt_reset]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list overload_inst01/add_cnt_reset0]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list overload_inst01/dev_off_to_idle]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list overload_inst01/dev_on_to_normal]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list overload_inst01/end_cnt_reset0]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list overload_inst01/idle_to_dev_on]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list locked]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list locked_300M]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list overload_inst01/normal_to_dev_off]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list vio_cap_1]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list vio_fifo_1]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list vio_udp_0]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_out_300M]
