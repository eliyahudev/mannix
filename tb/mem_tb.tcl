database -open -shm -into waves.shm waves -default -event
probe -create -database waves manix_mem_farm_tb -all -depth all
probe -create -database waves manix_mem_farm_tb -assertions -transaction -depth all
probe -create -database waves manix_mem_farm_tb -all -memories -depth all
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[0].i_mem_sram.mem[0]
probe -create -database waves manix_mem_farm_tb.i_mannix_mem_farm.loop[1].i_mem_sram.mem[0]
