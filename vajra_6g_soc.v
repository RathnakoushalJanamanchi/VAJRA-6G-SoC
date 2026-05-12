module vajra_6g_soc (
    // All Physical Pads must be inout because the Pad Cell is bidirectional.
    // Direction is set by the OE_N signal inside the instantiation.
    
    inout clk,          // Configured as INPUT via OE_N=1
    inout resetn,       // Configured as INPUT via OE_N=1

    // SPI Flash
    inout flash_csb,    // Configured as OUTPUT via OE_N=0
    inout flash_clk,    // Configured as OUTPUT via OE_N=0
    inout flash_io0,    // Configured as OUTPUT via OE_N=0
    inout flash_io1,    // Configured as INPUT via OE_N=1

    // UART
    inout serial_tx,    // Configured as OUTPUT via OE_N=0
    inout serial_rx,    // Configured as INPUT via OE_N=1

    // GPIO (Already inout, stays inout)
    inout [7:0] gpio_pins,

    // SPI
    inout spi_sclk,     // Configured as OUTPUT via OE_N=0
    inout spi_mosi,     // Configured as OUTPUT via OE_N=0
    inout spi_miso,     // Configured as INPUT via OE_N=1
    inout spi_cs_n,     // Configured as OUTPUT via OE_N=0

    // External IRQ
    input [31:0] ext_irq, // These are logical signals, not pads? 
                          // If these go to pads, change to inout. 
                          // Keeping as input assuming they are internal test signals or we treat them as logical only for now.
    output [31:0] eoi,

    // Trace
    output trace_valid,
    output [35:0] trace_data
);

    // -------------------------------------------------------------------------
    // 1. WIRES
    // -------------------------------------------------------------------------
    wire clk_core;
    wire resetn_core;

    wire uart_tx_core, uart_rx_core;
    wire flash_csb_core, flash_clk_core, flash_io0_core, flash_io1_core;
    wire spi_sclk_core, spi_mosi_core, spi_miso_core, spi_cs_n_core;

    wire [7:0] gpio_i, gpio_o, gpio_oe;

    // Internal RAM Wires
    wire [63:0] ram_wbm_adr;
    wire [63:0] ram_wbm_dat_core_to_ram;
    wire [63:0] ram_wbm_dat_ram_to_core;
    wire        ram_wbm_we;
    wire [7:0]  ram_wbm_sel;
    wire        ram_wbm_stb;
    wire        ram_wbm_cyc;
    wire        ram_wbm_ack;

    // -------------------------------------------------------------------------
    // 2. PAD INSTANTIATIONS (Using sky130_fd_io__top_gpiov2)
    // -------------------------------------------------------------------------

    // --- INPUT PADS (OE_N = 1, INP_DIS = 0) ---
    sky130_fd_io__top_gpiov2 pad_clk (
        .PAD(clk), .IN(clk_core), .OUT(1'b0), .OE_N(1'b1), .HLD_H_N(1'b1), 
        .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
        .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b0), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
        .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), 
        .ANALOG_POL(1'b0), .DM(3'b001)
    );

    sky130_fd_io__top_gpiov2 pad_reset (
        .PAD(resetn), .IN(resetn_core), .OUT(1'b0), .OE_N(1'b1), .HLD_H_N(1'b1), 
        .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
        .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b0), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
        .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), 
        .ANALOG_POL(1'b0), .DM(3'b001)
    );
    
    sky130_fd_io__top_gpiov2 pad_uart_rx (
        .PAD(serial_rx), .IN(uart_rx_core), .OUT(1'b0), .OE_N(1'b1), .HLD_H_N(1'b1), 
        .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
        .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b0), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
        .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), 
        .ANALOG_POL(1'b0), .DM(3'b001)
    );

    sky130_fd_io__top_gpiov2 pad_spi_miso (
        .PAD(spi_miso), .IN(spi_miso_core), .OUT(1'b0), .OE_N(1'b1), .HLD_H_N(1'b1), 
        .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
        .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b0), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
        .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), 
        .ANALOG_POL(1'b0), .DM(3'b001)
    );

    sky130_fd_io__top_gpiov2 pad_flash_miso (
        .PAD(flash_io1), .IN(flash_io1_core), .OUT(1'b0), .OE_N(1'b1), .HLD_H_N(1'b1), 
        .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
        .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b0), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
        .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), 
        .ANALOG_POL(1'b0), .DM(3'b001)
    );


    // --- OUTPUT PADS (OE_N = 0) ---
    // Note: Re-using generic config, tying OE_N Low for output
    
    sky130_fd_io__top_gpiov2 pad_uart_tx ( .PAD(serial_tx), .OUT(uart_tx_core), .OE_N(1'b0), .IN(), 
        .HLD_H_N(1'b1), .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
        .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b1), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
        .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), .ANALOG_POL(1'b0), .DM(3'b110));

    sky130_fd_io__top_gpiov2 pad_spi_sclk ( .PAD(spi_sclk), .OUT(spi_sclk_core), .OE_N(1'b0), .IN(), 
        .HLD_H_N(1'b1), .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
        .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b1), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
        .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), .ANALOG_POL(1'b0), .DM(3'b110));

    sky130_fd_io__top_gpiov2 pad_spi_mosi ( .PAD(spi_mosi), .OUT(spi_mosi_core), .OE_N(1'b0), .IN(), 
        .HLD_H_N(1'b1), .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
        .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b1), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
        .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), .ANALOG_POL(1'b0), .DM(3'b110));
        
    sky130_fd_io__top_gpiov2 pad_spi_cs ( .PAD(spi_cs_n), .OUT(spi_cs_n_core), .OE_N(1'b0), .IN(), 
        .HLD_H_N(1'b1), .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
        .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b1), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
        .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), .ANALOG_POL(1'b0), .DM(3'b110));

    sky130_fd_io__top_gpiov2 pad_flash_cs ( .PAD(flash_csb), .OUT(flash_csb_core), .OE_N(1'b0), .IN(), 
        .HLD_H_N(1'b1), .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
        .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b1), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
        .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), .ANALOG_POL(1'b0), .DM(3'b110));

    sky130_fd_io__top_gpiov2 pad_flash_clk ( .PAD(flash_clk), .OUT(flash_clk_core), .OE_N(1'b0), .IN(), 
        .HLD_H_N(1'b1), .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
        .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b1), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
        .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), .ANALOG_POL(1'b0), .DM(3'b110));

    sky130_fd_io__top_gpiov2 pad_flash_mosi ( .PAD(flash_io0), .OUT(flash_io0_core), .OE_N(1'b0), .IN(), 
        .HLD_H_N(1'b1), .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
        .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b1), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
        .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), .ANALOG_POL(1'b0), .DM(3'b110));


    // --- BIDIR GPIO PADS (Controlled by Core) ---
    genvar i;
    generate
        for (i=0; i<8; i=i+1) begin : gpio_pads
            sky130_fd_io__top_gpiov2 pad_gpio (
                .PAD(gpio_pins[i]),
                .IN(gpio_i[i]),
                .OUT(gpio_o[i]),
                .OE_N(~gpio_oe[i]),  // Invert OE because Pad is Active Low
                .HLD_H_N(1'b1), 
                .ENABLE_H(1'b1), .ENABLE_INP_H(1'b1), .ENABLE_VDDA_H(1'b1), .ENABLE_VDDIO(1'b1), 
                .ENABLE_VSWITCH_H(1'b0), .INP_DIS(1'b0), .IB_MODE_SEL(1'b0), .VTRIP_SEL(1'b0), 
                .SLOW(1'b0), .HLD_OVR(1'b0), .ANALOG_EN(1'b0), .ANALOG_SEL(1'b0), 
                .ANALOG_POL(1'b0), .DM(3'b110)
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    // 3. CORE INSTANTIATION
    // -------------------------------------------------------------------------
    vajra_6g_core core (
        .clk(clk_core),
        .resetn(resetn_core),

        // Internal RAM Connections
        .ram_wbm_adr_o(ram_wbm_adr), 
        .ram_wbm_dat_o(ram_wbm_dat_core_to_ram), 
        .ram_wbm_dat_i(ram_wbm_dat_ram_to_core),
        .ram_wbm_we_o(ram_wbm_we), 
        .ram_wbm_sel_o(ram_wbm_sel), 
        .ram_wbm_stb_o(ram_wbm_stb), 
        .ram_wbm_ack_i(ram_wbm_ack), 
        .ram_wbm_cyc_o(ram_wbm_cyc),

        // Peripherals
        .flash_csb(flash_csb_core), .flash_clk(flash_clk_core), .flash_io0(flash_io0_core), .flash_io1(flash_io1_core),
        .serial_tx(uart_tx_core), .serial_rx(uart_rx_core),
        .gpio_i(gpio_i), .gpio_o(gpio_o), .gpio_oe(gpio_oe),
        .spi_sclk(spi_sclk_core), .spi_mosi(spi_mosi_core), .spi_miso(spi_miso_core), .spi_cs_n(spi_cs_n_core),
        .ext_irq(ext_irq), .eoi(eoi),
        .trace_valid(trace_valid), .trace_data(trace_data)
    );

    // -------------------------------------------------------------------------
    // 4. SRAM MACRO INSTANTIATION
    // -------------------------------------------------------------------------
    wire [8:0] sram_addr = ram_wbm_adr[11:3]; 
    wire sram_csb = ~ram_wbm_stb; 
    wire sram_web = ~ram_wbm_we;

    sky130_sram_2kbyte_1rw1r_32x512_8 sram_low (
        .clk0(clk_core), .csb0(sram_csb), .web0(sram_web),
        .wmask0(ram_wbm_sel[3:0]), .addr0(sram_addr),
        .din0(ram_wbm_dat_core_to_ram[31:0]),
        .dout0(ram_wbm_dat_ram_to_core[31:0]),
        .clk1(clk_core), .csb1(1'b1), .addr1(9'b0), .dout1()
    );

    sky130_sram_2kbyte_1rw1r_32x512_8 sram_high (
        .clk0(clk_core), .csb0(sram_csb), .web0(sram_web),
        .wmask0(ram_wbm_sel[7:4]), .addr0(sram_addr),
        .din0(ram_wbm_dat_core_to_ram[63:32]),
        .dout0(ram_wbm_dat_ram_to_core[63:32]),
        .clk1(clk_core), .csb1(1'b1), .addr1(9'b0), .dout1()
    );
    assign ram_wbm_ack = ram_wbm_stb;

endmodule

// =========================================================================
// BLACKBOX DEFINITIONS
// =========================================================================

// 1. SRAM STUB 
(* blackbox *)
module sky130_sram_2kbyte_1rw1r_32x512_8(
`ifdef USE_POWER_PINS
    inout vccd1, inout vssd1,
`endif
    input clk0, input csb0, input web0, input [3:0] wmask0, input [8:0] addr0, input [31:0] din0, output [31:0] dout0,
    input clk1, input csb1, input [8:0] addr1, output [31:0] dout1
);
endmodule

// 2. IO PAD STUB (Matches your actual PDK cell)
(* blackbox *)
module sky130_fd_io__top_gpiov2 (
`ifdef USE_POWER_PINS
    inout vccd1, inout vssd1, inout vdda1, inout vssa1, inout vddio1, inout vssio1,
`endif
    inout PAD,
    output IN,
    input  OUT,
    input  OE_N,
    input  HLD_H_N,
    input  ENABLE_H,
    input  ENABLE_INP_H,
    input  ENABLE_VDDA_H,
    input  ENABLE_VDDIO,
    input  ENABLE_VSWITCH_H,
    input  INP_DIS,
    input  IB_MODE_SEL,
    input  VTRIP_SEL,
    input  SLOW,
    input  HLD_OVR,
    input  ANALOG_EN,
    input  ANALOG_SEL,
    input  ANALOG_POL,
    input [2:0] DM
);
endmodule