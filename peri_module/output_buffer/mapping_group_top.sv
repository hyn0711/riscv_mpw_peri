module mapping_group_top (
    input logic             clk_i,
    input logic             rst_ni,

    input logic [31:0]      output_i,

    input logic             buf_write_en_1_i,
    input logic             buf_write_en_2_i,
    input logic             buf_read_en_i,

    input logic             mode_i,

    input logic [1:0]       shift_count_i,

    input logic             accum_buf_write_i,
    input logic             accum_buf_read_i,

    output logic [31:0]     mapping_group_o
);

    logic [31:0] output_32b;

    mapping_group_shift mgs (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .output_i(output_i),       // 8bit * 4

    // Buffer write & read signal
        .buf_write_en_1_i(buf_write_en_1_i),
        .buf_write_en_2_i(buf_write_en_2_i),
        .buf_read_en_i(buf_read_en_i),

        .mode_i(mode_i),

    // Counter shifter data
        .shift_count_i(shift_count_i),

        .output_o(output_32b)
    );

    accum_buffer ab (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .write_en_i(accum_buf_write_i),

        .data_i(output_32b),

        .read_en_i(accum_buf_read_i),

        .data_o(mapping_group_o)
    );

endmodule 