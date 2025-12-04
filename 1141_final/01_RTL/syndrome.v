module syndrome(
    input i_clk,
    input i_rst_n, // synchronous reset, active low

    input i_mode,
    input [1:0] i_code, // 00: bch (63,51), 01: bch (255, 239), 10: bch (1023, 983)
    input i_clear_and_wen,
    input i_wen,

    input [63:0] i_data,

    output [9:0] o_S1,
    output [9:0] o_S2,
    output [9:0] o_S3,
    output [9:0] o_S4,
    output [9:0] o_S5,
    output [9:0] o_S6,
    output [9:0] o_S7,
    output [9:0] o_S8,

    output reg o_odd_s_valid,
    output reg o_all_s_valid,


    output [9:0] o_flip_alpha_S1_1,
    output [9:0] o_flip_alpha_S1_2,
    output [9:0] o_flip_alpha_S3_1,
    output [9:0] o_flip_alpha_S3_2,
    output [9:0] o_flip_alpha_S5_1,
    output [9:0] o_flip_alpha_S5_2,
    output [9:0] o_flip_alpha_S7_1,
    output [9:0] o_flip_alpha_S7_2,

    output [9:0] o_flip_pos1,
    output [9:0] o_flip_pos2,

    output [6:0] o_flip_llr1,
    output [6:0] o_flip_llr2,

    output o_flip_valid
);
    localparam m6_alpha_n0  = 10'b0000000001; // alpha^(0)  = 1
    localparam m6_alpha_n1  = 10'b0000100001; // alpha^(-1)  = alpha^(62)
    localparam m6_alpha_n2  = 10'b0000110001; // alpha^(-2)  = alpha^(61)
    localparam m6_alpha_n3  = 10'b0000111001; // alpha^(-3)  = alpha^(60)
    localparam m6_alpha_n4  = 10'b0000111101; // alpha^(-4)  = alpha^(59)
    localparam m6_alpha_n5  = 10'b0000111111; // alpha^(-5)  = alpha^(58)
    localparam m6_alpha_n6  = 10'b0000111110; // alpha^(-6)  = alpha^(57)
    localparam m6_alpha_n7  = 10'b0000011111; // alpha^(-7)  = alpha^(56)
    localparam m6_alpha_n8  = 10'b0000101110; // alpha^(-8)  = alpha^(55)
    localparam m6_alpha_n9  = 10'b0000010111; // alpha^(-9)  = alpha^(54)
    localparam m6_alpha_n10 = 10'b0000101010; // alpha^(-10) = alpha^(53)
    localparam m6_alpha_n11 = 10'b0000010101; // alpha^(-11) = alpha^(52)
    localparam m6_alpha_n12 = 10'b0000101011; // alpha^(-12) = alpha^(51)
    localparam m6_alpha_n13 = 10'b0000110100; // alpha^(-13) = alpha^(50)
    localparam m6_alpha_n14 = 10'b0000011010; // alpha^(-14) = alpha^(49)
    localparam m6_alpha_n15 = 10'b0000001101; // alpha^(-15) = alpha^(48)
    localparam m6_alpha_n16 = 10'b0000100111; // alpha^(-16) = alpha^(47)
    localparam m6_alpha_n17 = 10'b0000110010; // alpha^(-17) = alpha^(46)
    localparam m6_alpha_n18 = 10'b0000011001; // alpha^(-18) = alpha^(45)
    localparam m6_alpha_n19 = 10'b0000101101; // alpha^(-19) = alpha^(44)
    localparam m6_alpha_n20 = 10'b0000110111; // alpha^(-20) = alpha^(43)
    localparam m6_alpha_n21 = 10'b0000111010; // alpha^(-21) = alpha^(42)
    localparam m6_alpha_n22 = 10'b0000011101; // alpha^(-22) = alpha^(41)
    localparam m6_alpha_n23 = 10'b0000101111; // alpha^(-23) = alpha^(40)
    localparam m6_alpha_n24 = 10'b0000110110; // alpha^(-24) = alpha^(39)
    localparam m6_alpha_n25 = 10'b0000011011; // alpha^(-25) = alpha^(38)
    localparam m6_alpha_n26 = 10'b0000101100; // alpha^(-26) = alpha^(37)
    localparam m6_alpha_n27 = 10'b0000010110; // alpha^(-27) = alpha^(36)
    localparam m6_alpha_n28 = 10'b0000001011; // alpha^(-28) = alpha^(35)
    localparam m6_alpha_n29 = 10'b0000100100; // alpha^(-29) = alpha^(34)
    localparam m6_alpha_n30 = 10'b0000010010; // alpha^(-30) = alpha^(33)
    localparam m6_alpha_n31 = 10'b0000001001; // alpha^(-31) = alpha^(32)
    localparam m6_alpha_n32 = 10'b0000100101; // alpha^(-32) = alpha^(31)
    localparam m6_alpha_n33 = 10'b0000110011; // alpha^(-33) = alpha^(30)
    localparam m6_alpha_n34 = 10'b0000111000; // alpha^(-34) = alpha^(29)
    localparam m6_alpha_n35 = 10'b0000011100; // alpha^(-35) = alpha^(28)
    localparam m6_alpha_n36 = 10'b0000001110; // alpha^(-36) = alpha^(27)
    localparam m6_alpha_n37 = 10'b0000000111; // alpha^(-37) = alpha^(26)
    localparam m6_alpha_n38 = 10'b0000100010; // alpha^(-38) = alpha^(25)
    localparam m6_alpha_n39 = 10'b0000010001; // alpha^(-39) = alpha^(24)
    localparam m6_alpha_n40 = 10'b0000101001; // alpha^(-40) = alpha^(23)
    localparam m6_alpha_n41 = 10'b0000110101; // alpha^(-41) = alpha^(22)
    localparam m6_alpha_n42 = 10'b0000111011; // alpha^(-42) = alpha^(21)
    localparam m6_alpha_n43 = 10'b0000111100; // alpha^(-43) = alpha^(20)
    localparam m6_alpha_n44 = 10'b0000011110; // alpha^(-44) = alpha^(19)
    localparam m6_alpha_n45 = 10'b0000001111; // alpha^(-45) = alpha^(18)

    localparam m8_alpha_n0 = 10'b0000000001; // alpha^(0) = 1
    localparam m8_alpha_n1 = 10'b0010001110; // alpha^(-1) = alpha^(254)
    localparam m8_alpha_n2 = 10'b0001000111; // alpha^(-2) = alpha^(253)
    localparam m8_alpha_n3 = 10'b0010101101; // alpha^(-3) = alpha^(252)
    localparam m8_alpha_n4 = 10'b0011011000; // alpha^(-4) = alpha^(251)
    localparam m8_alpha_n5 = 10'b0001101100; // alpha^(-5) = alpha^(250)
    localparam m8_alpha_n6 = 10'b0000110110; // alpha^(-6) = alpha^(249)
    localparam m8_alpha_n7 = 10'b0000011011; // alpha^(-7) = alpha^(248)
    localparam m8_alpha_n8 = 10'b0010000011; // alpha^(-8) = alpha^(247)
    localparam m8_alpha_n9 = 10'b0011001111; // alpha^(-9) = alpha^(246)
    localparam m8_alpha_n10 = 10'b0011101001; // alpha^(-10) = alpha^(245)
    localparam m8_alpha_n11 = 10'b0011111010; // alpha^(-11) = alpha^(244)
    localparam m8_alpha_n12 = 10'b0001111101; // alpha^(-12) = alpha^(243)
    localparam m8_alpha_n13 = 10'b0010110000; // alpha^(-13) = alpha^(242)
    localparam m8_alpha_n14 = 10'b0001011000; // alpha^(-14) = alpha^(241)
    localparam m8_alpha_n15 = 10'b0000101100; // alpha^(-15) = alpha^(240)
    localparam m8_alpha_n16 = 10'b0000001011; // alpha^(-16) = alpha^(239)
    localparam m8_alpha_n17 = 10'b0010001011; // alpha^(-17) = alpha^(238)
    localparam m8_alpha_n18 = 10'b0010001011; // alpha^(-18) = alpha^(237)
    localparam m8_alpha_n19 = 10'b0011001011; // alpha^(-19) = alpha^(236)
    localparam m8_alpha_n20 = 10'b0011101011; // alpha^(-20) = alpha^(235)
    localparam m8_alpha_n21 = 10'b0011111011; // alpha^(-21) = alpha^(234)
    localparam m8_alpha_n22 = 10'b0011110011; // alpha^(-22) = alpha^(233)
    localparam m8_alpha_n23 = 10'b0011110111; // alpha^(-23) = alpha^(232)
    localparam m8_alpha_n24 = 10'b0011110101; // alpha^(-24) = alpha^(231)
    localparam m8_alpha_n25 = 10'b0011110100; // alpha^(-25) = alpha^(230)
    localparam m8_alpha_n26 = 10'b0001111010; // alpha^(-26) = alpha^(229)
    localparam m8_alpha_n27 = 10'b0000111101; // alpha^(-27) = alpha^(228)
    localparam m8_alpha_n28 = 10'b0010010000; // alpha^(-28) = alpha^(227)
    localparam m8_alpha_n29 = 10'b0001001000; // alpha^(-29) = alpha^(226)
    localparam m8_alpha_n30 = 10'b0000100100; // alpha^(-30) = alpha^(225)
    localparam m8_alpha_n31 = 10'b0000010010; // alpha^(-31) = alpha^(224)
    localparam m8_alpha_n32 = 10'b0000001001; // alpha^(-32) = alpha^(223)
    localparam m8_alpha_n33 = 10'b0010001010; // alpha^(-33) = alpha^(222)
    localparam m8_alpha_n34 = 10'b0001000101; // alpha^(-34) = alpha^(221)
    localparam m8_alpha_n35 = 10'b0010101100; // alpha^(-35) = alpha^(220)
    localparam m8_alpha_n36 = 10'b0001010110; // alpha^(-36) = alpha^(219)
    localparam m8_alpha_n37 = 10'b0000101011; // alpha^(-37) = alpha^(218)
    localparam m8_alpha_n38 = 10'b0010011011; // alpha^(-38) = alpha^(217)
    localparam m8_alpha_n39 = 10'b0011000011; // alpha^(-39) = alpha^(216)
    localparam m8_alpha_n40 = 10'b0011101111; // alpha^(-40) = alpha^(215)
    localparam m8_alpha_n41 = 10'b0011111001; // alpha^(-41) = alpha^(214)
    localparam m8_alpha_n42 = 10'b0011110010; // alpha^(-42) = alpha^(213)
    localparam m8_alpha_n43 = 10'b0001111001; // alpha^(-43) = alpha^(212)
    localparam m8_alpha_n44 = 10'b0010110010; // alpha^(-44) = alpha^(211)
    localparam m8_alpha_n45 = 10'b0001011001; // alpha^(-45) = alpha^(210)

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

    wire [7:0] rx_bit;
    wire [7:0] rx_bit_dly;

    wire clear_and_wen_dly;
    wire wen_dly;


    assign rx_bit = {i_data[63], i_data[55], i_data[47], i_data[39], i_data[31], i_data[23], i_data[15], i_data[7]};

    integer i;

    delay_n #(
        .N(1),
        .BITS(8),
        .INIT(8'b0)
    ) u_delay_n_rx_bit (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(rx_bit),
        .o_q(rx_bit_dly)
    );

    delay_n #(
        .N(1),
        .BITS(1),
        .INIT(1'b0)
    ) u_delay_n_clear_and_wen (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(i_clear_and_wen),
        .o_q(clear_and_wen_dly)
    );

    delay_n #(
        .N(1),
        .BITS(1),
        .INIT(1'b0)
    ) u_delay_n_wen (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(i_wen),
        .o_q(wen_dly)
    );


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

    // gf_mult u_gf_mult_S2 (
    //     .i_a(S1),
    //     .i_b(S1),
    //     .i_code(i_code),
    //     .o_product(S2_next)
    // );

    // gf_mult u_gf_mult_S4 (
    //     .i_a(S2_next),
    //     .i_b(S2_next),
    //     .i_code(i_code),
    //     .o_product(S4_next)
    // );

    // gf_mult u_gf_mult_S6 (
    //     .i_a(S3),
    //     .i_b(S3),
    //     .i_code(2'b10),
    //     .o_product(S6_next)
    // );

    // gf_mult u_gf_mult_S8 (
    //     .i_a(S4_next),
    //     .i_b(S4_next),
    //     .i_code(2'b10),
    //     .o_product(S8_next)
    // );


    gf_square u_gf_square_S2 (
        .i_in(S1),
        .i_code(i_code),
        .o_out(S2_next)
    );

    gf_square u_gf_square_S4 (
        .i_in(S2_next),
        .i_code(i_code),
        .o_out(S4_next)
    );

    gf_square u_gf_square_S6 (
        .i_in(S3),
        .i_code(2'b10),
        .o_out(S6_next)
    );

    gf_square u_gf_square_S8 (
        .i_in(S4_next),
        .i_code(2'b10),
        .o_out(S8_next)
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
        if (clear_and_wen_dly) begin
            counter_next = 8'b0;
        end
        else if (counter == 8'd131) begin
            counter_next = counter;
        end
        else if (wen_dly || counter >= 8'd7) begin
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
                o_odd_s_valid = counter >= 8'd7 && !clear_and_wen_dly;
                o_all_s_valid = counter >= 8'd8 && !clear_and_wen_dly;
            end
            2'b01: begin
                o_odd_s_valid = counter >= 8'd31 && !clear_and_wen_dly;
                o_all_s_valid = counter >= 8'd32 && !clear_and_wen_dly;
            end
            2'b10: begin
                o_odd_s_valid = counter >= 8'd127 && !clear_and_wen_dly;
                o_all_s_valid = counter >= 8'd128 && !clear_and_wen_dly;
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

            S5_poly_power[0] <= 10'd0;
            S5_poly_power[1] <= 10'd0;
            S5_poly_power[2] <= 10'd0;
            S5_poly_power[3] <= 10'd0;;
            S5_poly_power[4] <= 10'd0;;
            S5_poly_power[5] <= 10'd0;;
            S5_poly_power[6] <= 10'd0;;
            S5_poly_power[7] <= 10'd0;;


            S7_poly_power[0] <= 10'd0;;
            S7_poly_power[1] <= 10'd0;;
            S7_poly_power[2] <= 10'd0;;
            S7_poly_power[3] <= 10'd0;;
            S7_poly_power[4] <= 10'd0;;
            S7_poly_power[5] <= 10'd0;;
            S7_poly_power[6] <= 10'd0;;
            S7_poly_power[7] <= 10'd0;;

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
        if (clear_and_wen_dly) begin
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




                    S1_factor_next = m10_alpha_n8;
                    S3_factor_next = m10_alpha_n24;
                end
            endcase

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
        end
        else begin
            S1_factor_next = S1_factor;
            S3_factor_next = S3_factor;

            for (i = 0; i < 8; i = i + 1) begin
                if (wen_dly) begin
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
        if (clear_and_wen_dly) begin
            case(i_code) // synopsys full_case
                2'b00: begin
                    S1_next = (m6_alpha_n0 & {10{rx_bit_dly[7]}}) ^
                              (m6_alpha_n1 & {10{rx_bit_dly[6]}}) ^
                              (m6_alpha_n2 & {10{rx_bit_dly[5]}}) ^
                              (m6_alpha_n3 & {10{rx_bit_dly[4]}}) ^
                              (m6_alpha_n4 & {10{rx_bit_dly[3]}}) ^
                              (m6_alpha_n5 & {10{rx_bit_dly[2]}}) ^
                              (m6_alpha_n6 & {10{rx_bit_dly[1]}}) ^
                              (m6_alpha_n7 & {10{rx_bit_dly[0]}});
                    S3_next =   (m6_alpha_n0 & {10{rx_bit_dly[7]}}) ^
                                (m6_alpha_n3 & {10{rx_bit_dly[6]}}) ^
                                (m6_alpha_n6 & {10{rx_bit_dly[5]}}) ^
                                (m6_alpha_n9 & {10{rx_bit_dly[4]}}) ^
                                (m6_alpha_n12 & {10{rx_bit_dly[3]}}) ^
                                (m6_alpha_n15 & {10{rx_bit_dly[2]}}) ^
                                (m6_alpha_n18 & {10{rx_bit_dly[1]}}) ^
                                (m6_alpha_n21 & {10{rx_bit_dly[0]}});
                    S5_next = S5;
                    S7_next = S7;
                end
                2'b01: begin
                    S1_next = (m8_alpha_n0 & {10{rx_bit_dly[7]}}) ^
                              (m8_alpha_n1 & {10{rx_bit_dly[6]}}) ^
                              (m8_alpha_n2 & {10{rx_bit_dly[5]}}) ^
                              (m8_alpha_n3 & {10{rx_bit_dly[4]}}) ^
                              (m8_alpha_n4 & {10{rx_bit_dly[3]}}) ^
                              (m8_alpha_n5 & {10{rx_bit_dly[2]}}) ^
                              (m8_alpha_n6 & {10{rx_bit_dly[1]}}) ^
                              (m8_alpha_n7 & {10{rx_bit_dly[0]}});
                    S3_next = (m8_alpha_n0 & {10{rx_bit_dly[7]}}) ^
                              (m8_alpha_n3 & {10{rx_bit_dly[6]}}) ^
                              (m8_alpha_n6 & {10{rx_bit_dly[5]}}) ^
                              (m8_alpha_n9 & {10{rx_bit_dly[4]}}) ^
                              (m8_alpha_n12 & {10{rx_bit_dly[3]}}) ^
                              (m8_alpha_n15 & {10{rx_bit_dly[2]}}) ^
                              (m8_alpha_n18 & {10{rx_bit_dly[1]}}) ^
                              (m8_alpha_n21 & {10{rx_bit_dly[0]}});
                    S5_next = S5;
                    S7_next = S7;
                end
                2'b10: begin
                    S1_next = (m10_alpha_n0 & {10{rx_bit_dly[7]}}) ^
                              (m10_alpha_n1 & {10{rx_bit_dly[6]}}) ^
                              (m10_alpha_n2 & {10{rx_bit_dly[5]}}) ^
                              (m10_alpha_n3 & {10{rx_bit_dly[4]}}) ^
                              (m10_alpha_n4 & {10{rx_bit_dly[3]}}) ^
                              (m10_alpha_n5 & {10{rx_bit_dly[2]}}) ^
                              (m10_alpha_n6 & {10{rx_bit_dly[1]}}) ^
                              (m10_alpha_n7 & {10{rx_bit_dly[0]}});
                    S3_next = (m10_alpha_n0 & {10{rx_bit_dly[7]}}) ^
                              (m10_alpha_n3 & {10{rx_bit_dly[6]}}) ^
                              (m10_alpha_n6 & {10{rx_bit_dly[5]}}) ^
                              (m10_alpha_n9 & {10{rx_bit_dly[4]}}) ^
                              (m10_alpha_n12 & {10{rx_bit_dly[3]}}) ^
                              (m10_alpha_n15 & {10{rx_bit_dly[2]}}) ^
                              (m10_alpha_n18 & {10{rx_bit_dly[1]}}) ^
                              (m10_alpha_n21 & {10{rx_bit_dly[0]}});
                    S5_next = (m10_alpha_n0 & {10{rx_bit_dly[7]}}) ^
                              (m10_alpha_n5 & {10{rx_bit_dly[6]}}) ^
                              (m10_alpha_n10 & {10{rx_bit_dly[5]}}) ^
                              (m10_alpha_n15 & {10{rx_bit_dly[4]}}) ^
                              (m10_alpha_n20 & {10{rx_bit_dly[3]}}) ^
                              (m10_alpha_n25 & {10{rx_bit_dly[2]}}) ^
                              (m10_alpha_n30 & {10{rx_bit_dly[1]}}) ^
                              (m10_alpha_n35 & {10{rx_bit_dly[0]}});
                    S7_next = (m10_alpha_n0 & {10{rx_bit_dly[7]}}) ^
                              (m10_alpha_n7 & {10{rx_bit_dly[6]}}) ^
                              (m10_alpha_n14 & {10{rx_bit_dly[5]}}) ^
                              (m10_alpha_n21 & {10{rx_bit_dly[4]}}) ^
                              (m10_alpha_n28 & {10{rx_bit_dly[3]}}) ^
                              (m10_alpha_n35 & {10{rx_bit_dly[2]}}) ^
                              (m10_alpha_n42 & {10{rx_bit_dly[1]}}) ^
                              (m10_alpha_n49 & {10{rx_bit_dly[0]}});
                end

            endcase
        end
        else if (wen_dly) begin
            S1_next = S1 ^
                      (S1_poly_power[0] & {10{rx_bit_dly[7]}}) ^
                      (S1_poly_power[1] & {10{rx_bit_dly[6]}}) ^
                      (S1_poly_power[2] & {10{rx_bit_dly[5]}}) ^
                      (S1_poly_power[3] & {10{rx_bit_dly[4]}}) ^
                      (S1_poly_power[4] & {10{rx_bit_dly[3]}}) ^
                      (S1_poly_power[5] & {10{rx_bit_dly[2]}}) ^
                      (S1_poly_power[6] & {10{rx_bit_dly[1]}}) ^
                      (S1_poly_power[7] & {10{rx_bit_dly[0]}});

            S3_next =   S3 ^
                        (S3_poly_power[0] & {10{rx_bit_dly[7]}}) ^
                        (S3_poly_power[1] & {10{rx_bit_dly[6]}}) ^
                        (S3_poly_power[2] & {10{rx_bit_dly[5]}}) ^
                        (S3_poly_power[3] & {10{rx_bit_dly[4]}}) ^
                        (S3_poly_power[4] & {10{rx_bit_dly[3]}}) ^
                        (S3_poly_power[5] & {10{rx_bit_dly[2]}}) ^
                        (S3_poly_power[6] & {10{rx_bit_dly[1]}}) ^
                        (S3_poly_power[7] & {10{rx_bit_dly[0]}});

            if (i_code == 2'b10) begin
                S5_next =   S5 ^
                            (S5_poly_power[0] & {10{rx_bit_dly[7]}}) ^
                            (S5_poly_power[1] & {10{rx_bit_dly[6]}}) ^
                            (S5_poly_power[2] & {10{rx_bit_dly[5]}}) ^
                            (S5_poly_power[3] & {10{rx_bit_dly[4]}}) ^
                            (S5_poly_power[4] & {10{rx_bit_dly[3]}}) ^
                            (S5_poly_power[5] & {10{rx_bit_dly[2]}}) ^
                            (S5_poly_power[6] & {10{rx_bit_dly[1]}}) ^
                            (S5_poly_power[7] & {10{rx_bit_dly[0]}});

                S7_next =   S7 ^
                            (S7_poly_power[0] & {10{rx_bit_dly[7]}}) ^
                            (S7_poly_power[1] & {10{rx_bit_dly[6]}}) ^
                            (S7_poly_power[2] & {10{rx_bit_dly[5]}}) ^
                            (S7_poly_power[3] & {10{rx_bit_dly[4]}}) ^
                            (S7_poly_power[4] & {10{rx_bit_dly[3]}}) ^
                            (S7_poly_power[5] & {10{rx_bit_dly[2]}}) ^
                            (S7_poly_power[6] & {10{rx_bit_dly[1]}}) ^
                            (S7_poly_power[7] & {10{rx_bit_dly[0]}});
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


    // -------------------------- flip alpha logic ------------------------------------
    wire flip_alpha_logic_gen;
    assign flip_alpha_logic_gen = i_mode;


    wire [6:0] abs_llr0;
    wire [6:0] abs_llr1;    
    wire [6:0] abs_llr2;
    wire [6:0] abs_llr3;
    wire [6:0] abs_llr4;
    wire [6:0] abs_llr5;
    wire [6:0] abs_llr6;
    wire [6:0] abs_llr7;

    reg [6:0] min_llr, min_llr_next;
    reg [6:0] second_min_llr, second_min_llr_next;

    reg [9:0] alpha_S1_min, alpha_S1_min_next;
    reg [9:0] alpha_S1_second_min, alpha_S1_second_min_next;
    reg [9:0] alpha_S3_min, alpha_S3_min_next;
    reg [9:0] alpha_S3_second_min, alpha_S3_second_min_next;
    reg [9:0] alpha_S5_min, alpha_S5_min_next;
    reg [9:0] alpha_S5_second_min, alpha_S5_second_min_next;
    reg [9:0] alpha_S7_min, alpha_S7_min_next;
    reg [9:0] alpha_S7_second_min, alpha_S7_second_min_next;

    reg [9:0] min_pos, min_pos_next;
    reg [9:0] second_min_pos, second_min_pos_next;
    reg [6:0] abs_llr_min, abs_llr_min_next;
    reg [6:0] abs_llr_second_min, abs_llr_second_min_next;

    reg [9:0] llr_pos0;
    reg [9:0] llr_pos1;
    reg [9:0] llr_pos2;
    reg [9:0] llr_pos3; 
    reg [9:0] llr_pos4;
    reg [9:0] llr_pos5;
    reg [9:0] llr_pos6;
    reg [9:0] llr_pos7;

    reg [9:0] S1_alpha0;
    reg [9:0] S1_alpha1;
    reg [9:0] S1_alpha2;
    reg [9:0] S1_alpha3;
    reg [9:0] S1_alpha4;
    reg [9:0] S1_alpha5;
    reg [9:0] S1_alpha6;
    reg [9:0] S1_alpha7;

    reg [9:0] S3_alpha0;
    reg [9:0] S3_alpha1;
    reg [9:0] S3_alpha2;
    reg [9:0] S3_alpha3;
    reg [9:0] S3_alpha4;
    reg [9:0] S3_alpha5;
    reg [9:0] S3_alpha6;
    reg [9:0] S3_alpha7;

    reg [9:0] S5_alpha0;    
    reg [9:0] S5_alpha1;
    reg [9:0] S5_alpha2;
    reg [9:0] S5_alpha3;
    reg [9:0] S5_alpha4;
    reg [9:0] S5_alpha5;
    reg [9:0] S5_alpha6;
    reg [9:0] S5_alpha7;

    reg [9:0] S7_alpha0;
    reg [9:0] S7_alpha1;
    reg [9:0] S7_alpha2;
    reg [9:0] S7_alpha3;
    reg [9:0] S7_alpha4;
    reg [9:0] S7_alpha5;
    reg [9:0] S7_alpha6;
    reg [9:0] S7_alpha7;

    wire [6:0] top_2_min;
    wire [6:0] top_2_second_min;
    wire [3:0] top_2_min_idx;
    wire [3:0] top_2_second_min_idx;

    wire [3:0] top_2_min_idx_dly;
    wire [3:0] top_2_second_min_idx_dly;

    wire [6:0] abs_llr0_dly;
    wire [6:0] abs_llr1_dly;
    wire [6:0] abs_llr2_dly;
    wire [6:0] abs_llr3_dly;
    wire [6:0] abs_llr4_dly;
    wire [6:0] abs_llr5_dly;
    wire [6:0] abs_llr6_dly;
    wire [6:0] abs_llr7_dly;

    top_2 u_top_2_llr_min (
        .i_0(abs_llr0),
        .i_1(abs_llr1),
        .i_2(abs_llr2),
        .i_3(abs_llr3),
        .i_4(abs_llr4),
        .i_5(abs_llr5),
        .i_6(abs_llr6),
        .i_7(abs_llr7),
        .i_8(i_clear_and_wen ? 7'b1111111 : min_llr),
        .i_9(i_clear_and_wen ? 7'b1111111 : second_min_llr),

        .o_0(top_2_min),
        .o_1(top_2_second_min),

        .o_0_idx(top_2_min_idx),
        .o_1_idx(top_2_second_min_idx)
    );

    

    delay_n #(
        .N(1),
        .BITS(4),
        .INIT(4'b0)
    ) u_delay_min_llr_idx (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(flip_alpha_logic_gen),
        .i_d(top_2_min_idx),
        .o_q(top_2_min_idx_dly)
    );

    delay_n #(
        .N(1),
        .BITS(4),
        .INIT(4'b0)
    ) u_delay_second_min_llr_idx (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(flip_alpha_logic_gen),
        .i_d(top_2_second_min_idx),
        .o_q(top_2_second_min_idx_dly)
    );

    delay_n #(
        .N(1),
        .BITS(7),
        .INIT(7'b1111111)
    ) u_delay_abs_llr0 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(flip_alpha_logic_gen),
        .i_d(abs_llr0),
        .o_q(abs_llr0_dly)
    );

    delay_n #(
        .N(1),
        .BITS(7),
        .INIT(7'b1111111)
    ) u_delay_abs_llr1 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(flip_alpha_logic_gen),
        .i_d(abs_llr1),
        .o_q(abs_llr1_dly)
    );

    delay_n #(
        .N(1),
        .BITS(7),
        .INIT(7'b1111111)
    ) u_delay_abs_llr2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(flip_alpha_logic_gen),
        .i_d(abs_llr2),
        .o_q(abs_llr2_dly)
    );

    delay_n #(
        .N(1),
        .BITS(7),
        .INIT(7'b1111111)
    ) u_delay_abs_llr3 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(flip_alpha_logic_gen),
        .i_d(abs_llr3),
        .o_q(abs_llr3_dly)
    );

    delay_n #(
        .N(1),
        .BITS(7),
        .INIT(7'b1111111)
    ) u_delay_abs_llr4 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(flip_alpha_logic_gen),
        .i_d(abs_llr4),
        .o_q(abs_llr4_dly)
    );

    delay_n #(
        .N(1),
        .BITS(7),
        .INIT(7'b1111111)
    ) u_delay_abs_llr5 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(flip_alpha_logic_gen),
        .i_d(abs_llr5),
        .o_q(abs_llr5_dly)
    );

    delay_n #(
        .N(1),
        .BITS(7),
        .INIT(7'b1111111)
    ) u_delay_abs_llr6 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(flip_alpha_logic_gen),
        .i_d(abs_llr6),
        .o_q(abs_llr6_dly)
    );

    delay_n #(
        .N(1),
        .BITS(7),
        .INIT(7'b1111111)
    ) u_delay_abs_llr7 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(flip_alpha_logic_gen),
        .i_d(abs_llr7),
        .o_q(abs_llr7_dly)
    );

    assign abs_llr0 = i_clear_and_wen ? 7'b1111111 : (i_data[63] ? (~i_data[62:56] + 7'b1) : i_data[62:56]);
    assign abs_llr1 = i_data[55] ? (~i_data[54:48] + 7'b1) : i_data[54:48];
    assign abs_llr2 = i_data[47] ? (~i_data[46:40] + 7'b1) : i_data[46:40];
    assign abs_llr3 = i_data[39] ? (~i_data[38:32] + 7'b1) : i_data[38:32];
    assign abs_llr4 = i_data[31] ? (~i_data[30:24] + 7'b1) : i_data[30:24];
    assign abs_llr5 = i_data[23] ? (~i_data[22:16] + 7'b1) : i_data[22:16];
    assign abs_llr6 = i_data[15] ? (~i_data[14:8] + 7'b1) : i_data[14:8];
    assign abs_llr7 = i_data[7]  ? (~i_data[6:0] + 7'b1)  : i_data[6:0];


    assign o_flip_pos1 = min_pos < second_min_pos ? min_pos : second_min_pos;
    assign o_flip_pos2 = min_pos < second_min_pos ? second_min_pos : min_pos;
    assign o_flip_alpha_S1_1 = min_pos < second_min_pos ?  alpha_S1_min : alpha_S1_second_min;
    assign o_flip_alpha_S1_2 = min_pos < second_min_pos ?  alpha_S1_second_min : alpha_S1_min;
    assign o_flip_alpha_S3_1 = min_pos < second_min_pos ?  alpha_S3_min : alpha_S3_second_min;
    assign o_flip_alpha_S3_2 = min_pos < second_min_pos ?  alpha_S3_second_min : alpha_S3_min;
    assign o_flip_alpha_S5_1 = min_pos < second_min_pos ?  alpha_S5_min : alpha_S5_second_min;
    assign o_flip_alpha_S5_2 = min_pos < second_min_pos ?  alpha_S5_second_min : alpha_S5_min;
    assign o_flip_alpha_S7_1 = min_pos < second_min_pos ?  alpha_S7_min : alpha_S7_second_min;
    assign o_flip_alpha_S7_2 = min_pos < second_min_pos ?  alpha_S7_second_min : alpha_S7_min;
    assign o_flip_llr1 = min_pos < second_min_pos ? abs_llr_min : abs_llr_second_min;
    assign o_flip_llr2 = min_pos < second_min_pos ? abs_llr_second_min : abs_llr_min;


    assign o_flip_valid = o_odd_s_valid;

    

    // llr pos logic
    always @(*) begin
        case(i_code) // synopsys full_case
            2'b00: begin
                llr_pos0 = {(7'd7 - counter_next[6:0]), 3'b111};
                llr_pos1 = {(7'd7 - counter_next[6:0]), 3'b110};
                llr_pos2 = {(7'd7 - counter_next[6:0]), 3'b101};
                llr_pos3 = {(7'd7 - counter_next[6:0]), 3'b100};
                llr_pos4 = {(7'd7 - counter_next[6:0]), 3'b011};
                llr_pos5 = {(7'd7 - counter_next[6:0]), 3'b010};
                llr_pos6 = {(7'd7 - counter_next[6:0]), 3'b001};
                llr_pos7 = {(7'd7 - counter_next[6:0]), 3'b000};
            end
            2'b01: begin
                llr_pos0 = {(7'd31 - counter_next[6:0]), 3'b111};
                llr_pos1 = {(7'd31 - counter_next[6:0]), 3'b110};
                llr_pos2 = {(7'd31 - counter_next[6:0]), 3'b101};
                llr_pos3 = {(7'd31 - counter_next[6:0]), 3'b100};
                llr_pos4 = {(7'd31 - counter_next[6:0]), 3'b011};
                llr_pos5 = {(7'd31 - counter_next[6:0]), 3'b010};
                llr_pos6 = {(7'd31 - counter_next[6:0]), 3'b001};
                llr_pos7 = {(7'd31 - counter_next[6:0]), 3'b000};
            end
            2'b10: begin
                llr_pos0 = {(7'd127 - counter_next[6:0]), 3'b111};
                llr_pos1 = {(7'd127 - counter_next[6:0]), 3'b110};
                llr_pos2 = {(7'd127 - counter_next[6:0]), 3'b101};
                llr_pos3 = {(7'd127 - counter_next[6:0]), 3'b100};
                llr_pos4 = {(7'd127 - counter_next[6:0]), 3'b011};
                llr_pos5 = {(7'd127 - counter_next[6:0]), 3'b010};
                llr_pos6 = {(7'd127 - counter_next[6:0]), 3'b001};
                llr_pos7 = {(7'd127 - counter_next[6:0]), 3'b000};
            end
        endcase
    end

    always @(*) begin
        if (clear_and_wen_dly) begin
            case(i_code) // synopsys full_case
                2'b00: begin
                    S1_alpha0 = m6_alpha_n0;
                    S1_alpha1 = m6_alpha_n1;
                    S1_alpha2 = m6_alpha_n2;
                    S1_alpha3 = m6_alpha_n3;
                    S1_alpha4 = m6_alpha_n4;
                    S1_alpha5 = m6_alpha_n5;
                    S1_alpha6 = m6_alpha_n6;
                    S1_alpha7 = m6_alpha_n7;

                    S3_alpha0 = m6_alpha_n0;
                    S3_alpha1 = m6_alpha_n3;
                    S3_alpha2 = m6_alpha_n6;
                    S3_alpha3 = m6_alpha_n9;
                    S3_alpha4 = m6_alpha_n12;
                    S3_alpha5 = m6_alpha_n15;
                    S3_alpha6 = m6_alpha_n18;
                    S3_alpha7 = m6_alpha_n21;

                    S5_alpha0 = 10'b0;
                    S5_alpha1 = 10'b0;
                    S5_alpha2 = 10'b0;
                    S5_alpha3 = 10'b0;
                    S5_alpha4 = 10'b0;
                    S5_alpha5 = 10'b0;
                    S5_alpha6 = 10'b0;
                    S5_alpha7 = 10'b0;

                    S7_alpha0 = 10'b0;
                    S7_alpha1 = 10'b0;
                    S7_alpha2 = 10'b0;
                    S7_alpha3 = 10'b0;
                    S7_alpha4 = 10'b0;
                    S7_alpha5 = 10'b0;
                    S7_alpha6 = 10'b0;
                    S7_alpha7 = 10'b0;
                end
                2'b01: begin
                    S1_alpha0 = m8_alpha_n0;
                    S1_alpha1 = m8_alpha_n1;
                    S1_alpha2 = m8_alpha_n2;
                    S1_alpha3 = m8_alpha_n3;
                    S1_alpha4 = m8_alpha_n4;
                    S1_alpha5 = m8_alpha_n5;
                    S1_alpha6 = m8_alpha_n6;
                    S1_alpha7 = m8_alpha_n7;

                    S3_alpha0 = m8_alpha_n0;
                    S3_alpha1 = m8_alpha_n3;
                    S3_alpha2 = m8_alpha_n6;
                    S3_alpha3 = m8_alpha_n9;
                    S3_alpha4 = m8_alpha_n12;
                    S3_alpha5 = m8_alpha_n15;
                    S3_alpha6 = m8_alpha_n18;
                    S3_alpha7 = m8_alpha_n21;

                    S5_alpha0 = 10'b0;
                    S5_alpha1 = 10'b0;
                    S5_alpha2 = 10'b0;
                    S5_alpha3 = 10'b0;
                    S5_alpha4 = 10'b0;
                    S5_alpha5 = 10'b0;
                    S5_alpha6 = 10'b0;
                    S5_alpha7 = 10'b0;

                    S7_alpha0 = 10'b0;
                    S7_alpha1 = 10'b0;
                    S7_alpha2 = 10'b0;
                    S7_alpha3 = 10'b0;
                    S7_alpha4 = 10'b0;
                    S7_alpha5 = 10'b0;
                    S7_alpha6 = 10'b0;
                    S7_alpha7 = 10'b0;

                end
                2'b10: begin
                    S1_alpha0 = m10_alpha_n0;
                    S1_alpha1 = m10_alpha_n1;
                    S1_alpha2 = m10_alpha_n2;
                    S1_alpha3 = m10_alpha_n3;
                    S1_alpha4 = m10_alpha_n4;
                    S1_alpha5 = m10_alpha_n5;
                    S1_alpha6 = m10_alpha_n6;
                    S1_alpha7 = m10_alpha_n7;

                    S3_alpha0 = m10_alpha_n0;
                    S3_alpha1 = m10_alpha_n3;
                    S3_alpha2 = m10_alpha_n6;
                    S3_alpha3 = m10_alpha_n9;
                    S3_alpha4 = m10_alpha_n12;
                    S3_alpha5 = m10_alpha_n15;
                    S3_alpha6 = m10_alpha_n18;
                    S3_alpha7 = m10_alpha_n21;

                    S5_alpha0 = m10_alpha_n0;
                    S5_alpha1 = m10_alpha_n5;
                    S5_alpha2 = m10_alpha_n10;
                    S5_alpha3 = m10_alpha_n15;
                    S5_alpha4 = m10_alpha_n20;
                    S5_alpha5 = m10_alpha_n25;
                    S5_alpha6 = m10_alpha_n30;
                    S5_alpha7 = m10_alpha_n35;

                    S7_alpha0 = m10_alpha_n0;
                    S7_alpha1 = m10_alpha_n7;
                    S7_alpha2 = m10_alpha_n14;
                    S7_alpha3 = m10_alpha_n21;
                    S7_alpha4 = m10_alpha_n28;
                    S7_alpha5 = m10_alpha_n35;
                    S7_alpha6 = m10_alpha_n42;
                    S7_alpha7 = m10_alpha_n49;
                
                end
            endcase
        end
        else begin
            S1_alpha0 = S1_poly_power[0];
            S1_alpha1 = S1_poly_power[1];
            S1_alpha2 = S1_poly_power[2];
            S1_alpha3 = S1_poly_power[3];
            S1_alpha4 = S1_poly_power[4];
            S1_alpha5 = S1_poly_power[5];
            S1_alpha6 = S1_poly_power[6];
            S1_alpha7 = S1_poly_power[7];

            S3_alpha0 = S3_poly_power[0];
            S3_alpha1 = S3_poly_power[1];
            S3_alpha2 = S3_poly_power[2];
            S3_alpha3 = S3_poly_power[3];
            S3_alpha4 = S3_poly_power[4];
            S3_alpha5 = S3_poly_power[5];
            S3_alpha6 = S3_poly_power[6];
            S3_alpha7 = S3_poly_power[7];

            S5_alpha0 = S5_poly_power[0];
            S5_alpha1 = S5_poly_power[1];
            S5_alpha2 = S5_poly_power[2];
            S5_alpha3 = S5_poly_power[3];
            S5_alpha4 = S5_poly_power[4];
            S5_alpha5 = S5_poly_power[5];
            S5_alpha6 = S5_poly_power[6];
            S5_alpha7 = S5_poly_power[7];

            S7_alpha0 = S7_poly_power[0];
            S7_alpha1 = S7_poly_power[1];
            S7_alpha2 = S7_poly_power[2];
            S7_alpha3 = S7_poly_power[3];
            S7_alpha4 = S7_poly_power[4];
            S7_alpha5 = S7_poly_power[5];
            S7_alpha6 = S7_poly_power[6];
            S7_alpha7 = S7_poly_power[7];
        end
    end


    // min and second min logic
        // min and second min logic
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            min_llr             <= 7'b1111111;
            second_min_llr      <= 7'b1111111;
            alpha_S1_min        <= 10'b0;
            alpha_S1_second_min <= 10'b0;
            alpha_S3_min        <= 10'b0;
            alpha_S3_second_min <= 10'b0;
            alpha_S5_min        <= 10'b0;
            alpha_S5_second_min <= 10'b0;
            alpha_S7_min        <= 10'b0;
            alpha_S7_second_min <= 10'b0;
            min_pos             <= 10'b0;
            second_min_pos      <= 10'b0;
            abs_llr_min         <= 7'b0;
            abs_llr_second_min  <= 7'b0;

        end
        else begin
            // clock gating by flip_alpha_logic_gen (clock enable style)
            min_llr             <= flip_alpha_logic_gen ? min_llr_next             : min_llr;
            second_min_llr      <= flip_alpha_logic_gen ? second_min_llr_next      : second_min_llr;
            alpha_S1_min        <= flip_alpha_logic_gen ? alpha_S1_min_next        : alpha_S1_min;
            alpha_S1_second_min <= flip_alpha_logic_gen ? alpha_S1_second_min_next : alpha_S1_second_min;
            alpha_S3_min        <= flip_alpha_logic_gen ? alpha_S3_min_next        : alpha_S3_min;
            alpha_S3_second_min <= flip_alpha_logic_gen ? alpha_S3_second_min_next : alpha_S3_second_min;
            alpha_S5_min        <= flip_alpha_logic_gen ? alpha_S5_min_next        : alpha_S5_min;
            alpha_S5_second_min <= flip_alpha_logic_gen ? alpha_S5_second_min_next : alpha_S5_second_min;
            alpha_S7_min        <= flip_alpha_logic_gen ? alpha_S7_min_next        : alpha_S7_min;
            alpha_S7_second_min <= flip_alpha_logic_gen ? alpha_S7_second_min_next : alpha_S7_second_min;
            min_pos             <= flip_alpha_logic_gen ? min_pos_next             : min_pos;
            second_min_pos      <= flip_alpha_logic_gen ? second_min_pos_next      : second_min_pos;
            abs_llr_min         <= flip_alpha_logic_gen ? abs_llr_min_next         : abs_llr_min;
            abs_llr_second_min  <= flip_alpha_logic_gen ? abs_llr_second_min_next  : abs_llr_second_min;
        end
    end

    always @(*) begin
        if (i_wen || i_clear_and_wen) begin
            min_llr_next = top_2_min;
            second_min_llr_next = top_2_second_min;
        end
        else begin
            min_llr_next = min_llr;
            second_min_llr_next = second_min_llr;
        end
    end

    always @(*) begin
        if (wen_dly || clear_and_wen_dly) begin
            case (top_2_min_idx_dly)
                4'd0: begin
                    alpha_S1_min_next = S1_alpha0;
                    alpha_S3_min_next = S3_alpha0;
                    alpha_S5_min_next = S5_alpha0;
                    alpha_S7_min_next = S7_alpha0;
                    min_pos_next = llr_pos0;
                    abs_llr_min_next = abs_llr0_dly;
                end
                4'd1: begin
                    alpha_S1_min_next = S1_alpha1;
                    alpha_S3_min_next = S3_alpha1;
                    alpha_S5_min_next = S5_alpha1;
                    alpha_S7_min_next = S7_alpha1;
                    min_pos_next = llr_pos1;
                    abs_llr_min_next = abs_llr1_dly;
                end
                4'd2: begin
                    alpha_S1_min_next = S1_alpha2;
                    alpha_S3_min_next = S3_alpha2;
                    alpha_S5_min_next = S5_alpha2;
                    alpha_S7_min_next = S7_alpha2;
                    min_pos_next = llr_pos2;
                    abs_llr_min_next = abs_llr2_dly;
                end
                4'd3: begin
                    alpha_S1_min_next = S1_alpha3;
                    alpha_S3_min_next = S3_alpha3;
                    alpha_S5_min_next = S5_alpha3;
                    alpha_S7_min_next = S7_alpha3;
                    min_pos_next = llr_pos3;
                    abs_llr_min_next = abs_llr3_dly;
                end
                4'd4: begin
                    alpha_S1_min_next = S1_alpha4;
                    alpha_S3_min_next = S3_alpha4;
                    alpha_S5_min_next = S5_alpha4;
                    alpha_S7_min_next = S7_alpha4;
                    min_pos_next = llr_pos4;
                    abs_llr_min_next = abs_llr4_dly;
                end
                4'd5: begin
                    alpha_S1_min_next = S1_alpha5;
                    alpha_S3_min_next = S3_alpha5;
                    alpha_S5_min_next = S5_alpha5;
                    alpha_S7_min_next = S7_alpha5;
                    min_pos_next = llr_pos5;
                    abs_llr_min_next = abs_llr5_dly;
                end
                4'd6: begin
                    alpha_S1_min_next = S1_alpha6;
                    alpha_S3_min_next = S3_alpha6;
                    alpha_S5_min_next = S5_alpha6;
                    alpha_S7_min_next = S7_alpha6;
                    min_pos_next = llr_pos6;
                    abs_llr_min_next = abs_llr6_dly;
                end
                4'd7: begin
                    alpha_S1_min_next = S1_alpha7;
                    alpha_S3_min_next = S3_alpha7;
                    alpha_S5_min_next = S5_alpha7;
                    alpha_S7_min_next = S7_alpha7;
                    min_pos_next = llr_pos7;
                    abs_llr_min_next = abs_llr7_dly;
                end
                4'd8: begin
                    alpha_S1_min_next = alpha_S1_min;
                    alpha_S3_min_next = alpha_S3_min;
                    alpha_S5_min_next = alpha_S5_min;
                    alpha_S7_min_next = alpha_S7_min;
                    min_pos_next = min_pos;
                    abs_llr_min_next = abs_llr_min;
                end
                4'd9: begin
                    alpha_S1_min_next = alpha_S1_second_min;
                    alpha_S3_min_next = alpha_S3_second_min;
                    alpha_S5_min_next = alpha_S5_second_min;
                    alpha_S7_min_next = alpha_S7_second_min;
                    min_pos_next = second_min_pos;
                    abs_llr_min_next = abs_llr_second_min;
                end
                default: begin
                    alpha_S1_min_next = alpha_S1_min;
                    alpha_S3_min_next = alpha_S3_min;
                    alpha_S5_min_next = alpha_S5_min;
                    alpha_S7_min_next = alpha_S7_min;
                    min_pos_next = min_pos;
                    abs_llr_min_next = abs_llr_min;
                end
            endcase

            case (top_2_second_min_idx_dly)
                4'd0: begin
                    alpha_S1_second_min_next = S1_alpha0;
                    alpha_S3_second_min_next = S3_alpha0;
                    alpha_S5_second_min_next = S5_alpha0;
                    alpha_S7_second_min_next = S7_alpha0;
                    second_min_pos_next = llr_pos0;
                    abs_llr_second_min_next = abs_llr0_dly;
                end
                4'd1: begin
                    alpha_S1_second_min_next = S1_alpha1;
                    alpha_S3_second_min_next = S3_alpha1;
                    alpha_S5_second_min_next = S5_alpha1;
                    alpha_S7_second_min_next = S7_alpha1;
                    second_min_pos_next = llr_pos1;
                    abs_llr_second_min_next = abs_llr1_dly;
                end
                4'd2: begin
                    alpha_S1_second_min_next = S1_alpha2;
                    alpha_S3_second_min_next = S3_alpha2;
                    alpha_S5_second_min_next = S5_alpha2;
                    alpha_S7_second_min_next = S7_alpha2;
                    second_min_pos_next = llr_pos2;
                    abs_llr_second_min_next = abs_llr2_dly;
                end
                4'd3: begin
                    alpha_S1_second_min_next = S1_alpha3;
                    alpha_S3_second_min_next = S3_alpha3;
                    alpha_S5_second_min_next = S5_alpha3;
                    alpha_S7_second_min_next = S7_alpha3;
                    second_min_pos_next = llr_pos3;
                    abs_llr_second_min_next = abs_llr3_dly;
                end
                4'd4: begin
                    alpha_S1_second_min_next = S1_alpha4;
                    alpha_S3_second_min_next = S3_alpha4;
                    alpha_S5_second_min_next = S5_alpha4;
                    alpha_S7_second_min_next = S7_alpha4;
                    second_min_pos_next = llr_pos4;
                    abs_llr_second_min_next = abs_llr4_dly;
                end
                4'd5: begin
                    alpha_S1_second_min_next = S1_alpha5;
                    alpha_S3_second_min_next = S3_alpha5;
                    alpha_S5_second_min_next = S5_alpha5;
                    alpha_S7_second_min_next = S7_alpha5;
                    second_min_pos_next = llr_pos5;
                    abs_llr_second_min_next = abs_llr5_dly;
                end
                4'd6: begin
                    alpha_S1_second_min_next = S1_alpha6;
                    alpha_S3_second_min_next = S3_alpha6;
                    alpha_S5_second_min_next = S5_alpha6;
                    alpha_S7_second_min_next = S7_alpha6;
                    second_min_pos_next = llr_pos6;
                    abs_llr_second_min_next = abs_llr6_dly;
                end
                4'd7: begin
                    alpha_S1_second_min_next = S1_alpha7;
                    alpha_S3_second_min_next = S3_alpha7;
                    alpha_S5_second_min_next = S5_alpha7;
                    alpha_S7_second_min_next = S7_alpha7;
                    second_min_pos_next = llr_pos7;
                    abs_llr_second_min_next = abs_llr7_dly;
                end
                4'd8: begin
                    alpha_S1_second_min_next = alpha_S1_min;
                    alpha_S3_second_min_next = alpha_S3_min;
                    alpha_S5_second_min_next = alpha_S5_min;
                    alpha_S7_second_min_next = alpha_S7_min;
                    second_min_pos_next = min_pos;
                    abs_llr_second_min_next = abs_llr_min;
                end 
                4'd9: begin
                    alpha_S1_second_min_next = alpha_S1_second_min;
                    alpha_S3_second_min_next = alpha_S3_second_min;
                    alpha_S5_second_min_next = alpha_S5_second_min;
                    alpha_S7_second_min_next = alpha_S7_second_min;
                    second_min_pos_next = second_min_pos;
                    abs_llr_second_min_next = abs_llr_second_min;
                end
                default: begin
                    alpha_S1_second_min_next = alpha_S1_second_min;
                    alpha_S3_second_min_next = alpha_S3_second_min;
                    alpha_S5_second_min_next = alpha_S5_second_min;
                    alpha_S7_second_min_next = alpha_S7_second_min;
                    second_min_pos_next = second_min_pos;
                    abs_llr_second_min_next = abs_llr_second_min;
                end
            endcase
        end
        else begin
            alpha_S1_min_next = alpha_S1_min;
            alpha_S1_second_min_next = alpha_S1_second_min;
            alpha_S3_min_next = alpha_S3_min;
            alpha_S3_second_min_next = alpha_S3_second_min;
            alpha_S5_min_next = alpha_S5_min;
            alpha_S5_second_min_next = alpha_S5_second_min;
            alpha_S7_min_next = alpha_S7_min;
            alpha_S7_second_min_next = alpha_S7_second_min;
            min_pos_next = min_pos;
            second_min_pos_next = second_min_pos;
            abs_llr_min_next = abs_llr_min;
            abs_llr_second_min_next = abs_llr_second_min;
        end
    end

endmodule