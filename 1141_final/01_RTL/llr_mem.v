module llr_mem(
    input i_clk,
    input i_rst_n,

    input i_wen,
    input [63:0] i_data,

    input [9:0] i_pos0,
    input [9:0] i_pos1,
    input [9:0] i_pos2,
    input [9:0] i_pos3,
    input [9:0] i_pos4,
    input [9:0] i_pos5,

    output reg [6:0] o_data0,
    output reg [6:0] o_data1,
    output reg [6:0] o_data2,
    output reg [6:0] o_data3,
    output reg [6:0] o_data4,
    output reg [6:0] o_data5
);
    reg [6:0] mem[0:1023];
    reg [6:0] mem_next[0:1023];

    integer i;
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            for (i = 0; i < 1024; i = i + 1) begin
                mem[i] <= 7'd0;
            end
        end else begin
            for (i = 0; i < 1024; i = i + 1) begin
                mem[i] <= mem_next[i];
            end
        end
    end


    always @(*) begin
        if (i_wen) begin
            mem_next[0] = i_data[7] ? -i_data[6:0] : i_data[6:0];
            mem_next[1] = i_data[15] ? -i_data[14:8] : i_data[14:8];
            mem_next[2] = i_data[23] ? -i_data[22:16] : i_data[22:16];
            mem_next[3] = i_data[31] ? -i_data[30:24] : i_data[30:24];
            mem_next[4] = i_data[39] ? -i_data[38:32] : i_data[38:32];
            mem_next[5] = i_data[47] ? -i_data[46:40] : i_data[46:40];
            mem_next[6] = i_data[55] ? -i_data[54:48] : i_data[54:48];
            mem_next[7] = i_data[63] ? -i_data[62:56] : i_data[62:56];

            for (i = 8; i < 1024; i = i + 1) begin
                mem_next[i] = mem[i - 8];
            end
        end
        else begin
            for (i = 0; i < 1024; i = i + 1) begin
                mem_next[i] = mem[i];
            end
        end
    end

    always @(*) begin
        o_data0 = mem[i_pos0];
        o_data1 = mem[i_pos1];
        o_data2 = mem[i_pos2];
        o_data3 = mem[i_pos3];
        o_data4 = mem[i_pos4];
        o_data5 = mem[i_pos5];

    end

endmodule