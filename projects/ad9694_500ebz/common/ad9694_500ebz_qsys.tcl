# ad9694-xcvr

add_instance ad9694_jesd204 adi_jesd204
set_instance_parameter_value ad9694_jesd204 {ID} {1}
set_instance_parameter_value ad9694_jesd204 {TX_OR_RX_N} {0}
set_instance_parameter_value ad9694_jesd204 {LANE_RATE} {10000.0}
set_instance_parameter_value ad9694_jesd204 {REFCLK_FREQUENCY} {333.333333}
set_instance_parameter_value ad9694_jesd204 {NUM_OF_LANES} {4}
set_instance_parameter_value ad9694_jesd204 {SOFT_PCS} {true}

add_connection sys_clk.clk ad9694_jesd204.sys_clk
add_connection sys_clk.clk_reset ad9694_jesd204.sys_resetn
add_interface rx_ref_clk clock sink
set_interface_property rx_ref_clk EXPORT_OF ad9694_jesd204.ref_clk
add_interface rx_serial_data conduit end
set_interface_property rx_serial_data EXPORT_OF ad9694_jesd204.serial_data
add_interface rx_sysref conduit end
set_interface_property rx_sysref EXPORT_OF ad9694_jesd204.sysref
add_interface rx_sync conduit end
set_interface_property rx_sync EXPORT_OF ad9694_jesd204.sync

# ad9694

add_instance axi_ad9694_core axi_ad9694
set_instance_parameter_value axi_ad9694_core {CHANNEL_WIDTH} {8}

add_connection ad9694_jesd204.link_clk axi_ad9694_core.if_rx_clk
add_connection ad9694_jesd204.link_sof axi_ad9694_core.if_rx_sof
add_connection ad9694_jesd204.link_data axi_ad9694_core.if_rx_data
add_connection sys_clk.clk_reset axi_ad9694_core.s_axi_reset
add_connection sys_clk.clk axi_ad9694_core.s_axi_clock

# ad9694-pack

add_instance util_ad9694_cpack util_cpack
set_instance_parameter_value util_ad9694_cpack {CHANNEL_DATA_WIDTH} {64}
set_instance_parameter_value util_ad9694_cpack {NUM_OF_CHANNELS} {2}

add_connection sys_clk.clk_reset util_ad9694_cpack.if_adc_rst
add_connection ad9694_jesd204.link_clk util_ad9694_cpack.if_adc_clk
add_connection axi_ad9694_core.adc_ch_0 util_ad9694_cpack.adc_ch_0
add_connection axi_ad9694_core.adc_ch_1 util_ad9694_cpack.adc_ch_1

# ad9694-fifo

add_instance ad9694_adcfifo util_adcfifo
set_instance_parameter_value ad9694_adcfifo {ADC_DATA_WIDTH} {128}
set_instance_parameter_value ad9694_adcfifo {DMA_DATA_WIDTH} {128}
set_instance_parameter_value ad9694_adcfifo {DMA_ADDRESS_WIDTH} {16}

add_connection sys_clk.clk_reset ad9694_adcfifo.if_adc_rst
add_connection ad9694_jesd204.link_clk ad9694_adcfifo.if_adc_clk
add_connection util_ad9694_cpack.if_adc_valid ad9694_adcfifo.if_adc_wr
add_connection util_ad9694_cpack.if_adc_data ad9694_adcfifo.if_adc_wdata
add_connection sys_dma_clk.clk ad9694_adcfifo.if_dma_clk
add_connection sys_dma_clk.clk_reset ad9694_adcfifo.if_adc_rst

# ad9694-dma

add_instance axi_ad9694_dma axi_dmac
set_instance_parameter_value axi_ad9694_dma {DMA_DATA_WIDTH_SRC} {128}
set_instance_parameter_value axi_ad9694_dma {DMA_DATA_WIDTH_DEST} {128}
set_instance_parameter_value axi_ad9694_dma {DMA_LENGTH_WIDTH} {24}
set_instance_parameter_value axi_ad9694_dma {DMA_2D_TRANSFER} {0}
set_instance_parameter_value axi_ad9694_dma {SYNC_TRANSFER_START} {0}
set_instance_parameter_value axi_ad9694_dma {CYCLIC} {0}
set_instance_parameter_value axi_ad9694_dma {DMA_TYPE_DEST} {0}
set_instance_parameter_value axi_ad9694_dma {DMA_TYPE_SRC} {1}

add_connection sys_dma_clk.clk axi_ad9694_dma.if_s_axis_aclk
add_connection ad9694_adcfifo.if_dma_wr axi_ad9694_dma.if_s_axis_valid
add_connection ad9694_adcfifo.if_dma_wdata axi_ad9694_dma.if_s_axis_data
add_connection ad9694_adcfifo.if_dma_wready axi_ad9694_dma.if_s_axis_ready
add_connection ad9694_adcfifo.if_dma_xfer_req axi_ad9694_dma.if_s_axis_xfer_req
add_connection ad9694_adcfifo.if_adc_wovf axi_ad9694_core.if_adc_dovf
add_connection sys_clk.clk_reset axi_ad9694_dma.s_axi_reset
add_connection sys_clk.clk axi_ad9694_dma.s_axi_clock
add_connection sys_dma_clk.clk_reset axi_ad9694_dma.m_dest_axi_reset
add_connection sys_dma_clk.clk axi_ad9694_dma.m_dest_axi_clock

for {set i 0} {$i < 4} {incr i} {
  add_instance avl_adxcfg_${i} avl_adxcfg
  add_connection sys_clk.clk avl_adxcfg_${i}.rcfg_clk
  add_connection sys_clk.clk_reset avl_adxcfg_${i}.rcfg_reset_n
  add_connection avl_adxcfg_${i}.rcfg_m0 ad9694_jesd204.phy_reconfig_${i}
}

# addresses

ad_cpu_interconnect 0x00040000 ad9694_jesd204.link_reconfig
ad_cpu_interconnect 0x00044000 ad9694_jesd204.link_management
ad_cpu_interconnect 0x00045000 ad9694_jesd204.link_pll_reconfig
ad_cpu_interconnect 0x00048000 avl_adxcfg_0.rcfg_s0
ad_cpu_interconnect 0x00049000 avl_adxcfg_1.rcfg_s0
ad_cpu_interconnect 0x0004a000 avl_adxcfg_2.rcfg_s0
ad_cpu_interconnect 0x0004b000 avl_adxcfg_3.rcfg_s0
ad_cpu_interconnect 0x0004c000 axi_ad9694_dma.s_axi
ad_cpu_interconnect 0x00050000 axi_ad9694_core.s_axi

# dma interconnects

ad_dma_interconnect axi_ad9694_dma.m_dest_axi

# interrupts

ad_cpu_interrupt  8 ad9694_jesd204.interrupt
ad_cpu_interrupt  9 axi_ad9694_dma.interrupt_sender

