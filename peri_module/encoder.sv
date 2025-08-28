module encoder (
    input logic                 clk_i,
    input logic                 rst_ni,
    
    input logic [2:0]           pim_mode_i,

    // output from buffer_8b
    input logic [7:0]           output_1_i [0:3],
    input logic [7:0]           output_2_i [0:3],

    output logic [6:0]          encoder_output_o [0:3]
);
    // Pim mode
    localparam PIM_PARALLEL = 3'b101;
    localparam PIM_RBR = 3'b110;

    logic [7:0] parallel_output_in_1[0:3];
    logic [7:0] parallel_output_in_2[0:3];
    logic [7:0] rbr_output_in[0:3];


    //--|Demux|------------------------------------------------------
    always_comb begin
        for (int i = 0; i < 4; i++) begin
            parallel_output_in_1[i] = '0;
            parallel_output_in_2[i] = '0;
            rbr_output_in[i] = '0;
        end
        if (pim_mode_i == PIM_PARALLEL) begin
            for (int i = 0; i < 4; i++) begin
                parallel_output_in_1[i] = output_1_i[i];
                parallel_output_in_2[i] = output_2_i[i];
                rbr_output_in[i] = '0;
            end
        end else if (pim_mode_i == PIM_RBR) begin
            for (int i = 0; i < 4; i++) begin
                parallel_output_in_1[i] = '0;
                parallel_output_in_2[i] = '0;
                rbr_output_in[i] = output_1_i[i];
            end
        end else begin
            for (int i = 0; i < 4; i++) begin
                parallel_output_in_1[i] = '0;
                parallel_output_in_2[i] = '0;
                rbr_output_in[i] = '0;
            end
        end
    end


    //--|RBR mode|---------------------------------------------------
    logic [3:0] rbr_enc_output[0:3];
    generate 
        for (genvar i = 0; i < 4; i++) begin
            rbr_encoder rbr(
                .clk_i(clk_i),
                .rst_ni(rst_ni),

                .output_i(rbr_output_in[i]),

                .rbr_encoder_o(rbr_enc_output[i])
            );
        end
    endgenerate
    
    
    //--|PARALLEL mode|----------------------------------------------
    logic [6:0] parallel_enc_output[0:3];
    generate
        for (genvar i = 0; i < 4; i++) begin
            parallel_encoder parallel (
                .clk_i(clk_i),
                .rst_ni(rst_ni),

                .output_1_i(parallel_output_in_1[i]),
                .output_2_i(parallel_output_in_2[i]),

                .parallal_encoder_o(parallel_enc_output[i])
            );
        end
    endgenerate

    //--|Encoder output|----------------------------------------------
    always_comb begin
        for (int i = 0; i < 4; i++) begin
            encoder_output_o[i] = '0;
        end
        if (pim_mode_i == PIM_PARALLEL) begin
            for (int i = 0; i < 4; i++) begin
                encoder_output_o[i] = parallel_enc_output[i];
            end
        end else if (pim_mode_i == PIM_RBR) begin
            for (int i = 0; i < 4; i++) begin
                encoder_output_o[i] = rbr_enc_output[i];
            end
        end else begin
            for (int i = 0; i < 4; i++) begin
                encoder_output_o[i] = '0;
            end
        end
    end

endmodule