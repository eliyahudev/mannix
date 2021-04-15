
# XM-Sim Command File
# TOOL:	xmsim(64)	19.03-s013
#
#
# You can restore this configuration with:
#
#      xrun -sv ../rtl/activation.sv ../rtl/cnn_activation.sv ../rtl/cnn.sv ../rtl/dot_product_parallel.sv ../rtl/dot_product.sv ../rtl/fcc.sv ../rtl/fifo.sv ../rtl/mannix_mem_farm.sv ../rtl/mannix.sv ../rtl/mem_align.sv ../rtl/mem_arbiter.sv ../rtl/mem_ctrl.sv ../rtl/mem_demux.sv ../rtl/mem_fabric.sv ../rtl/mem_intf_read.sv ../rtl/mem_intf_write.sv ../rtl/mem_req_ctrl.sv ../rtl/mem_sram.sv ../rtl/pool.sv ../rtl/sort_4.sv ../rtl/sort_8.sv ../rtl/sort_xy.sv ../rtl/mem_intf.svh ../tb/acc_mem_wrap_tb.sv +incdir+../rtl/ -debug -input input/mem_acc.tcl -input /project/generic/users/gerners/ws/mannix/tb/input/restore.tcl
#

set tcl_prompt1 {puts -nonewline "xcelium> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
alias . run
alias quit exit
database -open -shm -into waves.shm waves -default -event
probe -create -packed 262144 -database waves acc_mem_wrap_tb -all -depth all
probe -create -database waves acc_mem_wrap_tb -assertions -transaction -depth all
probe -create -packed 262144 -database waves acc_mem_wrap_tb -all -memories -depth all
probe -create -database waves acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.intf_in[5]
probe -create -database waves acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.intf_out[5]
probe -create -database waves acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.intf_in[10]
probe -create -database waves acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.intf_out[10]
probe -create -database waves acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.addr_temp_buf acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.clk acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.data_in acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.data_out acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.data_read_align acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.data_write_align acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.first_data_out acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.first_data_out_mask acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.first_read_gnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.first_read_gnt_s acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.first_write_gnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.first_write_gnt_s acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.gnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.mask acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.mask_enable acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.new_read_req acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.new_write_req acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.next_state acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.num_bytes_first_data_out acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.num_bytes_second_data_out acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.num_bytes_temp_buf acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.read_bytes_s acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.read_gnt_cnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.read_gnt_cnt_s acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.read_prior acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.read_sram acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.req acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.req_data_stored_temp_buf acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.req_sram acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.rst_n acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.second_data_out acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.second_read_gnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.second_read_gnt_s acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.second_write_gnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.second_write_gnt_s acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.state acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.two_read_req acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.two_read_req_need_one acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.two_write_req acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.which_sram acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.which_sram_sec acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.write_gnt_cnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.write_sram
probe -create -packed 262144 -database waves acc_mem_wrap_tb.mannix_mem_farm_ins.loop[1].i_mem_sram.mem

simvision -input input/restore.tcl.svcf
