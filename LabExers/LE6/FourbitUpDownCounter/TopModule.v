// Chrys Sean T. Sevilla
// Group 4 CPE 3101L 10:30AM - 1:30PM
// Verilog HDL code for FourbitUpDownCounter

module TopModule (
    input wire clk_in,       // Assigned to PIN_P11 (50 MHz)
    input wire nReset,       // Assigned to PIN_B14 (Switch 8)
    input wire load,         // Assigned to PIN_A14 (Switch 7)
    input wire count_en,     // Assigned to PIN_F15 (Switch 9)
    input wire up,           // Assigned to PIN_A13 (Switch 6)
    input wire [3:0] data_in,// Assigned to Switches [3:0]
    output wire [3:0] count  // Assigned to LEDs [3:0]
);

    wire slow_clk; // Output of ClockDivider

    // Instantiate ClockDivider
    ClockDivider clk_div_inst (
        .clk_in(clk_in),
        .nReset(nReset),
        .clk_out(slow_clk)
    );

    // Instantiate FourbitUpDownCounter
    FourbitUpDownCounter counter_inst (
        .clk(slow_clk),       // Use divided clock
        .reset(nReset),       // Active-low reset
        .load(load),
        .count_en(count_en),
        .up(up),
        .data_in(data_in),
        .count(count)
    );

endmodule
