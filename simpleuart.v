module simpleuart (
    input clk,
    input resetn,

    input  [63:0] s_wbm_adr_i,
    input  [63:0] s_wbm_dat_i,
    output [63:0] s_wbm_dat_o,
    input         s_wbm_we_i,
    input  [7:0]  s_wbm_sel_i,
    input         s_wbm_stb_i,
    input         s_wbm_cyc_i,
    output reg    s_wbm_ack_o,

    output reg serial_tx,
    input      serial_rx
);
    // 0x00: Data Register
    // 0x08: Status Register (Bit 0: TX Ready)
    // 0x10: Divisor Register

    parameter DEFAULT_DIV = 100; // For simulation

    reg [31:0] divisor;
    reg [31:0] div_cnt;
    reg [9:0] shift_reg;
    reg [3:0] bit_cnt;

    wire tx_busy = (bit_cnt != 0);

    always @(posedge clk) begin
        if (!resetn) begin
            s_wbm_ack_o <= 0;
            serial_tx <= 1;
            divisor <= DEFAULT_DIV;
            div_cnt <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
        end else begin
            s_wbm_ack_o <= s_wbm_stb_i && s_wbm_cyc_i && !s_wbm_ack_o;

            // Write Logic
            if (s_wbm_stb_i && s_wbm_cyc_i && s_wbm_we_i) begin
                if (s_wbm_adr_i[5:0] == 6'h00 && !tx_busy) begin
                    shift_reg <= {1'b1, s_wbm_dat_i[7:0], 1'b0}; // Stop, Data, Start
                    bit_cnt <= 10;
                    div_cnt <= divisor;
                end
                if (s_wbm_adr_i[5:0] == 6'h10) begin
                    divisor <= s_wbm_dat_i[31:0];
                end
            end

            // TX Logic
            if (tx_busy) begin
                if (div_cnt == 0) begin
                    div_cnt <= divisor;
                    serial_tx <= shift_reg[0];
                    shift_reg <= {1'b1, shift_reg[9:1]};
                    bit_cnt <= bit_cnt - 1;
                end else begin
                    div_cnt <= div_cnt - 1;
                end
            end else begin
                serial_tx <= 1;
            end
        end
    end

    assign s_wbm_dat_o = (s_wbm_adr_i[5:0] == 6'h08) ? {63'b0, !tx_busy} : 64'b0;

endmodule
