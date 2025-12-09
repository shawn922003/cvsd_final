module chien_search(
    input i_clk,
    input i_rst_n,

    input i_mode,
    input  [1:0] i_code, 
    input        i_clear_and_wen,

    input i_early_stop,

    input [9:0] i_sigma1_0,
    input [9:0] i_sigma1_1,
    input [9:0] i_sigma1_2,
    input [9:0] i_sigma1_3,
    input [9:0] i_sigma1_4,
    input [3:0] i_degree1,
    input i_correct1,
    input [9:0] i_sigma2_0,
    input [9:0] i_sigma2_1,
    input [9:0] i_sigma2_2,
    input [3:0] i_degree2,
    input i_correct2,

    output [9:0] o_err_loc0,
    output [9:0] o_err_loc1,
    output [9:0] o_err_loc2,
    output [9:0] o_err_loc3,
    output [2:0] o_num_err,
    output reg o_correct,
    
    output reg o_err_valid,

    output [8:0] o_llr_sum,
    output o_llr_sum_valid,

    // interaction with llr_mem
    output [6:0] o_llr_mem_pos0,
    output [6:0] o_llr_mem_pos1,
    output [6:0] o_llr_mem_pos2,
    output [6:0] o_llr_mem_pos3,
    output reg o_llr_mem_rotate128,

    input [6:0] i_llr_mem_pos_llr0,
    input [6:0] i_llr_mem_pos_llr1,
    input [6:0] i_llr_mem_pos_llr2,
    input [6:0] i_llr_mem_pos_llr3
);

    localparam m8_alpha_n128 = 10'b0011001100; // alpha^(-128) = alpha^(127)
    localparam m8_alpha_n256 = 10'b0010001110; // alpha^(-256) = alpha^(254)
    localparam m10_alpha_n128 = 10'b0101001001; // alpha^(-128) = alpha^(895)
    localparam m10_alpha_n256 = 10'b1000100101; // alpha^(-256) = alpha^(767)
    localparam m10_alpha_n384 = 10'b1010010011; // alpha^(-384) = alpha^(639)
    localparam m10_alpha_n512 = 10'b0100001010; // alpha^(-512) = alpha^(511)

    wire sigma2_gen;
    assign sigma2_gen = i_mode == 1'b1 && i_code != 2'b10;

    wire llr_gen;
    assign llr_gen = i_mode == 1'b1;


    reg [9:0] sigma0;
    reg [9:0] sigma_alpha1;
    reg [9:0] sigma_alpha2;
    reg [9:0] sigma_alpha3;
    reg [9:0] sigma_alpha4;
    wire [127:0] is_root;

    reg [127:0] root_mask;

    wire [127:0] is_root_reg;

    

    reg [9:0] sigma_alpha_multiplier1;
    reg [9:0] sigma_alpha_multiplier2;
    reg [9:0] sigma_alpha_multiplier3;
    reg [9:0] sigma_alpha_multiplier4;

    wire [9:0] sigma_alpha_product1;
    wire [9:0] sigma_alpha_product2;
    wire [9:0] sigma_alpha_product3;
    wire [9:0] sigma_alpha_product4;

    wire [9:0] sigma_alpha_product1_reg;
    wire [9:0] sigma_alpha_product2_reg;
    wire [9:0] sigma_alpha_product3_reg;
    wire [9:0] sigma_alpha_product4_reg;


    reg [9:0] sigma1_0_buf, sigma1_0_buf_next;
    reg [9:0] sigma2_0_buf, sigma2_0_buf_next;
    reg [9:0] sigma2_1_buf, sigma2_1_buf_next;
    reg [9:0] sigma2_2_buf, sigma2_2_buf_next;

    reg [9:0] err_loc0_buf;
    wire [9:0] err_loc0_buf_next;
    reg [9:0] err_loc1_buf;
    wire [9:0] err_loc1_buf_next;
    reg [9:0] err_loc2_buf;
    wire [9:0] err_loc2_buf_next;
    reg [9:0] err_loc3_buf;
    wire [9:0] err_loc3_buf_next;
    reg [2:0] num_err_buf;
    wire [2:0] num_err_buf_next;

    reg [9:0] exist_err_loc0;
    reg [9:0] exist_err_loc1;
    reg [9:0] exist_err_loc2;
    reg [9:0] exist_err_loc3;
    reg [2:0] exist_num_err;

    wire [6:0] find_1_idx_0_out;
    wire [6:0] find_1_idx_1_out;
    wire [6:0] find_1_idx_2_out;
    wire [6:0] find_1_idx_3_out;
    wire [2:0] find_1_idx_num_out;

    wire [6:0] find_1_idx_0_out_dly;
    wire [6:0] find_1_idx_1_out_dly;
    wire [6:0] find_1_idx_2_out_dly;
    wire [6:0] find_1_idx_3_out_dly;
    wire [2:0] find_1_idx_num_out_dly1;
    wire [2:0] find_1_idx_num_out_dly2;

    reg [9:0] find_1_idx_0_adptive;
    reg [9:0] find_1_idx_1_adptive;
    reg [9:0] find_1_idx_2_adptive;
    reg [9:0] find_1_idx_3_adptive;

    reg [2:0] num_S_degree1_1, num_S_degree1_1_next; // for chien search pe stage
    reg [2:0] num_S_degree1_2, num_S_degree1_2_next; // for chien search pe stage

    wire [2:0] num_S_degree2_1; // for find 1 idx stage
    wire [2:0] num_S_degree2_2; // for find 1 idx stage

    reg [3:0] counter_pe, counter_pe_next;

    wire [3:0] counter_find_1_idx_pipe1;
    wire [3:0] counter_find_1_idx_pipe2;

    reg [9:0] llr_sum, llr_sum_next;

    wire o_llr_sum_valid_internal;

    reg correct1_1, correct1_2;
    reg correct1_1_next, correct1_2_next;
    wire correct2_1;
    wire correct2_2;
    


    assign o_llr_sum_valid = o_llr_sum_valid_internal & ~i_early_stop;

    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin : GEN_PE
            chien_search_pe #(
                .ALPHA_BASE(i)
            ) u_chien_search_pe (
                .i_code(i_code),

                .i_sigma0(sigma0),
                .i_sigma_alpha1(sigma_alpha1),
                .i_sigma_alpha2(sigma_alpha2),
                .i_sigma_alpha3(sigma_alpha3),
                .i_sigma_alpha4(sigma_alpha4),

                .o_is_root(is_root[i])
            );
        end
    endgenerate




    gf_mult u_gf_mult1 (
        .i_a(sigma_alpha1),
        .i_b(sigma_alpha_multiplier1),
        .i_code(i_code),
        .o_product(sigma_alpha_product1)
    );

    gf_mult u_gf_mult2 (
        .i_a(sigma_alpha2),
        .i_b(sigma_alpha_multiplier2),
        .i_code(i_code),
        .o_product(sigma_alpha_product2)
    );

    gf_mult u_gf_mult3 (
        .i_a(sigma_alpha3),
        .i_b(sigma_alpha_multiplier3),
        .i_code(i_code),
        .o_product(sigma_alpha_product3)
    );

    gf_mult u_gf_mult4 (
        .i_a(sigma_alpha4),
        .i_b(sigma_alpha_multiplier4),
        .i_code(i_code),
        .o_product(sigma_alpha_product4)
    );

    delay_n #(
        .N(1),
        .BITS(10)
    ) u_delay_n_mult1 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(sigma_alpha_product1),
        .o_q(sigma_alpha_product1_reg)
    );

    delay_n #(
        .N(1),
        .BITS(10)
    ) u_delay_n_mult2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(sigma_alpha_product2),
        .o_q(sigma_alpha_product2_reg)
    );

    delay_n #(
        .N(1),
        .BITS(10)
    ) u_delay_n_mult3 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(sigma_alpha_product3),
        .o_q(sigma_alpha_product3_reg)
    );

    delay_n #(
        .N(1),
        .BITS(10)
    ) u_delay_n_mult4 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(sigma_alpha_product4),
        .o_q(sigma_alpha_product4_reg)
    );


    delay_n #(
        .N(1),
        .BITS(128)
    ) u_delay_n_is_root (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(is_root & root_mask),
        .o_q(is_root_reg)
    );


    find_1_idx u_find_1_idx (
        .i_data(is_root_reg),

        .o_idx1(find_1_idx_0_out),
        .o_idx2(find_1_idx_1_out),
        .o_idx3(find_1_idx_2_out),
        .o_idx4(find_1_idx_3_out),
        .o_num_found(find_1_idx_num_out)
    );


    merge_idx #(
        .WIDTH(11),
        .IS_SHIFTED(1'b0)
    ) u_merge_idx0 (
        .i_idx1_1 ( exist_err_loc0 ),
        .i_idx1_2 ( exist_err_loc1 ),
        .i_idx1_3 ( exist_err_loc2 ),
        .i_idx1_4 ( exist_err_loc3 ),
        .i_num1   ( exist_num_err ),

        .i_idx2_1 ( find_1_idx_0_adptive ),
        .i_idx2_2 ( find_1_idx_1_adptive ),
        .i_idx2_3 ( find_1_idx_2_adptive ),
        .i_idx2_4 ( find_1_idx_3_adptive ),
        .i_num2   ( find_1_idx_num_out_dly1 ),

        .o_idx1   ( err_loc0_buf_next ),
        .o_idx2   ( err_loc1_buf_next ),
        .o_idx3   ( err_loc2_buf_next ),
        .o_idx4   ( err_loc3_buf_next ),
        .o_num    ( num_err_buf_next )
    );


    delay_n #(
        .N(1),
        .BITS(4),
        .INIT(4'd15)
    ) u_delay_n_valid (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(counter_pe),
        .o_q(counter_find_1_idx_pipe1)
    );

    delay_n #(
        .N(1),
        .BITS(4),
        .INIT(4'd15)
    ) u_delay_n_valid_2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(counter_find_1_idx_pipe1),
        .o_q(counter_find_1_idx_pipe2)
    );


    delay_n #(
        .N(2),
        .BITS(3)
    ) u_delay_n_o_valid (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(num_S_degree1_1),
        .o_q(num_S_degree2_1)
    );


    delay_n #(
        .N(2),
        .BITS(3)
    ) u_delay_n_o_valid_2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(num_S_degree1_2),
        .o_q(num_S_degree2_2)
    );


    delay_n #(
        .N(2),
        .BITS(1)
    ) u_delay_correct1 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(correct1_1),
        .o_q(correct2_1)
    );

    delay_n #(
        .N(2),
        .BITS(1)
    ) u_delay_correct2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(correct1_2),
        .o_q(correct2_2)
    );


    delay_n #(
        .N(1),
        .BITS(7)
    ) u_delay_n_llr0 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(llr_gen),
        .i_d(find_1_idx_0_out),
        .o_q(o_llr_mem_pos0)
    );


    delay_n #(
        .N(1),
        .BITS(7)
    ) u_delay_n_llr1 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(llr_gen),
        .i_d(find_1_idx_1_out),
        .o_q(o_llr_mem_pos1)
    );

    delay_n #(
        .N(1),
        .BITS(7)
    ) u_delay_n_llr2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(llr_gen),
        .i_d(find_1_idx_2_out),
        .o_q(o_llr_mem_pos2)
    );

    delay_n #(
        .N(1),
        .BITS(7)
    ) u_delay_n_llr3 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(llr_gen),
        .i_d(find_1_idx_3_out),
        .o_q(o_llr_mem_pos3)
    );

    delay_n #(
        .N(1),
        .BITS(7)
    ) u_delay_n_find_1_idx_0_out (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(find_1_idx_0_out),
        .o_q(find_1_idx_0_out_dly)
    );

    delay_n #(
        .N(1),
        .BITS(7)
    ) u_delay_n_find_1_idx_1_out (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(find_1_idx_1_out),
        .o_q(find_1_idx_1_out_dly)
    );

    delay_n #(
        .N(1),
        .BITS(7)
    ) u_delay_n_find_1_idx_2_out (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(find_1_idx_2_out),
        .o_q(find_1_idx_2_out_dly)
    );

    delay_n #(
        .N(1),
        .BITS(7)
    ) u_delay_n_find_1_idx_3_out (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(find_1_idx_3_out),
        .o_q(find_1_idx_3_out_dly)
    );

    delay_n #(
        .N(1),
        .BITS(3)
    ) u_delay_n_find_1_idx_num_out (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(find_1_idx_num_out),
        .o_q(find_1_idx_num_out_dly1)
    );

    delay_n #(
        .N(1),
        .BITS(3)
    ) u_delay_n_find_1_idx_num_out_dly2 (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(1'b1),
        .i_d(find_1_idx_num_out_dly1),
        .o_q(find_1_idx_num_out_dly2)
    );


    delay_n #(
        .N(1),
        .BITS(1)
    ) delay_n_llr_sum_valid (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_en(llr_gen),
        .i_d(o_err_valid),
        .o_q(o_llr_sum_valid_internal)
    );


    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            counter_pe <= 4'd15;
        end 
        else begin
            counter_pe <= counter_pe_next;
        end
    end

    always @(*) begin
        if (i_early_stop) begin
            counter_pe_next = 4'd15;
        end
        else if (i_clear_and_wen) begin
            counter_pe_next = 4'd0;
        end
        else if (counter_pe < 4'd15) begin
            counter_pe_next = counter_pe + 4'd1;
        end
        else begin
            counter_pe_next = counter_pe;
        end
    end

    always @(*) begin
        case(i_code) // synopsys full_case
            2'd0: begin // (63,51)
                if (i_clear_and_wen) begin
                    sigma0 = i_sigma1_0;
                    sigma_alpha1 = i_sigma1_1;
                    sigma_alpha2 = i_sigma1_2;
                end
                else if (counter_pe == 4'd1 && sigma2_gen) begin
                    sigma0 = sigma2_0_buf;
                    sigma_alpha1 = sigma2_1_buf;
                    sigma_alpha2 = sigma2_2_buf;
                end
                else begin
                    sigma0 = 10'd1;
                    sigma_alpha1 = 10'd1;
                    sigma_alpha2 = 10'd1;
                end

                sigma_alpha3 = 10'd0;
                sigma_alpha4 = 10'd0;
            end
            2'd1: begin // (255,239)
                if (i_clear_and_wen) begin
                    sigma0 = i_sigma1_0;
                    sigma_alpha1 = i_sigma1_1;
                    sigma_alpha2 = i_sigma1_2;
                end
                else if (counter_pe == 4'd0) begin
                    sigma0 = sigma1_0_buf;
                    sigma_alpha1 = sigma_alpha_product1_reg;
                    sigma_alpha2 = sigma_alpha_product2_reg;
                end
                else if (counter_pe == 4'd1 && sigma2_gen) begin
                    sigma0 = sigma2_0_buf;
                    sigma_alpha1 = sigma2_1_buf;
                    sigma_alpha2 = sigma2_2_buf;
                end
                else if (counter_pe == 4'd2 && sigma2_gen) begin
                    sigma0 = sigma2_0_buf;
                    sigma_alpha1 = sigma_alpha_product1_reg;
                    sigma_alpha2 = sigma_alpha_product2_reg;
                end
                else begin
                    sigma0 = 10'd1;
                    sigma_alpha1 = 10'd1;
                    sigma_alpha2 = 10'd1;
                end

                sigma_alpha3 = 10'd0;
                sigma_alpha4 = 10'd0;
            end
            2'd2: begin // (1023,983)
                if (i_clear_and_wen) begin
                    sigma0 = i_sigma1_0;
                    sigma_alpha1 = i_sigma1_1;
                    sigma_alpha2 = i_sigma1_2;
                    sigma_alpha3 = i_sigma1_3;
                    sigma_alpha4 = i_sigma1_4;
                end
                else begin
                    sigma0 = sigma1_0_buf;
                    sigma_alpha1 = sigma_alpha_product1_reg;
                    sigma_alpha2 = sigma_alpha_product2_reg;
                    sigma_alpha3 = sigma_alpha_product3_reg;
                    sigma_alpha4 = sigma_alpha_product4_reg;
                end
            end
        endcase

    end


    always @(*) begin
        // bch (63, 51) does not need to be implemented
        if (i_code == 2'b01) begin // bch (255, 239)
            sigma_alpha_multiplier1 = m8_alpha_n128;
            sigma_alpha_multiplier2 = m8_alpha_n256;
        end
        else begin // bch (1023, 983)
            sigma_alpha_multiplier1 = m10_alpha_n128;
            sigma_alpha_multiplier2 = m10_alpha_n256;

        end

        sigma_alpha_multiplier3 = m10_alpha_n384;
        sigma_alpha_multiplier4 = m10_alpha_n512;
    end


    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            sigma1_0_buf <= 10'd0;
            sigma2_0_buf <= 10'd0;
            sigma2_1_buf <= 10'd0;
            sigma2_2_buf <= 10'd0;
        end
        else begin
            sigma1_0_buf <= sigma1_0_buf_next;
            sigma2_0_buf <= sigma2_gen ? sigma2_0_buf_next : sigma2_0_buf;
            sigma2_1_buf <= sigma2_gen ? sigma2_1_buf_next : sigma2_1_buf;
            sigma2_2_buf <= sigma2_gen ? sigma2_2_buf_next : sigma2_2_buf;

        end
    end


    always @(*) begin
        if (i_clear_and_wen) begin
            sigma1_0_buf_next = i_sigma1_0;
            sigma2_0_buf_next = i_sigma2_0;
            sigma2_1_buf_next = i_sigma2_1;
            sigma2_2_buf_next = i_sigma2_2;
        end
        else begin
            sigma1_0_buf_next = sigma1_0_buf;
            sigma2_0_buf_next = sigma2_0_buf;
            sigma2_1_buf_next = sigma2_1_buf;
            sigma2_2_buf_next = sigma2_2_buf;
        end
    end

    always @(*) begin
        case(i_code) // synopsys full_case
            2'd0: begin // (63,51)
                root_mask[62:0] = {63{1'b1}};
                root_mask[127:63] = {65{1'b0}};
            end
            2'd1: begin // (255,239)
                root_mask[126:0] = {127{1'b1}};
                if (i_clear_and_wen) begin
                    root_mask[127] = 1'b1;
                end
                else if (counter_pe == 4'd0) begin
                    root_mask[127] = 1'b0;
                end
                else if (counter_pe == 4'd1) begin
                    root_mask[127] = 1'b1;
                end
                else if (counter_pe == 4'd2) begin
                    root_mask[127] = 1'b0;
                end
                else begin
                    root_mask[127] = 1'b1;
                end
            end
            2'd2: begin // (1023,983)
                root_mask[126:0] = {127{1'b1}};
                if (counter_pe == 4'd6) begin
                    root_mask[127] = 1'b0;
                end
                else begin
                    root_mask[127] = 1'b1;
                end
            end
        endcase

    end











    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            err_loc0_buf <= 10'd0;
            err_loc1_buf <= 10'd0;
            err_loc2_buf <= 10'd0;
            err_loc3_buf <= 10'd0;
            num_err_buf <= 3'd0;
        end
        else begin
            err_loc0_buf <= err_loc0_buf_next;
            err_loc1_buf <= err_loc1_buf_next;
            err_loc2_buf <= err_loc2_buf_next;
            err_loc3_buf <= err_loc3_buf_next;
            num_err_buf <= num_err_buf_next;
        end
    end

    always @(*) begin
        case(i_code) // synopsys full_case
            2'd0: begin // (63,51)
                exist_err_loc0 = 10'd0;
                exist_err_loc1 = 10'd0;
                exist_err_loc2 = 10'd0;
                exist_err_loc3 = 10'd0;
                exist_num_err = 3'd0;
            end
            2'd1: begin // (255,239)
                if (counter_find_1_idx_pipe1 == 4'd0) begin
                    exist_err_loc0 = 10'd0;
                    exist_err_loc1 = 10'd0;
                    exist_err_loc2 = 10'd0;
                    exist_err_loc3 = 10'd0;
                    exist_num_err = 3'd0;
                end
                else if (counter_find_1_idx_pipe1 == 4'd1) begin
                    exist_err_loc0 = err_loc0_buf;
                    exist_err_loc1 = err_loc1_buf;
                    exist_err_loc2 = err_loc2_buf;
                    exist_err_loc3 = err_loc3_buf;
                    exist_num_err = num_err_buf;
                end
                else if (counter_find_1_idx_pipe1 == 4'd2) begin
                    exist_err_loc0 = 10'd0;
                    exist_err_loc1 = 10'd0;
                    exist_err_loc2 = 10'd0;
                    exist_err_loc3 = 10'd0;
                    exist_num_err = 3'd0;
                end
                else if (counter_find_1_idx_pipe1 == 4'd3) begin
                    exist_err_loc0 = err_loc0_buf;
                    exist_err_loc1 = err_loc1_buf;
                    exist_err_loc2 = err_loc2_buf;
                    exist_err_loc3 = err_loc3_buf;
                    exist_num_err = num_err_buf;
                end
                else begin
                    exist_err_loc0 = 10'd0;
                    exist_err_loc1 = 10'd0;
                    exist_err_loc2 = 10'd0;
                    exist_err_loc3 = 10'd0;
                    exist_num_err = 3'd0;
                end
            end
            2'd2: begin // (1023,983)
                if (counter_find_1_idx_pipe1 == 4'd0) begin
                    exist_err_loc0 = 10'd0;
                    exist_err_loc1 = 10'd0;
                    exist_err_loc2 = 10'd0;
                    exist_err_loc3 = 10'd0;
                    exist_num_err = 3'd0;
                end
                else if (counter_find_1_idx_pipe1 >= 4'd1 && counter_find_1_idx_pipe1 <= 4'd7) begin
                    exist_err_loc0 = err_loc0_buf;
                    exist_err_loc1 = err_loc1_buf;
                    exist_err_loc2 = err_loc2_buf;
                    exist_err_loc3 = err_loc3_buf;
                    exist_num_err = num_err_buf;
                end
                else begin
                    exist_err_loc0 = 10'd0;
                    exist_err_loc1 = 10'd0;
                    exist_err_loc2 = 10'd0;
                    exist_err_loc3 = 10'd0;
                    exist_num_err = 3'd0;
                end
            end
        endcase
    end

    always @(*) begin
        // if find_1_idx has pipeline, counter_pe should be replaced by counter_find_1_idx_pipe
        case(i_code) // synopsys full_case
            2'd0: begin // (63,51)
                find_1_idx_0_adptive = {3'b000, find_1_idx_0_out_dly};
                find_1_idx_1_adptive = {3'b000, find_1_idx_1_out_dly};
                find_1_idx_2_adptive = {3'b000, find_1_idx_2_out_dly};
                find_1_idx_3_adptive = {3'b000, find_1_idx_3_out_dly};
            end
            2'd1: begin // (255,239)
                if (counter_find_1_idx_pipe1 == 4'd0) begin
                    find_1_idx_0_adptive = {3'b000, find_1_idx_0_out_dly};
                    find_1_idx_1_adptive = {3'b000, find_1_idx_1_out_dly};
                    find_1_idx_2_adptive = {3'b000, find_1_idx_2_out_dly};
                    find_1_idx_3_adptive = {3'b000, find_1_idx_3_out_dly};
                end
                else if (counter_find_1_idx_pipe1 == 4'd1) begin
                    find_1_idx_0_adptive = {3'b001, find_1_idx_0_out_dly};
                    find_1_idx_1_adptive = {3'b001, find_1_idx_1_out_dly};
                    find_1_idx_2_adptive = {3'b001, find_1_idx_2_out_dly};
                    find_1_idx_3_adptive = {3'b001, find_1_idx_3_out_dly};
                end
                else if (counter_find_1_idx_pipe1 == 4'd2) begin
                    find_1_idx_0_adptive = {3'b000, find_1_idx_0_out_dly};
                    find_1_idx_1_adptive = {3'b000, find_1_idx_1_out_dly};
                    find_1_idx_2_adptive = {3'b000, find_1_idx_2_out_dly};
                    find_1_idx_3_adptive = {3'b000, find_1_idx_3_out_dly};
                end
                else if (counter_find_1_idx_pipe1 == 4'd3) begin
                    find_1_idx_0_adptive = {3'b001, find_1_idx_0_out_dly};
                    find_1_idx_1_adptive = {3'b001, find_1_idx_1_out_dly};
                    find_1_idx_2_adptive = {3'b001, find_1_idx_2_out_dly};
                    find_1_idx_3_adptive = {3'b001, find_1_idx_3_out_dly};
                end
                else begin
                    find_1_idx_0_adptive = {3'b000, find_1_idx_0_out_dly};
                    find_1_idx_1_adptive = {3'b000, find_1_idx_1_out_dly};
                    find_1_idx_2_adptive = {3'b000, find_1_idx_2_out_dly};
                    find_1_idx_3_adptive = {3'b000, find_1_idx_3_out_dly};
                end
            end
            2'd2: begin // (1023,983)
                if (counter_find_1_idx_pipe1 <= 4'd7) begin
                    find_1_idx_0_adptive = {counter_find_1_idx_pipe1[2:0], find_1_idx_0_out_dly};
                    find_1_idx_1_adptive = {counter_find_1_idx_pipe1[2:0], find_1_idx_1_out_dly};
                    find_1_idx_2_adptive = {counter_find_1_idx_pipe1[2:0], find_1_idx_2_out_dly};
                    find_1_idx_3_adptive = {counter_find_1_idx_pipe1[2:0], find_1_idx_3_out_dly};
                end
                else begin
                    find_1_idx_0_adptive = {3'b000, find_1_idx_0_out_dly};
                    find_1_idx_1_adptive = {3'b000, find_1_idx_1_out_dly};
                    find_1_idx_2_adptive = {3'b000, find_1_idx_2_out_dly};
                    find_1_idx_3_adptive = {3'b000, find_1_idx_3_out_dly};
                end
            end
        endcase
    end




    assign o_llr_sum = llr_sum;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            llr_sum <= 9'd0;
        end
        else begin
            llr_sum <= llr_gen ? llr_sum_next : llr_sum;
        end
    end



    always @(*) begin
        case (i_code) // synopsys full_case
            2'd0: begin
                o_llr_mem_rotate128 = 1'b0;
                case (find_1_idx_num_out_dly2) 
                    3'd0: llr_sum_next = 9'd0;
                    3'd1: llr_sum_next = i_llr_mem_pos_llr0;
                    3'd2: llr_sum_next = i_llr_mem_pos_llr0 + i_llr_mem_pos_llr1;
                    default: llr_sum_next = 9'd0;
                endcase
            end
            2'd1: begin
                if (counter_find_1_idx_pipe1 <= 4'd3) begin
                    o_llr_mem_rotate128 = llr_gen;
                end
                else begin
                    o_llr_mem_rotate128 = 1'b0;
                end

                if (counter_find_1_idx_pipe2 == 4'd0) begin
                    case (find_1_idx_num_out_dly2) 
                        3'd0: llr_sum_next = 9'd0;
                        3'd1: llr_sum_next = i_llr_mem_pos_llr0;
                        3'd2: llr_sum_next = i_llr_mem_pos_llr0 + i_llr_mem_pos_llr1;
                        default: llr_sum_next = 9'd0;
                    endcase
                end
                else if (counter_find_1_idx_pipe2 == 4'd1) begin
                    case (find_1_idx_num_out_dly2) 
                        3'd0: llr_sum_next = llr_sum;
                        3'd1: llr_sum_next = i_llr_mem_pos_llr0 + llr_sum;
                        3'd2: llr_sum_next = i_llr_mem_pos_llr0 + i_llr_mem_pos_llr1;
                        default: llr_sum_next = 9'd0;
                    endcase
                end
                else if (counter_find_1_idx_pipe2 == 4'd2) begin
                    case (find_1_idx_num_out_dly2) 
                        3'd0: llr_sum_next = 9'd0;
                        3'd1: llr_sum_next = i_llr_mem_pos_llr0;
                        3'd2: llr_sum_next = i_llr_mem_pos_llr0 + i_llr_mem_pos_llr1;
                        default: llr_sum_next = 9'd0;
                    endcase
                end
                else if (counter_find_1_idx_pipe2 == 4'd3) begin
                    case (find_1_idx_num_out_dly2) 
                        3'd0: llr_sum_next = llr_sum;
                        3'd1: llr_sum_next = i_llr_mem_pos_llr0 + llr_sum;
                        3'd2: llr_sum_next = i_llr_mem_pos_llr0 + i_llr_mem_pos_llr1;
                        default: llr_sum_next = 9'd0;
                    endcase
                end
                else begin
                    llr_sum_next = 9'd0;
                end
            end
            2'd2: begin
                if (counter_find_1_idx_pipe1 <= 4'd7) begin
                    o_llr_mem_rotate128 = llr_gen;
                end
                else begin
                    o_llr_mem_rotate128 = 1'b0;
                end

                if (counter_find_1_idx_pipe2 == 4'd0) begin
                    case (find_1_idx_num_out_dly2) 
                        3'd0: llr_sum_next = 9'd0;
                        3'd1: llr_sum_next = i_llr_mem_pos_llr0;
                        3'd2: llr_sum_next = i_llr_mem_pos_llr0 + i_llr_mem_pos_llr1;
                        3'd3: llr_sum_next = i_llr_mem_pos_llr0 + i_llr_mem_pos_llr1 + i_llr_mem_pos_llr2;
                        3'd4: llr_sum_next = i_llr_mem_pos_llr0 + i_llr_mem_pos_llr1 + i_llr_mem_pos_llr2 + i_llr_mem_pos_llr3;
                        default: llr_sum_next = 9'd0;
                    endcase
                end
                else if (counter_find_1_idx_pipe2 >= 4'd1 && counter_find_1_idx_pipe2 <= 4'd7) begin
                    case (find_1_idx_num_out_dly2) 
                        3'd0: llr_sum_next = llr_sum;
                        3'd1: llr_sum_next = i_llr_mem_pos_llr0 + llr_sum;
                        3'd2: llr_sum_next = i_llr_mem_pos_llr0 + i_llr_mem_pos_llr1 + llr_sum;
                        3'd3: llr_sum_next = i_llr_mem_pos_llr0 + i_llr_mem_pos_llr1 + i_llr_mem_pos_llr2 + llr_sum;
                        3'd4: llr_sum_next = i_llr_mem_pos_llr0 + i_llr_mem_pos_llr1 + i_llr_mem_pos_llr2 + i_llr_mem_pos_llr3 + llr_sum;
                        default: llr_sum_next = 9'd0;
                    endcase
                end
                else begin
                    llr_sum_next = 9'd0;
                end
            end
        endcase
    end







    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            num_S_degree1_1 <= 3'd0;
            num_S_degree1_2 <= 3'd0;

            correct1_1 <= 1'b0;
            correct1_2 <= 1'b0;
        end
        else begin
            num_S_degree1_1 <= num_S_degree1_1_next;
            num_S_degree1_2 <= num_S_degree1_2_next;

            correct1_1 <= correct1_1_next;
            correct1_2 <= correct1_2_next;
        end
    end

    always @(*) begin
        if (i_clear_and_wen) begin
            // if (i_sigma1_4 != 10'd0 && i_code == 2'b10) begin
            //     num_S_degree1_1_next = 3'd4;
            // end
            // else if (i_sigma1_3 != 10'd0 && i_code == 2'b10) begin
            //     num_S_degree1_1_next = 3'd3;
            // end
            // else if (i_sigma1_2 != 10'd0) begin
            //     num_S_degree1_1_next = 3'd2;
            // end
            // else if (i_sigma1_1 != 10'd0) begin
            //     num_S_degree1_1_next = 3'd1;
            // end
            // else begin
            //     num_S_degree1_1_next = 3'd0;
            // end

            // if (i_sigma2_2 != 10'd0) begin
            //     num_S_degree1_2_next = 3'd2;
            // end
            // else if (i_sigma2_1 != 10'd0) begin
            //     num_S_degree1_2_next = 3'd1;
            // end
            // else begin
            //     num_S_degree1_2_next = 3'd0;
            // end

            num_S_degree1_1_next = i_degree1;
            num_S_degree1_2_next = i_degree2;

            correct1_1_next = i_correct1;
            correct1_2_next = i_correct2;
        end
        else begin
            num_S_degree1_1_next = num_S_degree1_1;
            num_S_degree1_2_next = num_S_degree1_2;

            correct1_1_next = correct1_1;
            correct1_2_next = correct1_2;
        end
    end


    assign o_err_loc0 = err_loc0_buf;
    assign o_err_loc1 = err_loc1_buf;
    assign o_err_loc2 = err_loc2_buf;
    assign o_err_loc3 = err_loc3_buf;
    assign o_num_err = num_err_buf;
    

    always @(*) begin
        case(i_code) // synopsys full_case
            2'd0: begin // (63,51)
                if (counter_find_1_idx_pipe2 == 4'd0) begin
                    o_correct = (num_S_degree2_1 == num_err_buf && correct2_1) ? 1'b1 : 1'b0;
                    o_err_valid = !i_early_stop;
                end
                else if (counter_find_1_idx_pipe2 == 4'd2 && i_mode == 1'b1) begin
                    o_correct = (num_S_degree2_2 == num_err_buf && correct2_2) ? 1'b1 : 1'b0;
                    o_err_valid = !i_early_stop;
                end 
                else begin
                    o_correct = 1'b0;
                    o_err_valid = 1'b0;
                end
            end
            2'd1: begin // (255,239)
                if (counter_find_1_idx_pipe2 == 4'd1) begin
                    o_correct = (num_S_degree2_1 == num_err_buf && correct2_1) ? 1'b1 : 1'b0;
                    o_err_valid = !i_early_stop;
                end
                else if (counter_find_1_idx_pipe2 == 4'd3 && i_mode == 1'b1) begin
                    o_correct = (num_S_degree2_2 == num_err_buf && correct2_2) ? 1'b1 : 1'b0;
                    o_err_valid = !i_early_stop;
                end
                else begin
                    o_correct = 1'b0;
                    o_err_valid = 1'b0;
                end
            end
            2'd2: begin // (1023,983)
                if (counter_find_1_idx_pipe2 == 4'd7) begin
                    o_correct = (num_S_degree2_1 == num_err_buf && correct2_1) ? 1'b1 : 1'b0;
                    o_err_valid = !i_early_stop;
                end
                else begin
                    o_correct = 1'b0;
                    o_err_valid = 1'b0;
                end
            end
        endcase
    end


endmodule



module chien_search_pe #(
    parameter [9:0] ALPHA_BASE = 0
)(
    input  [1:0] i_code,

    input  [9:0] i_sigma0,
    input  [9:0] i_sigma_alpha1,
    input  [9:0] i_sigma_alpha2,
    input  [9:0] i_sigma_alpha3,
    input  [9:0] i_sigma_alpha4,

    output        o_is_root
);
    // ----------------------------
    // pre-sized power indices (to avoid width mismatch)
    // 63-domain (6-bit)
    localparam ab_mod_63      = ALPHA_BASE % 10'd63;
    localparam abx2_mod_63    = (ALPHA_BASE * 10'd2) % 10'd63;
    localparam pwr63_a1       = (ALPHA_BASE >= 10'd63) ? 6'd63 : ((6'd63 - ab_mod_63[5:0])   % 6'd63);
    localparam pwr63_a2       = (ALPHA_BASE >= 10'd63) ? 6'd63 : ((6'd63 - abx2_mod_63[5:0]) % 6'd63);


    // 255-domain (8-bit)
    localparam ab_mod_255     = ALPHA_BASE % 10'd255;
    localparam abx2_mod_255   = (ALPHA_BASE * 10'd2) % 10'd255;
    localparam pwr255_a1      = (8'd255 - ab_mod_255[7:0])    % 8'd255;
    localparam pwr255_a2      = (8'd255 - abx2_mod_255[7:0])  % 8'd255;


    // 1023-domain (10-bit)
    localparam ab_mod_1023    = ALPHA_BASE % 10'd1023;
    localparam abx2_mod_1023  = (ALPHA_BASE * 10'd2) % 10'd1023;
    localparam abx3_mod_1023  = (ALPHA_BASE * 10'd3) % 10'd1023;
    localparam abx4_mod_1023  = (ALPHA_BASE * 10'd4) % 10'd1023;
    localparam pwr1023_a1     = (10'd1023 - ab_mod_1023)   % 10'd1023;
    localparam pwr1023_a2     = (10'd1023 - abx2_mod_1023) % 10'd1023;
    localparam pwr1023_a3     = (10'd1023 - abx3_mod_1023) % 10'd1023;
    localparam pwr1023_a4     = (10'd1023 - abx4_mod_1023) % 10'd1023;

    // ----------------------------
    // alpha^k (tuple) from power index
    wire [9:0] alpha1_63,  alpha2_63,  alpha3_63,  alpha4_63;
    wire [9:0] alpha1_255, alpha2_255, alpha3_255, alpha4_255;
    wire [9:0] alpha1_1023,alpha2_1023,alpha3_1023,alpha4_1023;

    assign alpha1_63[9:6]  = 4'd0;
    assign alpha2_63[9:6]  = 4'd0;
    assign alpha1_255[9:8] = 2'd0;
    assign alpha2_255[9:8] = 2'd0;


    power_to_tuple_63_51 u_power_to_tuple_63_51_alpha1 (
        .i_power(pwr63_a1[5:0]),
        .o_tuple(alpha1_63[5:0])
    );
    power_to_tuple_63_51 u_power_to_tuple_63_51_alpha2 (
        .i_power(pwr63_a2[5:0]),
        .o_tuple(alpha2_63[5:0])
    );
    // 未用：直接給 0（tuple 0）
    assign alpha3_63 = 10'd0;
    assign alpha4_63 = 10'd0;

    power_to_tuple_255_239 u_power_to_tuple_255_239_alpha1 (
        .i_power(pwr255_a1[7:0]),
        .o_tuple(alpha1_255[7:0])
    );
    power_to_tuple_255_239 u_power_to_tuple_255_239_alpha2 (
        .i_power(pwr255_a2[7:0]),
        .o_tuple(alpha2_255[7:0])
    );
    assign alpha3_255 = 10'd0;
    assign alpha4_255 = 10'd0;

    power_to_tuple_1023_983 u_power_to_tuple_1023_983_alpha1 (
        .i_power(pwr1023_a1[9:0]),
        .o_tuple(alpha1_1023)
    );
    power_to_tuple_1023_983 u_power_to_tuple_1023_983_alpha2 (
        .i_power(pwr1023_a2[9:0]),
        .o_tuple(alpha2_1023)
    );
    power_to_tuple_1023_983 u_power_to_tuple_1023_983_alpha3 (
        .i_power(pwr1023_a3[9:0]),
        .o_tuple(alpha3_1023)
    );
    power_to_tuple_1023_983 u_power_to_tuple_1023_983_alpha4 (
        .i_power(pwr1023_a4[9:0]),
        .o_tuple(alpha4_1023)
    );

    // ----------------------------
    // select proper domain tuples for multiplication
    wire [9:0] mult1_alpha1 = (i_code == 2'd0) ? alpha1_63   :
                              (i_code == 2'd1) ? alpha1_255  :
                                                 alpha1_1023;
    wire [9:0] mult2_alpha2 = (i_code == 2'd0) ? alpha2_63   :
                              (i_code == 2'd1) ? alpha2_255  :
                                                 alpha2_1023;
    wire [9:0] mult3_alpha3 = (i_code == 2'd0) ? alpha3_63   :
                              (i_code == 2'd1) ? alpha3_255  :
                                                 alpha3_1023;
    wire [9:0] mult4_alpha4 = (i_code == 2'd0) ? alpha4_63   :
                              (i_code == 2'd1) ? alpha4_255  :
                                                 alpha4_1023;

    // ----------------------------
    // GF multiplications
    wire [9:0] mult_out1, mult_out2, mult_out3, mult_out4;

    gf_mult u_gf_mult1 (
        .i_a(i_sigma_alpha1),
        .i_b(mult1_alpha1),
        .i_code(i_code),
        .o_product(mult_out1)
    );
    gf_mult u_gf_mult2 (
        .i_a(i_sigma_alpha2),
        .i_b(mult2_alpha2),
        .i_code(i_code),
        .o_product(mult_out2)
    );
    gf_mult u_gf_mult3 (
        .i_a(i_sigma_alpha3),
        .i_b(mult3_alpha3),
        .i_code(i_code),
        .o_product(mult_out3)
    );
    gf_mult u_gf_mult4 (
        .i_a(i_sigma_alpha4),
        .i_b(mult4_alpha4),
        .i_code(i_code),
        .o_product(mult_out4)
    );

    // sigma(alpha^{-j}) = sigma0 ^ (sigma1*alpha^{-j}) ^ ...
    wire [9:0] sum_mult = mult_out1 ^ mult_out2 ^ mult_out3 ^ mult_out4 ^ i_sigma0;
    assign o_is_root = (sum_mult == 10'd0);

endmodule

