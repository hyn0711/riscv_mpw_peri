
// Mapping group module

module mapping_group_shift (
    input logic             clk_i,
    input logic             rst_ni,

    input logic [31:0]      output_i,       // 8bit * 4

    // Buffer write & read signal
    input logic             buf_write_en_1_i,
    input logic             buf_write_en_2_i,
    input logic             buf_read_en_i,

    input logic             mode_i,

    // Counter shifter data
    input logic [1:0]       shift_count_i,

    output logic [31:0]     output_o
);

    logic [7:0]     output_8b [0:3];
    logic [6:0]     encoder_output [0:3];
    logic [13:0]    shift_output [0:3];
    logic [13:0]    shift_sum_output;

    logic [19:0]    shift_count_output;

    assign output_8b[0] = output_i[31:24];
    assign output_8b[1] = output_i[23:16];
    assign output_8b[2] = output_i[15:8];
    assign output_8b[3] = output_i[7:0];

    // Encoder for mapping group //

    eFlash_to_encoder ete0 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        
        .mode_i(mode_i),

        .buf_write_en_1_i(buf_write_en_1_i),
        .buf_write_en_2_i(buf_write_en_2_i),

        .buf_read_en_i(buf_read_en_i),

        .eFlash_output_i(output_8b[0]),

        .encoder_output_o(encoder_output[0])
    );

    eFlash_to_encoder ete1 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        
        .mode_i(mode_i),

        .buf_write_en_1_i(buf_write_en_1_i),
        .buf_write_en_2_i(buf_write_en_2_i),

        .buf_read_en_i(buf_read_en_i),

        .eFlash_output_i(output_8b[1]),

        .encoder_output_o(encoder_output[1])
    );

    eFlash_to_encoder ete2 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        
        .mode_i(mode_i),

        .buf_write_en_1_i(buf_write_en_1_i),
        .buf_write_en_2_i(buf_write_en_2_i),

        .buf_read_en_i(buf_read_en_i),

        .eFlash_output_i(output_8b[2]),

        .encoder_output_o(encoder_output[2])
    );

    eFlash_to_encoder ete3 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        
        .mode_i(mode_i),

        .buf_write_en_1_i(buf_write_en_1_i),
        .buf_write_en_2_i(buf_write_en_2_i),

        .buf_read_en_i(buf_read_en_i),

        .eFlash_output_i(output_8b[3]),

        .encoder_output_o(encoder_output[3])
    );

    // Shifting //
    assign shift_output[0] = {1'b0, encoder_output[0], 6'b0};
    assign shift_output[1] = {3'b0, encoder_output[1], 4'b0};
    assign shift_output[2] = {5'b0, encoder_output[2], 2'b0};
    assign shift_output[3] = {7'b0, encoder_output[3]};

    assign shift_sum_output = shift_output[0] + shift_output[1] + shift_output[2] + shift_output[3];


    // Counter shifter //
    // 0 : 0
    // 1 : 2
    // 2 : 4
    // 3 : 6

    always_comb begin
        shift_count_output = '0;
        
            case (shift_count_i)
                2'b00: shift_count_output = {6'b0, shift_sum_output};
                2'b01: shift_count_output = {4'b0, shift_sum_output, 2'b0};
                2'b10: shift_count_output = {2'b0, shift_sum_output, 4'b0};
                2'b11: shift_count_output = {shift_sum_output, 6'b0};
                default: shift_count_output = '0;
            endcase
        
    end

    assign output_o = shift_count_output;

    // logic [31:0] accum_buf;

    // always_ff @(posedge clk_i or negedge rst_ni) begin
    //     if (!rst_ni) begin
    //         accum_buf <= '0;
    //     end else begin
    //         if (buf_read_en_i) begin
    //             accum_buf <= accum_buf + shift_count_output;
    //         end else begin
    //             accum_buf <= accum_buf;
    //         end
    //     end
    // end

    // assign output_o = accum_buf;

endmodule


// Buffer to store the data after count shifting //


    
