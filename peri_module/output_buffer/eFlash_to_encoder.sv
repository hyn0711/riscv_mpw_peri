
// Top module
// eFlash output to encoder

module eFlash_to_encoder (
    input logic         clk_i,
    input logic         rst_ni,
    
    // Mode data (rbr or parallel)
    // 0: rbr, 1: parallel
    input logic [2:0]   pim_mode_i,

    // Buffer write, read signal
    input logic         buf_write_en_1_i,
    input logic         buf_write_en_2_i,

    input logic         buf_read_en_i,

    input logic [7:0]   eFlash_output_i,

    output logic [6:0]  encoder_output_o
);

    logic [7:0] buf_output_1, buf_output_2;

    // Seq
    buffer p_buf (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .output_i(eFlash_output_i),

        // buffer write signal
        .buf_write_en_1_i(buf_write_en_1_i),
        .buf_write_en_2_i(buf_write_en_2_i),

        // buffer read signal
        .buf_read_en_i(buf_read_en_i),

        .output_1_o(buf_output_1),
        .output_2_o(buf_output_2)
    );

    // Comb
    encoder enc (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .pim_mode_i(pim_mode_i),

        .buf_output_1_i(buf_output_1),
        .buf_output_2_i(buf_output_2),

        .buf_read_en_i(buf_read_en_i),

        .encoder_output_o(encoder_output_o)
    );

endmodule

// Encoder //

module encoder (
    input logic         clk_i,
    input logic         rst_ni,

    input logic [2:0]   pim_mode_i,

    // Output data from buffer
    input logic [7:0]   buf_output_1_i,
    input logic [7:0]   buf_output_2_i,

    input logic         buf_read_en_i,

    output logic [6:0]  encoder_output_o
);

    logic [7:0]     parallel_output_1, parallel_output_2, rbr_output;

    logic [3:0]     rbr_enc_output;
    logic [6:0]     parallel_enc_output;

    logic [6:0]     encoder_output;

    // pim_mode_i = 3'b110: rbr mode
    // pim_mode_i = 3'b101: parallel mode
    
    // Demux 
    always_comb begin
        parallel_output_1 = '0;
        parallel_output_2 = '0;
        rbr_output = '0;
        if (pim_mode_i == 3'b101) begin
            parallel_output_1 = buf_output_1_i;
            parallel_output_2 = buf_output_2_i;
        end else if (pim_mode_i == 3'b110) begin
            rbr_output = buf_output_1_i;
        end else begin
            parallel_output_1 = '0;
            parallel_output_2 = '0;
            rbr_output = '0;
        end
    end

    rbr_encoder rbr (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .output_i(rbr_output),

        .rbr_enc_output_o(rbr_enc_output)
    );

    parallel_encoder parallel (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .output_1_i(parallel_output_1),
        .output_2_i(parallel_output_2),

        .parallel_enc_output_o(parallel_enc_output)
    );

    always_comb begin
        if (pim_mode_i == 3'b101) begin
            encoder_output = parallel_enc_output;
        end else if (pim_mode_i == 3'b110) begin
            encoder_output = rbr_enc_output;
        end else begin
            encoder_output = '0;
        end 
    end
    //assign encoder_output = mode_i ? parallel_enc_output : rbr_enc_output;
    assign encoder_output_o = buf_read_en_i ? encoder_output : '0;

endmodule


module rbr_encoder (
    input logic         clk_i,
    input logic         rst_ni,

    input logic [7:0]   output_i,

    output logic [3:0]  rbr_enc_output_o
);

    logic [3:0]     output_d;

    always_comb begin
        output_d = '0;
        case (output_i)
            8'b00000000 : output_d = 4'd9;
            8'b10000000 : output_d = 4'd9;
            8'b11000000 : output_d = 4'd6;
            8'b11100000 : output_d = 4'd6;
            8'b11110000 : output_d = 4'd4;
            8'b11111000 : output_d = 4'd3;
            8'b11111100 : output_d = 4'd2;
            8'b11111110 : output_d = 4'd1;
            8'b11111111 : output_d = 4'd0;
            default: output_d = '0;
        endcase
    end

    assign rbr_enc_output_o = output_d;

endmodule



module parallel_encoder (
    input logic         clk_i,
    input logic         rst_ni,

    input logic [7:0]   output_1_i,
    input logic [7:0]   output_2_i,

    output logic [6:0]  parallel_enc_output_o
);

    logic [3:0]     output_4b_1;
    logic [3:0]     output_4b_2;

    parallel_num_encoder enc1 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .output_8b_i(output_1_i),

        .output_4b_o(output_4b_1)
    );

    parallel_num_encoder enc2 (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .output_8b_i(output_2_i),

        .output_4b_o(output_4b_2)
    );

    assign parallel_enc_output_o = 8 * output_4b_1 + output_4b_2;

endmodule

// Parallel mode encoder
// Check the number of 1
module parallel_num_encoder (
    input logic         clk_i,
    input logic         rst_ni,

    input logic [7:0]   output_8b_i,

    output logic [3:0]  output_4b_o
);

    always_comb begin
        output_4b_o = '0;
        case (output_8b_i)
            8'b00000000 : output_4b_o = 4'd0;
            8'b10000000 : output_4b_o = 4'd1;
            8'b11000000 : output_4b_o = 4'd2;
            8'b11100000 : output_4b_o = 4'd3;
            8'b11110000 : output_4b_o = 4'd4;
            8'b11111000 : output_4b_o = 4'd5;
            8'b11111100 : output_4b_o = 4'd6;
            8'b11111110 : output_4b_o = 4'd7;
            8'b11111111 : output_4b_o = 4'd8;
            default: output_4b_o = '0;
        endcase
    end

endmodule




// Output buffer //
// Store 8 bit output * 2 before encoding for parallel mode
// Store 8 bit output for rbr mode

module buffer (
    input logic         clk_i,
    input logic         rst_ni,

    input logic [7:0]   output_i,

    // buffer write signal
    input logic         buf_write_en_1_i,
    input logic         buf_write_en_2_i,

    // buffer read signal
    input logic         buf_read_en_i,

    output logic [7:0]  output_1_o,
    output logic [7:0]  output_2_o
);

    logic [7:0]     mem_1;
    logic [7:0]     mem_2;

    // Buffer write
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            mem_1 <= '0;
            mem_2 <= '0;
        end else begin
            if (buf_write_en_1_i) begin
                mem_1 <= output_i;
            end else if (buf_write_en_2_i) begin
                mem_2 <= output_i;
            end else begin
                mem_1 <= mem_1;
                mem_2 <= mem_2;
            end
        end
    end

    // Buffer read
    always_comb begin
        if (buf_read_en_i) begin
            output_1_o = mem_1;
            output_2_o = mem_2;
        end else begin
            output_1_o = '0;
            output_2_o = '0;
        end
    end

endmodule


