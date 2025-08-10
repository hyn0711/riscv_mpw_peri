// Peri top 
// not include output buffer


module peri_top (
    input logic             clk_i,
    input logic             rst_ni,

    // RISC-V
    input logic [31:0]      address_i,
    input logic [31:0]      data_i,

    //output logic [31:0]     data_o,

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
    output logic [7:0]      QDAC_o,
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

    // Debug
    logic [511:0] debug_input_data;

    always_comb begin
        for (int unsigned i = 0; i <256; i ++) begin
            debug_input_data[2*i +: 2] = input_data_to_driver[i];
        end
    end
    
    peri_controller p_c (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        // RISC-V
        .address_i(address_i),
        .data_i(data_i),

        .data_o(),

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
        //output logic        out_buf_write_o,
        .out_buf_read_o(),

        .read_ptr_o(),

        .out_buf_data_i()
    );

    eFlash_row_top r_t (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        // from Peri controller
        .pim_en_i(pim_en),
        .pim_mode_i(pim_mode),
        .exec_cnt_i(exec_cnt),

        .row_addr7_i(row_addr7),
        .col_addr9_i(col_addr9),

        .input_data_i(input_data_buf_in),
        .data_rx_cnt_i(data_rx_cnt),

        .in_buf_write_i(in_buf_write),
        .in_buf_read_i(in_buf_read),

        // Output signal
        // Input data to col driver
        .input_data_o(input_data_to_driver),

        // eFlash signal 
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
        .RSEL_o(RSEL_o)
    );

    eFlash_col_driver c_d (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

    // Buffer input
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


endmodule