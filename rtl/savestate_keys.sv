//
// savestate_keys.sv
//
// Save state front end: F1..F8 load slot 1..8, Shift+F1..F8 save into it, and
// the same eight slots from a pad by holding the Savestates button.
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

module savestate_keys #(parameter INFO_TIMEOUT_BITS = 26)
(
	input             clk,
	input             enable,

	input      [10:0] ps2_key,

	input             joy_ss,
	input             joy_right,
	input             joy_left,
	input             joy_down,
	input             joy_up,

	input       [2:0] menu_slot,
	input             osd_save,
	input             osd_load,

	output reg        save = 0,
	output reg        load = 0,
	output reg  [2:0] slot = 0,

	output reg        info_req = 0,
	output reg  [7:0] info = 0,
	output reg        status_update = 0
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

reg        old_toggle = 0;
reg        shift_down = 0;
reg  [7:0] fkey_down  = 0;
reg        old_right  = 0;
reg        old_left   = 0;
reg        old_down   = 0;
reg        old_up     = 0;
reg        old_osd_s  = 0;
reg        old_osd_l  = 0;
reg  [2:0] old_menu   = 0;
reg        slot_shown = 0;
reg [(INFO_TIMEOUT_BITS-1):0] idle = 0;

always @(posedge clk) begin

	save          <= 0;
	load          <= 0;
	info_req      <= 0;
	status_update <= 0;
	slot_shown    <= 0;

	old_toggle <= ps2_key[10];
	old_right  <= joy_right;
	old_left   <= joy_left;
	old_down   <= joy_down;
	old_up     <= joy_up;
	old_osd_s  <= osd_save;
	old_osd_l  <= osd_load;
	old_menu   <= menu_slot;

	if(enable) begin

		if(old_toggle != ps2_key[10]) begin
			if(ps2_key[7:0] == SC_LSHFT || ps2_key[7:0] == SC_RSHFT) shift_down <= ps2_key[9];
			if(is_fkey) begin
				fkey_down[fkey] <= ps2_key[9];
				if(ps2_key[9] & ~fkey_down[fkey]) begin
					slot          <= fkey;
					status_update <= 1;
					if(shift_down) save <= 1;
					else           load <= 1;
				end
			end
		end

		if(old_menu != menu_slot) slot <= menu_slot;

		if(joy_ss) begin
			idle <= idle + 1'd1;
			if(idle[INFO_TIMEOUT_BITS-1]) begin
				info     <= 8'd1;
				info_req <= 1;
				idle     <= 0;
			end
			if(joy_right & ~old_right & slot < 3'd7) begin
				slot          <= slot + 1'd1;
				status_update <= 1;
				slot_shown    <= 1;
				idle          <= 0;
			end
			if(joy_left & ~old_left & slot > 3'd0) begin
				slot          <= slot - 1'd1;
				status_update <= 1;
				slot_shown    <= 1;
				idle          <= 0;
			end
			if(joy_down & ~old_down) begin save <= 1; idle <= 0; end
			if(joy_up   & ~old_up  ) begin load <= 1; idle <= 0; end
		end
		else idle <= 0;

		if(~old_osd_s & osd_save) save <= 1;
		if(~old_osd_l & osd_load) load <= 1;
	end

	if(slot_shown) begin
		info     <= 8'd2 + {5'd0, slot};
		info_req <= 1;
	end

	if(save | load) begin
		info     <= 8'd10 + {4'd0, slot, load};
		info_req <= 1;
	end
end

endmodule
