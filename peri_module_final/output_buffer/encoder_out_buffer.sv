module encoder_out_buffer (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [3:0]           enc_out_1_i [0:3],

    // signal
    input logic                 buf_write_en_1_i,
    input logic                 buf_write_en_2_i,

    input logic                 buf_read_en_i,

    output logic [3:0]          output_1_o [0:3],
    output logic [3:0]          output_2_o [0:3]
);

    logic [3:0]         buf_1 [0:3];
    logic [3:0]         buf_2 [0:3];

    // Buffer write
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 4; i++) begin
                buf_1[i] <= '0;
                buf_2[i] <= '0;
            end
        end else begin
            if(buf_write_en_1_i) begin
                for (int i = 0; i < 4; i++) begin
                    buf_1[i] <= enc_out_1_i[i];
                end
            end else if (buf_write_en_2_i) begin
                for (int i = 0; i < 4; i++) begin
                    buf_2[i] <= enc_out_1_i[i];
                end
            end else begin
                for (int i = 0; i < 4; i++) begin
                    buf_1[i] <= buf_1[i];
                    buf_2[i] <= buf_2[i];
                end
            end
        end
    end

    // Buffer read
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 4; i++) begin
                output_1_o[i] <= '0;
                output_2_o[i] <= '0;
            end
        end else begin
            if (buf_read_en_i) begin
                for (int i = 0; i < 4; i++) begin
                    output_1_o[i] <= buf_1[i];
                    output_2_o[i] <= buf_2[i];
                end
            end else begin
                for (int i = 0; i < 4; i++) begin
                    output_1_o[i] <= '0;
                    output_2_o[i] <= '0;
                end
            end
        end
    end
            

endmodule