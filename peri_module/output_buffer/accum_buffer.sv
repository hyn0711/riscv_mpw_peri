module accum_buffer (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic                 accum_buf_write_en_i,

    input logic [19:0]          shifter_output_i,

    input logic                 accum_buf_read_en_i,

    output logic [31:0]         accum_buf_output_o
);


    logic [31:0] buf_reg;

    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            buf_reg <= '0;
        end else begin
            if (accum_buf_write_en_i) begin
                buf_reg <= buf_reg + shifter_output_i;
            end else if (accum_buf_read_en_i) begin
                buf_reg <= '0;
            end else begin
                buf_reg <= buf_reg;
            end
        end
    end

    always_comb begin
        if (accum_buf_read_en_i) begin  
            accum_buf_output_o = buf_reg;
        end else begin
            accum_buf_output_o = '0;
        end
    end
    
endmodule