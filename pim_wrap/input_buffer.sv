module input_buffer(
    input logic             clk_i,
    input logic             rst_ni,

    input logic [31:0]      data_i,
    input logic [3:0]       data_cnt_i,

    input logic             buf_write_i,
    input logic             buf_read_i,     // mode execution

    input logic             parallel_read_i,
    input logic             rowbyrow_read_i,

    output logic [1:0]      data_o [0:255]

    // unpacked output for gtkwave
    //utput logic [511:0]    data_flat_o
);

    logic [1:0]     input_data [0:255];

    // Write input data in the buffer
    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 256; i++) begin
                input_data[i] <= '0;
            end 
        end else begin
            if (buf_write_i) begin
                if (data_cnt_i == 4'd0) begin
                    for (int i = 0; i < 16; i++) begin
                        input_data[i] <= data_i[2*i +: 2];
                    end
                end else if (data_cnt_i == 4'd1) begin
                    for (int i = 16; i < 32; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd2) begin
                    for (int i = 32; i < 48; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd3) begin
                    for (int i = 48; i < 64; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd4) begin
                    for (int i = 64; i < 80; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd5) begin
                    for (int i = 80; i < 96; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd6) begin
                    for (int i = 96; i < 112; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd7) begin
                    for (int i = 112; i < 128; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd8) begin
                    for (int i = 128; i < 144; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd9) begin
                    for (int i = 144; i < 160; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd10) begin
                    for (int i = 160; i < 176; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd11) begin
                    for (int i = 176; i < 192; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd12) begin
                    for (int i = 192; i < 208; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd13) begin
                    for (int i = 208; i < 224; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd14) begin
                    for (int i = 224; i < 240; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd15) begin
                    for (int i = 240; i < 256; i++) begin
                        input_data[i] <= data_i[2 * (i % 16) +: 2];
                    end
                end else begin
                    for (int i = 0; i < 256; i++) begin
                        input_data[i] <= input_data[i];
                    end
                end
            end else begin
                for (int i = 0; i < 256; i++) begin
                    input_data[i] <= input_data[i];
                end
            end
        end
    end

    // Read the data
    always_comb begin
        if (buf_read_i) begin   
            if (parallel_read_i) begin
                for (int i = 0; i < 256; i++) begin
                    data_o[i] = input_data[i];
                end
            end else if (rowbyrow_read_i) begin
                for (int i = 0; i < 32; i++) begin
                    data_o[i] = input_data[i];
                end 
            for (int j = 32; j < 256; j++) begin
                data_o[j] = '0;
            end
            end else begin
                for (int i = 0; i < 256; i++) begin
                    data_o[i] = '0;
                end
            end
        end else begin
            for (int i = 0; i < 256; i++) begin
                data_o[i] = '0;
            end
        end
    end

    // // flat output
    // logic [1:0] data_o[0:255];

    // always_comb begin
    //     for (int i = 0; i < 256; i++) begin
    //         data_flat_o[i*2 +: 2] = data_o[i];
    //     end
    // end

endmodule 
