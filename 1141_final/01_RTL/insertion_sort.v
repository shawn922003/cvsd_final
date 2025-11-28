//   i_data1_0 <= i_data1_1 <= i_data1_2 <= i_data1_3
//   i_data2_0 <= i_data2_1
module insertion_sort (
    input  [9:0] i_data1_0,
    input  [9:0] i_data1_1,
    input  [9:0] i_data1_2,
    input  [9:0] i_data1_3,
    input  [9:0] i_data2_0,
    input  [9:0] i_data2_1,
    output [9:0] o_data_0,
    output [9:0] o_data_1,
    output [9:0] o_data_2,
    output [9:0] o_data_3,
    output [9:0] o_data_4,
    output [9:0] o_data_5
);

    // layer0: 插入 i_data2_0 到 4 個 sorted input -> 5 個數
    wire [9:0] layer0_0;
    wire [9:0] layer0_1;
    wire [9:0] layer0_2;
    wire [9:0] layer0_3;
    wire [9:0] layer0_4;
    wire [3:0] layer0_bigger;

    assign layer0_bigger[0] = (i_data2_0 < i_data1_0);
    assign layer0_bigger[1] = (i_data2_0 < i_data1_1);
    assign layer0_bigger[2] = (i_data2_0 < i_data1_2);
    assign layer0_bigger[3] = (i_data2_0 < i_data1_3);

    assign layer0_0 = (layer0_bigger[0] ? i_data2_0 : i_data1_0);
    assign layer0_1 = (layer0_bigger[0] ? i_data1_0 : (layer0_bigger[1] ? i_data2_0 : i_data1_1));
    assign layer0_2 = (layer0_bigger[1] ? i_data1_1 : (layer0_bigger[2] ? i_data2_0 : i_data1_2));
    assign layer0_3 = (layer0_bigger[2] ? i_data1_2 : (layer0_bigger[3] ? i_data2_0 : i_data1_3));
    assign layer0_4 = (layer0_bigger[3] ? i_data1_3 : i_data2_0);

    // layer1: 再把 i_data2_1 插入 layer0_0~4 -> 6 個數
    wire [4:0] layer1_bigger;

    assign layer1_bigger[0] = (i_data2_1 < layer0_0);
    assign layer1_bigger[1] = (i_data2_1 < layer0_1);
    assign layer1_bigger[2] = (i_data2_1 < layer0_2);
    assign layer1_bigger[3] = (i_data2_1 < layer0_3);
    assign layer1_bigger[4] = (i_data2_1 < layer0_4);

    assign o_data_0 = (layer1_bigger[0] ? i_data2_1 : layer0_0);
    assign o_data_1 = (layer1_bigger[0] ? layer0_0 : (layer1_bigger[1] ? i_data2_1 : layer0_1));
    assign o_data_2 = (layer1_bigger[1] ? layer0_1 : (layer1_bigger[2] ? i_data2_1 : layer0_2));
    assign o_data_3 = (layer1_bigger[2] ? layer0_2 : (layer1_bigger[3] ? i_data2_1 : layer0_3));
    assign o_data_4 = (layer1_bigger[3] ? layer0_3 : (layer1_bigger[4] ? i_data2_1 : layer0_4));
    assign o_data_5 = (layer1_bigger[4] ? layer0_4 : i_data2_1);

endmodule
