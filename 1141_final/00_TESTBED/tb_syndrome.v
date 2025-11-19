`timescale 1ns/1ps

module syndrome_tb();
    // Parameters
    parameter CYCLE = 10;
    parameter PATTERN_LEN = 10;
    parameter BCH63_51 = 2'b00;
    parameter BCH255_239 = 2'b01;
    parameter BCH1023_983 = 2'b10;

    // DUT Interface
    reg         i_clk;
    reg         i_rst_n;
    reg  [1:0]  i_code;
    reg         i_clear_and_wen;
    reg         i_wen;
    reg  [7:0]  i_data;
    wire [9:0]  o_S1;
    wire [9:0]  o_S2;
    wire [9:0]  o_S3;
    wire [9:0]  o_S4;
    wire [9:0]  o_S5;
    wire [9:0]  o_S6;
    wire [9:0]  o_S7;
    wire [9:0]  o_S8;
    wire        o_odd_valid;
    wire        o_all_valid;


    reg [1023:0] test_data[PATTERN_LEN-1:0];
    reg [1:0] bch_code[PATTERN_LEN-1:0];
    reg [9:0] golden_S1[PATTERN_LEN-1:0];
    reg [9:0] golden_S2[PATTERN_LEN-1:0];
    reg [9:0] golden_S3[PATTERN_LEN-1:0];
    reg [9:0] golden_S4[PATTERN_LEN-1:0];
    reg [9:0] golden_S5[PATTERN_LEN-1:0];
    reg [9:0] golden_S6[PATTERN_LEN-1:0];
    reg [9:0] golden_S7[PATTERN_LEN-1:0];
    reg [9:0] golden_S8[PATTERN_LEN-1:0];


    // Instantiate DUT
    syndrome u_syndrome (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_code(i_code),
        .i_clear_and_wen(i_clear_and_wen),
        .i_wen(i_wen),
        .i_data(i_data),
        .o_S1(o_S1),
        .o_S2(o_S2),
        .o_S3(o_S3),
        .o_S4(o_S4),
        .o_S5(o_S5),
        .o_S6(o_S6),
        .o_S7(o_S7),
        .o_S8(o_S8),
        .o_odd_valid(o_odd_valid),
        .o_all_valid(o_all_valid)
    );

    // Clock Generation
    initial begin
        i_clk = 0;
        forever #(CYCLE/2) i_clk = ~i_clk;
    end

    // Testbench Logic
    initial begin
        // Waveform Dumping
        $fsdbDumpfile("syndrome_tb.fsdb");
        $fsdbDumpvars(0, syndrome_tb);
    end

    // readfile
    initial begin
        readmemh("pattern/test_data.dat", test_data);
        readmemh("pattern/test_code.dat", bch_code);
        readmemh("pattern/golden_S1.dat", golden_S1);
        readmemh("pattern/golden_S2.dat", golden_S2);
        readmemh("pattern/golden_S3.dat", golden_S3);
        readmemh("pattern/golden_S4.dat", golden_S4);
        readmemh("pattern/golden_S5.dat", golden_S5);
        readmemh("pattern/golden_S6.dat", golden_S6);
        readmemh("pattern/golden_S7.dat", golden_S7);
        readmemh("pattern/golden_S8.dat", golden_S8);
    end

    // max cycle
    initial begin
        #1000000;
        $display("Error: Testbench Timeout");
        $finish;
    end

    // reset
    initial begin
        i_code = 3;
        i_clear_and_wen = 0;
        i_wen = 0;
        i_data = 8'bx;

        i_rst_n = 0;
        #(CYCLE*3);
        @(posedge i_clk);
        i_rst_n = 1;
    end

    // input stimulus
    integer i, j, code_length;
    reg [1023:0] curr_data;
    initial begin
        #1;
        wait(i_rst_n == 1);
        for (i = 0; i < PATTERN_LEN; i = i + 1) begin
            // Configure BCH code
            i_code = bch_code[i];
            curr_data = test_data[i];
            if (i_code === BCH63_51)
                code_length = 63;
            else if (i_code === BCH255_239)
                code_length = 255;
            else if (i_code === BCH1023_983)
                code_length = 1023;
            else begin
                $display("Error: Invalid BCH Code");
                $finish;
            end
            // Clear syndrome accumulators
            i_clear_and_wen = 1;
            i_wen = 1;
            for (j = 0; j < code_length; j = j + 1) begin
                if (j != 0)
                    i_clear_and_wen = 0;
                i_data = curr_data[1023 -: 8];
                curr_data = curr_data << 8;
                @(posedge i_clk);
            end

            wait(o_all_valid == 1);
            @(posedge i_clk);
            @(posedge i_clk);
        end
    end

    // get result and compare
    integer error_count;
    integer golden_idx;
    integer k;
    initial begin
        error_count = 0;
        golden_idx = 0;
        wait(i_rst_n == 1);
        while (golden_idx < PATTERN_LEN) begin
            if (o_odd_valid) begin
                if (o_S1 !== golden_S1[golden_idx]) begin
                    $display("Error: Pattern %0d, S1 Mismatch! Expected: %h, Got: %h", golden_idx, golden_S1[golden_idx], o_S1);
                    error_count = error_count + 1;
                end
                if (o_S3 !== golden_S3[golden_idx]) begin
                    $display("Error: Pattern %0d, S3 Mismatch! Expected: %h, Got: %h", golden_idx, golden_S3[golden_idx], o_S3);
                    error_count = error_count + 1;
                end
                if (o_S5 !== golden_S5[golden_idx]) begin
                    $display("Error: Pattern %0d, S5 Mismatch! Expected: %h, Got: %h", golden_idx, golden_S5[golden_idx], o_S5);
                    error_count = error_count + 1;
                end
                if (o_S7 !== golden_S7[golden_idx]) begin
                    $display("Error: Pattern %0d, S7 Mismatch! Expected: %h, Got: %h", golden_idx, golden_S7[golden_idx], o_S7);
                    error_count = error_count + 1;
                end

            end
            if (o_all_valid) begin
                if (o_S1 !== golden_S1[golden_idx]) begin
                    $display("Error: Pattern %0d, S1 Mismatch! Expected: %h, Got: %h", golden_idx, golden_S1[golden_idx], o_S1);
                    error_count = error_count + 1;
                end
                if (o_S2 !== golden_S2[golden_idx]) begin
                    $display("Error: Pattern %0d, S2 Mismatch! Expected: %h, Got: %h", golden_idx, golden_S2[golden_idx], o_S2);
                    error_count = error_count + 1;
                end
                if (o_S3 !== golden_S3[golden_idx]) begin
                    $display("Error: Pattern %0d, S3 Mismatch! Expected: %h, Got: %h", golden_idx, golden_S3[golden_idx], o_S3);
                    error_count = error_count + 1;
                end
                if (o_S4 !== golden_S4[golden_idx]) begin
                    $display("Error: Pattern %0d, S4 Mismatch! Expected: %h, Got: %h", golden_idx, golden_S4[golden_idx], o_S4);
                    error_count = error_count + 1;
                end
                if (o_S5 !== golden_S5[golden_idx]) begin
                    $display("Error: Pattern %0d, S5 Mismatch! Expected: %h, Got: %h", golden_idx, golden_S5[golden_idx], o_S5);
                    error_count = error_count + 1;
                end
                if (o_S6 !== golden_S6[golden_idx]) begin
                    $display("Error: Pattern %0d, S6 Mismatch! Expected: %h, Got: %h", golden_idx, golden_S6[golden_idx], o_S6);
                    error_count = error_count + 1;
                end
                if (o_S7 !== golden_S7[golden_idx]) begin
                    $display("Error: Pattern %0d, S7 Mismatch! Expected: %h, Got: %h", golden_idx, golden_S7[golden_idx], o_S7);
                    error_count = error_count + 1;
                end

                golden_idx = golden_idx + 1;
            end
            @(posedge i_clk);
        end
    end


endmodule