module VMC (
    // Inputs
    input wire CLOCK,          // Negative-edged clock
    input wire nRESET,         // Asynchronous active low
    input wire START,          // Synchronous active high
    input wire OK,             // Synchronous active high
    input wire CANCEL,         // Active high (Synchronous)
    input wire SELECT,         // Synchronous active high
    
    // Coin Inputs
    input wire COIN_1,         
    input wire COIN_5,         
    input wire COIN_10,        
    
    // Outputs
    output wire [2:0] ITEM,    // LED Indicator (Combinational)
    output reg DISPENSE,       // Actuator
    output reg C1,             // Change Actuators
    output reg C5,             
    output reg C10,
    
    // Debug Outputs for 7-Segment
    output wire [7:0] DBG_COST,
    output wire [7:0] DBG_PAID,
    output wire [7:0] DBG_CHANGE
);

    // ================= State Encoding =================
    localparam [2:0] 
        S_IDLE          = 3'd0,
        S_SELECT        = 3'd1,
        S_PAY           = 3'd2,
        S_DISPENSE_ITEM = 3'd3,
        S_CALC_CHANGE   = 3'd4, 
        S_REFUND        = 3'd5, 
        S_OUT_CHANGE    = 3'd6; 

    // ================= Internal Registers =================
    reg [2:0] state;
    reg [7:0] balance;      
    reg [7:0] price;
    reg [7:0] change_due;          // This one counts down (Working register)
    reg [7:0] final_change_display;// This one stays static (Display register)
    reg [1:0] item_ptr;     
    
    // Edge Detection Registers
    reg prev_sel, prev_ok, prev_c1, prev_c5, prev_c10;

    // ================= Output Logic (Combinational) =================
    reg [2:0] item_leds;
    always @(*) begin
        case (item_ptr)
            2'd1: item_leds = 3'b001;
            2'd2: item_leds = 3'b010;
            2'd3: item_leds = 3'b100;
            default: item_leds = 3'b000;
        endcase
    end
    assign ITEM = (state == S_SELECT) ? item_leds : 3'b000;

    // ================= Block 1: FSM Control Path =================
    always @(negedge CLOCK or negedge nRESET) begin
        if (!nRESET) begin
            state <= S_IDLE;
            DISPENSE <= 1'b0;
            C1 <= 1'b0; C5 <= 1'b0; C10 <= 1'b0;
        end 
        else begin
            // --- Synchronous Logic (Negative Edge) ---
            
            if (CANCEL) begin
                if (state != S_IDLE && state != S_OUT_CHANGE && state != S_REFUND) begin
                    state <= S_REFUND;
                    DISPENSE <= 1'b0; 
                    C1 <= 1'b0; C5 <= 1'b0; C10 <= 1'b0;
                end
            end
            else begin
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
                        if (OK && !prev_ok && balance >= price) begin
                            state <= S_DISPENSE_ITEM;
                        end
                    end

                    S_DISPENSE_ITEM: begin
                        DISPENSE <= 1'b1; 
                        state <= S_CALC_CHANGE;
                    end

                    S_CALC_CHANGE: state <= S_OUT_CHANGE; 

                    S_REFUND: state <= S_OUT_CHANGE;      

                    S_OUT_CHANGE: begin
                        if (change_due == 8'd0) state <= S_IDLE;
                    end

                    default: state <= S_IDLE;
                endcase
            end
        end
    end

    // ================= Block 2: Datapath Logic =================
    always @(negedge CLOCK or negedge nRESET) begin
        if (!nRESET) begin
            balance <= 8'd0;
            price <= 8'd0;
            change_due <= 8'd0;
            final_change_display <= 8'd0; // Reset display
            item_ptr <= 2'd0;
            prev_sel <= 0; prev_ok <= 0;
            prev_c1 <= 0; prev_c5 <= 0; prev_c10 <= 0;
        end 
        else begin
            // Input Edge Detection
            prev_sel <= SELECT;
            prev_ok <= OK;
            prev_c1 <= COIN_1;
            prev_c5 <= COIN_5;
            prev_c10 <= COIN_10;

            case (state)
                S_IDLE: begin
                    balance <= 8'd0;
                    change_due <= 8'd0;
                    // Note: We do NOT clear final_change_display here automatically
                    // so it persists from the last transaction.
                    // We only clear it when the user starts a NEW transaction.
                    if (START) begin
                        final_change_display <= 8'd0; // Clear old change for new user
                        item_ptr <= 2'd1;
                        price <= 8'd3;
                    end
                end

                S_SELECT: begin
                    if (SELECT && !prev_sel) begin
                        if (item_ptr == 2'd3) begin
                            item_ptr <= 2'd1;
                            price <= 8'd3;
                        end else begin
                            item_ptr <= item_ptr + 2'd1;
                            if (item_ptr == 2'd1) price <= 8'd5; 
                            else price <= 8'd12; 
                        end
                    end
                end

                S_PAY: begin
                    if (balance < price) begin
                        if (COIN_1 && !prev_c1)       balance <= balance + 8'd1;
                        else if (COIN_5 && !prev_c5)  balance <= balance + 8'd5;
                        else if (COIN_10 && !prev_c10) balance <= balance + 8'd10;
                    end
                end

                S_CALC_CHANGE: begin
                    // 1. Load the working register for dispensing
                    change_due <= balance - price;
                    // 2. Load the display register (This one won't change)
                    final_change_display <= balance - price;
                    
                    balance <= 8'd0; 
                end

                S_REFUND: begin
                    // 1. Load working register
                    change_due <= balance;
                    // 2. Load display register
                    final_change_display <= balance;
                    
                    balance <= 8'd0; 
                end

                S_OUT_CHANGE: begin
                    // Only modify 'change_due', leave 'final_change_display' alone
                    if (change_due >= 8'd10)      change_due <= change_due - 8'd10;
                    else if (change_due >= 8'd5)  change_due <= change_due - 8'd5;
                    else if (change_due >= 8'd1)  change_due <= change_due - 8'd1;
                end
            endcase
        end
    end

    // === CONNECT OUTPUTS ===
    assign DBG_COST   = price;
    assign DBG_PAID   = balance;
    
    // KEY FIX: Connect the 7-segment output to the STATIC register, not the countdown one
    assign DBG_CHANGE = final_change_display; 

endmodule
