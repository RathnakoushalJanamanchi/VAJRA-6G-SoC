module wb_gpio (
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

    // Core IO signals
    input  [7:0] gpio_i,
    output [7:0] gpio_o,
    output [7:0] gpio_oe
);

    reg [7:0] reg_data;
    reg [7:0] reg_dir;

    always @(posedge clk) begin
        if (!resetn) begin
            s_wbm_ack_o <= 0;
            reg_data <= 0;
            reg_dir <= 0;
        end else begin
            s_wbm_ack_o <= s_wbm_stb_i && s_wbm_cyc_i && !s_wbm_ack_o;

            if (s_wbm_stb_i && s_wbm_cyc_i && s_wbm_we_i) begin
                if (s_wbm_adr_i[5:0] == 6'h00)
                    reg_data <= s_wbm_dat_i[7:0];
                else if (s_wbm_adr_i[5:0] == 6'h08)
                    reg_dir <= s_wbm_dat_i[7:0];
            end
        end
    end

    assign gpio_o = reg_data;
    assign gpio_oe = reg_dir;

    assign s_wbm_dat_o = (s_wbm_adr_i[5:0] == 6'h00) ? {56'b0, gpio_i} :
                         (s_wbm_adr_i[5:0] == 6'h08) ? {56'b0, reg_dir} : 64'b0;

endmodule
