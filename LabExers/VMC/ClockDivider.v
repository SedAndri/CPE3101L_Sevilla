// Chrys Sean T. Sevilla
// Group 4 CPE 3101L 10:30AM - 1:30PM
// Verilog HDL code for ClockDivider

module ClockDivider (
    input wire clk_in,      // 50 MHz input clock
    input wire nReset,      // Active-low asynchronous reset
    output reg clk_out      // Divided clock output
);

    // Calculate division factor:
    // 50 MHz / 4 = 12,500,000 cycles per half-period
    parameter DIV_FACTOR = 12_500_000; // For FPGA
    reg [24:0] counter; // Enough bits for 25 million

    always @(posedge clk_in or negedge nReset) begin
        if (!nReset) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == DIV_FACTOR - 1) begin
                counter <= 0;
                clk_out <= ~clk_out; // Toggle output
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
