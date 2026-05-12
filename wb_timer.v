module wb_timer (
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

    output irq
);

    // Registers
    // 0x00: mtime
    // 0x08: mtimecmp

    reg [63:0] mtime;
    reg [63:0] mtimecmp;

    always @(posedge clk) begin
        if (!resetn) begin
            mtime <= 0;
            mtimecmp <= -1; // Max value to avoid immediate irq
            s_wbm_ack_o <= 0;
        end else begin
            mtime <= mtime + 1;

            s_wbm_ack_o <= s_wbm_stb_i && s_wbm_cyc_i && !s_wbm_ack_o;

            if (s_wbm_stb_i && s_wbm_cyc_i && s_wbm_we_i) begin
                if (s_wbm_adr_i[5:0] == 6'h00)
                    mtime <= s_wbm_dat_i;
                else if (s_wbm_adr_i[5:0] == 6'h08)
                    mtimecmp <= s_wbm_dat_i;
            end
        end
    end

    assign s_wbm_dat_o = (s_wbm_adr_i[5:0] == 6'h00) ? mtime :
                         (s_wbm_adr_i[5:0] == 6'h08) ? mtimecmp : 64'b0;

    assign irq = (mtime >= mtimecmp);

endmodule
