module control(
    input i_clk,
    input i_rst_n,
    
    // core
    input i_core_set,
    input i_core_mode,
    input [1:0] i_core_code,
    output reg o_core_ready,
    output reg o_early_stop,

    // all module
    output o_mode,
    output [1:0] o_code,

    // syndrome
    output reg o_syndrome_clear_and_wen,
    output reg o_syndrome_wen,

    // llr_mem
    output reg o_llr_mem_wen,

    // error_bit_saver
    output reg o_error_bit_saver_clear,

    // early stop
    input i_early_stop_pulse
);

    // mode and code
    reg mode_reg, mode_reg_next;
    reg [1:0] code_reg, code_reg_next;


    reg [7:0] counter, counter_next;


    assign o_mode = mode_reg;
    assign o_code = code_reg;

    reg early_stop_flag, early_stop_flag_next;

    assign o_early_stop = early_stop_flag;

    always @(posedge i_clk) begin
        if(!i_rst_n) begin
            mode_reg <= 1'b0;
            code_reg <= 2'b00;
        end
        else begin
            mode_reg <= mode_reg_next;
            code_reg <= code_reg_next;
        end
    end

    always @(*) begin
        if(i_core_set) begin
            mode_reg_next = i_core_mode;
            code_reg_next = i_core_code == 2'd0 ? i_core_code : i_core_code - 2'b1;
        end
        else begin
            mode_reg_next = mode_reg;
            code_reg_next = code_reg;
        end
    end


    always @(posedge i_clk) begin
        if(!i_rst_n) begin
            counter <= 8'd255;
        end
        else begin
            counter <= counter_next;
        end
    end

    always @(*) begin
        if(i_core_set) begin
            counter_next = 8'd0;
        end
        else if(counter <= 8'd128) begin
            counter_next = counter + 8'd1;
        end
        else begin
            counter_next = counter;
        end
    end

    always @(*) begin
        case (code_reg) // synopsys full_case
            2'd0: begin
                if (counter < 8'd8) begin
                    o_core_ready = 1'b1;
                end
                else begin
                    o_core_ready = 1'b0;
                end
            end
            2'd1: begin
                if (counter < 8'd32) begin
                    o_core_ready = 1'b1;
                end
                else begin
                    o_core_ready = 1'b0;
                end
            end
            2'd2: begin
                if (counter < 8'd128) begin
                    o_core_ready = 1'b1;
                end
                else begin
                    o_core_ready = 1'b0;
                end
            end
        endcase
    end

    always @(*) begin
        if (counter == 8'd1) begin
            o_syndrome_clear_and_wen = 1'b1;
        end
        else begin
            o_syndrome_clear_and_wen = 1'b0;
        end
    end

    always @(*) begin
        case (code_reg) // synopsys full_case
            2'd0: begin
                if (counter > 8'd0 && counter < 8'd9) begin
                    o_syndrome_wen = 1'b1;
                    o_llr_mem_wen = mode_reg ? 1'b1 : 1'b0;
                end
                else begin
                    o_syndrome_wen = 1'b0;
                    o_llr_mem_wen = 1'b0;
                end
            end
            2'd1: begin
                if (counter > 8'd0 && counter < 8'd33) begin
                    o_syndrome_wen = 1'b1;
                    o_llr_mem_wen = mode_reg ? 1'b1 : 1'b0;
                end
                else begin
                    o_syndrome_wen = 1'b0;
                    o_llr_mem_wen = 1'b0;
                end
            end
            2'd2: begin
                if (counter > 8'd0 && counter < 8'd129) begin
                    o_syndrome_wen = 1'b1;
                    o_llr_mem_wen = mode_reg ? 1'b1 : 1'b0;
                end
                else begin
                    o_syndrome_wen = 1'b0;
                    o_llr_mem_wen = 1'b0;
                end
            end
        endcase
    end


    always @(*) begin
        if (counter == 8'd0) begin
            o_error_bit_saver_clear = 1'b1;
        end
        else begin
            o_error_bit_saver_clear = 1'b0;
        end
    end


    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            early_stop_flag <= 1'b0;
        end
        else begin
            early_stop_flag <= early_stop_flag_next;
        end
    end

    always @(*) begin
        if (i_core_set) begin
            early_stop_flag_next = 1'b0;
        end
        else if (i_early_stop_pulse) begin
            early_stop_flag_next = 1'b1;
        end
        else begin
            early_stop_flag_next = early_stop_flag;
        end
    end
endmodule