//============================================================================
//  ColecoVision
//
//  Port to MiSTer
//  Copyright (C) 2017-2019 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	`include "sys/emu_ports.vh"
);

assign ADC_BUS = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
 
assign LED_USER   = ioctl_download | ss_busy;
assign LED_DISK   = 0;
assign LED_POWER  = 0;
assign BUTTONS    = 0;
assign VGA_SCALER = 0;
assign VGA_DISABLE= 0;
assign HDMI_FREEZE= ss_frz;

wire [1:0] ar = status[2:1];
wire vga_de;
reg  en216p;
always @(posedge CLK_VIDEO) en216p <= ((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080) && !forced_scandoubler && !scale);

video_freak video_freak
(
	.*,
	.VGA_DE_IN(vga_de),
	.ARX((!ar) ? 12'd4 : (ar - 1'd1)),
	.ARY((!ar) ? 12'd3 : 12'd0),
	.CROP_SIZE(en216p ? 10'd216 : 10'd0),
	.CROP_OFF(0),
	.SCALE(status[11:10])
);

`include "build_id.v" 
parameter CONF_STR = {
	"Coleco;;",
	"-;",
	"F,COLBINROM;",
	"F,SG,Load SG-1000;",
	"-;",
	"O12,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O79,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"-;",
	"O6,Border,No,Yes;",
	"OAB,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"-;",
	"O3,Joysticks swap,No,Yes;",
	"-;",
	"O45,RAM Size,1KB,8KB,SGM;",
	"-;",
	"S0,SST,Savestate file;",
	"OCE,Savestate slot,1,2,3,4,5,6,7,8;",
	"RF,Save state (Shift+F1-F8);",
	"RG,Load state (F1-F8);",
	"-;",
	"R0,Reset;",
	"J1,Fire 1,Fire 2,*,#,0,1,2,3,4,5,6,7,8,9,Purple Tr,Blue Tr,Savestates;",
	"I,",
	"Slot=LEFT/RIGHT  Save=DOWN  Load=UP,",
	"Slot 1,","Slot 2,","Slot 3,","Slot 4,","Slot 5,","Slot 6,","Slot 7,","Slot 8,",
	"Saved to slot 1,","Loaded slot 1,",
	"Saved to slot 2,","Loaded slot 2,",
	"Saved to slot 3,","Loaded slot 3,",
	"Saved to slot 4,","Loaded slot 4,",
	"Saved to slot 5,","Loaded slot 5,",
	"Saved to slot 6,","Loaded slot 6,",
	"Saved to slot 7,","Loaded slot 7,",
	"Saved to slot 8,","Loaded slot 8;",
	"V,v",`BUILD_DATE
};

/////////////////  CLOCKS  ////////////////////////

wire clk_sys;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.locked(pll_locked)
);

reg ce_10m7 = 0;
reg ce_5m3 = 0;
always @(posedge clk_sys) begin
	reg [2:0] div;

	div <= div+1'd1;
	ce_10m7 <= !div[1:0] & ~ss_frz;
	ce_5m3  <= !div[2:0] & ~ss_frz;
end

/////////////////  HPS  ///////////////////////////

wire [127:0] status;
wire   [1:0] buttons;

wire [127:0] status_in = {status[127:15], ss_slot, status[11:0]};

wire [31:0] joy0, joy1;

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        forced_scandoubler;
wire [21:0] gamma_bus;
wire [10:0] ps2_key;

wire [31:0] sd_lba[1];
wire  [5:0] sd_blk_cnt[1];
wire        sd_rd;
wire        sd_wr;
wire        sd_ack;
wire [13:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din[1];
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;
 
hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.buttons(buttons),
	.status(status),
	.status_in(status_in),
	.status_set(ss_status_upd),
	.info_req(ss_info_req),
	.info(ss_info),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),

	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.joystick_0(joy0),
	.joystick_1(joy1),
	.ps2_key(ps2_key),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.sd_lba(sd_lba),
	.sd_blk_cnt(sd_blk_cnt),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr)
);

/////////////////  RESET  /////////////////////////

wire reset = RESET | status[0] | buttons[1] | ioctl_download;

/////////////////  Memory  ////////////////////////

wire [12:0] bios_a;
wire  [7:0] bios_d;

spram #(13,8,"rtl/bios.mif") rom
(
	.clock(clk_sys),
	.address(bios_a),
	.q(bios_d)
);

wire [14:0] cpu_ram_a;
wire        ram_we_n, ram_ce_n;
wire  [7:0] ram_di;
wire  [7:0] ram_do;

wire [14:0] ram_a_cpu = (extram)            ? cpu_ram_a       :
                        (status[5:4] == 1)  ? cpu_ram_a[12:0] :
                        (status[5:4] == 0)  ? cpu_ram_a[9:0]  :
                        (sg1000)            ? cpu_ram_a[12:0] :
                                              cpu_ram_a;

wire [14:0] ram_a = ss_ram_sel ? ss_ram_a : ram_a_cpu;

spram #(15) ram
(
	.clock(clk_sys),
	.address(ram_a),
	.wren(ss_ram_sel ? (sd_buff_wr & ss_loading) : (ce_10m7 & ~(ram_we_n | ram_ce_n))),
	.data(ss_ram_sel ? sd_buff_dout : ram_do),
	.q(ram_di)
);

wire [13:0] vram_a;
wire        vram_we;
wire  [7:0] vram_di;
wire  [7:0] vram_do;

spram #(14) vram
(
	.clock(clk_sys),
	.address(ss_vram_sel ? ss_vram_a : vram_a),
	.wren(ss_vram_sel ? (sd_buff_wr & ss_loading) : vram_we),
	.data(ss_vram_sel ? sd_buff_dout : vram_do),
	.q(vram_di)
);

wire [19:0] cart_a;
wire  [7:0] cart_d;
wire        cart_rd;

reg [5:0] cart_pages;
always @(posedge clk_sys) if(ioctl_wr) cart_pages <= ioctl_addr[19:14];

reg [31:0] rom_sum;
reg [24:0] rom_len;
always @(posedge clk_sys) begin
	if(ioctl_wr) begin
		if(!ioctl_addr) begin
			rom_sum <= ioctl_dout;
			rom_len <= 1;
		end
		else begin
			rom_sum <= {rom_sum[30:0], rom_sum[31]} + ioctl_dout;
			rom_len <= ioctl_addr + 1'd1;
		end
	end
end

assign SDRAM_CLK = ~clk_sys;
sdram sdram
(
	.*,
	.init(~pll_locked),
	.clk(clk_sys),

   .wtbt(0),
   .addr(ioctl_download ? ioctl_addr : cart_a),
   .rd(cart_rd),
   .dout(cart_d),
   .din(ioctl_dout),
   .we(ioctl_wr),
   .ready()
);

reg sg1000 = 0;
reg extram = 0;
always @(posedge clk_sys) begin
	if(ioctl_wr) begin
		if(!ioctl_addr) begin
			extram <= 0;
			sg1000 <= (ioctl_index[4:0] == 2);
		end
		if(ioctl_addr[24:13] == 1 && sg1000) extram <= (!ioctl_addr[12:0] | extram) & &ioctl_dout; // 2000-3FFF on SG-1000
	end
end


////////////////  Console  ////////////////////////

wire [13:0] audio;
assign AUDIO_L = {1'b0,audio,1'b0};
assign AUDIO_R = {1'b0,audio,1'b0};
assign AUDIO_S = 0;
assign AUDIO_MIX = 0;

assign CLK_VIDEO = clk_sys;

wire [1:0] ctrl_p1;
wire [1:0] ctrl_p2;
wire [1:0] ctrl_p3;
wire [1:0] ctrl_p4;
wire [1:0] ctrl_p5;
wire [1:0] ctrl_p6;
wire [1:0] ctrl_p7 = 2'b11;
wire [1:0] ctrl_p8;
wire [1:0] ctrl_p9 = 2'b11;

wire [7:0] R,G,B;
wire hblank, vblank;
wire hsync, vsync;

wire [31:0] joy0_m = joy0[20] ? 32'd0 : joy0;
wire [31:0] joy1_m = joy1[20] ? 32'd0 : joy1;
wire [31:0] joy_ss = (joy0[20] ? joy0 : 32'd0) | (joy1[20] ? joy1 : 32'd0);

wire [31:0] joya = status[3] ? joy1_m : joy0_m;
wire [31:0] joyb = status[3] ? joy0_m : joy1_m;

cv_console console
(
	.clk_i(clk_sys),
	.clk_en_10m7_i(ce_10m7),
	.reset_n_i(~reset),
	.por_n_o(),
	.sg1000(sg1000),
	.dahjeeA_i(extram),

	.ctrl_p1_i(ctrl_p1),
	.ctrl_p2_i(ctrl_p2),
	.ctrl_p3_i(ctrl_p3),
	.ctrl_p4_i(ctrl_p4),
	.ctrl_p5_o(ctrl_p5),
	.ctrl_p6_i(ctrl_p6),
	.ctrl_p7_i(ctrl_p7),
	.ctrl_p8_o(ctrl_p8),
	.ctrl_p9_i(ctrl_p9),
	.joy0_i(~{|joya[19:6], 1'b0, joya[5:0]}),
	.joy1_i(~{|joyb[19:6], 1'b0, joyb[5:0]}),

	.bios_rom_a_o(bios_a),
	.bios_rom_d_i(bios_d),

	.cpu_ram_a_o(cpu_ram_a),
	.cpu_ram_we_n_o(ram_we_n),
	.cpu_ram_ce_n_o(ram_ce_n),
	.cpu_ram_d_i(ram_di),
	.cpu_ram_d_o(ram_do),

	.vram_a_o(vram_a),
	.vram_we_o(vram_we),
	.vram_d_o(vram_do),
	.vram_d_i(vram_di),

	.cart_pages_i(cart_pages),
	.cart_a_o(cart_a),
	.cart_d_i(cart_d),
	.cart_rd(cart_rd),

	.ss_frz_i(ss_frz),
	.ss_wr_i(ss_reg_wr),
	.ss_a_i(sd_buff_addr[7:0]),
	.ss_d_i(sd_buff_dout),
	.ss_d_o(ss_reg_dout),
	.ss_cpuset_i(ss_cpuset),
	.ss_cpu_cen_p_i(ss_cen_p),
	.ss_cpu_cen_n_i(ss_cen_n),
	.ss_bnd_o(ss_bnd),

	.border_i(status[6]),
	.rgb_r_o(R),
	.rgb_g_o(G),
	.rgb_b_o(B),
	.hsync_n_o(hsync),
	.vsync_n_o(vsync),
	.hblank_o(hblank),
	.vblank_o(vblank),

	.audio_o(audio)
);

assign VGA_F1 = 0;
assign VGA_SL = sl[1:0];

wire [2:0] scale = status[9:7];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;

reg hs_o, vs_o;
always @(posedge CLK_VIDEO) begin
	hs_o <= ~hsync;
	if(~hs_o & ~hsync) vs_o <= ~vsync;
end

video_mixer #(.LINE_LENGTH(290), .GAMMA(1)) video_mixer
(
	.*,

	.ce_pix(ce_5m3),
	.freeze_sync(),

	.scandoubler(scale || forced_scandoubler),
	.hq2x(scale==1),

	.VGA_DE(vga_de),
	.R(R),
	.G(G),
	.B(B),

	// Positive pulses.
	.HSync(hs_o),
	.VSync(vs_o),
	.HBlank(hblank),
	.VBlank(vblank)
);

wire        ss_bnd;
wire  [7:0] ss_reg_dout;
wire        ss_frz;
wire        ss_busy;
wire        ss_loading;
wire        ss_reg_wr;
wire        ss_cpuset;
wire        ss_cen_p;
wire        ss_cen_n;
wire        ss_ram_sel;
wire        ss_vram_sel;
wire [14:0] ss_ram_a;
wire [13:0] ss_vram_a;

reg         ss_mounted = 0;
always @(posedge clk_sys) if(img_mounted) ss_mounted <= |img_size;

wire       ss_key_save, ss_key_load, ss_info_req, ss_status_upd;
wire [2:0] ss_slot;
wire [7:0] ss_info;

savestate_keys savestate_keys
(
	.clk(clk_sys),
	.enable(~OSD_STATUS),
	.ps2_key(ps2_key),
	.joy_ss(joy_ss[20]),
	.joy_right(joy_ss[0]),
	.joy_left(joy_ss[1]),
	.joy_down(joy_ss[2]),
	.joy_up(joy_ss[3]),
	.menu_slot(status[14:12]),
	.osd_save(status[15]),
	.osd_load(status[16]),
	.save(ss_key_save),
	.load(ss_key_load),
	.slot(ss_slot),
	.info_req(ss_info_req),
	.info(ss_info),
	.status_update(ss_status_upd)
);

savestate savestate
(
	.clk(clk_sys),
	.reset(reset),

	.save_req(ss_key_save),
	.load_req(ss_key_load),
	.slot(ss_slot),
	.mounted(ss_mounted),
	.readonly(img_readonly),

	.bnd(ss_bnd),
	.frz(ss_frz),
	.cpuset(ss_cpuset),
	.cen_p(ss_cen_p),
	.cen_n(ss_cen_n),
	.busy(ss_busy),
	.loading(ss_loading),

	.rom_sum(rom_sum),
	.rom_len(rom_len),
	.cart_pages(cart_pages),
	.sg1000(sg1000),
	.extram(extram),
	.ram_size(status[5:4]),

	.reg_wr(ss_reg_wr),
	.reg_dout(ss_reg_dout),

	.ram_sel(ss_ram_sel),
	.vram_sel(ss_vram_sel),
	.ram_a(ss_ram_a),
	.vram_a(ss_vram_a),
	.ram_di(ram_di),
	.vram_di(vram_di),

	.sd_lba(sd_lba[0]),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din[0]),
	.sd_buff_wr(sd_buff_wr)
);

assign sd_blk_cnt[0] = 0;

////////////////  Control  ////////////////////////

wire [0:19] keypad0 = {joya[8],joya[9],joya[10],joya[11],joya[12],joya[13],joya[14],joya[15],joya[16],joya[17],joya[6],joya[7],joya[18],joya[19],joya[3],joya[2],joya[1],joya[0],joya[4],joya[5]};
wire [0:19] keypad1 = {joyb[8],joyb[9],joyb[10],joyb[11],joyb[12],joyb[13],joyb[14],joyb[15],joyb[16],joyb[17],joyb[6],joyb[7],joyb[18],joyb[19],joyb[3],joyb[2],joyb[1],joyb[0],joyb[4],joyb[5]};
wire [0:19] keypad[2] = '{keypad0,keypad1};

reg [3:0] ctrl1[2] = '{'0,'0};
assign {ctrl_p1[0],ctrl_p2[0],ctrl_p3[0],ctrl_p4[0]} = ctrl1[0];
assign {ctrl_p1[1],ctrl_p2[1],ctrl_p3[1],ctrl_p4[1]} = ctrl1[1];

localparam cv_key_0_c        = 4'b0011;
localparam cv_key_1_c        = 4'b1110;
localparam cv_key_2_c        = 4'b1101;
localparam cv_key_3_c        = 4'b0110;
localparam cv_key_4_c        = 4'b0001;
localparam cv_key_5_c        = 4'b1001;
localparam cv_key_6_c        = 4'b0111;
localparam cv_key_7_c        = 4'b1100;
localparam cv_key_8_c        = 4'b1000;
localparam cv_key_9_c        = 4'b1011;
localparam cv_key_asterisk_c = 4'b1010;
localparam cv_key_number_c   = 4'b0101;
localparam cv_key_pt_c       = 4'b0100;
localparam cv_key_bt_c       = 4'b0010;
localparam cv_key_none_c     = 4'b1111;

generate 
	genvar i;
	for (i = 0; i <= 1; i++) begin : ctl
		always_comb begin
			reg [3:0] ctl1, ctl2;
			reg p61,p62;
			
			ctl1 = 4'b1111;
			ctl2 = 4'b1111;
			p61 = 1;
			p62 = 1;

			if (~ctrl_p5[i]) begin
				casex(keypad[i][0:13]) 
					'b1xxxxxxxxxxxxx: ctl1 = cv_key_0_c;
					'b01xxxxxxxxxxxx: ctl1 = cv_key_1_c;
					'b001xxxxxxxxxxx: ctl1 = cv_key_2_c;
					'b0001xxxxxxxxxx: ctl1 = cv_key_3_c;
					'b00001xxxxxxxxx: ctl1 = cv_key_4_c;
					'b000001xxxxxxxx: ctl1 = cv_key_5_c;
					'b0000001xxxxxxx: ctl1 = cv_key_6_c;
					'b00000001xxxxxx: ctl1 = cv_key_7_c;
					'b000000001xxxxx: ctl1 = cv_key_8_c;
					'b0000000001xxxx: ctl1 = cv_key_9_c;
					'b00000000001xxx: ctl1 = cv_key_asterisk_c;
					'b000000000001xx: ctl1 = cv_key_number_c;
					'b0000000000001x: ctl1 = cv_key_pt_c;
					'b00000000000001: ctl1 = cv_key_bt_c;
					'b00000000000000: ctl1 = cv_key_none_c;
				endcase
				p61 = ~keypad[i][19]; // button 2
			end

			if (~ctrl_p8[i]) begin
				ctl2 = ~keypad[i][14:17];
				p62 = ~keypad[i][18];  // button 1
			end
			
			ctrl1[i] = ctl1 & ctl2;
			ctrl_p6[i] = p61 & p62;
		end
	end
endgenerate


endmodule
