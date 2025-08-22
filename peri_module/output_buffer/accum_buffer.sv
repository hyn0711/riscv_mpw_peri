module accum_buffer (
    input logic             clk_i,
    input logic             rst_ni,

    input logic             write_en_i,

    input logic [31:0]      data_i,

    input logic             read_en_i,
    input logic [31:0]      zero_point_i,

    output logic [31:0]     data_o
);


    logic [31:0] mem;

    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            mem <= '0;
            //data_o <= '0;
        end else begin
            if (write_en_i) begin
                mem <= mem + data_i;
                //data_o <= '0;
            end else if (read_en_i) begin
                mem <= '0;
                //data_o <= mem + zero_point_i;
            end else begin
                mem <= mem;
                //data_o <= '0;
            end
        end
    end

    always_comb begin
        if (read_en_i) begin  
            data_o = mem + zero_point_i;
        end else begin
            data_o = '0;
        end
    end
    
endmodule