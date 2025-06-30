module output_buffer (
    input logic             clk_i,
    input logic             rst_ni,

    input logic [1023:0]    output_i,

    input logic [7:0]       read_ptr_i,

    // control signal
    input logic             output_write_en_i,
    input logic             output_read_en_i,

    output logic [31:0]     output_o
);

    logic [7:0]     mem[0:255];
    logic [7:0]     write_ptr;
    logic [7:0]     read_ptr;

    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (int i = 0; i < 256; i++) begin
                mem[i] <= '0;
            end
            write_ptr <= '0;
            //read_ptr <= '0;
        end else begin
            if (output_write_en_i) begin
                for (int unsigned i = 0; i < 128; i++) begin
                    mem[write_ptr + i] <= output_i[1023-8*i -: 8];                   
                end
                write_ptr <= write_ptr + 8'd128;
            end else begin
                for (int i = 0; i < 256; i++) begin
                    mem[i] <= mem[i];
                end
                write_ptr <= write_ptr;
            end   
        end
    end

    always_comb begin
        if (output_read_en_i) begin
            output_o = {mem[4*read_ptr_i+8'd3], mem[4*read_ptr_i+8'd2], mem[4*read_ptr_i+8'd1], mem[4*read_ptr_i]};
        end else begin
            output_o = '0;
        end
    end

    
endmodule
