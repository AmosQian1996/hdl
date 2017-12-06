// ***************************************************************************
// ***************************************************************************
// Copyright 2017 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsabilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

module util_upack2 #(
  parameter NUM_OF_PORTS = 4,
  parameter PORT_DATA_WIDTH = 16
) (
  input clk,
  input reset,

  input enable_0,
  input enable_1,
  input enable_2,
  input enable_3,
  input enable_4,
  input enable_5,
  input enable_6,
  input enable_7,

  input fifo_rd_en,
  output reg fifo_rd_valid,
  output reg fifo_rd_underflow,

  output [PORT_DATA_WIDTH-1:0] fifo_rd_data_0,
  output [PORT_DATA_WIDTH-1:0] fifo_rd_data_1,
  output [PORT_DATA_WIDTH-1:0] fifo_rd_data_2,
  output [PORT_DATA_WIDTH-1:0] fifo_rd_data_3,
  output [PORT_DATA_WIDTH-1:0] fifo_rd_data_4,
  output [PORT_DATA_WIDTH-1:0] fifo_rd_data_5,
  output [PORT_DATA_WIDTH-1:0] fifo_rd_data_6,
  output [PORT_DATA_WIDTH-1:0] fifo_rd_data_7,

  input s_axis_valid,
  output s_axis_ready,
  input [NUM_OF_PORTS*PORT_DATA_WIDTH-1:0] s_axis_data
);

localparam PORT_ADDRESS_WIDTH =
  NUM_OF_PORTS > 4 ? 3:
  NUM_OF_PORTS > 2 ? 2 : 1;

localparam CTRL_WIDTH = NUM_OF_PORTS * PORT_ADDRESS_WIDTH / 2;

reg [PORT_DATA_WIDTH*NUM_OF_PORTS-1:0] fifo_rd_data = 'h00;
reg [PORT_ADDRESS_WIDTH-1:0] rotate = 'h00;

wire [NUM_OF_PORTS-1:0] enable;
wire [CTRL_WIDTH-1:0] unpack_ctrl;
wire [PORT_ADDRESS_WIDTH:0] channel_count;
wire [NUM_OF_PORTS*PORT_DATA_WIDTH-1:0] unpacked_data;
wire [PORT_ADDRESS_WIDTH:0] sum;

assign sum = rotate + channel_count;
assign s_axis_ready = sum[PORT_ADDRESS_WIDTH] & fifo_rd_en;

always @(posedge clk) begin
  if (reset == 1'b1) begin
    rotate <= 'h00;
  end else if (fifo_rd_en == 1'b1 && s_axis_valid == 1'b1) begin
    rotate <= sum;
  end
end

unpack_ctrl #(
  .PORT_ADDRESS_WIDTH(PORT_ADDRESS_WIDTH),
  .PORT_DATA_WIDTH(PORT_DATA_WIDTH),
  .PACK(0)
) i_unpack_ctrl (
  .r(rotate),
  .mask(enable),
  .ctrl(unpack_ctrl),
  .channel_count(channel_count)
);

omega #(
  .PORT_ADDRESS_WIDTH(PORT_ADDRESS_WIDTH),
  .PORT_DATA_WIDTH(PORT_DATA_WIDTH),
  .FLIP(0)
) omega_unpack (
  .clk(clk),
  .ctrl(unpack_ctrl),
  .data_in(s_axis_data),
  .data_out(unpacked_data)
);

always @(posedge clk) begin
  if (fifo_rd_en == 1'b1) begin
    fifo_rd_data <= unpacked_data;
    fifo_rd_valid <= s_axis_valid;;
    fifo_rd_underflow <= ~s_axis_valid;
  end else begin
    fifo_rd_valid <= 1'b0;
    fifo_rd_underflow <= 1'b0;
  end
end

/* FIXME: Find out how to do this in the IP-XACT */

wire [7:0] enable_s;
wire [PORT_DATA_WIDTH*8-1:0] fifo_rd_data_s;

assign enable_s = {enable_7,enable_6,enable_5,enable_4,enable_3,enable_2,enable_1,enable_0};
assign enable = enable_s[NUM_OF_PORTS-1:0];

assign fifo_rd_data_s = {{(8-NUM_OF_PORTS)*PORT_DATA_WIDTH{1'b0}},fifo_rd_data};

assign fifo_rd_data_0 = fifo_rd_data_s[PORT_DATA_WIDTH*0+:PORT_DATA_WIDTH];
assign fifo_rd_data_1 = fifo_rd_data_s[PORT_DATA_WIDTH*1+:PORT_DATA_WIDTH];
assign fifo_rd_data_2 = fifo_rd_data_s[PORT_DATA_WIDTH*2+:PORT_DATA_WIDTH];
assign fifo_rd_data_3 = fifo_rd_data_s[PORT_DATA_WIDTH*3+:PORT_DATA_WIDTH];
assign fifo_rd_data_4 = fifo_rd_data_s[PORT_DATA_WIDTH*4+:PORT_DATA_WIDTH];
assign fifo_rd_data_5 = fifo_rd_data_s[PORT_DATA_WIDTH*5+:PORT_DATA_WIDTH];
assign fifo_rd_data_6 = fifo_rd_data_s[PORT_DATA_WIDTH*6+:PORT_DATA_WIDTH];
assign fifo_rd_data_7 = fifo_rd_data_s[PORT_DATA_WIDTH*7+:PORT_DATA_WIDTH];

endmodule
