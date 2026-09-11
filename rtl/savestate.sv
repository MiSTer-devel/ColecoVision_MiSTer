//
// savestate.sv
//
// ColecoVision save states, 8 slots in one file mounted from the OSD.
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

module savestate
(
	input             clk,
	input             reset,

	input             save_req,
	input             load_req,
	input       [2:0] slot,
	input             mounted,
	input             readonly,

	input             bnd,
	output reg        frz = 0,
	output reg        cpuset = 0,
	output reg        cen_p = 0,
	output reg        cen_n = 0,
	output            busy,
	output            loading,

	input      [31:0] rom_sum,
	input      [24:0] rom_len,
	input       [5:0] cart_pages,
	input             sg1000,
	input             extram,
	input       [1:0] ram_size,

	output            reg_wr,
	input       [7:0] reg_dout,

	output            ram_sel,
	output            vram_sel,
	output     [14:0] ram_a,
	output     [13:0] vram_a,
	input       [7:0] ram_di,
	input       [7:0] vram_di,

	output     [31:0] sd_lba,
	output reg        sd_rd = 0,
	output reg        sd_wr = 0,
	input             sd_ack,
	input      [13:0] sd_buff_addr,
	input       [7:0] sd_buff_dout,
	output      [7:0] sd_buff_din,
	input             sd_buff_wr
);

localparam VER      = 8'd1;
localparam BLK_LAST = 7'd96;

localparam ST_IDLE  = 3'd0;
localparam ST_WAIT  = 3'd1;
localparam ST_REQ   = 3'd2;
localparam ST_ACK   = 3'd3;
localparam ST_SET   = 3'd4;
localparam ST_CATCH = 3'd5;
localparam ST_END   = 3'd6;

reg  [2:0] st = ST_IDLE;
reg  [2:0] slot_r = 0;
reg  [6:0] blk;
reg        loading_r = 0;
reg        hdr_bad;
reg        busy_r = 0;

assign busy    = busy_r;
assign loading = loading_r;

wire xfer = (st == ST_REQ) || (st == ST_ACK);

assign ram_sel  = xfer && (blk >= 7'd1)  && (blk <= 7'd64);
assign vram_sel = xfer && (blk >= 7'd65) && (blk <= BLK_LAST);
assign ram_a    = {blk[5:0] - 6'd1, sd_buff_addr[8:0]};
assign vram_a   = {blk[4:0] - 5'd1, sd_buff_addr[8:0]};

assign reg_wr = loading_r && xfer && !blk && sd_buff_wr && !hdr_bad &&
                (sd_buff_addr >= 14'd32) && (sd_buff_addr < 14'd256);

assign sd_lba = {22'd0, slot_r, blk};

wire [7:0] hdr_byte =
	(sd_buff_addr[4:0] == 5'd0)  ? 8'h43 :
	(sd_buff_addr[4:0] == 5'd1)  ? 8'h56 :
	(sd_buff_addr[4:0] == 5'd2)  ? 8'h53 :
	(sd_buff_addr[4:0] == 5'd3)  ? 8'h53 :
	(sd_buff_addr[4:0] == 5'd4)  ? VER :
	(sd_buff_addr[4:0] == 5'd5)  ? {6'd0, extram, sg1000} :
	(sd_buff_addr[4:0] == 5'd6)  ? {2'd0, cart_pages} :
	(sd_buff_addr[4:0] == 5'd7)  ? {6'd0, ram_size} :
	(sd_buff_addr[4:0] == 5'd8)  ? rom_sum[7:0]   :
	(sd_buff_addr[4:0] == 5'd9)  ? rom_sum[15:8]  :
	(sd_buff_addr[4:0] == 5'd10) ? rom_sum[23:16] :
	(sd_buff_addr[4:0] == 5'd11) ? rom_sum[31:24] :
	(sd_buff_addr[4:0] == 5'd12) ? rom_len[7:0]   :
	(sd_buff_addr[4:0] == 5'd13) ? rom_len[15:8]  :
	(sd_buff_addr[4:0] == 5'd14) ? rom_len[23:16] :
	(sd_buff_addr[4:0] == 5'd15) ? {7'd0, rom_len[24]} : 8'd0;

assign sd_buff_din = ram_sel  ? ram_di  :
                     vram_sel ? vram_di :
                     (sd_buff_addr >= 14'd256) ? 8'd0 :
                     (sd_buff_addr <  14'd32)  ? hdr_byte : reg_dout;

always @(posedge clk) begin
	reg old_save, old_load, old_ack;
	reg [7:0] catch_cnt;
	reg [2:0] ph;
	reg [2:0] setcnt;

	old_save <= save_req;
	old_load <= load_req;
	old_ack  <= sd_ack;

	cen_p <= 0;
	cen_n <= 0;

	if(loading_r && xfer && !blk && sd_buff_wr && (sd_buff_addr < 14'd32)) begin
		case(sd_buff_addr[4:0])
			5'd0:  if(sd_buff_dout != 8'h43) hdr_bad <= 1;
			5'd1:  if(sd_buff_dout != 8'h56) hdr_bad <= 1;
			5'd2:  if(sd_buff_dout != 8'h53) hdr_bad <= 1;
			5'd3:  if(sd_buff_dout != 8'h53) hdr_bad <= 1;
			5'd4:  if(sd_buff_dout != VER) hdr_bad <= 1;
			5'd6:  if(sd_buff_dout[5:0] != cart_pages) hdr_bad <= 1;
			5'd8:  if(sd_buff_dout != rom_sum[7:0])   hdr_bad <= 1;
			5'd9:  if(sd_buff_dout != rom_sum[15:8])  hdr_bad <= 1;
			5'd10: if(sd_buff_dout != rom_sum[23:16]) hdr_bad <= 1;
			5'd11: if(sd_buff_dout != rom_sum[31:24]) hdr_bad <= 1;
			5'd12: if(sd_buff_dout != rom_len[7:0])   hdr_bad <= 1;
			5'd13: if(sd_buff_dout != rom_len[15:8])  hdr_bad <= 1;
			5'd14: if(sd_buff_dout != rom_len[23:16]) hdr_bad <= 1;
			5'd15: if(sd_buff_dout != {7'd0, rom_len[24]}) hdr_bad <= 1;
			default: ;
		endcase
	end

	if(reset) begin
		st          <= ST_IDLE;
		frz         <= 0;
		busy_r      <= 0;
		cpuset      <= 0;
		{sd_rd, sd_wr} <= 2'b00;
	end
	else begin
		case(st)
			ST_IDLE:
				begin
					frz    <= 0;
					busy_r <= 0;
					if(mounted & ~old_save & save_req & ~readonly) begin
						loading_r <= 0;
						slot_r  <= slot;
						busy_r  <= 1;
						st      <= ST_WAIT;
					end
					else if(mounted & ~old_load & load_req) begin
						loading_r <= 1;
						slot_r  <= slot;
						busy_r  <= 1;
						st      <= ST_WAIT;
					end
				end

			ST_WAIT:
				if(bnd) begin
					frz     <= 1;
					blk     <= 0;
					hdr_bad <= 0;
					st      <= ST_REQ;
				end

			ST_REQ:
				begin
					if(loading_r) sd_rd <= 1;
					else        sd_wr <= 1;
					st <= ST_ACK;
				end

			ST_ACK:
				begin
					if(sd_ack) {sd_rd, sd_wr} <= 2'b00;
					if(old_ack & ~sd_ack) begin
						if(loading_r & ~|blk & hdr_bad) st <= ST_END;
						else if(blk == BLK_LAST) begin
							setcnt <= 0;
							st     <= loading_r ? ST_SET : ST_END;
						end
						else begin
							blk <= blk + 1'd1;
							st  <= ST_REQ;
						end
					end
				end

			ST_SET:
				begin
					cpuset <= 1;
					setcnt <= setcnt + 1'd1;
					if(setcnt == 3'd4) begin
						cpuset    <= 0;
						catch_cnt <= 0;
						ph        <= 0;
						st        <= ST_CATCH;
					end
				end

			ST_CATCH:
				begin
					ph <= ph + 1'd1;
					if(ph == 0) cen_p <= 1;
					if(ph == 4) cen_n <= 1;
					if(ph == 7) begin
						catch_cnt <= catch_cnt + 1'd1;
						if(bnd || (catch_cnt > 8'd200)) st <= ST_END;
					end
				end

			ST_END:
				begin
					frz    <= 0;
					busy_r <= 0;
					st     <= ST_IDLE;
				end

			default: st <= ST_IDLE;
		endcase
	end
end

endmodule
