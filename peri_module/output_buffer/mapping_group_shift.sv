
// Mapping group module

module mapping_group_shift #(
    parameter PIM_PARALLEL = 3'b100,
    parameter PIM_RBR      = 3'b101
    ) (
    input logic             clk_i,
    input logic             rst_ni,

    input logic [31:0]      output_i,       // 8bit * 4

    // Buffer write & read signal
    input logic             buf_write_en_1_i,
    input logic             buf_write_en_2_i,
    input logic             buf_read_en_i,

    input logic             shift_counter_en_i,

    input logic [2:0]       pim_mode_i,

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
        
        .pim_mode_i(pim_mode_i),

        .buf_write_en_1_i(buf_write_en_1_i),
        .buf_write_en_2_i(buf_write_en_2_i),

        .buf_read_en_i(buf_read_en_i),

        .eFlash_output_i(output_8b[0]),

        .encoder_output_o(encoder_output[0])
    );

    eFlash_to_encoder ete1 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        
        .pim_mode_i(pim_mode_i),

        .buf_write_en_1_i(buf_write_en_1_i),
        .buf_write_en_2_i(buf_write_en_2_i),

        .buf_read_en_i(buf_read_en_i),

        .eFlash_output_i(output_8b[1]),

        .encoder_output_o(encoder_output[1])
    );

    eFlash_to_encoder ete2 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        
        .pim_mode_i(pim_mode_i),

        .buf_write_en_1_i(buf_write_en_1_i),
        .buf_write_en_2_i(buf_write_en_2_i),

        .buf_read_en_i(buf_read_en_i),

        .eFlash_output_i(output_8b[2]),

        .encoder_output_o(encoder_output[2])
    );

    eFlash_to_encoder ete3 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        
        .pim_mode_i(pim_mode_i),

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

    // Counter
    // If the buffer read signal is on, counter + 1

    logic [1:0] shift_counter;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            shift_counter <= '0;
        end else begin
            if (shift_counter_en_i) begin
                shift_counter <= shift_counter + 2'd1;
            end else begin
                shift_counter <= shift_counter;
            end
        end
    end

    always_comb begin
        shift_count_output = '0;      
            case (shift_counter)
                2'b00: shift_count_output = {6'b0, shift_sum_output};
                2'b01: shift_count_output = {4'b0, shift_sum_output, 2'b0};
                2'b10: shift_count_output = {2'b0, shift_sum_output, 4'b0};
                2'b11: shift_count_output = {shift_sum_output, 6'b0};
                default: shift_count_output = '0;
            endcase      
    end

    assign output_o = shift_count_output;



endmodule





    
