module wb_spiflash (
    input clk,
    input resetn,

    // Wishbone Slave
    input  [63:0] s_wbm_adr_i,
    input  [63:0] s_wbm_dat_i,
    output [63:0] s_wbm_dat_o,
    input         s_wbm_we_i,
    input  [7:0]  s_wbm_sel_i,
    input         s_wbm_stb_i,
    input         s_wbm_cyc_i,
    output reg    s_wbm_ack_o,

    // SPI Flash Interface
    output reg flash_csb,
    output reg flash_clk,
    output reg flash_io0, // MOSI
    input      flash_io1  // MISO
);

    // Simple XIP Controller
    // Only supports Read command (0x03)
    // 64-bit wide read -> Requires 8 bytes -> 64 clocks + cmd/addr overhead.
    // Optimization: Assume sequential bursts? For simplicity, single access.

    reg [5:0] state;
    localparam IDLE = 0;
    localparam CMD  = 1;
    localparam ADDR = 2;
    localparam DATA = 3;
    localparam DONE = 4;

    reg [7:0] cmd_reg;
    reg [23:0] addr_reg;
    reg [63:0] data_reg;
    reg [6:0] bit_cnt;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            flash_csb <= 1;
            flash_clk <= 0;
            s_wbm_ack_o <= 0;
        end else begin
            s_wbm_ack_o <= 0;

            case (state)
                IDLE: begin
                    flash_csb <= 1;
                    if (s_wbm_stb_i && s_wbm_cyc_i && !s_wbm_we_i) begin
                        // Start Read
                        flash_csb <= 0;
                        cmd_reg <= 8'h03;
                        addr_reg <= s_wbm_adr_i[23:0]; // 24-bit address for standard flash
                        state <= CMD;
                        bit_cnt <= 7;
                        flash_clk <= 0;
                    end
                end
                CMD: begin
                    flash_clk <= !flash_clk;
                    if (!flash_clk) begin // Falling edge setup
                        flash_io0 <= cmd_reg[bit_cnt];
                    end else begin // Rising edge
                        if (bit_cnt == 0) begin
                            state <= ADDR;
                            bit_cnt <= 23;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end
                ADDR: begin
                    flash_clk <= !flash_clk;
                    if (!flash_clk) begin
                        flash_io0 <= addr_reg[bit_cnt];
                    end else begin
                        if (bit_cnt == 0) begin
                            state <= DATA;
                            bit_cnt <= 63; // Read 64 bits
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end
                DATA: begin
                    flash_clk <= !flash_clk;
                    if (flash_clk) begin // Rising edge sample
                        data_reg <= {data_reg[62:0], flash_io1};
                        if (bit_cnt == 0) begin
                            state <= DONE;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end
                DONE: begin
                    flash_csb <= 1;
                    s_wbm_ack_o <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

    assign s_wbm_dat_o = data_reg;

endmodule
