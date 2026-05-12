module wb_trng (
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
    output reg    s_wbm_ack_o
);

    reg [63:0] lfsr;
    reg [63:0] shift_reg;
    reg [5:0]  count;

    wire sample_bit;

    assign sample_bit = lfsr[0];
    wire _unused_trng = |{s_wbm_adr_i, s_wbm_dat_i, s_wbm_we_i, s_wbm_sel_i};
    always @(posedge clk) begin
        if (!resetn) begin
            shift_reg <= 64'b0;
            lfsr <= 64'hACE1_1234_DEAD_BEEF;
            count <= 0;
 	
        end else begin
            // Continuously shift in entropy
            lfsr <= {lfsr[62:0],
            lfsr[63] ^ lfsr[61] ^ lfsr[60] ^ lfsr[58]};
            shift_reg <= lfsr;
            


            s_wbm_ack_o <= s_wbm_stb_i && s_wbm_cyc_i && !s_wbm_ack_o;
        end

    end

    assign s_wbm_dat_o = shift_reg;

endmodule
