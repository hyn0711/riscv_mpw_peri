`timescale 1ns/10ps

module tb_peri_top;

    // Parameter and Signals -----------------------------------
    parameter CLK_PERIOD = 10;


    reg clk_i;
    reg rst_ni;

    reg [31:0] address_i;
    reg [31:0] data_i;

    wire [31:0] data_o;

    reg [1023:0] eFlash_output_i;

    wire [1:0] MODE_o;
    wire [127:0] WL_SEL_o;
    wire [127:0] VPASS_EN_o;

    wire [7:0] DUML_o;
    wire [7:0] CSL_o;
    wire [31:0] BSEL_o;
    wire [7:0] CSEL_o;
    wire ADC_EN1_o;
    wire ADC_EN2_o;
    wire [7:0] QDAC_o;
    wire [1:0] RSEL_o;

    wire [255:0] DUMH_o;
    wire [127:0] PRECB_o;
    wire [127:0] DISC_o;
    // ---------------------------------------------------------


    peri_top DUT (
    .clk_i(clk_i),
    .rst_ni(rst_ni),

    // RISC-V <-> PERI
    .address_i(address_i),
    .data_i(data_i),
    
    .data_o(data_o),

    .eFlash_output_i(eFlash_output_i),

    // PERI <-> PIM
    .MODE_o(MODE_o),
    .WL_SEL_o(WL_SEL_o),
    .VPASS_EN_o(VPASS_EN_o),

    .DUML_o(DUML_o),
    .CSL_o(CSL_o),
    .BSEL_o(BSEL_o),
    .CSEL_o(CSEL_o),
    .ADC_EN1_o(ADC_EN1_o),
    .ADC_EN2_o(ADC_EN2_o),
    .QDAC_o(QDAC_o), 
    .RSEL_o(RSEL_o),

    .DUMH_o(DUMH_o),
    .PRECB_o(PRECB_o),
    .DISC_o(DISC_o)
    );

    initial begin
        $dumpfile("peri_top_wave.vcd");
        $dumpvars(0, tb_peri_top);
    end

    always begin
        #(CLK_PERIOD/2) clk_i = ~clk_i;
    end

    // Pim mode ------------------------------------------------
    typedef enum logic [2:0] {
        PIM_ERASE = 3'b001,
        PIM_PROGRAM = 3'b010,
        PIM_READ = 3'b011,
        PIM_ZP = 3'b100,
        PIM_PARALLEL = 3'b101,
        PIM_RBR = 3'b110,
        PIM_LOAD = 3'b111
    } pim_mode_t;

    // ---------------------------------------------------------
    // RISC-V -> Peri
    task automatic send_mode(input pim_mode_t pim_mode);
        @(negedge clk_i);
        address_i = 32'h4100_0000;
        data_i = {29'b0, pim_mode};
    endtask

    task automatic check_status();
        @(negedge clk_i); 
        address_i = 32'h4300_0000;
    endtask

    task automatic send_data(
        input pim_mode_t pim_mode,
        input int row, 
        input int col,
        input int p_width, 
        input int p_count,
        input int zp
    );
        case (pim_mode)
        PIM_ERASE: begin
            @(negedge clk_i);
            address_i = {16'h4000, row[6:0], col[8:0]};
            data_i = {10'b0, p_width[16:0], p_count[4:0]};
        end
        PIM_PROGRAM: begin
            @(negedge clk_i);
            address_i = {16'h4000, row[6:0], col[8:0]};
            data_i = {10'b0, p_width[16:0], p_count[4:0]};
        end
        PIM_READ: begin
            @(negedge clk_i);
            address_i = {16'h4000, row[6:0], col[8:0]};
            data_i = '0;
        end
        PIM_ZP: begin
            @(negedge clk_i);
            address_i = 32'h4200_0000;
            data_i = zp[31:0];
        end
        PIM_PARALLEL: begin
            for (int i = 0; i < 16; i++) begin
                @(negedge clk_i);
                address_i = {12'h400, i[3:0], row[6:0], col[8:0]};
                for (int j = 0; j < 16; j++) begin
                    data_i[2 * j +: 2] = $urandom_range(0, 3);
                end
            end
            repeat(10) @(negedge clk_i); random_eFlash_output();
            repeat(3) @(negedge clk_i); random_eFlash_output();
            @(negedge clk_i);
        end
        PIM_RBR: begin
            for (int i = 0; i < 2; i++) begin
                @(negedge clk_i);
                address_i = {12'h400, i[3:0], row[6:0], col[8:0]};
                for (int j = 0; j < 16; j++) begin
                    data_i[2 * j +: 2] = $urandom_range(0, 3);
                end
            end
            repeat(10) @(negedge clk_i); random_eFlash_output();
            @(negedge clk_i); 
        end
        endcase
    endtask

    // Make the random output from the eFlash PIM
    task automatic random_eFlash_output();
        // 8 bit * 128
        logic [7:0] choices8b[] = '{
            8'b00000000, 8'b10000000, 8'b11000000, 8'b11100000, 8'b11110000, 8'b11111000, 8'b11111100, 8'b11111110, 8'b11111111
            };
        for (int i = 0; i < 128; i++) begin
            eFlash_output_i[1023 - 8*i -: 8] = choices8b[$urandom_range(0, choices8b.size()-1)];
        end
    endtask

    // Reset all the input signal
    task automatic init_signals();
        @(negedge clk_i);
        address_i = '0;
        data_i = '0;
        eFlash_output_i = '0;
    endtask
    // ---------------------------------------------------------

    // Testbench -----------------------------------------------
    initial begin
        // Initialize signals
        rst_ni = '0;
        clk_i = 1'b1;
        init_signals();

        repeat(2) @(posedge clk_i); rst_ni = 1'b1;

        check_status();
        init_signals();

        // Erase mode
        send_mode(PIM_ERASE);
        send_data(PIM_ERASE, 1, 1, 2, 2, 0);
        init_signals();

        // Zero Point
        repeat(10) check_status();
        init_signals();
        
        send_mode(PIM_ZP);
        send_data(PIM_ZP, 0, 0, 0, 0, 10);
        init_signals();

        // Parallrl mode 4 times
        // Fisrt 
        repeat(3) check_status();
        init_signals();
       
        send_mode(PIM_PARALLEL);
        send_data(PIM_PARALLEL, 1, 1, 0, 0, 0);
        init_signals();

        // Second
        repeat(20) check_status();
        init_signals();

        send_mode(PIM_PARALLEL);
        send_data(PIM_PARALLEL, 1, 1, 0, 0, 0);
        init_signals();

        // Third
        repeat(20) check_status();
        init_signals();

        send_mode(PIM_PARALLEL);
        send_data(PIM_PARALLEL, 1, 1, 0, 0, 0);
        init_signals();

        // Fourth
        repeat(20) check_status();
        init_signals();

        send_mode(PIM_PARALLEL);
        send_data(PIM_PARALLEL, 1, 1, 0, 0, 0);
        init_signals();

        // Load mode
        repeat(20) check_status();
        init_signals();

        send_mode(PIM_LOAD);
        init_signals();

        // Test erase mode
        // @(negedge clk_i); address_i = 32'h4200_0000;

        // @(negedge clk_i); init_signals();

        // @(negedge clk_i); address_i = 32'h4100_0000;
        //                   data_i = {29'b0, 3'b001};

        // @(negedge clk_i); address_i = {16'h4000, 7'd2, 9'd0};   // Row = 2
        //                   data_i = {10'b0, 17'd5, 5'd2};    //5 cycles * 2 times

        // @(negedge clk_i); init_signals();

        // @(negedge clk_i); address_i = 32'h4200_0000;
        // @(negedge clk_i); init_signals();

        // repeat(20) @(negedge clk_i); address_i = 32'h4200_0000;

        // // Test program mode
        // @(negedge clk_i); address_i = 32'h4100_0000;
        //                   data_i = {29'b0, 3'b010};
        // @(negedge clk_i); address_i = {16'h4000, 7'd4, 9'd11};
        //                 data_i = {10'b0, 17'd2, 5'd3}; // 2 cycle *  3 times

        // @(negedge clk_i); init_signals();

        // @(negedge clk_i); address_i = 32'h4200_0000;
        // @(negedge clk_i); init_signals();

        // repeat(20) @(negedge clk_i); address_i = 32'h4200_0000;

        // // Test Parallel mode
        // @(negedge clk_i); address_i = 32'h4100_0000;
        //                   data_i = {29'b0, 3'b100};
        // @(negedge clk_i); address_i = {16'h4000, 7'd1, 9'd1};
        //                   data_i = {16{2'b00}};
        // @(negedge clk_i); address_i = {16'h4001, 7'd1, 9'd1};
        //                   data_i = {16{2'b00}};
        // @(negedge clk_i); address_i = {16'h4002, 7'd1, 9'd1};
        //                   data_i = {16{2'b00}};
        // @(negedge clk_i); address_i = {16'h4003, 7'd1, 9'd1};
        //                   data_i = {16{2'b00}};
        // @(negedge clk_i); address_i = {16'h4004, 7'd1, 9'd1};
        //                   data_i = {16{2'b01}};
        // @(negedge clk_i); address_i = {16'h4005, 7'd1, 9'd1};
        //                   data_i = {16{2'b01}};
        // @(negedge clk_i); address_i = {16'h4006, 7'd1, 9'd1};
        //                   data_i = {16{2'b01}};
        // @(negedge clk_i); address_i = {16'h4007, 7'd1, 9'd1};
        //                   data_i = {16{2'b01}};                                                      
        // @(negedge clk_i); address_i = {16'h4008, 7'd1, 9'd1};
        //                   data_i = {16{2'b10}};
        // @(negedge clk_i); address_i = {16'h4009, 7'd1, 9'd1};
        //                   data_i = {16{2'b10}};
        // @(negedge clk_i); address_i = {16'h400A, 7'd1, 9'd1};
        //                   data_i = {16{2'b10}};
        // @(negedge clk_i); address_i = {16'h400B, 7'd1, 9'd1};
        //                   data_i = {16{2'b10}};
        // @(negedge clk_i); address_i = {16'h400C, 7'd1, 9'd1};
        //                   data_i = {16{2'b11}};
        // @(negedge clk_i); address_i = {16'h400D, 7'd1, 9'd1};
        //                   data_i = {16{2'b11}};
        // @(negedge clk_i); address_i = {16'h400E, 7'd1, 9'd1};
        //                   data_i = {16{2'b11}};
        // @(negedge clk_i); address_i = {16'h400F, 7'd1, 9'd1};
        //                   data_i = {16{2'b11}};

        // @(negedge clk_i); init_signals();
       
        
        repeat(100) @(posedge clk_i); $finish;

    end



endmodule