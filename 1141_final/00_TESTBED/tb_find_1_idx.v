`timescale 1ns/1ps

module tb_find_1_idx;

    // -------------------------
    // Parameters
    // -------------------------
    parameter PATTERN_LEN = 16;

    // -------------------------
    // DUT interface
    // -------------------------
    reg  [127:0] i_data;
    wire [6:0]   o_idx1;
    wire [6:0]   o_idx2;
    wire [6:0]   o_idx3;
    wire [6:0]   o_idx4;
    wire [2:0]   o_num_found;

    // -------------------------
    // Test pattern / golden
    // -------------------------
    reg [127:0] test_data   [0:PATTERN_LEN-1];
    reg [6:0]   golden_idx1 [0:PATTERN_LEN-1];
    reg [6:0]   golden_idx2 [0:PATTERN_LEN-1];
    reg [6:0]   golden_idx3 [0:PATTERN_LEN-1];
    reg [6:0]   golden_idx4 [0:PATTERN_LEN-1];
    reg [2:0]   golden_num  [0:PATTERN_LEN-1];

    // -------------------------
    // DUT instance
    // -------------------------
    find_1_idx u_find_1_idx (
        .i_data      (i_data),
        .o_idx1      (o_idx1),
        .o_idx2      (o_idx2),
        .o_idx3      (o_idx3),
        .o_idx4      (o_idx4),
        .o_num_found (o_num_found)
    );

    // -------------------------
    // Waveform (可選)
    // -------------------------
    initial begin
        $fsdbDumpfile("tb_find_1_idx.fsdb");
        $fsdbDumpvars(0, tb_find_1_idx, "+mda");
    end

    // -------------------------
    // Read pattern files
    // -------------------------
    initial begin
        $readmemh("../00_TESTBED/pattern_find_1_idx/find_1_idx_data.dat",  test_data);
        $readmemh("../00_TESTBED/pattern_find_1_idx/find_1_idx_idx1.dat",  golden_idx1);
        $readmemh("../00_TESTBED/pattern_find_1_idx/find_1_idx_idx2.dat",  golden_idx2);
        $readmemh("../00_TESTBED/pattern_find_1_idx/find_1_idx_idx3.dat",  golden_idx3);
        $readmemh("../00_TESTBED/pattern_find_1_idx/find_1_idx_idx4.dat",  golden_idx4);
        $readmemh("../00_TESTBED/pattern_find_1_idx/find_1_idx_num.dat",   golden_num);
    end

    // -------------------------
    // Stimulus + Check (單一 initial)
    // -------------------------
    integer i;
    integer error_count;

    initial begin
        error_count = 0;

        // 等讀檔完成 & combinational settle 一下
        #1;

        for (i = 0; i < PATTERN_LEN; i = i + 1) begin
            i_data = test_data[i];

            // 給組合邏輯一點時間穩定
            #1;

            if (o_num_found !== golden_num[i]) begin
                $display("[Error] Pattern %0d: num_found mismatch! exp=%0d got=%0d",
                         i, golden_num[i], o_num_found);
                error_count = error_count + 1;
            end

            if (o_idx1 !== golden_idx1[i]) begin
                $display("[Error] Pattern %0d: idx1 mismatch! exp=%0d (0x%02h) got=%0d (0x%02h)",
                         i, golden_idx1[i], golden_idx1[i], o_idx1, o_idx1);
                error_count = error_count + 1;
            end

            if (o_idx2 !== golden_idx2[i]) begin
                $display("[Error] Pattern %0d: idx2 mismatch! exp=%0d (0x%02h) got=%0d (0x%02h)",
                         i, golden_idx2[i], golden_idx2[i], o_idx2, o_idx2);
                error_count = error_count + 1;
            end

            if (o_idx3 !== golden_idx3[i]) begin
                $display("[Error] Pattern %0d: idx3 mismatch! exp=%0d (0x%02h) got=%0d (0x%02h)",
                         i, golden_idx3[i], golden_idx3[i], o_idx3, o_idx3);
                error_count = error_count + 1;
            end

            if (o_idx4 !== golden_idx4[i]) begin
                $display("[Error] Pattern %0d: idx4 mismatch! exp=%0d (0x%02h) got=%0d (0x%02h)",
                         i, golden_idx4[i], golden_idx4[i], o_idx4, o_idx4);
                error_count = error_count + 1;
            end
        end

        if (error_count == 0) begin
            $display("============================================");
            $display(" tb_find_1_idx: All %0d patterns passed! ", PATTERN_LEN);
            $display("============================================");
        end else begin
            $display("============================================");
            $display(" tb_find_1_idx: Total %0d errors found!", error_count);
            $display("============================================");
        end

        $finish;
    end

endmodule
