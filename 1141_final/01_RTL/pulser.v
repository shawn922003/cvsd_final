module pulser(
    input i_clk,
    input i_rst_n,

    input i_in,
    input i_clear,

    output o_pulse
);

    wire i_in_dly;

    delay_n #(
        .N(1),
        .BITS(1),
        .INIT(1'b0)
    ) u_delay_n (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(i_in && !i_clear),
        .o_q(i_in_dly)
    );

    assign o_pulse = i_in & ~i_in_dly;

endmodule