-------------------------------------------------------------------------------
--
-- FPGA Colecovision
--
-- $Id: cv_console.vhd,v 1.13 2006/02/28 22:29:55 arnim Exp $
--
-- Toplevel of the Colecovision console
--
-- References:
--
--   * Dan Boris' schematics of the Colecovision board
--     http://www.atarihq.com/danb/files/colecovision.pdf
--
--   * Schematics of the Colecovision controller, same source
--     http://www.atarihq.com/danb/files/ColecoController.pdf
--
--   * Technical information, same source
--     http://www.atarihq.com/danb/files/CV-Tech.txt
--
-------------------------------------------------------------------------------
--
-- Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-------------------------------------------------------------------------------

library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity cv_console is

  generic (
    is_pal_g        : integer := 0;
    compat_rgb_g    : integer := 0
  );
  port (
    -- Global Interface -------------------------------------------------------
    clk_i           : in  std_logic;
    clk_en_10m7_i   : in  std_logic;
    reset_n_i       : in  std_logic;
    sg1000          : in  std_logic;
    dahjeeA_i       : in  std_logic;  -- SG-1000 RAM extension at 0x2000-0x3fff
    por_n_o         : out std_logic;
    -- Controller Interface ---------------------------------------------------
    ctrl_p1_i       : in  std_logic_vector( 1 downto 0);
    ctrl_p2_i       : in  std_logic_vector( 1 downto 0);
    ctrl_p3_i       : in  std_logic_vector( 1 downto 0);
    ctrl_p4_i       : in  std_logic_vector( 1 downto 0);
    ctrl_p5_o       : out std_logic_vector( 1 downto 0);
    ctrl_p6_i       : in  std_logic_vector( 1 downto 0);
    ctrl_p7_i       : in  std_logic_vector( 1 downto 0);
    ctrl_p8_o       : out std_logic_vector( 1 downto 0);
    ctrl_p9_i       : in  std_logic_vector( 1 downto 0);
    joy0_i          : in  std_logic_vector( 7 downto 0);
    joy1_i          : in  std_logic_vector( 7 downto 0);
    -- BIOS ROM Interface -----------------------------------------------------
    bios_rom_a_o    : out std_logic_vector(12 downto 0);
    bios_rom_ce_n_o : out std_logic;
    bios_rom_d_i    : in  std_logic_vector( 7 downto 0);
    -- CPU RAM Interface ------------------------------------------------------
    cpu_ram_a_o     : out std_logic_vector(14 downto 0);
    cpu_ram_ce_n_o  : out std_logic;
    cpu_ram_rd_n_o  : out std_logic;
    cpu_ram_we_n_o  : out std_logic;
    cpu_ram_d_i     : in  std_logic_vector( 7 downto 0);
    cpu_ram_d_o     : out std_logic_vector( 7 downto 0);
    -- Video RAM Interface ----------------------------------------------------
    vram_a_o        : out std_logic_vector(13 downto 0);
    vram_we_o       : out std_logic;
    vram_d_o        : out std_logic_vector( 7 downto 0);
    vram_d_i        : in  std_logic_vector( 7 downto 0);
    -- Cartridge ROM Interface ------------------------------------------------
    cart_a_o        : out std_logic_vector(19 downto 0);
    cart_pages_i    : in  std_logic_vector( 5 downto 0);
    cart_en_80_n_o  : out std_logic;
    cart_en_a0_n_o  : out std_logic;
    cart_en_c0_n_o  : out std_logic;
    cart_en_e0_n_o  : out std_logic;
    cart_rd         : out std_logic;
    cart_d_i        : in  std_logic_vector( 7 downto 0);
    cart_en_sg1000_n_o : out std_logic;
    -- RGB Video Interface ----------------------------------------------------
    border_i        : in  std_logic;
    col_o           : out std_logic_vector( 3 downto 0);
    rgb_r_o         : out std_logic_vector( 7 downto 0);
    rgb_g_o         : out std_logic_vector( 7 downto 0);
    rgb_b_o         : out std_logic_vector( 7 downto 0);
    hsync_n_o       : out std_logic;
    vsync_n_o       : out std_logic;
    blank_n_o       : out std_logic;
    hblank_o        : out std_logic;
    vblank_o        : out std_logic;
    comp_sync_n_o   : out std_logic;
    -- Audio Interface --------------------------------------------------------
    ss_frz_i        : in  std_logic := '0';
    ss_wr_i         : in  std_logic := '0';
    ss_a_i          : in  std_logic_vector(7 downto 0) := (others => '0');
    ss_d_i          : in  std_logic_vector(7 downto 0) := (others => '0');
    ss_d_o          : out std_logic_vector(7 downto 0);
    ss_cpuset_i     : in  std_logic := '0';
    ss_cpu_cen_p_i  : in  std_logic := '0';
    ss_cpu_cen_n_i  : in  std_logic := '0';
    ss_bnd_o        : out std_logic;

    audio_o         : out unsigned(13 downto 0)
  );

end cv_console;


-- pragma translate_off
use std.textio.all;
-- pragma translate_on

architecture struct of cv_console is

  signal por_n_s          : std_logic;
  signal reset_n_s        : std_logic;

  signal clk_en_3m58_p_s  : std_logic;
  signal clk_en_3m58_n_s  : std_logic;

  -- CPU signals
  signal wait_n_s         : std_logic;
  signal nmi_n_s          : std_logic;
  signal int_n_s          : std_logic;
  signal iorq_n_s         : std_logic;
  signal m1_n_s           : std_logic;
  signal m1_wait_q        : std_logic;
  signal rd_n_s,
         wr_n_s           : std_logic;
  signal mreq_n_s         : std_logic;
  signal rfsh_n_s         : std_logic;
  signal a_s              : std_logic_vector(15 downto 0);
  signal d_to_cpu_s,
         d_from_cpu_s     : std_logic_vector( 7 downto 0);

  -- VDP18 signal
  signal d_from_vdp_s     : std_logic_vector( 7 downto 0);
  signal vdp_int_n_s      : std_logic;

  -- SN76489 signal
  signal psg_ready_s      : std_logic;
  signal psg_b_audio_s    : unsigned( 13 downto 0);

  -- AY-8910 signal
  signal ay_d_s           : std_logic_vector( 7 downto 0);
  signal ay_ch_a_s        : unsigned( 11 downto 0);
  signal ay_ch_b_s        : unsigned( 11 downto 0);
  signal ay_ch_c_s        : unsigned( 11 downto 0);
  signal psg_a_audio_s    : unsigned( 13 downto 0);

  -- Controller signals
  signal d_from_ctrl_s    : std_logic_vector( 7 downto 0);
  signal d_to_ctrl_s      : std_logic_vector( 7 downto 0);
  signal ctrl_int_n_s     : std_logic;

  -- Address decoder signals
  signal bios_rom_ce_n_s  : std_logic;
  signal ram_ce_n_s       : std_logic;
  signal vdp_r_n_s,
         vdp_w_n_s        : std_logic;
  signal psg_we_n_s       : std_logic;
  signal ay_addr_we_n_s   : std_logic;
  signal ay_data_we_n_s   : std_logic;
  signal ay_data_rd_n_s   : std_logic;
  signal ctrl_r_n_s       : std_logic;
  signal ctrl_en_key_n_s,
         ctrl_en_joy_n_s  : std_logic;
  signal cart_en_80_n_s,
         cart_en_a0_n_s,
         cart_en_c0_n_s,
         cart_en_e0_n_s   : std_logic;
  signal cart_page_s      : std_logic_vector(5 downto 0);

  signal cart_en_sg1000_n_s : std_logic;
  -- misc signals
  signal vdd_s            : std_logic;

  type   ss_cpu_arr_t is array (0 to 31) of std_logic_vector(7 downto 0);
  signal ss_cpu_q         : ss_cpu_arr_t;
  signal ss_dir_s         : std_logic_vector(211 downto 0);
  signal cpu_reg_s        : std_logic_vector(211 downto 0);
  signal cpu_wz_s         : std_logic_vector(15 downto 0);
  signal cpu_nmi_s        : std_logic;
  signal cpu_mc_s         : std_logic_vector(2 downto 0);
  signal cpu_ts_s         : std_logic_vector(2 downto 0);
  signal cpu_cen_p_s      : std_logic;
  signal cpu_cen_n_s      : std_logic;
  signal ss_d_cpu_s       : std_logic_vector(7 downto 0);
  signal ss_d_vdp_s       : std_logic_vector(7 downto 0);
  signal ss_d_clk_s       : std_logic_vector(7 downto 0);
  signal ss_d_dec_s       : std_logic_vector(7 downto 0);
  signal ss_d_ctrl_s      : std_logic_vector(7 downto 0);
  signal ss_d_psgb_s      : std_logic_vector(7 downto 0);
  signal ss_d_psga_s      : std_logic_vector(7 downto 0);
  signal ss_wr_vdp_s      : std_logic;
  signal ss_wr_clk_s      : std_logic;
  signal ss_wr_dec_s      : std_logic;
  signal ss_wr_ctrl_s     : std_logic;
  signal ss_wr_psgb_s     : std_logic;
  signal ss_wr_psga_s     : std_logic;

  -- pragma translate_off
  file logfile: text is out "access.txt";
  -- pragma translate_on

begin

  vdd_s <= '1';
  audio_o <= psg_a_audio_s + psg_b_audio_s;

  int_n_s <= ctrl_int_n_s when sg1000 = '0' else vdp_int_n_s;
  nmi_n_s <= vdp_int_n_s  when sg1000 = '0' else joy0_i(7) and joy1_i(7);

  -----------------------------------------------------------------------------
  -- Reset generation
  -----------------------------------------------------------------------------
  por_b : work.cv_por
    port map (
      clk_i   => clk_i,
      por_n_o => por_n_s
    );
  por_n_o   <= por_n_s;
  reset_n_s <= por_n_s and reset_n_i;

  -----------------------------------------------------------------------------
  -- Clock generation
  -----------------------------------------------------------------------------
  clock_b : work.cv_clock
    port map (
      clk_i         => clk_i,
      clk_en_10m7_i => clk_en_10m7_i,
      reset_n_i     => reset_n_s,
      clk_en_3m58_p_o => clk_en_3m58_p_s,
      clk_en_3m58_n_o => clk_en_3m58_n_s,
      ss_wr_i         => ss_wr_clk_s,
      ss_a_i          => ss_a_i(3 downto 0),
      ss_d_i          => ss_d_i,
      ss_d_o          => ss_d_clk_s
    );

  -----------------------------------------------------------------------------
  -- T80 CPU
  -----------------------------------------------------------------------------
  t80a_b : work.T80pa
    generic map (
      Mode       => 0
    )
    port map(
      RESET_n    => reset_n_s,
      CLK        => clk_i,
      CEN_p      => cpu_cen_p_s,
      CEN_n      => cpu_cen_n_s,
      WAIT_n     => wait_n_s,
      INT_n      => int_n_s,
      NMI_n      => nmi_n_s,
      BUSRQ_n    => vdd_s,
      M1_n       => m1_n_s,
      MREQ_n     => mreq_n_s,
      IORQ_n     => iorq_n_s,
      RD_n       => rd_n_s,
      WR_n       => wr_n_s,
      RFSH_n     => rfsh_n_s,
      HALT_n     => open,
      BUSAK_n    => open,
      A          => a_s,
      DI         => d_to_cpu_s,
      DO         => d_from_cpu_s,
      REG        => cpu_reg_s,
      DIRSet     => ss_cpuset_i,
      DIR        => ss_dir_s,
      SS_WZ_o    => cpu_wz_s,
      SS_NMI_o   => cpu_nmi_s,
      SS_WZ_i    => ss_cpu_q(27) & ss_cpu_q(28),
      SS_NMI_i   => ss_cpu_q(29)(0),
      SS_MC_o    => cpu_mc_s,
      SS_TS_o    => cpu_ts_s
    );

  cpu_cen_p_s <= clk_en_3m58_p_s or ss_cpu_cen_p_i;
  cpu_cen_n_s <= clk_en_3m58_n_s or ss_cpu_cen_n_i;

  ss_bnd_o <= '1' when cpu_mc_s = "001" and cpu_ts_s = "010" and wait_n_s = '1'
              else '0';

  ss_wr_vdp_s  <= ss_wr_i when ss_a_i(7 downto 4) = x"4" or
                                ss_a_i(7 downto 4) = x"5" or
                                ss_a_i(7 downto 4) = x"6" else '0';
  ss_wr_clk_s  <= ss_wr_i when ss_a_i(7 downto 4) = x"7" else '0';
  ss_wr_dec_s  <= ss_wr_i when ss_a_i(7 downto 4) = x"8" else '0';
  ss_wr_ctrl_s <= ss_wr_i when ss_a_i(7 downto 4) = x"9" else '0';
  ss_wr_psgb_s <= ss_wr_i when ss_a_i(7 downto 5) = "101" else '0';
  ss_wr_psga_s <= ss_wr_i when ss_a_i(7 downto 5) = "110" else '0';

  ss_cpu_wr: process (clk_i)
  begin
    if rising_edge(clk_i) then
      if ss_wr_i = '1' and ss_a_i(7 downto 5) = "001" then
        ss_cpu_q(to_integer(unsigned(ss_a_i(4 downto 0)))) <= ss_d_i;
      end if;
    end if;
  end process ss_cpu_wr;

  ss_dir_s <= ss_cpu_q(26)(3 downto 0) & ss_cpu_q(25) & ss_cpu_q(24) & ss_cpu_q(23) & ss_cpu_q(22) & ss_cpu_q(21) & ss_cpu_q(20) & ss_cpu_q(19) & ss_cpu_q(18) & ss_cpu_q(17) & ss_cpu_q(16) & ss_cpu_q(15) & ss_cpu_q(14) & ss_cpu_q(13) & ss_cpu_q(12) & ss_cpu_q(11) & ss_cpu_q(10) & ss_cpu_q(9) & ss_cpu_q(8) & ss_cpu_q(7) & ss_cpu_q(6) & ss_cpu_q(5) & ss_cpu_q(4) & ss_cpu_q(3) & ss_cpu_q(2) & ss_cpu_q(1) & ss_cpu_q(0);

  ss_cpu_rd: process (ss_a_i, cpu_reg_s, cpu_wz_s, cpu_nmi_s)
  begin
    case ss_a_i(4 downto 0) is
      when "00000" => ss_d_cpu_s <= cpu_reg_s(7 downto 0);
      when "00001" => ss_d_cpu_s <= cpu_reg_s(15 downto 8);
      when "00010" => ss_d_cpu_s <= cpu_reg_s(23 downto 16);
      when "00011" => ss_d_cpu_s <= cpu_reg_s(31 downto 24);
      when "00100" => ss_d_cpu_s <= cpu_reg_s(39 downto 32);
      when "00101" => ss_d_cpu_s <= cpu_reg_s(47 downto 40);
      when "00110" => ss_d_cpu_s <= cpu_reg_s(55 downto 48);
      when "00111" => ss_d_cpu_s <= cpu_reg_s(63 downto 56);
      when "01000" => ss_d_cpu_s <= cpu_reg_s(71 downto 64);
      when "01001" => ss_d_cpu_s <= cpu_reg_s(79 downto 72);
      when "01010" => ss_d_cpu_s <= cpu_reg_s(87 downto 80);
      when "01011" => ss_d_cpu_s <= cpu_reg_s(95 downto 88);
      when "01100" => ss_d_cpu_s <= cpu_reg_s(103 downto 96);
      when "01101" => ss_d_cpu_s <= cpu_reg_s(111 downto 104);
      when "01110" => ss_d_cpu_s <= cpu_reg_s(119 downto 112);
      when "01111" => ss_d_cpu_s <= cpu_reg_s(127 downto 120);
      when "10000" => ss_d_cpu_s <= cpu_reg_s(135 downto 128);
      when "10001" => ss_d_cpu_s <= cpu_reg_s(143 downto 136);
      when "10010" => ss_d_cpu_s <= cpu_reg_s(151 downto 144);
      when "10011" => ss_d_cpu_s <= cpu_reg_s(159 downto 152);
      when "10100" => ss_d_cpu_s <= cpu_reg_s(167 downto 160);
      when "10101" => ss_d_cpu_s <= cpu_reg_s(175 downto 168);
      when "10110" => ss_d_cpu_s <= cpu_reg_s(183 downto 176);
      when "10111" => ss_d_cpu_s <= cpu_reg_s(191 downto 184);
      when "11000" => ss_d_cpu_s <= cpu_reg_s(199 downto 192);
      when "11001" => ss_d_cpu_s <= cpu_reg_s(207 downto 200);
      when "11010" => ss_d_cpu_s <= "0000" & cpu_reg_s(211 downto 208);
      when "11011" => ss_d_cpu_s <= cpu_wz_s(7 downto 0);
      when "11100" => ss_d_cpu_s <= cpu_wz_s(15 downto 8);
      when "11101" => ss_d_cpu_s <= "0000000" & cpu_nmi_s;
      when others  => ss_d_cpu_s <= (others => '0');
    end case;
  end process ss_cpu_rd;

  ss_d_o <= ss_d_cpu_s  when ss_a_i(7 downto 5) = "001" else
            ss_d_vdp_s  when ss_a_i(7 downto 4) = x"4" or
                             ss_a_i(7 downto 4) = x"5" or
                             ss_a_i(7 downto 4) = x"6" else
            ss_d_clk_s  when ss_a_i(7 downto 4) = x"7" and ss_a_i(3 downto 0) = x"0" else
            "0000000" & m1_wait_q
                        when ss_a_i(7 downto 4) = x"7" and ss_a_i(3 downto 0) = x"1" else
            ss_d_dec_s  when ss_a_i(7 downto 4) = x"8" else
            ss_d_ctrl_s when ss_a_i(7 downto 4) = x"9" else
            ss_d_psgb_s when ss_a_i(7 downto 5) = "101" else
            ss_d_psga_s when ss_a_i(7 downto 5) = "110" else
            (others => '0');

  -----------------------------------------------------------------------------
  -- Process m1_wait
  --
  -- Purpose:
  --   Implements flip-flop U8A which asserts a wait states controlled by M1.
  --
  m1_wait: process (clk_i, reset_n_s, m1_n_s)
  begin
    if reset_n_s = '0' or m1_n_s = '1' then
      m1_wait_q   <= '0';
    elsif clk_i'event and clk_i = '1' then
      if clk_en_3m58_p_s = '1' then
        m1_wait_q <= not m1_wait_q;
      end if;
    end if;
  end process m1_wait;

  wait_n_s  <= psg_ready_s and not m1_wait_q;

  --
  -----------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- TMS9928A Video Display Processor
  -----------------------------------------------------------------------------
  vdp18_b : work.vdp18_core
    generic map (
      is_pal_g      => is_pal_g,
      compat_rgb_g  => compat_rgb_g
    )
    port map (
      clk_i         => clk_i,
      clk_en_10m7_i => clk_en_10m7_i,
      reset_n_i     => reset_n_s,
      csr_n_i       => vdp_r_n_s,
      csw_n_i       => vdp_w_n_s,
      mode_i        => a_s(0),
      int_n_o       => vdp_int_n_s,
      cd_i          => d_from_cpu_s,
      cd_o          => d_from_vdp_s,
      vram_we_o     => vram_we_o,
      vram_a_o      => vram_a_o,
      vram_d_o      => vram_d_o,
      vram_d_i      => vram_d_i,
      col_o         => col_o,
      rgb_r_o       => rgb_r_o,
      rgb_g_o       => rgb_g_o,
      rgb_b_o       => rgb_b_o,
      hsync_n_o     => hsync_n_o,
      vsync_n_o     => vsync_n_o,
      blank_n_o     => blank_n_o,
      border_i      => border_i,
      hblank_o      => hblank_o,
      vblank_o      => vblank_o,
      comp_sync_n_o => comp_sync_n_o,
      ss_frz_i      => ss_frz_i,
      ss_wr_i       => ss_wr_vdp_s,
      ss_a_i        => ss_a_i,
      ss_d_i        => ss_d_i,
      ss_d_o        => ss_d_vdp_s
    );


  psg_a: work.ym2149_audio
    port map (
		clk_i       => clk_i,
		en_clk_psg_i=> clk_en_3m58_p_s,
		reset_n_i   => reset_n_s,
		bdir_i      => not ay_addr_we_n_s or not ay_data_we_n_s,
		bc_i        => not ay_addr_we_n_s or not ay_data_rd_n_s,
		data_i      => d_from_cpu_s,
		data_r_o    => ay_d_s,
		ch_a_o      => ay_ch_a_s,
		ch_b_o      => ay_ch_b_s,
		ch_c_o      => ay_ch_c_s,
		mix_audio_o => psg_a_audio_s,
		sel_n_i     => '0',
		ss_wr_i     => ss_wr_psga_s,
		ss_a_i      => ss_a_i(4 downto 0),
		ss_d_i      => ss_d_i,
		ss_d_o      => ss_d_psga_s
    );
 
	 
  -----------------------------------------------------------------------------
  -- SN76489 Programmable Sound Generator
  -----------------------------------------------------------------------------
  psg_b : work.sn76489_audio
    generic map (
      FAST_IO_G          => '0',
		MIN_PERIOD_CNT_G   => 17
    )
    port map (
      clk_i        => clk_i,
      en_clk_psg_i => clk_en_3m58_p_s,
      ce_n_i       => psg_we_n_s,
      wr_n_i       => psg_we_n_s,
      ready_o      => psg_ready_s,
      data_i       => d_from_cpu_s,
      mix_audio_o  => psg_b_audio_s,
      ss_frz_i     => ss_frz_i,
      ss_wr_i      => ss_wr_psgb_s,
      ss_a_i       => ss_a_i(4 downto 0),
      ss_d_i       => ss_d_i,
      ss_d_o       => ss_d_psgb_s
    );


  -----------------------------------------------------------------------------
  -- Controller ports
  -----------------------------------------------------------------------------
  ctrl_b : work.cv_ctrl
    port map (
      clk_i           => clk_i,
      clk_en_3m58_i   => clk_en_3m58_p_s,
      reset_n_i       => reset_n_s,
      ctrl_en_key_n_i => ctrl_en_key_n_s,
      ctrl_en_joy_n_i => ctrl_en_joy_n_s,
      a1_i            => a_s(1),
      ctrl_p1_i       => ctrl_p1_i,
      ctrl_p2_i       => ctrl_p2_i,
      ctrl_p3_i       => ctrl_p3_i,
      ctrl_p4_i       => ctrl_p4_i,
      ctrl_p5_o       => ctrl_p5_o,
      ctrl_p6_i       => ctrl_p6_i,
      ctrl_p7_i       => ctrl_p7_i,
      ctrl_p8_o       => ctrl_p8_o,
      ctrl_p9_i       => ctrl_p9_i,
      d_o             => d_from_ctrl_s,
		int_n_o         => ctrl_int_n_s,
      ss_frz_i        => ss_frz_i,
      ss_wr_i         => ss_wr_ctrl_s,
      ss_a_i          => ss_a_i(3 downto 0),
      ss_d_i          => ss_d_i,
      ss_d_o          => ss_d_ctrl_s
    );


  -----------------------------------------------------------------------------
  -- Address decoder
  -----------------------------------------------------------------------------
  addr_dec_b : work.cv_addr_dec
    port map (
      clk_i           => clk_i,
      reset_n_i       => reset_n_i,
      sg1000          => sg1000,
      dahjeeA_i       => dahjeeA_i,
      a_i             => a_s,
      d_i             => d_from_cpu_s,
      cart_pages_i    => cart_pages_i,
      cart_page_o     => cart_page_s,
      iorq_n_i        => iorq_n_s,
      rd_n_i          => rd_n_s,
      wr_n_i          => wr_n_s,
      mreq_n_i        => mreq_n_s,
      rfsh_n_i        => rfsh_n_s,
      bios_rom_ce_n_o => bios_rom_ce_n_s,
      ram_ce_n_o      => ram_ce_n_s,
      vdp_r_n_o       => vdp_r_n_s,
      vdp_w_n_o       => vdp_w_n_s,
      psg_we_n_o      => psg_we_n_s,
      ay_addr_we_n_o  => ay_addr_we_n_s,
      ay_data_we_n_o  => ay_data_we_n_s,
      ay_data_rd_n_o  => ay_data_rd_n_s,
      ctrl_r_n_o      => ctrl_r_n_s,
      ctrl_en_key_n_o => ctrl_en_key_n_s,
      ctrl_en_joy_n_o => ctrl_en_joy_n_s,
      cart_en_80_n_o  => cart_en_80_n_s,
      cart_en_a0_n_o  => cart_en_a0_n_s,
      cart_en_c0_n_o  => cart_en_c0_n_s,
      cart_en_e0_n_o  => cart_en_e0_n_s,
      cart_en_sg1000_n_o=> cart_en_sg1000_n_s,
      ss_frz_i        => ss_frz_i,
      ss_wr_i         => ss_wr_dec_s,
      ss_a_i          => ss_a_i(3 downto 0),
      ss_d_i          => ss_d_i,
      ss_d_o          => ss_d_dec_s
    );

  bios_rom_ce_n_o <= bios_rom_ce_n_s;
  cpu_ram_ce_n_o  <= ram_ce_n_s;
  cpu_ram_we_n_o  <= wr_n_s;
  cpu_ram_rd_n_o  <= rd_n_s;
  cart_en_80_n_o  <= cart_en_80_n_s;
  cart_en_a0_n_o  <= cart_en_a0_n_s;
  cart_en_c0_n_o  <= cart_en_c0_n_s;
  cart_en_e0_n_o  <= cart_en_e0_n_s;
  cart_en_sg1000_n_o <= cart_en_sg1000_n_s;
  cart_rd <= not (cart_en_80_n_s and cart_en_a0_n_s and cart_en_c0_n_s and cart_en_e0_n_s and cart_en_sg1000_n_s);

  -----------------------------------------------------------------------------
  -- Bus multiplexer
  -----------------------------------------------------------------------------

  d_to_ctrl_s <= d_from_ctrl_s when sg1000 = '0'
    else joy1_i(2) & joy1_i(3) & joy0_i(5) & joy0_i(4) & joy0_i(0) & joy0_i(1) & joy0_i(2) & joy0_i(3) when a_s(0) = '0'
    else "111" & reset_n_i & joy1_i(5) & joy1_i(4) & joy1_i(0) & joy1_i(1);

  bus_mux_b : work.cv_bus_mux
    port map (
      bios_rom_ce_n_i => bios_rom_ce_n_s,
      ram_ce_n_i      => ram_ce_n_s,
      vdp_r_n_i       => vdp_r_n_s,
      ctrl_r_n_i      => ctrl_r_n_s,
      cart_en_80_n_i  => cart_en_80_n_s,
      cart_en_a0_n_i  => cart_en_a0_n_s,
      cart_en_c0_n_i  => cart_en_c0_n_s,
      cart_en_e0_n_i  => cart_en_e0_n_s,
      cart_en_sg1000_n_i => cart_en_sg1000_n_s,
      ay_data_rd_n_i  => ay_data_rd_n_s,
      bios_rom_d_i    => bios_rom_d_i,
      cpu_ram_d_i     => cpu_ram_d_i,
      vdp_d_i         => d_from_vdp_s,
      ctrl_d_i        => d_to_ctrl_s,
      cart_d_i        => cart_d_i,
      ay_d_i          => ay_d_s,
      d_o             => d_to_cpu_s
    );


  -----------------------------------------------------------------------------
  -- Misc outputs
  -----------------------------------------------------------------------------
  bios_rom_a_o <= a_s(12 downto 0);
  cpu_ram_a_o  <= a_s(14 downto 0);
  cpu_ram_d_o  <= d_from_cpu_s;
  cart_a_o     <= cart_page_s & a_s(13 downto 0) when sg1000 = '0' else "0000" & a_s(15 downto 0);


  -- pragma translate_off
  -----------------------------------------------------------------------------
  -- Process logger
  --
  -- Purpose:
  --   Logs CPU accesses to file "access.txt".
  --
  logger: process (clk_i)

    function byte_to_hex_f(val : in natural) return string is
      variable tmp_v,
               digit_v  : natural range 0 to 255;
      variable result_v : string(1 downto 0);
    begin
      tmp_v := val;
      for idx in 0 to 1 loop
        digit_v := tmp_v mod 16;
        if digit_v > 9 then
          digit_v := digit_v + 97-10;
        else
          digit_v := digit_v + 48;
        end if;
        result_v(idx) := character'val(digit_v);

        tmp_v := tmp_v / 16;
      end loop;

      return result_v;
    end;

    function byte_to_hex_f(val : in std_logic_vector) return string is
    begin
      return byte_to_hex_f(to_integer(unsigned(val)));
    end;

    function word_to_hex_f(val : in std_logic_vector) return string is
      variable tmp_v     : natural range 0 to 2**16-1;
      variable byte_u_v,
               byte_l_v  : natural range 0 to 255;
      variable result_v  : string(3 downto 0);
    begin
      tmp_v := to_integer(unsigned(val));
      byte_l_v := tmp_v mod 256;
      byte_u_v := tmp_v / 256;

      result_v(3 downto 2) := byte_to_hex_f(byte_u_v);
      result_v(1 downto 0) := byte_to_hex_f(byte_l_v);

      return result_v;
    end;

    variable l          : line;
    variable written_v  : boolean := false;
    variable inactive_v : boolean;
  begin
    inactive_v := true;

    -- BIOS access ------------------------------------------------------------
    if bios_rom_ce_n_s = '0' then
      inactive_v := false;

      if not written_v then
        write(l, string'("BIOS Read  "));
        write(l, byte_to_hex_f(bios_rom_d_i));
        write(l, string'(" @ "));
        write(l, word_to_hex_f(a_s));
        written_v := true;
      end if;

    end if;

    -- CPU RAM access ---------------------------------------------------------
    if ram_ce_n_s = '0' then
      inactive_v := false;

      if not written_v then
        if wr_n_s = '1' then
          write(l, string'("RAM  Read  "));
          write(l, byte_to_hex_f(cpu_ram_d_i));
        else
          write(l, string'("RAM  Write "));
          write(l, byte_to_hex_f(d_from_cpu_s));
        end if;
        write(l, string'(" @ "));
        write(l, word_to_hex_f(a_s));
        written_v := true;
      end if;

    end if;

    -- Cartridge access -------------------------------------------------------
    if (cart_en_80_n_s and cart_en_a0_n_s and
        cart_en_c0_n_s and cart_en_e0_n_s) = '0' then
      inactive_v := false;

      if not written_v then
        write(l, string'("Cart Read  "));
        write(l, byte_to_hex_f(cart_d_i));
        write(l, string'(" @ "));
        write(l, word_to_hex_f(a_s));
        written_v := true;
      end if;

    end if;

    -- VDP read access --------------------------------------------------------
    if vdp_r_n_s = '0' then
      inactive_v := false;

      if not written_v then
        write(l, string'("VDP  Read  "));
        write(l, byte_to_hex_f(d_from_vdp_s));
        write(l, string'(" Mode "));
        write(l, byte_to_hex_f('0' & a_s(0)));
        written_v := true;
      end if;

    end if;

    -- VDP write access -------------------------------------------------------
    if vdp_w_n_s = '0' then
      inactive_v := false;

      if not written_v then
        write(l, string'("VDP  Write "));
        write(l, byte_to_hex_f(d_from_cpu_s));
        write(l, string'(" Mode "));
        write(l, byte_to_hex_f('0' & a_s(0)));
        written_v := true;
      end if;

    end if;

    -- Dump information -------------------------------------------------------
    if clk_i'event and clk_i = '1' then
      if clk_en_10m7_i = '1' then
        if inactive_v and written_v then
          writeline(logfile, l);
          written_v := false;
        end if;
      end if;
    end if;
  end process logger;
  --
  -----------------------------------------------------------------------------
  -- pragma translate_on

end struct;
