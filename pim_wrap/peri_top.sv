module peri_top (
    input logic                 clk_i,
    input logic                 rst_ni,

    // RISC-V <-> PERI
    input logic [31:0]          address_i,
    input logic [31:0]          data_i,
    
    output logic [31:0]         data_o,

    // PERI <-> PIM
    output logic [1:0]          MODE_o,
    output logic [127:0]        WL_SEL_o,
    output logic [127:0]        VPASS_EN_o,

    output logic [255:0]        DUMH_o,
    output logic [255:0]        DUML_o,
    output logic [7:0]          CSL_o,
    output logic [3:0]          BSEL_o,
    output logic [3:0]          BSELB_o,
    output logic [7:0]          CSEL_o,
    output logic [7:0]          CSELB_o,
    output logic [127:0]        PRECB_o,
    output logic [127:0]        DISC_o,
    output logic                ADC_EN_o,
    output logic                DFF_o,
    output logic                QDAC_o, 

    input logic [1023:0]        output_i
);

    logic erase_en, program_en, read_en, parallel_en, rbr_en, load_en;
    logic [6:0] row_addr7;
    logic [8:0] col_addr9;
    logic [3:0] exec_cnt;

    logic [1:0] input_data_buf_driver[0:255];
    logic [511:0] input_flat_buf_driver;

    logic [31:0] input_data_contr_buf;
    logic [3:0] data_rx_cnt;
    logic in_buf_write, in_buf_read, out_buf_write, out_buf_read;

    logic [7:0] read_ptr;

    logic [31:0] output_buf_contr;


    // Peri controller
    peri_controller p_c(
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    // RISC-V
    .address_i(address_i),
    .data_i(data_i),

    .data_o(data_o),

    // eFLASH driver
    .erase_en_o(erase_en),
    .program_en_o(program_en),
    .read_en_o(read_en),
    .parallel_en_o(parallel_en),
    .rbr_en_o(rbr_en),
    .load_en_o(load_en),

    .row_addr7_o(row_addr7),
    .col_addr9_o(col_addr9),

    .exec_cnt_o(exec_cnt),

    // input buffer
    .input_data_o(input_data_contr_buf),
    .data_rx_cnt_o(data_rx_cnt),

    .in_buf_write_o(in_buf_write),
    
    .in_buf_read_o(in_buf_read),

    // output buffer
    //.out_buf_write_o(out_buf_write),
    .out_buf_read_o(out_buf_read),

    .read_ptr_o(read_ptr),

    .out_buf_data_i(output_buf_contr)
    );

    // eFLASH driver
    eFLASH_driver e_d(
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    // mode
    .erase_en_i(erase_en),
    .program_en_i(program_en),
    .read_en_i(read_en),
    .parallel_en_i(parallel_en),
    .rowbyrow_en_i(rbr_en),

    // address
    .row_addr7_i(row_addr7),
    .col_addr9_i(col_addr9),

    // input
    .input_i(input_data_buf_driver),  
    //.input_flat_i(input_flat_buf_driver),       // for testbench     

    .exec_cnt_i(exec_cnt),

    // HVS signal
    .MODE_o(MODE_o),
    .WL_SEL_o(WL_SEL_o),
    .VPASS_EN_o(VPASS_EN_o),

    // eFLASH signal
    .DUMH_o(DUMH_o),
    .DUML_o(DUML_o),
    .CSL_o(CSL_o),
    .BSEL_o(BSEL_o),
    .BSELB_o(BSELB_o),
    .CSEL_o(CSEL_o),
    .CSELB_o(CSELB_o),
    .PRECB_o(PRECB_o),
    .DISC_o(DISC_o),
    .ADC_EN_o(ADC_EN_o),
    .DFF_o(DFF_o),
    .QDAC_o(QDAC_o), 

    .out_buf_write_o(out_buf_write)
    );

    // input buffer
    input_buffer i_b(
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .input_data_i(input_data_contr_buf),
    .data_cnt_i(data_rx_cnt),

    .in_buf_write_i(in_buf_write),
    .in_buf_read_i(in_buf_read),     // mode execution
    
    .parallel_read_i(parallel_en),
    .rowbyrow_read_i(rbr_en),

    .data_o(input_data_buf_driver)
    //.data_flat_o(input_flat_buf_driver)  // for testbench gtkwave
    );

    // output buffer
    output_buffer o_b(
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    .output_i(output_i),

    .read_ptr_i(read_ptr),

    // control signal
    .output_write_en_i(out_buf_write),
    .output_read_en_i(out_buf_read),

    .output_o(output_buf_contr)
    );

endmodule