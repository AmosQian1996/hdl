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

module omega #(
  parameter PORT_DATA_WIDTH = 16,
  parameter PORT_ADDRESS_WIDTH = 3,
  parameter FLIP = 0 // 0 = Omega, 1 = Flip
) (
  input clk,

  input [(PORT_ADDRESS_WIDTH * 2**(PORT_ADDRESS_WIDTH-1))-1:0] ctrl,

  input [PORT_DATA_WIDTH*2**PORT_ADDRESS_WIDTH-1:0] data_in,
  output [PORT_DATA_WIDTH*2**PORT_ADDRESS_WIDTH-1:0] data_out
);

localparam SWITCHES_PER_STAGE = 2**(PORT_ADDRESS_WIDTH-1);
localparam TOTAL_DATA_WIDTH = PORT_DATA_WIDTH * 2**PORT_ADDRESS_WIDTH;

reg [TOTAL_DATA_WIDTH-1:0] interconnect[0:PORT_ADDRESS_WIDTH];

assign data_out = interconnect[PORT_ADDRESS_WIDTH];
always @(*) begin
  interconnect[0] <= data_in;
end

generate
genvar i;
genvar j;

/* Do perfect shuffle, either in forward (omega) or reverse (flip) direction */
for (i = 0; i < PORT_ADDRESS_WIDTH; i = i + 1) begin
  for (j = 0; j < SWITCHES_PER_STAGE; j = j + 1) begin
    localparam linear_lsb0 = j*PORT_DATA_WIDTH*2;
    localparam linear_lsb1 = j*PORT_DATA_WIDTH*2+PORT_DATA_WIDTH;
    localparam shuffle_lsb0 = j*PORT_DATA_WIDTH;
    localparam shuffle_lsb1 = (j+SWITCHES_PER_STAGE)*PORT_DATA_WIDTH;
    localparam src_lsb0 = FLIP == 0 ? shuffle_lsb0 : linear_lsb0;
    localparam src_lsb1 = FLIP == 0 ? shuffle_lsb1 : linear_lsb1;
    localparam dst_lsb0 = FLIP == 1 ? shuffle_lsb0 : linear_lsb0;
    localparam dst_lsb1 = FLIP == 1 ? shuffle_lsb1 : linear_lsb1;
    localparam w = PORT_DATA_WIDTH;

    always @(*) begin
      case (ctrl[i*SWITCHES_PER_STAGE+j])
      1'b0: begin
        interconnect[i+1][dst_lsb0+:w] <= interconnect[i][src_lsb0+:w];
        interconnect[i+1][dst_lsb1+:w] <= interconnect[i][src_lsb1+:w];
      end
      1'b1: begin
        interconnect[i+1][dst_lsb0+:w] <= interconnect[i][src_lsb1+:w];
        interconnect[i+1][dst_lsb1+:w] <= interconnect[i][src_lsb0+:w];
      end
      endcase
    end
  end
end

endgenerate

endmodule
