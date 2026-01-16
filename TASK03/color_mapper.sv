module color_mapper (
    input  logic [11:0] pixel_data,
    input  logic        display_enable,
    output logic [3:0]  vga_red,
    output logic [3:0]  vga_green,
    output logic [3:0]  vga_blue
);
    always_comb begin
        if (display_enable) begin
            vga_red   = pixel_data[11:8];  // 4-bit red
            vga_green = pixel_data[7:4];   // 4-bit green
            vga_blue  = pixel_data[3:0];   // 4-bit blue
        end else begin
            vga_red   = 4'b0000;
            vga_green = 4'b0000;
            vga_blue  = 4'b0000;
        end
    end
endmodule
