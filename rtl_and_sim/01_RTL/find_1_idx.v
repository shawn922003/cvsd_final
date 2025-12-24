module find_1_idx(
    input  [127:0] i_data,

    output [6:0]   o_idx1,
    output [6:0]   o_idx2,
    output [6:0]   o_idx3,
    output [6:0]   o_idx4,
    output [2:0]   o_num_found
);

    wire [2:0] g_idx1 [0:15];
    wire [2:0] g_idx2 [0:15];
    wire [2:0] g_idx3 [0:15];
    wire [2:0] g_idx4 [0:15];
    wire [2:0] g_num  [0:15];

    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : GEN_G8
            group8 u_group8 (
                .i_data      ( i_data[gi*8 +: 8] ),   // bit [8*gi+7 : 8*gi]

                .o_idx1      ( g_idx1[gi] ),
                .o_idx2      ( g_idx2[gi] ),
                .o_idx3      ( g_idx3[gi] ),
                .o_idx4      ( g_idx4[gi] ),
                .o_num_found ( g_num[gi]  )
            );
        end
    endgenerate


    wire [3:0] l1_idx1 [0:7];
    wire [3:0] l1_idx2 [0:7];
    wire [3:0] l1_idx3 [0:7];
    wire [3:0] l1_idx4 [0:7];
    wire [2:0] l1_num  [0:7];

    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : GEN_L1
            merge_idx #(
                .WIDTH(4),
                .IS_SHIFTED(1'b1)
            ) u_merge_idx_l1 (
                .i_idx1_1 ( g_idx1[2*gi]   ),
                .i_idx1_2 ( g_idx2[2*gi]   ),
                .i_idx1_3 ( g_idx3[2*gi]   ),
                .i_idx1_4 ( g_idx4[2*gi]   ),
                .i_num1   ( g_num [2*gi]   ),

                .i_idx2_1 ( g_idx1[2*gi+1] ),
                .i_idx2_2 ( g_idx2[2*gi+1] ),
                .i_idx2_3 ( g_idx3[2*gi+1] ),
                .i_idx2_4 ( g_idx4[2*gi+1] ),
                .i_num2   ( g_num [2*gi+1] ),

                .o_idx1   ( l1_idx1[gi]    ),
                .o_idx2   ( l1_idx2[gi]    ),
                .o_idx3   ( l1_idx3[gi]    ),
                .o_idx4   ( l1_idx4[gi]    ),
                .o_num    ( l1_num [gi]    )
            );
        end
    endgenerate


    wire [4:0] l2_idx1 [0:3];
    wire [4:0] l2_idx2 [0:3];
    wire [4:0] l2_idx3 [0:3];
    wire [4:0] l2_idx4 [0:3];
    wire [2:0] l2_num  [0:3];

    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : GEN_L2
            merge_idx #(
                .WIDTH(5),
                .IS_SHIFTED(1'b1)
            )  u_merge_idx_l2 (
                .i_idx1_1 ( l1_idx1[2*gi]   ),
                .i_idx1_2 ( l1_idx2[2*gi]   ),
                .i_idx1_3 ( l1_idx3[2*gi]   ),
                .i_idx1_4 ( l1_idx4[2*gi]   ),
                .i_num1   ( l1_num [2*gi]   ),

                .i_idx2_1 ( l1_idx1[2*gi+1] ),
                .i_idx2_2 ( l1_idx2[2*gi+1] ),
                .i_idx2_3 ( l1_idx3[2*gi+1] ),
                .i_idx2_4 ( l1_idx4[2*gi+1] ),
                .i_num2   ( l1_num [2*gi+1] ),

                .o_idx1   ( l2_idx1[gi]     ),
                .o_idx2   ( l2_idx2[gi]     ),
                .o_idx3   ( l2_idx3[gi]     ),
                .o_idx4   ( l2_idx4[gi]     ),
                .o_num    ( l2_num [gi]     )
            );
        end
    endgenerate


    wire [5:0] l3_idx1 [0:1];
    wire [5:0] l3_idx2 [0:1];
    wire [5:0] l3_idx3 [0:1];
    wire [5:0] l3_idx4 [0:1];
    wire [2:0] l3_num  [0:1];

    generate
        for (gi = 0; gi < 2; gi = gi + 1) begin : GEN_L3
            merge_idx #(
                .WIDTH(6),
                .IS_SHIFTED(1'b1)
            )  u_merge_idx_l3 (
                .i_idx1_1 ( l2_idx1[2*gi]   ),
                .i_idx1_2 ( l2_idx2[2*gi]   ),
                .i_idx1_3 ( l2_idx3[2*gi]   ),
                .i_idx1_4 ( l2_idx4[2*gi]   ),
                .i_num1   ( l2_num [2*gi]   ),

                .i_idx2_1 ( l2_idx1[2*gi+1] ),
                .i_idx2_2 ( l2_idx2[2*gi+1] ),
                .i_idx2_3 ( l2_idx3[2*gi+1] ),
                .i_idx2_4 ( l2_idx4[2*gi+1] ),
                .i_num2   ( l2_num [2*gi+1] ),

                .o_idx1   ( l3_idx1[gi]     ),
                .o_idx2   ( l3_idx2[gi]     ),
                .o_idx3   ( l3_idx3[gi]     ),
                .o_idx4   ( l3_idx4[gi]     ),
                .o_num    ( l3_num [gi]     )
            );
        end
    endgenerate


    wire [6:0] root_idx1, root_idx2, root_idx3, root_idx4;
    wire [2:0] root_num;

    merge_idx #(
        .WIDTH(7),
        .IS_SHIFTED(1'b1)
    )  u_merge_idx_root (
        .i_idx1_1 ( l3_idx1[0] ),
        .i_idx1_2 ( l3_idx2[0] ),
        .i_idx1_3 ( l3_idx3[0] ),
        .i_idx1_4 ( l3_idx4[0] ),
        .i_num1   ( l3_num [0] ),

        .i_idx2_1 ( l3_idx1[1] ),
        .i_idx2_2 ( l3_idx2[1] ),
        .i_idx2_3 ( l3_idx3[1] ),
        .i_idx2_4 ( l3_idx4[1] ),
        .i_num2   ( l3_num [1] ),

        .o_idx1   ( root_idx1 ),
        .o_idx2   ( root_idx2 ),
        .o_idx3   ( root_idx3 ),
        .o_idx4   ( root_idx4 ),
        .o_num    ( root_num  )
    );

    assign o_idx1      = root_idx1;
    assign o_idx2      = root_idx2;
    assign o_idx3      = root_idx3;
    assign o_idx4      = root_idx4;
    assign o_num_found = root_num;

endmodule


module group8(
    input [7:0] i_data,

    output [2:0] o_idx1,
    output [2:0] o_idx2,
    output [2:0] o_idx3,
    output [2:0] o_idx4,
    output [2:0] o_num_found
);

    wire [2:0] idx[0:7];
    wire [2:0] count[0:7];

    wire [2:0] out_pos[0:7][1:4];

    assign idx[0] = 3'd0;
    assign idx[1] = 3'd1;
    assign idx[2] = 3'd2;
    assign idx[3] = 3'd3;
    assign idx[4] = 3'd4;
    assign idx[5] = 3'd5;
    assign idx[6] = 3'd6;
    assign idx[7] = 3'd7;

    assign count[0] = i_data[0] ? 3'd1 : 3'd0;
    assign count[1] = count[0] + (i_data[1] ? 3'd1 : 3'd0);
    assign count[2] = count[1] + (i_data[2] ? 3'd1 : 3'd0);
    assign count[3] = count[2] + (i_data[3] ? 3'd1 : 3'd0);
    assign count[4] = count[3] + (i_data[4] ? 3'd1 : 3'd0);
    assign count[5] = count[4] + (i_data[5] ? 3'd1 : 3'd0);
    assign count[6] = count[5] + (i_data[6] ? 3'd1 : 3'd0);
    assign count[7] = count[6] + (i_data[7] ? 3'd1 : 3'd0);

    assign o_num_found = count[7];

    assign out_pos[0][1] = count[0] == 3'd1 ? (idx[0] & {3{i_data[0]}}) : 3'd0;
    assign out_pos[0][2] = count[0] == 3'd2 ? (idx[0] & {3{i_data[0]}}) : 3'd0;
    assign out_pos[0][3] = count[0] == 3'd3 ? (idx[0] & {3{i_data[0]}}) : 3'd0;
    assign out_pos[0][4] = count[0] == 3'd4 ? (idx[0] & {3{i_data[0]}}) : 3'd0;
    assign out_pos[1][1] = count[1] == 3'd1 ? (idx[1] & {3{i_data[1]}}) : 3'd0;
    assign out_pos[1][2] = count[1] == 3'd2 ? (idx[1] & {3{i_data[1]}}) : 3'd0;
    assign out_pos[1][3] = count[1] == 3'd3 ? (idx[1] & {3{i_data[1]}}) : 3'd0;
    assign out_pos[1][4] = count[1] == 3'd4 ? (idx[1] & {3{i_data[1]}}) : 3'd0;
    assign out_pos[2][1] = count[2] == 3'd1 ? (idx[2] & {3{i_data[2]}}) : 3'd0;
    assign out_pos[2][2] = count[2] == 3'd2 ? (idx[2] & {3{i_data[2]}}) : 3'd0;
    assign out_pos[2][3] = count[2] == 3'd3 ? (idx[2] & {3{i_data[2]}}) : 3'd0;
    assign out_pos[2][4] = count[2] == 3'd4 ? (idx[2] & {3{i_data[2]}}) : 3'd0;
    assign out_pos[3][1] = count[3] == 3'd1 ? (idx[3] & {3{i_data[3]}}) : 3'd0;
    assign out_pos[3][2] = count[3] == 3'd2 ? (idx[3] & {3{i_data[3]}}) : 3'd0;
    assign out_pos[3][3] = count[3] == 3'd3 ? (idx[3] & {3{i_data[3]}}) : 3'd0;
    assign out_pos[3][4] = count[3] == 3'd4 ? (idx[3] & {3{i_data[3]}}) : 3'd0;
    assign out_pos[4][1] = count[4] == 3'd1 ? (idx[4] & {3{i_data[4]}}) : 3'd0;
    assign out_pos[4][2] = count[4] == 3'd2 ? (idx[4] & {3{i_data[4]}}) : 3'd0;
    assign out_pos[4][3] = count[4] == 3'd3 ? (idx[4] & {3{i_data[4]}}) : 3'd0;
    assign out_pos[4][4] = count[4] == 3'd4 ? (idx[4] & {3{i_data[4]}}) : 3'd0;
    assign out_pos[5][1] = count[5] == 3'd1 ? (idx[5] & {3{i_data[5]}}) : 3'd0;
    assign out_pos[5][2] = count[5] == 3'd2 ? (idx[5] & {3{i_data[5]}}) : 3'd0;
    assign out_pos[5][3] = count[5] == 3'd3 ? (idx[5] & {3{i_data[5]}}) : 3'd0;
    assign out_pos[5][4] = count[5] == 3'd4 ? (idx[5] & {3{i_data[5]}}) : 3'd0;
    assign out_pos[6][1] = count[6] == 3'd1 ? (idx[6] & {3{i_data[6]}}) : 3'd0;
    assign out_pos[6][2] = count[6] == 3'd2 ? (idx[6] & {3{i_data[6]}}) : 3'd0;
    assign out_pos[6][3] = count[6] == 3'd3 ? (idx[6] & {3{i_data[6]}}) : 3'd0;
    assign out_pos[6][4] = count[6] == 3'd4 ? (idx[6] & {3{i_data[6]}}) : 3'd0;
    assign out_pos[7][1] = count[7] == 3'd1 ? (idx[7] & {3{i_data[7]}}) : 3'd0;
    assign out_pos[7][2] = count[7] == 3'd2 ? (idx[7] & {3{i_data[7]}}) : 3'd0;
    assign out_pos[7][3] = count[7] == 3'd3 ? (idx[7] & {3{i_data[7]}}) : 3'd0;
    assign out_pos[7][4] = count[7] == 3'd4 ? (idx[7] & {3{i_data[7]}}) : 3'd0;

    assign o_idx1 = out_pos[0][1] | out_pos[1][1] | out_pos[2][1] | out_pos[3][1] |
                    out_pos[4][1] | out_pos[5][1] | out_pos[6][1] | out_pos[7][1];
    assign o_idx2 = out_pos[0][2] | out_pos[1][2] | out_pos[2][2] | out_pos[3][2] |
                    out_pos[4][2] | out_pos[5][2] | out_pos[6][2] | out_pos[7][2];
    assign o_idx3 = out_pos[0][3] | out_pos[1][3] | out_pos[2][3] | out_pos[3][3] |
                    out_pos[4][3] | out_pos[5][3] | out_pos[6][3] | out_pos[7][3];
    assign o_idx4 = out_pos[0][4] | out_pos[1][4] | out_pos[2][4] | out_pos[3][4] |
                    out_pos[4][4] | out_pos[5][4] | out_pos[6][4] | out_pos[7][4];

endmodule




