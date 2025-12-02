# Setting environment
sh mkdir -p Netlist
sh mkdir -p Report
set_host_options -max_cores 47
set company {NTUGIEE}
set designer {Student}

set search_path      ". /mnt/data/LYX/cvsd/CBDK_IC_Contest/CIC/SynopsysDC/db $search_path"
set target_library   "slow.db"
set link_library     "* $target_library dw_foundation.sldb"
set symbol_library   "tsmc13.sdb generic.sdb"
set synthetic_library "dw_foundation.sldb"
set default_schematic_options {-size infinite}

set hdlin_translate_off_skip_text "TRUE"
set edifout_netlist_only "TRUE"
set verilogout_no_tri true

set hdlin_enable_presto_for_vhdl "TRUE"
set sh_enable_line_editing true
set sh_line_editing_mode emacs
history keep 100
alias h history

set bus_inference_style {%s[%d]}
set bus_naming_style {%s[%d]}
set hdlout_internal_busses true
define_name_rules name_rule -allowed {a-z A-Z 0-9 _} -max_length 255 -type cell
define_name_rules name_rule -allowed {a-z A-Z 0-9 _[]} -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}



# Import Design
set DESIGN "bch"



analyze -format sverilog "flist.sv"
elaborate $DESIGN
current_design [get_designs $DESIGN]
link

source -echo -verbose ./bch_dc.sdc










# Compile Design
current_design [get_designs ${DESIGN}]

# set multicycle path


check_design > Report/check_design.txt
check_timing > Report/check_timing.txt
#set high_fanout_net_threshold 0

set_clock_gating_style -pos integrated  -control_point before -control_signal scan_enable -max_fanout 20


ungroup -all
# uniquify
# ungroup
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
compile_ultra    -gate_clock 

# ungroup -all -flatten


# optimize_registers -no_compile
# compile_ultra -inc   -gate_clock

# optimize_netlist -area

# 取得 reset port 和所有暫存器
set rstn_port [get_ports rstn]
set all_regs  [all_registers]

# setup 多 10 個 clock
set_multicycle_path 10 -from $rstn_port -to $all_regs -setup

# hold 要配成 N-1，避免變成超嚴苛的 hold 要求
set_multicycle_path 9  -from $rstn_port -to $all_regs -hold


set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
compile_ultra    -gate_clock 
optimize_netlist -area

# 取得 reset port 和所有暫存器
# set rstn_port [get_ports rstn]
# set all_regs  [all_registers]

# # setup 多 10 個 clock
# set_multicycle_path 10 -from $rstn_port -to $all_regs -setup

# # hold 要配成 N-1，避免變成超嚴苛的 hold 要求
# set_multicycle_path 9  -from $rstn_port -to $all_regs -hold

# ungroup -all
# set_fix_multiple_port_nets -all -buffer_constants [get_designs *]
# compile_ultra    -gate_clock 
# optimize_netlist -area

# Report Output
current_design [get_designs ${DESIGN}]
report_timing -max_paths 5 > "./Report/${DESIGN}_syn.timing_max"
report_area -hierarchy > "./Report/${DESIGN}_syn.area"

# Output Design
current_design [get_designs ${DESIGN}]

remove_unconnected_ports -blast_buses [get_cells -hierarchical *]
set verilogout_higher_designs_first true
write -format ddc     -hierarchy -output "./Netlist/${DESIGN}_syn.ddc"
write -format verilog -hierarchy -output "./Netlist/${DESIGN}_syn.v"
write_sdf -version 2.1 -context verilog -load_delay cell ./Netlist/${DESIGN}_syn.sdf


report_timing
report_area -hierarchy
check_design
