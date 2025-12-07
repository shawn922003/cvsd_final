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



    output       o_early_stop_pulse
);

    wire tp1_1_3_zero;
    wire tp1_5_7_zero;


    wire tp1_zero;
    wire tp2_zero;
    wire tp3_zero;
    wire tp4_zero;

    reg early_stop;

    assign tp1_1_3_zero = (i_tp1_S1 == 10'b0) && (i_tp1_S3 == 10'b0);
    assign tp1_5_7_zero = (i_tp1_S5 == 10'b0) && (i_tp1_S7 == 10'b0);


    assign tp1_zero = tp1_1_3_zero && (tp1_5_7_zero || i_code != 2'b10);

    always @(*) begin
        if (i_tp1_valid && tp1_zero) begin
            early_stop = 1'b1;
        end
        else begin
            early_stop = 1'b0;
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