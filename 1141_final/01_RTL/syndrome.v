module syndrome(
    input i_clk,
    input i_rst_n, // synchronous reset, active low

    input [1:0] i_code, // 00: bch (63,51), 01: bch (255, 239), 10: bch (1023, 983)
    input i_clear_and_wen,
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
    localparam m6_alpha_n0  = 6'b000001; // alpha^(0)  = 1
    localparam m6_alpha_n1  = 6'b100001; // alpha^(-1)  = alpha^(62)
    localparam m6_alpha_n2  = 6'b110001; // alpha^(-2)  = alpha^(61)
    localparam m6_alpha_n3  = 6'b111001; // alpha^(-3)  = alpha^(60)
    localparam m6_alpha_n4  = 6'b111101; // alpha^(-4)  = alpha^(59)
    localparam m6_alpha_n5  = 6'b111111; // alpha^(-5)  = alpha^(58)
    localparam m6_alpha_n6  = 6'b111110; // alpha^(-6)  = alpha^(57)
    localparam m6_alpha_n7  = 6'b011111; // alpha^(-7)  = alpha^(56)
    localparam m6_alpha_n8  = 6'b101110; // alpha^(-8)  = alpha^(55)
    localparam m6_alpha_n9  = 6'b010111; // alpha^(-9)  = alpha^(54)
    localparam m6_alpha_n10 = 6'b101010; // alpha^(-10) = alpha^(53)
    localparam m6_alpha_n11 = 6'b010101; // alpha^(-11) = alpha^(52)
    localparam m6_alpha_n12 = 6'b101011; // alpha^(-12) = alpha^(51)
    localparam m6_alpha_n13 = 6'b110100; // alpha^(-13) = alpha^(50)
    localparam m6_alpha_n14 = 6'b011010; // alpha^(-14) = alpha^(49)
    localparam m6_alpha_n15 = 6'b001101; // alpha^(-15) = alpha^(48)
    localparam m6_alpha_n16 = 6'b100111; // alpha^(-16) = alpha^(47)
    localparam m6_alpha_n17 = 6'b110010; // alpha^(-17) = alpha^(46)
    localparam m6_alpha_n18 = 6'b011001; // alpha^(-18) = alpha^(45)
    localparam m6_alpha_n19 = 6'b101101; // alpha^(-19) = alpha^(44)
    localparam m6_alpha_n20 = 6'b110111; // alpha^(-20) = alpha^(43)
    localparam m6_alpha_n21 = 6'b111010; // alpha^(-21) = alpha^(42)
    localparam m6_alpha_n22 = 6'b011101; // alpha^(-22) = alpha^(41)
    localparam m6_alpha_n23 = 6'b101111; // alpha^(-23) = alpha^(40)
    localparam m6_alpha_n24 = 6'b110110; // alpha^(-24) = alpha^(39)
    localparam m6_alpha_n25 = 6'b011011; // alpha^(-25) = alpha^(38)
    localparam m6_alpha_n26 = 6'b101100; // alpha^(-26) = alpha^(37)
    localparam m6_alpha_n27 = 6'b010110; // alpha^(-27) = alpha^(36)
    localparam m6_alpha_n28 = 6'b001011; // alpha^(-28) = alpha^(35)
    localparam m6_alpha_n29 = 6'b100100; // alpha^(-29) = alpha^(34)
    localparam m6_alpha_n30 = 6'b010010; // alpha^(-30) = alpha^(33)
    localparam m6_alpha_n31 = 6'b001001; // alpha^(-31) = alpha^(32)
    localparam m6_alpha_n32 = 6'b100101; // alpha^(-32) = alpha^(31)
    localparam m6_alpha_n33 = 6'b110011; // alpha^(-33) = alpha^(30)
    localparam m6_alpha_n34 = 6'b111000; // alpha^(-34) = alpha^(29)
    localparam m6_alpha_n35 = 6'b011100; // alpha^(-35) = alpha^(28)
    localparam m6_alpha_n36 = 6'b001110; // alpha^(-36) = alpha^(27)
    localparam m6_alpha_n37 = 6'b000111; // alpha^(-37) = alpha^(26)
    localparam m6_alpha_n38 = 6'b100010; // alpha^(-38) = alpha^(25)
    localparam m6_alpha_n39 = 6'b010001; // alpha^(-39) = alpha^(24)
    localparam m6_alpha_n40 = 6'b101001; // alpha^(-40) = alpha^(23)
    localparam m6_alpha_n41 = 6'b110101; // alpha^(-41) = alpha^(22)
    localparam m6_alpha_n42 = 6'b111011; // alpha^(-42) = alpha^(21)
    localparam m6_alpha_n43 = 6'b111100; // alpha^(-43) = alpha^(20)
    localparam m6_alpha_n44 = 6'b011110; // alpha^(-44) = alpha^(19)
    localparam m6_alpha_n45 = 6'b001111; // alpha^(-45) = alpha^(18)

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
    localparam m8_alpha_n10 = 8'b11101001; // alpha^(-10) = alpha^(245)
    localparam m8_alpha_n11 = 8'b11111010; // alpha^(-11) = alpha^(244)
    localparam m8_alpha_n12 = 8'b01111101; // alpha^(-12) = alpha^(243)
    localparam m8_alpha_n13 = 8'b10110000; // alpha^(-13) = alpha^(242)
    localparam m8_alpha_n14 = 8'b01011000; // alpha^(-14) = alpha^(241)
    localparam m8_alpha_n15 = 8'b00101100; // alpha^(-15) = alpha^(240)
    localparam m8_alpha_n16 = 8'b00001011; // alpha^(-16) = alpha^(239)
    localparam m8_alpha_n17 = 8'b10001011; // alpha^(-17) = alpha^(238)
    localparam m8_alpha_n18 = 8'b10001011; // alpha^(-18) = alpha^(237)
    localparam m8_alpha_n19 = 8'b11001011; // alpha^(-19) = alpha^(236)
    localparam m8_alpha_n20 = 8'b11101011; // alpha^(-20) = alpha^(235)
    localparam m8_alpha_n21 = 8'b11111011; // alpha^(-21) = alpha^(234)
    localparam m8_alpha_n22 = 8'b11110011; // alpha^(-22) = alpha^(233)
    localparam m8_alpha_n23 = 8'b11110111; // alpha^(-23) = alpha^(232)
    localparam m8_alpha_n24 = 8'b11110101; // alpha^(-24) = alpha^(231)
    localparam m8_alpha_n25 = 8'b11110100; // alpha^(-25) = alpha^(230)
    localparam m8_alpha_n26 = 8'b01111010; // alpha^(-26) = alpha^(229)
    localparam m8_alpha_n27 = 8'b00111101; // alpha^(-27) = alpha^(228)
    localparam m8_alpha_n28 = 8'b10010000; // alpha^(-28) = alpha^(227)
    localparam m8_alpha_n29 = 8'b01001000; // alpha^(-29) = alpha^(226)
    localparam m8_alpha_n30 = 8'b00100100; // alpha^(-30) = alpha^(225)
    localparam m8_alpha_n31 = 8'b00010010; // alpha^(-31) = alpha^(224)
    localparam m8_alpha_n32 = 8'b00001001; // alpha^(-32) = alpha^(223)
    localparam m8_alpha_n33 = 8'b10001010; // alpha^(-33) = alpha^(222)
    localparam m8_alpha_n34 = 8'b01000101; // alpha^(-34) = alpha^(221)
    localparam m8_alpha_n35 = 8'b10101100; // alpha^(-35) = alpha^(220)
    localparam m8_alpha_n36 = 8'b01010110; // alpha^(-36) = alpha^(219)
    localparam m8_alpha_n37 = 8'b00101011; // alpha^(-37) = alpha^(218)
    localparam m8_alpha_n38 = 8'b10011011; // alpha^(-38) = alpha^(217)
    localparam m8_alpha_n39 = 8'b11000011; // alpha^(-39) = alpha^(216)
    localparam m8_alpha_n40 = 8'b11101111; // alpha^(-40) = alpha^(215)
    localparam m8_alpha_n41 = 8'b11111001; // alpha^(-41) = alpha^(214)
    localparam m8_alpha_n42 = 8'b11110010; // alpha^(-42) = alpha^(213)
    localparam m8_alpha_n43 = 8'b01111001; // alpha^(-43) = alpha^(212)
    localparam m8_alpha_n44 = 8'b10110010; // alpha^(-44) = alpha^(211)
    localparam m8_alpha_n45 = 8'b01011001; // alpha^(-45) = alpha^(210)

    localparam m10_alpha_n0 = 10'b0000000001; // alpha^(0) = 1 = alpha^0
    localparam m10_alpha_n1 = 10'b1000000100; // alpha^(-1) = alpha^1022
    localparam m10_alpha_n2 = 10'b0100000010; // alpha^(-2) = alpha^1021
    localparam m10_alpha_n3 = 10'b0010000001; // alpha^(-3) = alpha^1020
    localparam m10_alpha_n4 = 10'b1001000100; // alpha^(-4) = alpha^1019
    localparam m10_alpha_n5 = 10'b0100100010; // alpha^(-5) = alpha^1018
    localparam m10_alpha_n6 = 10'b0010010001; // alpha^(-6) = alpha^1017
    localparam m10_alpha_n7 = 10'b1001001100; // alpha^(-7) = alpha^1016
    localparam m10_alpha_n8 = 10'b0100100110; // alpha^(-8) = alpha^1015
    localparam m10_alpha_n9 = 10'b0010010011; // alpha^(-9) = alpha^1014
    localparam m10_alpha_n10 = 10'b1001001101; // alpha^(-10) = alpha^1013
    localparam m10_alpha_n11 = 10'b1100100010; // alpha^(-11) = alpha^1012
    localparam m10_alpha_n12 = 10'b0110010001; // alpha^(-12) = alpha^1011
    localparam m10_alpha_n13 = 10'b1011001100; // alpha^(-13) = alpha^1010
    localparam m10_alpha_n14 = 10'b0101100110; // alpha^(-14) = alpha^1009
    localparam m10_alpha_n15 = 10'b0010110011; // alpha^(-15) = alpha^1008
    localparam m10_alpha_n16 = 10'b1001011101; // alpha^(-16) = alpha^1007
    localparam m10_alpha_n17 = 10'b1100101010; // alpha^(-17) = alpha^1006
    localparam m10_alpha_n18 = 10'b0110010101; // alpha^(-18) = alpha^1005
    localparam m10_alpha_n19 = 10'b1011001110; // alpha^(-19) = alpha^1004
    localparam m10_alpha_n20 = 10'b0101100111; // alpha^(-20) = alpha^1003
    localparam m10_alpha_n21 = 10'b1010110111; // alpha^(-21) = alpha^1002
    localparam m10_alpha_n22 = 10'b1101011111; // alpha^(-22) = alpha^1001
    localparam m10_alpha_n23 = 10'b1110101011; // alpha^(-23) = alpha^1000
    localparam m10_alpha_n24 = 10'b1111010001; // alpha^(-24) = alpha^999
    localparam m10_alpha_n25 = 10'b1111101100; // alpha^(-25) = alpha^998
    localparam m10_alpha_n26 = 10'b0111110110; // alpha^(-26) = alpha^997
    localparam m10_alpha_n27 = 10'b0011111011; // alpha^(-27) = alpha^996
    localparam m10_alpha_n28 = 10'b1001111001; // alpha^(-28) = alpha^995
    localparam m10_alpha_n29 = 10'b1100111000; // alpha^(-29) = alpha^994
    localparam m10_alpha_n30 = 10'b0110011100; // alpha^(-30) = alpha^993
    localparam m10_alpha_n31 = 10'b0011001110; // alpha^(-31) = alpha^992
    localparam m10_alpha_n32 = 10'b0001100111; // alpha^(-32) = alpha^991
    localparam m10_alpha_n33 = 10'b1000110111; // alpha^(-33) = alpha^990
    localparam m10_alpha_n34 = 10'b1100011111; // alpha^(-34) = alpha^989
    localparam m10_alpha_n35 = 10'b1110001011; // alpha^(-35) = alpha^988
    localparam m10_alpha_n36 = 10'b1111000001; // alpha^(-36) = alpha^987
    localparam m10_alpha_n37 = 10'b1111100100; // alpha^(-37) = alpha^986
    localparam m10_alpha_n38 = 10'b0111110010; // alpha^(-38) = alpha^985
    localparam m10_alpha_n39 = 10'b0011111001; // alpha^(-39) = alpha^984
    localparam m10_alpha_n40 = 10'b1001111000; // alpha^(-40) = alpha^983
    localparam m10_alpha_n41 = 10'b0100111100; // alpha^(-41) = alpha^982
    localparam m10_alpha_n42 = 10'b0010011110; // alpha^(-42) = alpha^981
    localparam m10_alpha_n43 = 10'b0001001111; // alpha^(-43) = alpha^980
    localparam m10_alpha_n44 = 10'b1000100011; // alpha^(-44) = alpha^979
    localparam m10_alpha_n45 = 10'b1100010101; // alpha^(-45) = alpha^978
    localparam m10_alpha_n46 = 10'b1110001110; // alpha^(-46) = alpha^977
    localparam m10_alpha_n47 = 10'b0111000111; // alpha^(-47) = alpha^976
    localparam m10_alpha_n48 = 10'b1011100111; // alpha^(-48) = alpha^975
    localparam m10_alpha_n49 = 10'b1101110111; // alpha^(-49) = alpha^974
    localparam m10_alpha_n50 = 10'b1110111111; // alpha^(-50) = alpha^973
    localparam m10_alpha_n51 = 10'b1111011011; // alpha^(-51) = alpha^972
    localparam m10_alpha_n52 = 10'b1111101001; // alpha^(-52) = alpha^971
    localparam m10_alpha_n53 = 10'b1111110000; // alpha^(-53) = alpha^970
    localparam m10_alpha_n54 = 10'b0111111000; // alpha^(-54) = alpha^969
    localparam m10_alpha_n55 = 10'b0011111100; // alpha^(-55) = alpha^968
    localparam m10_alpha_n56 = 10'b0001111110; // alpha^(-56) = alpha^967
    localparam m10_alpha_n57 = 10'b0000111111; // alpha^(-57) = alpha^966
    localparam m10_alpha_n58 = 10'b1000011011; // alpha^(-58) = alpha^965
    localparam m10_alpha_n59 = 10'b1100001001; // alpha^(-59) = alpha^964
    localparam m10_alpha_n60 = 10'b1110000000; // alpha^(-60) = alpha^963
    localparam m10_alpha_n61 = 10'b0111000000; // alpha^(-61) = alpha^962
    localparam m10_alpha_n62 = 10'b0011100000; // alpha^(-62) = alpha^961
    localparam m10_alpha_n63 = 10'b0001110000; // alpha^(-63) = alpha^960
    localparam m10_alpha_n64 = 10'b0000111000; // alpha^(-64) = alpha^959
    localparam m10_alpha_n65 = 10'b0000011100; // alpha^(-65) = alpha^958
    localparam m10_alpha_n66 = 10'b0000001110; // alpha^(-66) = alpha^957
    localparam m10_alpha_n67 = 10'b0000000111; // alpha^(-67) = alpha^956
    localparam m10_alpha_n68 = 10'b1000000111; // alpha^(-68) = alpha^955
    localparam m10_alpha_n69 = 10'b1100000111; // alpha^(-69) = alpha^954
    localparam m10_alpha_n70 = 10'b1110000111; // alpha^(-70) = alpha^953
    localparam m10_alpha_n71 = 10'b1111000111; // alpha^(-71) = alpha^952
    localparam m10_alpha_n72 = 10'b1111100111; // alpha^(-72) = alpha^951
    localparam m10_alpha_n73 = 10'b1111110111; // alpha^(-73) = alpha^950
    localparam m10_alpha_n74 = 10'b1111111111; // alpha^(-74) = alpha^949
    localparam m10_alpha_n75 = 10'b1111111011; // alpha^(-75) = alpha^948
    localparam m10_alpha_n76 = 10'b1111111001; // alpha^(-76) = alpha^947
    localparam m10_alpha_n77 = 10'b1111111000; // alpha^(-77) = alpha^946
    localparam m10_alpha_n78 = 10'b0111111100; // alpha^(-78) = alpha^945
    localparam m10_alpha_n79 = 10'b0011111110; // alpha^(-79) = alpha^944
    localparam m10_alpha_n80 = 10'b0001111111; // alpha^(-80) = alpha^943
    localparam m10_alpha_n81 = 10'b1000111011; // alpha^(-81) = alpha^942
    localparam m10_alpha_n82 = 10'b1100011001; // alpha^(-82) = alpha^941
    localparam m10_alpha_n83 = 10'b1110001000; // alpha^(-83) = alpha^940
    localparam m10_alpha_n84 = 10'b0111000100; // alpha^(-84) = alpha^939
    localparam m10_alpha_n85 = 10'b0011100010; // alpha^(-85) = alpha^938
    localparam m10_alpha_n86 = 10'b0001110001; // alpha^(-86) = alpha^937
    localparam m10_alpha_n87 = 10'b1000111100; // alpha^(-87) = alpha^936
    localparam m10_alpha_n88 = 10'b0100011110; // alpha^(-88) = alpha^935
    localparam m10_alpha_n89 = 10'b0010001111; // alpha^(-89) = alpha^934
    localparam m10_alpha_n90 = 10'b1001000011; // alpha^(-90) = alpha^933
    localparam m10_alpha_n91 = 10'b1100100101; // alpha^(-91) = alpha^932
    localparam m10_alpha_n92 = 10'b1110010110; // alpha^(-92) = alpha^931
    localparam m10_alpha_n93 = 10'b0111001011; // alpha^(-93) = alpha^930
    localparam m10_alpha_n94 = 10'b1011100001; // alpha^(-94) = alpha^929
    localparam m10_alpha_n95 = 10'b1101110100; // alpha^(-95) = alpha^928
    localparam m10_alpha_n96 = 10'b0110111010; // alpha^(-96) = alpha^927
    localparam m10_alpha_n97 = 10'b0011011101; // alpha^(-97) = alpha^926
    localparam m10_alpha_n98 = 10'b1001101010; // alpha^(-98) = alpha^925
    localparam m10_alpha_n99 = 10'b0100110101; // alpha^(-99) = alpha^924
    localparam m10_alpha_n100 = 10'b1010011110; // alpha^(-100) = alpha^923
    localparam m10_alpha_n101 = 10'b0101001111; // alpha^(-101) = alpha^922
    localparam m10_alpha_n102 = 10'b1010100011; // alpha^(-102) = alpha^921
    localparam m10_alpha_n103 = 10'b1101010101; // alpha^(-103) = alpha^920
    localparam m10_alpha_n104 = 10'b1110101110; // alpha^(-104) = alpha^919
    localparam m10_alpha_n105 = 10'b0111010111; // alpha^(-105) = alpha^918

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
        if (i_clear_and_wen) begin
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

            S5_poly_power_next[0] = m10_alpha_n40;
            S5_poly_power_next[1] = m10_alpha_n45;
            S5_poly_power_next[2] = m10_alpha_n50;
            S5_poly_power_next[3] = m10_alpha_n55;
            S5_poly_power_next[4] = m10_alpha_n60;
            S5_poly_power_next[5] = m10_alpha_n65;
            S5_poly_power_next[6] = m10_alpha_n70;
            S5_poly_power_next[7] = m10_alpha_n75;


            S7_poly_power_next[0] = m10_alpha_n56;
            S7_poly_power_next[1] = m10_alpha_n63;
            S7_poly_power_next[2] = m10_alpha_n70;
            S7_poly_power_next[3] = m10_alpha_n77;
            S7_poly_power_next[4] = m10_alpha_n84;
            S7_poly_power_next[5] = m10_alpha_n91;
            S7_poly_power_next[6] = m10_alpha_n98;
            S7_poly_power_next[7] = m10_alpha_n105;

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
        if (i_clear_and_wen) begin
            case(i_code) // synopsys full_case
                2'b00: begin
                    S1_poly_power_next[0] = m6_alpha_n8;
                    S1_poly_power_next[1] = m6_alpha_n9;
                    S1_poly_power_next[2] = m6_alpha_n10;
                    S1_poly_power_next[3] = m6_alpha_n11;
                    S1_poly_power_next[4] = m6_alpha_n12;
                    S1_poly_power_next[5] = m6_alpha_n13;
                    S1_poly_power_next[6] = m6_alpha_n14;
                    S1_poly_power_next[7] = m6_alpha_n15;

                    S3_poly_power_next[0] = m6_alpha_n24;
                    S3_poly_power_next[1] = m6_alpha_n27;
                    S3_poly_power_next[2] = m6_alpha_n30;
                    S3_poly_power_next[3] = m6_alpha_n33;
                    S3_poly_power_next[4] = m6_alpha_n36;
                    S3_poly_power_next[5] = m6_alpha_n39;
                    S3_poly_power_next[6] = m6_alpha_n42;
                    S3_poly_power_next[7] = m6_alpha_n45;      

                    S1_factor_next = m6_alpha_n8;  
                    S3_factor_next = m6_alpha_n24;
                end
                2'b01: begin
                    S1_poly_power_next[0] = m8_alpha_n8;
                    S1_poly_power_next[1] = m8_alpha_n9;
                    S1_poly_power_next[2] = m8_alpha_n10;
                    S1_poly_power_next[3] = m8_alpha_n11;
                    S1_poly_power_next[4] = m8_alpha_n12;
                    S1_poly_power_next[5] = m8_alpha_n13;
                    S1_poly_power_next[6] = m8_alpha_n14;
                    S1_poly_power_next[7] = m8_alpha_n15;

                    S3_poly_power_next[0] = m8_alpha_n24;
                    S3_poly_power_next[1] = m8_alpha_n27;
                    S3_poly_power_next[2] = m8_alpha_n30;
                    S3_poly_power_next[3] = m8_alpha_n33;
                    S3_poly_power_next[4] = m8_alpha_n36;
                    S3_poly_power_next[5] = m8_alpha_n39;
                    S3_poly_power_next[6] = m8_alpha_n42;
                    S3_poly_power_next[7] = m8_alpha_n45;

                    S1_factor_next = m8_alpha_n8;
                    S3_factor_next = m8_alpha_n24;
                end
                2'b10: begin
                    S1_poly_power_next[0] = m10_alpha_n8;
                    S1_poly_power_next[1] = m10_alpha_n9;
                    S1_poly_power_next[2] = m10_alpha_n10;
                    S1_poly_power_next[3] = m10_alpha_n11;
                    S1_poly_power_next[4] = m10_alpha_n12;
                    S1_poly_power_next[5] = m10_alpha_n13;
                    S1_poly_power_next[6] = m10_alpha_n14;
                    S1_poly_power_next[7] = m10_alpha_n15;

                    S3_poly_power_next[0] = m10_alpha_n24;
                    S3_poly_power_next[1] = m10_alpha_n27;
                    S3_poly_power_next[2] = m10_alpha_n30;
                    S3_poly_power_next[3] = m10_alpha_n33;
                    S3_poly_power_next[4] = m10_alpha_n36;
                    S3_poly_power_next[5] = m10_alpha_n39;
                    S3_poly_power_next[6] = m10_alpha_n42;
                    S3_poly_power_next[7] = m10_alpha_n45;

                    S5_poly_power_next[0] = m10_alpha_n40;
                    S5_poly_power_next[1] = m10_alpha_n45;
                    S5_poly_power_next[2] = m10_alpha_n50;
                    S5_poly_power_next[3] = m10_alpha_n55;
                    S5_poly_power_next[4] = m10_alpha_n60;
                    S5_poly_power_next[5] = m10_alpha_n65;
                    S5_poly_power_next[6] = m10_alpha_n70;
                    S5_poly_power_next[7] = m10_alpha_n75;


                    S7_poly_power_next[0] = m10_alpha_n56;
                    S7_poly_power_next[1] = m10_alpha_n63;
                    S7_poly_power_next[2] = m10_alpha_n70;
                    S7_poly_power_next[3] = m10_alpha_n77;
                    S7_poly_power_next[4] = m10_alpha_n84;
                    S7_poly_power_next[5] = m10_alpha_n91;
                    S7_poly_power_next[6] = m10_alpha_n98;
                    S7_poly_power_next[7] = m10_alpha_n105;


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
        if (i_clear_and_wen) begin
            case(i_code) // synopsys full_case
                2'b00: begin
                    S1_next = (m6_alpha_n0 & {10{i_data[7]}}) ^
                              (m6_alpha_n1 & {10{i_data[6]}}) ^
                              (m6_alpha_n2 & {10{i_data[5]}}) ^
                              (m6_alpha_n3 & {10{i_data[4]}}) ^
                              (m6_alpha_n4 & {10{i_data[3]}}) ^
                              (m6_alpha_n5 & {10{i_data[2]}}) ^
                              (m6_alpha_n6 & {10{i_data[1]}}) ^
                              (m6_alpha_n7 & {10{i_data[0]}});
                    S3_next =   (m6_alpha_n0 & {10{i_data[7]}}) ^
                                (m6_alpha_n3 & {10{i_data[6]}}) ^
                                (m6_alpha_n6 & {10{i_data[5]}}) ^
                                (m6_alpha_n9 & {10{i_data[4]}}) ^
                                (m6_alpha_n12 & {10{i_data[3]}}) ^
                                (m6_alpha_n15 & {10{i_data[2]}}) ^
                                (m6_alpha_n18 & {10{i_data[1]}}) ^
                                (m6_alpha_n21 & {10{i_data[0]}});
                    S5_next = S5;
                    S7_next = S7;
                end
                2'b01: begin
                    S1_next = (m8_alpha_n0 & {10{i_data[7]}}) ^
                              (m8_alpha_n1 & {10{i_data[6]}}) ^
                              (m8_alpha_n2 & {10{i_data[5]}}) ^
                              (m8_alpha_n3 & {10{i_data[4]}}) ^
                              (m8_alpha_n4 & {10{i_data[3]}}) ^
                              (m8_alpha_n5 & {10{i_data[2]}}) ^
                              (m8_alpha_n6 & {10{i_data[1]}}) ^
                              (m8_alpha_n7 & {10{i_data[0]}});
                    S3_next = (m8_alpha_n0 & {10{i_data[7]}}) ^
                              (m8_alpha_n3 & {10{i_data[6]}}) ^
                              (m8_alpha_n6 & {10{i_data[5]}}) ^
                              (m8_alpha_n9 & {10{i_data[4]}}) ^
                              (m8_alpha_n12 & {10{i_data[3]}}) ^
                              (m8_alpha_n15 & {10{i_data[2]}}) ^
                              (m8_alpha_n18 & {10{i_data[1]}}) ^
                              (m8_alpha_n21 & {10{i_data[0]}});
                    S5_next = S5;
                    S7_next = S7;
                end
                2'b10: begin
                    S1_next = (m10_alpha_n0 & {10{i_data[7]}}) ^
                              (m10_alpha_n1 & {10{i_data[6]}}) ^
                              (m10_alpha_n2 & {10{i_data[5]}}) ^
                              (m10_alpha_n3 & {10{i_data[4]}}) ^
                              (m10_alpha_n4 & {10{i_data[3]}}) ^
                              (m10_alpha_n5 & {10{i_data[2]}}) ^
                              (m10_alpha_n6 & {10{i_data[1]}}) ^
                              (m10_alpha_n7 & {10{i_data[0]}});
                    S3_next = (m10_alpha_n0 & {10{i_data[7]}}) ^
                              (m10_alpha_n3 & {10{i_data[6]}}) ^
                              (m10_alpha_n6 & {10{i_data[5]}}) ^
                              (m10_alpha_n9 & {10{i_data[4]}}) ^
                              (m10_alpha_n12 & {10{i_data[3]}}) ^
                              (m10_alpha_n15 & {10{i_data[2]}}) ^
                              (m10_alpha_n18 & {10{i_data[1]}}) ^
                              (m10_alpha_n21 & {10{i_data[0]}});
                    S5_next = (m10_alpha_n0 & {10{i_data[7]}}) ^
                              (m10_alpha_n5 & {10{i_data[6]}}) ^
                              (m10_alpha_n10 & {10{i_data[5]}}) ^
                              (m10_alpha_n15 & {10{i_data[4]}}) ^
                              (m10_alpha_n20 & {10{i_data[3]}}) ^
                              (m10_alpha_n25 & {10{i_data[2]}}) ^
                              (m10_alpha_n30 & {10{i_data[1]}}) ^
                              (m10_alpha_n35 & {10{i_data[0]}});
                    S7_next = (m10_alpha_n0 & {10{i_data[7]}}) ^
                              (m10_alpha_n7 & {10{i_data[6]}}) ^
                              (m10_alpha_n14 & {10{i_data[5]}}) ^
                              (m10_alpha_n21 & {10{i_data[4]}}) ^
                              (m10_alpha_n28 & {10{i_data[3]}}) ^
                              (m10_alpha_n35 & {10{i_data[2]}}) ^
                              (m10_alpha_n42 & {10{i_data[1]}}) ^
                              (m10_alpha_n49 & {10{i_data[0]}});
                end

            endcase
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