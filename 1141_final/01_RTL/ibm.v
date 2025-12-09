module ibm(
    input i_clk,
    input i_rst_n,

    input i_mode,
    input [1:0] i_code,
    input i_clear_and_wen,

    input i_early_stop,

    input [9:0] i_S1,
    input [9:0] i_S2,
    input [9:0] i_S3,
    input [9:0] i_S4,
    input [9:0] i_S5,
    input [9:0] i_S6,
    input [9:0] i_S7,
    input [9:0] i_S8,

    output [9:0] o_sigma1_0,
    output [9:0] o_sigma1_1,
    output [9:0] o_sigma1_2,
    output [9:0] o_sigma1_3,
    output [9:0] o_sigma1_4,
    output [3:0] o_degree1,
    output reg o_correct1,

    output [9:0] o_sigma2_0,
    output [9:0] o_sigma2_1,
    output [9:0] o_sigma2_2,
    output [3:0] o_degree2,
    output reg o_correct2,

    output o_valid,
    output reg o_next_S
);

    wire pe7_12_active;
    wire pe13_active;
    wire control2_active;
    wire single_double; // 0: single, 1: double

    wire [9:0] pe_phi_i_out[0:13];
    wire [9:0] pe_psi_i_out[0:13];
    wire [9:0] pe_phi_0_out[0:13];
    wire [9:0] pe_psi_0_out[0:13];
    wire [9:0] pe_phi_reg_out[0:13];
    wire mc1, mc2;

    wire all_cen;

    reg [3:0] counter, counter_next;
    reg first, first_next;

    reg valid;
    
    wire o_valid_internal;

    wire [3:0] control1_degree;
    wire [3:0] control2_degree;

    assign pe7_12_active = i_mode == 1'b1 || i_code == 2'b10;
    assign pe13_active = i_mode == 1'b1 && i_code != 2'b10; 
    assign control2_active = i_mode == 1'b1 && i_code != 2'b10; 
    assign single_double = i_code != 2'b10;

    assign all_cen = i_clear_and_wen || (i_code == 2'b10 && counter < 3'd7) || (i_code != 2'b10 && counter < 3'd3);

    assign o_valid = o_valid_internal & ~i_early_stop;

    assign o_degree1 = control1_degree;
    assign o_degree2 = control2_degree;

    delay_n #(
        .N(1),
        .BITS(1)
    ) delay_valid (
        .i_clk (i_clk),
        .i_rst_n(i_rst_n),
        .i_en  (1'b1),
        .i_d   (valid),
        .o_q   (o_valid_internal)
    );

    // PE0 to PE6 initialization
    ibm_pe u_pe0 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(pe_phi_i_out[1]),
        .i_phi_0(pe_phi_0_out[1]),
        .i_psi_i(pe_psi_i_out[1]),
        .i_psi_0(pe_psi_0_out[1]),

        .i_mc(mc1),

        .i_gen(1'b1),

        .i_phi_init(i_S1),
        .i_psi_init(10'b1),

        .o_phi_i(pe_phi_i_out[0]),
        .o_phi_0(pe_phi_0_out[0]),
        .o_psi_i(pe_psi_i_out[0]),
        .o_psi_0(pe_psi_0_out[0]),
        .o_phi_reg(pe_phi_reg_out[0])
    );

    ibm_pe u_pe1 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(pe_phi_i_out[2]),
        .i_phi_0(pe_phi_0_out[2]),
        .i_psi_i(pe_psi_i_out[2]),
        .i_psi_0(pe_psi_0_out[2]),

        .i_mc(mc1),

        .i_gen(1'b1),

        .i_phi_init(i_S2),
        .i_psi_init(10'b0),

        .o_phi_i(pe_phi_i_out[1]),
        .o_phi_0(pe_phi_0_out[1]),
        .o_psi_i(pe_psi_i_out[1]),
        .o_psi_0(pe_psi_0_out[1]),
        .o_phi_reg(pe_phi_reg_out[1])
    );

    ibm_pe u_pe2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(pe_phi_i_out[3]),
        .i_phi_0(pe_phi_0_out[3]),
        .i_psi_i(pe_psi_i_out[3]),
        .i_psi_0(pe_psi_0_out[3]),

        .i_mc(mc1),

        .i_gen(1'b1),

        .i_phi_init(i_S3),
        .i_psi_init(10'b0),

        .o_phi_i(pe_phi_i_out[2]),
        .o_phi_0(pe_phi_0_out[2]),
        .o_psi_i(pe_psi_i_out[2]),
        .o_psi_0(pe_psi_0_out[2]),
        .o_phi_reg(pe_phi_reg_out[2])
    );

    ibm_pe u_pe3 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(pe_phi_i_out[4]),
        .i_phi_0(pe_phi_0_out[4]),
        .i_psi_i(pe_psi_i_out[4]),
        .i_psi_0(pe_psi_0_out[4]),

        .i_mc(mc1),

        .i_gen(1'b1),

        .i_phi_init(i_S4),
        .i_psi_init(10'b0),

        .o_phi_i(pe_phi_i_out[3]),
        .o_phi_0(pe_phi_0_out[3]),
        .o_psi_i(pe_psi_i_out[3]),
        .o_psi_0(pe_psi_0_out[3]),
        .o_phi_reg(pe_phi_reg_out[3])
    );

    ibm_pe u_pe4 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(pe_phi_i_out[5]),
        .i_phi_0(pe_phi_0_out[5]),
        .i_psi_i(pe_psi_i_out[5]),
        .i_psi_0(pe_psi_0_out[5]),

        .i_mc(mc1),

        .i_gen(1'b1),

        .i_phi_init(single_double == 1'b1 ? 10'd0 : i_S5),
        .i_psi_init(10'b0),

        .o_phi_i(pe_phi_i_out[4]),
        .o_phi_0(pe_phi_0_out[4]),
        .o_psi_i(pe_psi_i_out[4]),
        .o_psi_0(pe_psi_0_out[4]),
        .o_phi_reg(pe_phi_reg_out[4])
    );

    ibm_pe u_pe5 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(pe_phi_i_out[6]),
        .i_phi_0(pe_phi_0_out[6]),
        .i_psi_i(pe_psi_i_out[6]),
        .i_psi_0(pe_psi_0_out[6]),

        .i_mc(mc1),

        .i_gen(1'b1),

        .i_phi_init(single_double == 1'b1 ? 10'd0 : i_S6),
        .i_psi_init(10'b0),

        .o_phi_i(pe_phi_i_out[5]),
        .o_phi_0(pe_phi_0_out[5]),
        .o_psi_i(pe_psi_i_out[5]),
        .o_psi_0(pe_psi_0_out[5]),
        .o_phi_reg(pe_phi_reg_out[5])
    );

    ibm_pe u_pe6 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(single_double == 1'b1 ? 10'd0 : pe_phi_i_out[7]),
        .i_phi_0(single_double == 1'b1 ? pe_phi_i_out[0] : pe_phi_0_out[7]),
        .i_psi_i(single_double == 1'b1 ? 10'd0 : pe_psi_i_out[7]),
        .i_psi_0(single_double == 1'b1 ? pe_psi_i_out[0] : pe_psi_0_out[7]),

        .i_mc(mc1),

        .i_gen(1'b1),

        .i_phi_init(single_double == 1'b1 ? 10'd1 : i_S7),
        .i_psi_init(10'd0),

        .o_phi_i(pe_phi_i_out[6]),
        .o_phi_0(pe_phi_0_out[6]),
        .o_psi_i(pe_psi_i_out[6]),
        .o_psi_0(pe_psi_0_out[6]),
        .o_phi_reg(pe_phi_reg_out[6])
    );

    // PE7 to PE12 initialization
    ibm_pe u_pe7 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(pe_phi_i_out[8]),
        .i_phi_0(pe_phi_0_out[8]),
        .i_psi_i(pe_psi_i_out[8]),
        .i_psi_0(pe_psi_0_out[8]),

        .i_mc(single_double == 1'b1 ? mc2 : mc1),

        .i_gen(pe7_12_active),

        .i_phi_init(single_double == 1'b1 ? i_S5 : i_S8),
        .i_psi_init(single_double == 1'b1 ? 10'd1 : 10'd0),

        .o_phi_i(pe_phi_i_out[7]),
        .o_phi_0(pe_phi_0_out[7]),
        .o_psi_i(pe_psi_i_out[7]),
        .o_psi_0(pe_psi_0_out[7]),
        .o_phi_reg(pe_phi_reg_out[7])
    );

    ibm_pe u_pe8 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(pe_phi_i_out[9]),
        .i_phi_0(pe_phi_0_out[9]),
        .i_psi_i(pe_psi_i_out[9]),
        .i_psi_0(pe_psi_0_out[9]),

        .i_mc(single_double == 1'b1 ? mc2 : mc1),

        .i_gen(pe7_12_active),

        .i_phi_init(single_double == 1'b1 ? i_S6 : 10'd0),
        .i_psi_init(10'd0),

        .o_phi_i(pe_phi_i_out[8]),
        .o_phi_0(pe_phi_0_out[8]),
        .o_psi_i(pe_psi_i_out[8]),
        .o_psi_0(pe_psi_0_out[8]),
        .o_phi_reg(pe_phi_reg_out[8])
    );

    ibm_pe u_pe9 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(pe_phi_i_out[10]),
        .i_phi_0(pe_phi_0_out[10]),
        .i_psi_i(pe_psi_i_out[10]),
        .i_psi_0(pe_psi_0_out[10]),

        .i_mc(single_double == 1'b1 ? mc2 : mc1),

        .i_gen(pe7_12_active),

        .i_phi_init(single_double == 1'b1 ? i_S7 : 10'd0),
        .i_psi_init(10'd0),

        .o_phi_i(pe_phi_i_out[9]),
        .o_phi_0(pe_phi_0_out[9]),
        .o_psi_i(pe_psi_i_out[9]),
        .o_psi_0(pe_psi_0_out[9]),
        .o_phi_reg(pe_phi_reg_out[9])
    );

    ibm_pe u_pe10 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(pe_phi_i_out[11]),
        .i_phi_0(pe_phi_0_out[11]),
        .i_psi_i(pe_psi_i_out[11]),
        .i_psi_0(pe_psi_0_out[11]),

        .i_mc(single_double == 1'b1 ? mc2 : mc1),

        .i_gen(pe7_12_active),

        .i_phi_init(single_double == 1'b1 ? i_S8 : 10'd0),
        .i_psi_init(10'd0),

        .o_phi_i(pe_phi_i_out[10]),
        .o_phi_0(pe_phi_0_out[10]),
        .o_psi_i(pe_psi_i_out[10]),
        .o_psi_0(pe_psi_0_out[10]),
        .o_phi_reg(pe_phi_reg_out[10])
    );

    ibm_pe u_pe11 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(pe_phi_i_out[12]),
        .i_phi_0(pe_phi_0_out[12]),
        .i_psi_i(pe_psi_i_out[12]),
        .i_psi_0(pe_psi_0_out[12]),

        .i_mc(single_double == 1'b1 ? mc2 : mc1),

        .i_gen(pe7_12_active),

        .i_phi_init(10'd0),
        .i_psi_init(10'd0),

        .o_phi_i(pe_phi_i_out[11]),
        .o_phi_0(pe_phi_0_out[11]),
        .o_psi_i(pe_psi_i_out[11]),
        .o_psi_0(pe_psi_0_out[11]),
        .o_phi_reg(pe_phi_reg_out[11])
    );

    ibm_pe u_pe12 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(single_double == 1'b1 ? pe_phi_i_out[13] : 10'd0),
        .i_phi_0(single_double == 1'b1 ? pe_phi_0_out[13] : pe_phi_i_out[0]),
        .i_psi_i(single_double == 1'b1 ? pe_psi_i_out[13] : 10'd0),
        .i_psi_0(single_double == 1'b1 ? pe_psi_0_out[13] : pe_psi_i_out[0]),

        .i_mc(single_double == 1'b1 ? mc2 : mc1),

        .i_gen(pe7_12_active),

        .i_phi_init(single_double == 1'b1 ? 10'd0 : 10'd1),
        .i_psi_init(10'd0),

        .o_phi_i(pe_phi_i_out[12]),
        .o_phi_0(pe_phi_0_out[12]),
        .o_psi_i(pe_psi_i_out[12]),
        .o_psi_0(pe_psi_0_out[12]),
        .o_phi_reg(pe_phi_reg_out[12])
    );



    // PE13 initialization
    ibm_pe u_pe13 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),

        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_phi_i(10'd0),
        .i_phi_0(pe_phi_i_out[7]),
        .i_psi_i(10'd0),
        .i_psi_0(pe_psi_i_out[7]),

        .i_mc(mc2),

        .i_gen(pe13_active),

        .i_phi_init(10'd1),
        .i_psi_init(10'd0),

        .o_phi_i(pe_phi_i_out[13]),
        .o_phi_0(pe_phi_0_out[13]),
        .o_psi_i(pe_psi_i_out[13]),
        .o_psi_0(pe_psi_0_out[13]),
        .o_phi_reg(pe_phi_reg_out[13])
    );

    // Control Unit 1
    ibm_control u_control1 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_gen(1'b1),

        .i_phi_0(pe_phi_i_out[0]),

        .o_mc(mc1),
        .o_num_degree(control1_degree)
    );

    // Control Unit 2
    ibm_control u_control2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_code(i_code),

        .i_init(i_clear_and_wen),
        .i_cen(all_cen),

        .i_gen(control2_active),

        .i_phi_0(pe_phi_i_out[7]),

        .o_mc(mc2),
        .o_num_degree(control2_degree)
    );

    assign o_sigma1_0 = i_code == 2'b10 ? pe_phi_reg_out[4] : pe_phi_reg_out[2];
    assign o_sigma1_1 = i_code == 2'b10 ? pe_phi_reg_out[5] : pe_phi_reg_out[3];
    assign o_sigma1_2 = i_code == 2'b10 ? pe_phi_reg_out[6] : pe_phi_reg_out[4];
    assign o_sigma1_3 = pe_phi_reg_out[7];
    assign o_sigma1_4 = pe_phi_reg_out[8];
    assign o_sigma2_0 = pe_phi_reg_out[9];
    assign o_sigma2_1 = pe_phi_reg_out[10];
    assign o_sigma2_2 = pe_phi_reg_out[11];

    // always @(posedge i_clk) begin
    //     if (!i_rst_n) begin
    //         first <= 1'b1;
    //     end
    //     else begin
    //         first <= first_next;
    //     end
    // end


    // always @(*) begin
    //     if (i_clear_and_wen) begin
    //         first_next = 1'b0;
    //     end
    //     else begin
    //         first_next = first;
    //     end
    // end

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            counter <= 4'd15;
        end
        else begin
            counter <= counter_next;
        end
    end

    always @(*) begin
        if (i_early_stop) begin
            counter_next = 4'd15;
        end
        else if (i_clear_and_wen) begin
            counter_next = 4'd0;
        end
        else if (counter < 4'd15) begin
            counter_next = counter + 4'd1;
        end
        else begin
            counter_next = counter;
        end
    end

    always @(*) begin
        if (i_code == 2'b10) begin
            o_next_S = counter == 4'd6 && !i_early_stop;
            valid = counter == 4'd6 && !i_early_stop;
        end
        else begin
            o_next_S = counter == 4'd2 && !i_early_stop;
            valid = counter == 4'd2 && !i_early_stop;
        end
    end
    

    always @(*) begin
        if (i_code == 2'b10) begin
            o_correct1 = (o_degree1 <= 4'd4);
        end
        else begin
            o_correct1 = (o_degree1 <= 4'd2);
        end

        if (i_code == 2'b10) begin
            o_correct2 = (o_degree2 <= 4'd4);
        end
        else begin
            o_correct2 = (o_degree2 <= 4'd2);
        end
    end

endmodule


module ibm_pe(
    input i_clk,
    input i_rst_n,

    input [1:0] i_code,

    input i_init,
    input i_cen,

    input [9:0] i_phi_i,
    input [9:0] i_phi_0,
    input [9:0] i_psi_i,
    input [9:0] i_psi_0,

    input i_mc,

    input i_gen,

    input [9:0] i_phi_init,
    input [9:0] i_psi_init,

    output [9:0] o_phi_i,
    output [9:0] o_phi_0,
    output [9:0] o_psi_i,
    output [9:0] o_psi_0,

    output [9:0] o_phi_reg
);

    reg [9:0] phi_reg, psi_reg;
    wire [9:0] phi_next, psi_next;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            phi_reg <= 10'd0;
            psi_reg <= 10'd0;
        end
        else begin
            phi_reg <= i_gen ? phi_next : phi_reg;
            psi_reg <= i_gen ? psi_next : psi_reg;
        end
    end

    wire [9:0] phi_i_psi_0;
    wire [9:0] psi_i_phi_0;
    wire [9:0] mul_add_all;

    gf_mult u_gf_mult_phi_i_psi_0 (
        .i_a(i_phi_i),
        .i_b(i_psi_0),
        .i_code(i_code),
        .o_product(phi_i_psi_0)
    );

    gf_mult u_gf_mult_psi_i_phi_0 (
        .i_a(i_psi_i),
        .i_b(i_phi_0),
        .i_code(i_code),
        .o_product(psi_i_phi_0)
    );

    assign mul_add_all = phi_i_psi_0 ^ psi_i_phi_0;

    assign phi_next = i_cen ? mul_add_all : phi_reg;
    assign psi_next = i_cen ? (i_mc ? o_phi_i : o_psi_i) : psi_reg;

    assign o_phi_i = i_init ? i_phi_init : phi_reg;
    assign o_psi_i = i_init ? i_psi_init : psi_reg;

    assign o_phi_0 = i_phi_0;
    assign o_psi_0 = i_psi_0;

    assign o_phi_reg = phi_reg;
endmodule

module ibm_control(
    input i_clk,
    input i_rst_n,
    input [1:0] i_code,

    input i_init,
    input i_cen,

    input i_gen,

    input [9:0] i_phi_0,

    output o_mc,
    output reg [3:0] o_num_degree
);

    wire phi_or;

    reg [3:0] l_reg, l_reg_next;

    assign phi_or = |i_phi_0;
    assign o_mc = phi_or & (i_init ? 1'b1: !l_reg[3]);

    always @(*) begin
        if (i_code == 2'b10) begin
            o_num_degree = (8 - $signed(l_reg)) >>> 1;
        end
        else begin
            o_num_degree = (4 - $signed(l_reg)) >>> 1;
        end
    end

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            l_reg <= 4'd0;
        end
        else begin
            l_reg <= i_gen ? l_reg_next : l_reg;
        end
    end

    always @(*) begin
        if (i_init) begin
            if (o_mc) begin
                l_reg_next = 4'b1111;
            end
            else begin
                l_reg_next =  4'd1;
            end
        end
        else if (i_cen) begin
            if (o_mc) begin
                l_reg_next = ~l_reg;
            end
            else begin
                l_reg_next = l_reg + 4'd1;
            end
        end
        else begin
            l_reg_next = l_reg;
        end
    end


endmodule