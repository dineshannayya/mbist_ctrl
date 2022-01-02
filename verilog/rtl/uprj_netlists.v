// SPDX-FileCopyrightText: 2020 Efabless Corporation
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

// Include caravel global defines for the number of the user project IO pads 
`include "defines.v"
`define USE_POWER_PINS
`define UNIT_DELAY #0.1

`ifdef GL
    // Assume default net type to be wire because GL netlists don't have the wire definitions
    `default_nettype wire
    `include "gl/user_project_wrapper.v"
    `include "gl/user_proj_example.v"
`else
     `include "libs.ref/sky130_fd_sc_hd/verilog/primitives.v"
     `include "libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"
     `include "libs.ref/sky130_fd_sc_hvl/verilog/primitives.v"
     `include "libs.ref/sky130_fd_sc_hvl/verilog/sky130_fd_sc_hvl.v"

     `include "user_project_wrapper.v"


    `include "mbist/src/core/mbist_addr_gen.sv"
    `include "mbist/src/core/mbist_fsm.sv" 
    `include "mbist/src/core/mbist_op_sel.sv" 
    `include "mbist/src/core/mbist_repair_addr.sv" 
    `include "mbist/src/core/mbist_sti_sel.sv" 
    `include "mbist/src/core/mbist_pat_sel.sv"
    `include "mbist/src/core/mbist_mux.sv"
    `include "mbist/src/core/mbist_data_cmp.sv"
    `include "mbist/src/core/mbist_mem_wrapper.sv"

    `include "mbist/src/top/mbist_top1.sv" 
    `include "mbist/src/top/mbist_top2.sv" 

    `include "wb_host/src/wb_host.sv"
    `include "lib/async_fifo.sv"
    `include "lib/async_wb.sv"
    `include "lib/registers.v"
    `include "lib/clk_ctl.v"
    `include "lib/reset_sync.sv"
    `include "lib/ser_inf_32b.sv"
    `include "lib/ctech_cells.sv"
     
    `include "lib/wb_stagging.sv"
    `include "wb_interconnect/src/wb_interconnect.sv"
    `include "glbl/src/glbl_cfg.sv"

     `include "uart/src/uart_core.sv"
     `include "uart/src/uart_cfg.sv"
     `include "uart/src/uart_rxfsm.sv"
     `include "uart/src/uart_txfsm.sv"
     `include "lib/async_fifo_th.sv"  
     `include "lib/double_sync_low.v"  
     `include "lib/clk_buf.v"  
     `include "lib/wb_arb.sv"

    `include "uart2wb/src/uart2wb.sv" 
    `include "uart2wb/src/uart2_core.sv" 
    `include "uart2wb/src/uart_msg_handler.v" 
    `include "lib/async_reg_bus.sv"

    `include "clk_skew_adjust/src/clk_skew_adjust.v"
    `include "sram_macros/sky130_sram_2kbyte_1rw1r_32x512_8.v"
    `include "sram_macros/sky130_sram_1kbyte_1rw1r_32x256_8.v"

`endif
