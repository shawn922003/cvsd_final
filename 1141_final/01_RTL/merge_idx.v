module merge_idx #(
    parameter WIDTH = 4,
    parameter IS_SHIFTED = 1'b1
)(
    input  [WIDTH-2:0] i_idx1_1,
    input  [WIDTH-2:0] i_idx1_2,
    input  [WIDTH-2:0] i_idx1_3,
    input  [WIDTH-2:0] i_idx1_4,
    input  [2:0]       i_num1,

    input  [WIDTH-2:0] i_idx2_1,
    input  [WIDTH-2:0] i_idx2_2,
    input  [WIDTH-2:0] i_idx2_3,
    input  [WIDTH-2:0] i_idx2_4,
    input  [2:0]       i_num2,

    output [WIDTH-1:0] o_idx1,
    output [WIDTH-1:0] o_idx2,
    output [WIDTH-1:0] o_idx3,
    output [WIDTH-1:0] o_idx4,
    output [2:0]       o_num
);
    wire [WIDTH-1:0] idx1_1_full = {1'b0, i_idx1_1};
    wire [WIDTH-1:0] idx1_2_full = {1'b0, i_idx1_2};
    wire [WIDTH-1:0] idx1_3_full = {1'b0, i_idx1_3};
    wire [WIDTH-1:0] idx1_4_full = {1'b0, i_idx1_4};

    wire [WIDTH-1:0] idx2_1_full = {IS_SHIFTED, i_idx2_1};
    wire [WIDTH-1:0] idx2_2_full = {IS_SHIFTED, i_idx2_2};
    wire [WIDTH-1:0] idx2_3_full = {IS_SHIFTED, i_idx2_3};
    wire [WIDTH-1:0] idx2_4_full = {IS_SHIFTED, i_idx2_4};

    wire [2:0] n1 = i_num1;
    wire [2:0] n2 = i_num2;

    assign o_num = n1 + n2;

    localparam [WIDTH-1:0] ZERO_IDX = {WIDTH{1'b0}};

    wire [WIDTH-1:0] o1_from_l = (n1 >= 3'd1) ? idx1_1_full : ZERO_IDX;
    wire [WIDTH-1:0] o1_from_r = ((n1 == 3'd0) && (n2 >= 3'd1)) ? idx2_1_full : ZERO_IDX;
    assign o_idx1 = o1_from_l | o1_from_r;


    wire [WIDTH-1:0] o2_from_l2 = (n1 >= 3'd2) ? idx1_2_full : ZERO_IDX;
    wire [WIDTH-1:0] o2_from_r1 = ((n1 == 3'd1) && (n2 >= 3'd1)) ? idx2_1_full : ZERO_IDX;
    wire [WIDTH-1:0] o2_from_r2 = ((n1 == 3'd0) && (n2 >= 3'd2)) ? idx2_2_full : ZERO_IDX;
    assign o_idx2 = o2_from_l2 | o2_from_r1 | o2_from_r2;


    wire [WIDTH-1:0] o3_from_l3 = (n1 >= 3'd3) ? idx1_3_full : ZERO_IDX;
    wire [WIDTH-1:0] o3_from_r1 = ((n1 == 3'd2) && (n2 >= 3'd1)) ? idx2_1_full : ZERO_IDX;
    wire [WIDTH-1:0] o3_from_r2 = ((n1 == 3'd1) && (n2 >= 3'd2)) ? idx2_2_full : ZERO_IDX;
    wire [WIDTH-1:0] o3_from_r3 = ((n1 == 3'd0) && (n2 >= 3'd3)) ? idx2_3_full : ZERO_IDX;
    assign o_idx3 = o3_from_l3 | o3_from_r1 | o3_from_r2 | o3_from_r3;


    wire [WIDTH-1:0] o4_from_l4 = (n1 >= 3'd4) ? idx1_4_full : ZERO_IDX;
    wire [WIDTH-1:0] o4_from_r1 = ((n1 == 3'd3) && (n2 >= 3'd1)) ? idx2_1_full : ZERO_IDX;
    wire [WIDTH-1:0] o4_from_r2 = ((n1 == 3'd2) && (n2 >= 3'd2)) ? idx2_2_full : ZERO_IDX;
    wire [WIDTH-1:0] o4_from_r3 = ((n1 == 3'd1) && (n2 >= 3'd3)) ? idx2_3_full : ZERO_IDX;
    wire [WIDTH-1:0] o4_from_r4 = ((n1 == 3'd0) && (n2 >= 3'd4)) ? idx2_4_full : ZERO_IDX;
    assign o_idx4 = o4_from_l4 | o4_from_r1 | o4_from_r2 | o4_from_r3 | o4_from_r4;

endmodule