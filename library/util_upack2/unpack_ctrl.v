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

module unpack_ctrl #(
  parameter PORT_DATA_WIDTH = 16,
  parameter PORT_ADDRESS_WIDTH = 2,
  parameter PACK = 0
) (
  input [PORT_ADDRESS_WIDTH-1:0] r,

  input [2**PORT_ADDRESS_WIDTH-1:0] mask,
  output [(SWITCHES_PER_STAGE*PORT_ADDRESS_WIDTH)-1:0] ctrl,
  output [PORT_ADDRESS_WIDTH:0] channel_count
);

localparam SWITCHES_PER_STAGE = 2**(PORT_ADDRESS_WIDTH-1);
localparam TOTAL_DATA_WIDTH = PORT_DATA_WIDTH * 2**PORT_ADDRESS_WIDTH;

wire [PORT_ADDRESS_WIDTH-1:0] prefix_count[0:2**PORT_ADDRESS_WIDTH-1];
wire [(SWITCHES_PER_STAGE*PORT_ADDRESS_WIDTH)-1:0] _ctrl;

generate
genvar i;
genvar j;
genvar n;

assign prefix_count[0] = ~mask[0];

for (i = 1; i < 2**PORT_ADDRESS_WIDTH; i = i + 1) begin
  assign prefix_count[i] = prefix_count[i-1] + ~mask[i];
end

assign channel_count = 2**PORT_ADDRESS_WIDTH-prefix_count[2**PORT_ADDRESS_WIDTH-1];

for (i = 0; i < PORT_ADDRESS_WIDTH; i = i + 1) begin
  localparam k = 2**i;
  localparam o = PORT_ADDRESS_WIDTH - i - 1;

  for (j = 0; j < 2**(PORT_ADDRESS_WIDTH-i-1); j = j + 1) begin
    localparam m = k * (j * 2 + 1) - 1;
    localparam min = i * SWITCHES_PER_STAGE + k*j;
    localparam max = min+k-1;
    assign _ctrl[max:min] = ({{k{1'b1}},{k{1'b0}}}) >> (((2*k - r) + prefix_count[m]) % (k*2));
  end

end

for (i = 0; i < PORT_ADDRESS_WIDTH; i = i + 1) begin
  localparam k = 2**i;
  localparam basex = i * SWITCHES_PER_STAGE;
  localparam basey = PACK ? basex : (PORT_ADDRESS_WIDTH-1) * SWITCHES_PER_STAGE - basex;
  for (j = 0; j < SWITCHES_PER_STAGE; j = j + 1) begin
    localparam x = basex + j;
    localparam y = basey + (j*k) % SWITCHES_PER_STAGE + (j*k) / SWITCHES_PER_STAGE;
    assign ctrl[x] = _ctrl[y];
  end
end

endgenerate

endmodule
