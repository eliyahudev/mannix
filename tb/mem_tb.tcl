database -open -shm -into waves.shm waves -default -event
probe -create -database waves manix_mem_farm_tb -all -depth all
probe -create -database waves manix_mem_farm_tb -assertions -transaction -depth all
probe -create -database waves manix_mem_farm_tb -all -memories -depth all
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[0].i_mem_sram.mem[0]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[1].i_mem_sram.mem[0]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[0].i_mem_sram.mem[1]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[1].i_mem_sram.mem[1]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[0].i_mem_sram.mem[2]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[1].i_mem_sram.mem[2]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[0].i_mem_sram.mem[3]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[1].i_mem_sram.mem[3]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[0].i_mem_sram.mem[4]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[1].i_mem_sram.mem[4]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[0].i_mem_sram.mem[5]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[1].i_mem_sram.mem[5]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[0].i_mem_sram.mem[6]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[1].i_mem_sram.mem[6]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[0].i_mem_sram.mem[7]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[1].i_mem_sram.mem[7]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[0].i_mem_sram.mem[8]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[1].i_mem_sram.mem[8]


simvision -input ../tb/mem_tb.tcl.svcf
