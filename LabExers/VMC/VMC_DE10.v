// Chrys Sean T. Sevilla
// Group 4 CPE 3101L 10:30AM - 1:30PM
// Top-Level Wrapper for DE10-Lite

module VMC_DE10 (
    input  wire MAX10_CLK1_50, // 50 MHz Board Clock
    input  wire [9:0] SW,      // Switches
    output wire [9:0] LEDR     // LEDs
);

    // 1. Internal Signals
    wire w_slow_clk; // 2 Hz Clock from Divider

    // 2. Instantiate the Clock Divider
    // Input: 50MHz, Output: ~2Hz
    ClockDivider clk_div_inst (
        .clk_in  (MAX10_CLK1_50),
        .nReset  (SW[9]),       // Reset on Switch 9
        .clk_out (w_slow_clk)   // Connects to VMC clock
    );

    // 3. Instantiate the Vending Machine Controller
    // We map the Switches directly to the VMC inputs
    VMC vmc_inst (
        .CLOCK   (w_slow_clk),  // Uses the slow 2Hz clock
        .nRESET  (SW[9]),       // Same Reset
        
        // Inputs mapped to Switches 0-6
        .START   (SW[0]),
        .SELECT  (SW[1]),
        .OK      (SW[2]),
        .CANCEL  (SW[3]),
        .COIN_1  (SW[4]),
        .COIN_5  (SW[5]),
        .COIN_10 (SW[6]),
        
        // Outputs mapped to LEDs
        .ITEM    (LEDR[2:0]),   // Item LEDs on Right
        .C1      (LEDR[5]),     // Change LEDs in Middle
        .C5      (LEDR[6]),
        .C10     (LEDR[7]),
        .DISPENSE(LEDR[9])      // Dispense on Far Left
    );

    // Turn off unused LEDs
    assign LEDR[4:3] = 2'b00;
    assign LEDR[8]   = 1'b0;

endmodule