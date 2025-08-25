module output_buffer_top (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [1023:0]        pim_output_i,

    input logic [2:0]           pim_mode_i,
    input logic [2:0]           before_load_mode_i,

    // Store the eFlash pim output when adc_en signal is on
    input logic                 pim_out_buf_w_en_1_i, 
    input logic                 pim_out_buf_w_en_2_i,

    input logic                 pim_out_buf_r_en_i,

    input logic                 output_processing_done_i,


    // Read mode
    input logic                 read_mode_buf_w_en_i,
    input logic [8:0]           col_addr9_i,
    
    // Load mode
    input logic                 load_en_i,
    input logic [4:0]           load_cnt_i,

    // Zero point 
    input logic                 zp_en_i,
    input logic signed [31:0]   zp_data_i,

    output logic [31:0]         output_buffer_o

);
    localparam PIM_READ = 3'b011;
    localparam PIM_PARALLEL = 3'b101;
    localparam PIM_RBR = 3'b110;

    logic read_load_en;
    logic parallel_rbr_load_en [0:31];
    
    logic [31:0] mapping_group_in [0:31];
    logic [31:0] mapping_group_output [0:31];

    logic [31:0] read_mode_output;

    logic [4:0] output_cnt;
    assign output_cnt = 5'd31 - load_cnt_i;

    always_comb begin
        if (before_load_mode_i == PIM_READ) begin
            read_load_en = load_en_i;
            for (int i = 0; i < 32; i++) begin
                parallel_rbr_load_en[i] = '0;
            end
        end else if (before_load_mode_i == PIM_PARALLEL || before_load_mode_i == PIM_RBR) begin
            read_load_en = '0;
            for (int i = 0; i < 32; i++) begin
                parallel_rbr_load_en[i] = load_en_i && (output_cnt == i);
            end
        end else begin
            read_load_en = '0;
            for (int i = 0; i < 32; i++) begin
                parallel_rbr_load_en[i] = '0;
            end
        end
    end


    always_comb begin
        for (int i = 0; i < 32; i++) begin
            mapping_group_in[i] = pim_output_i[1023 - 32 * i -: 32];
        end
    end
   
    generate
        for (genvar i = 0; i < 32; i++) begin
            mapping_group_top mgt (
                    .clk_i(clk_i),
                    .rst_ni(rst_ni),

                    .pim_output_i(mapping_group_in[i]),

                    .pim_out_buf_w_en_1_i(pim_out_buf_w_en_1_i),
                    .pim_out_buf_w_en_2_i(pim_out_buf_w_en_2_i),

                    .pim_out_buf_r_en_i(pim_out_buf_r_en_i),

                    .pim_mode_i(pim_mode_i),

                    .output_processing_done_i(output_processing_done_i),

                    .load_en_i(parallel_rbr_load_en[i]),

                // Zero point 
                    .zp_en_i(zp_en_i),
                    .zp_data_i(zp_data_i),

                    .mapping_group_output_o(mapping_group_output[i])
            );
        end
    endgenerate

    output_buffer_read_mode read_mode (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .pim_output_i(pim_output_i),  

        .read_mode_buf_w_en_i(read_mode_buf_w_en_i),
        .read_mode_buf_r_en_i(read_load_en),

        .col_addr9_i(col_addr9_i),

        .read_mode_encoder_o(read_mode_output)
    );

    always_comb begin
        if (read_load_en) begin
            output_buffer_o = read_mode_output;
        end else if (load_en_i) begin
            if (output_cnt == 5'd0) begin
                output_buffer_o = mapping_group_output[0];
            end else if (output_cnt == 5'd1) begin
                output_buffer_o = mapping_group_output[1];
            end else if (output_cnt == 5'd2) begin
                output_buffer_o = mapping_group_output[2];
            end else if (output_cnt == 5'd3) begin
                output_buffer_o = mapping_group_output[3];
            end else if (output_cnt == 5'd4) begin
                output_buffer_o = mapping_group_output[4];
            end else if (output_cnt == 5'd5) begin
                output_buffer_o = mapping_group_output[5];
            end else if (output_cnt == 5'd6) begin
                output_buffer_o = mapping_group_output[6];
            end else if (output_cnt == 5'd7) begin
                output_buffer_o = mapping_group_output[7];
            end else if (output_cnt == 5'd8) begin
                output_buffer_o = mapping_group_output[8];
            end else if (output_cnt == 5'd9) begin
                output_buffer_o = mapping_group_output[9];
            end else if (output_cnt == 5'd10) begin
                output_buffer_o = mapping_group_output[10];
            end else if (output_cnt == 5'd11) begin
                output_buffer_o = mapping_group_output[11];
            end else if (output_cnt == 5'd12) begin
                output_buffer_o = mapping_group_output[12];
            end else if (output_cnt == 5'd13) begin
                output_buffer_o = mapping_group_output[13];
            end else if (output_cnt == 5'd14) begin
                output_buffer_o = mapping_group_output[14];
            end else if (output_cnt == 5'd15) begin
                output_buffer_o = mapping_group_output[15];
            end else if (output_cnt == 5'd16) begin
                output_buffer_o = mapping_group_output[16];
            end else if (output_cnt == 5'd17) begin
                output_buffer_o = mapping_group_output[17];
            end else if (output_cnt == 5'd18) begin
                output_buffer_o = mapping_group_output[18];
            end else if (output_cnt == 5'd19) begin
                output_buffer_o = mapping_group_output[19];
            end else if (output_cnt == 5'd20) begin
                output_buffer_o = mapping_group_output[20];
            end else if (output_cnt == 5'd21) begin
                output_buffer_o = mapping_group_output[21];
            end else if (output_cnt == 5'd22) begin
                output_buffer_o = mapping_group_output[22];
            end else if (output_cnt == 5'd23) begin
                output_buffer_o = mapping_group_output[23];
            end else if (output_cnt == 5'd24) begin
                output_buffer_o = mapping_group_output[24];
            end else if (output_cnt == 5'd25) begin
                output_buffer_o = mapping_group_output[25];
            end else if (output_cnt == 5'd26) begin
                output_buffer_o = mapping_group_output[26];
            end else if (output_cnt == 5'd27) begin
                output_buffer_o = mapping_group_output[27];
            end else if (output_cnt == 5'd28) begin
                output_buffer_o = mapping_group_output[28];
            end else if (output_cnt == 5'd29) begin
                output_buffer_o = mapping_group_output[29];
            end else if (output_cnt == 5'd30) begin
                output_buffer_o = mapping_group_output[30];
            end else if (output_cnt == 5'd31) begin
                output_buffer_o = mapping_group_output[31];
            end else begin
                output_buffer_o = '0;
            end
        end else begin
            output_buffer_o = '0;
        end
    end

endmodule