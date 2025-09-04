module encoder (
    input logic                 clk_i,
    input logic                 rst_ni,
    
    input logic [2:0]           pim_mode_i,

    // output from eFlash
    input logic [7:0]           output_1_i [0:3],

    output logic [3:0]          enc_out_1_o [0:3]
);
    // Pim mode
    localparam PIM_PARALLEL = 3'b101;
    localparam PIM_RBR = 3'b110;
            
    //--|RBR mode|---------------------------------------------------
    logic [3:0] rbr_enc_output[0:3];
    generate 
        for (genvar i = 0; i < 4; i++) begin
            rbr_encoder rbr (
                .clk_i(clk_i),
                .rst_ni(rst_ni),

                .output_i(output_1_i[i]),

                .rbr_encoder_o(rbr_enc_output[i])
            );
        end
    endgenerate
    
    //--|PARALLEL mode|----------------------------------------------
    
    logic [3:0] parallel_enc_output_1[0:3];

    // First output
    generate
        for (genvar i = 0; i < 4; i++) begin
            parallel_encoder parallel (
                .clk_i(clk_i),
                .rst_ni(rst_ni),

                .output_i(output_1_i[i]),

                .parallel_encoder_o(parallel_enc_output_1[i])
            );
        end
    endgenerate


    //--|Encoder output|----------------------------------------------
    always_comb begin
        for (int i = 0; i < 4; i++) begin
            enc_out_1_o[i] = '0;
        end
        if (pim_mode_i == PIM_PARALLEL) begin
            for (int i = 0; i < 4; i++) begin
                enc_out_1_o[i] = parallel_enc_output_1[i];
            end
        end else if (pim_mode_i == PIM_RBR) begin
            for (int i = 0; i < 4; i++) begin
                enc_out_1_o[i] = rbr_enc_output[i];
            end
        end else begin
            for (int i = 0; i < 4; i++) begin
                enc_out_1_o[i] = '0;
            end
        end
    end

endmodule