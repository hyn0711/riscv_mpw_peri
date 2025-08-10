module eFlash_row_top (
    input logic             clk_i,
    input logic             rst_ni,

    // from Peri controller
    input logic             pim_en_i,
    input logic [2:0]       pim_mode_i,
    input logic [3:0]       exec_cnt_i,

    input logic [6:0]       row_addr7_i,
    input logic [8:0]       col_addr9_i,

    input logic [31:0]      input_data_i,
    input logic [3:0]       data_rx_cnt_i,

    input logic             in_buf_write_i,
    input logic             in_buf_read_i,

    // Output signal
    // Input data to col driver
    output logic [1:0]      input_data_o [0:255],

    // eFlash signal 
    output logic [1:0]      MODE_o,
    output logic [127:0]    WL_SEL_o,
    output logic [127:0]    VPASS_EN_o,

    output logic [7:0]      DUML_o,
    output logic [7:0]      CSL_o,
    output logic [31:0]     BSEL_o,
    output logic [7:0]      CSEL_o,
    output logic            ADC_EN1_o,
    output logic            ADC_EN2_o,
    output logic [7:0]      QDAC_o,
    output logic [1:0]      RSEL_o
);


    input_buffer i_b(
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        // Buffer
        .input_data_i(input_data_i),
        .data_cnt_i(data_rx_cnt_i),

        .in_buf_write_i(in_buf_write_i),
        .in_buf_read_i(in_buf_read_i),

        // eFlash signal control
        .pim_mode_i(pim_mode_i),

        .input_data_o(input_data_o)
    );

    eFlash_row_driver r_d(
        .clk_i(clk_i),
        .rst_ni(rst_ni),

    // eFlash signal control
        .pim_en_i(pim_en_i),
        .pim_mode_i(pim_mode_i),
        .exec_cnt_i(exec_cnt_i),

    // address
        .row_addr7_i(row_addr7_i),
        .col_addr9_i(col_addr9_i),

    // HVS signal
        .MODE_o(MODE_o),
        .WL_SEL_o(WL_SEL_o),
        .VPASS_EN_o(VPASS_EN_o),

    // eFLASH signal
        .DUML_o(DUML_o),
        .CSL_o(CSL_o),
        .BSEL_o(BSEL_o),
        .CSEL_o(CSEL_o),
        .ADC_EN1_o(ADC_EN1_o),
        .ADC_EN2_o(ADC_EN2_o),
        .QDAC_o(QDAC_o),
        .RSEL_o(RSEL_o)
);


endmodule