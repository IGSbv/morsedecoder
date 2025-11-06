// uart_tx.v
// Simple UART Transmitter
module uart_tx(
    input           clk,        // System clock (27MHz)
    input           rst_n,      // Active-low reset
    input [7:0]     data_in,    // 8-bit data to send
    input           send,       // Pulse to start sending
    output  reg     tx_pin,     // Serial output pin
    output  reg     busy        // 1 if currently sending
);

    // --- Parameters ---
    // We want 9600 baud.
    // System clock is 27,000,000 Hz.
    // Ticks per bit = 27,000,000 / 9600 = 2813 (rounded)
    parameter CLKS_PER_BIT = 2813;

    // --- State Machine ---
    localparam STATE_IDLE = 3'b001;
    localparam STATE_START = 3'b010;
    localparam STATE_DATA = 3'b011;
    localparam STATE_STOP = 3'b100;

    reg [2:0] state = STATE_IDLE;
    reg [11:0] clk_counter = 0; // Counter for bit timing
    reg [3:0] bit_index = 0;   // Index for 8 data bits
    reg [7:0] data_reg = 0;    // Internal register for data

    // --- Logic ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            state <= STATE_IDLE;
            tx_pin <= 1; // IDLE line is high
            busy <= 0;
            clk_counter <= 0;
            bit_index <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    tx_pin <= 1;
                    busy <= 0;
                    clk_counter <= 0;
                    bit_index <= 0;
                    if (send) begin
                        data_reg <= data_in;
                        busy <= 1;
                        state <= STATE_START;
                    end
                end
                
                STATE_START: begin
                    tx_pin <= 0; // Start bit
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter <= 0;
                        state <= STATE_DATA;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end
                
                STATE_DATA: begin
                    tx_pin <= data_reg[bit_index]; // LSB first
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter <= 0;
                        if (bit_index == 7) begin
                            bit_index <= 0;
                            state <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end
                
                STATE_STOP: begin
                    tx_pin <= 1; // Stop bit
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter <= 0;
                        state <= STATE_IDLE;
                    end else begin
                        clk_counter <= clk_counter + 1;
                    end
                end
            endcase
        end
    end
endmodule