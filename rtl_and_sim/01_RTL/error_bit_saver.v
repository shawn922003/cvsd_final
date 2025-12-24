module error_bit_saver(
    input i_clk,
    input i_rst_n,

    input i_mode,
    input [1:0] i_code,

    input i_early_stop,

    input i_clear,
    input i_err_valid_pulse, 
    input [9:0] i_err_loc0,
    input [9:0] i_err_loc1,
    input [9:0] i_err_loc2,
    input [9:0] i_err_loc3,
    input [2:0] i_num_err,
    input i_correct,

    input [8:0] i_llr_sum,
    input i_llr_sum_valid,

    input [9:0] i_flip_pos1,
    input [9:0] i_flip_pos2,
    input [6:0] i_flip_llr1,
    input [6:0] i_flip_llr2,
    input i_flip_valid, // i_flip_valid need to be high before i_err_valid_pulse at least 1 cycle

    output [9:0] o_tp1_err_loc0,
    output [9:0] o_tp1_err_loc1,
    output [9:0] o_tp1_err_loc2,
    output [9:0] o_tp1_err_loc3,
    output [9:0] o_tp1_err_loc4,
    output [9:0] o_tp1_err_loc5,
    output [2:0] o_tp1_num_err,

    output [9:0] o_tp2_err_loc0,
    output [9:0] o_tp2_err_loc1,
    output [9:0] o_tp2_err_loc2,
    output [9:0] o_tp2_err_loc3,
    output [9:0] o_tp2_err_loc4,
    output [9:0] o_tp2_err_loc5,
    output [2:0] o_tp2_num_err,

    output [9:0] o_tp3_err_loc0,
    output [9:0] o_tp3_err_loc1,
    output [9:0] o_tp3_err_loc2,
    output [9:0] o_tp3_err_loc3,
    output [9:0] o_tp3_err_loc4,
    output [9:0] o_tp3_err_loc5,
    output [2:0] o_tp3_num_err,

    output [9:0] o_tp4_err_loc0,
    output [9:0] o_tp4_err_loc1,
    output [9:0] o_tp4_err_loc2,
    output [9:0] o_tp4_err_loc3,
    output [9:0] o_tp4_err_loc4,
    output [9:0] o_tp4_err_loc5,
    output [2:0] o_tp4_num_err,

    output [2:0] o_min_llr_tp,

    output o_valid
);

    wire gen;
    assign gen = i_mode;

    reg [2:0] num_tp, num_tp_next;
    reg [2:0] num_valid_tp, num_valid_tp_next;

    reg [9:0] tp1_err_loc0_buf, tp1_err_loc0_buf_next;
    reg [9:0] tp1_err_loc1_buf, tp1_err_loc1_buf_next;
    reg [9:0] tp1_err_loc2_buf, tp1_err_loc2_buf_next;
    reg [9:0] tp1_err_loc3_buf, tp1_err_loc3_buf_next;
    reg [9:0] tp1_err_loc4_buf, tp1_err_loc4_buf_next;
    reg [9:0] tp1_err_loc5_buf, tp1_err_loc5_buf_next;
    reg [2:0] tp1_num_err_buf, tp1_num_err_buf_next;

    reg [9:0] tp2_err_loc0_buf, tp2_err_loc0_buf_next;
    reg [9:0] tp2_err_loc1_buf, tp2_err_loc1_buf_next;
    reg [9:0] tp2_err_loc2_buf, tp2_err_loc2_buf_next;
    reg [9:0] tp2_err_loc3_buf, tp2_err_loc3_buf_next;
    reg [9:0] tp2_err_loc4_buf, tp2_err_loc4_buf_next;
    reg [9:0] tp2_err_loc5_buf, tp2_err_loc5_buf_next;
    reg [2:0] tp2_num_err_buf, tp2_num_err_buf_next;

    reg [9:0] tp3_err_loc0_buf, tp3_err_loc0_buf_next;
    reg [9:0] tp3_err_loc1_buf, tp3_err_loc1_buf_next;
    reg [9:0] tp3_err_loc2_buf, tp3_err_loc2_buf_next;
    reg [9:0] tp3_err_loc3_buf, tp3_err_loc3_buf_next;
    reg [9:0] tp3_err_loc4_buf, tp3_err_loc4_buf_next;
    reg [9:0] tp3_err_loc5_buf, tp3_err_loc5_buf_next;
    reg [2:0] tp3_num_err_buf, tp3_num_err_buf_next;

    reg [9:0] tp4_err_loc0_buf, tp4_err_loc0_buf_next;
    reg [9:0] tp4_err_loc1_buf, tp4_err_loc1_buf_next;
    reg [9:0] tp4_err_loc2_buf, tp4_err_loc2_buf_next;
    reg [9:0] tp4_err_loc3_buf, tp4_err_loc3_buf_next;
    reg [9:0] tp4_err_loc4_buf, tp4_err_loc4_buf_next;
    reg [9:0] tp4_err_loc5_buf, tp4_err_loc5_buf_next;
    reg [2:0] tp4_num_err_buf, tp4_num_err_buf_next;

    reg [9:0] err_loc0_adaptive;
    reg [9:0] err_loc1_adaptive;
    reg [9:0] err_loc2_adaptive;
    reg [9:0] err_loc3_adaptive;
    reg [9:0] flip_pos1_adaptive;
    reg [9:0] flip_pos2_adaptive;
    reg [1:0] num_flip_adaptive;

    wire [9:0] sort_out0;
    wire [9:0] sort_out1;
    wire [9:0] sort_out2;
    wire [9:0] sort_out3;
    wire [9:0] sort_out4;
    wire [9:0] sort_out5;


    wire valid;
    wire o_valid_internal;


    assign o_tp1_err_loc0 = tp1_err_loc0_buf;
    assign o_tp1_err_loc1 = tp1_err_loc1_buf;
    assign o_tp1_err_loc2 = tp1_err_loc2_buf;
    assign o_tp1_err_loc3 = tp1_err_loc3_buf;
    assign o_tp1_err_loc4 = tp1_err_loc4_buf;
    assign o_tp1_err_loc5 = tp1_err_loc5_buf;
    assign o_tp1_num_err  = tp1_num_err_buf;

    assign o_tp2_err_loc0 = tp2_err_loc0_buf;
    assign o_tp2_err_loc1 = tp2_err_loc1_buf;
    assign o_tp2_err_loc2 = tp2_err_loc2_buf;
    assign o_tp2_err_loc3 = tp2_err_loc3_buf;
    assign o_tp2_err_loc4 = tp2_err_loc4_buf;
    assign o_tp2_err_loc5 = tp2_err_loc5_buf;
    assign o_tp2_num_err  = tp2_num_err_buf;

    assign o_tp3_err_loc0 = tp3_err_loc0_buf;
    assign o_tp3_err_loc1 = tp3_err_loc1_buf;
    assign o_tp3_err_loc2 = tp3_err_loc2_buf;
    assign o_tp3_err_loc3 = tp3_err_loc3_buf;
    assign o_tp3_err_loc4 = tp3_err_loc4_buf;
    assign o_tp3_err_loc5 = tp3_err_loc5_buf;
    assign o_tp3_num_err  = tp3_num_err_buf;

    assign o_tp4_err_loc0 = tp4_err_loc0_buf;
    assign o_tp4_err_loc1 = tp4_err_loc1_buf;
    assign o_tp4_err_loc2 = tp4_err_loc2_buf;
    assign o_tp4_err_loc3 = tp4_err_loc3_buf;
    assign o_tp4_err_loc4 = tp4_err_loc4_buf;
    assign o_tp4_err_loc5 = tp4_err_loc5_buf;
    assign o_tp4_num_err  = tp4_num_err_buf;

    assign valid = num_tp == 3'd4;


    insertion_sort u_insertion_sort (
        .i_data1_0(err_loc0_adaptive),
        .i_data1_1(err_loc1_adaptive),
        .i_data1_2(err_loc2_adaptive),
        .i_data1_3(err_loc3_adaptive),
        .i_data2_0(flip_pos1_adaptive),
        .i_data2_1(flip_pos2_adaptive),
        .o_data_0(sort_out0),
        .o_data_1(sort_out1),
        .o_data_2(sort_out2),
        .o_data_3(sort_out3),
        .o_data_4(sort_out4),
        .o_data_5(sort_out5)
    );




    // ----------  tp location and num error logic ---------------------------
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            num_tp        <= 3'd0;
            num_valid_tp  <= 3'd0;

            tp1_err_loc0_buf <= 10'd0;
            tp1_err_loc1_buf <= 10'd0;
            tp1_err_loc2_buf <= 10'd0;
            tp1_err_loc3_buf <= 10'd0;
            tp1_err_loc4_buf <= 10'd0;
            tp1_err_loc5_buf <= 10'd0;
            tp1_num_err_buf  <= 3'd0;

            tp2_err_loc0_buf <= 10'd0;
            tp2_err_loc1_buf <= 10'd0;
            tp2_err_loc2_buf <= 10'd0;
            tp2_err_loc3_buf <= 10'd0;
            tp2_err_loc4_buf <= 10'd0;
            tp2_err_loc5_buf <= 10'd0;
            tp2_num_err_buf  <= 3'd0;

            tp3_err_loc0_buf <= 10'd0;
            tp3_err_loc1_buf <= 10'd0;
            tp3_err_loc2_buf <= 10'd0;
            tp3_err_loc3_buf <= 10'd0;
            tp3_err_loc4_buf <= 10'd0;
            tp3_err_loc5_buf <= 10'd0;
            tp3_num_err_buf  <= 3'd0;

            tp4_err_loc0_buf <= 10'd0;
            tp4_err_loc1_buf <= 10'd0;
            tp4_err_loc2_buf <= 10'd0;
            tp4_err_loc3_buf <= 10'd0;
            tp4_err_loc4_buf <= 10'd0;
            tp4_err_loc5_buf <= 10'd0;
            tp4_num_err_buf  <= 3'd0;
        end 
        else begin
            // 加上 gen clock enable：gen=1 才更新，否則保持原值
            num_tp        <= gen ? num_tp_next        : num_tp;
            num_valid_tp  <= gen ? num_valid_tp_next  : num_valid_tp;

            tp1_err_loc0_buf <= gen ? tp1_err_loc0_buf_next : tp1_err_loc0_buf;
            tp1_err_loc1_buf <= gen ? tp1_err_loc1_buf_next : tp1_err_loc1_buf;
            tp1_err_loc2_buf <= gen ? tp1_err_loc2_buf_next : tp1_err_loc2_buf;
            tp1_err_loc3_buf <= gen ? tp1_err_loc3_buf_next : tp1_err_loc3_buf;
            tp1_err_loc4_buf <= gen ? tp1_err_loc4_buf_next : tp1_err_loc4_buf;
            tp1_err_loc5_buf <= gen ? tp1_err_loc5_buf_next : tp1_err_loc5_buf;
            tp1_num_err_buf  <= gen ? tp1_num_err_buf_next  : tp1_num_err_buf;

            tp2_err_loc0_buf <= gen ? tp2_err_loc0_buf_next : tp2_err_loc0_buf;
            tp2_err_loc1_buf <= gen ? tp2_err_loc1_buf_next : tp2_err_loc1_buf;
            tp2_err_loc2_buf <= gen ? tp2_err_loc2_buf_next : tp2_err_loc2_buf;
            tp2_err_loc3_buf <= gen ? tp2_err_loc3_buf_next : tp2_err_loc3_buf;
            tp2_err_loc4_buf <= gen ? tp2_err_loc4_buf_next : tp2_err_loc4_buf;
            tp2_err_loc5_buf <= gen ? tp2_err_loc5_buf_next : tp2_err_loc5_buf;
            tp2_num_err_buf  <= gen ? tp2_num_err_buf_next  : tp2_num_err_buf;

            tp3_err_loc0_buf <= gen ? tp3_err_loc0_buf_next : tp3_err_loc0_buf;
            tp3_err_loc1_buf <= gen ? tp3_err_loc1_buf_next : tp3_err_loc1_buf;
            tp3_err_loc2_buf <= gen ? tp3_err_loc2_buf_next : tp3_err_loc2_buf;
            tp3_err_loc3_buf <= gen ? tp3_err_loc3_buf_next : tp3_err_loc3_buf;
            tp3_err_loc4_buf <= gen ? tp3_err_loc4_buf_next : tp3_err_loc4_buf;
            tp3_err_loc5_buf <= gen ? tp3_err_loc5_buf_next : tp3_err_loc5_buf;
            tp3_num_err_buf  <= gen ? tp3_num_err_buf_next  : tp3_num_err_buf;

            tp4_err_loc0_buf <= gen ? tp4_err_loc0_buf_next : tp4_err_loc0_buf;
            tp4_err_loc1_buf <= gen ? tp4_err_loc1_buf_next : tp4_err_loc1_buf;
            tp4_err_loc2_buf <= gen ? tp4_err_loc2_buf_next : tp4_err_loc2_buf;
            tp4_err_loc3_buf <= gen ? tp4_err_loc3_buf_next : tp4_err_loc3_buf;
            tp4_err_loc4_buf <= gen ? tp4_err_loc4_buf_next : tp4_err_loc4_buf;
            tp4_err_loc5_buf <= gen ? tp4_err_loc5_buf_next : tp4_err_loc5_buf;
            tp4_num_err_buf  <= gen ? tp4_num_err_buf_next  : tp4_num_err_buf;
        end
    end

    

    always @(*) begin
        if (i_clear) begin
            num_tp_next = 3'd0;
            num_valid_tp_next = 3'd0;
        end
        else if (i_err_valid_pulse) begin
            num_tp_next = num_tp + 3'd1;
            if (i_correct) begin
                num_valid_tp_next = num_valid_tp + 3'd1;
            end
            else begin
                num_valid_tp_next = num_valid_tp;
            end
        end
        else begin
            num_tp_next = num_tp;
            num_valid_tp_next = num_valid_tp;
        end
    end


    always @(*) begin
        if (i_num_err == 3'd0) begin
            err_loc0_adaptive = {10{1'b1}};
            err_loc1_adaptive = {10{1'b1}};
            err_loc2_adaptive = {10{1'b1}};
            err_loc3_adaptive = {10{1'b1}};
        end
        else if (i_num_err == 3'd1) begin
            err_loc0_adaptive = i_err_loc0;
            err_loc1_adaptive = {10{1'b1}};
            err_loc2_adaptive = {10{1'b1}};
            err_loc3_adaptive = {10{1'b1}};
        end
        else if (i_num_err == 3'd2) begin
            err_loc0_adaptive = i_err_loc0;
            err_loc1_adaptive = i_err_loc1;
            err_loc2_adaptive = {10{1'b1}};
            err_loc3_adaptive = {10{1'b1}};
        end
        else if (i_num_err == 3'd3) begin
            err_loc0_adaptive = i_err_loc0;
            err_loc1_adaptive = i_err_loc1;
            err_loc2_adaptive = i_err_loc2;
            err_loc3_adaptive = {10{1'b1}};
        end
        else begin
            err_loc0_adaptive = i_err_loc0;
            err_loc1_adaptive = i_err_loc1;
            err_loc2_adaptive = i_err_loc2;
            err_loc3_adaptive = i_err_loc3;
        end


        case (num_tp) 
            3'd0: begin
                flip_pos1_adaptive = {10{1'b1}};
                flip_pos2_adaptive = {10{1'b1}};
                num_flip_adaptive = 2'd0;
            end
            3'd1: begin
                flip_pos1_adaptive = i_flip_pos1;
                flip_pos2_adaptive = {10{1'b1}};
                num_flip_adaptive = 2'd1;
            end
            3'd2: begin
                flip_pos1_adaptive = {10{1'b1}};
                flip_pos2_adaptive = i_flip_pos2;
                num_flip_adaptive = 2'd1;
            end
            3'd3: begin
                flip_pos1_adaptive = i_flip_pos1;
                flip_pos2_adaptive = i_flip_pos2;
                num_flip_adaptive = 2'd2;
            end
            default: begin
                flip_pos1_adaptive = {10{1'b1}};
                flip_pos2_adaptive = {10{1'b1}};
                num_flip_adaptive = 2'd0;
            end
        endcase
    end


    always @(*) begin
        if (i_correct && i_err_valid_pulse && i_flip_valid) begin
            case (num_valid_tp)
                3'd0: begin
                    tp1_err_loc0_buf_next = sort_out0;
                    tp1_err_loc1_buf_next = sort_out1;
                    tp1_err_loc2_buf_next = sort_out2;
                    tp1_err_loc3_buf_next = sort_out3;
                    tp1_err_loc4_buf_next = sort_out4;
                    tp1_err_loc5_buf_next = sort_out5;
                    tp1_num_err_buf_next  = i_num_err + num_flip_adaptive;

                    tp2_err_loc0_buf_next = tp2_err_loc0_buf;
                    tp2_err_loc1_buf_next = tp2_err_loc1_buf;
                    tp2_err_loc2_buf_next = tp2_err_loc2_buf;
                    tp2_err_loc3_buf_next = tp2_err_loc3_buf;
                    tp2_err_loc4_buf_next = tp2_err_loc4_buf;
                    tp2_err_loc5_buf_next = tp2_err_loc5_buf;
                    tp2_num_err_buf_next  = tp2_num_err_buf;

                    tp3_err_loc0_buf_next = tp3_err_loc0_buf;
                    tp3_err_loc1_buf_next = tp3_err_loc1_buf;
                    tp3_err_loc2_buf_next = tp3_err_loc2_buf;
                    tp3_err_loc3_buf_next = tp3_err_loc3_buf;
                    tp3_err_loc4_buf_next = tp3_err_loc4_buf;
                    tp3_err_loc5_buf_next = tp3_err_loc5_buf;
                    tp3_num_err_buf_next  = tp3_num_err_buf;

                    tp4_err_loc0_buf_next = tp4_err_loc0_buf;
                    tp4_err_loc1_buf_next = tp4_err_loc1_buf;
                    tp4_err_loc2_buf_next = tp4_err_loc2_buf;
                    tp4_err_loc3_buf_next = tp4_err_loc3_buf;
                    tp4_err_loc4_buf_next = tp4_err_loc4_buf;
                    tp4_err_loc5_buf_next = tp4_err_loc5_buf;
                    tp4_num_err_buf_next  = tp4_num_err_buf;
                end
                3'd1: begin
                    tp1_err_loc0_buf_next = tp1_err_loc0_buf;
                    tp1_err_loc1_buf_next = tp1_err_loc1_buf;
                    tp1_err_loc2_buf_next = tp1_err_loc2_buf;
                    tp1_err_loc3_buf_next = tp1_err_loc3_buf;
                    tp1_err_loc4_buf_next = tp1_err_loc4_buf;
                    tp1_err_loc5_buf_next = tp1_err_loc5_buf;
                    tp1_num_err_buf_next  = tp1_num_err_buf;

                    tp2_err_loc0_buf_next = sort_out0;
                    tp2_err_loc1_buf_next = sort_out1;
                    tp2_err_loc2_buf_next = sort_out2;
                    tp2_err_loc3_buf_next = sort_out3;
                    tp2_err_loc4_buf_next = sort_out4;
                    tp2_err_loc5_buf_next = sort_out5;
                    tp2_num_err_buf_next  = i_num_err + num_flip_adaptive;

                    tp3_err_loc0_buf_next = tp3_err_loc0_buf;
                    tp3_err_loc1_buf_next = tp3_err_loc1_buf;
                    tp3_err_loc2_buf_next = tp3_err_loc2_buf;
                    tp3_err_loc3_buf_next = tp3_err_loc3_buf;
                    tp3_err_loc4_buf_next = tp3_err_loc4_buf;
                    tp3_err_loc5_buf_next = tp3_err_loc5_buf;
                    tp3_num_err_buf_next  = tp3_num_err_buf;

                    tp4_err_loc0_buf_next = tp4_err_loc0_buf;
                    tp4_err_loc1_buf_next = tp4_err_loc1_buf;
                    tp4_err_loc2_buf_next = tp4_err_loc2_buf;
                    tp4_err_loc3_buf_next = tp4_err_loc3_buf;
                    tp4_err_loc4_buf_next = tp4_err_loc4_buf;
                    tp4_err_loc5_buf_next = tp4_err_loc5_buf;
                    tp4_num_err_buf_next  = tp4_num_err_buf;
                end
                3'd2: begin
                    tp1_err_loc0_buf_next = tp1_err_loc0_buf;
                    tp1_err_loc1_buf_next = tp1_err_loc1_buf;
                    tp1_err_loc2_buf_next = tp1_err_loc2_buf;
                    tp1_err_loc3_buf_next = tp1_err_loc3_buf;
                    tp1_err_loc4_buf_next = tp1_err_loc4_buf;
                    tp1_err_loc5_buf_next = tp1_err_loc5_buf;
                    tp1_num_err_buf_next  = tp1_num_err_buf;

                    tp2_err_loc0_buf_next = tp2_err_loc0_buf;
                    tp2_err_loc1_buf_next = tp2_err_loc1_buf;
                    tp2_err_loc2_buf_next = tp2_err_loc2_buf;
                    tp2_err_loc3_buf_next = tp2_err_loc3_buf;
                    tp2_err_loc4_buf_next = tp2_err_loc4_buf;
                    tp2_err_loc5_buf_next = tp2_err_loc5_buf;
                    tp2_num_err_buf_next  = tp2_num_err_buf;

                    tp3_err_loc0_buf_next = sort_out0;
                    tp3_err_loc1_buf_next = sort_out1;
                    tp3_err_loc2_buf_next = sort_out2;
                    tp3_err_loc3_buf_next = sort_out3;
                    tp3_err_loc4_buf_next = sort_out4;
                    tp3_err_loc5_buf_next = sort_out5;
                    tp3_num_err_buf_next  = i_num_err + num_flip_adaptive;

                    tp4_err_loc0_buf_next = tp4_err_loc0_buf;
                    tp4_err_loc1_buf_next = tp4_err_loc1_buf;
                    tp4_err_loc2_buf_next = tp4_err_loc2_buf;
                    tp4_err_loc3_buf_next = tp4_err_loc3_buf;
                    tp4_err_loc4_buf_next = tp4_err_loc4_buf;
                    tp4_err_loc5_buf_next = tp4_err_loc5_buf;
                    tp4_num_err_buf_next  = tp4_num_err_buf;
                end
                3'd3: begin
                    tp1_err_loc0_buf_next = tp1_err_loc0_buf;
                    tp1_err_loc1_buf_next = tp1_err_loc1_buf;
                    tp1_err_loc2_buf_next = tp1_err_loc2_buf;
                    tp1_err_loc3_buf_next = tp1_err_loc3_buf;
                    tp1_err_loc4_buf_next = tp1_err_loc4_buf;
                    tp1_err_loc5_buf_next = tp1_err_loc5_buf;
                    tp1_num_err_buf_next  = tp1_num_err_buf;

                    tp2_err_loc0_buf_next = tp2_err_loc0_buf;
                    tp2_err_loc1_buf_next = tp2_err_loc1_buf;
                    tp2_err_loc2_buf_next = tp2_err_loc2_buf;
                    tp2_err_loc3_buf_next = tp2_err_loc3_buf;
                    tp2_err_loc4_buf_next = tp2_err_loc4_buf;
                    tp2_err_loc5_buf_next = tp2_err_loc5_buf;
                    tp2_num_err_buf_next  = tp2_num_err_buf;

                    tp3_err_loc0_buf_next = tp3_err_loc0_buf;
                    tp3_err_loc1_buf_next = tp3_err_loc1_buf;
                    tp3_err_loc2_buf_next = tp3_err_loc2_buf;
                    tp3_err_loc3_buf_next = tp3_err_loc3_buf;
                    tp3_err_loc4_buf_next = tp3_err_loc4_buf;
                    tp3_err_loc5_buf_next = tp3_err_loc5_buf;
                    tp3_num_err_buf_next  = tp3_num_err_buf;

                    tp4_err_loc0_buf_next = sort_out0;
                    tp4_err_loc1_buf_next = sort_out1;
                    tp4_err_loc2_buf_next = sort_out2;
                    tp4_err_loc3_buf_next = sort_out3;
                    tp4_err_loc4_buf_next = sort_out4;
                    tp4_err_loc5_buf_next = sort_out5;
                    tp4_num_err_buf_next  = i_num_err + num_flip_adaptive;
                end
                default: begin
                    tp1_err_loc0_buf_next = tp1_err_loc0_buf;
                    tp1_err_loc1_buf_next = tp1_err_loc1_buf;
                    tp1_err_loc2_buf_next = tp1_err_loc2_buf;
                    tp1_err_loc3_buf_next = tp1_err_loc3_buf;
                    tp1_err_loc4_buf_next = tp1_err_loc4_buf;
                    tp1_err_loc5_buf_next = tp1_err_loc5_buf;
                    tp1_num_err_buf_next  = tp1_num_err_buf;

                    tp2_err_loc0_buf_next = tp2_err_loc0_buf;
                    tp2_err_loc1_buf_next = tp2_err_loc1_buf;
                    tp2_err_loc2_buf_next = tp2_err_loc2_buf;
                    tp2_err_loc3_buf_next = tp2_err_loc3_buf;
                    tp2_err_loc4_buf_next = tp2_err_loc4_buf;
                    tp2_err_loc5_buf_next = tp2_err_loc5_buf;
                    tp2_num_err_buf_next  = tp2_num_err_buf;

                    tp3_err_loc0_buf_next = tp3_err_loc0_buf;
                    tp3_err_loc1_buf_next = tp3_err_loc1_buf;
                    tp3_err_loc2_buf_next = tp3_err_loc2_buf;
                    tp3_err_loc3_buf_next = tp3_err_loc3_buf;
                    tp3_err_loc4_buf_next = tp3_err_loc4_buf;
                    tp3_err_loc5_buf_next = tp3_err_loc5_buf;
                    tp3_num_err_buf_next  = tp3_num_err_buf;

                    tp4_err_loc0_buf_next = tp4_err_loc0_buf;
                    tp4_err_loc1_buf_next = tp4_err_loc1_buf;
                    tp4_err_loc2_buf_next = tp4_err_loc2_buf;
                    tp4_err_loc3_buf_next = tp4_err_loc3_buf;
                    tp4_err_loc4_buf_next = tp4_err_loc4_buf;
                    tp4_err_loc5_buf_next = tp4_err_loc5_buf;
                    tp4_num_err_buf_next  = tp4_num_err_buf;
                end
            endcase
        end
        else begin
            tp1_err_loc0_buf_next = tp1_err_loc0_buf;
            tp1_err_loc1_buf_next = tp1_err_loc1_buf;
            tp1_err_loc2_buf_next = tp1_err_loc2_buf;
            tp1_err_loc3_buf_next = tp1_err_loc3_buf;
            tp1_err_loc4_buf_next = tp1_err_loc4_buf;
            tp1_err_loc5_buf_next = tp1_err_loc5_buf;
            tp1_num_err_buf_next  = tp1_num_err_buf;

            tp2_err_loc0_buf_next = tp2_err_loc0_buf;
            tp2_err_loc1_buf_next = tp2_err_loc1_buf;
            tp2_err_loc2_buf_next = tp2_err_loc2_buf;
            tp2_err_loc3_buf_next = tp2_err_loc3_buf;
            tp2_err_loc4_buf_next = tp2_err_loc4_buf;
            tp2_err_loc5_buf_next = tp2_err_loc5_buf;
            tp2_num_err_buf_next  = tp2_num_err_buf;

            tp3_err_loc0_buf_next = tp3_err_loc0_buf;
            tp3_err_loc1_buf_next = tp3_err_loc1_buf;
            tp3_err_loc2_buf_next = tp3_err_loc2_buf;
            tp3_err_loc3_buf_next = tp3_err_loc3_buf;
            tp3_err_loc4_buf_next = tp3_err_loc4_buf;
            tp3_err_loc5_buf_next = tp3_err_loc5_buf;
            tp3_num_err_buf_next  = tp3_num_err_buf;

            tp4_err_loc0_buf_next = tp4_err_loc0_buf;
            tp4_err_loc1_buf_next = tp4_err_loc1_buf;
            tp4_err_loc2_buf_next = tp4_err_loc2_buf;
            tp4_err_loc3_buf_next = tp4_err_loc3_buf;
            tp4_err_loc4_buf_next = tp4_err_loc4_buf;
            tp4_err_loc5_buf_next = tp4_err_loc5_buf;
            tp4_num_err_buf_next  = tp4_num_err_buf;
        end
    end
    

    // ------------------  llr logic ---------------------------

    wire [2:0] num_tp_dly;
    wire [2:0] num_valid_tp_dly;

    reg [9:0] all_llr_sum;

    reg [9:0] min_llr, min_llr_next;
    reg [2:0] min_llr_tp, min_llr_tp_next;

    wire correct_dly;

    assign o_valid = o_valid_internal & !i_early_stop;

    delay_n #(
        .N(1),
        .BITS(3),
        .INIT(3'd0)
    ) u_delay_num_tp (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_en    (gen),
        .i_d     (num_tp),
        .o_q     (num_tp_dly)
    );

    delay_n #(
        .N(1),
        .BITS(3),
        .INIT(3'd0)
    ) u_delay_num_valid_tp (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_en    (gen),
        .i_d     (num_valid_tp),
        .o_q     (num_valid_tp_dly)
    );


    delay_n #(
        .N(1),
        .BITS(1),
        .INIT(1'd0)
    ) u_delay_valid (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_en    (gen),
        .i_d     (valid),
        .o_q     (o_valid_internal)
    );

    delay_n #(
        .N(1),
        .BITS(1),
        .INIT(1'd0)
    ) u_delay_correct (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_en    (gen),
        .i_d     (i_correct),
        .o_q     (correct_dly)
    );

    assign o_min_llr_tp = min_llr_tp;

    always @(*) begin
        case (num_tp_dly)
            3'd0: all_llr_sum = i_llr_sum;
            3'd1: all_llr_sum = i_llr_sum + i_flip_llr1;
            3'd2: all_llr_sum = i_llr_sum + i_flip_llr2;
            3'd3: all_llr_sum = i_llr_sum + i_flip_llr1 + i_flip_llr2;
            default: all_llr_sum = 10'd0;
        endcase
    end 

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            min_llr     <= 10'd1023;
            min_llr_tp  <= 3'd0;
        end
        else begin
            min_llr     <= gen ? min_llr_next    : min_llr;
            min_llr_tp  <= gen ? min_llr_tp_next : min_llr_tp;
        end
    end


    always @(*) begin
        if (i_clear) begin
            min_llr_next    = 10'd1023;
            min_llr_tp_next = 3'd0;
        end
        else if (i_llr_sum_valid && correct_dly) begin
            if (all_llr_sum < min_llr) begin
                min_llr_next    = all_llr_sum;
                min_llr_tp_next = num_valid_tp_dly + 4'd1;
            end
            else begin
                min_llr_next    = min_llr;
                min_llr_tp_next = min_llr_tp;
            end
        end
        else begin
            min_llr_next    = min_llr;
            min_llr_tp_next = min_llr_tp;
        end
    end

endmodule