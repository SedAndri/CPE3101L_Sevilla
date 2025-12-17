`timescale 1ns / 1ps

module tb_ProblemD;

    // Inputs to DUT (Device Under Test)
    reg clk;
    reg reset;
    reg [1:0] A;

    // Outputs from DUT
    wire [3:0] Z;

    // Instantiate the Device Under Test (DUT)
    ProblemD uut (
        .clk(clk), 
        .reset(reset), 
        .A(A), 
        .Z(Z)
    );

    // Clock generation: 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Sequence
    initial begin
        // Optional: Dump waves for GTKWave/ModelSim
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_ProblemD);

        // Initialize Inputs
        reset = 1;
        A = 2'b11; // Hold mode initially
        
        // Wait 20ns and release reset
        #20;
        reset = 0;
        $display("--- Simulation Start ---");

        // -------------------------------------------------
        // TEST CASE 1: Test Even Sequence (A = 00)
        // -------------------------------------------------
        // Expect: 0 -> 2 -> 4 -> ... -> 14 -> 0
        $display("[Time %0t] Testing Even Sequence (A=00)", $time);
        A = 2'b00;
        #80; // Wait 8 clock cycles to see the count progress

        // -------------------------------------------------
        // TEST CASE 2: Test Hold (A = 11)
        // -------------------------------------------------
        // Expect: Z should stop changing
        $display("[Time %0t] Testing Hold (A=11) - Current Z: %d", $time, Z);
        A = 2'b11;
        #30; 

        // -------------------------------------------------
        // TEST CASE 3: Test Load 15 (A = 10)
        // -------------------------------------------------
        // Expect: Z becomes 15 immediately on next clock
        $display("[Time %0t] Testing Load 15 (A=10)", $time);
        A = 2'b10;
        #10; // Wait 1 clock cycle

        // -------------------------------------------------
        // TEST CASE 4: Test Odd Sequence (A = 01)
        // -------------------------------------------------
        // Expect: 15 (current) -> 1 -> 3 -> 5...
        // Note: Your logic says if Z is odd, next is Z+2. 
        // Since 15 is odd, it should wrap to 1 (15+2 = 17 = 1 mod 16)
        $display("[Time %0t] Testing Odd Sequence (A=01) from 15", $time);
        A = 2'b01;
        #80; // Let it count for a while

        // -------------------------------------------------
        // TEST CASE 5: Test Transition Logic (Odd -> Even)
        // -------------------------------------------------
        // Currently Z is likely odd. Switching to A=00.
        // Logic: if (Z[0]==1) next_Z = 0.
        $display("[Time %0t] Testing Switch: Odd Z to Even Mode (A=00)", $time);
        A = 2'b00;
        #20; // Should reset to 0 then count 2, 4...

        // -------------------------------------------------
        // TEST CASE 6: Test Transition Logic (Even -> Odd)
        // -------------------------------------------------
        // Currently Z is Even. Switching to A=01.
        // Logic: if (Z[0]==0) next_Z = 1.
        $display("[Time %0t] Testing Switch: Even Z to Odd Mode (A=01)", $time);
        A = 2'b01;
        #20; // Should jump to 1 then count 3, 5...

        // -------------------------------------------------
        // TEST CASE 7: Test Asynchronous Reset
        // -------------------------------------------------
        $display("[Time %0t] Testing Async Reset", $time);
        #3 reset = 1; // Assert reset not on clock edge to prove async nature
        #10 reset = 0;

        $display("--- Simulation End ---");
        $stop;
    end

    // Monitor changes to console
    initial begin
        $monitor("Time=%0t | Reset=%b A=%b | Z=%d (binary %b)", 
                 $time, reset, A, Z, Z);
    end

endmodule