module peri_controller(
    input logic         clk_i,
    input logic         rst_ni,

    // RISC-V
    input logic [31:0]  address_i,
    input logic [31:0]  data_i,

    output logic [31:0] data_o,

    // eFlash row driver
    output logic        pim_en_o,
    output logic [2:0]  pim_mode_o,
    output logic [3:0]  exec_cnt_o,

    output logic [6:0]  row_addr7_o,
    output logic [8:0]  col_addr9_o,

    // input buffer
    output logic [31:0] input_data_o,
    output logic [3:0]  data_rx_cnt_o,

    output logic        in_buf_write_o,
    output logic        in_buf_read_o,

    // output buffer
    //output logic        out_buf_write_o,
    output logic        out_buf_read_o,

    output logic [7:0]  read_ptr_o,

    input logic [31:0]  out_buf_data_i
);

    localparam MODE = 32'h4100_0000;
    localparam STATUS = 32'h4200_0000;

    // PIM mode
    localparam PIM_ERASE = 3'b001;
    localparam PIM_PROGRAM = 3'b010;
    localparam PIM_READ = 3'b011;
    localparam PIM_PARALLEL = 3'b100;
    localparam PIM_RBR = 3'b101;
    localparam PIM_LOAD = 3'b111;
    
    //state
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        WAIT_MODE = 2'b01,
        MODE_READY = 2'b10,
        MODE_EXEC = 2'b11
    } state_t;

    state_t current_state, next_state;

    logic   erase_en, program_en, read_en, parallel_en, rbr_en, load_en;

    logic   [3:0] data_rx_cnt;

    logic   [6:0] row_addr;
    logic   [8:0] col_addr;
    logic   [16:0] pulse_width, init_pulse_width;
    logic   [4:0] pulse_count, init_pulse_count;

    logic   pim_busy, pim_data_valid;

    logic   pim_en, load_exec_en;
    logic   [3:0] exec_cnt;
    logic   [5:0] read_ptr;

    logic   [31:0] output_result, data_o_next;

    // PIM mode enable signal
    logic   [5:0] pim_mode_en;
    assign erase_en = pim_mode_en[5];
    assign program_en = pim_mode_en[4];
    assign read_en = pim_mode_en[3];
    assign parallel_en = pim_mode_en[2];
    assign rbr_en = pim_mode_en[1];
    assign load_en = pim_mode_en[0];

    assign pim_busy = erase_en || program_en || read_en || parallel_en || rbr_en || load_en;
    assign pim_data_valid = 1'b1;


    // FSM
    // state transition
    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Next state logic
    always_comb begin
        case (current_state)
            IDLE: begin
                if (address_i == STATUS) begin
                    if (~pim_busy) begin
                        next_state = WAIT_MODE;
                    end else begin
                        next_state = IDLE;
                    end
                end else begin
                    next_state = IDLE;
                end
            end
            WAIT_MODE: begin
                if (address_i == MODE) begin
                    if (data_i[2:0] == PIM_ERASE || data_i[2:0] == PIM_PROGRAM || data_i[2:0] == PIM_READ || data_i[2:0] == PIM_PARALLEL || data_i[2:0] == PIM_RBR) begin
                        next_state = MODE_READY;
                    end else if (data_i[2:0] == PIM_LOAD) begin
                        next_state = MODE_EXEC;
                    end else begin
                        next_state = WAIT_MODE;
                    end
                end else begin
                    next_state = WAIT_MODE;
                end
            end
            MODE_READY: begin
                if (exec_trigger) begin
                    next_state = MODE_EXEC;
                end else begin
                    next_state = MODE_READY;
                end
            end
            MODE_EXEC: begin
                if (exec_finish) begin
                    next_state = IDLE;
                end else begin
                    next_state = MODE_EXEC;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // FSM state trigger signal
    assign exec_trigger = (current_state == MODE_READY) && (
        (pim_mode_en == 6'b100000 && address_i[31:20] == 12'h400)   ||      // erase
        (pim_mode_en == 6'b010000 && address_i[31:20] == 12'h400)   ||      // program
        (pim_mode_en == 6'b001000 && address_i[31:20] == 12'h400)   ||      // read
        (pim_mode_en == 6'b000100 && address_i[31:16] == 16'h400F)  ||      // parallel
        (pim_mode_en == 6'b000010 && address_i[31:16] == 16'h4001));        // rbr

    assign exec_finish = (current_state == MODE_EXEC) && (
        (pim_mode_en == 6'b100000 && pulse_count == '0)     ||      // erase
        (pim_mode_en == 6'b010000 && pulse_count == '0)     ||      // program
        (pim_mode_en == 6'b001000 && exec_cnt == '0)        ||      // read
        (pim_mode_en == 6'b000100 && exec_cnt == '0)        ||      // parallel
        (pim_mode_en == 6'b000010 && exec_cnt == '0)        ||      // rbr
        (pim_mode_en == 6'b000001 && address_i[5:0] == '0));        // load
    

    // Register 
    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            pim_mode_en <= '0; 
        end else begin
            in_buf_write_o <= '0;
            case (current_state) 
                WAIT_MODE: begin
                    if (address_i == MODE) begin
                        case (data_i[2:0]) 
                            PIM_ERASE: pim_mode_en <= 6'b100000;
                            PIM_PROGRAM: pim_mode_en <= 6'b010000;
                            PIM_READ: pim_mode_en <= 6'b001000;
                            PIM_PARALLEL: pim_mode_en <= 6'b000100;
                            PIM_RBR: pim_mode_en <= 6'b000010;
                            PIM_LOAD: pim_mode_en <= 6'b000001;
                            default: pim_mode_en <= 6'b000000;
                        endcase
                    end else begin
                        pim_mode_en <= 6'b000000;
                    end
                end
                MODE_READY: begin
                    pim_mode_en <= pim_mode_en;
                    case (pim_mode_en)
                        6'b100000: begin // erase mode
                            if (address_i[31:20] == 12'h400) begin
                                row_addr <= address_i[15:9];
                                col_addr <= address_i[8:0];
                                pulse_width <= data_i[21:5];
                                pulse_count <= data_i[4:0];
                                init_pulse_width <= data_i[21:5];
                                init_pulse_count <= data_i[4:0];                                
                            end else begin
                                row_addr <= '0;
                                col_addr <= '0;
                                pulse_width <= '0;
                                pulse_count <= '0;
                                init_pulse_width <= '0;
                                init_pulse_count <= '0;
                            end
                        end
                        6'b010000: begin // program mode
                            if (address_i[31:20] == 12'h400) begin
                                row_addr <= address_i[15:9];
                                col_addr <= address_i[8:0];
                                pulse_width <= data_i[21:5];
                                pulse_count <= data_i[4:0];
                                init_pulse_width <= data_i[21:5];
                                init_pulse_count <= data_i[4:0];
                            end else begin
                                row_addr <= '0;
                                col_addr <= '0;
                                pulse_width <= '0;
                                pulse_count <= '0;
                                init_pulse_width <= '0;
                                init_pulse_count <= '0;
                            end
                        end
                        6'b001000: begin // read mode
                            if (address_i[31:20] == 12'h400) begin
                                row_addr <= address_i[15:9];
                                col_addr <= address_i[8:0];
                                exec_cnt <= 4'd9;
                            end else begin
                                row_addr <= '0;
                                col_addr <= '0;
                                exec_cnt <= '0;
                            end
                        end
                        6'b000100: begin // parallel mode
                            if (address_i[31:20] == 12'h400) begin
                                row_addr <= address_i[15:9];
                                col_addr <= address_i[8:0];
                                in_buf_write_o <= 1'b1;
                                input_data_o <= data_i;
                                data_rx_cnt_o <= address_i[19:16];
                                exec_cnt <= 4'd12;
                            end else begin
                                row_addr <= '0;
                                col_addr <= '0;
                                in_buf_write_o <= '0;
                                input_data_o <= '0;
                                data_rx_cnt_o <= '0;
                                exec_cnt <= '0;
                            end
                        end
                        6'b000010: begin // rbr mode
                            if (address_i[31:20] == 12'h400) begin
                                row_addr <= address_i[15:9];
                                col_addr <= address_i[8:0];
                                in_buf_write_o <= 1'b1;
                                input_data_o <= data_i;
                                data_rx_cnt_o <= address_i[19:16];
                                exec_cnt <= 4'd9;
                            end else begin
                                row_addr <= '0;
                                col_addr <= '0;
                                in_buf_write_o <= '0;
                                input_data_o <= '0;
                                data_rx_cnt_o <= '0;
                                exec_cnt <= '0;
                            end
                        end
                        default: begin
                            row_addr <= '0;
                            col_addr <= '0;
                            pulse_width <= '0;
                            pulse_count <= '0;
                            init_pulse_width <= '0;
                            init_pulse_count <= '0;
                            in_buf_write_o <= '0;
                            input_data_o <= '0;
                            data_rx_cnt_o <= '0;
                            exec_cnt <= '0;
                        end                
                    endcase
                end
                MODE_EXEC: begin
                    case (pim_mode_en)
                        6'b100000: begin    // erase
                            if (pulse_count != '0) begin
                                if (pulse_width != '0) begin
                                    pim_en <= 1'b1;
                                    pulse_width <= pulse_width - 17'd1;
                                end else begin
                                    pim_en <= 1'b0;
                                    pulse_count <= pulse_count - 5'd1;
                                    pulse_width <= init_pulse_width;
                                end
                            end else begin
                                pim_en <= 1'b0;
                                pim_mode_en <= 6'b000000;
                            end
                        end
                        6'b010000: begin    // program
                            if (pulse_count != '0) begin
                                if (pulse_width != '0) begin
                                    pim_en <= 1'b1;
                                    pulse_width <= pulse_width - 17'd1;
                                end else begin
                                    pim_en <= 1'b0;
                                    pulse_count <= pulse_count - 5'd1;
                                    pulse_width <= init_pulse_width;
                                end
                            end else begin
                                pim_en <= 1'b0;
                                pim_mode_en <= 6'b000000;
                            end
                        end
                        6'b001000: begin    // read
                            if (exec_cnt != '0) begin
                                pim_en <= 1'b1;
                                exec_cnt <= exec_cnt - 4'd1;
                            end else begin
                                pim_en <= 1'b0;
                                pim_mode_en <= 6'b000000;
                            end
                        end
                        6'b000100: begin    // parallel
                            if (exec_cnt != '0) begin
                                pim_en <= 1'b1;
                                exec_cnt <= exec_cnt - 4'd1;
                            end else begin
                                pim_en <= 1'b0;
                                pim_mode_en <= 6'b000000;
                            end
                        end
                        6'b000010: begin    // rbr
                            if (exec_cnt != '0) begin
                                pim_en <= 1'b1;
                                exec_cnt <= exec_cnt - 4'd1;
                            end else begin
                                pim_en <= 1'b0;
                                pim_mode_en <= 6'b000000;
                            end
                        end
                        6'b000001: begin
                            if (address_i[31:20] == 12'h400) begin
                                load_exec_en <= 1'b1;
                                read_ptr <= address_i[5:0];
                            end else begin
                                load_exec_en <= 1'b0;
                                read_ptr <= '0;
                                pim_mode_en <= 6'b000000;
                            end
                        end
                        default: begin
                            pim_en <= 1'b0;
                            load_exec_en <= 1'b0;
                            read_ptr <= '0;
                            pim_mode_en <= 6'b000000;
                        end
                    endcase
                end
            endcase
        end
    end


    // signal to PIM during MODE_EXEC state
    always_comb begin
        case (pim_mode_en) 
            6'b100000: begin    // erase mode
                if (pim_en) begin
                    pim_en_o = 1'b1;
                    pim_mode_o = PIM_ERASE;
                    row_addr7_o = row_addr;
                end else begin
                    pim_en_o = '0;
                    pim_mode_o = '0;
                    row_addr7_o = '0;
                end
            end
            6'b010000: begin    // program mode
                if (pim_en) begin
                    pim_en_o = 1'b1;
                    pim_mode_o = PIM_PROGRAM;
                    row_addr7_o = row_addr;
                    col_addr9_o = col_addr;
                end else begin
                    pim_en_o = '0;
                    pim_mode_o = '0;
                    row_addr7_o = '0;
                    col_addr9_o = '0;
                end
            end
            6'b001000: begin    // read mode
                if (pim_en) begin
                    pim_en_o = 1'b1;
                    pim_mode_o = PIM_READ;
                    row_addr7_o = row_addr;
                    col_addr9_o = col_addr;
                    exec_cnt_o = exec_cnt;
                end else begin
                    pim_en_o = '0;
                    pim_mode_o = '0;
                    row_addr7_o = '0;
                    col_addr9_o = '0;
                    exec_cnt_o = '0;
                end
            end
            6'b000100: begin    // parallel
                if (pim_en) begin
                    pim_en_o = 1'b1;
                    pim_mode_o = PIM_PARALLEL;
                    in_buf_read_o = 1'b1;
                    row_addr7_o = row_addr;
                    col_addr9_o = col_addr;
                    exec_cnt_o = exec_cnt;
                end else begin
                    pim_en_o = '0;
                    pim_mode_o = '0;
                    in_buf_read_o = '0;
                    row_addr7_o = '0;
                    col_addr9_o = '0;
                    exec_cnt_o = '0;
                end
            end
            6'b000010: begin    // rbr
                if (pim_en) begin
                    pim_en_o = '0;
                    pim_mode_o = PIM_RBR;
                    in_buf_read_o = 1'b1;
                    row_addr7_o = row_addr;
                    col_addr9_o = col_addr;
                    exec_cnt_o = exec_cnt;
                end else begin
                    pim_en_o = '0;
                    pim_mode_o= '0;
                    in_buf_read_o = '0;
                    row_addr7_o = '0;
                    col_addr9_o = '0;
                    exec_cnt_o = '0;
                end
            end
            6'b000001: begin    // load
                if (load_exec_en) begin
                    out_buf_read_o = 1'b1;
                    read_ptr_o = read_ptr;
                end else begin
                    out_buf_read_o = '0;
                    read_ptr_o = '0;
                end
            end
            default: begin
                pim_en_o = '0;
                pim_mode_o = '0;
                in_buf_read_o = '0;
                row_addr7_o = '0;
                col_addr9_o = '0;
                exec_cnt_o = '0;
            end
        endcase
    end


    // output result from the ouput buffer at load mode
    assign output_result = out_buf_data_i;

    always_comb begin
        if (address_i == STATUS) begin
            data_o_next = {30'b0, pim_data_valid, pim_busy};
        end else if (load_exec_en == 1'b1) begin
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