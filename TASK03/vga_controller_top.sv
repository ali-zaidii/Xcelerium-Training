module vga_controller_top (
    input  logic       clk_50mhz,
    input  logic       rst_n,
    output logic       vga_hsync,
    output logic       vga_vsync,
    output logic [3:0] vga_red,
    output logic [3:0] vga_green,
    output logic [3:0] vga_blue
);
    // Internal signals
    logic        pixel_clk;
    logic        display_enable;
    logic [9:0]  h_count;
    logic [9:0]  v_count;
    logic [16:0] pixel_addr;
    logic [11:0] pixel_data;
    
    // Instantiate Clock Divider
    clock_divider #(
        .DIV_FACTOR(2)
    ) clk_div_inst (
        .clk_in(clk_50mhz),
        .rst_n(rst_n),
        .clk_out(pixel_clk)
    );
    
    // Instantiate VGA Sync Generator FSM
    vga_sync_generator sync_gen_inst (
        .clk(pixel_clk),
        .rst_n(rst_n),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .display_enable(display_enable),
        .h_count(h_count),
        .v_count(v_count)
    );
    
    // Instantiate Pixel Address Generator
    pixel_address_generator addr_gen_inst (
        .h_count(h_count),
        .v_count(v_count),
        .display_enable(display_enable),
        .pixel_addr(pixel_addr)
    );
    
    // Instantiate SRAM
    sram #(
        .ADDR_WIDTH(17),
        .DATA_WIDTH(12)
    ) sram_inst (
        .clk(pixel_clk),
        .we(1'b0),           // Read-only for display
        .addr(pixel_addr),
        .din(12'h000),
        .dout(pixel_data)
    );
    
    // Instantiate Color Mapper
    color_mapper color_map_inst (
        .pixel_data(pixel_data),
        .display_enable(display_enable),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue)
    );
endmodule
