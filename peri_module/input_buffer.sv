module input_buffer (
    input logic             clk_i,
    input logic             rst_ni,

    // Buffer
    input logic [31:0]      input_data_i,
    input logic [3:0]       data_cnt_i,

    input logic             in_buf_write_i,
    input logic             in_buf_read_i,

    // eFlash signal control
    input logic [2:0]       pim_mode_i,

    output logic [1:0]      input_data_o [0:255]


);

    // eFlash mode
    localparam PIM_ERASE = 3'b001;
    localparam PIM_PROGRAM = 3'b010;
    localparam PIM_READ = 3'b011;
    localparam PIM_PARALLEL = 3'b100;
    localparam PIM_RBR = 3'b101;
    localparam PIM_LOAD = 3'b110;

    logic [2:0] pim_mode;

    assign pim_mode = pim_mode_i;

    // -------------------- Buffer --------------------

    logic [1:0]     mem [0:255];

    // Write input data in the buffer
    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 256; i++) begin
                mem[i] <= '0;
            end 
        end else begin
            if (in_buf_write_i) begin
                if (data_cnt_i == 4'd0) begin
                    for (int i = 0; i < 16; i++) begin
                        mem[i] <= input_data_i[2*i +: 2];
                    end
                end else if (data_cnt_i == 4'd1) begin
                    for (int i = 16; i < 32; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd2) begin
                    for (int i = 32; i < 48; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd3) begin
                    for (int i = 48; i < 64; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd4) begin
                    for (int i = 64; i < 80; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd5) begin
                    for (int i = 80; i < 96; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd6) begin
                    for (int i = 96; i < 112; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd7) begin
                    for (int i = 112; i < 128; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd8) begin
                    for (int i = 128; i < 144; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd9) begin
                    for (int i = 144; i < 160; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd10) begin
                    for (int i = 160; i < 176; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd11) begin
                    for (int i = 176; i < 192; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd12) begin
                    for (int i = 192; i < 208; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd13) begin
                    for (int i = 208; i < 224; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd14) begin
                    for (int i = 224; i < 240; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else if (data_cnt_i == 4'd15) begin
                    for (int i = 240; i < 256; i++) begin
                        mem[i] <= input_data_i[2 * (i % 16) +: 2];
                    end
                end else begin
                    for (int i = 0; i < 256; i++) begin
                        mem[i] <= mem[i];
                    end
                end
            end else begin
                for (int i = 0; i < 256; i++) begin
                    mem[i] <= mem[i];
                end
            end
        end
    end

    // Read the data 
    always_comb begin
        if (in_buf_read_i) begin   
            if (pim_mode == PIM_PARALLEL) begin
                for (int i = 0; i < 256; i++) begin
                    input_read[i] = mem[i];
                end
            end else if (pim_mode == PIM_RBR) begin
                for (int i = 0; i < 32; i++) begin
                    input_read[i] = mem[i];
                end 
                for (int j = 32; j < 256; j++) begin
                    input_read[j] = '0;
                end
            end else begin
                for (int i = 0; i < 256; i++) begin
                    input_read[i] = '0;
                end
            end
        end else begin
            for (int i = 0; i < 256; i++) begin
                input_read[i] = '0;
            end
        end
    end

    always_comb begin
        for (int i = 0; i < 256; i++) begin
            input_data_o[i] = input_read[i];
        end
    end


endmodule