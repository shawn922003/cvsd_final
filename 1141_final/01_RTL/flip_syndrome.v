module flip_syndrome(
    input i_clk,
    input i_rst_n,

    input i_mode,
    input [1:0] i_code,

    input [9:0] i_S1,
    input [9:0] i_S2,
    input [9:0] i_S3,
    input [9:0] i_S4,
    input [9:0] i_S5,
    input [9:0] i_S6,
    input [9:0] i_S7,
    input [9:0] i_S8,

    input i_syndrome_valid,

    input [9:0] i_flip_alpha_S1_1,
    input [9:0] i_flip_alpha_S1_2,
    input [9:0] i_flip_alpha_S3_1,
    input [9:0] i_flip_alpha_S3_2,
    input [9:0] i_flip_alpha_S5_1,
    input [9:0] i_flip_alpha_S5_2,
    input [9:0] i_flip_alpha_S7_1,
    input [9:0] i_flip_alpha_S7_2,

    input i_flip_alpha_valid,

    output [9:0] o_tp2_S1,
    output [9:0] o_tp2_S2,
    output [9:0] o_tp2_S3,
    output [9:0] o_tp2_S4,
    output [9:0] o_tp2_S5,
    output [9:0] o_tp2_S6,
    output [9:0] o_tp2_S7,
    output [9:0] o_tp2_S8,

    output [9:0] o_tp3_S1,
    output [9:0] o_tp3_S2,
    output [9:0] o_tp3_S3,
    output [9:0] o_tp3_S4,
    output [9:0] o_tp3_S5,
    output [9:0] o_tp3_S6,
    output [9:0] o_tp3_S7,
    output [9:0] o_tp3_S8,

    output [9:0] o_tp4_S1,
    output [9:0] o_tp4_S2,
    output [9:0] o_tp4_S3,
    output [9:0] o_tp4_S4,
    output [9:0] o_tp4_S5,
    output [9:0] o_tp4_S6,
    output [9:0] o_tp4_S7,
    output [9:0] o_tp4_S8,

    output reg o_tp_valid
);

    wire gen;
    assign gen = i_mode;

    wire [9:0] tp2_S1;
    wire [9:0] tp2_S2;
    wire [9:0] tp2_S3;
    wire [9:0] tp2_S4;
    wire [9:0] tp2_S5;
    wire [9:0] tp2_S6;
    wire [9:0] tp2_S7;
    wire [9:0] tp2_S8;

    wire [9:0] tp3_S1;
    wire [9:0] tp3_S2;
    wire [9:0] tp3_S3;
    wire [9:0] tp3_S4;
    wire [9:0] tp3_S5;
    wire [9:0] tp3_S6;
    wire [9:0] tp3_S7;
    wire [9:0] tp3_S8;

    wire [9:0] tp4_S1;
    wire [9:0] tp4_S2;  
    wire [9:0] tp4_S3;
    wire [9:0] tp4_S4;
    wire [9:0] tp4_S5;
    wire [9:0] tp4_S6;
    wire [9:0] tp4_S7;
    wire [9:0] tp4_S8;

    reg [9:0] i_flip_alpha_S2_1;
    wire [9:0] i_flip_alpha_S2_1_next;
    reg [9:0] i_flip_alpha_S4_1;
    wire [9:0] i_flip_alpha_S4_1_next;
    reg [9:0] i_flip_alpha_S6_1;
    wire [9:0] i_flip_alpha_S6_1_next;
    reg [9:0] i_flip_alpha_S8_1;
    wire [9:0] i_flip_alpha_S8_1_next;

    reg [9:0] i_flip_alpha_S2_2;
    wire [9:0] i_flip_alpha_S2_2_next;
    reg [9:0] i_flip_alpha_S4_2;
    wire [9:0] i_flip_alpha_S4_2_next;
    reg [9:0] i_flip_alpha_S6_2;
    wire [9:0] i_flip_alpha_S6_2_next;
    reg [9:0] i_flip_alpha_S8_2;
    wire [9:0] i_flip_alpha_S8_2_next;

    assign tp2_S1 = i_S1 ^ i_flip_alpha_S1_1;
    assign tp2_S2 = i_S2 ^ i_flip_alpha_S2_1;
    assign tp2_S3 = i_S3 ^ i_flip_alpha_S3_1;
    assign tp2_S4 = i_S4 ^ i_flip_alpha_S4_1;
    assign tp2_S5 = i_S5 ^ i_flip_alpha_S5_1;
    assign tp2_S6 = i_S6 ^ i_flip_alpha_S6_1;
    assign tp2_S7 = i_S7 ^ i_flip_alpha_S7_1;
    assign tp2_S8 = i_S8 ^ i_flip_alpha_S8_1;

    assign tp3_S1 = i_S1 ^ i_flip_alpha_S1_2;
    assign tp3_S2 = i_S2 ^ i_flip_alpha_S2_2;
    assign tp3_S3 = i_S3 ^ i_flip_alpha_S3_2;
    assign tp3_S4 = i_S4 ^ i_flip_alpha_S4_2;
    assign tp3_S5 = i_S5 ^ i_flip_alpha_S5_2;
    assign tp3_S6 = i_S6 ^ i_flip_alpha_S6_2;
    assign tp3_S7 = i_S7 ^ i_flip_alpha_S7_2;
    assign tp3_S8 = i_S8 ^ i_flip_alpha_S8_2;

    assign tp4_S1 = tp2_S1 ^ i_flip_alpha_S1_2;
    assign tp4_S2 = tp2_S2 ^ i_flip_alpha_S2_2;
    assign tp4_S3 = tp2_S3 ^ i_flip_alpha_S3_2;
    assign tp4_S4 = tp2_S4 ^ i_flip_alpha_S4_2;
    assign tp4_S5 = tp2_S5 ^ i_flip_alpha_S5_2;
    assign tp4_S6 = tp2_S6 ^ i_flip_alpha_S6_2;
    assign tp4_S7 = tp2_S7 ^ i_flip_alpha_S7_2;
    assign tp4_S8 = tp2_S8 ^ i_flip_alpha_S8_2;

    assign o_tp2_S1 = tp2_S1;
    assign o_tp2_S2 = tp2_S2;
    assign o_tp2_S3 = tp2_S3;
    assign o_tp2_S4 = tp2_S4;
    assign o_tp2_S5 = tp2_S5;
    assign o_tp2_S6 = tp2_S6;
    assign o_tp2_S7 = tp2_S7;
    assign o_tp2_S8 = tp2_S8;

    assign o_tp3_S1 = tp3_S1;
    assign o_tp3_S2 = tp3_S2;
    assign o_tp3_S3 = tp3_S3;
    assign o_tp3_S4 = tp3_S4;
    assign o_tp3_S5 = tp3_S5;
    assign o_tp3_S6 = tp3_S6;
    assign o_tp3_S7 = tp3_S7;
    assign o_tp3_S8 = tp3_S8;

    assign o_tp4_S1 = tp4_S1;
    assign o_tp4_S2 = tp4_S2;
    assign o_tp4_S3 = tp4_S3;
    assign o_tp4_S4 = tp4_S4;
    assign o_tp4_S5 = tp4_S5;
    assign o_tp4_S6 = tp4_S6;
    assign o_tp4_S7 = tp4_S7;
    assign o_tp4_S8 = tp4_S8;



    // gf_mult u_gf_mult_S2 (
    //     .i_a(i_flip_alpha_S1_1),
    //     .i_b(i_flip_alpha_S1_1),
    //     .i_code(i_code),
    //     .o_product(i_flip_alpha_S2_1_next)
    // );

    // gf_mult u_gf_mult_S4 (
    //     .i_a(i_flip_alpha_S2_1_next),
    //     .i_b(i_flip_alpha_S2_1_next),
    //     .i_code(i_code),
    //     .o_product(i_flip_alpha_S4_1_next)
    // );

    // gf_mult u_gf_mult_S6 (
    //     .i_a(i_flip_alpha_S3_1),
    //     .i_b(i_flip_alpha_S3_1),
    //     .i_code(i_code),
    //     .o_product(i_flip_alpha_S6_1_next)
    // );
    
    // gf_mult u_gf_mult_S8 (
    //     .i_a(i_flip_alpha_S4_1_next),
    //     .i_b(i_flip_alpha_S4_1_next),
    //     .i_code(i_code),
    //     .o_product(i_flip_alpha_S8_1_next)
    // );

    // gf_mult u_gf_mult_S2_second (
    //     .i_a(i_flip_alpha_S1_2),
    //     .i_b(i_flip_alpha_S1_2),
    //     .i_code(i_code),
    //     .o_product(i_flip_alpha_S2_2_next)
    // );

    // gf_mult u_gf_mult_S4_second (
    //     .i_a(i_flip_alpha_S2_2_next),
    //     .i_b(i_flip_alpha_S2_2_next),
    //     .i_code(i_code),
    //     .o_product(i_flip_alpha_S4_2_next)
    // );

    // gf_mult u_gf_mult_S6_second (
    //     .i_a(i_flip_alpha_S3_2),
    //     .i_b(i_flip_alpha_S3_2),
    //     .i_code(i_code),
    //     .o_product(i_flip_alpha_S6_2_next)
    // );

    // gf_mult u_gf_mult_S8_second (
    //     .i_a(i_flip_alpha_S4_2_next),
    //     .i_b(i_flip_alpha_S4_2_next),
    //     .i_code(i_code),
    //     .o_product(i_flip_alpha_S8_2_next)
    // );

    gf_square u_gf_square_S2_1 (
        .i_in(i_flip_alpha_S1_1),
        .i_code(i_code),
        .o_out(i_flip_alpha_S2_1_next)
    );

    gf_square u_gf_square_S4_1 (
        .i_in(i_flip_alpha_S2_1_next),
        .i_code(i_code),
        .o_out(i_flip_alpha_S4_1_next)
    );

    gf_square u_gf_square_S6_1 (
        .i_in(i_flip_alpha_S3_1),
        .i_code(i_code),
        .o_out(i_flip_alpha_S6_1_next)
    );

    gf_square u_gf_square_S8_1 (
        .i_in(i_flip_alpha_S4_1_next),
        .i_code(i_code),
        .o_out(i_flip_alpha_S8_1_next)
    );

    gf_square u_gf_square_S2_2 (
        .i_in(i_flip_alpha_S1_2),
        .i_code(i_code),
        .o_out(i_flip_alpha_S2_2_next)
    );

    gf_square u_gf_square_S4_2 (
        .i_in(i_flip_alpha_S2_2_next),
        .i_code(i_code),
        .o_out(i_flip_alpha_S4_2_next)
    );

    gf_square u_gf_square_S6_2 (
        .i_in(i_flip_alpha_S3_2),
        .i_code(i_code),
        .o_out(i_flip_alpha_S6_2_next)
    );

    gf_square u_gf_square_S8_2 (
        .i_in(i_flip_alpha_S4_2_next),
        .i_code(i_code),
        .o_out(i_flip_alpha_S8_2_next)
    );

    


    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            i_flip_alpha_S2_1 <= 10'b0;
            i_flip_alpha_S4_1 <= 10'b0;
            i_flip_alpha_S6_1 <= 10'b0;
            i_flip_alpha_S8_1 <= 10'b0;

            i_flip_alpha_S2_2 <= 10'b0;
            i_flip_alpha_S4_2 <= 10'b0;
            i_flip_alpha_S6_2 <= 10'b0;
            i_flip_alpha_S8_2 <= 10'b0;
        end
        else begin
            // 第一組 alpha：用 gen 做 clock enable
            i_flip_alpha_S2_1 <= gen ? i_flip_alpha_S2_1_next : i_flip_alpha_S2_1;
            i_flip_alpha_S4_1 <= gen ? i_flip_alpha_S4_1_next : i_flip_alpha_S4_1;
            i_flip_alpha_S6_1 <= (gen && (i_code == 2'b10)) ? i_flip_alpha_S6_1_next : i_flip_alpha_S6_1;
            i_flip_alpha_S8_1 <= (gen && (i_code == 2'b10)) ? i_flip_alpha_S8_1_next : i_flip_alpha_S8_1;

            // 第二組 alpha：一樣用 gen gating
            i_flip_alpha_S2_2 <= gen ? i_flip_alpha_S2_2_next : i_flip_alpha_S2_2;
            i_flip_alpha_S4_2 <= gen ? i_flip_alpha_S4_2_next : i_flip_alpha_S4_2;
            i_flip_alpha_S6_2 <= (gen && (i_code == 2'b10)) ? i_flip_alpha_S6_2_next : i_flip_alpha_S6_2;
            i_flip_alpha_S8_2 <= (gen && (i_code == 2'b10)) ? i_flip_alpha_S8_2_next : i_flip_alpha_S8_2;
        end
    end


    reg [1:0] counter, counter_next;
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            counter <= 2'b0;
        end
        else begin
            counter <= gen ? counter_next : counter;
        end
    end

    always @(*) begin
        if (!i_flip_alpha_valid) begin
            counter_next = 2'b0;
        end
        else if (i_flip_alpha_valid && counter != 2'd3) begin
            counter_next = counter + 2'b1;
        end
        else begin
            counter_next = counter;
        end
    end

    always @(*) begin
        if (i_code == 2'b10) begin
            o_tp_valid = (counter == 2'd1) && i_syndrome_valid && i_flip_alpha_valid;
        end
        else begin
            o_tp_valid = (counter == 2'd1) && i_syndrome_valid && i_flip_alpha_valid;
        end
    end

endmodule