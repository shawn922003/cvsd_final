############################################
# 1. Clock gating style 設定
############################################
set_clock_gating_style \
    -control_point before \
    -control_signal scan_enable \
    -max_fanout 20

############################################
# 2. 抓出 llr_mem / error_bit_saver 裡所有暫存器
############################################
# 假設 top 裡的 instance 名稱是：
#   u_llr_mem
#   u_error_bit_saver
set llr_regs_all [all_registers u_llr_mem/*]
set ebs_regs     [all_registers u_error_bit_saver/*]

# 如果你還有 syndrome 的需求，可以先抓起來（現在沒用到也無妨）
set syndrome_regs [all_registers u_syndrome/*]

############################################
# 3. 過濾出 llr_mem 的 mem_reg[>=8][*] 暫存器
#
# 假設 register 名稱類似：
#   u_llr_mem/mem_reg[0][0]
#   u_llr_mem/mem_reg[7][3]
#   u_llr_mem/mem_reg[8][0]
#   u_llr_mem/mem_reg[15][6]
# 用 regexp 把第一個 index 抓出來，判斷 >= 8
############################################

set llr_regs ""

foreach_in_collection reg $llr_regs_all {
    # 取出完整路徑名稱
    set reg_name [get_object_name $reg]

    # 用 regexp 擷取 mem_reg[...] 的第一個 index
    # 例：u_llr_mem/mem_reg[12][3] 會 match 到 idx = 12
    #
    # 說明：
    #   .*mem_reg\[(\d+)\]      ：找到 "...mem_reg[數字]"，把數字丟到 (idx)
    #   (?:\[(\d+)\])?          ：可選的第二個 [數字]，如果是二維 array
    if {[regexp {.*mem_reg\[(\d+)\](?:\[(\d+)\])?} $reg_name -> idx bit]} {
        if {$idx >= 8} {
            # 把符合條件的 register 加進 llr_regs
            set llr_regs [add_to_collection $llr_regs $reg]
            puts "Clock gating enabled for llr_mem register (bank>=8): $reg_name"
        }
    }
}

puts "High-bank llr_mem regs (idx>=8) count = [sizeof_collection $llr_regs]"
puts "u_error_bit_saver regs count           = [sizeof_collection $ebs_regs]"

# 將 llr 高位 bank + error_bit_saver 全部合併為要 clock gating 的集合
set cg_regs $llr_regs
set cg_regs [add_to_collection $cg_regs $ebs_regs]
puts "Total clock-gating regs (llr high-bank + error_bit_saver) = [sizeof_collection $cg_regs]"

############################################
# 4. reset multicycle path
############################################
# 取得 reset port 和所有暫存器
set rstn_port [get_ports rstn]
set all_regs  [all_registers]

# setup 多 10 個 clock (N=10 -> setup N-1 = 9)
set_multicycle_path 9 -from $rstn_port -to $all_regs -setup

# hold 要配成 N-1，避免變成超嚴苛的 hold 要求
set_multicycle_path 8 -from $rstn_port -to $all_regs -hold

############################################
# 5. 其他暫存器一律禁止 clock gating
############################################
set all_regs     [all_registers]
set non_cg_regs  [remove_from_collection $all_regs $cg_regs]

############################################
# 6. Clock gating register 限定：
#    只允許：
#      - llr_mem 的 mem_reg[>=8][*]
#      - u_error_bit_saver 內所有暫存器
#    被 gate，其餘一律禁止
############################################
# ⚠️ 雖然 Synopsys 說 set_clock_gating_registers 之後會 obsolete，
#    但目前版本還是可以用，你原本 flow 也是用這組指令。
set_clock_gating_registers -include_instances $cg_regs
set_clock_gating_registers -exclude_instances $non_cg_regs

# 若之後要加 margin，可以調整 setup/hold
set_clock_gating_check -setup 0.0 -hold 0.0 [get_clocks clk]

############################################
# 7. 後續 ungroup / compile flow
############################################
ungroup -all
# uniquify
# uniquify
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
# set_timing_derate -early 0.9  [current_design]
compile_ultra -gate_clock
