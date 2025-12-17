
module ProblemD (
    input  wire       clk,        // posedge clock
    input  wire       reset,      // active-high async reset
    input  wire [1:0] A,          // control: 00 even seq, 01 odd seq, 10 load 15, 11 hold
    output reg  [3:0] Z           // current count
);

    reg [3:0] next_Z;

    // Next-state logic enforces the requested sequences
    always @(*) begin
        next_Z = Z; // default hold
        case (A)
            2'b00: begin
                if (Z[0] == 1'b1)
                    next_Z = 4'd0;          // if coming from odd path, restart even sequence
                else
                    next_Z = Z + 4'd2;      // 0,2,4,...,14 cycling via modulo-16
            end
            2'b01: begin
                if (Z[0] == 1'b0)
                    next_Z = 4'd1;          // force odd start when switching from even path
                else
                    next_Z = Z + 4'd2;      // 1,3,5,...,15 then wraps to 1
            end
            2'b10: next_Z = 4'd15;          // immediate load to 15
            default: next_Z = Z;            // hold for 2'b11 or any unused codes
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            Z <= 4'd0;
        else
            Z <= next_Z;
    end

endmodule
