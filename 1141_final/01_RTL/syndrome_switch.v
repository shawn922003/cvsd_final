module syndrome_switch(
    input        i_clk,
    input        i_rst_n,

    input        i_mode,
    input  [1:0] i_code,      // 原本是 1bit，下面有用到 2'b10，改成 2bit

    input  [9:0] i_tp1_S1,
    input  [9:0] i_tp1_S2,
    input  [9:0] i_tp1_S3,
    input  [9:0] i_tp1_S4,
    input  [9:0] i_tp1_S5,
    input  [9:0] i_tp1_S6,
    input  [9:0] i_tp1_S7,
    input  [9:0] i_tp1_S8,
    input        i_tp1_valid,

    input  [9:0] i_tp2_S1,
    input  [9:0] i_tp2_S2,
    input  [9:0] i_tp2_S3,
    input  [9:0] i_tp2_S4,
    input  [9:0] i_tp2_S5,
    input  [9:0] i_tp2_S6,
    input  [9:0] i_tp2_S7,
    input  [9:0] i_tp2_S8,

    input  [9:0] i_tp3_S1,
    input  [9:0] i_tp3_S2,
    input  [9:0] i_tp3_S3,
    input  [9:0] i_tp3_S4,
    input  [9:0] i_tp3_S5,
    input  [9:0] i_tp3_S6,
    input  [9:0] i_tp3_S7,
    input  [9:0] i_tp3_S8,

    input  [9:0] i_tp4_S1,
    input  [9:0] i_tp4_S2,
    input  [9:0] i_tp4_S3,
    input  [9:0] i_tp4_S4,
    input  [9:0] i_tp4_S5,
    input  [9:0] i_tp4_S6,
    input  [9:0] i_tp4_S7,
    input  [9:0] i_tp4_S8,

    input        i_all_tp_valid,
    input        i_next_tp,

    // if i_mode == 0 -> output tp1
    // if i_mode == 1 and i_code == 2'b00 or 2'b01 -> o_S5 to o_S8 is tp2 or tp4
    // if i_mode == 1 and i_code == 2'b10 -> o_S1 to o_S8 is full tp
    output [9:0] o_S1,
    output [9:0] o_S2,
    output [9:0] o_S3,
    output [9:0] o_S4,
    output [9:0] o_S5,
    output [9:0] o_S6,
    output [9:0] o_S7,
    output [9:0] o_S8,
    output       o_valid
);

    // 這裡改成 reg，因為下面 always @(*) 裡要對它們 assign
    reg [9:0] S1, S2, S3, S4, S5, S6, S7, S8;

    wire valid, valid_dly;
    reg next_tp_valid_pulse;
    wire input_valid_pulse;

    // ---- delay stage for S1~S8 ----
    delay_n #(
        .N(1),
        .BITS(10)
    ) delay_S1 (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (1'b1),
        .i_d   (S1),
        .o_q   (o_S1)
    );

    delay_n #(
        .N(1),
        .BITS(10)
    ) delay_S2 (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (1'b1),
        .i_d   (S2),
        .o_q   (o_S2)
    );

    delay_n #(
        .N(1),
        .BITS(10)
    ) delay_S3 (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (1'b1),
        .i_d   (S3),
        .o_q   (o_S3)
    );

    delay_n #(
        .N(1),
        .BITS(10)
    ) delay_S4 (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (1'b1),
        .i_d   (S4),
        .o_q   (o_S4)
    );

    delay_n #(
        .N(1),
        .BITS(10)
    ) delay_S5 (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (1'b1),
        .i_d   (S5),
        .o_q   (o_S5)
    );

    delay_n #(
        .N(1),
        .BITS(10)
    ) delay_S6 (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (1'b1),
        .i_d   (S6),
        .o_q   (o_S6)
    );

    delay_n #(
        .N(1),
        .BITS(10)
    ) delay_S7 (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (1'b1),
        .i_d   (S7),
        .o_q   (o_S7)
    );

    delay_n #(
        .N(1),
        .BITS(10)
    ) delay_S8 (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (1'b1),
        .i_d   (S8),
        .o_q   (o_S8)
    );

    delay_n #(
        .N(1),
        .BITS(1)
    ) delay_valid (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (1'b1),
        .i_d   (valid),
        .o_q   (valid_dly)
    );

    pulser u_pulser_valid (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_in    (valid_dly),
        .i_clear (1'b0),
        .o_pulse (o_valid)
    );

    pulser u_pulser_input_valid (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_in    (i_code == 2'b10 ? i_tp1_valid : i_all_tp_valid && i_tp1_valid),
        .i_clear (1'b0),
        .o_pulse (input_valid_pulse)
    );


    // valid 一樣：mode=0 用 tp1_valid，mode=1 要 all_tp_valid & tp1_valid
    assign valid = (i_mode == 1'b0) ? i_tp1_valid : (input_valid_pulse || next_tp_valid_pulse);

    reg [1:0] state, state_next;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            state <= 2'b00;
        end 
        else begin
            state <= state_next;
        end
    end

    always @(*) begin
        if (i_tp1_valid == 1'b0) begin
            state_next = 2'b00;
        end
        else if (i_next_tp && i_mode == 1'b1) begin
            if (i_code == 2'b10) begin
                state_next = state + 2'd1;
            end
            else begin
                state_next = state + 2'd2;
            end
        end
        else begin
            state_next = state;
        end
    end

    always @(*) begin
        if (i_mode == 1'b0) begin
            S1 = i_tp1_S1;
            S2 = i_tp1_S2;
            S3 = i_tp1_S3;
            S4 = i_tp1_S4;
            S5 = i_tp1_S5;
            S6 = i_tp1_S6;
            S7 = i_tp1_S7;
            S8 = i_tp1_S8;
        end
        else begin
            if (i_code != 2'b10) begin
                case ({i_next_tp, state[1]})
                    2'b00: begin
                        S1 = i_tp1_S1;
                        S2 = i_tp1_S2;
                        S3 = i_tp1_S3;
                        S4 = i_tp1_S4;
                        S5 = i_tp2_S1;
                        S6 = i_tp2_S2;
                        S7 = i_tp2_S3;
                        S8 = i_tp2_S4;
                    end
                    2'b01, 2'b10, 2'b11: begin
                        S1 = i_tp3_S1;
                        S2 = i_tp3_S2;
                        S3 = i_tp3_S3;
                        S4 = i_tp3_S4;
                        S5 = i_tp4_S1;
                        S6 = i_tp4_S2;
                        S7 = i_tp4_S3;
                        S8 = i_tp4_S4;
                    end
                endcase
            end
            else begin
                case ({i_next_tp, state})
                    3'b000: begin
                        S1 = i_tp1_S1;
                        S2 = i_tp1_S2;
                        S3 = i_tp1_S3;
                        S4 = i_tp1_S4;
                        S5 = i_tp1_S5;
                        S6 = i_tp1_S6;
                        S7 = i_tp1_S7;
                        S8 = i_tp1_S8;
                    end
                    3'b001, 3'b100: begin
                        S1 = i_tp2_S1;
                        S2 = i_tp2_S2;
                        S3 = i_tp2_S3;
                        S4 = i_tp2_S4;
                        S5 = i_tp2_S5;
                        S6 = i_tp2_S6;
                        S7 = i_tp2_S7;
                        S8 = i_tp2_S8;
                    end
                    3'b010, 3'b101: begin
                        S1 = i_tp3_S1;
                        S2 = i_tp3_S2;
                        S3 = i_tp3_S3;
                        S4 = i_tp3_S4;
                        S5 = i_tp3_S5;
                        S6 = i_tp3_S6;
                        S7 = i_tp3_S7;
                        S8 = i_tp3_S8;
                    end 
                    3'b011, 3'b110, 3'b111: begin
                        S1 = i_tp4_S1;
                        S2 = i_tp4_S2;
                        S3 = i_tp4_S3;
                        S4 = i_tp4_S4;
                        S5 = i_tp4_S5;
                        S6 = i_tp4_S6;
                        S7 = i_tp4_S7;
                        S8 = i_tp4_S8;
                    end
                endcase
            end 
        end
    end


    always @(*) begin
        if (i_code != 2'b10) begin
            case ({i_next_tp, state[1]})
                2'b10: begin
                    next_tp_valid_pulse = 1'b1;
                end
                2'b01, 2'b00, 2'b11: begin
                    next_tp_valid_pulse = 1'b0;
                end
            endcase
        end
        else begin
            case ({i_next_tp, state})
                3'b100: begin
                    next_tp_valid_pulse = 1'b1;
                end
                3'b101: begin
                    next_tp_valid_pulse = 1'b1;
                end
                3'b110: begin
                    next_tp_valid_pulse = 1'b1;
                end 
                default: begin
                    next_tp_valid_pulse = 1'b0;
                end
            endcase
        end 
    end

endmodule
