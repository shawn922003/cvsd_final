module output_selector(
    input i_clk,
    input i_rst_n,

    input i_mode,

    input [9:0] chien_search_err_loc0,
    input [9:0] chien_search_err_loc1,
    input [9:0] chien_search_err_loc2,
    input [9:0] chien_search_err_loc3,
    input [2:0] chien_search_num_err,
    input chien_search_valid_pulse,

    input [9:0] err_bit_saver_tp1_err_loc0,
    input [9:0] err_bit_saver_tp1_err_loc1, 
    input [9:0] err_bit_saver_tp1_err_loc2,
    input [9:0] err_bit_saver_tp1_err_loc3,
    input [9:0] err_bit_saver_tp1_err_loc4,
    input [9:0] err_bit_saver_tp1_err_loc5,
    input [2:0] err_bit_saver_tp1_num_err,

    input [9:0] err_bit_saver_tp2_err_loc0,
    input [9:0] err_bit_saver_tp2_err_loc1, 
    input [9:0] err_bit_saver_tp2_err_loc2,
    input [9:0] err_bit_saver_tp2_err_loc3,
    input [9:0] err_bit_saver_tp2_err_loc4,
    input [9:0] err_bit_saver_tp2_err_loc5,
    input [2:0] err_bit_saver_tp2_num_err,

    input [9:0] err_bit_saver_tp3_err_loc0,
    input [9:0] err_bit_saver_tp3_err_loc1, 
    input [9:0] err_bit_saver_tp3_err_loc2,
    input [9:0] err_bit_saver_tp3_err_loc3,
    input [9:0] err_bit_saver_tp3_err_loc4,
    input [9:0] err_bit_saver_tp3_err_loc5,
    input [2:0] err_bit_saver_tp3_num_err,

    input [9:0] err_bit_saver_tp4_err_loc0,
    input [9:0] err_bit_saver_tp4_err_loc1, 
    input [9:0] err_bit_saver_tp4_err_loc2,
    input [9:0] err_bit_saver_tp4_err_loc3,
    input [9:0] err_bit_saver_tp4_err_loc4,
    input [9:0] err_bit_saver_tp4_err_loc5,
    input [2:0] err_bit_saver_tp4_num_err,

    input [2:0] err_bit_saver_select_tp, // 1: tp1, 2: tp2, 3: tp3, 4: tp4
    input err_bit_saver_valid_pulse,

    output [9:0] o_err_loc,
    output o_valid // connect to chip finish port
);

    reg [9:0] err_loc0;
    reg [9:0] err_loc1_buf, err_loc1_buf_next;
    reg [9:0] err_loc2_buf, err_loc2_buf_next;
    reg [9:0] err_loc3_buf, err_loc3_buf_next;
    reg [9:0] err_loc4_buf, err_loc4_buf_next;
    reg [9:0] err_loc5_buf, err_loc5_buf_next;
    reg [2:0] num_err_buf, num_err_buf_next;

    reg [2:0] counter, counter_next;


    reg [9:0] out_err_loc;
    reg out_valid;

    delay_n #(
        .BITS(10),
        .N(1)
    ) u_delay_n_out (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(out_err_loc),
        .o_q(o_err_loc)
    );

    delay_n #(
        .BITS(1),
        .N(1)
    ) u_delay_n_valid (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(out_valid),
        .o_q(o_valid)
    );


    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            err_loc1_buf <= 10'd0;
            err_loc2_buf <= 10'd0;
            err_loc3_buf <= 10'd0;
            err_loc4_buf <= 10'd0;
            err_loc5_buf <= 10'd0;
            num_err_buf <= 3'd0;
        end else begin
            err_loc1_buf <= err_loc1_buf_next;
            err_loc2_buf <= err_loc2_buf_next;
            err_loc3_buf <= err_loc3_buf_next;
            err_loc4_buf <= err_loc4_buf_next;
            err_loc5_buf <= err_loc5_buf_next;
            num_err_buf <= num_err_buf_next;
        end
    end

    always @(*) begin
        if (i_mode == 0) begin
            if (chien_search_valid_pulse) begin
                err_loc1_buf_next = chien_search_err_loc1;
                err_loc2_buf_next = chien_search_err_loc2;
                err_loc3_buf_next = chien_search_err_loc3;
                num_err_buf_next = chien_search_num_err;
            end
            else begin
                err_loc1_buf_next = err_loc1_buf;
                err_loc2_buf_next = err_loc2_buf;
                err_loc3_buf_next = err_loc3_buf;
                num_err_buf_next = num_err_buf;
            end
            err_loc0 = 10'd1023;
            err_loc4_buf_next = err_loc4_buf;
            err_loc5_buf_next = err_loc5_buf;
        end
        else begin
            if (err_bit_saver_valid_pulse) begin
                case (err_bit_saver_select_tp)
                    3'd1: begin
                        err_loc0 = err_bit_saver_tp1_err_loc0;
                        err_loc1_buf_next = err_bit_saver_tp1_err_loc1;
                        err_loc2_buf_next = err_bit_saver_tp1_err_loc2;
                        err_loc3_buf_next = err_bit_saver_tp1_err_loc3;
                        err_loc4_buf_next = err_bit_saver_tp1_err_loc4;
                        err_loc5_buf_next = err_bit_saver_tp1_err_loc5;
                        num_err_buf_next = err_bit_saver_tp1_num_err;
                    end
                    3'd2: begin
                        err_loc0 = err_bit_saver_tp2_err_loc0;
                        err_loc1_buf_next = err_bit_saver_tp2_err_loc1;
                        err_loc2_buf_next = err_bit_saver_tp2_err_loc2;
                        err_loc3_buf_next = err_bit_saver_tp2_err_loc3;
                        err_loc4_buf_next = err_bit_saver_tp2_err_loc4;
                        err_loc5_buf_next = err_bit_saver_tp2_err_loc5;
                        num_err_buf_next = err_bit_saver_tp2_num_err;
                    end
                    3'd3: begin
                        err_loc0 = err_bit_saver_tp3_err_loc0;
                        err_loc1_buf_next = err_bit_saver_tp3_err_loc1;
                        err_loc2_buf_next = err_bit_saver_tp3_err_loc2;
                        err_loc3_buf_next = err_bit_saver_tp3_err_loc3;
                        err_loc4_buf_next = err_bit_saver_tp3_err_loc4;
                        err_loc5_buf_next = err_bit_saver_tp3_err_loc5;
                        num_err_buf_next = err_bit_saver_tp3_num_err;
                    end
                    3'd4: begin
                        err_loc0 = err_bit_saver_tp4_err_loc0;
                        err_loc1_buf_next = err_bit_saver_tp4_err_loc1;
                        err_loc2_buf_next = err_bit_saver_tp4_err_loc2;
                        err_loc3_buf_next = err_bit_saver_tp4_err_loc3;
                        err_loc4_buf_next = err_bit_saver_tp4_err_loc4;
                        err_loc5_buf_next = err_bit_saver_tp4_err_loc5;
                        num_err_buf_next = err_bit_saver_tp4_num_err;
                    end
                    default: begin
                        err_loc0 = 10'd1023;
                        err_loc1_buf_next = err_loc1_buf;
                        err_loc2_buf_next = err_loc2_buf;
                        err_loc3_buf_next = err_loc3_buf;
                        err_loc4_buf_next = err_loc4_buf;
                        err_loc5_buf_next = err_loc5_buf;
                        num_err_buf_next = num_err_buf;
                    end
                endcase
            end
            else begin
                err_loc0 = 10'd1023;
                err_loc1_buf_next = err_loc1_buf;
                err_loc2_buf_next = err_loc2_buf;
                err_loc3_buf_next = err_loc3_buf;
                err_loc4_buf_next = err_loc4_buf;
                err_loc5_buf_next = err_loc5_buf;
                num_err_buf_next = num_err_buf;
            end
        end
    end

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            counter <= 3'd0;
        end
        else begin
            counter <= counter_next;
        end
    end

    always @(*) begin
        if ((i_mode == 0 && chien_search_valid_pulse) ||
            (i_mode == 1 && err_bit_saver_valid_pulse)) begin
            counter_next = 3'd0;
        end
        else if (counter < 3'd7) begin
            counter_next = counter + 3'd1;
        end
        else begin
            counter_next = counter;
        end
    end


    always @(*) begin
        if (i_mode == 0) begin
            case (counter_next) 
                3'd0: begin
                    if (chien_search_num_err >= 3'd1) begin
                        out_err_loc = chien_search_err_loc0;
                        out_valid = 1'b1;
                    end
                    else begin
                        out_err_loc = 10'd1023;
                        out_valid = 1'b1;
                    end
                end
                3'd1: begin
                    if (num_err_buf >= 3'd2) begin
                        out_err_loc = err_loc1_buf;
                        out_valid = 1'b1;
                    end
                    else begin
                        out_err_loc = 10'd1023;
                        out_valid = 1'b0;
                    end
                end
                3'd2: begin
                    if (num_err_buf >= 3'd3) begin
                        out_err_loc = err_loc2_buf;
                        out_valid = 1'b1;
                    end
                    else begin
                        out_err_loc = 10'd1023;
                        out_valid = 1'b0;
                    end
                end
                3'd3: begin
                    if (num_err_buf >= 3'd4) begin
                        out_err_loc = err_loc3_buf;
                        out_valid = 1'b1;
                    end
                    else begin
                        out_err_loc = 10'd1023;
                        out_valid = 1'b0;
                    end
                end
                default: begin
                    out_err_loc = 10'd1023;
                    out_valid = 1'b0;
                end
            endcase
        end
        else begin
            case (counter_next) 
                3'd0: begin
                    if (num_err_buf_next >= 3'd1) begin
                        out_err_loc = err_loc0;
                        out_valid = 1'b1;
                    end
                    else begin
                        out_err_loc = 10'd1023;
                        out_valid = 1'b1;
                    end
                end
                3'd1: begin
                    if (num_err_buf >= 3'd2) begin
                        out_err_loc = err_loc1_buf;
                        out_valid = 1'b1;
                    end
                    else begin
                        out_err_loc = 10'd1023;
                        out_valid = 1'b0;
                    end
                end
                3'd2: begin
                    if (num_err_buf >= 3'd3) begin
                        out_err_loc = err_loc2_buf;
                        out_valid = 1'b1;
                    end
                    else begin
                        out_err_loc = 10'd1023;
                        out_valid = 1'b0;
                    end
                end
                3'd3: begin
                    if (num_err_buf >= 3'd4) begin
                        out_err_loc = err_loc3_buf;
                        out_valid = 1'b1;
                    end
                    else begin
                        out_err_loc = 10'd1023;
                        out_valid = 1'b0;
                    end
                end
                3'd4: begin
                    if (num_err_buf >= 3'd5) begin
                        out_err_loc = err_loc4_buf;
                        out_valid = 1'b1;
                    end
                    else begin
                        out_err_loc = 10'd1023;
                        out_valid = 1'b0;
                    end
                end
                3'd5: begin
                    if (num_err_buf >= 3'd6) begin
                        out_err_loc = err_loc5_buf;
                        out_valid = 1'b1;
                    end
                    else begin
                        out_err_loc = 10'd1023;
                        out_valid = 1'b0;
                    end
                end
                default: begin
                    out_err_loc = 10'd1023;
                    out_valid = 1'b0;
                end
            endcase
        end
    end

endmodule