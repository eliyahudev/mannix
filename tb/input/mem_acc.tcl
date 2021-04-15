
# XM-Sim Command File
# TOOL:	xmsim(64)	19.03-s013
#
#
# You can restore this configuration with:
#
#      xrun -sv activation.sv cnn_activation.sv cnn.sv dot_product_parallel.sv dot_product.sv fcc.sv fifo.sv mannix_mem_farm.sv mannix.sv mem_align.sv mem_arbiter.sv mem_ctrl.sv mem_demux.sv mem_fabric.sv mem_intf_read.sv mem_intf_write.sv mem_req_ctrl.sv mem_sram.sv pool.sv sort_4.sv sort_8.sv sort_xy.sv mem_intf.svh ../tb/acc_mem_wrap_tb.sv -debug -input /project/generic/users/gerners/ws/mannix/tb/restore.tcl
#
database -open -shm -into waves.shm waves -default -event
probe -create -database waves acc_mem_wrap_tb -all -depth all
probe -create -database waves acc_mem_wrap_tb -assertions -transaction -depth all
probe -create -database waves acc_mem_wrap_tb -all -memories -depth all
probe -create -packed 5344 -database waves acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.intf_in[10]
probe -create -database waves acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.intf_out[10]
probe -create -packed 5344 -database waves acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.intf_in[5]
probe -create -database waves acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.intf_out[5]
probe -create -database waves acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.addr_temp_buf acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.clk acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.data_in acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.data_out acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.data_read_align acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.data_write_align acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.first_data_out acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.first_data_out_mask acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.first_read_gnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.first_read_gnt_s acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.first_write_gnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.first_write_gnt_s acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.intf_in[10] acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.intf_out[10] acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.gnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.mask acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.mask_enable acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.new_read_req acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.new_write_req acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.next_state acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.num_bytes_first_data_out acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.num_bytes_second_data_out acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.num_bytes_temp_buf acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.read_bytes_s acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.read_gnt_cnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.read_gnt_cnt_s acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.read_prior acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.read_sram acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.req acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.req_data_stored_temp_buf acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.req_sram acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.rst_n acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.second_data_out acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.second_read_gnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.second_read_gnt_s acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.second_write_gnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.second_write_gnt_s acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.state acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.two_read_req acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.two_read_req_need_one acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.two_write_req acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.which_sram acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.which_sram_sec acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.write_gnt_cnt acc_mem_wrap_tb.mannix_mem_farm_ins.i_req_ctrl.write_sram

probe -create -packed 262144 -database waves acc_mem_wrap_tb.mannix_mem_farm_ins.loop[1].i_mem_sram.mem
simvision -input input/mem_acc.tcl.svcf
