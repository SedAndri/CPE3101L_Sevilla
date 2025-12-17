`timescale 1ns/1ps

module tb_VMC;

    // 1. Declare Inputs as Regs and Outputs as Wires
    reg CLOCK = 0;
    reg nRESET = 0;
    reg START = 0; 
    reg OK = 0; 
    reg CANCEL = 0; 
    reg SELECT = 0;
    reg COIN_1 = 0; 
    reg COIN_5 = 0; 
    reg COIN_10 = 0;

    wire [2:0] ITEM; 
    wire DISPENSE, C1, C5, C10;

    // 2. Instantiate the DUT
    // Ensure the module name 'VMC' matches your design file
    VMC dut (
        .CLOCK(CLOCK), .nRESET(nRESET),
        .START(START), .OK(OK), .CANCEL(CANCEL), .SELECT(SELECT),
        .COIN_1(COIN_1), .COIN_5(COIN_5), .COIN_10(COIN_10),
        .ITEM(ITEM), .DISPENSE(DISPENSE), 
        .C1(C1), .C5(C5), .C10(C10)
    );

    // 3. Clock Generation (50 MHz -> 20ns period)
    always #10 CLOCK = ~CLOCK;

    // 4. Synchronous Pulse Task
    // The DUT works on NEGATIVE edges. We drive inputs on POSITIVE edges
    // to ensure the signal is stable and setup times are met.
    task pulse(input integer sel);
        begin
            @(posedge CLOCK); // Wait for a safe edge
            case (sel)
              0: START    = 1;
              1: OK       = 1;
              2: SELECT   = 1;
              3: COIN_1   = 1; // Fixed Typo
              4: COIN_5   = 1; // Fixed Typo
              5: COIN_10  = 1; // Fixed Typo
            endcase
            
            @(posedge CLOCK); // Hold high for exactly 1 clock cycle
            
            START = 0; OK = 0; SELECT = 0;
            COIN_1 = 0; COIN_5 = 0; COIN_10 = 0;
            
            #5; // Small buffer between pulses
        end
    endtask

    // 5. Test Sequence
    initial begin
        

        // Reset Sequence
        $display("--- Resetting ---");
        nRESET = 0; 
        #30; 
        nRESET = 1; 
        #20;

        // ------------------------------------------------------------
        // Test 1: Item 1 (Price 3.00), Exact Pay
        // ------------------------------------------------------------
        $display("--- Test 1: Item 1 (Price 3), Exact Pay ---");
        pulse(0);       // START (Default selects Item 1)
        pulse(1);       // OK (Confirm Selection) -> State: PAY
        
        pulse(3);       // Insert 1.00
        pulse(3);       // Insert 1.00
        pulse(3);       // Insert 1.00 (Total 3.00)
        
        pulse(1);       // OK -> DISPENSE
        #60;            // Wait for operation to complete

        // ------------------------------------------------------------
        // Test 2: Item 2 (Price 5.00), Overpay (Pay 10)
        // ------------------------------------------------------------
        $display("--- Test 2: Item 2 (Price 5), Pay 10 (Change 5) ---");
        pulse(0);       // START (Item 1)
        pulse(2);       // SELECT (Advance to Item 2)
        pulse(1);       // OK -> State: PAY
        
        pulse(5);       // Insert 10.00
        pulse(1);       // OK -> DISPENSE
        #100;           // Wait (needs time for dispense + change C5)

        // ------------------------------------------------------------
        // Test 3: Item 3 (Price 12.00), Partial Pay + CANCEL
        // ------------------------------------------------------------
        $display("--- Test 3: Item 3 (Price 12), Partial Pay + CANCEL ---");
        pulse(0);       // START
        pulse(2);       // SELECT (Item 2)
        pulse(2);       // SELECT (Item 3)
        pulse(1);       // OK -> State: PAY
        
        pulse(5);       // Insert 10.00
        pulse(3);       // Insert 1.00 (Total 11.00)
        
        $display(" > Asserting CANCEL (Refund 11.00)");
        #15 CANCEL = 1; // Async Assert
        #30 CANCEL = 0; // Release
        #150;           // Wait for refund (C10 + C1)

        $display("--- Simulation Finished ---");
        $stop;
    end
    
    // 6. Monitor Changes
    initial begin
        $monitor("Time: %t | ITEM: %b | DISP: %b | Change: 1:%b 5:%b 10:%b", 
                 $time, ITEM, DISPENSE, C1, C5, C10);
    end

endmodule
