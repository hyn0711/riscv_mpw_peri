
// 4 * 8bits buffer for mapping group

module buffer_8b (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [31:0]          output_i,       // Output from eFlash pim

    // signal
    input logic                 buf_write_en_1_i,
    input logic                 buf_write_en_2_i,

    input logic                 buf_read_en_i,

    output logic [7:0]          output_1_o [0:3],
    output logic [7:0]          output_2_o [0:3]
);

    logic [7:0]        buf_1[0:3];
    logic [7:0]        buf_2[0:3];

    // Output[31:24] -> buf[0]
    // Output[23:16] -> buf[1]
    // Output[15:8]  -> buf[2]
    // Output[7:0]   -> buf[3]

    // Buffer write
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 4; i++) begin
                buf_1[i] <= '0;
                buf_2[i] <= '0;
            end
        end else begin
            if (buf_write_en_1_i) begin
                buf_1[0] <= output_i[31:24];
                buf_1[1] <= output_i[23:16];
                buf_1[2] <= output_i[15:8];
                buf_1[3] <= output_i[7:0];
            end else if (buf_write_en_2_i) begin
                buf_2[0] <= output_i[31:24];
                buf_2[1] <= output_i[23:16];
                buf_2[2] <= output_i[15:8];
                buf_2[3] <= output_i[7:0];
            end else begin
                for (int i = 0; i < 4; i++) begin
                    buf_1[i] <= buf_1[i];
                    buf_2[i] <= buf_2[i];
                end
            end
        end
    end

    // Buffer read
    always_comb begin
        if (buf_read_en_i) begin
            for (int i = 0; i < 4; i++) begin
                output_1_o[i] = buf_1[i];
                output_2_o[i] = buf_2[i];
            end
        end else begin
            for (int i = 0; i < 4; i++) begin
                output_1_o[i] = '0;
                output_2_o[i] = '0;
            end
        end
    end

endmodule