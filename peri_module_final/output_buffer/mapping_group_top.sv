module mapping_group_top (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [31:0]          pim_output_1_i,

    input logic [2:0]           pim_mode_i,

    // Buffer
    input logic                 buf_write_en_1_i,
    input logic                 buf_write_en_2_i,

    input logic                 buf_read_en_i,

    input logic                 output_processing_done_i,

    input logic                 load_en_i,

    // Zero point 
    input logic                 zp_en_i,
    input logic signed [31:0]   zp_data_i,

    output logic [31:0]         mapping_group_output_o
);

    // Pim mode
    localparam PIM_PARALLEL = 3'b101;
    localparam PIM_RBR = 3'b110;

    // Encoder
    logic [7:0] pim_output_8b_1 [0:3];

    always_comb begin
        for (int i = 0; i < 4; i++) begin
            pim_output_8b_1[i] = pim_output_1_i[31 - 8 * i -: 8];
        end
    end

    logic [3:0] enc_out_1 [0:3];

    // Buffer
    logic [3:0] buf_out_1 [0:3];
    logic [3:0] buf_out_2 [0:3];

    // Shifter
    logic [6:0] shifter_input [0:3];

    logic shift_counter_en;
    assign shift_counter_en = output_processing_done_i;

    logic [19:0] shifter_output;

    logic accum_buf_write_en;
    assign accum_buf_write_en = output_processing_done_i;

    logic accum_buf_read_en;
    assign accum_buf_read_en = load_en_i;

    logic [31:0] accum_buf_output;


    logic signed [31:0] zp_data;

    //--|Zero point|-----------------------------------------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            zp_data <= '0;
        end else begin
            if (zp_en_i) begin
                zp_data <= zp_data_i;
            end else begin
                zp_data <= zp_data;
            end
        end
    end


    //--|Encoder|----------------------------------------------
    encoder enc (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
            
        .pim_mode_i(pim_mode_i),

        .output_1_i(pim_output_8b_1),

        .enc_out_1_o(enc_out_1)
    );

    //--|Buffer|-----------------------------------------------
    encoder_out_buffer encbuf (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .enc_out_1_i(enc_out_1),

        .buf_write_en_1_i(buf_write_en_1_i),
        .buf_write_en_2_i(buf_write_en_2_i),

        .buf_read_en_i(buf_read_en_i),

        .output_1_o(buf_out_1),
        .output_2_o(buf_out_2)
    );


    always_comb begin
        if (pim_mode_i == PIM_RBR) begin
            for (int i = 0; i < 4; i++) begin
                shifter_input[i] =  buf_out_1[i];
            end
        end else if (pim_mode_i == PIM_PARALLEL) begin
            for (int i = 0; i < 4; i++) begin
                shifter_input[i] = 8 * buf_out_1[i] + buf_out_2[i];
            end
        end else begin
            for (int i = 0; i < 4; i++) begin
                shifter_input[i] =  '0;
            end
        end
    end


    //--|Shifter|----------------------------------------------
    shifter s (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .encoder_output_i(shifter_input),

        .shift_counter_en_i(shift_counter_en), 

        .shifter_output_o(shifter_output)
    );


    //--|Accum buffer|-----------------------------------------
    accum_buffer accum (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .accum_buf_write_en_i(accum_buf_write_en),

        .shifter_output_i(shifter_output),

        .accum_buf_read_en_i(accum_buf_read_en),

        .accum_buf_output_o(accum_buf_output)
    );


    always_comb begin
        if (load_en_i) begin
            mapping_group_output_o = accum_buf_output + $signed(zp_data);
        end else begin
            mapping_group_output_o = '0;
        end
    end

endmodule