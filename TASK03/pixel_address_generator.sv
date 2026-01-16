module pixel_address_generator (
    input  logic [9:0]  h_count,
    input  logic [9:0]  v_count,
    input  logic        display_enable,
    output logic [16:0] pixel_addr
);
    import vga_pkg::*;
    
    always_comb begin
        if (display_enable) begin
            // Calculate linear address: addr = y * width + x
            pixel_addr = (v_count * H_DISPLAY) + h_count;
        end else begin
            pixel_addr = 0;
        end
    end
endmodule
