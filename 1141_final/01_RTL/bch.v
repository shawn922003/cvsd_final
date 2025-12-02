module bch(
	input clk,
	input rstn,
	input mode,
	input [1:0] code,
	input set,
	input [63:0] idata,
	output ready,
	output finish,
	output [9:0] odata
);

	wire core_mode;
	wire [1:0] core_code;


	wire [63:0] i_data_buf;
	
	wire syndrome_clear_and_wen;
	wire syndrome_wen;

	wire llr_mem_wen;

	wire error_bit_saver_clear;

	wire [9:0] llr_mem_pos[0:1];
	wire [6:0] llr_mem_pos_llr[0:1];

	wire [9:0] syndrome_tp1_S[1:8];
	wire [9:0] syndrome_tp2_S[1:8];
	wire [9:0] syndrome_tp3_S[1:8];
	wire [9:0] syndrome_tp4_S[1:8]; 

	wire [9:0] flip_alpha_S1[1:2];
	wire [9:0] flip_alpha_S3[1:2];
	wire [9:0] flip_alpha_S5[1:2];
	wire [9:0] flip_alpha_S7[1:2];
	
	wire [9:0] flip_pos[1:2];

	wire syndrome_odd_s_valid;
	wire syndrome_all_s_valid;
	wire flip_valid;

	wire flip_syndrome_all_tp_valid;

	wire [9:0] syndrome_switch_out_s[1:8];
	wire syndrome_switch_out_valid;
	wire ibm_in_clear_and_wen;
	wire syndrome_switch_next_tp;

	wire [9:0] ibm_sigma1[0:4];
	wire [9:0] ibm_sigma2[0:2];

	wire ibm_out_valid;

	wire [9:0] chien_search_err_loc_out[0:3];
	wire [2:0] chien_search_num_err_out;
	wire chien_search_correct_out;

	wire chien_search_err_loc_valid_pulse;

	wire [9:0] err_bit_saver_tp1_loc[0:5];
	wire [9:0] err_bit_saver_tp2_loc[0:5];
	wire [9:0] err_bit_saver_tp3_loc[0:5];
	wire [9:0] err_bit_saver_tp4_loc[0:5];
	wire [2:0] err_bit_saver_tp1_num_err;
	wire [2:0] err_bit_saver_tp2_num_err;
	wire [2:0] err_bit_saver_tp3_num_err;
	wire [2:0] err_bit_saver_tp4_num_err;

	wire [2:0] select_tp;

	wire err_bit_saver_out_valid;
	wire err_bit_saver_valid_pulse;

	delay_n #(
		.N(1),
		.BITS(64),
		.INIT(64'd0)
	) u_data_buf (
		.i_clk(clk),
		.i_rst_n(rstn),
		.i_en(1'b1),
		.i_d(idata),
		.o_q(i_data_buf)
	);


	//====================================================
	// control
	//====================================================
	control u_control (
		.i_clk(clk),                    // 1 bit
		.i_rst_n(rstn),                  // 1 bit

		// core
		.i_core_set(set),               // 1 bit
		.i_core_mode(mode),              // 1 bit
		.i_core_code(code),              // 2 bits
		.o_core_ready(ready),             // 1 bit

		// all module
		.o_mode(core_mode),                   // 1 bit
		.o_code(core_code),                   // 2 bits

		// syndrome
		.o_syndrome_clear_and_wen(syndrome_clear_and_wen), // 1 bit
		.o_syndrome_wen(syndrome_wen),           // 1 bit

		// llr_mem
		.o_llr_mem_wen(llr_mem_wen),            // 1 bit

		// error_bit_saver
		.o_error_bit_saver_clear(error_bit_saver_clear)   // 1 bit
	);

	//====================================================
	// llr_mem
	//====================================================
	llr_mem u_llr_mem (
		.i_clk(clk),     // 1 bit
		.i_rst_n(rstn),  // 1 bit

		.i_wen(llr_mem_wen),    // 1 bit
		.i_data(i_data_buf),   // 64 bits

		.i_pos0(llr_mem_pos[0]),   // 10 bits
		.i_pos1(llr_mem_pos[1]),   // 10 bits

		.o_data0(llr_mem_pos_llr[0]),  // 7 bits
		.o_data1(llr_mem_pos_llr[1])  // 7 bits
	);

	//====================================================
	// syndrome
	//====================================================
	syndrome u_syndrome (
		.i_clk(clk),                // 1 bit
		.i_rst_n(rstn),             // 1 bit

		.i_mode(core_mode),              // 1 bit
		.i_code(core_code),              // 2 bits
		.i_clear_and_wen(syndrome_clear_and_wen),     // 1 bit
		.i_wen(syndrome_wen),               // 1 bit

		.i_data(i_data_buf),              // 64 bits

		.o_S1(syndrome_tp1_S[1]),                // 10 bits
		.o_S2(syndrome_tp1_S[2]),                // 10 bits
		.o_S3(syndrome_tp1_S[3]),                // 10 bits
		.o_S4(syndrome_tp1_S[4]),                // 10 bits
		.o_S5(syndrome_tp1_S[5]),                // 10 bits
		.o_S6(syndrome_tp1_S[6]),                // 10 bits
		.o_S7(syndrome_tp1_S[7]),                // 10 bits
		.o_S8(syndrome_tp1_S[8]),                // 10 bits

		.o_odd_s_valid(syndrome_odd_s_valid),       // 1 bit
		.o_all_s_valid(syndrome_all_s_valid),       // 1 bit

		.o_flip_alpha_S1_1(flip_alpha_S1[1]),   // 10 bits
		.o_flip_alpha_S1_2(flip_alpha_S1[2]),   // 10 bits
		.o_flip_alpha_S3_1(flip_alpha_S3[1]),   // 10 bits
		.o_flip_alpha_S3_2(flip_alpha_S3[2]),   // 10 bits
		.o_flip_alpha_S5_1(flip_alpha_S5[1]),   // 10 bits
		.o_flip_alpha_S5_2(flip_alpha_S5[2]),   // 10 bits
		.o_flip_alpha_S7_1(flip_alpha_S7[1]),   // 10 bits
		.o_flip_alpha_S7_2(flip_alpha_S7[2]),   // 10 bits

		.o_flip_pos1(flip_pos[1]),         // 10 bits
		.o_flip_pos2(flip_pos[2]),         // 10 bits

		.o_flip_valid(flip_valid)         // 1 bit
	);

	//====================================================
	// flip_syndrome
	//====================================================
	flip_syndrome u_flip_syndrome (
		.i_clk(clk),                // 1 bit
		.i_rst_n(rstn),             // 1 bit

		.i_mode(core_mode),              // 1 bit
		.i_code(core_code),              // 2 bits

		.i_S1(syndrome_tp1_S[1]),                // 10 bits
		.i_S2(syndrome_tp1_S[2]),                // 10 bits
		.i_S3(syndrome_tp1_S[3]),                // 10 bits
		.i_S4(syndrome_tp1_S[4]),                // 10 bits
		.i_S5(syndrome_tp1_S[5]),                // 10 bits
		.i_S6(syndrome_tp1_S[6]),                // 10 bits
		.i_S7(syndrome_tp1_S[7]),                // 10 bits
		.i_S8(syndrome_tp1_S[8]),                // 10 bits

		.i_syndrome_valid(syndrome_odd_s_valid),    // 1 bit

		.i_flip_alpha_S1_1(flip_alpha_S1[1]),   // 10 bits
		.i_flip_alpha_S1_2(flip_alpha_S1[2]),   // 10 bits
		.i_flip_alpha_S3_1(flip_alpha_S3[1]),   // 10 bits
		.i_flip_alpha_S3_2(flip_alpha_S3[2]),   // 10 bits
		.i_flip_alpha_S5_1(flip_alpha_S5[1]),   // 10 bits
		.i_flip_alpha_S5_2(flip_alpha_S5[2]),   // 10 bits
		.i_flip_alpha_S7_1(flip_alpha_S7[1]),   // 10 bits
		.i_flip_alpha_S7_2(flip_alpha_S7[2]),   // 10 bits

		.i_flip_alpha_valid(flip_valid),  // 1 bit

		.o_tp2_S1(syndrome_tp2_S[1]),            // 10 bits
		.o_tp2_S2(syndrome_tp2_S[2]),            // 10 bits
		.o_tp2_S3(syndrome_tp2_S[3]),            // 10 bits
		.o_tp2_S4(syndrome_tp2_S[4]),            // 10 bits
		.o_tp2_S5(syndrome_tp2_S[5]),            // 10 bits
		.o_tp2_S6(syndrome_tp2_S[6]),            // 10 bits
		.o_tp2_S7(syndrome_tp2_S[7]),            // 10 bits
		.o_tp2_S8(syndrome_tp2_S[8]),            // 10 bits

		.o_tp3_S1(syndrome_tp3_S[1]),            // 10 bits
		.o_tp3_S2(syndrome_tp3_S[2]),            // 10 bits
		.o_tp3_S3(syndrome_tp3_S[3]),            // 10 bits
		.o_tp3_S4(syndrome_tp3_S[4]),            // 10 bits
		.o_tp3_S5(syndrome_tp3_S[5]),            // 10 bits
		.o_tp3_S6(syndrome_tp3_S[6]),            // 10 bits
		.o_tp3_S7(syndrome_tp3_S[7]),            // 10 bits
		.o_tp3_S8(syndrome_tp3_S[8]),            // 10 bits

		.o_tp4_S1(syndrome_tp4_S[1]),            // 10 bits
		.o_tp4_S2(syndrome_tp4_S[2]),            // 10 bits
		.o_tp4_S3(syndrome_tp4_S[3]),            // 10 bits
		.o_tp4_S4(syndrome_tp4_S[4]),            // 10 bits
		.o_tp4_S5(syndrome_tp4_S[5]),            // 10 bits
		.o_tp4_S6(syndrome_tp4_S[6]),            // 10 bits
		.o_tp4_S7(syndrome_tp4_S[7]),            // 10 bits
		.o_tp4_S8(syndrome_tp4_S[8]),            // 10 bits

		.o_tp_valid(flip_syndrome_all_tp_valid)           // 1 bit
	);

	//====================================================
	// syndrome_switch
	//====================================================
	syndrome_switch u_syndrome_switch (
		.i_clk(clk),         // 1 bit
		.i_rst_n(rstn),      // 1 bit

		.i_mode(core_mode),       // 1 bit
		.i_code(core_code),       // 2 bits

		.i_tp1_S1(syndrome_tp1_S[1]),     // 10 bits
		.i_tp1_S2(syndrome_tp1_S[2]),     // 10 bits
		.i_tp1_S3(syndrome_tp1_S[3]),     // 10 bits
		.i_tp1_S4(syndrome_tp1_S[4]),     // 10 bits
		.i_tp1_S5(syndrome_tp1_S[5]),     // 10 bits
		.i_tp1_S6(syndrome_tp1_S[6]),     // 10 bits
		.i_tp1_S7(syndrome_tp1_S[7]),     // 10 bits
		.i_tp1_S8(syndrome_tp1_S[8]),     // 10 bits
		.i_tp1_valid(syndrome_all_s_valid),  // 1 bit

		.i_tp2_S1(syndrome_tp2_S[1]),     // 10 bits
		.i_tp2_S2(syndrome_tp2_S[2]),     // 10 bits
		.i_tp2_S3(syndrome_tp2_S[3]),     // 10 bits
		.i_tp2_S4(syndrome_tp2_S[4]),     // 10 bits
		.i_tp2_S5(syndrome_tp2_S[5]),     // 10 bits
		.i_tp2_S6(syndrome_tp2_S[6]),     // 10 bits
		.i_tp2_S7(syndrome_tp2_S[7]),     // 10 bits
		.i_tp2_S8(syndrome_tp2_S[8]),     // 10 bits

		.i_tp3_S1(syndrome_tp3_S[1]),     // 10 bits
		.i_tp3_S2(syndrome_tp3_S[2]),     // 10 bits
		.i_tp3_S3(syndrome_tp3_S[3]),     // 10 bits
		.i_tp3_S4(syndrome_tp3_S[4]),     // 10 bits
		.i_tp3_S5(syndrome_tp3_S[5]),     // 10 bits
		.i_tp3_S6(syndrome_tp3_S[6]),     // 10 bits
		.i_tp3_S7(syndrome_tp3_S[7]),     // 10 bits
		.i_tp3_S8(syndrome_tp3_S[8]),     // 10 bits

		.i_tp4_S1(syndrome_tp4_S[1]),     // 10 bits
		.i_tp4_S2(syndrome_tp4_S[2]),     // 10 bits
		.i_tp4_S3(syndrome_tp4_S[3]),     // 10 bits
		.i_tp4_S4(syndrome_tp4_S[4]),     // 10 bits
		.i_tp4_S5(syndrome_tp4_S[5]),     // 10 bits
		.i_tp4_S6(syndrome_tp4_S[6]),     // 10 bits
		.i_tp4_S7(syndrome_tp4_S[7]),     // 10 bits
		.i_tp4_S8(syndrome_tp4_S[8]),     // 10 bits

		.i_all_tp_valid(flip_syndrome_all_tp_valid), // 1 bit
		.i_next_tp(syndrome_switch_next_tp),      // 1 bit

		.o_S1(syndrome_switch_out_s[1]),         // 10 bits
		.o_S2(syndrome_switch_out_s[2]),         // 10 bits
		.o_S3(syndrome_switch_out_s[3]),         // 10 bits
		.o_S4(syndrome_switch_out_s[4]),         // 10 bits
		.o_S5(syndrome_switch_out_s[5]),         // 10 bits
		.o_S6(syndrome_switch_out_s[6]),         // 10 bits
		.o_S7(syndrome_switch_out_s[7]),         // 10 bits
		.o_S8(syndrome_switch_out_s[8]),         // 10 bits
		.o_valid(syndrome_switch_out_valid)       // 1 bit
	);



	// pulser u_syndrome_ibm_pulser (
	// 	.i_clk(clk),
	// 	.i_rst_n(rstn),

	// 	.i_in(syndrome_switch_out_valid), 
	// 	.i_clear(syndrome_switch_next_tp),

	// 	.o_pulse(ibm_in_clear_and_wen) 
	// );
	assign ibm_in_clear_and_wen = syndrome_switch_out_valid;

	//====================================================
	// ibm
	//====================================================
	ibm u_ibm (
		.i_clk(clk),           // 1 bit
		.i_rst_n(rstn),        // 1 bit

		.i_mode(core_mode),         // 1 bit
		.i_code(core_code),         // 2 bits
		.i_clear_and_wen(ibm_in_clear_and_wen),// 1 bit

		.i_S1(syndrome_switch_out_s[1]),           // 10 bits
		.i_S2(syndrome_switch_out_s[2]),           // 10 bits
		.i_S3(syndrome_switch_out_s[3]),           // 10 bits
		.i_S4(syndrome_switch_out_s[4]),           // 10 bits
		.i_S5(syndrome_switch_out_s[5]),           // 10 bits
		.i_S6(syndrome_switch_out_s[6]),           // 10 bits
		.i_S7(syndrome_switch_out_s[7]),           // 10 bits
		.i_S8(syndrome_switch_out_s[8]),           // 10 bits

		.o_sigma1_0(ibm_sigma1[0]),     // 10 bits
		.o_sigma1_1(ibm_sigma1[1]),     // 10 bits
		.o_sigma1_2(ibm_sigma1[2]),     // 10 bits
		.o_sigma1_3(ibm_sigma1[3]),     // 10 bits
		.o_sigma1_4(ibm_sigma1[4]),     // 10 bits

		.o_sigma2_0(ibm_sigma2[0]),     // 10 bits
		.o_sigma2_1(ibm_sigma2[1]),     // 10 bits
		.o_sigma2_2(ibm_sigma2[2]),     // 10 bits

		.o_valid(ibm_out_valid),        // 1 bit
		.o_next_S(syndrome_switch_next_tp)        // 1 bit
	);

	//====================================================
	// chien_search
	//====================================================
	chien_search u_chien_search (
		.i_clk(clk),           // 1 bit
		.i_rst_n(rstn),        // 1 bit

		.i_mode(core_mode),         // 1 bit
		.i_code(core_code),         // 2 bits
		.i_clear_and_wen(ibm_out_valid),// 1 bit

		.i_sigma1_0(ibm_sigma1[0]),     // 10 bits
		.i_sigma1_1(ibm_sigma1[1]),     // 10 bits
		.i_sigma1_2(ibm_sigma1[2]),     // 10 bits
		.i_sigma1_3(ibm_sigma1[3]),     // 10 bits
		.i_sigma1_4(ibm_sigma1[4]),     // 10 bits
		.i_sigma2_0(ibm_sigma2[0]),     // 10 bits
		.i_sigma2_1(ibm_sigma2[1]),     // 10 bits
		.i_sigma2_2(ibm_sigma2[2]),     // 10 bits

		.o_err_loc0(chien_search_err_loc_out[0]),     // 10 bits
		.o_err_loc1(chien_search_err_loc_out[1]),     // 10 bits
		.o_err_loc2(chien_search_err_loc_out[2]),     // 10 bits
		.o_err_loc3(chien_search_err_loc_out[3]),     // 10 bits
		.o_num_err(chien_search_num_err_out),      // 3 bits
		.o_correct(chien_search_correct_out),      // 1 bit

		.o_valid(chien_search_err_loc_valid_pulse)         // 1 bit
	);

	//====================================================
	// error_bit_saver
	//====================================================
	error_bit_saver u_error_bit_saver (
		.i_clk(clk),                // 1 bit
		.i_rst_n(rstn),             // 1 bit

		.i_mode(core_mode),              // 1 bit
		.i_code(core_code),              // 2 bits

		.i_clear(error_bit_saver_clear),             // 1 bit
		.i_err_valid_pulse(chien_search_err_loc_valid_pulse),   // 1 bit
		.i_err_loc0(chien_search_err_loc_out[0]),          // 10 bits
		.i_err_loc1(chien_search_err_loc_out[1]),          // 10 bits
		.i_err_loc2(chien_search_err_loc_out[2]),          // 10 bits
		.i_err_loc3(chien_search_err_loc_out[3]),          // 10 bits
		.i_num_err(chien_search_num_err_out),           // 3 bits
		.i_correct(chien_search_correct_out),           // 1 bit

		.i_flip_pos1(flip_pos[1]),         // 10 bits
		.i_flip_pos2(flip_pos[2]),         // 10 bits
		.i_flip_valid(flip_valid),        // 1 bit

		.o_tp1_err_loc0(err_bit_saver_tp1_loc[0]),      // 10 bits
		.o_tp1_err_loc1(err_bit_saver_tp1_loc[1]),      // 10 bits
		.o_tp1_err_loc2(err_bit_saver_tp1_loc[2]),      // 10 bits
		.o_tp1_err_loc3(err_bit_saver_tp1_loc[3]),      // 10 bits
		.o_tp1_err_loc4(err_bit_saver_tp1_loc[4]),      // 10 bits
		.o_tp1_err_loc5(err_bit_saver_tp1_loc[5]),      // 10 bits
		.o_tp1_num_err(err_bit_saver_tp1_num_err),       // 3 bits

		.o_tp2_err_loc0(err_bit_saver_tp2_loc[0]),      // 10 bits
		.o_tp2_err_loc1(err_bit_saver_tp2_loc[1]),      // 10 bits
		.o_tp2_err_loc2(err_bit_saver_tp2_loc[2]),      // 10 bits
		.o_tp2_err_loc3(err_bit_saver_tp2_loc[3]),      // 10 bits
		.o_tp2_err_loc4(err_bit_saver_tp2_loc[4]),      // 10 bits
		.o_tp2_err_loc5(err_bit_saver_tp2_loc[5]),      // 10 bits
		.o_tp2_num_err(err_bit_saver_tp2_num_err),       // 3 bits

		.o_tp3_err_loc0(err_bit_saver_tp3_loc[0]),      // 10 bits
		.o_tp3_err_loc1(err_bit_saver_tp3_loc[1]),      // 10 bits
		.o_tp3_err_loc2(err_bit_saver_tp3_loc[2]),      // 10 bits
		.o_tp3_err_loc3(err_bit_saver_tp3_loc[3]),      // 10 bits
		.o_tp3_err_loc4(err_bit_saver_tp3_loc[4]),      // 10 bits
		.o_tp3_err_loc5(err_bit_saver_tp3_loc[5]),      // 10 bits
		.o_tp3_num_err(err_bit_saver_tp3_num_err),       // 3 bits

		.o_tp4_err_loc0(err_bit_saver_tp4_loc[0]),      // 10 bits
		.o_tp4_err_loc1(err_bit_saver_tp4_loc[1]),      // 10 bits
		.o_tp4_err_loc2(err_bit_saver_tp4_loc[2]),      // 10 bits
		.o_tp4_err_loc3(err_bit_saver_tp4_loc[3]),      // 10 bits
		.o_tp4_err_loc4(err_bit_saver_tp4_loc[4]),      // 10 bits
		.o_tp4_err_loc5(err_bit_saver_tp4_loc[5]),      // 10 bits
		.o_tp4_num_err(err_bit_saver_tp4_num_err),       // 3 bits

		.mim_llr_tp(select_tp),          // 3 bits

		.o_valid(err_bit_saver_out_valid),             // 1 bit

		// interaction with llr_mem
		.o_llr_mem_pos0(llr_mem_pos[0]),      // 10 bits
		.o_llr_mem_pos1(llr_mem_pos[1]),      // 10 bits

		.i_llr_mem_pos0_llr(llr_mem_pos_llr[0]),  // 7 bits
		.i_llr_mem_pos1_llr(llr_mem_pos_llr[1])  // 7 bits
	);


	pulser u_error_bit_saver_output_selector_pulser (
		.i_clk(clk),
		.i_rst_n(rstn),

		.i_in(err_bit_saver_out_valid), 
		.i_clear(1'b0),

		.o_pulse(err_bit_saver_valid_pulse)
	);

	//====================================================
	// output_selector
	//====================================================
	output_selector u_output_selector (
		.i_clk(clk),                       // 1 bit
		.i_rst_n(rstn),                    // 1 bit

		.i_mode(core_mode),                     // 1 bit

		.chien_search_err_loc0(chien_search_err_loc_out[0]),      // 10 bits
		.chien_search_err_loc1(chien_search_err_loc_out[1]),      // 10 bits
		.chien_search_err_loc2(chien_search_err_loc_out[2]),      // 10 bits
		.chien_search_err_loc3(chien_search_err_loc_out[3]),      // 10 bits
		.chien_search_num_err(chien_search_num_err_out),       // 3 bits
		.chien_search_valid_pulse(chien_search_err_loc_valid_pulse),   // 1 bit

		.err_bit_saver_tp1_err_loc0(err_bit_saver_tp1_loc[0]), // 10 bits
		.err_bit_saver_tp1_err_loc1(err_bit_saver_tp1_loc[1]), // 10 bits
		.err_bit_saver_tp1_err_loc2(err_bit_saver_tp1_loc[2]), // 10 bits
		.err_bit_saver_tp1_err_loc3(err_bit_saver_tp1_loc[3]), // 10 bits
		.err_bit_saver_tp1_err_loc4(err_bit_saver_tp1_loc[4]), // 10 bits
		.err_bit_saver_tp1_err_loc5(err_bit_saver_tp1_loc[5]), // 10 bits
		.err_bit_saver_tp1_num_err(err_bit_saver_tp1_num_err),  // 3 bits

		.err_bit_saver_tp2_err_loc0(err_bit_saver_tp2_loc[0]), // 10 bits
		.err_bit_saver_tp2_err_loc1(err_bit_saver_tp2_loc[1]), // 10 bits
		.err_bit_saver_tp2_err_loc2(err_bit_saver_tp2_loc[2]), // 10 bits
		.err_bit_saver_tp2_err_loc3(err_bit_saver_tp2_loc[3]), // 10 bits
		.err_bit_saver_tp2_err_loc4(err_bit_saver_tp2_loc[4]), // 10 bits
		.err_bit_saver_tp2_err_loc5(err_bit_saver_tp2_loc[5]), // 10 bits
		.err_bit_saver_tp2_num_err(err_bit_saver_tp2_num_err),  // 3 bits

		.err_bit_saver_tp3_err_loc0(err_bit_saver_tp3_loc[0]), // 10 bits
		.err_bit_saver_tp3_err_loc1(err_bit_saver_tp3_loc[1]), // 10 bits
		.err_bit_saver_tp3_err_loc2(err_bit_saver_tp3_loc[2]), // 10 bits
		.err_bit_saver_tp3_err_loc3(err_bit_saver_tp3_loc[3]), // 10 bits
		.err_bit_saver_tp3_err_loc4(err_bit_saver_tp3_loc[4]), // 10 bits
		.err_bit_saver_tp3_err_loc5(err_bit_saver_tp3_loc[5]), // 10 bits
		.err_bit_saver_tp3_num_err(err_bit_saver_tp3_num_err),  // 3 bits

		.err_bit_saver_tp4_err_loc0(err_bit_saver_tp4_loc[0]), // 10 bits
		.err_bit_saver_tp4_err_loc1(err_bit_saver_tp4_loc[1]), // 10 bits
		.err_bit_saver_tp4_err_loc2(err_bit_saver_tp4_loc[2]), // 10 bits
		.err_bit_saver_tp4_err_loc3(err_bit_saver_tp4_loc[3]), // 10 bits
		.err_bit_saver_tp4_err_loc4(err_bit_saver_tp4_loc[4]), // 10 bits
		.err_bit_saver_tp4_err_loc5(err_bit_saver_tp4_loc[5]), // 10 bits
		.err_bit_saver_tp4_num_err(err_bit_saver_tp4_num_err),  // 3 bits

		.err_bit_saver_select_tp(select_tp),    // 3 bits
		.err_bit_saver_valid_pulse(err_bit_saver_valid_pulse),  // 1 bit

		.o_err_loc(odata),                  // 10 bits
		.o_valid(finish)                     // 1 bit
	);

endmodule

