// output_controller.v
// --- VERSION 7: Destructive Backspace (3-char) ---

module output_controller(
    input           clk,
    input           rst_n,
    
    // Triggers from FSM
    input           trigger_letter,
    input           trigger_word,
    input           trigger_line,
    
    // Triggers from top.v
    input           manual_space_press,
    input           manual_newline_press,
    input           manual_backspace_press, // NEW
    
    input           long_press_clear,
    
    // Data from decoder
    input [7:0]     decoded_char_in,
    
    // UART interface
    input           uart_busy_in,
    output reg [7:0] char_to_send_out = 0,
    output reg      send_trigger_out = 0
);

    // FSM States (4 bits)
    localparam S_IDLE = 4'b0000;
    localparam S_SEND_CHAR = 4'b0001;
    localparam S_SEND_GAP = 4'b0010;
    localparam S_SEND_LF = 4'b0011;
    localparam S_WAIT = 4'b0100;
    // ANSI Clear
    localparam S_SEND_CLR1 = 4'b0101; // ESC
    localparam S_SEND_CLR2 = 4'b0110; // [
    localparam S_SEND_CLR3 = 4'b0111; // 2
    localparam S_SEND_CLR4 = 4'b1000; // J
    // ANSI Home
    localparam S_SEND_HOME1 = 4'b1001; // ESC
    localparam S_SEND_HOME2 = 4'b1010; // [
    localparam S_SEND_HOME3 = 4'b1011; // H
    // NEW: Backspace Sequence
    localparam S_SEND_BS1 = 4'b1100; // \b (8'h08)
    localparam S_SEND_BS2 = 4'b1101; // ' ' (8'h20)
    localparam S_SEND_BS3 = 4'b1110; // \b (8'h08)

    reg [3:0] state = S_IDLE;
    reg [3:0] next_state = S_IDLE;
    reg [7:0] gap_char = 0;
    reg [7:0] char_to_send_buf = 0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            next_state <= S_IDLE;
            send_trigger_out <= 0;
        end else begin
            
            send_trigger_out <= 0; // Default: don't send
            
            if (state != S_WAIT && state != S_IDLE && uart_busy_in) begin
                state <= state; // Hold state
            end
            
            // Main FSM
            else begin
                case (state)
                    S_IDLE: begin
                        // --- Priority 1: Backspace ---
                        if (manual_backspace_press && !uart_busy_in) begin
                            state <= S_SEND_BS1; // Start 3-char sequence
                        end
                        // --- Priority 2: Long Press Clear ---
                        else if (long_press_clear && !uart_busy_in) begin
                            state <= S_SEND_CLR1; // Start 7-char sequence
                        end
                        // --- Priority 3: Manual Buttons ---
                        else if (manual_space_press && !uart_busy_in) begin
                            char_to_send_out <= 8'h20; // ' '
                            send_trigger_out <= 1;
                            state <= S_WAIT;
                            next_state <= S_IDLE;
                        end 
                        else if (manual_newline_press && !uart_busy_in) begin
                            char_to_send_out <= 8'h0D; // '\r'
                            send_trigger_out <= 1;
                            state <= S_WAIT;
                            next_state <= S_SEND_LF;
                        end
                        // --- Priority 4: Automatic Gaps ---
                        else if (trigger_letter && !uart_busy_in) begin
                            char_to_send_out <= decoded_char_in;
                            send_trigger_out <= 1;
                            state <= S_WAIT;
                            next_state <= S_IDLE;
                        end 
                        else if (trigger_word && !uart_busy_in) begin
                            char_to_send_buf <= decoded_char_in;
                            gap_char <= 8'h20; // ' '
                            state <= S_SEND_CHAR;
                        end
                        else if (trigger_line && !uart_busy_in) begin
                            char_to_send_buf <= decoded_char_in;
                            gap_char <= 8'h0D; // '\r'
                            state <= S_SEND_CHAR;
                        end
                    end
                    
                    // --- Automatic Sending States ---
                    S_SEND_CHAR: begin
                        char_to_send_out <= char_to_send_buf;
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= S_SEND_GAP;
                    end
                    S_SEND_GAP: begin
                        char_to_send_out <= gap_char;
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= (gap_char == 8'h20) ? S_IDLE : S_SEND_LF;
                    end
                    S_SEND_LF: begin
                        char_to_send_out <= 8'h0A; // '\n'
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= S_IDLE;
                    end

                    // --- ANSI CLEAR STATES ---
                    S_SEND_CLR1: begin
                        char_to_send_out <= 8'h1B; // ESC
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= S_SEND_CLR2;
                    end
                    S_SEND_CLR2: begin
                        char_to_send_out <= 8'h5B; // '['
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= S_SEND_CLR3;
                    end
                    S_SEND_CLR3: begin
                        char_to_send_out <= 8'h32; // '2'
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= S_SEND_CLR4;
                    end
                    S_SEND_CLR4: begin
                        char_to_send_out <= 8'h4A; // 'J'
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= S_SEND_HOME1;
                    end
                    
                    // --- ANSI HOME STATES ---
                    S_SEND_HOME1: begin
                        char_to_send_out <= 8'h1B; // ESC
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= S_SEND_HOME2;
                    end
                    S_SEND_HOME2: begin
                        char_to_send_out <= 8'h5B; // '['
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= S_SEND_HOME3;
                    end
                    S_SEND_HOME3: begin
                        char_to_send_out <= 8'h48; // 'H'
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= S_IDLE; // All done
                    end
                    
                    // --- NEW: BACKSPACE STATES ---
                    S_SEND_BS1: begin
                        char_to_send_out <= 8'h08; // Backspace
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= S_SEND_BS2;
                    end
                    S_SEND_BS2: begin
                        char_to_send_out <= 8'h20; // Space
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= S_SEND_BS3;
                    end
                    S_SEND_BS3: begin
                        char_to_send_out <= 8'h08; // Backspace
                        send_trigger_out <= 1;
                        state <= S_WAIT;
                        next_state <= S_IDLE;
                    end
                    
                    // --- Wait State ---
                    S_WAIT: begin
                        if (!uart_busy_in) begin
                            state <= next_state; // Go to where we planned
                        end
                    end
                    
                endcase
            end
        end
    end
endmodule