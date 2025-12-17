module VMC (
    // Inputs
    input wire CLOCK,          // Negative-edged clock
    input wire nRESET,         // Asynchronous active low
    input wire START,          // Synchronous active high
    input wire OK,             // Synchronous active high
    input wire CANCEL,         // Asynchronous active high
    input wire SELECT,         // Synchronous active high
    
    // Coin Inputs (Assumed pulse inputs)
    input wire COIN_1,         
    input wire COIN_5,         
    input wire COIN_10,        
    
    // Outputs
    output wire [2:0] ITEM,    // LED Indicator (Combinational)
    output reg DISPENSE,       // Actuator
    output reg C1,             // Change Actuators
    output reg C5,             
    output reg C10             
);

    // ================= State Encoding =================
    localparam [2:0] 
        S_IDLE          = 3'd0,
        S_SELECT        = 3'd1,
        S_PAY           = 3'd2,
        S_DISPENSE_ITEM = 3'd3,
        S_CALC_CHANGE   = 3'd4, // Normal change (Balance - Price)
        S_REFUND        = 3'd5, // Cancelled (Full Balance)
        S_OUT_CHANGE    = 3'd6; // Dispensing loop

    // ================= Internal Registers =================
    reg [2:0] state;
    reg [7:0] balance;      // 8-bit to match constants and prevent truncation
    reg [7:0] price;
    reg [7:0] change_due;
    reg [1:0] item_ptr;     // 1, 2, or 3
    
    // Edge Detection Registers
    reg prev_sel, prev_ok, prev_c1, prev_c5, prev_c10;

    // ================= Output Logic (Combinational) =================
    // This removes 'ITEM' from the complex sequential blocks to avoid latches
    reg [2:0] item_leds;
    always @(*) begin
        case (item_ptr)
            2'd1: item_leds = 3'b001;
            2'd2: item_leds = 3'b010;
            2'd3: item_leds = 3'b100;
            default: item_leds = 3'b000;
        endcase
    end
    // Only show LEDs during selection
    assign ITEM = (state == S_SELECT) ? item_leds : 3'b000;

    // ================= Block 1: FSM Control Path =================
    // Handles State Transitions, Reset, and Async Cancel
    always @(negedge CLOCK or negedge nRESET or posedge CANCEL) begin
        if (!nRESET) begin
            state <= S_IDLE;
            // Reset Actuators
            DISPENSE <= 1'b0;
            C1 <= 1'b0; C5 <= 1'b0; C10 <= 1'b0;
        end 
        else if (CANCEL) begin
            // Async Cancel: Immediate transition
            // Only if we are not IDLE and not already dispensing change
            if (state != S_IDLE && state != S_OUT_CHANGE && state != S_REFUND) begin
                state <= S_REFUND;
                // Immediate safety shutdown of actuators
                DISPENSE <= 1'b0; 
                C1 <= 1'b0; C5 <= 1'b0; C10 <= 1'b0;
            end
        end 
        else begin
            // --- Synchronous Logic (Negative Edge) ---
            
            // Default pulse reset
            DISPENSE <= 1'b0;
            C1 <= 1'b0; C5 <= 1'b0; C10 <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (START) state <= S_SELECT;
                end

                S_SELECT: begin
                    if (OK && !prev_ok) state <= S_PAY;
                end

                S_PAY: begin
                    // If OK is pressed and we have enough money
                    // Note: price check is handled in Datapath Block to keep this clean
                    if (OK && !prev_ok && balance >= price) begin
                        state <= S_DISPENSE_ITEM;
                    end
                end

                S_DISPENSE_ITEM: begin
                    DISPENSE <= 1'b1; // Pulse actuator
                    state <= S_CALC_CHANGE;
                end

                S_CALC_CHANGE: state <= S_OUT_CHANGE; // Transition state

                S_REFUND: state <= S_OUT_CHANGE;      // Transition state

                S_OUT_CHANGE: begin
                    // Remain here until change_due is 0
                    if (change_due == 8'd0) state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // ================= Block 2: Datapath Logic =================
    // Handles Arithmetic (Counting money). 
    // NOT reset by CANCEL (This prevents Latch inference for 'balance')
    always @(negedge CLOCK or negedge nRESET) begin
        if (!nRESET) begin
            balance <= 8'd0;
            price <= 8'd0;
            change_due <= 8'd0;
            item_ptr <= 2'd0;
            prev_sel <= 0; prev_ok <= 0;
            prev_c1 <= 0; prev_c5 <= 0; prev_c10 <= 0;
        end 
        else begin
            // Input Edge Detection updates
            prev_sel <= SELECT;
            prev_ok <= OK;
            prev_c1 <= COIN_1;
            prev_c5 <= COIN_5;
            prev_c10 <= COIN_10;

            case (state)
                S_IDLE: begin
                    balance <= 8'd0;
                    change_due <= 8'd0;
                    if (START) begin
                        item_ptr <= 2'd1;
                        price <= 8'd3;
                    end
                end

                S_SELECT: begin
                    if (SELECT && !prev_sel) begin
                        // Rotate Items: 1->2->3->1
                        if (item_ptr == 2'd3) begin
                            item_ptr <= 2'd1;
                            price <= 8'd3;
                        end else begin
                            item_ptr <= item_ptr + 2'd1;
                            if (item_ptr == 2'd1) price <= 8'd5; // Moving to 2
                            else price <= 8'd12; // Moving to 3
                        end
                    end
                end

                S_PAY: begin
                    // Accumulate coins if balance < price
                    if (balance < price) begin
                        if (COIN_1 && !prev_c1)       balance <= balance + 8'd1;
                        else if (COIN_5 && !prev_c5)  balance <= balance + 8'd5;
                        else if (COIN_10 && !prev_c10) balance <= balance + 8'd10;
                    end
                end

                S_CALC_CHANGE: begin
                    // Normal purchase path: Change = Balance - Price
                    change_due <= balance - price;
                    balance <= 8'd0; // Clear balance
                end

                S_REFUND: begin
                    // Cancel path: Change = Full Balance
                    change_due <= balance;
                    balance <= 8'd0; // Clear balance
                end

                S_OUT_CHANGE: begin
                    // Greedy Algorithm for Change
                    if (change_due >= 8'd10)      change_due <= change_due - 8'd10;
                    else if (change_due >= 8'd5)  change_due <= change_due - 8'd5;
                    else if (change_due >= 8'd1)  change_due <= change_due - 8'd1;
                end
            endcase
        end
    end

endmodule
