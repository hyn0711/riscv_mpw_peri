module peri_controller(
    input logic         clk_i,
    input logic         rst_ni,

    // RISC-V
    input logic [31:0]  address_i,
    input logic [31:0]  data_i,

    output logic [31:0] data_o,

    // eFLASH driver
    output logic        erase_en_o,
    output logic        program_en_o,
    output logic        read_en_o,
    output logic        parallel_en_o,
    output logic        rbr_en_o,
    output logic        load_en_o,

    output logic [6:0]  row_addr7_o,
    output logic [8:0]  col_addr9_o,

    output logic [3:0]  exec_cnt_o,

    // input buffer
    output logic [31:0] input_data_o,
    output logic [3:0]  data_rx_cnt_o,

    output logic        in_buf_write_o,
    
    output logic        in_buf_read_o,

    // output buffer
    output logic        out_buf_write_o,
    output logic        out_buf_read_o,

    output logic [7:0]  read_ptr_o,

    input logic [31:0]  out_buf_data_i
);

    localparam MODE = 32'h4100_0000;
    localparam STATUS = 32'h4200_0000;
    
    //state
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        MODE_READY = 2'b01,
        MODE_EXEC = 2'b10
    } state_t;

    state_t state;

    logic   erase_en, program_en, read_en, parallel_en, rbr_en, load_en;
    logic   [3:0] data_rx_cnt;
    logic   [5:0] data_tx_cnt;
    logic   [6:0] row_addr;
    logic   [8:0] col_addr;
    logic   [16:0] pulse_width, init_pulse_width;
    logic   [4:0] pulse_count, init_pulse_count;

    logic   [31:0] output_result, data_o_next;

    logic   pim_busy, pim_data_valid;


    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state <= IDLE;
        end else begin
            case (state)
            IDLE: begin
                erase_en <= 1'b0;
                program_en <= 1'b0;
                read_en <= 1'b0;
                parallel_en <= 1'b0;
                rbr_en <= 1'b0;
                load_en <= 1'b0;

                // move state to MODE_READY
                if (address_i == MODE) begin
                    //state <= MODE_READY;
                    if (data_i[2:0] == 3'b001) begin
                        erase_en <= 1'b1;
                        state <= MODE_READY;
                    end else if (data_i[2:0] == 3'b010) begin
                        program_en <= 1'b1;
                        state <= MODE_READY;
                    end else if (data_i[2:0] == 3'b011) begin
                        read_en <= 1'b1;
                        state <= MODE_READY;
                    end else if (data_i[2:0] == 3'b100) begin
                        parallel_en <= 1'b1;
                        state <= MODE_READY;
                        data_rx_cnt <= 4'd0;
                    end else if (data_i[2:0] == 3'b101) begin
                        rbr_en <= 1'b1;
                        state <= MODE_READY;
                        data_rx_cnt <= 4'd0;
                    end else if (data_i[2:0] == 3'b111) begin
                        load_en <= 1'b1;
                        state <= MODE_EXEC;
                    end
                end else begin
                    state <= IDLE;
                end
            end

            MODE_READY: begin
                if (erase_en) begin
                    if (address_i[31:20] == 12'h400) begin
                        row_addr <= address_i[15:9];
                        pulse_width <= data_i[21:5];
                        pulse_count <= data_i[4:0];
                        init_pulse_width <= data_i[21:5];
                        init_pulse_count <= data_i[4:0];
                        state <= MODE_EXEC;
                    end else begin
                        state <= MODE_READY;
                    end

                end else if (program_en) begin
                    if (address_i[31:20] == 12'h400) begin
                        row_addr <= address_i[15:9];
                        col_addr <= address_i[8:0];
                        pulse_width <= data_i[21:5];
                        pulse_count <= data_i[4:0];
                        init_pulse_width <= data_i[21:5];
                        init_pulse_count <= data_i[4:0];
                        state <= MODE_EXEC;
                    end else begin
                        state <= MODE_READY;
                    end

                end else if (read_en) begin
                    if (address_i[31:20] == 12'h400) begin
                        row_addr <= address_i[15:9];
                        col_addr <= address_i[8:0];
                        exec_cnt_o <= 4'd9;
                        state <= MODE_EXEC;
                    end else begin
                        state <= MODE_READY;
                    end

                end else if (parallel_en) begin
                    if (address_i[31:20] == 12'h400) begin
                        row_addr <= address_i[15:9];
                        col_addr <= address_i[8:0];
                        in_buf_write_o <= 1'b1;
                        input_data_o <= data_i;         // to input buffer
                        data_rx_cnt <= data_rx_cnt + 4'd1;
                        data_rx_cnt_o <= data_rx_cnt;
                        exec_cnt_o <= 4'd12;

                        if (data_rx_cnt == 4'd15) begin
                            state <= MODE_EXEC;
                        end else begin
                            state <= MODE_READY;
                        end
                    end else begin
                        state <= MODE_READY;
                    end

                end else if (rbr_en) begin
                    if (address_i[31:20] == 12'h400) begin
                        row_addr <= address_i[15:9];
                        col_addr <= address_i[8:0];
                        in_buf_write_o <= 1'b1;
                        input_data_o <= data_i;
                        data_rx_cnt <= data_rx_cnt + 4'd1;
                        data_rx_cnt_o <= data_rx_cnt;
                        exec_cnt_o <= 4'd9;

                        if (data_rx_cnt == 4'd1) begin
                            state <= MODE_EXEC;
                        end else begin
                            state <= MODE_READY;
                        end
                    end else begin
                        state <= MODE_READY;
                    end
                    
                end else if (load_en) begin
                    
                end

            end


            MODE_EXEC: begin
                if (erase_en) begin
                    if (pulse_count != '0) begin
                        if (pulse_width != '0) begin
                            erase_en_o <= 1'b1;
                            row_addr7_o <= row_addr;
                            pulse_width <= pulse_width - 17'd1;
                        end else begin
                            erase_en_o <= 1'b0;
                            pulse_count <= pulse_count - 5'd1;
                            pulse_width <= init_pulse_width;
                        end
                        state <= MODE_EXEC;
                    end else begin
                        erase_en <= 1'b0;
                        erase_en_o <= 1'b0;
                        state <= IDLE;
                    end

                end else if (program_en) begin
                    if (pulse_count != '0) begin
                        if (pulse_width != '0) begin
                            program_en_o <= 1'b1;
                            row_addr7_o <= row_addr;
                            col_addr9_o <= col_addr;
                            pulse_width <= pulse_width - 17'd1;
                        end else begin
                            program_en_o <= 1'b0;
                            pulse_count <= pulse_count - 5'd1;
                            pulse_width <= init_pulse_width;
                        end
                        state <= MODE_EXEC;
                    end else begin
                        program_en <= 1'b0;
                        program_en_o <= 1'b0;
                        state <= IDLE;
                    end

                end else if (read_en) begin // execute 9 cycles
                    if (exec_cnt_o != '0) begin
                        read_en_o <= 1'b1;
                        row_addr7_o <= row_addr;
                        col_addr9_o <= col_addr;
                        exec_cnt_o <= exec_cnt_o - 4'd1;
                        if (exec_cnt_o == 4'd1) begin
                            out_buf_write_o <= 1'b1;
                        end else begin
                            out_buf_write_o <= 1'b0;
                        end
                        state <= MODE_EXEC;
                    end else begin
                        read_en <= 1'b0;
                        read_en_o <= 1'b0;
                        out_buf_write_o <= 1'b0;
                        state <= IDLE;
                    end

                end else if (parallel_en) begin // execute 12 cycles
                    if (exec_cnt_o != 0) begin
                        parallel_en_o <= 1'b1;
                        row_addr7_o <= row_addr;
                        col_addr9_o <= col_addr;
                        in_buf_read_o <= 1'b1;
                        exec_cnt_o <= exec_cnt_o - 4'd1;
                        if (exec_cnt_o == 4'd3 || exec_cnt_o == 4'd0) begin
                            out_buf_write_o <= 1'b1;
                        end else begin
                            out_buf_write_o <= 1'b0;
                        end
                        state <= MODE_EXEC;
                    end else begin
                        parallel_en <= 1'b0;
                        parallel_en_o <= 1'b0;
                        in_buf_read_o <= 1'b0;
                        out_buf_write_o <= 1'b0;
                        state <= IDLE;
                    end

                end else if (rbr_en) begin
                    if (exec_cnt_o != 0) begin
                        rbr_en_o <= 1'b1;
                        row_addr7_o <= row_addr;
                        col_addr9_o <= col_addr;
                        in_buf_read_o <= 1'b1;
                        exec_cnt_o <= exec_cnt_o - 4'd1;
                        if (exec_cnt_o == 4'd0) begin
                            out_buf_write_o <= 1'b1;
                        end else begin
                            out_buf_write_o <= 1'b0;
                        end
                        state <= MODE_EXEC;
                    end else begin
                        rbr_en <= 1'b0;
                        rbr_en_o <= 1'b0;
                        in_buf_read_o <= 1'b0;
                        out_buf_write_o <= 1'b0;
                        state <= IDLE;
                    end

                end else if (load_en) begin
                    if (address_i[31:20] == 12'h400) begin
                        out_buf_read_o <= 1'b1;
                        read_ptr_o <= address_i[7:0];
                        //data_o <= out_buf_data_i;
                    end
                end

            end
            endcase
        end
    end

    // output result from the ouput buffer at load mode
    assign output_result = out_buf_data_i;

    // check if pim is busy
    assign pim_busy = erase_en || program_en || read_en || parallel_en || rbr_en || load_en;
    assign pim_data_valid = 1'b1;

    always_comb begin
        if (address_i == STATUS) begin
            data_o_next = {30'b0, pim_data_valid, pim_busy};
        end else if (address_i[31:20] == 12'h400 && load_en == 1'b1) begin
            data_o_next = output_result;
        end else begin
            data_o_next = '0;
        end
    end

    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_o <= '0;
        end else begin
            data_o <= data_o_next;
        end
    end

endmodule