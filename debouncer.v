// debouncer.v
// This module takes a noisy/bouncy input (btn_in) and
// provides a clean, stable output (btn_out).

module debouncer(
    input clk,
    input rst_n,
    input btn_in,     // Bouncy input
    output reg btn_out // Clean output
);
    // 27MHz clock. We want ~20ms debounce time.
    // 27,000,000 * 0.020 = 540,000 cycles.
    // A 20-bit counter is needed (2^20 > 540k).
    parameter [19:0] DEBOUNCE_LIMIT = 539999;
    
    reg [19:0] counter = 0;
    reg btn_state = 0; // Internal stable state
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            btn_state <= 0;
            btn_out <= 0;
        end else begin
            if (btn_in == btn_state) begin
                // Input matches our stable state, reset counter
                counter <= 0;
            end else begin
                // Input is different! Start/continue counting
                if (counter == DEBOUNCE_LIMIT) begin
                    // Timer expired, it's a real change.
                    btn_state <= btn_in;
                    btn_out <= btn_in;
                    counter <= 0;
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end
endmodule