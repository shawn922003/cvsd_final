
`timescale 1ns/1ps

module tb_ibm;
    parameter CYCLE = 10;
    parameter PATTERN_LEN = 30;
    parameter BCH63_51 = 2'b00;
    parameter BCH255_239 = 2'b01;
    parameter BCH1023_983 = 2'b10;


    reg         i_clk;
    reg         i_rst_n;
    reg         i_mode;
    reg  [1:0]  i_code;
    reg         i_clear_and_wen;
    reg  [9:0]  i_S1;
    reg  [9:0]  i_S2;
    reg  [9:0]  i_S3;
    reg  [9:0]  i_S4;
    reg  [9:0]  i_S5;
    reg  [9:0]  i_S6;
    reg  [9:0]  i_S7;
    reg  [9:0]  i_S8;
    wire [9:0]  o_sigma1_0;
    wire [9:0]  o_sigma1_1;
    wire [9:0]  o_sigma1_2;
    wire [9:0]  o_sigma1_3;
    wire [9:0]  o_sigma1_4;
    wire [9:0]  o_sigma2_0;
    wire [9:0]  o_sigma2_1;
    wire [9:0]  o_sigma2_2;
    wire        o_valid;
    wire        o_next_S;

    reg [1:0] i_code_dly;

    reg [79:0] test_data[PATTERN_LEN-1:0];
    reg [1:0] bch_code[PATTERN_LEN-1:0];
    reg bch_mode[PATTERN_LEN-1:0];
    reg [9:0] golden_sigma1_0[PATTERN_LEN-1:0];
    reg [9:0] golden_sigma1_1[PATTERN_LEN-1:0];
    reg [9:0] golden_sigma1_2[PATTERN_LEN-1:0];
    reg [9:0] golden_sigma1_3[PATTERN_LEN-1:0];
    reg [9:0] golden_sigma1_4[PATTERN_LEN-1:0];
    reg [9:0] golden_sigma2_0[PATTERN_LEN-1:0];
    reg [9:0] golden_sigma2_1[PATTERN_LEN-1:0];
    reg [9:0] golden_sigma2_2[PATTERN_LEN-1:0];

    ibm U_ibm (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_mode(1'b1),
        .i_code(i_code),
        .i_clear_and_wen(i_clear_and_wen),
        .i_S1(i_S1),
        .i_S2(i_S2),
        .i_S3(i_S3),
        .i_S4(i_S4),
        .i_S5(i_S5),
        .i_S6(i_S6),
        .i_S7(i_S7),
        .i_S8(i_S8),
        .o_sigma1_0(o_sigma1_0),
        .o_sigma1_1(o_sigma1_1),
        .o_sigma1_2(o_sigma1_2),
        .o_sigma1_3(o_sigma1_3),
        .o_sigma1_4(o_sigma1_4),
        .o_sigma2_0(o_sigma2_0),
        .o_sigma2_1(o_sigma2_1),
        .o_sigma2_2(o_sigma2_2),
        .o_valid(o_valid),
        .o_next_S(o_next_S)
    );

    // Clock Generation
    initial begin
        i_clk = 0;
        forever #(CYCLE/2) i_clk = ~i_clk;
    end

    // Testbench Logic
    initial begin
        // Waveform Dumping
        $fsdbDumpfile("ibm_tb.fsdb");
        $fsdbDumpvars(0, tb_ibm, "+mda");
    end

    // readfile
    initial begin
        $readmemb("../00_TESTBED/pattern_ibm/test_data.dat", test_data);
        $readmemb("../00_TESTBED/pattern_ibm/test_code.dat", bch_code);
        $readmemh("../00_TESTBED/pattern_ibm/golden_sigma1_0.dat", golden_sigma1_0);
        $readmemh("../00_TESTBED/pattern_ibm/golden_sigma1_1.dat", golden_sigma1_1);
        $readmemh("../00_TESTBED/pattern_ibm/golden_sigma1_2.dat", golden_sigma1_2);
        $readmemh("../00_TESTBED/pattern_ibm/golden_sigma1_3.dat", golden_sigma1_3);
        $readmemh("../00_TESTBED/pattern_ibm/golden_sigma1_4.dat", golden_sigma1_4);
        $readmemh("../00_TESTBED/pattern_ibm/golden_sigma2_0.dat", golden_sigma2_0);
        $readmemh("../00_TESTBED/pattern_ibm/golden_sigma2_1.dat", golden_sigma2_1);
        $readmemh("../00_TESTBED/pattern_ibm/golden_sigma2_2.dat", golden_sigma2_2);
    end

        // max cycle
    initial begin
        #1000000;
        $display("============================================");
        $display("Error: Testbench Timeout");
        $display("%d patterns are tested.", golden_idx);
        $display("============================================");
        $finish;
    end

    // reset
    initial begin
        i_code = 3;
        i_clear_and_wen = 0;
        i_S1 = 8'bx;
        i_S2 = 8'bx;
        i_S3 = 8'bx;
        i_S4 = 8'bx;
        i_S5 = 8'bx;
        i_S6 = 8'bx;
        i_S7 = 8'bx;
        i_S8 = 8'bx;

        i_rst_n = 0;
        #(CYCLE*3);
        @(posedge i_clk);
        i_rst_n = 1;
    end

    integer i;
    initial begin
        #1;
        wait(i_rst_n == 1);
        @(posedge i_clk);
        for (i = 0; i < PATTERN_LEN; i = i + 1) begin
            i_clear_and_wen = 1'b1;
            i_code = bch_code[i];
            i_mode = bch_mode[i];
            {i_S1, i_S2, i_S3, i_S4, i_S5, i_S6, i_S7, i_S8} = test_data[i];

            @(posedge i_clk);

            i_clear_and_wen = 1'b0;
            i_code_dly = i_code;

            wait(o_next_S == 1'b1);

            @(posedge i_clk);

            if (i % 10 == 9) begin
                @(posedge i_clk);
            end
        end
    end


    integer error_count;
    integer golden_idx;
    integer k;
    initial begin
        error_count = 0;
        golden_idx = 0;
        wait(i_rst_n == 1);
        while (golden_idx < PATTERN_LEN) begin
            if (o_valid) begin
                if (o_sigma1_0 !== golden_sigma1_0[golden_idx]) begin
                    $display("Error at pattern %d: S1_0 mismatch! Expected: %h, Got: %h", golden_idx, golden_sigma1_0[golden_idx], o_sigma1_0);
                    error_count = error_count + 1;
                end

                if (o_sigma1_1 !== golden_sigma1_1[golden_idx]) begin
                    $display("Error at pattern %d: S1_1 mismatch! Expected: %h, Got: %h", golden_idx, golden_sigma1_1[golden_idx], o_sigma1_1);
                    error_count = error_count + 1;
                end

                if (o_sigma1_2 !== golden_sigma1_2[golden_idx]) begin
                    $display("Error at pattern %d: S1_2 mismatch! Expected: %h, Got: %h", golden_idx, golden_sigma1_2[golden_idx], o_sigma1_2);
                    error_count = error_count + 1;
                end

                if (o_sigma1_3 !== golden_sigma1_3[golden_idx] && i_code_dly == 2'b10) begin
                    $display("Error at pattern %d: S1_3 mismatch! Expected: %h, Got: %h", golden_idx, golden_sigma1_3[golden_idx], o_sigma1_3);
                    error_count = error_count + 1;
                end

                if (o_sigma1_4 !== golden_sigma1_4[golden_idx] && i_code_dly == 2'b10) begin
                    $display("Error at pattern %d: S1_4 mismatch! Expected: %h, Got: %h", golden_idx, golden_sigma1_4[golden_idx], o_sigma1_4);
                    error_count = error_count + 1;
                end

                if (o_sigma2_0 !== golden_sigma2_0[golden_idx]  && i_code_dly != 2'b10) begin
                    $display("Error at pattern %d: S2_0 mismatch! Expected: %h, Got: %h", golden_idx, golden_sigma2_0[golden_idx], o_sigma2_0);
                    error_count = error_count + 1;
                end

                if (o_sigma2_1 !== golden_sigma2_1[golden_idx]  && i_code_dly != 2'b10) begin
                    $display("Error at pattern %d: S2_1 mismatch! Expected: %h, Got: %h", golden_idx, golden_sigma2_1[golden_idx], o_sigma2_1);
                    error_count = error_count + 1;
                end

                if (o_sigma2_2 !== golden_sigma2_2[golden_idx]  && i_code_dly != 2'b10) begin
                    $display("Error at pattern %d: S2_2 mismatch! Expected: %h, Got: %h", golden_idx, golden_sigma2_2[golden_idx], o_sigma2_2);
                    error_count = error_count + 1;
                end

                wait(o_valid === 0 || golden_idx == PATTERN_LEN - 1);
                golden_idx = golden_idx + 1;
            end

            @(posedge i_clk);
        end

        if (error_count == 0) begin
            $display("============================================");
            $display("All patterns passed!");
            $display("============================================");
        end else begin
            $display("============================================");
            $display("Total %0d errors found!", error_count);
            $display("============================================");
        end

        $finish;

    end
endmodule