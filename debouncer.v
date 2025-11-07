
module debouncer(
    input clk,
    input rst_n,
    input btn_in, 
    output reg btn_out 
);
    parameter [19:0] DEBOUNCE_LIMIT = 539999;
    
    reg [19:0] counter = 0;
    reg btn_state = 0; 
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            btn_state <= 0;
            btn_out <= 0;
        end else begin
            if (btn_in == btn_state) begin
                counter <= 0;
            end else begin
                if (counter == DEBOUNCE_LIMIT) begin
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
