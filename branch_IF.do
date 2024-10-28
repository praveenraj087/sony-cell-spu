onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_InstructionFetch/ins_fetch/clk
add wave -noupdate /tb_InstructionFetch/ins_fetch/reset
add wave -noupdate /tb_InstructionFetch/ins_fetch/ins_cache
add wave -noupdate -expand /tb_InstructionFetch/ins_fetch/instr_d
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/finished
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/first_odd
add wave -noupdate /tb_InstructionFetch/ins_fetch/stall
add wave -noupdate /tb_InstructionFetch/ins_fetch/read_enable
add wave -noupdate -radix decimal /tb_InstructionFetch/ins_fetch/pc
add wave -noupdate -radix decimal /tb_InstructionFetch/ins_fetch/pc_wb
add wave -noupdate -radix decimal /tb_InstructionFetch/ins_fetch/pc_check
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/instr_even
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/instr_odd
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/pipe/branch_taken
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/pipe/ev/fp1/rt_delay
add wave -noupdate -radix unsigned /tb_InstructionFetch/ins_fetch/decode/pipe/ev/fp1/rt_addr_delay
add wave -noupdate -radix binary /tb_InstructionFetch/ins_fetch/decode/pipe/ev/fp1/reg_write_delay
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/pipe/ev/fx2/rt_delay
add wave -noupdate -radix unsigned /tb_InstructionFetch/ins_fetch/decode/pipe/ev/fx2/rt_addr_delay
add wave -noupdate -radix binary /tb_InstructionFetch/ins_fetch/decode/pipe/ev/fx2/reg_write_delay
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/pipe/ev/b1/rt_delay
add wave -noupdate -radix unsigned /tb_InstructionFetch/ins_fetch/decode/pipe/ev/b1/rt_addr_delay
add wave -noupdate -radix binary /tb_InstructionFetch/ins_fetch/decode/pipe/ev/b1/reg_write_delay
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/pipe/ev/fx1/rt_delay
add wave -noupdate -radix unsigned /tb_InstructionFetch/ins_fetch/decode/pipe/ev/fx1/rt_addr_delay
add wave -noupdate -radix binary /tb_InstructionFetch/ins_fetch/decode/pipe/ev/fx1/reg_write_delay
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/pipe/od/p1/rt_delay
add wave -noupdate -radix unsigned /tb_InstructionFetch/ins_fetch/decode/pipe/od/p1/rt_addr_delay
add wave -noupdate -radix binary /tb_InstructionFetch/ins_fetch/decode/pipe/od/p1/reg_write_delay
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/pipe/od/ls1/rt_delay
add wave -noupdate -radix unsigned /tb_InstructionFetch/ins_fetch/decode/pipe/od/ls1/rt_addr_delay
add wave -noupdate -radix binary /tb_InstructionFetch/ins_fetch/decode/pipe/od/ls1/reg_write_delay
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/pipe/od/br1/rt_delay
add wave -noupdate -radix unsigned /tb_InstructionFetch/ins_fetch/decode/pipe/od/br1/rt_addr_delay
add wave -noupdate -radix binary /tb_InstructionFetch/ins_fetch/decode/pipe/od/br1/reg_write_delay
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/pipe/od/br1/pc_delay
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/pipe/od/br1/branch_delay
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/pipe/rf/registers
add wave -noupdate /tb_InstructionFetch/ins_fetch/decode/pipe/od/ls1/mem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {195 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 404
configure wave -valuecolwidth 265
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {24 ns} {332 ns}