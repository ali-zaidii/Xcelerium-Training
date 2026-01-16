module sram #(
    parameter ADDR_WIDTH = 17,  // 128K addresses for 640x480 image
    parameter DATA_WIDTH = 12   // 12-bit color (4-bit R, 4-bit G, 4-bit B)
)(
    input  logic                    clk,
    input  logic                    we,
    input  logic [ADDR_WIDTH-1:0]   addr,
    input  logic [DATA_WIDTH-1:0]   din,
    output logic [DATA_WIDTH-1:0]   dout
);
    logic [DATA_WIDTH-1:0] ram [0:(2**ADDR_WIDTH)-1];
    
    // Initialize RAM from hex file
    initial begin
        $readmemh("image.hex", ram);
    end
    
    always_ff @(posedge clk) begin
        if (we) begin
            ram[addr] <= din;
        end
        dout <= ram[addr];
    end
endmodule
