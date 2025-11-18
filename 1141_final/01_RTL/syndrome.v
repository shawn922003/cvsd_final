module syndrome(
    input i_clk,
    input i_rst_n, // synchronous reset, active low

    input [1:0] i_code, // 00: bch (63,51), 01: bch (255, 239), 10: bch (1023, 983)
    input i_clear,
    input i_wen,

    input [7:0] i_data,

    output [9:0] o_S1,
    output [9:0] o_S2,
    output [9:0] o_S3,
    output [9:0] o_S4,
    output [9:0] o_S5,
    output [9:0] o_S6,
    output [9:0] o_S7,
    output [9:0] o_S8,

    output reg o_odd_valid,
    output reg o_all_valid
);
    localparam m6_alpha_n0 = 6'b000001; // alpha^(0) = 1
    localparam m6_alpha_n1 = 6'b100001; // alpha^(-1) = alpha^(62)
    localparam m6_alpha_n2 = 6'b110001; // alpha^(-2) = alpha^(61)
    localparam m6_alpha_n3 = 6'b111001; // alpha^(-3) = alpha^(60)
    localparam m6_alpha_n4 = 6'b111101; // alpha^(-4) = alpha^(59)
    localparam m6_alpha_n5 = 6'b111111; // alpha^(-5) = alpha^(58)
    localparam m6_alpha_n6 = 6'b111110; // alpha^(-6) = alpha^(57)
    localparam m6_alpha_n7 = 6'b011111; // alpha^(-7) = alpha^(56)
    localparam m6_alpha_n8 = 6'b101110; // alpha^(-8) = alpha^(55)
    localparam m6_alpha_n9 = 6'b010111; // alpha^(-9) = alpha^(54)
    localparam m6_alpha_n12 = 6'b101011; // alpha^(-12) = alpha^(51)
    localparam m6_alpha_n15 = 6'b001101; // alpha^(-15) = alpha^(48)
    localparam m6_alpha_n18 = 6'b011001; // alpha^(-18) = alpha^(45)
    localparam m6_alpha_n21 = 6'b111010; // alpha^(-21) = alpha^(42)
    localparam m6_alpha_n24 = 6'b110110; // alpha^(-24) = alpha^(39)

    localparam m8_alpha_n0 = 8'b00000001; // alpha^(0) = 1
    localparam m8_alpha_n1 = 8'b10001110; // alpha^(-1) = alpha^(254)
    localparam m8_alpha_n2 = 8'b01000111; // alpha^(-2) = alpha^(253)
    localparam m8_alpha_n3 = 8'b10101101; // alpha^(-3) = alpha^(252)
    localparam m8_alpha_n4 = 8'b11011000; // alpha^(-4) = alpha^(251)
    localparam m8_alpha_n5 = 8'b01101100; // alpha^(-5) = alpha^(250)
    localparam m8_alpha_n6 = 8'b00110110; // alpha^(-6) = alpha^(249)
    localparam m8_alpha_n7 = 8'b00011011; // alpha^(-7) = alpha^(248)
    localparam m8_alpha_n8 = 8'b10000011; // alpha^(-8) = alpha^(247)
    localparam m8_alpha_n9 = 8'b11001111; // alpha^(-9) = alpha^(246)
    localparam m8_alpha_n12 = 8'b01111101; // alpha^(-12) = alpha^(243)
    localparam m8_alpha_n15 = 8'b00101100; // alpha^(-15) = alpha^(240)
    localparam m8_alpha_n18 = 8'b10001011; // alpha^(-18) = alpha^(237)
    localparam m8_alpha_n21 = 8'b11111011; // alpha^(-21) = alpha^(234)
    localparam m8_alpha_n24 = 8'b11110101; // alpha^(-24) = alpha^(231)

    localparam m10_alpha_n0 = 10'b0000000001; // alpha^(0) = 1
    localparam m10_alpha_n1 = 10'b1000000100; // alpha^(-1) = alpha^(1022)
    localparam m10_alpha_n2 = 10'b0100000010; // alpha^(-2) = alpha^(1021)
    localparam m10_alpha_n3 = 10'b0010000001; // alpha^(-3) = alpha^(1020)
    localparam m10_alpha_n4 = 10'b1001000100; // alpha^(-4) = alpha^(1019)
    localparam m10_alpha_n5 = 10'b0100100010; // alpha^(-5) = alpha^(1018)
    localparam m10_alpha_n6 = 10'b0010010001; // alpha^(-6) = alpha^(1017)
    localparam m10_alpha_n7 = 10'b1001001100; // alpha^(-7) = alpha^(1016)
    localparam m10_alpha_n8 = 10'b0100100110; // alpha^(-8) = alpha^(1015)
    localparam m10_alpha_n9 = 10'b0010010011; // alpha^(-9) = alpha^(1014)
    localparam m10_alpha_n10 = 10'b1001001101; // alpha^(-10) = alpha^(1013)
    localparam m10_alpha_n12 = 10'b0110010001; // alpha^(-12) = alpha^(1011)
    localparam m10_alpha_n14 = 10'b0101100110; // alpha^(-14) = alpha^(1009)
    localparam m10_alpha_n15 = 10'b0010110011; // alpha^(-15) = alpha^(1008)
    localparam m10_alpha_n18 = 10'b0110010101; // alpha^(-18) = alpha^(1005)
    localparam m10_alpha_n20 = 10'b0101100111; // alpha^(-20) = alpha^(1003)
    localparam m10_alpha_n21 = 10'b1010110111; // alpha^(-21) = alpha^(1002)
    localparam m10_alpha_n24 = 10'b1111010001; // alpha^(-24) = alpha^(999)
    localparam m10_alpha_n25 = 10'b1111101100; // alpha^(-25) = alpha^(998)
    localparam m10_alpha_n28 = 10'b1001111001; // alpha^(-28) = alpha^(995)
    localparam m10_alpha_n30 = 10'b0110011100; // alpha^(-30) = alpha^(993)
    localparam m10_alpha_n35 = 10'b1110001011; // alpha^(-35) = alpha^(988)
    localparam m10_alpha_n40 = 10'b1001111000; // alpha^(-40) = alpha^(983)
    localparam m10_alpha_n42 = 10'b0010011110; // alpha^(-42) = alpha^(981)
    localparam m10_alpha_n49 = 10'b1101110111; // alpha^(-49) = alpha^(974)
    localparam m10_alpha_n56 = 10'b0001111110; // alpha^(-56) = alpha^(967)

    localparam S5_factor = m10_alpha_n40;
    localparam S7_factor = m10_alpha_n56;


    reg [9:0] S1_poly_power[0:7];
    reg [9:0] S1_poly_power_next[0:7];
    reg [9:0] S3_poly_power[0:7];
    reg [9:0] S3_poly_power_next[0:7];
    reg [9:0] S5_poly_power[0:7];
    reg [9:0] S5_poly_power_next[0:7];
    reg [9:0] S7_poly_power[0:7];
    reg [9:0] S7_poly_power_next[0:7];

    reg [9:0] S1_factor, S3_factor;
    reg [9:0] S1_factor_next, S3_factor_next;

    wire [9:0] S1_poly_power_next_wire[0:7];
    wire [9:0] S3_poly_power_next_wire[0:7];    
    wire [9:0] S5_poly_power_next_wire[0:7];
    wire [9:0] S7_poly_power_next_wire[0:7];

    reg [9:0] S1, S2, S3, S4, S5, S6, S7, S8;
    reg [9:0] S1_next, S3_next, S5_next, S7_next;
    wire [9:0] S2_next, S4_next, S6_next, S8_next;



    reg [7:0] counter, counter_next;

    reg odd_valid;


    integer i;


    // generate gf mult
    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin : GEN_GFMULT_S1
            gf_mult u_gf_mult_S1 (
                .i_a(S1_poly_power[j]),
                .i_b(S1_factor),
                .i_code(i_code),
                .o_product(S1_poly_power_next_wire[j])
            );

            gf_mult u_gf_mult_S3 (
                .i_a(S3_poly_power[j]),
                .i_b(S3_factor),
                .i_code(i_code),
                .o_product(S3_poly_power_next_wire[j])
            );

            gf_mult u_gf_mult_S5 (
                .i_a(S5_poly_power[j]),
                .i_b(S5_factor),
                .i_code(2'b10),
                .o_product(S5_poly_power_next_wire[j])
            );

            gf_mult u_gf_mult_S7 (
                .i_a(S7_poly_power[j]),
                .i_b(S7_factor),
                .i_code(2'b10),
                .o_product(S7_poly_power_next_wire[j])
            );
        end
    endgenerate

    gf_mult u_gf_mult_S2 (
        .i_a(S1),
        .i_b(S1),
        .i_code(i_code),
        .o_product(S2_next)
    );

    gf_mult u_gf_mult_S4 (
        .i_a(S2),
        .i_b(S2),
        .i_code(i_code),
        .o_product(S4_next)
    );

    gf_mult u_gf_mult_S6 (
        .i_a(S3),
        .i_b(S3),
        .i_code(2'b10),
        .o_product(S6_next)
    );

    gf_mult u_gf_mult_S8 (
        .i_a(S4),
        .i_b(S4),
        .i_code(2'b10),
        .o_product(S8_next)
    );


    // syndrome output assign logic
    assign o_S1 = S1;
    assign o_S2 = S2;
    assign o_S3 = S3;
    assign o_S4 = S4;
    assign o_S5 = S5;
    assign o_S6 = S6;
    assign o_S7 = S7;
    assign o_S8 = S8;


    // counter logic
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            counter <= 8'b0;
        end
        else begin
            counter <= counter_next;
        end
    end

    always @(*) begin
        if (i_clear) begin
            counter_next = 8'b0;
        end
        else if (counter == 8'd131) begin
            counter_next = counter;
        end
        else if (i_wen) begin
            counter_next = counter + 8'b1;
        end
        else begin
            counter_next = counter;
        end
    end 

    // odd_valid logic
    always @(*) begin
        case(i_code) // synopsys full_case
            2'b00: begin
                o_odd_valid = counter >= 8'd8;
                o_all_valid = counter >= 8'd10;
            end
            2'b01: begin
                o_odd_valid = counter >= 8'd32;
                o_all_valid = counter >= 8'd34;
            end
            2'b10: begin
                o_odd_valid = counter >= 8'd128;
                o_all_valid = counter >= 8'd131;
            end
        endcase
    end




    // S1, S3, S5, S7 polynomial power and multiplication factor update logic
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                S1_poly_power[i] <= 10'b0;
                S3_poly_power[i] <= 10'b0;
            end

            S5_poly_power_next[0] = m10_alpha_n0;
            S5_poly_power_next[1] = m10_alpha_n5;
            S5_poly_power_next[2] = m10_alpha_n10;
            S5_poly_power_next[3] = m10_alpha_n15;
            S5_poly_power_next[4] = m10_alpha_n20;
            S5_poly_power_next[5] = m10_alpha_n25;
            S5_poly_power_next[6] = m10_alpha_n30;
            S5_poly_power_next[7] = m10_alpha_n35;

            S7_poly_power_next[0] = m10_alpha_n0;
            S7_poly_power_next[1] = m10_alpha_n7;
            S7_poly_power_next[2] = m10_alpha_n14;
            S7_poly_power_next[3] = m10_alpha_n21;
            S7_poly_power_next[4] = m10_alpha_n28;
            S7_poly_power_next[5] = m10_alpha_n35;
            S7_poly_power_next[6] = m10_alpha_n42;
            S7_poly_power_next[7] = m10_alpha_n49;

            S1_factor <= 10'b0;
            S3_factor <= 10'b0;

        end
        else begin
            for (i = 0; i < 8; i = i + 1) begin
                S1_poly_power[i] <= S1_poly_power_next[i];
                S3_poly_power[i] <= S3_poly_power_next[i];
                S5_poly_power[i] <= S5_poly_power_next[i];
                S7_poly_power[i] <= S7_poly_power_next[i];
            end

            S1_factor <= S1_factor_next;
            S3_factor <= S3_factor_next;
        end
    end

    always @(*) begin
        if (i_clear) begin
            case(i_code) // synopsys full_case
                2'b00: begin
                    S1_poly_power_next[0] = m6_alpha_n0;
                    S1_poly_power_next[1] = m6_alpha_n1;
                    S1_poly_power_next[2] = m6_alpha_n2;
                    S1_poly_power_next[3] = m6_alpha_n3;
                    S1_poly_power_next[4] = m6_alpha_n4;
                    S1_poly_power_next[5] = m6_alpha_n5;
                    S1_poly_power_next[6] = m6_alpha_n6;
                    S1_poly_power_next[7] = m6_alpha_n7;

                    S3_poly_power_next[0] = m6_alpha_n0;
                    S3_poly_power_next[1] = m6_alpha_n3;
                    S3_poly_power_next[2] = m6_alpha_n6;
                    S3_poly_power_next[3] = m6_alpha_n9;
                    S3_poly_power_next[4] = m6_alpha_n12;
                    S3_poly_power_next[5] = m6_alpha_n15;
                    S3_poly_power_next[6] = m6_alpha_n18;
                    S3_poly_power_next[7] = m6_alpha_n21;      

                    S1_factor_next = m6_alpha_n8;  
                    S3_factor_next = m6_alpha_n24;
                end
                2'b01: begin
                    S1_poly_power_next[0] = m8_alpha_n0;
                    S1_poly_power_next[1] = m8_alpha_n1;
                    S1_poly_power_next[2] = m8_alpha_n2;
                    S1_poly_power_next[3] = m8_alpha_n3;
                    S1_poly_power_next[4] = m8_alpha_n4;
                    S1_poly_power_next[5] = m8_alpha_n5;
                    S1_poly_power_next[6] = m8_alpha_n6;
                    S1_poly_power_next[7] = m8_alpha_n7;

                    S3_poly_power_next[0] = m8_alpha_n0;
                    S3_poly_power_next[1] = m8_alpha_n3;
                    S3_poly_power_next[2] = m8_alpha_n6;
                    S3_poly_power_next[3] = m8_alpha_n9;
                    S3_poly_power_next[4] = m8_alpha_n12;
                    S3_poly_power_next[5] = m8_alpha_n15;
                    S3_poly_power_next[6] = m8_alpha_n18;
                    S3_poly_power_next[7] = m8_alpha_n21;

                    S1_factor_next = m8_alpha_n8;
                    S3_factor_next = m8_alpha_n24;
                end
                2'b10: begin
                    S1_poly_power_next[0] = m10_alpha_n0;
                    S1_poly_power_next[1] = m10_alpha_n1;
                    S1_poly_power_next[2] = m10_alpha_n2;
                    S1_poly_power_next[3] = m10_alpha_n3;
                    S1_poly_power_next[4] = m10_alpha_n4;
                    S1_poly_power_next[5] = m10_alpha_n5;
                    S1_poly_power_next[6] = m10_alpha_n6;
                    S1_poly_power_next[7] = m10_alpha_n7;

                    S3_poly_power_next[0] = m10_alpha_n0;
                    S3_poly_power_next[1] = m10_alpha_n3;
                    S3_poly_power_next[2] = m10_alpha_n6;
                    S3_poly_power_next[3] = m10_alpha_n9;
                    S3_poly_power_next[4] = m10_alpha_n12;
                    S3_poly_power_next[5] = m10_alpha_n15;
                    S3_poly_power_next[6] = m10_alpha_n18;
                    S3_poly_power_next[7] = m10_alpha_n21;

                    S5_poly_power_next[0] = m10_alpha_n0;
                    S5_poly_power_next[1] = m10_alpha_n5;
                    S5_poly_power_next[2] = m10_alpha_n10;
                    S5_poly_power_next[3] = m10_alpha_n15;
                    S5_poly_power_next[4] = m10_alpha_n20;
                    S5_poly_power_next[5] = m10_alpha_n25;
                    S5_poly_power_next[6] = m10_alpha_n30;
                    S5_poly_power_next[7] = m10_alpha_n35;

                    S7_poly_power_next[0] = m10_alpha_n0;
                    S7_poly_power_next[1] = m10_alpha_n7;
                    S7_poly_power_next[2] = m10_alpha_n14;
                    S7_poly_power_next[3] = m10_alpha_n21;
                    S7_poly_power_next[4] = m10_alpha_n28;
                    S7_poly_power_next[5] = m10_alpha_n35;
                    S7_poly_power_next[6] = m10_alpha_n42;
                    S7_poly_power_next[7] = m10_alpha_n49;

                    S1_factor_next = m10_alpha_n8;
                    S3_factor_next = m10_alpha_n24;
                end
            endcase
        end
        else begin
            S1_factor_next = S1_factor;
            S3_factor_next = S3_factor;

            for (i = 0; i < 8; i = i + 1) begin
                if (i_wen) begin
                    S1_poly_power_next[i] = S1_poly_power_next_wire[i];
                    S3_poly_power_next[i] = S3_poly_power_next_wire[i];
                    if (i_code == 2'b10) begin
                        S5_poly_power_next[i] = S5_poly_power_next_wire[i];
                        S7_poly_power_next[i] = S7_poly_power_next_wire[i];
                    end
                    else begin
                        S5_poly_power_next[i] = S5_poly_power[i];
                        S7_poly_power_next[i] = S7_poly_power[i];
                    end
                end
                else begin
                    S1_poly_power_next[i] = S1_poly_power[i];
                    S3_poly_power_next[i] = S3_poly_power[i];
                    S5_poly_power_next[i] = S5_poly_power[i];
                    S7_poly_power_next[i] = S7_poly_power[i];
                end
            end
        end
    end


    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            S1 <= 10'b0;
            S2 <= 10'b0;
            S3 <= 10'b0;
            S4 <= 10'b0;
            S5 <= 10'b0;
            S6 <= 10'b0;
            S7 <= 10'b0;
            S8 <= 10'b0;
        end
        else begin
            S1 <= S1_next;
            S2 <= S2_next;
            S3 <= S3_next;
            S4 <= S4_next;
            S5 <= S5_next;
            S6 <= S6_next;
            S7 <= S7_next;
            S8 <= S8_next;
        end
    end

    always @(*) begin
        if (i_clear) begin
            S1_next = 10'b0;
            S3_next = 10'b0;
            if (i_code == 2'b10) begin
                S5_next = 10'b0;
                S7_next = 10'b0;
            end
            else begin
                S5_next = S5;
                S7_next = S7;
            end
        end
        else if (i_wen) begin
            S1_next = (S1_poly_power[0] & {10{i_data[7]}}) ^
                      (S1_poly_power[1] & {10{i_data[6]}}) ^
                      (S1_poly_power[2] & {10{i_data[5]}}) ^
                      (S1_poly_power[3] & {10{i_data[4]}}) ^
                      (S1_poly_power[4] & {10{i_data[3]}}) ^
                      (S1_poly_power[5] & {10{i_data[2]}}) ^
                      (S1_poly_power[6] & {10{i_data[1]}}) ^
                      (S1_poly_power[7] & {10{i_data[0]}});

            S3_next = (S3_poly_power[0] & {10{i_data[7]}}) ^
                        (S3_poly_power[1] & {10{i_data[6]}}) ^
                        (S3_poly_power[2] & {10{i_data[5]}}) ^
                        (S3_poly_power[3] & {10{i_data[4]}}) ^
                        (S3_poly_power[4] & {10{i_data[3]}}) ^
                        (S3_poly_power[5] & {10{i_data[2]}}) ^
                        (S3_poly_power[6] & {10{i_data[1]}}) ^
                        (S3_poly_power[7] & {10{i_data[0]}});

            if (i_code == 2'b10) begin
                S5_next = (S5_poly_power[0] & {10{i_data[7]}}) ^
                            (S5_poly_power[1] & {10{i_data[6]}}) ^
                            (S5_poly_power[2] & {10{i_data[5]}}) ^
                            (S5_poly_power[3] & {10{i_data[4]}}) ^
                            (S5_poly_power[4] & {10{i_data[3]}}) ^
                            (S5_poly_power[5] & {10{i_data[2]}}) ^
                            (S5_poly_power[6] & {10{i_data[1]}}) ^
                            (S5_poly_power[7] & {10{i_data[0]}});

                S7_next = (S7_poly_power[0] & {10{i_data[7]}}) ^
                            (S7_poly_power[1] & {10{i_data[6]}}) ^
                            (S7_poly_power[2] & {10{i_data[5]}}) ^
                            (S7_poly_power[3] & {10{i_data[4]}}) ^
                            (S7_poly_power[4] & {10{i_data[3]}}) ^
                            (S7_poly_power[5] & {10{i_data[2]}}) ^
                            (S7_poly_power[6] & {10{i_data[1]}}) ^
                            (S7_poly_power[7] & {10{i_data[0]}});
            end
            else begin
                S5_next = S5;
                S7_next = S7;
            end
        end
        else begin
            S1_next = S1;
            S3_next = S3;
            S5_next = S5;
            S7_next = S7;
        end
    end

endmodule