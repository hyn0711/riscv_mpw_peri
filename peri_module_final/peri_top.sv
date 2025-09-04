// Peri top 
// not include output buffer


module peri_top (
    input logic             clk_i,
    input logic             rst_ni,

    // RISC-V
    input logic [31:0]      address_i,
    input logic [31:0]      data_i,

    output logic [31:0]     data_o,

    // PIM
    input logic [1023:0]    eFlash_output_1_i,


    // Row wise signal
    output logic [1:0]      MODE_o,
    output logic [127:0]    WL_SEL_o,
    output logic [127:0]    VPASS_EN_o,

    output logic [7:0]      DUML_o,
    output logic [7:0]      CSL_o,
    output logic [31:0]     BSEL_o,
    output logic [7:0]      CSEL_o,
    output logic            ADC_EN1_o,
    output logic            ADC_EN2_o,
    output logic            QDAC_o,
    output logic [1:0]      RSEL_o,

    // Col wise signal
    output logic [255:0]    DUMH_o,
    output logic [127:0]    PRECB_o,
    output logic [127:0]    DISC_o
);

    // Peri controller signal 
    logic pim_en;
    logic [2:0] pim_mode;
    logic [3:0] exec_cnt;
    logic [6:0] row_addr7;
    logic [8:0] col_addr9;

    logic [31:0] input_data_buf_in;
    logic [1:0] input_data_to_driver [0:255];
    logic [3:0] data_rx_cnt;
    logic in_buf_write, in_buf_read;

    // Row driver -> Output buffer
    logic buf_write_en_0, buf_write_en_1, buf_write_en_2;

    // Controller -> Output buffer
    logic buf_read_en, output_processing_done, zero_point_en, load_en;
    logic [31:0] zero_point;
    logic [4:0] load_cnt;
    logic [2:0] before_load_mode;

    logic [31:0] out_buf_output;

    logic read_mode_buf_w_en;

    peri_controller p_c (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        // RISC-V
        .address_i(address_i),
        .data_i(data_i),

        .data_o(data_o),

        // eFlash row driver
        .pim_en_o(pim_en),
        .pim_mode_o(pim_mode),
        .exec_cnt_o(exec_cnt),

        .row_addr7_o(row_addr7),
        .col_addr9_o(col_addr9),

        // input buffer
        .in_buf_write_o(in_buf_write),
        .in_buf_read_o(in_buf_read),
        .input_data_o(input_data_buf_in),
        .data_rx_cnt_o(data_rx_cnt),

        // output buffer
        .before_load_mode_o(before_load_mode),
        .read_mode_buf_w_en_0(read_mode_buf_w_en),

        .zp_en_o(zero_point_en),
        .zp_data_o(zero_point),

        .pim_out_buf_r_en_o(buf_read_en),
        .output_processing_done_o(output_processing_done),

        .load_en_o(load_en),
        .load_cnt_o(load_cnt),

        .output_buffer_result_i(out_buf_output)
    );


    eFlash_row_driver r_d (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

    // eFlash signal control
        .pim_en_i(pim_en),
        .pim_mode_i(pim_mode),
        .exec_cnt_i(exec_cnt),

    // address
        .row_addr7_i(row_addr7),
        .col_addr9_i(col_addr9),

    // input buffer
        .input_data_i(input_data_buf_in),
        .data_cnt_i(data_rx_cnt),

        .in_buf_write_i(in_buf_write),
        .in_buf_read_i(in_buf_read),

        .input_data_o(input_data_to_driver),

        //eFlash signal 
        .MODE_o(MODE_o),
        .WL_SEL_o(WL_SEL_o),
        .VPASS_EN_o(VPASS_EN_o),

        .DUML_o(DUML_o),
        .CSL_o(CSL_o),
        .BSEL_o(BSEL_o),
        .CSEL_o(CSEL_o),
        .ADC_EN1_o(ADC_EN1_o),
        .ADC_EN2_o(ADC_EN2_o),
        .QDAC_o(QDAC_o),
        .RSEL_o(RSEL_o),

        //.buf_write_en_0_o(buf_write_en_0),
        .buf_write_en_1_o(buf_write_en_1),
        .buf_write_en_2_o(buf_write_en_2)
);

    eFlash_col_driver c_d (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .input_data_i(input_data_to_driver),

    // eFlash signal control
        .pim_en_i(pim_en),
        .pim_mode_i(pim_mode),
        .exec_cnt_i(exec_cnt),

        .row_addr7_i(row_addr7),
        .col_addr9_i(col_addr9),

        .DUMH_o(DUMH_o),
        .PRECB_o(PRECB_o),
        .DISC_o(DISC_o)
    );

    

    output_buffer_top o_b_t (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .pim_output_1_i(eFlash_output_1_i),

        .pim_mode_i(pim_mode),
        .before_load_mode_i(before_load_mode),

        .output_processing_done_i(output_processing_done),

        .buf_write_en_1_i(buf_write_en_1),
        .buf_write_en_2_i(buf_write_en_2),
        .buf_read_en_i(buf_read_en),

        .read_mode_buf_w_en_i(read_mode_buf_w_en),
        .col_addr9_i(col_addr9),

        .load_en_i(load_en),
        .load_cnt_i(load_cnt), 

        .zp_en_i(zero_point_en),
        .zp_data_i(zero_point),

        .output_buffer_o(out_buf_output)
    );


endmodule