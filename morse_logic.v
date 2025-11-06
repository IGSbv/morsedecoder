// morse_logic.v
module morse_logic(
    input           clk,
    input           rst_n,
    input           ms_tick,      // 1ms pulse
    input           key_state,    // Synchronized key input
    
    output  reg     new_dot,      // 1-cycle pulse
    output  reg     new_dash,     // 1-cycle pulse
    output  reg     gap_letter,   // 1-cycle pulse
    output  reg     gap_word,     // 1-cycle pulse
    output  reg     gap_line,     // 1-cycle pulse
    output  reg     long_press_clear // NEW: 1-cycle pulse for clear
);

    // Arduino Timings
    parameter MIN_PRESS = 50;
    parameter DOT_MAX = 200;
    parameter LETTER_GAP_MIN = 400;
    parameter WORD_GAP_MIN = 700;
    parameter LINE_GAP_MIN = 1200;
    parameter LONG_PRESS = 2000;  // NEW: 2-second long press
    
    // FSM States
    localparam S_IDLE = 2'b00;
    localparam S_PRESSED = 2'b01;
    localparam S_GAP = 2'b10;
    
    reg [1:0] state = S_IDLE;
    reg [11:0] pulse_timer = 0; // Needs to hold LONG_PRESS+
    reg [11:0] gap_timer = 0;   // Needs to hold LINE_GAP_MIN+
    
    // Edge detection
    reg key_state_prev = 0;
    wire key_pressed = key_state & ~key_state_prev;
    wire key_released = ~key_state & key_state_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            pulse_timer <= 0;
            gap_timer <= 0;
            key_state_prev <= 0;
            new_dot <= 0;
            new_dash <= 0;
            gap_letter <= 0;
            gap_word <= 0;
            gap_line <= 0;
            long_press_clear <= 0; // NEW: Reset
        end else begin
            // Default: clear pulse outputs
            new_dot <= 0;
            new_dash <= 0;
            gap_letter <= 0;
            gap_word <= 0;
            gap_line <= 0;
            long_press_clear <= 0; // NEW: Default to 0
            
            // Update previous key state
            key_state_prev <= key_state;
            
            // Increment timers on 1ms tick
            if (ms_tick) begin
                if (state == S_PRESSED) pulse_timer <= pulse_timer + 1;
                if (state == S_GAP)     gap_timer <= gap_timer + 1;
            end
            
            // --- Main FSM Logic ---
            case (state)
                S_IDLE: begin
                    if (key_pressed) begin
                        state <= S_PRESSED;
                        pulse_timer <= 0;
                    end
                end
                
                S_PRESSED: begin
                    // --- NEW: Check for long press first ---
                    if (ms_tick && pulse_timer == LONG_PRESS) begin
                        long_press_clear <= 1;
                        state <= S_IDLE; // Go to idle, wait for key release
                    end
                    // --- OLD: Check for key release ---
                    else if (key_released) begin
                        state <= S_GAP;
                        gap_timer <= 0;
                        
                        // Evaluate the pulse that just ended
                        if (pulse_timer > MIN_PRESS) begin
                            if (pulse_timer < DOT_MAX) new_dot <= 1;
                            else new_dash <= 1;
                        end
                    end
                end
                
                S_GAP: begin
                    if (key_pressed) begin
                        // Gap was interrupted, it's a new letter
                        state <= S_PRESSED;
                        pulse_timer <= 0;
                    end
                    
                    if (ms_tick) begin
                        if (gap_timer == LINE_GAP_MIN) begin
                            gap_line <= 1;
                            state <= S_IDLE;
                        end
                        else if (gap_timer == WORD_GAP_MIN) begin
                            gap_word <= 1;
                            state <= S_IDLE;
                        end
                        else if (gap_timer == LETTER_GAP_MIN) begin
                            gap_letter <= 1;
                            state <= S_IDLE;
                        end
                    end
                end
                
            endcase
        end
    end

endmodule