set_clock_latency -source -early -max -rise  -0.979782 [get_ports {clk}] -clock clk 
set_clock_latency -source -early -max -fall  -1.0384 [get_ports {clk}] -clock clk 
set_clock_latency -source -late -max -rise  -0.979782 [get_ports {clk}] -clock clk 
set_clock_latency -source -late -max -fall  -1.0384 [get_ports {clk}] -clock clk 
