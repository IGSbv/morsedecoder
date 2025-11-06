// morse_buffer.v
module morse_buffer(
    input           clk,
    input           rst_n,
    input           new_dot,
    input           new_dash,
    input           clear,      // Pulse to clear the buffer
    
    output reg [11:0] symbol_data = 0,   // Max 6 symbols (6*2=12 bits)
    output reg [2:0]  symbol_count = 0  // 0 to 6
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            symbol_data <= 0;
            symbol_count <= 0;
        end else if (clear) begin
            symbol_data <= 0;
            symbol_count <= 0;
        end else if (new_dot && symbol_count < 6) begin
            // Shift left by 2, add '01' (DOT)
            symbol_data <= {symbol_data[9:0], 2'b01};
            symbol_count <= symbol_count + 1;
        end else if (new_dash && symbol_count < 6) begin
            // Shift left by 2, add '10' (DASH)
            symbol_data <= {symbol_data[9:0], 2'b10};
            symbol_count <= symbol_count + 1;
        end
    end
endmodule