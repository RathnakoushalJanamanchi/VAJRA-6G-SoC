module pcpi_kyber (
    input clk,
    input resetn,

    input             pcpi_valid,
    input      [31:0] pcpi_insn,
    input      [63:0] pcpi_rs1,
    input      [63:0] pcpi_rs2,
    output reg        pcpi_wr,
    output reg [63:0] pcpi_rd,
    output reg        pcpi_wait,
    output reg        pcpi_ready
);
    // Kyber Parameters
    parameter KYBER_Q = 3329;

    // Custom opcode for Kyber accelerator
    wire is_kyber_insn = pcpi_valid && (pcpi_insn[6:0] == 7'b0101011);

    // Operation codes (funct7)
    localparam OP_NTT_MUL = 7'b0000001;
    localparam OP_NTT_ADD = 7'b0000010;
    localparam OP_NTT_SUB = 7'b0000011;

    localparam IDLE = 0;
    localparam BUSY = 1;
    reg state;

    // SIMD Inputs (4x 16-bit)
    wire [15:0] a0 = pcpi_rs1[15:0];
    wire [15:0] a1 = pcpi_rs1[31:16];
    wire [15:0] a2 = pcpi_rs1[47:32];
    wire [15:0] a3 = pcpi_rs1[63:48];

    wire [15:0] b0 = pcpi_rs2[15:0];
    wire [15:0] b1 = pcpi_rs2[31:16];
    wire [15:0] b2 = pcpi_rs2[47:32];
    wire [15:0] b3 = pcpi_rs2[63:48];

    // Intermediate wires for combinatorial logic
    reg [15:0] res0, res1, res2, res3;

    // Function for modular reduction (Barrett-like or simple conditional subtract for Add/Sub)
    function [15:0] reduce_add;
        input [16:0] val;
        begin
            reduce_add = (val >= KYBER_Q) ? val - KYBER_Q : val;
        end
    endfunction

    // Montgomery Multiplication
    // montgomery_reduce(a * b)
    function [15:0] montgomery_mul;
        input [15:0] a;
        input [15:0] b;
        reg [31:0] t;
        reg [15:0] u;
        reg [31:0] val;
        begin
            val = a * b;
            u = val * 3327; // (val * q^-1) mod 2^16
            t = (val + u * 3329) >> 16;
            if (t >= 3329)
                montgomery_mul = t - 3329;
            else
                montgomery_mul = t;
        end
    endfunction

    // Combinatorial logic for results
    always @* begin
        case (pcpi_insn[31:25])
            OP_NTT_MUL: begin
                res0 = montgomery_mul(a0, b0);
                res1 = montgomery_mul(a1, b1);
                res2 = montgomery_mul(a2, b2);
                res3 = montgomery_mul(a3, b3);
            end
            OP_NTT_ADD: begin
                res0 = reduce_add(a0 + b0);
                res1 = reduce_add(a1 + b1);
                res2 = reduce_add(a2 + b2);
                res3 = reduce_add(a3 + b3);
            end
            OP_NTT_SUB: begin
                 res0 = (a0 >= b0) ? (a0 - b0) : (a0 + KYBER_Q - b0);
                 res1 = (a1 >= b1) ? (a1 - b1) : (a1 + KYBER_Q - b1);
                 res2 = (a2 >= b2) ? (a2 - b2) : (a2 + KYBER_Q - b2);
                 res3 = (a3 >= b3) ? (a3 - b3) : (a3 + KYBER_Q - b3);
            end
            default: begin
                res0 = 0; res1 = 0; res2 = 0; res3 = 0;
            end
        endcase
    end

    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            pcpi_ready <= 0;
            pcpi_wr <= 0;
        end else begin
            pcpi_ready <= 0;
            pcpi_wr <= 0;

            if (state == IDLE) begin
                if (is_kyber_insn) begin
                    state <= BUSY;
                    pcpi_wait <= 1;
                end
            end else if (state == BUSY) begin
                // Register the result
                pcpi_rd <= {res3, res2, res1, res0};
                pcpi_ready <= 1;
                pcpi_wr <= 1;
                pcpi_wait <= 0;
                state <= IDLE;
            end
        end
    end

endmodule
