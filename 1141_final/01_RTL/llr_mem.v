module llr_mem(
    input i_clk,
    input i_rst_n,
    input [1:0] i_code,

    input i_wen,
    input [63:0] i_data,

    input i_right_rotate128,

    input [6:0] i_pos0,
    input [6:0] i_pos1,
    input [6:0] i_pos2,
    input [6:0] i_pos3,

    output [6:0] o_data0,
    output [6:0] o_data1,
    output [6:0] o_data2,
    output [6:0] o_data3
);
    reg [6:0] mem[0:1023];
    reg [6:0] mem_next[0:1023];

    reg [6:0] data;

    wire [6:0] mem_front[0:127];

    reg [6:0] data0;
    reg [6:0] data1;
    reg [6:0] data2;
    reg [6:0] data3;

    delay_n #(
        .N(1),
        .BITS(7)
    ) delay_data0 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(data0),
        .o_q(o_data0)
    );

    delay_n #(
        .N(1),
        .BITS(7)
    ) delay_data1 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(data1),
        .o_q(o_data1)
    );

    delay_n #(
        .N(1),
        .BITS(7)
    ) delay_data2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(data2),
        .o_q(o_data2)
    );

    delay_n #(
        .N(1),
        .BITS(7)
    ) delay_data3 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(data3),
        .o_q(o_data3)
    );


    genvar idx;
    generate
        for (idx = 0; idx < 128; idx = idx + 1) begin : gen_mem_front
            assign mem_front[idx] = mem[idx];
        end
    endgenerate

    
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

            case (i_code)
                2'd0: begin
                    for (i = 8; i < 64; i = i + 1) begin
                        mem_next[i] = mem[i - 8];
                    end
                    for (i = 64; i < 1024; i = i + 1) begin
                        mem_next[i] = mem[i];
                    end
                end
                2'd1: begin
                    for (i = 8; i < 256; i = i + 1) begin
                        mem_next[i] = mem[i - 8];
                    end
                    for (i = 256; i < 1024; i = i + 1) begin
                        mem_next[i] = mem[i];
                    end
                end
                2'd2: begin
                    for (i = 8; i < 1024; i = i + 1) begin
                        mem_next[i] = mem[i - 8];
                    end
                end
                default: begin
                    for (i = 8; i < 1024; i = i + 1) begin
                        mem_next[i] = mem[i];
                    end
                end
            endcase
        end
        else if (i_right_rotate128) begin
            case (i_code)
                2'd1: begin
                    for (i = 0; i < 128; i = i + 1) begin
                        mem_next[i] = mem[i + 128];
                        mem_next[i + 128] = mem[i];
                    end
                    for (i = 256; i < 1024; i = i + 1) begin
                        mem_next[i] = mem[i];
                    end
                end
                2'd2: begin
                    for (i = 0; i < 1024 - 128; i = i + 1) begin
                        mem_next[i] = mem[i + 128];
                    end
                    for (i = 1024 - 128; i < 1024; i = i + 1) begin
                        mem_next[i] = mem[i - (1024 - 128)];
                    end
                end
                default: begin
                    for (i = 0; i < 1024; i = i + 1) begin
                        mem_next[i] = mem[i];
                    end
                end
            endcase
        end
        else begin
            for (i = 0; i < 1024; i = i + 1) begin
                mem_next[i] = mem[i];
            end
        end
    end

    always @(*) begin
        data0 = mem_front[i_pos0];
        data1 = mem_front[i_pos1];
        data2 = mem_front[i_pos2];
        data3 = mem_front[i_pos3];
    end

endmodule