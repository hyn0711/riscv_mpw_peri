module output_buffer (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [1023:0]        pim_output_1_i,
    input logic [1023:0]        pim_output_2_i,

    // signal
    input logic                 buf_write_en_1_i,
    input logic                 buf_write_en_2_i,

    input logic                 buf_read_en_i,

    output logic [1023:0]       output_1_o,
    output logic [1023:0]       output_2_o
);

    logic [1023:0]         buf_1;
    logic [1023:0]         buf_2;

    // Buffer write
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            buf_1 <= '0;
            buf_2 <= '0;
        end else begin
            if(buf_write_en_1_i) begin
                buf_1 <= pim_output_1_i;
            end else if (buf_write_en_2_i) begin
                buf_2 <= pim_output_2_i;
            end else begin
                buf_1 <= buf_1;
                buf_2 <= buf_2;
            end
        end
    end

    // Buffer read
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            output_1_o <= '0;
            output_2_o <= '0;
        end else begin
            if (buf_read_en_i) begin
                output_1_o <= buf_1;
                output_2_o <= buf_2;
            end else begin
                output_1_o <= '0;
                output_2_o <= '0;
            end
        end
    end
            

endmodule