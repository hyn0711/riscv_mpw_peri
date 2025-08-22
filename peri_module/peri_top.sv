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
    input logic [1023:0]    eFlash_output_i,

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
    logic buf_read_en, shift_counter_en, zero_point_en, load_en;
    logic [31:0] zero_point;
    logic [5:0] load_cnt;
    logic [1:0] before_load_mode;

    logic [31:0] out_buf_output;

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
        .input_data_o(input_data_buf_in),
        .data_rx_cnt_o(data_rx_cnt),

        .in_buf_write_o(in_buf_write),
        .in_buf_read_o(in_buf_read),

        // output buffer
        .out_buf_data_i(out_buf_output),

        .buf_read_en_o(buf_read_en),
        .shift_counter_en_o(shift_counter_en),

        .zero_point_en_o(zero_point_en),
        .zero_point_o(zero_point),

        .load_en_o(load_en),
        .load_cnt_o(load_cnt),
        .before_load_mode_o(before_load_mode)
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

        .buf_write_en_0_o(buf_write_en_0),
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

    output_buffer_top o_b (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

    // eFlash output 128 * 8 bit
        .output_i(eFlash_output_i),

    // Buffer signal 
        .buf_write_en_0_i(buf_write_en_0),
        .buf_write_en_1_i(buf_write_en_1),
        .buf_write_en_2_i(buf_write_en_2),
        .buf_read_en_i(buf_read_en),

        .shift_counter_en_i(shift_counter_en),
    
        .pim_mode_i(pim_mode),

    // zero point
        .zero_point_en_i(zero_point_en),
        .zero_point_i(zero_point),

    // Load mode
        .pim_en_i(pim_en),
        .col_addr9_i(col_addr9),
        .load_en_i(load_en),
        .load_cnt_i(load_cnt),     // 0 ~ 31
        .before_load_mode_i(before_load_mode),

        .out_buf_o(out_buf_output)
    );


endmodule