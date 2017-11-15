
package require qsys
source ../scripts/adi_env.tcl
source ../scripts/adi_ip_alt.tcl

ad_ip_create axi_adc_jesd204 {AXI RX JESD204 Transport Layer} p_axi_adc_jesd204_elab
ad_ip_files axi_adc_jesd204 [list \
	$ad_hdl_dir/library/common/ad_rst.v \
	$ad_hdl_dir/library/common/ad_pnmon.v \
	$ad_hdl_dir/library/common/ad_datafmt.v \
	$ad_hdl_dir/library/common/up_axi.v \
	$ad_hdl_dir/library/common/up_xfer_cntrl.v \
	$ad_hdl_dir/library/common/up_xfer_status.v \
	$ad_hdl_dir/library/common/up_clock_mon.v \
	$ad_hdl_dir/library/common/up_delay_cntrl.v \
	$ad_hdl_dir/library/common/up_adc_common.v \
	$ad_hdl_dir/library/common/up_adc_channel.v \
	$ad_hdl_dir/library/common/ad_xcvr_rx_if.v \
  $ad_hdl_dir/library/axi_adc_jesd204/axi_adc_jesd204_pnmon.v \
  $ad_hdl_dir/library/axi_adc_jesd204/axi_adc_jesd204_channel.v \
  $ad_hdl_dir/library/axi_adc_jesd204/axi_adc_jesd204_core.v \
  $ad_hdl_dir/library/axi_adc_jesd204/axi_adc_jesd204_if.v \
  $ad_hdl_dir/library/axi_adc_jesd204/axi_adc_jesd204.v \
  $ad_hdl_dir/library/altera/common/up_xfer_cntrl_constr.sdc \
  $ad_hdl_dir/library/altera/common/up_xfer_status_constr.sdc \
  $ad_hdl_dir/library/altera/common/up_clock_mon_constr.sdc \
  $ad_hdl_dir/library/altera/common/up_rst_constr.sdc]

# parameters

ad_ip_parameter ID INTEGER 0
ad_ip_parameter NUM_CHANNELS INTEGER 1
ad_ip_parameter CHANNEL_WIDTH INTEGER 14
ad_ip_parameter NUM_LANES INTEGER 1
ad_ip_parameter TWOS_COMPLEMENT INTEGER 1

# axi4 slave

ad_ip_intf_s_axi s_axi_aclk s_axi_aresetn

# core clock and start of frame

ad_alt_intf clock   rx_clk  input 1
ad_alt_intf signal  rx_sof  input 4 export

# elaborate

proc p_axi_adc_jesd204_elab {} {

  # read core parameters

  set m_num_of_lanes [get_parameter_value "NUM_LANES"]
  set m_num_of_channels [get_parameter_value "NUM_CHANNELS"]
  set channel_bus_witdh [expr 32*$m_num_of_lanes/$m_num_of_channels]

  # link layer interface

  add_interface if_rx_data avalon_streaming sink
  add_interface_port  if_rx_data  rx_data   data  input   [expr 32*$m_num_of_lanes]
  add_interface_port  if_rx_data  rx_valid  valid input   1
  add_interface_port  if_rx_data  rx_ready  ready output  1
  set_interface_property if_rx_data associatedClock if_rx_clk
  set_interface_property if_rx_data dataBitsPerSymbol [expr 32*$m_num_of_lanes]

  # dma interface

  for {set i 0} {$i < $m_num_of_channels} {incr i} {

    add_interface adc_ch_$i conduit end
    add_interface_port adc_ch_$i adc_enable_$i enable output 1
    set_port_property adc_enable_$i fragment_list [format "adc_enable(%d:%d)" $i $i]
    add_interface_port adc_ch_$i adc_valid_$i  valid  output 1
    set_port_property adc_valid_$i fragment_list [format "adc_valid(%d:%d)" $i $i]
    add_interface_port adc_ch_$i adc_data_$i   data   output $channel_bus_witdh
    set_port_property adc_data_$i fragment_list \
          [format "adc_data(%d:%d)" [expr $channel_bus_witdh*$i+$channel_bus_witdh-1] [expr $channel_bus_witdh*$i]]
    set_interface_property adc_ch_$i associatedClock if_rx_clk
    set_interface_property adc_ch_$i associatedReset none
  }

  ad_alt_intf signal  adc_dovf  input  1 ovf

}

