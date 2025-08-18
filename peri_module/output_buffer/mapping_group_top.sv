module mapping_group_top (
    input logic             clk_i,
    input logic             rst_ni,

    input logic [31:0]      output_i,

    input logic             buf_write_en_1_i,
    input logic             buf_write_en_2_i,
    input logic             buf_read_en_i,

    input logic             shift_counter_en_i,

    input logic             mode_i,

    input logic             accum_buf_write_i,
    //input logic             accum_buf_read_i,

    input logic             zero_point_en_i,
    input logic [31:0]      zero_point_i,

    // Load mode 
    input logic             load_en_i,

    output logic [31:0]     mapping_group_o
);

    logic [31:0] output_32b, accum_buf_o;

    logic [31:0] zero_point_r;

    mapping_group_shift mgs (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .output_i(output_i),       // 8bit * 4

    // Buffer write & read signal
        .buf_write_en_1_i(buf_write_en_1_i),
        .buf_write_en_2_i(buf_write_en_2_i),
        .buf_read_en_i(buf_read_en_i),

        .shift_counter_en_i(shift_counter_en_i),

        .mode_i(mode_i),

        .output_o(output_32b)
    );

    accum_buffer ab (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .write_en_i(accum_buf_write_i),

        .data_i(output_32b),

        .read_en_i(load_en_i),
        .zero_point_i(zero_point_r),

        .data_o(accum_buf_o)
    );

    // Zero point register

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            zero_point_r <= '0;
        end else begin
            if (zero_point_en_i) begin
                zero_point_r <= zero_point_i;
            end else begin
                zero_point_r <= zero_point_r;
            end 
        end
    end

    // Load mode 
    // always_ff @(posedge clk_i or negedge rst_ni) begin
    //     if (!rst_ni) begin
    //         mapping_group_o <= '0;
    //     end else begin
    //         if (load_en_i) begin
    //             mapping_group_o <= accum_buf_o;
    //         end else begin
    //             mapping_group_o <= '0;
    //         end
    //     end
    // end

    always_comb begin
        if (load_en_i) begin
            mapping_group_o = accum_buf_o;
        end else begin
            mapping_group_o = '0;
        end
    end



endmodule 