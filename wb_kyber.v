module wb_kyber (
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

    output irq
);
    // Wrapper around PCPI core, converting to Memory Mapped
    // Registers:
    // 0x00: INSN (Command)
    // 0x08: RS1
    // 0x10: RS2
    // 0x18: RD (Result)
    // 0x20: Status (Bit 0: Done) - Cleared on Read? Or Write to command.

    reg [31:0] reg_insn;
    reg [63:0] reg_rs1;
    reg [63:0] reg_rs2;
    wire [63:0] core_rd;

    reg start_core;
    wire done_core;
    wire core_ready;

    // Instantiate pcpi_kyber
    // Modify pcpi_kyber interface usage.
    // pcpi_valid -> start_core
    // pcpi_ready -> done_core (Wait, pcpi_ready is high when done)

    pcpi_kyber core (
        .clk(clk),
        .resetn(resetn),
        .pcpi_valid(start_core),
        .pcpi_insn(reg_insn),
        .pcpi_rs1(reg_rs1),
        .pcpi_rs2(reg_rs2),
        .pcpi_wr(), // Unused, we use ready
        .pcpi_rd(core_rd),
        .pcpi_wait(), // Unused
        .pcpi_ready(core_ready)
    );

    reg busy;
    reg [63:0] res_buf;

    always @(posedge clk) begin
        if (!resetn) begin
            s_wbm_ack_o <= 0;
            start_core <= 0;
            busy <= 0;
        end else begin
            s_wbm_ack_o <= s_wbm_stb_i && s_wbm_cyc_i && !s_wbm_ack_o;
            start_core <= 0;

            if (s_wbm_stb_i && s_wbm_cyc_i && s_wbm_we_i) begin
                case (s_wbm_adr_i[5:0])
                    6'h00: begin reg_insn <= s_wbm_dat_i[31:0]; start_core <= 1; busy <= 1; end
                    6'h08: reg_rs1 <= s_wbm_dat_i;
                    6'h10: reg_rs2 <= s_wbm_dat_i;
                endcase
            end

            if (core_ready && busy) begin
                res_buf <= core_rd;
                busy <= 0;
            end
        end
    end

    assign s_wbm_dat_o = (s_wbm_adr_i[5:0] == 6'h18) ? res_buf :
                         (s_wbm_adr_i[5:0] == 6'h20) ? {63'b0, !busy} : 64'b0;

    assign irq = !busy; // Simple IRQ when ready (level). Ideally should be edge or cleared.
    // For "Fire and Forget", the CPU checks status or gets IRQ.

endmodule
