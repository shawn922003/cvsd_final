module gf_add(
    input [9:0] i_a,
    input [9:0] i_b,
    output [9:0] o_sum
);


    assign o_sum = i_a ^ i_b; // GF(2^m) addition is XOR

endmodule

// i_code == 0: m = 6, p(x) = x^6 + x + 1
// i_code == 1: m = 8, p(x) = x^8 + x^4 + x^3 + x^2 + 1
// i_code == 2: m = 10, p(x) = x^10 + x^3 + 1
module gf_mult(
    input [9:0] i_a,
    input [9:0] i_b,
    input [1:0] i_code,
    output reg [9:0] o_product
);
    wire [18:0] row_xor;
    
    assign row_xor[0] = i_a[0] & i_b[0];
    assign row_xor[1] = (i_a[1] & i_b[0]) ^ (i_a[0] & i_b[1]);
    assign row_xor[2] = (i_a[2] & i_b[0]) ^ (i_a[1] & i_b[1]) ^ (i_a[0] & i_b[2]);
    assign row_xor[3] = (i_a[3] & i_b[0]) ^ (i_a[2] & i_b[1]) ^ (i_a[1] & i_b[2]) ^ 
                        (i_a[0] & i_b[3]);
    assign row_xor[4] = (i_a[4] & i_b[0]) ^ (i_a[3] & i_b[1]) ^ (i_a[2] & i_b[2]) ^
                        (i_a[1] & i_b[3]) ^ (i_a[0] & i_b[4]);
    assign row_xor[5] = (i_a[5] & i_b[0]) ^ (i_a[4] & i_b[1]) ^ (i_a[3] & i_b[2]) ^
                        (i_a[2] & i_b[3]) ^ (i_a[1] & i_b[4]) ^ (i_a[0] & i_b[5]);
    assign row_xor[6] = (i_a[6] & i_b[0]) ^ (i_a[5] & i_b[1]) ^ (i_a[4] & i_b[2]) ^ 
                        (i_a[3] & i_b[3]) ^ (i_a[2] & i_b[4]) ^ (i_a[1] & i_b[5]) ^
                        (i_a[0] & i_b[6]);
    assign row_xor[7] = (i_a[7] & i_b[0]) ^ (i_a[6] & i_b[1]) ^ (i_a[5] & i_b[2]) ^
                        (i_a[4] & i_b[3]) ^ (i_a[3] & i_b[4]) ^ (i_a[2] & i_b[5]) ^
                        (i_a[1] & i_b[6]) ^ (i_a[0] & i_b[7]);
    assign row_xor[8] = (i_a[8] & i_b[0]) ^ (i_a[7] & i_b[1]) ^ (i_a[6] & i_b[2]) ^ 
                        (i_a[5] & i_b[3]) ^ (i_a[4] & i_b[4]) ^ (i_a[3] & i_b[5]) ^
                        (i_a[2] & i_b[6]) ^ (i_a[1] & i_b[7]) ^ (i_a[0] & i_b[8]);
    assign row_xor[9] = (i_a[9] & i_b[0]) ^ (i_a[8] & i_b[1]) ^ (i_a[7] & i_b[2]) ^
                        (i_a[6] & i_b[3]) ^ (i_a[5] & i_b[4]) ^ (i_a[4] & i_b[5]) ^
                        (i_a[3] & i_b[6]) ^ (i_a[2] & i_b[7]) ^ (i_a[1] & i_b[8]) ^
                        (i_a[0] & i_b[9]);
    assign row_xor[10] =    (i_a[9] & i_b[1]) ^ (i_a[8] & i_b[2]) ^ (i_a[7] & i_b[3]) ^
                            (i_a[6] & i_b[4]) ^ (i_a[5] & i_b[5]) ^ (i_a[4] & i_b[6]) ^
                            (i_a[3] & i_b[7]) ^ (i_a[2] & i_b[8]) ^ (i_a[1] & i_b[9]);
    assign row_xor[11] =    (i_a[9] & i_b[2]) ^ (i_a[8] & i_b[3]) ^ (i_a[7] & i_b[4]) ^
                            (i_a[6] & i_b[5]) ^ (i_a[5] & i_b[6]) ^ (i_a[4] & i_b[7]) ^
                            (i_a[3] & i_b[8]) ^ (i_a[2] & i_b[9]);
    assign row_xor[12] =    (i_a[9] & i_b[3]) ^ (i_a[8] & i_b[4]) ^ (i_a[7] & i_b[5]) ^
                            (i_a[6] & i_b[6]) ^ (i_a[5] & i_b[7]) ^ (i_a[4] & i_b[8]) ^
                            (i_a[3] & i_b[9]);
    assign row_xor[13] =    (i_a[9] & i_b[4]) ^ (i_a[8] & i_b[5]) ^ (i_a[7] & i_b[6]) ^
                            (i_a[6] & i_b[7]) ^ (i_a[5] & i_b[8]) ^ (i_a[4] & i_b[9]);
    assign row_xor[14] =    (i_a[9] & i_b[5]) ^ (i_a[8] & i_b[6]) ^ (i_a[7] & i_b[7]) ^
                            (i_a[6] & i_b[8]) ^ (i_a[5] & i_b[9]);
    assign row_xor[15] =    (i_a[9] & i_b[6]) ^ (i_a[8] & i_b[7]) ^ (i_a[7] & i_b[8]) ^
                            (i_a[6] & i_b[9]);
    assign row_xor[16] =    (i_a[9] & i_b[7]) ^ (i_a[8] & i_b[8]) ^ (i_a[7] & i_b[9]);  
    assign row_xor[17] =    (i_a[9] & i_b[8]) ^ (i_a[8] & i_b[9]);
    assign row_xor[18] =    (i_a[9] & i_b[9]);


    always @(*) begin
        case(i_code) // synopsys full_case
            2'b00: begin
                o_product[0] = row_xor[0] ^ row_xor[6];
                o_product[1] = row_xor[1] ^ row_xor[6] ^ row_xor[7];
                o_product[2] = row_xor[2] ^ row_xor[7] ^ row_xor[8];
                o_product[3] = row_xor[3] ^ row_xor[8] ^ row_xor[9];
                o_product[4] = row_xor[4] ^ row_xor[9] ^ row_xor[10];
                o_product[5] = row_xor[5] ^ row_xor[10];
                o_product[9:6] = 4'b0;
            end
            2'b01: begin
                o_product[0] = row_xor[0] ^ row_xor[8] ^ row_xor[12] ^ row_xor[13] ^ row_xor[14];
                o_product[1] = row_xor[1] ^ row_xor[9] ^ row_xor[13] ^ row_xor[14];
                o_product[2] = row_xor[2] ^ row_xor[8] ^ row_xor[10] ^ row_xor[12] ^ row_xor[13];
                o_product[3] = row_xor[3] ^ row_xor[8] ^ row_xor[9] ^ row_xor[11] ^ row_xor[12];
                o_product[4] = row_xor[4] ^ row_xor[8] ^ row_xor[9] ^ row_xor[10] ^ row_xor[14];
                o_product[5] = row_xor[5] ^ row_xor[9] ^ row_xor[10] ^ row_xor[11];
                o_product[6] = row_xor[6] ^ row_xor[10] ^ row_xor[11] ^ row_xor[12];
                o_product[7] = row_xor[7] ^ row_xor[11] ^ row_xor[12] ^ row_xor[13];
                o_product[9:8] = 2'b0;
            end
            2'b10: begin
                o_product[0] = row_xor[0] ^ row_xor[10] ^ row_xor[17];
                o_product[1] = row_xor[1] ^ row_xor[11] ^ row_xor[18];
                o_product[2] = row_xor[2] ^ row_xor[12];
                o_product[3] = row_xor[3] ^ row_xor[10] ^ row_xor[13] ^ row_xor[17];
                o_product[4] = row_xor[4] ^ row_xor[11] ^ row_xor[14] ^ row_xor[18];
                o_product[5] = row_xor[5] ^ row_xor[12] ^ row_xor[15];
                o_product[6] = row_xor[6] ^ row_xor[13] ^ row_xor[16];
                o_product[7] = row_xor[7] ^ row_xor[14] ^ row_xor[17];
                o_product[8] = row_xor[8] ^ row_xor[15] ^ row_xor[18];
                o_product[9] = row_xor[9] ^ row_xor[16];
            end
        endcase
    end       


endmodule
