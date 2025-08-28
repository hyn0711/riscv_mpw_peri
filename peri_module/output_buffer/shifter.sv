module shifter (
    input logic                 clk_i,
    input logic                 rst_ni,

    input logic [6:0]           encoder_output_i [0:3],

    // Signal for shift counter
    input logic                 shift_counter_en_i, 

    output logic [19:0]         shifter_output_o
);

    logic [13:0]    shift_output [0:3];
    logic [13:0]    shift_sum_output;

    logic [1:0]     shift_counter;

    logic [19:0]    shifter_output;

    //--|Shift sum|----------------------------------------------
    // encoder_output_i[0] << 6
    // encoder_output_i[1] << 4
    // encoder_output_i[2] << 2
    // encoder_output_i[3] << 0

    assign shift_output[0] = {1'b0, encoder_output_i[0], 6'b0};
    assign shift_output[1] = {3'b0, encoder_output_i[1], 4'b0};
    assign shift_output[2] = {5'b0, encoder_output_i[2], 2'b0};
    assign shift_output[3] = {7'b0, encoder_output_i[3]};

    assign shift_sum_output = shift_output[0] + shift_output[1] + shift_output[2] + shift_output[3];


    //--|Shift counter|------------------------------------------
    // 0 : 0
    // 1 : 2
    // 2 : 4
    // 3 : 6

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            shift_counter <= '0;
        end else begin
            if (shift_counter_en_i) begin
                shift_counter <= shift_counter + 2'd1;
            end else begin
                shift_counter <= shift_counter;
            end
        end
    end

    always_comb begin   
        shifter_output = '0;
        case (shift_counter)
            2'b00: shifter_output = {6'b0, shift_sum_output};
            2'b01: shifter_output = {4'b0, shift_sum_output, 2'b0};
            2'b10: shifter_output = {2'b0, shift_sum_output, 4'b0};
            2'b11: shifter_output = {shift_sum_output, 6'b0};
            default: shifter_output = '0;
        endcase
    end

    assign shifter_output_o = shifter_output;

endmodule