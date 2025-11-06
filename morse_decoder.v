// morse_decoder.v
module morse_decoder(
    input [11:0] symbol_data,  // Data from buffer
    input [2:0]  symbol_count, // Length of data
    
    output reg [7:0] ascii_out   // 8-bit ASCII
);

    // We create a single 15-bit value for the case statement
    // 3-bits for count, 12-bits for data.
    wire [14:0] lookup_key = {symbol_count, symbol_data};

    always @(*) begin
        case (lookup_key)
            // Format: {count, data}
            // Data is {sym6, sym5, sym4, sym3, sym2, sym1}
            // 'A' (.-) = 2 symbols, {DASH, DOT} = {2'b10, 2'b01}
            // Key = {3'd2, 10'b0, 2'b10, 2'b01} = 15'b010_00000000_1001
            // Let's re-do the buffer to make this easier...
            // Ok, the buffer shifts left. So sym1 is MSB.
            // A (.-) = {DOT, DASH} = {01, 10}
            // Key = {3'd2, 2'b01, 2'b10, 8'b0} = 15'b010_011000000000

            // Re-thinking: The buffer logic is {sym_N...sym2, sym1}
            // 'A' (.-) -> 1st: new_dot -> {0, 01} -> count=1
            //            2nd: new_dash-> {01, 10} -> count=2
            // So data = 0...0110. Key = {3'd2, 8'b0, 4'b0110}
            // This is better.

            // Format: {3'bCOUNT, 12'b_DATA_}
            // (Data is LSB-aligned)
            
            // Letters
            {3'd2, 12'b000000000110}: ascii_out = "A"; // .-
            {3'd4, 12'b000010010101}: ascii_out = "B"; // -...
            {3'd4, 12'b000010011001}: ascii_out = "C"; // -.-.
            {3'd3, 12'b000000100101}: ascii_out = "D"; // -..
            {3'd1, 12'b000000000001}: ascii_out = "E"; // .
            {3'd4, 12'b000001011001}: ascii_out = "F"; // ..-.
            {3'd3, 12'b000000101001}: ascii_out = "G"; // --.
            {3'd4, 12'b000001010101}: ascii_out = "H"; // ....
            {3'd2, 12'b000000000101}: ascii_out = "I"; // ..
            {3'd4, 12'b000001101010}: ascii_out = "J"; // .---
            {3'd3, 12'b000000100110}: ascii_out = "K"; // -.-
            {3'd4, 12'b000001100101}: ascii_out = "L"; // .-..
            {3'd2, 12'b000000001010}: ascii_out = "M"; // --
            {3'd2, 12'b000000001001}: ascii_out = "N"; // -.
            {3'd3, 12'b000000101010}: ascii_out = "O"; // ---
            {3'd4, 12'b000001101001}: ascii_out = "P"; // .--.
            {3'd4, 12'b000010100110}: ascii_out = "Q"; // --.-
            {3'd3, 12'b000000011001}: ascii_out = "R"; // .-.
            {3'd3, 12'b000000010101}: ascii_out = "S"; // ...
            {3'd1, 12'b000000000010}: ascii_out = "T"; // -
            {3'd3, 12'b000000010110}: ascii_out = "U"; // ..-
            {3'd4, 12'b000001010110}: ascii_out = "V"; // ...-
            {3'd3, 12'b000000011010}: ascii_out = "W"; // .--
            {3'd4, 12'b000010010110}: ascii_out = "X"; // -..-
            {3'd4, 12'b000010011010}: ascii_out = "Y"; // -.--
            {3'd4, 12'b000010100101}: ascii_out = "Z"; // --..
            
            // Numbers
            {3'd5, 12'b001010101010}: ascii_out = "0"; // -----
            {3'd5, 12'b000110101010}: ascii_out = "1"; // .----
            {3'd5, 12'b000101101010}: ascii_out = "2"; // ..---
            {3'd5, 12'b000101011010}: ascii_out = "3"; // ...--
            {3'd5, 12'b000101010110}: ascii_out = "4"; // ....-
            {3'd5, 12'b000101010101}: ascii_out = "5"; // .....
            {3'd5, 12'b001001010101}: ascii_out = "6"; // -....
            {3'd5, 12'b001010010101}: ascii_out = "7"; // --...
            {3'd5, 12'b001010100101}: ascii_out = "8"; // ---..
            {3'd5, 12'b001010101001}: ascii_out = "9"; // ----.
            
            default: ascii_out = "?"; // Unknown symbol
        endcase
    end
    
endmodule