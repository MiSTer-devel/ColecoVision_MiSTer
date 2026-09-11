//
// savestate_keys.sv
//
// Save state hot keys: F1..F8 load slot 1..8, Shift+F1..F8 save into it.
//
// Copyright (c) 2026
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

module savestate_keys
(
	input             clk,
	input             enable,

	input      [10:0] ps2_key,

	input             joy_save,
	input             joy_load,

	output reg        save = 0,
	output reg        load = 0,
	output reg  [2:0] slot = 0
);

localparam SC_LSHFT = 8'h12;
localparam SC_RSHFT = 8'h59;

reg  [2:0] fkey;
reg        is_fkey;

always @(*) begin
	is_fkey = 1;
	case(ps2_key[7:0])
		8'h05:   fkey = 3'd0;
		8'h06:   fkey = 3'd1;
		8'h04:   fkey = 3'd2;
		8'h0C:   fkey = 3'd3;
		8'h03:   fkey = 3'd4;
		8'h0B:   fkey = 3'd5;
		8'h83:   fkey = 3'd6;
		8'h0A:   fkey = 3'd7;
		default: begin fkey = 3'd0; is_fkey = 0; end
	endcase
end

reg        old_toggle   = 0;
reg        shift_down   = 0;
reg  [7:0] fkey_down    = 0;
reg        old_joy_save = 0;
reg        old_joy_load = 0;

always @(posedge clk) begin

	save <= 0;
	load <= 0;

	old_toggle <= ps2_key[10];
	if(old_toggle != ps2_key[10]) begin

		if(ps2_key[7:0] == SC_LSHFT || ps2_key[7:0] == SC_RSHFT) shift_down <= ps2_key[9];

		if(is_fkey) begin
			fkey_down[fkey] <= ps2_key[9];
			if(ps2_key[9] & ~fkey_down[fkey] & enable) begin
				slot <= fkey;
				if(shift_down) save <= 1;
				else           load <= 1;
			end
		end
	end

	old_joy_save <= joy_save;
	old_joy_load <= joy_load;
	if(~old_joy_save & joy_save & enable) save <= 1;
	if(~old_joy_load & joy_load & enable) load <= 1;
end

endmodule
