############################################
# 1. Clock gating style 設定
############################################
set_clock_gating_style \
    -control_point before \
    -control_signal scan_enable \
    -max_fanout 20

############################################
# 2. 先抓出 llr_mem 裡所有暫存器
############################################
# 這裡假設 top 裡的 instance 名稱是 u_llr_mem
set llr_regs_all [all_registers u_llr_mem/*]

# 如果你還有 syndrome 的需求，可以先抓起來（現在沒用到也無妨）
set syndrome_regs [all_registers u_syndrome/*]

############################################
# 3. 過濾出 llr_mem 的 mem[>=8][*] 暫存器
#
# 假設 register 名稱類似：
#   u_llr_mem/mem[0][0]
#   u_llr_mem/mem[7][3]
#   u_llr_mem/mem[8][0]
#   u_llr_mem/mem[15][6]
# 我們用 regexp 把第一個 index 抓出來，判斷 >= 8
############################################

set llr_regs ""

foreach_in_collection reg $llr_regs_all {
    # 取出完整路徑名稱
    set reg_name [get_object_name $reg]

    # 用 regexp 擷取 mem[...] 的第一個 index
    # 例：u_llr_mem/mem[12][3] 會 match 到 idx = 12
    #
    # 說明：
    #   .*mem\[(\d+)\]      ：找到 "...mem[數字]"，把數字丟到 (idx)
    #   (?:\[(\d+)\])?      ：可選的第二個 [數字]，如果是二維 array
    if {[regexp {.*mem_reg\[(\d+)\](?:\[(\d+)\])?} $reg_name -> idx bit]} {
        if {$idx >= 8} {
            # 把符合條件的 register 加進 llr_regs
            set llr_regs [add_to_collection $llr_regs $reg]
            puts "Clock gating enabled for register: $reg_name"
        }
    }
}

# 取得 reset port 和所有暫存器
set rstn_port [get_ports rstn]
set all_regs  [all_registers]

# setup 多 10 個 clock
set_multicycle_path 9 -from $rstn_port -to $all_regs -setup

# hold 要配成 N-1，避免變成超嚴苛的 hold 要求
set_multicycle_path 8  -from $rstn_port -to $all_regs -hold


############################################
# 4. 其他暫存器一律禁止 clock gating
############################################
set all_regs     [all_registers]
set non_llr_regs [remove_from_collection $all_regs $llr_regs]

############################################
# 5. Clock gating register 限定：
#    只允許 llr_mem 的 mem[>=8][*] 被 gate
############################################
# ⚠️ 雖然 Synopsys 說 set_clock_gating_registers 之後會 obsolete，
#    但目前版本還是可以用，你原本 flow 也就是用這組指令。
set_clock_gating_registers -include_instances $llr_regs
set_clock_gating_registers -exclude_instances $non_llr_regs
set_clock_gating_check -setup 0.0 -hold 0.0 [get_clocks clk]
############################################
# 6. 後續 ungroup / compile flow
############################################
ungroup -all
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

compile_ultra -gate_clock
