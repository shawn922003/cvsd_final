set company "CIC"
set designer "Student"
set search_path       "./ /mnt/data/LYX/cvsd/CBDK_IC_Contest/CIC/SynopsysDC/db  $search_path"
set target_library    "slow.db"
set link_library      "* $target_library"

set hdlin_translate_off_skip_text "TRUE"
set edifout_netlist_only "TRUE"
set verilogout_no_tri true

set hdlin_enable_presto_for_vhdl "TRUE"
set sh_enable_line_editing true
set sh_line_editing_mode emacs
history keep 100
alias h history

#PrimeTime Script
set power_enable_analysis TRUE
set power_analysis_mode time_based

read_file -format verilog  ../03_GATE/IOTDF_syn.v
current_design IOTDF
link

read_sdf -load_delay net ../03_GATE/IOTDF_syn.sdf


## Measure  power
#report_switching_activity -list_not_annotated -show_pin

read_vcd  -strip_path test/u_IOTDF  ../03_GATE/IOTDF_F1.fsdb
update_power
report_power 
report_power > F1_4.power

read_vcd  -strip_path test/u_IOTDF  ../03_GATE/IOTDF_F2.fsdb
update_power
report_power
report_power >> F1_4.power

read_vcd  -strip_path test/u_IOTDF  ../03_GATE/IOTDF_F3.fsdb
update_power
report_power
report_power >> F1_4.power

read_vcd  -strip_path test/u_IOTDF  ../03_GATE/IOTDF_F4.fsdb
update_power
report_power
report_power >> F1_4.power



