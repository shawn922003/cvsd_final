module top_2(
    input [6:0] i_0,
    input [6:0] i_1,
    input [6:0] i_2,
    input [6:0] i_3,
    input [6:0] i_4,
    input [6:0] i_5,
    input [6:0] i_6,
    input [6:0] i_7,
    input [6:0] i_8, // i_8 < i_9
    input [6:0] i_9,

    // o_0 <= o_1
    output [6:0] o_0,
    output [6:0] o_1,

    output [3:0] o_0_idx,
    output [3:0] o_1_idx
);

    wire [6:0] layer1_val[9:0];
    wire [3:0] layer1_idx[9:0];

    compare2 u_compare2_0 (
        .i_a(i_0),
        .i_b(i_1),
        .i_a_idx(4'd0),
        .i_b_idx(4'd1),
        .o_min(layer1_val[0]),
        .o_max(layer1_val[1]),
        .o_min_idx(layer1_idx[0]),
        .o_max_idx(layer1_idx[1])
    );

    compare2 u_compare2_1 (
        .i_a(i_2),
        .i_b(i_3),
        .i_a_idx(4'd2),
        .i_b_idx(4'd3),
        .o_min(layer1_val[2]),
        .o_max(layer1_val[3]),
        .o_min_idx(layer1_idx[2]),
        .o_max_idx(layer1_idx[3])
    );

    compare2 u_compare2_2 (
        .i_a(i_4),
        .i_b(i_5),
        .i_a_idx(4'd4),
        .i_b_idx(4'd5),
        .o_min(layer1_val[4]),
        .o_max(layer1_val[5]),
        .o_min_idx(layer1_idx[4]),
        .o_max_idx(layer1_idx[5])
    );

    compare2 u_compare2_3 (
        .i_a(i_6),
        .i_b(i_7),
        .i_a_idx(4'd6),
        .i_b_idx(4'd7),
        .o_min(layer1_val[6]),
        .o_max(layer1_val[7]),
        .o_min_idx(layer1_idx[6]),
        .o_max_idx(layer1_idx[7])
    );

    assign layer1_val[8] = i_8;
    assign layer1_idx[8] = 4'd8;
    assign layer1_val[9] = i_9;
    assign layer1_idx[9] = 4'd9;


    wire [6:0] layer2_val[5:0];
    wire [3:0] layer2_idx[5:0];

    assign layer2_val[0] = layer1_val[0];
    assign layer2_idx[0] = layer1_idx[0];
    assign layer2_val[1] = layer1_val[1];
    assign layer2_idx[1] = layer1_idx[1];

    merge2 u_merge2_0 (
        .i_a0(layer1_val[2]),
        .i_a1(layer1_val[3]),
        .i_b0(layer1_val[4]),
        .i_b1(layer1_val[5]),
        .i_a0_idx(layer1_idx[2]),
        .i_a1_idx(layer1_idx[3]),
        .i_b0_idx(layer1_idx[4]),
        .i_b1_idx(layer1_idx[5]),
        .o_min(layer2_val[2]),
        .o_second_min(layer2_val[3]),
        .o_min_idx(layer2_idx[2]),
        .o_second_min_idx(layer2_idx[3])
    );

    merge2 u_merge2_1 (
        .i_a0(layer1_val[6]),
        .i_a1(layer1_val[7]),
        .i_b0(layer1_val[8]),
        .i_b1(layer1_val[9]),
        .i_a0_idx(layer1_idx[6]),
        .i_a1_idx(layer1_idx[7]),
        .i_b0_idx(layer1_idx[8]),
        .i_b1_idx(layer1_idx[9]),
        .o_min(layer2_val[4]),
        .o_second_min(layer2_val[5]),
        .o_min_idx(layer2_idx[4]),
        .o_second_min_idx(layer2_idx[5])
    );
        

    wire [6:0] layer3_val[3:0];
    wire [3:0] layer3_idx[3:0];
  
    assign layer3_val[0] = layer2_val[0];
    assign layer3_idx[0] = layer2_idx[0];
    assign layer3_val[1] = layer2_val[1];
    assign layer3_idx[1] = layer2_idx[1];

    merge2 u_merge2_2 (
        .i_a0(layer2_val[2]),
        .i_a1(layer2_val[3]),
        .i_b0(layer2_val[4]),
        .i_b1(layer2_val[5]),
        .i_a0_idx(layer2_idx[2]),
        .i_a1_idx(layer2_idx[3]),
        .i_b0_idx(layer2_idx[4]),
        .i_b1_idx(layer2_idx[5]),
        .o_min(layer3_val[2]),
        .o_second_min(layer3_val[3]),
        .o_min_idx(layer3_idx[2]),
        .o_second_min_idx(layer3_idx[3])
    );


    merge2 u_merge2_3 (
        .i_a0(layer3_val[0]),
        .i_a1(layer3_val[1]),
        .i_b0(layer3_val[2]),
        .i_b1(layer3_val[3]),
        .i_a0_idx(layer3_idx[0]),
        .i_a1_idx(layer3_idx[1]),
        .i_b0_idx(layer3_idx[2]),
        .i_b1_idx(layer3_idx[3]),
        .o_min(o_0),
        .o_second_min(o_1),
        .o_min_idx(o_0_idx),
        .o_second_min_idx(o_1_idx)
    );

 

endmodule


module compare2(
    input [6:0] i_a,
    input [6:0] i_b,
    input [3:0] i_a_idx,
    input [3:0] i_b_idx,

    output reg [6:0] o_min,
    output reg [6:0] o_max,
    output reg [3:0] o_min_idx,
    output reg [3:0] o_max_idx
);

    always @(*) begin
        if (i_a < i_b) begin
            o_min = i_a;
            o_max = i_b;
            o_min_idx = i_a_idx;
            o_max_idx = i_b_idx;
        end
        else begin
            o_min = i_b;
            o_max = i_a;
            o_min_idx = i_b_idx;
            o_max_idx = i_a_idx;
        end
    end
endmodule
    

module merge2(
    // i_a0 <= i_a1
    input [6:0] i_a0,
    input [6:0] i_a1,

    // i_b0 <= i_b1
    input [6:0] i_b0,
    input [6:0] i_b1,

    input [3:0] i_a0_idx,
    input [3:0] i_a1_idx,
    input [3:0] i_b0_idx,
    input [3:0] i_b1_idx,

    output reg [6:0] o_second_min,     
    output reg [6:0] o_min,           
    output reg [3:0] o_second_min_idx,  
    output reg [3:0] o_min_idx          
);

    // a0_le_b0 = 1  i_a0 <= i_b0
    wire a0_le_b0 = (i_a0 <= i_b0);

    // a1_le_b0 = 1  i_a1 <= i_b0
    wire a1_le_b0 = (i_a1 <= i_b0);

    // b1_le_a0 = 1 i_b1 <= i_a0
    wire b1_le_a0 = (i_b1 <= i_a0);

    always @(*) begin
        if (a0_le_b0) begin
            // i_a0 <= i_b0
            o_min     = i_a0;
            o_min_idx = i_a0_idx;
            if (a1_le_b0) begin
                // i_a1 <= i_b0
                o_second_min     = i_a1;
                o_second_min_idx = i_a1_idx;
            end 
            else begin
                // i_b0 < i_a1
                o_second_min     = i_b0;
                o_second_min_idx = i_b0_idx;
            end
        end else begin
            // i_b0 < i_a0
            o_min     = i_b0;
            o_min_idx = i_b0_idx;

            if (b1_le_a0) begin
                o_second_min     = i_b1;
                o_second_min_idx = i_b1_idx;
            end else begin
                o_second_min     = i_a0;
                o_second_min_idx = i_a0_idx;
            end
        end
    end

endmodule
