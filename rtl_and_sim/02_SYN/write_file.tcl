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
write_sdc -version 1.8 "./Netlist/${DESIGN}_syn.sdc"

report_timing
report_area -hierarchy
check_design