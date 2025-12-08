`timescale 1ns/1ps

module test;

// --------------------------
// parameters
parameter CYCLE = 10;
parameter PATTERN = 1;
integer NTEST = 64;  // 改为64笔测试数据

// --------------------------
// signals
reg clk, rstn;
reg mode;
reg [1:0] code;
reg set;
reg [63:0] idata;
wire ready;
wire finish;
wire [9:0] odata;

// --------------------------
// test data
reg [63:0] testdata [0:1280000];
reg [9:0] testa [0:100000];
integer i1, i2, i3;
integer errcnt;

// --------------------------
// read files and dump files
initial begin
	// 硬判决测试 (Hard-decision)
	if (PATTERN == 100) begin
		NTEST = 64;
		$readmemb("../00_TESTBED/tb/p100.txt", testdata);
		$readmemb("../00_TESTBED/tb/p100a.txt", testa);
	end
	if (PATTERN == 200) begin
		NTEST = 64;
		$readmemb("../00_TESTBED/tb/p200.txt", testdata);
		$readmemb("../00_TESTBED/tb/p200a.txt", testa);
	end
	if (PATTERN == 300) begin
		NTEST = 64;
		$readmemb("../00_TESTBED/tb/p300.txt", testdata);
		$readmemb("../00_TESTBED/tb/p300a.txt", testa);
	end
	// 软判决测试 (Soft-decision)
	if (PATTERN == 400) begin
		NTEST = 64;
		$readmemb("../00_TESTBED/tb/soft_decoder_100.txt", testdata);
		$readmemb("../00_TESTBED/tb/soft_decoder_100a.txt", testa);
	end
	if (PATTERN == 500) begin
		NTEST = 64;
		$readmemb("../00_TESTBED/tb/soft_decoder_200.txt", testdata);
		$readmemb("../00_TESTBED/tb/soft_decoder_200a.txt", testa);
	end
	if (PATTERN == 600) begin
		NTEST = 64;
		$readmemb("../00_TESTBED/tb/soft_decorder_300.txt", testdata);
		$readmemb("../00_TESTBED/tb/soft_decorder_300a.txt", testa);
	end
	if (PATTERN == 700) begin
		NTEST = 1000;
		$readmemb("../00_TESTBED/tb/bch63_hard/p101.txt", testdata);
		$readmemb("../00_TESTBED/tb/bch63_hard/p101a.txt", testa);
	end
	if (PATTERN == 800) begin
		NTEST = 1000;
		$readmemb("../00_TESTBED/tb/bch63_hard/p102.txt", testdata);
		$readmemb("../00_TESTBED/tb/bch63_hard/p102a.txt", testa);
	end
	if (PATTERN == 900) begin
		NTEST = 1000;
		$readmemb("../00_TESTBED/tb/bch255_hard/p201.txt", testdata);
		$readmemb("../00_TESTBED/tb/bch255_hard/p201a.txt", testa);
	end
	if (PATTERN == 1000) begin
		NTEST = 1000;
		$readmemb("../00_TESTBED/tb/bch255_hard/p202.txt", testdata);
		$readmemb("../00_TESTBED/tb/bch255_hard/p202a.txt", testa);
	end
	if (PATTERN == 1100) begin
		NTEST = 1000;
		$readmemb("../00_TESTBED/tb/bch1023_hard/p301.txt", testdata);
		$readmemb("../00_TESTBED/tb/bch1023_hard/p301a.txt", testa);
	end
	if (PATTERN == 1200) begin
		NTEST = 1000;
		$readmemb("../00_TESTBED/tb/bch1023_hard/p302.txt", testdata);
		$readmemb("../00_TESTBED/tb/bch1023_hard/p302a.txt", testa);
	end
	if (PATTERN == 10000) begin
		NTEST = 10000;
		$readmemb("../00_TESTBED/tb/p10000.txt", testdata);
		$readmemb("../00_TESTBED/tb/p10000a.txt", testa);
	end
	if (PATTERN == 20000) begin
		NTEST = 10000;
		$readmemb("../00_TESTBED/tb/p20000.txt", testdata);
		$readmemb("../00_TESTBED/tb/p20000a.txt", testa);
	end
	if (PATTERN == 30000) begin
		NTEST = 10000;
		$readmemb("../00_TESTBED/tb/p30000.txt", testdata);
		$readmemb("../00_TESTBED/tb/p30000a.txt", testa);
	end
	if (PATTERN == 40000) begin
		NTEST = 10000;
		$readmemb("../00_TESTBED/tb/soft_decoder_10000.txt", testdata);
		$readmemb("../00_TESTBED/tb/soft_decoder_10000a.txt", testa);
	end
	if (PATTERN == 50000) begin
		NTEST = 10000;
		$readmemb("../00_TESTBED/tb/soft_decoder_20000.txt", testdata);
		$readmemb("../00_TESTBED/tb/soft_decoder_20000a.txt", testa);
	end
	if (PATTERN == 60000) begin
		NTEST = 10000;
		$readmemb("../00_TESTBED/tb/soft_decorder_30000.txt", testdata);
		$readmemb("../00_TESTBED/tb/soft_decorder_30000a.txt", testa);
	end
end

initial begin
	$fsdbDumpfile("waveform.fsdb");
	$fsdbDumpvars(0,test ,"+mda");
end

// --------------------------
// modules
bch U_bch(
	.clk(clk),
	.rstn(rstn),
	.mode(mode),
	.code(code),
	.set(set),
	.idata(idata),
	.ready(ready),
	.finish(finish),
	.odata(odata)
);
`ifdef SDF_GATE
	initial $sdf_annotate("../02_SYN/Netlist/bch_syn.sdf", U_bch);
`elsif SDF_POST
	initial $sdf_annotate("../04_APR/Netlist/bch_apr.sdf", U_bch);
`endif

// --------------------------
// clock
initial clk = 1;
always #(CYCLE/2.0) clk = ~clk;

// --------------------------
// test
initial begin
	i1 = 0;
	i2 = 0;
	i3 = 0;
	errcnt = 0;

	rstn = 0;
	mode = 0;
	code = 0;
	set = 0;
	idata = 0;
	#(CYCLE*5);
	@(negedge clk);
	rstn = 1;

	@(negedge clk);
	#(CYCLE*5);
	for (i2 = 0; i2 < NTEST; i2 = i2 + 1) begin
		if (PATTERN <= 100) begin
			code = 1;
			mode = 0;  // 硬判决
		end else if (PATTERN <= 200) begin
			code = 2;
			mode = 0;  // 硬判决
		end else if (PATTERN <= 300) begin
			code = 3;
			mode = 0;  // 硬判决
		end else if (PATTERN <= 400) begin
			code = 1;
			mode = 1;  // 软判决
		end else if (PATTERN <= 500) begin
			code = 2;
			mode = 1;  // 软判决
		end else if (PATTERN <= 600) begin
			code = 3;
			mode = 1;  // 软判决
		end
		else if (PATTERN <= 600) begin
			code = 1;
			mode = 0;  // 硬判决 bch63
		end
		else if (PATTERN <= 800) begin
			code = 1;
			mode = 0;  // 硬判决 bch63
		end
		else if (PATTERN <= 900) begin
			code = 2;
			mode = 0;  // 硬判决 bch255
		end
		else if (PATTERN <= 1000) begin
			code = 2;
			mode = 0;  // 硬判决 bch255
		end
		else if (PATTERN <= 1100) begin
			code = 3;
			mode = 0;  // 硬判决 bch1023
		end
		else if (PATTERN <= 1200) begin
			code = 3;
			mode = 0;  // 硬判决 bch1023
		end
		else if (PATTERN <= 10000) begin
			code = 1;
			mode = 0;  // 硬判决
		end else if (PATTERN <= 20000) begin
			code = 2;
			mode = 0;  // 硬判决
		end else if (PATTERN <= 30000) begin
			code = 3;
			mode = 0;  // 硬判决
		end else if (PATTERN <= 40000) begin
			code = 1;
			mode = 1;  // 软判决
		end else if (PATTERN <= 50000) begin
			code = 2;
			mode = 1;  // 软判决
		end else if (PATTERN <= 60000) begin
			code = 3;
			mode = 1;  // 软判决
		end

		set = 1;
		#(CYCLE);
		set = 0;

		$write("Test %0d start...\n", i2);
		wait(finish === 1);
		@(negedge clk);
		#(CYCLE*10);
	end
end
always @(negedge clk) begin
	if (ready === 1) begin
		// $display("Input data = %64b\n", idata);
		idata = testdata[i1];
		i1 = i1 + 1;
	end
end
always @(negedge clk) begin
	if (finish === 1 && $time >= CYCLE * 5) begin
		if (odata !== testa[i3]) begin
			errcnt = errcnt + 1;
			$write("design output = %4d, golden output = %4d. Error\n", odata, testa[i3]);
		end else begin
			$write("design output = %4d, golden output = %4d\n", odata, testa[i3]);
		end
		i3 = i3 + 1;
	end
end
initial begin
	wait(i2 == NTEST);
	$write("Error count = %0d\n", errcnt);
	$write("Time = %0d\n", $time - CYCLE * 5);
	#(CYCLE*5);
	$finish;
end
initial begin
	#(CYCLE*10000000);
	$write("Timeout\n");
	$finish;
end

endmodule