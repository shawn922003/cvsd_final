`timescale 1ns/1ps

module tb_error_bit_saver;
    parameter CYCLE = 10;
    parameter PATTERN_LEN = 30;
    parameter BCH63_51 = 2'b00;
    parameter BCH255_239 = 2'b01;
    parameter BCH1023_983 = 2'b10;

    reg i_clk;
    reg i_rst_n;
    reg llr_mem_i_wen;
    reg [63:0] llr_mem_i_data;
    reg [9:0] llr_mem_i_pos0;
    reg [9:0] llr_mem_i_pos1;
    reg [9:0] llr_mem_i_pos2;
    reg [9:0] llr_mem_i_pos3;
    reg [9:0] llr_mem_i_pos4;
    reg [9:0] llr_mem_i_pos5;
    wire [6:0] llr_mem_o_data0;
    wire [6:0] llr_mem_o_data1;
    wire [6:0] llr_mem_o_data2;
    wire [6:0] llr_mem_o_data3;
    wire [6:0] llr_mem_o_data4;
    wire [6:0] llr_mem_o_data5;

    reg [1:0] i_code;
    reg i_clear;
    reg i_err_valid_pulse;
    reg [9:0] i_err_loc0;
    reg [9:0] i_err_loc1;
    reg [9:0] i_err_loc2;
    reg [9:0] i_err_loc3;
    reg [2:0] i_num_err;
    reg i_correct;
    reg [9:0] i_flip_pos1;
    reg [9:0] i_flip_pos2;
    reg i_flip_valid;
    wire [9:0] o_tp1_err_loc0;
    wire [9:0] o_tp1_err_loc1;
    wire [9:0] o_tp1_err_loc2;
    wire [9:0] o_tp1_err_loc3;
    wire [9:0] o_tp1_err_loc4;
    wire [9:0] o_tp1_err_loc5;
    wire [2:0] o_tp1_num_err;
    wire o_tp1_correct;
    wire [9:0] o_tp2_err_loc0;
    wire [9:0] o_tp2_err_loc1;
    wire [9:0] o_tp2_err_loc2;
    wire [9:0] o_tp2_err_loc3;
    wire [9:0] o_tp2_err_loc4;
    wire [9:0] o_tp2_err_loc5;
    wire [2:0] o_tp2_num_err;
    wire o_tp2_correct;
    wire [9:0] o_tp3_err_loc0;
    wire [9:0] o_tp3_err_loc1;
    wire [9:0] o_tp3_err_loc2;
    wire [9:0] o_tp3_err_loc3;
    wire [9:0] o_tp3_err_loc4;
    wire [9:0] o_tp3_err_loc5;
    wire [2:0] o_tp3_num_err;
    wire o_tp3_correct;
    wire [9:0] o_tp4_err_loc0;
    wire [9:0] o_tp4_err_loc1;
    wire [9:0] o_tp4_err_loc2;
    wire [9:0] o_tp4_err_loc3;
    wire [9:0] o_tp4_err_loc4;
    wire [9:0] o_tp4_err_loc5;
    wire [2:0] o_tp4_num_err;
    wire o_tp4_correct;
    wire [2:0] mim_llr_tp;
    wire o_valid;

    reg [1024*8-1:0] test_llr_mem_data[PATTERN_LEN-1:0];
    reg [1:0] test_bch_code[PATTERN_LEN-1:0];
    reg [39:0] test_err_loc0[PATTERN_LEN-1:0];
    reg [39:0] test_err_loc1[PATTERN_LEN-1:0];
    reg [39:0] test_err_loc2[PATTERN_LEN-1:0];
    reg [39:0] test_err_loc3[PATTERN_LEN-1:0];
    reg [11:0] test_num_err[PATTERN_LEN-1:0];
    reg [3:0] test_correct[PATTERN_LEN-1:0];
    reg [9:0] test_flip_pos1[PATTERN_LEN-1:0];
    reg [9:0] test_flip_pos2[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_err_loc0[PATTERN_LEN-1:0];  
    reg [9:0] golden_tp1_err_loc1[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_err_loc2[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_err_loc3[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_err_loc4[PATTERN_LEN-1:0];
    reg [9:0] golden_tp1_err_loc5[PATTERN_LEN-1:0];
    reg [2:0] golden_tp1_num_err[PATTERN_LEN-1:0];
    reg golden_tp1_correct[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_err_loc0[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_err_loc1[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_err_loc2[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_err_loc3[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_err_loc4[PATTERN_LEN-1:0];
    reg [9:0] golden_tp2_err_loc5[PATTERN_LEN-1:0];
    reg [2:0] golden_tp2_num_err[PATTERN_LEN-1:0];
    reg golden_tp2_correct[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_err_loc0[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_err_loc1[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_err_loc2[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_err_loc3[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_err_loc4[PATTERN_LEN-1:0];
    reg [9:0] golden_tp3_err_loc5[PATTERN_LEN-1:0];
    reg [2:0] golden_tp3_num_err[PATTERN_LEN-1:0];
    reg golden_tp3_correct[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_err_loc0[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_err_loc1[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_err_loc2[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_err_loc3[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_err_loc4[PATTERN_LEN-1:0];
    reg [9:0] golden_tp4_err_loc5[PATTERN_LEN-1:0];
    reg [2:0] golden_tp4_num_err[PATTERN_LEN-1:0];
    reg golden_tp4_correct[PATTERN_LEN-1:0];
    reg [2:0] golden_mim_llr_tp[PATTERN_LEN-1:0];




    llr_mem u_llr_mem (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_wen(llr_mem_i_wen),
        .i_data(llr_mem_i_data),
        .i_pos0(llr_mem_i_pos0),
        .i_pos1(llr_mem_i_pos1),
        .i_pos2(llr_mem_i_pos2),
        .i_pos3(llr_mem_i_pos3),
        .i_pos4(llr_mem_i_pos4),
        .i_pos5(llr_mem_i_pos5),
        .o_data0(llr_mem_o_data0),
        .o_data1(llr_mem_o_data1),
        .o_data2(llr_mem_o_data2),
        .o_data3(llr_mem_o_data3),
        .o_data4(llr_mem_o_data4),
        .o_data5(llr_mem_o_data5)
    );

    error_bit_saver u_error_bit_saver (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_code(i_code),
        .i_clear(i_clear),
        .i_err_valid_pulse(i_err_valid_pulse),
        .i_err_loc0(i_err_loc0),
        .i_err_loc1(i_err_loc1),
        .i_err_loc2(i_err_loc2),
        .i_err_loc3(i_err_loc3),
        .i_num_err(i_num_err),
        .i_correct(i_correct),
        .i_flip_pos1(i_flip_pos1),
        .i_flip_pos2(i_flip_pos2),
        .i_flip_valid(i_flip_valid),
        .o_tp1_err_loc0(o_tp1_err_loc0),
        .o_tp1_err_loc1(o_tp1_err_loc1),
        .o_tp1_err_loc2(o_tp1_err_loc2),
        .o_tp1_err_loc3(o_tp1_err_loc3),
        .o_tp1_err_loc4(o_tp1_err_loc4),
        .o_tp1_err_loc5(o_tp1_err_loc5),
        .o_tp1_num_err(o_tp1_num_err),
        .o_tp1_correct(o_tp1_correct),
        .o_tp2_err_loc0(o_tp2_err_loc0),
        .o_tp2_err_loc1(o_tp2_err_loc1),
        .o_tp2_err_loc2(o_tp2_err_loc2),
        .o_tp2_err_loc3(o_tp2_err_loc3),
        .o_tp2_err_loc4(o_tp2_err_loc4),
        .o_tp2_err_loc5(o_tp2_err_loc5),
        .o_tp2_num_err(o_tp2_num_err),
        .o_tp2_correct(o_tp2_correct),
        .o_tp3_err_loc0(o_tp3_err_loc0),
        .o_tp3_err_loc1(o_tp3_err_loc1),
        .o_tp3_err_loc2(o_tp3_err_loc2),
        .o_tp3_err_loc3(o_tp3_err_loc3),
        .o_tp3_err_loc4(o_tp3_err_loc4),
        .o_tp3_err_loc5(o_tp3_err_loc5),
        .o_tp3_num_err(o_tp3_num_err),
        .o_tp3_correct(o_tp3_correct),
        .o_tp4_err_loc0(o_tp4_err_loc0),
        .o_tp4_err_loc1(o_tp4_err_loc1),
        .o_tp4_err_loc2(o_tp4_err_loc2),
        .o_tp4_err_loc3(o_tp4_err_loc3),
        .o_tp4_err_loc4(o_tp4_err_loc4),
        .o_tp4_err_loc5(o_tp4_err_loc5),
        .o_tp4_num_err(o_tp4_num_err),
        .o_tp4_correct(o_tp4_correct),
        .mim_llr_tp(mim_llr_tp),
        .o_valid(o_valid),
        .o_llr_mem_pos0(llr_mem_i_pos0),
        .o_llr_mem_pos1(llr_mem_i_pos1),
        .o_llr_mem_pos2(llr_mem_i_pos2),
        .o_llr_mem_pos3(llr_mem_i_pos3),
        .o_llr_mem_pos4(llr_mem_i_pos4),
        .o_llr_mem_pos5(llr_mem_i_pos5),
        .i_llr_mem_pos0_llr(llr_mem_o_data0),
        .i_llr_mem_pos1_llr(llr_mem_o_data1),
        .i_llr_mem_pos2_llr(llr_mem_o_data2),
        .i_llr_mem_pos3_llr(llr_mem_o_data3),
        .i_llr_mem_pos4_llr(llr_mem_o_data4),
        .i_llr_mem_pos5_llr(llr_mem_o_data5)
    );


    // Clock Generation
    initial begin
        i_clk = 0;
        forever #(CYCLE/2) i_clk = ~i_clk;
    end

    initial begin
        $fsdbDumpfile("tb_error_bit_saver.fsdb");
        $fsdbDumpvars(0, tb_error_bit_saver, "+mda");
    end

    // read pattern
    initial begin
        $readmemh("../00_TESTBED/pattern_error_bit_saver/llr_mem_data.dat", test_llr_mem_data);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/bch_code.dat", test_bch_code);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/err_loc0.dat", test_err_loc0);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/err_loc1.dat", test_err_loc1);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/err_loc2.dat", test_err_loc2);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/err_loc3.dat", test_err_loc3);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/num_err.dat", test_num_err);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/correct.dat", test_correct);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/flip_pos1.dat", test_flip_pos1);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/flip_pos2.dat", test_flip_pos2);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp1_err_loc0.dat", golden_tp1_err_loc0);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp1_err_loc1.dat", golden_tp1_err_loc1);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp1_err_loc2.dat", golden_tp1_err_loc2);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp1_err_loc3.dat", golden_tp1_err_loc3);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp1_err_loc4.dat", golden_tp1_err_loc4);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp1_err_loc5.dat", golden_tp1_err_loc5);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp1_num_err.dat", golden_tp1_num_err);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp1_correct.dat", golden_tp1_correct);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp2_err_loc0.dat", golden_tp2_err_loc0);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp2_err_loc1.dat", golden_tp2_err_loc1);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp2_err_loc2.dat", golden_tp2_err_loc2);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp2_err_loc3.dat", golden_tp2_err_loc3);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp2_err_loc4.dat", golden_tp2_err_loc4);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp2_err_loc5.dat", golden_tp2_err_loc5);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp2_num_err.dat", golden_tp2_num_err);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp2_correct.dat", golden_tp2_correct);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp3_err_loc0.dat", golden_tp3_err_loc0);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp3_err_loc1.dat", golden_tp3_err_loc1);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp3_err_loc2.dat", golden_tp3_err_loc2);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp3_err_loc3.dat", golden_tp3_err_loc3);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp3_err_loc4.dat", golden_tp3_err_loc4);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp3_err_loc5.dat", golden_tp3_err_loc5);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp3_num_err.dat", golden_tp3_num_err);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp3_correct.dat", golden_tp3_correct);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp4_err_loc0.dat", golden_tp4_err_loc0);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp4_err_loc1.dat", golden_tp4_err_loc1);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp4_err_loc2.dat", golden_tp4_err_loc2);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp4_err_loc3.dat", golden_tp4_err_loc3);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp4_err_loc4.dat", golden_tp4_err_loc4);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp4_err_loc5.dat", golden_tp4_err_loc5);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp4_num_err.dat", golden_tp4_num_err);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/tp4_correct.dat", golden_tp4_correct);
        $readmemh("../00_TESTBED/pattern_error_bit_saver/mim_llr_tp.dat", golden_mim_llr_tp);    
    end

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
        llr_mem_i_wen = 0;
        llr_mem_i_data = 0;
        i_clear = 0;
        i_err_valid_pulse = 0;
        i_flip_valid = 0;
        #(CYCLE*3);
        @(posedge i_clk);
        i_rst_n = 1;
    end


    integer i, j;
    integer llr_mem_data_length;
    initial begin
        #1;
        wait(i_rst_n == 1);
        // all input initial to 0
        llr_mem_i_wen = 0;
        llr_mem_i_data = 0;
        i_clear = 0;
        i_err_valid_pulse = 0;
        i_flip_valid = 0;
        i_flip_pos1 = 0;
        i_flip_pos2 = 0;
        i_err_loc0 = 0;
        i_err_loc1 = 0;
        i_err_loc2 = 0;
        i_err_loc3 = 0;
        i_num_err = 0;
        i_correct = 0;
        i_err_valid_pulse = 0;


        @(posedge i_clk);
        for (i = 0; i < PATTERN_LEN; i = i + 1) begin
            // Configure BCH code
            i_code = test_bch_code[i];
            if (i_code === BCH63_51)
                llr_mem_data_length = 64;
            else if (i_code === BCH255_239)
                llr_mem_data_length = 256;
            else if (i_code === BCH1023_983)
                llr_mem_data_length = 1024;
            else begin
                $display("Error: Invalid BCH Code");
                $finish;
            end

            // Load LLR memory
            for (j = 0; j < llr_mem_data_length/8; j = j + 1) begin
                llr_mem_i_wen = 1;
                llr_mem_i_data = test_llr_mem_data[i][(1024*8-1) - (j*64) -: 64];
                @(posedge i_clk);
            end
            llr_mem_i_wen = 0;
            i_clear = 1;
            @(posedge i_clk);
            i_clear = 0;
            @(posedge i_clk);
            i_flip_pos1 = test_flip_pos1[i];
            i_flip_pos2 = test_flip_pos2[i];
            i_flip_valid = 1;

            // Provide error locations and other inputs
            for (j = 0; j < 4; j = j + 1) begin
                i_err_valid_pulse = 1;
                i_err_loc0 = test_err_loc0[i][(39) - (j*10) -: 10];
                i_err_loc1 = test_err_loc1[i][(39) - (j*10) -: 10];
                i_err_loc2 = test_err_loc2[i][(39) - (j*10) -: 10];
                i_err_loc3 = test_err_loc3[i][(39) - (j*10) -: 10];
                i_num_err = test_num_err[i][(11) - (j*3) -: 3];
                i_correct = test_correct[i][j];
                @(posedge i_clk);
                i_err_valid_pulse = 0;
                @(posedge i_clk);
            end



            // Wait for valid output
            wait(o_valid == 1);
            i_flip_valid = 0;
        end
    end


    integer error_count;
    initial begin
        error_count = 0;
        golden_idx = 0;
        wait(i_rst_n == 1);
        @(posedge i_clk);

        while (golden_idx < PATTERN_LEN - 1) begin
            if (o_valid) begin
                if (golden_tp1_correct[golden_idx] === 1'b1) begin
                    if (o_tp1_correct !== 1'b1) begin
                        $display("[Error] Pattern %0d TP1: correct signal mismatch! exp=1 got=0", golden_idx);
                        error_count = error_count + 1;
                    end

                    if (o_tp1_num_err !== golden_tp1_num_err[golden_idx]) begin
                        $display("[Error] Pattern %0d TP1: num_err mismatch! exp=%0d got=%0d", golden_idx, golden_tp1_num_err[golden_idx], o_tp1_num_err);
                        error_count = error_count + 1;
                    end
                    if (o_tp1_err_loc0 !== golden_tp1_err_loc0[golden_idx] && golden_tp1_num_err[golden_idx] > 0) begin
                        $display("[Error] Pattern %0d TP1: err_loc0 mismatch! exp=%0d got=%0d", golden_idx, golden_tp1_err_loc0[golden_idx], o_tp1_err_loc0);
                        error_count = error_count + 1;
                    end
                    if (o_tp1_err_loc1 !== golden_tp1_err_loc1[golden_idx] && golden_tp1_num_err[golden_idx] > 1) begin
                        $display("[Error] Pattern %0d TP1: err_loc1 mismatch! exp=%0d got=%0d", golden_idx, golden_tp1_err_loc1[golden_idx], o_tp1_err_loc1);
                        error_count = error_count + 1;
                    end
                    if (o_tp1_err_loc2 !== golden_tp1_err_loc2[golden_idx] && golden_tp1_num_err[golden_idx] > 2) begin
                        $display("[Error] Pattern %0d TP1: err_loc2 mismatch! exp=%0d got=%0d", golden_idx, golden_tp1_err_loc2[golden_idx], o_tp1_err_loc2);
                        error_count = error_count + 1;
                    end
                    if (o_tp1_err_loc3 !== golden_tp1_err_loc3[golden_idx] && golden_tp1_num_err[golden_idx] > 3) begin
                        $display("[Error] Pattern %0d TP1: err_loc3 mismatch! exp=%0d got=%0d", golden_idx, golden_tp1_err_loc3[golden_idx], o_tp1_err_loc3);
                        error_count = error_count + 1;
                    end
                    if (o_tp1_err_loc4 !== golden_tp1_err_loc4[golden_idx] && golden_tp1_num_err[golden_idx] > 4) begin
                        $display("[Error] Pattern %0d TP1: err_loc4 mismatch! exp=%0d got=%0d", golden_idx, golden_tp1_err_loc4[golden_idx], o_tp1_err_loc4);
                        error_count = error_count + 1;
                    end
                    if (o_tp1_err_loc5 !== golden_tp1_err_loc5[golden_idx] && golden_tp1_num_err[golden_idx] > 5) begin
                        $display("[Error] Pattern %0d TP1: err_loc5 mismatch! exp=%0d got=%0d", golden_idx, golden_tp1_err_loc5[golden_idx], o_tp1_err_loc5);
                        error_count = error_count + 1;
                    end
                end
                else begin
                    if (o_tp1_correct === 1'b1) begin
                        $display("[Error] Pattern %0d TP1: correct signal mismatch! exp=0 got=1", golden_idx);
                        error_count = error_count + 1;
                    end
                end

                if (golden_tp2_correct[golden_idx] === 1'b1) begin
                    if (o_tp2_correct !== 1'b1) begin
                        $display("[Error] Pattern %0d TP2: correct signal mismatch! exp=1 got=0", golden_idx);
                        error_count = error_count + 1;
                    end
                    if (o_tp2_num_err !== golden_tp2_num_err[golden_idx]) begin
                        $display("[Error] Pattern %0d TP2: num_err mismatch! exp=%0d got=%0d", golden_idx, golden_tp2_num_err[golden_idx], o_tp2_num_err);
                        error_count = error_count + 1;
                    end
                    if (o_tp2_err_loc0 !== golden_tp2_err_loc0[golden_idx] && golden_tp2_num_err[golden_idx] > 0) begin
                        $display("[Error] Pattern %0d TP2: err_loc0 mismatch! exp=%0d got=%0d", golden_idx, golden_tp2_err_loc0[golden_idx], o_tp2_err_loc0);
                        error_count = error_count + 1;
                    end
                    if (o_tp2_err_loc1 !== golden_tp2_err_loc1[golden_idx] && golden_tp2_num_err[golden_idx] > 1) begin
                        $display("[Error] Pattern %0d TP2: err_loc1 mismatch! exp=%0d got=%0d", golden_idx, golden_tp2_err_loc1[golden_idx], o_tp2_err_loc1);
                        error_count = error_count + 1;
                    end
                    if (o_tp2_err_loc2 !== golden_tp2_err_loc2[golden_idx] && golden_tp2_num_err[golden_idx] > 2) begin
                        $display("[Error] Pattern %0d TP2: err_loc2 mismatch! exp=%0d got=%0d", golden_idx, golden_tp2_err_loc2[golden_idx], o_tp2_err_loc2);
                        error_count = error_count + 1;
                    end
                    if (o_tp2_err_loc3 !== golden_tp2_err_loc3[golden_idx] && golden_tp2_num_err[golden_idx] > 3) begin
                        $display("[Error] Pattern %0d TP2: err_loc3 mismatch! exp=%0d got=%0d", golden_idx, golden_tp2_err_loc3[golden_idx], o_tp2_err_loc3);
                        error_count = error_count + 1;
                    end
                    if (o_tp2_err_loc4 !== golden_tp2_err_loc4[golden_idx] && golden_tp2_num_err[golden_idx] > 4) begin
                        $display("[Error] Pattern %0d TP2: err_loc4 mismatch! exp=%0d got=%0d", golden_idx, golden_tp2_err_loc4[golden_idx], o_tp2_err_loc4);
                        error_count = error_count + 1;
                    end
                    if (o_tp2_err_loc5 !== golden_tp2_err_loc5[golden_idx] && golden_tp2_num_err[golden_idx] > 5) begin
                        $display("[Error] Pattern %0d TP2: err_loc5 mismatch! exp=%0d got=%0d", golden_idx, golden_tp2_err_loc5[golden_idx], o_tp2_err_loc5);
                        error_count = error_count + 1;
                    end
                end
                else begin
                    if (o_tp2_correct === 1'b1) begin
                        $display("[Error] Pattern %0d TP2: correct signal mismatch! exp=0 got=1", golden_idx);
                        error_count = error_count + 1;
                    end
                end

                if (golden_tp3_correct[golden_idx] === 1'b1) begin
                    if (o_tp3_correct !== 1'b1) begin
                        $display("[Error] Pattern %0d TP3: correct signal mismatch! exp=1 got=0", golden_idx);
                        error_count = error_count + 1;
                    end
                    if (o_tp3_num_err !== golden_tp3_num_err[golden_idx]) begin
                        $display("[Error] Pattern %0d TP3: num_err mismatch! exp=%0d got=%0d", golden_idx, golden_tp3_num_err[golden_idx], o_tp3_num_err);
                        error_count = error_count + 1;
                    end
                    if (o_tp3_err_loc0 !== golden_tp3_err_loc0[golden_idx] && golden_tp3_num_err[golden_idx] > 0) begin
                        $display("[Error] Pattern %0d TP3: err_loc0 mismatch! exp=%0d got=%0d", golden_idx, golden_tp3_err_loc0[golden_idx], o_tp3_err_loc0);
                        error_count = error_count + 1;
                    end
                    if (o_tp3_err_loc1 !== golden_tp3_err_loc1[golden_idx] && golden_tp3_num_err[golden_idx] > 1) begin
                        $display("[Error] Pattern %0d TP3: err_loc1 mismatch! exp=%0d got=%0d", golden_idx, golden_tp3_err_loc1[golden_idx], o_tp3_err_loc1);
                        error_count = error_count + 1;
                    end
                    if (o_tp3_err_loc2 !== golden_tp3_err_loc2[golden_idx] && golden_tp3_num_err[golden_idx] > 2) begin
                        $display("[Error] Pattern %0d TP3: err_loc2 mismatch! exp=%0d got=%0d", golden_idx, golden_tp3_err_loc2[golden_idx], o_tp3_err_loc2);
                        error_count = error_count + 1;
                    end
                    if (o_tp3_err_loc3 !== golden_tp3_err_loc3[golden_idx] && golden_tp3_num_err[golden_idx] > 3) begin
                        $display("[Error] Pattern %0d TP3: err_loc3 mismatch! exp=%0d got=%0d", golden_idx, golden_tp3_err_loc3[golden_idx], o_tp3_err_loc3);
                        error_count = error_count + 1;
                    end
                    if (o_tp3_err_loc4 !== golden_tp3_err_loc4[golden_idx] && golden_tp3_num_err[golden_idx] > 4) begin
                        $display("[Error] Pattern %0d TP3: err_loc4 mismatch! exp=%0d got=%0d", golden_idx, golden_tp3_err_loc4[golden_idx], o_tp3_err_loc4);
                        error_count = error_count + 1;
                    end
                    if (o_tp3_err_loc5 !== golden_tp3_err_loc5[golden_idx] && golden_tp3_num_err[golden_idx] > 5) begin
                        $display("[Error] Pattern %0d TP3: err_loc5 mismatch! exp=%0d got=%0d", golden_idx, golden_tp3_err_loc5[golden_idx], o_tp3_err_loc5);
                        error_count = error_count + 1;
                    end
                end
                else begin
                    if (o_tp3_correct === 1'b1) begin
                        $display("[Error] Pattern %0d TP3: correct signal mismatch! exp=0 got=1", golden_idx);
                        error_count = error_count + 1;
                    end
                end

                if (golden_tp4_correct[golden_idx] === 1'b1) begin
                    if (o_tp4_correct !== 1'b1) begin
                        $display("[Error] Pattern %0d TP4: correct signal mismatch! exp=1 got=0", golden_idx);
                        error_count = error_count + 1;
                    end
                    if (o_tp4_num_err !== golden_tp4_num_err[golden_idx]) begin
                        $display("[Error] Pattern %0d TP4: num_err mismatch! exp=%0d got=%0d", golden_idx, golden_tp4_num_err[golden_idx], o_tp4_num_err);
                        error_count = error_count + 1;
                    end

                    if (o_tp4_err_loc0 !== golden_tp4_err_loc0[golden_idx] && golden_tp4_num_err[golden_idx] > 0) begin
                        $display("[Error] Pattern %0d TP4: err_loc0 mismatch! exp=%0d got=%0d", golden_idx, golden_tp4_err_loc0[golden_idx], o_tp4_err_loc0);
                        error_count = error_count + 1;
                    end
                    if (o_tp4_err_loc1 !== golden_tp4_err_loc1[golden_idx] && golden_tp4_num_err[golden_idx] > 1) begin
                        $display("[Error] Pattern %0d TP4: err_loc1 mismatch! exp=%0d got=%0d", golden_idx, golden_tp4_err_loc1[golden_idx], o_tp4_err_loc1);
                        error_count = error_count + 1;
                    end
                    if (o_tp4_err_loc2 !== golden_tp4_err_loc2[golden_idx] && golden_tp4_num_err[golden_idx] > 2) begin
                        $display("[Error] Pattern %0d TP4: err_loc2 mismatch! exp=%0d got=%0d", golden_idx, golden_tp4_err_loc2[golden_idx], o_tp4_err_loc2);
                        error_count = error_count + 1;
                    end
                    if (o_tp4_err_loc3 !== golden_tp4_err_loc3[golden_idx] && golden_tp4_num_err[golden_idx] > 3) begin
                        $display("[Error] Pattern %0d TP4: err_loc3 mismatch! exp=%0d got=%0d", golden_idx, golden_tp4_err_loc3[golden_idx], o_tp4_err_loc3);
                        error_count = error_count + 1;
                    end
                    if (o_tp4_err_loc4 !== golden_tp4_err_loc4[golden_idx] && golden_tp4_num_err[golden_idx] > 4) begin
                        $display("[Error] Pattern %0d TP4: err_loc4 mismatch! exp=%0d got=%0d", golden_idx, golden_tp4_err_loc4[golden_idx], o_tp4_err_loc4);
                        error_count = error_count + 1;
                    end
                    if (o_tp4_err_loc5 !== golden_tp4_err_loc5[golden_idx] && golden_tp4_num_err[golden_idx] > 5) begin
                        $display("[Error] Pattern %0d TP4: err_loc5 mismatch! exp=%0d got=%0d", golden_idx, golden_tp4_err_loc5[golden_idx], o_tp4_err_loc5);
                        error_count = error_count + 1;
                    end
                end
                else begin
                    if (o_tp4_correct === 1'b1) begin
                        $display("[Error] Pattern %0d TP4: correct signal mismatch! exp=0 got=1", golden_idx);
                        error_count = error_count + 1;
                    end
                end

                if (mim_llr_tp !== golden_mim_llr_tp[golden_idx]) begin
                    $display("[Error] Pattern %0d: mim_llr_tp mismatch! exp=%0d got=%0d", golden_idx, golden_mim_llr_tp[golden_idx], mim_llr_tp);
                    error_count = error_count + 1;
                end

                golden_idx = golden_idx + 1;
                wait(o_valid == 0 || golden_idx == PATTERN_LEN);
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