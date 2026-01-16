timescale 1ns / 1ps

module vga_controller (
    input  logic       clk,         // 25 MHz Pixel Clock
    input  logic       reset,       // Active High Reset
    output logic       h_sync,      // Horizontal Sync (Active Low)
    output logic       v_sync,      // Vertical Sync (Active Low)
    output logic       video_on,    // High = Active Drawing Area
    output logic [9:0] pixel_x,     // Current X (0-799)
    output logic [9:0] pixel_y      // Current Y (0-524)
);

    // --- VGA 640x480 Parameters ---
    localparam int H_DISPLAY = 640;
    localparam int H_FRONT   = 16;
    localparam int H_SYNC    = 96;
    localparam int H_BACK    = 48;
    localparam int H_TOTAL   = 800;

    localparam int V_DISPLAY = 480;
    localparam int V_FRONT   = 10;
    localparam int V_SYNC    = 2;
    localparam int V_BACK    = 33;
    localparam int V_TOTAL   = 525;

    // --- Internal Counters ---
    logic [9:0] h_count;
    logic [9:0] v_count;

    // --- Horizontal Counter Logic ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            h_count <= 10'd0;
        end else begin
            if (h_count == H_TOTAL - 1)
                h_count <= 10'd0;
            else
                h_count <= h_count + 1'b1;
        end
    end

    // --- Vertical Counter Logic ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            v_count <= 10'd0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                if (v_count == V_TOTAL - 1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 1'b1;
            end
        end
    end

    // --- Output Logic (Combinational) ---
    // H_Sync is LOW during the sync pulse (Active Low)
    assign h_sync = ~((h_count >= (H_DISPLAY + H_FRONT)) && 
                      (h_count < (H_DISPLAY + H_FRONT + H_SYNC)));

    // V_Sync is LOW during the sync pulse (Active Low)
    assign v_sync = ~((v_count >= (V_DISPLAY + V_FRONT)) && 
                      (v_count < (V_DISPLAY + V_FRONT + V_SYNC)));

    // Video is ON only when within the display area
    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

    // Export coordinates
    assign pixel_x = h_count;
    assign pixel_y = v_count;

endmodule
