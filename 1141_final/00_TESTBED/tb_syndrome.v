/********************************************************************
* Filename: syndrome_tb.v
* Description:
*     Comprehensive testbench for BCH syndrome calculator
*     Supports BCH(63,51), BCH(255,239), and BCH(1023,983)
*     
* Features:
*     - Parameterized test patterns
*     - Automatic golden result verification
*     - Detailed error reporting
*     - Multiple test scenarios
*     - Waveform dumping
*
* Test Flow:
*     1. System reset
*     2. Configure BCH code type
*     3. Clear syndrome accumulators
*     4. Input data (8 cycles, MSB first)
*     5. Wait for o_odd_valid
*     6. Verify odd syndromes (S1, S3, S5, S7)
*     7. Wait for o_all_valid
*     8. Verify all syndromes (S1-S8)
*********************************************************************/

`timescale 1ns/1ps

module syndrome_tb();

    //========================================
    // Parameters
    //========================================
    parameter CLK_PERIOD = 10.0;        // 100MHz clock
    parameter RST_CYCLES = 5;           // Reset duration in clock cycles
    parameter TIMEOUT_CYCLES = 200;     // Timeout for valid signals
    parameter NUM_PATTERNS = 10;        // Number of test patterns
    
    parameter DATA_WIDTH = 8;
    parameter SYNDROME_WIDTH = 10;

    //========================================
    // DUT Signals
    //========================================
    reg                         clk;
    reg                         rst_n;
    reg  [1:0]                  i_code;
    reg                         i_clear;
    reg                         i_wen;
    reg  [DATA_WIDTH-1:0]       i_data;
    
    wire [SYNDROME_WIDTH-1:0]   o_S1;
    wire [SYNDROME_WIDTH-1:0]   o_S2;
    wire [SYNDROME_WIDTH-1:0]   o_S3;
    wire [SYNDROME_WIDTH-1:0]   o_S4;
    wire [SYNDROME_WIDTH-1:0]   o_S5;
    wire [SYNDROME_WIDTH-1:0]   o_S6;
    wire [SYNDROME_WIDTH-1:0]   o_S7;
    wire [SYNDROME_WIDTH-1:0]   o_S8;
    wire                        o_odd_valid;
    wire                        o_all_valid;

    //========================================
    // Test Control Variables
    //========================================
    integer pattern_idx;
    integer error_count;
    integer pass_count;
    integer cycle_count;
    integer i;
    
    reg test_running;
    
    //========================================
    // Test Pattern Storage
    //========================================
    reg [1:0]                   test_codes      [0:NUM_PATTERNS-1];
    reg [63:0]                  test_data       [0:NUM_PATTERNS-1];
    reg [SYNDROME_WIDTH-1:0]    golden_S1       [0:NUM_PATTERNS-1];
    reg [SYNDROME_WIDTH-1:0]    golden_S2       [0:NUM_PATTERNS-1];
    reg [SYNDROME_WIDTH-1:0]    golden_S3       [0:NUM_PATTERNS-1];
    reg [SYNDROME_WIDTH-1:0]    golden_S4       [0:NUM_PATTERNS-1];
    reg [SYNDROME_WIDTH-1:0]    golden_S5       [0:NUM_PATTERNS-1];
    reg [SYNDROME_WIDTH-1:0]    golden_S6       [0:NUM_PATTERNS-1];
    reg [SYNDROME_WIDTH-1:0]    golden_S7       [0:NUM_PATTERNS-1];
    reg [SYNDROME_WIDTH-1:0]    golden_S8       [0:NUM_PATTERNS-1];

    //========================================
    // Clock Generation
    //========================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2.0) clk = ~clk;
    end

    //========================================
    // Cycle Counter
    //========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cycle_count <= 0;
        else if (test_running)
            cycle_count <= cycle_count + 1;
    end

    //========================================
    // DUT Instantiation
    //========================================
    syndrome u_dut (
        .i_clk          (clk),
        .i_rst_n        (rst_n),
        .i_code         (i_code),
        .i_clear        (i_clear),
        .i_wen          (i_wen),
        .i_data         (i_data),
        .o_S1           (o_S1),
        .o_S2           (o_S2),
        .o_S3           (o_S3),
        .o_S4           (o_S4),
        .o_S5           (o_S5),
        .o_S6           (o_S6),
        .o_S7           (o_S7),
        .o_S8           (o_S8),
        .o_odd_valid    (o_odd_valid),
        .o_all_valid    (o_all_valid)
    );

    //========================================
    // Waveform Dump
    //========================================
    initial begin
        `ifdef FSDB
            $fsdbDumpfile("syndrome.fsdb");
            $fsdbDumpvars(0, syndrome_tb, "+all");
            $fsdbDumpMDA();
        `endif
        
        `ifdef VCD
            $dumpfile("syndrome.vcd");
            $dumpvars(0, syndrome_tb);
        `endif
    end

    //========================================
    // Watchdog Timer
    //========================================
    initial begin
        #(CLK_PERIOD * TIMEOUT_CYCLES * NUM_PATTERNS * 2);
        $display("\n");
        $display("========================================");
        $display("  SIMULATION TIMEOUT!");
        $display("========================================");
        $display("  Simulation exceeded maximum time");
        $display("========================================\n");
        $finish;
    end

    //========================================
    // Load Test Patterns
    //========================================
    initial begin
        if ($test$plusargs("LOAD_PATTERNS")) begin
            $readmemb("pattern/test_code.dat", test_codes);
            $readmemh("pattern/test_data.dat", test_data);
            $readmemh("pattern/golden_S1.dat", golden_S1);
            $readmemh("pattern/golden_S2.dat", golden_S2);
            $readmemh("pattern/golden_S3.dat", golden_S3);
            $readmemh("pattern/golden_S4.dat", golden_S4);
            $readmemh("pattern/golden_S5.dat", golden_S5);
            $readmemh("pattern/golden_S6.dat", golden_S6);
            $readmemh("pattern/golden_S7.dat", golden_S7);
            $readmemh("pattern/golden_S8.dat", golden_S8);
            $display("[INFO] Test patterns loaded from files");
        end else begin
            // Default test patterns
            initialize_default_patterns();
            $display("[INFO] Using default test patterns");
        end
    end

    //========================================
    // Main Test Sequence
    //========================================
    initial begin
        // Initialize
        initialize_signals();
        test_running = 0;
        error_count = 0;
        pass_count = 0;
        
        // Print header
        print_test_header();
        
        // Wait for pattern loading
        #1;
        
        // System reset
        apply_reset();
        
        // Run all test patterns
        test_running = 1;
        for (pattern_idx = 0; pattern_idx < NUM_PATTERNS; pattern_idx = pattern_idx + 1) begin
            run_single_test(pattern_idx);
        end
        test_running = 0;
        
        // Print summary
        print_test_summary();
        
        // Finish simulation
        #(CLK_PERIOD * 10);
        $finish;
    end

    //========================================
    // Task: Initialize Signals
    //========================================
    task initialize_signals;
    begin
        rst_n   = 1'b1;
        i_code  = 2'b00;
        i_clear = 1'b0;
        i_wen   = 1'b0;
        i_data  = 8'h00;
    end
    endtask

    //========================================
    // Task: Apply Reset
    //========================================
    task apply_reset;
    begin
        $display("\n[INFO] Applying system reset...");
        
        @(negedge clk);
        rst_n = 1'b0;
        i_clear = 1'b1;
        
        repeat(RST_CYCLES) @(posedge clk);
        
        @(negedge clk);
        rst_n = 1'b1;
        
        @(posedge clk);
        @(negedge clk);
        i_clear = 1'b0;
        
        @(posedge clk);
        
        $display("[INFO] Reset complete\n");
    end
    endtask

    //========================================
    // Task: Run Single Test
    //========================================
    task run_single_test;
        input integer pat_idx;
        
        reg [1:0]                   test_code;
        reg [63:0]                  test_input;
        reg [SYNDROME_WIDTH-1:0]    captured_S1, captured_S2, captured_S3, captured_S4;
        reg [SYNDROME_WIDTH-1:0]    captured_S5, captured_S6, captured_S7, captured_S8;
        reg                         odd_pass, all_pass;
        integer                     byte_idx;
        integer                     wait_cycles;
        
    begin: RUN_SINGLE_TEST
        test_code = test_codes[pat_idx];
        test_input = test_data[pat_idx];
        odd_pass = 1'b1;
        all_pass = 1'b1;
        
        // Print test info
        $display("========================================");
        $display("  Test Pattern %0d", pat_idx);
        $display("========================================");
        $display("  BCH Code: %s", get_code_name(test_code));
        $display("  Input Data: 0x%016h", test_input);
        $display("----------------------------------------");
        
        // Phase 1: Clear
        clear_syndrome(test_code);
        
        // Phase 2: Input data (8 bytes, MSB first)
        $display("\n[Phase 1] Inputting data...");
        input_data_stream(test_input);
        
        // Phase 3: Wait for odd syndromes
        $display("\n[Phase 2] Waiting for odd syndromes...");
        wait_for_signal(o_odd_valid, TIMEOUT_CYCLES, wait_cycles);
        
        if (wait_cycles < 0) begin
            $display("  [ERROR] Timeout waiting for o_odd_valid!");
            error_count = error_count + 1;
            disable RUN_SINGLE_TEST;   // ★★★ 取代 return;
        end
        
        $display("  [INFO] o_odd_valid asserted after %0d cycles", wait_cycles);
        
        // Capture odd syndromes
        @(negedge clk);
        captured_S1 = o_S1;
        captured_S3 = o_S3;
        if (test_code == 2'b10) begin
            captured_S5 = o_S5;
            captured_S7 = o_S7;
        end
        @(posedge clk);
        
        // Verify odd syndromes
        $display("\n[Phase 2] Verifying odd syndromes...");
        odd_pass = verify_syndrome("S1", captured_S1, golden_S1[pat_idx]) && odd_pass;
        odd_pass = verify_syndrome("S3", captured_S3, golden_S3[pat_idx]) && odd_pass;
        
        if (test_code == 2'b10) begin
            odd_pass = verify_syndrome("S5", captured_S5, golden_S5[pat_idx]) && odd_pass;
            odd_pass = verify_syndrome("S7", captured_S7, golden_S7[pat_idx]) && odd_pass;
        end
        
        // Phase 4: Wait for all syndromes
        $display("\n[Phase 3] Waiting for all syndromes...");
        wait_for_signal(o_all_valid, TIMEOUT_CYCLES, wait_cycles);

        
        if (wait_cycles < 0) begin
            $display("  [ERROR] Timeout waiting for o_all_valid!");
            error_count = error_count + 1;
            disable RUN_SINGLE_TEST;
        end
        
        $display("  [INFO] o_all_valid asserted after %0d cycles", wait_cycles);
        
        // Capture all syndromes
        @(negedge clk);
        captured_S1 = o_S1;
        captured_S2 = o_S2;
        captured_S3 = o_S3;
        captured_S4 = o_S4;
        if (test_code == 2'b10) begin
            captured_S5 = o_S5;
            captured_S6 = o_S6;
            captured_S7 = o_S7;
            captured_S8 = o_S8;
        end
        @(posedge clk);
        
        // Verify all syndromes
        $display("\n[Phase 3] Verifying all syndromes...");
        all_pass = verify_syndrome("S1", captured_S1, golden_S1[pat_idx]) && all_pass;
        all_pass = verify_syndrome("S2", captured_S2, golden_S2[pat_idx]) && all_pass;
        all_pass = verify_syndrome("S3", captured_S3, golden_S3[pat_idx]) && all_pass;
        all_pass = verify_syndrome("S4", captured_S4, golden_S4[pat_idx]) && all_pass;
        
        if (test_code == 2'b10) begin
            all_pass = verify_syndrome("S5", captured_S5, golden_S5[pat_idx]) && all_pass;
            all_pass = verify_syndrome("S6", captured_S6, golden_S6[pat_idx]) && all_pass;
            all_pass = verify_syndrome("S7", captured_S7, golden_S7[pat_idx]) && all_pass;
            all_pass = verify_syndrome("S8", captured_S8, golden_S8[pat_idx]) && all_pass;
        end
        
        // Test result
        $display("\n----------------------------------------");
        if (odd_pass && all_pass) begin
            $display("  ✓ PASSED");
            pass_count = pass_count + 1;
        end else begin
            $display("  ✗ FAILED");
            error_count = error_count + 1;
        end
        $display("========================================\n");
        
        // Wait before next test
        repeat(5) @(posedge clk);
    end
    endtask

    //========================================
    // Task: Clear Syndrome
    //========================================
    task clear_syndrome;
        input [1:0] code;
    begin
        $display("\n[Phase 0] Clearing syndrome registers...");
        
        @(negedge clk);
        i_code = code;
        i_clear = 1'b1;
        i_wen = 1'b0;
        i_data = 8'h00;
        @(posedge clk);
        
        repeat(3) @(posedge clk);
        
        @(negedge clk);
        i_clear = 1'b0;
        @(posedge clk);
        
        $display("  [INFO] Syndrome cleared for %s", get_code_name(code));
    end
    endtask

    //========================================
    // Task: Input Data Stream
    //========================================
    task input_data_stream;
        input [63:0] data;
        integer byte_idx;
        reg [7:0] current_byte;
    begin
        for (byte_idx = 0; byte_idx < 8; byte_idx = byte_idx + 1) begin
            @(negedge clk);
            i_wen = 1'b1;
            // MSB first: byte[7] to byte[0]
            current_byte = data[63 - byte_idx*8 -: 8];
            i_data = current_byte;
            @(posedge clk);
            
            $display("  Cycle %0d: i_data = 0x%02h", byte_idx, current_byte);
        end
        
        // Stop writing
        @(negedge clk);
        i_wen = 1'b0;
        i_data = 8'hXX;
        @(posedge clk);
    end
    endtask

    //========================================
    // Task: Wait for Signal
    //========================================
    task wait_for_signal;
        input signal;
        input integer max_cycles;
        output integer cycles_waited;
        
        integer counter;
    begin
        counter = 0;
        while (signal !== 1'b1 && counter < max_cycles) begin
            @(posedge clk);
            counter = counter + 1;
        end
        
        if (counter >= max_cycles)
            cycles_waited = -1;  // Timeout
        else
            cycles_waited = counter;
    end
    endtask

    //========================================
    // Function: Verify Syndrome
    //========================================
    function verify_syndrome;
        input [8*2:1] name;  // Syndrome name (e.g., "S1")
        input [SYNDROME_WIDTH-1:0] actual;
        input [SYNDROME_WIDTH-1:0] expected;
    begin
        if (actual === expected) begin
            $display("  [PASS] %s = 0x%03h (expected: 0x%03h)", name, actual, expected);
            verify_syndrome = 1'b1;
        end else begin
            $display("  [FAIL] %s = 0x%03h (expected: 0x%03h)", name, actual, expected);
            verify_syndrome = 1'b0;
        end
    end
    endfunction

    //========================================
    // Function: Get Code Name
    //========================================
    function [8*20:1] get_code_name;
        input [1:0] code;
    begin
        case (code)
            2'b00: get_code_name = "BCH(63,51)";
            2'b01: get_code_name = "BCH(255,239)";
            2'b10: get_code_name = "BCH(1023,983)";
            default: get_code_name = "Unknown";
        endcase
    end
    endfunction

    //========================================
    // Task: Initialize Default Patterns
    //========================================
    task initialize_default_patterns;
        integer i;
    begin
        // Initialize with safe default values
        for (i = 0; i < NUM_PATTERNS; i = i + 1) begin
            test_codes[i] = 2'b00;  // BCH(63,51)
            test_data[i] = 64'h0;
            golden_S1[i] = 10'h0;
            golden_S2[i] = 10'h0;
            golden_S3[i] = 10'h0;
            golden_S4[i] = 10'h0;
            golden_S5[i] = 10'h0;
            golden_S6[i] = 10'h0;
            golden_S7[i] = 10'h0;
            golden_S8[i] = 10'h0;
        end
        
        // Pattern 0: All zeros (no error)
        test_codes[0] = 2'b00;
        test_data[0] = 64'h0000000000000000;
        
        // Pattern 1: Simple pattern
        test_codes[1] = 2'b00;
        test_data[1] = 64'h0102030405060708;
        
        // Pattern 2: BCH(255,239) test
        test_codes[2] = 2'b01;
        test_data[2] = 64'hAA55AA55AA55AA55;
        
        // Pattern 3: BCH(1023,983) test
        test_codes[3] = 2'b10;
        test_data[3] = 64'h123456789ABCDEF0;
    end
    endtask

    //========================================
    // Task: Print Test Header
    //========================================
    task print_test_header;
    begin
        $display("\n");
        $display("╔════════════════════════════════════════════╗");
        $display("║   BCH Syndrome Calculator Testbench       ║");
        $display("╚════════════════════════════════════════════╝");
        $display("");
        $display("  Supported Codes:");
        $display("    • BCH(63,51)    - GF(2^6)");
        $display("    • BCH(255,239)  - GF(2^8)");
        $display("    • BCH(1023,983) - GF(2^10)");
        $display("");
        $display("  Test Configuration:");
        $display("    • Clock Period:   %0.1f ns", CLK_PERIOD);
        $display("    • Num Patterns:   %0d", NUM_PATTERNS);
        $display("    • Timeout Cycles: %0d", TIMEOUT_CYCLES);
        $display("");
    end
    endtask

    //========================================
    // Task: Print Test Summary
    //========================================
    task print_test_summary;
    begin
        $display("\n");
        $display("╔════════════════════════════════════════════╗");
        $display("║           Test Summary                     ║");
        $display("╚════════════════════════════════════════════╝");
        $display("");
        $display("  Total Tests:  %0d", pass_count + error_count);
        $display("  Passed:       %0d", pass_count);
        $display("  Failed:       %0d", error_count);
        $display("  Pass Rate:    %0.1f%%", (pass_count * 100.0) / (pass_count + error_count));
        $display("");
        
        if (error_count == 0) begin
            $display("  ╔═══════════════════════════════════════╗");
            $display("  ║     ✓ ALL TESTS PASSED!              ║");
            $display("  ╚═══════════════════════════════════════╝");
        end else begin
            $display("  ╔═══════════════════════════════════════╗");
            $display("  ║     ✗ SOME TESTS FAILED              ║");
            $display("  ╚═══════════════════════════════════════╝");
        end
        $display("");
    end
    endtask

endmodule