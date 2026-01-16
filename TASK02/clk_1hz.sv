// 1 Hz clock generator from 50 MHz input clock
module clk_1hz (
    input  logic clk_50mhz,
    input  logic reset,
    output logic clock_1hz
);

    // 50 MHz → 1 Hz
    // Toggle every 25,000,000 cycles → full period = 50,000,000 cycles
    localparam int DIV_COUNT = 25_000_000;

    logic [$clog2(DIV_COUNT)-1:0] count;

    always_ff @(posedge clk_50mhz or posedge reset) begin
        if (reset) begin
            count  <= '0;
            clock_1hz <= 1'b0;
        end
        else if (count == DIV_COUNT-1) begin
            count  <= '0;
            clock_1hz <= ~clock_1hz;
        end
        else begin
            count <= count + 1'b1;
        end
    end

endmodule