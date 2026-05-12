module wb_intercon (
    input clk,
    input resetn,

    // Masters
    // M0: Cache (CPU)
    input  [63:0] m0_wbm_adr_i,
    input  [63:0] m0_wbm_dat_i,
    output [63:0] m0_wbm_dat_o,
    input         m0_wbm_we_i,
    input  [7:0]  m0_wbm_sel_i,
    input         m0_wbm_stb_i,
    input         m0_wbm_cyc_i,
    output        m0_wbm_ack_o,

    // M1: DMA
    input  [63:0] m1_wbm_adr_i,
    input  [63:0] m1_wbm_dat_i,
    output [63:0] m1_wbm_dat_o,
    input         m1_wbm_we_i,
    input  [7:0]  m1_wbm_sel_i,
    input         m1_wbm_stb_i,
    input         m1_wbm_cyc_i,
    output        m1_wbm_ack_o,

    // Slaves
    // S0: Boot ROM / Flash (0x0000....)
    // S1: RAM (0x1000....)
    // S2: Peripherals Base (0x2000....)

    // Sub-decoding for Peripherals:
    // 0x2000_0000: UART
    // 0x2000_1000: DMA Config
    // 0x2000_2000: Kyber
    // 0x2000_3000: GPIO
    // 0x2000_4000: SPI
    // 0x2000_5000: Timer
    // 0x2000_6000: TRNG

    // Output to S0 (Flash)
    output [63:0] s0_wbm_adr_o,
    output [63:0] s0_wbm_dat_o,
    input  [63:0] s0_wbm_dat_i,
    output        s0_wbm_we_o,
    output [7:0]  s0_wbm_sel_o,
    output        s0_wbm_stb_o,
    output        s0_wbm_cyc_o,
    input         s0_wbm_ack_i,

    // Output to S1 (RAM)
    output [63:0] s1_wbm_adr_o,
    output [63:0] s1_wbm_dat_o,
    input  [63:0] s1_wbm_dat_i,
    output        s1_wbm_we_o,
    output [7:0]  s1_wbm_sel_o,
    output        s1_wbm_stb_o,
    output        s1_wbm_cyc_o,
    input         s1_wbm_ack_i,

    // Output to S2 (UART)
    output [63:0] s2_wbm_adr_o,
    output [63:0] s2_wbm_dat_o,
    input  [63:0] s2_wbm_dat_i,
    output        s2_wbm_we_o,
    output [7:0]  s2_wbm_sel_o,
    output        s2_wbm_stb_o,
    output        s2_wbm_cyc_o,
    input         s2_wbm_ack_i,

    // Output to S3 (DMA)
    output [63:0] s3_wbm_adr_o,
    output [63:0] s3_wbm_dat_o,
    input  [63:0] s3_wbm_dat_i,
    output        s3_wbm_we_o,
    output [7:0]  s3_wbm_sel_o,
    output        s3_wbm_stb_o,
    output        s3_wbm_cyc_o,
    input         s3_wbm_ack_i,

    // Output to S4 (Kyber)
    output [63:0] s4_wbm_adr_o,
    output [63:0] s4_wbm_dat_o,
    input  [63:0] s4_wbm_dat_i,
    output        s4_wbm_we_o,
    output [7:0]  s4_wbm_sel_o,
    output        s4_wbm_stb_o,
    output        s4_wbm_cyc_o,
    input         s4_wbm_ack_i,

    // Output to S5 (GPIO)
    output [63:0] s5_wbm_adr_o,
    output [63:0] s5_wbm_dat_o,
    input  [63:0] s5_wbm_dat_i,
    output        s5_wbm_we_o,
    output [7:0]  s5_wbm_sel_o,
    output        s5_wbm_stb_o,
    output        s5_wbm_cyc_o,
    input         s5_wbm_ack_i,

    // Output to S6 (SPI)
    output [63:0] s6_wbm_adr_o,
    output [63:0] s6_wbm_dat_o,
    input  [63:0] s6_wbm_dat_i,
    output        s6_wbm_we_o,
    output [7:0]  s6_wbm_sel_o,
    output        s6_wbm_stb_o,
    output        s6_wbm_cyc_o,
    input         s6_wbm_ack_i,

    // Output to S7 (Timer)
    output [63:0] s7_wbm_adr_o,
    output [63:0] s7_wbm_dat_o,
    input  [63:0] s7_wbm_dat_i,
    output        s7_wbm_we_o,
    output [7:0]  s7_wbm_sel_o,
    output        s7_wbm_stb_o,
    output        s7_wbm_cyc_o,
    input         s7_wbm_ack_i,

    // Output to S8 (TRNG)
    output [63:0] s8_wbm_adr_o,
    output [63:0] s8_wbm_dat_o,
    input  [63:0] s8_wbm_dat_i,
    output        s8_wbm_we_o,
    output [7:0]  s8_wbm_sel_o,
    output        s8_wbm_stb_o,
    output        s8_wbm_cyc_o,
    input         s8_wbm_ack_i
);

    // Simple Arbiter: Priority M1 (DMA) > M0 (CPU)
    wire m_sel = m1_wbm_cyc_i; // If DMA active, select it.

    wire [63:0] adr = m_sel ? m1_wbm_adr_i : m0_wbm_adr_i;
    wire [63:0] dat = m_sel ? m1_wbm_dat_i : m0_wbm_dat_i;
    wire        we  = m_sel ? m1_wbm_we_i  : m0_wbm_we_i;
    wire [7:0]  sel = m_sel ? m1_wbm_sel_i : m0_wbm_sel_i;
    wire        stb = m_sel ? m1_wbm_stb_i : m0_wbm_stb_i;
    wire        cyc = m_sel ? m1_wbm_cyc_i : m0_wbm_cyc_i;

    // Address Decoding
    // 0x0... -> Flash
    // 0x1... -> RAM
    // 0x2000_0... -> UART
    // 0x2000_1... -> DMA
    // 0x2000_2... -> Kyber
    // 0x2000_3... -> GPIO
    // 0x2000_4... -> SPI
    // 0x2000_5... -> Timer
    // 0x2000_6... -> TRNG

    wire is_peri = (adr[31:28] == 4'h2);

    wire s0_sel = (adr[31:28] == 4'h0);
    wire s1_sel = (adr[31:28] == 4'h1);

    wire s2_sel = is_peri && (adr[15:12] == 4'h0);
    wire s3_sel = is_peri && (adr[15:12] == 4'h1);
    wire s4_sel = is_peri && (adr[15:12] == 4'h2);
    wire s5_sel = is_peri && (adr[15:12] == 4'h3);
    wire s6_sel = is_peri && (adr[15:12] == 4'h4);
    wire s7_sel = is_peri && (adr[15:12] == 4'h5);
    wire s8_sel = is_peri && (adr[15:12] == 4'h6);

    // Mux outputs
    assign s0_wbm_adr_o = adr; assign s0_wbm_dat_o = dat; assign s0_wbm_we_o = we; assign s0_wbm_sel_o = sel;
    assign s0_wbm_stb_o = stb && s0_sel; assign s0_wbm_cyc_o = cyc && s0_sel;

    assign s1_wbm_adr_o = adr; assign s1_wbm_dat_o = dat; assign s1_wbm_we_o = we; assign s1_wbm_sel_o = sel;
    assign s1_wbm_stb_o = stb && s1_sel; assign s1_wbm_cyc_o = cyc && s1_sel;

    assign s2_wbm_adr_o = adr; assign s2_wbm_dat_o = dat; assign s2_wbm_we_o = we; assign s2_wbm_sel_o = sel;
    assign s2_wbm_stb_o = stb && s2_sel; assign s2_wbm_cyc_o = cyc && s2_sel;

    assign s3_wbm_adr_o = adr; assign s3_wbm_dat_o = dat; assign s3_wbm_we_o = we; assign s3_wbm_sel_o = sel;
    assign s3_wbm_stb_o = stb && s3_sel; assign s3_wbm_cyc_o = cyc && s3_sel;

    assign s4_wbm_adr_o = adr; assign s4_wbm_dat_o = dat; assign s4_wbm_we_o = we; assign s4_wbm_sel_o = sel;
    assign s4_wbm_stb_o = stb && s4_sel; assign s4_wbm_cyc_o = cyc && s4_sel;

    assign s5_wbm_adr_o = adr; assign s5_wbm_dat_o = dat; assign s5_wbm_we_o = we; assign s5_wbm_sel_o = sel;
    assign s5_wbm_stb_o = stb && s5_sel; assign s5_wbm_cyc_o = cyc && s5_sel;

    assign s6_wbm_adr_o = adr; assign s6_wbm_dat_o = dat; assign s6_wbm_we_o = we; assign s6_wbm_sel_o = sel;
    assign s6_wbm_stb_o = stb && s6_sel; assign s6_wbm_cyc_o = cyc && s6_sel;

    assign s7_wbm_adr_o = adr; assign s7_wbm_dat_o = dat; assign s7_wbm_we_o = we; assign s7_wbm_sel_o = sel;
    assign s7_wbm_stb_o = stb && s7_sel; assign s7_wbm_cyc_o = cyc && s7_sel;

    assign s8_wbm_adr_o = adr; assign s8_wbm_dat_o = dat; assign s8_wbm_we_o = we; assign s8_wbm_sel_o = sel;
    assign s8_wbm_stb_o = stb && s8_sel; assign s8_wbm_cyc_o = cyc && s8_sel;

    // Mux inputs (ack/dat)
    wire [63:0] ack_dat = s0_sel ? s0_wbm_dat_i :
                          s1_sel ? s1_wbm_dat_i :
                          s2_sel ? s2_wbm_dat_i :
                          s3_sel ? s3_wbm_dat_i :
                          s4_sel ? s4_wbm_dat_i :
                          s5_sel ? s5_wbm_dat_i :
                          s6_sel ? s6_wbm_dat_i :
                          s7_sel ? s7_wbm_dat_i :
                          s8_sel ? s8_wbm_dat_i : 64'b0;

    wire        ack     = s0_sel ? s0_wbm_ack_i :
                          s1_sel ? s1_wbm_ack_i :
                          s2_sel ? s2_wbm_ack_i :
                          s3_sel ? s3_wbm_ack_i :
                          s4_sel ? s4_wbm_ack_i :
                          s5_sel ? s5_wbm_ack_i :
                          s6_sel ? s6_wbm_ack_i :
                          s7_sel ? s7_wbm_ack_i :
                          s8_sel ? s8_wbm_ack_i : 1'b0;

    assign m0_wbm_dat_o = ack_dat;
    assign m0_wbm_ack_o = ack && !m_sel;

    assign m1_wbm_dat_o = ack_dat;
    assign m1_wbm_ack_o = ack && m_sel;

endmodule
