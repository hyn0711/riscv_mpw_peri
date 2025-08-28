module rbr_encoder (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [7:0]           output_i,

    output logic [3:0]          rbr_encoder_o
);

    logic [3:0] encoder_rbr;

    always_comb begin
        encoder_rbr = '0;
        case (output_i)
            8'b00000000 : encoder_rbr = 4'd9;
            8'b10000000 : encoder_rbr = 4'd9;
            8'b11000000 : encoder_rbr = 4'd6;
            8'b11100000 : encoder_rbr = 4'd6;
            8'b11110000 : encoder_rbr = 4'd4;
            8'b11111000 : encoder_rbr = 4'd3;
            8'b11111100 : encoder_rbr = 4'd2;
            8'b11111110 : encoder_rbr = 4'd1;
            8'b11111111 : encoder_rbr = 4'd0;
            default: encoder_rbr = '0;
        endcase
    end

    assign rbr_encoder_o = encoder_rbr;

endmodule