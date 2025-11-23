module llr_mem(
    input i_clk,
    input i_rst_n,

    input i_wen,
    input [63:0] i_data,

    input [9:0] i_pos,
    output [7:0] o_data
);
    reg [7:0] mem[0:1023];
    reg [7:0] mem_next[0:1023];

    integer i;
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            for (i = 0; i < 1024; i = i + 1) begin
                mem[i] <= 8'd0;
            end
        end else begin
            for (i = 0; i < 1024; i = i + 1) begin
                mem[i] <= mem_next[i];
            end
        end
    end


    always @(*) begin
        if (i_wen) begin
            mem_next[0] = i_data[7:0];
            mem_next[1] = i_data[15:8];
            mem_next[2] = i_data[23:16];
            mem_next[3] = i_data[31:24];
            mem_next[4] = i_data[39:32];
            mem_next[5] = i_data[47:40];
            mem_next[6] = i_data[55:48];
            mem_next[7] = i_data[63:56];

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
        o_data = mem[i_pos];
    end

endmodule