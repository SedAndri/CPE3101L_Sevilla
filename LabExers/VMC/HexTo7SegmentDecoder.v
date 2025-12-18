// Chrys Sean T. Sevilla
// Group 4 CPE 3101L 10:30AM - 1:30PM
// Verilog HDL code for HexTo7SegmentDecoder

module HexTo7SegmentDecoder (
    input  [3:0] hex,       // 4-bit hexadecimal input
    input        dp,        // Decimal point control (active low)
    output reg [7:0] seg    // 7-segment output: seg[6:0] = segments a-g, seg[7] = DP
);

    always @(*) begin
        case (hex)
            //dp g f e d c b a
            // dp abcdefg
4'h0: seg[6:0] = 7'b1000000;
            4'h1: seg[6:0] = 7'b1111001; 
            4'h2: seg[6:0] = 7'b0100100;//ok 
            4'h3: seg[6:0] = 7'b0110000;
            4'h4: seg[6:0] = 7'b0011001;
            4'h5: seg[6:0] = 7'b0010010;
            4'h6: seg[6:0] = 7'b0000010;
            4'h7: seg[6:0] = 7'b1111000;
            4'h8: seg[6:0] = 7'b0000000;
            4'h9: seg[6:0] = 7'b0010000;
            
				4'hA: seg[6:0] = 7'b0001000;
            4'hB: seg[6:0] = 7'b0000011;
            4'hC: seg[6:0] = 7'b1000110;
            4'hD: seg[6:0] = 7'b0100001;
            4'hE: seg[6:0] = 7'b0000110;
            4'hF: seg[6:0] = 7'b0001110;
            default: seg[6:0] = 7'b1111111; // All segments off
        endcase

        seg[7] = dp; // Decimal point (active low)
    end

endmodule