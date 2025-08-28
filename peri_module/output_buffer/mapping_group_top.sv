module mapping_group_top (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [31:0]          pim_output_1_i,
    input logic [31:0]          pim_output_2_i,

    input logic [2:0]           pim_mode_i,

    input logic                 output_processing_done_i,

    input logic                 load_en_i,

    // Zero point 
    input logic                 zp_en_i,
    input logic signed [31:0]   zp_data_i,

    output logic [31:0]         mapping_group_output_o
);

    logic [7:0] pim_output_8b_1 [0:3];
    logic [7:0] pim_output_8b_2 [0:3];

    always_comb begin
        for (int i = 0; i < 4; i++) begin
            pim_output_8b_1[i] = pim_output_1_i[31 - 8 * i -: 8];
            pim_output_8b_2[i] = pim_output_2_i[31 - 8 * i -: 8];
        end
    end

    logic [6:0] encoder_output [0:3];

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


    encoder enc (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
    
        .pim_mode_i(pim_mode_i),

        .output_1_i(pim_output_8b_1),
        .output_2_i(pim_output_8b_2),

        .encoder_output_o(encoder_output)
    );

    shifter s (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .encoder_output_i(encoder_output),

        .shift_counter_en_i(shift_counter_en), 

        .shifter_output_o(shifter_output)
    );

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