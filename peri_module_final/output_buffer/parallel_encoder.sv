module parallel_encoder (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [7:0]           output_i,

    output logic [3:0]          parallel_encoder_o
);

    logic [3:0] encoder_parallel;

    // Check the number of 1 
    always_comb begin
        encoder_parallel = '0;
        case (output_i)
            8'b00000000 : encoder_parallel = 4'd0;
            8'b10000000 : encoder_parallel = 4'd1;
            8'b11000000 : encoder_parallel = 4'd2;
            8'b11100000 : encoder_parallel = 4'd3;
            8'b11110000 : encoder_parallel = 4'd4;
            8'b11111000 : encoder_parallel = 4'd5;
            8'b11111100 : encoder_parallel = 4'd6;
            8'b11111110 : encoder_parallel = 4'd7;
            8'b11111111 : encoder_parallel = 4'd8;
            default: encoder_parallel = '0;
        endcase
    end

    assign parallel_encoder_o = encoder_parallel;

endmodule