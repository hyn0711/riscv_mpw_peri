
// HVS driver + eFLASH driver

module eFLASH_driver (
    input logic                 clk_i,
    input logic                 rst_ni,

    // mode
    input logic                 erase_en_i,
    input logic                 program_en_i,
    input logic                 read_en_i,
    input logic                 parallel_en_i,
    input logic                 rowbyrow_en_i,

    // address
    input logic [6:0]           row_addr7_i,
    input logic [8:0]           col_addr9_i,

    // input
    input logic [1:0]           input_i[0:255],  
    //input logic [511:0]         input_flat_i,       // for testbench     

    input logic [3:0]           exec_cnt_i,

    // HVS signal
    output logic [1:0]          MODE_o,
    output logic [127:0]        WL_SEL_o,
    output logic [127:0]        VPASS_EN_o,

    // eFLASH signal
    output logic [255:0]        DUMH_o,
    output logic [255:0]        DUML_o,
    output logic [7:0]          CSL_o,
    output logic [3:0]          BSEL_o,
    output logic [3:0]          BSELB_o,
    output logic [7:0]          CSEL_o,
    output logic [7:0]          CSELB_o,
    output logic [127:0]        PRECB_o,
    output logic [127:0]        DISC_o,
    output logic                ADC_EN_o,
    output logic                DFF_o,
    output logic                QDAC_o, 

    output logic                out_buf_write_o
);

    // HVS
    logic [1:0]         mode;
    logic [127:0]       wl_sel;
    logic [127:0]       vpass_en;

    // eFLASH 
    logic [255:0] dumh, duml;
    logic [7:0] csl, csel, cselb;
    logic [3:0] bsel, bselb;
    logic [127:0] precb, disc;
    logic adc_en, dff, qdac;

    logic [3:0] row_a;
    logic [1:0] col_b;
    logic [2:0] row_c;

    logic out_buf_write;

    assign row_a = row_addr7_i[3:0];
    assign col_b = col_addr9_i[1:0];
    assign row_c = row_addr7_i[6:4];


    // // flat input for testbench //
    // logic [1:0] input_i[0:255];
    
    // always_comb begin
    //     for (int i = 0; i < 256; i++) begin
    //         input_i[i] = input_flat_i[i*2 +: 2];
    //     end
    // end
    ////


//////////////////////////
    always_comb begin
        // HVS
        mode = '0;
        wl_sel = '0;
        vpass_en = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        // eFLASH
        dumh = '0;
        duml = '0;
        csl = '0;
        bsel = '0;
        bselb = 4'b1111;
        csel = '0;
        cselb = 8'hFF;
        precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        disc = '0;
        adc_en = '0;
        dff = '0;
        qdac = 1'b1;
        // output buffer
        out_buf_write = 1'b0;
        // Erase mode
        if (erase_en_i) begin
            out_buf_write = 1'b0;
            // HVS
            mode = 2'b00;
            for (int unsigned i = 0; i < 128; i++) begin
                vpass_en[i] = 1'b1;
                if (i == row_addr7_i) begin
                    wl_sel[i] = 1'b1;
                end else begin
                    wl_sel[i] = 1'b0;
                end
            end
            // eFLASH 
            dumh = '0;
            duml = '0;
            csl = '0;
            bsel = 4'b1111;
            bselb = '0;
            precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
            disc = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
            adc_en = '0;
            dff = '0;
            qdac = 1'b1;
            for (int unsigned i = 0; i < 8; i++) begin
                if (i == (row_addr7_i/16)) begin
                    csel[i] = 1'b1;
                    cselb[i] = 1'b0;
                end else begin
                    csel[i] = 1'b0;
                    cselb[i] = 1'b1;
                end
            end

        // Program mode
        end else if (program_en_i) begin
            out_buf_write = 1'b0;
            // HVS
            mode = 2'b01;
            for (int unsigned i = 0; i < 128; i++) begin
                if (i == row_addr7_i) begin
                    wl_sel[i] = 1'b1;
                    vpass_en[i] = 1'b1;
                end else begin
                    wl_sel[i] = 1'b0;
                    vpass_en[i] = 1'b0;
                end
            end
            // eFLASH
            duml = '0;
            csl = 8'hFF;
            adc_en = 1'b0;
            dff = 1'b0;
            qdac = 1'b1;
            for (int unsigned i = 0; i < 256; i++) begin
                if (i == (8*(row_addr7_i/16)+(col_addr9_i/16))) begin
                    dumh[i] = 1'b1;
                end else begin
                    dumh[i] = 1'b0;
                end
            end
            for (int unsigned j = 0; j < 4; j++) begin
                if (j == (col_addr9_i%4)) begin
                    bsel[j] = 1'b1;
                    bselb[j] = 1'b0;
                end else begin
                    bsel[j] = 1'b0;
                    bselb[j] = 1'b1;
                end
            end
            for (int unsigned k = 0; k < 8; k++) begin
                if (k == (row_addr7_i/16)) begin
                    csel[k] = 1'b1;
                    cselb[k] = 1'b0;
                end else begin
                    csel[k] = 1'b0;
                    cselb[k] = 1'b1;
                end
            end
            for (int unsigned n = 0; n < 128; n++) begin
                if (n == (col_addr9_i/4)) begin
                    precb[n] = 1'b1;
                    disc[n] = 1'b1;
                end else begin
                    precb[n] = 1'b0;
                    disc[n] = 1'b0;
                end
            end

        // Read mode
        end else if (read_en_i) begin
            mode = 2'b10;
            //HVS
            for (int unsigned i = 0; i < 128; i++) begin
                if (i == row_addr7_i) begin
                    wl_sel[i] = 1'b1;
                    vpass_en[i] = 1'b1;
                end else begin
                    wl_sel[i] = 1'b0;
                    vpass_en[i] = 1'b0;
                end
            end
            if (exec_cnt_i == 4'd8 || exec_cnt_i == 4'd7 || exec_cnt_i == 4'd6) begin
                // eFLASH
                dumh = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                duml = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                csl = '0;
                csel = '0;
                cselb = 8'hFF;
                precb = '0;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
                for (int unsigned i = 0; i < 4; i++) begin
                    if (i == col_b) begin
                        bsel[i] = 1'b1;
                        bselb[i] = 1'b0;
                    end else begin
                        bsel[i] = 1'b0;
                        bselb[i] = 1'b1;
                    end
                end
            end else if (exec_cnt_i == 4'd5) begin
                // eFLASH
                csl = '0;
                csel = '0;
                cselb = 8'hFF;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
                for (int unsigned i = 0; i < 256; i++) begin
                    if ((i-row_c)%8 == 0) begin
                        dumh[i] = 1'b1;
                        duml[i] = 1'b1;
                    end else begin
                        dumh[i] = 1'b0;
                        duml[i] = 1'b0;
                    end
                end
                for (int unsigned j = 0; j < 4; j++) begin
                    if (j == col_b) begin
                        bsel[j] = 1'b1;
                        bselb = 1'b0;
                    end else begin
                        bsel[j] = 1'b0;
                        bselb[j] = 1'b1;
                    end
                end
            end else if (exec_cnt_i == 4'd4 || exec_cnt_i == 4'd3) begin
                // eFLASH
                dumh = '0;
                duml = '0;
                csl = '0;
                csel = '0;
                cselb = 8'hFF;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
                for (int unsigned j = 0; j < 4; j++) begin
                    if (j == col_b) begin
                        bsel[j] = 1'b1;
                        bselb = 1'b0;
                    end else begin
                        bsel[j] = 1'b0;
                        bselb[j] = 1'b1;
                    end
                end
            end else if (exec_cnt_i == 4'd2) begin
                // eFLASH
                dumh = '0;
                duml = '0;
                csl = '0;
                bsel = '0;
                bselb = 4'b1111;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
                for (int unsigned i = 0; i < 8; i++) begin
                    if (i == row_c) begin
                        csel[i] = 1'b1;
                        cselb[i] = 1'b0;
                    end else begin
                        csel[i] = 1'b0;
                        cselb[i] = 1'b1;
                    end 
                end
            end else if (exec_cnt_i == 4'd1 || exec_cnt_i == 4'd0) begin
                // eFLASH
                dumh = '0;
                duml = '0;
                csl = '0;
                bsel = '0;
                bselb = 4'b1111;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = 1'b1;
                dff = '0;
                qdac = 1'b1;
                for (int unsigned i = 0; i < 8; i++) begin
                    if (i == row_c) begin
                        csel[i] = 1'b1;
                        cselb[i] = 1'b0;
                    end else begin
                        csel[i] = 1'b0;
                        cselb[i] = 1'b1;
                    end 
                end
            end else begin
                // eFLASH
                dumh = '0;
                duml = '0;
                csl = '0;
                bsel = '0;
                bselb = 4'b1111;
                csel = '0;
                cselb = 8'hFF;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
            end

            if (exec_cnt_i == 4'd0) begin
                out_buf_write = 1'b1;   // output buffer write signal
            end else begin
                out_buf_write = 1'b0;
            end

        // Parallel mode
        end else if (parallel_en_i) begin
            // HVS
            mode = 2'b10;
            for (int unsigned i = 0; i < 128; i++) begin
                for (int unsigned j = 0; j < 8; j++) begin
                    if (i == (16 * j + row_a)) begin
                        wl_sel[i] = 1'b1;
                        vpass_en[i] = 1'b1;
                    end else begin
                        wl_sel[i] = 1'b0;
                        vpass_en[i] = 1'b0;
                    end
                end
            end
            // eFLASH
            if (exec_cnt_i == 4'd11 || exec_cnt_i == 4'd10 || exec_cnt_i == 4'd9) begin
                dumh = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                duml = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                csl = '0;
                csel = '0;
                cselb = 8'hFF;
                precb = '0;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
                for (int unsigned i = 0; i < 4; i++) begin
                    if (i == col_b) begin
                        bsel[i] = 1'b1;
                        bselb[i] = 1'b0;
                    end else begin
                        bsel[i] = 1'b0;
                        bselb[i] = 1'b1;
                    end
                end
            end else if (exec_cnt_i == 4'd8 || exec_cnt_i == 4'd7 || exec_cnt_i == 4'd6) begin
                csl = '0;
                csel = '0;
                cselb = 8'hFF;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
                for (int unsigned i = 0; i < 256; i++) begin
                    if (input_i[i] == 2'b00) begin
                        dumh[i] = '0;
                        duml[i] = '0;
                    end else if (input_i[i] == 2'b01) begin
                        if (exec_cnt_i == 4'd8) begin
                            dumh[i] = 1'b1;
                            duml[i] = 1'b1;
                        end else begin
                            dumh[i] = '0;
                            duml[i] = '0;
                        end
                    end else if (input_i[i] == 2'b10) begin
                        if (exec_cnt_i == 4'd8 || exec_cnt_i == 4'd7) begin
                            dumh[i] = 1'b1;
                            duml[i] = 1'b1;
                        end else begin
                            dumh[i] = '0;
                            duml[i] = '0;
                        end
                    end else if (input_i[i] == 2'b11) begin
                        dumh[i] = 1'b1;
                        duml[i] = 1'b1;
                    end else begin
                        dumh[i] = '0;
                        duml[i] = '0;
                    end
                end
                for (int unsigned j = 0; j < 4; j++) begin
                    if (j == col_b) begin
                        bsel[j] = 1'b1;
                        bselb[j] = 1'b0;
                    end else begin
                        bsel[j] = 1'b0;
                        bselb[j] = 1'b1;
                    end
                end
            end else if (exec_cnt_i == 4'd5) begin
                dumh = '0;
                duml = '0;
                csl = '0;
                bsel = '0;
                bselb = 4'hF;
                csel = 8'hFF;
                cselb = '0;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
            end else if (exec_cnt_i == 4'd4) begin
                dumh = '0;
                duml = '0;
                csl = '0;
                bsel = '0;
                bselb = 4'hF;
                csel = 8'hFF;
                cselb = '0;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = 1'b1;
                dff = '0;
                qdac = 1'b1;
            end else if (exec_cnt_i == 4'd3) begin
                dumh = '0;
                duml = '0;
                csl = '0;
                bsel = '0;
                bselb = 4'hF;
                csel = 8'hFF;
                cselb = '0;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = 1'b1;
                dff = 1'b1;
                qdac = '0;
            end else if (exec_cnt_i == 4'd2) begin
                dumh = '0;
                duml = '0;
                csl = '0;
                bsel = '0;
                bselb = 4'hF;
                csel = 8'hFF;
                cselb = '0;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = '0;
            end else if (exec_cnt_i == 4'd1 || exec_cnt_i == 4'd0) begin
                dumh = '0;
                duml = '0;
                csl = '0;
                bsel = '0;
                bselb = 4'hF;
                csel = 8'hFF;
                cselb = '0;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = 1'b1;
                dff = '0;
                qdac = '0;
            end else begin
                // eFLASH
                dumh = '0;
                duml = '0;
                csl = '0;
                bsel = '0;
                bselb = 4'b1111;
                csel = '0;
                cselb = 8'hFF;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
            end

            if (exec_cnt_i == 4'd3 || exec_cnt_i == 4'd0) begin
                out_buf_write = 1'b1;   // output buffer write signal
            end else begin
                out_buf_write = 1'b0;
            end

        // Rowbyrow mode
        end else if (rowbyrow_en_i) begin
            // HVS
            mode = 2'b10;
            for (int unsigned i = 0; i < 128; i++) begin
                if (i == row_addr7_i) begin
                    wl_sel[i] = 1'b1;
                    vpass_en[i] = 1'b1;
                end else begin
                    wl_sel[i] = 1'b0;
                    vpass_en[i] = 1'b0;
                end
            end
            // eFLASH
            if (exec_cnt_i == 4'd8 || exec_cnt_i == 4'd7 || exec_cnt_i == 4'd6) begin
                dumh = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                duml = 256'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                csl = '0;
                csel = '0;
                cselb = 8'hFF;
                precb = '0;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
                for (int unsigned i = 0; i < 4; i++) begin
                    if (i == col_b) begin
                        bsel[i] = 1'b1;
                        bselb[i] = 1'b0;
                    end else begin
                        bsel[i] = 1'b0;
                        bselb[i] = 1'b1;
                    end
                end
            end else if (exec_cnt_i == 4'd5 || exec_cnt_i == 4'd4 || exec_cnt_i == 4'd3) begin
                csl = '0;
                csel = '0;
                cselb = 8'hFF;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
                for (int unsigned i = 0; i < 256; i++) begin
                    dumh[i] = 1'b0;
                    duml[i] = 1'b0;
                end

                for (int unsigned i = 0; i < 32; i++) begin
                    if (input_i[i] == 2'b00) begin
                        dumh[8*i + row_c] = '0;
                        duml[8*i + row_c] = '0;
                    end else if (input_i[i] == 2'b01) begin
                        if (exec_cnt_i == 4'd5) begin
                            dumh[8*i + row_c] = 1'b1;
                            duml[8*i + row_c] = 1'b1;
                        end else begin
                            dumh[8*i + row_c] = '0;
                            duml[8*i + row_c] = '0;
                        end
                    end else if (input_i[i] == 2'b10) begin
                        if (exec_cnt_i == 4'd5 || exec_cnt_i == 4'd4) begin
                            dumh[8*i + row_c] = 1'b1;
                            duml[8*i + row_c] = 1'b1;
                        end else begin
                            dumh[8*i + row_c] = '0;
                            duml[8*i + row_c] = '0;
                        end
                    end else if (input_i[i] == 2'b11) begin
                        dumh[8*i + row_c] = 1'b1;
                        duml[8*i + row_c] = 1'b1;
                    end else begin
                        dumh[8*i + row_c] = '0;
                        duml[8*i + row_c] = '0;
                    end
                end
                for (int unsigned j = 0; j < 4; j++) begin
                    if (j == col_b) begin
                        bsel[j] = 1'b1;
                        bselb[j] = 1'b0;
                    end else begin
                        bsel[j] = 1'b0;
                        bselb[j] = 1'b1;
                    end
                end
            end else if (exec_cnt_i == 4'd2) begin
                dumh = '0;
                duml = '0;
                csl = '0;
                bsel = '0;
                bselb = 4'b1111;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
                for (int unsigned i = 0; i < 8; i++) begin
                    if (i == row_c) begin
                        csel[i] = 1'b1;
                        cselb[i] = 1'b0;
                    end else begin
                        csel[i] = 1'b0;
                        cselb[i] = 1'b1;
                    end
                end
            end else if (exec_cnt_i == 4'd1 || exec_cnt_i == 4'd0) begin
                dumh = '0;
                duml = '0;
                csl = '0;
                bsel = '0;
                bselb = 4'b1111;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = 1'b1;
                dff = '0;
                qdac = 1'b1;
                for (int unsigned i = 0; i < 8; i++) begin
                    if (i == row_c) begin
                        csel[i] = 1'b1;
                        cselb[i] = 1'b0;
                    end else begin
                        csel[i] = 1'b0;
                        cselb[i] = 1'b1;
                    end
                end
            end else begin
                // eFLASH
                dumh = '0;
                duml = '0;
                csl = '0;
                bsel = '0;
                bselb = 4'b1111;
                csel = '0;
                cselb = 8'hFF;
                precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
                disc = '0;
                adc_en = '0;
                dff = '0;
                qdac = 1'b1;
            end

            if (exec_cnt_i == 4'd0) begin
                out_buf_write = 1'b1;   // output buffer write signal
            end else begin
                out_buf_write = 1'b0;
            end

        end else begin
            // HVS
            mode = '0;
            wl_sel = '0;
            vpass_en = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
            // eFLASH
            dumh = '0;
            duml = '0;
            csl = '0;
            bsel = '0;
            bselb = 4'b1111;
            csel = '0;
            cselb = 8'hFF;
            precb = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
            disc = '0;
            adc_en = '0;
            dff = '0;
            qdac = 1'b1;
        end
    end

    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // HVS
            MODE_o <= '0;
            WL_SEL_o <= '0;
            VPASS_EN_o <= 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
            // eFLASH
            DUMH_o <= '0;
            DUML_o <= '0;
            CSL_o <= '0;
            BSEL_o <= '0;
            BSELB_o <= 4'b1111;
            CSEL_o <= '0;
            CSELB_o <= 8'hFF;
            PRECB_o <= 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
            DISC_o <= '0;
            ADC_EN_o <= '0;
            DFF_o <= '0;
            QDAC_o <= 1'b1;

            out_buf_write_o <= '0;
        end else begin
            // HVS
            MODE_o <= mode;
            WL_SEL_o <= wl_sel;
            VPASS_EN_o <= vpass_en;
            // eFLASH
            DUMH_o <= dumh;
            DUML_o <= duml;
            CSL_o <= csl;
            BSEL_o <= bsel;
            BSELB_o <= bselb;
            CSEL_o <= csel;
            CSELB_o <= cselb;
            PRECB_o <= precb;
            DISC_o <= disc;
            ADC_EN_o <= adc_en;
            DFF_o <= dff;
            QDAC_o <= qdac;
            
            out_buf_write_o <= out_buf_write;
        end
    end


endmodule