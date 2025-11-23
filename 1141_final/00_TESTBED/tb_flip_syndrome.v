`timescale 1ns/1ps

module tb_flip_syndrome;
    parameter CYCLE = 10;
    parameter PATTERN_LEN = 10;
    parameter BCH63_51 = 2'b00;
    parameter BCH255_239 = 2'b01;
    parameter BCH1023_983 = 2'b10;

    reg         i_clk;
    reg         i_rst_n;
    reg  [1:0]  i_code;
    reg         i_clear_and_wen;
    reg         i_wen;
    reg  [63:0]  i_data;
    wire [9:0]  o_tp1_S1;
    wire [9:0]  o_tp1_S2;
    wire [9:0]  o_tp1_S3;
    wire [9:0]  o_tp1_S4;
    wire [9:0]  o_tp1_S5;
    wire [9:0]  o_tp1_S6;
    wire [9:0]  o_tp1_S7;
    wire [9:0]  o_tp1_S8;
    wire        o_tp1_odd_valid;
    wire        o_tp1_all_valid;
    wire [9:0]  o_flip_alpha_S1_1;
    wire [9:0]  o_flip_alpha_S1_2;
    wire [9:0]  o_flip_alpha_S3_1;
    wire [9:0]  o_flip_alpha_S3_2;
    wire [9:0]  o_flip_alpha_S5_1;
    wire [9:0]  o_flip_alpha_S5_2;
    wire [9:0]  o_flip_alpha_S7_1;
    wire [9:0]  o_flip_alpha_S7_2;
    wire [9:0]  o_flip_pos1;
    wire [9:0]  o_flip_pos2;
    wire        o_flip_valid;

    wire [9:0]  o_tp2_S1;
    wire [9:0]  o_tp2_S2;
    wire [9:0]  o_tp2_S3;
    wire [9:0]  o_tp2_S4;
    wire [9:0]  o_tp2_S5;
    wire [9:0]  o_tp2_S6;
    wire [9:0]  o_tp2_S7;
    wire [9:0]  o_tp2_S8;
    wire [9:0]  o_tp3_S1;
    wire [9:0]  o_tp3_S2;
    wire [9:0]  o_tp3_S3;
    wire [9:0]  o_tp3_S4;
    wire [9:0]  o_tp3_S5;
    wire [9:0]  o_tp3_S6;
    wire [9:0]  o_tp3_S7;
    wire [9:0]  o_tp3_S8;
    wire [9:0]  o_tp4_S1;
    wire [9:0]  o_tp4_S2;
    wire [9:0]  o_tp4_S3;
    wire [9:0]  o_tp4_S4;
    wire [9:0]  o_tp4_S5;
    wire [9:0]  o_tp4_S6;
    wire [9:0]  o_tp4_S7;
    wire [9:0]  o_tp4_S8;
    wire        o_tp_valid;

    reg [8191:0] test_data[PATTERN_LEN-1:0];
    reg [1:0] bch_code[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_S1[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_S2[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_S3[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_S4[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_S5[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_S6[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_S7[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_S8[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_S1[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_S2[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_S3[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_S4[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_S5[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_S6[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_S7[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_S8[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_S1[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_S2[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_S3[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_S4[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_S5[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_S6[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_S7[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_S8[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_S1[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_S2[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_S3[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_S4[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_S5[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_S6[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_S7[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_S8[PATTERN_LEN-1:0];
    reg [9:0] golden_pos1[PATTERN_LEN-1:0];
    reg [9:0] golden_pos2[PATTERN_LEN-1:0];

    // Instantiate DUT
    syndrome u_syndrome (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_code(i_code),
        .i_clear_and_wen(i_clear_and_wen),
        .i_wen(i_wen),
        .i_data(i_data),
        .o_S1(o_tp1_S1),
        .o_S2(o_tp1_S2),
        .o_S3(o_tp1_S3),
        .o_S4(o_tp1_S4),
        .o_S5(o_tp1_S5),
        .o_S6(o_tp1_S6),
        .o_S7(o_tp1_S7),
        .o_S8(o_tp1_S8),
        .o_odd_s_valid(o_tp1_odd_valid),
        .o_all_s_valid(o_tp1_all_valid),
        .o_flip_alpha_S1_1(o_flip_alpha_S1_1),
        .o_flip_alpha_S1_2(o_flip_alpha_S1_2),
        .o_flip_alpha_S3_1(o_flip_alpha_S3_1),
        .o_flip_alpha_S3_2(o_flip_alpha_S3_2),
        .o_flip_alpha_S5_1(o_flip_alpha_S5_1),
        .o_flip_alpha_S5_2(o_flip_alpha_S5_2),
        .o_flip_alpha_S7_1(o_flip_alpha_S7_1),
        .o_flip_alpha_S7_2(o_flip_alpha_S7_2),
        .o_flip_pos1(o_flip_pos1),
        .o_flip_pos2(o_flip_pos2),
        .o_flip_valid(o_flip_valid)
    );

    flip_syndrome u_flip_syndrome (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_code(i_code),
        .i_S1(o_tp1_S1),
        .i_S2(o_tp1_S2),
        .i_S3(o_tp1_S3),
        .i_S4(o_tp1_S4),
        .i_S5(o_tp1_S5),
        .i_S6(o_tp1_S6),
        .i_S7(o_tp1_S7),
        .i_S8(o_tp1_S8),
        .i_syndrome_valid(o_tp1_odd_valid),
        .i_flip_alpha_S1_1(o_flip_alpha_S1_1),
        .i_flip_alpha_S1_2(o_flip_alpha_S1_2),
        .i_flip_alpha_S3_1(o_flip_alpha_S3_1),
        .i_flip_alpha_S3_2(o_flip_alpha_S3_2),
        .i_flip_alpha_S5_1(o_flip_alpha_S5_1),
        .i_flip_alpha_S5_2(o_flip_alpha_S5_2),
        .i_flip_alpha_S7_1(o_flip_alpha_S7_1),
        .i_flip_alpha_S7_2(o_flip_alpha_S7_2),
        .i_flip_alpha_valid(o_flip_valid),
        .o_tp2_S1(o_tp2_S1),
        .o_tp2_S2(o_tp2_S2),
        .o_tp2_S3(o_tp2_S3),
        .o_tp2_S4(o_tp2_S4),
        .o_tp2_S5(o_tp2_S5),
        .o_tp2_S6(o_tp2_S6),
        .o_tp2_S7(o_tp2_S7),
        .o_tp2_S8(o_tp2_S8),
        .o_tp3_S1(o_tp3_S1),
        .o_tp3_S2(o_tp3_S2),
        .o_tp3_S3(o_tp3_S3),
        .o_tp3_S4(o_tp3_S4),
        .o_tp3_S5(o_tp3_S5),
        .o_tp3_S6(o_tp3_S6),
        .o_tp3_S7(o_tp3_S7),
        .o_tp3_S8(o_tp3_S8),
        .o_tp4_S1(o_tp4_S1),
        .o_tp4_S2(o_tp4_S2),
        .o_tp4_S3(o_tp4_S3),
        .o_tp4_S4(o_tp4_S4),
        .o_tp4_S5(o_tp4_S5),
        .o_tp4_S6(o_tp4_S6),
        .o_tp4_S7(o_tp4_S7),
        .o_tp4_S8(o_tp4_S8),
        .o_tp_valid(o_tp_valid)
    );


    // Clock Generation
    initial begin
        i_clk = 0;
        forever #(CYCLE/2) i_clk = ~i_clk;
    end

    initial begin
        $fsdbDumpfile("tb_flip_syndrome.fsdb");
        $fsdbDumpvars(0, tb_flip_syndrome);
    end

    // read file
    initial begin
        $readmemh("../00_TESTBED/pattern_flip_syndrome/soft_data.dat", test_data);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/test_code.dat", bch_code);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp1_S1.dat", golden_tp1_S1);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp1_S2.dat", golden_tp1_S2);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp1_S3.dat", golden_tp1_S3);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp1_S4.dat", golden_tp1_S4);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp1_S5.dat", golden_tp1_S5);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp1_S6.dat", golden_tp1_S6);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp1_S7.dat", golden_tp1_S7);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp1_S8.dat", golden_tp1_S8);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp2_S1.dat", golden_tp2_S1);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp2_S2.dat", golden_tp2_S2);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp2_S3.dat", golden_tp2_S3);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp2_S4.dat", golden_tp2_S4);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp2_S5.dat", golden_tp2_S5);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp2_S6.dat", golden_tp2_S6);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp2_S7.dat", golden_tp2_S7);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp2_S8.dat", golden_tp2_S8);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp3_S1.dat", golden_tp3_S1);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp3_S2.dat", golden_tp3_S2);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp3_S3.dat", golden_tp3_S3);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp3_S4.dat", golden_tp3_S4);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp3_S5.dat", golden_tp3_S5);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp3_S6.dat", golden_tp3_S6);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp3_S7.dat", golden_tp3_S7);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp3_S8.dat", golden_tp3_S8);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp4_S1.dat", golden_tp4_S1);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp4_S2.dat", golden_tp4_S2);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp4_S3.dat", golden_tp4_S3);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp4_S4.dat", golden_tp4_S4);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp4_S5.dat", golden_tp4_S5);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp4_S6.dat", golden_tp4_S6);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp4_S7.dat", golden_tp4_S7);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_tp4_S8.dat", golden_tp4_S8);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_pos1.dat", golden_pos1);
        $readmemb("../00_TESTBED/pattern_flip_syndrome/golden_pos2.dat", golden_pos2);
    end
    
    // max cycle
    integer golden_idx;
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
        i_wen = 0;
        i_data = 8'bx;

        i_rst_n = 0;
        #(CYCLE*3);
        @(posedge i_clk);
        i_rst_n = 1;
    end

    // input stimulus
    integer i, j, code_length;
    reg [8191:0] curr_data;
    initial begin
        #1;
        wait(i_rst_n == 1);
        for (i = 0; i < PATTERN_LEN; i = i + 1) begin
            // Configure BCH code
            i_code = bch_code[i];
            curr_data = test_data[i];
            if (i_code === BCH63_51)
                code_length = 8;
            else if (i_code === BCH255_239)
                code_length = 32;
            else if (i_code === BCH1023_983)
                code_length = 128;
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
                i_data = curr_data[8191 -: 64];
                curr_data = curr_data << 64;
                @(posedge i_clk);
            end
            i_wen = 0;

            wait(o_tp_valid == 1);
            @(posedge i_clk);
            @(posedge i_clk);
        end
    end

    integer error_count;  // 新增：錯誤計數
    // 結果檢查
    // 每一個 valid 只檢查一次用的旗標
    reg flip_checked;
    reg tp1_odd_checked;
    reg tp1_all_checked;
    reg tp_checked;

    // 結果檢查
    initial begin
        error_count      = 0;
        golden_idx       = 0;
        flip_checked     = 0;
        tp1_odd_checked  = 0;
        tp1_all_checked  = 0;
        tp_checked       = 0;

        // 等待 reset 解除
        wait (i_rst_n == 1);
        @(posedge i_clk);

        while (golden_idx < PATTERN_LEN) begin
            @(posedge i_clk);

            // -------------------------------------------------
            // 1) 檢查 flip 位置 (由 syndrome 輸出) ：只在本 pattern
            //    第一次 o_flip_valid 為 1 時檢查
            // -------------------------------------------------
            if (o_flip_valid && !flip_checked) begin
                if (o_flip_pos1 !== golden_pos1[golden_idx]) begin
                    $display("Error: Pattern %0d, flip_pos1 Mismatch! Expected: %d, Got: %d",
                             golden_idx, golden_pos1[golden_idx], o_flip_pos1);
                    error_count = error_count + 1;
                end
                if (o_flip_pos2 !== golden_pos2[golden_idx]) begin
                    $display("Error: Pattern %0d, flip_pos2 Mismatch! Expected: %d, Got: %d",
                             golden_idx, golden_pos2[golden_idx], o_flip_pos2);
                    error_count = error_count + 1;
                end
                flip_checked = 1;  // 這個 pattern 的 flip 已經檢查過
            end

            // -------------------------------------------------
            // 2) 檢查 tp1 (odd_valid)：只在本 pattern
            //    第一次 o_tp1_odd_valid 為 1 時檢查
            // -------------------------------------------------
            if (o_tp1_odd_valid && !tp1_odd_checked) begin
                if (o_tp1_S1 !== golden_tp1_S1[golden_idx]) begin
                    $display("Error: Pattern %0d, tp1 S1 (odd) Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp1_S1[golden_idx], o_tp1_S1);
                    error_count = error_count + 1;
                end
                if (o_tp1_S3 !== golden_tp1_S3[golden_idx]) begin
                    $display("Error: Pattern %0d, tp1 S3 (odd) Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp1_S3[golden_idx], o_tp1_S3);
                    error_count = error_count + 1;
                end
                if (i_code === BCH1023_983) begin
                    if (o_tp1_S5 !== golden_tp1_S5[golden_idx]) begin
                        $display("Error: Pattern %0d, tp1 S5 (odd) Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp1_S5[golden_idx], o_tp1_S5);
                        error_count = error_count + 1;
                    end
                    if (o_tp1_S7 !== golden_tp1_S7[golden_idx]) begin
                        $display("Error: Pattern %0d, tp1 S7 (odd) Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp1_S7[golden_idx], o_tp1_S7);
                        error_count = error_count + 1;
                    end
                end
                tp1_odd_checked = 1;
            end

            // -------------------------------------------------
            // 3) 檢查 tp1 all_valid：只在本 pattern
            //    第一次 o_tp1_all_valid 為 1 時檢查
            // -------------------------------------------------
            if (o_tp1_all_valid && !tp1_all_checked) begin
                if (o_tp1_S1 !== golden_tp1_S1[golden_idx]) begin
                    $display("Error: Pattern %0d, tp1 S1 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp1_S1[golden_idx], o_tp1_S1);
                    error_count = error_count + 1;
                end
                if (o_tp1_S2 !== golden_tp1_S2[golden_idx]) begin
                    $display("Error: Pattern %0d, tp1 S2 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp1_S2[golden_idx], o_tp1_S2);
                    error_count = error_count + 1;
                end
                if (o_tp1_S3 !== golden_tp1_S3[golden_idx]) begin
                    $display("Error: Pattern %0d, tp1 S3 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp1_S3[golden_idx], o_tp1_S3);
                    error_count = error_count + 1;
                end
                if (o_tp1_S4 !== golden_tp1_S4[golden_idx]) begin
                    $display("Error: Pattern %0d, tp1 S4 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp1_S4[golden_idx], o_tp1_S4);
                    error_count = error_count + 1;
                end

                if (i_code === BCH1023_983) begin
                    if (o_tp1_S5 !== golden_tp1_S5[golden_idx]) begin
                        $display("Error: Pattern %0d, tp1 S5 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp1_S5[golden_idx], o_tp1_S5);
                        error_count = error_count + 1;
                    end
                    if (o_tp1_S6 !== golden_tp1_S6[golden_idx]) begin
                        $display("Error: Pattern %0d, tp1 S6 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp1_S6[golden_idx], o_tp1_S6);
                        error_count = error_count + 1;
                    end
                    if (o_tp1_S7 !== golden_tp1_S7[golden_idx]) begin
                        $display("Error: Pattern %0d, tp1 S7 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp1_S7[golden_idx], o_tp1_S7);
                        error_count = error_count + 1;
                    end
                    if (o_tp1_S8 !== golden_tp1_S8[golden_idx]) begin
                        $display("Error: Pattern %0d, tp1 S8 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp1_S8[golden_idx], o_tp1_S8);
                        error_count = error_count + 1;
                    end
                end
                tp1_all_checked = 1;
            end

            // -------------------------------------------------
            // 4) 檢查 flip_syndrome 的 tp2 / tp3 / tp4
            //    只在本 pattern 第一次 o_tp_valid 為 1 時檢查
            // -------------------------------------------------
            if (o_tp_valid && !tp_checked) begin
                // ---------- tp2 ----------
                if (o_tp2_S1 !== golden_tp2_S1[golden_idx]) begin
                    $display("Error: Pattern %0d, tp2 S1 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp2_S1[golden_idx], o_tp2_S1);
                    error_count = error_count + 1;
                end
                if (o_tp2_S2 !== golden_tp2_S2[golden_idx]) begin
                    $display("Error: Pattern %0d, tp2 S2 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp2_S2[golden_idx], o_tp2_S2);
                    error_count = error_count + 1;
                end
                if (o_tp2_S3 !== golden_tp2_S3[golden_idx]) begin
                    $display("Error: Pattern %0d, tp2 S3 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp2_S3[golden_idx], o_tp2_S3);
                    error_count = error_count + 1;
                end
                if (o_tp2_S4 !== golden_tp2_S4[golden_idx]) begin
                    $display("Error: Pattern %0d, tp2 S4 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp2_S4[golden_idx], o_tp2_S4);
                    error_count = error_count + 1;
                end
                if (i_code === BCH1023_983) begin
                    if (o_tp2_S5 !== golden_tp2_S5[golden_idx]) begin
                        $display("Error: Pattern %0d, tp2 S5 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp2_S5[golden_idx], o_tp2_S5);
                        error_count = error_count + 1;
                    end
                    if (o_tp2_S6 !== golden_tp2_S6[golden_idx]) begin
                        $display("Error: Pattern %0d, tp2 S6 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp2_S6[golden_idx], o_tp2_S6);
                        error_count = error_count + 1;
                    end
                    if (o_tp2_S7 !== golden_tp2_S7[golden_idx]) begin
                        $display("Error: Pattern %0d, tp2 S7 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp2_S7[golden_idx], o_tp2_S7);
                        error_count = error_count + 1;
                    end
                    if (o_tp2_S8 !== golden_tp2_S8[golden_idx]) begin
                        $display("Error: Pattern %0d, tp2 S8 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp2_S8[golden_idx], o_tp2_S8);
                        error_count = error_count + 1;
                    end
                end

                // ---------- tp3 ----------
                if (o_tp3_S1 !== golden_tp3_S1[golden_idx]) begin
                    $display("Error: Pattern %0d, tp3 S1 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp3_S1[golden_idx], o_tp3_S1);
                    error_count = error_count + 1;
                end
                if (o_tp3_S2 !== golden_tp3_S2[golden_idx]) begin
                    $display("Error: Pattern %0d, tp3 S2 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp3_S2[golden_idx], o_tp3_S2);
                    error_count = error_count + 1;
                end
                if (o_tp3_S3 !== golden_tp3_S3[golden_idx]) begin
                    $display("Error: Pattern %0d, tp3 S3 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp3_S3[golden_idx], o_tp3_S3);
                    error_count = error_count + 1;
                end
                if (o_tp3_S4 !== golden_tp3_S4[golden_idx]) begin
                    $display("Error: Pattern %0d, tp3 S4 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp3_S4[golden_idx], o_tp3_S4);
                    error_count = error_count + 1;
                end
                if (i_code === BCH1023_983) begin
                    if (o_tp3_S5 !== golden_tp3_S5[golden_idx]) begin
                        $display("Error: Pattern %0d, tp3 S5 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp3_S5[golden_idx], o_tp3_S5);
                        error_count = error_count + 1;
                    end
                    if (o_tp3_S6 !== golden_tp3_S6[golden_idx]) begin
                        $display("Error: Pattern %0d, tp3 S6 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp3_S6[golden_idx], o_tp3_S6);
                        error_count = error_count + 1;
                    end
                    if (o_tp3_S7 !== golden_tp3_S7[golden_idx]) begin
                        $display("Error: Pattern %0d, tp3 S7 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp3_S7[golden_idx], o_tp3_S7);
                        error_count = error_count + 1;
                    end
                    if (o_tp3_S8 !== golden_tp3_S8[golden_idx]) begin
                        $display("Error: Pattern %0d, tp3 S8 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp3_S8[golden_idx], o_tp3_S8);
                        error_count = error_count + 1;
                    end
                end

                // ---------- tp4 ----------
                if (o_tp4_S1 !== golden_tp4_S1[golden_idx]) begin
                    $display("Error: Pattern %0d, tp4 S1 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp4_S1[golden_idx], o_tp4_S1);
                    error_count = error_count + 1;
                end
                if (o_tp4_S2 !== golden_tp4_S2[golden_idx]) begin
                    $display("Error: Pattern %0d, tp4 S2 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp4_S2[golden_idx], o_tp4_S2);
                    error_count = error_count + 1;
                end
                if (o_tp4_S3 !== golden_tp4_S3[golden_idx]) begin
                    $display("Error: Pattern %0d, tp4 S3 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp4_S3[golden_idx], o_tp4_S3);
                    error_count = error_count + 1;
                end
                if (o_tp4_S4 !== golden_tp4_S4[golden_idx]) begin
                    $display("Error: Pattern %0d, tp4 S4 Mismatch! Expected: %h, Got: %h",
                             golden_idx, golden_tp4_S4[golden_idx], o_tp4_S4);
                    error_count = error_count + 1;
                end
                if (i_code === BCH1023_983) begin
                    if (o_tp4_S5 !== golden_tp4_S5[golden_idx]) begin
                        $display("Error: Pattern %0d, tp4 S5 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp4_S5[golden_idx], o_tp4_S5);
                        error_count = error_count + 1;
                    end
                    if (o_tp4_S6 !== golden_tp4_S6[golden_idx]) begin
                        $display("Error: Pattern %0d, tp4 S6 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp4_S6[golden_idx], o_tp4_S6);
                        error_count = error_count + 1;
                    end
                    if (o_tp4_S7 !== golden_tp4_S7[golden_idx]) begin
                        $display("Error: Pattern %0d, tp4 S7 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp4_S7[golden_idx], o_tp4_S7);
                        error_count = error_count + 1;
                    end
                    if (o_tp4_S8 !== golden_tp4_S8[golden_idx]) begin
                        $display("Error: Pattern %0d, tp4 S8 Mismatch! Expected: %h, Got: %h",
                                 golden_idx, golden_tp4_S8[golden_idx], o_tp4_S8);
                        error_count = error_count + 1;
                    end
                end

                tp_checked = 1;  // tp2/3/4 已檢查
            end

            // -------------------------------------------------
            // 5) 所有 valid 都檢查過一次後，才進到下一個 pattern
            // -------------------------------------------------
            if (flip_checked && tp1_odd_checked && tp1_all_checked && tp_checked && 
                !o_flip_valid && !o_tp1_odd_valid && ! o_tp1_all_valid && ! o_tp_valid || golden_idx == PATTERN_LEN - 1) begin
                golden_idx = golden_idx + 1;

                // 清旗標，準備下一個 pattern
                flip_checked     = 0;
                tp1_odd_checked  = 0;
                tp1_all_checked  = 0;
                tp_checked       = 0;
            end
        end

        // 總結
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