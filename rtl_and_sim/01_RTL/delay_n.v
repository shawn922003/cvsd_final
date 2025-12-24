module  delay_n #(
    parameter N = 4,
    parameter BITS = 1,
    parameter INIT = {BITS{1'b0}}
)(
    input i_clk,
    input i_rst_n,
    input i_en,
    input [BITS-1:0] i_d,
    output [BITS-1:0] o_q
);
    // Generate N stages of delay using a shift register approach
    reg [BITS-1:0] shift_reg [0:N-1];
    reg [BITS-1:0] shift_reg_next [0:N-1];
    integer i;

    always @(*) begin
        // First stage takes input data if enabled
        shift_reg_next[0] = i_en ? i_d : shift_reg[0];
        // Subsequent stages take data from the previous stage
        for (i = 1; i < N; i = i + 1) begin
            shift_reg_next[i] = i_en ? shift_reg[i-1] : shift_reg[i];
        end
    end

    always @(posedge i_clk ) begin
        if (!i_rst_n) begin
            for (i = 0; i < N; i = i + 1) begin
                shift_reg[i] <= INIT;
            end
        end 
        else begin
            for (i = 0; i < N; i = i + 1) begin
                shift_reg[i] <= shift_reg_next[i];
            end

        end
    end

    assign o_q = shift_reg[N-1];
endmodule