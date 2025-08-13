`timescale 1ns/10ps

module tb_mapping_group_top;

    parameter CLK_PERIOD = 10;

    reg clk_i;
    reg rst_ni;

    reg [31:0] output_i;

    reg buf_write_en_1_i;
    reg buf_write_en_2_i;
    reg buf_read_en_i;

    reg mode_i;

    reg [1:0] shift_count_i;

    reg accum_buf_write_i;
    reg accum_buf_read_i;

    wire [31:0] mapping_group_o;

    mapping_group_top top(
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        .output_i(output_i),

        .buf_write_en_1_i(buf_write_en_1_i),
        .buf_write_en_2_i(buf_write_en_2_i),
        .buf_read_en_i(buf_read_en_i),

        .mode_i(mode_i),

        .shift_count_i(shift_count_i),

        .accum_buf_write_i(accum_buf_write_i),
        .accum_buf_read_i(accum_buf_read_i),

        .mapping_group_o(mapping_group_o)
);

    initial begin
        $dumpfile("tb_mapping_group_top.vcd");
        $dumpvars(0,tb_mapping_group_top);
    end

    always begin
        #(CLK_PERIOD/2) clk_i = ~clk_i;
    end

    task init_signals();
        output_i = '0;
        buf_write_en_1_i = '0;
        buf_write_en_2_i = '0;
        buf_read_en_i = '0;
        mode_i = '0;
        shift_count_i = '0;
        accum_buf_write_i = '0;
        accum_buf_read_i = '0;
    endtask

    initial begin
        clk_i = '0;
        rst_ni = '0;

        init_signals();

        repeat(2) @(posedge clk_i); rst_ni = 1'b1;

        // Test rbr mode ----------------------------
        // shift_sum_output = 55, shift_count_output = 55
        @(posedge clk_i); mode_i = 1'b0;
                          output_i = {8'b11111110, 8'b11111110, 8'b11111110, 8'b11111110};
        @(posedge clk_i); buf_write_en_1_i = 1'b1;
        @(posedge clk_i); buf_write_en_1_i = '0;
                          buf_read_en_i = 1'b1;
                          shift_count_i = 2'b00;
        @(posedge clk_i); accum_buf_write_i = 1'b1;
        @(posedge clk_i); init_signals();

        // shift_sum_output = 55, shift_count_output = 154
        repeat(5) @(posedge clk_i); mode_i = 1'b0;
                                    output_i = {8'b11111110, 8'b11111110, 8'b11111110, 8'b11111110};
        @(posedge clk_i); buf_write_en_1_i = 1'b1;
        @(posedge clk_i); buf_write_en_1_i = '0;
                          buf_read_en_i = 1'b1;
                          shift_count_i = 2'b01;
        @(posedge clk_i); accum_buf_write_i = 1'b1;
        @(posedge clk_i); init_signals();

        // shift_sum_output = AA, shift_count_output = AA0
        repeat(5) @(posedge clk_i); mode_i = 1'b0;
                                    output_i = {8'b11111100, 8'b11111100, 8'b11111100, 8'b11111100};
        @(posedge clk_i); buf_write_en_1_i = 1'b1;
        @(posedge clk_i); buf_write_en_1_i = '0;
                          buf_read_en_i = 1'b1;
                          shift_count_i = 2'b10;
        @(posedge clk_i); accum_buf_write_i = 1'b1;
        @(posedge clk_i); init_signals();

        // shift_sum_output = AA, shift_count_output = 2A80
        repeat(5) @(posedge clk_i); mode_i = 1'b0;
                                    output_i = {8'b11111100, 8'b11111100, 8'b11111100, 8'b11111100};
        @(posedge clk_i); buf_write_en_1_i = 1'b1;
        @(posedge clk_i); buf_write_en_1_i = '0;
                          buf_read_en_i = 1'b1;
                          shift_count_i = 2'b11;
        @(posedge clk_i); accum_buf_write_i = 1'b1;
        @(posedge clk_i); init_signals();

        // Read the mapping group output to zero points
        repeat(2) @(posedge clk_i); accum_buf_read_i = 1'b1;
        @(posedge clk_i); init_signals();



        // Test paralle mode ----------------------------
        @(posedge clk_i); mode_i = 1'b1;
                          output_i = {8'b10000000, 8'b10000000, 8'b10000000, 8'b10000000};
        @(posedge clk_i); buf_write_en_1_i = 1'b1;
        @(posedge clk_i); buf_write_en_1_i = '0;
        @(posedge clk_i); output_i = {8'b11111000, 8'b11111000, 8'b11111000, 8'b11111000};
        @(posedge clk_i); buf_write_en_2_i = 1'b1;
        @(posedge clk_i); buf_write_en_2_i = '0;
                          buf_read_en_i = 1'b1;
                          shift_count_i = 2'b00;
        @(posedge clk_i); accum_buf_write_i = 1'b1;
        @(posedge clk_i); init_signals();


        repeat(6) @(posedge clk_i); mode_i = 1'b1;
                          output_i = {8'b11000000, 8'b11000000, 8'b11000000, 8'b11000000};
        @(posedge clk_i); buf_write_en_1_i = 1'b1;
        @(posedge clk_i); buf_write_en_1_i = '0;
        @(posedge clk_i); output_i = {8'b11111000, 8'b11111000, 8'b11111000, 8'b11111000};
        @(posedge clk_i); buf_write_en_2_i = 1'b1;
        @(posedge clk_i); buf_write_en_2_i = '0;
                          buf_read_en_i = 1'b1;
                          shift_count_i = 2'b01;
        @(posedge clk_i); accum_buf_write_i = 1'b1;
        @(posedge clk_i); init_signals();


        repeat(6) @(posedge clk_i); mode_i = 1'b1;
                          output_i = {8'b11100000, 8'b11100000, 8'b11100000, 8'b11100000};
        @(posedge clk_i); buf_write_en_1_i = 1'b1;
        @(posedge clk_i); buf_write_en_1_i = '0;
        @(posedge clk_i); output_i = {8'b11111000, 8'b11111000, 8'b11111000, 8'b11111000};
        @(posedge clk_i); buf_write_en_2_i = 1'b1;
        @(posedge clk_i); buf_write_en_2_i = '0;
                          buf_read_en_i = 1'b1;
                          shift_count_i = 2'b10;
        @(posedge clk_i); accum_buf_write_i = 1'b1;
        @(posedge clk_i); init_signals();


        repeat(6) @(posedge clk_i); mode_i = 1'b1;
                          output_i = {8'b11110000, 8'b11110000, 8'b11110000, 8'b11110000};
        @(posedge clk_i); buf_write_en_1_i = 1'b1;
        @(posedge clk_i); buf_write_en_1_i = '0;
        @(posedge clk_i); output_i = {8'b11111000, 8'b11111000, 8'b11111000, 8'b11111000};
        @(posedge clk_i); buf_write_en_2_i = 1'b1;
        @(posedge clk_i); buf_write_en_2_i = '0;
                          buf_read_en_i = 1'b1;
                          shift_count_i = 2'b11;
        @(posedge clk_i); accum_buf_write_i = 1'b1;
        @(posedge clk_i); init_signals();


        repeat(2) @(posedge clk_i); accum_buf_read_i = 1'b1;
        @(posedge clk_i); init_signals();

                    
        repeat(20) @(posedge clk_i); $finish;
    end
endmodule