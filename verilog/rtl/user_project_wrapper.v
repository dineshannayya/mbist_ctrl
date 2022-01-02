//////////////////////////////////////////////////////////////////////////////
// SPDX-FileCopyrightText: 2021 , Dinesh Annayya                          
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0
// SPDX-FileContributor: Created by Dinesh Annayya <dinesha@opencores.org>
//
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Digital core                                                ////
////                                                              ////
////  This file is part of the mbist_ctrl  project                ////
////  https://github.com/dineshannayya/mbist_ctrl.git             ////
////                                                              ////
////  Description                                                 ////
////      This is digital core and integrate all the main block   ////
////      here.                                                   ////
////      1. Wishbone Host                                        ////
////      2. 4x MBIST Controller                                  ////
////      3. 2x SRAM 2KB                                          ////
////      4. 2x SRAM 1KB                                          ////
////      5. Wishbone Interconnect                                ////
////      6. Global Register                                      ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
////  Revision :                                                  ////
////    0.1 - 13th Oct 2021, Dinesh A                             ////
////          Initial Version                                     ////
////    0.2 - 19, Nov 2021, Dinesh A                              ////
////          Following things are integrated                     ////
////          2x SRAM 2KB, 2x SRAM 1KB, 4 MBIST ,                 ////
////          1 Wishbone Interconnect, 1 Global register          ////
////    0.3 - 20, Nov 2021, Dinesh A                              ////
////          Following  are integrated                           ////
////          4x SRAM 2KB, 4x SRAM 1KB, 8 MBIST ,                 ////
////          1 Wishbone Interconnect, 1 Global register          ////
////    0.4 - 23 Nov 2021, Dinesh A                               ////
////          Three Software Register added for signature at glbl ////
////    0.5 - 10 Dec 2021, Dinesh A                               ////
////          Full Chip STA with Caravel                          ////
////    0.6  Jan 01, 2022, Dinesh A                               ////
////       1. LA[0] is added as soft reset option at wb_port      ////
////       2. Uart Master is added at wb_port                     ////
//////////////////////////////////////////////////////////////////////
`default_nettype none

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

parameter BIST1_ADDR_WD = 11; // 512x32 SRAM
parameter BIST2_ADDR_WD = 10; // 256x32 SRAM
parameter BIST_DATA_WD = 32;
parameter WB_WIDTH = 32; // WB ADDRESS/DARA WIDTH

//---------------------------------------------------------------------
// WB HOST Interface
//---------------------------------------------------------------------
wire                           wbd_int_cyc_i; // strobe/request
wire                           wbd_int_stb_i; // strobe/request
wire   [WB_WIDTH-1:0]          wbd_int_adr_i; // address
wire                           wbd_int_we_i;  // write
wire   [WB_WIDTH-1:0]          wbd_int_dat_i; // data output
wire   [3:0]                   wbd_int_sel_i; // byte enable
wire   [WB_WIDTH-1:0]          wbd_int_dat_o; // data input
wire                           wbd_int_ack_o; // acknowlegement
wire                           wbd_int_err_o; // error

//---------------------------------------------------------------------
//    Global Register Wishbone Interface
//---------------------------------------------------------------------
wire                           wbd_glbl_stb_o; // strobe/request
wire   [7:0]                   wbd_glbl_adr_o; // address
wire                           wbd_glbl_we_o;  // write
wire   [WB_WIDTH-1:0]          wbd_glbl_dat_o; // data output
wire   [3:0]                   wbd_glbl_sel_o; // byte enable
wire                           wbd_glbl_cyc_o ;
wire   [WB_WIDTH-1:0]          wbd_glbl_dat_i; // data input
wire                           wbd_glbl_ack_i; // acknowlegement
wire                           wbd_glbl_err_i;  // error

//---------------------------------------------------------------------
//  MBIST1  
//---------------------------------------------------------------------
wire                           wbd_mbist1_stb_o; // strobe/request
wire   [BIST1_ADDR_WD-1:0]     wbd_mbist1_adr_o; // address
wire                           wbd_mbist1_we_o;  // write
wire   [WB_WIDTH-1:0]          wbd_mbist1_dat_o; // data output
wire   [3:0]                   wbd_mbist1_sel_o; // byte enable
wire                           wbd_mbist1_cyc_o ;
wire   [WB_WIDTH-1:0]          wbd_mbist1_dat_i; // data input
wire                           wbd_mbist1_ack_i; // acknowlegement
wire                           wbd_mbist1_err_i;  // error

//---------------------------------------------------------------------
//  MBIST2  
//---------------------------------------------------------------------
wire                           wbd_mbist2_stb_o; // strobe/request
wire   [BIST1_ADDR_WD-1:0]     wbd_mbist2_adr_o; // address
wire                           wbd_mbist2_we_o;  // write
wire   [WB_WIDTH-1:0]          wbd_mbist2_dat_o; // data output
wire   [3:0]                   wbd_mbist2_sel_o; // byte enable
wire                           wbd_mbist2_cyc_o ;
wire   [WB_WIDTH-1:0]          wbd_mbist2_dat_i; // data input
wire                           wbd_mbist2_ack_i; // acknowlegement
wire                           wbd_mbist2_err_i;  // error

//---------------------------------------------------------------------
//  MBIST3  
//---------------------------------------------------------------------
wire                           wbd_mbist3_stb_o; // strobe/request
wire   [BIST1_ADDR_WD-1:0]     wbd_mbist3_adr_o; // address
wire                           wbd_mbist3_we_o;  // write
wire   [WB_WIDTH-1:0]          wbd_mbist3_dat_o; // data output
wire   [3:0]                   wbd_mbist3_sel_o; // byte enable
wire                           wbd_mbist3_cyc_o ;
wire   [WB_WIDTH-1:0]          wbd_mbist3_dat_i; // data input
wire                           wbd_mbist3_ack_i; // acknowlegement
wire                           wbd_mbist3_err_i;  // error

//---------------------------------------------------------------------
//  MBIST4  
//---------------------------------------------------------------------
wire                           wbd_mbist4_stb_o; // strobe/request
wire   [BIST1_ADDR_WD-1:0]     wbd_mbist4_adr_o; // address
wire                           wbd_mbist4_we_o;  // write
wire   [WB_WIDTH-1:0]          wbd_mbist4_dat_o; // data output
wire   [3:0]                   wbd_mbist4_sel_o; // byte enable
wire                           wbd_mbist4_cyc_o ;
wire   [WB_WIDTH-1:0]          wbd_mbist4_dat_i; // data input
wire                           wbd_mbist4_ack_i; // acknowlegement
wire                           wbd_mbist4_err_i;  // error

//---------------------------------------------------------------------
//  MBIST5  
//---------------------------------------------------------------------
wire                           wbd_mbist5_stb_o; // strobe/request
wire   [BIST2_ADDR_WD-1:0]     wbd_mbist5_adr_o; // address
wire                           wbd_mbist5_we_o;  // write
wire   [WB_WIDTH-1:0]          wbd_mbist5_dat_o; // data output
wire   [3:0]                   wbd_mbist5_sel_o; // byte enable
wire                           wbd_mbist5_cyc_o ;
wire   [WB_WIDTH-1:0]          wbd_mbist5_dat_i; // data input
wire                           wbd_mbist5_ack_i; // acknowlegement
wire                           wbd_mbist5_err_i;  // error

//---------------------------------------------------------------------
//  MBIST6  
//---------------------------------------------------------------------
wire                           wbd_mbist6_stb_o; // strobe/request
wire   [BIST2_ADDR_WD-1:0]     wbd_mbist6_adr_o; // address
wire                           wbd_mbist6_we_o;  // write
wire   [WB_WIDTH-1:0]          wbd_mbist6_dat_o; // data output
wire   [3:0]                   wbd_mbist6_sel_o; // byte enable
wire                           wbd_mbist6_cyc_o ;
wire   [WB_WIDTH-1:0]          wbd_mbist6_dat_i; // data input
wire                           wbd_mbist6_ack_i; // acknowlegement
wire                           wbd_mbist6_err_i;  // error

//---------------------------------------------------------------------
//  MBIST7  
//---------------------------------------------------------------------
wire                           wbd_mbist7_stb_o; // strobe/request
wire   [BIST2_ADDR_WD-1:0]     wbd_mbist7_adr_o; // address
wire                           wbd_mbist7_we_o;  // write
wire   [WB_WIDTH-1:0]          wbd_mbist7_dat_o; // data output
wire   [3:0]                   wbd_mbist7_sel_o; // byte enable
wire                           wbd_mbist7_cyc_o ;
wire   [WB_WIDTH-1:0]          wbd_mbist7_dat_i; // data input
wire                           wbd_mbist7_ack_i; // acknowlegement
wire                           wbd_mbist7_err_i;  // error

//---------------------------------------------------------------------
//  MBIST8  
//---------------------------------------------------------------------
wire                           wbd_mbist8_stb_o; // strobe/request
wire   [BIST2_ADDR_WD-1:0]     wbd_mbist8_adr_o; // address
wire                           wbd_mbist8_we_o;  // write
wire   [WB_WIDTH-1:0]          wbd_mbist8_dat_o; // data output
wire   [3:0]                   wbd_mbist8_sel_o; // byte enable
wire                           wbd_mbist8_cyc_o ;
wire   [WB_WIDTH-1:0]          wbd_mbist8_dat_i; // data input
wire                           wbd_mbist8_ack_i; // acknowlegement
wire                           wbd_mbist8_err_i;  // error


wire                           wbd_int_rst_n;
wire                           bist_rst_n;

// MBIST I/F
wire    [7:0]                  bist_en;
wire    [7:0]                  bist_run;
wire    [7:0]                  bist_shift;
wire    [7:0]                  bist_load;
wire    [7:0]                  bist_sdi;

wire    [7:0]                  bist_correct;
wire    [7:0]                  bist_error;
wire    [7:0]                  bist_done;
wire    [7:0]                  bist_sdo;

wire  [3:0]                    bist_error_cnt0;
wire  [3:0]                    bist_error_cnt1;
wire  [3:0]                    bist_error_cnt2;
wire  [3:0]                    bist_error_cnt3;
wire  [3:0]                    bist_error_cnt4;
wire  [3:0]                    bist_error_cnt5;
wire  [3:0]                    bist_error_cnt6;
wire  [3:0]                    bist_error_cnt7;

// MBIST I/F Buffered
wire    [7:0]                  bist_en_int;
wire    [7:0]                  bist_run_int;
wire    [7:0]                  bist_shift_int;
wire    [7:0]                  bist_load_int;
wire    [7:0]                  bist_sdi_int;

wire    [7:0]                  bist_correct_int;
wire    [7:0]                  bist_error_int;
wire    [7:0]                  bist_done_int;
wire    [7:0]                  bist_sdo_int;

wire  [3:0]                    bist_error_cnt0_int;
wire  [3:0]                    bist_error_cnt1_int;
wire  [3:0]                    bist_error_cnt2_int;
wire  [3:0]                    bist_error_cnt3_int;
wire  [3:0]                    bist_error_cnt4_int;
wire  [3:0]                    bist_error_cnt5_int;
wire  [3:0]                    bist_error_cnt6_int;
wire  [3:0]                    bist_error_cnt7_int;

// towards memory MBIST1
// PORT-A
wire                           mem1_clk_a;
wire   [BIST1_ADDR_WD-1:2]     mem1_addr_a;
wire                           mem1_cen_a;
wire   [BIST_DATA_WD-1:0]      mem1_din_b;

// PORT-B
wire                           mem1_clk_b;
wire                           mem1_cen_b;
wire                           mem1_web_b;
wire [BIST_DATA_WD/8-1:0]      mem1_mask_b;
wire [BIST1_ADDR_WD-1:2]       mem1_addr_b;
wire [BIST_DATA_WD-1:0]        mem1_dout_a;

// towards memory MBIST2
// PORT-A
wire                           mem2_clk_a;
wire   [BIST1_ADDR_WD-1:2]     mem2_addr_a;
wire                           mem2_cen_a;
wire   [BIST_DATA_WD-1:0]      mem2_din_b;

// PORT-B
wire                           mem2_clk_b;
wire                           mem2_cen_b;
wire                           mem2_web_b;
wire [BIST_DATA_WD/8-1:0]      mem2_mask_b;
wire [BIST1_ADDR_WD-1:2]       mem2_addr_b;
wire [BIST_DATA_WD-1:0]        mem2_dout_a;

// towards memory MBIST3
// PORT-A
wire                           mem3_clk_a;
wire   [BIST1_ADDR_WD-1:2]     mem3_addr_a;
wire                           mem3_cen_a;
wire   [BIST_DATA_WD-1:0]      mem3_din_b;

// PORT-B
wire                           mem3_clk_b;
wire                           mem3_cen_b;
wire                           mem3_web_b;
wire [BIST_DATA_WD/8-1:0]      mem3_mask_b;
wire [BIST1_ADDR_WD-1:2]       mem3_addr_b;
wire [BIST_DATA_WD-1:0]        mem3_dout_a;

// towards memory MBIST4
// PORT-A
wire                           mem4_clk_a;
wire   [BIST1_ADDR_WD-1:2]     mem4_addr_a;
wire                           mem4_cen_a;
wire   [BIST_DATA_WD-1:0]      mem4_din_b;

// PORT-B
wire                           mem4_clk_b;
wire                           mem4_cen_b;
wire                           mem4_web_b;
wire [BIST_DATA_WD/8-1:0]      mem4_mask_b;
wire [BIST1_ADDR_WD-1:2]       mem4_addr_b;
wire [BIST_DATA_WD-1:0]        mem4_dout_a;

// towards memory MBIST5
// PORT-A
wire                           mem5_clk_a;
wire   [BIST2_ADDR_WD-1:2]     mem5_addr_a;
wire                           mem5_cen_a;
wire   [BIST_DATA_WD-1:0]      mem5_din_b;

// PORT-B
wire                           mem5_clk_b;
wire                           mem5_cen_b;
wire                           mem5_web_b;
wire [BIST_DATA_WD/8-1:0]      mem5_mask_b;
wire [BIST2_ADDR_WD-1:2]       mem5_addr_b;
wire [BIST_DATA_WD-1:0]        mem5_dout_a;

// towards memory MBIST6
// PORT-A
wire                           mem6_clk_a;
wire   [BIST2_ADDR_WD-1:2]     mem6_addr_a;
wire                           mem6_cen_a;
wire   [BIST_DATA_WD-1:0]      mem6_din_b;

// PORT-B
wire                           mem6_clk_b;
wire                           mem6_cen_b;
wire                           mem6_web_b;
wire [BIST_DATA_WD/8-1:0]      mem6_mask_b;
wire [BIST2_ADDR_WD-1:2]       mem6_addr_b;
wire [BIST_DATA_WD-1:0]        mem6_dout_a;

// towards memory MBIST7
// PORT-A
wire                           mem7_clk_a;
wire   [BIST2_ADDR_WD-1:2]     mem7_addr_a;
wire                           mem7_cen_a;
wire   [BIST_DATA_WD-1:0]      mem7_din_b;

// PORT-B
wire                           mem7_clk_b;
wire                           mem7_cen_b;
wire                           mem7_web_b;
wire [BIST_DATA_WD/8-1:0]      mem7_mask_b;
wire [BIST2_ADDR_WD-1:2]       mem7_addr_b;
wire [BIST_DATA_WD-1:0]        mem7_dout_a;

// towards memory MBIST8
// PORT-A
wire                           mem8_clk_a;
wire   [BIST2_ADDR_WD-1:2]     mem8_addr_a;
wire                           mem8_cen_a;
wire   [BIST_DATA_WD-1:0]      mem8_din_b;

// PORT-B
wire                           mem8_clk_b;
wire                           mem8_cen_b;
wire                           mem8_web_b;
wire [BIST_DATA_WD/8-1:0]      mem8_mask_b;
wire [BIST2_ADDR_WD-1:2]       mem8_addr_b;
wire [BIST_DATA_WD-1:0]        mem8_dout_a;

wire                          wbd_clk_wh         ;
wire                          wbd_clk_int        ;
wire                          wbd_clk_glbl_int   ;
wire                          wbd_clk_mbist1_int ;
wire                          wbd_clk_mbist2_int ;
wire                          wbd_clk_mbist3_int ;
wire                          wbd_clk_mbist4_int ;
wire                          wbd_clk_mbist5_int ;
wire                          wbd_clk_mbist6_int ;
wire                          wbd_clk_mbist7_int ;
wire                          wbd_clk_mbist8_int ;
wire                          wbd_clk_wi         ;
wire                          wbd_clk_glbl       ; // clock for global reg
wire                          wbd_clk_mbist1     ; // clock for global reg
wire                          wbd_clk_mbist2     ; // clock for global reg
wire                          wbd_clk_mbist3     ; // clock for global reg
wire                          wbd_clk_mbist4     ; // clock for global reg
wire                          wbd_clk_mbist5     ; // clock for global reg
wire                          wbd_clk_mbist6     ; // clock for global reg
wire                          wbd_clk_mbist7     ; // clock for global reg
wire                          wbd_clk_mbist8     ; // clock for global reg

wire [31:0]                   cfg_clk_ctrl1      ;
wire [31:0]                   cfg_clk_ctrl2      ;
/////////////////////////////////////////////////////////
// Clock Skew Ctrl
////////////////////////////////////////////////////////

wire [3:0] cfg_cska_wh       = cfg_clk_ctrl1[3:0];
wire [3:0] cfg_cska_wi       = cfg_clk_ctrl1[7:4];
wire [3:0] cfg_cska_glbl     = cfg_clk_ctrl1[11:8];

wire [3:0] cfg_cska_mbist1   = cfg_clk_ctrl2[3:0];
wire [3:0] cfg_cska_mbist2   = cfg_clk_ctrl2[7:4];
wire [3:0] cfg_cska_mbist3   = cfg_clk_ctrl2[11:8];
wire [3:0] cfg_cska_mbist4   = cfg_clk_ctrl2[15:12];
wire [3:0] cfg_cska_mbist5   = cfg_clk_ctrl2[19:16];
wire [3:0] cfg_cska_mbist6   = cfg_clk_ctrl2[23:20];
wire [3:0] cfg_cska_mbist7   = cfg_clk_ctrl2[27:24];
wire [3:0] cfg_cska_mbist8   = cfg_clk_ctrl2[31:28];

wb_host u_wb_host(
`ifdef USE_POWER_PINS
         .vccd1         (vccd1                 ),// User area 1 1.8V supply
         .vssd1         (vssd1                 ),// User area 1 digital ground
`endif
        .user_clock1          (wb_clk_i         ),
        .user_clock2          (user_clock2      ),
	.user_irq             (user_irq         ),

    // Master Port
        .wbm_rst_i            (wb_rst_i         ),  
        .wbm_clk_i            (wb_clk_i         ),  
        .wbm_cyc_i            (wbs_cyc_i        ),  
        .wbm_stb_i            (wbs_stb_i        ),  
        .wbm_adr_i            (wbs_adr_i        ),  
        .wbm_we_i             (wbs_we_i         ),  
        .wbm_dat_i            (wbs_dat_i        ),  
        .wbm_sel_i            (wbs_sel_i        ),  
        .wbm_dat_o            (wbs_dat_o        ),  
        .wbm_ack_o            (wbs_ack_o        ),  
        .wbm_err_o            (                 ),  

    // Clock Skeq Adjust
        .wbd_clk_int          (wbd_clk_int      ),
        .wbd_clk_wh           (wbd_clk_wh       ),  
        .cfg_cska_wh          (cfg_cska_wh      ),

    // Slave Port
        .wbs_clk_out          (wbd_clk_int      ),
        .wbs_clk_i            (wbd_clk_wh       ),  
        .wbs_cyc_o            (wbd_int_cyc_i    ),  
        .wbs_stb_o            (wbd_int_stb_i    ),  
        .wbs_adr_o            (wbd_int_adr_i    ),  
        .wbs_we_o             (wbd_int_we_i     ),  
        .wbs_dat_o            (wbd_int_dat_i    ),  
        .wbs_sel_o            (wbd_int_sel_i    ),  
        .wbs_dat_i            (wbd_int_dat_o    ),  
        .wbs_ack_i            (wbd_int_ack_o    ),  
        .wbs_err_i            (wbd_int_err_o    ),  

        .cfg_clk_ctrl1        (cfg_clk_ctrl1    ),
        .cfg_clk_ctrl2        (cfg_clk_ctrl2    ),

        .bist_rst_n           (bist_rst_n       ),
	.wbd_int_rst_n        (wbd_int_rst_n    ),

        .io_in                (io_in[0]         ),
        .io_out               (io_out           ),
        .io_oeb               (io_oeb           ),
       .la_data_in            (la_data_in[17:0] ),
        .la_data_out          (la_data_out      )

    );

wb_interconnect  #(
	`ifndef SYNTHESIS
	        .CH_CLK_WD(9),
	        .CH_DATA_WD(104)
        `endif
	   )
     u_intercon (
`ifdef USE_POWER_PINS
         .vccd1         (vccd1                 ),// User area 1 1.8V supply
         .vssd1         (vssd1                 ),// User area 1 digital ground
`endif
     // Clock Skew adjust
	 .wbd_clk_int   (wbd_clk_int           ), 
	 .cfg_cska_wi   (cfg_cska_wi           ), 
	 .wbd_clk_wi    (wbd_clk_wi            ),

	 .ch_clk_in     ({
	                  wbd_clk_int,
                          wbd_clk_int, 
                          wbd_clk_int, 
                          wbd_clk_int, 
                          wbd_clk_int, 
                          wbd_clk_int, 
                          wbd_clk_int, 
                          wbd_clk_int, 
                          wbd_clk_int}),
	 .ch_clk_out    ({
                         wbd_clk_mbist8_int,  
                         wbd_clk_mbist7_int,  
                         wbd_clk_mbist6_int,  
                         wbd_clk_mbist5_int,  
                         wbd_clk_mbist4_int,  
                         wbd_clk_mbist3_int,  
                         wbd_clk_mbist2_int,  
                         wbd_clk_mbist1_int, 
			 wbd_clk_glbl_int
		         }),
	 .ch_data_in    ({
			 bist_error_cnt7,
			 bist_correct[7],
			 bist_error[7],
			 bist_done[7],
		         bist_sdo[7],
		         bist_sdi[7],
		         bist_load[7],
			 bist_shift[7],
		         bist_run[7],
                         bist_en[7],
			 
			 bist_error_cnt6,
			 bist_correct[6],
			 bist_error[6],
			 bist_done[6],
		         bist_sdo[6],
		         bist_sdi[6],
		         bist_load[6],
			 bist_shift[6],
		         bist_run[6],
                         bist_en[6],
			 
			 bist_error_cnt5,
			 bist_correct[5],
			 bist_error[5],
			 bist_done[5],
		         bist_sdo[5],
		         bist_sdi[5],
		         bist_load[5],
			 bist_shift[5],
		         bist_run[5],
                         bist_en[5],
			 
			 bist_error_cnt4,
			 bist_correct[4],
			 bist_error[4],
			 bist_done[4],
		         bist_sdo[4],
		         bist_sdi[4],
		         bist_load[4],
			 bist_shift[4],
		         bist_run[4],
                         bist_en[4],
			 
			 bist_error_cnt3,
			 bist_correct[3],
			 bist_error[3],
			 bist_done[3],
		         bist_sdo[3],
		         bist_sdi[3],
		         bist_load[3],
			 bist_shift[3],
		         bist_run[3],
                         bist_en[3],
			 
			 bist_error_cnt2,
			 bist_correct[2],
			 bist_error[2],
			 bist_done[2],
		         bist_sdo[2],
		         bist_sdi[2],
		         bist_load[2],
			 bist_shift[2],
		         bist_run[2],
                         bist_en[2],
			 
			 bist_error_cnt1,
			 bist_correct[1],
			 bist_error[1],
			 bist_done[1],
		         bist_sdo[1],
		         bist_sdi[1],
		         bist_load[1],
			 bist_shift[1],
		         bist_run[1],
                         bist_en[1],

			 bist_error_cnt0,
			 bist_correct[0],
			 bist_error[0],
			 bist_done[0],
		         bist_sdo[0],
		         bist_sdi[0],
		         bist_load[0],
			 bist_shift[0],
		         bist_run[0],
                         bist_en[0]
			 } ),
	 .ch_data_out   ({
			 bist_error_cnt7_int,
			 bist_correct_int[7],
			 bist_error_int[7],
			 bist_done_int[7],
		         bist_sdo_int[7],
		         bist_sdi_int[7],
		         bist_load_int[7],
			 bist_shift_int[7],
		         bist_run_int[7],
                         bist_en_int[7],
			 
			 bist_error_cnt6_int,
			 bist_correct_int[6],
			 bist_error_int[6],
			 bist_done_int[6],
		         bist_sdo_int[6],
		         bist_sdi_int[6],
		         bist_load_int[6],
			 bist_shift_int[6],
		         bist_run_int[6],
                         bist_en_int[6],
			 
			 bist_error_cnt5_int,
			 bist_correct_int[5],
			 bist_error_int[5],
			 bist_done_int[5],
		         bist_sdo_int[5],
		         bist_sdi_int[5],
		         bist_load_int[5],
			 bist_shift_int[5],
		         bist_run_int[5],
                         bist_en_int[5],
			 
			 bist_error_cnt4_int,
			 bist_correct_int[4],
			 bist_error_int[4],
			 bist_done_int[4],
		         bist_sdo_int[4],
		         bist_sdi_int[4],
		         bist_load_int[4],
			 bist_shift_int[4],
		         bist_run_int[4],
                         bist_en_int[4],
			 
			 bist_error_cnt3_int,
			 bist_correct_int[3],
			 bist_error_int[3],
			 bist_done_int[3],
		         bist_sdo_int[3],
		         bist_sdi_int[3],
		         bist_load_int[3],
			 bist_shift_int[3],
		         bist_run_int[3],
                         bist_en_int[3],
			 
			 bist_error_cnt2_int,
			 bist_correct_int[2],
			 bist_error_int[2],
			 bist_done_int[2],
		         bist_sdo_int[2],
		         bist_sdi_int[2],
		         bist_load_int[2],
			 bist_shift_int[2],
		         bist_run_int[2],
                         bist_en_int[2],
			 
			 bist_error_cnt1_int,
			 bist_correct_int[1],
			 bist_error_int[1],
			 bist_done_int[1],
		         bist_sdo_int[1],
		         bist_sdi_int[1],
		         bist_load_int[1],
			 bist_shift_int[1],
		         bist_run_int[1],
                         bist_en_int[1],

			 bist_error_cnt0_int,
			 bist_correct_int[0],
			 bist_error_int[0],
			 bist_done_int[0],
		         bist_sdo_int[0],
		         bist_sdi_int[0],
		         bist_load_int[0],
			 bist_shift_int[0],
		         bist_run_int[0],
                         bist_en_int[0]
                         }),

         .clk_i         (wbd_clk_wi            ), 
         .rst_n         (wbd_int_rst_n         ),

         // Master 0 Interface
         .m0_wbd_dat_i  (wbd_int_dat_i         ),
         .m0_wbd_adr_i  (wbd_int_adr_i         ),
         .m0_wbd_sel_i  (wbd_int_sel_i         ),
         .m0_wbd_we_i   (wbd_int_we_i          ),
         .m0_wbd_cyc_i  (wbd_int_cyc_i         ),
         .m0_wbd_stb_i  (wbd_int_stb_i         ),
         .m0_wbd_dat_o  (wbd_int_dat_o         ),
         .m0_wbd_ack_o  (wbd_int_ack_o         ),
         .m0_wbd_err_o  (wbd_int_err_o         ),

         // Slave 0 Interface
         // .s0_wbd_err_i  (1'b0           ), - Moved inside IP
         .s0_wbd_dat_i  (wbd_glbl_dat_i ),
         .s0_wbd_ack_i  (wbd_glbl_ack_i ),
         .s0_wbd_dat_o  (wbd_glbl_dat_o ),
         .s0_wbd_adr_o  (wbd_glbl_adr_o ),
         .s0_wbd_sel_o  (wbd_glbl_sel_o ),
         .s0_wbd_we_o   (wbd_glbl_we_o  ),  
         .s0_wbd_cyc_o  (wbd_glbl_cyc_o ),
         .s0_wbd_stb_o  (wbd_glbl_stb_o ),
         
         // Slave 0 Interface
         // .s0_wbd_err_i  (1'b0           ), - Moved inside IP
         .s1_wbd_dat_i  (wbd_mbist1_dat_i ),
         .s1_wbd_ack_i  (wbd_mbist1_ack_i ),
         .s1_wbd_dat_o  (wbd_mbist1_dat_o ),
         .s1_wbd_adr_o  (wbd_mbist1_adr_o ),
         .s1_wbd_sel_o  (wbd_mbist1_sel_o ),
         .s1_wbd_we_o   (wbd_mbist1_we_o  ),  
         .s1_wbd_cyc_o  (wbd_mbist1_cyc_o ),
         .s1_wbd_stb_o  (wbd_mbist1_stb_o ),
         
         // Slave 1 Interface
         // .s1_wbd_err_i  (1'b0           ), - Moved inside IP
         .s2_wbd_dat_i  (wbd_mbist2_dat_i ),
         .s2_wbd_ack_i  (wbd_mbist2_ack_i ),
         .s2_wbd_dat_o  (wbd_mbist2_dat_o ),
         .s2_wbd_adr_o  (wbd_mbist2_adr_o ),
         .s2_wbd_sel_o  (wbd_mbist2_sel_o ),
         .s2_wbd_we_o   (wbd_mbist2_we_o  ),  
         .s2_wbd_cyc_o  (wbd_mbist2_cyc_o ),
         .s2_wbd_stb_o  (wbd_mbist2_stb_o ),
         
         // Slave 2 Interface
         // .s2_wbd_err_i  (1'b0           ), - Moved inside IP
         .s3_wbd_dat_i  (wbd_mbist3_dat_i ),
         .s3_wbd_ack_i  (wbd_mbist3_ack_i ),
         .s3_wbd_dat_o  (wbd_mbist3_dat_o ),
         .s3_wbd_adr_o  (wbd_mbist3_adr_o ),
         .s3_wbd_sel_o  (wbd_mbist3_sel_o ),
         .s3_wbd_we_o   (wbd_mbist3_we_o  ),  
         .s3_wbd_cyc_o  (wbd_mbist3_cyc_o ),
         .s3_wbd_stb_o  (wbd_mbist3_stb_o ),

         // Slave 3 Interface
         // .s3_wbd_err_i  (1'b0           ), - Moved inside IP
         .s4_wbd_dat_i  (wbd_mbist4_dat_i ),
         .s4_wbd_ack_i  (wbd_mbist4_ack_i ),
         .s4_wbd_dat_o  (wbd_mbist4_dat_o ),
         .s4_wbd_adr_o  (wbd_mbist4_adr_o ),
         .s4_wbd_sel_o  (wbd_mbist4_sel_o ),
         .s4_wbd_we_o   (wbd_mbist4_we_o  ),  
         .s4_wbd_cyc_o  (wbd_mbist4_cyc_o ),
         .s4_wbd_stb_o  (wbd_mbist4_stb_o ),

         // Slave 4 Interface
         // .s0_wbd_err_i  (1'b0           ), - Moved inside IP
         .s5_wbd_dat_i  (wbd_mbist5_dat_i ),
         .s5_wbd_ack_i  (wbd_mbist5_ack_i ),
         .s5_wbd_dat_o  (wbd_mbist5_dat_o ),
         .s5_wbd_adr_o  (wbd_mbist5_adr_o ),
         .s5_wbd_sel_o  (wbd_mbist5_sel_o ),
         .s5_wbd_we_o   (wbd_mbist5_we_o  ),  
         .s5_wbd_cyc_o  (wbd_mbist5_cyc_o ),
         .s5_wbd_stb_o  (wbd_mbist5_stb_o ),
         
         // Slave 5 Interface
         // .s6_wbd_err_i  (1'b0           ), - Moved inside IP
         .s6_wbd_dat_i  (wbd_mbist6_dat_i ),
         .s6_wbd_ack_i  (wbd_mbist6_ack_i ),
         .s6_wbd_dat_o  (wbd_mbist6_dat_o ),
         .s6_wbd_adr_o  (wbd_mbist6_adr_o ),
         .s6_wbd_sel_o  (wbd_mbist6_sel_o ),
         .s6_wbd_we_o   (wbd_mbist6_we_o  ),  
         .s6_wbd_cyc_o  (wbd_mbist6_cyc_o ),
         .s6_wbd_stb_o  (wbd_mbist6_stb_o ),
         
         // Slave 6 Interface
         // .s7_wbd_err_i  (1'b0           ), - Moved inside IP
         .s7_wbd_dat_i  (wbd_mbist7_dat_i ),
         .s7_wbd_ack_i  (wbd_mbist7_ack_i ),
         .s7_wbd_dat_o  (wbd_mbist7_dat_o ),
         .s7_wbd_adr_o  (wbd_mbist7_adr_o ),
         .s7_wbd_sel_o  (wbd_mbist7_sel_o ),
         .s7_wbd_we_o   (wbd_mbist7_we_o  ),  
         .s7_wbd_cyc_o  (wbd_mbist7_cyc_o ),
         .s7_wbd_stb_o  (wbd_mbist7_stb_o ),

         // Slave 7 Interface
         // .s8_wbd_err_i  (1'b0           ), - Moved inside IP
         .s8_wbd_dat_i  (wbd_mbist8_dat_i ),
         .s8_wbd_ack_i  (wbd_mbist8_ack_i ),
         .s8_wbd_dat_o  (wbd_mbist8_dat_o ),
         .s8_wbd_adr_o  (wbd_mbist8_adr_o ),
         .s8_wbd_sel_o  (wbd_mbist8_sel_o ),
         .s8_wbd_we_o   (wbd_mbist8_we_o  ),  
         .s8_wbd_cyc_o  (wbd_mbist8_cyc_o ),
         .s8_wbd_stb_o  (wbd_mbist8_stb_o )
	);


glbl_cfg u_glbl(
`ifdef USE_POWER_PINS
       .vccd1                  (vccd1                     ),// User area 1 1.8V supply
       .vssd1                  (vssd1                     ),// User area 1 digital ground
`endif
       .wbd_clk_int            (wbd_clk_glbl_int          ), 
       .cfg_cska_glbl          (cfg_cska_glbl             ), 
       .wbd_clk_glbl           (wbd_clk_glbl              ), 

       .mclk                   (wbd_clk_glbl              ),
       .reset_n                (wbd_int_rst_n             ),

        // Reg Bus Interface Signal
       .reg_cs                 (wbd_glbl_stb_o            ),
       .reg_wr                 (wbd_glbl_we_o             ),
       .reg_addr               (wbd_glbl_adr_o            ),
       .reg_wdata              (wbd_glbl_dat_o            ),
       .reg_be                 (wbd_glbl_sel_o            ),

       // Outputs
       .reg_rdata              (wbd_glbl_dat_i            ),
       .reg_ack                (wbd_glbl_ack_i            ),


	// BIST I/F Outputs
	.bist_en           (bist_en),
	.bist_run          (bist_run),
	.bist_load         (bist_load),

	.bist_sdi          (bist_sdi),
	.bist_shift        (bist_shift),

	// BIST Inputs
	.bist_sdo          (bist_sdo_int),
	.bist_done         (bist_done_int),
	.bist_error        (bist_error_int),
	.bist_correct      (bist_correct_int),
	.bist_error_cnt0   (bist_error_cnt0_int),
	.bist_error_cnt1   (bist_error_cnt1_int),
	.bist_error_cnt2   (bist_error_cnt2_int),
	.bist_error_cnt3   (bist_error_cnt3_int),
	.bist_error_cnt4   (bist_error_cnt4_int),
	.bist_error_cnt5   (bist_error_cnt5_int),
	.bist_error_cnt6   (bist_error_cnt6_int),
	.bist_error_cnt7   (bist_error_cnt7_int)

        );


//------------- MBIST1 - 512x24             ----

mbist_top1  #(
	`ifndef SYNTHESIS
	.BIST_ADDR_WD           (BIST1_ADDR_WD-2        ),
	.BIST_DATA_WD           (BIST_DATA_WD           ),
	.BIST_ADDR_START        (9'h000                 ),
	.BIST_ADDR_END          (9'h1FB                 ),
	.BIST_REPAIR_ADDR_START (9'h1FC                 ),
	.BIST_RAD_WD_I          (BIST1_ADDR_WD-2        ),
	.BIST_RAD_WD_O          (BIST1_ADDR_WD-2        )
        `endif
     ) 
	     u_mbist1 (

`ifdef USE_POWER_PINS
       .vccd1                  (vccd1                     ),// User area 1 1.8V supply
       .vssd1                  (vssd1                     ),// User area 1 digital ground
`endif

     // Clock Skew adjust
	.wbd_clk_int          (wbd_clk_mbist1_int), 
	.cfg_cska_mbist       (cfg_cska_mbist1  ), 
	.wbd_clk_mbist        (wbd_clk_mbist1   ),

	// WB I/F
        .wb_clk_i             (wbd_clk_mbist1  ),  
        .wb_cyc_i             (wbd_mbist1_cyc_o),  
        .wb_stb_i             (wbd_mbist1_stb_o),  
        .wb_adr_i             (wbd_mbist1_adr_o[BIST1_ADDR_WD-1:2]),  
        .wb_we_i              (wbd_mbist1_we_o ),  
        .wb_dat_i             (wbd_mbist1_dat_o),  
        .wb_sel_i             (wbd_mbist1_sel_o),  
        .wb_dat_o             (wbd_mbist1_dat_i),  
        .wb_ack_o             (wbd_mbist1_ack_i),  
        .wb_err_o             (    ), 

	.rst_n                (bist_rst_n       ),

	
	.bist_en              (bist_en_int[0]       ),
	.bist_run             (bist_run_int[0]      ),
	.bist_shift           (bist_shift_int[0]    ),
	.bist_load            (bist_load_int[0]     ),
	.bist_sdi             (bist_sdi_int[0]      ),

	.bist_error_cnt       (bist_error_cnt0      ),
	.bist_correct         (bist_correct[0]      ),
	.bist_error           (bist_error[0]        ),
	.bist_done            (bist_done[0]         ),
	.bist_sdo             (bist_sdo[0]          ),

     // towards memory
     // PORT-A
        .mem_clk_a            (mem1_clk_a        ),
        .mem_addr_a           (mem1_addr_a       ),
        .mem_cen_a            (mem1_cen_a        ),
        .mem_dout_a           (mem1_dout_a       ),
     // PORT-B
        .mem_clk_b            (mem1_clk_b        ),
        .mem_cen_b            (mem1_cen_b        ),
        .mem_web_b            (mem1_web_b        ),
        .mem_mask_b           (mem1_mask_b       ),
        .mem_addr_b           (mem1_addr_b       ),
        .mem_din_b            (mem1_din_b        )


);

sky130_sram_2kbyte_1rw1r_32x512_8 u_sram1_2kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (mem1_clk_b),
    .csb0     (mem1_cen_b),
    .web0     (mem1_web_b),
    .wmask0   (mem1_mask_b),
    .addr0    (mem1_addr_b),
    .din0     (mem1_din_b),
    .dout0    (),
// Port 1: R
    .clk1     (mem1_clk_a),
    .csb1     (mem1_cen_a),
    .addr1    (mem1_addr_a),
    .dout1    (mem1_dout_a)
  );

//------------- MBIST2 - 512x24             ----

mbist_top1  #(
	`ifndef SYNTHESIS
	.BIST_ADDR_WD           (BIST1_ADDR_WD-2        ),
	.BIST_DATA_WD           (BIST_DATA_WD           ),
	.BIST_ADDR_START        (9'h000                 ),
	.BIST_ADDR_END          (9'h1FB                 ),
	.BIST_REPAIR_ADDR_START (9'h1FC                 ),
	.BIST_RAD_WD_I          (BIST1_ADDR_WD-2        ),
	.BIST_RAD_WD_O          (BIST1_ADDR_WD-2        )
        `endif
     ) 
	     u_mbist2 (
`ifdef USE_POWER_PINS
       .vccd1                  (vccd1                     ),// User area 1 1.8V supply
       .vssd1                  (vssd1                     ),// User area 1 digital ground
`endif

     // Clock Skew adjust
	.wbd_clk_int          (wbd_clk_mbist2_int), 
	.cfg_cska_mbist       (cfg_cska_mbist2  ), 
	.wbd_clk_mbist        (wbd_clk_mbist2   ),

	// WB I/F
        .wb_clk_i             (wbd_clk_mbist2  ),  
        .wb_cyc_i             (wbd_mbist2_cyc_o),  
        .wb_stb_i             (wbd_mbist2_stb_o),  
        .wb_adr_i             (wbd_mbist2_adr_o[BIST1_ADDR_WD-1:2]),  
        .wb_we_i              (wbd_mbist2_we_o ),  
        .wb_dat_i             (wbd_mbist2_dat_o),  
        .wb_sel_i             (wbd_mbist2_sel_o),  
        .wb_dat_o             (wbd_mbist2_dat_i),  
        .wb_ack_o             (wbd_mbist2_ack_i),  
        .wb_err_o             (    ), 

	.rst_n                  (bist_rst_n            ),

	
	.bist_en                (bist_en_int[1]     ),
	.bist_run               (bist_run_int[1]    ),
	.bist_shift             (bist_shift_int[1]  ),
	.bist_load              (bist_load_int[1]   ),
	.bist_sdi               (bist_sdi_int[1]    ),

	.bist_error_cnt         (bist_error_cnt1    ),
	.bist_correct           (bist_correct[1]    ),
	.bist_error             (bist_error[1]      ),
	.bist_done              (bist_done[1]       ),
	.bist_sdo               (bist_sdo[1]        ),

     // towards memory
     // PORT-A
        .mem_clk_a            (mem2_clk_a        ),
        .mem_addr_a           (mem2_addr_a       ),
        .mem_cen_a            (mem2_cen_a        ),
        .mem_dout_a           (mem2_dout_a       ),
     // PORT-B
        .mem_clk_b            (mem2_clk_b        ),
        .mem_cen_b            (mem2_cen_b        ),
        .mem_web_b            (mem2_web_b        ),
        .mem_mask_b           (mem2_mask_b       ),
        .mem_addr_b           (mem2_addr_b       ),
        .mem_din_b            (mem2_din_b        )


);

sky130_sram_2kbyte_1rw1r_32x512_8 u_sram2_2kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (mem2_clk_b),
    .csb0     (mem2_cen_b),
    .web0     (mem2_web_b),
    .wmask0   (mem2_mask_b),
    .addr0    (mem2_addr_b),
    .din0     (mem2_din_b),
    .dout0    (),
// Port 1: R
    .clk1     (mem2_clk_a),
    .csb1     (mem2_cen_a),
    .addr1    (mem2_addr_a),
    .dout1    (mem2_dout_a)
  );

//------------- MBIST3 - 512x24             ----

mbist_top1  #(
	`ifndef SYNTHESIS
	.BIST_ADDR_WD           (BIST1_ADDR_WD-2        ),
	.BIST_DATA_WD           (BIST_DATA_WD           ),
	.BIST_ADDR_START        (9'h000                 ),
	.BIST_ADDR_END          (9'h1FB                 ),
	.BIST_REPAIR_ADDR_START (9'h1FC                 ),
	.BIST_RAD_WD_I          (BIST1_ADDR_WD-2        ),
	.BIST_RAD_WD_O          (BIST1_ADDR_WD-2        )
        `endif
     ) 
	     u_mbist3 (

`ifdef USE_POWER_PINS
       .vccd1                  (vccd1                     ),// User area 1 1.8V supply
       .vssd1                  (vssd1                     ),// User area 1 digital ground
`endif

     // Clock Skew adjust
	.wbd_clk_int          (wbd_clk_mbist3_int      ), 
	.cfg_cska_mbist       (cfg_cska_mbist3  ), 
	.wbd_clk_mbist        (wbd_clk_mbist3   ),

	// WB I/F
        .wb_clk_i             (wbd_clk_mbist3  ),  
        .wb_cyc_i             (wbd_mbist3_cyc_o),  
        .wb_stb_i             (wbd_mbist3_stb_o),  
        .wb_adr_i             (wbd_mbist3_adr_o[BIST1_ADDR_WD-1:2]),  
        .wb_we_i              (wbd_mbist3_we_o ),  
        .wb_dat_i             (wbd_mbist3_dat_o),  
        .wb_sel_i             (wbd_mbist3_sel_o),  
        .wb_dat_o             (wbd_mbist3_dat_i),  
        .wb_ack_o             (wbd_mbist3_ack_i),  
        .wb_err_o             (    ), 

	.rst_n                (bist_rst_n       ),

	
	.bist_en              (bist_en_int[2]   ),
	.bist_run             (bist_run_int[2]  ),
	.bist_shift           (bist_shift_int[2]),
	.bist_load            (bist_load_int[2] ),
	.bist_sdi             (bist_sdi_int[2]  ),

	.bist_error_cnt       (bist_error_cnt2  ),
	.bist_correct         (bist_correct[2]  ),
	.bist_error           (bist_error[2]    ),
	.bist_done            (bist_done[2]     ),
	.bist_sdo             (bist_sdo[2]      ),

     // towards memory
     // PORT-A
        .mem_clk_a            (mem3_clk_a        ),
        .mem_addr_a           (mem3_addr_a       ),
        .mem_cen_a            (mem3_cen_a        ),
        .mem_dout_a           (mem3_dout_a       ),
     // PORT-B
        .mem_clk_b            (mem3_clk_b        ),
        .mem_cen_b            (mem3_cen_b        ),
        .mem_web_b            (mem3_web_b        ),
        .mem_mask_b           (mem3_mask_b       ),
        .mem_addr_b           (mem3_addr_b       ),
        .mem_din_b            (mem3_din_b        )


);

sky130_sram_2kbyte_1rw1r_32x512_8 u_sram3_2kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (mem3_clk_b),
    .csb0     (mem3_cen_b),
    .web0     (mem3_web_b),
    .wmask0   (mem3_mask_b),
    .addr0    (mem3_addr_b),
    .din0     (mem3_din_b),
    .dout0    (),
// Port 1: R
    .clk1     (mem3_clk_a),
    .csb1     (mem3_cen_a),
    .addr1    (mem3_addr_a),
    .dout1    (mem3_dout_a)
  );

//------------- MBIST4 - 512x24             ----

mbist_top1  #(
	`ifndef SYNTHESIS
	.BIST_ADDR_WD           (BIST1_ADDR_WD-2        ),
	.BIST_DATA_WD           (BIST_DATA_WD           ),
	.BIST_ADDR_START        (9'h000                 ),
	.BIST_ADDR_END          (9'h1FB                 ),
	.BIST_REPAIR_ADDR_START (9'h1FC                 ),
	.BIST_RAD_WD_I          (BIST1_ADDR_WD-2        ),
	.BIST_RAD_WD_O          (BIST1_ADDR_WD-2        )
        `endif
     ) 
	     u_mbist4 (
`ifdef USE_POWER_PINS
       .vccd1                  (vccd1                     ),// User area 1 1.8V supply
       .vssd1                  (vssd1                     ),// User area 1 digital ground
`endif

     // Clock Skew adjust
	.wbd_clk_int          (wbd_clk_mbist4_int      ), 
	.cfg_cska_mbist       (cfg_cska_mbist4  ), 
	.wbd_clk_mbist        (wbd_clk_mbist4   ),

	// WB I/F
        .wb_clk_i             (wbd_clk_mbist4  ),  
        .wb_cyc_i             (wbd_mbist4_cyc_o),  
        .wb_stb_i             (wbd_mbist4_stb_o),  
        .wb_adr_i             (wbd_mbist4_adr_o[BIST1_ADDR_WD-1:2]),  
        .wb_we_i              (wbd_mbist4_we_o ),  
        .wb_dat_i             (wbd_mbist4_dat_o),  
        .wb_sel_i             (wbd_mbist4_sel_o),  
        .wb_dat_o             (wbd_mbist4_dat_i),  
        .wb_ack_o             (wbd_mbist4_ack_i),  
        .wb_err_o             (    ), 

	.rst_n                  (bist_rst_n            ),

	
	.bist_en                (bist_en_int[3]        ),
	.bist_run               (bist_run_int[3]       ),
	.bist_shift             (bist_shift_int[3]     ),
	.bist_load              (bist_load_int[3]      ),
	.bist_sdi               (bist_sdi_int[3]       ),

	.bist_error_cnt         (bist_error_cnt3       ),
	.bist_correct           (bist_correct[3]       ),
	.bist_error             (bist_error[3]         ),
	.bist_done              (bist_done[3]          ),
	.bist_sdo               (bist_sdo[3]           ),

     // towards memory
     // PORT-A
        .mem_clk_a            (mem4_clk_a        ),
        .mem_addr_a           (mem4_addr_a       ),
        .mem_cen_a            (mem4_cen_a        ),
        .mem_dout_a           (mem4_dout_a       ),
     // PORT-B
        .mem_clk_b            (mem4_clk_b        ),
        .mem_cen_b            (mem4_cen_b        ),
        .mem_web_b            (mem4_web_b        ),
        .mem_mask_b           (mem4_mask_b       ),
        .mem_addr_b           (mem4_addr_b       ),
        .mem_din_b            (mem4_din_b        )


);

sky130_sram_2kbyte_1rw1r_32x512_8 u_sram4_2kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (mem4_clk_b),
    .csb0     (mem4_cen_b),
    .web0     (mem4_web_b),
    .wmask0   (mem4_mask_b),
    .addr0    (mem4_addr_b),
    .din0     (mem4_din_b),
    .dout0    (),
// Port 1: R
    .clk1     (mem4_clk_a),
    .csb1     (mem4_cen_a),
    .addr1    (mem4_addr_a),
    .dout1    (mem4_dout_a)
  );

//------------- MBIST5 - 256x32             ----

mbist_top2  #(
	`ifndef SYNTHESIS
	.BIST_ADDR_WD           (BIST2_ADDR_WD-2        ),
	.BIST_DATA_WD           (BIST_DATA_WD           ),
	.BIST_ADDR_START        (8'h00                  ),
	.BIST_ADDR_END          (8'hFB                  ),
	.BIST_REPAIR_ADDR_START (8'hFC                  ),
	.BIST_RAD_WD_I          (BIST2_ADDR_WD-2        ),
	.BIST_RAD_WD_O          (BIST2_ADDR_WD-2        )
        `endif
     ) 
	     u_mbist5 (
`ifdef USE_POWER_PINS
       .vccd1                  (vccd1                     ),// User area 1 1.8V supply
       .vssd1                  (vssd1                     ),// User area 1 digital ground
`endif

     // Clock Skew adjust
	.wbd_clk_int          (wbd_clk_mbist5_int      ), 
	.cfg_cska_mbist       (cfg_cska_mbist5  ), 
	.wbd_clk_mbist        (wbd_clk_mbist5   ),

	// WB I/F
        .wb_clk_i             (wbd_clk_mbist5  ),  
        .wb_cyc_i             (wbd_mbist5_cyc_o),  
        .wb_stb_i             (wbd_mbist5_stb_o),  
        .wb_adr_i             (wbd_mbist5_adr_o[BIST2_ADDR_WD-1:2]),  
        .wb_we_i              (wbd_mbist5_we_o ),  
        .wb_dat_i             (wbd_mbist5_dat_o),  
        .wb_sel_i             (wbd_mbist5_sel_o),  
        .wb_dat_o             (wbd_mbist5_dat_i),  
        .wb_ack_o             (wbd_mbist5_ack_i),  
        .wb_err_o             (    ), 

	.rst_n                (bist_rst_n       ),

	
	.bist_en              (bist_en_int[4]   ),
	.bist_run             (bist_run_int[4]  ),
	.bist_shift           (bist_shift_int[4]),
	.bist_load            (bist_load_int[4] ),
	.bist_sdi             (bist_sdi_int[4]  ),

	.bist_error_cnt       (bist_error_cnt4  ),
	.bist_correct         (bist_correct[4]  ),
	.bist_error           (bist_error[4]    ),
	.bist_done            (bist_done[4]     ),
	.bist_sdo             (bist_sdo[4]      ),


     // towards memory
     // PORT-A
        .mem_clk_a            (mem5_clk_a        ),
        .mem_addr_a           (mem5_addr_a       ),
        .mem_cen_a            (mem5_cen_a        ),
        .mem_dout_a           (mem5_dout_a       ),
     // PORT-B
        .mem_clk_b            (mem5_clk_b        ),
        .mem_cen_b            (mem5_cen_b        ),
        .mem_web_b            (mem5_web_b        ),
        .mem_mask_b           (mem5_mask_b       ),
        .mem_addr_b           (mem5_addr_b       ),
        .mem_din_b            (mem5_din_b        )


);

sky130_sram_1kbyte_1rw1r_32x256_8 u_sram5_1kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (mem5_clk_b),
    .csb0     (mem5_cen_b),
    .web0     (mem5_web_b),
    .wmask0   (mem5_mask_b),
    .addr0    (mem5_addr_b),
    .din0     (mem5_din_b),
    .dout0    (),
// Port 1: R
    .clk1     (mem5_clk_a),
    .csb1     (mem5_cen_a),
    .addr1    (mem5_addr_a),
    .dout1    (mem5_dout_a)
  );

//------------- MBIST6 - 256x32             ----

mbist_top2  #(
	`ifndef SYNTHESIS
	.BIST_ADDR_WD           (BIST2_ADDR_WD-2        ),
	.BIST_DATA_WD           (BIST_DATA_WD           ),
	.BIST_ADDR_START        (8'h00                  ),
	.BIST_ADDR_END          (8'hFB                  ),
	.BIST_REPAIR_ADDR_START (8'hFC                  ),
	.BIST_RAD_WD_I          (BIST2_ADDR_WD-2        ),
	.BIST_RAD_WD_O          (BIST2_ADDR_WD-2        )
        `endif
     ) 
	     u_mbist6 (
`ifdef USE_POWER_PINS
       .vccd1                  (vccd1                     ),// User area 1 1.8V supply
       .vssd1                  (vssd1                     ),// User area 1 digital ground
`endif

     // Clock Skew adjust
	.wbd_clk_int          (wbd_clk_mbist6_int      ), 
	.cfg_cska_mbist       (cfg_cska_mbist6  ), 
	.wbd_clk_mbist        (wbd_clk_mbist6   ),

	// WB I/F
        .wb_clk_i             (wbd_clk_mbist6  ),  
        .wb_cyc_i             (wbd_mbist6_cyc_o),  
        .wb_stb_i             (wbd_mbist6_stb_o),  
        .wb_adr_i             (wbd_mbist6_adr_o[BIST2_ADDR_WD-1:2]),  
        .wb_we_i              (wbd_mbist6_we_o ),  
        .wb_dat_i             (wbd_mbist6_dat_o),  
        .wb_sel_i             (wbd_mbist6_sel_o),  
        .wb_dat_o             (wbd_mbist6_dat_i),  
        .wb_ack_o             (wbd_mbist6_ack_i),  
        .wb_err_o             (    ), 

	.rst_n                (bist_rst_n       ),

	
	.bist_en              (bist_en_int[5]   ),
	.bist_run             (bist_run_int[5]  ),
	.bist_shift           (bist_shift_int[5]),
	.bist_load            (bist_load_int[5] ),
	.bist_sdi             (bist_sdi_int[5]  ),

	.bist_error_cnt       (bist_error_cnt5  ),
	.bist_correct         (bist_correct[5]  ),
	.bist_error           (bist_error[5]    ),
	.bist_done            (bist_done[5]     ),
	.bist_sdo             (bist_sdo[5]      ),

     // towards memory
     // PORT-A
        .mem_clk_a            (mem6_clk_a        ),
        .mem_addr_a           (mem6_addr_a       ),
        .mem_cen_a            (mem6_cen_a        ),
        .mem_dout_a           (mem6_dout_a       ),
     // PORT-B
        .mem_clk_b            (mem6_clk_b        ),
        .mem_cen_b            (mem6_cen_b        ),
        .mem_web_b            (mem6_web_b        ),
        .mem_mask_b           (mem6_mask_b       ),
        .mem_addr_b           (mem6_addr_b       ),
        .mem_din_b            (mem6_din_b        )


);

sky130_sram_1kbyte_1rw1r_32x256_8 u_sram6_1kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (mem6_clk_b),
    .csb0     (mem6_cen_b),
    .web0     (mem6_web_b),
    .wmask0   (mem6_mask_b),
    .addr0    (mem6_addr_b),
    .din0     (mem6_din_b),
    .dout0    (),
// Port 1: R
    .clk1     (mem6_clk_a),
    .csb1     (mem6_cen_a),
    .addr1    (mem6_addr_a),
    .dout1    (mem6_dout_a)
  );
//------------- MBIST7 - 256x32             ----

mbist_top2  #(
	`ifndef SYNTHESIS
	.BIST_ADDR_WD           (BIST2_ADDR_WD-2        ),
	.BIST_DATA_WD           (BIST_DATA_WD           ),
	.BIST_ADDR_START        (8'h00                  ),
	.BIST_ADDR_END          (8'hFB                  ),
	.BIST_REPAIR_ADDR_START (8'hFC                  ),
	.BIST_RAD_WD_I          (BIST2_ADDR_WD-2        ),
	.BIST_RAD_WD_O          (BIST2_ADDR_WD-2        )
        `endif
     ) 
	     u_mbist7 (
`ifdef USE_POWER_PINS
       .vccd1                  (vccd1                     ),// User area 1 1.8V supply
       .vssd1                  (vssd1                     ),// User area 1 digital ground
`endif

     // Clock Skew adjust
	.wbd_clk_int          (wbd_clk_mbist7_int      ), 
	.cfg_cska_mbist       (cfg_cska_mbist7  ), 
	.wbd_clk_mbist        (wbd_clk_mbist7   ),

	// WB I/F
        .wb_clk_i             (wbd_clk_mbist7  ),  
        .wb_cyc_i             (wbd_mbist7_cyc_o),  
        .wb_stb_i             (wbd_mbist7_stb_o),  
        .wb_adr_i             (wbd_mbist7_adr_o[BIST2_ADDR_WD-1:2]),  
        .wb_we_i              (wbd_mbist7_we_o ),  
        .wb_dat_i             (wbd_mbist7_dat_o),  
        .wb_sel_i             (wbd_mbist7_sel_o),  
        .wb_dat_o             (wbd_mbist7_dat_i),  
        .wb_ack_o             (wbd_mbist7_ack_i),  
        .wb_err_o             (    ), 

	.rst_n                (bist_rst_n       ),

	
	.bist_en              (bist_en_int[6]   ),
	.bist_run             (bist_run_int[6]  ),
	.bist_shift           (bist_shift_int[6]),
	.bist_load            (bist_load_int[6] ),
	.bist_sdi             (bist_sdi_int[6]  ),

	.bist_error_cnt       (bist_error_cnt6  ),
	.bist_correct         (bist_correct[6]  ),
	.bist_error           (bist_error[6]    ),
	.bist_done            (bist_done[6]     ),
	.bist_sdo             (bist_sdo[6]      ),


     // towards memory
     // PORT-A
        .mem_clk_a            (mem7_clk_a        ),
        .mem_addr_a           (mem7_addr_a       ),
        .mem_cen_a            (mem7_cen_a        ),
        .mem_dout_a           (mem7_dout_a       ),
     // PORT-B
        .mem_clk_b            (mem7_clk_b        ),
        .mem_cen_b            (mem7_cen_b        ),
        .mem_web_b            (mem7_web_b        ),
        .mem_mask_b           (mem7_mask_b       ),
        .mem_addr_b           (mem7_addr_b       ),
        .mem_din_b            (mem7_din_b        )


);

sky130_sram_1kbyte_1rw1r_32x256_8 u_sram7_1kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (mem7_clk_b),
    .csb0     (mem7_cen_b),
    .web0     (mem7_web_b),
    .wmask0   (mem7_mask_b),
    .addr0    (mem7_addr_b),
    .din0     (mem7_din_b),
    .dout0    (),
// Port 1: R
    .clk1     (mem7_clk_a),
    .csb1     (mem7_cen_a),
    .addr1    (mem7_addr_a),
    .dout1    (mem7_dout_a)
  );

//------------- MBIST6 - 256x32             ----

mbist_top2  #(
	`ifndef SYNTHESIS
	.BIST_ADDR_WD           (BIST2_ADDR_WD-2        ),
	.BIST_DATA_WD           (BIST_DATA_WD           ),
	.BIST_ADDR_START        (8'h00                  ),
	.BIST_ADDR_END          (8'hFB                  ),
	.BIST_REPAIR_ADDR_START (8'hFC                  ),
	.BIST_RAD_WD_I          (BIST2_ADDR_WD-2        ),
	.BIST_RAD_WD_O          (BIST2_ADDR_WD-2        )
        `endif
     ) 
	     u_mbist8 (
`ifdef USE_POWER_PINS
       .vccd1                  (vccd1                     ),// User area 1 1.8V supply
       .vssd1                  (vssd1                     ),// User area 1 digital ground
`endif

     // Clock Skew adjust
	.wbd_clk_int          (wbd_clk_mbist8_int), 
	.cfg_cska_mbist       (cfg_cska_mbist8  ), 
	.wbd_clk_mbist        (wbd_clk_mbist8   ),

	// WB I/F
        .wb_clk_i             (wbd_clk_mbist8  ),  
        .wb_cyc_i             (wbd_mbist8_cyc_o),  
        .wb_stb_i             (wbd_mbist8_stb_o),  
        .wb_adr_i             (wbd_mbist8_adr_o[BIST2_ADDR_WD-1:2]),  
        .wb_we_i              (wbd_mbist8_we_o ),  
        .wb_dat_i             (wbd_mbist8_dat_o),  
        .wb_sel_i             (wbd_mbist8_sel_o),  
        .wb_dat_o             (wbd_mbist8_dat_i),  
        .wb_ack_o             (wbd_mbist8_ack_i),  
        .wb_err_o             (    ), 

	.rst_n                (bist_rst_n       ),

	
	.bist_en              (bist_en_int[7]   ),
	.bist_run             (bist_run_int[7]  ),
	.bist_shift           (bist_shift_int[7]),
	.bist_load            (bist_load_int[7] ),
	.bist_sdi             (bist_sdi_int[7]  ),

	.bist_error_cnt       (bist_error_cnt7  ),
	.bist_correct         (bist_correct[7]  ),
	.bist_error           (bist_error[7]    ),
	.bist_done            (bist_done[7]     ),
	.bist_sdo             (bist_sdo[7]      ),

     // towards memory
     // PORT-A
        .mem_clk_a            (mem8_clk_a        ),
        .mem_addr_a           (mem8_addr_a       ),
        .mem_cen_a            (mem8_cen_a        ),
        .mem_dout_a           (mem8_dout_a       ),
     // PORT-B
        .mem_clk_b            (mem8_clk_b        ),
        .mem_cen_b            (mem8_cen_b        ),
        .mem_web_b            (mem8_web_b        ),
        .mem_mask_b           (mem8_mask_b       ),
        .mem_addr_b           (mem8_addr_b       ),
        .mem_din_b            (mem8_din_b        )


);

sky130_sram_1kbyte_1rw1r_32x256_8 u_sram8_1kb(
`ifdef USE_POWER_PINS
    .vccd1 (vccd1),// User area 1 1.8V supply
    .vssd1 (vssd1),// User area 1 digital ground
`endif
// Port 0: RW
    .clk0     (mem8_clk_b),
    .csb0     (mem8_cen_b),
    .web0     (mem8_web_b),
    .wmask0   (mem8_mask_b),
    .addr0    (mem8_addr_b),
    .din0     (mem8_din_b),
    .dout0    (),
// Port 1: R
    .clk1     (mem8_clk_a),
    .csb1     (mem8_cen_a),
    .addr1    (mem8_addr_a),
    .dout1    (mem8_dout_a)
  );

endmodule	// user_project_wrapper

`default_nettype wire
