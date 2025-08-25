module peri_controller #(
    parameter PIM_MODE          = 32'h4100_0000,
    parameter PIM_ZP_ADDR       = 32'h4200_0000,
    parameter PIM_STATUS        = 32'h4300_0000
) (
    input logic                 clk_i,
    input logic                 rst_ni,

    // RISC-V <-> PERI
    input logic [31:0]          address_i,
    input logic [31:0]          data_i,

    output logic [31:0]         data_o,

    // -> Row, Col driver
    output logic                pim_en_o,
    output logic [2:0]          pim_mode_o,
    output logic [3:0]          exec_cnt_o,

    output logic [6:0]          row_addr7_o,
    output logic [8:0]          col_addr9_o,
        
    // -> Input buffer
    output logic                in_buf_write_o,
    output logic                in_buf_read_o,
    output logic [31:0]         input_data_o,
    output logic [3:0]          data_rx_cnt_o,


    // -> Output buffer
    output logic [2:0]          before_load_mode_o,

    output logic                zp_en_o,
    output logic signed [31:0]  zp_data_o,

    // For processing
    output logic                pim_out_buf_r_en_o,
    output logic                output_processing_done_o,

    output logic                load_en_o,
    output logic [4:0]          load_cnt_o,

    input logic [31:0]          output_buffer_result_i
);

    // PIM MODE
    // 3'b001 : PIM_ERASE
    // 3'b010 : PIM_PROGRAM
    // 3'b011 : PIM_READ
    // 3'b100 : PIM_ZP
    // 3'b101 : PIM_PARALLEL
    // 3'b110 : PIM_RBR
    // 3'b111 : PIM_LOAD
    localparam PIM_ERASE = 3'b001;
    localparam PIM_PROGRAM = 3'b010;
    localparam PIM_READ = 3'b011;
    localparam PIM_ZP = 3'b100;
    localparam PIM_PARALLEL = 3'b101;
    localparam PIM_RBR = 3'b110;
    localparam PIM_LOAD = 3'b111;

    // state 
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        PIM_SETUP = 2'b01,
        PIM_EXEC = 2'b10, 
        PIM_PROCESSING = 2'b11
    } state_t;

    state_t curr_state, next_state;
    
    logic mode_received, setup_finish;

    logic [2:0] pim_mode;
    logic [6:0] row_addr;
    logic [8:0] col_addr;
    logic [16:0] pulse_width;
    logic [4:0] pulse_count;
    logic [2:0] before_load_mode;

    assign mode_received = (address_i == PIM_MODE);
    assign setup_finish = (curr_state == PIM_SETUP) && (
        (pim_mode == PIM_ERASE && address_i[31:16] == 16'h4000)      ||
        (pim_mode == PIM_PROGRAM && address_i[31:16] == 16'h4000)    ||
        (pim_mode == PIM_READ && address_i[31:16] == 16'h4000)       || 
        (pim_mode == PIM_ZP && address_i == PIM_ZP_ADDR)             ||
        (pim_mode == PIM_PARALLEL && address_i[31:16] == 16'h400F)   ||
        (pim_mode == PIM_RBR && address_i[31:16] == 16'h4001)        ||
        (pim_mode == PIM_LOAD && address_i[31:16] == 16'h4000)
    );


    // ==|REGISTER|======================================================

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pim_mode <= '0;
            row_addr <= '0;
            col_addr <= '0;
            pulse_width <= '0;
            pulse_count <= '0;
            before_load_mode <= '0;
        end else begin
            if (mode_received) begin        // Save the mode data
                pim_mode <= data_i[2:0];
                row_addr <= row_addr;
                col_addr <= col_addr;
                pulse_width <= pulse_width;
                pulse_count <= pulse_count;
                if (data_i[2:0] == PIM_LOAD) begin
                    before_load_mode <= pim_mode;
                end else begin
                    before_load_mode <= before_load_mode;
                end
            end else if (address_i[31:16] == 16'h4000) begin    // Save the data 
                pim_mode <= pim_mode;
                before_load_mode <= before_load_mode;
                if (pim_mode == PIM_ERASE || pim_mode == PIM_PROGRAM) begin
                    row_addr <= address_i[15:9];
                    col_addr <= address_i[8:0];
                    pulse_width <= data_i[21:5];
                    pulse_count <= data_i[4:0];
                end else if (pim_mode == PIM_READ) begin
                    row_addr <= address_i[15:9];
                    col_addr <= address_i[8:0];
                    pulse_width <= '0;
                    pulse_count <= '0;
                end else if (pim_mode == PIM_PARALLEL) begin
                    row_addr <= address_i[15:9];
                    col_addr <= address_i[8:0];
                    pulse_width <= '0;
                    pulse_count <= '0;
                end else if (pim_mode == PIM_RBR) begin
                    row_addr <= address_i[15:9];
                    col_addr <= address_i[8:0];
                    pulse_width <= '0;
                    pulse_count <= '0;
                end else begin
                    row_addr <= row_addr;
                    col_addr <= col_addr;
                    pulse_width <= pulse_width;
                    pulse_count <= pulse_count;
                end
            end else begin
                pim_mode <= pim_mode;
                row_addr <= row_addr;
                col_addr <= col_addr;
                pulse_width <= pulse_width;
                pulse_count <= pulse_count;
                before_load_mode <= before_load_mode;
            end
        end
    end

    // ==|EXEC COUNTER|===================================================
    logic [3:0] counter;
    logic [16:0] p_width_counter;
    logic [4:0] p_count_counter;
    logic [4:0] load_counter;
    logic [1:0] processing_counter;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            counter <= '0;
            p_width_counter <= '0;
            p_count_counter <= '0;
            load_counter <= '0;
            processing_counter <= '0;
        end else begin
            if (pim_mode == PIM_READ) begin
                if (setup_finish) begin    
                    counter <= 4'd9;
                end else if (counter != '0) begin
                    counter <= counter - 1;
                end else begin
                    counter <= '0;
                end
            end else if (pim_mode == PIM_RBR) begin
                if (setup_finish) begin    
                    counter <= 4'd9;
                end else if (counter != '0) begin
                    counter <= counter - 1;
                end else begin
                    counter <= '0;
                end

                if (counter == '0 && processing_counter == '0) begin
                    processing_counter <= 2'd2;
                end else if (processing_counter != '0) begin
                    processing_counter <= processing_counter - 1;
                end

            end else if (pim_mode == PIM_PARALLEL) begin
                if (setup_finish) begin    
                    counter <= 4'd12;
                end else if (counter != '0) begin
                    counter <= counter - 1;
                end else begin
                    counter <= '0;
                end

                if (counter == '0 && processing_counter == '0) begin
                    processing_counter <= 2'd2;
                end else if (processing_counter != '0) begin
                    processing_counter <= processing_counter - 1;
                end

            end else if (pim_mode == PIM_ERASE || pim_mode == PIM_PROGRAM) begin
                if (setup_finish) begin
                    p_width_counter <= data_i[21:5];
                    p_count_counter <= data_i[4:0];
                end else if (p_count_counter != '0) begin
                    if (p_width_counter != '0) begin
                        p_width_counter <= p_width_counter -1;
                    end else begin
                        p_count_counter <= p_count_counter -1;
                        p_width_counter <= pulse_width;
                    end
                end else begin
                    p_width_counter <= '0;
                    p_count_counter <= '0;
                end
            end else if (pim_mode == PIM_LOAD) begin
                if (before_load_mode == PIM_READ) begin
                    if (setup_finish) begin
                        load_counter <= '0;
                    end else begin
                        load_counter <= '0;
                    end
                end else if (before_load_mode == PIM_PARALLEL || before_load_mode == PIM_RBR) begin
                    if (setup_finish) begin
                        load_counter <= 5'd31;
                    end else if (load_counter != '0) begin
                        load_counter <= load_counter - 1;
                    end else begin
                        load_counter <= '0;
                    end
                end else begin
                    load_counter <= '0;
                end                      
            end else begin
                counter <= '0;
                p_width_counter <= '0;
                p_count_counter <= '0;
            end
        end
    end


    // ==|OUTPUT SIGNAL|==================================================
    always_comb begin
        pim_en_o = '0;
        pim_mode_o = '0;
        row_addr7_o = '0;
        col_addr9_o = '0;
        exec_cnt_o = '0;
        in_buf_read_o = '0;
        before_load_mode_o = '0;
        load_en_o = '0;
        load_cnt_o = '0;
        in_buf_write_o = '0;
        input_data_o = '0;
        data_rx_cnt_o = '0;
        zp_en_o = '0;
        zp_data_o = '0;
        pim_out_buf_r_en_o = '0;
        output_processing_done_o = '0;
        case (curr_state)
            PIM_SETUP: begin
                if (pim_mode == PIM_PARALLEL || pim_mode == PIM_RBR) begin
                    if (address_i[31:16] == 12'h400) begin
                        in_buf_write_o = 1'b1;
                        input_data_o= data_i;
                        data_rx_cnt_o = address_i[15:12];
                    end else begin
                        in_buf_write_o = '0;
                        input_data_o = '0;
                        data_rx_cnt_o = '0;
                    end
                end else if (pim_mode == PIM_ZP) begin
                    zp_en_o = 1'b1;
                    zp_data_o = data_i;
                end else begin
                    in_buf_write_o = '0;
                    input_data_o = '0;
                    data_rx_cnt_o = '0;
                    zp_en_o = '0;
                    zp_data_o = '0;
                end
            end
            PIM_EXEC: begin
                if (pim_mode == PIM_ERASE || pim_mode == PIM_PROGRAM) begin
                    if (p_width_counter != '0) begin
                        pim_en_o = 1'b1;
                        pim_mode_o = pim_mode;
                        row_addr7_o = row_addr;
                        col_addr9_o = col_addr;
                    end else begin
                        pim_en_o = '0;
                        pim_mode_o = pim_mode;
                        row_addr7_o = row_addr;
                        col_addr9_o = col_addr;
                    end
                end else if (pim_mode == PIM_READ) begin
                    if (counter != '0) begin
                        pim_en_o = 1'b1;
                        pim_mode_o = pim_mode;
                        row_addr7_o = row_addr;
                        col_addr9_o = col_addr;
                        exec_cnt_o = counter;
                        in_buf_read_o = '0;
                    end else begin
                        pim_en_o = '0;
                        pim_mode_o = '0;
                        row_addr7_o = '0;
                        col_addr9_o = '0;
                        exec_cnt_o = '0;
                        in_buf_read_o = '0;
                    end
                end else if (pim_mode == PIM_PARALLEL || pim_mode == PIM_RBR) begin
                    if (counter != '0) begin
                        pim_en_o = 1'b1;
                        pim_mode_o = pim_mode;
                        row_addr7_o = row_addr;
                        col_addr9_o = col_addr;
                        exec_cnt_o = counter;
                        in_buf_read_o = 1'b1;
                    end else begin
                        pim_en_o = '0;
                        pim_mode_o = '0;
                        row_addr7_o = '0;
                        col_addr9_o = '0;
                        exec_cnt_o = '0;
                        in_buf_read_o = '0;
                    end
                end else if (pim_mode == PIM_LOAD) begin
                    before_load_mode_o = before_load_mode;
                    load_en_o = 1'b1;
                    load_cnt_o = load_counter;
                end else begin
                    pim_en_o = '0;
                    pim_mode_o = '0;
                    row_addr7_o = '0;
                    col_addr9_o = '0;
                    exec_cnt_o = '0;
                    in_buf_read_o = '0;
                    before_load_mode_o = '0;
                    load_en_o = '0;
                    load_cnt_o = '0;
                end
            end
            PIM_PROCESSING: begin
                pim_mode_o = pim_mode;
                if (processing_counter == 2'd2) begin
                    pim_out_buf_r_en_o = 1'b1;
                    output_processing_done_o = '0;
                end else if (processing_counter == 2'd1) begin
                    pim_out_buf_r_en_o = 1'b1;
                    output_processing_done_o = 1'b1;
                end else begin
                    pim_out_buf_r_en_o = '0;
                    output_processing_done_o = '0;
                end
            end
            default: begin
                pim_en_o = '0;
                pim_mode_o = '0;
                row_addr7_o = '0;
                col_addr9_o = '0;
                exec_cnt_o = '0;
                in_buf_read_o = '0;
                before_load_mode_o = '0;
                load_en_o = '0;
                load_cnt_o = '0;
                in_buf_write_o = '0;
                input_data_o = '0;
                data_rx_cnt_o = '0;
                zp_en_o = '0;
                zp_data_o = '0;
                pim_out_buf_r_en_o = '0;
                output_processing_done_o = '0;
            end
        endcase
    end

    // ==|FSM|============================================================
    // state transition
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
        end
    end

    always_comb begin
        case (curr_state) 
            IDLE: begin
                if (mode_received) begin
                    next_state = PIM_SETUP;
                end else begin
                    next_state = IDLE;
                end
            end
            PIM_SETUP: begin
                if (setup_finish) begin
                    if (pim_mode == PIM_ZP) begin
                        next_state = IDLE;
                    end else begin
                        next_state = PIM_EXEC;
                    end
                end else begin
                    next_state = PIM_SETUP;
                end
            end
            PIM_EXEC: begin
                if (pim_mode == PIM_ERASE || pim_mode == PIM_PROGRAM) begin
                    if (p_count_counter == 5'd1 && p_width_counter == '0) begin
                        next_state = IDLE;
                    end else begin
                        next_state = PIM_EXEC;
                    end
                end else if (pim_mode == PIM_READ || pim_mode == PIM_PARALLEL || pim_mode == PIM_RBR) begin
                    if (counter == '0) begin
                        next_state = PIM_PROCESSING;
                    end else begin
                        next_state = PIM_EXEC;
                    end
                end else if (pim_mode == PIM_LOAD) begin
                    if (load_counter == '0) begin
                        next_state = IDLE;
                    end else begin
                        next_state = PIM_EXEC;
                    end
                end else begin
                    next_state = PIM_EXEC;
                end
            end
            PIM_PROCESSING: begin
                if (processing_counter == '0) begin
                    next_state = IDLE;
                end else begin
                    next_state = PIM_PROCESSING;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    logic pim_valid;
    assign pim_valid = (curr_state == IDLE);
    logic pim_data_valid;
    assign pim_data_valid = 1'b1;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            data_o <= '0;
        end else begin
            if (address_i == PIM_STATUS) begin
                data_o <= {30'b0, pim_data_valid, pim_valid};
            end else if (load_en_o) begin
                data_o <= output_buffer_result_i;
            end else begin
                data_o <= '0;
            end
        end
    end

endmodule