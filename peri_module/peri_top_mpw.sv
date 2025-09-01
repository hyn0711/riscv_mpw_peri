module peri_top_mpw (
    input logic             CLK,
    input logic             RSTN,

    // RISC-V
    input logic [31:0]      ADDRESS_I,
    input logic [31:0]      DATA_I,

    output logic [31:0]     DATA_O,

    // PIM
    input logic [1023:0]    EFLASH_OUTPUT_1_I,
    input logic [1023:0]    EFLASH_OUTPUT_2_I,


    // Row wise signal
    output logic [1:0]      MODE_O,
    output logic [127:0]    WL_SEL_O,
    output logic [127:0]    VPASS_EN_O,

    output logic [7:0]      DUML_O,
    output logic [7:0]      CSL_O,
    output logic [31:0]     BSEL_O,
    output logic [7:0]      CSEL_O,
    output logic            ADC_EN1_O,
    output logic            ADC_EN2_O,
    output logic            QDAC_O,
    output logic [1:0]      RSEL_O,

    // Col wise signal
    output logic [255:0]    DUMH_O,
    output logic [127:0]    PRECB_O,
    output logic [127:0]    DISC_O
);

peri_top peritop (
        .clk_i(CLK),
        .rst_ni(RSTN),

        // RISC-V
        .address_i(ADDRESS_I),
        .data_i(DATA_I),

        .data_o(DATA_O),

        // PIM
        .eFlash_output_1_i(EFLASH_OUTPUT_1_I),
        .eFlash_output_2_i(EFLASH_OUTPUT_2_I),


        // Row wise signal
        .MODE_o(MODE_O),
        .WL_SEL_o(WL_SEL_O),
        .VPASS_EN_o(VPASS_EN_O),

        .DUML_o(DUML_O),
        .CSL_o(CSL_O),
        .BSEL_o(BSEL_O),
        .CSEL_o(CSEL_O),
        .ADC_EN1_o(ADC_EN1_O),
        .ADC_EN2_o(ADC_EN2_O),
        .QDAC_o(QDAC_O),
        .RSEL_o(RSEL_O),

        // Col wise signal
        .DUMH_o(DUMH_O),
        .PRECB_o(PRECB_O),
        .DISC_o(DISC_O)
    );

endmodule