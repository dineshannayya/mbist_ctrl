###############################################################################
# Created by write_sdc
# Fri Nov 12 05:00:05 2021
###############################################################################
current_design wb_interconnect
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk_i -period 10.0000 [get_ports {clk_i}]
set_clock_uncertainty -rise_from [get_clocks {clk_i}] -rise_to [get_clocks {clk_i}]  -hold  0.2500
set_clock_uncertainty -rise_from [get_clocks {clk_i}] -rise_to [get_clocks {clk_i}]  -setup 0.2500
set_clock_uncertainty -rise_from [get_clocks {clk_i}] -fall_to [get_clocks {clk_i}]  -hold  0.2500
set_clock_uncertainty -rise_from [get_clocks {clk_i}] -fall_to [get_clocks {clk_i}]  -setup 0.2500
set_clock_uncertainty -fall_from [get_clocks {clk_i}] -rise_to [get_clocks {clk_i}]  -hold  0.2500
set_clock_uncertainty -fall_from [get_clocks {clk_i}] -rise_to [get_clocks {clk_i}]  -setup 0.2500
set_clock_uncertainty -fall_from [get_clocks {clk_i}] -fall_to [get_clocks {clk_i}]  -hold  0.2500
set_clock_uncertainty -fall_from [get_clocks {clk_i}] -fall_to [get_clocks {clk_i}]  -setup 0.2500

set ::env(SYNTH_TIMING_DERATE) 0.05
puts "\[INFO\]: Setting timing derate to: [expr {$::env(SYNTH_TIMING_DERATE) * 10}] %"
set_timing_derate -early [expr {1-$::env(SYNTH_TIMING_DERATE)}]
set_timing_derate -late [expr {1+$::env(SYNTH_TIMING_DERATE)}]

set_case_analysis 0 [get_ports {cfg_cska_wi[0]}]
set_case_analysis 0 [get_ports {cfg_cska_wi[1]}]
set_case_analysis 0 [get_ports {cfg_cska_wi[2]}]
set_case_analysis 0 [get_ports {cfg_cska_wi[3]}]

#Static Signal Clock Skew adjustment
set_false_path -from [get_ports {cfg_cska_wi[0]}]
set_false_path -from [get_ports {cfg_cska_wi[1]}]
set_false_path -from [get_ports {cfg_cska_wi[2]}]
set_false_path -from [get_ports {cfg_cska_wi[3]}]

# Set max delay for clock skew
set_max_delay   3.5 -from [get_ports {wbd_clk_int}]
set_max_delay   2 -to   [get_ports {wbd_clk_wi}]
set_max_delay 3.5 -from wbd_clk_int -to wbd_clk_wi
##
set_input_delay -max 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {rst_n}]

set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {m0_wbd_adr_i[*]}]
set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {m0_wbd_dat_i[*]}]
set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {m0_wbd_sel_i[*]}]
set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s0_wbd_ack_i}]
set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s0_wbd_dat_i[*]}]
set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s1_wbd_ack_i}]
set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s1_wbd_dat_i[*]}]
set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s2_wbd_ack_i}]
set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s2_wbd_dat_i[*]}]
set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s3_wbd_ack_i}]
set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s3_wbd_ack_i}]
set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s4_wbd_dat_i[*]}]
set_input_delay -max 6.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s4_wbd_dat_i[*]}]

set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {m0_wbd_adr_i[*]}]
set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {m0_wbd_dat_i[*]}]
set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {m0_wbd_sel_i[*]}]
set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s0_wbd_ack_i}]
set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s0_wbd_dat_i[*]}]
set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s1_wbd_ack_i}]
set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s1_wbd_dat_i[*]}]
set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s2_wbd_ack_i}]
set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s2_wbd_dat_i[*]}]
set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s3_wbd_ack_i}]
set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s3_wbd_dat_i[*]}]
set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s4_wbd_ack_i}]
set_input_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s4_wbd_dat_i[*]}]

set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {m0_wbd_ack_o}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {m0_wbd_dat_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {m0_wbd_err_o}]

set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s0_wbd_adr_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s0_wbd_cyc_o}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s0_wbd_dat_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s0_wbd_sel_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s0_wbd_we_o}]

set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s1_wbd_adr_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s1_wbd_cyc_o}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s1_wbd_dat_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s1_wbd_sel_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s1_wbd_we_o}]

set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s2_wbd_adr_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s2_wbd_cyc_o}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s2_wbd_dat_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s2_wbd_sel_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s2_wbd_we_o}]

set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s3_wbd_adr_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s3_wbd_cyc_o}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s3_wbd_dat_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s3_wbd_sel_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s3_wbd_we_o}]

set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s4_wbd_adr_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s4_wbd_cyc_o}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s4_wbd_dat_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s4_wbd_sel_o[*]}]
set_output_delay -max 4.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s4_wbd_we_o}]

set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {m0_wbd_ack_o}]
set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {m0_wbd_dat_o[*]}]
set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {m0_wbd_err_o}]

set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s0_wbd_adr_o[*]}]
set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s0_wbd_cyc_o}]
set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s0_wbd_dat_o[*]}]

set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s1_wbd_adr_o[*]}]
set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s1_wbd_cyc_o}]
set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s1_wbd_dat_o[*]}]

set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s2_wbd_adr_o[*]}]
set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s2_wbd_cyc_o}]
set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s2_wbd_dat_o[*]}]

set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s3_wbd_adr_o[*]}]
set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s3_wbd_cyc_o}]
set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s3_wbd_dat_o[*]}]

set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s4_wbd_adr_o[*]}]
set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s4_wbd_cyc_o}]
set_output_delay -min 2.0000 -clock [get_clocks {clk_i}] -add_delay [get_ports {s4_wbd_dat_o[*]}]


###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.0334 [get_ports {m0_wbd_ack_o}]
set_load -pin_load 0.0334 [get_ports {m0_wbd_err_o}]
set_load -pin_load 0.0334 [get_ports {s0_wbd_cyc_o}]
set_load -pin_load 0.0334 [get_ports {s0_wbd_stb_o}]
set_load -pin_load 0.0334 [get_ports {s0_wbd_we_o}]
set_load -pin_load 0.0334 [get_ports {s1_wbd_cyc_o}]
set_load -pin_load 0.0334 [get_ports {s1_wbd_stb_o}]
set_load -pin_load 0.0334 [get_ports {s1_wbd_we_o}]
set_load -pin_load 0.0334 [get_ports {s2_wbd_cyc_o}]
set_load -pin_load 0.0334 [get_ports {s2_wbd_stb_o}]
set_load -pin_load 0.0334 [get_ports {s2_wbd_we_o}]
set_load -pin_load 0.0334 [get_ports {s3_wbd_cyc_o}]
set_load -pin_load 0.0334 [get_ports {s3_wbd_stb_o}]
set_load -pin_load 0.0334 [get_ports {s3_wbd_we_o}]
set_load -pin_load 0.0334 [get_ports {s4_wbd_cyc_o}]
set_load -pin_load 0.0334 [get_ports {s4_wbd_stb_o}]
set_load -pin_load 0.0334 [get_ports {s4_wbd_we_o}]
set_load -pin_load 0.0334 [get_ports {wbd_clk_wi}]
set_load -pin_load 0.0334 [get_ports {m0_wbd_dat_o[*]}]
set_load -pin_load 0.0334 [get_ports {s0_wbd_adr_o[*]}]
set_load -pin_load 0.0334 [get_ports {s0_wbd_dat_o[*]}]
set_load -pin_load 0.0334 [get_ports {s0_wbd_sel_o[*]}]

set_load -pin_load 0.0334 [get_ports {s1_wbd_adr_o[*]}]
set_load -pin_load 0.0334 [get_ports {s1_wbd_dat_o[*]}]
set_load -pin_load 0.0334 [get_ports {s1_wbd_sel_o[*]}]

set_load -pin_load 0.0334 [get_ports {s2_wbd_adr_o[*]}]
set_load -pin_load 0.0334 [get_ports {s2_wbd_dat_o[*]}]
set_load -pin_load 0.0334 [get_ports {s2_wbd_sel_o[*]}]

set_load -pin_load 0.0334 [get_ports {s3_wbd_adr_o[*]}]
set_load -pin_load 0.0334 [get_ports {s3_wbd_dat_o[*]}]
set_load -pin_load 0.0334 [get_ports {s3_wbd_sel_o[*]}]

set_load -pin_load 0.0334 [get_ports {s4_wbd_adr_o[*]}]
set_load -pin_load 0.0334 [get_ports {s4_wbd_dat_o[*]}]
set_load -pin_load 0.0334 [get_ports {s4_wbd_sel_o[*]}]

set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {clk_i}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {m0_wbd_cyc_i}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {m0_wbd_stb_i}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {m0_wbd_we_i}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {m0_wbd_adr_i[*]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {m0_wbd_dat_i[*]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {rst_n}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {wbd_clk_int}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {cfg_cska_wi[*]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {s0_wbd_dat_i[*]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {s0_wbd_ack_i}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {s1_wbd_dat_i[*]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {s1_wbd_ack_i}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {s2_wbd_dat_i[*]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {s2_wbd_ack_i}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {s3_wbd_dat_i[*]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {s3_wbd_ack_i}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {s4_wbd_dat_i[*]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_8 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {s4_wbd_ack_i}]
###############################################################################
# Design Rules
###############################################################################
