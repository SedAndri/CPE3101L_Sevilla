// Chrys Sean T. Sevilla
// Group 4 CPE 3101L 10:30AM - 1:30PM
// Top-Level Wrapper for DE10-Lite with 7-Segment Displays

module VMC_DE10 (
    input  wire MAX10_CLK1_50, // 50 MHz Board Clock
    input  wire [9:0] SW,      // Switches
    output wire [9:0] LEDR,    // LEDs
    output wire [7:0] HEX0,    // 7-Seg Digit 0 (Rightmost)
    output wire [7:0] HEX1,    // 7-Seg Digit 1
    output wire [7:0] HEX2,    // 7-Seg Digit 2
    output wire [7:0] HEX3,    // 7-Seg Digit 3
    output wire [7:0] HEX4,    // 7-Seg Digit 4
    output wire [7:0] HEX5     // 7-Seg Digit 5 (Leftmost)
);

    // 1. Internal Signals
    wire w_slow_clk; 
    wire [7:0] w_cost;   // Wires to hold the debug values
    wire [7:0] w_paid;
    wire [7:0] w_change;

    // 2. Instantiate Clock Divider
    ClockDivider clk_div_inst (
        .clk_in  (MAX10_CLK1_50),
        .nReset  (SW[9]),
        .clk_out (w_slow_clk)
    );

    // 3. Instantiate VMC with Debug Outputs
    VMC vmc_inst (
        .CLOCK   (w_slow_clk),
        .nRESET  (SW[9]),
        .START   (SW[0]), .SELECT (SW[1]), .OK (SW[2]), .CANCEL (SW[3]),
        .COIN_1  (SW[4]), .COIN_5 (SW[5]), .COIN_10 (SW[6]),
        
        // LEDs
        .ITEM    (LEDR[2:0]),
        .C1      (LEDR[5]), .C5 (LEDR[6]), .C10 (LEDR[7]),
        .DISPENSE(LEDR[9]),

        // New Debug Connections
        .DBG_COST   (w_cost),
        .DBG_PAID   (w_paid),
        .DBG_CHANGE (w_change)
    );

    // 4. Instantiate 7-Segment Decoders
    
    // --- Display PAID Amount (HEX1, HEX0) ---
    HexTo7SegmentDecoder disp_paid_L (
        .hex(w_paid[3:0]), .dp(1'b1), .seg(HEX0) // Lower 4 bits
    );
    HexTo7SegmentDecoder disp_paid_H (
        .hex(w_paid[7:4]), .dp(1'b1), .seg(HEX1) // Upper 4 bits
    );

    // --- Display CHANGE Amount (HEX3, HEX2) ---
    HexTo7SegmentDecoder disp_change_L (
        .hex(w_change[3:0]), .dp(1'b1), .seg(HEX2) 
    );
    HexTo7SegmentDecoder disp_change_H (
        .hex(w_change[7:4]), .dp(1'b1), .seg(HEX3) 
    );

    // --- Display COST Amount (HEX5, HEX4) ---
    HexTo7SegmentDecoder disp_cost_L (
        .hex(w_cost[3:0]), .dp(1'b1), .seg(HEX4) 
    );
    HexTo7SegmentDecoder disp_cost_H (
        .hex(w_cost[7:4]), .dp(1'b1), .seg(HEX5) 
    );

    // Turn off unused LEDs
    assign LEDR[4:3] = 2'b00;
    assign LEDR[8]   = 1'b0;

endmodule