module wb_spi (
    input clk,
    input resetn,

    // Wishbone Slave Interface
    input  [63:0] s_wbm_adr_i,
    input  [63:0] s_wbm_dat_i,
    output [63:0] s_wbm_dat_o,
    input         s_wbm_we_i,
    input  [7:0]  s_wbm_sel_i,
    input         s_wbm_stb_i,
    input         s_wbm_cyc_i,
    output reg    s_wbm_ack_o,

    // External SPI Pins
    output reg spi_sclk,
    output reg spi_mosi,
    input      spi_miso,
    output reg spi_cs_n
);

    // Registers
    // 0x00: Data (Write to TX, Read from RX)
    // 0x08: Status (Bit 0: Busy)
    // 0x10: Control (Bit 0: Start, Bit 1: CS active low control)

    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg busy;
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;

    // Clock divider for SPI SCLK (Assume clk is fast, SPI needs to be slower)
    // Simple toggle for now.
    reg [3:0] clk_div;

    always @(posedge clk) begin
        if (!resetn) begin
            s_wbm_ack_o <= 0;
            spi_sclk <= 0;
            spi_mosi <= 0;
            spi_cs_n <= 1;
            busy <= 0;
            tx_data <= 0;
            bit_cnt <= 0;
            clk_div <= 0;
        end else begin
            s_wbm_ack_o <= s_wbm_stb_i && s_wbm_cyc_i && !s_wbm_ack_o;

            if (s_wbm_stb_i && s_wbm_cyc_i && s_wbm_we_i) begin
                if (s_wbm_adr_i[5:0] == 6'h00 && !busy) begin
                    tx_data <= s_wbm_dat_i[7:0];
                    shift_reg <= s_wbm_dat_i[7:0];
                    busy <= 1;
                    bit_cnt <= 8;
                    spi_cs_n <= 0; // Auto-assert CS
                end
                if (s_wbm_adr_i[5:0] == 6'h10) begin
                    // Manual CS control if needed, but simplistic here.
                end
            end

            if (busy) begin
                clk_div <= clk_div + 1;
                if (clk_div == 4'h8) begin // SCLK Rising Edge
                    spi_sclk <= 1;
                    rx_data <= {rx_data[6:0], spi_miso}; // Sample MISO
                end else if (clk_div == 4'hF) begin // SCLK Falling Edge (Next Bit)
                    spi_sclk <= 0;
                    spi_mosi <= shift_reg[7];
                    shift_reg <= {shift_reg[6:0], 1'b0};
                    bit_cnt <= bit_cnt - 1;
                    if (bit_cnt == 1) begin // Done
                        busy <= 0;
                        spi_cs_n <= 1; // Auto-deassert CS
                    end
                end
            end else begin
                spi_sclk <= 0;
            end
        end
    end

    assign s_wbm_dat_o = (s_wbm_adr_i[5:0] == 6'h00) ? {56'b0, rx_data} :
                         (s_wbm_adr_i[5:0] == 6'h08) ? {63'b0, busy} : 64'b0;

endmodule
