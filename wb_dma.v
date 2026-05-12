module wb_dma (
    input clk,
    input resetn,

    // Wishbone Slave Interface (Config Registers)
    input  [63:0] s_wbm_adr_i,
    input  [63:0] s_wbm_dat_i,
    output [63:0] s_wbm_dat_o,
    input         s_wbm_we_i,
    input  [7:0]  s_wbm_sel_i,
    input         s_wbm_stb_i,
    input         s_wbm_cyc_i,
    output reg    s_wbm_ack_o,

    // Wishbone Master Interface (Data Movement)
    output reg [63:0] m_wbm_adr_o,
    output reg [63:0] m_wbm_dat_o,
    input      [63:0] m_wbm_dat_i,
    output reg        m_wbm_we_o,
    output reg [7:0]  m_wbm_sel_o,
    output reg        m_wbm_stb_o,
    input             m_wbm_ack_i,
    output reg        m_wbm_cyc_o,

    // Interrupt
    output reg irq
);

    // Registers
    // 0x00: Source Addr
    // 0x08: Dest Addr
    // 0x10: Length (Bytes)
    // 0x18: Control/Status (Bit 0: Start, Bit 1: Busy, Bit 2: DoneIRQ Enable)

    reg [63:0] reg_src;
    reg [63:0] reg_dest;
    reg [63:0] reg_len;
    reg [63:0] reg_ctrl;

    assign s_wbm_dat_o = (s_wbm_adr_i[5:0] == 6'h00) ? reg_src :
                         (s_wbm_adr_i[5:0] == 6'h08) ? reg_dest :
                         (s_wbm_adr_i[5:0] == 6'h10) ? reg_len :
                         (s_wbm_adr_i[5:0] == 6'h18) ? reg_ctrl : 64'b0;

    // Slave Logic
    always @(posedge clk) begin
        if (!resetn) begin
            s_wbm_ack_o <= 0;
            reg_src <= 0; reg_dest <= 0; reg_len <= 0; reg_ctrl <= 0;
        end else begin
            s_wbm_ack_o <= s_wbm_stb_i && s_wbm_cyc_i && !s_wbm_ack_o;
            if (s_wbm_stb_i && s_wbm_cyc_i && s_wbm_we_i) begin
                case (s_wbm_adr_i[5:0])
                    6'h00: reg_src <= s_wbm_dat_i;
                    6'h08: reg_dest <= s_wbm_dat_i;
                    6'h10: reg_len <= s_wbm_dat_i;
                    6'h18: reg_ctrl <= s_wbm_dat_i; // Start bit written here
                endcase
            end
            if (reg_ctrl[1]) reg_ctrl[0] <= 0; // Clear start bit if busy
            if (state == IDLE && reg_ctrl[1]) reg_ctrl[1] <= 0; // Clear busy if idle
            if (state != IDLE) reg_ctrl[1] <= 1; // Set busy
        end
    end

    // DMA State Machine
    reg [2:0] state;
    localparam IDLE = 0;
    localparam READ = 1;
    localparam WRITE = 2;
    localparam DONE = 3;

    reg [63:0] current_src;
    reg [63:0] current_dest;
    reg [63:0] count;
    reg [63:0] buf_data;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            m_wbm_cyc_o <= 0;
            m_wbm_stb_o <= 0;
            irq <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (reg_ctrl[0]) begin // Start
                        current_src <= reg_src;
                        current_dest <= reg_dest;
                        count <= reg_len;
                        state <= READ;
                        irq <= 0;
                    end
                end
                READ: begin
                    m_wbm_adr_o <= current_src;
                    m_wbm_sel_o <= 8'hFF;
                    m_wbm_we_o <= 0;
                    m_wbm_cyc_o <= 1;
                    m_wbm_stb_o <= 1;
                    if (m_wbm_ack_i) begin
                        buf_data <= m_wbm_dat_i;
                        m_wbm_cyc_o <= 0;
                        m_wbm_stb_o <= 0;
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    m_wbm_adr_o <= current_dest;
                    m_wbm_dat_o <= buf_data;
                    m_wbm_sel_o <= 8'hFF;
                    m_wbm_we_o <= 1;
                    m_wbm_cyc_o <= 1;
                    m_wbm_stb_o <= 1;
                    if (m_wbm_ack_i) begin
                        m_wbm_cyc_o <= 0;
                        m_wbm_stb_o <= 0;
                        current_src <= current_src + 8;
                        current_dest <= current_dest + 8;
                        if (count <= 8) begin
                            state <= DONE;
                        end else begin
                            count <= count - 8;
                            state <= READ;
                        end
                    end
                end
                DONE: begin
                    if (reg_ctrl[2]) irq <= 1; // IRQ Enable check
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
