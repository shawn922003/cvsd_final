module gf_square(
    input [9:0] i_in,
    input [1:0] i_code,
    output reg [9:0] o_out
);


    always @(*) begin
        case (i_code) // synopsys full_case
            2'b00: begin
                o_out[0] = i_in[0] ^ i_in[3];
                o_out[1] = i_in[3];
                o_out[2] = i_in[1] ^ i_in[4];
                o_out[3] = i_in[4];
                o_out[4] = i_in[2] ^ i_in[5];
                o_out[5] = i_in[5];
                o_out[6] = 1'b0;
                o_out[7] = 1'b0;
                o_out[8] = 1'b0;
                o_out[9] = 1'b0;
            end
            2'b01: begin
                o_out[0] = i_in[0] ^ i_in[4] ^ i_in[6] ^ i_in[7];
                o_out[1] = i_in[7];
                o_out[2] = i_in[1] ^ i_in[4] ^ i_in[5] ^ i_in[6];
                o_out[3] = i_in[4] ^ i_in[6];
                o_out[4] = i_in[2] ^ i_in[4] ^ i_in[5] ^ i_in[7];
                o_out[5] = i_in[5];
                o_out[6] = i_in[3] ^ i_in[5] ^ i_in[6];
                o_out[7] = i_in[6];
                o_out[8] = 1'b0;
                o_out[9] = 1'b0;
            end
            2'b10: begin
                o_out[0] = i_in[0] ^ i_in[5];
                o_out[1] = i_in[9];
                o_out[2] = i_in[1] ^ i_in[6];
                o_out[3] = i_in[5];
                o_out[4] = i_in[2] ^ i_in[7] ^ i_in[9];
                o_out[5] = i_in[6];
                o_out[6] = i_in[3] ^ i_in[8];
                o_out[7] = i_in[7];
                o_out[8] = i_in[4] ^ i_in[9];
                o_out[9] = i_in[8];
            end
        endcase
    end

endmodule