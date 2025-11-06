// top.v
module top(
    input clk,         // 27MHz clock
    input morse_in,    // Clean, debounced input from your MCP6004
    input btn_space,   // Bouncy input from Pin 3
    input btn_newline, // Bouncy input from Pin 4
    output tx_pin       // UART Transmit
);

    // --- Reset Logic ---
    reg [4:0] rst_counter = 5'b0;
    wire rst_n;
    assign rst_n = (rst_counter == 5'b11111); 
    always @(posedge clk) begin
        if (!rst_n) rst_counter <= rst_counter + 1;
    end

    // --- 1ms Tick Generator ---
    reg [14:0] ms_counter = 0;
    wire ms_tick;
    assign ms_tick = (ms_counter == 26999);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ms_counter <= 0;
        end else if (ms_tick) begin
            ms_counter <= 0;
        end else begin
            ms_counter <= ms_counter + 1;
        end
    end

    // --- Input Synchronizer (for morse key) ---
    reg morse_sync_r1, morse_sync_r2;
    wire morse_in_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            morse_sync_r1 <= 0;
            morse_sync_r2 <= 0;
        end else begin
            morse_sync_r1 <= morse_in;
            morse_sync_r2 <= morse_sync_r1;
        end
    end
    assign morse_in_sync = morse_sync_r2;

    // --- Debouncers and Edge Detectors for Buttons ---
    wire btn_space_clean;
    wire btn_newline_clean;
    
    debouncer space_debouncer (
        .clk(clk),
        .rst_n(rst_n),
        .btn_in(btn_space),
        .btn_out(btn_space_clean)
    );
    
    debouncer newline_debouncer (
        .clk(clk),
        .rst_n(rst_n),
        .btn_in(btn_newline),
        .btn_out(btn_newline_clean)
    );
    
    // --- NEW: Mutually Exclusive Button Logic ---
    // Note: Buttons are active-LOW (1=off, 0=on)
    
    wire btn3_pressed = !btn_space_clean;
    wire btn4_pressed = !btn_newline_clean;
    
    reg btn3_prev = 0;
    reg btn4_prev = 0;
    
    // Detect the 0 -> 1 transition (rising edge)
    wire btn3_just_pressed = btn3_pressed & !btn3_prev;
    wire btn4_just_pressed = btn4_pressed & !btn4_prev;
    
    always @(posedge clk) begin
        btn3_prev <= btn3_pressed;
        btn4_prev <= btn4_pressed;
    end
    
    // Logic:
    // Backspace = Hold 3, Press 4 (Press 4 *while* 3 is already pressed)
    // Space = Press 3 only (Press 3 *while* 4 is NOT pressed)
    // Newline = Press 4 only (Press 4 *while* 3 is NOT pressed)
    
    wire manual_backspace_press;
    wire manual_space_press;
    wire manual_newline_press;
    
    assign manual_backspace_press = btn4_just_pressed & btn3_pressed;
    assign manual_space_press     = btn3_just_pressed & !btn4_pressed;
    assign manual_newline_press   = btn4_just_pressed & !btn3_pressed;
    

    // --- Wires for all modules ---
    wire        new_dot;
    wire        new_dash;
    wire        gap_letter;
    wire        gap_word;
    wire        gap_line;
    wire        long_press_clear;
    
    wire [11:0] symbol_data;
    wire [2:0]  symbol_count;
    
    wire [7:0]  decoded_char;
    wire [7:0]  char_to_send;
    wire        send_trigger;
    wire        uart_busy;

    // --- Module Instantiations ---

    morse_logic logic_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .ms_tick(ms_tick),
        .key_state(morse_in_sync),
        .new_dot(new_dot),
        .new_dash(new_dash),
        .gap_letter(gap_letter),
        .gap_word(gap_word),
        .gap_line(gap_line),
        .long_press_clear(long_press_clear)
    );

    morse_buffer buffer (
        .clk(clk),
        .rst_n(rst_n),
        .new_dot(new_dot),
        .new_dash(new_dash),
        .clear(gap_letter | gap_word | gap_line | manual_backspace_press), // Clear buffer on backspace
        .symbol_data(symbol_data),
        .symbol_count(symbol_count)
    );

    morse_decoder decoder (
        .symbol_data(symbol_data),
        .symbol_count(symbol_count),
        .ascii_out(decoded_char)
    );

    output_controller out_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .trigger_letter(gap_letter),
        .trigger_word(gap_word),
        .trigger_line(gap_line),
        .manual_space_press(manual_space_press),
        .manual_newline_press(manual_newline_press),
        .manual_backspace_press(manual_backspace_press), // NEW: Connected port
        .long_press_clear(long_press_clear),
        .decoded_char_in(decoded_char),
        .uart_busy_in(uart_busy),
        .char_to_send_out(char_to_send),
        .send_trigger_out(send_trigger)
    );

    uart_tx my_uart (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(char_to_send),
        .send(send_trigger),
        .tx_pin(tx_pin),
        .busy(uart_busy)
    );

endmodule