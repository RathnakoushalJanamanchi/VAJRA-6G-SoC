module vajra_6g_core (
    input clk,
    input resetn,

    // External Memory Interface (RAM)
    output [63:0] ram_wbm_adr_o,
    output [63:0] ram_wbm_dat_o,
    input  [63:0] ram_wbm_dat_i,
    output        ram_wbm_we_o,
    output [7:0]  ram_wbm_sel_o,
    output        ram_wbm_stb_o,
    input         ram_wbm_ack_i,
    output        ram_wbm_cyc_o,

    // SPI Flash Interface (Boot)
    output flash_csb,
    output flash_clk,
    output flash_io0,
    input  flash_io1,

    // UART
    output serial_tx,
    input  serial_rx,

    // GPIO
    input  [7:0] gpio_i,
    output [7:0] gpio_o,
    output [7:0] gpio_oe,

    // SPI
    output spi_sclk,
    output spi_mosi,
    input  spi_miso,
    output spi_cs_n,

    // External IRQ lines
    input [31:0] ext_irq,
    output [31:0] eoi,

    // Trace
    output trace_valid,
    output [35:0] trace_data
);

    // Internal Wires

    // CPU <-> Cache
    wire        cpu_mem_valid;
    wire        cpu_mem_instr;
    wire        cpu_mem_ready;
    wire [63:0] cpu_mem_addr;
    wire [63:0] cpu_mem_wdata;
    wire [7:0]  cpu_mem_wstrb;
    wire [63:0] cpu_mem_rdata;

    // Cache <-> Interconnect (M0)
    wire [63:0] m0_wbm_adr;
    wire [63:0] m0_wbm_dat_o;
    wire [63:0] m0_wbm_dat_i;
    wire        m0_wbm_we;
    wire [7:0]  m0_wbm_sel;
    wire        m0_wbm_stb;
    wire        m0_wbm_cyc;
    wire        m0_wbm_ack;

    // DMA <-> Interconnect (M1)
    wire [63:0] m1_wbm_adr;
    wire [63:0] m1_wbm_dat_o;
    wire [63:0] m1_wbm_dat_i;
    wire        m1_wbm_we;
    wire [7:0]  m1_wbm_sel;
    wire        m1_wbm_stb;
    wire        m1_wbm_cyc;
    wire        m1_wbm_ack;

    // Interconnect <-> Flash (S0)
    wire [63:0] s0_wbm_adr;
    wire [63:0] s0_wbm_dat_o;
    wire [63:0] s0_wbm_dat_i;
    wire        s0_wbm_we;
    wire [7:0]  s0_wbm_sel;
    wire        s0_wbm_stb;
    wire        s0_wbm_cyc;
    wire        s0_wbm_ack;

    // Interconnect <-> UART (S2)
    wire [63:0] s2_wbm_adr;
    wire [63:0] s2_wbm_dat_o;
    wire [63:0] s2_wbm_dat_i;
    wire        s2_wbm_we;
    wire [7:0]  s2_wbm_sel;
    wire        s2_wbm_stb;
    wire        s2_wbm_cyc;
    wire        s2_wbm_ack;

    // Interconnect <-> DMA Config (S3)
    wire [63:0] s3_wbm_adr;
    wire [63:0] s3_wbm_dat_o;
    wire [63:0] s3_wbm_dat_i;
    wire        s3_wbm_we;
    wire [7:0]  s3_wbm_sel;
    wire        s3_wbm_stb;
    wire        s3_wbm_cyc;
    wire        s3_wbm_ack;

    // Interconnect <-> Kyber (S4)
    wire [63:0] s4_wbm_adr;
    wire [63:0] s4_wbm_dat_o;
    wire [63:0] s4_wbm_dat_i;
    wire        s4_wbm_we;
    wire [7:0]  s4_wbm_sel;
    wire        s4_wbm_stb;
    wire        s4_wbm_cyc;
    wire        s4_wbm_ack;

    // Interconnect <-> GPIO (S5)
    wire [63:0] s5_wbm_adr;
    wire [63:0] s5_wbm_dat_o;
    wire [63:0] s5_wbm_dat_i;
    wire        s5_wbm_we;
    wire [7:0]  s5_wbm_sel;
    wire        s5_wbm_stb;
    wire        s5_wbm_cyc;
    wire        s5_wbm_ack;

    // Interconnect <-> SPI (S6)
    wire [63:0] s6_wbm_adr;
    wire [63:0] s6_wbm_dat_o;
    wire [63:0] s6_wbm_dat_i;
    wire        s6_wbm_we;
    wire [7:0]  s6_wbm_sel;
    wire        s6_wbm_stb;
    wire        s6_wbm_cyc;
    wire        s6_wbm_ack;

    // Interconnect <-> Timer (S7)
    wire [63:0] s7_wbm_adr;
    wire [63:0] s7_wbm_dat_o;
    wire [63:0] s7_wbm_dat_i;
    wire        s7_wbm_we;
    wire [7:0]  s7_wbm_sel;
    wire        s7_wbm_stb;
    wire        s7_wbm_cyc;
    wire        s7_wbm_ack;

    // Interconnect <-> TRNG (S8)
    wire [63:0] s8_wbm_adr;
    wire [63:0] s8_wbm_dat_o;
    wire [63:0] s8_wbm_dat_i;
    wire        s8_wbm_we;
    wire [7:0]  s8_wbm_sel;
    wire        s8_wbm_stb;
    wire        s8_wbm_cyc;
    wire        s8_wbm_ack;

    // IRQs
    wire irq_dma;
    wire irq_kyber;
    wire irq_timer;
    wire [31:0] irq_vector = {ext_irq[31:3], irq_timer, irq_dma, irq_kyber}; // Bit 0: Kyber, 1: DMA, 2: Timer

    // Instantiate Core
    picorv64_vajra #(
        .ENABLE_PCPI(0),
        .ENABLE_IRQ(1),
        .ENABLE_COUNTERS(1),
        .PROGADDR_RESET(64'h00000000), // Boot from Flash
        .STACKADDR(64'h10008000)
    ) cpu (
        .clk(clk),
        .resetn(resetn),
        .mem_valid(cpu_mem_valid),
        .mem_instr(cpu_mem_instr),
        .mem_ready(cpu_mem_ready),
        .mem_addr(cpu_mem_addr),
        .mem_wdata(cpu_mem_wdata),
        .mem_wstrb(cpu_mem_wstrb),
        .mem_rdata(cpu_mem_rdata),
        .irq(irq_vector),
        .eoi(eoi),
        .pcpi_valid(),
        .pcpi_insn(),
        .pcpi_rs1(),
        .pcpi_rs2(),
        .pcpi_wr(1'b0),
        .pcpi_rd(64'b0),
        .pcpi_wait(1'b0),
        .pcpi_ready(1'b0),
        .trace_valid(trace_valid),
        .trace_data(trace_data)
    );

    // Cache
    wb_cache cache (
        .clk(clk),
        .resetn(resetn),
        .cpu_mem_valid(cpu_mem_valid),
        .cpu_mem_instr(cpu_mem_instr),
        .cpu_mem_ready(cpu_mem_ready),
        .cpu_mem_addr(cpu_mem_addr),
        .cpu_mem_wdata(cpu_mem_wdata),
        .cpu_mem_wstrb(cpu_mem_wstrb),
        .cpu_mem_rdata(cpu_mem_rdata),
        .wbm_adr_o(m0_wbm_adr),
        .wbm_dat_o(m0_wbm_dat_o),
        .wbm_dat_i(m0_wbm_dat_i),
        .wbm_we_o(m0_wbm_we),
        .wbm_sel_o(m0_wbm_sel),
        .wbm_stb_o(m0_wbm_stb),
        .wbm_ack_i(m0_wbm_ack),
        .wbm_cyc_o(m0_wbm_cyc)
    );

    // Interconnect
    wb_intercon intercon (
        .clk(clk),
        .resetn(resetn),
        .m0_wbm_adr_i(m0_wbm_adr), .m0_wbm_dat_i(m0_wbm_dat_o), .m0_wbm_dat_o(m0_wbm_dat_i),
        .m0_wbm_we_i(m0_wbm_we), .m0_wbm_sel_i(m0_wbm_sel), .m0_wbm_stb_i(m0_wbm_stb), .m0_wbm_cyc_i(m0_wbm_cyc), .m0_wbm_ack_o(m0_wbm_ack),

        .m1_wbm_adr_i(m1_wbm_adr), .m1_wbm_dat_i(m1_wbm_dat_o), .m1_wbm_dat_o(m1_wbm_dat_i),
        .m1_wbm_we_i(m1_wbm_we), .m1_wbm_sel_i(m1_wbm_sel), .m1_wbm_stb_i(m1_wbm_stb), .m1_wbm_cyc_i(m1_wbm_cyc), .m1_wbm_ack_o(m1_wbm_ack),

        // Flash (S0)
        .s0_wbm_adr_o(s0_wbm_adr), .s0_wbm_dat_o(s0_wbm_dat_o), .s0_wbm_dat_i(s0_wbm_dat_i),
        .s0_wbm_we_o(s0_wbm_we), .s0_wbm_sel_o(s0_wbm_sel), .s0_wbm_stb_o(s0_wbm_stb), .s0_wbm_cyc_o(s0_wbm_cyc), .s0_wbm_ack_i(s0_wbm_ack),

        // RAM (S1)
        .s1_wbm_adr_o(ram_wbm_adr_o), .s1_wbm_dat_o(ram_wbm_dat_o), .s1_wbm_dat_i(ram_wbm_dat_i),
        .s1_wbm_we_o(ram_wbm_we_o), .s1_wbm_sel_o(ram_wbm_sel_o), .s1_wbm_stb_o(ram_wbm_stb_o), .s1_wbm_cyc_o(ram_wbm_cyc_o), .s1_wbm_ack_i(ram_wbm_ack_i),

        // UART (S2)
        .s2_wbm_adr_o(s2_wbm_adr), .s2_wbm_dat_o(s2_wbm_dat_o), .s2_wbm_dat_i(s2_wbm_dat_i),
        .s2_wbm_we_o(s2_wbm_we), .s2_wbm_sel_o(s2_wbm_sel), .s2_wbm_stb_o(s2_wbm_stb), .s2_wbm_cyc_o(s2_wbm_cyc), .s2_wbm_ack_i(s2_wbm_ack),

        // DMA Config (S3)
        .s3_wbm_adr_o(s3_wbm_adr), .s3_wbm_dat_o(s3_wbm_dat_o), .s3_wbm_dat_i(s3_wbm_dat_i),
        .s3_wbm_we_o(s3_wbm_we), .s3_wbm_sel_o(s3_wbm_sel), .s3_wbm_stb_o(s3_wbm_stb), .s3_wbm_cyc_o(s3_wbm_cyc), .s3_wbm_ack_i(s3_wbm_ack),

        // Kyber (S4)
        .s4_wbm_adr_o(s4_wbm_adr), .s4_wbm_dat_o(s4_wbm_dat_o), .s4_wbm_dat_i(s4_wbm_dat_i),
        .s4_wbm_we_o(s4_wbm_we), .s4_wbm_sel_o(s4_wbm_sel), .s4_wbm_stb_o(s4_wbm_stb), .s4_wbm_cyc_o(s4_wbm_cyc), .s4_wbm_ack_i(s4_wbm_ack),

        // GPIO (S5)
        .s5_wbm_adr_o(s5_wbm_adr), .s5_wbm_dat_o(s5_wbm_dat_o), .s5_wbm_dat_i(s5_wbm_dat_i),
        .s5_wbm_we_o(s5_wbm_we), .s5_wbm_sel_o(s5_wbm_sel), .s5_wbm_stb_o(s5_wbm_stb), .s5_wbm_cyc_o(s5_wbm_cyc), .s5_wbm_ack_i(s5_wbm_ack),

        // SPI (S6)
        .s6_wbm_adr_o(s6_wbm_adr), .s6_wbm_dat_o(s6_wbm_dat_o), .s6_wbm_dat_i(s6_wbm_dat_i),
        .s6_wbm_we_o(s6_wbm_we), .s6_wbm_sel_o(s6_wbm_sel), .s6_wbm_stb_o(s6_wbm_stb), .s6_wbm_cyc_o(s6_wbm_cyc), .s6_wbm_ack_i(s6_wbm_ack),

        // Timer (S7)
        .s7_wbm_adr_o(s7_wbm_adr), .s7_wbm_dat_o(s7_wbm_dat_o), .s7_wbm_dat_i(s7_wbm_dat_i),
        .s7_wbm_we_o(s7_wbm_we), .s7_wbm_sel_o(s7_wbm_sel), .s7_wbm_stb_o(s7_wbm_stb), .s7_wbm_cyc_o(s7_wbm_cyc), .s7_wbm_ack_i(s7_wbm_ack),

        // TRNG (S8)
        .s8_wbm_adr_o(s8_wbm_adr), .s8_wbm_dat_o(s8_wbm_dat_o), .s8_wbm_dat_i(s8_wbm_dat_i),
        .s8_wbm_we_o(s8_wbm_we), .s8_wbm_sel_o(s8_wbm_sel), .s8_wbm_stb_o(s8_wbm_stb), .s8_wbm_cyc_o(s8_wbm_cyc), .s8_wbm_ack_i(s8_wbm_ack)
    );

    // DMA
    wb_dma dma (
        .clk(clk),
        .resetn(resetn),
        .s_wbm_adr_i(s3_wbm_adr), .s_wbm_dat_i(s3_wbm_dat_o), .s_wbm_dat_o(s3_wbm_dat_i),
        .s_wbm_we_i(s3_wbm_we), .s_wbm_sel_i(s3_wbm_sel), .s_wbm_stb_i(s3_wbm_stb), .s_wbm_cyc_i(s3_wbm_cyc), .s_wbm_ack_o(s3_wbm_ack),
        .m_wbm_adr_o(m1_wbm_adr), .m_wbm_dat_o(m1_wbm_dat_o), .m_wbm_dat_i(m1_wbm_dat_i),
        .m_wbm_we_o(m1_wbm_we), .m_wbm_sel_o(m1_wbm_sel), .m_wbm_stb_o(m1_wbm_stb), .m_wbm_ack_i(m1_wbm_ack), .m_wbm_cyc_o(m1_wbm_cyc),
        .irq(irq_dma)
    );

    // UART
    simpleuart uart (
        .clk(clk),
        .resetn(resetn),
        .s_wbm_adr_i(s2_wbm_adr), .s_wbm_dat_i(s2_wbm_dat_o), .s_wbm_dat_o(s2_wbm_dat_i),
        .s_wbm_we_i(s2_wbm_we), .s_wbm_sel_i(s2_wbm_sel), .s_wbm_stb_i(s2_wbm_stb), .s_wbm_cyc_i(s2_wbm_cyc), .s_wbm_ack_o(s2_wbm_ack),
        .serial_tx(serial_tx), .serial_rx(serial_rx)
    );

    // Kyber Wrapper
    wb_kyber kyber (
        .clk(clk),
        .resetn(resetn),
        .s_wbm_adr_i(s4_wbm_adr), .s_wbm_dat_i(s4_wbm_dat_o), .s_wbm_dat_o(s4_wbm_dat_i),
        .s_wbm_we_i(s4_wbm_we), .s_wbm_sel_i(s4_wbm_sel), .s_wbm_stb_i(s4_wbm_stb), .s_wbm_cyc_i(s4_wbm_cyc), .s_wbm_ack_o(s4_wbm_ack),
        .irq(irq_kyber)
    );

    // GPIO
    wb_gpio gpio (
        .clk(clk),
        .resetn(resetn),
        .s_wbm_adr_i(s5_wbm_adr), .s_wbm_dat_i(s5_wbm_dat_o), .s_wbm_dat_o(s5_wbm_dat_i),
        .s_wbm_we_i(s5_wbm_we), .s_wbm_sel_i(s5_wbm_sel), .s_wbm_stb_i(s5_wbm_stb), .s_wbm_cyc_i(s5_wbm_cyc), .s_wbm_ack_o(s5_wbm_ack),
        .gpio_i(gpio_i), .gpio_o(gpio_o), .gpio_oe(gpio_oe)
    );

    // SPI
    wb_spi spi (
        .clk(clk),
        .resetn(resetn),
        .s_wbm_adr_i(s6_wbm_adr), .s_wbm_dat_i(s6_wbm_dat_o), .s_wbm_dat_o(s6_wbm_dat_i),
        .s_wbm_we_i(s6_wbm_we), .s_wbm_sel_i(s6_wbm_sel), .s_wbm_stb_i(s6_wbm_stb), .s_wbm_cyc_i(s6_wbm_cyc), .s_wbm_ack_o(s6_wbm_ack),
        .spi_sclk(spi_sclk), .spi_mosi(spi_mosi), .spi_miso(spi_miso), .spi_cs_n(spi_cs_n)
    );

    // Timer
    wb_timer timer (
        .clk(clk),
        .resetn(resetn),
        .s_wbm_adr_i(s7_wbm_adr), .s_wbm_dat_i(s7_wbm_dat_o), .s_wbm_dat_o(s7_wbm_dat_i),
        .s_wbm_we_i(s7_wbm_we), .s_wbm_sel_i(s7_wbm_sel), .s_wbm_stb_i(s7_wbm_stb), .s_wbm_cyc_i(s7_wbm_cyc), .s_wbm_ack_o(s7_wbm_ack),
        .irq(irq_timer)
    );

    // TRNG
    wb_trng trng (
        .clk(clk),
        .resetn(resetn),
        .s_wbm_adr_i(s8_wbm_adr), .s_wbm_dat_i(s8_wbm_dat_o), .s_wbm_dat_o(s8_wbm_dat_i),
        .s_wbm_we_i(s8_wbm_we), .s_wbm_sel_i(s8_wbm_sel), .s_wbm_stb_i(s8_wbm_stb), .s_wbm_cyc_i(s8_wbm_cyc), .s_wbm_ack_o(s8_wbm_ack)
    );

    // SPI Flash Controller
    wb_spiflash flash (
        .clk(clk),
        .resetn(resetn),
        .s_wbm_adr_i(s0_wbm_adr), .s_wbm_dat_i(s0_wbm_dat_o), .s_wbm_dat_o(s0_wbm_dat_i),
        .s_wbm_we_i(s0_wbm_we), .s_wbm_sel_i(s0_wbm_sel), .s_wbm_stb_i(s0_wbm_stb), .s_wbm_cyc_i(s0_wbm_cyc), .s_wbm_ack_o(s0_wbm_ack),
        .flash_csb(flash_csb), .flash_clk(flash_clk), .flash_io0(flash_io0), .flash_io1(flash_io1)
    );

endmodule
