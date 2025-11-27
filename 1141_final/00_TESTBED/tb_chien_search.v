`timescale 1ns/1ps

module tb_chien_search;
    parameter CYCLE = 10;
    parameter PATTERN_LEN = 30;
    parameter PATTERN_TWO_LEN = 10;
    parameter BCH63_51 = 2'b00;
    parameter BCH255_239 = 2'b01;
    parameter BCH1023_983 = 2'b10;


    reg i_clk;
    reg i_rst_n;
    reg i_mode;
    reg i_mode_dly;
    reg [1:0] i_code;
    reg [1:0] i_code_dly;
    reg i_clear_and_wen;
    reg [9:0] i_sigma1_0;
    reg [9:0] i_sigma1_1;
    reg [9:0] i_sigma1_2;
    reg [9:0] i_sigma1_3;
    reg [9:0] i_sigma1_4;
    reg [9:0] i_sigma2_0;
    reg [9:0] i_sigma2_1;
    reg [9:0] i_sigma2_2;
    wire [9:0] o_err_loc0;
    wire [9:0] o_err_loc1;
    wire [9:0] o_err_loc2;
    wire [9:0] o_err_loc3;
    wire [2:0] o_num_err;
    wire o_correct;
    wire o_valid;

    reg [79:0] test_data[PATTERN_LEN-1:0];
    reg [1:0] bch_code[PATTERN_LEN-1:0];
    reg bch_mode[PATTERN_LEN-1:0];
    reg [9:0] golden_err_loc0[PATTERN_LEN + PATTERN_TWO_LEN-1:0];
    reg [9:0] golden_err_loc1[PATTERN_LEN + PATTERN_TWO_LEN-1:0];
    reg [9:0] golden_err_loc2[PATTERN_LEN + PATTERN_TWO_LEN-1:0];
    reg [9:0] golden_err_loc3[PATTERN_LEN + PATTERN_TWO_LEN-1:0];
    reg [2:0] golden_num_err[PATTERN_LEN + PATTERN_TWO_LEN-1:0];
    reg golden_correct[PATTERN_LEN + PATTERN_TWO_LEN-1:0];

    // Instantiate DUT
    chien_search u_chien_search (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_mode(i_mode),
        .i_code(i_code),
        .i_clear_and_wen(i_clear_and_wen),
        .i_sigma1_0(i_sigma1_0),
        .i_sigma1_1(i_sigma1_1),
        .i_sigma1_2(i_sigma1_2),
        .i_sigma1_3(i_sigma1_3),
        .i_sigma1_4(i_sigma1_4),
        .i_sigma2_0(i_sigma2_0),
        .i_sigma2_1(i_sigma2_1),
        .i_sigma2_2(i_sigma2_2),
        .o_err_loc0(o_err_loc0),
        .o_err_loc1(o_err_loc1),
        .o_err_loc2(o_err_loc2),
        .o_err_loc3(o_err_loc3),
        .o_num_err(o_num_err),
        .o_correct(o_correct),
        .o_valid(o_valid)
    );


    // Clock Generation
    initial begin
        i_clk = 0;
        forever #(CYCLE/2) i_clk = ~i_clk;
    end

    initial begin
        $fsdbDumpfile("tb_chien_search.fsdb");
        $fsdbDumpvars(0, tb_chien_search, "+mda");
    end

    // Read pattern files
    initial begin
        $readmemh("../00_TESTBED/pattern_chien_search/chien_search_data.dat",  test_data);
        $readmemh("../00_TESTBED/pattern_chien_search/chien_search_code.dat",  bch_code);
        $readmemh("../00_TESTBED/pattern_chien_search/chien_search_mode.dat",  bch_mode);
        $readmemh("../00_TESTBED/pattern_chien_search/chien_search_err_loc0.dat",  golden_err_loc0);
        $readmemh("../00_TESTBED/pattern_chien_search/chien_search_err_loc1.dat",  golden_err_loc1);
        $readmemh("../00_TESTBED/pattern_chien_search/chien_search_err_loc2.dat",  golden_err_loc2);
        $readmemh("../00_TESTBED/pattern_chien_search/chien_search_err_loc3.dat",  golden_err_loc3);
        $readmemh("../00_TESTBED/pattern_chien_search/chien_search_num_err.dat",   golden_num_err);
        $readmemh("../00_TESTBED/pattern_chien_search/chien_search_correct.dat",   golden_correct);
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
        i_rst_n = 0;
        i_mode = 0;
        i_code = BCH63_51;
        i_clear_and_wen = 0;
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
            {i_mode,
             i_code,
             i_sigma1_0,
             i_sigma1_1,
             i_sigma1_2,
             i_sigma1_3,
             i_sigma1_4,
             i_sigma2_0,
             i_sigma2_1,
             i_sigma2_2} = test_data[i];

            i_clear_and_wen = 1'b1;
            i_code = bch_code[i];
            i_mode = bch_mode[i];

            @(posedge i_clk);

            i_clear_and_wen = 1'b0;
            i_code_dly = i_code;
            i_mode_dly = i_mode;

            wait(o_valid == 1'b1);
            @(posedge i_clk);

            if (i_mode === 1'b1 && i_code !== BCH1023_983) begin
                wait(o_valid == 1'b1);
                @(posedge i_clk);
            end

            if (i != PATTERN_LEN-1 && (i_mode_dly != bch_mode[i+1] || i_code_dly != bch_code[i+1])) begin
                @(posedge i_clk);
                @(posedge i_clk);
                @(posedge i_clk);
                @(posedge i_clk);
                @(posedge i_clk);
                @(posedge i_clk);
                @(posedge i_clk);
                @(posedge i_clk);
                @(posedge i_clk);
                @(posedge i_clk);
            end
        end
    end


    integer error_count;
    integer pattern_idx;  // 目前是第幾個 input pattern
    integer is_repeat;    // 0=>第一個output, 1=>第二個output(僅雙輸出情況)
    integer cur_out;      // 1 或 2，用於列印

    initial begin
        error_count = 0;
        golden_idx  = 0;
        pattern_idx = 0;
        is_repeat   = 0;

        wait(i_rst_n == 1);
        @(posedge i_clk);

        while (golden_idx < PATTERN_LEN + PATTERN_TWO_LEN) begin
            if (o_valid) begin
                // 這次列印用的 output 序號（在更新 is_repeat 之前先記下）
                cur_out = is_repeat + 1;

                // === 比對並在訊息中帶入 input/output 編號 ===
                if (o_err_loc0 !== golden_err_loc0[golden_idx]) begin
                    $display("[Error][InPat %0d][Out %0d] err_loc0 mismatch! exp=%0d got=%0d",
                             pattern_idx, cur_out, golden_err_loc0[golden_idx], o_err_loc0);
                    error_count = error_count + 1;
                end
                else begin
                    $display("[Info ][InPat %0d][Out %0d] err_loc0 match. value=%0d",
                             pattern_idx, cur_out, o_err_loc0);
                end

                if (o_err_loc1 !== golden_err_loc1[golden_idx]) begin
                    $display("[Error][InPat %0d][Out %0d] err_loc1 mismatch! exp=%0d got=%0d",
                             pattern_idx, cur_out, golden_err_loc1[golden_idx], o_err_loc1);
                    error_count = error_count + 1;
                end
                else begin
                    $display("[Info ][InPat %0d][Out %0d] err_loc1 match. value=%0d",
                             pattern_idx, cur_out, o_err_loc1);
                end

                if (o_err_loc2 !== golden_err_loc2[golden_idx] &&
                    i_code_dly === BCH1023_983) begin
                    $display("[Error][InPat %0d][Out %0d] err_loc2 mismatch! exp=%0d got=%0d",
                             pattern_idx, cur_out, golden_err_loc2[golden_idx], o_err_loc2);
                    error_count = error_count + 1;
                end
                else if (i_code_dly === BCH1023_983) begin
                    $display("[Info ][InPat %0d][Out %0d] err_loc2 match. value=%0d",
                             pattern_idx, cur_out, o_err_loc2);
                end

                if (o_err_loc3 !== golden_err_loc3[golden_idx] &&
                    i_code_dly === BCH1023_983) begin
                    $display("[Error][InPat %0d][Out %0d] err_loc3 mismatch! exp=%0d got=%0d",
                             pattern_idx, cur_out, golden_err_loc3[golden_idx], o_err_loc3);
                    error_count = error_count + 1;
                end
                else if (i_code_dly === BCH1023_983) begin
                    $display("[Info ][InPat %0d][Out %0d] err_loc3 match. value=%0d",
                             pattern_idx, cur_out, o_err_loc3);
                end

                if (o_num_err !== golden_num_err[golden_idx]) begin
                    $display("[Error][InPat %0d][Out %0d] num_err mismatch! exp=%0d got=%0d",
                             pattern_idx, cur_out, golden_num_err[golden_idx], o_num_err);
                    error_count = error_count + 1;
                end
                else begin
                    $display("[Info ][InPat %0d][Out %0d] num_err match. value=%0d",
                             pattern_idx, cur_out, o_num_err);
                end

                // 前進 golden 索引（每個 o_valid 都會消耗一筆 golden）
                golden_idx = golden_idx + 1;

                // === 維護 input pattern 與 output 編號 ===
                if (i_mode_dly === 1'b1 && i_code_dly !== BCH1023_983) begin
                    // 這個 input 會吐兩筆
                    if (is_repeat == 0) begin
                        // 剛輸出第 1 筆，下一次還是同一個 input
                        is_repeat = 1;
                    end else begin
                        // 剛輸出第 2 筆，換到下一個 input
                        is_repeat  = 0;
                        pattern_idx = pattern_idx + 1;
                    end
                end else begin
                    // 只會吐一筆，直接換到下一個 input
                    is_repeat  = 0;
                    pattern_idx = pattern_idx + 1;
                end
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