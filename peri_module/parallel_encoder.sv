module parallel_encoder (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [7:0]           output_1_i,
    input logic [7:0]           output_2_i,

    output logic [6:0]          parallal_encoder_o
);

    logic [3:0] num_of_1b_1, num_of_1b_2;

    // Check the number of 1 
    always_comb begin
        num_of_1b_1 = '0;
        case (output_1_i)
            8'b00000000 : num_of_1b_1 = 4'd0;
            8'b10000000 : num_of_1b_1 = 4'd1;
            8'b11000000 : num_of_1b_1 = 4'd2;
            8'b11100000 : num_of_1b_1 = 4'd3;
            8'b11110000 : num_of_1b_1 = 4'd4;
            8'b11111000 : num_of_1b_1 = 4'd5;
            8'b11111100 : num_of_1b_1 = 4'd6;
            8'b11111110 : num_of_1b_1 = 4'd7;
            8'b11111111 : num_of_1b_1 = 4'd8;
            default: num_of_1b_1 = '0;
        endcase
    end

    always_comb begin
        num_of_1b_2 = '0;
        case (output_2_i)
            8'b00000000 : num_of_1b_2 = 4'd0;
            8'b10000000 : num_of_1b_2 = 4'd1;
            8'b11000000 : num_of_1b_2 = 4'd2;
            8'b11100000 : num_of_1b_2 = 4'd3;
            8'b11110000 : num_of_1b_2 = 4'd4;
            8'b11111000 : num_of_1b_2 = 4'd5;
            8'b11111100 : num_of_1b_2 = 4'd6;
            8'b11111110 : num_of_1b_2 = 4'd7;
            8'b11111111 : num_of_1b_2 = 4'd8;
            default: num_of_1b_2 = '0;
        endcase
    end

    assign parallal_encoder_o = 8 * num_of_1b_1 + num_of_1b_2;

endmodule