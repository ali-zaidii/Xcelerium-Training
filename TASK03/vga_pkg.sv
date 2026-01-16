package vga_pkg;
    // 640x480 @ 60Hz timing parameters
    parameter H_DISPLAY    = 640;
    parameter H_FRONT      = 16;
    parameter H_SYNC       = 96;
    parameter H_BACK       = 48;
    parameter H_TOTAL      = 800;
    
    parameter V_DISPLAY    = 480;
    parameter V_FRONT      = 10;
    parameter V_SYNC       = 2;
    parameter V_BACK       = 33;
    parameter V_TOTAL      = 525;
    
    // Pixel clock = 25.175 MHz (for 60Hz refresh)
    parameter PIXEL_CLK_DIV = 2; // Assuming 50MHz input clock
    
    typedef enum logic [2:0] {
        IDLE,
        HORIZONTAL_SYNC,
        HORIZONTAL_BACK_PORCH,
        DISPLAY_ACTIVE,
        HORIZONTAL_FRONT_PORCH
    } vga_state_t;
endpackage
