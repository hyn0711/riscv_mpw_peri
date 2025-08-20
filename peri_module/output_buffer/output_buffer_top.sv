module output_buffer_top (
    input logic             clk_i,
    input logic             rst_ni,

    // eFlash output 128 * 8 bit
    input logic [1023:0]    output_i,

    // Buffer signal 
    input logic             buf_write_en_1_i,
    input logic             buf_write_en_2_i,
    input logic             buf_read_en_i,

    input logic             shift_counter_en_i,
    
    input logic [2:0]       pim_mode_i,

    // zero point
    input logic             zero_point_en_i,
    input logic [31:0]      zero_point_i,

    // Load mode
    input logic             load_en_i, 
    input logic [5:0]       load_cnt_i,     // 0 ~ 31

    output logic [31:0]     out_buf_o
);

    logic [31:0]    mapping_group_i [0:31];
    logic [31:0]    mapping_group_output [0:31];

    always_comb begin
        for (int i = 0; i < 32; i ++) begin
            mapping_group_i[i] = output_i[1023-32*i -: 32];
        end
    end

    // Load mode, send the output to RISC-V
    logic load_en [0:31];
    logic load_out_en [0:31];

    always_comb begin
        for (int i = 0; i < 32; i++) begin
            load_en[i] = load_en_i && (i == load_cnt_i);
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 32; i++) begin
                load_out_en[i] <= '0;
            end
        end else begin
            for (int i = 0; i < 32; i++) begin
                load_out_en[i] <= load_en[i];
            end 
        end
    end



    generate 
        for (genvar i = 0; i < 32; i++) begin
            mapping_group_top mg_top (
                .clk_i(clk_i),
                .rst_ni(rst_ni),

                .output_i(mapping_group_i[i]),

                .buf_write_en_1_i(buf_write_en_1_i),
                .buf_write_en_2_i(buf_write_en_2_i),
                .buf_read_en_i(buf_read_en_i),

                .shift_counter_en_i(shift_counter_en_i),

                .pim_mode_i(pim_mode_i),

                .accum_buf_write_i(shift_counter_en_i),

                .zero_point_en_i(zero_point_en_i),
                .zero_point_i(zero_point_i),

            // Load mode 
                .load_en_i(load_en[i]),

                .mapping_group_o(mapping_group_output[i])
            );
        end
    endgenerate

    always_comb begin
        out_buf_o = '0;
        if (load_out_en[0]) begin
            out_buf_o = mapping_group_output[0];
        end else if (load_out_en[1]) begin
            out_buf_o = mapping_group_output[1];
        end else if (load_out_en[2]) begin
            out_buf_o = mapping_group_output[2];
        end else if (load_out_en[3]) begin
            out_buf_o = mapping_group_output[3];
        end else if (load_out_en[4]) begin
            out_buf_o = mapping_group_output[4];
        end else if (load_out_en[5]) begin
            out_buf_o = mapping_group_output[5];
        end else if (load_out_en[6]) begin
            out_buf_o = mapping_group_output[6];
        end else if (load_out_en[7]) begin
            out_buf_o = mapping_group_output[7];
        end else if (load_out_en[8]) begin
            out_buf_o = mapping_group_output[8];
        end else if (load_out_en[9]) begin
            out_buf_o = mapping_group_output[9];
        end else if (load_out_en[10]) begin
            out_buf_o = mapping_group_output[10];
        end else if (load_out_en[11]) begin
            out_buf_o = mapping_group_output[11];
        end else if (load_out_en[12]) begin
            out_buf_o = mapping_group_output[12];
        end else if (load_out_en[13]) begin
            out_buf_o = mapping_group_output[13];
        end else if (load_out_en[14]) begin
            out_buf_o = mapping_group_output[14];
        end else if (load_out_en[15]) begin
            out_buf_o = mapping_group_output[15];
        end else if (load_out_en[16]) begin
            out_buf_o = mapping_group_output[16];
        end else if (load_out_en[17]) begin
            out_buf_o = mapping_group_output[17];
        end else if (load_out_en[18]) begin
            out_buf_o = mapping_group_output[18];
        end else if (load_out_en[19]) begin
            out_buf_o = mapping_group_output[19];
        end else if (load_out_en[20]) begin
            out_buf_o = mapping_group_output[20];
        end else if (load_out_en[21]) begin
            out_buf_o = mapping_group_output[21];
        end else if (load_out_en[22]) begin
            out_buf_o = mapping_group_output[22];
        end else if (load_out_en[23]) begin
            out_buf_o = mapping_group_output[23];
        end else if (load_out_en[24]) begin
            out_buf_o = mapping_group_output[24];
        end else if (load_out_en[25]) begin
            out_buf_o = mapping_group_output[25];
        end else if (load_out_en[26]) begin
            out_buf_o = mapping_group_output[26];
        end else if (load_out_en[27]) begin
            out_buf_o = mapping_group_output[27];
        end else if (load_out_en[28]) begin
            out_buf_o = mapping_group_output[28];
        end else if (load_out_en[29]) begin
            out_buf_o = mapping_group_output[29];
        end else if (load_out_en[30]) begin
            out_buf_o = mapping_group_output[30];
        end else if (load_out_en[31]) begin
            out_buf_o = mapping_group_output[31];
        end else begin
            out_buf_o = '0;
        end
    end

endmodule