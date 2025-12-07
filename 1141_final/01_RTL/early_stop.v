module early_stop(
    input i_clk,
    input i_rst_n,

    input i_mode,
    input [1:0] i_code,

    input  [9:0] i_tp1_S1,
    input  [9:0] i_tp1_S3,
    input  [9:0] i_tp1_S5,
    input  [9:0] i_tp1_S7,
    input        i_tp1_valid,

    input  [9:0] i_tp2_S1,
    input  [9:0] i_tp2_S3,
    input  [9:0] i_tp2_S5,
    input  [9:0] i_tp2_S7,

    input  [9:0] i_tp3_S1,
    input  [9:0] i_tp3_S3,
    input  [9:0] i_tp3_S5,
    input  [9:0] i_tp3_S7,

    input  [9:0] i_tp4_S1,
    input  [9:0] i_tp4_S3,
    input  [9:0] i_tp4_S5,
    input  [9:0] i_tp4_S7,

    input        i_all_tp_valid,

    output       o_early_stop_pulse
);

    wire tp1_1_3_zero;
    wire tp1_5_7_zero;
    wire tp2_1_3_zero;
    wire tp2_5_7_zero;
    wire tp3_1_3_zero;
    wire tp3_5_7_zero;
    wire tp4_1_3_zero;
    wire tp4_5_7_zero;

    wire tp1_zero;
    wire tp2_zero;
    wire tp3_zero;
    wire tp4_zero;

    reg early_stop;

    assign tp1_1_3_zero = (i_tp1_S1 == 10'b0) && (i_tp1_S3 == 10'b0);
    assign tp1_5_7_zero = (i_tp1_S5 == 10'b0) && (i_tp1_S7 == 10'b0);
    assign tp2_1_3_zero = (i_tp2_S1 == 10'b0) && (i_tp2_S3 == 10'b0);
    assign tp2_5_7_zero = (i_tp2_S5 == 10'b0) && (i_tp2_S7 == 10'b0);
    assign tp3_1_3_zero = (i_tp3_S1 == 10'b0) && (i_tp3_S3 == 10'b0);
    assign tp3_5_7_zero = (i_tp3_S5 == 10'b0) && (i_tp3_S7 == 10'b0);
    assign tp4_1_3_zero = (i_tp4_S1 == 10'b0) && (i_tp4_S3 == 10'b0);
    assign tp4_5_7_zero = (i_tp4_S5 == 10'b0) && (i_tp4_S7 == 10'b0);

    assign tp1_zero = tp1_1_3_zero && (tp1_5_7_zero || i_code != 2'b10);
    assign tp2_zero = tp2_1_3_zero && (tp2_5_7_zero || i_code != 2'b10);
    assign tp3_zero = tp3_1_3_zero && (tp3_5_7_zero || i_code != 2'b10);
    assign tp4_zero = tp4_1_3_zero && (tp4_5_7_zero || i_code != 2'b10);

    always @(*) begin
        if (i_mode == 0) begin
            if (i_tp1_valid && tp1_zero) begin
                early_stop = 1'b1;
            end
            else begin
                early_stop = 1'b0;
            end
        end
        else begin
            if (i_all_tp_valid && i_tp1_valid && (tp1_zero || tp2_zero || tp3_zero || tp4_zero)) begin
                early_stop = 1'b1;
            end
            else begin
                early_stop = 1'b0;
            end
        end
    end


    pulser u_pulser_early_stop (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_in    (early_stop),
        .i_clear (1'b0),
        .o_pulse (o_early_stop_pulse)
    );
endmodule