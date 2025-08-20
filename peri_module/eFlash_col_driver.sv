
// Input buffer //
// Store 2 bit input data x 256 for parallel mode
//                        X 32 for rowbyrow mode

// eFlash_col_driver //
// DUMH, PRECB, DISC signal

module eFlash_col_driver (
    input logic             clk_i,
    input logic             rst_ni,

    // Buffer input
    input logic [1:0]       input_data_i [0:255],  

    // eFlash signal control
    input logic             pim_en_i,
    input logic [2:0]       pim_mode_i,
    input logic [3:0]       exec_cnt_i,

    input logic [6:0]       row_addr7_i,
    input logic [8:0]       col_addr9_i,

    output logic [255:0]    DUMH_o,
    output logic [127:0]    PRECB_o,
    output logic [127:0]    DISC_o
);

    // eFlash mode
    localparam PIM_ERASE = 3'b001;
    localparam PIM_PROGRAM = 3'b010;
    localparam PIM_READ = 3'b011;
    localparam PIM_ZP = 3'b100;
    localparam PIM_PARALLEL = 3'b101;
    localparam PIM_RBR = 3'b110;
    localparam PIM_LOAD = 3'b111;

    logic pim_en;
    logic [2:0] pim_mode;
    logic [3:0] exec_cnt;

    assign pim_en = pim_en_i;
    assign pim_mode = pim_mode_i;
    assign exec_cnt = exec_cnt_i;

    logic [255:0] dumh;
    logic [127:0] precb, disc;

    logic [3:0] row_a;
    logic [1:0] col_b;
    logic [2:0] row_c;

    assign row_a = row_addr7_i[3:0];
    assign col_b = col_addr9_i[1:0];
    assign row_c = row_addr7_i[6:4];


    // --------------------------- eFlash signal ---------------------------
    always_comb begin
        dumh = '0;
        precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        disc = '0;
        if (pim_en) begin
            case (pim_mode)
                PIM_ERASE: begin    // erase mode
                    dumh = '0;
                    precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                    disc = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                end
                PIM_PROGRAM: begin    // program mode
                    for (int unsigned i = 0; i < 256; i++) begin
                        if (i == ((row_addr7_i/16)+8*(col_addr9_i/16))) begin
                            dumh[i] = 1'b1;
                        end else begin
                            dumh[i] = 1'b0;
                        end
                    end
                    for (int unsigned j = 0; j < 128; j++) begin
                        if (j == (col_addr9_i/4)) begin
                            precb[j] = 1'b1;
                            disc[j] = 1'b1;
                        end else begin
                            precb[j] = 1'b0;
                            disc[j] = 1'b0;
                        end
                    end
                end
                PIM_READ: begin    // Read mode
                    if (exec_cnt == 4'd8 || exec_cnt == 4'd7 || exec_cnt == 4'd6) begin
                        for (int unsigned i = 0; i < 256; i++) begin
                            if ((i - row_c) % 8 == 0) begin
                                dumh[i] = 1'b1;
                            end else begin
                                dumh[i] = 1'b0;
                            end
                        end
                        precb = '0;
                        disc = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                    end else if (exec_cnt == 4'd5) begin
                        for (int unsigned i = 0; i < 256; i++) begin
                            if ((i - row_c) % 8 == 0) begin
                                dumh[i] = 1'b1;
                            end else begin
                                dumh[i] = 1'b0;
                            end
                        end
                        precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        disc = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                    end else if (exec_cnt == 4'd4 || exec_cnt == 4'd3) begin
                        dumh = '0;
                        precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        disc = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                    end else if (exec_cnt == 4'd2 ||exec_cnt == 4'd1 || exec_cnt == 4'd0) begin
                        dumh = '0;
                        precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        disc = '0;
                    end else begin
                        dumh = '0;
                        precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        disc = '0;
                    end
                end
                PIM_PARALLEL: begin    // Parallel mode
                    if (exec_cnt == 4'd11 || exec_cnt == 4'd10 || exec_cnt == 4'd9) begin
                        dumh = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        precb = '0;
                        disc = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                    end else if (exec_cnt == 4'd8 || exec_cnt == 4'd7 || exec_cnt == 4'd6) begin
                        for (int unsigned i = 0; i < 256; i++) begin
                            case (input_data_i[i])
                                2'b00: begin
                                    dumh[i] = '0;
                                end
                                2'b01: begin
                                    dumh[i] = (exec_cnt == 4'd8) ;
                                end
                                2'b10: begin
                                    dumh[i] = (exec_cnt == 4'd8 || exec_cnt == 4'd7) ;
                                end
                                2'b11: begin
                                    dumh[i] = 1'b1;
                                end
                                default: begin
                                    dumh[i] = '0;
                                end
                            endcase
                        end
                        precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        disc = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                    end else if (exec_cnt == 4'd5 || exec_cnt == 4'd4 || exec_cnt == 4'd3 || exec_cnt == 4'd2 || exec_cnt == 4'd1 || exec_cnt == 4'd0) begin
                        dumh = '0;
                        precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        disc = '0;
                    end else begin
                        dumh = '0;
                        precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        disc = '0;
                    end
                end
                PIM_RBR: begin    // Rbr mode
                    if (exec_cnt == 4'd8 || exec_cnt == 4'd7 || exec_cnt == 4'd6) begin
                        for (int unsigned i = 0; i < 256; i++) begin
                            if ((i - row_c) % 8 == 0) begin
                                dumh[i] = 1'b1;
                            end else begin
                                dumh[i] = '0;
                            end
                        end
                        precb = '0;
                        disc = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                    end else if (exec_cnt == 4'd5 || exec_cnt == 4'd4 || exec_cnt == 4'd3) begin
                        dumh = '0;
                        for (int unsigned i = 0; i < 32; i++) begin
                            case (input_data_i[i])
                                2'b00: begin
                                    dumh[8 * i + row_c] = '0;
                                end
                                2'b01: begin
                                    if (exec_cnt == 4'd5) begin
                                        dumh[8 * i + row_c] = 1'b1;
                                    end else begin
                                        dumh[8 * i + row_c] = '0;
                                    end
                                end
                                2'b10: begin
                                    if (exec_cnt == 4'd5 || exec_cnt == 4'd4) begin
                                        dumh[8 * i + row_c] = 1'b1;
                                    end else begin
                                        dumh[8 * i + row_c] = '0;
                                    end
                                end
                                2'b11: begin
                                    dumh[8 * i + row_c] = 1'b1;
                                end
                                default: begin
                                    dumh[8 * i + row_c] = '0;
                                end
                            endcase
                        end
                        precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        disc = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                    end else if (exec_cnt == 4'd2 || exec_cnt == 4'd1 || exec_cnt == 4'd0) begin
                        dumh = '0;
                        precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        disc = '0;
                    end else begin
                        dumh = '0;
                        precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                        disc = '0;
                    end
                end
                PIM_LOAD: begin    // Load mode
                end
                default: begin
                    dumh = '0;
                    precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                    disc = '0;
                end
            endcase
        end else begin
            dumh = '0;
            precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
            disc = '0;
        end
    end

    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            DUMH_o <= '0;
            PRECB_o <= 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
            DISC_o <= '0;
        end else begin
            DUMH_o <= dumh;
            PRECB_o <= precb;
            DISC_o <= disc;
        end
    end

endmodule 
