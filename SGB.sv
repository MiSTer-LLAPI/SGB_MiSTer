//============================================================================
//  SNES for MiSTer
//  Copyright (C) 2017-2019 Srg320
//  Copyright (C) 2018-2019 Sorgelig
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
//LLAPI: llapi.sv needs to be in rtl folder and needs to be declared in file.qip (set_global_assignment -name SYSTEMVERILOG_FILE rtl/llapi.sv)																																			  

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

//`define DEBUG_BUILD

assign ADC_BUS  = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign AUDIO_S   = 1;
assign AUDIO_MIX = status[20:19];

assign LED_USER  = cart_download | gb_cart_download | (status[23] & sav_pending);
assign LED_DISK  = 0;
assign LED_POWER = 0;
//LLAPI: OSD combinaison
assign BUTTONS   = osd_btn | llapi_osd;
//LLAPI	 
assign VGA_SCALER= 0;
assign HDMI_FREEZE = 0;
assign VGA_DISABLE = 0;

assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

wire [2:0] ar       = status[34:32];
wire       vcrop_en = status[39];
wire [3:0] vcopt    = status[38:35];
reg        en216p;
reg  [4:0] voff;
always @(posedge CLK_VIDEO) begin
	en216p <= ((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080) && !forced_scandoubler && !scale);
	voff <= (vcopt < 6) ? {vcopt,1'b0} : ({vcopt,1'b0} - 5'd24);
end

wire vga_de;
video_freak video_freak
(
	.*,
	.VGA_DE_IN(vga_de),
	.ARX((!ar) ? 12'd64 : (ar == 3'd1) ? 12'd8 : (ar - 3'd2)),
	.ARY((!ar) ? 12'd49 : (ar == 3'd1) ? 12'd7 : 12'd0),
	.CROP_SIZE((en216p & vcrop_en) ? 10'd216 : 10'd0),
	.CROP_OFF(voff),
	.SCALE(status[41:40])
);

///////////////////////  CLOCK/RESET  ///////////////////////////////////

wire clock_locked;
wire clk_mem;
wire clk_sys;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_mem),
	.outclk_1(CLK_VIDEO),
	.outclk_2(clk_sys),
	.reconfig_to_pll(reconfig_to_pll),
	.reconfig_from_pll(reconfig_from_pll),
	.locked(clock_locked)
);

wire [63:0] reconfig_to_pll;
wire [63:0] reconfig_from_pll;
wire        cfg_waitrequest;
reg         cfg_write;
reg   [5:0] cfg_address;
reg  [31:0] cfg_data;

pll_cfg pll_cfg
(
	.mgmt_clk(CLK_50M),
	.mgmt_reset(0),
	.mgmt_waitrequest(cfg_waitrequest),
	.mgmt_read(0),
	.mgmt_readdata(),
	.mgmt_write(cfg_write),
	.mgmt_address(cfg_address),
	.mgmt_writedata(cfg_data),
	.reconfig_to_pll(reconfig_to_pll),
	.reconfig_from_pll(reconfig_from_pll)
);

always @(posedge CLK_50M) begin
	reg pald = 0, pald2 = 0;
	reg [2:0] state = 0;

	pald  <= PAL;
	pald2 <= pald;

	cfg_write <= 0;
	if(pald2 != pald) state <= 1;

	if(!cfg_waitrequest) begin
		if(state) state<=state+1'd1;
		case(state)
			1: begin
					cfg_address <= 0;
					cfg_data <= 0;
					cfg_write <= 1;
				end
			3: begin
					cfg_address <= 7;
					cfg_data <= pald2 ? 2201376898 : 2537930535;
					cfg_write <= 1;
				end
			5: begin
					cfg_address <= 2;
					cfg_data <= 0;
					cfg_write <= 1;
				end
		endcase
	end
end

wire reset = RESET | buttons[1] | status[0] | cart_download | gb_cart_download | boot_download | bk_loading | clearing_ram | msu_data_download;

////////////////////////////  HPS I/O  //////////////////////////////////

// Status Bit Map:
//              Upper                          Lower
// 0         1         2         3          4         5         6
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// X  XXXXX XXXXXX  X XX  XXXXXXXXX XXXXXXXXXXXX      XXX

`include "build_id.v"
parameter CONF_STR = {
	"SGB;SS3F800000:100000;",
	//LLAPI Always ON
	"-,>> LLAPI enabled core    <<;",
	"-,>> Connect USER I/O port <<;",		"-;",
	//END LLAPI
	"FS1,GBCGB ;",
	"OPR,GB Mapper,Auto,WisdomTree,Mani161,MBC1,MBC3;",
	"-;",
	"O[50],Save state to SD,Off,On;",
	"O[52:51],Savestate Slot,1,2,3,4;",
	"d6RU,Save state (Alt-F1);",
	"d6RV,Load state (F1);",
	"-;",
	"FC4,SFC,Load SGB BIOS;",
	"O[29:28],SGB Speed,SGB1,SGB2,SNES;",
	"OE,Video Region,NTSC,PAL;",
	"-;",
	"C,Cheats;",
	"H2OO,Cheats Enabled,Yes,No;",
	"-;",
	"D0RC,Load Backup RAM;",
	"D0RD,Save Backup RAM;",
	"D0ON,Autosave,Off,On;",
	"D0-;",

	"P1,Audio & Video;",
	"P1-;",
	"P1o02,Aspect ratio,Original,Original GB,Full Screen,[ARC1],[ARC2];",
	"P1O9B,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"P1-;",
	"d5P1o7,Vertical Crop,Disabled,216p(5x);",
	"d5P1o36,Crop Offset,0,2,4,8,10,12,-12,-10,-8,-6,-4,-2;",
	"P1o89,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"P1oA,Force 256px,Off,On;",
	"P1-;",
	"P1O[43],GB Audio mode,Accurate,No Pops;",
	"P1OJK,Stereo Mix,None,25%,50%,100%;", 

	"P2,Hardware;",
	"P2-;",
	"P2FC5,BIN,Load SGB Boot;",
	"P2-;",
	"P2OH,Multitap,Disabled,Port2;",
	//LLAPI : Disable SNAC
	//"P2O34,Serial,OFF,SNAC SNES,SNAC GB;",
	//END LLAPI
	"P2-;",

	"-;",
	"O56,Mouse,None,Port1,Port2;",
	"O7,Swap Joysticks,No,Yes;",
	"-;",
	"R0,Reset;",
	"J1,A,B,X,Y,L,R,Select,Start,SaveState;",
	"I,",
	"Slot=DPAD|Save/Load=Pause+DPAD,",
	"Active Slot 1,",
	"Active Slot 2,",
	"Active Slot 3,",
	"Active Slot 4,",
	"Save to state 1,",
	"Restore state 1,",
	"Save to state 2,",
	"Restore state 2,",
	"Save to state 3,",
	"Restore state 3,",
	"Save to state 4,",
	"Restore state 4,",
	"V,v",`BUILD_DATE
};

wire  [1:0] buttons;
wire [63:0] status;
wire [15:0] status_menumask = {ss_allow, en216p, 1'b1, 1'b1, ~gg_available, 1'b1, ~sav_supported };
wire        forced_scandoubler;
reg  [31:0] sd_lba;
reg         sd_rd = 0;
reg         sd_wr = 0;
wire        sd_ack;
wire  [7:0] sd_buff_addr;
wire [15:0] sd_buff_dout;
wire [15:0] sd_buff_din;
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;
wire        ioctl_download;
wire [24:0] ioctl_addr;
wire [15:0] ioctl_dout;
wire        ioctl_wr;
wire  [7:0] ioctl_index;

//LLAPI: Distinguish hps_io (usb) josticks from llapi joysticks
wire [12:0] joy_usb_0, joy_usb_1, joy_usb_2, joy_usb_3, joy_usb_4;		
wire [12:0] joy0,joy1,joy2,joy3,joy4;
//END LLAPI	

wire [24:0] ps2_mouse;
wire [10:0] ps2_key;

wire [32:0] RTC_time;

wire [21:0] gamma_bus;

hps_io #(.CONF_STR(CONF_STR), .WIDE(1)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),
	.new_vmode(new_vmode),
	//LLAPI : renamed hps_io (usb) joysticks for mixn match
	//.joystick_0(joy0),
	//.joystick_1(joy1),
	//.joystick_2(joy2),
	//.joystick_3(joy3),
	//.joystick_4(joy4),
	.joystick_0(joy_usb_0),
	.joystick_1(joy_usb_1),
	.joystick_2(joy_usb_2),
	.joystick_3(joy_usb_3),
	.joystick_4(joy_usb_4),
	//END LLAPI
	.ps2_mouse(ps2_mouse),
	.ps2_key(ps2_key),

	.status(status),
	.status_menumask(status_menumask),
	.status_in({status[63:49], ss_slot, status[46:0]}),
	.status_set(ss_status),

	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wr(ioctl_wr),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),

	.sd_lba('{sd_lba}),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din('{sd_buff_din}),
	.sd_buff_wr(sd_buff_wr),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.TIMESTAMP(RTC_time),

	.gamma_bus(gamma_bus),
	.EXT_BUS(EXT_BUS)
);

wire [1:0] mouse_mode = status[6:5];
wire       joy_swap = status[7];
wire [1:0] sgb_speed = status[29:28];
wire       PAL = status[14];
wire [2:0] gb_mapper = status[27:25];

wire code_index = &ioctl_index;
wire code_download = ioctl_download & code_index;
wire cart_download = ioctl_download & ioctl_index[5:0] == 6'h04;
wire boot_download = ioctl_download & ioctl_index[5:0] == 6'h05;
wire gb_cart_download = ioctl_download & (ioctl_index[5:0] == 6'h01 || ioctl_index == 8'h00);
wire spc_download = 0;

reg is_sgb2_bios;
always @(posedge clk_sys) begin
	if (cart_download) is_sgb2_bios <= ioctl_addr[18];
end

reg new_vmode;
always @(posedge clk_sys) begin
	reg old_pal;
	int to;

	if(~reset) begin
		old_pal <= PAL;
		if(old_pal != PAL) to <= 2000000;
	end

	if(to) begin
		to <= to - 1;
		if(to == 1) new_vmode <= ~new_vmode;
	end
end


reg osd_btn = 0;
always @(posedge clk_sys) begin
	integer timeout = 0;
	reg     has_bootrom = 0;
	reg     last_rst = 0;

	if (RESET) last_rst <= 0;
	if (status[0]) last_rst <= 1;

	if (gb_cart_download & ioctl_wr & status[0]) has_bootrom <= 1;

	if(last_rst & ~status[0]) begin
		osd_btn <= 0;
		if(timeout < 24000000) begin
			timeout <= timeout + 1;
			osd_btn <= ~has_bootrom;
		end
	end
end

////////////////////////////  SYSTEM  ///////////////////////////////////

wire ss_avail;
wire ss_ddr_ack, ss_ddr_req, ss_ddr_we;
wire [63:0] ss_ddr_dout, ss_ddr_din;
wire [21:3] ss_ddr_addr;
wire [ 7:0] ss_ddr_be;

wire [15:0] MAIN_AUDIO_L, MAIN_AUDIO_R;
wire [15:0] GB_AUDIO_L, GB_AUDIO_R;
wire AUDIO_MUTE;

main main
(
	.RESET_N(RESET_N),

	.MCLK(clk_sys), // 21.47727 / 21.28137
	.ACLK(clk_sys),

	.ROM_MASK({is_sgb2_bios,~18'd0} ),
	.PAL(PAL),
	.BLEND(0),

	.ROM_ADDR(ROM_ADDR),
	.ROM_D(ROM_D),
	.ROM_Q(ROM_Q),
	.ROM_OE_N(ROM_OE_N),
	.ROM_WE_N(ROM_WE_N),
	.ROM_WORD(ROM_WORD),

	.WRAM_ADDR(WRAM_ADDR),
	.WRAM_D(WRAM_D),
	.WRAM_Q(WRAM_Q),
	.WRAM_CE_N(WRAM_CE_N),
	.WRAM_WE_N(WRAM_WE_N),

	.VRAM1_ADDR(VRAM1_ADDR),
	.VRAM1_DI(VRAM1_Q),
	.VRAM1_DO(VRAM1_D),
	.VRAM1_WE_N(VRAM1_WE_N),

	.VRAM2_ADDR(VRAM2_ADDR),
	.VRAM2_DI(VRAM2_Q),
	.VRAM2_DO(VRAM2_D),
	.VRAM2_WE_N(VRAM2_WE_N),

	.ARAM_ADDR(ARAM_ADDR),
	.ARAM_D(ARAM_D),
	.ARAM_Q(ARAM_Q),
	.ARAM_CE_N(ARAM_CE_N),
	.ARAM_WE_N(ARAM_WE_N),

	.R(R_out),
	.G(G_out),
	.B(B_out),

	.FIELD(FIELD),
	.INTERLACE(INTERLACE),
	.HIGH_RES(HIGH_RES),
	.DOTCLK(DOTCLK_out),
	
	.HBLANKn(HBlank_out),
	.VBLANKn(VBlank_out),
	.HSYNC(HSYNC_out),
	.VSYNC(VSYNC_out),

	.JOY1_DI(JOY1_DI),
	.JOY2_DI(JOY2_DI),
	.JOY_STRB(JOY_STRB),
	.JOY1_CLK(JOY1_CLK),
	.JOY2_CLK(JOY2_CLK),
	.JOY1_P6(JOY1_P6),
	.JOY2_P6(JOY2_P6),
	.JOY2_P6_in(JOY2_P6_DI),
	
	.GG_EN(~status[24]),
	.GG_CODE(gg_code),
	.GG_RESET((code_download && ioctl_wr && !ioctl_addr) || gb_cart_download),
	.GG_AVAILABLE(gg_available),
	
	.SPC_MODE(0),

	.IO_ADDR(ioctl_addr),
	.IO_DAT(ioctl_dout),
	.IO_WR(ioctl_wr),
	.IO_GB_CART(gb_cart_download),
	.IO_SGB_BOOT(boot_download),

	.TURBO(0),

	.GB_ROM_ADDR(GB_ROM_ADDR),
	.GB_ROM_RD(GB_ROM_RD),
	.GB_ROM_DI(GB_ROM_Q),

	.GB_CRAM_WR(cram_wr),

	.GB_BK_WR(bk_wr),
	.GB_RTC_WR(bk_rtc_wr),
	.GB_BK_ADDR(bk_addr),
	.GB_BK_DATA(bk_data),
	.GB_BK_Q(bk_q),
	.GB_BK_IMG_SIZE(img_size),

	.GB_RAM_MASK(ram_mask_file),
	.GB_HAS_SAVE(cart_has_save),

	.GB_RTC_TIME_IN(RTC_time),
	.GB_RTC_TIMEOUT(RTC_timestampOut),
	.GB_RTC_SAVEDTIME(RTC_savedtimeOut),
	.GB_RTC_INUSE(RTC_inuse),

	.GB_MAPPER(gb_mapper),
	.SGB_SPEED(sgb_speed),

	.GB_AUDIO_NO_POPS(status[43]),
	.GB_AUDIO_L(GB_AUDIO_L),
	.GB_AUDIO_R(GB_AUDIO_R),

	.GB_SC_INT_CLOCK(gb_sc_int_clock),
	.GB_SER_CLK_IN(gb_ser_clk_in),
	.GB_SER_DATA_IN(gb_ser_data_in),
	.GB_SER_CLK_OUT(gb_ser_clk_out),
	.GB_SER_DATA_OUT(gb_ser_data_out),

`ifdef DEBUG_BUILD
	.DBG_BG_EN(DBG_BG_EN),
	.DBG_CPU_EN(DBG_CPU_EN),
`else
	.DBG_BG_EN(5'b11111),
	.DBG_CPU_EN(1'b1),
`endif

	// MSU register handling
	.MSU_TRACK_NUM(msu_track_num),
	.MSU_TRACK_REQUEST(msu_track_request),
	.MSU_TRACK_MOUNTING(msu_track_mounting),
	.MSU_TRACK_MISSING(msu_track_missing),
	.MSU_VOLUME(msu_volume),
	.MSU_AUDIO_REPEAT(msu_audio_repeat),
	.MSU_AUDIO_STOP(msu_audio_stop),
	.MSU_AUDIO_PLAYING(msu_audio_playing),
	.MSU_DATA_ADDR(msu_data_addr),
	.MSU_DATA(msu_data),
	.MSU_DATA_ACK(msu_data_ack),
	.MSU_DATA_SEEK(msu_data_seek),
	.MSU_DATA_REQ(msu_data_req),
	.MSU_ENABLE(msu_enable),

	.SS_SAVE(ss_save),
	.SS_TOSD(status[50]),
	.SS_LOAD(ss_load),
	.SS_SLOT(ss_slot),
	.SS_AVAIL(ss_avail),

	.SS_DDR_DI(ss_ddr_dout),
	.SS_DDR_ACK(ss_ddr_ack),
	.SS_DDR_DO(ss_ddr_din),
	.SS_DDR_ADDR(ss_ddr_addr),
	.SS_DDR_WE(ss_ddr_we),
	.SS_DDR_BE(ss_ddr_be),
	.SS_DDR_REQ(ss_ddr_req),

	.CH_EN(8'hFF),
	.AUDIO_MUTE(AUDIO_MUTE),
	.AUDIO_L(MAIN_AUDIO_L),
	.AUDIO_R(MAIN_AUDIO_R)
);

// Mix GB audio with Main audio.
wire [16:0] MAIN_GB_MIX_L = $signed(MAIN_AUDIO_L) + $signed({ GB_AUDIO_L[15],GB_AUDIO_L[13:0],1'b0 });
wire [16:0] MAIN_GB_MIX_R = $signed(MAIN_AUDIO_R) + $signed({ GB_AUDIO_R[15],GB_AUDIO_R[13:0],1'b0 });

// Mix msu_audio into main mix
wire [16:0] AUDIO_MIX_L = $signed(MAIN_GB_MIX_L[16:1]) + $signed(msu_audio_l[15:1]);
wire [16:0] AUDIO_MIX_R = $signed(MAIN_GB_MIX_R[16:1]) + $signed(msu_audio_r[15:1]);

assign AUDIO_L = AUDIO_MUTE ? 16'd0 : msu_enable ? AUDIO_MIX_L[16:1] : MAIN_GB_MIX_L[16:1];
assign AUDIO_R = AUDIO_MUTE ? 16'd0 : msu_enable ? AUDIO_MIX_R[16:1] : MAIN_GB_MIX_R[16:1];

reg RESET_N = 0;
reg RFSH = 0;
always @(posedge clk_sys) begin
	reg [1:0] div;
	
	div <= div + 1'd1;
	RFSH <= !div;
	
	if (div == 2) RESET_N <= ~reset;
end

////////////////////////////  CODES  ///////////////////////////////////

reg [128:0] gg_code;
wire gg_available;

// Code layout:
// {clock bit, code flags,     32'b address, 32'b compare, 32'b replace}
//  128        127:96          95:64         63:32         31:0
// Integer values are in BIG endian byte order, so it up to the loader
// or generator of the code to re-arrange them correctly.

always_ff @(posedge clk_sys) begin
	gg_code[128] <= 0;

	if (code_download & ioctl_wr) begin
		case (ioctl_addr[3:0])
			0:  gg_code[111:96]  <= ioctl_dout; // Flags Bottom Word
			2:  gg_code[127:112] <= ioctl_dout; // Flags Top Word
			4:  gg_code[79:64]   <= ioctl_dout; // Address Bottom Word
			6:  gg_code[95:80]   <= ioctl_dout; // Address Top Word
			8:  gg_code[47:32]   <= ioctl_dout; // Compare Bottom Word
			10: gg_code[63:48]   <= ioctl_dout; // Compare top Word
			12: gg_code[15:0]    <= ioctl_dout; // Replace Bottom Word
			14: begin
				gg_code[31:16]    <= ioctl_dout; // Replace Top Word
				gg_code[128]      <= 1;          // Clock it in
			end
		endcase
	end
end

////////////////////////////  MEMORY  ///////////////////////////////////

reg [16:0] mem_fill_addr;
reg clearing_ram = 0;
reg old_cart_download = 0;
always @(posedge clk_sys) begin
	old_cart_download <= cart_download;
	if(~old_cart_download & cart_download)
		clearing_ram <= 1'b1;

	if (&mem_fill_addr) clearing_ram <= 0;

	if (clearing_ram)
		mem_fill_addr <= mem_fill_addr + 1'b1;
	else
		mem_fill_addr <= 0;
end

reg [7:0] wram_fill_data;
always @* begin
    //case(status[22:21])
    case(2'b00)
        0: wram_fill_data = (mem_fill_addr[8] ^ mem_fill_addr[2]) ? 8'h66 : 8'h99;
        1: wram_fill_data = (mem_fill_addr[9] ^ mem_fill_addr[0]) ? 8'hFF : 8'h00;
        2: wram_fill_data = 8'h55;
        3: wram_fill_data = 8'hFF;
    endcase
end

wire[23:0] ROM_ADDR;
wire       ROM_OE_N;
wire       ROM_WE_N;
wire       ROM_WORD;
wire[15:0] ROM_D;
wire[15:0] ROM_Q;

wire [22:0] GB_ROM_ADDR;
wire        GB_ROM_RD;
wire [ 7:0] GB_ROM_Q;

localparam GB_BANK = 2'b10;

wire[24:0] addr_download =
            gb_cart_download ? { GB_BANK, ioctl_addr[22:0] } : // 8MB GameBoy
            { 6'd0,ioctl_addr[18:0] }; // 512KB SGB

wire       sdram_download = cart_download | gb_cart_download;

sdram sdram
(
	.*,

	// system interface
	.clk        ( clk_mem           ),
	.init       (0), //~clock_locked),

	// SNES
	.ch0_addr   ( sdram_download ? addr_download : ROM_ADDR  ),
	.ch0_wr     ( sdram_download ? ioctl_wr : ~ROM_WE_N ),
	.ch0_din    ( sdram_download ? ioctl_dout : ROM_D  ),
	.ch0_rd     ( ~sdram_download & (RESET_N ? ~ROM_OE_N : RFSH) ),
	.ch0_dout   ( ROM_Q   ),
	.ch0_word   ( sdram_download | ROM_WORD ),
	.ch0_busy   ( ),

	// GameBoy
	.ch1_addr   ( { GB_BANK,GB_ROM_ADDR } ),
	.ch1_wr     ( 0 ),
	.ch1_din    ( 0  ),
	.ch1_rd     ( GB_ROM_RD  ),
	.ch1_dout   ( GB_ROM_Q   ),
	.ch1_busy   ( ),

	.ch2_addr   ( 0 ),
	.ch2_wr     ( 0 ),
	.ch2_din    ( 0 ),
	.ch2_rd     ( 0 ),
	.ch2_dout   (   ),
	.ch2_busy   (   ),

	.refresh    (  )
);

wire[16:0] WRAM_ADDR;
wire       WRAM_CE_N;
wire       WRAM_WE_N;
wire [7:0] WRAM_Q, WRAM_D;
dpram #(17)	wram
(
	.clock(clk_sys),
	.address_a(WRAM_ADDR),
	.data_a(WRAM_D),
	.wren_a(~WRAM_CE_N & ~WRAM_WE_N),
	.q_a(WRAM_Q),

	// clear the RAM on loading
	.address_b(mem_fill_addr[16:0]),
	.data_b(wram_fill_data),
	.wren_b(clearing_ram)
);

wire [15:0] VRAM1_ADDR;
wire        VRAM1_WE_N;
wire  [7:0] VRAM1_D, VRAM1_Q;
dpram #(15)	vram1
(
	.clock(clk_sys),
	.address_a(VRAM1_ADDR[14:0]),
	.data_a(VRAM1_D),
	.wren_a(~VRAM1_WE_N),
	.q_a(VRAM1_Q),

	// clear the RAM on loading
	.address_b(mem_fill_addr[14:0]),
	.wren_b(clearing_ram)
);

wire [15:0] VRAM2_ADDR;
wire        VRAM2_WE_N;
wire  [7:0] VRAM2_D, VRAM2_Q;
dpram #(15) vram2
(
	.clock(clk_sys),
	.address_a(VRAM2_ADDR[14:0]),
	.data_a(VRAM2_D),
	.wren_a(~VRAM2_WE_N),
	.q_a(VRAM2_Q),

	// clear the RAM on loading
	.address_b(mem_fill_addr[14:0]),
	.wren_b(clearing_ram)
);

wire [15:0] ARAM_ADDR;
wire        ARAM_CE_N;
wire        ARAM_WE_N;
wire  [7:0] ARAM_Q, ARAM_D;
dpram_dif #(16,8,15,16) aram
(
	.clock(clk_sys),
	.address_a(ARAM_ADDR),
	.data_a(ARAM_D),
	.wren_a(~ARAM_CE_N & ~ARAM_WE_N),
	.q_A(ARAM_Q),

	// clear the RAM on loading
	.address_b(spc_download ? addr_download[15:1] : mem_fill_addr[15:1]),
	.data_b(spc_download ? ioctl_dout : 16'h0000),
	.wren_b(spc_download ? ioctl_wr : clearing_ram)
);

////////////////////////////  VIDEO  ////////////////////////////////////

wire [7:0] R_out,G_out,B_out;
wire HSYNC_out;
wire VSYNC_out;
wire HBlank_out;
wire VBlank_out;
wire DOTCLK_out;

always @(posedge clk_sys) begin
	DOTCLK <= DOTCLK_out;
	if(DOTCLK ^ DOTCLK_out) begin
		R <= R_out;
		G <= G_out;
		B <= B_out;
		HSYNC  <= HSYNC_out;
		VSYNC  <= VSYNC_out;
		HBlank <= ~HBlank_out;
		VBlank <= ~VBlank_out;
	end
end

reg  [7:0] R,G,B;
wire FIELD,INTERLACE;
reg  HSync, HSYNC;
reg  VSync, VSYNC;
reg  HBlank;
reg  VBlank;
wire HIGH_RES;
reg  DOTCLK;

reg interlace;
reg ce_pix;
always @(posedge CLK_VIDEO) begin
	reg [2:0] pcnt;
	reg old_vsync;
	reg tmp_hres, frame_hres;
	reg old_dotclk;
	
	if(~HBlank & ~VBlank) tmp_hres <= tmp_hres | HIGH_RES;

	old_vsync <= VSync;
	if(~old_vsync & VSync) begin
		frame_hres <= (tmp_hres | ~scandoubler) & ~status[42];
		tmp_hres <= 0;
		interlace <= INTERLACE;
	end

	pcnt <= pcnt + 1'd1;
	old_dotclk <= DOTCLK;
	if(~old_dotclk & DOTCLK & ~HBlank & ~VBlank) pcnt <= 1;

	ce_pix <= !pcnt[1:0] & (frame_hres | ~pcnt[2]);
	
	if(pcnt==3) {HSync, VSync} <= {HSYNC, VSYNC};
end

assign VGA_F1 = interlace & FIELD;
assign VGA_SL = {~interlace,~interlace}&sl[1:0];

wire [2:0] scale = status[11:9];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;
wire       scandoubler = ~interlace && (scale || forced_scandoubler);

video_mixer #(.LINE_LENGTH(520), .GAMMA(1)) video_mixer
(
	.*,
	.hq2x(scale==1),
	.freeze_sync(),
	.VGA_DE(vga_de),
	.R(R),
	.G(G),
	.B(B)
);

////////////////////////////  I/O PORTS  ////////////////////////////////

wire       JOY_STRB;

wire [1:0] JOY1_DO;
wire       JOY1_CLK;
wire       JOY1_P6;
ioport port1
(
	.CLK(clk_sys),

	.PORT_LATCH(JOY_STRB),
	.PORT_CLK(JOY1_CLK),
	.PORT_P6(JOY1_P6),
	.PORT_DO(JOY1_DO),
//LLAPI: Disable SNAC
	.JOYSTICK1((joy_swap) ? joy1 : joy0),
//END LLAPI
	.MOUSE(ps2_mouse),
	.MOUSE_EN(mouse_mode[0])
);

wire [1:0] JOY2_DO;
wire       JOY2_CLK;
wire       JOY2_P6;
ioport port2
(
	.CLK(clk_sys),

	.MULTITAP(status[17]),

	.PORT_LATCH(JOY_STRB),
	.PORT_CLK(JOY2_CLK),
	.PORT_P6(JOY2_P6),
	.PORT_DO(JOY2_DO),
//LLAPI: Disable SNAC
	.JOYSTICK1((joy_swap) ? joy0 : joy1),
//LLAPI: Disable SNAC
	.JOYSTICK2(joy2),
	.JOYSTICK3(joy3),
	.JOYSTICK4(joy4),

	.MOUSE(ps2_mouse),
	.MOUSE_EN(mouse_mode[1])
);


// Indexes:
// 0 = D+    = Latch
// 1 = D-    = CLK
// 2 = TX-   = P5
// 3 = GND_d
// 4 = RX+   = P6
// 5 = RX-   = P4

//LLAPI : Disable SNAC
wire gb_sc_int_clock;
wire gb_ser_data_in = 1'b1;
wire gb_ser_data_out;
wire gb_ser_clk_in = 1'b1;
wire gb_ser_clk_out;

wire snac_snes = status[3];
wire snac_gb   = status[4];

//assign USER_OUT[2] = 1'b1;
//assign USER_OUT[3] = 1'b1;
//assign USER_OUT[5] = 1'b1;
//assign USER_OUT[6] = 1'b1;
//END LLAPI

// JOYX_DO[0] is P4, JOYX_DO[1] is P5
wire [1:0] JOY1_DI = JOY1_DO;
wire [1:0] JOY2_DI = JOY2_DO;
wire JOY2_P6_DI = 1'b1;

/*
always_comb begin
	gb_ser_data_in = 1'b1;
	gb_ser_clk_in = 1'b1;
	USER_OUT[0] = 1'b1;
	USER_OUT[1] = 1'b1;
	USER_OUT[4] = 1'b1;
	JOY1_DI = JOY1_DO;
	JOY2_DI = JOY2_DO;
	JOY2_P6_DI = 1'b1;
	if (snac_snes) begin
		USER_OUT[0] = JOY_STRB;
		USER_OUT[1] = joy_swap ? ~JOY2_CLK : ~JOY1_CLK;
		USER_OUT[4] = joy_swap ? JOY2_P6 : JOY1_P6;
		JOY1_DI = joy_swap ? JOY1_DO : {USER_IN[2], USER_IN[5]};
		JOY2_DI = joy_swap ? {USER_IN[2], USER_IN[5]} : JOY2_DO;
		JOY2_P6_DI = USER_IN[4];
	end
	if (snac_gb) begin
		if (gb_sc_int_clock) USER_OUT[0] = gb_ser_clk_out;
		USER_OUT[1] = gb_ser_data_out;
		gb_ser_data_in = USER_IN[2];
		gb_ser_clk_in = USER_IN[0];
	end
end
*/
//END LLAPI

//////////////////   LLAPI   ///////////////////

wire [31:0] llapi_buttons, llapi_buttons2;
wire [71:0] llapi_analog, llapi_analog2;
wire [7:0]  llapi_type, llapi_type2;
wire llapi_en, llapi_en2;
wire llapi_latch_o, llapi_latch_o2, llapi_data_o, llapi_data_o2;
wire [12:0] joy_ll_a;
wire [12:0] joy_ll_b;

//Assign (DOWN + START + FIRST BUTTON) Combinaison to bring the OSD up - P1 and P2 ports.
wire llapi_osd = (llapi_buttons[26] & llapi_buttons[5] & llapi_buttons[0]) || (llapi_buttons2[26] & llapi_buttons2[5] & llapi_buttons2[0]);

// LLAPI Indexes:
// 0 = D+    = P1 Latch
// 1 = D-    = P1 Data
// 2 = TX-   = LLAPI Enable
// 3 = GND_d = N/C
// 4 = RX+   = P2 Latch
// 5 = RX-   = P2 Data

always_comb begin
		USER_OUT[0] = llapi_latch_o;
		USER_OUT[1] = llapi_data_o;
		USER_OUT[2] = OSD_STATUS; // Blister LED
		USER_OUT[4] = llapi_latch_o2;
		USER_OUT[5] = llapi_data_o2;
end

//Port 1 conf
LLAPI llapi
(
	.CLK_50M(CLK_50M),
	.LLAPI_SYNC(vblank),
	.IO_LATCH_IN(USER_IN[0]),
	.IO_LATCH_OUT(llapi_latch_o),
	.IO_DATA_IN(USER_IN[1]),
	.IO_DATA_OUT(llapi_data_o),
	.ENABLE(~OSD_STATUS),
	.LLAPI_BUTTONS(llapi_buttons),
	.LLAPI_ANALOG(llapi_analog),
	.LLAPI_TYPE(llapi_type),
	.LLAPI_EN(llapi_en)
);

//Port 2 conf
LLAPI llapi2
(
	.CLK_50M(CLK_50M),
	.LLAPI_SYNC(vblank),
	.IO_LATCH_IN(USER_IN[4]),
	.IO_LATCH_OUT(llapi_latch_o2),
	.IO_DATA_IN(USER_IN[5]),
	.IO_DATA_OUT(llapi_data_o2),
	.ENABLE(~OSD_STATUS),
	.LLAPI_BUTTONS(llapi_buttons2),
	.LLAPI_ANALOG(llapi_analog2),
	.LLAPI_TYPE(llapi_type2),
	.LLAPI_EN(llapi_en2)
);

// controller id is 0 if there is either an Atari controller or no controller
// if id is 0, assume there is no controller
// also check for 255 ('Searching mode') and treat that as 'no controller' as well
wire use_llapi  = llapi_en && ((|llapi_type  && ~(&llapi_type))); //  || llapi_button_pressed);
wire use_llapi2 = llapi_en2 && ((|llapi_type2 && ~(&llapi_type2))); // || llapi_button_pressed2);

//Controller string provided by core for reference (order is important)
//Controller specific mapping based on type. More info here : https://docs.google.com/document/d/12XpxrmKYx_jgfEPyw-O2zex1kTQZZ-NSBdLO2RQPRzM/edit
//llapi_Buttons id are HID id - 1

//Port 1 mapping

always_comb begin
	// map for saturn controller
	// use L and R instead of top face buttons
	// no select button so use Z
	if (llapi_type == 3 || llapi_type == 8) begin
		joy_ll_a = {
			1'd0, llapi_buttons[5], llapi_buttons[6], // Start Select
			llapi_buttons[9] | llapi_buttons[7], llapi_buttons[8], // RT LT
			llapi_buttons[2], llapi_buttons[3], llapi_buttons[0], llapi_buttons[1], // Y X B A
			llapi_buttons[27], llapi_buttons[26], llapi_buttons[25], llapi_buttons[24] // d-pad
		};
	end else begin
		joy_ll_a = {
			1'd0, llapi_buttons[5], llapi_buttons[4], // Start Select
			llapi_buttons[7], llapi_buttons[6], // RT LT
			llapi_buttons[2], llapi_buttons[3], llapi_buttons[0], llapi_buttons[1], // Y X B A
			llapi_buttons[27], llapi_buttons[26], llapi_buttons[25], llapi_buttons[24] // d-pad
		};
	end
end

//Port 2 mapping

always_comb begin
	// map for saturn controller
	// use L and R instead of top face buttons
	// no select button so use Z
	if (llapi_type2 == 3 || llapi_type2 == 8) begin
		joy_ll_b = {
			1'd0, llapi_buttons2[5],  llapi_buttons2[6], // Start Select
			llapi_buttons2[9] | llapi_buttons2[7],  llapi_buttons2[8], // RT LT
			llapi_buttons2[2],  llapi_buttons2[3],  llapi_buttons2[0],  llapi_buttons2[1], // Y X B A
			llapi_buttons2[27], llapi_buttons2[26], llapi_buttons2[25], llapi_buttons2[24] // d-pad
		};
	end else begin
		joy_ll_b = {
			1'd0, llapi_buttons2[5],  llapi_buttons2[4], // Start Select
			llapi_buttons2[7],  llapi_buttons2[6], // RT LT
			llapi_buttons2[2],  llapi_buttons2[3],  llapi_buttons2[0],  llapi_buttons2[1], // Y X B A
			llapi_buttons2[27], llapi_buttons2[26], llapi_buttons2[25], llapi_buttons2[24] // d-pad
		};
	end
end

// Player / LLAPI port allocation
always_comb begin
        if (~use_llapi & use_llapi2)  begin
               	joy0 = joy_ll_b;
                joy1 = joy_usb_0;
                joy2 = joy_usb_1;
                joy3 = joy_usb_2;
                joy4 = joy_usb_3;
        end else begin
                joy0 = joy_ll_a;
                joy1 = joy_ll_b;
                joy2 = joy_usb_0;
                joy3 = joy_usb_1;
                joy4 = joy_usb_2;
		end
end


/////////////////////////  GB SAVE/LOAD  /////////////////////////////
wire [7:0] ram_mask_file;
wire cart_has_save;
wire [31:0] RTC_timestampOut;
wire [47:0] RTC_savedtimeOut;
wire RTC_inuse;
wire cram_wr;

wire [16:0] bk_addr = {sd_lba[7:0],sd_buff_addr};
wire bk_wr = (sd_lba[7:0] > ram_mask_file) ? 1'b0 : sd_buff_wr & sd_ack; // only restore data amount of saveram, don't save on RTC data
wire bk_rtc_wr = (sd_lba[7:0] > ram_mask_file) & sd_buff_wr & sd_ack;
wire [15:0] bk_data = sd_buff_dout;
wire [15:0] bk_q;
assign sd_buff_din = (sd_lba[7:0] <= ram_mask_file) ? bk_q :  // normal saveram data or RTC data
					 (sd_buff_addr == 8'd0) ? RTC_timestampOut[15:0]  :
					 (sd_buff_addr == 8'd1) ? RTC_timestampOut[31:16] :
					 (sd_buff_addr == 8'd2) ? RTC_savedtimeOut[15:0]  :
					 (sd_buff_addr == 8'd3) ? RTC_savedtimeOut[31:16] :
					 (sd_buff_addr == 8'd4) ? RTC_savedtimeOut[47:32] :
					 16'hFFFF;


wire downloading = gb_cart_download;

reg  bk_ena          = 0;
reg  new_load        = 0;
reg  old_downloading = 0;
reg  sav_pending     = 0;
reg  cart_ready      = 0;
wire sav_supported   = cart_has_save && bk_ena;

always @(posedge clk_sys) begin
	old_downloading <= downloading;
	if(~old_downloading & downloading) bk_ena <= 0;

	if(old_downloading & ~downloading) cart_ready <= 1;

	//Save file always mounted in the end of downloading state.
	if(downloading && img_mounted && !img_readonly) bk_ena <= 1;

	if (old_downloading & ~downloading & sav_supported)
		new_load <= 1'b1;
	else if (bk_state)
		new_load <= 1'b0;

	if (cram_wr & ~OSD_STATUS & sav_supported)
		sav_pending <= 1'b1;
	else if (bk_state | ~bk_ena)
		sav_pending <= 1'b0;
end

wire bk_load    = status[12] | new_load;
wire bk_save    = status[13] | (sav_pending & OSD_STATUS & status[23]);
reg  bk_loading = 0;
reg  bk_state   = 0;


always @(posedge clk_sys) begin
	reg old_load = 0, old_save = 0, old_ack;

	old_load <= bk_load;
	old_save <= bk_save;
	old_ack  <= sd_ack;

	if(~old_ack & sd_ack) {sd_rd, sd_wr} <= 0;

	if(!bk_state) begin
		if(bk_ena & ((~old_load & bk_load) | (~old_save & bk_save))) begin
			bk_state <= 1;
			bk_loading <= bk_load;
			sd_lba <= 32'd0;
			sd_rd <=  bk_load;
			sd_wr <= ~bk_load;
		end
		if(old_downloading & ~downloading & |img_size & bk_ena) begin
			bk_state <= 1;
			bk_loading <= 1;
			sd_lba <= 0;
			sd_rd <= 1;
			sd_wr <= 0;
		end
	end else begin
		if(old_ack & ~sd_ack) begin

			if (RTC_inuse && sd_lba[7:0]>ram_mask_file) begin // save/load one block more when game/savefile uses RTC, only first 8 bytes used
				bk_loading <= 0;
				bk_state <= 0;
			end else if(!RTC_inuse && sd_lba[7:0]>=ram_mask_file) begin
				bk_loading <= 0;
				bk_state <= 0;
			end else begin
				sd_lba <= sd_lba + 1'd1;
				sd_rd  <=  bk_loading;
				sd_wr  <= ~bk_loading;
			end
		end
	end
end


//debug
`ifdef DEBUG_BUILD
reg [4:0] DBG_BG_EN = '1;
reg       DBG_CPU_EN = 1;

wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];

always @(posedge clk_sys) begin
	reg old_state = 0;

	old_state <= ps2_key[10];

	if((ps2_key[10] != old_state) && pressed) begin
		casex(code)
			'h005: begin DBG_BG_EN[0] <= ~DBG_BG_EN[0]; end // F1
			'h006: begin DBG_BG_EN[1] <= ~DBG_BG_EN[1]; end // F2
			'h004: begin DBG_BG_EN[2] <= ~DBG_BG_EN[2]; end // F3
			'h00C: begin DBG_BG_EN[3] <= ~DBG_BG_EN[3]; end // F4
			'h003: begin DBG_BG_EN[4] <= ~DBG_BG_EN[4]; end // F5
			'h177: begin DBG_CPU_EN   <= ~DBG_CPU_EN;   end // Pause
		endcase
	end
end
`endif

///////////////////////////  MSU1  ///////////////////////////////////

wire msu_enable;
wire msu_audio_download = ioctl_download & ioctl_index[5:0] == 6'h02;
wire msu_data_download  = ioctl_download & ioctl_index[5:0] == 6'h03;

// EXT bus is used to communicate with the HPS for MSU functionality
wire [35:0] EXT_BUS;
hps_ext hps_ext
(
	.reset(reset),
	.clk_sys(clk_sys),
	.EXT_BUS(EXT_BUS),

	.msu_enable(msu_enable),

	.msu_track_mounting(msu_track_mounting),
	.msu_track_missing(msu_track_missing),
	.msu_track_num(msu_track_num),
	.msu_track_request(msu_track_request),

	.msu_audio_size(msu_audio_size),
	.msu_audio_ack(msu_audio_ack),
	.msu_audio_req(msu_audio_req),
	.msu_audio_seek(msu_audio_seek),
	.msu_audio_sector(msu_audio_sector),
	.msu_audio_download(msu_audio_download),

	.msu_data_base(msu_data_base)
);

wire        msu_track_mounting;
wire        msu_track_missing;
wire [15:0] msu_track_num;
wire        msu_track_request;
wire [31:0] msu_audio_size;

wire  [7:0] msu_volume;
wire        msu_audio_repeat;
wire        msu_audio_playing;
wire        msu_audio_stop;

wire        msu_audio_ack;
wire        msu_audio_req;
wire        msu_audio_seek;
wire [21:0] msu_audio_sector;

wire [15:0] msu_audio_l;
wire [15:0] msu_audio_r;

msu_audio msu_audio
(
	.reset(reset),

	.clk(clk_sys),
	.clk_rate(PAL ? 21281370 : 21477270),

	.ctl_volume(msu_volume),
	.ctl_stop(msu_audio_stop),
	.ctl_play(msu_audio_playing),
	.ctl_repeat(msu_audio_repeat),

	.track_size(msu_audio_size),
	.track_processing(msu_track_missing | msu_track_mounting | msu_track_request),

	.audio_download(msu_audio_download),
	.audio_data(ioctl_dout),
	.audio_data_wr(ioctl_wr),

	.audio_ack(msu_audio_ack),
	.audio_sector(msu_audio_sector),
	.audio_req(msu_audio_req),
	.audio_seek(msu_audio_seek),

	.audio_l(msu_audio_l),
	.audio_r(msu_audio_r)
);

wire [31:0] msu_data_addr;
wire  [7:0] msu_data;
wire        msu_data_ack;
wire        msu_data_seek;
wire        msu_data_req;
wire [31:0] msu_data_base;

wire [31:3] msu_ram_addr;
wire        msu_ram_req;
wire        msu_ram_ack;
wire [63:0] msu_ram_dout;

assign DDRAM_CLK = clk_mem;

msu_data_store msu_data_store
(
	.clk_sys(clk_sys),

	.base_addr(msu_data_base),

	.rd_next(msu_data_req),
	.rd_seek(msu_data_seek),
	.rd_seek_done(msu_data_ack),
	.rd_addr(msu_data_addr),

	.ram_addr(msu_ram_addr),
	.ram_req(msu_ram_req),
	.ram_ack(msu_ram_ack),
	.ram_din(msu_ram_dout),

	.rd_dout(msu_data)
);

ddram ddram
(
	.DDRAM_CLK(DDRAM_CLK),

	.DDRAM_BUSY(DDRAM_BUSY),
	.DDRAM_BURSTCNT(DDRAM_BURSTCNT),
	.DDRAM_ADDR(DDRAM_ADDR),
	.DDRAM_DOUT(DDRAM_DOUT),
	.DDRAM_DOUT_READY(DDRAM_DOUT_READY),
	.DDRAM_RD(DDRAM_RD),
	.DDRAM_DIN(DDRAM_DIN),
	.DDRAM_BE(DDRAM_BE),
	.DDRAM_WE(DDRAM_WE),

	.cache_rst(~RESET_N),

	.rdaddr({11'b0011_1111_10, ss_ddr_addr[21:3]}), // Save states at $3F80.0000
	.dout(ss_ddr_dout),
	.rom_din(ss_ddr_din),
	.rom_be(ss_ddr_be),
	.rom_we(ss_ddr_we),
	.rom_req(ss_ddr_req),
	.rom_ack(ss_ddr_ack),

	.rdaddr2(msu_ram_addr), // MSU is at $2060.0000-3F7F.FFFF
	.dout2(msu_ram_dout),
	.rd_req2(msu_ram_req),
	.rd_ack2(msu_ram_ack)
);


// saving with keyboard/OSD/gamepad
wire [1:0] ss_slot;
wire [7:0] ss_info;
wire ss_save, ss_load, ss_info_req;
wire ss_status;
wire ss_allow = ss_avail & cart_ready;

savestate_ui #(.INFO_TIMEOUT_BITS(27)) savestate_ui
(
	.clk            (clk_sys       ),
	.ps2_key        (ps2_key[10:0] ),
	.allow_ss       (ss_allow      ),
	.joySS          (joy0[12]      ),
	.joyRight       (joy0[0]       ),
	.joyLeft        (joy0[1]       ),
	.joyDown        (joy0[2]       ),
	.joyUp          (joy0[3]       ),
	.joyStart       (joy0[11]      ),
	.joyRewind      (0             ),
	.rewindEnable   (0             ),
	.status_slot    (status[52:51] ),
	.OSD_saveload   (status[31:30] ),
	.ss_save        (ss_save       ),
	.ss_load        (ss_load       ),
	.ss_info_req    (ss_info_req   ),
	.ss_info        (ss_info       ),
	.statusUpdate   (ss_status     ),
	.selected_slot  (ss_slot       )
);

endmodule
