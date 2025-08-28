module output_buffer_read_mode (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [1023:0]        pim_output_i,  

    input logic                 read_mode_buf_w_en_i,       
    input logic                 read_load_en_i,

    input logic [8:0]           col_addr9_i,

    output logic [31:0]         read_mode_encoder_o
);

    logic [3:0] buf_reg;

    logic [6:0] num_adc;
    assign num_adc = col_addr9_i[8:2];

    logic [7:0] output_8b;
    assign output_8b = pim_output_i[1023 - 8 * num_adc -: 8];

    

    // logic [7:0] read_output_8b;
    // assign read_output_8b = buf_reg;

    // Encoder
    logic [3:0] enc_output;
    always_comb begin
        enc_output = '0;
        case (output_8b)
            8'b00000000 : enc_output = 4'd9;
            8'b10000000 : enc_output = 4'd9;
            8'b11000000 : enc_output = 4'd6;
            8'b11100000 : enc_output = 4'd6;
            8'b11110000 : enc_output = 4'd4;
            8'b11111000 : enc_output = 4'd3;
            8'b11111100 : enc_output = 4'd2;
            8'b11111110 : enc_output = 4'd1;
            8'b11111111 : enc_output = 4'd0;
            default: enc_output = '0;
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            buf_reg <= '0;
        end else begin
            if (read_mode_buf_w_en_i) begin
                buf_reg <= enc_output;
            end else begin
                buf_reg <= buf_reg;
            end
        end
    end

    // Read buffer
    always_comb begin
        if (read_load_en_i) begin
            read_mode_encoder_o = {28'b0, buf_reg};
        end else begin
            read_mode_encoder_o = '0;
        end
    end

endmodule